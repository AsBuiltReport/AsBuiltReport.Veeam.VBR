
function Get-AbrVbrTapeMediaPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Media Pools Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR Tape Media Pools information from $System."
    }

    process {
        try {
            if ((Get-VBRTapeMediaPool).count -gt 0) {
                Section -Style Heading3 'Tape Media Pools' {
                    $OutObj = @()
                    try {
                        $PoolObjs = Get-VBRTapeMediaPool
                        foreach ($PoolObj in $PoolObjs) {
                            try {
                                if ($PoolObj.Type -ne "Custom") {
                                    $Capacity = ((Get-VBRTapeMedium -MediaPool $PoolObj.Name).Capacity | Measure-Object -Sum).Sum
                                    $FreeSpace = ((Get-VBRTapeMedium -MediaPool $PoolObj.Name).Free | Measure-Object -Sum).Sum
                                }
                                else {
                                    $Capacity = $PoolObj.Capacity
                                    $FreeSpace = $PoolObj.FreeSpace
                                }
                                Write-PscriboMessage "Discovered $($PoolObj.Name) Media Pool."
                                $inObj = [ordered] @{
                                    'Name' = $PoolObj.Name
                                    'Type' = $PoolObj.Type
                                    'Tape Count' = ((Get-VBRTapeMediaPool -Id $PoolObj.Id).Medium).count
                                    'Total Space' = ConvertTo-FileSizeString $Capacity
                                    'Free Space' = ConvertTo-FileSizeString $FreeSpace
                                    'Tape Library' = ($PoolObj.GlobalOptions.LibraryId | ForEach-Object {Get-VBRTapeLibrary -Id $_}).Name
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Tape Media Pools - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 24, 15, 12, 12, 12, 25
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                    Section -Style Heading4 'Tape Media Pools Configuration' {
                        foreach ($PoolObj in ($PoolObjs | Where-Object {$_.Type -eq 'Gfs' -or $_.Type -eq 'Custom'})) {
                            Section -Style Heading5 $PoolObj.Name {
                                Section -ExcludeFromTOC -Style NOTOCHeading6 'Tape Library' {
                                    $OutObj = @()
                                    foreach ($TapeLibrary in $PoolObj.GlobalOptions.LibraryId) {
                                        try {
                                            $TapeLibraryObj = Get-VBRTapeLibrary -Id $TapeLibrary.Guid
                                            if ($PoolObj.Type -ne "Custom") {
                                                $Capacity = ((Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibrary.Guid}).Capacity | Measure-Object -Sum).Sum
                                                $FreeSpace = ((Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibrary.Guid}).Free | Measure-Object -Sum).Sum
                                            }
                                            else {
                                                $Capacity = $PoolObj.Capacity
                                                $FreeSpace = $PoolObj.FreeSpace
                                            }
                                            $TapeDrives = @()
                                            foreach ($Drive in $TapeLibraryObj.Drives) {
                                                $TapeDrives += "Drive $($Drive.Address + 1)"
                                            }
                                            Write-PscriboMessage "Discovered $($PoolObj.Name) Media Pool Configuration."
                                            $inObj = [ordered] @{
                                                'Name' = $TapeLibraryObj.Name
                                                'Type' = $TapeLibraryObj.Type
                                                'State' = $TapeLibraryObj.State
                                                'Model' = $TapeLibraryObj.Model
                                                'Drives' = $TapeDrives -join ', '
                                                'Slots' = $TapeLibraryObj.Slots
                                                'Description' = $TapeLibraryObj.Description
                                                'Tape Count' = ((Get-VBRTapeMediaPool -Id $PoolObj.Id).Medium).count
                                                'Total Space' = ConvertTo-FileSizeString $Capacity
                                                'Free Space' = ConvertTo-FileSizeString $FreeSpace
                                            }

                                            $OutObj = [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Tape Library - $($PoolObj.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}