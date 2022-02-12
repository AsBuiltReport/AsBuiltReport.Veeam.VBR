
function Get-AbrVbrConfigurationBackupSetting {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Configuration Backup settings on Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
        Write-PscriboMessage "Discovering Veeam VBR Configuration Backup settings information from $System."
    }

    process {
        try {
            if ((Get-VBRConfigurationBackupJob).count -gt 0) {
                Section -Style Heading4 'Configuration Backup Settings' {
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $BackupSettings = Get-VBRConfigurationBackupJob
                            if ($BackupSettings.ScheduleOptions.Type -like "Daily") {
                                $ScheduleOptions = "Type: $($BackupSettings.ScheduleOptions.Type)`r`nPeriod: $($BackupSettings.ScheduleOptions.DailyOptions.Period)`r`nDay Of Week: $($BackupSettings.ScheduleOptions.DailyOptions.DayOfWeek)"
                            }
                            elseif ($BackupSettings.ScheduleOptions.Type -like "Monthly") {
                                $ScheduleOptions = "Period: $($BackupSettings.ScheduleOptions.MonthlyOptions.Period)`r`nDay Number In Month: $($BackupSettings.ScheduleOptions.MonthlyOptions.DayNumberInMonth)`r`nDay of Week $($BackupSettings.ScheduleOptions.MonthlyOptions.DayOfWeek)`r`nDay of Month $($BackupSettings.ScheduleOptions.MonthlyOptions.DayOfMonth)"
                            }
                            $inObj = [ordered] @{
                                'Name' = $BackupSettings.Name
                                'Run Job Automatically' = ConvertTo-TextYN $BackupSettings.ScheduleOptions.Enabled
                                'Schedule Type' = $BackupSettings.ScheduleOptions.Type
                                'Schedule Options' = $ScheduleOptions
                                'Restore Points To Keep' = $BackupSettings.RestorePointsToKeep
                                'Encryption Enabled' = ConvertTo-TextYN $BackupSettings.EncryptionOptions
                                'Encryption Key' = $BackupSettings.EncryptionOptions.Key.Description
                                'Additional Address' = $BackupSettings.NotificationOptions.AdditionalAddress
                                'Email Subject' = $BackupSettings.NotificationOptions.NotificationSubject
                                'Notify On' = Switch ($BackupSettings.NotificationOptions.EnableAdditionalNotification) {
                                    "" {"-"; break}
                                    $Null {"-"; break}
                                    default {"Notify On Success: $(ConvertTo-TextYN $BackupSettings.NotificationOptions.NotifyOnSuccess)`r`nNotify On Warning: $(ConvertTo-TextYN $BackupSettings.NotificationOptions.NotifyOnWarning)`r`nNotify On Error: $(ConvertTo-TextYN $BackupSettings.NotificationOptions.NotifyOnError)`r`nNotify On Last Retry Only: $(ConvertTo-TextYN $BackupSettings.NotificationOptions.NotifyOnLastRetryOnly)"}
                                }
                                'NextRun' = $BackupSettings.NextRun
                                'Target' = $BackupSettings.Target
                                'Enabled' = ConvertTo-TextYN $BackupSettings.Enabled
                                'LastResult' = $BackupSettings.LastResult
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.'Enabled' -like 'No'} | Set-Style -Style Warning -Property 'Enabled'
                            $OutObj | Where-Object { $_.'Run Job Automatically' -like 'No'} | Set-Style -Style Warning -Property 'Run Job Automatically'
                            $OutObj | Where-Object { $_.'Encryption Enabled' -like 'No'} | Set-Style -Style Critical -Property 'Encryption Enabled'
                            $OutObj | Where-Object { $_.'LastResult' -like 'Warning'} | Set-Style -Style Warning -Property 'LastResult'
                            $OutObj | Where-Object { $_.'LastResult' -like 'Failed'} | Set-Style -Style Critical -Property 'LastResult'
                        }

                        $TableParams = @{
                            Name = "Configuration Backup Settings - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
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