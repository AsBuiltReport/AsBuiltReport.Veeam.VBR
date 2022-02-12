
function Get-AbrVbrBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns backup jobs created in Veeam Backup & Replication.
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
        Write-PscriboMessage "Discovering Veeam VBR Backup jobs information from $System."
    }

    process {
        try {
            if ((Get-VBRJob -WarningAction Ignore).count -gt 0) {
                Section -Style Heading3 'Backup Jobs' {
                    Paragraph "The following section list backup jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        $Bkjobs = Get-VBRJob -WarningAction Ignore
                        foreach ($Bkjob in $Bkjobs) {
                            try {
                                if ($Bkjob.GetTargetRepository().Name) {
                                    $Target = $Bkjob.GetTargetRepository().Name
                                } else {$Target = "-"}
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                            try {
                                Write-PscriboMessage "Discovered $($Bkjob.Name) location."
                                $inObj = [ordered] @{
                                    'Name' = $Bkjob.Name
                                    'Type' = $Bkjob.TypeToString
                                    'Latest Status' = $Bkjob.info.LatestStatus
                                    'Target Repository' = $Target
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Backup Jobs - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $false
                            ColumnWidths = 30, 25, 15, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        try {
                            if ((Get-VBRJob -WarningAction Ignore).count -gt 0) {
                                Section -Style Heading3 'Backup Jobs Configuration' {
                                    Paragraph "The following section details per backup jobs configuration."
                                    BlankLine
                                    $Bkjobs = Get-VBRJob -WarningAction Ignore | Where-Object {$_.TypeToString -eq "VMware Backup"}
                                    foreach ($Bkjob in $Bkjobs) {
                                        Section -Style Heading3 "$($Bkjob.Name) Configuration" {
                                            $OutObj = @()
                                            try {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) location."
                                                if ($Bkjob.ScheduleOptions.OptionsDaily.Enabled -eq "True") {
                                                    $ScheduleType = "Daily"
                                                    $Schedule = "Kind: $($Bkjob.ScheduleOptions.OptionsDaily.Kind),`r`nDays: $($Bkjob.ScheduleOptions.OptionsDaily.DaysSrv)"
                                                }
                                                elseif ($Bkjob.ScheduleOptions.OptionsMonthly.Enabled -eq "True") {
                                                    $ScheduleType = "Monthly"
                                                    $Schedule = "Day Of Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfMonth),`r`nDay Number In Month: $($Bkjob.ScheduleOptions.OptionsMonthly.DayNumberInMonth),`r`nDay Of Week: $($Bkjob.ScheduleOptions.OptionsMonthly.DayOfWeek)"
                                                }
                                                elseif ($Bkjob.ScheduleOptions.OptionsPeriodically.Enabled -eq "True") {
                                                    $ScheduleType = "Hours"
                                                    $Schedule = "Full Period: $($Bkjob.ScheduleOptions.OptionsPeriodically.FullPeriod),`r`nHourly Offset: $($Bkjob.ScheduleOptions.OptionsPeriodically.HourlyOffset),`r`nUnit: $($Bkjob.ScheduleOptions.OptionsPeriodically.Unit)"
                                                }
                                                $inObj = [ordered] @{
                                                    'Name' = $Bkjob.Name
                                                    'SourceType' = $Bkjob.SourceType
                                                    'Description' = $Bkjob.Description
                                                    'Backup Platform' = $Bkjob.BackupPlatform
                                                    'Retry Failed item' = $Bkjob.ScheduleOptions.RetryTimes
                                                    'Wait before each retry' = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                    'Linked Jobs' = $Bkjob.LinkedJobs
                                                    'Backup Window' = ConvertTo-TextYN $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled
                                                    'Shedule type' = $ScheduleType
                                                    'Shedule Options' = $Schedule
                                                    'Start Time' =  $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                }
                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Backup Jobs Configuration - $($Bkjob.Name)"
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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}
