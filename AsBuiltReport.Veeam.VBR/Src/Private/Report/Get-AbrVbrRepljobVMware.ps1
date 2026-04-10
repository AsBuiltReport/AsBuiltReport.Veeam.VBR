
function Get-AbrVbrRepljobVMware {
    <#
    .SYNOPSIS
        Used by As Built Report to returns vmware replication jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR VMware Replication Jobs Configuration information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrRepljobVMware
        Show-AbrDebugExecutionTime -Start -TitleMessage 'VMware Replication Jobs Configuration'
    }

    process {
        try {
            if ($Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -eq 'VMware Replication' } | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($VMcount in $Bkjobs) {
                            try {

                                $inObj = [ordered] @{
                                    ($LocalizedData.name) = $VMcount.Name
                                    ($LocalizedData.creationTime) = $VMcount.Info.CreationTimeUtc.ToLongDateString()
                                    ($LocalizedData.vmCount) = try { ((Get-VBRReplica | Where-Object { $_.JobName -eq $VMcount.Name }).VMcount | Measure-Object -Sum).Count } catch { Out-Null }
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "VMware Replication Summary $($VMcount.Name) Table: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeadingSummary) - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 35, 35, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property $LocalizedData.name | Table @TableParams
                    } catch {
                        Write-PScriboMessage -IsWarning "VMware Replication Summary Section: $($_.Exception.Message)"
                    }
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionCommonInfo {
                                    $OutObj = @()
                                    try {
                                        $CommonInfos = (Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -eq 'VMware Replication' }).Info
                                        foreach ($CommonInfo in $CommonInfos) {
                                            try {

                                                $inObj = [ordered] @{
                                                    ($LocalizedData.name) = $Bkjob.Name
                                                    ($LocalizedData.type) = $Bkjob.TypeToString
                                                    ($LocalizedData.totalBackupSize) = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CommonInfo.IncludedSize
                                                    ($LocalizedData.targetAddress) = $CommonInfo.TargetDir
                                                    ($LocalizedData.targetFile) = $CommonInfo.TargetFile
                                                    ($LocalizedData.description) = $CommonInfo.CommonInfo.Description
                                                    ($LocalizedData.modifiedBy) = $CommonInfo.CommonInfo.ModifiedBy.FullName
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware Replication Jobs Common Information $($Bkjob.Name) Table: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeadingCommonInfo) - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    } catch {
                                        Write-PScriboMessage -IsWarning "VMware Replication Jobs Common Information Section: $($_.Exception.Message)"
                                    }
                                }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionDestination {
                                    $OutObj = @()
                                    try {
                                        foreach ($Destination in $Bkjob.ViReplicaTargetOptions) {
                                            try {

                                                if (!$Destination.ClusterName) {
                                                    $HostorCluster = (Find-VBRHvEntity -Name $FailOverPlansVM | Where-Object { $_.Reference -eq $Destination.HostReference }).Name
                                                } else { $HostorCluster = $Destination.ClusterName }
                                                $inObj = [ordered]  @{
                                                    ($LocalizedData.hostOrCluster) = switch ($HostorCluster) {
                                                        $Null { 'Unknown' }
                                                        default { $HostorCluster }
                                                    }
                                                    ($LocalizedData.resourcesPool) = $Destination.ReplicaTargetResourcePoolName
                                                    ($LocalizedData.vmFolder) = $Destination.ReplicaTargetVmFolderName
                                                    ($LocalizedData.datastore) = $Destination.DatastoreName
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Destination Table: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeadingDestination) - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    } catch {
                                        Write-PScriboMessage -IsWarning "VMware Replication Jobs Destination Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($Bkjob.ViReplicaTargetOptions.UseNetworkMapping) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionNetwork {
                                        $OutObj = @()
                                        try {
                                            foreach ($NetMapping in $Bkjob.Options.ViNetworkMappingOptions.NetworkMapping) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.sourceNetwork) = $NetMapping.SourceNetwork
                                                        ($LocalizedData.targetNetwork) = $NetMapping.TargetNetwork
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Network Table: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeadingNetwork) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 50, 50
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Source Network' | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Network Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                                if ($Bkjob.Options.ViReplicaTargetOptions.UseReIP) {
                                    if ($Bkjob.Options.ReIPRulesOptions.Rules) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionReIPRules {
                                            $OutObj = @()
                                            try {
                                                foreach ($ReIpRule in $Bkjob.Options.ReIPRulesOptions.Rules) {
                                                    try {

                                                        $inObj = [ordered] @{
                                                            ($LocalizedData.sourceIPAddress) = $ReIpRule.Source.IPAddress
                                                            ($LocalizedData.sourceSubnetMask) = $ReIpRule.Source.SubnetMask
                                                            ($LocalizedData.targetPAddress) = $ReIpRule.Target.IPAddress
                                                            ($LocalizedData.targetSubnetMask) = $ReIpRule.Target.SubnetMask
                                                            ($LocalizedData.targetDefaultGateway) = $ReIpRule.Target.DefaultGateway
                                                            ($LocalizedData.targetDNSAddresses) = $ReIpRule.Target.DNSAddresses
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Re-IP Rules Table: $($_.Exception.Message)"
                                                    }
                                                }

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.TableHeadingReIP) - $($Bkjob.Name)"
                                                    List = $false
                                                    ColumnWidths = 17, 17, 17, 17, 16, 16
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Source IP Address' | Table @TableParams
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Re-IP Rules Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                    if ($Bkjob.Options.ReIPRulesOptions.RulesIPv4) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionReIPRules {
                                            $OutObj = @()
                                            try {
                                                foreach ($ReIpRule in $Bkjob.Options.ReIPRulesOptions.RulesIPv4) {
                                                    try {

                                                        $inObj = [ordered] @{
                                                            ($LocalizedData.sourceIPAddress) = $ReIpRule.Source.IPAddress
                                                            ($LocalizedData.sourceSubnetMask) = $ReIpRule.Source.SubnetMask
                                                            ($LocalizedData.targetPAddress) = $ReIpRule.Target.IPAddress
                                                            ($LocalizedData.targetSubnetMask) = $ReIpRule.Target.SubnetMask
                                                            ($LocalizedData.targetDefaultGateway) = $ReIpRule.Target.DefaultGateway
                                                            ($LocalizedData.targetDNSAddresses) = $ReIpRule.Target.DNSAddresses
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Re-IP Rules Table: $($_.Exception.Message)"
                                                    }
                                                }

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.TableHeadingReIP) - $($Bkjob.Name)"
                                                    List = $false
                                                    ColumnWidths = 17, 17, 17, 17, 16, 16
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Source IP Address' | Table @TableParams
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Re-IP Rules Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                }
                                if ($Bkjob.GetViOijs()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionVMs {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetViOijs() | Where-Object { $_.Type -eq 'Include' -or $_.Type -eq 'Exclude' } )) {

                                                $inObj = [ordered] @{
                                                    ($LocalizedData.name) = $OBJ.Name
                                                    ($LocalizedData.resourceType) = $OBJ.TypeDisplayName
                                                    ($LocalizedData.role) = $OBJ.Type
                                                    ($LocalizedData.approxSize) = $OBJ.ApproxSizeString
                                                    ($LocalizedData.diskFilterMode) = $OBJ.DiskFilterInfo.Mode
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeadingVMs) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 20, 20, 20, 20, 20
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning "VMware Replication Jobs Virtual Machine Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionJobSettings {
                                    $OutObj = @()
                                    try {

                                        if ($Bkjob.BackupStorageOptions.RetentionType -eq 'Days') {
                                            $RetainString = 'Restore Point To Keep'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainDaysToKeep
                                        } elseif ($Bkjob.BackupStorageOptions.RetentionType -eq 'Cycles') {
                                            $RetainString = 'Retain Cycles'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainCycles
                                        }
                                        $inObj = [ordered] @{
                                            ($LocalizedData.replicaMetadataRepo) = switch ($Bkjob.info.TargetRepositoryId) {
                                                '00000000-0000-0000-0000-000000000000' { $Bkjob.TargetDir }
                                                { $Null -eq (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name } { (Get-VBRBackupRepository -ScaleOut | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                                default { (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                            }
                                            ($LocalizedData.replicaNameSuffix) = $Bkjob.Options.ViReplicaTargetOptions.ReplicaNameSuffix
                                            $RetainString = $Retains
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeadingJobSettings) - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($InfoLevel.Jobs.Replication -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvMaintenance {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.slcg) = $Bkjob.Options.GenerationPolicy.EnableRechek
                                                        ($LocalizedData.slcgScheduleType) = $Bkjob.Options.GenerationPolicy.RecheckScheduleKind
                                                        ($LocalizedData.slcgScheduleDay) = $Bkjob.Options.GenerationPolicy.RecheckDays
                                                        ($LocalizedData.slcgMonthlySchedule) = "Day Of Week: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.Months)"
                                                        ($LocalizedData.dcfb) = $Bkjob.Options.GenerationPolicy.EnableCompactFull
                                                        ($LocalizedData.dcfbScheduleType) = $Bkjob.Options.GenerationPolicy.CompactFullBackupScheduleKind
                                                        ($LocalizedData.dcfbScheduleDay) = $Bkjob.Options.GenerationPolicy.CompactFullBackupDays
                                                        ($LocalizedData.dcfbMonthlySchedule) = "Day Of Week: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.Months)"
                                                        ($LocalizedData.removeDeletedData) = $Bkjob.Options.BackupStorageOptions.RetainDays
                                                    }

                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.slcg) -eq 'No' } | Set-Style -Style Warning -Property ($LocalizedData.slcg)
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvMaintenance) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }

                                                    $OutObj | Table @TableParams

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.$($LocalizedData.slcg) -eq 'No' }) {
                                                            Paragraph $LocalizedData.healthCheck -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text $LocalizedData.bestPractice -Bold
                                                                Text $LocalizedData.healthCheckSLCGText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Advanced Settings (Maintenance) Table: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvTraffic {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.inlineDeduplication) = $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                        ($LocalizedData.excludeSwapFiles) = $Bkjob.ViSourceOptions.ExcludeSwapFile
                                                        ($LocalizedData.excludeDeletedFiles) = $Bkjob.ViSourceOptions.DirtyBlocksNullingEnabled
                                                        ($LocalizedData.compressionLevel) = switch ($Bkjob.Options.BackupStorageOptions.CompressionLevel) {
                                                            0 { 'NONE' }
                                                            -1 { 'AUTO' }
                                                            4 { 'DEDUPE_friendly' }
                                                            5 { 'OPTIMAL (Default)' }
                                                            6 { 'High' }
                                                            9 { 'EXTREME' }
                                                        }
                                                        ($LocalizedData.storageOptimization) = switch ($Bkjob.Options.BackupStorageOptions.StgBlockSize) {
                                                            'KbBlockSize1024' { 'Local target' }
                                                            'KbBlockSize512' { 'LAN target' }
                                                            'KbBlockSize256' { 'WAN target' }
                                                            'KbBlockSize4096' { 'Local target (large blocks)' }
                                                            default { $Bkjob.Options.BackupStorageOptions.StgBlockSize }
                                                        }
                                                        ($LocalizedData.enabledBackupFileEncryption) = $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                                        ($LocalizedData.encryptionKey) = switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                            $false { 'None' }
                                                            default { (Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.enabledBackupFileEncryption) -eq 'No' } | Set-Style -Style Warning -Property ($LocalizedData.enabledBackupFileEncryption)
                                                        $OutObj | Where-Object { $_.$($LocalizedData.excludeSwapFiles) -eq 'No' } | Set-Style -Style Warning -Property ($LocalizedData.excludeSwapFiles)
                                                        $OutObj | Where-Object { $_.$($LocalizedData.excludeDeletedFiles) -eq 'No' } | Set-Style -Style Warning -Property ($LocalizedData.excludeDeletedFiles)
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvTraffic) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.$($LocalizedData.enabledBackupFileEncryption) -eq 'No' }) {
                                                            Paragraph $LocalizedData.healthCheck -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text $LocalizedData.bestPractice -Bold
                                                                Text $LocalizedData.healthCheckEncryptionText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Advanced Settings (Traffic) Table: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.NotificationOptions.SnmpNotification -or $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvNotification {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.sendSnmpNotification) = $Bkjob.Options.NotificationOptions.SnmpNotification
                                                        ($LocalizedData.sendEmailNotification) = $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses
                                                        ($LocalizedData.emailAdditionalAddresses) = $Bkjob.Options.NotificationOptions.EmailNotificationAdditionalAddresses
                                                        ($LocalizedData.emailNotifyTime) = $Bkjob.Options.NotificationOptions.EmailNotifyTime.ToShortTimeString()
                                                        ($LocalizedData.useCustomEmailNotification) = $Bkjob.Options.NotificationOptions.UseCustomEmailNotificationOptions
                                                        ($LocalizedData.useCustomNotificationSetting) = $Bkjob.Options.NotificationOptions.EmailNotificationSubject
                                                        ($LocalizedData.notifyOnSuccess) = $Bkjob.Options.NotificationOptions.EmailNotifyOnSuccess
                                                        ($LocalizedData.notifyOnWarning) = $Bkjob.Options.NotificationOptions.EmailNotifyOnWarning
                                                        ($LocalizedData.notifyOnError) = $Bkjob.Options.NotificationOptions.EmailNotifyOnError
                                                        ($LocalizedData.suppressNotification) = $Bkjob.Options.NotificationOptions.EmailNotifyOnLastRetryOnly
                                                        ($LocalizedData.setResultsToVmNotes) = $Bkjob.Options.ViSourceOptions.SetResultsToVmNotes
                                                        ($LocalizedData.vmAttributeNoteValue) = $Bkjob.Options.ViSourceOptions.VmAttributeName
                                                        ($LocalizedData.appendToAttribute) = $Bkjob.Options.ViSourceOptions.VmNotesAppend
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvNotification) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Advanced Settings (Notification) Table: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.ViSourceOptions.VMToolsQuiesce -or $Bkjob.Options.ViSourceOptions.UseChangeTracking)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvVSphere {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.enableVMwareToolsQuiescence) = $Bkjob.Options.ViSourceOptions.VMToolsQuiesce
                                                        ($LocalizedData.useChangeBlockTracking) = $Bkjob.Options.ViSourceOptions.UseChangeTracking
                                                        ($LocalizedData.enableCBT) = $Bkjob.Options.ViSourceOptions.EnableChangeTracking
                                                        ($LocalizedData.resetCBTOnActiveFull) = $Bkjob.Options.ViSourceOptions.ResetChangeTrackingOnActiveFull
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvVSphere) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Advanced Settings (vSphere) Table: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvIntegration {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.enableBackupFromStorage) = $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots
                                                        ($LocalizedData.limitVMCountPerSnapshot) = $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotEnabled
                                                        ($LocalizedData.vmCountPerSnapshot) = $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotVmsCount
                                                        ($LocalizedData.failoverToStandardBackup) = $Bkjob.Options.SanIntegrationOptions.FailoverFromSan
                                                        ($LocalizedData.failoverToPrimarySnapshot) = $Bkjob.Options.SanIntegrationOptions.Failover2StorageSnapshotBackup
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvIntegration) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Advanced Settings (Integration) Table: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.JobScriptCommand.PreScriptEnabled -or $Bkjob.Options.JobScriptCommand.PostScriptEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvScript {
                                                $OutObj = @()
                                                try {
                                                    if ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Days') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Days -join ','
                                                        $FrequencyText = 'Run Script on the Selected Days'
                                                    } elseif ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Cycles') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Frequency
                                                        $FrequencyText = 'Run Script Every Backup Session'
                                                    }

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.runScriptBefore) = $Bkjob.Options.JobScriptCommand.PreScriptEnabled
                                                        ($LocalizedData.runScriptBeforeJob) = $Bkjob.Options.JobScriptCommand.PreScriptCommandLine
                                                        ($LocalizedData.runScriptAfter) = $Bkjob.Options.JobScriptCommand.PostScriptEnabled
                                                        ($LocalizedData.runScriptAfterJob) = $Bkjob.Options.JobScriptCommand.PostScriptCommandLine
                                                        ($LocalizedData.runScriptFrequency) = $Bkjob.Options.JobScriptCommand.Periodicity
                                                        $FrequencyText = $FrequencyValue

                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvScript) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Advanced Settings (Script) Table: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.RpoOptions.Enabled -or $Bkjob.Options.RpoOptions.LogBackupRpoEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvRPO {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        ($LocalizedData.rpoMonitorEnabled) = $Bkjob.Options.RpoOptions.Enabled
                                                        ($LocalizedData.ifBackupNotCopied) = "$($Bkjob.Options.RpoOptions.Value) $($Bkjob.Options.RpoOptions.TimeUnit)"
                                                        ($LocalizedData.logBackupRpoEnabled) = $Bkjob.Options.RpoOptions.LogBackupRpoEnabled
                                                        ($LocalizedData.ifLogBackupNotCopied) = "$($Bkjob.Options.RpoOptions.LogBackupRpoValue) $($Bkjob.Options.RpoOptions.LogBackupRpoTimeUnit)"
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvRPO) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Advanced Settings (RPO Monitor) Table: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Job Setting Section: $($_.Exception.Message)"
                                    }
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionDataTransfer {
                                        $OutObj = @()

                                        $inObj = [ordered] @{
                                            ($LocalizedData.sourceProxy) = switch (($Bkjob.GetProxy().Name).count) {
                                                0 { 'Unknown' }
                                                { $_ -gt 1 } { 'Automatic' }
                                                default { $Bkjob.GetProxy().Name }
                                            }
                                            ($LocalizedData.targetProxy) = switch (($Bkjob.GetTargetProxies().Name).count) {
                                                0 { 'Unknown' }
                                                { $_ -gt 1 } { 'Automatic' }
                                                default { $Bkjob.GetTargetProxies().Name }
                                            }
                                            ($LocalizedData.useWanAccelerator) = $Bkjob.IsWanAcceleratorEnabled()
                                        }

                                        if ($Bkjob.IsWanAcceleratorEnabled()) {
                                            try {
                                                $TargetWanAccelerator = $Bkjob.GetTargetWanAccelerator().Name
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Data Transfer GetTargetWanAccelerator Item: $($_.Exception.Message)"
                                            }
                                            try {
                                                $SourceWanAccelerator = $Bkjob.GetSourceWanAccelerator().Name
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Data Trsnfer GetSourceWanAccelerator Item: $($_.Exception.Message)"
                                            }
                                            $inObj.add('Source Wan accelerator', $SourceWanAccelerator)
                                            $inObj.add('Target Wan accelerator', $TargetWanAccelerator)
                                        }

                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeadingDataTransfer) - $($Bkjob.Name)"
                                            List = $True
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Data Trsnfer Section: $($_.Exception.Message)"
                                }
                                if ($Bkjob.Options.ViReplicaTargetOptions.InitialSeeding) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionSeeding {
                                            $OutObj = @()

                                            if ($Bkjob.Options.ViReplicaTargetOptions.EnableInitialPass) {
                                                $SeedRepo = $Bkjob.GetInitialRepository().Name
                                            } else { $SeedRepo = 'Disabled' }
                                            $inObj = [ordered] @{
                                                ($LocalizedData.seedFromBackupRepo) = $SeedRepo
                                                ($LocalizedData.mapReplicaToExistingVM) = $Bkjob.Options.ViReplicaTargetOptions.UseVmMapping
                                            }

                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeadingSeeding) - $($Bkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Seeding Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($Bkjob.VssOptions.Enabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionGuestProcessing {
                                        $OutObj = @()
                                        try {
                                            $VSSObjs = Get-VBRJobObject -Job $Bkjob.Name | Where-Object { $_.Type -eq 'Include' -or $_.Type -eq 'VssChild' } | Sort-Object -Property Name
                                            foreach ($VSSObj in $VSSObjs) {

                                                $inObj = [ordered] @{
                                                    ($LocalizedData.name) = $VSSObj.Name
                                                    ($LocalizedData.enabled) = $VSSObj.VssOptions.Enabled
                                                    ($LocalizedData.resourceType) = ($Bkjob.GetViOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq 'Include' -or $_.Type -eq 'VssChild') }).TypeDisplayName
                                                    ($LocalizedData.ignoreErrors) = $VSSObj.VssOptions.IgnoreErrors
                                                    ($LocalizedData.guestProxyAutoDetect) = $VSSObj.VssOptions.GuestProxyAutoDetect
                                                    ($LocalizedData.defaultCredential) = switch ((Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid }).count) {
                                                        0 { 'None' }
                                                        default { Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid } }
                                                    }
                                                    ($LocalizedData.objectCredential) = switch ($VSSObj.VssOptions.WinCredsId.Guid) {
                                                        '00000000-0000-0000-0000-000000000000' { 'Default Credential' }
                                                        default { Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.WinCredsId.Guid } }
                                                    }
                                                    ($LocalizedData.applicationProcessing) = $VSSObj.VssOptions.VssSnapshotOptions.ApplicationProcessingEnabled
                                                    ($LocalizedData.transactionLogs) = switch ($VSSObj.VssOptions.VssSnapshotOptions.IsCopyOnly) {
                                                        'False' { 'Process Transaction Logs' }
                                                        'True' { 'Perform Copy Only' }
                                                    }
                                                    ($LocalizedData.usePersistentGuestAgent) = $VSSObj.VssOptions.VssSnapshotOptions.UsePersistentGuestAgent
                                                }
                                                if ($InfoLevel.Jobs.Replication -ge 2) {
                                                    if (!$VSSObj.VssOptions.VssSnapshotOptions.IsCopyOnly) {
                                                        $TransactionLogsProcessing = switch ($VSSObj.VssOptions.SqlBackupOptions.TransactionLogsProcessing) {
                                                            'TruncateOnlyOnSuccessJob' { 'Truncate logs' }
                                                            'Backup' { 'Backup logs periodically' }
                                                            'NeverTruncate' { 'Do not truncate logs' }
                                                        }
                                                        $RetainLogBackups = switch ($VSSObj.VssOptions.SqlBackupOptions.UseDbBackupRetention) {
                                                            'True' { 'Until the corresponding image-level backup is deleted' }
                                                            'False' { "Keep Only Last $($VSSObj.VssOptions.SqlBackupOptions.RetainDays) days of log backups" }
                                                        }
                                                        $inObj.add('SQL Transaction Logs Processing', ($TransactionLogsProcessing))
                                                        $inObj.add('SQL Backup Log Every', ("$($VSSObj.VssOptions.SqlBackupOptions.BackupLogsFrequencyMin) min"))
                                                        $inObj.add('SQL Retain Log Backups', $($RetainLogBackups))
                                                    }
                                                    if ($VSSObj.VssOptions.OracleBackupOptions.BackupLogsEnabled -or $VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation) {
                                                        $ArchivedLogsTruncation = switch ($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation) {
                                                            'ByAge' { "Delete Log Older Than $($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsMaxAgeHours) hours" }
                                                            'BySize' { "Delete Log Over $([Math]::Round($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsMaxSizeMb / 1024, 0)) GB" }
                                                            default { $VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation }

                                                        }
                                                        $SysdbaCredsId = switch ($VSSObj.VssOptions.OracleBackupOptions.SysdbaCredsId) {
                                                            '00000000-0000-0000-0000-000000000000' { 'Guest OS Credential' }
                                                            default { (Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.OracleBackupOptions.SysdbaCredsId }).Description }
                                                        }
                                                        $RetainLogBackups = switch ($VSSObj.VssOptions.OracleBackupOptions.UseDbBackupRetention) {
                                                            'True' { 'Until the corresponding image-level backup is deleted' }
                                                            'False' { "Keep Only Last $($VSSObj.VssOptions.OracleBackupOptions.RetainDays) days of log backups" }
                                                        }
                                                        $inObj.add('Oracle Account Type', $VSSObj.VssOptions.OracleBackupOptions.AccountType)
                                                        $inObj.add('Oracle Sysdba Creds', $SysdbaCredsId)
                                                        if ($VSSObj.VssOptions.OracleBackupOptions.BackupLogsEnabled) {
                                                            $inObj.add('Oracle Backup Logs Every', ("$($VSSObj.VssOptions.OracleBackupOptions.BackupLogsFrequencyMin) min"))
                                                        }
                                                        $inObj.add('Oracle Archive Logs', ($ArchivedLogsTruncation))
                                                        $inObj.add('Oracle Retain Log Backups', $($RetainLogBackups))
                                                    }
                                                    if ($VSSObj.VssOptions.GuestFSExcludeOptions.FileExcludeEnabled) {
                                                        $inObj.add('File Exclusions', ($VSSObj.VssOptions.GuestFSExcludeOptions.FileExcludeEnabled))
                                                        if ($VSSObj.VssOptions.GuestFSExcludeOptions.BackupScope -eq 'ExcludeSpecifiedFolders') {
                                                            $inObj.add('Exclude the following file and folders', ($VSSObj.VssOptions.GuestFSExcludeOptions.ExcludeList -join ','))
                                                        } elseif ($VSSObj.VssOptions.GuestFSExcludeOptions.BackupScope -eq 'IncludeSpecifiedFolders') {
                                                            $inObj.add('Include only the following file and folders', ($VSSObj.VssOptions.GuestFSExcludeOptions.IncludeList -join ','))
                                                        }
                                                    }
                                                    if ($VSSObj.VssOptions.GuestScriptsOptions.ScriptingMode -ne 'Disabled') {
                                                        $ScriptingMode = switch ($VSSObj.VssOptions.GuestScriptsOptions.ScriptingMode) {
                                                            'FailJobOnError' { 'Require successfull script execution' }
                                                            'IgnoreErrors' { 'Ignore script execution failures' }
                                                            'Disabled' { 'Disable script execution' }
                                                        }
                                                        $inObj.add('Scripts', ($VSSObj.VssOptions.GuestScriptsOptions.IsAtLeastOneScriptSet))
                                                        $inObj.add('Scripts Mode', ($ScriptingMode))
                                                        if ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.IsAtLeastOneScriptSet) {
                                                            $inObj.add('Windows Pre-freeze script', ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.PreScriptFilePath))
                                                            $inObj.add('Windows Post-thaw script', ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.PostScriptFilePath))
                                                        } elseif ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.IsAtLeastOneScriptSet) {
                                                            $inObj.add('Linux Pre-freeze script', ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.PreScriptFilePath))
                                                            $inObj.add('Linux Post-thaw script', ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.PostScriptFilePath))
                                                        }
                                                    }
                                                }

                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.TableHeadingGuestProcessing) - $($VSSObj.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Guest Processing Section: $($_.Exception.Message)"e
                                        }
                                    }
                                }
                                if ($Bkjob.IsScheduleEnabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionSchedule {
                                        $OutObj = @()
                                        try {

                                            if ($Bkjob.ScheduleOptions.OptionsDaily.Enabled -eq 'True') {
                                                $ScheduleType = 'Daily'
                                                $Schedule = "Kind: $($Bkjob.ScheduleOptions.OptionsDaily.Kind),`r`nDays: $($Bkjob.ScheduleOptions.OptionsDaily.DaysSrv)"
                                            } elseif ($Bkjob.ScheduleOptions.OptionsMonthly.Enabled -eq 'True') {
                                                $ScheduleType = 'Monthly'
                                                $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfWeek)"
                                            } elseif ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled -eq 'True') {
                                                $ScheduleType = $Bkjob.ScheduleOptions.OptionsPeriodically.Kind
                                                $Schedule = "Full Period: $($Bkjob.ScheduleOptions.OptionsPeriodically.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.OptionsPeriodically.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.OptionsPeriodically.Unit)"
                                            } elseif ($Bkjob.ScheduleOptions.OptionsContinuous.Enabled -eq 'True') {
                                                $ScheduleType = 'Continuous'
                                                $Schedule = 'Schedule Time Period'
                                            }
                                            $inObj = [ordered] @{
                                                ($LocalizedData.retryFailedItem) = $Bkjob.ScheduleOptions.RetryTimes
                                                ($LocalizedData.waitBeforeRetry) = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                ($LocalizedData.backupWindow) = $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled
                                                ($LocalizedData.scheduleType) = $ScheduleType
                                                ($LocalizedData.scheduleOptions) = $Schedule
                                                ($LocalizedData.startTime) = $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                ($LocalizedData.latestRun) = $Bkjob.LatestRunLocal
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeadingSchedule) - $($Bkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if ($Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled -or $Bkjob.ScheduleOptions.OptionsContinuous.Enabled) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionBackupWindowTimePeriod {
                                                    Paragraph -ScriptBlock $Legend

                                                    $OutObj = @()
                                                    try {
                                                        $ScheduleTimePeriod = @()
                                                        $Days = 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
                                                        foreach ($Day in $Days) {

                                                            $Regex = [Regex]::new("(?<=<$Day>)(.*)(?=</$Day>)")
                                                            if ($Bkjob.TypeToString -eq 'VMware Backup Copy') {
                                                                $BackupWindow = $Bkjob.ScheduleOptions.OptionsContinuous.Schedule
                                                            } else { $BackupWindow = $Bkjob.ScheduleOptions.OptionsBackupWindow.BackupWindow }
                                                            $Match = $Regex.Match($BackupWindow)
                                                            if ($Match.Success) {
                                                                $ScheduleTimePeriod += $Match.Value
                                                            }
                                                        }

                                                        $OutObj = Get-WindowsTimePeriod -InputTimePeriod $ScheduleTimePeriod

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHeadingBackupWindow) - $($Bkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                            Key = 'H'
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        if ($OutObj) {
                                                            $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq '0' } | Set-Style -Style ON -Property 'Sun'
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq '0' } | Set-Style -Style ON -Property 'Mon'
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq '0' } | Set-Style -Style ON -Property 'Tue'
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq '0' } | Set-Style -Style ON -Property 'Wed'
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq '0' } | Set-Style -Style ON -Property 'Thu'
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq '0' } | Set-Style -Style ON -Property 'Fri'
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq '0' } | Set-Style -Style ON -Property 'Sat'

                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq '1' } | Set-Style -Style OFF -Property 'Sun'
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq '1' } | Set-Style -Style OFF -Property 'Mon'
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq '1' } | Set-Style -Style OFF -Property 'Tue'
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq '1' } | Set-Style -Style OFF -Property 'Wed'
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq '1' } | Set-Style -Style OFF -Property 'Thu'
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq '1' } | Set-Style -Style OFF -Property 'Fri'
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq '1' } | Set-Style -Style OFF -Property 'Sat'
                                                            $OutObj2
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Backup Windows Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "VMware Replication Jobs $($Bkjob.Name) Schedule Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "VMware Replication Jobs Configuration Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "VMware Replication Jobs Configuration Document: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'VMware Replication Jobs Configuration'
    }

}
