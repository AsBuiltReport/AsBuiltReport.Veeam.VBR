
function Get-AbrVbrCloudConnectReplica {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Replicas
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Connect Replicas information from $System."
    }

    process {
        try {
            if (Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -in @("Enterprise")}) {
                if ((Get-VBRCloudHardwarePlan).count -gt 0) {
                    Section -Style Heading3 'Replicas' {
                        Paragraph "The following table provides a summary of Replicas."
                        BlankLine
                        try {
                            $CloudObjects = Get-VBRCloudHardwarePlan
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {
                                    Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Connect Replica Resources information."
                                    $inObj = [ordered] @{
                                        'Name' = $CloudObject.Name
                                        'Platform' = $CloudObject.Platform
                                        'CPU' = Switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                                            $true {'Unlimited'}
                                            $false {"$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz"}
                                            default {'-'}
                                        }
                                        'Memory' = Switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                                            $true {'Unlimited'}
                                            $false {"$([math]::Round($CloudObject.Memory / 1Kb, 2)) GB"}
                                            default {'-'}
                                        }
                                        'Storage Quota' = "$(($CloudObject.Datastore.Quota | Measure-Object -Sum).Sum) GB"
                                        'Network Count' = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                        'Subscribers' = ($CloudObject.SubscribedTenantId).count
                                    }

                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            if ($HealthCheck.CloudConnect.ReplicaResources) {
                                $OutObj | Where-Object { $_.'Subscribers' -eq 0} | Set-Style -Style Warning -Property 'Subscribers'
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
                            Section -Style Heading4 'Replica Resources Configuration' {
                                try {
                                    $OutObj = @()
                                    foreach ($CloudObject in $CloudObjects) {
                                        try {
                                            Section -Style Heading5 $CloudObject.Name {
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Host Hardware Quota' {
                                                        Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Connect Hardware Quota information."
                                                        $inObj = [ordered] @{
                                                            'Host or Cluster' = "$($CloudObject.Host.Name) ($($CloudObject.Host.Type))"
                                                            'Platform' = $CloudObject.Platform
                                                            'CPU' = Switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                                                                $true {'Unlimited'}
                                                                $false {"$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz"}
                                                                default {'-'}
                                                            }
                                                            'Memory' = Switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                                                                $true {'Unlimited'}
                                                                $false {"$([math]::Round($CloudObject.Memory / 1Kb, 2)) GB"}
                                                                default {'-'}
                                                            }
                                                            'Network Count' = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                                            'Subscribed Tenant' = Switch ([string]::IsNullOrEmpty($CloudObject.SubscribedTenantId)) {
                                                                $true {'None'}
                                                                $false {($CloudObject.SubscribedTenantId | ForEach-Object {Get-VBRCloudTenant -Id $_}).Name}
                                                                default {'Unknown'}
                                                            }
                                                            'Description' = $CloudObject.Description
                                                        }

                                                        $OutObj += [pscustomobject]$inobj

                                                        if ($HealthCheck.CloudConnect.ReplicaResources) {
                                                            $OutObj | Where-Object {$_.'Subscribed Tenant' -eq 'None'} | Set-Style -Style Warning -Property 'Subscribed Tenant'
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
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Storage Quota' {
                                                        $OutObj = @()
                                                        Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Connect Storage Quota information."
                                                        foreach ($Storage in $CloudObject.Datastore) {
                                                            $inObj = [ordered] @{
                                                                'Datastore Name' = $Storage.Datastore
                                                                'Friendly Name' = $Storage.FriendlyName
                                                                'Platform' = $Storage.Platform
                                                                'Storage Quota' = "$($Storage.Quota)GB"
                                                                'Storage Policy' = Switch ([string]::IsNullOrEmpty($Storage.StoragePolicy.Name)) {
                                                                    $true {'-'}
                                                                    $false {$Storage.StoragePolicy.Name}
                                                                    default {'Unknown'}
                                                                }
                                                            }

                                                            $OutObj = [pscustomobject]$inobj

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
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Network Quota' {
                                                        $OutObj = @()
                                                        $VlanConfiguration = Get-VBRCloudVLANConfiguration | Where-Object {$_.Host.Name -eq $CloudObject.Host.Name}
                                                        Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Connect Network Quota information."
                                                        $inObj = [ordered] @{
                                                            'Specify number of networks with Internet Access' = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                                            'Specify number of internal networks' = $CloudObject.NumberOfNetWithoutInternet
                                                        }

                                                        if ($VlanConfiguration) {
                                                            $inObj.add('Host or Cluster', "$($VlanConfiguration.Host.Name) ($($VlanConfiguration.Host.Type))")
                                                            $inObj.add('Platform', $VlanConfiguration.Platform)
                                                            $inObj.add('Virtual Switch', $VlanConfiguration.VirtualSwitch)
                                                            $inObj.add('VLAN With Internet', "$($VlanConfiguration.FirstVLANWithInternet) - $($VlanConfiguration.LastVLANWithInternet)")
                                                            $inObj.add('VLAN Without Internet', "$($VlanConfiguration.FirstVLANWithoutInternet) - $($VlanConfiguration.LastVLANWithoutInternet)")
                                                        }

                                                        $OutObj = [pscustomobject]$inobj

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
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}