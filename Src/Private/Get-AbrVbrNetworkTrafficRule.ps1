
function Get-AbrVbrNetworkTrafficRule {
    <#
    .SYNOPSIS
    Used by As Built Report to returns network traffic rules settings created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.12
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
    }

    process {
        try {
            if ($TrafficOptions = Get-VBRNetworkTrafficRuleOptions) {
                Section -Style Heading4 'Network Traffic Rules Options' {
                    Paragraph "The following section details network traffic rules options configured on Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    try {
                        $inObj = [ordered] @{
                            'Is Multiple Upload Streams Enabled?' = $TrafficOptions.MultipleUploadStreamsEnabled
                            'Upload Streams Per Job' = $TrafficOptions.StreamsPerJobCount
                            'Is IPv6 Enabled?' = $TrafficOptions.IPv6Enabled
                        }
                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                        $TableParams = @{
                            Name = "Network Traffic Rule Options - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($TrafficRules = Get-VBRNetworkTrafficRule) {
                            Section -Style Heading5 'Network Traffic Rule' {
                                Paragraph "The following section details network traffic rules settings configured on Veeam Backup & Replication."
                                BlankLine
                                $OutObj = @()
                                try {
                                    foreach ($TrafficRule in $TrafficRules) {
                                        $inObj = [ordered] @{
                                            'Name' = $TrafficRule.Name
                                            'Source IP Start' = $TrafficRule.SourceIPStart
                                            'Source IP End' = $TrafficRule.SourceIPEnd
                                            'Target IP Start' = $TrafficRule.TargetIPStart
                                            'Target IP End' = $TrafficRule.TargetIPEnd
                                            'Encryption Enabled' = $TrafficRule.EncryptionEnabled
                                            'Throttling' = "Throttling Enabled: $($TrafficRule.ThrottlingEnabled)`r`nThrottling Unit: $($TrafficRule.ThrottlingUnit)`r`nThrottling Value: $($TrafficRule.ThrottlingValue)`r`nThrottling Windows: $($TrafficRule.ThrottlingWindowEnabled)"
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Infrastructure.Settings) {
                                            $OutObj | Where-Object { $_.'Encryption Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Encryption Enabled'
                                        }

                                        $TableParams = @{
                                            Name = "Network Traffic Rules - $($TrafficRule.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($TrafficRule.ThrottlingWindowEnabled) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Throttling Windows Time Period" {
                                                Paragraph -ScriptBlock $Legend

                                                try {

                                                    $OutObj = Get-WindowsTimePeriod -InputTimePeriod $TrafficRule.ThrottlingWindowOptions

                                                    $TableParams = @{
                                                        Name = "Throttling Windows - $($TrafficRule.Name)"
                                                        List = $true
                                                        ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                        Key = 'H'
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    if ($OutObj) {
                                                        $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                        $OutObj2.Rows | Where-Object { $_.Sun -eq "0" } | Set-Style -Style OFF -Property "Sun"
                                                        $OutObj2.Rows | Where-Object { $_.Mon -eq "0" } | Set-Style -Style OFF -Property "Mon"
                                                        $OutObj2.Rows | Where-Object { $_.Tue -eq "0" } | Set-Style -Style OFF -Property "Tue"
                                                        $OutObj2.Rows | Where-Object { $_.Wed -eq "0" } | Set-Style -Style OFF -Property "Wed"
                                                        $OutObj2.Rows | Where-Object { $_.Thu -eq "0" } | Set-Style -Style OFF -Property "Thu"
                                                        $OutObj2.Rows | Where-Object { $_.Fri -eq "0" } | Set-Style -Style OFF -Property "Fri"
                                                        $OutObj2.Rows | Where-Object { $_.Sat -eq "0" } | Set-Style -Style OFF -Property "Sat"

                                                        $OutObj2.Rows | Where-Object { $_.Sun -eq "1" } | Set-Style -Style ON -Property "Sun"
                                                        $OutObj2.Rows | Where-Object { $_.Mon -eq "1" } | Set-Style -Style ON -Property "Mon"
                                                        $OutObj2.Rows | Where-Object { $_.Tue -eq "1" } | Set-Style -Style ON -Property "Tue"
                                                        $OutObj2.Rows | Where-Object { $_.Wed -eq "1" } | Set-Style -Style ON -Property "Wed"
                                                        $OutObj2.Rows | Where-Object { $_.Thu -eq "1" } | Set-Style -Style ON -Property "Thu"
                                                        $OutObj2.Rows | Where-Object { $_.Fri -eq "1" } | Set-Style -Style ON -Property "Fri"
                                                        $OutObj2.Rows | Where-Object { $_.Sat -eq "1" } | Set-Style -Style ON -Property "Sat"
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
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Preferred Networks' {
                                            $OutObj = @()
                                            $PreferedNetworks = Get-VBRPreferredNetwork
                                            foreach ($PreferedNetwork in $PreferedNetworks) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($PreferedNetwork.CIDRNotation) Prefered Network."
                                                    $inObj = [ordered] @{
                                                        'IP Address' = $PreferedNetwork.IpAddress
                                                        'Subnet Mask' = $PreferedNetwork.SubnetMask
                                                        'CIDR Notation' = $PreferedNetwork.CIDRNotation
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Preferred Networks $($PreferedNetwork.IpAddress) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Preferred Networks - $VeeamBackupServer"
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
    end {}

}