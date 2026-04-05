
function Get-AbrVbrNetworkTrafficRule {
    <#
    .SYNOPSIS
    Used by As Built Report to returns network traffic rules settings created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.0
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
        Write-PScriboMessage "Discovering Veeam VBR network traffic rules settings information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrNetworkTrafficRule
        Show-AbrDebugExecutionTime -Start -TitleMessage 'NDMP Servers'
    }

    process {
        try {
            if ($TrafficOptions = Get-VBRNetworkTrafficRuleOptions) {
                Section -Style Heading4 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        $inObj = [ordered] @{
                            $LocalizedData.IsMultipleUploadStreamsEnabled = $TrafficOptions.MultipleUploadStreamsEnabled
                            $LocalizedData.UploadStreamsPerJob = $TrafficOptions.StreamsPerJobCount
                            $LocalizedData.IsIPv6Enabled = $TrafficOptions.IPv6Enabled
                        }
                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($TrafficRules = Get-VBRNetworkTrafficRule) {
                            Section -Style Heading5 $LocalizedData.TrafficRuleHeading {
                                Paragraph $LocalizedData.TrafficRuleParagraph
                                BlankLine
                                $OutObj = @()
                                try {
                                    foreach ($TrafficRule in $TrafficRules) {
                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $TrafficRule.Name
                                            $LocalizedData.SourceIPStart = $TrafficRule.SourceIPStart
                                            $LocalizedData.SourceIPEnd = $TrafficRule.SourceIPEnd
                                            $LocalizedData.TargetIPStart = $TrafficRule.TargetIPStart
                                            $LocalizedData.TargetIPEnd = $TrafficRule.TargetIPEnd
                                            $LocalizedData.EncryptionEnabled = $TrafficRule.EncryptionEnabled
                                            $LocalizedData.Throttling = "Throttling Enabled: $($TrafficRule.ThrottlingEnabled)`r`nThrottling Unit: $($TrafficRule.ThrottlingUnit)`r`nThrottling Value: $($TrafficRule.ThrottlingValue)`r`nThrottling Windows: $($TrafficRule.ThrottlingWindowEnabled)"
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Infrastructure.Settings) {
                                            $OutObj | Where-Object { $_.$($LocalizedData.EncryptionEnabled) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.EncryptionEnabled
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TrafficRuleHeading) - $($TrafficRule.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($TrafficRule.ThrottlingWindowEnabled) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ThrottlingWindowsHeading {
                                                Paragraph -ScriptBlock $Legend

                                                try {

                                                    $OutObj = Get-WindowsTimePeriod -InputTimePeriod $TrafficRule.ThrottlingWindowOptions

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.ThrottlingWindowsTableHeading) - $($TrafficRule.Name)"
                                                        List = $true
                                                        ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                        Key = 'H'
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    if ($OutObj) {
                                                        $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                        $OutObj2.Rows | Where-Object { $_.Sun -eq '0' } | Set-Style -Style OFF -Property 'Sun'
                                                        $OutObj2.Rows | Where-Object { $_.Mon -eq '0' } | Set-Style -Style OFF -Property 'Mon'
                                                        $OutObj2.Rows | Where-Object { $_.Tue -eq '0' } | Set-Style -Style OFF -Property 'Tue'
                                                        $OutObj2.Rows | Where-Object { $_.Wed -eq '0' } | Set-Style -Style OFF -Property 'Wed'
                                                        $OutObj2.Rows | Where-Object { $_.Thu -eq '0' } | Set-Style -Style OFF -Property 'Thu'
                                                        $OutObj2.Rows | Where-Object { $_.Fri -eq '0' } | Set-Style -Style OFF -Property 'Fri'
                                                        $OutObj2.Rows | Where-Object { $_.Sat -eq '0' } | Set-Style -Style OFF -Property 'Sat'

                                                        $OutObj2.Rows | Where-Object { $_.Sun -eq '1' } | Set-Style -Style ON -Property 'Sun'
                                                        $OutObj2.Rows | Where-Object { $_.Mon -eq '1' } | Set-Style -Style ON -Property 'Mon'
                                                        $OutObj2.Rows | Where-Object { $_.Tue -eq '1' } | Set-Style -Style ON -Property 'Tue'
                                                        $OutObj2.Rows | Where-Object { $_.Wed -eq '1' } | Set-Style -Style ON -Property 'Wed'
                                                        $OutObj2.Rows | Where-Object { $_.Thu -eq '1' } | Set-Style -Style ON -Property 'Thu'
                                                        $OutObj2.Rows | Where-Object { $_.Fri -eq '1' } | Set-Style -Style ON -Property 'Fri'
                                                        $OutObj2.Rows | Where-Object { $_.Sat -eq '1' } | Set-Style -Style ON -Property 'Sat'
                                                        $OutObj2
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Throttling Windows Time Period Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Network Traffic Rules Section: $($_.Exception.Message)"
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                                Preferred Networks                                           #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    if ((Get-VBRPreferredNetwork).count -gt 0) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.PreferredNetworksHeading {
                                            $OutObj = @()
                                            $PreferedNetworks = Get-VBRPreferredNetwork
                                            foreach ($PreferedNetwork in $PreferedNetworks) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.IPAddress = $PreferedNetwork.IpAddress
                                                        $LocalizedData.SubnetMask = $PreferedNetwork.SubnetMask
                                                        $LocalizedData.CIDRNotation = $PreferedNetwork.CIDRNotation
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Preferred Networks $($PreferedNetwork.IpAddress) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.PreferredNetworksTableHeading) - $VeeamBackupServer"
                                                List = $false
                                                ColumnWidths = 30, 30, 40
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Preferred Networks Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Network Traffic Options Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'NDMP Servers'
    }

}