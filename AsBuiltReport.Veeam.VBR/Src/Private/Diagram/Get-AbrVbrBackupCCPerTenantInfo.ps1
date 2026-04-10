function Get-AbrBackupCCPerTenantInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication Cloud Connect per Tenant information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        1.0.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]

    param (
        [Parameter(Mandatory = $true)]
        [string]$TenantName
    )

    process {
        Write-PScriboMessage "Collecting Cloud Connect per Tenant information from $($VBRServer)."
        try {

            $BackupCCTenantInfo = @()
            if ($CloudObject = Get-VBRCloudTenant -Name $TenantName) {

                $AditionalInfo = [PSCustomObject] [ordered] @{
                    'Type' = switch ($CloudObject.Type) {
                        'Ad' { 'Active Directory' }
                        'General' { 'Standalone' }
                        'vCD' { 'vCloud Director' }
                        default { 'Unknown' }
                    }
                    'Status' = switch ($CloudObject.Enabled) {
                        'True' { 'Enabled' }
                        'False' { 'Disabled' }
                        default { 'Unknown' }
                    }
                    'Expiration Date' = switch ([string]::IsNullOrEmpty($CloudObject.LeaseExpirationDate)) {
                        $true { 'Never' }
                        $false {
                            & {
                                if ($CloudObject.LeaseExpirationDate -lt (Get-Date)) {
                                    "$($CloudObject.LeaseExpirationDate.ToShortDateString()) (Expired)"
                                } else { $CloudObject.LeaseExpirationDate.ToShortDateString() }
                            }
                        }
                        default { '--' }
                    }
                }

                $TempBackupCCTenantInfo = [PSCustomObject]@{
                    Name = $CloudObject.Name
                    Label = Add-NodeIcon -Name "$((Remove-SpecialCharacter -String $CloudObject.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Cloud_Connect_Gateway' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                    Id = $CloudObject.Id
                    CloudGatewaySelectionType = $CloudObject.GatewaySelectionType
                    CloudGatewayPools = Get-VbrBackupCGPoolInfo | Where-Object { $_.Name -eq $CloudObject.GatewayPool }
                    CloudGatewayServers = & {
                        $CloudGatewayPoolServers = (Get-VBRCloudGatewayPool).CloudGateways.Name
                        $CloudGatewayServersNotInPool = Get-VBRCloudGateway | Where-Object { $_.Name -notin $CloudGatewayPoolServers }
                        Get-AbrBackupCGServerInfo | Where-Object { $_.Name -in $CloudGatewayServersNotInPool.Name }
                    }
                    BackupResources = & {
                        if ($CloudObject.ResourcesEnabled) {
                            $CloudObject.Resources | ForEach-Object {
                                $RepoNameFriendlyName = $_.RepositoryFriendlyName
                                $AditionalInfo = [PSCustomObject]@{
                                    'Used Space' = ConvertTo-FileSizeString -Size (Convert-Size -From MB -To Bytes -Value $_.UsedSpace) -RoundUnits 2
                                    'Quota' = ConvertTo-FileSizeString -Size (Convert-Size -From MB -To Bytes -Value $_.RepositoryQuota) -RoundUnits 2
                                    'Quota Path' = $_.RepositoryQuotaPath
                                }
                                [PSCustomObject]@{
                                    Name = $_.RepositoryFriendlyName
                                    Label = Add-NodeIcon -Name "$($_.RepositoryFriendlyName)" -IconType 'VBR_Cloud_Repository' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                                    Id = $_.Id
                                    WanAccelerationEnabled = $_.WanAccelerationEnabled
                                    WanAccelerator = & {
                                        if ($_.WanAccelerator.Name) {
                                            $WANName = $_.WanAccelerator.Name.split('.')[0]
                                            Get-AbrBackupWanAccelInfo | Where-Object { $_.Name -eq $WANName }
                                        }
                                    }
                                    Repositories = & {
                                        foreach ($Repository in $_.Repository.Name) {
                                            $RepoName = $Repository
                                            Get-AbrBackupCCBackupStorageInfo | Where-Object { $_.Name -eq $RepoName }
                                        }
                                    }
                                    SubTenant = & {
                                        $Guid = $_.Id.Guid
                                        Get-CloudSubTenant -Tenant $CloudObject | Where-Object { $_.Resources.ParentId.Guid -eq $Guid } | ForEach-Object {
                                            $AditionalInfo = [PSCustomObject]@{
                                                'Type' = $_.Type
                                                'Repository Name' = $_.Resources.RepositoryFriendlyName
                                                'Cloud Repository' = $RepoNameFriendlyName
                                                'Quota' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $_.Resources.RepositoryQuota
                                                'Used Space' = $_.Resources.UsedSpacePercentage
                                                'Status' = switch ($_.Enabled) {
                                                    'True' { 'Enabled' }
                                                    'False' { 'Disabled' }
                                                    default { '--' }
                                                }
                                            }
                                            [PSCustomObject]@{
                                                Name = $_.Name
                                                Label = Add-NodeIcon -Name "$($_.Name)" -IconType 'VBR_Cloud_Sub_Tenant' -Align 'Center' -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -AditionalInfo $AditionalInfo -FontBold
                                                Id = $_.Id
                                                IconType = 'VBR_Cloud_Sub_Tenant'
                                                AditionalInfo = $AditionalInfo
                                            }
                                        }
                                    }
                                    IconType = 'VBR_Cloud_Storage'
                                }
                            }
                        }
                    }
                    ReplicationResources = & {
                        if ($CloudObject.ReplicationResourcesEnabled) {
                            $CloudObject.ReplicationResources | ForEach-Object {
                                $NetExEnabled = $_.NetworkFailoverResourcesEnabled
                                [PSCustomObject]@{
                                    'NetworkFailoverResourcesEnabled' = switch ($_.NetworkFailoverResourcesEnabled) {
                                        'True' { 'Enabled' }
                                        'False' { 'Disabled' }
                                        default { 'Unknown' }
                                    }
                                    HardwarePlanOptions = & {
                                        if ($_.HardwarePlanOptions) {
                                            $_.HardwarePlanOptions | ForEach-Object {
                                                $HardwarePlanId = $_.HardwarePlanId.Guid
                                                $HardwarePlanObject = Get-AbrBackupCCReplicaResourcesInfo | Where-Object { $_.id -eq $HardwarePlanId }
                                                [PSCustomObject]@{
                                                    Name = $HardwarePlanObject.Name
                                                    Label = $HardwarePlanObject.Label
                                                    Host = $HardwarePlanObject.Host
                                                    Storage = $HardwarePlanObject.Storage
                                                    WanAcceleration = & {
                                                        if ($_.WanAccelerationEnabled) {
                                                            if ($_.WanAccelerator.Name) {
                                                                $WANName = $_.WanAccelerator.Name.split('.')[0]
                                                                Get-AbrBackupWanAccelInfo | Where-Object { $_.Name -eq $WANName }
                                                            }
                                                        }
                                                    }
                                                    NetworkExtensions = & {
                                                        if ($NetExEnabled) {
                                                            Get-AbrCloudTenantNetworkAppliance -Tenant $CloudObject | Where-Object { $_.HardwarePlanId -eq $HardwarePlanId } | ForEach-Object {
                                                                $IPAddress = $_.IpAddress
                                                                $SubnetMask = $_.SubnetMask
                                                                $Gateway = $_.DefaultGateway
                                                                $AditionalInfo = [PSCustomObject]@{
                                                                    'Hardware Plan' = $HardwarePlanObject.Name
                                                                    'Platform' = $_.Platform
                                                                    'Network Name' = $_.ProductionNetwork.NetworkName
                                                                    'Switch Name' = & {
                                                                        if ([string]::IsNullOrEmpty($_.ProductionNetwork.SwitchName)) {
                                                                            'Not Configured'
                                                                        } else {
                                                                            $_.ProductionNetwork.SwitchName
                                                                        }
                                                                    }
                                                                    'Ip Address' = switch ($_.ObtainIpAddressAutomatically) {
                                                                        $true { 'Automatic' }
                                                                        $false { $IPAddress }
                                                                        default { 'Unknown' }
                                                                    }
                                                                    'Network Mask' = switch ($_.ObtainIpAddressAutomatically) {
                                                                        $true { 'Automatic' }
                                                                        $false { $SubnetMask }
                                                                        default { 'Unknown' }
                                                                    }
                                                                    'Gateway' = switch ($_.ObtainIpAddressAutomatically) {
                                                                        $true { 'Automatic' }
                                                                        $false { $Gateway }
                                                                        default { 'Unknown' }
                                                                    }
                                                                }
                                                                [PSCustomObject]@{
                                                                    Name = $_.Name
                                                                    Label = Add-NodeIcon -Name "$($_.Name)" -IconType 'VBR_Cloud_Network_Extension' -Align 'Center' -ImagesObj $Images -IconDebug $IconDebug -AditionalInfo $AditionalInfo -FontSize 18 -FontBold
                                                                    AditionalInfo = $AditionalInfo
                                                                    IconType = 'VBR_Cloud_Network_Extension'
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    vCDReplicationResources = & {
                        if ($CloudObject.vCDReplicationResourcesEnabled) {
                            $CloudObject.vCDReplicationResource | ForEach-Object {
                                $NetExEnabled = $_.NetworkFailoverResourcesEnabled
                                [PSCustomObject]@{
                                    'NetworkFailoverResourcesEnabled' = switch ($_.NetworkFailoverResourcesEnabled) {
                                        'True' { 'Enabled' }
                                        'False' { 'Disabled' }
                                        default { 'Unknown' }
                                    }
                                    OrganizationvDCOptions = & {
                                        if ($_.OrganizationvDCOptions) {
                                            $_.OrganizationvDCOptions | ForEach-Object {
                                                $OrganizationvDCId = $_.OrganizationvDCID.Guid
                                                $OrganizationvDCObject = Get-AbrBackupCCvCDReplicaResourcesInfo | Where-Object { $_.id -eq $OrganizationvDCId }
                                                [PSCustomObject]@{
                                                    Name = $OrganizationvDCObject.Name
                                                    Label = $OrganizationvDCObject.Label
                                                    WanAcceleration = & {
                                                        if ($_.WANAccelarationEnabled) {
                                                            if ($_.WANAccelerator.Name) {
                                                                $WANName = $_.WANAccelerator.Name.split('.')[0]

                                                                Get-AbrBackupWanAccelInfo | Where-Object { $_.Name -eq $WANName }
                                                            }
                                                        }
                                                    }
                                                    NetworkExtensions = & {
                                                        if ($NetExEnabled) {
                                                            Get-AbrCloudTenantNetworkAppliance -Tenant $CloudObject | Where-Object { $_.HardwarePlanId -eq $OrganizationvDCId } | ForEach-Object {
                                                                $IPAddress = $_.IpAddress
                                                                $SubnetMask = $_.SubnetMask
                                                                $Gateway = $_.DefaultGateway
                                                                $AditionalInfo = [PSCustomObject]@{
                                                                    'Organization vDC' = $OrganizationvDCObject.Name
                                                                    'Platform' = $_.Platform
                                                                    'Network Name' = $_.ProductionNetwork.NetworkName
                                                                    'Switch Name' = switch ([string]::IsNullOrEmpty($_.ProductionNetwork.SwitchName)) {
                                                                        $true { 'Not Configured' }
                                                                        $false { $_.ProductionNetwork.SwitchName }
                                                                        default { 'Unknown' }
                                                                    }
                                                                    'Ip Address' = switch ($_.ObtainIpAddressAutomatically) {
                                                                        $true { 'Automatic' }
                                                                        $false { $IPAddress }
                                                                        default { 'Unknown' }
                                                                    }
                                                                    'Network Mask' = switch ($_.ObtainIpAddressAutomatically) {
                                                                        $true { 'Automatic' }
                                                                        $false { $SubnetMask }
                                                                        default { 'Unknown' }
                                                                    }
                                                                    'Gateway' = switch ($_.ObtainIpAddressAutomatically) {
                                                                        $true { 'Automatic' }
                                                                        $false { $Gateway }
                                                                        default { 'Unknown' }
                                                                    }
                                                                }
                                                                [PSCustomObject]@{
                                                                    Name = $_.Name
                                                                    Label = Add-NodeIcon -Name "$($_.Name)" -IconType 'VBR_Cloud_Network_Extension' -Align 'Center' -ImagesObj $Images -IconDebug $IconDebug -AditionalInfo $AditionalInfo -FontSize 18 -FontBold
                                                                    IconType = 'VBR_Cloud_Network_Extension'
                                                                    AditionalInfo = $AditionalInfo
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                $BackupCCTenantInfo += $TempBackupCCTenantInfo
            } else {
                throw "No Cloud Connect Tenant found with the name $TenantName."
            }

            return $BackupCCTenantInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}