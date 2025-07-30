
function Get-AbrVbrBackupjobNutanixConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Nutanix backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.23
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
        Write-PScriboMessage "Discovering Veeam VBR Nutanix Backup jobs information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Nutanix Backup Jobs"
    }

    process {
        try {
            if ($Bkjobs = [Veeam.Backup.Core.CBackupJob]::GetAll() | Where-Object { $_.TypeToString -like "*Nutanix*" } | Sort-Object -Property 'Name') {
                Section -Style Heading3 'Nutanix Backup Jobs Configuration' {
                    Paragraph "The following section details the configuration of Nutanix type backup jobs."
                    BlankLine
                    $OutObj = @()
                    try {
                        if ($VMcounts = Get-VBRBackup | Where-Object { $_.TypeToString -like "Nutanix" }) {
                            foreach ($VMcount in $VMcounts) {
                                try {
                                    Write-PScriboMessage "Discovered $($VMcount.Name) ."
                                    $inObj = [ordered] @{
                                        'Name' = $VMcount.Name
                                        'Creation Time' = $VMcount.CreationTime
                                        'VM Count' = $VMcount.VmCount
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "Nutanix Backup Jobs Configuration Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "Nutanix Backup Summary - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 35, 35, 30
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading4 -ExcludeFromTOC 'Common Information' {
                                    $OutObj = @()
                                    try {
                                        try {
                                            Write-PScriboMessage "Discovered $($Bkjob.Name) common information."
                                            $inObj = [ordered] @{
                                                'Name' = $Bkjob.Name
                                                'Type' = $Bkjob.TypeToString
                                                'Total Backup Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Bkjob.Info.IncludedSize
                                                'Target Address' = $Bkjob.Info.TargetDir
                                                'Target File' = $Bkjob.Info.TargetFile
                                                'Description' = $Bkjob.Info.CommonInfo.Description
                                                'Modified By' = $Bkjob.Info.CommonInfo.ModifiedBy.FullName
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
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
                                            if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $_.'Description' -eq "--" }) {
                                                Paragraph "Health Check:" -Bold -Underline
                                                BlankLine
                                                Paragraph {
                                                    Text "Best Practice:" -Bold
                                                    Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                }
                                                BlankLine
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Linked Backup Jobs' {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedBkJob in $Bkjob.LinkedJobs) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) linked backup job."
                                                    $Job = $Bkjobs | Where-Object { $_.Id -eq $LinkedBkJob.info.LinkedObjectId.Guid }
                                                    $inObj = [ordered] @{
                                                        'Name' = $Job.Name
                                                        'Type' = $Job.TypeToString
                                                        'Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Job.Info.IncludedSize
                                                        'Repository' = $Job.GetTargetRepository().Name
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
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
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.LinkedRepositories) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Linked Repositories' {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedRepository in $Bkjob.LinkedRepositories.LinkedRepositoryId) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) linked repository."
                                                    if ($Repo = Get-VBRBackupRepository | Where-Object { $_.Id -eq $LinkedRepository }) {
                                                        $inObj = [ordered] @{
                                                            'Name' = $Repo.Name
                                                            'Type' = "Standard"
                                                            'Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Repo.GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    }
                                                    if ($ScaleRepo = Get-VBRBackupRepository -ScaleOut | Where-Object { $_.Id -eq $LinkedRepository }) {
                                                        $inObj = [ordered] @{
                                                            'Name' = $ScaleRepo.Name
                                                            'Type' = "ScaleOut"
                                                            'Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size (($ScaleRepo.Extent).Repository).GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Linked Repositories - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 35, 30
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Data Transfer' {
                                        $OutObj = @()
                                        try {
                                            try {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) data transfer."
                                                if ($Bkjob.IsWanAcceleratorEnabled()) {
                                                    try {
                                                        $TargetWanAccelerator = $Bkjob.GetTargetWanAccelerator().Name
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                    try {
                                                        $SourceWanAccelerator = $Bkjob.GetSourceWanAccelerator().Name
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                }
                                                $inObj = [ordered] @{
                                                    'Use Wan accelerator' = $Bkjob.IsWanAcceleratorEnabled()
                                                    'Source Wan accelerator' = switch ($Bkjob.IsWanAcceleratorEnabled()) {
                                                        'False' { 'Direct Mode' }
                                                        'True' { $SourceWanAccelerator }
                                                        default { 'Unknown' }
                                                    }
                                                    'Target Wan accelerator' = switch ($Bkjob.IsWanAcceleratorEnabled()) {
                                                        'False' { 'Direct Mode' }
                                                        'True' { $TargetWanAccelerator }
                                                        default { 'Unknown' }
                                                    }
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning $_.Exception.Message
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
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.GetAhvOijs()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Virtual Machines" {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetAhvOijs() | Where-Object { $_.Type -eq "Include" -or $_.Type -eq "Exclude" } )) {
                                                Write-PScriboMessage "Discovered $($OBJ.Name) object to backup."
                                                $inObj = [ordered] @{
                                                    'Name' = $OBJ.Name
                                                    'Resource Type' = & {
                                                        if ($OBJ.TypeDisplayName) {
                                                            $OBJ.TypeDisplayName
                                                        } elseif ($OBJ.Object) {
                                                            $OBJ.Object.Type
                                                        }
                                                    }
                                                    'Role' = $OBJ.Type
                                                    'Approx Size' = $OBJ.ApproxSizeString
                                                    'Disk Filter Mode' = $OBJ.DiskFilterInfo.Mode
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
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
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.TypeToString -eq "Nutanix") {
                                    $Storage = 'Target'
                                } else { $Storage = 'Storage' }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $Storage {
                                    $OutObj = @()
                                    try {
                                        Write-PScriboMessage "Discovered $($Bkjob.Name) storage options."
                                        if ($Bkjob.BackupStorageOptions.RetentionType -eq "Days") {
                                            $RetainString = 'Retain Days To Keep'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainDaysToKeep
                                        } elseif ($Bkjob.BackupStorageOptions.RetentionType -eq "Cycles") {
                                            $RetainString = 'Retain Cycles'
                                            $Retains = $Bkjob.BackupStorageOptions.RetainCycles
                                        }
                                        $inObj = [ordered] @{
                                            'Backup Proxy' = "Backup Appliance"
                                            'Backup Repository' = switch ($Bkjob.info.TargetRepositoryId) {
                                                '00000000-0000-0000-0000-000000000000' { "Snapshot Backup" }
                                                { $Null -eq (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name } { (Get-VBRBackupRepository -ScaleOut | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                                default { (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                            }
                                            'Retention Type' = $Bkjob.BackupStorageOptions.RetentionType
                                            $RetainString = $Retains
                                            'Keep First Full Backup' = $Bkjob.BackupStorageOptions.KeepFirstFullBackup
                                            'Enable Full Backup' = $Bkjob.BackupStorageOptions.EnableFullBackup
                                            'Integrity Checks' = $Bkjob.BackupStorageOptions.EnableIntegrityChecks
                                            'Storage Encryption' = $Bkjob.BackupStorageOptions.StorageEncryptionEnabled
                                            'Backup Mode' = switch ($Bkjob.Options.BackupTargetOptions.Algorithm) {
                                                'Synthetic' { "Reverse Incremental" }
                                                'Increment' { 'Incremental' }
                                            }
                                            'Active Full Backup Schedule Kind' = $Bkjob.Options.BackupTargetOptions.FullBackupScheduleKind
                                            'Active Full Backup Days' = $Bkjob.Options.BackupTargetOptions.FullBackupDays
                                            'Transform Full To Synthetic' = $Bkjob.Options.BackupTargetOptions.TransformFullToSyntethic
                                            'Transform Increments To Synthetic' = $Bkjob.Options.BackupTargetOptions.TransformIncrementsToSyntethic
                                            'Transform To Synthetic Days' = $Bkjob.Options.BackupTargetOptions.TransformToSyntethicDays


                                        }
                                        if ($Bkjob.Options.GfsPolicy.IsEnabled) {
                                            $inObj.add('Keep certain full backup longer for archival purposes (GFS)', ($Bkjob.Options.GfsPolicy.IsEnabled))
                                            if (-not $Bkjob.Options.GfsPolicy.Weekly.IsEnabled) {
                                                $inObj.add('Keep Weekly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Weekly full backup for', ("$($Bkjob.Options.GfsPolicy.Weekly.KeepBackupsForNumberOfWeeks) weeks,`r`nIf multiple backup exist use the one from: $($Bkjob.Options.GfsPolicy.Weekly.DesiredTime)"))
                                            }
                                            if (-not $Bkjob.Options.GfsPolicy.Monthly.IsEnabled) {
                                                $inObj.add('Keep Monthly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Monthly full backup for', ("$($Bkjob.Options.GfsPolicy.Monthly.KeepBackupsForNumberOfMonths) months,`r`nUse weekly full backup from the following week of the month: $($Bkjob.Options.GfsPolicy.Monthly.DesiredTime)"))
                                            }
                                            if (-not $Bkjob.Options.GfsPolicy.Yearly.IsEnabled) {
                                                $inObj.add('Keep Yearly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Yearly full backup for', ("$($Bkjob.Options.GfsPolicy.Yearly.KeepBackupsForNumberOfYears) years,`r`nUse monthly full backup from the following month: $($Bkjob.Options.GfsPolicy.Yearly.DesiredTime)"))
                                            }
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "$Storage Options - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($InfoLevel.Jobs.Nutanix -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Maintenance)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) maintenance options."
                                                    $inObj = [ordered] @{
                                                        'Storage-Level Corruption Guard (SLCG)' = $Bkjob.Options.GenerationPolicy.EnableRechek
                                                        'SLCG Schedule Type' = $Bkjob.Options.GenerationPolicy.RecheckScheduleKind
                                                        'SLCG Schedule Day' = $Bkjob.Options.GenerationPolicy.RecheckDays
                                                        'SLCG Backup Monthly Schedule' = "Day Of Week: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.Months)"
                                                        'Defragment and Compact Full Backup (DCFB)' = $Bkjob.Options.GenerationPolicy.EnableCompactFull
                                                        'DCFB Schedule Type' = $Bkjob.Options.GenerationPolicy.CompactFullBackupScheduleKind
                                                        'DCFB Schedule Day' = $Bkjob.Options.GenerationPolicy.CompactFullBackupDays
                                                        'DCFB Backup Monthly Schedule' = "Day Of Week: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.Months)"
                                                        'Remove deleted item data after' = $Bkjob.Options.BackupStorageOptions.RetainDays
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

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
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Storage)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) storage options."
                                                    $inObj = [ordered] @{
                                                        'Inline Data Deduplication' = $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                        'Exclude Swap Files Block' = $Bkjob.ViSourceOptions.ExcludeSwapFile
                                                        'Exclude Deleted Files Block' = $Bkjob.ViSourceOptions.DirtyBlocksNullingEnabled
                                                        'Compression Level' = switch ($Bkjob.Options.BackupStorageOptions.CompressionLevel) {
                                                            0 { 'NONE' }
                                                            -1 { 'AUTO' }
                                                            4 { 'DEDUPE_friendly' }
                                                            5 { 'OPTIMAL (Default)' }
                                                            6 { 'High' }
                                                            9 { 'EXTREME' }
                                                        }
                                                        'Storage optimization' = switch ($Bkjob.Options.BackupStorageOptions.StgBlockSize) {
                                                            'KbBlockSize1024' { 'Local target (1MB)' }
                                                            'KbBlockSize512' { 'LAN target (512KB)' }
                                                            'KbBlockSize256' { 'WAN target (256KB)' }
                                                            'KbBlockSize4096' { 'Local target (4MB large blocks)' }
                                                            default { $Bkjob.Options.BackupStorageOptions.StgBlockSize }
                                                        }
                                                        'Enabled Backup File Encryption' = $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                                        'Encryption Key' = switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                            $false { 'None' }
                                                            default { (Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.'Enabled Backup File Encryption' -eq 'No' } | Set-Style -Style Warning -Property 'Enabled Backup File Encryption'
                                                        $OutObj | Where-Object { $_.'Exclude Swap Files Block' -eq 'No' } | Set-Style -Style Warning -Property 'Exclude Swap Files Block'
                                                        $OutObj | Where-Object { $_.'Exclude Deleted Files Block' -eq 'No' } | Set-Style -Style Warning -Property 'Exclude Deleted Files Block'
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
                                                        if ($OutObj | Where-Object { $_.'Enabled Backup File Encryption' -eq 'No' }) {
                                                            Paragraph "Health Check:" -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text "Best Practice:" -Bold
                                                                Text "Backup and replica data is a high potential source of vulnerability. To secure data stored in backups and replicas, use Veeam Backup & Replication inbuilt encryption to protect data in backups"
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.NotificationOptions.SnmpNotification -or $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Notification)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) notification options."
                                                    $inObj = [ordered] @{
                                                        'Send Snmp Notification' = $Bkjob.Options.NotificationOptions.SnmpNotification
                                                        'Send Email Notification' = $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses
                                                        'Email Notification Additional Addresses' = $Bkjob.Options.NotificationOptions.EmailNotificationAdditionalAddresses
                                                        'Email Notify Time' = $Bkjob.Options.NotificationOptions.EmailNotifyTime.ToShortTimeString()
                                                        'Use Custom Email Notification Options' = $Bkjob.Options.NotificationOptions.UseCustomEmailNotificationOptions
                                                        'Use Custom Notification Setting' = $Bkjob.Options.NotificationOptions.EmailNotificationSubject
                                                        'Notify On Success' = $Bkjob.Options.NotificationOptions.EmailNotifyOnSuccess
                                                        'Notify On Warning' = $Bkjob.Options.NotificationOptions.EmailNotifyOnWarning
                                                        'Notify On Error' = $Bkjob.Options.NotificationOptions.EmailNotifyOnError
                                                        'Suppress Notification until Last Retry' = $Bkjob.Options.NotificationOptions.EmailNotifyOnLastRetryOnly
                                                        'Set Results To Vm Notes' = $Bkjob.Options.ViSourceOptions.SetResultsToVmNotes
                                                        'VM Attribute Note Value' = $Bkjob.Options.ViSourceOptions.VmAttributeName
                                                        'Append to Existing Attribute' = $Bkjob.Options.ViSourceOptions.VmNotesAppend
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Notification) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.ViSourceOptions.VMToolsQuiesce -or $Bkjob.Options.ViSourceOptions.UseChangeTracking)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Nutanix)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) Nutanix options."
                                                    $inObj = [ordered] @{
                                                        'Enable Nutanix Tools Quiescence' = $Bkjob.Options.ViSourceOptions.VMToolsQuiesce
                                                        'Use Change Block Tracking' = $Bkjob.Options.ViSourceOptions.UseChangeTracking
                                                        'Enable CBT for all protected VMs' = $Bkjob.Options.ViSourceOptions.EnableChangeTracking
                                                        'Reset CBT On each Active Full Backup' = $Bkjob.Options.ViSourceOptions.ResetChangeTrackingOnActiveFull
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Nutanix) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Integration)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) Integration options."
                                                    $inObj = [ordered] @{
                                                        'Enable Backup from Storage Snapshots' = $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots
                                                        'Limit processed VM count per Storage Snapshot' = $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotEnabled
                                                        'VM count per Storage Snapshot' = $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotVmsCount
                                                        'Failover to Standard Backup' = $Bkjob.Options.SanIntegrationOptions.FailoverFromSan
                                                        'Failover to Primary Storage Snapshot' = $Bkjob.Options.SanIntegrationOptions.Failover2StorageSnapshotBackup
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Integration) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.JobScriptCommand.PreScriptEnabled -or $Bkjob.Options.JobScriptCommand.PostScriptEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Script)" {
                                                $OutObj = @()
                                                try {
                                                    if ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Days') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Days -join ","
                                                        $FrequencyText = 'Run Script on the Selected Days'
                                                    } elseif ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Cycles') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Frequency
                                                        $FrequencyText = 'Run Script Every Backup Session'
                                                    }
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) script options."
                                                    $inObj = [ordered] @{
                                                        'Run the Following Script Before' = $Bkjob.Options.JobScriptCommand.PreScriptEnabled
                                                        'Run Script Before the Job' = $Bkjob.Options.JobScriptCommand.PreScriptCommandLine
                                                        'Run the Following Script After' = $Bkjob.Options.JobScriptCommand.PostScriptEnabled
                                                        'Run Script After the Job' = $Bkjob.Options.JobScriptCommand.PostScriptCommandLine
                                                        'Run Script Frequency' = $Bkjob.Options.JobScriptCommand.Periodicity
                                                        $FrequencyText = $FrequencyValue

                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Script) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.RpoOptions.Enabled -or $Bkjob.Options.RpoOptions.LogBackupRpoEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (RPO Monitor)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) rpo monitor options."
                                                    $inObj = [ordered] @{
                                                        'RPO Monitor Enabled' = $Bkjob.Options.RpoOptions.Enabled
                                                        'If Backup is not Copied Within' = "$($Bkjob.Options.RpoOptions.Value) $($Bkjob.Options.RpoOptions.TimeUnit)"
                                                        'Log Backup RPO Monitor Enabled' = $Bkjob.Options.RpoOptions.LogBackupRpoEnabled
                                                        'If Log Backup is not Copied Within' = "$($Bkjob.Options.RpoOptions.LogBackupRpoValue) $($Bkjob.Options.RpoOptions.LogBackupRpoTimeUnit)"
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (RPO Monitor) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($Bkjob.Id) | Where-Object { $_.JobType -ne 'SimpleBackupCopyWorker' }
                                if ($SecondaryTargets) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Secondary Target" {
                                        $OutObj = @()
                                        try {
                                            foreach ($SecondaryTarget in $SecondaryTargets) {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) secondary target."
                                                try {
                                                    $inObj = [ordered] @{
                                                        'Job Name' = $SecondaryTarget.Name
                                                        'Type' = $SecondaryTarget.TypeToString
                                                        'State' = $SecondaryTarget.info.LatestStatus
                                                        'Description' = $SecondaryTarget.Description
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
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
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.VssOptions.Enabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Guest Processing" {
                                        $OutObj = @()
                                        try {
                                            $VSSObjs = Get-VBRJobObject -Job $Bkjob.Name | Where-Object { $_.Type -eq "Include" -or $_.Type -eq "VssChild" } | Sort-Object -Property Name
                                            foreach ($VSSObj in $VSSObjs) {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) guest processing."
                                                $inObj = [ordered] @{
                                                    'Name' = $VSSObj.Name
                                                    'Enabled' = $VSSObj.VssOptions.Enabled
                                                    'Resource Type' = & {
                                                        if (($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq "Include" -or $_.Type -eq "VssChild") }).TypeDisplayName) {
                                                            ($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq "Include" -or $_.Type -eq "VssChild") }).TypeDisplayName
                                                        } elseif (($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq "Include" -or $_.Type -eq "VssChild") }).Object) {
                                                            ($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq "Include" -or $_.Type -eq "VssChild") }).Object.Type
                                                        }
                                                    }
                                                    'Ignore Errors' = $VSSObj.VssOptions.IgnoreErrors
                                                    'Guest Proxy Auto Detect' = $VSSObj.VssOptions.GuestProxyAutoDetect
                                                    'Default Credential' = switch ((Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid }).count) {
                                                        0 { 'None' }
                                                        Default { Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid } }
                                                    }
                                                    'Object Credential' = switch ($VSSObj.VssOptions.WinCredsId.Guid) {
                                                        '00000000-0000-0000-0000-000000000000' { 'Default Credential' }
                                                        default { Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.WinCredsId.Guid } }
                                                    }
                                                    'Application Processing' = $VSSObj.VssOptions.VssSnapshotOptions.ApplicationProcessingEnabled
                                                    'Transaction Logs' = switch ($VSSObj.VssOptions.VssSnapshotOptions.IsCopyOnly) {
                                                        'False' { 'Process Transaction Logs' }
                                                        'True' { 'Perform Copy Only' }
                                                    }
                                                    'Use Persistent Guest Agent' = $VSSObj.VssOptions.VssSnapshotOptions.UsePersistentGuestAgent
                                                }
                                                if ($InfoLevel.Jobs.Nutanix -ge 2) {
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
                                                    Name = "Guest Processing Options - $($VSSObj.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.IsScheduleEnabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                        $OutObj = @()
                                        try {
                                            Write-PScriboMessage "Discovered $($Bkjob.Name) schedule options."
                                            if ($Bkjob.ScheduleOptions.OptionsDaily.Enabled -eq "True") {
                                                $ScheduleType = "Daily"
                                                $Schedule = "Kind: $($Bkjob.ScheduleOptions.OptionsDaily.Kind),`r`nDays: $($Bkjob.ScheduleOptions.OptionsDaily.DaysSrv)"
                                            } elseif ($Bkjob.ScheduleOptions.OptionsMonthly.Enabled -eq "True") {
                                                $ScheduleType = "Monthly"
                                                $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfWeek)"
                                            } elseif ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled -eq "True") {
                                                $ScheduleType = $Bkjob.ScheduleOptions.OptionsPeriodically.Kind
                                                $Schedule = "Full Period: $($Bkjob.ScheduleOptions.OptionsPeriodically.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.OptionsPeriodically.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.OptionsPeriodically.Unit)"
                                            } elseif ($Bkjob.ScheduleOptions.OptionsContinuous.Enabled -eq "True") {
                                                $ScheduleType = 'Continuous'
                                                $Schedule = "Schedule Time Period"
                                            }
                                            $inObj = [ordered] @{
                                                'Retry Failed item' = $Bkjob.ScheduleOptions.RetryTimes
                                                'Wait before each retry' = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                'Backup Window' = switch ($Bkjob.TypeToString) {
                                                    "Nutanix" { $Bkjob.ScheduleOptions.OptionsContinuous.Enabled }
                                                    default { $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled }
                                                }
                                                'Shedule type' = $ScheduleType
                                                'Shedule Options' = $Schedule
                                                'Start Time' = $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                'Latest Run' = $Bkjob.LatestRunLocal
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

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
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Backup Window Time Period" {
                                                        Paragraph -ScriptBlock $Legend

                                                        $ScheduleTimePeriod = @()
                                                        $Days = 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
                                                        foreach ($Day in $Days) {

                                                            $Regex = [Regex]::new("(?<=<$Day>)(.*)(?=</$Day>)")
                                                            if ($Bkjob.TypeToString -eq "Nutanix") {
                                                                $BackupWindow = $Bkjob.ScheduleOptions.OptionsContinuous.Schedule
                                                            } else { $BackupWindow = $Bkjob.ScheduleOptions.OptionsBackupWindow.BackupWindow }
                                                            $Match = $Regex.Match($BackupWindow)
                                                            if ($Match.Success) {
                                                                $ScheduleTimePeriod += $Match.Value
                                                            }
                                                        }

                                                        $OutObj = Get-WindowsTimePeriod -InputTimePeriod $ScheduleTimePeriod

                                                        $TableParams = @{
                                                            Name = "Backup Window - $($Bkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                            Key = 'H'
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        if ($OutObj) {
                                                            $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq "0" } | Set-Style -Style ON -Property "Sun"
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq "0" } | Set-Style -Style ON -Property "Mon"
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq "0" } | Set-Style -Style ON -Property "Tue"
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq "0" } | Set-Style -Style ON -Property "Wed"
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq "0" } | Set-Style -Style ON -Property "Thu"
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq "0" } | Set-Style -Style ON -Property "Fri"
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq "0" } | Set-Style -Style ON -Property "Sat"

                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq "1" } | Set-Style -Style OFF -Property "Sun"
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq "1" } | Set-Style -Style OFF -Property "Mon"
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq "1" } | Set-Style -Style OFF -Property "Tue"
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq "1" } | Set-Style -Style OFF -Property "Wed"
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq "1" } | Set-Style -Style OFF -Property "Thu"
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq "1" } | Set-Style -Style OFF -Property "Fri"
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq "1" } | Set-Style -Style OFF -Property "Sat"
                                                            $OutObj2
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage "Nutanix Backup Jobs"
    }

}