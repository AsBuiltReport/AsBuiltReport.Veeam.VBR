
function Get-AbrVbrFileToTape {
    <#
    .SYNOPSIS
        Used by As Built Report to returns tape backup jobs configuration created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR File to Tape Backup jobs configuration information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrFileToTape
        Show-AbrDebugExecutionTime -Start -TitleMessage 'File to Tape Backup jobs'
    }

    process {
        try {
            if ($TBkjobs = Get-VBRTapeJob | Where-Object { $_.Type -eq 'FileToTape' } | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    if ($TBkjobs) {
                        foreach ($TBkjob in $TBkjobs) {
                            Section -Style Heading4 $($TBkjob.Name) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.BackupsInformation {
                                    $OutObj = @()
                                    try {

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $TBkjob.Name
                                            $LocalizedData.Type = $TBkjob.Type
                                            $LocalizedData.NextRun = switch ($TBkjob.Enabled) {
                                                'False' { $LocalizedData.Disabled }
                                                default { $TBkjob.NextRun }
                                            }
                                            $LocalizedData.Description = $TBkjob.Description
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.CommonInformation) - $($TBkjob.Name)"
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
                                                    Text $LocalizedData.BestPracticeDescription
                                                }
                                                BlankLine
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Common Information $($TBkjob.Name) Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($TBkjob.Object) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.FilesAndFolders {
                                            $OutObj = @()
                                            foreach ($File in $TBkjob.Object) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $File.Server.Name
                                                        $LocalizedData.Type = $File.Server.Type
                                                        $LocalizedData.SelectionType = $File.SelectionType
                                                        $LocalizedData.Path = $File.Path
                                                        $LocalizedData.IncludeFilter = $File.IncludeMask
                                                        $LocalizedData.ExcludeFilter = $File.ExcludeMask
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Files and Folders $($File.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                            if ($TBkjob.NdmpObject) {
                                                foreach ($NDMP in $TBkjob.NdmpObject) {
                                                    try {

                                                        $inObj2 = [ordered] @{
                                                            $LocalizedData.Name = switch ((Get-VBRNDMPServer -Id $NDMP.ServerId).Name) {
                                                                $Null { $LocalizedData.NdmpObject }
                                                                default { (Get-VBRNDMPServer -Id $NDMP.ServerId).Name }
                                                            }
                                                            $LocalizedData.Type = $LocalizedData.Ndmp
                                                            $LocalizedData.SelectionType = $LocalizedData.Directory
                                                            $LocalizedData.Path = $NDMP.Name
                                                            $LocalizedData.IncludeFilter = '--'
                                                            $LocalizedData.ExcludeFilter = '--'
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj2)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Files and Folders $($NDMP.Name) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.FilesAndFolders) - $($TBkjob.Name)"
                                                List = $false
                                                ColumnWidths = 25, 15, 15, 25, 10, 10
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Files and Folders Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($TBkjob.FullBackupMediaPool) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.FullBackup {
                                            $OutObj = @()
                                            foreach ($BackupMediaPool in $TBkjob.FullBackupMediaPool) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $BackupMediaPool.Name
                                                        $LocalizedData.PoolType = $BackupMediaPool.Type
                                                        $LocalizedData.TapeCount = (Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).count
                                                        $LocalizedData.Capacity = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupMediaPool.Capacity
                                                        $LocalizedData.Remaining = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupMediaPool.FreeSpace
                                                        $LocalizedData.IsWorm = $BackupMediaPool.Worm
                                                        $LocalizedData.ScheduleEnabled = $TBkjob.FullBackupPolicy.Enabled
                                                    }
                                                    if ($BackupMediaPool.Type -eq 'Custom' -and $TBkjob.FullBackupPolicy.Enabled) {
                                                        if ($TBkjob.FullBackupPolicy.Type -eq 'Daily') {
                                                            $inObj.add($LocalizedData.DailyAtThisTime, ("$($TBkjob.FullBackupPolicy.DailyOptions.Period) - $($TBkjob.FullBackupPolicy.DailyOptions.DayOfWeek -join ', ')"))
                                                        } elseif ($TBkjob.FullBackupPolicy.Type -eq 'Monthly') {
                                                            $Months = switch (($TBkjob.FullBackupPolicy.MonthlyOptions.Months).count) {
                                                                12 { $LocalizedData.EveryMonth }
                                                                default { $TBkjob.FullBackupPolicy.MonthlyOptions.Months -join ', ' }
                                                            }
                                                            if ($TBkjob.FullBackupPolicy.MonthlyOptions.DayNumberInMonth -eq 'OnDay') {
                                                                $inObj.add($LocalizedData.MonthlyAtThisTime, ($LocalizedData.MonthlyOnTheDayOf -f $TBkjob.FullBackupPolicy.DailyOptions.Period, $TBkjob.FullBackupPolicy.MonthlyOptions.DayOfMonth, $Months))
                                                            } else {
                                                                $inObj.add($LocalizedData.MonthlyAtThisTime, ($LocalizedData.MonthlyOnTheDayNumberOf -f $TBkjob.FullBackupPolicy.DailyOptions.Period, $TBkjob.FullBackupPolicy.MonthlyOptions.DayNumberInMonth, $TBkjob.FullBackupPolicy.MonthlyOptions.DayOfWeek, $Months))
                                                            }
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Full Backup $($BackupMediaPool.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.FullBackup) - $($TBkjob.Name)"
                                                List = $True
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Full Backup Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($TBkjob.IncrementalBackupPolicy) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.IncrementalBackup {
                                            $OutObj = @()
                                            foreach ($BackupMediaPool in $TBkjob.IncrementalBackupMediaPool) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $BackupMediaPool.Name
                                                        $LocalizedData.PoolType = $BackupMediaPool.Type
                                                        $LocalizedData.TapeCount = (Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).count
                                                        $LocalizedData.Capacity = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupMediaPool.Capacity
                                                        $LocalizedData.Remaining = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupMediaPool.FreeSpace
                                                        $LocalizedData.IsWorm = $BackupMediaPool.Worm
                                                        $LocalizedData.ScheduleEnabled = $TBkjob.IncrementalBackupPolicy.Enabled
                                                    }
                                                    if ($BackupMediaPool.Type -eq 'Custom' -and $TBkjob.IncrementalBackupPolicy.Enabled) {
                                                        if ($TBkjob.IncrementalBackupPolicy.Type -eq 'Daily') {
                                                            $inObj.add($LocalizedData.DailyAtThisTime, ("$($TBkjob.IncrementalBackupPolicy.DailyOptions.Period) - $($TBkjob.IncrementalBackupPolicy.DailyOptions.DayOfWeek -join ', ')"))
                                                        } elseif ($TBkjob.IncrementalBackupPolicy.Type -eq 'Monthly') {
                                                            $Months = switch (($TBkjob.IncrementalBackupPolicy.MonthlyOptions.Months).count) {
                                                                12 { $LocalizedData.EveryMonth }
                                                                default { $TBkjob.IncrementalBackupPolicy.MonthlyOptions.Months -join ', ' }
                                                            }
                                                            if ($TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayNumberInMonth -eq 'OnDay') {
                                                                $inObj.add($LocalizedData.MonthlyAtThisTime, ($LocalizedData.MonthlyOnTheDayOf -f $TBkjob.IncrementalBackupPolicy.DailyOptions.Period, $TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayOfMonth, $Months))
                                                            } else {
                                                                $inObj.add($LocalizedData.MonthlyAtThisTime, ($LocalizedData.MonthlyOnTheDayNumberOf -f $TBkjob.IncrementalBackupPolicy.DailyOptions.Period, $TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayNumberInMonth, $TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayOfWeek, $Months))
                                                            }
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Incremental Backup $($BackupMediaPool.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.IncrementalBackup) - $($TBkjob.Name)"
                                                List = $True
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Incremental Backup $($TBkjob.Name) Section: $($_.Exception.Message)"
                                    }
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Options' {
                                        $OutObj = @()
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.UseVss = $TBkjob.UseVss
                                                $LocalizedData.EjectTapeMedia = $TBkjob.EjectCurrentMedium
                                                $LocalizedData.ExportMediaSet = $TBkjob.ExportCurrentMediaSet
                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Options $($TBkjob.Name) Section: $($_.Exception.Message)"
                                        }

                                        $TableParams = @{
                                            Name = "Options - $($TBkjob.Name)"
                                            List = $True
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        if ($InfoLevel.Jobs.Tape -ge 2 -and $TBkjob.NotificationOptions.EnableAdditionalNotification) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Advanced Settings (Notifications)' {
                                                    $OutObj = @()
                                                    try {

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.SendEmailNotification = $TBkjob.NotificationOptions.EnableAdditionalNotification
                                                            $LocalizedData.EmailAdditionalRecipients = $TBkjob.NotificationOptions.AdditionalAddress -join ','
                                                        }
                                                        if (!$TBkjob.NotificationOptions.UseNotificationOptions) {
                                                            $inObj.add('Use Global Notification Settings', ($TBkjob.NotificationOptions.UseNotificationOptions))
                                                        } elseif ($TBkjob.NotificationOptions.UseNotificationOptions) {
                                                            $inObj.add('Use Custom Notification Settings', ('Yes'))
                                                            $inObj.add('Subject', ($TBkjob.NotificationOptions.NotificationSubject))
                                                            $inObj.add('Notify On Success', ($TBkjob.NotificationOptions.NotifyOnSuccess))
                                                            $inObj.add('Notify On Warning', ($TBkjob.NotificationOptions.NotifyOnWarning))
                                                            $inObj.add('Notify On Error', ($TBkjob.NotificationOptions.NotifyOnError))
                                                            $inObj.add('Notify On Last Retry Only', ($TBkjob.NotificationOptions.NotifyOnLastRetryOnly))
                                                            $inObj.add('Notify When Waiting For Tape', ($TBkjob.NotificationOptions.NotifyWhenWaitingForTape))
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Advanced Settings (Notifications) $($TBkjob.Name) Section: $($_.Exception.Message)"
                                                    }

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Notifications) - $($TBkjob.Name)"
                                                        List = $True
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Advanced Settings (Notifications) Section: $($_.Exception.Message)"
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Tape -ge 2 -and $TBkjob.NotificationOptions.EnableAdditionalNotification) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC 'Advanced Settings (Advanced)' {
                                                    $OutObj = @()
                                                    try {

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.UseHardwareCompression = $TBkjob.UseHardwareCompression
                                                        }
                                                        if (!$TBkjob.JobScriptOptions.PreScriptEnabled) {
                                                            $inObj.add('Pre Job Script Enabled', ($TBkjob.JobScriptOptions.PreScriptEnabled))
                                                        } elseif ($TBkjob.JobScriptOptions.PreScriptEnabled) {
                                                            $inObj.add('Run the following script before job', ($TBkjob.JobScriptOptions.PreCommand))
                                                        }
                                                        if (!$TBkjob.JobScriptOptions.PostScriptEnabled) {
                                                            $inObj.add('Post Job Script Enabled', ($TBkjob.JobScriptOptions.PostScriptEnabled))
                                                        } elseif ($TBkjob.JobScriptOptions.PostScriptEnabled) {
                                                            $inObj.add('Run the following script after job', ($TBkjob.JobScriptOptions.PostCommand))
                                                        }
                                                        if ($TBkjob.JobScriptOptions.PreScriptEnabled -or $TBkjob.JobScriptOptions.PostScriptEnabled) {
                                                            if ($TBkjob.JobScriptOptions.Periodicity -eq 'Days') {
                                                                $FrequencyValue = $TBkjob.JobScriptOptions.Day -join ', '
                                                                $FrequencyText = 'Run Script on the Selected Days'
                                                            } elseif ($TBkjob.JobScriptOptions.Periodicity -eq 'Cycles') {
                                                                $FrequencyValue = "Every $($TBkjob.JobScriptOptions.Frequency) backup session"
                                                                $FrequencyText = 'Run Script Every Backup Session'
                                                            }
                                                            $inObj.add($FrequencyText, ($FrequencyValue))
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Advanced Settings (Advanced) $($TBkjob.Name) Section: $($_.Exception.Message)"
                                                    }

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Advanced) - $($TBkjob.Name)"
                                                        List = $True
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Advanced Settings (Advanced) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Options Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "File To Tape Job Configuration Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'File to Tape Backup jobs'
    }

}
