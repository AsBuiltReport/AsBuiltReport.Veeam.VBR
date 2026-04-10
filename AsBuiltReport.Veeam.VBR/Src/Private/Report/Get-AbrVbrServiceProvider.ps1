
function Get-AbrVbrServiceProvider {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Service Providers
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Service Providers information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrServiceProvider
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Service Providers'
    }

    process {
        try {
            $CloudProviders = Get-VBRCloudProvider | Sort-Object -Property 'DNSName'
            if (($VbrLicenses | Where-Object { $_.Edition -in @('EnterprisePlus') }) -and $CloudProviders) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    try {
                        $OutObj = @()
                        foreach ($CloudProvider in $CloudProviders) {
                            try {

                                $inObj = [ordered] @{
                                    $LocalizedData.DNSName = $CloudProvider.DNSName
                                    $LocalizedData.CloudConnectType = & {
                                        if ($CloudProvider.ResourcesEnabled -and $CloudProvider.ReplicationResourcesEnabled) {
                                            'BaaS & DRaaS'
                                        } elseif ($CloudProvider.ResourcesEnabled) {
                                            'BaaS'
                                        } elseif ($CloudProvider.ReplicationResourcesEnabled) {
                                            'DRaas'
                                        } elseif ($CloudProvider.vCDReplicationResources) {
                                            'vCD'
                                        } else { 'Unknown' }
                                    }
                                    $LocalizedData.ManagedByProvider = $CloudProvider.IsManagedByProvider
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) Table: $($_.Exception.Message)"
                            }
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
                        if ($InfoLevel.Infrastructure.ServiceProvider -ge 2) {
                            try {
                                Section -Style Heading4 $LocalizedData.ConfigHeading {
                                    foreach ($CloudProvider in $CloudProviders) {
                                        Section -Style Heading5 $CloudProvider.DNSName {
                                            try {
                                                Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.GeneralInfoHeading {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.DNSName = $CloudProvider.DNSName
                                                        $LocalizedData.IpAddress = $CloudProvider.IpAddress
                                                        $LocalizedData.Port = $CloudProvider.Port
                                                        $LocalizedData.Credentials = $CloudProvider.Credentials
                                                        $LocalizedData.CertificateExpDate = $CloudProvider.Certificate.NotAfter
                                                        $LocalizedData.ManagedByServiceProvider = $CloudProvider.IsManagedByProvider
                                                        $LocalizedData.Description = $CloudProvider.Description
                                                    }

                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.GeneralInfoHeading) - $($CloudProvider.DNSName)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) General Information Table: $($_.Exception.Message)"
                                            }
                                            if ($CloudProvider.ResourcesEnabled) {
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.BaaSResourcesHeading {
                                                        $OutObj = @()

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.ResourcesEnabled = $CloudProvider.ResourcesEnabled
                                                            $LocalizedData.RepositoryName = $CloudProvider.Resources.RepositoryName
                                                            $LocalizedData.WanAcceleration = $CloudProvider.Resources | ForEach-Object { "$($_.RepositoryName): $($_.WanAccelerationEnabled)" }
                                                            $LocalizedData.PerDatastoreAllocatedSpace = $CloudProvider.Resources | ForEach-Object { "$($_.RepositoryName): $(ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $_.RepositoryAllocatedSpace)" }
                                                            $LocalizedData.TotalDatastoreAllocatedSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CloudProvider.Resources.RepositoryAllocatedSpace
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.BaaSResourcesHeading) - $($CloudProvider.DNSName)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) BaaS Resources Table: $($_.Exception.Message)"
                                                }
                                            }
                                            if ($CloudProvider.ReplicationResourcesEnabled -and (-not $CloudProvider.vCDReplicationResources)) {
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.DRaaSResourcesHeading {
                                                        $OutObj = @()
                                                        $CPU = switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.CPU)) {
                                                            $true { 'Unlimited' }
                                                            $false { "$([math]::Round($CloudProvider.ReplicationResources.CPU / 1000, 1)) Ghz" }
                                                            default { '--' }
                                                        }
                                                        $Memory = switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.Memory)) {
                                                            $true { 'Unlimited' }
                                                            $false { ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CloudProvider.ReplicationResources.Memory }
                                                            default { '--' }
                                                        }

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.ResourcesEnabled = $CloudProvider.ReplicationResourcesEnabled
                                                            $LocalizedData.HardwarePlanName = $CloudProvider.ReplicationResources.HardwarePlanName
                                                            $LocalizedData.AllocatedCPUResources = $CPU
                                                            $LocalizedData.AllocatedMemoryResources = $Memory
                                                            $LocalizedData.RepositoryName = $CloudProvider.ReplicationResources.Datastore.Name
                                                            $LocalizedData.PerDatastoreAllocatedSpace = $CloudProvider.ReplicationResources.Datastore | ForEach-Object { "$($_.Name): $(ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $_.DatastoreAllocatedSpace)" }
                                                            $LocalizedData.TotalDatastoreAllocatedSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size ($CloudProvider.ReplicationResources.Datastore.DatastoreAllocatedSpace | Measure-Object -Sum).Sum
                                                            $LocalizedData.NetworkCount = $CloudProvider.ReplicationResources.NetworkCount
                                                            $LocalizedData.PublicIPEnabled = $CloudProvider.ReplicationResources.PublicIpEnabled
                                                        }

                                                        if ($CloudProvider.ReplicationResources.PublicIpEnabled) {
                                                            $PublicIP = switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.PublicIp)) {
                                                                $true { '--' }
                                                                $false { $CloudProvider.ReplicationResources.PublicIp }
                                                                default { 'Unknown' }
                                                            }
                                                            $inObj.add($LocalizedData.AllocatedPublicIPAddress, $PublicIP)
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.DRaaSResourcesHeading) - $($CloudProvider.DNSName)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) DRaaS Resources Table: $($_.Exception.Message)"
                                                }
                                            }
                                            if ($CloudProvider.vCDReplicationResources) {
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.vCDResourcesHeading {
                                                        $OutObj = @()

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.ResourcesEnabled = $CloudProvider.ReplicationResourcesEnabled
                                                            $LocalizedData.OrgvDCName = $CloudProvider.vCDReplicationResources.OrganizationvDCName
                                                            $LocalizedData.AllocatedCPUResources = $CloudProvider.vCDReplicationResources.CPU
                                                            $LocalizedData.AllocatedMemoryResources = $CloudProvider.vCDReplicationResources.Memory
                                                            $LocalizedData.StoragePolicy = $CloudProvider.vCDReplicationResources.StoragePolicy
                                                            $LocalizedData.IsWanAcceleratorEnabled = $CloudProvider.vCDReplicationResources.WanAcceleratorEnabled
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.vCDResourcesHeading) - $($CloudProvider.DNSName)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) vCD Resources Table: $($_.Exception.Message)"
                                                }
                                            }
                                            try {
                                                $DefaultGatewayConfig = Get-VBRDefaultGatewayConfiguration -CloudProvider $CloudProvider | Sort-Object -Property Name
                                                if ($DefaultGatewayConfig.DefaultGateway | Where-Object { $Null -ne $_ }) {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.DefaultGatewayHeading {
                                                        $OutObj = @()
                                                        foreach ($Gateway in $DefaultGatewayConfig.DefaultGateway) {
                                                            try {

                                                                $inObj = [ordered] @{
                                                                    $LocalizedData.Name = $Gateway.Name
                                                                    $LocalizedData.IPv4Address = $Gateway.IpAddress
                                                                    $LocalizedData.NetworkMask = $Gateway.NetworkMask
                                                                    $LocalizedData.IPv6Address = $Gateway.IpAddress
                                                                    $LocalizedData.IPv6SubnetAddress = $Gateway.Ipv6SubnetAddress
                                                                    $LocalizedData.IPv6PrefixLength = $Gateway.Ipv6PrefixLength
                                                                    $LocalizedData.RoutingEnabled = $DefaultGatewayConfig.RoutingEnabled
                                                                }

                                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                $TableParams = @{
                                                                    Name = "$($LocalizedData.DefaultGatewayHeading) - $($Gateway.Name)"
                                                                    List = $true
                                                                    ColumnWidths = 40, 60
                                                                }

                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                $OutObj | Table @TableParams
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) Default Gateway Configuration Table: $($_.Exception.Message)"
                                                            }
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) Default Gateway Section: $($_.Exception.Message)"
                                            }
                                            try {
                                                $CloudSubUserConfig = Get-VBRCloudSubUser -CloudProvider $CloudProvider | Sort-Object -Property Name
                                                if ($CloudSubUserConfig.DefaultGateway) {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.CloudSubUserGatewayHeading {
                                                        $OutObj = @()
                                                        foreach ($Gateway in $CloudSubUserConfig.DefaultGateway) {
                                                            try {

                                                                $inObj = [ordered] @{
                                                                    $LocalizedData.Name = $Gateway.Name
                                                                    $LocalizedData.IPv4Address = $Gateway.IpAddress
                                                                    $LocalizedData.NetworkMask = $Gateway.NetworkMask
                                                                    $LocalizedData.IPv6Address = $Gateway.IpAddress
                                                                    $LocalizedData.IPv6SubnetAddress = $Gateway.Ipv6SubnetAddress
                                                                    $LocalizedData.IPv6PrefixLength = $Gateway.Ipv6PrefixLength
                                                                    $LocalizedData.RoutingEnabled = $CloudSubUserConfig.RoutingEnabled
                                                                }

                                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                $TableParams = @{
                                                                    Name = "$($LocalizedData.CloudSubUserGatewayHeading) - $($Gateway.Name)"
                                                                    List = $true
                                                                    ColumnWidths = 40, 60
                                                                }

                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                $OutObj | Table @TableParams
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) Cloud SubUser Cloud SubUser Default Gateway Table: $($_.Exception.Message)"
                                                            }
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) Cloud SubUser Default Gateway Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Service Providers Configuration Section: $($_.Exception.Message)"
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Service Providers Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Service Providers Document: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Service Providers'
    }

}