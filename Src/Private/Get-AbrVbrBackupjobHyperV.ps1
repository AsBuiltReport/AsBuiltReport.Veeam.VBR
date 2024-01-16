
function Get-AbrVbrBackupjobHyperV {
    <#
    .SYNOPSIS
        Used by As Built Report to returns hyper-v backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.4
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
        Write-PscriboMessage "Discovering Veeam VBR Hyper-V Backup jobs information from $System."
    }

    process {
        try {
            $Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.TypeToString -eq "Hyper-V Backup" -or $_.TypeToString -eq "Hyper-V Backup Copy"} | Sort-Object -Property Name
            if (($Bkjobs).count -gt 0) {
                Section -Style Heading3 'Hyper-V Backup Jobs Configuration' {
                    Paragraph "The following section details the configuration of the Hyper-V type backup jobs."
                    BlankLine
                    $OutObj = @()
                    try {
                        $VMcounts = Get-VBRBackup | Where-Object {$_.TypeToString -eq "Hyper-V Backup" -or $_.TypeToString -eq "Hyper-V Backup Copy"}
                        if ($VMcounts) {
                            foreach ($VMcount in $VMcounts) {
                                try {
                                    Write-PscriboMessage "Discovered $($VMcount.Name) ."
                                    $inObj = [ordered] @{
                                        'Name' = $VMcount.Name
                                        'Creation Time' = $VMcount.CreationTime
                                        'VM Count' = $VMcount.VmCount
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Configuration Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "Hyper-V Backup Summary - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 35, 35, 30
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Configuration Section: $($_.Exception.Message)"
                    }
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading4 -ExcludeFromTOC 'Common Information' {
                                    $OutObj = @()
                                    try {
                                        $CommonInfos = (Get-VBRJob -WarningAction SilentlyContinue -Name $Bkjob.Name | Where-object {$_.TypeToString -ne 'Windows Agent Backup'}).Info
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
                                                Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Common Information Section: $($_.Exception.Message)"
                                            }
                                        }

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $Null -like $_.'Description' } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
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
                                    catch {
                                        Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Common Information Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Linked Backup Jobs' {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedBkJob in $Bkjob.LinkedJobs) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) linked backup job."
                                                    $Job = Get-VBRJob -WarningAction SilentlyContinue| Where-Object {$_.Id -eq  $LinkedBkJob.info.LinkedObjectId}
                                                    $inObj = [ordered] @{
                                                        'Name' = $Job.Name
                                                        'Type' = $Job.TypeToString
                                                        'Size' = ConvertTo-FileSizeString $Job.Info.IncludedSize
                                                        'Repository' = $Job.GetTargetRepository().Name
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Linked Backup Jobs Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Linked Backup Jobs - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 25, 15, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Linked Backup Jobs Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Data Transfer' {
                                        $OutObj = @()
                                        try {
                                            try {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) data transfer."
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
                                                }
                                                $inObj = [ordered] @{
                                                    'Use Wan accelerator' = ConvertTo-TextYN $Bkjob.IsWanAcceleratorEnabled()
                                                    'Source Wan accelerator' = Switch ($Bkjob.IsWanAcceleratorEnabled()) {
                                                        'False' {'Direct Mode'}
                                                        'True' {$SourceWanAccelerator}
                                                        default {'Unknown'}
                                                    }
                                                    'Target Wan accelerator' = Switch ($Bkjob.IsWanAcceleratorEnabled()) {
                                                        'False' {'Direct Mode'}
                                                        'True' {$TargetWanAccelerator}
                                                        default {'Unknown'}
                                                    }
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Data Transfer Section: $($_.Exception.Message)"
                                            }

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
                                        catch {
                                            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Data Transfer Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                                if ($Bkjob.GetHvOijs()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Virtual Machines" {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetObjectsInJob() | Where-Object {$_.Type -eq "Include" -or $_.Type -eq "Exclude"} )) {
                                                Write-PscriboMessage "Discovered $($OBJ.Name) object to backup."
                                                $inObj = [ordered] @{
                                                    'Name' = $OBJ.Object.Name
                                                    'Resource Type' = $OBJ.Object.Info.Type
                                                    'Role' = $OBJ.Type
                                                    'Approx Size' = $OBJ.ApproxSizeString
                                                    'Disk Filter Mode' = $OBJ.DiskFilterInfo.Mode
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }

                                            $TableParams = @{
                                                Name = "Virtual Machines - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 20, 20, 20, 20, 20
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Virtual Machine Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                                if ($Bkjob.TypeToString -eq "Hyper-V Backup Copy") {
                                    $Storage = 'Target'
                                } else {$Storage = 'Storage'}
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $Storage {
                                    $OutObj = @()
                                    try {
                                        Write-PscriboMessage "Discovered $($Bkjob.Name) storage options."
                                        if ($Bkjob.BackupStorageOptions.RetentionType -eq "Days") {
                                            $RetainString = 'Retain Days To Keep'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainDaysToKeep
                                        }
                                        elseif ($Bkjob.BackupStorageOptions.RetentionType -eq "Cycles") {
                                            $RetainString = 'Retain Cycles'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainCycles
                                        }
                                        $inObj = [ordered] @{
                                            'Backup Proxy' = Switch (($Bkjob.GetProxy().Name).count) {
                                                0 {"Unknown"}
                                                {$_ -gt 1} {"Automatic"}
                                                default {$Bkjob.GetProxy().Name}
                                            }
                                            'Backup Repository' = Switch ($Bkjob.info.TargetRepositoryId) {
                                                '00000000-0000-0000-0000-000000000000' {$Bkjob.TargetDir}
                                                {$Null -eq (Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name} {(Get-VBRBackupRepository -ScaleOut | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                                                default {(Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                                            }
                                            'Retention Type' = $Bkjob.BackupStorageOptions.RetentionType
                                            $RetainString = $Retains
                                            'Keep First Full Backup' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.KeepFirstFullBackup
                                            'Enable Full Backup' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.EnableFullBackup
                                            'Integrity Checks' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.EnableIntegrityChecks
                                            'Storage Encryption' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.StorageEncryptionEnabled
                                            'Backup Mode' = Switch ($Bkjob.Options.BackupTargetOptions.Algorithm) {
                                                'Syntethic' {"Reverse Incremental"}
                                                'Increment' {'Incremental'}
                                            }
                                            'Active Full Backup Schedule Kind' = $Bkjob.Options.BackupTargetOptions.FullBackupScheduleKind
                                            'Active Full Backup Days' = $Bkjob.Options.BackupTargetOptions.FullBackupDays
                                            'Transform Full To Syntethic' = ConvertTo-TextYN $Bkjob.Options.BackupTargetOptions.TransformFullToSyntethic
                                            'Transform Increments To Syntethic' = ConvertTo-TextYN $Bkjob.Options.BackupTargetOptions.TransformIncrementsToSyntethic
                                            'Transform To Syntethic Days' = $Bkjob.Options.BackupTargetOptions.TransformToSyntethicDays


                                        }
                                        if ($Bkjob.Options.GfsPolicy.IsEnabled) {
                                            $inObj.add('Keep certain full backup longer for archival purposes (GFS)',(ConvertTo-TextYN $Bkjob.Options.GfsPolicy.IsEnabled))
                                            if (-Not $Bkjob.Options.GfsPolicy.Weekly.IsEnabled) {
                                                $inObj.add('Keep Weekly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Weekly full backup for', ("$($Bkjob.Options.GfsPolicy.Weekly.KeepBackupsForNumberOfWeeks) weeks,`r`nIf multiple backup exist use the one from: $($Bkjob.Options.GfsPolicy.Weekly.DesiredTime)"))
                                            }
                                            if (-Not $Bkjob.Options.GfsPolicy.Monthly.IsEnabled) {
                                                $inObj.add('Keep Monthly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Monthly full backup for', ("$($Bkjob.Options.GfsPolicy.Monthly.KeepBackupsForNumberOfMonths) months,`r`nUse weekly full backup from the following week of the month: $($Bkjob.Options.GfsPolicy.Monthly.DesiredTime)"))
                                            }
                                            if (-Not $Bkjob.Options.GfsPolicy.Yearly.IsEnabled) {
                                                $inObj.add('Keep Yearly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Yearly full backup for', ("$($Bkjob.Options.GfsPolicy.Yearly.KeepBackupsForNumberOfYears) years,`r`nUse monthly full backup from the following month: $($Bkjob.Options.GfsPolicy.Yearly.DesiredTime)"))
                                            }
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
                                        if ($InfoLevel.Jobs.Backup -ge 2) {
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

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.'Storage-Level Corruption Guard (SLCG)' -eq "No" } | Set-Style -Style Warning -Property 'Storage-Level Corruption Guard (SLCG)'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Maintenance) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.'Storage-Level Corruption Guard (SLCG)' -eq 'No' }) {
                                                            Paragraph "Health Check:" -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text "Best Practice:" -Bold
                                                                Text "It is recommended to use storage-level corruption guard for any backup job with no active full backups scheduled. Synthetic full backups are still 'incremental forever' and may suffer from corruption over time. Storage-level corruption guard was introduced to provide a greater level of confidence in integrity of the backups."
                                                            }
                                                        }
                                                    }
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Storage Options Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Backup -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Storage)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) storage options."
                                                    $inObj = [ordered] @{
                                                        'Inline Data Deduplication' = ConvertTo-TextYN $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                        'Exclude Swap Files Block' = ConvertTo-TextYN $Bkjob.HvSourceOptions.ExcludeSwapFile
                                                        'Exclude Deleted Files Block' = ConvertTo-TextYN $Bkjob.HvSourceOptions.DirtyBlocksNullingEnabled
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

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.'Enabled Backup File Encryption' -eq 'No'} | Set-Style -Style Warning -Property 'Enabled Backup File Encryption'
                                                        $OutObj | Where-Object { $_.'Exclude Swap Files Block' -eq 'No'} | Set-Style -Style Warning -Property 'Exclude Swap Files Block'
                                                        $OutObj | Where-Object { $_.'Exclude Deleted Files Block' -eq 'No'} | Set-Style -Style Warning -Property 'Exclude Deleted Files Block'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Storage) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.'Enabled Backup File Encryption' -eq 'No'}) {
                                                            Paragraph "Health Check:" -Bold -Underline
                                                            Blankline
                                                            Paragraph {
                                                                Text "Best Practice:" -Bold
                                                                Text "Backup and replica data is a high potential source of vulnerability. To secure data stored in backups and replicas, use Veeam Backup & Replication inbuilt encryption to protect data in backups"
                                                            }
                                                        }
                                                    }
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Advanced Settings (Storage) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Backup -ge 2 -and ($Bkjob.Options.NotificationOptions.SnmpNotification -or $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses)) {
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
                                                        'Set Results To Vm Notes' = ConvertTo-TextYN $Bkjob.Options.HvSourceOptions.SetResultsToVmNotes
                                                        'VM Attribute Note Value' = $Bkjob.Options.HvSourceOptions.VmAttributeName
                                                        'Append to Existing Attribute' = ConvertTo-TextYN $Bkjob.Options.HvSourceOptions.VmNotesAppend
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
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Advanced Settings (Notification) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Backup -ge 2 -and ($Bkjob.Options.HvSourceOptions.EnableHvQuiescence -or $Bkjob.Options.HvSourceOptions.UseChangeTracking)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Hyper-V)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) Hyper-V options."
                                                    $inObj = [ordered] @{
                                                        'Enable Hyper-V Guest Quiescence' = ConvertTo-TextYN $Bkjob.Options.HvSourceOptions.EnableHvQuiescence
                                                        'Crash Consistent Backup' = ConvertTo-TextYN $Bkjob.Options.HvSourceOptions.CanDoCrashConsistent
                                                        'Use Change Block Tracking' = ConvertTo-TextYN $Bkjob.Options.HvSourceOptions.UseChangeTracking
                                                        'Volume Snapshot' = ConvertTo-TextYN $Bkjob.Options.HvSourceOptions.GroupSnapshotProcessing
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Hyper-V) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Advanced Settings (Hyper-V) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Backup -ge 2 -and $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots) {
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
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Advanced Settings (Integration) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Backup -ge 2 -and ($Bkjob.Options.JobScriptCommand.PreScriptEnabled -or $Bkjob.Options.JobScriptCommand.PostScriptEnabled)) {
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
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Advanced Settings (Script) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Backup -ge 2 -and ($Bkjob.Options.RpoOptions.Enabled -or $Bkjob.Options.RpoOptions.LogBackupRpoEnabled)) {
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
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Advanced Settings (RPO Monitor) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Storage Options Section: $($_.Exception.Message)"
                                    }
                                }
                                $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($Bkjob.Id) | Where-Object {$_.JobType -ne 'SimpleBackupCopyWorker'}
                                if ($SecondaryTargets) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Secondary Target" {
                                        $OutObj = @()
                                        try {
                                            foreach ($SecondaryTarget in $SecondaryTargets) {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) secondary target."
                                                try {
                                                    $inObj = [ordered] @{
                                                        'Job Name' = $SecondaryTarget.Name
                                                        'Type' = $SecondaryTarget.TypeToString
                                                        'State' = $SecondaryTarget.info.LatestStatus
                                                        'Description' = $SecondaryTarget.Description
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Secondary Target Section: $($_.Exception.Message)"
                                                }
                                            }
                                            $TableParams = @{
                                                Name = "Secondary Destination Jobs - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 25, 25, 15, 35
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Job Name' | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Secondary Target Section: $($_.Exception.Message)"
                                        }
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
                                                    'Resource Type' = ($Bkjob.GetHvOijs() | Where-Object {$_.Name -eq $VSSObj.Name -and ($_.Type -eq "Include" -or $_.Type -eq "VssChild")}).TypeDisplayName
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
                                                if ($InfoLevel.Jobs.Backup -ge 2) {
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
                                            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Guest Processing Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                                if ($Bkjob.IsScheduleEnabled) {
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
                                                'Backup Window' = Switch ($Bkjob.TypeToString) {
                                                    "Hyper-V Backup Copy" {ConvertTo-TextYN $Bkjob.ScheduleOptions.OptionsContinuous.Enabled}
                                                    default {ConvertTo-TextYN $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled}
                                                }
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
                                            if ($Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled -or $Bkjob.ScheduleOptions.OptionsContinuous.Enabled) {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Backup Window Time Period" {
                                                    Paragraph {
                                                        Text 'Permited \' -Color 81BC50 -Bold
                                                        Text ' Denied' -Color dddf62 -Bold
                                                    }

                                                    try {

                                                        $ScheduleTimePeriod = @()
                                                        $Days = 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
                                                        foreach ($Day in $Days) {

                                                            $Regex = [Regex]::new("(?<=<$Day>)(.*)(?=</$Day>)")
                                                            if ($Bkjob.TypeToString -eq "VMware Backup Copy") {
                                                                $BackupWindow = $Bkjob.ScheduleOptions.OptionsContinuous.Schedule
                                                            } else {$BackupWindow = $Bkjob.ScheduleOptions.OptionsBackupWindow.BackupWindow}
                                                            $Match = $Regex.Match($BackupWindow)
                                                            if($Match.Success)
                                                            {
                                                                $ScheduleTimePeriod += $Match.Value
                                                            }
                                                        }

                                                        $OutObj = Get-WindowsTimePeriod -InputTimePeriod $ScheduleTimePeriod

                                                        $TableParams = @{
                                                            Name = "Backup Window - $($Bkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 6,4,3,4,4,4,4,4,4,4,4,4,4,4,3,4,4,4,4,4,4,4,4,4,4
                                                            Key = 'H'
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        if ($OutObj) {
                                                            $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                            $OutObj2.Rows | Where-Object {$_.Sun -eq "0"} | Set-Style -Style ON -Property "Sun"
                                                            $OutObj2.Rows | Where-Object {$_.Mon -eq "0"} | Set-Style -Style ON -Property "Mon"
                                                            $OutObj2.Rows | Where-Object {$_.Tue -eq "0"} | Set-Style -Style ON -Property "Tue"
                                                            $OutObj2.Rows | Where-Object {$_.Wed -eq "0"} | Set-Style -Style ON -Property "Wed"
                                                            $OutObj2.Rows | Where-Object {$_.Thu -eq "0"} | Set-Style -Style ON -Property "Thu"
                                                            $OutObj2.Rows | Where-Object {$_.Fri -eq "0"} | Set-Style -Style ON -Property "Fri"
                                                            $OutObj2.Rows | Where-Object {$_.Sat -eq "0"} | Set-Style -Style ON -Property "Sat"

                                                            $OutObj2.Rows | Where-Object {$_.Sun -eq "1"} | Set-Style -Style OFF -Property "Sun"
                                                            $OutObj2.Rows | Where-Object {$_.Mon -eq "1"} | Set-Style -Style OFF -Property "Mon"
                                                            $OutObj2.Rows | Where-Object {$_.Tue -eq "1"} | Set-Style -Style OFF -Property "Tue"
                                                            $OutObj2.Rows | Where-Object {$_.Wed -eq "1"} | Set-Style -Style OFF -Property "Wed"
                                                            $OutObj2.Rows | Where-Object {$_.Thu -eq "1"} | Set-Style -Style OFF -Property "Thu"
                                                            $OutObj2.Rows | Where-Object {$_.Fri -eq "1"} | Set-Style -Style OFF -Property "Fri"
                                                            $OutObj2.Rows | Where-Object {$_.Sat -eq "1"} | Set-Style -Style OFF -Property "Sat"
                                                            $OutObj2
                                                        }
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Schedule Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Schedule Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Configuration Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Hyper-V Backup Jobs Configuration Section: $($_.Exception.Message)"
        }
    }
    end {}

}
