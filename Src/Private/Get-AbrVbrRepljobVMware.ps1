
function Get-AbrVbrRepljobVMware {
    <#
    .SYNOPSIS
        Used by As Built Report to returns vmware replication jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.5
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
        Write-PscriboMessage "Discovering Veeam VBR VMware replication jobs information from $System."
    }

    process {
        try {
            $Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-object {$_.TypeToString -eq 'VMware Replication'} | Sort-Object -Property Name
            if (($Bkjobs).count -gt 0) {
                Section -Style Heading3 'VMware Replication Jobs Configuration' {
                    Paragraph "The following section details the configuration abut VMware type backup jobs."
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($VMcount in $Bkjobs) {
                            try {
                                Write-PscriboMessage "Discovered $($VMcount.Name) ."
                                $inObj = [ordered] @{
                                    'Name' = $VMcount.Name
                                    'Creation Time' = $VMcount.CreationTime
                                    'VM Count' = (Get-VBRReplica | Where-Object {$_.JobName -eq $VMcount.Name}).VMcount
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "VMware Replication Summary - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 35, 35, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Common Information' {
                                    $OutObj = @()
                                    try {
                                        $CommonInfos = (Get-VBRJob -WarningAction SilentlyContinue | Where-object {$_.TypeToString -eq 'VMware Replication'}).Info
                                        foreach ($CommonInfo in $CommonInfos) {
                                            try {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) common information."
                                                $inObj = [ordered] @{
                                                    'Name' = $Bkjob.Name
                                                    'Type' = $Bkjob.TypeToString
                                                    'Total Backup Size' = ConvertTo-FileSizeString $CommonInfo.IncludedSize
                                                    'Target Address' = $CommonInfo.TargetDir
                                                    'Target File' = $CommonInfo.TargetFile
                                                    'Description' = $CommonInfo.CommonInfo.Description
                                                    'Modified By' = $CommonInfo.CommonInfo.ModifiedBy.FullName
                                                }
                                                $OutObj = [pscustomobject]$inobj
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "Common Information - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Destination' {
                                    $OutObj = @()
                                    try {
                                        foreach ($Destination in $Bkjob.ViReplicaTargetOptions) {
                                            try {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) destination information."
                                                if (!$Destination.ClusterName) {
                                                    $HostorCluster = (Find-VBRViEntity -ErrorAction SilentlyContinue | Where-Object { $_.Reference -eq $Destination.HostReference}).Name
                                                } else {$HostorCluster = $Destination.ClusterName}
                                                $inObj = [ordered]  @{
                                                    'Host or Cluster' = Switch ($HostorCluster) {
                                                        $Null {'Unknown'}
                                                        default {$HostorCluster}
                                                    }
                                                    'Resources Pool' = $Destination.ReplicaTargetResourcePoolName
                                                    'VM Folder' = $Destination.ReplicaTargetVmFolderName
                                                    'Datastore' = $Destination.DatastoreName
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "Destination - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($Bkjob.ViReplicaTargetOptions.UseNetworkMapping) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Network' {
                                        $OutObj = @()
                                        try {
                                            foreach ($NetMapping in $Bkjob.Options.ViNetworkMappingOptions.NetworkMapping) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) network mapping information."
                                                    $inObj = [ordered] @{
                                                        'Source Network' = $NetMapping.SourceNetwork
                                                        'Target Network' = $NetMapping.TargetNetwork
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Network Mappings - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 50, 50
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Source Network' | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.Options.ViReplicaTargetOptions.UseReIP) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Re-IP Rules' {
                                        $OutObj = @()
                                        try {
                                            foreach ($ReIpRule in $Bkjob.Options.ReIPRulesOptions.Rules) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) re-ip rules $($ReIpRule.Source.IPAddress) information."
                                                    $inObj = [ordered] @{
                                                        'Source IP Address' = $ReIpRule.Source.IPAddress
                                                        'Source Subnet Mask' = $ReIpRule.Source.SubnetMask
                                                        'Target P Address' = $ReIpRule.Target.IPAddress
                                                        'Target Subnet Mask' = $ReIpRule.Target.SubnetMask
                                                        'Target Default Gateway' = $ReIpRule.Target.DefaultGateway
                                                        'Target DNS Addresses' = $ReIpRule.Target.DNSAddresses
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Re-IP Rules - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 17, 17, 17, 17, 16, 16
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Source IP Address' | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.GetViOijs()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Virtual Machines" {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetViOijs() | Where-Object {$_.Type -eq "Include" -or $_.Type -eq "Exclude"} )) {
                                                Write-PscriboMessage "Discovered $($OBJ.Name) object to replicate."
                                                $inObj = [ordered] @{
                                                    'Name' = $OBJ.Name
                                                    'Resource Type' = $OBJ.TypeDisplayName
                                                    'Role' = $OBJ.Type
                                                    'Location' = $OBJ.Location
                                                    'Approx Size' = $OBJ.ApproxSizeString
                                                    'Disk Filter Mode' = $OBJ.DiskFilterInfo.Mode
                                                }
                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Virtual Machines - $($OBJ.Name)"
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
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Job Settings' {
                                    $OutObj = @()
                                    try {
                                        Write-PscriboMessage "Discovered $($Bkjob.Name) storage options."
                                        if ($Bkjob.BackupStorageOptions.RetentionType -eq "Days") {
                                            $RetainString = 'Restore Point To Keep'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainDaysToKeep
                                        }
                                        elseif ($Bkjob.BackupStorageOptions.RetentionType -eq "Cycles") {
                                            $RetainString = 'Retain Cycles'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainCycles
                                        }
                                        $inObj = [ordered] @{
                                            'Repository for replica metadata' = Switch ($Bkjob.info.TargetRepositoryId) {
                                                '00000000-0000-0000-0000-000000000000' {$Bkjob.TargetDir}
                                                {$Null -eq (Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name} {(Get-VBRBackupRepository -ScaleOut | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                                                default {(Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                                            }
                                            'Replica Name Suffix' = $Bkjob.Options.ViReplicaTargetOptions.ReplicaNameSuffix
                                            $RetainString = $Retains
                                        }
                                        $OutObj = [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "$Storage Options - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.GenerationPolicy.EnableRechek -or $Bkjob.Options.GenerationPolicy.EnableCompactFull)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Maintenance)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) maintenance options."
                                                    $inObj = [ordered] @{
                                                        'Storage-Level Corruption Guard (SLCG)' = ConvertTo-TextYN $Bkjob.Options.GenerationPolicy.EnableRechek
                                                        'SLCG Schedule Type' = $Bkjob.Options.GenerationPolicy.RecheckScheduleKind
                                                        'SLCG Schedule Day' = $Bkjob.Options.GenerationPolicy.RecheckDays
                                                        'SLCG Backup Monthly Schedule' = "Day Of Week: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.Months)"
                                                        'Defragment and Compact Full Backup (DCFB)' = ConvertTo-TextYN $Bkjob.Options.GenerationPolicy.EnableCompactFull
                                                        'DCFB Schedule Type' = $Bkjob.Options.GenerationPolicy.CompactFullBackupScheduleKind
                                                        'DCFB Schedule Day' = $Bkjob.Options.GenerationPolicy.CompactFullBackupDays
                                                        'DCFB Backup Monthly Schedule' = "Day Of Week: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.Months)"
                                                        'Remove deleted item data after' = $Bkjob.Options.BackupStorageOptions.RetainDays
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Maintenance) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Traffic)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) traffic options."
                                                    $inObj = [ordered] @{
                                                        'Inline Data Deduplication' = ConvertTo-TextYN $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                        'Exclude Swap Files Block' = ConvertTo-TextYN $Bkjob.ViSourceOptions.ExcludeSwapFile
                                                        'Exclude Deleted Files Block' = ConvertTo-TextYN $Bkjob.ViSourceOptions.DirtyBlocksNullingEnabled
                                                        'Compression Level' = Switch ($Bkjob.Options.BackupStorageOptions.CompressionLevel) {
                                                            0 {'NONE'}
                                                            -1 {'AUTO'}
                                                            4 {'DEDUPE_friendly'}
                                                            5 {'OPTIMAL (Default)'}
                                                            6 {'High'}
                                                            9 {'EXTREME'}
                                                        }
                                                        'Storage optimization' = Switch ($Bkjob.Options.BackupStorageOptions.StgBlockSize) {
                                                            'KbBlockSize1024' {'Local target'}
                                                            'KbBlockSize512' {'LAN target'}
                                                            'KbBlockSize256' {'WAN target'}
                                                            'KbBlockSize4096' {'Local target (large blocks)'}
                                                            default {$Bkjob.Options.BackupStorageOptions.StgBlockSize}
                                                        }
                                                        'Enabled Backup File Encryption' = ConvertTo-TextYN $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                                        'Encryption Key' = Switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                            $false {'None'}
                                                            default {(Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description}
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Traffic) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.NotificationOptions.SnmpNotification -or $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Notification)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) notification options."
                                                    $inObj = [ordered] @{
                                                        'Send Snmp Notification' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.SnmpNotification
                                                        'Send Email Notification' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses
                                                        'Email Notification Additional Addresses' = $Bkjob.Options.NotificationOptions.EmailNotificationAdditionalAddresses
                                                        'Email Notify Time' = $Bkjob.Options.NotificationOptions.EmailNotifyTime.ToShortTimeString()
                                                        'Use Custom Email Notification Options' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.UseCustomEmailNotificationOptions
                                                        'Use Custom Notification Setting' = $Bkjob.Options.NotificationOptions.EmailNotificationSubject
                                                        'Notify On Success' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnSuccess
                                                        'Notify On Warning' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnWarning
                                                        'Notify On Error' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnError
                                                        'Suppress Notification until Last Retry' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnLastRetryOnly
                                                        'Set Results To Vm Notes' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.SetResultsToVmNotes
                                                        'VM Attribute Note Value' = $Bkjob.Options.ViSourceOptions.VmAttributeName
                                                        'Append to Existing Attribute' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.VmNotesAppend
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Notification) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.ViSourceOptions.VMToolsQuiesce -or $Bkjob.Options.ViSourceOptions.UseChangeTracking)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (vSphere)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) vSphere options."
                                                    $inObj = [ordered] @{
                                                        'Enable VMware Tools Quiescence' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.VMToolsQuiesce
                                                        'Use Change Block Tracking' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.UseChangeTracking
                                                        'Enable CBT for all protected VMs' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.EnableChangeTracking
                                                        'Reset CBT On each Active Full Backup' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.ResetChangeTrackingOnActiveFull
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (vSphere) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Integration)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) Integration options."
                                                    $inObj = [ordered] @{
                                                        'Enable Backup from Storage Snapshots' = ConvertTo-TextYN $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots
                                                        'Limit processed VM count per Storage Snapshot' = ConvertTo-TextYN $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotEnabled
                                                        'VM count per Storage Snapshot' = $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotVmsCount
                                                        'Failover to Standard Backup' = ConvertTo-TextYN $Bkjob.Options.SanIntegrationOptions.FailoverFromSan
                                                        'Failover to Primary Storage Snapshot' = ConvertTo-TextYN $Bkjob.Options.SanIntegrationOptions.Failover2StorageSnapshotBackup
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Integration) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.JobScriptCommand.PreScriptEnabled -or $Bkjob.Options.JobScriptCommand.PostScriptEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Script)" {
                                                $OutObj = @()
                                                try {
                                                    if ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Days') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Days -join ","
                                                        $FrequencyText = 'Run Script on the Selected Days'
                                                    }
                                                    elseif ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Cycles') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Frequency
                                                        $FrequencyText = 'Run Script Every Backup Session'
                                                    }
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) script options."
                                                    $inObj = [ordered] @{
                                                        'Run the Following Script Before' = ConvertTo-TextYN $Bkjob.Options.JobScriptCommand.PreScriptEnabled
                                                        'Run Script Before the Job' = $Bkjob.Options.JobScriptCommand.PreScriptCommandLine
                                                        'Run the Following Script After' = ConvertTo-TextYN $Bkjob.Options.JobScriptCommand.PostScriptEnabled
                                                        'Run Script After the Job' = $Bkjob.Options.JobScriptCommand.PostScriptCommandLine
                                                        'Run Script Frequency' = $Bkjob.Options.JobScriptCommand.Periodicity
                                                        $FrequencyText = $FrequencyValue

                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Script) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Replication -ge 2 -and ($Bkjob.Options.RpoOptions.Enabled -or $Bkjob.Options.RpoOptions.LogBackupRpoEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (RPO Monitor)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) rpo monitor options."
                                                    $inObj = [ordered] @{
                                                        'RPO Monitor Enabled' = ConvertTo-TextYN $Bkjob.Options.RpoOptions.Enabled
                                                        'If Backup is not Copied Within' = "$($Bkjob.Options.RpoOptions.Value) $($Bkjob.Options.RpoOptions.TimeUnit)"
                                                        'Log Backup RPO Monitor Enabled' = ConvertTo-TextYN $Bkjob.Options.RpoOptions.LogBackupRpoEnabled
                                                        'If Log Backup is not Copied Within' = "$($Bkjob.Options.RpoOptions.LogBackupRpoValue) $($Bkjob.Options.RpoOptions.LogBackupRpoTimeUnit)"
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (RPO Monitor) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Data Transfer' {
                                        $OutObj = @()
                                        Write-PscriboMessage "Discovered $($Bkjob.Name) data transfer."
                                        $inObj = [ordered] @{
                                            'Source Proxy' = Switch (($Bkjob.GetProxy().Name).count) {
                                                0 {"Unknown"}
                                                {$_ -gt 1} {"Automatic"}
                                                default {$Bkjob.GetProxy().Name}
                                            }
                                            'Target Proxy' = Switch (($Bkjob.GetTargetProxies().Name).count) {
                                                0 {"Unknown"}
                                                {$_ -gt 1} {"Automatic"}
                                                default {$Bkjob.GetTargetProxies().Name}
                                            }
                                            'Use Wan accelerator' = ConvertTo-TextYN $Bkjob.IsWanAcceleratorEnabled()
                                        }

                                        if ($Bkjob.IsWanAcceleratorEnabled()) {
                                            try {
                                                $TargetWanAccelerator = $Bkjob.GetTargetWanAccelerator().Name
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                            try {
                                                $SourceWanAccelerator = $Bkjob.GetSourceWanAccelerator().Name
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                            $inObj.add('Source Wan accelerator', $SourceWanAccelerator)
                                            $inObj.add('Target Wan accelerator', $TargetWanAccelerator)
                                        }

                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Data Transfer - $($Bkjob.Name)"
                                            List = $True
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                                if ($Bkjob.Options.ViReplicaTargetOptions.InitialSeeding) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Seeding' {
                                            $OutObj = @()
                                            Write-PscriboMessage "Discovered $($Bkjob.Name) seeding information."
                                            if ($Bkjob.Options.ViReplicaTargetOptions.EnableInitialPass) {
                                                $SeedRepo = $Bkjob.GetInitialRepository().Name
                                            } else {$SeedRepo = 'Disabled'}
                                            $inObj = [ordered] @{
                                                'Seed from Backup Repository' = $SeedRepo
                                                'Map Replica to Existing VM' = ConvertTo-TextYN $Bkjob.Options.ViReplicaTargetOptions.UseVmMapping
                                            }

                                            $OutObj += [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Seeding - $($Bkjob.Name)"
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
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($Bkjob.VssOptions.Enabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Guest Processing" {
                                        $OutObj = @()
                                        try {
                                            $VSSObjs = Get-VBRJobObject -Job $Bkjob.Name | Where-Object {$_.Type -eq "Include" -or $_.Type -eq "VssChild"}
                                            foreach ($VSSObj in $VSSObjs) {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) guest processing."
                                                $inObj = [ordered] @{
                                                    'Name' = $VSSObj.Name
                                                    'Enabled' = ConvertTo-TextYN $VSSObj.VssOptions.Enabled
                                                    'Resource Type' = ($Bkjob.GetViOijs() | Where-Object {$_.Name -eq $VSSObj.Name -and ($_.Type -eq "Include" -or $_.Type -eq "VssChild")}).TypeDisplayName
                                                    'Ignore Errors' = ConvertTo-TextYN $VSSObj.VssOptions.IgnoreErrors
                                                    'Guest Proxy Auto Detect' = ConvertTo-TextYN  $VSSObj.VssOptions.GuestProxyAutoDetect
                                                    'Default Credential' = Switch ((Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid}).count) {
                                                        0 {'None'}
                                                        Default {Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid}}
                                                    }
                                                    'Object Credential' = Switch ($VSSObj.VssOptions.WinCredsId.Guid) {
                                                        '00000000-0000-0000-0000-000000000000' {'Default Credential'}
                                                        default {Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.WinCredsId.Guid}}
                                                    }
                                                    'Application Processing' = ConvertTo-TextYN $VSSObj.VssOptions.VssSnapshotOptions.ApplicationProcessingEnabled
                                                    'Transaction Logs' = Switch ($VSSObj.VssOptions.VssSnapshotOptions.IsCopyOnly) {
                                                        'False' {'Process Transaction Logs'}
                                                        'True' {'Perform Copy Only'}
                                                    }
                                                    'Use Persistent Guest Agent' = ConvertTo-TextYN $VSSObj.VssOptions.VssSnapshotOptions.UsePersistentGuestAgent
                                                }
                                                if ($InfoLevel.Jobs.Replication -ge 2) {
                                                    if (!$VSSObj.VssOptions.VssSnapshotOptions.IsCopyOnly) {
                                                        $TransactionLogsProcessing = Switch ($VSSObj.VssOptions.SqlBackupOptions.TransactionLogsProcessing) {
                                                            'TruncateOnlyOnSuccessJob' {'Truncate logs'}
                                                            'Backup' {'Backup logs periodically'}
                                                            'NeverTruncate' {'Do not truncate logs'}
                                                        }
                                                        $RetainLogBackups = Switch ($VSSObj.VssOptions.SqlBackupOptions.UseDbBackupRetention) {
                                                            'True' {'Until the corresponding image-level backup is deleted'}
                                                            'False' {"Keep Only Last $($VSSObj.VssOptions.SqlBackupOptions.RetainDays) days of log backups"}
                                                        }
                                                        $inObj.add('SQL Transaction Logs Processing', ($TransactionLogsProcessing))
                                                        $inObj.add('SQL Backup Log Every', ("$($VSSObj.VssOptions.SqlBackupOptions.BackupLogsFrequencyMin) min"))
                                                        $inObj.add('SQL Retain Log Backups', $($RetainLogBackups))
                                                    }
                                                    if ($VSSObj.VssOptions.OracleBackupOptions.BackupLogsEnabled -or $VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation) {
                                                        $ArchivedLogsTruncation = Switch ($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation) {
                                                            'ByAge' {"Delete Log Older Than $($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsMaxAgeHours) hours"}
                                                            'BySize' {"Delete Log Over $([Math]::Round($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsMaxSizeMb / 1024, 0)) GB"}
                                                            default {$VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation}

                                                        }
                                                        $SysdbaCredsId = Switch ($VSSObj.VssOptions.OracleBackupOptions.SysdbaCredsId) {
                                                            '00000000-0000-0000-0000-000000000000' {'Guest OS Credential'}
                                                            default {(Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.OracleBackupOptions.SysdbaCredsId}).Description}
                                                        }
                                                        $RetainLogBackups = Switch ($VSSObj.VssOptions.OracleBackupOptions.UseDbBackupRetention) {
                                                            'True' {'Until the corresponding image-level backup is deleted'}
                                                            'False' {"Keep Only Last $($VSSObj.VssOptions.OracleBackupOptions.RetainDays) days of log backups"}
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
                                                        $inObj.add('File Exclusions', (ConvertTo-TextYN $VSSObj.VssOptions.GuestFSExcludeOptions.FileExcludeEnabled))
                                                        if ($VSSObj.VssOptions.GuestFSExcludeOptions.BackupScope -eq 'ExcludeSpecifiedFolders') {
                                                            $inObj.add('Exclude the following file and folders', ($VSSObj.VssOptions.GuestFSExcludeOptions.ExcludeList -join ','))
                                                        }
                                                        elseif ($VSSObj.VssOptions.GuestFSExcludeOptions.BackupScope -eq 'IncludeSpecifiedFolders') {
                                                            $inObj.add('Include only the following file and folders', ($VSSObj.VssOptions.GuestFSExcludeOptions.IncludeList-join ','))
                                                        }
                                                    }
                                                    if ($VSSObj.VssOptions.GuestScriptsOptions.ScriptingMode -ne 'Disabled') {
                                                        $ScriptingMode = Switch ($VSSObj.VssOptions.GuestScriptsOptions.ScriptingMode) {
                                                            'FailJobOnError' {'Require successfull script execution'}
                                                            'IgnoreErrors' {'Ignore script execution failures'}
                                                            'Disabled' {'Disable script execution'}
                                                        }
                                                        $inObj.add('Scripts', (ConvertTo-TextYN $VSSObj.VssOptions.GuestScriptsOptions.IsAtLeastOneScriptSet))
                                                        $inObj.add('Scripts Mode', ($ScriptingMode))
                                                        if ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.IsAtLeastOneScriptSet) {
                                                            $inObj.add('Windows Pre-freeze script', ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.PreScriptFilePath))
                                                            $inObj.add('Windows Post-thaw script', ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.PostScriptFilePath))
                                                        }
                                                        elseif ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.IsAtLeastOneScriptSet) {
                                                            $inObj.add('Linux Pre-freeze script', ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.PreScriptFilePath))
                                                            $inObj.add('Linux Post-thaw script', ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.PostScriptFilePath))
                                                        }
                                                    }
                                                }

                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Guest Processing Options - $($VSSObj.Name)"
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
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.GetScheduleOptions().NextRun) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                        $OutObj = @()
                                        try {
                                            Write-PscriboMessage "Discovered $($Bkjob.Name) schedule options."
                                            if ($Bkjob.ScheduleOptions.OptionsDaily.Enabled -eq "True") {
                                                $ScheduleType = "Daily"
                                                $Schedule = "Kind: $($Bkjob.ScheduleOptions.OptionsDaily.Kind),`r`nDays: $($Bkjob.ScheduleOptions.OptionsDaily.DaysSrv)"
                                            }
                                            elseif ($Bkjob.ScheduleOptions.OptionsMonthly.Enabled -eq "True") {
                                                $ScheduleType = "Monthly"
                                                $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfWeek)"
                                            }
                                            elseif ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled -eq "True") {
                                                $ScheduleType = $Bkjob.ScheduleOptions.OptionsPeriodically.Kind
                                                $Schedule = "Full Period: $($Bkjob.ScheduleOptions.OptionsPeriodically.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.OptionsPeriodically.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.OptionsPeriodically.Unit)"
                                            }
                                            elseif ($Bkjob.ScheduleOptions.OptionsContinuous.Enabled -eq "True") {
                                                $ScheduleType = 'Continuous'
                                                $Schedule = "Schedule Time Period"
                                            }
                                            $inObj = [ordered] @{
                                                'Retry Failed item' = $Bkjob.ScheduleOptions.RetryTimes
                                                'Wait before each retry' = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                'Backup Window' = ConvertTo-TextYN $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled
                                                'Shedule type' = $ScheduleType
                                                'Shedule Options' = $Schedule
                                                'Start Time' =  $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                'Latest Run' =  $Bkjob.LatestRunLocal
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Schedule Options - $($Bkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
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
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}
