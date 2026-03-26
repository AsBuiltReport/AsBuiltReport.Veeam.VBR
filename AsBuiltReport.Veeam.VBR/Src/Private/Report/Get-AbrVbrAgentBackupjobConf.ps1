
function Get-AbrVbrAgentBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns computer backup jobs configuration created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Agent Backup jobs configuration information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrAgentBackupjobConf
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Agent Backup Jobs Configuration'
    }

    process {
        try {
            if ($ABkjobs = Get-VBRComputerBackupJob | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($ABkjob in $ABkjobs) {
                        try {
                            Section -Style Heading4 $($ABkjob.Name) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionJobMode {
                                    $OutObj = @()
                                    try {
                                        $inObj = [ordered] @{
                                            $LocalizedData.name = $ABkjob.Name
                                            $LocalizedData.id = $ABkjob.Id
                                            $LocalizedData.type = $ABkjob.Type
                                            $LocalizedData.mode = switch ($ABkjob.Mode) {
                                                'ManagedByBackupServer' { $LocalizedData.managedByBackupServer }
                                                'ManagedByAgent' { $LocalizedData.managedByAgent }
                                                default { $ABkjob.Mode }
                                            }
                                            $LocalizedData.description = $ABkjob.Description
                                            $LocalizedData.priority = switch ($ABkjob.IsHighPriority) {
                                                'True' { $LocalizedData.highPriority }
                                                'False' { $LocalizedData.normalPriority }
                                            }
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.$($LocalizedData.description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.description
                                            $OutObj | Where-Object { $_.$($LocalizedData.description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.description
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeadingJobMode) - $($ABkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($HealthCheck.Jobs.BestPractice) {
                                            if ($OutObj | Where-Object { $_.$($LocalizedData.description) -match 'Created by' -or $_.$($LocalizedData.description) -eq '--' }) {
                                                Paragraph $LocalizedData.healthCheck -Bold -Underline
                                                BlankLine
                                                Paragraph {
                                                    Text $LocalizedData.bestPractice -Bold
                                                    Text $LocalizedData.healthCheckDescriptionText
                                                }
                                                BlankLine
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Agent Backup Jobs Common Information Section: $($_.Exception.Message)"
                                    }
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionProtectedComputers {
                                        $OutObj = @()
                                        foreach ($BackupObject in $ABkjob.BackupObject) {
                                            try {
                                                $inObj = [ordered] @{
                                                    $LocalizedData.name = $BackupObject.Name
                                                    $LocalizedData.type = switch ($BackupObject.Type) {
                                                        $Null { $LocalizedData.computer }
                                                        default { $BackupObject.Type }
                                                    }
                                                    $LocalizedData.enabled = $BackupObject.Enabled
                                                    $LocalizedData.container = switch ($BackupObject.Container) {
                                                        $Null { $LocalizedData.individualComputer }
                                                        'ActiveDirectory' { $LocalizedData.activeDirectory }
                                                        'ManuallyDeployed' { $LocalizedData.manuallyDeployed }
                                                        'IndividualComputers' { $LocalizedData.individualComputers }
                                                        default { $BackupObject.Container }
                                                    }
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Protected Computers Section: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeadingProtectedComputers) - $($ABkjob.Name)"
                                            List = $false
                                            ColumnWidths = 25, 25, 25, 25
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Protected Computers Section: $($_.Exception.Message)"
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionBackupMode {
                                        $OutObj = @()
                                        try {
                                            $inObj = [ordered] @{
                                                $LocalizedData.backupMode = switch ($ABkjob.BackupType) {
                                                    'EntireComputer' { $LocalizedData.entireComputer }
                                                    'SelectedVolumes' { $LocalizedData.volumeLevelBackup }
                                                    'SelectedFiles' { $LocalizedData.fileLevelBackup }
                                                }
                                            }
                                            if ($ABkjob.BackupType -eq 'EntireComputer') {
                                                $inObj.add($LocalizedData.includeExternalUSB, ($ABkjob.UsbDrivesIncluded))
                                            } elseif ($ABkjob.BackupType -eq 'SelectedVolumes') {
                                                if ($Null -ne $ABkjob.SelectedVolumes.Path) {
                                                    $inObj.add($LocalizedData.backupFollowingVolumes, ($ABkjob.SelectedVolumes.Path -join ', '))
                                                } elseif ($Null -ne $ABkjob.ExcludedVolumes.Path) {
                                                    $inObj.add($LocalizedData.backupAllVolumesExcept, ($ABkjob.ExcludedVolumes.Path -join ', '))
                                                }

                                            } elseif ($ABkjob.BackupType -eq 'SelectedFiles') {
                                                $inObj.add($LocalizedData.backupOSFiles, ($ABkjob.SelectedFilesOptions.BackupOS))
                                                $inObj.add($LocalizedData.backupPersonalFiles, ($ABkjob.SelectedFilesOptions.BackupPersonalFiles))
                                                if ($ABkjob.SelectedFilesOptions.BackupPersonalFiles -eq $TRUE) {
                                                    $inObj.add($LocalizedData.userProfileFolderToBackup, ("Desktop: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Desktop),`r`nDocuments: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Documents),`r`nPictures: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Pictures),`r`nVideo: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Video),`r`nFavorites: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Favorites),`r`nDownloads: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Downloads),`r`nApplicationData: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ApplicationData),`r`nOther Files and Folders: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Custom),`r`nExclude Roaming Profile: $($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ExcludeRoamingUsers)"))
                                                }
                                                $inObj.add($LocalizedData.backupFileSystemFiles, ($ABkjob.SelectedFilesOptions.BackupSelectedFiles))
                                                if ($Null -ne $ABkjob.SelectedFilesOptions.SelectedFiles) {
                                                    $inObj.add($LocalizedData.filesSystemPath, ($ABkjob.SelectedFilesOptions.SelectedFiles -join ', '))
                                                }
                                                if ('' -ne $ABkjob.SelectedFilesOptions.IncludeMask) {
                                                    $inObj.add($LocalizedData.filterFilesInclude, ($ABkjob.SelectedFilesOptions.IncludeMask))
                                                }
                                                if ('' -ne $ABkjob.SelectedFilesOptions.ExcludeMask) {
                                                    $inObj.add($LocalizedData.filterFilesExclude, ($ABkjob.SelectedFilesOptions.ExcludeMask))
                                                }
                                                if ($ABkjob.SelectedFilesOptions.BackupPersonalFiles -eq $TRUE) {
                                                    $inObj.add($LocalizedData.excludeOneDrive, ($ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ExcludeOneDrive))
                                                }
                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Agent Backup Jobs Backup Mode Section: $($_.Exception.Message)"
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeadingBackupMode) - $($ABkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Backup Mode Section: $($_.Exception.Message)"
                                }
                                try {
                                    if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                        $StorageTXT = $LocalizedData.SectionDestination
                                    } elseif ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                        $StorageTXT = $LocalizedData.SectionStorage
                                    }
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $StorageTXT {
                                        $OutObj = @()
                                        if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                            try {
                                                if ($ABkjob.RetentionType -eq 'RestoreDays') {
                                                    $RetainString = $LocalizedData.retainDaysToKeep
                                                    $Retains = $ABkjob.RetentionPolicy
                                                } elseif ($ABkjob.RetentionType -eq 'RestorePoints') {
                                                    $RetainString = $LocalizedData.retainPoints
                                                    $Retains = $ABkjob.RetentionPolicy
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                                    $DestinationType = $LocalizedData.veeamBackupRepository
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                                    $DestinationType = switch ($ABkjob.DestinationOptions.DestinationType) {
                                                        'BackupRepository' { $LocalizedData.veeamBackupRepository }
                                                        'LocalStorage' { $LocalizedData.localStorage }
                                                        'NetworkFolder' { $LocalizedData.sharedFolderDest }
                                                        default { $ABkjob.DestinationOptions.DestinationType }
                                                    }
                                                }
                                                if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                    $SecondaryJobRepo = $LocalizedData.yes
                                                } else { $SecondaryJobRepo = $LocalizedData.no }
                                                $inObj = [ordered] @{
                                                    $LocalizedData.destinationType = $DestinationType
                                                    $LocalizedData.retentionPolicy = switch ($ABkjob.RetentionType) {
                                                        'RestorePoints' { $LocalizedData.restorePoints }
                                                        'RestoreDays' { $LocalizedData.restoreDays }
                                                        default { $ABkjob.RetentionType }
                                                    }
                                                    $RetainString = $Retains
                                                    $LocalizedData.configureSecondaryDestination = $SecondaryJobRepo
                                                }
                                                if ($ABkjob.DestinationOptions.DestinationType -eq 'BackupRepository') {
                                                    $inObj.add($LocalizedData.backupServer, ($ABkjob.DestinationOptions.BackupServerName))
                                                    $inObj.add($LocalizedData.backupRepository, ($ABkjob.DestinationOptions.BackupRepository.Name))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'LocalStorage') {
                                                    $inObj.add($LocalizedData.localPath, ($ABkjob.DestinationOptions.LocalPath))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'NetworkFolder') {
                                                    $inObj.add($LocalizedData.sharedFolder, ($ABkjob.DestinationOptions.NetworkFolderPath))
                                                    $inObj.add($LocalizedData.targetShareType, ($ABkjob.DestinationOptions.TargetShareType))
                                                    $inObj.add($LocalizedData.useNetworkCredentials, ($ABkjob.DestinationOptions.UseNetworkCredentials))
                                                    if ($ABkjob.DestinationOptions.UseNetworkCredentials) {
                                                        $inObj.add($LocalizedData.credentials, ($ABkjob.DestinationOptions.NetworkCredentials.Name))
                                                    }
                                                }
                                                if ($ABkjob.GFSRetentionEnabled) {
                                                    $inObj.add($LocalizedData.gfsEnabled, ($ABkjob.GFSRetentionEnabled))
                                                    $inObj.add($LocalizedData.gfsWeekly, ("$($ABkjob.GFSOptions.WeeklyOptions.RetentionPeriod) weeks,`r`nIf multiple backup exist use the one from: $($ABkjob.GFSOptions.WeeklyOptions.SelectedDay)"))
                                                    $inObj.add($LocalizedData.gfsMonthly, ("$($ABkjob.GFSOptions.MonthlyOptions.RetentionPeriod) months,`r`nUse weekly full backup from the following week of the month: $($ABkjob.GFSOptions.MonthlyOptions.SelectedWeek)"))
                                                    $inObj.add($LocalizedData.gfsYearly, ("$($ABkjob.GFSOptions.YearlyOptions.RetentionPeriod) years,`r`nUse monthly full backup from the following month: $($ABkjob.GFSOptions.YearlyOptions.SelectedMonth)"))
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Destination Section: $($_.Exception.Message)"
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeadingDestination) - $($ABkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionSecondaryTarget {
                                                        $OutObj = @()
                                                        $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)
                                                        foreach ($SecondaryTarget in $SecondaryTargets) {
                                                            $inObj = [ordered] @{
                                                                $LocalizedData.jobName = $SecondaryTarget.Name
                                                                $LocalizedData.type = $SecondaryTarget.TypeToString
                                                                $LocalizedData.state = $SecondaryTarget.info.LatestStatus
                                                                $LocalizedData.description = $SecondaryTarget.Description
                                                            }
                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                        }

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHeadingSecondaryTarget) - $($ABkjob.Name)"
                                                            List = $false
                                                            ColumnWidths = 25, 25, 15, 35
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Secondary Target Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                            try {
                                                if ($ABkjob.RetentionType -eq 'RestoreDays') {
                                                    $RetainString = $LocalizedData.retainDaysToKeep
                                                    $Retains = $ABkjob.RetentionPolicy
                                                } elseif ($ABkjob.RetentionType -eq 'RestorePoints') {
                                                    $RetainString = $LocalizedData.retainRestorePoints
                                                    $Retains = $ABkjob.RetentionPolicy
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                                    $DestinationType = $LocalizedData.veeamBackupRepository
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                                    $DestinationType = switch ($ABkjob.DestinationOptions.DestinationType) {
                                                        'BackupRepository' { $LocalizedData.veeamBackupRepository }
                                                        'LocalStorage' { $LocalizedData.localStorage }
                                                        'NetworkFolder' { $LocalizedData.sharedFolderDest }
                                                        default { $ABkjob.DestinationOptions.DestinationType }
                                                    }
                                                }
                                                if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                    $SecondaryJobRepo = $LocalizedData.yes
                                                } else { $SecondaryJobRepo = $LocalizedData.no }
                                                $inObj = [ordered] @{
                                                    $LocalizedData.backupRepository = $ABkjob.BackupRepository.Name
                                                    $LocalizedData.repositoryType = $ABkjob.BackupRepository.Type
                                                    $LocalizedData.retentionPolicy = switch ($ABkjob.RetentionType) {
                                                        'RestorePoints' { $LocalizedData.restorePoints }
                                                        'RestoreDays' { $LocalizedData.restoreDays }
                                                        default { $ABkjob.RetentionType }
                                                    }
                                                    $RetainString = $Retains
                                                    $LocalizedData.configureSecondaryDestination = $SecondaryJobRepo
                                                }
                                                if ($ABkjob.DestinationOptions.DestinationType -eq 'BackupRepository') {
                                                    $inObj.add($LocalizedData.backupServer, ($ABkjob.DestinationOptions.BackupServerName))
                                                    $inObj.add($LocalizedData.backupRepository, ($ABkjob.DestinationOptions.BackupRepository.Name))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'LocalStorage') {
                                                    $inObj.add($LocalizedData.localPath, ($ABkjob.DestinationOptions.LocalPath))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'NetworkFolder') {
                                                    $inObj.add($LocalizedData.sharedFolder, ($ABkjob.DestinationOptions.NetworkFolderPath))
                                                    $inObj.add($LocalizedData.targetShareType, ($ABkjob.DestinationOptions.TargetShareType))
                                                    $inObj.add($LocalizedData.useNetworkCredentials, ($ABkjob.DestinationOptions.UseNetworkCredentials))
                                                    if ($ABkjob.DestinationOptions.UseNetworkCredentials) {
                                                        $inObj.add($LocalizedData.credentials, ($ABkjob.DestinationOptions.NetworkCredentials.Name))
                                                    }
                                                }
                                                if ($ABkjob.GFSRetentionEnabled) {
                                                    $inObj.add($LocalizedData.gfsEnabled, ($ABkjob.GFSRetentionEnabled))
                                                    $inObj.add($LocalizedData.gfsWeekly, ("$($ABkjob.GFSOptions.WeeklyOptions.RetentionPeriod) weeks,`r`nIf multiple backup exist use the one from: $($ABkjob.GFSOptions.WeeklyOptions.SelectedDay)"))
                                                    $inObj.add($LocalizedData.gfsMonthly, ("$($ABkjob.GFSOptions.MonthlyOptions.RetentionPeriod) months,`r`nUse weekly full backup from the following week of the month: $($ABkjob.GFSOptions.MonthlyOptions.SelectedWeek)"))
                                                    $inObj.add($LocalizedData.gfsYearly, ("$($ABkjob.GFSOptions.YearlyOptions.RetentionPeriod) years,`r`nUse monthly full backup from the following month: $($ABkjob.GFSOptions.YearlyOptions.SelectedMonth)"))
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Destination Section: $($_.Exception.Message)"
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeadingDestination) - $($ABkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionSecondaryTarget {
                                                        $OutObj = @()
                                                        $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)
                                                        foreach ($SecondaryTarget in $SecondaryTargets) {
                                                            $inObj = [ordered] @{
                                                                $LocalizedData.jobName = $SecondaryTarget.Name
                                                                $LocalizedData.type = $SecondaryTarget.TypeToString
                                                                $LocalizedData.state = $SecondaryTarget.info.LatestStatus
                                                                $LocalizedData.description = $SecondaryTarget.Description
                                                            }
                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                        }

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHeadingSecondaryTarget) - $($ABkjob.Name)"
                                                            List = $false
                                                            ColumnWidths = 25, 25, 15, 35
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Secondary Target Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($InfoLevel.Jobs.Agent -ge 2) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvBackup {
                                                    $OutObj = @()
                                                    try {
                                                        $inObj = [ordered] @{
                                                            $LocalizedData.syntheticFullBackup = $ABkjob.SyntheticFullOptions.Enabled
                                                        }
                                                        if ($ABkjob.SyntheticFullOptions.Enabled) {
                                                            $inObj.add($LocalizedData.createSyntheticOnDays, $ABkjob.SyntheticFullOptions.Days -join ', ')
                                                        }
                                                        $inObj += [ordered] @{
                                                            $LocalizedData.activeFullBackup = $ABkjob.ActiveFullOptions.Enabled
                                                        }
                                                        if ($ABkjob.ActiveFullOptions.ScheduleType -eq 'Weekly' -and $ABkjob.ActiveFullOptions.Enabled) {
                                                            $inObj.add($LocalizedData.activeFullBackupScheduleType, $ABkjob.ActiveFullOptions.ScheduleType)
                                                            $inObj.add($LocalizedData.activeFullBackupDays, $ABkjob.ActiveFullOptions.SelectedDays -join ',')
                                                        }
                                                        if ($ABkjob.ActiveFullOptions.ScheduleType -eq 'Monthly' -and $ABkjob.ActiveFullOptions.Enabled) {
                                                            $inObj.add($LocalizedData.activeFullBackupScheduleType, $ABkjob.ActiveFullOptions.ScheduleType)
                                                            $inObj.add($LocalizedData.activeFullBackupMonthlyOn, "Day Number In Month: $($ABkjob.ActiveFullOptions.DayNumber)`r`nDay Of Week: $($ABkjob.ActiveFullOptions.DayOfWeek)`r`nDay of Month: $($ABkjob.ActiveFullOptions.DayOfMonth)`r`nMonths: $($ABkjob.ActiveFullOptions.SelectedMonths)")
                                                        }

                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHeadingAdvBackup) - $($ABkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Backup) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Backup) Section: $($_.Exception.Message)"
                                            }
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvMaintenance {
                                                    $OutObj = @()
                                                    try {
                                                        $inObj = [ordered] @{
                                                            $LocalizedData.slcg = $ABkjob.HealthCheckOptions.Enabled
                                                        }
                                                        if ($ABkjob.HealthCheckOptions.Enabled) {
                                                            $inObj.add($LocalizedData.slcgScheduleType, $ABkjob.HealthCheckOptions.ScheduleType)
                                                            $inObj.add($LocalizedData.slcgScheduleDay, $ABkjob.HealthCheckOptions.SelectedDays)
                                                        }
                                                        if ($ABkjob.HealthCheckOptions.ScheduleType -ne 'Weekly' -and $ABkjob.HealthCheckOptions.Enabled) {
                                                            $inObj.add($LocalizedData.slcgMonthlySchedule, "Day Of Week: $($ABkjob.HealthCheckOptions.DayOfWeek)`r`nDay Number In Month: $($ABkjob.HealthCheckOptions.DayNumber)`r`nDay of Month: $($ABkjob.HealthCheckOptions.DayOfMonth)`r`nMonths: $($ABkjob.HealthCheckOptions.SelectedMonths)")
                                                        }

                                                        $inObj += [ordered] @{
                                                            $LocalizedData.dcfb = $ABkjob.CompactFullOptions.Enabled
                                                        }
                                                        if ($ABkjob.CompactFullOptions.Enabled) {
                                                            $inObj.add($LocalizedData.dcfbScheduleType, $ABkjob.CompactFullOptions.ScheduleType)
                                                            $inObj.add($LocalizedData.dcfbScheduleDay, $ABkjob.CompactFullOptions.SelectedDays)
                                                        }
                                                        if ($ABkjob.CompactFullOptions.ScheduleType -ne 'Weekly' -and $ABkjob.CompactFullOptions.Enabled) {
                                                            $inObj.add($LocalizedData.dcfbMonthlySchedule, "Day Of Week: $($ABkjob.CompactFullOptions.DayOfWeek)`r`nDay Number In Month: $($ABkjob.CompactFullOptions.DayNumber)`r`nDay of Month: $($ABkjob.CompactFullOptions.DayOfMonth)`r`nMonths: $($ABkjob.CompactFullOptions.SelectedMonths)")
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        if ($HealthCheck.Jobs.BestPractice) {
                                                            $OutObj | Where-Object { $_.$($LocalizedData.slcg) -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.slcg
                                                        }

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHeadingAdvMaintenance) - $($ABkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                        if ($HealthCheck.Jobs.BestPractice) {
                                                            if ($OutObj | Where-Object { $_.$($LocalizedData.slcg) -eq 'No' }) {
                                                                Paragraph $LocalizedData.healthCheck -Bold -Underline
                                                                BlankLine
                                                                Paragraph {
                                                                    Text $LocalizedData.bestPractice -Bold
                                                                    Text $LocalizedData.healthCheckSLCGText
                                                                }
                                                                BlankLine
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Maintenance) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning Write-PscriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Maintenance) Section: $($_.Exception.Message)"
                                            }
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvStorage {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.compressionLevel = $ABkjob.StorageOptions.CompressionLevel
                                                        $LocalizedData.storageOptimization = $ABkjob.StorageOptions.StorageOptimizationType
                                                        $LocalizedData.enabledBackupFileEncryption = $ABkjob.StorageOptions.EncryptionEnabled
                                                        $LocalizedData.encryptionKey = switch ($ABkjob.StorageOptions.EncryptionEnabled) {
                                                            $false { $LocalizedData.none }
                                                            default { (Get-VBREncryptionKey | Where-Object { $_.id -eq $ABkjob.StorageOptions.EncryptionKey.Id }).Description }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.enabledBackupFileEncryption) -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.enabledBackupFileEncryption
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvStorage) - $($ABkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        if ($OutObj | Where-Object { $_.$($LocalizedData.enabledBackupFileEncryption) -eq 'No' }) {
                                                            Paragraph $LocalizedData.healthCheck -Bold -Underline
                                                            BlankLine
                                                            Paragraph {
                                                                Text $LocalizedData.bestPractice -Bold
                                                                Text $LocalizedData.healthCheckEncryptionText
                                                            }
                                                            BlankLine
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Storage) Section: $($_.Exception.Message)"
                                            }
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvNotification {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.sendSnmpNotification = $ABkjob.NotificationOptions.EnableSnmpNotification
                                                        $LocalizedData.sendEmailNotification = $ABkjob.NotificationOptions.EnableAdditionalNotification
                                                    }
                                                    if ($ABkjob.NotificationOptions.EnableAdditionalNotification) {
                                                        $inObj.add($LocalizedData.emailAdditionalAddresses, $ABkjob.NotificationOptions.AdditionalAddress)
                                                        $inObj.add($LocalizedData.useCustomEmailNotification, ($ABkjob.NotificationOptions.UseNotificationOptions))
                                                        $inObj.add($LocalizedData.useCustomNotificationSetting, $ABkjob.NotificationOptions.NotificationSubject)
                                                        $inObj.add($LocalizedData.notifyOnSuccess, ($ABkjob.NotificationOptions.NotifyOnSuccess))
                                                        $inObj.add($LocalizedData.notifyOnWarning, ($ABkjob.NotificationOptions.NotifyOnWarning))
                                                        $inObj.add($LocalizedData.notifyOnError, ($ABkjob.NotificationOptions.NotifyOnError))
                                                        $inObj.add($LocalizedData.suppressNotification, ($ABkjob.NotificationOptions.NotifyOnLastRetryOnly))
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingAdvNotification) - $($ABkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Notification) Section: $($_.Exception.Message)"
                                            }
                                            if ($ABkjob.Mode -eq 'ManagedByBackupServer' -and $ABkjob.OSPlatform -eq 'Windows') {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvIntegration {
                                                        $OutObj = @()

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.enableBackupFromStorage = $ABkjob.SanIntegrationOptions.SanSnapshotsEnabled
                                                        }
                                                        if ($ABkjob.SanIntegrationOptions.SanSnapshotsEnabled) {
                                                            $inObj.add($LocalizedData.failoverToOnHostAgent, ($ABkjob.SanIntegrationOptions.FailoverFromSanEnabled))
                                                            $inObj.add($LocalizedData.offHostProxyAutoSelect, ($ABkjob.SanIntegrationOptions.SanProxyAutodetectEnabled))
                                                        }
                                                        if (!$ABkjob.SanIntegrationOptions.SanProxyAutodetectEnabled) {
                                                            $inObj.add($LocalizedData.offHostProxyServer, $ABkjob.SanIntegrationOptions.Proxy.Server.Name)
                                                        }
                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHeadingAdvIntegration) - $($ABkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Integration) Section: $($_.Exception.Message)"
                                                }
                                            }
                                            if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionAdvScript {
                                                        $OutObj = @()
                                                        if ($ABkjob.ScriptOptions.Periodicity -eq 'Days') {
                                                            $FrequencyValue = $ABkjob.ScriptOptions.Day -join ','
                                                            $FrequencyText = $LocalizedData.runScriptOnSelectedDays
                                                        } elseif ($ABkjob.ScriptOptions.Periodicity -eq 'Cycles') {
                                                            $FrequencyValue = $ABkjob.ScriptOptions.Frequency
                                                            $FrequencyText = $LocalizedData.runScriptEverySession
                                                        }

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.runScriptBefore = $ABkjob.ScriptOptions.PreScriptEnabled
                                                        }
                                                        $inObj += [ordered] @{
                                                            $LocalizedData.runScriptAfter = $ABkjob.ScriptOptions.PostScriptEnabled
                                                        }
                                                        if ($ABkjob.ScriptOptions.PreScriptEnabled) {
                                                            $inObj.add($LocalizedData.runScriptBeforeJob, $ABkjob.ScriptOptions.PreCommand)
                                                        }
                                                        if ($ABkjob.ScriptOptions.PostScriptEnabled) {
                                                            $inObj.add($LocalizedData.runScriptAfterJob, $ABkjob.ScriptOptions.PostCommand)
                                                        }
                                                        if ($ABkjob.ScriptOptions.PreScriptEnabled -or $ABkjob.ScriptOptions.PostScriptEnabled) {
                                                            $inObj.add($LocalizedData.runScriptFrequency, $ABkjob.ScriptOptions.Periodicity)
                                                            $inObj.add($FrequencyText, $FrequencyValue)
                                                        }
                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TableHeadingAdvScript) - $($ABkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Script) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    }
                                    if ($ABkjob.ApplicationProcessingEnabled -or $ABkjob.IndexingEnabled) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionGuestProcessing {
                                            $OutObj = @()
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.enabledAppProcessing = $ABkjob.ApplicationProcessingEnabled
                                                    $LocalizedData.enabledGuestIndexing = $ABkjob.IndexingEnabled
                                                }

                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.TableHeadingGuestProcessing) - $($ABkjob.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Guest Processing) Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                    if ($ABkjob.ScheduleEnabled) {
                                        if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionSchedule {
                                                $OutObj = @()
                                                try {

                                                    if ($ABkjob.ScheduleOptions.Type -eq 'Daily') {
                                                        $ScheduleType = $LocalizedData.daily
                                                        $Schedule = "Recurrence: $($ABkjob.ScheduleOptions.DailyOptions.Type),`r`nDays: $($ABkjob.ScheduleOptions.DailyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq 'Monthly') {
                                                        $ScheduleType = $LocalizedData.monthly
                                                        $Schedule = "Day Of Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nDay Number In Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq 'Periodically') {
                                                        $ScheduleType = $ABkjob.ScheduleOptions.PeriodicallyOptions.PeriodicallyKind
                                                        $Schedule = "Full Period: $($ABkjob.ScheduleOptions.PeriodicallyOptions.FullPeriod),`r`nHourly Offset: $($ABkjob.ScheduleOptions.PeriodicallyOptions.HourlyOffset)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq 'AfterJob') {
                                                        $ScheduleType = $LocalizedData.afterJob
                                                        $Schedule = $ABkjob.ScheduleOptions.Job.Name
                                                    }
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.retryFailedItem = $ABkjob.ScheduleOptions.RetryCount
                                                        $LocalizedData.waitBeforeRetry = "$($ABkjob.ScheduleOptions.RetryTimeout)/min"
                                                        $LocalizedData.backupWindow = $ABkjob.ScheduleOptions.BackupTerminationWindowEnabled
                                                        $LocalizedData.scheduleType = $ScheduleType
                                                        $LocalizedData.scheduleOptions = $Schedule
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingSchedule) - $($ABkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($ABkjob.ScheduleOptions.BackupTerminationWindowEnabled) {
                                                        try {
                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SectionBackupWindowTimePeriod {
                                                                Paragraph -ScriptBlock $Legend

                                                                $OutObj = Get-WindowsTimePeriod -InputTimePeriod $ABkjob.ScheduleOptions.TerminationWindow

                                                                $TableParams = @{
                                                                    Name = "$($LocalizedData.TableHeadingBackupWindow) - $($ABkjob.Name)"
                                                                    List = $true
                                                                    ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                                    Key = 'H'
                                                                }
                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                if ($OutObj) {
                                                                    $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                                    $OutObj2.Rows | Where-Object { $_.Sun -eq '0' } | Set-Style -Style OFF -Property 'Sun'
                                                                    $OutObj2.Rows | Where-Object { $_.Mon -eq '0' } | Set-Style -Style OFF -Property 'Mon'
                                                                    $OutObj2.Rows | Where-Object { $_.Tue -eq '0' } | Set-Style -Style OFF -Property 'Tue'
                                                                    $OutObj2.Rows | Where-Object { $_.Wed -eq '0' } | Set-Style -Style OFF -Property 'Wed'
                                                                    $OutObj2.Rows | Where-Object { $_.Thu -eq '0' } | Set-Style -Style OFF -Property 'Thu'
                                                                    $OutObj2.Rows | Where-Object { $_.Fri -eq '0' } | Set-Style -Style OFF -Property 'Fri'
                                                                    $OutObj2.Rows | Where-Object { $_.Sat -eq '0' } | Set-Style -Style OFF -Property 'Sat'

                                                                    $OutObj2.Rows | Where-Object { $_.Sun -eq '1' } | Set-Style -Style ON -Property 'Sun'
                                                                    $OutObj2.Rows | Where-Object { $_.Mon -eq '1' } | Set-Style -Style ON -Property 'Mon'
                                                                    $OutObj2.Rows | Where-Object { $_.Tue -eq '1' } | Set-Style -Style ON -Property 'Tue'
                                                                    $OutObj2.Rows | Where-Object { $_.Wed -eq '1' } | Set-Style -Style ON -Property 'Wed'
                                                                    $OutObj2.Rows | Where-Object { $_.Thu -eq '1' } | Set-Style -Style ON -Property 'Thu'
                                                                    $OutObj2.Rows | Where-Object { $_.Fri -eq '1' } | Set-Style -Style ON -Property 'Fri'
                                                                    $OutObj2.Rows | Where-Object { $_.Sat -eq '1' } | Set-Style -Style ON -Property 'Sat'
                                                                    $OutObj2
                                                                }
                                                            }
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning $_.Exception.Message
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Schedule Options) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($ABkjob.BackupCacheOptions.Enabled) {
                                            try {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionBackupCache {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.maximumSize = "$($ABkjob.BackupCacheOptions.SizeLimit) $($ABkjob.BackupCacheOptions.SizeUnit)"
                                                        $LocalizedData.type = $ABkjob.BackupCacheOptions.Type
                                                        $LocalizedData.path = switch ($ABkjob.BackupCacheOptions.Type) {
                                                            'Automatic' { $LocalizedData.autoSelected }
                                                            default { $ABkjob.BackupCacheOptions.LocalPath }
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingBackupCache) - $($ABkjob.Name)"
                                                        List = $false
                                                        ColumnWidths = 33, 33, 34
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Backup Cache) Section: $($_.Exception.Message)"
                                            }
                                        }
                                        if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SectionSchedule {
                                                $OutObj = @()
                                                try {

                                                    if ($ABkjob.ScheduleOptions.DailyScheduleEnabled) {
                                                        $ScheduleType = $LocalizedData.daily
                                                        $Schedule = "Recurrence: $($ABkjob.ScheduleOptions.DailyOptions.Type),`r`nDays: $($ABkjob.ScheduleOptions.DailyOptions.DayOfWeek)r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    }

                                                    if ($ABkjob.ScheduleOptions.Type -eq 'Daily') {
                                                        $ScheduleType = $LocalizedData.daily
                                                        $Schedule = "Recurrence: $($ABkjob.ScheduleOptions.DailyOptions.Type),`r`nDays: $($ABkjob.ScheduleOptions.DailyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq 'Monthly') {
                                                        $ScheduleType = $LocalizedData.monthly
                                                        $Schedule = "Day Of Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nDay Number In Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq 'Periodically') {
                                                        $ScheduleType = $ABkjob.ScheduleOptions.PeriodicallyOptions.PeriodicallyKind
                                                        $Schedule = "Full Period: $($ABkjob.ScheduleOptions.PeriodicallyOptions.FullPeriod),`r`nHourly Offset: $($ABkjob.ScheduleOptions.PeriodicallyOptions.HourlyOffset)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq 'AfterJob') {
                                                        $ScheduleType = $LocalizedData.afterJob
                                                        $Schedule = $ABkjob.ScheduleOptions.Job.Name
                                                    }

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.scheduleType = $ScheduleType
                                                        $LocalizedData.scheduleOptions = $Schedule
                                                        $LocalizedData.powerOffAction = switch ($ABkjob.ScheduleOptions.PowerOffAction) {
                                                            $null { '--' }
                                                            'SkipBackup' { $LocalizedData.skipBackup }
                                                            'BackupAtPowerOn' { $LocalizedData.backupAtPowerOn }
                                                            default { $ABkjob.ScheduleOptions.PowerOffAction }
                                                        }
                                                        $LocalizedData.onceBackupTaken = switch ($ABkjob.ScheduleOptions.PostBackupAction) {
                                                            $null { '--' }
                                                            'KeepRunning' { $LocalizedData.keepRunning }
                                                            default { $ABkjob.ScheduleOptions.PostBackupAction }
                                                        }
                                                        $LocalizedData.backupAtLogOff = $ABkjob.ScheduleOptions.BackupAtLogOff
                                                        $LocalizedData.backupAtLock = $ABkjob.ScheduleOptions.BackupAtLock
                                                        $LocalizedData.backupAtTargetConnection = $ABkjob.ScheduleOptions.BackupAtTargetConnection
                                                        $LocalizedData.ejectStorageAfterBackup = $ABkjob.ScheduleOptions.EjectStorageAfterBackup
                                                        $LocalizedData.backupTimeout = switch ([string]::IsNullOrEmpty($ABkjob.ScheduleOptions.BackupTimeout)) {
                                                            $true { '--' }
                                                            $false { "$($ABkjob.ScheduleOptions.BackupTimeout) $($ABkjob.ScheduleOptions.BackupTimeoutType)" }
                                                            default { $LocalizedData.unknown }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeadingSchedule) - $($ABkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Schedule Options) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Section: $($_.Exception.Message)"
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Agent Backup Jobs Configuration Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Agent Backup Jobs Configuration Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Agent Backup Jobs'
    }

}
