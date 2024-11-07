
function Get-AbrVbrCloudConnectRR {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Replica Resources
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Connect Replica Resources information from $System."
    }

    process {
        if ($VbrLicenses | Where-Object { $_.CloudConnect -ne "Disabled" }) {
            if ($CloudObjects = Get-VBRCloudHardwarePlan) {
                Section -Style Heading3 'Replica Resources' {
                    Paragraph "The following table provides a summary of Replica Resources."
                    BlankLine
                    try {
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            try {
                                Write-PScriboMessage "Discovered $($CloudObject.Name) Cloud Connect Replica Resources information."
                                $inObj = [ordered] @{
                                    'Name' = $CloudObject.Name
                                    'Platform' = $CloudObject.Platform
                                    'CPU' = Switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                                        $true { 'Unlimited' }
                                        $false { "$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz" }
                                        default { '--' }
                                    }
                                    'Memory' = Switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                                        $true { 'Unlimited' }
                                        $false { ConvertTo-FileSizeString -Size $CloudObject.Memory }
                                        default { '--' }
                                    }
                                    'Storage Quota' = ConvertTo-FileSizeString -Size ($CloudObject.Datastore.Quota | Measure-Object -Sum).Sum
                                    'Network Count' = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                    'Subscribers Count' = ($CloudObject.SubscribedTenantId).count
                                }

                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Replica Resources $($CloudObject.Name) Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.CloudConnect.ReplicaResources) {
                            $OutObj | Where-Object { $_.'Subscribers Count' -eq 0 } | Set-Style -Style Warning -Property 'Subscribers Count'
                        }

                        $TableParams = @{
                            Name = "Replica Resources - $($VeeamBackupServer)"
                            List = $false
                            ColumnWidths = 26, 12, 12, 12, 12, 12, 14
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        #---------------------------------------------------------------------------------------------#
                        #                          Replica Resources Configuration Section                            #
                        #---------------------------------------------------------------------------------------------#
                        if ($InfoLevel.CloudConnect.ReplicaResources -ge 2) {
                            Section -Style Heading4 'Replica Resources Configuration' {
                                try {
                                    $OutObj = @()
                                    foreach ($CloudObject in $CloudObjects) {
                                        try {
                                            Section -Style Heading5 $CloudObject.Name {
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Host Hardware Quota' {
                                                        Write-PScriboMessage "Discovered $($CloudObject.Name) Cloud Connect Hardware Quota information."
                                                        $inObj = [ordered] @{
                                                            'Host or Cluster' = "$($CloudObject.Host.Name) ($($CloudObject.Host.Type))"
                                                            'Platform' = $CloudObject.Platform
                                                            'CPU' = Switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                                                                $true { 'Unlimited' }
                                                                $false { "$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz" }
                                                                default { '--' }
                                                            }
                                                            'Memory' = Switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                                                                $true { 'Unlimited' }
                                                                $false { ConvertTo-FileSizeString -Size $CloudObject.Memory }
                                                                default { '--' }
                                                            }
                                                            'Network Count' = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                                            'Subscribed Tenant' = Switch ([string]::IsNullOrEmpty($CloudObject.SubscribedTenantId)) {
                                                                $true { 'None' }
                                                                $false { ($CloudObject.SubscribedTenantId | ForEach-Object { Get-VBRCloudTenant -Id $_ }).Name -join ", " }
                                                                default { 'Unknown' }
                                                            }
                                                            'Description' = $CloudObject.Description
                                                        }

                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        if ($HealthCheck.CloudConnect.ReplicaResources) {
                                                            $OutObj | Where-Object { $_.'Subscribed Tenant' -eq 'None' } | Set-Style -Style Warning -Property 'Subscribed Tenant'
                                                        }

                                                        $TableParams = @{
                                                            Name = "Host Hardware Quota - $($CloudObject.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Host Hardware Quota $($CloudObject.Host.Name) Section: $($_.Exception.Message)"
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Storage Quota' {
                                                        $OutObj = @()
                                                        Write-PScriboMessage "Discovered $($CloudObject.Name) Cloud Connect Storage Quota information."
                                                        foreach ($Storage in $CloudObject.Datastore) {
                                                            $inObj = [ordered] @{
                                                                'Datastore Name' = $Storage.Datastore
                                                                'Friendly Name' = $Storage.FriendlyName
                                                                'Platform' = $Storage.Platform
                                                                'Storage Quota' = ConvertTo-FileSizeString -Size $Storage.Quota
                                                                'Storage Policy' = Switch ([string]::IsNullOrEmpty($Storage.StoragePolicy.Name)) {
                                                                    $true { '--' }
                                                                    $false { $Storage.StoragePolicy.Name }
                                                                    default { 'Unknown' }
                                                                }
                                                            }

                                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "Storage Quota - $($Storage.Datastore)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }

                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Storage Quota $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Network Quota' {
                                                        $OutObj = @()
                                                        $VlanConfiguration = Get-VBRCloudVLANConfiguration | Where-Object { $_.Host.Name -eq $CloudObject.Host.Name }
                                                        Write-PScriboMessage "Discovered $($CloudObject.Name) Cloud Connect Network Quota information."
                                                        $inObj = [ordered] @{
                                                            'Specify number of networks with Internet Access' = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                                            'Specify number of internal networks' = $CloudObject.NumberOfNetWithoutInternet
                                                        }

                                                        if ($VlanConfiguration) {
                                                            $inObj.add('Host or Cluster', "$($VlanConfiguration.Host.Name) ($($VlanConfiguration.Host.Type))")
                                                            $inObj.add('Platform', $VlanConfiguration.Platform)
                                                            $inObj.add('Virtual Switch', $VlanConfiguration.VirtualSwitch)
                                                            $inObj.add('VLANs With Internet', "$($VlanConfiguration.FirstVLANWithInternet) - $($VlanConfiguration.LastVLANWithInternet)")
                                                            $inObj.add('VLANs Without Internet', "$($VlanConfiguration.FirstVLANWithoutInternet) - $($VlanConfiguration.LastVLANWithoutInternet)")
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "Network Quota - $($CloudObject.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Network Quota $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                                try {
                                                    $Tenants = Get-VBRCloudTenant | Where-Object { $_.ReplicationResources.HardwarePlanOptions.HardwarePlanId -eq $CloudObject.Id }
                                                    $TenantHardwarePlan = @()
                                                    foreach ($Tenant in $Tenants) {
                                                        $planOption = $Tenant.ReplicationResources.HardwarePlanOptions | Where-Object { $_.HardwarePlanId -eq $CloudObject.Id }
                                                        $TenantHardwarePlan += $Tenant | Select-Object Name, @{n = 'CPUUsage'; e = { $planOption.UsedCPU } }, @{n = 'MemoryUsage'; e = { $planOption.UsedMemory } }, @{n = 'StorageUsage'; e = { $planOption.DatastoreQuota } }
                                                    }
                                                    if ($TenantHardwarePlan) {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 'Tenant Utilization' {
                                                            $OutObj = @()
                                                            foreach ($TenantUtil in $TenantHardwarePlan) {
                                                                $inObj = [ordered] @{
                                                                    'Name' = $TenantUtil.Name
                                                                    'CPU Usage' = $TenantUtil.CPUUsage
                                                                    'Memory Usage' = $TenantUtil.MemoryUsage
                                                                    'Storage Usage' = $TenantUtil.StorageUsage | ForEach-Object { "$(ConvertTo-FileSizeString -Size $_.UsedSpace) ($($_.FriendlyName))" }
                                                                }

                                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                            }

                                                            $TableParams = @{
                                                                Name = "Tenant Utilization - $($CloudObject.Name)"
                                                                List = $false
                                                                ColumnWidths = 25, 25, 25, 25
                                                            }

                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Tenant Utilization $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Replica Resources Configuration $($CloudObject.Name) Section: $($_.Exception.Message)"
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Replica Resources Configuration Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Replica Resources Section: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    end {}

}