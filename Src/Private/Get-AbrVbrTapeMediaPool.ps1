
function Get-AbrVbrTapeMediaPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Media Pools Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.1
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
                                    'Tape Library' = $PoolObj.LibraryId | ForEach-Object {Get-VBRTapeLibrary -Id $_}
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
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}