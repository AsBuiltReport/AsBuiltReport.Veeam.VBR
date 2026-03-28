
function Get-AbrVbrBackupjobNutanixConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Nutanix backup jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Nutanix Backup jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupjobNutanixConf
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Nutanix Backup Jobs'
    }

    process {
        try {
            if ($Bkjobs = [Veeam.Backup.Core.CBackupJob]::GetAll() | Where-Object { $_.TypeToString -like '*Nutanix*' } | Sort-Object -Property 'Name') {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        if ($VMcounts = Get-VBRBackup | Where-Object { $_.TypeToString -like 'Nutanix' }) {
                            foreach ($VMcount in $VMcounts) {
                                try {

                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $VMcount.Name
                                        $LocalizedData.CreationTime = $VMcount.CreationTime
                                        $LocalizedData.VMCount = $VMcount.VmCount
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "Nutanix Backup Jobs Configuration Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.NutanixBackupSummary) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 35, 35, 30
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning $_.Exception.Message
                    }
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Section -Style Heading4 $($Bkjob.Name) {
                                Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.CommonInformation {
                                    $OutObj = @()
                                    try {
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name = $Bkjob.Name
                                                $LocalizedData.Type = $Bkjob.TypeToString
                                                $LocalizedData.TotalBackupSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Bkjob.Info.IncludedSize
                                                $LocalizedData.TargetAddress = $Bkjob.Info.TargetDir
                                                $LocalizedData.TargetFile = $Bkjob.Info.TargetFile
                                                $LocalizedData.Description = $Bkjob.Info.CommonInfo.Description
                                                $LocalizedData.ModifiedBy = $Bkjob.Info.CommonInfo.ModifiedBy.FullName
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $($LocalizedData.Description)
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $($LocalizedData.Description)
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.CommonInformation) - $($Bkjob.Name)"
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
                                                    Text $LocalizedData.DescriptionBestPracticeText
                                                }
                                                BlankLine
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.LinkedBackupJobs {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedBkJob in $Bkjob.LinkedJobs) {
                                                try {

                                                    $Job = $Bkjobs | Where-Object { $_.Id -eq $LinkedBkJob.info.LinkedObjectId.Guid }
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $Job.Name
                                                        $LocalizedData.Type = $Job.TypeToString
                                                        $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Job.Info.IncludedSize
                                                        $LocalizedData.Repository = $Job.GetTargetRepository().Name
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.LinkedBackupJobs) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 25, 15, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.LinkedRepositories) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.LinkedRepositories {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedRepository in $Bkjob.LinkedRepositories.LinkedRepositoryId) {
                                                try {

                                                    if ($Repo = Get-VBRBackupRepository | Where-Object { $_.Id -eq $LinkedRepository }) {
                                                        $inObj = [ordered] @{
                                                            $LocalizedData.Name = $Repo.Name
                                                            $LocalizedData.Type = $LocalizedData.Standard
                                                            $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Repo.GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    }
                                                    if ($ScaleRepo = Get-VBRBackupRepository -ScaleOut | Where-Object { $_.Id -eq $LinkedRepository }) {
                                                        $inObj = [ordered] @{
                                                            $LocalizedData.Name = $ScaleRepo.Name
                                                            $LocalizedData.Type = $LocalizedData.ScaleOut
                                                            $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size (($ScaleRepo.Extent).Repository).GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.LinkedRepositories) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 35, 30
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.LinkedJobs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.DataTransfer {
                                        $OutObj = @()
                                        try {
                                            try {

                                                if ($Bkjob.IsWanAcceleratorEnabled()) {
                                                    try {
                                                        $TargetWanAccelerator = $Bkjob.GetTargetWanAccelerator().Name
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                    try {
                                                        $SourceWanAccelerator = $Bkjob.GetSourceWanAccelerator().Name
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                }
                                                $inObj = [ordered] @{
                                                    $LocalizedData.UseWanAccelerator = $Bkjob.IsWanAcceleratorEnabled()
                                                    $LocalizedData.SourceWanAccelerator = switch ($Bkjob.IsWanAcceleratorEnabled()) {
                                                        'False' { 'Direct Mode' }
                                                        'True' { $SourceWanAccelerator }
                                                        default { 'Unknown' }
                                                    }
                                                    $LocalizedData.TargetWanAccelerator = switch ($Bkjob.IsWanAcceleratorEnabled()) {
                                                        'False' { 'Direct Mode' }
                                                        'True' { $TargetWanAccelerator }
                                                        default { 'Unknown' }
                                                    }
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning $_.Exception.Message
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.DataTransfer) - $($Bkjob.Name)"
                                                List = $True
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
                                if ($Bkjob.GetAhvOijs()) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.VirtualMachines {
                                        $OutObj = @()
                                        try {
                                            foreach ($OBJ in ($Bkjob.GetAhvOijs() | Where-Object { $_.Type -eq 'Include' -or $_.Type -eq 'Exclude' } )) {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $OBJ.Name
                                                    $LocalizedData.ResourceType = & {
                                                        if ($OBJ.TypeDisplayName) {
                                                            $OBJ.TypeDisplayName
                                                        } elseif ($OBJ.Object) {
                                                            $OBJ.Object.Type
                                                        }
                                                    }
                                                    $LocalizedData.Role = $OBJ.Type
                                                    $LocalizedData.ApproxSize = $OBJ.ApproxSizeString
                                                    $LocalizedData.DiskFilterMode = $OBJ.DiskFilterInfo.Mode
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.VirtualMachines) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 20, 20, 20, 20, 20
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
                                if ($Bkjob.TypeToString -eq 'Nutanix') {
                                    $Storage = $LocalizedData.Target
                                    $StorageTableName = $LocalizedData.TargetOptions
                                } else {
                                    $Storage = $LocalizedData.Storage
                                    $StorageTableName = $LocalizedData.StorageOptions
                                }
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $Storage {
                                    $OutObj = @()
                                    try {

                                        if ($Bkjob.BackupStorageOptions.RetentionType -eq 'Days') {
                                            $RetainString = $LocalizedData.RetainDaysToKeep
                                            $Retains = $Bkjob.BackupStorageOptions.RetainDaysToKeep
                                        } elseif ($Bkjob.BackupStorageOptions.RetentionType -eq 'Cycles') {
                                            $RetainString = $LocalizedData.RetainCycles
                                            $Retains = $Bkjob.BackupStorageOptions.RetainCycles
                                        }
                                        $inObj = [ordered] @{
                                            $LocalizedData.BackupProxy = $LocalizedData.BackupAppliance
                                            $LocalizedData.BackupRepository = switch ($Bkjob.info.TargetRepositoryId) {
                                                '00000000-0000-0000-0000-000000000000' { $LocalizedData.SnapshotBackup }
                                                { $Null -eq (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name } { (Get-VBRBackupRepository -ScaleOut | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                                default { (Get-VBRBackupRepository | Where-Object { $_.Id -eq $Bkjob.info.TargetRepositoryId }).Name }
                                            }
                                            $LocalizedData.RetentionType = $Bkjob.BackupStorageOptions.RetentionType
                                            $RetainString = $Retains
                                            $LocalizedData.KeepFirstFullBackup = $Bkjob.BackupStorageOptions.KeepFirstFullBackup
                                            $LocalizedData.EnableFullBackup = $Bkjob.BackupStorageOptions.EnableFullBackup
                                            $LocalizedData.IntegrityChecks = $Bkjob.BackupStorageOptions.EnableIntegrityChecks
                                            $LocalizedData.StorageEncryption = $Bkjob.BackupStorageOptions.StorageEncryptionEnabled
                                            $LocalizedData.BackupMode = switch ($Bkjob.Options.BackupTargetOptions.Algorithm) {
                                                'Synthetic' { $LocalizedData.ReverseIncremental }
                                                'Increment' { $LocalizedData.Incremental }
                                            }
                                            $LocalizedData.ActiveFullBackupScheduleKind = $Bkjob.Options.BackupTargetOptions.FullBackupScheduleKind
                                            $LocalizedData.ActiveFullBackupDays = $Bkjob.Options.BackupTargetOptions.FullBackupDays
                                            $LocalizedData.TransformFullToSynthetic = $Bkjob.Options.BackupTargetOptions.TransformFullToSyntethic
                                            $LocalizedData.TransformIncrementsToSynthetic = $Bkjob.Options.BackupTargetOptions.TransformIncrementsToSyntethic
                                            $LocalizedData.TransformToSyntheticDays = $Bkjob.Options.BackupTargetOptions.TransformToSyntethicDays


                                        }
                                        if ($Bkjob.Options.GfsPolicy.IsEnabled) {
                                            $inObj.add($LocalizedData.KeepCertainFullBackupGFS, ($Bkjob.Options.GfsPolicy.IsEnabled))
                                            if (-not $Bkjob.Options.GfsPolicy.Weekly.IsEnabled) {
                                                $inObj.add($LocalizedData.KeepWeeklyFullBackup, ($LocalizedData.Disabled))
                                            } else {
                                                $inObj.add($LocalizedData.KeepWeeklyFullBackupFor, ("$($Bkjob.Options.GfsPolicy.Weekly.KeepBackupsForNumberOfWeeks) weeks,`r`nIf multiple backup exist use the one from: $($Bkjob.Options.GfsPolicy.Weekly.DesiredTime)"))
                                            }
                                            if (-not $Bkjob.Options.GfsPolicy.Monthly.IsEnabled) {
                                                $inObj.add($LocalizedData.KeepMonthlyFullBackup, ($LocalizedData.Disabled))
                                            } else {
                                                $inObj.add($LocalizedData.KeepMonthlyFullBackupFor, ("$($Bkjob.Options.GfsPolicy.Monthly.KeepBackupsForNumberOfMonths) months,`r`nUse weekly full backup from the following week of the month: $($Bkjob.Options.GfsPolicy.Monthly.DesiredTime)"))
                                            }
                                            if (-not $Bkjob.Options.GfsPolicy.Yearly.IsEnabled) {
                                                $inObj.add($LocalizedData.KeepYearlyFullBackup, ($LocalizedData.Disabled))
                                            } else {
                                                $inObj.add($LocalizedData.KeepYearlyFullBackupFor, ("$($Bkjob.Options.GfsPolicy.Yearly.KeepBackupsForNumberOfYears) years,`r`nUse monthly full backup from the following month: $($Bkjob.Options.GfsPolicy.Yearly.DesiredTime)"))
                                            }
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "$StorageTableName - $($Bkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($InfoLevel.Jobs.Nutanix -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsMaintenance {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.SLCG = $Bkjob.Options.GenerationPolicy.EnableRechek
                                                        $LocalizedData.SLCGScheduleType = $Bkjob.Options.GenerationPolicy.RecheckScheduleKind
                                                        $LocalizedData.SLCGScheduleDay = $Bkjob.Options.GenerationPolicy.RecheckDays
                                                        $LocalizedData.SLCGBackupMonthlySchedule = "Day Of Week: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.RecheckBackupMonthlyScheduleOptions.Months)"
                                                        $LocalizedData.DCFB = $Bkjob.Options.GenerationPolicy.EnableCompactFull
                                                        $LocalizedData.DCFBScheduleType = $Bkjob.Options.GenerationPolicy.CompactFullBackupScheduleKind
                                                        $LocalizedData.DCFBScheduleDay = $Bkjob.Options.GenerationPolicy.CompactFullBackupDays
                                                        $LocalizedData.DCFBBackupMonthlySchedule = "Day Of Week: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfWeek)`r`nDay Number In Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayNumberInMonth)`r`nDay of Month: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.DayOfMonth)`r`nMonths: $($Bkjob.Options.GenerationPolicy.CompactFullBackupMonthlyScheduleOptions.Months)"
                                                        $LocalizedData.RemoveDeletedItemData = $Bkjob.Options.BackupStorageOptions.RetainDays
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.SLCG) -eq 'No' } | Set-Style -Style Warning -Property $($LocalizedData.SLCG)
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsMaintenance) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.$($LocalizedData.SLCG) -eq 'No' }) {
                                                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text $LocalizedData.BestPractice -Bold
                                                                Text $LocalizedData.SLCGBestPracticeText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsStorage {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.InlineDataDeduplication = $Bkjob.Options.BackupStorageOptions.EnableDeduplication
                                                        $LocalizedData.ExcludeSwapFilesBlock = $Bkjob.ViSourceOptions.ExcludeSwapFile
                                                        $LocalizedData.ExcludeDeletedFilesBlock = $Bkjob.ViSourceOptions.DirtyBlocksNullingEnabled
                                                        $LocalizedData.CompressionLevel = switch ($Bkjob.Options.BackupStorageOptions.CompressionLevel) {
                                                            0 { $LocalizedData.CompressionNone }
                                                            -1 { $LocalizedData.CompressionAuto }
                                                            4 { $LocalizedData.CompressionDedupe }
                                                            5 { $LocalizedData.CompressionOptimal }
                                                            6 { $LocalizedData.CompressionHigh }
                                                            9 { $LocalizedData.CompressionExtreme }
                                                        }
                                                        $LocalizedData.StorageOptimization = switch ($Bkjob.Options.BackupStorageOptions.StgBlockSize) {
                                                            'KbBlockSize1024' { $LocalizedData.LocalTarget1MB }
                                                            'KbBlockSize512' { $LocalizedData.LANTarget512KB }
                                                            'KbBlockSize256' { $LocalizedData.WANTarget256KB }
                                                            'KbBlockSize4096' { $LocalizedData.LocalTarget4MB }
                                                            default { $Bkjob.Options.BackupStorageOptions.StgBlockSize }
                                                        }
                                                        $LocalizedData.EnabledBackupFileEncryption = $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                                        $LocalizedData.EncryptionKey = switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                            $false { $LocalizedData.None }
                                                            default { (Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.EnabledBackupFileEncryption) -eq 'No' } | Set-Style -Style Warning -Property $($LocalizedData.EnabledBackupFileEncryption)
                                                        $OutObj | Where-Object { $_.$($LocalizedData.ExcludeSwapFilesBlock) -eq 'No' } | Set-Style -Style Warning -Property $($LocalizedData.ExcludeSwapFilesBlock)
                                                        $OutObj | Where-Object { $_.$($LocalizedData.ExcludeDeletedFilesBlock) -eq 'No' } | Set-Style -Style Warning -Property $($LocalizedData.ExcludeDeletedFilesBlock)
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsStorage) - $($Bkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.$($LocalizedData.EnabledBackupFileEncryption) -eq 'No' }) {
                                                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text $LocalizedData.BestPractice -Bold
                                                                Text $LocalizedData.EncryptionBestPracticeText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.NotificationOptions.SnmpNotification -or $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsNotification {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.SendSnmpNotification = $Bkjob.Options.NotificationOptions.SnmpNotification
                                                        $LocalizedData.SendEmailNotification = $Bkjob.Options.NotificationOptions.SendEmailNotification2AdditionalAddresses
                                                        $LocalizedData.EmailAdditionalAddresses = $Bkjob.Options.NotificationOptions.EmailNotificationAdditionalAddresses
                                                        $LocalizedData.EmailNotifyTime = $Bkjob.Options.NotificationOptions.EmailNotifyTime.ToShortTimeString()
                                                        $LocalizedData.UseCustomEmailNotification = $Bkjob.Options.NotificationOptions.UseCustomEmailNotificationOptions
                                                        $LocalizedData.UseCustomNotificationSetting = $Bkjob.Options.NotificationOptions.EmailNotificationSubject
                                                        $LocalizedData.NotifyOnSuccess = $Bkjob.Options.NotificationOptions.EmailNotifyOnSuccess
                                                        $LocalizedData.NotifyOnWarning = $Bkjob.Options.NotificationOptions.EmailNotifyOnWarning
                                                        $LocalizedData.NotifyOnError = $Bkjob.Options.NotificationOptions.EmailNotifyOnError
                                                        $LocalizedData.SuppressNotification = $Bkjob.Options.NotificationOptions.EmailNotifyOnLastRetryOnly
                                                        $LocalizedData.SetResultsToVmNotes = $Bkjob.Options.ViSourceOptions.SetResultsToVmNotes
                                                        $LocalizedData.VmAttributeNoteValue = $Bkjob.Options.ViSourceOptions.VmAttributeName
                                                        $LocalizedData.AppendToAttribute = $Bkjob.Options.ViSourceOptions.VmNotesAppend
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsNotification) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.ViSourceOptions.VMToolsQuiesce -or $Bkjob.Options.ViSourceOptions.UseChangeTracking)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsNutanix {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.EnableNutanixToolsQuiescence = $Bkjob.Options.ViSourceOptions.VMToolsQuiesce
                                                        $LocalizedData.UseChangeBlockTracking = $Bkjob.Options.ViSourceOptions.UseChangeTracking
                                                        $LocalizedData.EnableCBTForAllVMs = $Bkjob.Options.ViSourceOptions.EnableChangeTracking
                                                        $LocalizedData.ResetCBTOnActiveFull = $Bkjob.Options.ViSourceOptions.ResetChangeTrackingOnActiveFull
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsNutanix) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsIntegration {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.EnableBackupFromStorage = $Bkjob.Options.SanIntegrationOptions.UseSanSnapshots
                                                        $LocalizedData.LimitVMCountPerSnapshot = $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotEnabled
                                                        $LocalizedData.VMCountPerSnapshot = $Bkjob.Options.SanIntegrationOptions.MultipleStorageSnapshotVmsCount
                                                        $LocalizedData.FailoverToStandardBackup = $Bkjob.Options.SanIntegrationOptions.FailoverFromSan
                                                        $LocalizedData.FailoverToPrimarySnapshot = $Bkjob.Options.SanIntegrationOptions.Failover2StorageSnapshotBackup
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsIntegration) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.JobScriptCommand.PreScriptEnabled -or $Bkjob.Options.JobScriptCommand.PostScriptEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsScript {
                                                $OutObj = @()
                                                try {
                                                    if ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Days') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Days -join ','
                                                        $FrequencyText = $LocalizedData.RunScriptOnSelectedDays
                                                    } elseif ($Bkjob.Options.JobScriptCommand.Periodicity -eq 'Cycles') {
                                                        $FrequencyValue = $Bkjob.Options.JobScriptCommand.Frequency
                                                        $FrequencyText = $LocalizedData.RunScriptEverySession
                                                    }

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.RunScriptBefore = $Bkjob.Options.JobScriptCommand.PreScriptEnabled
                                                        $LocalizedData.RunScriptBeforeJob = $Bkjob.Options.JobScriptCommand.PreScriptCommandLine
                                                        $LocalizedData.RunScriptAfter = $Bkjob.Options.JobScriptCommand.PostScriptEnabled
                                                        $LocalizedData.RunScriptAfterJob = $Bkjob.Options.JobScriptCommand.PostScriptCommandLine
                                                        $LocalizedData.RunScriptFrequency = $Bkjob.Options.JobScriptCommand.Periodicity
                                                        $FrequencyText = $FrequencyValue

                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsScript) - $($Bkjob.Name)"
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
                                        if ($InfoLevel.Jobs.Nutanix -ge 2 -and ($Bkjob.Options.RpoOptions.Enabled -or $Bkjob.Options.RpoOptions.LogBackupRpoEnabled)) {
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.AdvancedSettingsRPO {
                                                $OutObj = @()
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.RpoMonitorEnabled = $Bkjob.Options.RpoOptions.Enabled
                                                        $LocalizedData.IfBackupNotCopied = "$($Bkjob.Options.RpoOptions.Value) $($Bkjob.Options.RpoOptions.TimeUnit)"
                                                        $LocalizedData.LogBackupRpoEnabled = $Bkjob.Options.RpoOptions.LogBackupRpoEnabled
                                                        $LocalizedData.IfLogBackupNotCopied = "$($Bkjob.Options.RpoOptions.LogBackupRpoValue) $($Bkjob.Options.RpoOptions.LogBackupRpoTimeUnit)"
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.AdvancedSettingsRPO) - $($Bkjob.Name)"
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
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($Bkjob.Id) | Where-Object { $_.JobType -ne 'SimpleBackupCopyWorker' }
                                if ($SecondaryTargets) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SecondaryTarget {
                                        $OutObj = @()
                                        try {
                                            foreach ($SecondaryTarget in $SecondaryTargets) {

                                                try {
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.JobName = $SecondaryTarget.Name
                                                        $LocalizedData.Type = $SecondaryTarget.TypeToString
                                                        $LocalizedData.State = $SecondaryTarget.info.LatestStatus
                                                        $LocalizedData.Description = $SecondaryTarget.Description
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                            $TableParams = @{
                                                Name = "$($LocalizedData.SecondaryDestinationJobs) - $($Bkjob.Name)"
                                                List = $false
                                                ColumnWidths = 25, 25, 15, 35
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property $LocalizedData.JobName | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.VssOptions.Enabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.GuestProcessing {
                                        $OutObj = @()
                                        try {
                                            $VSSObjs = Get-VBRJobObject -Job $Bkjob.Name | Where-Object { $_.Type -eq 'Include' -or $_.Type -eq 'VssChild' } | Sort-Object -Property Name
                                            foreach ($VSSObj in $VSSObjs) {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $VSSObj.Name
                                                    $LocalizedData.Enabled = $VSSObj.VssOptions.Enabled
                                                    $LocalizedData.ResourceType = & {
                                                        if (($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq 'Include' -or $_.Type -eq 'VssChild') }).TypeDisplayName) {
                                                            ($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq 'Include' -or $_.Type -eq 'VssChild') }).TypeDisplayName
                                                        } elseif (($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq 'Include' -or $_.Type -eq 'VssChild') }).Object) {
                                                            ($Bkjob.GetAhvOijs() | Where-Object { $_.Name -eq $VSSObj.Name -and ($_.Type -eq 'Include' -or $_.Type -eq 'VssChild') }).Object.Type
                                                        }
                                                    }
                                                    $LocalizedData.IgnoreErrors = $VSSObj.VssOptions.IgnoreErrors
                                                    $LocalizedData.GuestProxyAutoDetect = $VSSObj.VssOptions.GuestProxyAutoDetect
                                                    $LocalizedData.DefaultCredential = switch ((Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid }).count) {
                                                        0 { $LocalizedData.None }
                                                        default { Get-VBRCredentials | Where-Object { $_.Id -eq $Bkjob.VssOptions.WinCredsId.Guid } }
                                                    }
                                                    $LocalizedData.ObjectCredential = switch ($VSSObj.VssOptions.WinCredsId.Guid) {
                                                        '00000000-0000-0000-0000-000000000000' { $LocalizedData.DefaultCredential }
                                                        default { Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.WinCredsId.Guid } }
                                                    }
                                                    $LocalizedData.ApplicationProcessing = $VSSObj.VssOptions.VssSnapshotOptions.ApplicationProcessingEnabled
                                                    $LocalizedData.TransactionLogs = switch ($VSSObj.VssOptions.VssSnapshotOptions.IsCopyOnly) {
                                                        'False' { $LocalizedData.ProcessTransactionLogs }
                                                        'True' { $LocalizedData.PerformCopyOnly }
                                                    }
                                                    $LocalizedData.UsePersistentGuestAgent = $VSSObj.VssOptions.VssSnapshotOptions.UsePersistentGuestAgent
                                                }
                                                if ($InfoLevel.Jobs.Nutanix -ge 2) {
                                                    if (!$VSSObj.VssOptions.VssSnapshotOptions.IsCopyOnly) {
                                                        $TransactionLogsProcessing = switch ($VSSObj.VssOptions.SqlBackupOptions.TransactionLogsProcessing) {
                                                            'TruncateOnlyOnSuccessJob' { 'Truncate logs' }
                                                            'Backup' { 'Backup logs periodically' }
                                                            'NeverTruncate' { 'Do not truncate logs' }
                                                        }
                                                        $RetainLogBackups = switch ($VSSObj.VssOptions.SqlBackupOptions.UseDbBackupRetention) {
                                                            'True' { 'Until the corresponding image-level backup is deleted' }
                                                            'False' { "Keep Only Last $($VSSObj.VssOptions.SqlBackupOptions.RetainDays) days of log backups" }
                                                        }
                                                        $inObj.add($LocalizedData.SqlTransactionLogsProcessing, ($TransactionLogsProcessing))
                                                        $inObj.add($LocalizedData.SqlBackupLogEvery, ("$($VSSObj.VssOptions.SqlBackupOptions.BackupLogsFrequencyMin) min"))
                                                        $inObj.add($LocalizedData.SqlRetainLogBackups, $($RetainLogBackups))
                                                    }
                                                    if ($VSSObj.VssOptions.OracleBackupOptions.BackupLogsEnabled -or $VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation) {
                                                        $ArchivedLogsTruncation = switch ($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation) {
                                                            'ByAge' { "Delete Log Older Than $($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsMaxAgeHours) hours" }
                                                            'BySize' { "Delete Log Over $([Math]::Round($VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsMaxSizeMb / 1024, 0)) GB" }
                                                            default { $VSSObj.VssOptions.OracleBackupOptions.ArchivedLogsTruncation }

                                                        }
                                                        $SysdbaCredsId = switch ($VSSObj.VssOptions.OracleBackupOptions.SysdbaCredsId) {
                                                            '00000000-0000-0000-0000-000000000000' { 'Guest OS Credential' }
                                                            default { (Get-VBRCredentials | Where-Object { $_.Id -eq $VSSObj.VssOptions.OracleBackupOptions.SysdbaCredsId }).Description }
                                                        }
                                                        $RetainLogBackups = switch ($VSSObj.VssOptions.OracleBackupOptions.UseDbBackupRetention) {
                                                            'True' { 'Until the corresponding image-level backup is deleted' }
                                                            'False' { "Keep Only Last $($VSSObj.VssOptions.OracleBackupOptions.RetainDays) days of log backups" }
                                                        }
                                                        $inObj.add($LocalizedData.OracleAccountType, $VSSObj.VssOptions.OracleBackupOptions.AccountType)
                                                        $inObj.add($LocalizedData.OracleSysdbaCredsId, $SysdbaCredsId)
                                                        if ($VSSObj.VssOptions.OracleBackupOptions.BackupLogsEnabled) {
                                                            $inObj.add($LocalizedData.OracleBackupLogsEvery, ("$($VSSObj.VssOptions.OracleBackupOptions.BackupLogsFrequencyMin) min"))
                                                        }
                                                        $inObj.add($LocalizedData.OracleArchiveLogs, ($ArchivedLogsTruncation))
                                                        $inObj.add($LocalizedData.OracleRetainLogBackups, $($RetainLogBackups))
                                                    }
                                                    if ($VSSObj.VssOptions.GuestFSExcludeOptions.FileExcludeEnabled) {
                                                        $inObj.add($LocalizedData.FileExclusions, ($VSSObj.VssOptions.GuestFSExcludeOptions.FileExcludeEnabled))
                                                        if ($VSSObj.VssOptions.GuestFSExcludeOptions.BackupScope -eq 'ExcludeSpecifiedFolders') {
                                                            $inObj.add($LocalizedData.ExcludeFileFolders, ($VSSObj.VssOptions.GuestFSExcludeOptions.ExcludeList -join ','))
                                                        } elseif ($VSSObj.VssOptions.GuestFSExcludeOptions.BackupScope -eq 'IncludeSpecifiedFolders') {
                                                            $inObj.add($LocalizedData.IncludeFileFolders, ($VSSObj.VssOptions.GuestFSExcludeOptions.IncludeList -join ','))
                                                        }
                                                    }
                                                    if ($VSSObj.VssOptions.GuestScriptsOptions.ScriptingMode -ne 'Disabled') {
                                                        $ScriptingMode = switch ($VSSObj.VssOptions.GuestScriptsOptions.ScriptingMode) {
                                                            'FailJobOnError' { 'Require successfull script execution' }
                                                            'IgnoreErrors' { 'Ignore script execution failures' }
                                                            'Disabled' { 'Disable script execution' }
                                                        }
                                                        $inObj.add($LocalizedData.Scripts, ($VSSObj.VssOptions.GuestScriptsOptions.IsAtLeastOneScriptSet))
                                                        $inObj.add($LocalizedData.ScriptsMode, ($ScriptingMode))
                                                        if ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.IsAtLeastOneScriptSet) {
                                                            $inObj.add($LocalizedData.WindowsPreFreezeScript, ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.PreScriptFilePath))
                                                            $inObj.add($LocalizedData.WindowsPostThawScript, ($VSSObj.VssOptions.GuestScriptsOptions.WinScriptFiles.PostScriptFilePath))
                                                        } elseif ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.IsAtLeastOneScriptSet) {
                                                            $inObj.add($LocalizedData.LinuxPreFreezeScript, ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.PreScriptFilePath))
                                                            $inObj.add($LocalizedData.LinuxPostThawScript, ($VSSObj.VssOptions.GuestScriptsOptions.LinScriptFiles.PostScriptFilePath))
                                                        }
                                                    }
                                                }

                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.GuestProcessingOptions) - $($VSSObj.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                if ($Bkjob.IsScheduleEnabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.Schedule {
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
                                            }
                                            $inObj = [ordered] @{
                                                $LocalizedData.RetryFailedItem = $Bkjob.ScheduleOptions.RetryTimes
                                                $LocalizedData.WaitBeforeRetry = "$($Bkjob.ScheduleOptions.RetryTimeout)/min"
                                                $LocalizedData.BackupWindow = switch ($Bkjob.TypeToString) {
                                                    'Nutanix' { $Bkjob.ScheduleOptions.OptionsContinuous.Enabled }
                                                    default { $Bkjob.ScheduleOptions.OptionsBackupWindow.IsEnabled }
                                                }
                                                $LocalizedData.ScheduleType = $ScheduleType
                                                $LocalizedData.ScheduleOptions = $Schedule
                                                $LocalizedData.StartTime = $Bkjob.ScheduleOptions.OptionsDaily.TimeLocal.ToShorttimeString()
                                                $LocalizedData.LatestRun = $Bkjob.LatestRunLocal
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
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.BackupWindowTimePeriod {
                                                        Paragraph -ScriptBlock $Legend

                                                        $ScheduleTimePeriod = @()
                                                        $Days = 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
                                                        foreach ($Day in $Days) {

                                                            $Regex = [Regex]::new("(?<=<$Day>)(.*)(?=</$Day>)")
                                                            if ($Bkjob.TypeToString -eq 'Nutanix') {
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
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning $_.Exception.Message
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
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Nutanix Backup Jobs'
    }

}