
function Get-AbrVbrNetworkTrafficRule {
    <#
    .SYNOPSIS
    Used by As Built Report to returns network traffic rules settings created in Veeam Backup & Replication.


    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR network traffic rules settings information from $System."
    }

    process {
        Section -Style Heading4 'Network Traffic Rules' {
            Paragraph "The following section returns network traffic rules settings configured on Veeam Backup & Replication."
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
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
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                if ($HealthCheck.Infrastructure.Settings) {
                    $OutObj | Where-Object { $_.'Enabled' -like 'No'} | Set-Style -Style Warning -Property 'Enabled'
                }

                $TableParams = @{
                    Name = "Network Traffic Rules Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                try {
                    if (Get-VBRPreferredNetwork) {
                        Section -Style Heading5 'Preferred Networks' {
                            Paragraph "The following section returns configured preferred networks on Backup Server"
                            BlankLine
                            $OutObj = @()
                            if ((Get-VBRServerSession).Server) {
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
                                    Name = "Preferred Networks Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
            }
        }
    }
    end {}

}