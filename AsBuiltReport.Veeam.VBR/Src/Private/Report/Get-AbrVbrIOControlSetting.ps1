
function Get-AbrVbrIOControlSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns storage latency control settings on the production datastores.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.26
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
        Write-PScriboMessage "Discovering Veeam VBR storage latency control settings information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrIOControlSetting
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Storage latency control settings'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.Edition -in @('EnterprisePlus', 'Enterprise') -and $_.Status -ne 'Expired' }) {
                if ($StorageLatencyControls = Get-VBRStorageLatencyControlOptions) {
                    Section -Style Heading4 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        $OutObj = @()
                        foreach ($StorageLatencyControl in $StorageLatencyControls) {
                            try {
                                $inObj = [ordered] @{
                                    $LocalizedData.LatencyLimit = "$($StorageLatencyControl.LatencyLimitMs)/ms"
                                    $LocalizedData.ThrottlingIOLimit = "$($StorageLatencyControl.ThrottlingIOLimitMs)/ms"
                                    $LocalizedData.Enabled = $StorageLatencyControl.Enabled
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Storage Latency Control Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.$($LocalizedData.Enabled) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.Enabled
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 35, 35, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        #---------------------------------------------------------------------------------------------#
                        #                          Per Datastore Latency Control Options                              #
                        #---------------------------------------------------------------------------------------------#
                        try {
                            $StorageLatencyControls = Get-VBRAdvancedLatencyOptions
                            if (($VbrLicenses | Where-Object { $_.Edition -eq 'EnterprisePlus' }) -and $StorageLatencyControls) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SubHeading {
                                    $OutObj = @()
                                    try {
                                        $Datastores = Invoke-FindVBRViEntityWithTimeout -DatastoresAndVMsOnly | Where-Object { ($_.type -eq 'Datastore') }

                                    } catch {
                                        Write-PScriboMessage -IsWarning "Per Datastore Latency Control Options Section: $($_.Exception.Message)"
                                    }

                                    foreach ($StorageLatencyControl in $StorageLatencyControls) {
                                        try {
                                            $DatastoreName = ($Datastores | Where-Object { $_.Reference -eq $StorageLatencyControl.DatastoreId }).Name | Select-Object -Unique
                                            $inObj = [ordered] @{
                                                $LocalizedData.DatastoreName = switch ([string]::IsNullOrEmpty($DatastoreName)) {
                                                    $true { $StorageLatencyControl.DatastoreId }
                                                    default { $DatastoreName }
                                                }
                                                $LocalizedData.LatencyLimit = "$($StorageLatencyControl.LatencyLimitMs)/ms"
                                                $LocalizedData.ThrottlingIOLimit = "$($StorageLatencyControl.ThrottlingIOLimitMs)/ms"
                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Per Datastore Latency Control Options Section: $($_.Exception.Message)"
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.SubTableHeading) - $VeeamBackupServer"
                                        List = $false
                                        ColumnWidths = 40, 30, 30
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Per Datastore Latency Control Options Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Storage Latency Control Section: $($_.Exception.Message)"
        }
    }
    end {}

}