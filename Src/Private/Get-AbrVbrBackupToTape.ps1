
function Get-AbrVbrBackupToTape {
    <#
    .SYNOPSIS
        Used by As Built Report to returns tape backup jobs configuration created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Discovering Veeam VBR Tape Backup jobs configuration information from $System."
    }

    process {
        try {
            if ((Get-VBRTapeJob).count -gt 0) {
                Section -Style Heading3 'Backup To Tape Job Configuration' {
                    Paragraph "The following section details backup to tape jobs configuration."
                    BlankLine
                    $OutObj = @()
                    $TBkjobs = Get-VBRTapeJob | Where-Object {$_.Type -eq 'BackupToTape'}
                    if ($TBkjobs) {
                        foreach ($TBkjob in $TBkjobs) {
                            Section -Style Heading4 "$($TBkjob.Name) Configuration" {
                                Section -Style Heading5 'Backups Information' {
                                    $OutObj = @()
                                    try {
                                        Write-PscriboMessage "Discovered $($TBkjob.Name) common information."
                                        if ($TBkjob.Object.Group -eq 'BackupRepository') {
                                            $RepoSize = $TBkjob.Object | Where-Object {$_.Group -eq 'BackupRepository'}
                                            $TotalBackupSize = (($TBkjob.Object.info.IncludedSize | Measure-Object -Sum ).Sum) + ($RepoSize.GetContainer().CachedTotalSpace.InBytes - $RepoSize.GetContainer().CachedFreeSpace.InBytes)
                                        } else {$TotalBackupSize = ($TBkjob.Object.info.IncludedSize | Measure-Object -Sum).Sum}

                                        $inObj = [ordered] @{
                                            'Name' = $TBkjob.Name
                                            'Type' = $TBkjob.Type
                                            'Total Backup Size' = ConvertTo-FileSizeString $TotalBackupSize
                                            'Next Run' = Switch ($TBkjob.Enabled) {
                                                'False' {'Disabled'}
                                                default {$TBkjob.NextRun}
                                            }
                                            'Description' = $TBkjob.Description
                                        }
                                        $OutObj = [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Common Information - $($TBkjob.Name)"
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
                                if ($TBkjob.Object) {
                                    try {
                                        Section -Style Heading5 'Object to Process' {
                                            $OutObj = @()
                                            foreach ($LinkedBkJob in $TBkjob.Object) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($LinkedBkJob.Name) object to process."
                                                    if ($LinkedBkJob.Type) {
                                                        $Repository = $LinkedBkJob.Name
                                                        $Type = 'Repository'
                                                    } else {
                                                        $Repository = $LinkedBkJob.GetTargetRepository().Name
                                                        $Type = 'Backup Job'
                                                    }
                                                    if ($LinkedBkJob.Group -eq 'BackupRepository') {
                                                        $TotalBackupSize = ConvertTo-FileSizeString ($LinkedBkJob.GetContainer().CachedTotalSpace.InBytes - $LinkedBkJob.GetContainer().CachedFreeSpace.InBytes)
                                                    } else {$TotalBackupSize = ConvertTo-FileSizeString $LinkedBkJob.Info.IncludedSize}

                                                    $inObj = [ordered] @{
                                                        'Name' = $LinkedBkJob.Name
                                                        'Type' = $Type
                                                        'Size' = $TotalBackupSize
                                                        'Repository' = $Repository
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Objects - $($TBkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 25, 15, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($TBkjob.FullBackupMediaPool) {
                                    try {
                                        Section -Style Heading5 'Tape Media Pool' {
                                            $OutObj = @()
                                            foreach ($BackupMediaPool in $TBkjob.FullBackupMediaPool) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($TBkjob.Name) media pool."
                                                    #Todo Fix this mess!
                                                    if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                        $MoveFromMediaPoolAutomatically = 'Use any available media'
                                                    } else {$MoveFromMediaPoolAutomatically = "Use $(($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.Medium).count) selected"}
                                                    if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                        $AppendToCurrentTape = 'append'
                                                    } else {$AppendToCurrentTape = "do not append"}
                                                    if ($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                        $MoveOfflineToVault = "export to vault $($BackupMediaPool.DailyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                    } else {$MoveOfflineToVault = "do not export"}

                                                    if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                        $WeeklyMoveFromMediaPoolAutomatically = 'Use any available media'
                                                    } else {$WeeklyMoveFromMediaPoolAutomatically = "Use $(($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.Medium).count) selected"}
                                                    if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                        $WeeklyAppendToCurrentTape = 'append'
                                                    } else {$WeeklyAppendToCurrentTape = "do not append"}
                                                    if ($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                        $WeeklyMoveOfflineToVault = "export to vault $($BackupMediaPool.WeeklyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                    } else {$WeeklyMoveOfflineToVault = "do not export"}

                                                    if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                        $MonthlyMoveFromMediaPoolAutomatically = 'Use any available media'
                                                    } else {$MonthlyMoveFromMediaPoolAutomatically = "Use $(($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.Medium).count) selected"}
                                                    if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                        $MonthlyAppendToCurrentTape = 'append'
                                                    } else {$MonthlyAppendToCurrentTape = "do not append"}
                                                    if ($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                        $MonthlyMoveOfflineToVault = "export to vault $($BackupMediaPool.MonthlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                    } else {$MonthlyMoveOfflineToVault = "do not export"}

                                                    if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                        $QuarterlyMoveFromMediaPoolAutomatically = 'Use any available media'
                                                    } else {$QuarterlyMoveFromMediaPoolAutomatically = "Use $(($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.Medium).count) selected"}
                                                    if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                        $QuarterlyAppendToCurrentTape = 'append'
                                                    } else {$QuarterlyAppendToCurrentTape = "do not append"}
                                                    if ($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                        $QuarterlyMoveOfflineToVault = "export to vault $($BackupMediaPool.QuarterlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                    } else {$QuarterlyMoveOfflineToVault = "do not export"}

                                                    if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.MoveFromMediaPoolAutomatically) {
                                                        $YearlyMoveFromMediaPoolAutomatically = 'Use any available media'
                                                    } else {$YearlyMoveFromMediaPoolAutomatically = "Use $(($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.Medium).count) selected"}
                                                    if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.AppendToCurrentTape) {
                                                        $YearlyAppendToCurrentTape = 'append'
                                                    } else {$YearlyAppendToCurrentTape = "do not append"}
                                                    if ($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.MoveOfflineToVault) {
                                                        $YearlyMoveOfflineToVault = "export to vault $($BackupMediaPool.YearlyMediaSetOptions.MediaSetPolicy.Vault.Name)"
                                                    } else {$YearlyMoveOfflineToVault = "do not export"}

                                                    $inObj = [ordered] @{
                                                        'Name' = $BackupMediaPool.Name
                                                        'Pool Type' = $BackupMediaPool.Type
                                                        'Tape Count' = (Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).count
                                                        'Free Space' = ConvertTo-FileSizeString ((Get-VBRTapeMedium -MediaPool $BackupMediaPool.Name).Free | Measure-Object -Sum).Sum
                                                        'Daily' = "$($TBkjob.FullBackupMediaPool.DailyMediaSetOptions.OverwritePeriod) days; $MoveFromMediaPoolAutomatically; $AppendToCurrentTape; $MoveOfflineToVault"
                                                        'Weekly' = "$($TBkjob.FullBackupMediaPool.WeeklyMediaSetOptions.OverwritePeriod) days; $WeeklyMoveFromMediaPoolAutomatically; $WeeklyAppendToCurrentTape; $WeeklyMoveOfflineToVault"
                                                        'Monthly' = "$($TBkjob.FullBackupMediaPool.MonthlyMediaSetOptions.OverwritePeriod) days; $MonthlyMoveFromMediaPoolAutomatically; $MonthlyAppendToCurrentTape; $MonthlyMoveOfflineToVault"
                                                        'Quarterly' = "$($TBkjob.FullBackupMediaPool.QuarterlyMediaSetOptions.OverwritePeriod) days; $QuarterlyMoveFromMediaPoolAutomatically; $QuarterlyAppendToCurrentTape; $QuarterlyMoveOfflineToVault"
                                                        'Yearly' = "$($TBkjob.FullBackupMediaPool.YearlyMediaSetOptions.OverwritePeriod) days; $YearlyMoveFromMediaPoolAutomatically; $YearlyAppendToCurrentTape; $YearlyMoveOfflineToVault"
                                                        'Encryption Enabled' = ConvertTo-TextYN $BackupMediaPool.EncryptionOptions.Enabled
                                                        'Encryption Key' = (Get-VBREncryptionKey | Where-Object {$_.Id -eq $BackupMediaPool.EncryptionOptions.Key.Id}).Description
                                                        'Parallel Processing' = "$(ConvertTo-TextYN $BackupMediaPool.MultiStreamingOptions.NumberOfStreams) drives; Multiple Backup Chains: $(ConvertTo-TextYN $BackupMediaPool.MultiStreamingOptions.SplitJobFilesBetweenDrives)"
                                                        'Is WORM' = ConvertTo-TextYN $BackupMediaPool.Worm
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Media Pool - $($TBkjob.Name)"
                                                List = $True
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                try {
                                    Section -Style Heading5 'Options' {
                                        $OutObj = @()
                                        try {
                                            Write-PscriboMessage "Discovered $($TBkjob.Name) options."
                                            $inObj = [ordered] @{
                                                'Eject Tape Media Upon Job Completion' = ConvertTo-TextYN $TBkjob.EjectCurrentMedium
                                                'Export the following MediaSet Upon Job Completion' = ConvertTo-TextYN $TBkjob.ExportCurrentMediaSet
                                                'Limit the number of drives this job can use' = "Enabled: $(ConvertTo-TextYN $TBkjob.ParallelDriveOptions.IsEnabled); Tape Drives Limit: $($TBkjob.ParallelDriveOptions.DrivesLimit)"

                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }

                                        $TableParams = @{
                                            Name = "Media Pool - $($TBkjob.Name)"
                                            List = $True
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        if ($InfoLevel.Jobs.Tape -ge 2 -and $TBkjob.NotificationOptions.EnableAdditionalNotification) {
                                            try {
                                                Section -Style Heading5 'Advanced Settings (Notifications)' {
                                                    $OutObj = @()
                                                    try {
                                                        Write-PscriboMessage "Discovered $($TBkjob.Name) notification options."
                                                        $inObj = [ordered] @{
                                                            'Send Email Notification' = ConvertTo-TextYN $TBkjob.NotificationOptions.EnableAdditionalNotification
                                                            'Email Notification Additional Recipients' = $TBkjob.NotificationOptions.AdditionalAddress -join ","
                                                        }
                                                        if (!$TBkjob.NotificationOptions.UseNotificationOptions) {
                                                            $inObj.add('Use Global Notification Settings', (ConvertTo-TextYN $TBkjob.NotificationOptions.UseNotificationOptions))
                                                        }
                                                        elseif ($TBkjob.NotificationOptions.UseNotificationOptions) {
                                                            $inObj.add('Use Custom Notification Settings', ('Yes'))
                                                            $inObj.add('Subject', ($TBkjob.NotificationOptions.NotificationSubject))
                                                            $inObj.add('Notify On Success', (ConvertTo-TextYN $TBkjob.NotificationOptions.NotifyOnSuccess))
                                                            $inObj.add('Notify On Warning', (ConvertTo-TextYN $TBkjob.NotificationOptions.NotifyOnWarning))
                                                            $inObj.add('Notify On Error', (ConvertTo-TextYN $TBkjob.NotificationOptions.NotifyOnError))
                                                            $inObj.add('Notify On Last Retry Only', (ConvertTo-TextYN $TBkjob.NotificationOptions.NotifyOnLastRetryOnly))
                                                            $inObj.add('Notify When Waiting For Tape', (ConvertTo-TextYN $TBkjob.NotificationOptions.NotifyWhenWaitingForTape))
                                                        }
                                                        $OutObj += [pscustomobject]$inobj
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                                    }

                                                    $TableParams = @{
                                                        Name = "Media Pool - $($TBkjob.Name)"
                                                        List = $True
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                }
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
