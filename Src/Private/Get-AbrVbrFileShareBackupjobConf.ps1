
function Get-AbrVbrFileShareBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns file share backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.4
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
        Write-PscriboMessage "Discovering Veeam VBR File Share Backup jobs information from $System."
    }

    process {
        try {
            $Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.TypeToString -like 'File Backup'}
            if (($Bkjobs).count -gt 0) {
                Section -Style Heading3 'File Share Backup Jobs Configuration' {
                    Paragraph "The following section details the configuration of File Share type backup jobs."
                    BlankLine
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading4 -ExcludeFromTOC 'Common Information' {
                                    $OutObj = @()
                                    try {
                                        $CommonInfos = (Get-VBRJob -WarningAction SilentlyContinue -Name $Bkjob.Name | Where-object {$_.TypeToString -ne 'Windows Agent Backup'}).Info
                                        foreach ($CommonInfo in $CommonInfos) {
                                            try {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) common information."
                                                $inObj = [ordered] @{
                                                    'Name' = $Bkjob.Name
                                                    'Type' = $Bkjob.TypeToString
                                                    'Total Backup Size' = ConvertTo-FileSizeString $CommonInfo.IncludedSize
                                                    'Target Address' = $CommonInfo.TargetDir
                                                    'Target File' = $CommonInfo.TargetFile
                                                    'Description' = $CommonInfo.CommonInfo.Description
                                                    'Modified By' = $CommonInfo.CommonInfo.ModifiedBy.FullName
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
                                if ($Bkjob.GetObjectsInJob()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Files and Folders" {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetObjectsInJob() | Where-Object {$_.Type -eq "Include" -or $_.Type -eq "Exclude"} )) {
                                                Write-PscriboMessage "Discovered $($OBJ.Name) object to backup."
                                                $inObj = [ordered] @{
                                                    'Name' = $OBJ.Name
                                                    'Resource Type' = $OBJ.TypeDisplayName
                                                    'Role' = $OBJ.Type
                                                    'Location' = $OBJ.Location
                                                    'Approx Size' = $OBJ.ApproxSizeString
                                                    'File Filter Include Masks' = $OBJ.ExtendedOptions.FileSourceOptions.IncludeMasks
                                                    'File Filter Exclude Masks' = $OBJ.ExtendedOptions.FileSourceOptions.ExcludeMasks
                                                }
                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Files and Folders - $($OBJ.Name)"
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
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Storage' {
                                    $OutObj = @()
                                    try {
                                        Write-PscriboMessage "Discovered $($Bkjob.Name) storage options."
                                        $inObj = [ordered] @{
                                            'Backup Repository' = Switch ($Bkjob.info.TargetRepositoryId) {
                                                '00000000-0000-0000-0000-000000000000' {$Bkjob.TargetDir}
                                                {$Null -eq (Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name} {(Get-VBRBackupRepository -ScaleOut | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                                                default {(Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                                            }
                                            'Keep all file versions for the last' = "$($Bkjob.Options.NasBackupRetentionPolicy.ShortTermRetention) $($Bkjob.Options.NasBackupRetentionPolicy.ShortTermRetentionUnit)"
                                        }

                                        $FiletoArchive = Switch ($Bkjob.Options.NasBackupRetentionPolicy.ArchiveFileExtensionsScope) {
                                            'ExceptSpecified' {"All file exept the following extension: $($Bkjob.Options.NasBackupRetentionPolicy.ExcludedFileExtensions)"}
                                            'Any' {'All Files: *.*'}
                                            'Specified' {"File with the following extension only: $($Bkjob.Options.NasBackupRetentionPolicy.IncludedFileExtensions)"}
                                        }

                                        if ($Bkjob.Options.NasBackupRetentionPolicy.LongTermEnabled) {
                                            $inObj.add('Keep previous file versions for', "$($Bkjob.Options.NasBackupRetentionPolicy.LongTermRetention) $($Bkjob.Options.NasBackupRetentionPolicy.LongTermRetentionUnit)")
                                            $inObj.add('Archive repository', (Get-VBRBackupRepository | Where-Object {$_.id -eq $BKjob.FindNasBackupJobInfo().LongTermRepositoryId.Guid}).Name)
                                            $inObj.add('File to Archive', $FiletoArchive)
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
                                        if ($InfoLevel.Jobs.FileShare -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (File Version)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) File Version options."
                                                    $FileVersionsRetentionScope = Switch ($Bkjob.Options.NasBackupRetentionPolicy.FileVersionsRetentionScope) {
                                                        'LongTermOnly' {'Limit the number of archived file versions only'}
                                                        'None' {'Keep all file versions'}
                                                        'All' {'Limit the number of both recent and archived file versions'}
                                                    }
                                                    $inObj = [ordered] @{
                                                        'File version to keep' = $FileVersionsRetentionScope
                                                    }
                                                    if ($Bkjob.Options.NasBackupRetentionPolicy.LimitMaxActiveFileVersionsCount) {
                                                        $inObj.add('Active file version limit', $Bkjob.Options.NasBackupRetentionPolicy.MaxActiveFileVersionsCount)
                                                    }
                                                    if ($Bkjob.Options.NasBackupRetentionPolicy.LimitMaxDeletedFileVersionsCount) {
                                                        $inObj.add('Delete file version limit', $Bkjob.Options.NasBackupRetentionPolicy.MaxDeletedFileVersionsCount)
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (File Version) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.FileShare -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Storage)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) storage options."
                                                    $inObj = [ordered] @{
                                                        'Inline Data Deduplication' = ConvertTo-TextYN $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                        'Compression Level' = Switch ($Bkjob.Options.BackupStorageOptions.CompressionLevel) {
                                                            0 {'NONE'}
                                                            -1 {'AUTO'}
                                                            4 {'DEDUPE_friendly'}
                                                            5 {'OPTIMAL (Default)'}
                                                            6 {'High'}
                                                            9 {'EXTREME'}
                                                        }
                                                        'Enabled Backup File Encryption' = ConvertTo-TextYN $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                                        'Encryption Key' = Switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                            $false {'None'}
                                                            default {(Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description}
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Storage) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.FileShare -ge 2 -and $Bkjob.Options.GenerationPolicy.EnableRechek) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Maintenance)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) maintenance options."
                                                    $inObj = [ordered] @{
                                                        'Storage-Level Corruption Guard (SLCG)' = ConvertTo-TextYN $Bkjob.Options.GenerationPolicy.EnableRechek
                                                        'SLCG Schedule Type' = $Bkjob.Options.GenerationPolicy.RecheckScheduleKind
                                                    }

                                                    if ($Bkjob.Options.GenerationPolicy.RecheckScheduleKind -eq 'Daily') {
                                                        $inObj.add('SLCG Schedule Day', $Bkjob.Options.GenerationPolicy.RecheckDays)
                                                    }
                                                    if ($Bkjob.Options.GenerationPolicy.RecheckScheduleKind -eq 'Monthly') {
                                                        $inObj.add('SLCG Backup Monthly Schedule', "Day Of Week: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.Months)")
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Maintenance) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.FileShare -ge 2 -and ($Bkjob.Options.NotificationOptions.SnmpNotification -or $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Notification)" {
                                                $OutObj = @()
                                                try {
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) notification options."
                                                    $inObj = [ordered] @{
                                                        'Send Snmp Notification' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.SnmpNotification
                                                        'Send Email Notification' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses
                                                        'Email Notification Additional Addresses' = $Bkjob.Options.NotificationOptions.EmailNotificationAdditionalAddresses
                                                        'Email Notify Time' = $Bkjob.Options.NotificationOptions.EmailNotifyTime.ToShortTimeString()
                                                        'Use Custom Email Notification Options' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.UseCustomEmailNotificationOptions
                                                        'Use Custom Notification Setting' = $Bkjob.Options.NotificationOptions.EmailNotificationSubject
                                                        'Notify On Success' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnSuccess
                                                        'Notify On Warning' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnWarning
                                                        'Notify On Error' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnError
                                                        'Suppress Notification until Last Retry' = ConvertTo-TextYN $Bkjob.Options.NotificationOptions.EmailNotifyOnLastRetryOnly
                                                        'Set Results To Vm Notes' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.SetResultsToVmNotes
                                                        'VM Attribute Note Value' = $Bkjob.Options.ViSourceOptions.VmAttributeName
                                                        'Append to Existing Attribute' = ConvertTo-TextYN $Bkjob.Options.ViSourceOptions.VmNotesAppend
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Notification) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.FileShare -ge 2 -and ($Bkjob.Options.JobScriptCommand.PreScriptEnabled -or $Bkjob.Options.JobScriptCommand.PostScriptEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Script)" {
                                                $OutObj = @()
                                                try {
                                                    if ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Days') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Days -join ","
                                                        $FrequencyText = 'Run Script on the Selected Days'
                                                    }
                                                    elseif ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Cycles') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Frequency
                                                        $FrequencyText = 'Run Script Every Backup Session'
                                                    }
                                                    Write-PscriboMessage "Discovered $($Bkjob.Name) script options."
                                                    $inObj = [ordered] @{
                                                        'Run the Following Script Before' = ConvertTo-TextYN $Bkjob.Options.JobScriptCommand.PreScriptEnabled
                                                        'Run Script Before the Job' = $Bkjob.Options.JobScriptCommand.PreScriptCommandLine
                                                        'Run the Following Script After' = ConvertTo-TextYN $Bkjob.Options.JobScriptCommand.PostScriptEnabled
                                                        'Run Script After the Job' = $Bkjob.Options.JobScriptCommand.PostScriptCommandLine
                                                        'Run Script Frequency' = $Bkjob.Options.JobScriptCommand.Periodicity
                                                        $FrequencyText = $FrequencyValue

                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Script) - $($Bkjob.Name)"
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
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($Bkjob.Id) | Where-Object {$_.JobType -ne 'SimpleBackupCopyWorker'}
                                if ($SecondaryTargets) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Secondary Target" {
                                        $OutObj = @()
                                        try {
                                            foreach ($SecondaryTarget in $SecondaryTargets) {
                                                Write-PscriboMessage "Discovered $($Bkjob.Name) secondary target."
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
                                            $OutObj | Sort-Object -Property 'Job Name' | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.GetScheduleOptions().NextRun -and $Bkjob.ScheduleOptions.OptionsContinuous.Enabled -ne "True") {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                        $OutObj = @()
                                        try {
                                            Write-PscriboMessage "Discovered $($Bkjob.Name) schedule options."
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