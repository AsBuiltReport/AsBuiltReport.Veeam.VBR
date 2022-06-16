
function Get-AbrVbrNetworkTrafficRule {
    <#
    .SYNOPSIS
    Used by As Built Report to returns network traffic rules settings created in Veeam Backup & Replication.
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
        Write-PscriboMessage "Discovering Veeam VBR network traffic rules settings information from $System."
    }

    process {
        try {
            if ((Get-VBRNetworkTrafficRule).count -gt 0) {
                Section -Style Heading4 'Network Traffic Rules' {
                    Paragraph "The following section details network traffic rules settings configured on Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    try {
                        $TrafficRules = Get-VBRNetworkTrafficRule
                        foreach ($TrafficRule in $TrafficRules) {
                            $inObj = [ordered] @{
                                'Name' = $TrafficRule.Name
                                'Source IP Start' = $TrafficRule.SourceIPStart
                                'Source IP End' = ConvertTo-EmptyToFiller $TrafficRule.SourceIPEnd
                                'Target IP Start' = $TrafficRule.TargetIPStart
                                'Target IP End' = ConvertTo-EmptyToFiller $TrafficRule.TargetIPEnd
                                'Encryption Enabled' = ConvertTo-TextYN $TrafficRule.EncryptionEnabled
                                'Throttling' = "Throttling Enabled: $(ConvertTo-TextYN $TrafficRule.ThrottlingEnabled)`r`nThrottling Unit: $($TrafficRule.ThrottlingUnit)`r`nThrottling Value: $($TrafficRule.ThrottlingValue)`r`nThrottling Windows: $(ConvertTo-TextYN $TrafficRule.ThrottlingWindowEnabled)"
                            }
                            $OutObj = [pscustomobject]$inobj

                            if ($HealthCheck.Infrastructure.Settings) {
                                $OutObj | Where-Object { $_.'Enabled' -like 'No'} | Set-Style -Style Warning -Property 'Enabled'
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
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                                Preferred Networks                                           #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        if ((Get-VBRPreferredNetwork).count -gt 0) {
                            Section -Style Heading5 'Preferred Networks' {
                                $OutObj = @()
                                try {
                                    $PreferedNetworks = Get-VBRPreferredNetwork
                                    foreach ($PreferedNetwork in $PreferedNetworks) {
                                        Write-PscriboMessage "Discovered $($PreferedNetwork.CIDRNotation) Prefered Network."
                                        $inObj = [ordered] @{
                                            'IP Address' = $PreferedNetwork.IpAddress
                                            'Subnet Mask' = $PreferedNetwork.SubnetMask
                                            'CIDR Notation' = $PreferedNetwork.CIDRNotation
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
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