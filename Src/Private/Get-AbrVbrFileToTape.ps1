
function Get-AbrVbrFileToTape {
    <#
    .SYNOPSIS
        Used by As Built Report to returns tape backup jobs configuration created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR File to Tape Backup jobs configuration information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'File to Tape Backup jobs'
    }

    process {
        try {
            if ($TBkjobs = Get-VBRTapeJob | Where-Object { $_.Type -eq 'FileToTape' } | Sort-Object -Property Name) {
                Section -Style Heading3 'File To Tape Job Configuration' {
                    Paragraph "The following section details the configuration about file to tape jobs."
                    BlankLine
                    $OutObj = @()
                    if ($TBkjobs) {
                        foreach ($TBkjob in $TBkjobs) {
                            Section -Style Heading4 $($TBkjob.Name) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Backups Information' {
                                    $OutObj = @()
                                    try {
                                        Write-PScriboMessage "Discovered $($TBkjob.Name) common information."
                                        $inObj = [ordered] @{
                                            'Name' = $TBkjob.Name
                                            'Type' = $TBkjob.Type
                                            'Next Run' = Switch ($TBkjob.Enabled) {
                                                'False' { 'Disabled' }
                                                default { $TBkjob.NextRun }
                                            }
                                            'Description' = $TBkjob.Description
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                        }

                                        $TableParams = @{
                                            Name = "Common Information - $($TBkjob.Name)"
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
                                        Write-PScriboMessage -IsWarning "Common Information $($TBkjob.Name) Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($TBkjob.Object) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Files and Folders' {
                                            $OutObj = @()
                                            foreach ($File in $TBkjob.Object) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($File.Name) files and folders to process."
                                                    $inObj = [ordered] @{
                                                        'Name' = $File.Server.Name
                                                        'Type' = $File.Server.Type
                                                        'Selection Type' = $File.SelectionType
                                                        'Path' = $File.Path
                                                        'Include Filter' = $File.IncludeMask
                                                        'Exclude Filter' = $File.ExcludeMask
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Files and Folders $($File.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                            if ($TBkjob.NdmpObject) {
                                                foreach ($NDMP in $TBkjob.NdmpObject) {
                                                    try {
                                                        Write-PScriboMessage "Discovered $($NDMP.Name) NDMP to process."
                                                        $inObj2 = [ordered] @{
                                                            'Name' = Switch ((Get-VBRNDMPServer -Id $NDMP.ServerId).Name) {
                                                                $Null { 'NDMP Object' }
                                                                default { (Get-VBRNDMPServer -Id $NDMP.ServerId).Name }
                                                            }
                                                            'Type' = 'NDMP'
                                                            'Selection Type' = 'Directory'
                                                            'Path' = $NDMP.Name
                                                            'Include Filter' = '--'
                                                            'Exclude Filter' = '--'
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj2)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Files and Folders $($NDMP.Name) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Files and Folders - $($TBkjob.Name)"
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Full Backup' {
                                            $OutObj = @()
                                            foreach ($BackupMediaPool in $TBkjob.FullBackupMediaPool) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($TBkjob.Name) media pool."
                                                    $inObj = [ordered] @{
                                                        'Name' = $BackupMediaPool.Name
                                                        'Pool Type' = $BackupMediaPool.Type
                                                        'Tape Count' = (Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).count
                                                        'Capacity' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupMediaPool.Capacity
                                                        'Remaining' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size  $BackupMediaPool.FreeSpace
                                                        'Is WORM' = $BackupMediaPool.Worm
                                                        'Schedule Enabled' = $TBkjob.FullBackupPolicy.Enabled
                                                    }
                                                    if ($BackupMediaPool.Type -eq "Custom" -and $TBkjob.FullBackupPolicy.Enabled) {
                                                        if ($TBkjob.FullBackupPolicy.Type -eq 'Daily') {
                                                            $inObj.add('Daily at this Time', ("$($TBkjob.FullBackupPolicy.DailyOptions.Period) - $($TBkjob.FullBackupPolicy.DailyOptions.DayOfWeek -join ", ")"))
                                                        } elseif ($TBkjob.FullBackupPolicy.Type -eq 'Monthly') {
                                                            $Months = Switch (($TBkjob.FullBackupPolicy.MonthlyOptions.Months).count) {
                                                                12 { 'Every Month' }
                                                                default { $TBkjob.FullBackupPolicy.MonthlyOptions.Months -join ", " }
                                                            }
                                                            if ($TBkjob.FullBackupPolicy.MonthlyOptions.DayNumberInMonth -eq 'OnDay') {
                                                                $inObj.add('Monthly at this Time', ("At $($TBkjob.FullBackupPolicy.DailyOptions.Period), Monthly on the: $($TBkjob.FullBackupPolicy.MonthlyOptions.DayOfMonth) day of $Months"))
                                                            } else {
                                                                $inObj.add('Monthly at this Time', ("At $($TBkjob.FullBackupPolicy.DailyOptions.Period), Monthly on the: $($TBkjob.FullBackupPolicy.MonthlyOptions.DayNumberInMonth) $($TBkjob.FullBackupPolicy.MonthlyOptions.DayOfWeek) of $Months"))
                                                            }
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Full Backup $($BackupMediaPool.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Full Backup - $($TBkjob.Name)"
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Incremental Backup' {
                                            $OutObj = @()
                                            foreach ($BackupMediaPool in $TBkjob.IncrementalBackupMediaPool) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($TBkjob.Name) incremental backup."
                                                    $inObj = [ordered] @{
                                                        'Name' = $BackupMediaPool.Name
                                                        'Pool Type' = $BackupMediaPool.Type
                                                        'Tape Count' = (Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).count
                                                        'Capacity' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size  $BackupMediaPool.Capacity
                                                        'Remaining' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size  $BackupMediaPool.FreeSpace
                                                        'Is WORM' = $BackupMediaPool.Worm
                                                        'Schedule Enabled' = $TBkjob.IncrementalBackupPolicy.Enabled
                                                    }
                                                    if ($BackupMediaPool.Type -eq "Custom" -and $TBkjob.IncrementalBackupPolicy.Enabled) {
                                                        if ($TBkjob.IncrementalBackupPolicy.Type -eq 'Daily') {
                                                            $inObj.add('Daily at this Time', ("$($TBkjob.IncrementalBackupPolicy.DailyOptions.Period) - $($TBkjob.IncrementalBackupPolicy.DailyOptions.DayOfWeek -join ", ")"))
                                                        } elseif ($TBkjob.IncrementalBackupPolicy.Type -eq 'Monthly') {
                                                            $Months = Switch (($TBkjob.IncrementalBackupPolicy.MonthlyOptions.Months).count) {
                                                                12 { 'Every Month' }
                                                                default { $TBkjob.IncrementalBackupPolicy.MonthlyOptions.Months -join ", " }
                                                            }
                                                            if ($TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayNumberInMonth -eq 'OnDay') {
                                                                $inObj.add('Monthly at this Time', ("At $($TBkjob.IncrementalBackupPolicy.DailyOptions.Period), Monthly on the: $($TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayOfMonth) day of $Months"))
                                                            } else {
                                                                $inObj.add('Monthly at this Time', ("At $($TBkjob.IncrementalBackupPolicy.DailyOptions.Period), Monthly on the: $($TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayNumberInMonth) $($TBkjob.IncrementalBackupPolicy.MonthlyOptions.DayOfWeek) of $Months"))
                                                            }
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Incremental Backup $($BackupMediaPool.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Incremental Backup - $($TBkjob.Name)"
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
                                            Write-PScriboMessage "Discovered $($TBkjob.Name) options."
                                            $inObj = [ordered] @{
                                                'Use Microsoft volume shadow copy (VSS)' = $TBkjob.UseVss
                                                'Eject Tape Media Upon Job Completion' = $TBkjob.EjectCurrentMedium
                                                'Export the following MediaSet Upon Job Completion' = $TBkjob.ExportCurrentMediaSet
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
                                                        Write-PScriboMessage "Discovered $($TBkjob.Name) notification options."
                                                        $inObj = [ordered] @{
                                                            'Send Email Notification' = $TBkjob.NotificationOptions.EnableAdditionalNotification
                                                            'Email Notification Additional Recipients' = $TBkjob.NotificationOptions.AdditionalAddress -join ","
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
                                                        Write-PScriboMessage "Discovered $($TBkjob.Name) advanced options."
                                                        $inObj = [ordered] @{
                                                            'Use Hardware Compression when available' = $TBkjob.UseHardwareCompression
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
                                                                $FrequencyValue = $TBkjob.JobScriptOptions.Day -join ", "
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
