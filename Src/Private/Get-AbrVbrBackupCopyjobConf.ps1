
function Get-AbrVbrBackupCopyjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns vmware backup copy jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR backup copy jobs information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Backup Copy Jobs"
    }

    process {
        try {
            if ($Bkjobs = Get-VBRBackupCopyJob -WarningAction SilentlyContinue | Sort-Object -Property Name) {
                Section -Style Heading3 'Backup Copy Jobs Configuration' {
                    Paragraph "The following section details the configuration of backup copy jobs."
                    BlankLine
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
                                                'Id' = $Bkjob.Id
                                                'Type' = $Bkjob.type
                                                'Copy Mode' = $Bkjob.Mode
                                                'Last Result' = $Bkjob.LastResult
                                                'Status' = $Bkjob.LastState
                                                'Next Run' = $Bkjob.NextRun
                                                'Include database transaction log backup' = $Bkjob.TransactionLogCopyEnabled
                                                'Description' = $Bkjob.Description
                                                'Modified By' = (Get-VBRJob -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Where-Object { $_.id -eq $Bkjob.Id }).Info.CommonInfo.ModifiedBy.FullName
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $Null -like $_.'Description' -or $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Latest Result' -eq 'Failed' } | Set-Style -Style Critical -Property 'Latest Result'
                                            $OutObj | Where-Object { $_.'Latest Result' -eq 'Warning' } | Set-Style -Style Warning -Property 'Latest Result'
                                            $OutObj | Where-Object { $_.'Status' -eq 'Disabled' } | Set-Style -Style Warning -Property 'Status'
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
                                            if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $_.'Description' -eq '--' }) {
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
                                if ($Bkjob.BackupJob) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Backup Jobs Objects' {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedBkJob in $Bkjob.BackupJob) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($LinkedBkJob.Name) linked backup job objects."
                                                    $inObj = [ordered] @{
                                                        'Name' = $LinkedBkJob.Name
                                                        'Type' = $LinkedBkJob.TypeToString
                                                        'Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $LinkedBkJob.Info.IncludedSize
                                                        'Repository' = $LinkedBkJob.GetTargetRepository().Name
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Backup Jobs Objects - $($Bkjob.Name)"
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
                                if ($Bkjob.SourceRepository) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Repositories Objects' {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedRepository in $Bkjob.SourceRepository) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($LinkedRepository.Name) linked repository objects."
                                                    if ($LinkedRepository.Type -eq "ExtendableRepository") {
                                                        $inObj = [ordered] @{
                                                            'Name' = $LinkedRepository.Name
                                                            'Type' = "ScaleOut"
                                                            'Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $LinkedRepository.GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    } else {
                                                        $inObj = [ordered] @{
                                                            'Name' = $LinkedRepository.Name
                                                            'Type' = "Standard"
                                                            'Size' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $LinkedRepository.GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Repositories Objects - $($Bkjob.Name)"
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
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Target' {
                                    $OutObj = @()
                                    try {
                                        Write-PScriboMessage "Discovered $($Bkjob.Name) Target options."
                                        if ($Bkjob.RetentionType -eq "RestoreDays") {
                                            $RetainString = 'Retain Days To Keep'
                                            $Retains = $Bkjob.RetentionNumber
                                        } elseif ($Bkjob.RetentionType -eq "RestorePoints") {
                                            $RetainString = 'Restore Points'
                                            $Retains = $Bkjob.RetentionNumber
                                        }
                                        $inObj = [ordered] @{
                                            'Backup Repository' = $Bkjob.Target
                                            'Retention Type' = SWitch ($Bkjob.RetentionType) {
                                                'RestoreDays' { 'Restore Days' }
                                                'RestorePoints' { 'Restore Points' }
                                                default { 'Unknown' }
                                            }
                                            $RetainString = $Retains
                                        }
                                        if ($Bkjob.GFSOptions) {
                                            if (-Not $Bkjob.GFSOptions.WeeklyGFSEnabled) {
                                                $inObj.add('Keep Weekly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Weekly full backup for', ("$($Bkjob.GFSOptions.WeeklyOptions.RetentionPeriod) weeks,`r`nCreate weekly full on this day: $($Bkjob.GFSOptions.WeeklyOptions.SelectedDay)"))
                                            }
                                            if (-Not $Bkjob.GFSOptions.MonthlyGFSEnabled) {
                                                $inObj.add('Keep Monthly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Monthly full backup for', ("$($Bkjob.GFSOptions.MonthlyOptions.RetentionPeriod) months,`r`nUse weekly full backup from the following week of the month: $($Bkjob.GFSOptions.MonthlyOptions.SelectedWeek)"))
                                            }
                                            if (-Not $Bkjob.GFSOptions.YearlyGFSEnabled) {
                                                $inObj.add('Keep Yearly full backup', ('Disabled'))
                                            } else {
                                                $inObj.add('Keep Yearly full backup for', ("$($Bkjob.GFSOptions.YearlyOptions.RetentionPeriod) years,`r`nUse monthly full backup from the following month: $($Bkjob.GFSOptions.YearlyOptions.SelectedMonth)"))
                                            }
                                            $inObj.add('Read the entire RestorePoint fromSource Backup', ($Bkjob.GFSOptions.ReadEntireRestorePoint))
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "Target Options - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Maintenance)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) maintenance options."
                                                    $inObj = [ordered] @{
                                                        'Storage-Level Corruption Guard (SLCG)' = $Bkjob.HealthCheckOptions.Enabled
                                                        'SLCG Schedule Type' = $Bkjob.HealthCheckOptions.ScheduleType
                                                    }

                                                    if ($Bkjob.HealthCheckOptions.ScheduleType -eq 'Monthly') {
                                                        $inObj.add("SLCG Backup Monthly Schedule at", "Hour of Day: $($Bkjob.HealthCheckOptions.MonthlyPeriod)`r`nDay Number In Month: $($Bkjob.HealthCheckOptions.DayNumber)`r`nDay Of Week: $($Bkjob.HealthCheckOptions.DayOfWeek)`r`nDay of Month: $($Bkjob.HealthCheckOptions.DayOfMonth)`r`nMonths: $($Bkjob.HealthCheckOptions.SelectedMonths)")

                                                    } elseif ($Bkjob.HealthCheckOptions.ScheduleType -eq 'Weekly') {
                                                        $inObj.add("SLCG Backup Weekly Schedule at", "Hour of Day: $($Bkjob.HealthCheckOptions.WeeklyPeriod)`r`nSelected Days: $($Bkjob.HealthCheckOptions.SelectedDays)")

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
                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Storage)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) storage options."
                                                    $inObj = [ordered] @{
                                                        'Inline Data Deduplication' = $Bkjob.StorageOptions.DataDeduplicationEnabled
                                                        'Compression Level' = $Bkjob.StorageOptions.CompressionLevel
                                                        'Enabled Backup File Encryption' = $Bkjob.StorageOptions.EncryptionEnabled
                                                        'Encryption Key' = $Bkjob.StorageOptions.EncryptionKey.Description
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.'Enabled Backup File Encryption' -eq 'No' } | Set-Style -Style Warning -Property 'Enabled Backup File Encryption'
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

                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (RPO Monitor)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) rpo monitor options."
                                                    $BackupJob = $Bkjob.RpoWarningOptions | Where-Object { $_.RpoType -eq 'BackupJob' }
                                                    $BackupLogJob = $Bkjob.RpoWarningOptions | Where-Object { $_.RpoType -eq 'BackupLogJob' }

                                                    $inObj = [ordered] @{
                                                        'Alert me when new backup is not copied within' = "$($BackupJob.Value) $($BackupJob.TimeUnit)`r`nEnable:$($BackupJob.EnableRpoWarning)"
                                                        'Alert me when new log backup is not copied within' = "$($BackupLogJob.Value) $($BackupLogJob.TimeUnit)`r`nEnabled:$($BackupLogJob.EnableRpoWarning)"

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

                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Notification)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) notification options."
                                                    $inObj = [ordered] @{
                                                        'Send Snmp Notification' = $Bkjob.NotificationOptions.EnableSnmpNotification
                                                        'Send Email Notification' = $Bkjob.NotificationOptions.EnableAdditionalNotification
                                                        'Email Notification Additional Addresses' = Switch ($Bkjob.NotificationOptions.AdditionalAddress) {
                                                            $Null { '--' }
                                                            default { $Bkjob.NotificationOptions.AdditionalAddress }
                                                        }
                                                        'Email Notify Time' = $Bkjob.NotificationOptions.SendTime
                                                        'Use Custom Email Notification Options' = $Bkjob.NotificationOptions.UseNotificationOptions
                                                        'Use Custom Notification Setting' = $Bkjob.NotificationOptions.NotificationSubject
                                                        'Notify On Success' = $Bkjob.NotificationOptions.NotifyOnSuccess
                                                        'Notify On Warning' = $Bkjob.NotificationOptions.NotifyOnWarning
                                                        'Notify On Error' = $Bkjob.NotificationOptions.NotifyOnError
                                                        'Send notification' = Switch ($Bkjob.NotificationOptions.EnableDailyNotification) {
                                                            'False' { 'Immediately after each copied backup' }
                                                            'True' { 'Daily as a summary' }
                                                            default { 'Unknown' }
                                                        }
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

                                        if ($InfoLevel.Jobs.BackupCopy -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Script)" {
                                                $OutObj = @()
                                                try {
                                                    if ($Bkjob.ScriptOptions.Periodicity -eq 'Days') {
                                                        $FrequencyValue = $Bkjob.ScriptOptions.Days -join ","
                                                        $FrequencyText = 'Run Script on the Selected Days'
                                                    } elseif ($Bkjob.ScriptOptions.Periodicity -eq 'Cycles') {
                                                        $FrequencyValue = $Bkjob.ScriptOptions.Frequency
                                                        $FrequencyText = 'Run Script Every Backup Session'
                                                    }
                                                    Write-PScriboMessage "Discovered $($Bkjob.Name) script options."
                                                    $inObj = [ordered] @{
                                                        'Run the Following Script Before' = $Bkjob.ScriptOptions.PreScriptEnabled
                                                        'Run Script Before the Job' = $Bkjob.ScriptOptions.PreCommand
                                                        'Run the Following Script After' = $Bkjob.ScriptOptions.PostScriptEnabled
                                                        'Run Script After the Job' = $Bkjob.ScriptOptions.PostCommand
                                                        'Run Script Frequency' = $Bkjob.ScriptOptions.Periodicity
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
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Data Transfer' {
                                    $OutObj = @()
                                    try {
                                        try {
                                            Write-PScriboMessage "Discovered $($Bkjob.Name) data transfer."
                                            $inObj = [ordered] @{
                                                'Use Wan accelerator' = Switch ($Bkjob.DataTransferMode) {
                                                    'ThroughWanAccelerators' { 'Yes' }
                                                    'Direct' { 'No' }
                                                    default { 'Unkwnown' }
                                                }
                                                'Source Wan accelerator' = $Bkjob.SourceAccelerator.Name
                                                'Target Wan accelerator' = $Bkjob.TargetAccelerator.Name
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
                                if ($Bkjob.Mode -eq 'Periodic') {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                        $OutObj = @()
                                        try {
                                            Write-PScriboMessage "Discovered $($Bkjob.Name) schedule options."
                                            if ($Bkjob.ScheduleOptions.Type -eq "Daily") {
                                                $ScheduleType = "Daily"
                                                $Schedule = "Kind: $($Bkjob.ScheduleOptions.DailyOptions.Type) at $($Bkjob.ScheduleOptions.DailyOptions.Period.ToString()), Days of Week: $($Bkjob.ScheduleOptions.DailyOptions.DayOfWeek)"
                                            } elseif ($Bkjob.ScheduleOptions.Type -eq "Monthly") {
                                                $ScheduleType = "Monthly"
                                                $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.MonthlyOptions.DayOfWeek),`r`nAt $($Bkjob.ScheduleOptions.MonthlyOptions.Period.ToString()),"
                                            } elseif ($Bkjob.ScheduleOptions.Type -eq "Periodically") {
                                                $ScheduleType = $Bkjob.ScheduleOptions.PeriodicallyOptions.PeriodicallyKind
                                                $Schedule = "Full Period: $($Bkjob.ScheduleOptions.PeriodicallyOptions.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.PeriodicallyOptions.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.PeriodicallyOptions.Unit)"
                                            } elseif ($Bkjob.ScheduleOptions.Type -eq "AfterJob") {
                                                $ScheduleType = 'AfterJob'
                                                $Schedule = "After Job: $($BKjob.ScheduleOptions.Job.Name)"
                                            }
                                            $inObj = [ordered] @{
                                                'Retry Failed Enabled?' = $Bkjob.ScheduleOptions.RetryEnabled
                                                'Retry Failed item processing' = $Bkjob.ScheduleOptions.RetryCount
                                                'Wait before each retry' = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                'Backup Window' = $Bkjob.ScheduleOptions.BackupTerminationWindowEnabled
                                                'Shedule type' = $ScheduleType
                                                'Shedule Options' = $Schedule
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
                                            if ($Bkjob.ScheduleOptions.BackupTerminationWindowEnabled) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Backup Window Time Period" {
                                                        Paragraph -ScriptBlock $Legend

                                                        $OutObj = Get-WindowsTimePeriod -InputTimePeriod $Bkjob.ScheduleOptions.TerminationWindow

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
                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq "0" } | Set-Style -Style OFF -Property "Sun"
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq "0" } | Set-Style -Style OFF -Property "Mon"
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq "0" } | Set-Style -Style OFF -Property "Tue"
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq "0" } | Set-Style -Style OFF -Property "Wed"
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq "0" } | Set-Style -Style OFF -Property "Thu"
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq "0" } | Set-Style -Style OFF -Property "Fri"
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq "0" } | Set-Style -Style OFF -Property "Sat"

                                                            $OutObj2.Rows | Where-Object { $_.Sun -eq "1" } | Set-Style -Style ON -Property "Sun"
                                                            $OutObj2.Rows | Where-Object { $_.Mon -eq "1" } | Set-Style -Style ON -Property "Mon"
                                                            $OutObj2.Rows | Where-Object { $_.Tue -eq "1" } | Set-Style -Style ON -Property "Tue"
                                                            $OutObj2.Rows | Where-Object { $_.Wed -eq "1" } | Set-Style -Style ON -Property "Wed"
                                                            $OutObj2.Rows | Where-Object { $_.Thu -eq "1" } | Set-Style -Style ON -Property "Thu"
                                                            $OutObj2.Rows | Where-Object { $_.Fri -eq "1" } | Set-Style -Style ON -Property "Fri"
                                                            $OutObj2.Rows | Where-Object { $_.Sat -eq "1" } | Set-Style -Style ON -Property "Sat"
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
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                        $OutObj = @()
                                        try {
                                            Write-PScriboMessage "Discovered $($Bkjob.Name) schedule options."
                                            $inObj = [ordered] @{
                                                'Retry Failed Enabled?' = $Bkjob.ScheduleOptions.RetryEnabled
                                                'Retry Failed item processing' = $Bkjob.ScheduleOptions.RetryCount
                                                'Wait before each retry' = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                'Backup Window' = $Bkjob.ScheduleOptions.BackupTerminationWindowEnabled
                                                'Shedule type' = $Bkjob.ScheduleOptions.Type
                                                'Shedule Options' = "Continuously"
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
        Show-AbrDebugExecutionTime -End -TitleMessage "Backup Copy Jobs"
    }

}