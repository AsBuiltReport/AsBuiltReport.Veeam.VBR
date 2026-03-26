
function Get-AbrVbrCloudConnectTenant {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway Tenants
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.9.0
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Tenants information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCloudConnectTenant
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Cloud Connect Tenants'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' }) {
                if ($CloudObjects = Get-VBRCloudTenant | Sort-Object -Property Name) {
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            try {

                                $inObj = [ordered] @{
                                    $LocalizedData.Name = $CloudObject.Name
                                    $LocalizedData.Type = switch ($CloudObject.Type) {
                                        'Ad' { $LocalizedData.ActiveDirectory }
                                        'General' { $LocalizedData.Standalone }
                                        'vCD' { $LocalizedData.VcloudDirector }
                                        default { $LocalizedData.Unknown }
                                    }
                                    $LocalizedData.LastActive = $CloudObject.LastActive
                                    $LocalizedData.LastResult = $CloudObject.LastResult
                                }

                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Tenants $($CloudObject.Name) Section: $($_.Exception.Message)"
                            }
                        }

                        if ($HealthCheck.CloudConnect.Tenants) {
                            $OutObj | Where-Object { $_.$($LocalizedData.LastResult) -ne 'Success' } | Set-Style -Style Warning -Property $LocalizedData.LastResult
                            $OutObj | Where-Object { $Null -like $_.$($LocalizedData.LastActive) } | Set-Style -Style Warning -Property $LocalizedData.LastActive
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TenantsSummary) - $($VeeamBackupServer)"
                            List = $false
                            ColumnWidths = 40, 20, 25, 15
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        if ($HealthCheck.CloudConnect.BestPractice) {
                            if ($OutObj | Where-Object { $Null -like $_.$($LocalizedData.LastActive) }) {
                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text $LocalizedData.BestPractice -Bold
                                    Text $LocalizedData.BestPracticeText
                                }
                                BlankLine
                            }
                        }
                        #---------------------------------------------------------------------------------------------#
                        #                            Tenants Configuration Section                                    #
                        #---------------------------------------------------------------------------------------------#
                        if ($InfoLevel.CloudConnect.Tenants -ge 2) {
                            try {
                                Section -Style Heading4 $LocalizedData.TenantsConfiguration {
                                    Paragraph $LocalizedData.TenantsConfigParagraph
                                    BlankLine
                                    foreach ($CloudObject in $CloudObjects) {
                                        Section -Style Heading5 $CloudObject.Name {
                                            $OutObj = @()
                                            try {
                                                Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.GeneralInformation {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $CloudObject.Name
                                                        $LocalizedData.Type = switch ($CloudObject.Type) {
                                                            'Ad' { $LocalizedData.ActiveDirectory }
                                                            'General' { $LocalizedData.Standalone }
                                                            'vCD' { $LocalizedData.VcloudDirector }
                                                            default { $LocalizedData.Unknown }
                                                        }
                                                        $LocalizedData.Status = switch ($CloudObject.Enabled) {
                                                            'True' { $LocalizedData.Enabled }
                                                            'False' { $LocalizedData.Disabled }
                                                            default { $LocalizedData.Unknown }
                                                        }
                                                        $LocalizedData.ExpirationDate = switch ([string]::IsNullOrEmpty($CloudObject.LeaseExpirationDate)) {
                                                            $true { $LocalizedData.Never }
                                                            $false {
                                                                & {
                                                                    if ($CloudObject.LeaseExpirationDate -lt (Get-Date)) {
                                                                        "$($CloudObject.LeaseExpirationDate.ToShortDateString()) ($($LocalizedData.Expired))"
                                                                    } else { $CloudObject.LeaseExpirationDate.ToShortDateString() }
                                                                }
                                                            }
                                                            default { '--' }
                                                        }
                                                        $LocalizedData.BackupStorage = $CloudObject.ResourcesEnabled
                                                        $LocalizedData.ReplicationResource = switch ($CloudObject.ReplicationResourcesEnabled -or $CloudObject.vCDReplicationResourcesEnabled) {
                                                            'True' { $LocalizedData.Yes }
                                                            'False' { $LocalizedData.No }
                                                            default { '--' }
                                                        }
                                                        $LocalizedData.Description = $CloudObject.Description
                                                    }

                                                    if ($CloudObject.Type -eq 'Ad') {
                                                        $inObj.add($LocalizedData.Domain, $CloudObject.DomainUrl)
                                                        $inObj.add($LocalizedData.DomainUsername, $CloudObject.Name)
                                                    }

                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.CloudConnect.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                                        $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                                        $OutObj | Where-Object { $_.$($LocalizedData.ExpirationDate) -match '(Expired)' } | Set-Style -Style Warning -Property $LocalizedData.ExpirationDate
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.Tenant) - $($CloudObject.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' -or $_.$($LocalizedData.Description) -eq '--' }) {
                                                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text $LocalizedData.BestPractice -Bold
                                                                Text $LocalizedData.DescriptionBPText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.Bandwidth {
                                                        $OutObj = @()
                                                        try {

                                                            $inObj = [ordered] @{
                                                                $LocalizedData.MaxConcurrentTask = $CloudObject.MaxConcurrentTask
                                                            }

                                                            if ($CloudObject.ThrottlingEnabled) {
                                                                $inObj.add($LocalizedData.LimitNetworkTraffic, ($CloudObject.ThrottlingEnabled))
                                                                switch ($CloudObject.ThrottlingUnit) {
                                                                    'MbytePerSec' { $inObj.add($LocalizedData.ThrottlingTo, "$($CloudObject.ThrottlingValue) MB/s") }
                                                                    'KbytePerSec' { $inObj.add($LocalizedData.ThrottlingTo, "$($CloudObject.ThrottlingValue) KB/s") }
                                                                    'MbitPerSec' { $inObj.add($LocalizedData.ThrottlingTo, "$($CloudObject.ThrottlingValue) Mbps") }
                                                                }
                                                            }

                                                            if ($CloudObject.GatewaySelectionType -eq 'StandaloneGateways') {
                                                                $inObj.add($LocalizedData.GatewayPoolStandalone, $LocalizedData.Automatic)
                                                            } else {
                                                                $GatewayPool = switch ([string]::IsNullOrEmpty($CloudObject.GatewayPool.Name)) {
                                                                    $true { '--' }
                                                                    $false { $CloudObject.GatewayPool.Name }
                                                                    default { $LocalizedData.Unknown }
                                                                }
                                                                $inObj.add($LocalizedData.GatewayType, $LocalizedData.GatewayPool)
                                                                $inObj.add($LocalizedData.GatewayPool, $GatewayPool)
                                                                $inObj.add($LocalizedData.GatewayFailover, ($CloudObject.GatewayFailoverEnabled))
                                                            }

                                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "$($LocalizedData.Bandwidth) - $($CloudObject.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }

                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Bandwidth $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Bandwidth $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                                if ($CloudObject.ResourcesEnabled -and $CloudObject.Resources) {
                                                    try {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.BackupResources {
                                                            $OutObj = @()
                                                            foreach ($CloudBackupRepo in $CloudObject.Resources) {
                                                                try {

                                                                    $inObj = [ordered] @{
                                                                        $LocalizedData.Repository = $CloudBackupRepo.Repository.Name
                                                                        $LocalizedData.FriendlyName = $CloudBackupRepo.RepositoryFriendlyName
                                                                        $LocalizedData.Quota = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size (Convert-Size -From MB -To Bytes -Value $CloudBackupRepo.RepositoryQuota)
                                                                        $LocalizedData.QuotaPath = $CloudBackupRepo.RepositoryQuotaPath
                                                                        $LocalizedData.UseWanAcceleration = $CloudBackupRepo.WanAccelerationEnabled
                                                                    }

                                                                    if ($CloudBackupRepo.WanAccelerationEnabled) {
                                                                        $inObj.add($LocalizedData.WanAccelerator, ($CloudBackupRepo.WanAccelerator).Name)
                                                                    }
                                                                    if ($CloudObject.BackupProtectionEnabled) {
                                                                        $inObj.add($LocalizedData.KeepDeletedBackup, "$($CloudObject.BackupProtectionPeriod) $($LocalizedData.Days)")
                                                                    }

                                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.BackupResources) - $($CloudBackupRepo.RepositoryFriendlyName)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                } catch {
                                                                    Write-PScriboMessage -IsWarning "Backup Resources $($CloudBackupRepo.RepositoryFriendlyName) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Backup Resources Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                if ($CloudObject.ReplicationResourcesEnabled -and $CloudObject.ReplicationResources.HardwarePlanOptions) {
                                                    try {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.ReplicationResources {
                                                            $OutObj = @()
                                                            foreach ($CloudRepliRes in $CloudObject.ReplicationResources) {
                                                                try {

                                                                    $inObj = [ordered] @{
                                                                        $LocalizedData.HardwarePlans = (Get-VBRCloudHardwarePlan | Where-Object { $_.SubscribedTenantId -contains $CloudObject.Id }).Name -join ', '
                                                                        $LocalizedData.UseVeeamNetworkExtension = $CloudRepliRes.NetworkFailoverResourcesEnabled
                                                                    }

                                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.ReplicationResources) - $($CloudObject.Name)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                } catch {
                                                                    Write-PScriboMessage -IsWarning "Replication Resources $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Replication Resources Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                if ($CloudObject.vCDReplicationResourcesEnabled) {
                                                    try {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.ReplicationResourcesVcd {
                                                            $OutObj = @()
                                                            foreach ($CloudRepliRes in $CloudObject.vCDReplicationResource.OrganizationvDCOptions) {
                                                                try {

                                                                    $inObj = [ordered] @{
                                                                        $LocalizedData.OrgvDCName = $CloudRepliRes.OrganizationvDCName
                                                                        $LocalizedData.AllocationModel = $CloudRepliRes.AllocationModel
                                                                        $LocalizedData.WanAcceleration = $CloudRepliRes.WANAccelarationEnabled
                                                                        $LocalizedData.WanAcceleratorCol = switch ([string]::IsNullOrEmpty($CloudRepliRes.WANAccelerator.Name)) {
                                                                            $true { '--' }
                                                                            $false { $CloudRepliRes.WANAccelerator.Name }
                                                                            default { $LocalizedData.Unknown }
                                                                        }
                                                                    }

                                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.ReplicationResourcesVcd) - $($CloudObject.Name)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                } catch {
                                                                    Write-PScriboMessage -IsWarning "Replication Resources (vCD) $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Replication Resources (vCD) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                if ($CloudObject.ReplicationResources.NetworkFailoverResourcesEnabled -or $CloudObject.vCDReplicationResource.TenantNetworkAppliance) {
                                                    try {
                                                        if ($TenantNetworkAppliances = Get-VBRCloudTenantNetworkAppliance -Tenant $CloudObject) {
                                                            Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.NetworkExtension {
                                                                $OutObj = @()
                                                                foreach ($TenantNetworkAppliance in $TenantNetworkAppliances) {
                                                                    try {

                                                                        $inObj = [ordered] @{
                                                                            $LocalizedData.Name = $TenantNetworkAppliance.Name
                                                                            $LocalizedData.Platform = $TenantNetworkAppliance.Platform
                                                                        }

                                                                        if (-not $CloudObject.vCDReplicationResource.TenantNetworkAppliance) {
                                                                            $inObj.add($LocalizedData.HardwarePlan, (Get-VBRCloudHardwarePlan -Id $TenantNetworkAppliance.HardwarePlanId).Name)
                                                                        }

                                                                        $inObj.add($LocalizedData.ProductionNetwork, $TenantNetworkAppliance.ProductionNetwork.Name)
                                                                        $inObj.add($LocalizedData.ObtainIpAuto, ($TenantNetworkAppliance.ObtainIpAddressAutomatically))

                                                                        if (-not $TenantNetworkAppliance.ObtainIpAddressAutomatically) {
                                                                            $inObj.add($LocalizedData.IpAddress, $TenantNetworkAppliance.IpAddress)
                                                                            $inObj.add($LocalizedData.SubnetMask, $TenantNetworkAppliance.SubnetMask)
                                                                            $inObj.add($LocalizedData.DefaultGateway, $TenantNetworkAppliance.DefaultGateway)
                                                                        }

                                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.NetworkExtension) - $($CloudObject.Name)"
                                                                            List = $true
                                                                            ColumnWidths = 40, 60
                                                                        }

                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Table @TableParams
                                                                    } catch {
                                                                        Write-PScriboMessage -IsWarning "Network Extension $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Network Extension Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                try {
                                                    if ($CloudSubTenants = Get-VBRCloudSubTenant | Where-Object { $_.TenantId -eq $CloudObject.Id } | Sort-Object -Property Name) {
                                                        Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.SubTenants {
                                                            $OutObj = @()
                                                            foreach ($CloudSubTenant in $CloudSubTenants) {
                                                                try {

                                                                    $inObj = [ordered] @{
                                                                        $LocalizedData.Name = $CloudSubTenant.Name
                                                                        $LocalizedData.Type = $CloudSubTenant.Type
                                                                        $LocalizedData.Mode = $CloudSubTenant.Mode
                                                                        $LocalizedData.RepositoryName = $CloudSubTenant.Resources.RepositoryFriendlyName
                                                                        $LocalizedData.Quota = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CloudSubTenant.Resources.RepositoryQuota
                                                                        $LocalizedData.QuotaPath = $CloudSubTenant.Resources.RepositoryQuotaPath
                                                                        $LocalizedData.UsedSpacePct = $CloudSubTenant.Resources.UsedSpacePercentage
                                                                        $LocalizedData.Status = switch ($CloudSubTenant.Enabled) {
                                                                            'True' { $LocalizedData.Enabled }
                                                                            'False' { $LocalizedData.Disabled }
                                                                            default { '--' }
                                                                        }
                                                                    }

                                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                    if ($HealthCheck.CloudConnect.Tenants) {
                                                                        $OutObj | Where-Object { $_.$($LocalizedData.UsedSpacePct) -gt 85 } | Set-Style -Style Warning -Property $LocalizedData.UsedSpacePct
                                                                        $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.Subtenant) - $($CloudSubTenant.Name)"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }

                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                } catch {
                                                                    Write-PScriboMessage -IsWarning "Subtenant $($CloudSubTenant.Name) Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Subtenant Section: $($_.Exception.Message)"
                                                }
                                                try {
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.LicensesUtilization {
                                                        $OutObj = @()

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.NewVMBackup = $CloudObject.NewVMBackupCount
                                                            $LocalizedData.NewWorkstationBackup = $CloudObject.NewWorkstationBackupCount
                                                            $LocalizedData.NewServerBackup = $CloudObject.NewServerBackupCount
                                                            $LocalizedData.NewReplica = $CloudObject.NewReplicaCount
                                                            $LocalizedData.RentalVMBackup = $CloudObject.RentalVMBackupCount
                                                            $LocalizedData.RentalWorkstationBackup = $CloudObject.RentalWorkstationBackupCount
                                                            $LocalizedData.RentalServerBackup = $CloudObject.RentalServerBackupCount
                                                            $LocalizedData.RentalReplica = $CloudObject.RentalReplicaCount
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.LicensesUtilization) - $($CloudObject.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Licenses Utilization $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Tenants $($CloudObject.Name) Configuration Section: $($_.Exception.Message)"
                                            }
                                            ##############################################################################
                                            #                              Diagram section                               #
                                            ##############################################################################
                                            if ($Options.EnableDiagrams) {
                                                try {
                                                    try {
                                                        $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-CloudConnect-Tenant' -Tenant $CloudObject.Name -DiagramOutput base64 -Direction 'left-to-right'
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Backup CloudConnect Tenant $($CloudObject.Name) Diagram: $($_.Exception.Message)"
                                                    }
                                                    if ($Graph) {
                                                        $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                                        PageBreak
                                                        Section -Style Heading6 $LocalizedData.Diagram {
                                                            Image -Base64 $Graph -Text $LocalizedData.DiagramText -Align Center -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height
                                                            PageBreak
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Backup CloudConnect Tenant  $($CloudObject.Name) Diagram Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Tenants Configuration Section: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tenants Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Cloud Connect Tenants'
    }

}