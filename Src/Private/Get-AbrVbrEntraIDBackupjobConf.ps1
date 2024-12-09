
function Get-AbrVbrEntraIDBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns entraid jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.13
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
        Write-PScriboMessage "Discovering Veeam VBR EntraID Tenant Backup jobs information from $System."
    }

    process {
        try {
            if ($Bkjobs = Get-VBREntraIDTenantBackupJob | Sort-Object -Property 'Name') {
                Section -Style Heading3 'EntraID Tenant Backup Jobs Configuration' {
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
                                                'Next Run' = $Bkjob.ScheduleOptions.NextRun
                                                'Description' = $Bkjob.Description
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $Null -like $_.'Description' -or $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
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
                                Section -Style NOTOCHeading4 -ExcludeFromTOC 'Tenant' {
                                    $OutObj = @()
                                    try {
                                        Write-PScriboMessage "Discovered $($Bkjob.Tenant.Name) EntraID Tenant."
                                        $inObj = [ordered] @{
                                            'Name' = $Bkjob.Tenant.Name
                                            'Azure Tenant Id' = $Bkjob.Tenant.AzureTenantId
                                            'Application Id' = $Bkjob.Tenant.ApplicationId
                                            'Region' = $Bkjob.Tenant.Region
                                            'Cache Repository' = $Bkjob.Tenant.CacheRepository.Name
                                            'Retention Policy' = "$($Bkjob.RetentionPolicy) days"
                                            'Description' = $Bkjob.Tenant.Description
                                        }

                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Entra ID Tenant Section: $($_.Exception.Message)"
                                    }

                                    if ($HealthCheck.Jobs.BestPractice) {
                                        $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                                        $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                    }

                                    $TableParams = @{
                                        Name = "Tenant Information - $($Bkjob.Name)"
                                        List = $True
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
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
                                    if ($InfoLevel.Jobs.EntraID -ge 2) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Advanced Settings (Encryption)' {
                                            $OutObj = @()
                                            try {
                                                Write-PScriboMessage "Discovered $($Bkjob.Tenant.Name) EntraID Encryption."
                                                $inObj = [ordered] @{
                                                    'Enabled' = $Bkjob.EncryptionOptions.Enabled
                                                    'Id' = $Bkjob.EncryptionOptions.key.Id
                                                    'Last Modified Date' = $Bkjob.EncryptionOptions.key.LastModifiedDate
                                                    'Description' = $Bkjob.EncryptionOptions.key.Description
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Entra ID Encryption Section: $($_.Exception.Message)"
                                            }

                                            if ($HealthCheck.Jobs.BestPractice) {
                                                $OutObj | Where-Object { $_.'Enabled' -eq "No" } | Set-Style -Style Warning -Property 'Enabled'
                                            }

                                            $TableParams = @{
                                                Name = "Encryption - $($Bkjob.Name)"
                                                List = $True
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
                                        }
                                    }
                                    if ($InfoLevel.Jobs.EntraID -ge 2) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "Advanced Settings (Notification)" {
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
                                                    Name = "Notification - $($Bkjob.Name)"
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
                                    if ($Bkjob.EnableSchedule) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                            $OutObj = @()
                                            try {
                                                Write-PScriboMessage "Discovered $($Bkjob.Name) schedule options."
                                                if ($Bkjob.ScheduleOptions.OptionsDaily.Enabled -eq "True") {
                                                    $ScheduleType = "Daily"
                                                    $Schedule = "Kind: $($Bkjob.ScheduleOptions.OptionsDaily.Kind),`r`nDays: $($Bkjob.ScheduleOptions.OptionsDaily.DaysSrv)"
                                                } elseif ($Bkjob.ScheduleOptions.OptionsMonthly.Enabled -eq "True") {
                                                    $ScheduleType = "Monthly"
                                                    $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfWeek)"
                                                } elseif ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled -eq "True") {
                                                    $ScheduleType = $Bkjob.ScheduleOptions.OptionsPeriodically.Kind
                                                    $Schedule = "Full Period: $($Bkjob.ScheduleOptions.OptionsPeriodically.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.OptionsPeriodically.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.OptionsPeriodically.Unit)"
                                                } elseif ($Bkjob.ScheduleOptions.OptionsContinuous.Enabled -eq "True") {
                                                    $ScheduleType = 'Continuous'
                                                    $Schedule = "Schedule Time Period"
                                                } elseif ($Bkjob.ScheduleOptions.OptionsScheduleAfterJob.IsEnabled) {
                                                    $ScheduleType = 'After Job'
                                                }
                                                $inObj = [ordered] @{
                                                    'Retry Failed item' = $Bkjob.ScheduleOptions.RetryTimes
                                                    'Wait before each retry' = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                    'Backup Window' = $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled
                                                    'Shedule type' = $ScheduleType
                                                    'Shedule Options' = $Schedule
                                                    'Start Time' = $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                    'Latest Run' = $Bkjob.ScheduleOptions.LatestRunLocal
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
                                                if ($Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled -or $Bkjob.ScheduleOptions.OptionsContinuous.Enabled) {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Backup Window Time Period" {
                                                        Paragraph -ScriptBlock $Legend

                                                        $OutObj = @()
                                                        try {
                                                            $ScheduleTimePeriod = @()
                                                            $Days = 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
                                                            foreach ($Day in $Days) {

                                                                $Regex = [Regex]::new("(?<=<$Day>)(.*)(?=</$Day>)")
                                                                if ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled) {
                                                                    $BackupWindow = $Bkjob.ScheduleOptions.OptionsPeriodically.Schedule
                                                                } elseif ($Bkjob.ScheduleOptions.OptionsContinuous.Enabled) {
                                                                    $BackupWindow = $Bkjob.ScheduleOptions.OptionsContinuous.Schedule
                                                                } else { $BackupWindow = $Bkjob.ScheduleOptions.OptionsBackupWindow.BackupWindow }
                                                                $Match = $Regex.Match($BackupWindow)
                                                                if ($Match.Success) {
                                                                    $ScheduleTimePeriod += $Match.Value
                                                                }
                                                            }

                                                            $OutObj = Get-WindowsTimePeriod -InputTimePeriod $ScheduleTimePeriod

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
                                                                $OutObj2.Rows | Where-Object { $_.Sun -eq "0" } | Set-Style -Style ON -Property "Sun"
                                                                $OutObj2.Rows | Where-Object { $_.Mon -eq "0" } | Set-Style -Style ON -Property "Mon"
                                                                $OutObj2.Rows | Where-Object { $_.Tue -eq "0" } | Set-Style -Style ON -Property "Tue"
                                                                $OutObj2.Rows | Where-Object { $_.Wed -eq "0" } | Set-Style -Style ON -Property "Wed"
                                                                $OutObj2.Rows | Where-Object { $_.Thu -eq "0" } | Set-Style -Style ON -Property "Thu"
                                                                $OutObj2.Rows | Where-Object { $_.Fri -eq "0" } | Set-Style -Style ON -Property "Fri"
                                                                $OutObj2.Rows | Where-Object { $_.Sat -eq "0" } | Set-Style -Style ON -Property "Sat"

                                                                $OutObj2.Rows | Where-Object { $_.Sun -eq "1" } | Set-Style -Style OFF -Property "Sun"
                                                                $OutObj2.Rows | Where-Object { $_.Mon -eq "1" } | Set-Style -Style OFF -Property "Mon"
                                                                $OutObj2.Rows | Where-Object { $_.Tue -eq "1" } | Set-Style -Style OFF -Property "Tue"
                                                                $OutObj2.Rows | Where-Object { $_.Wed -eq "1" } | Set-Style -Style OFF -Property "Wed"
                                                                $OutObj2.Rows | Where-Object { $_.Thu -eq "1" } | Set-Style -Style OFF -Property "Thu"
                                                                $OutObj2.Rows | Where-Object { $_.Fri -eq "1" } | Set-Style -Style OFF -Property "Fri"
                                                                $OutObj2.Rows | Where-Object { $_.Sat -eq "1" } | Set-Style -Style OFF -Property "Sat"
                                                                $OutObj2
                                                            }
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Entra ID Backup Jobs $($Bkjob.Name) Backup Windows Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Entra ID Backup Jobs $($Bkjob.Name) Schedule Section: $($_.Exception.Message)"
                                            }
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
            Write-PScriboMessage -IsWarning "EntraID Tenant Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}
}