
function Get-AbrVbrBackupCopyjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns vmware backup copy jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR backup copy jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupCopyjobConf
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Copy Jobs'
    }

    process {
        try {
            if ($Bkjobs = Get-VBRBackupCopyJob -WarningAction SilentlyContinue | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.CommonInformation {
                                    $OutObj = @()
                                    try {
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name = $Bkjob.Name
                                                $LocalizedData.Id = $Bkjob.Id
                                                $LocalizedData.Type = $Bkjob.type
                                                $LocalizedData.CopyMode = $Bkjob.Mode
                                                $LocalizedData.LastResult = $Bkjob.LastResult
                                                $LocalizedData.Status = $Bkjob.LastState
                                                $LocalizedData.NextRun = $Bkjob.NextRun
                                                $LocalizedData.IncludeDBTransactionLogBackup = $Bkjob.TransactionLogCopyEnabled
                                                $LocalizedData.Description = $Bkjob.Description
                                                $LocalizedData.ModifiedBy = (Get-VBRJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Where-Object { $_.id -eq $Bkjob.Id }).Info.CommonInfo.ModifiedBy.FullName
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $Null -like $_.$($LocalizedData.Description) -or $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                            $OutObj | Where-Object { $_.$($LocalizedData.LastResult) -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LastResult
                                            $OutObj | Where-Object { $_.$($LocalizedData.LastResult) -eq 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LastResult
                                            $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq 'Disabled' } | Set-Style -Style Warning -Property $LocalizedData.Status
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
                                                    Text $LocalizedData.DescriptionBestPracticeText
                                                }
                                                BlankLine
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($Bkjob.BackupJob) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.BackupJobsObjects {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedBkJob in $Bkjob.BackupJob) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $LinkedBkJob.Name
                                                        $LocalizedData.Type = $LinkedBkJob.TypeToString
                                                        $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $LinkedBkJob.Info.IncludedSize
                                                        $LocalizedData.Repository = $LinkedBkJob.GetTargetRepository().Name
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.BackupJobsObjects) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 25, 15, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.SourceRepository) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.RepositoriesObjects {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedRepository in $Bkjob.SourceRepository) {
                                                try {

                                                    if ($LinkedRepository.Type -eq 'ExtendableRepository') {
                                                        $inObj = [ordered] @{
                                                            $LocalizedData.Name = $LinkedRepository.Name
                                                            $LocalizedData.Type = $LocalizedData.ScaleOut
                                                            $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $LinkedRepository.GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    } else {
                                                        $inObj = [ordered] @{
                                                            $LocalizedData.Name = $LinkedRepository.Name
                                                            $LocalizedData.Type = $LocalizedData.Standard
                                                            $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $LinkedRepository.GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.RepositoriesObjects) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 35, 30
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Target {
                                    $OutObj = @()
                                    try {

                                        if ($Bkjob.RetentionType -eq 'RestoreDays') {
                                            $RetainString = $LocalizedData.RetainDaysToKeep
                                            $Retains = $Bkjob.RetentionNumber
                                        } elseif ($Bkjob.RetentionType -eq 'RestorePoints') {
                                            $RetainString = $LocalizedData.RestorePoints
                                            $Retains = $Bkjob.RetentionNumber
                                        }
                                        $inObj = [ordered] @{
                                            $LocalizedData.BackupRepository = $Bkjob.Target
                                            $LocalizedData.RetentionType = switch ($Bkjob.RetentionType) {
                                                'RestoreDays' { $LocalizedData.RestoreDays }
                                                'RestorePoints' { $LocalizedData.RestorePoints }
                                                default { $LocalizedData.Unknown }
                                            }
                                            $RetainString = $Retains
                                        }
                                        if ($Bkjob.GFSOptions) {
                                            if (-not $Bkjob.GFSOptions.WeeklyGFSEnabled) {
                                                $inObj.add($LocalizedData.KeepWeeklyFullBackup, ($LocalizedData.Disabled))
                                            } else {
                                                $inObj.add($LocalizedData.KeepWeeklyFullBackupFor, ("$($Bkjob.GFSOptions.WeeklyOptions.RetentionPeriod) weeks,`r`nCreate weekly full on this day: $($Bkjob.GFSOptions.WeeklyOptions.SelectedDay)"))
                                            }
                                            if (-not $Bkjob.GFSOptions.MonthlyGFSEnabled) {
                                                $inObj.add($LocalizedData.KeepMonthlyFullBackup, ($LocalizedData.Disabled))
                                            } else {
                                                $inObj.add($LocalizedData.KeepMonthlyFullBackupFor, ("$($Bkjob.GFSOptions.MonthlyOptions.RetentionPeriod) months,`r`nUse weekly full backup from the following week of the month: $($Bkjob.GFSOptions.MonthlyOptions.SelectedWeek)"))
                                            }
                                            if (-not $Bkjob.GFSOptions.YearlyGFSEnabled) {
                                                $inObj.add($LocalizedData.KeepYearlyFullBackup, ($LocalizedData.Disabled))
                                            } else {
                                                $inObj.add($LocalizedData.KeepYearlyFullBackupFor, ("$($Bkjob.GFSOptions.YearlyOptions.RetentionPeriod) years,`r`nUse monthly full backup from the following month: $($Bkjob.GFSOptions.YearlyOptions.SelectedMonth)"))
                                            }
                                            $inObj.add($LocalizedData.ReadEntireRestorePoint, ($Bkjob.GFSOptions.ReadEntireRestorePoint))
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TargetOptions) - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsMaintenance {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.SLCG = $Bkjob.HealthCheckOptions.Enabled
                                                        $LocalizedData.SLCGScheduleType = $Bkjob.HealthCheckOptions.ScheduleType
                                                    }

                                                    if ($Bkjob.HealthCheckOptions.ScheduleType -eq 'Monthly') {
                                                        $inObj.add($LocalizedData.SLCGBackupMonthlyScheduleAt, "Hour of Day: $($Bkjob.HealthCheckOptions.MonthlyPeriod)`r`nDay Number In Month: $($Bkjob.HealthCheckOptions.DayNumber)`r`nDay Of Week: $($Bkjob.HealthCheckOptions.DayOfWeek)`r`nDay of Month: $($Bkjob.HealthCheckOptions.DayOfMonth)`r`nMonths: $($Bkjob.HealthCheckOptions.SelectedMonths)")

                                                    } elseif ($Bkjob.HealthCheckOptions.ScheduleType -eq 'Weekly') {
                                                        $inObj.add($LocalizedData.SLCGBackupWeeklyScheduleAt, "Hour of Day: $($Bkjob.HealthCheckOptions.WeeklyPeriod)`r`nSelected Days: $($Bkjob.HealthCheckOptions.SelectedDays)")

                                                    }

                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.SLCG) -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.SLCG
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsMaintenance) - $($Bkjob.Name)"
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
                                                                Text $LocalizedData.SLCGBestPracticeText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsStorage {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.InlineDataDeduplication = $Bkjob.StorageOptions.DataDeduplicationEnabled
                                                        $LocalizedData.CompressionLevel = $Bkjob.StorageOptions.CompressionLevel
                                                        $LocalizedData.EnabledBackupFileEncryption = $Bkjob.StorageOptions.EncryptionEnabled
                                                        $LocalizedData.EncryptionKey = $Bkjob.StorageOptions.EncryptionKey.Description
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.EnabledBackupFileEncryption) -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.EnabledBackupFileEncryption
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsStorage) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.$($LocalizedData.EnabledBackupFileEncryption) -eq 'No' }) {
                                                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text $LocalizedData.BestPractice -Bold
                                                                Text $LocalizedData.EncryptionBestPracticeText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }

                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsRPOMonitor {
                                                $OutObj = @()
                                                try {

                                                    $BackupJob = $Bkjob.RpoWarningOptions | Where-Object { $_.RpoType -eq 'BackupJob' }
                                                    $BackupLogJob = $Bkjob.RpoWarningOptions | Where-Object { $_.RpoType -eq 'BackupLogJob' }

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.AlertNewBackupNotCopied = "$($BackupJob.Value) $($BackupJob.TimeUnit)`r`nEnable:$($BackupJob.EnableRpoWarning)"
                                                        $LocalizedData.AlertNewLogBackupNotCopied = "$($BackupLogJob.Value) $($BackupLogJob.TimeUnit)`r`nEnabled:$($BackupLogJob.EnableRpoWarning)"

                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsRPOMonitor) - $($Bkjob.Name)"
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

                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsNotification {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.SendSnmpNotification = $Bkjob.NotificationOptions.EnableSnmpNotification
                                                        $LocalizedData.SendEmailNotification = $Bkjob.NotificationOptions.EnableAdditionalNotification
                                                        $LocalizedData.EmailNotificationAdditionalAddresses = switch ($Bkjob.NotificationOptions.AdditionalAddress) {
                                                            $Null { '--' }
                                                            default { $Bkjob.NotificationOptions.AdditionalAddress }
                                                        }
                                                        $LocalizedData.EmailNotifyTime = $Bkjob.NotificationOptions.SendTime
                                                        $LocalizedData.UseCustomEmailNotificationOptions = $Bkjob.NotificationOptions.UseNotificationOptions
                                                        $LocalizedData.UseCustomNotificationSetting = $Bkjob.NotificationOptions.NotificationSubject
                                                        $LocalizedData.NotifyOnSuccess = $Bkjob.NotificationOptions.NotifyOnSuccess
                                                        $LocalizedData.NotifyOnWarning = $Bkjob.NotificationOptions.NotifyOnWarning
                                                        $LocalizedData.NotifyOnError = $Bkjob.NotificationOptions.NotifyOnError
                                                        $LocalizedData.SendNotification = switch ($Bkjob.NotificationOptions.EnableDailyNotification) {
                                                            'False' { $LocalizedData.ImmediatelyAfterEachCopiedBackup }
                                                            'True' { $LocalizedData.DailyAsASummary }
                                                            default { $LocalizedData.Unknown }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsNotification) - $($Bkjob.Name)"
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

                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsScript {
                                                $OutObj = @()
                                                try {
                                                    if ($Bkjob.ScriptOptions.Periodicity -eq 'Days') {
                                                        $FrequencyValue = $Bkjob.ScriptOptions.Days -join ','
                                                        $FrequencyText = $LocalizedData.RunScriptOnSelectedDays
                                                    } elseif ($Bkjob.ScriptOptions.Periodicity -eq 'Cycles') {
                                                        $FrequencyValue = $Bkjob.ScriptOptions.Frequency
                                                        $FrequencyText = $LocalizedData.RunScriptEveryBackupSession
                                                    }

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.RunFollowingScriptBefore = $Bkjob.ScriptOptions.PreScriptEnabled
                                                        $LocalizedData.RunScriptBeforeJob = $Bkjob.ScriptOptions.PreCommand
                                                        $LocalizedData.RunFollowingScriptAfter = $Bkjob.ScriptOptions.PostScriptEnabled
                                                        $LocalizedData.RunScriptAfterJob = $Bkjob.ScriptOptions.PostCommand
                                                        $LocalizedData.RunScriptFrequency = $Bkjob.ScriptOptions.Periodicity
                                                        $FrequencyText = $FrequencyValue

                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsScript) - $($Bkjob.Name)"
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
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.DataTransfer {
                                    $OutObj = @()
                                    try {
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.UseWanAccelerator = switch ($Bkjob.DataTransferMode) {
                                                    'ThroughWanAccelerators' { $LocalizedData.Yes }
                                                    'Direct' { $LocalizedData.No }
                                                    default { $LocalizedData.Unknown }
                                                }
                                                $LocalizedData.SourceWanAccelerator = $Bkjob.SourceAccelerator.Name
                                                $LocalizedData.TargetWanAccelerator = $Bkjob.TargetAccelerator.Name
                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.DataTransfer) - $($Bkjob.Name)"
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
                                if ($Bkjob.Mode -eq 'Periodic') {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Schedule {
                                        $OutObj = @()
                                        try {

                                            if ($Bkjob.ScheduleOptions.Type -eq 'Daily') {
                                                $ScheduleType = $LocalizedData.Daily
                                                $Schedule = "Kind: $($Bkjob.ScheduleOptions.DailyOptions.Type) at $($Bkjob.ScheduleOptions.DailyOptions.Period.ToString()), Days of Week: $($Bkjob.ScheduleOptions.DailyOptions.DayOfWeek)"
                                            } elseif ($Bkjob.ScheduleOptions.Type -eq 'Monthly') {
                                                $ScheduleType = $LocalizedData.Monthly
                                                $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.MonthlyOptions.DayOfWeek),`r`nAt $($Bkjob.ScheduleOptions.MonthlyOptions.Period.ToString()),"
                                            } elseif ($Bkjob.ScheduleOptions.Type -eq 'Periodically') {
                                                $ScheduleType = $Bkjob.ScheduleOptions.PeriodicallyOptions.PeriodicallyKind
                                                $Schedule = "Full Period: $($Bkjob.ScheduleOptions.PeriodicallyOptions.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.PeriodicallyOptions.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.PeriodicallyOptions.Unit)"
                                            } elseif ($Bkjob.ScheduleOptions.Type -eq 'AfterJob') {
                                                $ScheduleType = $LocalizedData.AfterJob
                                                $Schedule = "$($LocalizedData.AfterJobPrefix) $($BKjob.ScheduleOptions.Job.Name)"
                                            }
                                            $inObj = [ordered] @{
                                                $LocalizedData.RetryFailedEnabled = $Bkjob.ScheduleOptions.RetryEnabled
                                                $LocalizedData.RetryFailedItemProcessing = $Bkjob.ScheduleOptions.RetryCount
                                                $LocalizedData.WaitBeforeEachRetry = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                $LocalizedData.BackupWindowKey = $Bkjob.ScheduleOptions.BackupTerminationWindowEnabled
                                                $LocalizedData.ScheduleType = $ScheduleType
                                                $LocalizedData.ScheduleOptionsKey = $Schedule
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                            $TableParams = @{
                                                Name = "$($LocalizedData.ScheduleOptions) - $($Bkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if ($Bkjob.ScheduleOptions.BackupTerminationWindowEnabled) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.BackupWindowTimePeriod {
                                                        Paragraph -ScriptBlock $Legend

                                                        $OutObj = Get-WindowsTimePeriod -InputTimePeriod $Bkjob.ScheduleOptions.TerminationWindow

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
                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq '0' } | Set-Style -Style OFF -Property 'Sun'
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq '0' } | Set-Style -Style OFF -Property 'Mon'
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq '0' } | Set-Style -Style OFF -Property 'Tue'
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq '0' } | Set-Style -Style OFF -Property 'Wed'
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq '0' } | Set-Style -Style OFF -Property 'Thu'
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq '0' } | Set-Style -Style OFF -Property 'Fri'
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq '0' } | Set-Style -Style OFF -Property 'Sat'

                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq '1' } | Set-Style -Style ON -Property 'Sun'
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq '1' } | Set-Style -Style ON -Property 'Mon'
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq '1' } | Set-Style -Style ON -Property 'Tue'
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq '1' } | Set-Style -Style ON -Property 'Wed'
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq '1' } | Set-Style -Style ON -Property 'Thu'
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq '1' } | Set-Style -Style ON -Property 'Fri'
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq '1' } | Set-Style -Style ON -Property 'Sat'
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
                                if ($Bkjob.Mode -eq 'Immediate') {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Schedule {
                                        $OutObj = @()
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.RetryFailedEnabled = $Bkjob.ScheduleOptions.RetryEnabled
                                                $LocalizedData.RetryFailedItemProcessing = $Bkjob.ScheduleOptions.RetryCount
                                                $LocalizedData.WaitBeforeEachRetry = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                $LocalizedData.BackupWindowKey = $Bkjob.ScheduleOptions.BackupTerminationWindowEnabled
                                                $LocalizedData.ScheduleType = $Bkjob.ScheduleOptions.Type
                                                $LocalizedData.ScheduleOptionsKey = $LocalizedData.Continuously
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                            $TableParams = @{
                                                Name = "$($LocalizedData.ScheduleOptions) - $($Bkjob.Name)"
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
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Copy Jobs'
    }

}