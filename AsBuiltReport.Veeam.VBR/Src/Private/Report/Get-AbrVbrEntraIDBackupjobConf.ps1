
function Get-AbrVbrEntraIDBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns entraid jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR EntraID Tenant Backup jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrEntraIDBackupjobConf
        Show-AbrDebugExecutionTime -Start -TitleMessage 'EntraID Tenant Backup Jobs'
    }

    process {
        try {
            if ($Bkjobs = Get-VBREntraIDTenantBackupJob | Sort-Object -Property 'Name') {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.CommonInfoSection {
                                    $OutObj = @()
                                    try {
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name        = $Bkjob.Name
                                                $LocalizedData.Id          = $Bkjob.Id
                                                $LocalizedData.NextRun     = $Bkjob.ScheduleOptions.NextRun
                                                $LocalizedData.Description = $Bkjob.Description
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $Null -like $_.$($LocalizedData.Description) -or $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.CommonInfoTable) - $($Bkjob.Name)"
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
                                                    Text $LocalizedData.BestPracticeDesc
                                                }
                                                BlankLine
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.TenantSection {
                                    $OutObj = @()
                                    try {

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $Bkjob.Tenant.Name
                                            $LocalizedData.AzureTenantId = $Bkjob.Tenant.AzureTenantId
                                            $LocalizedData.ApplicationId = $Bkjob.Tenant.ApplicationId
                                            $LocalizedData.Region = $Bkjob.Tenant.Region
                                            $LocalizedData.CacheRepository = $Bkjob.Tenant.CacheRepository.Name
                                            $LocalizedData.RetentionPolicy = ($LocalizedData.RetentionPolicyValue -f $Bkjob.RetentionPolicy)
                                            $LocalizedData.Description = $Bkjob.Tenant.Description
                                        }

                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Entra ID Tenant Section: $($_.Exception.Message)"
                                    }

                                    if ($HealthCheck.Jobs.BestPractice) {
                                        $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                        $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.TenantInfoTable) - $($Bkjob.Name)"
                                        List = $True
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                    if ($HealthCheck.Jobs.BestPractice) {
                                        if ($OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' -or $_.$($LocalizedData.Description) -eq '--' }) {
                                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                            BlankLine
                                            Paragraph {
                                                Text $LocalizedData.BestPractice -Bold
                                                Text $LocalizedData.BestPracticeDesc
                                            }
                                            BlankLine
                                        }
                                    }
                                    if ($InfoLevel.Jobs.EntraID -ge 2) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.EncryptionSection {
                                            $OutObj = @()
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Enabled = $Bkjob.EncryptionOptions.Enabled
                                                    $LocalizedData.Id = $Bkjob.EncryptionOptions.key.Id
                                                    $LocalizedData.LastModifiedDate = $Bkjob.EncryptionOptions.key.LastModifiedDate
                                                    $LocalizedData.Description = $Bkjob.EncryptionOptions.key.Description
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Entra ID Encryption Section: $($_.Exception.Message)"
                                            }

                                            if ($HealthCheck.Jobs.BestPractice) {
                                                $OutObj | Where-Object { $_.$($LocalizedData.Enabled) -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.Enabled
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.EncryptionTable) - $($Bkjob.Name)"
                                                List = $True
                                                ColumnWidths = 40, 60
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if ($HealthCheck.Jobs.BestPractice) {
                                                if ($OutObj | Where-Object { $_.$($LocalizedData.Enabled) -eq 'No' }) {
                                                    Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                    BlankLine
                                                    Paragraph {
                                                        Text $LocalizedData.BestPractice -Bold
                                                        Text $LocalizedData.BestPracticeEncDesc
                                                    }
                                                    BlankLine
                                                }
                                            }
                                        }
                                    }
                                    if ($InfoLevel.Jobs.EntraID -ge 2) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.NotificationSection {
                                            $OutObj = @()
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.SendSnmpNotification = $Bkjob.NotificationOptions.EnableSnmpNotification
                                                    $LocalizedData.SendEmailNotification = $Bkjob.NotificationOptions.EnableAdditionalNotification
                                                    $LocalizedData.EmailAdditionalAddresses = switch ($Bkjob.NotificationOptions.AdditionalAddress) {
                                                        $Null { '--' }
                                                        default { $Bkjob.NotificationOptions.AdditionalAddress }
                                                    }
                                                    $LocalizedData.EmailNotifyTime = $Bkjob.NotificationOptions.SendTime
                                                    $LocalizedData.UseCustomEmailNotification = $Bkjob.NotificationOptions.UseNotificationOptions
                                                    $LocalizedData.UseCustomNotificationSetting = $Bkjob.NotificationOptions.NotificationSubject
                                                    $LocalizedData.NotifyOnSuccess = $Bkjob.NotificationOptions.NotifyOnSuccess
                                                    $LocalizedData.NotifyOnWarning = $Bkjob.NotificationOptions.NotifyOnWarning
                                                    $LocalizedData.NotifyOnError = $Bkjob.NotificationOptions.NotifyOnError
                                                    $LocalizedData.SendNotification = switch ($Bkjob.NotificationOptions.EnableDailyNotification) {
                                                        'False' { $LocalizedData.ImmediatelyAfterBackup }
                                                        'True' { $LocalizedData.DailyAsSummary }
                                                        default { $LocalizedData.Unknown }
                                                    }
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.NotificationTable) - $($Bkjob.Name)"
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.ScheduleSection {
                                            $OutObj = @()
                                            try {

                                                if ($Bkjob.ScheduleOptions.OptionsDaily.Enabled -eq 'True') {
                                                    $ScheduleType = 'Daily'
                                                    $Schedule = "Kind: $($Bkjob.ScheduleOptions.OptionsDaily.Kind),`r`nDays: $($Bkjob.ScheduleOptions.OptionsDaily.DaysSrv)"
                                                } elseif ($Bkjob.ScheduleOptions.OptionsMonthly.Enabled -eq 'True') {
                                                    $ScheduleType = 'Monthly'
                                                    $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfWeek)"
                                                } elseif ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled -eq 'True') {
                                                    $ScheduleType = $Bkjob.ScheduleOptions.OptionsPeriodically.Kind
                                                    $Schedule = "Full Period: $($Bkjob.ScheduleOptions.OptionsPeriodically.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.OptionsPeriodically.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.OptionsPeriodically.Unit)"
                                                } elseif ($Bkjob.ScheduleOptions.OptionsContinuous.Enabled -eq 'True') {
                                                    $ScheduleType = 'Continuous'
                                                    $Schedule = 'Schedule Time Period'
                                                } elseif ($Bkjob.ScheduleOptions.OptionsScheduleAfterJob.IsEnabled) {
                                                    $ScheduleType = 'After Job'
                                                }
                                                $inObj = [ordered] @{
                                                    $LocalizedData.RetryFailedItem = $Bkjob.ScheduleOptions.RetryTimes
                                                    $LocalizedData.WaitBeforeRetry = ($LocalizedData.RetryTimeoutValue -f $Bkjob.ScheduleOptions.RetryTimeout)
                                                    $LocalizedData.BackupWindow = $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled
                                                    $LocalizedData.ScheduleType = $ScheduleType
                                                    $LocalizedData.ScheduleOptions = $Schedule
                                                    $LocalizedData.StartTime = $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                    $LocalizedData.LatestRun = $Bkjob.ScheduleOptions.LatestRunLocal
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.ScheduleOptionsTable) - $($Bkjob.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                                if ($Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled -or $Bkjob.ScheduleOptions.OptionsContinuous.Enabled) {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.BackupWindowSection {
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
                                                                Name = "$($LocalizedData.BackupWindowTable) - $($Bkjob.Name)"
                                                                List = $true
                                                                ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                                Key = 'H'
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            if ($OutObj) {
                                                                $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                                $OutObj2.Rows | Where-Object { $_.Sun -eq '0' } | Set-Style -Style ON -Property 'Sun'
                                                                $OutObj2.Rows | Where-Object { $_.Mon -eq '0' } | Set-Style -Style ON -Property 'Mon'
                                                                $OutObj2.Rows | Where-Object { $_.Tue -eq '0' } | Set-Style -Style ON -Property 'Tue'
                                                                $OutObj2.Rows | Where-Object { $_.Wed -eq '0' } | Set-Style -Style ON -Property 'Wed'
                                                                $OutObj2.Rows | Where-Object { $_.Thu -eq '0' } | Set-Style -Style ON -Property 'Thu'
                                                                $OutObj2.Rows | Where-Object { $_.Fri -eq '0' } | Set-Style -Style ON -Property 'Fri'
                                                                $OutObj2.Rows | Where-Object { $_.Sat -eq '0' } | Set-Style -Style ON -Property 'Sat'

                                                                $OutObj2.Rows | Where-Object { $_.Sun -eq '1' } | Set-Style -Style OFF -Property 'Sun'
                                                                $OutObj2.Rows | Where-Object { $_.Mon -eq '1' } | Set-Style -Style OFF -Property 'Mon'
                                                                $OutObj2.Rows | Where-Object { $_.Tue -eq '1' } | Set-Style -Style OFF -Property 'Tue'
                                                                $OutObj2.Rows | Where-Object { $_.Wed -eq '1' } | Set-Style -Style OFF -Property 'Wed'
                                                                $OutObj2.Rows | Where-Object { $_.Thu -eq '1' } | Set-Style -Style OFF -Property 'Thu'
                                                                $OutObj2.Rows | Where-Object { $_.Fri -eq '1' } | Set-Style -Style OFF -Property 'Fri'
                                                                $OutObj2.Rows | Where-Object { $_.Sat -eq '1' } | Set-Style -Style OFF -Property 'Sat'
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
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'EntraID Tenant Backup Jobs'
    }
}
