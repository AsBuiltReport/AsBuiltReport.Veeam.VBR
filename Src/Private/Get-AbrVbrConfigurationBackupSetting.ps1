
function Get-AbrVbrConfigurationBackupSetting {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Configuration Backup settings on Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.16
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
    }

    process {
        try {
            if ($BackupSettings = Get-VBRConfigurationBackupJob | Sort-Object -Property Name) {
                Section -Style Heading4 'Configuration Backup' {
                    $OutObj = @()
                    try {
                        if ($BackupSettings.ScheduleOptions.Type -like "Daily") {
                            $ScheduleOptions = "Type: $($BackupSettings.ScheduleOptions.DailyOptions.Type)`r`nPeriod: $($BackupSettings.ScheduleOptions.DailyOptions.Period)`r`nDay Of Week: $($BackupSettings.ScheduleOptions.DailyOptions.DayOfWeek)"
                        } elseif ($BackupSettings.ScheduleOptions.Type -like "Monthly") {
                            $ScheduleOptions = "Period: $($BackupSettings.ScheduleOptions.MonthlyOptions.Period)`r`nDay Number In Month: $($BackupSettings.ScheduleOptions.MonthlyOptions.DayNumberInMonth)`r`nDay of Week: $($BackupSettings.ScheduleOptions.MonthlyOptions.DayOfWeek)`r`nDay of Month: $($BackupSettings.ScheduleOptions.MonthlyOptions.DayOfMonth)"
                        }
                        $inObj = [ordered] @{
                            'Name' = $BackupSettings.Name
                            'Run Job Automatically' = $BackupSettings.ScheduleOptions.Enabled
                            'Schedule Type' = $BackupSettings.ScheduleOptions.Type
                            'Schedule Options' = $ScheduleOptions
                            'Restore Points To Keep' = $BackupSettings.RestorePointsToKeep
                            'Encryption Enabled' = $BackupSettings.EncryptionOptions
                            'Encryption Key' = $BackupSettings.EncryptionOptions.Key.Description
                            'Additional Address' = $BackupSettings.NotificationOptions.AdditionalAddress
                            'Email Subject' = $BackupSettings.NotificationOptions.NotificationSubject
                            'Notify On' = Switch ($BackupSettings.NotificationOptions.EnableAdditionalNotification) {
                                "" { "--"; break }
                                $Null { "--"; break }
                                default { "Notify On Success: $($BackupSettings.NotificationOptions.NotifyOnSuccess)`r`nNotify On Warning: $($BackupSettings.NotificationOptions.NotifyOnWarning)`r`nNotify On Error: $($BackupSettings.NotificationOptions.NotifyOnError)`r`nNotify On Last Retry Only: $($BackupSettings.NotificationOptions.NotifyOnLastRetryOnly)" }
                            }
                            'NextRun' = $BackupSettings.NextRun
                            'Target' = $BackupSettings.Target
                            'Enabled' = $BackupSettings.Enabled
                            'LastResult' = $BackupSettings.LastResult
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning "Configuration Backup Settings Section: $($_.Exception.Message)"
                    }

                    if ($HealthCheck.Infrastructure.Settings) {
                        $List = @()
                        $Num = 0
                        $OutObj | Where-Object { $_.'Run Job Automatically' -like 'No' } | Set-Style -Style Warning -Property 'Run Job Automatically'
                        foreach ( $OBJ in ($OutObj | Where-Object { $_.'Run Job Automatically' -like 'No' })) {
                            $Num++
                            $OBJ.'Run Job Automatically' = $OBJ.'Run Job Automatically' + " ($Num)"
                            $List += "It's a recommended best practice to activate the 'Run job automatically' option of the Backup Configuration job."
                        }

                        $OutObj | Where-Object { $_.'Encryption Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Encryption Enabled'
                        foreach ( $OBJ in ($OutObj | Where-Object { $_.'Encryption Enabled' -like 'No' })) {
                            $Num++
                            $OBJ.'Encryption Enabled' = $OBJ.'Encryption Enabled' + " ($Num)"
                            $List += "Whenever possible, enable configuration backup encryption."
                        }

                        $OutObj | Where-Object { $_.'Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Enabled'
                        foreach ( $OBJ in ($OutObj | Where-Object { $_.'Enabled' -eq 'No' })) {
                            $Num++
                            $OBJ.'Enabled' = $OBJ.'Enabled' + " ($Num)"
                            $List += "It's a recommended best practice to enable the Backup Configuration job"
                        }

                        $OutObj | Where-Object { $_.'LastResult' -like 'Warning' } | Set-Style -Style Warning -Property 'LastResult'
                        $OutObj | Where-Object { $_.'LastResult' -like 'Failed' } | Set-Style -Style Critical -Property 'LastResult'
                    }

                    $TableParams = @{
                        Name = "Configuration Backup Settings - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    if ($HealthCheck.Infrastructure.BestPractice -and $List) {
                        Paragraph "Health Check:" -Bold -Underline
                        BlankLine
                        Paragraph "Best Practice:" -Bold
                        List -Item $List -Numbered
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Configuration Backup Section: $($_.Exception.Message)"
        }
    }
    end {}

}