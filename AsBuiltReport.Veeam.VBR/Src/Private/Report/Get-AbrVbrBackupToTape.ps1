
function Get-AbrVbrBackupToTape {
    <#
    .SYNOPSIS
        Used by As Built Report to returns tape backup jobs configuration created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Tape Backup jobs configuration information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup To Tape Jobs'
        $LocalizedData = $reportTranslate.GetAbrVbrBackupToTape
    }

    process {
        try {
            if ($TBkjobs = Get-VBRTapeJob | Where-Object { $_.Type -eq 'BackupToTape' } | Sort-Object -Property Name) {
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

                                        if ($TBkjob.Object.Group -eq 'BackupRepository') {
                                            $RepoSize = $TBkjob.Object | Where-Object { $_.Group -eq 'BackupRepository' }
                                            $TotalBackupSize = (($TBkjob.Object.info.IncludedSize | Measure-Object -Sum ).Sum) + ($RepoSize.GetContainer().CachedTotalSpace.InBytes - $RepoSize.GetContainer().CachedFreeSpace.InBytes)
                                        } else { $TotalBackupSize = ($TBkjob.Object.info.IncludedSize | Measure-Object -Sum).Sum }

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $TBkjob.Name
                                            $LocalizedData.Type = $TBkjob.Type
                                            $LocalizedData.TotalBackupSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $TotalBackupSize
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
                                            Name = "$($LocalizedData.CommonInfoTable) - $($TBkjob.Name)"
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
                                        Write-PScriboMessage -IsWarning "Common Information - $($TBkjob.Name) Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($TBkjob.Object) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.BackupsObjects {
                                            $OutObj = @()
                                            foreach ($LinkedBkJob in $TBkjob.Object) {
                                                try {

                                                    if ($LinkedBkJob.Type) {
                                                        $Repository = $LinkedBkJob.Name
                                                        $Type = $LocalizedData.RepositoryType
                                                    } else {
                                                        $Repository = $LinkedBkJob.GetTargetRepository().Name
                                                        $Type = $LocalizedData.BackupJob
                                                    }
                                                    if ($LinkedBkJob.Group -eq 'BackupRepository') {
                                                        $TotalBackupSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size ($LinkedBkJob.GetContainer().CachedTotalSpace.InBytes - $LinkedBkJob.GetContainer().CachedFreeSpace.InBytes)
                                                    } else { $TotalBackupSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $LinkedBkJob.Info.IncludedSize }

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $LinkedBkJob.Name
                                                        $LocalizedData.Type = $Type
                                                        $LocalizedData.Size = $TotalBackupSize
                                                        $LocalizedData.Repository = $Repository
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Backups Objects - $($TBkjob.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.BackupsObjects) - $($TBkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 25, 15, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Backups Objects Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($TBkjob.FullBackupMediaPool) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.MediaPool {
                                            $OutObj = @()
                                            foreach ($BackupMediaPool in $TBkjob.FullBackupMediaPool) {
                                                try {

                                                    #Todo Fix this mess!
                                                    if ($BackupMediaPool.Type -eq 'Gfs') {
                                                        if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $MoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $MoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $AppendToCurrentTape = $LocalizedData.Append
                                                        } else { $AppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $MoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $MoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $WeeklyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $WeeklyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $WeeklyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $WeeklyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $WeeklyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $WeeklyMoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $MonthlyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $MonthlyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $MonthlyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $MonthlyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $MonthlyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $MonthlyMoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $QuarterlyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $QuarterlyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $QuarterlyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $QuarterlyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $QuarterlyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $QuarterlyMoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $YearlyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $YearlyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $YearlyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $YearlyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $YearlyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $YearlyMoveOfflineToVault = $LocalizedData.DoNotExport }
                                                    }

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $BackupMediaPool.Name
                                                        $LocalizedData.PoolType = $BackupMediaPool.Type
                                                        $LocalizedData.TapeCount = (Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).count
                                                        $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size ((Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).Free | Measure-Object -Sum).Sum
                                                        $LocalizedData.EncryptionEnabled = $BackupMediaPool.EncryptionOptions.Enabled
                                                        $LocalizedData.EncryptionKey = switch ($BackupMediaPool.EncryptionOptions.Enabled) {
                                                            'True' { (Get-VBREncryptionKey | Where-Object { $_.Id -eq $BackupMediaPool.EncryptionOptions.Key.Id }).Description }
                                                            'False' { $LocalizedData.Disabled }
                                                            default { $BackupMediaPool.EncryptionOptions.Key.Id }
                                                        }
                                                        $LocalizedData.ParallelProcessing = "$($BackupMediaPool.MultiStreamingOptions.NumberOfStreams) drives; Multiple Backup Chains: $($BackupMediaPool.MultiStreamingOptions.SplitJobFilesBetweenDrives)"
                                                        $LocalizedData.IsWORM = $BackupMediaPool.Worm
                                                    }
                                                    if ($BackupMediaPool.Type -eq 'Gfs') {
                                                        $inObj.add($LocalizedData.Daily, ("$($TBkjob.FullBackupMediaPool.DailyMediaSetOptions.OverwritePeriod) days; $MoveFromMediaPoolAutomatically; $AppendToCurrentTape; $MoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Weekly, ("$($TBkjob.FullBackupMediaPool.WeeklyMediaSetOptions.OverwritePeriod) days; $WeeklyMoveFromMediaPoolAutomatically; $WeeklyAppendToCurrentTape; $WeeklyMoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Monthly, ("$($TBkjob.FullBackupMediaPool.MonthlyMediaSetOptions.OverwritePeriod) days; $MonthlyMoveFromMediaPoolAutomatically; $MonthlyAppendToCurrentTape; $MonthlyMoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Quarterly, ("$($TBkjob.FullBackupMediaPool.QuarterlyMediaSetOptions.OverwritePeriod) days; $QuarterlyMoveFromMediaPoolAutomatically; $QuarterlyAppendToCurrentTape; $QuarterlyMoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Yearly, ("$($TBkjob.FullBackupMediaPool.YearlyMediaSetOptions.OverwritePeriod) days; $YearlyMoveFromMediaPoolAutomatically; $YearlyAppendToCurrentTape; $YearlyMoveOfflineToVault"))
                                                    }
                                                    if ($BackupMediaPool.Type -eq 'Custom') {
                                                        $Vault = switch (($TBkjob.FullBackupMediaPool.Vault).count) {
                                                            0 { $LocalizedData.Disabled }
                                                            default { $TBkjob.FullBackupMediaPool.Vault }
                                                        }
                                                        $Retention = switch ($TBkjob.FullBackupMediaPool.RetentionPolicy.Type) {
                                                            $Null { $LocalizedData.Disabled }
                                                            'Period' { "Protect data for $($TBkjob.FullBackupMediaPool.RetentionPolicy.Value) $($TBkjob.FullBackupMediaPool.RetentionPolicy.Period)" }
                                                            'Cyclic' { $LocalizedData.CyclicRetention }
                                                            'Never' { $LocalizedData.NeverOverwriteData }
                                                        }
                                                        $MediaSetPolicy = switch ($TBkjob.FullBackupMediaPool.MediaSetCreationPolicy.Type) {
                                                            $Null { $LocalizedData.Disabled }
                                                            'Always' { $LocalizedData.CreateNewMediaSet }
                                                            'Daily' { "Daily at $($TBkjob.FullBackupMediaPool.MediaSetCreationPolicy.DailyOptions.Period), $($TBkjob.FullBackupMediaPool.MediaSetCreationPolicy.DailyOptions.Type)" }
                                                            'Never' { $LocalizedData.DoNotCreateMediaSet }
                                                        }
                                                        $inObj.add($LocalizedData.Retention, ($Retention))
                                                        $inObj.add($LocalizedData.ExportToVault, ($TBkjob.FullBackupMediaPool.MoveOfflineToVault))
                                                        $inObj.add($LocalizedData.Vault, ($Vault))
                                                        $inObj.add($LocalizedData.MediaSetName, ($TBkjob.FullBackupMediaPool.MediaSetName))
                                                        $inObj.add($LocalizedData.AutoCreateMediaSet, ($MediaSetPolicy))
                                                        if ($TBkjob.FullBackupMediaPool.MediaSetCreationPolicy.Type -eq 'Daily') {
                                                            $inObj.add($LocalizedData.OnTheseDays, ($TBkjob.FullBackupMediaPool.MediaSetCreationPolicy.DailyOptions.DayOfWeek -join ', '))
                                                        }
                                                        if ($TBkjob.FullBackupPolicy.Type -eq 'WeeklyOnDays') {
                                                            $DayOfWeek = switch (($TBkjob.FullBackupPolicy.WeeklyOnDays).count) {
                                                                7 { $LocalizedData.Everyday }
                                                                default { $TBkjob.FullBackupPolicy.WeeklyOnDays -join ', ' }
                                                            }
                                                            $inObj.add($LocalizedData.FullBackupSchedule, ("Weekly on selected days: $DayOfWeek"))
                                                        } else {
                                                            $Months = switch (($TBkjob.FullBackupPolicy.MonthlyOptions.Months).count) {
                                                                12 { 'Every Month' }
                                                                default { $TBkjob.FullBackupPolicy.MonthlyOptions.Months -join ', ' }
                                                            }
                                                            $inObj.add($LocalizedData.FullBackupSchedule, ("Monthly on: $($TBkjob.FullBackupPolicy.MonthlyOptions.DayNumberInMonth), $($TBkjob.FullBackupPolicy.MonthlyOptions.DayOfWeek) of $Months"))
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Media Pool - $($TBkjob.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.MediaPool) - $($TBkjob.Name)"
                                                List = $True
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Media Pool Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($TBkjob.ProcessIncrementalBackup -and $TBkjob.FullBackupMediaPool.Type -eq 'Custom') {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.IncrementalBackup {
                                            $OutObj = @()
                                            foreach ($BackupMediaPool in $TBkjob.IncrementalBackupMediaPool) {
                                                try {

                                                    #Todo Fix this mess!
                                                    if ($BackupMediaPool.Type -eq 'Gfs') {
                                                        if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $MoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $MoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $AppendToCurrentTape = $LocalizedData.Append
                                                        } else { $AppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $MoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $MoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $WeeklyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $WeeklyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $WeeklyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $WeeklyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $WeeklyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $WeeklyMoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $MonthlyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $MonthlyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $MonthlyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $MonthlyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $MonthlyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $MonthlyMoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $QuarterlyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $QuarterlyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $QuarterlyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $QuarterlyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $QuarterlyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $QuarterlyMoveOfflineToVault = $LocalizedData.DoNotExport }

                                                        if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                            $YearlyMoveFromMediaPoolAutomatically = $LocalizedData.UseAnyAvailableMedia
                                                        } else { $YearlyMoveFromMediaPoolAutomatically = $LocalizedData.UseCountSelected -f ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.Medium).count }
                                                        if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                            $YearlyAppendToCurrentTape = $LocalizedData.Append
                                                        } else { $YearlyAppendToCurrentTape = $LocalizedData.DoNotAppend }
                                                        if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                            $YearlyMoveOfflineToVault = "$($LocalizedData.ExportToVaultPrefix) $($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                        } else { $YearlyMoveOfflineToVault = $LocalizedData.DoNotExport }
                                                    }

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.MediaPoolCol = $BackupMediaPool.Name
                                                        $LocalizedData.PoolType = $BackupMediaPool.Type
                                                        $LocalizedData.TapeCount = (Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).count
                                                        $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size ((Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).Free | Measure-Object -Sum).Sum
                                                        $LocalizedData.EncryptionEnabled = $BackupMediaPool.EncryptionOptions.Enabled
                                                        $LocalizedData.EncryptionKey = switch ($BackupMediaPool.EncryptionOptions.Enabled) {
                                                            'True' { (Get-VBREncryptionKey | Where-Object { $_.Id -eq $BackupMediaPool.EncryptionOptions.Key.Id }).Description }
                                                            'False' { $LocalizedData.Disabled }
                                                            default { $BackupMediaPool.EncryptionOptions.Key.Id }
                                                        }
                                                        $LocalizedData.ParallelProcessing = "$($BackupMediaPool.MultiStreamingOptions.NumberOfStreams) drives; Multiple Backup Chains: $($BackupMediaPool.MultiStreamingOptions.SplitJobFilesBetweenDrives)"
                                                        $LocalizedData.IsWORM = $BackupMediaPool.Worm
                                                    }
                                                    if ($BackupMediaPool.Type -eq 'Gfs') {
                                                        $inObj.add($LocalizedData.Daily, ("$($TBkjob.IncrementalBackupMediaPool.DailyMediaSetOptions.OverwritePeriod) days; $MoveFromMediaPoolAutomatically; $AppendToCurrentTape; $MoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Weekly, ("$($TBkjob.IncrementalBackupMediaPool.WeeklyMediaSetOptions.OverwritePeriod) days; $WeeklyMoveFromMediaPoolAutomatically; $WeeklyAppendToCurrentTape; $WeeklyMoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Monthly, ("$($TBkjob.IncrementalBackupMediaPool.MonthlyMediaSetOptions.OverwritePeriod) days; $MonthlyMoveFromMediaPoolAutomatically; $MonthlyAppendToCurrentTape; $MonthlyMoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Quarterly, ("$($TBkjob.IncrementalBackupMediaPool.QuarterlyMediaSetOptions.OverwritePeriod) days; $QuarterlyMoveFromMediaPoolAutomatically; $QuarterlyAppendToCurrentTape; $QuarterlyMoveOfflineToVault"))
                                                        $inObj.add($LocalizedData.Yearly, ("$($TBkjob.IncrementalBackupMediaPool.YearlyMediaSetOptions.OverwritePeriod) days; $YearlyMoveFromMediaPoolAutomatically; $YearlyAppendToCurrentTape; $YearlyMoveOfflineToVault"))
                                                    }
                                                    if ($BackupMediaPool.Type -eq 'Custom') {
                                                        $Vault = switch (($TBkjob.IncrementalBackupMediaPool.Vault).count) {
                                                            0 { $LocalizedData.Disabled }
                                                            default { $TBkjob.IncrementalBackupMediaPool.Vault }
                                                        }
                                                        $Retention = switch ($TBkjob.IncrementalBackupMediaPool.RetentionPolicy.Type) {
                                                            $Null { $LocalizedData.Disabled }
                                                            'Period' { "Protect data for $($TBkjob.IncrementalBackupMediaPool.RetentionPolicy.Value) $($TBkjob.IncrementalBackupMediaPool.RetentionPolicy.Period)" }
                                                            'Cyclic' { $LocalizedData.CyclicRetention }
                                                            'Never' { $LocalizedData.NeverOverwriteData }
                                                        }
                                                        $MediaSetPolicy = switch ($TBkjob.IncrementalBackupMediaPool.MediaSetCreationPolicy.Type) {
                                                            $Null { $LocalizedData.Disabled }
                                                            'Always' { $LocalizedData.CreateNewMediaSet }
                                                            'Daily' { "Daily at $($TBkjob.IncrementalBackupMediaPool.MediaSetCreationPolicy.DailyOptions.Period), $($TBkjob.IncrementalBackupMediaPool.MediaSetCreationPolicy.DailyOptions.Type)" }
                                                            'Never' { $LocalizedData.DoNotCreateMediaSet }
                                                        }
                                                        $inObj.add($LocalizedData.Retention, ($Retention))
                                                        $inObj.add($LocalizedData.ExportToVault, ($TBkjob.IncrementalBackupMediaPool.MoveOfflineToVault))
                                                        $inObj.add($LocalizedData.Vault, ($Vault))
                                                        $inObj.add($LocalizedData.MediaSetName, ($TBkjob.IncrementalBackupMediaPool.MediaSetName))
                                                        $inObj.add($LocalizedData.AutoCreateMediaSet, ($MediaSetPolicy))
                                                        if ($TBkjob.IncrementalBackupMediaPool.MediaSetCreationPolicy.Type -eq 'Daily') {
                                                            $inObj.add($LocalizedData.OnTheseDays, ($TBkjob.IncrementalBackupMediaPool.MediaSetCreationPolicy.DailyOptions.DayOfWeek -join ', '))
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Incremental Backup - $($TBkjob.Name) Section: $($_.Exception.Message)"
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
                                        Write-PScriboMessage -IsWarning "Incremental Backup Section: $($_.Exception.Message)"
                                    }
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Options {
                                        $OutObj = @()
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.EjectTapeMedia = $TBkjob.EjectCurrentMedium
                                                $LocalizedData.ExportMediaSet = $TBkjob.ExportCurrentMediaSet
                                                $LocalizedData.LimitDrives = "Enabled: $($TBkjob.ParallelDriveOptions.IsEnabled); Tape Drives Limit: $($TBkjob.ParallelDriveOptions.DrivesLimit)"

                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Options - $($TBkjob.Name) Section: $($_.Exception.Message)"
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.Options) - $($TBkjob.Name)"
                                            List = $True
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        if ($InfoLevel.Jobs.Tape -ge 2 -and $TBkjob.NotificationOptions.EnableAdditionalNotification) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsNotifications {
                                                    $OutObj = @()
                                                    try {

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.SendEmailNotification = $TBkjob.NotificationOptions.EnableAdditionalNotification
                                                            $LocalizedData.EmailNotificationAdditionalRecipients = $TBkjob.NotificationOptions.AdditionalAddress -join ','
                                                        }
                                                        if (!$TBkjob.NotificationOptions.UseNotificationOptions) {
                                                            $inObj.add($LocalizedData.UseGlobalNotificationSettings, ($TBkjob.NotificationOptions.UseNotificationOptions))
                                                        } elseif ($TBkjob.NotificationOptions.UseNotificationOptions) {
                                                            $inObj.add($LocalizedData.UseCustomNotificationSettings, ($LocalizedData.Yes))
                                                            $inObj.add($LocalizedData.Subject, ($TBkjob.NotificationOptions.NotificationSubject))
                                                            $inObj.add($LocalizedData.NotifyOnSuccess, ($TBkjob.NotificationOptions.NotifyOnSuccess))
                                                            $inObj.add($LocalizedData.NotifyOnWarning, ($TBkjob.NotificationOptions.NotifyOnWarning))
                                                            $inObj.add($LocalizedData.NotifyOnError, ($TBkjob.NotificationOptions.NotifyOnError))
                                                            $inObj.add($LocalizedData.NotifyOnLastRetryOnly, ($TBkjob.NotificationOptions.NotifyOnLastRetryOnly))
                                                            $inObj.add($LocalizedData.NotifyWhenWaitingForTape, ($TBkjob.NotificationOptions.NotifyWhenWaitingForTape))
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Advanced Settings (Notifications) - $($TBkjob.Name) Section: $($_.Exception.Message)"
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsNotifications) - $($TBkjob.Name)"
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
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsAdvanced {
                                                    $OutObj = @()
                                                    try {

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.ProcessMostRecentRestorePoint = $TBkjob.AlwaysCopyFromLatestFull
                                                            $LocalizedData.UseHardwareCompression = $TBkjob.UseHardwareCompression
                                                        }
                                                        if (!$TBkjob.JobScriptOptions.PreScriptEnabled) {
                                                            $inObj.add($LocalizedData.PreJobScriptEnabled, ($TBkjob.JobScriptOptions.PreScriptEnabled))
                                                        } elseif ($TBkjob.JobScriptOptions.PreScriptEnabled) {
                                                            $inObj.add($LocalizedData.RunScriptBeforeJob, ($TBkjob.JobScriptOptions.PreCommand))
                                                        }
                                                        if (!$TBkjob.JobScriptOptions.PostScriptEnabled) {
                                                            $inObj.add($LocalizedData.PostJobScriptEnabled, ($TBkjob.JobScriptOptions.PostScriptEnabled))
                                                        } elseif ($TBkjob.JobScriptOptions.PostScriptEnabled) {
                                                            $inObj.add($LocalizedData.RunScriptAfterJob, ($TBkjob.JobScriptOptions.PostCommand))
                                                        }
                                                        if ($TBkjob.JobScriptOptions.PreScriptEnabled -or $TBkjob.JobScriptOptions.PostScriptEnabled) {
                                                            if ($TBkjob.JobScriptOptions.Periodicity -eq 'Days') {
                                                                $FrequencyValue = $TBkjob.JobScriptOptions.Day -join ', '
                                                                $FrequencyText = $LocalizedData.RunScriptOnSelectedDays
                                                            } elseif ($TBkjob.JobScriptOptions.Periodicity -eq 'Cycles') {
                                                                $FrequencyValue = "Every $($TBkjob.JobScriptOptions.Frequency) backup session"
                                                                $FrequencyText = $LocalizedData.RunScriptEveryBackupSession
                                                            }
                                                            $inObj.add($FrequencyText, ($FrequencyValue))
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Advanced Settings (Advanced) - $($TBkjob.Name) Section: $($_.Exception.Message)"
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsAdvanced) - $($TBkjob.Name)"
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
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Schedule {
                                        $OutObj = @()
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.PreventInterruption = $TBkjob.WaitForBackupJobs
                                            }

                                            if ($TBkjob.GFSScheduleOptions) {
                                                $inObj.add($LocalizedData.PerformGFSScanDailyAt, ($TBkjob.GFSScheduleOptions.DailyOptions))
                                                $inObj.add($LocalizedData.DailyBackup, ($TBkjob.ScheduleOptions.DailyOptions.Type))
                                                $inObj.add($LocalizedData.WeeklyBackup, ($TBkjob.GFSScheduleOptions.WeeklyOptions.ToString()))
                                                $inObj.add($LocalizedData.MonthlyBackup, ($TBkjob.GFSScheduleOptions.MonthlyOptions.ToString()))
                                                $inObj.add($LocalizedData.QuarterlyBackup, ($TBkjob.GFSScheduleOptions.QuarterlyOptions.ToString()))
                                                $inObj.add($LocalizedData.YearlyBackup, ($TBkjob.GFSScheduleOptions.YearlyOptions.ToString()))
                                            }
                                            if ($TBkjob.ScheduleOptions.Enabled -and !$TBkjob.GFSScheduleOptions) {
                                                if ($TBkjob.ScheduleOptions.Type -eq 'Daily') {
                                                    $Schedule = "Daily at this time: $($TBkjob.ScheduleOptions.DailyOptions.Period),`r`nDays: $($TBkjob.ScheduleOptions.DailyOptions.Type),`r`nDay Of Week: $($TBkjob.ScheduleOptions.DailyOptions.DayOfWeek)"
                                                } elseif ($TBkjob.ScheduleOptions.Type -eq 'Monthly') {
                                                    if ($TBkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth -eq 'OnDay') {
                                                        $Schedule = "Monthly at this time: $($TBkjob.ScheduleOptions.MonthlyOptions.Period),`r`nThis Day: $($TBkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nMonths: $($TBkjob.ScheduleOptions.MonthlyOptions.Months)"
                                                    } else {
                                                        $Schedule = "Monthly at this time: $($TBkjob.ScheduleOptions.MonthlyOptions.Period),`r`nDays Number of Month: $($TBkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($TBkjob.ScheduleOptions.MonthlyOptions.DayOfWeek),`r`nMonth: $($TBkjob.ScheduleOptions.MonthlyOptions.Months)"
                                                    }
                                                } elseif ($TBkjob.ScheduleOptions.Type -eq 'AfterJob') {
                                                    $Schedule = switch ($TBkjob.ScheduleOptions.JobId) {
                                                        $Null { $LocalizedData.Unknown }
                                                        default { " After Job: $((Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.Id -eq $TBkjob.ScheduleOptions.JobId}).Name)" }
                                                    }
                                                } elseif ($TBkjob.ScheduleOptions.Type -eq 'AfterNewBackup') {
                                                    $Schedule = $LocalizedData.AfterNewBackupFileAppears
                                                }
                                                $inObj.add($LocalizedData.RunAutomatically, ($Schedule))
                                            }

                                            if ($TBkjob.WaitForBackupJobs -and !$TBkjob.GFSScheduleOptions) {
                                                $inObj.add($LocalizedData.WaitForBackupJob, ("$($TBkjob.WaitPeriod.ToString()) hours"))
                                            }

                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Schedule - $($TBkjob.Name) Section: $($_.Exception.Message)"
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.Schedule) - $($TBkjob.Name)"
                                            List = $True
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Schedule Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup To Tape Job Configuration Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage 'Backup To Tape Job Configuration'
        }
    }
    end {}

}
