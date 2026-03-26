
function Get-AbrVbrFileShareBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns file share backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.24
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
        $LocalizedData = $reportTranslate.GetAbrVbrFileShareBackupjobConf
        Show-AbrDebugExecutionTime -Start -TitleMessage 'File Share Backup jobs'
    }

    process {
        if ($Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -like 'File Backup' -or $_.TypeToString -like 'Object Storage Backup' } | Sort-Object -Property Name) {
            if ($VbrVersion -lt 12.1) {
                $BSName = $LocalizedData.FileShareBackupJobsConf
            } else {
                $BSName = $LocalizedData.UnstructuredDataBackupJobsConf
            }
            Section -Style Heading3 $BSName {
                Paragraph ($LocalizedData.Paragraph -f $BSName.ToLower())
                BlankLine
                foreach ($Bkjob in $Bkjobs) {
                    try {
                        Section -Style Heading4 $($Bkjob.Name) {
                            Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.CommonInformation {
                                $OutObj = @()
                                try {
                                    $CommonInfos = (Get-VBRJob -WarningAction SilentlyContinue -Name $Bkjob.Name | Where-Object { $_.TypeToString -ne 'Windows Agent Backup' }).Info
                                    foreach ($CommonInfo in $CommonInfos) {
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name = $Bkjob.Name
                                                $LocalizedData.Type = $Bkjob.TypeToString
                                                $LocalizedData.TotalBackupSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CommonInfo.IncludedSize
                                                $LocalizedData.TargetAddress = $CommonInfo.TargetDir
                                                $LocalizedData.TargetFile = $CommonInfo.TargetFile
                                                $LocalizedData.Description = $CommonInfo.CommonInfo.Description
                                                $LocalizedData.ModifiedBy = $CommonInfo.CommonInfo.ModifiedBy.FullName
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Common Information $($Bkjob.Name) Section: $($_.Exception.Message)"
                                        }
                                    }

                                    if ($HealthCheck.Jobs.BestPractice) {
                                        $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                        $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.CommonInformation) - $($Bkjob.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
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
                                } catch {
                                    Write-PScriboMessage -IsWarning "Common Information Section: $($_.Exception.Message)"
                                }
                            }
                            if ($Bkjob.TypeToString -ne 'Object Storage Backup') {
                                if ($Bkjob.GetObjectsInJob()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.FilesAndFolders {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetObjectsInJob() | Where-Object { $_.Type -eq 'Include' -or $_.Type -eq 'Exclude' })) {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $OBJ.Name
                                                    $LocalizedData.ResourceType = $OBJ.TypeDisplayName
                                                    $LocalizedData.Role = $OBJ.Type
                                                    $LocalizedData.Location = $OBJ.Location
                                                    $LocalizedData.ApproxSize = $OBJ.ApproxSizeString
                                                    $LocalizedData.FileFilterIncludeMasks = $OBJ.ExtendedOptions.FileSourceOptions.IncludeMasks
                                                    $LocalizedData.FileFilterExcludeMasks = $OBJ.ExtendedOptions.FileSourceOptions.ExcludeMasks
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.FilesAndFolders) - $($OBJ.Name)"
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
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Objects {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ((Get-VBRUnstructuredBackupJob -Id $Bkjob.Id).BackupObject)) {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $OBJ.Server.FriendlyName
                                                    $LocalizedData.Path = switch ([string]::IsNullOrEmpty($OBJ.Path)) {
                                                        $true { '--' }
                                                        $false { $OBJ.Path }
                                                        default { 'Unknown' }
                                                    }
                                                    $LocalizedData.Container = switch ([string]::IsNullOrEmpty($OBJ.Container)) {
                                                        $true { '--' }
                                                        $false { $OBJ.Container }
                                                        default { 'Unknown' }
                                                    }
                                                    $LocalizedData.InclusionMask = switch ([string]::IsNullOrEmpty($OBJ.InclusionMask)) {
                                                        $true { '--' }
                                                        $false { $OBJ.InclusionMask }
                                                        default { 'Unknown' }
                                                    }
                                                    $LocalizedData.ExclusionMask = switch ([string]::IsNullOrEmpty($OBJ.ExclusionMask)) {
                                                        $true { '--' }
                                                        $false { $OBJ.ExclusionMask }
                                                        default { 'Unknown' }
                                                    }
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            }
                                            $TableParams = @{
                                                Name = "$($LocalizedData.Objects) - $($OBJ.Name)"
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
                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Storage {
                                $OutObj = @()
                                try {

                                    $inObj = [ordered] @{
                                        $LocalizedData.BackupRepository = switch ($Bkjob.info.TargetRepositoryId) {
                                            '00000000-0000-0000-0000-000000000000' { $Bkjob.TargetDir }
                                            { $Null -eq (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name } { (Get-VBRBackupRepository -ScaleOut | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                            default { (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                        }
                                        $LocalizedData.KeepAllFileVersions = "$($Bkjob.Options.NasBackupRetentionPolicy.ShortTermRetention) $($Bkjob.Options.NasBackupRetentionPolicy.ShortTermRetentionUnit)"
                                    }

                                    $FiletoArchive = switch ($Bkjob.Options.NasBackupRetentionPolicy.ArchiveFileExtensionsScope) {
                                        'ExceptSpecified' { "$($LocalizedData.AllFileExcept) $($Bkjob.Options.NasBackupRetentionPolicy.ExcludedFileExtensions)" }
                                        'Any' { $LocalizedData.AllFiles }
                                        'Specified' { "$($LocalizedData.FileWithExtensionOnly) $($Bkjob.Options.NasBackupRetentionPolicy.IncludedFileExtensions)" }
                                    }

                                    if ($Bkjob.Options.NasBackupRetentionPolicy.LongTermEnabled -and ($VbrVersion -lt 12.1)) {
                                        $inObj.add($LocalizedData.KeepPreviousFileVersions, "$($Bkjob.Options.NasBackupRetentionPolicy.LongTermRetention) $($Bkjob.Options.NasBackupRetentionPolicy.LongTermRetentionUnit)")
                                        $inObj.add($LocalizedData.ArchiveRepository, (Get-VBRNASBackupJob -WarningAction SilentlyContinue | Where-Object { $_.id -eq $BKjob.id }).LongTermBackupRepository.Name)
                                        $inObj.add($LocalizedData.FileToArchive, $FiletoArchive)
                                    }

                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                    $TableParams = @{
                                        Name = "$($LocalizedData.StorageOptions) - $($Bkjob.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    if ($InfoLevel.Jobs.FileShare -ge 2) {
                                        if ($VbrVersion -lt 12.1) {
                                            $FLVersion = $LocalizedData.FileVersion
                                        } else {
                                            $FLVersion = $LocalizedData.ObjectVersion
                                        }
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings ($FLVersion)" {
                                            $OutObj = @()
                                            try {

                                                $FileVersionsRetentionScope = switch ($Bkjob.Options.NasBackupRetentionPolicy.FileVersionsRetentionScope) {
                                                    'LongTermOnly' { $LocalizedData.LimitArchivedFileVersions }
                                                    'None' { $LocalizedData.KeepAllFileVersionsValue }
                                                    'All' { $LocalizedData.LimitBothFileVersions }
                                                }
                                                $inObj = [ordered] @{
                                                    $LocalizedData.FileVersionToKeep = $FileVersionsRetentionScope
                                                }
                                                if ($Bkjob.Options.NasBackupRetentionPolicy.LimitMaxActiveFileVersionsCount) {
                                                    $inObj.add($LocalizedData.ActiveFileVersionLimit, $Bkjob.Options.NasBackupRetentionPolicy.MaxActiveFileVersionsCount)
                                                }
                                                if ($Bkjob.Options.NasBackupRetentionPolicy.LimitMaxDeletedFileVersionsCount) {
                                                    $inObj.add($LocalizedData.DeleteFileVersionLimit, $Bkjob.Options.NasBackupRetentionPolicy.MaxDeletedFileVersionsCount)
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
                                    if ($InfoLevel.Jobs.FileShare -ge 2 -and ($Bkjob.TypeToString -ne 'Object Storage Backup')) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedACL {
                                            $OutObj = @()
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.PermissionsBackup = switch ($Bkjob.Options.NasBackupOptions.FileAttributesChangeTrackingMode) {
                                                        'TrackOnlyFolderAttributesChanges' { $LocalizedData.FolderLevelOnly }
                                                        'TrackEverythingAttributesChanges' { $LocalizedData.FileAndFolders }
                                                        default { '--' }
                                                    }
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.AdvancedACL) - $($Bkjob.Name)"
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
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedStorage {
                                            $OutObj = @()
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.InlineDataDedup = $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                    $LocalizedData.CompressionLevel = switch ($Bkjob.Options.BackupStorageOptions.CompressionLevel) {
                                                        0 { 'NONE' }
                                                        -1 { 'AUTO' }
                                                        4 { 'DEDUPE_friendly' }
                                                        5 { 'OPTIMAL (Default)' }
                                                        6 { 'High' }
                                                        9 { 'EXTREME' }
                                                    }
                                                    $LocalizedData.EnabledEncryption = $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                                    $LocalizedData.EncryptionKey = switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                        $false { $LocalizedData.None }
                                                        default { (Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description }
                                                    }
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.AdvancedStorage) - $($Bkjob.Name)"
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
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedMaintenance {
                                            $OutObj = @()
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.SLCG = $Bkjob.Options.GenerationPolicy.EnableRechek
                                                    $LocalizedData.SLCGScheduleType = $Bkjob.Options.GenerationPolicy.RecheckScheduleKind
                                                }

                                                if ($Bkjob.Options.GenerationPolicy.RecheckScheduleKind -eq 'Daily') {
                                                    $inObj.add($LocalizedData.SLCGScheduleDay, $Bkjob.Options.GenerationPolicy.RecheckDays)
                                                }
                                                if ($Bkjob.Options.GenerationPolicy.RecheckScheduleKind -eq 'Monthly') {
                                                    $inObj.add($LocalizedData.SLCGMonthlySchedule, "$($LocalizedData.DayOfWeekLabel) $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfWeek)`r`n$($LocalizedData.DayNumberInMonth) $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayNumberInMonth)`r`n$($LocalizedData.DayOfMonth) $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfMonth)`r`n$($LocalizedData.MonthsLabel) $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.Months)")
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                if ($HealthCheck.Jobs.BestPractice) {
                                                    $OutObj | Where-Object { $_.$($LocalizedData.SLCG) -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.SLCG
                                                }

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.AdvancedMaintenance) - $($Bkjob.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                                if ($HealthCheck.Jobs.BestPractice) {
                                                    if ($OutObj | Where-Object { $_.$($LocalizedData.SLCG) -eq 'No' }) {
                                                        Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                        BlankLine
                                                        Paragraph {
                                                            Text $LocalizedData.BestPractice -Bold
                                                            Text $LocalizedData.SLCGBPText
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
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedNotification {
                                            $OutObj = @()
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.SendSnmpNotification = $Bkjob.Options.NotificationOptions.SnmpNotification
                                                    $LocalizedData.SendEmailNotification = $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses
                                                    $LocalizedData.EmailNotifAddresses = $Bkjob.Options.NotificationOptions.EmailNotificationAdditionalAddresses
                                                    $LocalizedData.EmailNotifyTime = $Bkjob.Options.NotificationOptions.EmailNotifyTime.ToShortTimeString()
                                                    $LocalizedData.UseCustomEmailNotif = $Bkjob.Options.NotificationOptions.UseCustomEmailNotificationOptions
                                                    $LocalizedData.UseCustomNotifSetting = $Bkjob.Options.NotificationOptions.EmailNotificationSubject
                                                    $LocalizedData.NotifyOnSuccess = $Bkjob.Options.NotificationOptions.EmailNotifyOnSuccess
                                                    $LocalizedData.NotifyOnWarning = $Bkjob.Options.NotificationOptions.EmailNotifyOnWarning
                                                    $LocalizedData.NotifyOnError = $Bkjob.Options.NotificationOptions.EmailNotifyOnError
                                                    $LocalizedData.SuppressNotification = $Bkjob.Options.NotificationOptions.EmailNotifyOnLastRetryOnly
                                                    $LocalizedData.SetResultsToVmNotes = $Bkjob.Options.ViSourceOptions.SetResultsToVmNotes
                                                    $LocalizedData.VMAttributeNoteValue = $Bkjob.Options.ViSourceOptions.VmAttributeName
                                                    $LocalizedData.AppendToExistingAttr = $Bkjob.Options.ViSourceOptions.VmNotesAppend
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.AdvancedNotification) - $($Bkjob.Name)"
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
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedScript {
                                            $OutObj = @()
                                            try {
                                                if ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Days') {
                                                    $FrequencyValue = $Bkjob.Options.JobScriptCommand.Days -join ','
                                                    $FrequencyText = $LocalizedData.RunScriptSelectedDays
                                                } elseif ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Cycles') {
                                                    $FrequencyValue = $Bkjob.Options.JobScriptCommand.Frequency
                                                    $FrequencyText = $LocalizedData.RunScriptEverySession
                                                }

                                                $inObj = [ordered] @{
                                                    $LocalizedData.RunScriptBefore = $Bkjob.Options.JobScriptCommand.PreScriptEnabled
                                                    $LocalizedData.RunScriptBeforeJob = $Bkjob.Options.JobScriptCommand.PreScriptCommandLine
                                                    $LocalizedData.RunScriptAfter = $Bkjob.Options.JobScriptCommand.PostScriptEnabled
                                                    $LocalizedData.RunScriptAfterJob = $Bkjob.Options.JobScriptCommand.PostScriptCommandLine
                                                    $LocalizedData.RunScriptFrequency = $Bkjob.Options.JobScriptCommand.Periodicity
                                                    $FrequencyText = $FrequencyValue

                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.AdvancedScript) - $($Bkjob.Name)"
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
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.ArchiveRepositorySection {
                                    $OutObj = @()
                                    try {

                                        try {
                                            $inObj = [ordered] @{
                                                $LocalizedData.BackupRepositoryCol = $ArchiveRepoTarget.LongTermBackupRepository.Name
                                                $LocalizedData.Type = $ArchiveRepoTarget.LongTermBackupRepository.Type
                                                $LocalizedData.FriendlyPath = $ArchiveRepoTarget.LongTermBackupRepository.FriendlyPath
                                                $LocalizedData.ArchivePreviousVersionFor = "$($ArchiveRepoTarget.LongTermRetentionPeriod) $($ArchiveRepoTarget.LongTermRetentionType)"
                                                $LocalizedData.FileToArchiveCol = $ArchiveRepoTarget.BackupArchivalOptions.ArchivalType
                                            }

                                            if ($ArchiveRepoTarget.BackupArchivalOptions.ArchivalType -eq 'ExclusionMask') {
                                                $inObj.add($LocalizedData.ExclusionMask, $ArchiveRepoTarget.BackupArchivalOptions.ExclusionMask -join ',')
                                            } elseif ($ArchiveRepoTarget.BackupArchivalOptions.ArchivalType -eq 'InclusionMask') {
                                                $inObj.add($LocalizedData.InclusionMask, $ArchiveRepoTarget.BackupArchivalOptions.InclusionMask -join ',')
                                            }
                                            $inObj.add($LocalizedData.Description, $ArchiveRepoTarget.LongTermBackupRepository.Description)

                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Archive Repository $($ArchiveRepoTarget.Name) Section: $($_.Exception.Message)"
                                        }
                                        $TableParams = @{
                                            Name = "$($LocalizedData.ArchiveRepositorySection) - $($Bkjob.Name)"
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
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SecondaryTarget {
                                    $OutObj = @()
                                    try {
                                        foreach ($SecondaryTarget in $SecondaryTargets) {

                                            try {
                                                $inObj = [ordered] @{
                                                    $LocalizedData.JobName = $SecondaryTarget.Name
                                                    $LocalizedData.Type = $SecondaryTarget.TypeToString
                                                    $LocalizedData.State = $SecondaryTarget.info.LatestStatus
                                                    $LocalizedData.Description = $SecondaryTarget.Description
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Secondary Target $($SecondaryTarget.Name) Section: $($_.Exception.Message)"
                                            }
                                        }
                                        $TableParams = @{
                                            Name = "$($LocalizedData.SecondaryDestinationJobs) - $($Bkjob.Name)"
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
                            if ($Bkjob.IsScheduleEnabled -and $Bkjob.ScheduleOptions.OptionsContinuous.Enabled -ne 'True') {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Schedule {
                                    $OutObj = @()
                                    try {

                                        if ($Bkjob.ScheduleOptions.OptionsDaily.Enabled -eq 'True') {
                                            $ScheduleType = 'Daily'
                                            $Schedule = "$($LocalizedData.Kind) $($Bkjob.ScheduleOptions.OptionsDaily.Kind),`r`n$($LocalizedData.DaysLabel) $($Bkjob.ScheduleOptions.OptionsDaily.DaysSrv)"
                                        } elseif ($Bkjob.ScheduleOptions.OptionsMonthly.Enabled -eq 'True') {
                                            $ScheduleType = 'Monthly'
                                            $Schedule = "$($LocalizedData.DayOfMonth) $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfMonth),`r`n$($LocalizedData.DayNumberInMonth) $($Bkjob.ScheduleOptions.OptionsMonthly.DayNumberInMonth),`r`n$($LocalizedData.DayOfWeekLabel) $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfWeek)"
                                        } elseif ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled -eq 'True') {
                                            $ScheduleType = $Bkjob.ScheduleOptions.OptionsPeriodically.Kind
                                            $Schedule = "$($LocalizedData.FullPeriod) $($Bkjob.ScheduleOptions.OptionsPeriodically.FullPeriod),`r`n$($LocalizedData.HourlyOffset) $($Bkjob.ScheduleOptions.OptionsPeriodically.HourlyOffset),`r`n$($LocalizedData.Unit) $($Bkjob.ScheduleOptions.OptionsPeriodically.Unit)"
                                        } elseif ($Bkjob.ScheduleOptions.OptionsContinuous.Enabled -eq 'True') {
                                            $ScheduleType = 'Continuous'
                                            $Schedule = $LocalizedData.ScheduleTimePeriod
                                        }
                                        $inObj = [ordered] @{
                                            $LocalizedData.RetryFailedItem = $Bkjob.ScheduleOptions.RetryTimes
                                            $LocalizedData.WaitBeforeRetry = "$($Bkjob.ScheduleOptions.RetryTimeout)/$($LocalizedData.Min)"
                                            $LocalizedData.BackupWindow = switch ($Bkjob.TypeToString) {
                                                'Backup Copy' { $Bkjob.ScheduleOptions.OptionsContinuous.Enabled }
                                                default { $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled }
                                            }
                                            $LocalizedData.ScheduleType = $ScheduleType
                                            $LocalizedData.ScheduleOptions = $Schedule
                                            $LocalizedData.StartTime = $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                            $LocalizedData.LatestRun = $Bkjob.LatestRunLocal
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "$($LocalizedData.ScheduleOptionsTable) - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled -or $Bkjob.ScheduleOptions.OptionsContinuous.Enabled) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.BackupWindowTimePeriod {
                                                Paragraph -ScriptBlock $Legend

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
                                                        Name = "$($LocalizedData.BackupWindow) - $($Bkjob.Name)"
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