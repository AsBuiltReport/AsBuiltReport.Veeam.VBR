
function Get-AbrVbrServiceProvider {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Service Providers
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.24
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
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Service Providers'
    }

    process {
        try {
            $CloudProviders = Get-VBRCloudProvider | Sort-Object -Property 'DNSName'
            if (($VbrLicenses | Where-Object { $_.Edition -in @('EnterprisePlus') }) -and $CloudProviders) {
                Section -Style Heading3 'Service Providers' {
                    Paragraph 'The following section provides a summary of all Veeam Cloud Service Providers (VCSPs) configured as replication or backup targets in Veeam Backup & Replication.'
                    BlankLine
                    try {
                        $OutObj = @()
                        foreach ($CloudProvider in $CloudProviders) {
                            try {

                                $inObj = [ordered] @{
                                    'DNS Name' = $CloudProvider.DNSName
                                    'Cloud Connect Type' = & {
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
                                    'Managed By Provider' = $CloudProvider.IsManagedByProvider
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Service Providers $($CloudProvider.DNSName) Table: $($_.Exception.Message)"
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
                        $OutObj | Table @TableParams
                        if ($InfoLevel.Infrastructure.ServiceProvider -ge 2) {
                            try {
                                Section -Style Heading4 'Service Providers Configuration' {
                                    foreach ($CloudProvider in $CloudProviders) {
                                        Section -Style Heading5 $CloudProvider.DNSName {
                                            try {
                                                Section -ExcludeFromTOC -Style NOTOCHeading6 'General Information' {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        'DNS Name' = $CloudProvider.DNSName
                                                        'Ip Address' = $CloudProvider.IpAddress
                                                        'Port' = $CloudProvider.Port
                                                        'Credentials' = $CloudProvider.Credentials
                                                        'Certificate Expiration Date' = $CloudProvider.Certificate.NotAfter
                                                        'Managed By Service Provider' = $CloudProvider.IsManagedByProvider
                                                        'Description' = $CloudProvider.Description
                                                    }

                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "General Information - $($CloudProvider.DNSName)"
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
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'BaaS Resources' {
                                                        $OutObj = @()

                                                        $inObj = [ordered] @{
                                                            'Resources Enabled' = $CloudProvider.ResourcesEnabled
                                                            'Repository Name' = $CloudProvider.Resources.RepositoryName
                                                            'Wan Acceleration?' = $CloudProvider.Resources | ForEach-Object { "$($_.RepositoryName): $($_.WanAccelerationEnabled)" }
                                                            'Per Datastore Allocated Space' = $CloudProvider.Resources | ForEach-Object { "$($_.RepositoryName): $(ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $_.RepositoryAllocatedSpace)" }
                                                            'Total Datastore Allocated Space' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CloudProvider.Resources.RepositoryAllocatedSpace
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "BaaS Resources - $($CloudProvider.DNSName)"
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
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'DRaaS Resources' {
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
                                                            'Resources Enabled' = $CloudProvider.ReplicationResourcesEnabled
                                                            'Hardware Plan Name' = $CloudProvider.ReplicationResources.HardwarePlanName
                                                            'Allocated CPU Resources' = $CPU
                                                            'Allocated Memory Resources' = $Memory
                                                            'Repository Name' = $CloudProvider.ReplicationResources.Datastore.Name
                                                            'Per Datastore Allocated Space' = $CloudProvider.ReplicationResources.Datastore | ForEach-Object { "$($_.Name): $(ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $_.DatastoreAllocatedSpace)" }
                                                            'Total Datastore Allocated Space' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size ($CloudProvider.ReplicationResources.Datastore.DatastoreAllocatedSpace | Measure-Object -Sum).Sum
                                                            'Network Count' = $CloudProvider.ReplicationResources.NetworkCount
                                                            'Public IP Enabled' = $CloudProvider.ReplicationResources.PublicIpEnabled
                                                        }

                                                        if ($CloudProvider.ReplicationResources.PublicIpEnabled) {
                                                            $PublicIP = switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.PublicIp)) {
                                                                $true { '--' }
                                                                $false { $CloudProvider.ReplicationResources.PublicIp }
                                                                default { 'Unknown' }
                                                            }
                                                            $inObj.add('Allocated Public IP Address', $PublicIP)
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "DRaaS Resources - $($CloudProvider.DNSName)"
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
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'vCD Resources' {
                                                        $OutObj = @()

                                                        $inObj = [ordered] @{
                                                            'Resources Enabled' = $CloudProvider.ReplicationResourcesEnabled
                                                            'Organizationv DC Name' = $CloudProvider.vCDReplicationResources.OrganizationvDCName
                                                            'Allocated CPU Resources' = $CloudProvider.vCDReplicationResources.CPU
                                                            'Allocated Memory Resources' = $CloudProvider.vCDReplicationResources.Memory
                                                            'Storage Policy' = $CloudProvider.vCDReplicationResources.StoragePolicy
                                                            'Is Wan Accelerator Enabled?' = $CloudProvider.vCDReplicationResources.WanAcceleratorEnabled
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "vCD Resources - $($CloudProvider.DNSName)"
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
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Default Gateway Configuration ' {
                                                        $OutObj = @()
                                                        foreach ($Gateway in $DefaultGatewayConfig.DefaultGateway) {
                                                            try {

                                                                $inObj = [ordered] @{
                                                                    'Name' = $Gateway.Name
                                                                    'IPv4 Address' = $Gateway.IpAddress
                                                                    'Network Mask' = $Gateway.NetworkMask
                                                                    'IPv6 Address' = $Gateway.IpAddress
                                                                    'IPv6 Subnet Address' = $Gateway.Ipv6SubnetAddress
                                                                    'IPv6 Prefix Length' = $Gateway.Ipv6PrefixLength
                                                                    'Routing Enabled?' = $DefaultGatewayConfig.RoutingEnabled
                                                                }

                                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                $TableParams = @{
                                                                    Name = "Default Gateway Configuration - $($Gateway.Name)"
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
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Cloud SubUser Default Gateway' {
                                                        $OutObj = @()
                                                        foreach ($Gateway in $CloudSubUserConfig.DefaultGateway) {
                                                            try {

                                                                $inObj = [ordered] @{
                                                                    'Name' = $Gateway.Name
                                                                    'IPv4 Address' = $Gateway.IpAddress
                                                                    'Network Mask' = $Gateway.NetworkMask
                                                                    'IPv6 Address' = $Gateway.IpAddress
                                                                    'IPv6 Subnet Address' = $Gateway.Ipv6SubnetAddress
                                                                    'IPv6 Prefix Length' = $Gateway.Ipv6PrefixLength
                                                                    'Routing Enabled?' = $CloudSubUserConfig.RoutingEnabled
                                                                }

                                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                $TableParams = @{
                                                                    Name = "Cloud SubUser Default Gateway - $($Gateway.Name)"
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