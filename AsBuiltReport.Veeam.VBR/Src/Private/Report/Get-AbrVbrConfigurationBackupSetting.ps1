
function Get-AbrVbrConfigurationBackupSetting {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Configuration Backup settings on Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Configuration Backup settings information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrConfigurationBackupSetting
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Configuration Backup'
    }

    process {
        try {
            if ($BackupSettings = Get-VBRConfigurationBackupJob | Sort-Object -Property Name) {
                Section -Style Heading4 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        if ($BackupSettings.ScheduleOptions.Type -like 'Daily') {
                            $ScheduleOptions = $LocalizedData.DailyScheduleTemplate -f $BackupSettings.ScheduleOptions.DailyOptions.Type, $BackupSettings.ScheduleOptions.DailyOptions.Period, $BackupSettings.ScheduleOptions.DailyOptions.DayOfWeek
                        } elseif ($BackupSettings.ScheduleOptions.Type -like 'Monthly') {
                            $ScheduleOptions = $LocalizedData.MonthlyScheduleTemplate -f $BackupSettings.ScheduleOptions.MonthlyOptions.Period, $BackupSettings.ScheduleOptions.MonthlyOptions.DayNumberInMonth, $BackupSettings.ScheduleOptions.MonthlyOptions.DayOfWeek, $BackupSettings.ScheduleOptions.MonthlyOptions.DayOfMonth
                        }
                        $inObj = [ordered] @{
                            $LocalizedData.Name = $BackupSettings.Name
                            $LocalizedData.RunJobAutomatically = $BackupSettings.ScheduleOptions.Enabled
                            $LocalizedData.ScheduleType = $BackupSettings.ScheduleOptions.Type
                            $LocalizedData.ScheduleOptions = $ScheduleOptions
                            $LocalizedData.RestorePointsToKeep = $BackupSettings.RestorePointsToKeep
                            $LocalizedData.EncryptionEnabled = $BackupSettings.EncryptionOptions
                            $LocalizedData.EncryptionKey = $BackupSettings.EncryptionOptions.Key.Description
                            $LocalizedData.AdditionalAddress = $BackupSettings.NotificationOptions.AdditionalAddress
                            $LocalizedData.EmailSubject = $BackupSettings.NotificationOptions.NotificationSubject
                            $LocalizedData.NotifyOn = switch ($BackupSettings.NotificationOptions.EnableAdditionalNotification) {
                                '' { '--'; break }
                                $Null { '--'; break }
                                default { $LocalizedData.NotifyOnTemplate -f $BackupSettings.NotificationOptions.NotifyOnSuccess, $BackupSettings.NotificationOptions.NotifyOnWarning, $BackupSettings.NotificationOptions.NotifyOnError, $BackupSettings.NotificationOptions.NotifyOnLastRetryOnly }
                            }
                            $LocalizedData.NextRun = $BackupSettings.NextRun
                            $LocalizedData.Target = $BackupSettings.Target
                            $LocalizedData.Enabled = $BackupSettings.Enabled
                            $LocalizedData.LastResult = $BackupSettings.LastResult
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning "Configuration Backup Settings Section: $($_.Exception.Message)"
                    }

                    if ($HealthCheck.Infrastructure.Settings) {
                        $List = @()
                        $Num = 0
                        $OutObj | Where-Object { $_.$($LocalizedData.RunJobAutomatically) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.RunJobAutomatically
                        foreach ( $OBJ in ($OutObj | Where-Object { $_.$($LocalizedData.RunJobAutomatically) -like 'No' })) {
                            $Num++
                            $OBJ.$($LocalizedData.RunJobAutomatically) = $OBJ.$($LocalizedData.RunJobAutomatically) + " ($Num)"
                            $List += $LocalizedData.BP1
                        }

                        $OutObj | Where-Object { $_.$($LocalizedData.EncryptionEnabled) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.EncryptionEnabled
                        foreach ( $OBJ in ($OutObj | Where-Object { $_.$($LocalizedData.EncryptionEnabled) -like 'No' })) {
                            $Num++
                            $OBJ.$($LocalizedData.EncryptionEnabled) = $OBJ.$($LocalizedData.EncryptionEnabled) + " ($Num)"
                            $List += $LocalizedData.BP2
                        }

                        $OutObj | Where-Object { $_.$($LocalizedData.Enabled) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.Enabled
                        foreach ( $OBJ in ($OutObj | Where-Object { $_.$($LocalizedData.Enabled) -eq 'No' })) {
                            $Num++
                            $OBJ.$($LocalizedData.Enabled) = $OBJ.$($LocalizedData.Enabled) + " ($Num)"
                            $List += $LocalizedData.BP3
                        }

                        $OutObj | Where-Object { $_.$($LocalizedData.LastResult) -like 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LastResult
                        $OutObj | Where-Object { $_.$($LocalizedData.LastResult) -like 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LastResult
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    if ($HealthCheck.Infrastructure.BestPractice -and $List) {
                        Paragraph $LocalizedData.HealthCheck -Bold -Underline
                        BlankLine
                        Paragraph $LocalizedData.BestPractice -Bold
                        List -Item $List -Numbered
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Configuration Backup Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Configuration Backup'
    }

}