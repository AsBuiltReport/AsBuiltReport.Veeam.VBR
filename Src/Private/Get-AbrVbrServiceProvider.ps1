
function Get-AbrVbrServiceProvider {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Service Providers
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.0
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Service Providers information from $System."
    }

    process {
        try {
            if ((Get-VBRInstalledLicense | Where-Object {$_.Edition -in @("EnterprisePlus")}) -and (Get-VBRCloudProvider).count -gt 0) {
                Section -Style Heading3 'Service Providers' {
                    Paragraph "The following section provides a summary about configured Veeam Cloud Service Providers."
                    BlankLine
                    try {
                        $CloudProviders = Get-VBRCloudProvider
                        $OutObj = @()
                        foreach ($CloudProvider in $CloudProviders) {
                            try {
                                Write-PscriboMessage "Discovered $($CloudProvider.DNSName) Service Provider summary information."
                                if ($CloudProvider.ResourcesEnabled) {
                                    $WanAcceleration = $CloudProvider.Resources.WanAccelerationEnabled
                                }
                                elseif ($CloudProvider.ReplicationResourcesEnabled) {
                                    $WanAcceleration = $CloudProvider.ReplicationResources.WanAcceleratorEnabled
                                }

                                if ($CloudProvider.ResourcesEnabled) {
                                    $VCCType = 'Cloud Repositories'
                                }
                                elseif ($CloudProvider.ReplicationResourcesEnabled) {
                                    $VCCType = 'Replication Resources'
                                }

                                $inObj = [ordered] @{
                                    'DNS Name' = $CloudProvider.DNSName
                                    'Cloud Connect Type' = $VCCType
                                    'Wan Acceleration' = ConvertTo-TextYN $WanAcceleration
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Service Providers - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 35, 35, 30
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'DNS Name' | Table @TableParams
                        if ($InfoLevel.Infrastructure.ServiceProvider -ge 2) {
                            try {
                                Section -Style Heading4 'Service Providers Configuration' {
                                    foreach ($CloudProvider in $CloudProviders) {
                                        Section -Style Heading5 $CloudProvider.DNSName {
                                            $OutObj = @()
                                            Write-PscriboMessage "Discovered $($CloudProvider.DNSName) Service Provider configuration information."
                                            $inObj = [ordered] @{
                                                'DNS Name' = $CloudProvider.DNSName
                                                'Ip Address' = $CloudProvider.IpAddress
                                                'Port' = $CloudProvider.Port
                                                'Credentials' = $CloudProvider.Credentials
                                                'Certificate Expiration Date' = $CloudProvider.Certificate.NotAfter
                                                'Managed By Service Provider' = ConvertTo-TextYN $CloudProvider.IsManagedByProvider
                                            }
                                            if ($CloudProvider.ResourcesEnabled) {
                                                $inObj.add('BaaS Resources Enabled', (ConvertTo-TextYN $CloudProvider.ResourcesEnabled))
                                                $inObj.add('BaaS Repository Name', $CloudProvider.Resources.RepositoryName)
                                                $inObj.add('BaaS Datastore Resources', "$([Math]::Round(($CloudProvider.Resources.RepositoryAllocatedSpace | measure-object -Sum).Sum / 1024)) GB")
                                            }

                                            if ($CloudProvider.ReplicationResourcesEnabled) {
                                                $CPU = Switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.CPU)) {
                                                    $true {'Unlimited'}
                                                    $false {"$([math]::Round($CloudProvider.ReplicationResources.CPU / 1000, 1)) Ghz"}
                                                    default {'-'}
                                                }
                                                $Memory = Switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.Memory)) {
                                                    $true {'Unlimited'}
                                                    $false {"$([math]::Round($CloudProvider.ReplicationResources.Memory / 1Kb, 2)) GB"}
                                                    default {'-'}
                                                }
                                                $inObj.add('DRaaS Replication Enabled', (ConvertTo-TextYN $CloudProvider.ReplicationResourcesEnabled))
                                                $inObj.add('Hardware Plan Name', $CloudProvider.ReplicationResources.HardwarePlanName)
                                                $inObj.add('Allocated CPU Resources', $CPU)
                                                $inObj.add('Allocated Memory Resources', $Memory)
                                                $inObj.add('DRaaS Datastore Resources', "$([Math]::Round(($CloudProvider.ReplicationResources.Datastore.DatastoreAllocatedSpace | measure-object -Sum).Sum)) GB")
                                                $inObj.add('Network Count', $CloudProvider.ReplicationResources.NetworkCount)
                                                $inObj.add('Public IP Enabled', (ConvertTo-TextYN $CloudProvider.ReplicationResources.PublicIpEnabled))
                                                if ($CloudProvider.ReplicationResources.PublicIpEnabled) {
                                                    $PublicIP = Switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.PublicIp)) {
                                                        $true {'-'}
                                                        $false {$CloudProvider.ReplicationResources.PublicIp}
                                                        default {'Unknown'}
                                                    }
                                                    $inObj.add('Allocated Public IP', $PublicIP)
                                                }
                                            }

                                            $inObj.add('Description', $CloudProvider.Description)


                                            $OutObj = [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Cloud Service Providers - $($CloudProvider.DNSName)"
                                                List = $true
                                                ColumnWidths = 40, 60
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