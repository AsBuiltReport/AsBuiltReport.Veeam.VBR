
function Get-AbrVbrTapeMediaPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Media Pools Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $PoolObjs = Get-VBRTapeMediaPool
                            foreach ($PoolObj in $PoolObjs) {
                                try {
                                    Write-PscriboMessage "Discovered $($PoolObj.Name) Media Pool."
                                    $inObj = [ordered] @{
                                        'Name' = $PoolObj.Name
                                        'Type' = $PoolObj.Type
                                        'Tape Count' = ((Get-VBRTapeMediaPool -Id $PoolObj.Id ).Medium).count
                                        'Total Space' = ConvertTo-FileSizeString $PoolObj.Capacity
                                        'Free Space' = ConvertTo-FileSizeString $PoolObj.FreeSpace
                                        'Tape Library' = $PoolObj.LibraryId | ForEach-Object {Get-VBRTapeLibrary -Id $_}
                                    }

                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "Tape Media Pools - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}