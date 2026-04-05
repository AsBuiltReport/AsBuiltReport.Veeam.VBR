
function Get-AbrVbrCloudConnectRR {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Replica Resources
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Connect Replica Resources information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCloudConnectRR
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Cloud Connect Replica Resources'
    }

    process {
        if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' }) {
            if ($CloudObjects = Get-VBRCloudHardwarePlan | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    try {
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            try {

                                $inObj = [ordered] @{
                                    $LocalizedData.Name = $CloudObject.Name
                                    $LocalizedData.Platform = $CloudObject.Platform
                                    $LocalizedData.CPU = switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                                        $true { $LocalizedData.Unlimited }
                                        $false { "$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz" }
                                        default { $LocalizedData.Dash }
                                    }
                                    $LocalizedData.Memory = switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                                        $true { $LocalizedData.Unlimited }
                                        $false { ConvertTo-FileSizeString -Size (Convert-Size -From MB -To Bytes -Value $CloudObject.Memory) -RoundUnits $Options.RoundUnits }
                                        default { $LocalizedData.Dash }
                                    }
                                    $LocalizedData.StorageQuota = ConvertTo-FileSizeString -Size (Convert-Size -From GB -To Bytes -Value ($CloudObject.Datastore.Quota | Measure-Object -Sum).Sum) -RoundUnits $Options.RoundUnits
                                    $LocalizedData.NetworkCount = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                    $LocalizedData.SubscribersCount = ($CloudObject.SubscribedTenantId).count
                                }

                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Replica Resources $($CloudObject.Name) Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.CloudConnect.ReplicaResources) {
                            $OutObj | Where-Object { $_.$($LocalizedData.SubscribersCount) -eq 0 } | Set-Style -Style Warning -Property $LocalizedData.SubscribersCount
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $($VeeamBackupServer)"
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
                            Section -Style Heading4 $LocalizedData.ConfigHeading {
                                try {
                                    $OutObj = @()
                                    foreach ($CloudObject in $CloudObjects) {
                                        try {
                                            Section -Style Heading5 $CloudObject.Name {
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.HostHardwareQuotaHeading {

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.HostOrCluster = "$($CloudObject.Host.Name) ($($CloudObject.Host.Type))"
                                                            $LocalizedData.Platform = $CloudObject.Platform
                                                            $LocalizedData.CPU = switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                                                                $true { $LocalizedData.Unlimited }
                                                                $false { "$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz" }
                                                                default { $LocalizedData.Dash }
                                                            }
                                                            $LocalizedData.Memory = switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                                                                $true { $LocalizedData.Unlimited }
                                                                $false { ConvertTo-FileSizeString -Size (Convert-Size -From MB -To Bytes -Value $CloudObject.Memory) -RoundUnits $Options.RoundUnits }
                                                                default { $LocalizedData.Dash }
                                                            }
                                                            $LocalizedData.NetworkCount = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                                            $LocalizedData.SubscribedTenant = switch ([string]::IsNullOrEmpty($CloudObject.SubscribedTenantId)) {
                                                                $true { $LocalizedData.None }
                                                                $false { ($CloudObject.SubscribedTenantId | ForEach-Object { Get-VBRCloudTenant -Id $_ }).Name -join ', ' }
                                                                default { $LocalizedData.Unknown }
                                                            }
                                                            $LocalizedData.Description = $CloudObject.Description
                                                        }

                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        if ($HealthCheck.CloudConnect.ReplicaResources) {
                                                            $OutObj | Where-Object { $_.$($LocalizedData.SubscribedTenant) -eq $LocalizedData.None } | Set-Style -Style Warning -Property $LocalizedData.SubscribedTenant
                                                        }

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHostHardwareQuota) - $($CloudObject.Name)"
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
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.StorageQuotaHeading {
                                                        $OutObj = @()

                                                        foreach ($Storage in $CloudObject.Datastore) {
                                                            $inObj = [ordered] @{
                                                                $LocalizedData.DatastoreName = $Storage.Datastore
                                                                $LocalizedData.FriendlyName = $Storage.FriendlyName
                                                                $LocalizedData.Platform = $Storage.Platform
                                                                $LocalizedData.StorageQuota = ConvertTo-FileSizeString -Size (Convert-Size -From GB -To Bytes -Value $Storage.Quota) -RoundUnits $Options.RoundUnits
                                                                $LocalizedData.StoragePolicyCol = switch ([string]::IsNullOrEmpty($Storage.StoragePolicy.Name)) {
                                                                    $true { $LocalizedData.Dash }
                                                                    $false { $Storage.StoragePolicy.Name }
                                                                    default { $LocalizedData.Unknown }
                                                                }
                                                            }

                                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "$($LocalizedData.TableStorageQuota) - $($Storage.Datastore)"
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
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.NetworkQuotaHeading {
                                                        $OutObj = @()
                                                        $VlanConfiguration = Get-VBRCloudVLANConfiguration | Where-Object { $_.Host.Name -eq $CloudObject.Host.Name }

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.SpecifyNetworksWithInternet = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                                            $LocalizedData.SpecifyInternalNetworks = $CloudObject.NumberOfNetWithoutInternet
                                                        }

                                                        if ($VlanConfiguration) {
                                                            $inObj.add($LocalizedData.HostOrCluster, "$($VlanConfiguration.Host.Name) ($($VlanConfiguration.Host.Type))")
                                                            $inObj.add($LocalizedData.Platform, $VlanConfiguration.Platform)
                                                            $inObj.add($LocalizedData.VirtualSwitch, $VlanConfiguration.VirtualSwitch)
                                                            $inObj.add($LocalizedData.VLANsWithInternet, "$($VlanConfiguration.FirstVLANWithInternet) - $($VlanConfiguration.LastVLANWithInternet)")
                                                            $inObj.add($LocalizedData.VLANsWithoutInternet, "$($VlanConfiguration.FirstVLANWithoutInternet) - $($VlanConfiguration.LastVLANWithoutInternet)")
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableNetworkQuota) - $($CloudObject.Name)"
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
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.TenantUtilizationHeading {
                                                            $OutObj = @()
                                                            foreach ($TenantUtil in $TenantHardwarePlan) {
                                                                $inObj = [ordered] @{
                                                                    $LocalizedData.Name = $TenantUtil.Name
                                                                    $LocalizedData.CPUUsage = $TenantUtil.CPUUsage
                                                                    $LocalizedData.MemoryUsage = $TenantUtil.MemoryUsage
                                                                    $LocalizedData.StorageUsage = $TenantUtil.StorageUsage | ForEach-Object { "$(ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $_.UsedSpace) ($($_.FriendlyName))" }
                                                                }

                                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                            }

                                                            $TableParams = @{
                                                                Name = "$($LocalizedData.TableTenantUtilization) - $($CloudObject.Name)"
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
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Cloud Connect Replica Resources'
    }

}