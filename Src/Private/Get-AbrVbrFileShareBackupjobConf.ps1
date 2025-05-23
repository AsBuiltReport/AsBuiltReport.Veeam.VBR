
function Get-AbrVbrFileShareBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns file share backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        Write-PScriboMessage "Discovering Veeam VBR File Share Backup jobs information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'File Share Backup jobs'
    }

    process {
        if ($Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -like 'File Backup' -or $_.TypeToString -like 'Object Storage Backup' } | Sort-Object -Property Name) {
            if ($VbrVersion -lt 12.1) {
                $BSName = 'File Share Backup Jobs Configuration'
            } else {
                $BSName = 'Unstructured Data Backup Jobs Configuration'
            }
            Section -Style Heading3 $BSName {
                Paragraph "The following section details the information of $($BSName.ToLower())."
                BlankLine
                foreach ($Bkjob in $Bkjobs) {
                    try {
                        Section -Style Heading4 $($Bkjob.Name) {
                            Section -Style NOTOCHeading4 -ExcludeFromTOC 'Common Information' {
                                $OutObj = @()
                                try {
                                    $CommonInfos = (Get-VBRJob -WarningAction SilentlyContinue -Name $Bkjob.Name | Where-Object { $_.TypeToString -ne 'Windows Agent Backup' }).Info
                                    foreach ($CommonInfo in $CommonInfos) {
                                        try {
                                            Write-PScriboMessage "Discovered $($Bkjob.Name) common information."
                                            $inObj = [ordered] @{
                                                'Name' = $Bkjob.Name
                                                'Type' = $Bkjob.TypeToString
                                                'Total Backup Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CommonInfo.IncludedSize
                                                'Target Address' = $CommonInfo.TargetDir
                                                'Target File' = $CommonInfo.TargetFile
                                                'Description' = $CommonInfo.CommonInfo.Description
                                                'Modified By' = $CommonInfo.CommonInfo.ModifiedBy.FullName
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Common Information $($Bkjob.Name) Section: $($_.Exception.Message)"
                                        }
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
                                    Write-PScriboMessage -IsWarning "Common Information Section: $($_.Exception.Message)"
                                }
                            }
                            if ($Bkjob.TypeToString -ne "Object Storage Backup") {
                                if ($Bkjob.GetObjectsInJob()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Files and Folders" {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetObjectsInJob() | Where-Object { $_.Type -eq "Include" -or $_.Type -eq "Exclude" })) {
                                                Write-PScriboMessage "Discovered $($OBJ.Name) files and folders to backup."
                                                $inObj = [ordered] @{
                                                    'Name' = $OBJ.Name
                                                    'Resource Type' = $OBJ.TypeDisplayName
                                                    'Role' = $OBJ.Type
                                                    'Location' = $OBJ.Location
                                                    'Approx Size' = $OBJ.ApproxSizeString
                                                    'File Filter Include Masks' = $OBJ.ExtendedOptions.FileSourceOptions.IncludeMasks
                                                    'File Filter Exclude Masks' = $OBJ.ExtendedOptions.FileSourceOptions.ExcludeMasks
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "Files and Folders - $($OBJ.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Files and Folders Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            } else {
                                if ((Get-VBRUnstructuredBackupJob -Id $Bkjob.Id).BackupObject) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Objects" {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ((Get-VBRUnstructuredBackupJob -Id $Bkjob.Id).BackupObject)) {
                                                Write-PScriboMessage "Discovered $($OBJ.Name) object to backup."
                                                $inObj = [ordered] @{
                                                    'Name' = $OBJ.Server.FriendlyName
                                                    'Path' = Switch ([string]::IsNullOrEmpty($OBJ.Path)) {
                                                        $true { "--" }
                                                        $false { $OBJ.Path }
                                                        default { "Unknown" }
                                                    }
                                                    'Container' = Switch ([string]::IsNullOrEmpty($OBJ.Container)) {
                                                        $true { "--" }
                                                        $false { $OBJ.Container }
                                                        default { "Unknown" }
                                                    }
                                                    'Inclusion Mask' = Switch ([string]::IsNullOrEmpty($OBJ.InclusionMask)) {
                                                        $true { "--" }
                                                        $false { $OBJ.InclusionMask }
                                                        default { "Unknown" }
                                                    }
                                                    'Exclusion Mask' = Switch ([string]::IsNullOrEmpty($OBJ.ExclusionMask)) {
                                                        $true { "--" }
                                                        $false { $OBJ.ExclusionMask }
                                                        default { "Unknown" }
                                                    }
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            }
                                            $TableParams = @{
                                                Name = "Objects - $($OBJ.Name)"
                                                List = $false
                                                ColumnWidths = 20, 20, 20, 20, 20
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Objects Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'Storage' {
                                $OutObj = @()
                                try {
                                    Write-PScriboMessage "Discovered $($Bkjob.Name) storage options."
                                    $inObj = [ordered] @{
                                        'Backup Repository' = Switch ($Bkjob.info.TargetRepositoryId) {
                                            '00000000-0000-0000-0000-000000000000' { $Bkjob.TargetDir }
                                            { $Null -eq (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name } { (Get-VBRBackupRepository -ScaleOut | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                            default { (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                        }
                                        'Keep all file versions for the last' = "$($Bkjob.Options.NasBackupRetentionPolicy.ShortTermRetention) $($Bkjob.Options.NasBackupRetentionPolicy.ShortTermRetentionUnit)"
                                    }

                                    $FiletoArchive = Switch ($Bkjob.Options.NasBackupRetentionPolicy.ArchiveFileExtensionsScope) {
                                        'ExceptSpecified' { "All file exept the following extension: $($Bkjob.Options.NasBackupRetentionPolicy.ExcludedFileExtensions)" }
                                        'Any' { 'All Files: *.*' }
                                        'Specified' { "File with the following extension only: $($Bkjob.Options.NasBackupRetentionPolicy.IncludedFileExtensions)" }
                                    }

                                    if ($Bkjob.Options.NasBackupRetentionPolicy.LongTermEnabled -and ($VbrVersion -lt 12.1)) {
                                        $inObj.add('Keep previous file versions for', "$($Bkjob.Options.NasBackupRetentionPolicy.LongTermRetention) $($Bkjob.Options.NasBackupRetentionPolicy.LongTermRetentionUnit)")
                                        $inObj.add('Archive repository', (Get-VBRNASBackupJob -WarningAction SilentlyContinue | Where-Object { $_.id -eq $BKjob.id }).LongTermBackupRepository.Name)
                                        $inObj.add('File to Archive', $FiletoArchive)
                                    }

                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                    $TableParams = @{
                                        Name = "Storage Options - $($Bkjob.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    if ($InfoLevel.Jobs.FileShare -ge 2) {
                                        if ($VbrVersion -lt 12.1) {
                                            $FLVersion = "File Version"
                                        } else {
                                            $FLVersion = "Object Version"
                                        }
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings ($FLVersion)" {
                                            $OutObj = @()
                                            try {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) File Version options."
                                                $FileVersionsRetentionScope = Switch ($Bkjob.Options.NasBackupRetentionPolicy.FileVersionsRetentionScope) {
                                                    'LongTermOnly' { 'Limit the number of archived file versions only' }
                                                    'None' { 'Keep all file versions' }
                                                    'All' { 'Limit the number of both recent and archived file versions' }
                                                }
                                                $inObj = [ordered] @{
                                                    'File version to keep' = $FileVersionsRetentionScope
                                                }
                                                if ($Bkjob.Options.NasBackupRetentionPolicy.LimitMaxActiveFileVersionsCount) {
                                                    $inObj.add('Active file version limit', $Bkjob.Options.NasBackupRetentionPolicy.MaxActiveFileVersionsCount)
                                                }
                                                if ($Bkjob.Options.NasBackupRetentionPolicy.LimitMaxDeletedFileVersionsCount) {
                                                    $inObj.add('Delete file version limit', $Bkjob.Options.NasBackupRetentionPolicy.MaxDeletedFileVersionsCount)
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "Advanced Settings ($FLVersion) - $($Bkjob.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Advanced Settings ($FLVersion) $($Bkjob.Name) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                    if ($InfoLevel.Jobs.FileShare -ge 2 -and ($Bkjob.TypeToString -ne "Object Storage Backup")) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (ACL Handling)" {
                                            $OutObj = @()
                                            try {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) acl handling options."
                                                $inObj = [ordered] @{
                                                    'Permissions and attribute backup' = Switch ($Bkjob.Options.NasBackupOptions.FileAttributesChangeTrackingMode) {
                                                        'TrackOnlyFolderAttributesChanges' { 'Folder-level only (recommended)' }
                                                        'TrackEverythingAttributesChanges' { 'File and folders (slower)' }
                                                        default { "--" }
                                                    }
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "Advanced Settings (acl handling) - $($Bkjob.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Advanced Settings (acl handling) $($Bkjob.Name) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                    if ($InfoLevel.Jobs.FileShare -ge 2) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Storage)" {
                                            $OutObj = @()
                                            try {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) storage options."
                                                $inObj = [ordered] @{
                                                    'Inline Data Deduplication' = $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                    'Compression Level' = Switch ($Bkjob.Options.BackupStorageOptions.CompressionLevel) {
                                                        0 { 'NONE' }
                                                        -1 { 'AUTO' }
                                                        4 { 'DEDUPE_friendly' }
                                                        5 { 'OPTIMAL (Default)' }
                                                        6 { 'High' }
                                                        9 { 'EXTREME' }
                                                    }
                                                    'Enabled Backup File Encryption' = $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                                    'Encryption Key' = Switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                        $false { 'None' }
                                                        default { (Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description }
                                                    }
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "Advanced Settings (Storage) - $($Bkjob.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Advanced Settings (Storage) $($Bkjob.Name) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                    if ($InfoLevel.Jobs.FileShare -ge 2) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Maintenance)" {
                                            $OutObj = @()
                                            try {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) maintenance options."
                                                $inObj = [ordered] @{
                                                    'Storage-Level Corruption Guard (SLCG)' = $Bkjob.Options.GenerationPolicy.EnableRechek
                                                    'SLCG Schedule Type' = $Bkjob.Options.GenerationPolicy.RecheckScheduleKind
                                                }

                                                if ($Bkjob.Options.GenerationPolicy.RecheckScheduleKind -eq 'Daily') {
                                                    $inObj.add('SLCG Schedule Day', $Bkjob.Options.GenerationPolicy.RecheckDays)
                                                }
                                                if ($Bkjob.Options.GenerationPolicy.RecheckScheduleKind -eq 'Monthly') {
                                                    $inObj.add('SLCG Backup Monthly Schedule', "Day Of Week: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.Months)")
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
                                                Write-PScriboMessage -IsWarning "Advanced Settings (Maintenance) $($Bkjob.Name) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                    if ($InfoLevel.Jobs.FileShare -ge 2 -and ($Bkjob.Options.NotificationOptions.SnmpNotification -or $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses)) {
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
                                                Write-PScriboMessage -IsWarning "Advanced Settings (Notification) $($Bkjob.Name) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                    if ($InfoLevel.Jobs.FileShare -ge 2 -and ($Bkjob.Options.JobScriptCommand.PreScriptEnabled -or $Bkjob.Options.JobScriptCommand.PostScriptEnabled)) {
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
                                                Write-PScriboMessage -IsWarning "Advanced Settings (Script) $($Bkjob.Name) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Storage Options Section: $($_.Exception.Message)"
                                }
                            }
                            $ArchiveRepoTarget = Get-VBRUnstructuredBackupJob -Id $Bkjob.Id
                            if ($ArchiveRepoTarget.LongTermRetentionPeriodEnabled) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "Archive Repository" {
                                    $OutObj = @()
                                    try {
                                        Write-PScriboMessage "Discovered $($Bkjob.Name) archive repository."
                                        try {
                                            $inObj = [ordered] @{
                                                'Backup Repository	' = $ArchiveRepoTarget.LongTermBackupRepository.Name
                                                'Type' = $ArchiveRepoTarget.LongTermBackupRepository.Type
                                                'FriendlyPath' = $ArchiveRepoTarget.LongTermBackupRepository.FriendlyPath
                                                'Archive previus version for' = "$($ArchiveRepoTarget.LongTermRetentionPeriod) $($ArchiveRepoTarget.LongTermRetentionType)"
                                                'File to archive' = $ArchiveRepoTarget.BackupArchivalOptions.ArchivalType
                                            }

                                            if ($ArchiveRepoTarget.BackupArchivalOptions.ArchivalType -eq 'ExclusionMask') {
                                                $inObj.add("Exclusion Mask", $ArchiveRepoTarget.BackupArchivalOptions.ExclusionMask -join ",")
                                            } elseif ($ArchiveRepoTarget.BackupArchivalOptions.ArchivalType -eq 'InclusionMask') {
                                                $inObj.add("Inclusion Mask", $ArchiveRepoTarget.BackupArchivalOptions.InclusionMask -join ",")
                                            }
                                            $inObj.add("Description", $ArchiveRepoTarget.LongTermBackupRepository.Description)

                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Archive Repository $($ArchiveRepoTarget.Name) Section: $($_.Exception.Message)"
                                        }
                                        $TableParams = @{
                                            Name = "Archive Repository - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Job Name' | Table @TableParams
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Archive Repository Section: $($_.Exception.Message)"
                                    }
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
                                                Write-PScriboMessage -IsWarning "Secondary Target $($SecondaryTarget.Name) Section: $($_.Exception.Message)"
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
                                        Write-PScriboMessage -IsWarning "Secondary Destination Jobs Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                            if ($Bkjob.IsScheduleEnabled -and $Bkjob.ScheduleOptions.OptionsContinuous.Enabled -ne "True") {
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
                                            'Backup Window' = Switch ($Bkjob.TypeToString) {
                                                "Backup Copy" { $Bkjob.ScheduleOptions.OptionsContinuous.Enabled }
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
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Backup Window Time Period" {
                                                Paragraph -ScriptBlock $Legend

                                                try {

                                                    $ScheduleTimePeriod = @()
                                                    $Days = 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
                                                    foreach ($Day in $Days) {

                                                        $Regex = [Regex]::new("(?<=<$Day>)(.*)(?=</$Day>)")
                                                        if ($Bkjob.TypeToString -eq "VMware Backup Copy") {
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
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Backup Window Time Period Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Schedule Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "$($BSName) Section: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'File Share Backup jobs'
    }

}