
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
                        $Bkjobs = Get-VBRJob -WarningAction Ignore | Where-object {$_.TypeToString -ne 'Windows Agent Backup'}
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
                                Write-PscriboMessage "Discovered $($Bkjob.Name) backup job."
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
                                Section -Style Heading4 'Backup Jobs Configuration' {
                                    Paragraph "The following section details per backup jobs configuration."
                                    BlankLine
                                    $Bkjobs = Get-VBRJob -WarningAction Ignore | Where-Object {$_.TypeToString -eq "VMware Backup"}
                                    foreach ($Bkjob in $Bkjobs) {
                                        Section -Style Heading5 "$($Bkjob.Name) Configuration" {
                                            Section -Style Heading6 "Object to Backup" {
                                                $OutObj = @()
                                                try {
                                                    foreach ($OBJ in $Bkjob.GetViOijs()) {
                                                        Write-PscriboMessage "Discovered $($OBJ.Name) object to backup."
                                                        $inObj = [ordered] @{
                                                            'Name' = $OBJ.Name
                                                            'Resource Type' = $OBJ.TypeDisplayName
                                                            'Role' = $OBJ.Type
                                                            'Location' = $OBJ.Location
                                                            'Approx Size' = $OBJ.ApproxSizeString
                                                            'Order' = $OBJ.OrderNo
                                                            'Disk Filter Mode' = $OBJ.DiskFilterInfo.Mode
                                                        }
                                                        $OutObj = [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Object - $($OBJ.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                            Section -Style Heading6 "Storage Options" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) storage options."
                                                    if ($Bkjob.BackupStorageOptions.RetentionType -eq "Days") {
                                                        $RetainString = 'Retain Days To Keep'
                                                        $Retains = $Bkjob.BackupStorageOptions.RetainDaysToKeep
                                                    }
                                                    elseif ($Bkjob.BackupStorageOptions.RetentionType -eq "Cycles") {
                                                        $RetainString = 'Retain Cycles'
                                                        $Retains = $Bkjob.BackupStorageOptions.RetainCycles
                                                    }
                                                    $inObj = [ordered] @{
                                                        'Backup Proxy' = Switch (($Bkjob.GetProxy().Name).count) {
                                                            0 {"Unknown"}
                                                            {$_ -gt 1} {"Automatic"}
                                                            default {$Bkjob.GetProxy().Name}
                                                        }
                                                        'Backup Repository' = $Bkjob.GetTargetRepository().Name
                                                        'Retention Type' = $Bkjob.BackupStorageOptions.RetentionType
                                                        $RetainString = $Retains
                                                        'Keep First Full Backup' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.KeepFirstFullBackup
                                                        'Enable Full Backup' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.EnableFullBackup
                                                        'Integrity Checks' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.EnableIntegrityChecks
                                                        'Storage Encryption' = ConvertTo-TextYN $Bkjob.BackupStorageOptions.StorageEncryptionEnabled
                                                        'Backup Mode' = $Bkjob.Options.BackupTargetOptions.Algorithm
                                                        'Full Backup Schedule Kind' = $Bkjob.Options.BackupTargetOptions.FullBackupScheduleKind
                                                        'Full Backup Days' = $Bkjob.Options.BackupTargetOptions.FullBackupDays
                                                        'Transform Full To Syntethic' = ConvertTo-TextYN $Bkjob.Options.BackupTargetOptions.TransformFullToSyntethic
                                                        'Transform Increments To Syntethic' = ConvertTo-TextYN $Bkjob.Options.BackupTargetOptions.TransformIncrementsToSyntethic
                                                        'Transform To Syntethic Days' = $Bkjob.Options.BackupTargetOptions.TransformToSyntethicDays


                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Storage Options - $($Bkjob.Name)"
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
                                                                                        Section -Style Heading6 "Schedule Options" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) backup job."
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
                                                        'Retry Failed item' = $Bkjob.ScheduleOptions.RetryTimes
                                                        'Wait before each retry' = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                        'Backup Window' = ConvertTo-TextYN $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled
                                                        'Shedule type' = $ScheduleType
                                                        'Shedule Options' = $Schedule
                                                        'Start Time' =  $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                        'Latest Run' =  $Bkjob.LatestRunLocal
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
