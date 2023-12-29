
function Get-AbrVbrCloudConnectTenant {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway Tenants
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.0
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Tenants information from $System."
    }

    process {
        try {
            if (Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -ne "Disabled"}) {
                $CloudObjects = Get-VBRCloudTenant | Sort-Object -Property Name
                if ($CloudObjects) {
                    Section -Style Heading3 'Tenants' {
                        Paragraph "The following table provides status information about Cloud Connect Tenants."
                        BlankLine
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            try {
                                Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Tenants information."
                                $inObj = [ordered] @{
                                    'Name' = $CloudObject.Name
                                    'Type' = Switch ($CloudObject.Type) {
                                        'Ad' {'Active Directory'}
                                        'General' {'Standalone'}
                                        'vCD' {'vCloud Director'}
                                        default {'Unknown'}
                                    }
                                    'Last Active' = $CloudObject.LastActive
                                    'Last Result' = $CloudObject.LastResult
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Tenants $($CloudObject.Name) Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.CloudConnect.Tenants) {
                            $OutObj | Where-Object { $_.'Last Result' -ne 'Success'} | Set-Style -Style Warning -Property 'Last Result'
                            $OutObj | Where-Object { $Null -like $_.'Last Active' } | Set-Style -Style Warning -Property 'Last Active'
                        }

                        $TableParams = @{
                            Name = "Tenants Summary - $($VeeamBackupServer)"
                            List = $false
                            ColumnWidths = 40, 20, 25, 15
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        if ($HealthCheck.CloudConnect.BestPractice) {
                            if ($OutObj | Where-Object { $Null -like $_.'Last Active' }) {
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Best Practice:" -Bold
                                    Text "Validate if the tenant's resources are being utilized"
                                }
                            }
                        }
                        #---------------------------------------------------------------------------------------------#
                        #                            Tenants Configuration Section                                    #
                        #---------------------------------------------------------------------------------------------#
                        if ($InfoLevel.CloudConnect.Tenants -ge 2) {
                            try {
                                Section -Style Heading4 'Tenants Configuration' {
                                    Paragraph "The following section provides detailed configuration information about Cloud Connect Tenants."
                                    BlankLine
                                    foreach ($CloudObject in $CloudObjects) {
                                        Section -Style Heading5 $CloudObject.Name {
                                            $OutObj = @()
                                            try {
                                                Section -ExcludeFromTOC -Style NOTOCHeading6 'General Information' {
                                                    Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Tenants information."
                                                    $inObj = [ordered] @{
                                                        'Name' = $CloudObject.Name
                                                        'Type' = Switch ($CloudObject.Type) {
                                                            'Ad' {'Active Directory'}
                                                            'General' {'Standalone'}
                                                            'vCD' {'vCloud Director'}
                                                            default {'Unknown'}
                                                        }
                                                        'Status' = Switch ($CloudObject.Enabled) {
                                                            'True' {'Enabled'}
                                                            'False' {'Disabled'}
                                                            default {'Unknown'}
                                                        }
                                                        'Expiration Date' = Switch ([string]::IsNullOrEmpty($CloudObject.LeaseExpirationDate)) {
                                                            $true {'Never'}
                                                            $false {$CloudObject.LeaseExpirationDate.ToLongDateString()}
                                                            default {'-'}
                                                        }
                                                        'Backup Storage (Cloud Backup Repository)' = ConvertTo-TextYN $CloudObject.ResourcesEnabled
                                                        'Replication Resource (Cloud Host)' = Switch ($CloudObject.ReplicationResourcesEnabled -or $CloudObject.vCDReplicationResourcesEnabled) {
                                                            'True' {'Yes'}
                                                            'False' {'No'}
                                                            default {'-'}
                                                        }
                                                        'Description' = $CloudObject.Description
                                                    }

                                                    if ($CloudObject.Type -eq 'Ad') {
                                                        $inObj.add('Domain',$CloudObject.DomainUrl)
                                                        $inObj.add('Domain Username',$CloudObject.Name)
                                                    }

                                                    $OutObj = [pscustomobject]$inobj

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $Null -like $_.'Description' } | Set-Style -Style Warning -Property 'Description'
                                                        $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Tenant - $($CloudObject.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $Null -like $_.'Description'}) {
                                                            Paragraph "Health Check:" -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text "Best Practice:" -Bold
                                                                Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                            }
                                                        }
                                                    }
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Bandwidth' {
                                                        $OutObj = @()
                                                        try {
                                                            Write-PscriboMessage "Discovered $($CloudObject.Name) Bandwidth information."
                                                            $inObj = [ordered] @{
                                                                'Max Concurrent Task' = $CloudObject.MaxConcurrentTask
                                                            }

                                                            if ($CloudObject.ThrottlingEnabled) {
                                                                $inObj.add('Limit network traffic from this tenant?', (ConvertTo-TextYN $CloudObject.ThrottlingEnabled))
                                                                Switch ($CloudObject.ThrottlingUnit) {
                                                                    'MbytePerSec' {$inObj.add('Throttling network traffic to',"$($CloudObject.ThrottlingValue) MB/s")}
                                                                    'KbytePerSec' {$inObj.add('Throttling network traffic to',"$($CloudObject.ThrottlingValue) KB/s")}
                                                                    'MbitPerSec' {$inObj.add('Throttling network traffic to',"$($CloudObject.ThrottlingValue) Mbps")}
                                                                }
                                                            }

                                                            if ($CloudObject.GatewaySelectionType -eq 'StandaloneGateways') {
                                                                $inObj.add('Gateway Pool', 'Automatic')
                                                            } else {
                                                                $GatewayPool = Switch ([string]::IsNullOrEmpty($CloudObject.GatewayPool.Name)) {
                                                                    $true {'-'}
                                                                    $false {$CloudObject.GatewayPool.Name}
                                                                    default {'Unknown'}
                                                                }
                                                                $inObj.add('Gateway Type', 'Gateway Pool')
                                                                $inObj.add('Gateway Pool', $GatewayPool)
                                                                $inObj.add('Gateway Failover', (ConvertTo-TextYN $CloudObject.GatewayFailoverEnabled))
                                                            }

                                                            $OutObj = [pscustomobject]$inobj

                                                            $TableParams = @{
                                                                Name = "Bandwidth - $($CloudObject.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }

                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning "Bandwidth $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Bandwidth $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                                if ($CloudObject.ResourcesEnabled -and $CloudObject.Resources) {
                                                    try {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 'Backup Resources' {
                                                            $OutObj = @()
                                                            foreach ($CloudBackupRepo in $CloudObject.Resources) {
                                                                try {
                                                                    Write-PscriboMessage "Discovered $($CloudBackupRepo.RepositoryFriendlyName) Backup Resources information."
                                                                    $inObj = [ordered] @{
                                                                        'Repository' = $CloudBackupRepo.Repository.Name
                                                                        'Friendly Name' = $CloudBackupRepo.RepositoryFriendlyName
                                                                        'Quota' = "$(Convert-Size -from MB -to GB -Value $CloudBackupRepo.RepositoryQuota) GB"
                                                                        'Quota Path' = $CloudBackupRepo.RepositoryQuotaPath
                                                                        'Use Wan Acceleration' = ConvertTo-TextYN $CloudBackupRepo.WanAccelerationEnabled
                                                                    }

                                                                    if ($CloudBackupRepo.WanAccelerationEnabled) {
                                                                        $inObj.add('Wan Accelerator', ($CloudBackupRepo.WanAccelerator).Name)
                                                                    }
                                                                    if ($CloudObject.BackupProtectionEnabled) {
                                                                        $inObj.add('Keep deleted backup file for', "$($CloudObject.BackupProtectionPeriod) days")
                                                                    }

                                                                    $OutObj = [pscustomobject]$inobj

                                                                    $TableParams = @{
                                                                        Name = "Backup Resources - $($CloudBackupRepo.RepositoryFriendlyName)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                }
                                                                catch {
                                                                    Write-PscriboMessage -IsWarning "Backup Resources $($CloudBackupRepo.RepositoryFriendlyName) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "Backup Resources Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                if ($CloudObject.ReplicationResourcesEnabled -and $CloudObject.ReplicationResources.HardwarePlanOptions) {
                                                    try {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 'Replication Resources' {
                                                            $OutObj = @()
                                                            foreach ($CloudRepliRes in $CloudObject.ReplicationResources) {
                                                                try {
                                                                    Write-PscriboMessage "Discovered $($CloudRepliRes.RepositoryFriendlyName) Replication Resources information."
                                                                    $inObj = [ordered] @{
                                                                        'Hardware Plans' = (Get-VBRCloudHardwarePlan  | Where-Object {$_.SubscribedTenantId -contains $CloudObject.Id}).Name -join ', '
                                                                        'Use Veeam Network Extension Capabilities during Partial and Full Site Failover' = ConvertTo-TextYN $CloudRepliRes.NetworkFailoverResourcesEnabled
                                                                    }

                                                                    $OutObj = [pscustomobject]$inobj

                                                                    $TableParams = @{
                                                                        Name = "Replication Resources - $($CloudObject.Name)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                }
                                                                catch {
                                                                    Write-PscriboMessage -IsWarning "Replication Resources $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "Replication Resources Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                if ($CloudObject.vCDReplicationResourcesEnabled) {
                                                    try {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 'Replication Resources (vCD)' {
                                                            $OutObj = @()
                                                            foreach ($CloudRepliRes in $CloudObject.vCDReplicationResource.OrganizationvDCOptions) {
                                                                try {
                                                                    Write-PscriboMessage "Discovered $($CloudRepliRes.RepositoryFriendlyName) Replication Resources information."
                                                                    $inObj = [ordered] @{
                                                                        'Organization vDC Name' = $CloudRepliRes.OrganizationvDCName
                                                                        'Allocation Model' = $CloudRepliRes.AllocationModel
                                                                        'WAN Accelaration?' = ConvertTo-TextYN $CloudRepliRes.WANAccelarationEnabled
                                                                    }

                                                                    if ($CloudRepliRes.WANAccelarationEnabled) {
                                                                        $inObj.add('WAN Accelerator', $CloudRepliRes.WANAccelerator.Name)
                                                                    }

                                                                    $OutObj = [pscustomobject]$inobj

                                                                    $TableParams = @{
                                                                        Name = "Replication Resources (vCD) - $($CloudObject.Name)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                }
                                                                catch {
                                                                    Write-PscriboMessage -IsWarning "Replication Resources (vCD) $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "Replication Resources (vCD) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                if ($CloudObject.ReplicationResources.NetworkFailoverResourcesEnabled -or $CloudObject.vCDReplicationResource.TenantNetworkAppliance) {
                                                    try {
                                                        $TenantNetworkAppliances = Get-VBRCloudTenantNetworkAppliance -Tenant $CloudObject
                                                        if ($TenantNetworkAppliances) {
                                                            Section -ExcludeFromTOC -Style NOTOCHeading6 'Network Extension' {
                                                                $OutObj = @()
                                                                foreach ($TenantNetworkAppliance in $TenantNetworkAppliances) {
                                                                    try {
                                                                        Write-PscriboMessage "Discovered $($TenantNetworkAppliance.Name) Network Extension information."
                                                                        $inObj = [ordered] @{
                                                                            'Name' = $TenantNetworkAppliance.Name
                                                                            'Platform' = $TenantNetworkAppliance.Platform
                                                                        }

                                                                        if (-Not $CloudObject.vCDReplicationResource.TenantNetworkAppliance) {
                                                                            $inObj.add('Hardware Plan', (Get-VBRCloudHardwarePlan -Id $TenantNetworkAppliance.HardwarePlanId).Name)
                                                                        }

                                                                        $inObj.add('Production Network', $TenantNetworkAppliance.ProductionNetwork.Name)
                                                                        $inObj.add('Obtain Ip Address Automatically', (ConvertTo-TextYN $TenantNetworkAppliance.ObtainIpAddressAutomatically))

                                                                        if (-Not $TenantNetworkAppliance.ObtainIpAddressAutomatically) {
                                                                            $inObj.add('Ip Address', $TenantNetworkAppliance.IpAddress)
                                                                            $inObj.add('Subnet Mask', $TenantNetworkAppliance.SubnetMask)
                                                                            $inObj.add('Default Gateway', $TenantNetworkAppliance.DefaultGateway)
                                                                        }

                                                                        $OutObj = [pscustomobject]$inobj

                                                                        $TableParams = @{
                                                                            Name = "Network Extension - $($CloudObject.Name)"
                                                                            List = $true
                                                                            ColumnWidths = 40, 60
                                                                        }

                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Table @TableParams
                                                                    }
                                                                    catch {
                                                                        Write-PscriboMessage -IsWarning "Network Extension $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "Network Extension Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                try {
                                                    $CloudSubTenants = Get-VBRCloudSubTenant | Where-Object {$_.TenantId -eq $CloudObject.Id}
                                                    if ($CloudSubTenants) {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 'Sub-Tenants' {
                                                            $OutObj = @()
                                                            foreach ($CloudSubTenant in $CloudSubTenants) {
                                                                try {
                                                                    Write-PscriboMessage "Discovered $($CloudSubTenant.Name) Subtenant information."
                                                                    $inObj = [ordered] @{
                                                                        'Name' = $CloudSubTenant.Name
                                                                        'Type' = $CloudSubTenant.Type
                                                                        'Mode' = $CloudSubTenant.Mode
                                                                        'Repository Name' = $CloudSubTenant.Resources.RepositoryFriendlyName
                                                                        'Quota' = "$(Convert-Size -from MB -to GB -Value $CloudSubTenant.Resources.RepositoryQuota) GB"
                                                                        'Quota Path' = $CloudSubTenant.Resources.RepositoryQuotaPath
                                                                        'Used Space %' = $CloudSubTenant.Resources.UsedSpacePercentage
                                                                        'Status' = Switch ($CloudSubTenant.Enabled) {
                                                                            'True' {'Enabled'}
                                                                            'False' {'Disabled'}
                                                                            default {'-'}
                                                                        }
                                                                    }

                                                                    $OutObj = [pscustomobject]$inobj

                                                                    if ($HealthCheck.CloudConnect.Tenants) {
                                                                        $OutObj | Where-Object { $_.'Used Space %' -gt 85} | Set-Style -Style Warning -Property 'Used Space %'
                                                                        $OutObj | Where-Object { $_.'Status' -eq 'Disabled'} | Set-Style -Style Warning -Property 'Status'
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "Subtenant - $($CloudSubTenant.Name)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                }
                                                                catch {
                                                                    Write-PscriboMessage -IsWarning "Subtenant $($CloudSubTenant.Name) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Subtenant Section: $($_.Exception.Message)"
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 'Licenses Utilization' {
                                                        $OutObj = @()
                                                        Write-PscriboMessage "Discovered $($CloudObject.Name) License Utilization information."
                                                        $inObj = [ordered] @{
                                                            'New VM Backup' = $CloudObject.NewVMBackupCount
                                                            'New Workstation Backup' = $CloudObject.NewWorkstationBackupCount
                                                            'New Server Backup' = $CloudObject.NewServerBackupCount
                                                            'New Replica' = $CloudObject.NewReplicaCount
                                                            'Rental VM Backup' = $CloudObject.RentalVMBackupCount
                                                            'Rental Workstation Backup' = $CloudObject.RentalWorkstationBackupCount
                                                            'Rental Server Backup' = $CloudObject.RentalServerBackupCount
                                                            'Rental Replica' = $CloudObject.RentalReplicaCount
                                                        }

                                                        $OutObj = [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Licenses Utilization - $($CloudObject.Name)"
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
                                                    Write-PscriboMessage -IsWarning "Licenses Utilization $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning "Licenses Utilization Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Tenants Configuration Section: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Tenants Section: $($_.Exception.Message)"
        }
    }
    end {}

}