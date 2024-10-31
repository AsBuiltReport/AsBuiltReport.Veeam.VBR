
function Get-AbrVbrServiceProvider {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Service Providers
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.11
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
    }

    process {
        try {
            $CloudProviders = Get-VBRCloudProvider | Sort-Object -Property 'DNSName'
            if (($VbrLicenses | Where-Object { $_.Edition -in @("EnterprisePlus") }) -and $CloudProviders) {
                Section -Style Heading3 'Service Providers' {
                    Paragraph "The following section provides a summary about configured Veeam Cloud Service Providers."
                    BlankLine
                    try {
                        $OutObj = @()
                        foreach ($CloudProvider in $CloudProviders) {
                            try {
                                Write-PScriboMessage "Discovered $($CloudProvider.DNSName) Service Provider summary information."
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
                                    'Managed By Provider' = ConvertTo-TextYN $CloudProvider.IsManagedByProvider
                                }
                                $OutObj += [pscustomobject]$inobj
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
                                                    Write-PScriboMessage "Discovered $($CloudProvider.DNSName) Service Provider general information."
                                                    $inObj = [ordered] @{
                                                        'DNS Name' = $CloudProvider.DNSName
                                                        'Ip Address' = $CloudProvider.IpAddress
                                                        'Port' = $CloudProvider.Port
                                                        'Credentials' = $CloudProvider.Credentials
                                                        'Certificate Expiration Date' = $CloudProvider.Certificate.NotAfter
                                                        'Managed By Service Provider' = ConvertTo-TextYN $CloudProvider.IsManagedByProvider
                                                        'Description' = $CloudProvider.Description
                                                    }

                                                    $OutObj = [pscustomobject]$inobj

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
                                                        Write-PScriboMessage "Discovered $($CloudProvider.DNSName) Service Provider BaaS Resources information."
                                                        $inObj = [ordered] @{
                                                            'Resources Enabled' = ConvertTo-TextYN $CloudProvider.ResourcesEnabled
                                                            'Repository Name' = $CloudProvider.Resources.RepositoryName
                                                            'Wan Acceleration?' = $CloudProvider.Resources | ForEach-Object { "$($_.RepositoryName): $(ConvertTo-TextYN $_.WanAccelerationEnabled)" }
                                                            'Per Datastore Allocated Space' = $CloudProvider.Resources | ForEach-Object { "$($_.RepositoryName): $(ConvertTo-FileSizeString -Size $_.RepositoryAllocatedSpace)" }
                                                            'Total Datastore Allocated Space' = ConvertTo-FileSizeString -Size $CloudProvider.Resources.RepositoryAllocatedSpace
                                                        }

                                                        $OutObj = [pscustomobject]$inobj

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
                                            if ($CloudProvider.ReplicationResourcesEnabled -and (-Not $CloudProvider.vCDReplicationResources)) {
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'DRaaS Resources' {
                                                        $OutObj = @()
                                                        $CPU = Switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.CPU)) {
                                                            $true { 'Unlimited' }
                                                            $false { "$([math]::Round($CloudProvider.ReplicationResources.CPU / 1000, 1)) Ghz" }
                                                            default { '--' }
                                                        }
                                                        $Memory = Switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.Memory)) {
                                                            $true { 'Unlimited' }
                                                            $false { ConvertTo-FileSizeString -Size $CloudProvider.ReplicationResources.Memory }
                                                            default { '--' }
                                                        }
                                                        Write-PScriboMessage "Discovered $($CloudProvider.DNSName) Service Provider DRaaS Resources information."
                                                        $inObj = [ordered] @{
                                                            'Resources Enabled' = ConvertTo-TextYN $CloudProvider.ReplicationResourcesEnabled
                                                            'Hardware Plan Name' = $CloudProvider.ReplicationResources.HardwarePlanName
                                                            'Allocated CPU Resources' = $CPU
                                                            'Allocated Memory Resources' = $Memory
                                                            'Repository Name' = $CloudProvider.ReplicationResources.Datastore.Name
                                                            'Per Datastore Allocated Space' = $CloudProvider.ReplicationResources.Datastore | ForEach-Object { "$($_.Name): $(ConvertTo-FileSizeString -Size $_.DatastoreAllocatedSpace)" }
                                                            'Total Datastore Allocated Space' = ConvertTo-FileSizeString -Size ($CloudProvider.ReplicationResources.Datastore.DatastoreAllocatedSpace | Measure-Object -Sum).Sum
                                                            'Network Count' = $CloudProvider.ReplicationResources.NetworkCount
                                                            'Public IP Enabled' = ConvertTo-TextYN $CloudProvider.ReplicationResources.PublicIpEnabled
                                                        }

                                                        if ($CloudProvider.ReplicationResources.PublicIpEnabled) {
                                                            $PublicIP = Switch ([string]::IsNullOrEmpty($CloudProvider.ReplicationResources.PublicIp)) {
                                                                $true { '--' }
                                                                $false { $CloudProvider.ReplicationResources.PublicIp }
                                                                default { 'Unknown' }
                                                            }
                                                            $inObj.add('Allocated Public IP Address', $PublicIP)
                                                        }

                                                        $OutObj = [pscustomobject]$inobj

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
                                                        Write-PScriboMessage "Discovered $($CloudProvider.DNSName) Service Provider vCD Resources information."
                                                        $inObj = [ordered] @{
                                                            'Resources Enabled' = ConvertTo-TextYN $CloudProvider.ReplicationResourcesEnabled
                                                            'Organizationv DC Name' = $CloudProvider.vCDReplicationResources.OrganizationvDCName
                                                            'Allocated CPU Resources' = $CloudProvider.vCDReplicationResources.CPU
                                                            'Allocated Memory Resources' = $CloudProvider.vCDReplicationResources.Memory
                                                            'Storage Policy' = $CloudProvider.vCDReplicationResources.StoragePolicy
                                                            'Is Wan Accelerator Enabled?' = ConvertTo-TextYN $CloudProvider.vCDReplicationResources.WanAcceleratorEnabled
                                                        }

                                                        $OutObj = [pscustomobject]$inobj

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
                                                if ($DefaultGatewayConfig.DefaultGateway | Where-Object {$Null -ne $_}) {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Default Gateway Configuration ' {
                                                        $OutObj = @()
                                                        foreach ($Gateway in $DefaultGatewayConfig.DefaultGateway) {
                                                            try {
                                                                Write-PScriboMessage "Discovered $($Gateway.Name) Service Provider Default Gateway Configuration information."
                                                                $inObj = [ordered] @{
                                                                    'Name' = $Gateway.Name
                                                                    'IPv4 Address' = ConvertTo-EmptyToFiller -TEXT $Gateway.IpAddress
                                                                    'Network Mask' = ConvertTo-EmptyToFiller -TEXT $Gateway.NetworkMask
                                                                    'IPv6 Address' = ConvertTo-EmptyToFiller -TEXT $Gateway.IpAddress
                                                                    'IPv6 Subnet Address' = ConvertTo-EmptyToFiller -TEXT $Gateway.Ipv6SubnetAddress
                                                                    'IPv6 Prefix Length' = ConvertTo-EmptyToFiller -TEXT $Gateway.Ipv6PrefixLength
                                                                    'Routing Enabled?' = ConvertTo-TextYN $DefaultGatewayConfig.RoutingEnabled
                                                                }

                                                                $OutObj = [pscustomobject]$inobj

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
                                                                Write-PScriboMessage "Discovered $($Gateway.Name) Service Provider Cloud SubUser Default Gateway information."
                                                                $inObj = [ordered] @{
                                                                    'Name' = $Gateway.Name
                                                                    'IPv4 Address' = ConvertTo-EmptyToFiller -TEXT $Gateway.IpAddress
                                                                    'Network Mask' = ConvertTo-EmptyToFiller -TEXT $Gateway.NetworkMask
                                                                    'IPv6 Address' = ConvertTo-EmptyToFiller -TEXT $Gateway.IpAddress
                                                                    'IPv6 Subnet Address' = ConvertTo-EmptyToFiller -TEXT $Gateway.Ipv6SubnetAddress
                                                                    'IPv6 Prefix Length' = ConvertTo-EmptyToFiller -TEXT $Gateway.Ipv6PrefixLength
                                                                    'Routing Enabled?' = ConvertTo-TextYN $CloudSubUserConfig.RoutingEnabled
                                                                }

                                                                $OutObj = [pscustomobject]$inobj

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
    end {}

}