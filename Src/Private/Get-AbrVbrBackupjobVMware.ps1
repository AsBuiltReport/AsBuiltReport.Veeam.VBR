
function Get-AbrVbrBackupjobVMware {
    <#
    .SYNOPSIS
        Used by As Built Report to returns vmware backup jobs created in Veeam Backup & Replication.
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
        Write-PscriboMessage "Discovering Veeam VBR VMware Backup jobs information from $System."
    }

    process {
        try {
            $Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.TypeToString -eq "VMware Backup" -or $_.TypeToString -eq "VMware Backup Copy"}
            if (($Bkjobs).count -gt 0) {
                Section -Style Heading3 'VMware Backup Configuration' {
                    Paragraph "The following section details VMware type per backup jobs configuration."
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 "$($Bkjob.Name) Configuration" {
                                Section -Style Heading5 'Common Information' {
                                    $OutObj = @()
                                    try {
                                        $CommonInfos = (Get-VBRJob -WarningAction SilentlyContinue -Name $Bkjob.Name | Where-object {$_.TypeToString -ne 'Windows Agent Backup'}).Info
                                        foreach ($CommonInfo in $CommonInfos) {
                                            try {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) common information."
                                                $inObj = [ordered] @{
                                                    'Name' = $Bkjob.Name
                                                    'Total Backup Size' = ConvertTo-FileSizeString $CommonInfo.IncludedSize
                                                    'Description' = $CommonInfo.CommonInfo.Description
                                                    'Modified By' = $CommonInfo.CommonInfo.ModifiedBy.FullName
                                                    'Target Address' = $CommonInfo.TargetDir
                                                    'Target File' = $CommonInfo.TargetFile
                                                }
                                                $OutObj = [pscustomobject]$inobj
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
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
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style Heading5 'Linked Backup Jobs' {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedBkJob in $Bkjob.LinkedJobs) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) linked backup job."
                                                    $Job = Get-VBRJob -WarningAction SilentlyContinue| Where-Object {$_.Id -eq  $LinkedBkJob.info.LinkedObjectId}
                                                    $inObj = [ordered] @{
                                                        'Name' = $Job.Name
                                                        'Type' = $Job.TypeToString
                                                        'Size' = ConvertTo-FileSizeString $Job.Info.IncludedSize
                                                        'Repository' = $Job.GetTargetRepository().Name
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Linked Backup Jobs - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 25, 15, 25
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
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style Heading5 'Data Transfer' {
                                        $OutObj = @()
                                        try {
                                            try {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) data transfer."
                                                $inObj = [ordered] @{
                                                    'Use Wan accelerator' = ConvertTo-TextYN $Bkjob.IsWanAcceleratorEnabled()
                                                    'Source Wan accelerator' = $Bkjob.GetSourceWanAccelerator().Name
                                                    'Target Wan accelerator' = $Bkjob.GetTargetWanAccelerator().Name
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }

                                            $TableParams = @{
                                                Name = "Data Transfer - $($Bkjob.Name)"
                                                List = $True
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
                                if ($Bkjob.GetViOijs()) {
                                    Section -Style Heading5 "Virtual Machines" {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetViOijs() | Where-Object {$_.Type -eq "Include" -or $_.Type -eq "Exclude"} )) {
                                                Write-PscriboMessage "Discovered $($OBJ.Name) object to backup."
                                                $inObj = [ordered] @{
                                                    'Name' = $OBJ.Name
                                                    'Resource Type' = $OBJ.TypeDisplayName
                                                    'Role' = $OBJ.Type
                                                    'Location' = $OBJ.Location
                                                    'Approx Size' = $OBJ.ApproxSizeString
                                                    'Disk Filter Mode' = $OBJ.DiskFilterInfo.Mode
                                                }
                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Virtual Machines - $($OBJ.Name)"
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
                                }
                                Section -Style Heading5 "Storage" {
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
                                $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($Bkjob.Id) | Where-Object {$_.JobType -ne 'SimpleBackupCopyWorker'}
                                if ($SecondaryTargets) {
                                    Section -Style Heading5 "Secondary Target" {
                                        $OutObj = @()
                                        try {
                                            foreach ($SecondaryTarget in $SecondaryTargets) {
                                                try {
                                                    $inObj = [ordered] @{
                                                        'Job Name' = $SecondaryTarget.Name
                                                        'Type' = $SecondaryTarget.TypeToString
                                                        'State' = $SecondaryTarget.info.LatestStatus
                                                        'Description' = $SecondaryTarget.Description
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                            $TableParams = @{
                                                Name = "Secondary Destination Jobs - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 25, 25, 15, 35
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
                                if ($Bkjob.VssOptions.Enabled) {
                                    Section -Style Heading5 "Guest Processing" {
                                        $OutObj = @()
                                        try {
                                            $VSSObjs = Get-VBRJobObject -Job $Bkjob.Name | Where-Object {$_.Type -eq "Include" -or $_.Type -eq "VssChild"}
                                            foreach ($VSSObj in $VSSObjs) {
                                                $inObj = [ordered] @{
                                                    'Name' = $VSSObj.Name
                                                    'Enabled' = ConvertTo-TextYN $Bkjob.VssOptions.Enabled
                                                    'Ignore Errors' = ConvertTo-TextYN $VSSObj.VssOptions.IgnoreErrors
                                                    'Guest Proxy Auto Detect' = ConvertTo-TextYN  $VSSObj.VssOptions.GuestProxyAutoDetect
                                                    'Default Credential' = Switch ((Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid}).count) {
                                                        0 {'None'}
                                                        Default {Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid}}
                                                    }
                                                    'Object Credential' = Switch ($VSSObj.VssOptions.WinCredsId.Guid) {
                                                        '00000000-0000-0000-0000-000000000000' {'Default Credential'}
                                                        default {Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.WinCredsId.Guid}}
                                                    }
                                                    'Application Processing' = ConvertTo-TextYN $VSSObj.VssOptions.VssSnapshotOptions.ApplicationProcessingEnabled
                                                    'Use Persistent Guest Agent' = ConvertTo-TextYN $VSSObj.VssOptions.VssSnapshotOptions.UsePersistentGuestAgent
                                                }
                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Guest Processing Options - $($VSSObj.Name)"
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
                                }
                                if ($Bkjob.GetScheduleOptions().NextRun) {
                                    Section -Style Heading5 "Schedule" {
                                        $OutObj = @()
                                        try {
                                            Write-PscriboMessage "Discovered $($Bkjob.Name) Schedule Options."
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
                                                Name = "Schedule Options - $($Bkjob.Name)"
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
