
function Get-AbrVbrAgentBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns computer backup jobs configuration created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.7
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
    }

    process {
        try {
            if ($ABkjobs = Get-VBRComputerBackupJob | Sort-Object -Property Name) {
                Section -Style Heading3 'Agent Backup Jobs Configuration' {
                    Paragraph "The following section details agent backup jobs configuration created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    foreach ($ABkjob in $ABkjobs) {
                        try {
                            Section -Style Heading4 $($ABkjob.Name) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Job Mode' {
                                    $OutObj = @()
                                    try {
                                        Write-PScriboMessage "Discovered $($ABkjob.Name) common information."
                                        $inObj = [ordered] @{
                                            'Name' = $ABkjob.Name
                                            'Id' = $ABkjob.Id
                                            'Type' = $ABkjob.Type
                                            'Mode' = Switch ($ABkjob.Mode) {
                                                'ManagedByBackupServer' { 'Managed by Backup Server' }
                                                'ManagedByAgent' { 'Managed by Agent' }
                                                default { $ABkjob.Mode }
                                            }
                                            'Description' = $ABkjob.Description
                                            'Priority' = Switch ($ABkjob.IsHighPriority) {
                                                'True' { 'High Priority' }
                                                'False' { 'Normal Priority' }
                                            }
                                        }
                                        $OutObj = [pscustomobject]$inobj

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $Null -like $_.'Description' } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                        }

                                        $TableParams = @{
                                            Name = "Job Mode - $($ABkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($HealthCheck.Jobs.BestPractice) {
                                            if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $Null -like $_.'Description' }) {
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
                                        Write-PScriboMessage -IsWarning "Agent Backup Jobs Common Information Section: $($_.Exception.Message)"
                                    }
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Protected Computers' {
                                        $OutObj = @()
                                        foreach ($BackupObject in $ABkjob.BackupObject) {
                                            try {
                                                Write-PScriboMessage "Discovered $($BackupObject.Name) protected computer information."
                                                $inObj = [ordered] @{
                                                    'Name' = $BackupObject.Name
                                                    'Type' = SWitch ($BackupObject.Type) {
                                                        $Null { 'Computer' }
                                                        default { $BackupObject.Type }
                                                    }
                                                    'Enabled' = ConvertTo-TextYN $BackupObject.Enabled
                                                    'Container' = Switch ($BackupObject.Container) {
                                                        $Null { 'Individual Computer' }
                                                        'ActiveDirectory' { 'Active Directory' }
                                                        'ManuallyDeployed' { 'Manually Deployed' }
                                                        'IndividualComputers' { 'Individual Computers' }
                                                        default { $BackupObject.Container }
                                                    }
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Protected Computers Section: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "Protected Computers - $($ABkjob.Name)"
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
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Backup Mode' {
                                        $OutObj = @()
                                        try {
                                            Write-PScriboMessage "Discovered $($ABkjob.Name) backup mode information."
                                            $inObj = [ordered] @{
                                                'Backup Mode' = Switch ($ABkjob.BackupType) {
                                                    'EntireComputer' { 'Entire Computer' }
                                                    'SelectedVolumes' { 'Volume Level Backup' }
                                                    'SelectedFiles' { 'File Level Backup (slower)' }
                                                }
                                            }
                                            if ($ABkjob.BackupType -eq 'EntireComputer') {
                                                $inObj.add('Include external USB drives', (ConvertTo-TextYN $ABkjob.UsbDrivesIncluded))
                                            } elseif ($ABkjob.BackupType -eq 'SelectedVolumes') {
                                                if ($Null -ne $ABkjob.SelectedVolumes.Path) {
                                                    $inObj.add('Backup the following volumes only', ($ABkjob.SelectedVolumes.Path -join ', '))
                                                } elseif ($Null -ne $ABkjob.ExcludedVolumes.Path) {
                                                    $inObj.add('Backup all volumes except the following', ($ABkjob.ExcludedVolumes.Path -join ', '))
                                                }

                                            } elseif ($ABkjob.BackupType -eq 'SelectedFiles') {
                                                $inObj.add('Backup Operating System Files', (ConvertTo-TextYN $ABkjob.SelectedFilesOptions.BackupOS))
                                                $inObj.add('Backup Personal Files', (ConvertTo-TextYN $ABkjob.SelectedFilesOptions.BackupPersonalFiles))
                                                if ($ABkjob.SelectedFilesOptions.BackupPersonalFiles -eq $TRUE) {
                                                    $inObj.add('User Profile Folder to Backup', ("Desktop: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Desktop),`r`nDocuments: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Documents),`r`nPictures: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Pictures),`r`nVideo: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Video),`r`nFavorites: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Favorites),`r`nDownloads: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Downloads),`r`nApplicationData: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ApplicationData),`r`nOther Files and Folders: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Custom),`r`nExclude Roaming Profile: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ExcludeRoamingUsers)"))
                                                }
                                                $inObj.add('Backup File System Files', (ConvertTo-TextYN $ABkjob.SelectedFilesOptions.BackupSelectedFiles))
                                                if ($Null -ne $ABkjob.SelectedFilesOptions.SelectedFiles) {
                                                    $inObj.add('Files System Path', ($ABkjob.SelectedFilesOptions.SelectedFiles -join ', '))
                                                }
                                                if ('' -ne $ABkjob.SelectedFilesOptions.IncludeMask) {
                                                    $inObj.add('Filter Files (Include Mask)', ($ABkjob.SelectedFilesOptions.IncludeMask))
                                                }
                                                if ('' -ne $ABkjob.SelectedFilesOptions.ExcludeMask) {
                                                    $inObj.add('Filter Files (Exclude Mask)', ($ABkjob.SelectedFilesOptions.ExcludeMask))
                                                }
                                                if ($ABkjob.SelectedFilesOptions.BackupPersonalFiles -eq $TRUE) {
                                                    $inObj.add('Exclude Microsoft Onedrive Folders', (ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ExcludeOneDrive))
                                                }
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Agent Backup Jobs Backup Mode Section: $($_.Exception.Message)"
                                        }

                                        $TableParams = @{
                                            Name = "Backup Mode - $($ABkjob.Name)"
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
                                        $StorageTXT = 'Destination'
                                    } elseif ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                        $StorageTXT = 'Storage'
                                    }
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $StorageTXT {
                                        $OutObj = @()
                                        if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                            try {
                                                Write-PScriboMessage "Discovered $($ABkjob.Name) destination information."
                                                if ($ABkjob.RetentionType -eq "RestoreDays") {
                                                    $RetainString = 'Retain Days To Keep'
                                                    $Retains = $ABkjob.RetentionPolicy
                                                } elseif ($ABkjob.RetentionType -eq "RestorePoints") {
                                                    $RetainString = 'Retain Points'
                                                    $Retains = $ABkjob.RetentionPolicy
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                                    $DestinationType = 'Veeam Backup Repository'
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                                    $DestinationType = SWitch ($ABkjob.DestinationOptions.DestinationType) {
                                                        'BackupRepository' { 'Veeam Backup Repository' }
                                                        'LocalStorage' { 'Local Storage' }
                                                        'NetworkFolder' { 'Shared Folder' }
                                                        default { $ABkjob.DestinationOptions.DestinationType }
                                                    }
                                                }
                                                if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                    $SecondaryJobRepo = 'Yes'
                                                } else { $SecondaryJobRepo = 'No' }
                                                $inObj = [ordered] @{
                                                    'Destination Type' = $DestinationType
                                                    'Retention Policy' = Switch ($ABkjob.RetentionType) {
                                                        'RestorePoints' { 'Restore Points' }
                                                        'RestoreDays' { 'Restore Days' }
                                                        default { $ABkjob.RetentionType }
                                                    }
                                                    $RetainString = $Retains
                                                    'Configure Secondary Destination for this Job' = $SecondaryJobRepo
                                                }
                                                if ($ABkjob.DestinationOptions.DestinationType -eq 'BackupRepository') {
                                                    $inObj.add('Backup Server', ($ABkjob.DestinationOptions.BackupServerName))
                                                    $inObj.add('Backup Repository', ($ABkjob.DestinationOptions.BackupRepository.Name))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'LocalStorage') {
                                                    $inObj.add('Local Path', ($ABkjob.DestinationOptions.LocalPath))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'NetworkFolder') {
                                                    $inObj.add('Shared Folder', ($ABkjob.DestinationOptions.NetworkFolderPath))
                                                    $inObj.add('Target Share Type', ($ABkjob.DestinationOptions.TargetShareType))
                                                    $inObj.add('Use Network Credentials', (ConvertTo-TextYN $ABkjob.DestinationOptions.UseNetworkCredentials))
                                                    if ($ABkjob.DestinationOptions.UseNetworkCredentials) {
                                                        $inObj.add('Credentials', ($ABkjob.DestinationOptions.NetworkCredentials.Name))
                                                    }
                                                }
                                                if ($ABkjob.GFSRetentionEnabled) {
                                                    $inObj.add('Keep certain full backup longer for archival purposes (GFS)', (ConvertTo-TextYN $ABkjob.GFSRetentionEnabled))
                                                    $inObj.add('Keep Weekly full backup for', ("$($ABkjob.GFSOptions.WeeklyOptions.RetentionPeriod) weeks,`r`nIf multiple backup exist use the one from: $($ABkjob.GFSOptions.WeeklyOptions.SelectedDay)"))
                                                    $inObj.add('Keep Monthly full backup for', ("$($ABkjob.GFSOptions.MonthlyOptions.RetentionPeriod) months,`r`nUse weekly full backup from the following week of the month: $($ABkjob.GFSOptions.MonthlyOptions.SelectedWeek)"))
                                                    $inObj.add('Keep Yearly full backup for', ("$($ABkjob.GFSOptions.YearlyOptions.RetentionPeriod) years,`r`nUse monthly full backup from the following month: $($ABkjob.GFSOptions.YearlyOptions.SelectedMonth)"))
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Destination Section: $($_.Exception.Message)"
                                            }

                                            $TableParams = @{
                                                Name = "Destination - $($ABkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Secondary Target" {
                                                        $OutObj = @()
                                                        $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)
                                                        foreach ($SecondaryTarget in $SecondaryTargets) {
                                                            Write-PScriboMessage "Discovered $($ABkjob.Name) job secondary destination $($SecondaryTarget.Name)."
                                                            $inObj = [ordered] @{
                                                                'Job Name' = $SecondaryTarget.Name
                                                                'Type' = $SecondaryTarget.TypeToString
                                                                'State' = $SecondaryTarget.info.LatestStatus
                                                                'Description' = $SecondaryTarget.Description
                                                            }
                                                            $OutObj += [pscustomobject]$inobj
                                                        }

                                                        $TableParams = @{
                                                            Name = "Secondary Destination Job - $($ABkjob.Name)"
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
                                                Write-PScriboMessage "Discovered $($ABkjob.Name) destination information."
                                                if ($ABkjob.RetentionType -eq "RestoreDays") {
                                                    $RetainString = 'Retain Days To Keep'
                                                    $Retains = $ABkjob.RetentionPolicy
                                                } elseif ($ABkjob.RetentionType -eq "RestorePoints") {
                                                    $RetainString = 'Restore Points'
                                                    $Retains = $ABkjob.RetentionPolicy
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                                    $DestinationType = 'Veeam Backup Repository'
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                                    $DestinationType = SWitch ($ABkjob.DestinationOptions.DestinationType) {
                                                        'BackupRepository' { 'Veeam Backup Repository' }
                                                        'LocalStorage' { 'Local Storage' }
                                                        'NetworkFolder' { 'Shared Folder' }
                                                        default { $ABkjob.DestinationOptions.DestinationType }
                                                    }
                                                }
                                                if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                    $SecondaryJobRepo = 'Yes'
                                                } else { $SecondaryJobRepo = 'No' }
                                                $inObj = [ordered] @{
                                                    'Backup Repository' = $ABkjob.BackupRepository.Name
                                                    'Repository Type' = $ABkjob.BackupRepository.Type
                                                    'Retention Policy' = Switch ($ABkjob.RetentionType) {
                                                        'RestorePoints' { 'Restore Points' }
                                                        'RestoreDays' { 'Restore Days' }
                                                        default { $ABkjob.RetentionType }
                                                    }
                                                    $RetainString = $Retains
                                                    'Configure Secondary Destination for this Job' = $SecondaryJobRepo
                                                }
                                                if ($ABkjob.DestinationOptions.DestinationType -eq 'BackupRepository') {
                                                    $inObj.add('Backup Server', ($ABkjob.DestinationOptions.BackupServerName))
                                                    $inObj.add('Backup Repository', ($ABkjob.DestinationOptions.BackupRepository.Name))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'LocalStorage') {
                                                    $inObj.add('Local Path', ($ABkjob.DestinationOptions.LocalPath))
                                                } elseif ($ABkjob.DestinationOptions.DestinationType -eq 'NetworkFolder') {
                                                    $inObj.add('Shared Folder', ($ABkjob.DestinationOptions.NetworkFolderPath))
                                                    $inObj.add('Target Share Type', ($ABkjob.DestinationOptions.TargetShareType))
                                                    $inObj.add('Use Network Credentials', (ConvertTo-TextYN $ABkjob.DestinationOptions.UseNetworkCredentials))
                                                    if ($ABkjob.DestinationOptions.UseNetworkCredentials) {
                                                        $inObj.add('Credentials', ($ABkjob.DestinationOptions.NetworkCredentials.Name))
                                                    }
                                                }
                                                if ($ABkjob.GFSRetentionEnabled) {
                                                    $inObj.add('Keep certain full backup longer for archival purposes (GFS)', (ConvertTo-TextYN $ABkjob.GFSRetentionEnabled))
                                                    $inObj.add('Keep Weekly full backup for', ("$($ABkjob.GFSOptions.WeeklyOptions.RetentionPeriod) weeks,`r`nIf multiple backup exist use the one from: $($ABkjob.GFSOptions.WeeklyOptions.SelectedDay)"))
                                                    $inObj.add('Keep Monthly full backup for', ("$($ABkjob.GFSOptions.MonthlyOptions.RetentionPeriod) months,`r`nUse weekly full backup from the following week of the month: $($ABkjob.GFSOptions.MonthlyOptions.SelectedWeek)"))
                                                    $inObj.add('Keep Yearly full backup for', ("$($ABkjob.GFSOptions.YearlyOptions.RetentionPeriod) years,`r`nUse monthly full backup from the following month: $($ABkjob.GFSOptions.YearlyOptions.SelectedMonth)"))
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Destination Section: $($_.Exception.Message)"
                                            }

                                            $TableParams = @{
                                                Name = "Destination - $($ABkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if ([Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Secondary Target" {
                                                        $OutObj = @()
                                                        $SecondaryTargets = [Veeam.Backup.Core.CBackupJob]::GetSecondDestinationJobs($ABkjob.id)
                                                        foreach ($SecondaryTarget in $SecondaryTargets) {
                                                            Write-PScriboMessage "Discovered $($ABkjob.Name) job secondary destination $($SecondaryTarget.Name)."
                                                            $inObj = [ordered] @{
                                                                'Job Name' = $SecondaryTarget.Name
                                                                'Type' = $SecondaryTarget.TypeToString
                                                                'State' = $SecondaryTarget.info.LatestStatus
                                                                'Description' = $SecondaryTarget.Description
                                                            }
                                                            $OutObj += [pscustomobject]$inobj
                                                        }

                                                        $TableParams = @{
                                                            Name = "Secondary Destination Job - $($ABkjob.Name)"
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
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Backup)" {
                                                    $OutObj = @()
                                                    try {
                                                        Write-PScriboMessage "Discovered $($ABkjob.Name) backup options."

                                                        $inObj = [ordered] @{
                                                            'Syntethic Full Backup' = ConvertTo-TextYN $ABkjob.SyntheticFullOptions.Enabled
                                                        }
                                                        if ($ABkjob.SyntheticFullOptions.Enabled) {
                                                            $inObj.add('Create Syntethic on Days', $ABkjob.SyntheticFullOptions.Days -join ", ")
                                                        }
                                                        $inObj += [ordered] @{
                                                            'Active Full Backup' = ConvertTo-TextYN $ABkjob.ActiveFullOptions.Enabled
                                                        }
                                                        if ($ABkjob.ActiveFullOptions.ScheduleType -eq 'Weekly' -and $ABkjob.ActiveFullOptions.Enabled) {
                                                            $inObj.add('Active Full Backup Schedule Type', $ABkjob.ActiveFullOptions.ScheduleType)
                                                            $inObj.add('Active Full Backup Days', $ABkjob.ActiveFullOptions.SelectedDays -join ',')
                                                        }
                                                        if ($ABkjob.ActiveFullOptions.ScheduleType -eq 'Monthly' -and $ABkjob.ActiveFullOptions.Enabled) {
                                                            $inObj.add('Active Full Backup Schedule Type', $ABkjob.ActiveFullOptions.ScheduleType)
                                                            $inObj.add('Active Full Backup Monthly on', "Day Number In Month: $($ABkjob.ActiveFullOptions.DayNumber)`r`nDay Of Week: $($ABkjob.ActiveFullOptions.DayOfWeek)`r`nDay of Month: $($ABkjob.ActiveFullOptions.DayOfMonth)`r`nMonths: $($ABkjob.ActiveFullOptions.SelectedMonths)")
                                                        }

                                                        $OutObj += [pscustomobject]$inObj

                                                        $TableParams = @{
                                                            Name = "Advanced Settings (Backup) - $($ABkjob.Name)"
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
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Maintenance)" {
                                                    $OutObj = @()
                                                    try {
                                                        Write-PScriboMessage "Discovered $($ABkjob.Name) maintenance options."

                                                        $inObj = [ordered] @{
                                                            'Storage-Level Corruption Guard (SLCG)' = ConvertTo-TextYN $ABkjob.HealthCheckOptions.Enabled
                                                        }
                                                        if ($ABkjob.HealthCheckOptions.Enabled) {
                                                            $inObj.add('SLCG Schedule Type', $ABkjob.HealthCheckOptions.ScheduleType)
                                                            $inObj.add('SLCG Schedule Day', $ABkjob.HealthCheckOptions.SelectedDays)
                                                        }
                                                        if ($ABkjob.HealthCheckOptions.ScheduleType -ne 'Weekly' -and $ABkjob.HealthCheckOptions.Enabled) {
                                                            $inObj.add('SLCG Backup Monthly Schedule', "Day Of Week: $($ABkjob.HealthCheckOptions.DayOfWeek)`r`nDay Number In Month: $($ABkjob.HealthCheckOptions.DayNumber)`r`nDay of Month: $($ABkjob.HealthCheckOptions.DayOfMonth)`r`nMonths: $($ABkjob.HealthCheckOptions.SelectedMonths)")
                                                        }

                                                        $inObj += [ordered] @{
                                                            'Defragment and Compact Full Backup (DCFB)' = ConvertTo-TextYN $ABkjob.CompactFullOptions.Enabled
                                                        }
                                                        if ($ABkjob.CompactFullOptions.Enabled) {
                                                            $inObj.add('DCFB Schedule Type', $ABkjob.CompactFullOptions.ScheduleType)
                                                            $inObj.add('DCFB Schedule Day', $ABkjob.CompactFullOptions.SelectedDays)
                                                        }
                                                        if ($ABkjob.CompactFullOptions.ScheduleType -ne 'Weekly' -and $ABkjob.CompactFullOptions.Enabled) {
                                                            $inObj.add('DCFB Backup Monthly Schedule', "Day Of Week: $($ABkjob.CompactFullOptions.DayOfWeek)`r`nDay Number In Month: $($ABkjob.CompactFullOptions.DayNumber)`r`nDay of Month: $($ABkjob.CompactFullOptions.DayOfMonth)`r`nMonths: $($ABkjob.CompactFullOptions.SelectedMonths)")
                                                        }
                                                        $OutObj += [pscustomobject]$inObj

                                                        if ($HealthCheck.Jobs.BestPractice) {
                                                            $OutObj | Where-Object { $_.'Storage-Level Corruption Guard (SLCG)' -eq "No" } | Set-Style -Style Warning -Property 'Storage-Level Corruption Guard (SLCG)'
                                                        }

                                                        $TableParams = @{
                                                            Name = "Advanced Settings (Maintenance) - $($ABkjob.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                        if ($HealthCheck.Jobs.BestPractice) {
                                                            if ($OutObj | Where-Object { $_.'Storage-Level Corruption Guard (SLCG)' -eq 'No' }) {
                                                                Paragraph "Health Check:" -Bold -Underline
                                                                BlankLine
                                                                Paragraph {
                                                                    Text "Best Practice:" -Bold
                                                                    Text "It is recommended to use storage-level corruption guard for any backup job with no active full backups scheduled. Synthetic full backups are still 'incremental forever' and may suffer from corruption over time. Storage-level corruption guard was introduced to provide a greater level of confidence in integrity of the backups."
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
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Storage)" {
                                                    $OutObj = @()
                                                    Write-PScriboMessage "Discovered $($ABkjob.Name) storage options."
                                                    $inObj = [ordered] @{
                                                        'Compression Level' = $ABkjob.StorageOptions.CompressionLevel
                                                        'Storage optimization' = $ABkjob.StorageOptions.StorageOptimizationType
                                                        'Enabled Backup File Encryption' = ConvertTo-TextYN $ABkjob.StorageOptions.EncryptionEnabled
                                                        'Encryption Key' = Switch ($ABkjob.StorageOptions.EncryptionEnabled) {
                                                            $false { 'None' }
                                                            default { (Get-VBREncryptionKey | Where-Object { $_.id -eq $ABkjob.StorageOptions.EncryptionKey.Id }).Description }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    if ($HealthCheck.Jobs.BestPractice) {
                                                        $OutObj | Where-Object { $_.'Enabled Backup File Encryption' -eq 'No' } | Set-Style -Style Warning -Property 'Enabled Backup File Encryption'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Storage) - $($ABkjob.Name)"
                                                        List = $true
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
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Agent Backup Jobs Advanced Settings (Storage) Section: $($_.Exception.Message)"
                                            }
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Notification)" {
                                                    $OutObj = @()
                                                    Write-PScriboMessage "Discovered $($ABkjob.Name) notification options."
                                                    $inObj = [ordered] @{
                                                        'Send Snmp Notification' = ConvertTo-TextYN $ABkjob.NotificationOptions.EnableSnmpNotification
                                                        'Send Email Notification' = ConvertTo-TextYN $ABkjob.NotificationOptions.EnableAdditionalNotification
                                                    }
                                                    if ($ABkjob.NotificationOptions.EnableAdditionalNotification) {
                                                        $inObj.add('Email Notification Additional Addresses', $ABkjob.NotificationOptions.AdditionalAddress)
                                                        $inObj.add('Use Custom Email Notification Options', (ConvertTo-TextYN $ABkjob.NotificationOptions.UseNotificationOptions))
                                                        $inObj.add('Use Custom Notification Setting', $ABkjob.NotificationOptions.NotificationSubject)
                                                        $inObj.add('Notify On Success', (ConvertTo-TextYN $ABkjob.NotificationOptions.NotifyOnSuccess))
                                                        $inObj.add('Notify On Warning', (ConvertTo-TextYN $ABkjob.NotificationOptions.NotifyOnWarning))
                                                        $inObj.add('Notify On Error', (ConvertTo-TextYN $ABkjob.NotificationOptions.NotifyOnError))
                                                        $inObj.add('Suppress Notification until Last Retry', (ConvertTo-TextYN $ABkjob.NotificationOptions.NotifyOnLastRetryOnly))
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Advanced Settings (Notification) - $($ABkjob.Name)"
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
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Integration)" {
                                                        $OutObj = @()
                                                        Write-PScriboMessage "Discovered $($ABkjob.Name) Integration options."
                                                        $inObj = [ordered] @{
                                                            'Enable Backup from Storage Snapshots' = ConvertTo-TextYN $ABkjob.SanIntegrationOptions.SanSnapshotsEnabled
                                                        }
                                                        if ($ABkjob.SanIntegrationOptions.SanSnapshotsEnabled) {
                                                            $inObj.add('Failover to On-Host Backup agent', (ConvertTo-TextYN $ABkjob.SanIntegrationOptions.FailoverFromSanEnabled))
                                                            $inObj.add('Off-host Backup Proxy Automatic Selection', (ConvertTo-TextYN $ABkjob.SanIntegrationOptions.SanProxyAutodetectEnabled))
                                                        }
                                                        if (!$ABkjob.SanIntegrationOptions.SanProxyAutodetectEnabled) {
                                                            $inObj.add('Off-host Backup Proxy Server', $ABkjob.SanIntegrationOptions.Proxy.Server.Name)
                                                        }
                                                        $OutObj = [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Advanced Settings (Integration) - $($ABkjob.Name)"
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
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "Advanced Settings (Script)" {
                                                        $OutObj = @()
                                                        if ($ABkjob.ScriptOptions.Periodicity -eq 'Days') {
                                                            $FrequencyValue = $ABkjob.ScriptOptions.Day -join ","
                                                            $FrequencyText = 'Run Script on the Selected Days'
                                                        } elseif ($ABkjob.ScriptOptions.Periodicity -eq 'Cycles') {
                                                            $FrequencyValue = $ABkjob.ScriptOptions.Frequency
                                                            $FrequencyText = 'Run Script Every Backup Session'
                                                        }
                                                        Write-PScriboMessage "Discovered $($ABkjob.Name) script options."
                                                        $inObj = [ordered] @{
                                                            'Run the Following Script Before' = ConvertTo-TextYN $ABkjob.ScriptOptions.PreScriptEnabled
                                                        }
                                                        $inObj += [ordered] @{
                                                            'Run the Following Script After' = ConvertTo-TextYN $ABkjob.ScriptOptions.PostScriptEnabled
                                                        }
                                                        if ($ABkjob.ScriptOptions.PreScriptEnabled) {
                                                            $inObj.add('Run Script Before the Job', $ABkjob.ScriptOptions.PreCommand)
                                                        }
                                                        if ($ABkjob.ScriptOptions.PostScriptEnabled) {
                                                            $inObj.add('Run Script After the Job', $ABkjob.ScriptOptions.PostCommand)
                                                        }
                                                        if ($ABkjob.ScriptOptions.PreScriptEnabled -or $ABkjob.ScriptOptions.PostScriptEnabled) {
                                                            $inObj.add('Run Script Frequency', $ABkjob.ScriptOptions.Periodicity)
                                                            $inObj.add($FrequencyText, $FrequencyValue)
                                                        }
                                                        $OutObj = [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Advanced Settings (Script) - $($ABkjob.Name)"
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC "Guest Processing" {
                                            $OutObj = @()
                                            try {
                                                Write-PScriboMessage "Discovered $($ABkjob.Name) guest processing."
                                                $inObj = [ordered] @{
                                                    'Enabled Application Process Processing' = ConvertTo-TextYN $ABkjob.ApplicationProcessingEnabled
                                                    'Enabled Guest File System Indexing' = ConvertTo-TextYN $ABkjob.IndexingEnabled
                                                }

                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Guest Processing Options - $($ABkjob.Name)"
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
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($ABkjob.Name) schedule options."
                                                    if ($ABkjob.ScheduleOptions.Type -eq "Daily") {
                                                        $ScheduleType = "Daily"
                                                        $Schedule = "Recurrence: $($ABkjob.ScheduleOptions.DailyOptions.Type),`r`nDays: $($ABkjob.ScheduleOptions.DailyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq "Monthly") {
                                                        $ScheduleType = "Monthly"
                                                        $Schedule = "Day Of Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nDay Number In Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq "Periodically") {
                                                        $ScheduleType = $ABkjob.ScheduleOptions.PeriodicallyOptions.PeriodicallyKind
                                                        $Schedule = "Full Period: $($ABkjob.ScheduleOptions.PeriodicallyOptions.FullPeriod),`r`nHourly Offset: $($ABkjob.ScheduleOptions.PeriodicallyOptions.HourlyOffset)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq "AfterJob") {
                                                        $ScheduleType = 'After Job'
                                                        $Schedule = $ABkjob.ScheduleOptions.Job.Name
                                                    }
                                                    $inObj = [ordered] @{
                                                        'Retry Failed item' = $ABkjob.ScheduleOptions.RetryCount
                                                        'Wait before each retry' = "$($ABkjob.ScheduleOptions.RetryTimeout)/min"
                                                        'Backup Window' = ConvertTo-TextYN $ABkjob.ScheduleOptions.BackupTerminationWindowEnabled
                                                        'Schedule type' = $ScheduleType
                                                        'Schedule Options' = $Schedule
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Schedule Options - $($ABkjob.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($ABkjob.ScheduleOptions.BackupTerminationWindowEnabled) {
                                                        try {
                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "Backup Window Time Period" {
                                                                Paragraph -ScriptBlock $Legend

                                                                $OutObj = Get-WindowsTimePeriod -InputTimePeriod $ABkjob.ScheduleOptions.TerminationWindow

                                                                $TableParams = @{
                                                                    Name = "Backup Window - $($ABkjob.Name)"
                                                                    List = $true
                                                                    ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                                    Key = 'H'
                                                                }
                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                if ($OutObj) {
                                                                    $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                                    $OutObj2.Rows | Where-Object { $_.Sun -eq "0" } | Set-Style -Style OFF -Property "Sun"
                                                                    $OutObj2.Rows | Where-Object { $_.Mon -eq "0" } | Set-Style -Style OFF -Property "Mon"
                                                                    $OutObj2.Rows | Where-Object { $_.Tue -eq "0" } | Set-Style -Style OFF -Property "Tue"
                                                                    $OutObj2.Rows | Where-Object { $_.Wed -eq "0" } | Set-Style -Style OFF -Property "Wed"
                                                                    $OutObj2.Rows | Where-Object { $_.Thu -eq "0" } | Set-Style -Style OFF -Property "Thu"
                                                                    $OutObj2.Rows | Where-Object { $_.Fri -eq "0" } | Set-Style -Style OFF -Property "Fri"
                                                                    $OutObj2.Rows | Where-Object { $_.Sat -eq "0" } | Set-Style -Style OFF -Property "Sat"

                                                                    $OutObj2.Rows | Where-Object { $_.Sun -eq "1" } | Set-Style -Style ON -Property "Sun"
                                                                    $OutObj2.Rows | Where-Object { $_.Mon -eq "1" } | Set-Style -Style ON -Property "Mon"
                                                                    $OutObj2.Rows | Where-Object { $_.Tue -eq "1" } | Set-Style -Style ON -Property "Tue"
                                                                    $OutObj2.Rows | Where-Object { $_.Wed -eq "1" } | Set-Style -Style ON -Property "Wed"
                                                                    $OutObj2.Rows | Where-Object { $_.Thu -eq "1" } | Set-Style -Style ON -Property "Thu"
                                                                    $OutObj2.Rows | Where-Object { $_.Fri -eq "1" } | Set-Style -Style ON -Property "Fri"
                                                                    $OutObj2.Rows | Where-Object { $_.Sat -eq "1" } | Set-Style -Style ON -Property "Sat"
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
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC "Backup Cache" {
                                                    $OutObj = @()
                                                    Write-PScriboMessage "Discovered $($ABkjob.Name) backup cache information."
                                                    $inObj = [ordered] @{
                                                        'Maximun Size' = "$($ABkjob.BackupCacheOptions.SizeLimit) $($ABkjob.BackupCacheOptions.SizeUnit)"
                                                        'Type' = $ABkjob.BackupCacheOptions.Type
                                                        'Path' = Switch ($ABkjob.BackupCacheOptions.Type) {
                                                            'Automatic' { 'Auto Selected' }
                                                            default { $ABkjob.BackupCacheOptions.LocalPath }
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Backup Cache - $($ABkjob.Name)"
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
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC "Schedule" {
                                                $OutObj = @()
                                                try {
                                                    Write-PScriboMessage "Discovered $($ABkjob.Name) schedule options."
                                                    if ($ABkjob.ScheduleOptions.DailyScheduleEnabled) {
                                                        $ScheduleType = 'Daily'
                                                        $Schedule = "Recurrence: $($ABkjob.ScheduleOptions.DailyOptions.Type),`r`nDays: $($ABkjob.ScheduleOptions.DailyOptions.DayOfWeek)r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    }

                                                    if ($ABkjob.ScheduleOptions.Type -eq "Daily") {
                                                        $ScheduleType = "Daily"
                                                        $Schedule = "Recurrence: $($ABkjob.ScheduleOptions.DailyOptions.Type),`r`nDays: $($ABkjob.ScheduleOptions.DailyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq "Monthly") {
                                                        $ScheduleType = "Monthly"
                                                        $Schedule = "Day Of Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nDay Number In Month: $($ABkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($ABkjob.ScheduleOptions.MonthlyOptions.DayOfWeek)`r`nAt: $($ABkjob.ScheduleOptions.DailyOptions.Period)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq "Periodically") {
                                                        $ScheduleType = $ABkjob.ScheduleOptions.PeriodicallyOptions.PeriodicallyKind
                                                        $Schedule = "Full Period: $($ABkjob.ScheduleOptions.PeriodicallyOptions.FullPeriod),`r`nHourly Offset: $($ABkjob.ScheduleOptions.PeriodicallyOptions.HourlyOffset)"
                                                    } elseif ($ABkjob.ScheduleOptions.Type -eq "AfterJob") {
                                                        $ScheduleType = 'After Job'
                                                        $Schedule = $ABkjob.ScheduleOptions.Job.Name
                                                    }

                                                    $inObj = [ordered] @{
                                                        'Schedule type' = $ScheduleType
                                                        'Schedule Options' = $Schedule
                                                        'If Computer is Power Off Action' = SWitch ($ABkjob.ScheduleOptions.PowerOffAction) {
                                                            $null { '--' }
                                                            'SkipBackup' { 'Skip Backup' }
                                                            'BackupAtPowerOn' { 'Backup At Power On' }
                                                            default { $ABkjob.ScheduleOptions.PowerOffAction }
                                                        }
                                                        'Once Backup is Taken' = Switch ($ABkjob.ScheduleOptions.PostBackupAction) {
                                                            $null { '--' }
                                                            'KeepRunning' { 'Keep Running' }
                                                            default { $ABkjob.ScheduleOptions.PostBackupAction }
                                                        }
                                                        'Backup At LogOff' = ConvertTo-TextYN $ABkjob.ScheduleOptions.BackupAtLogOff
                                                        'Backup At Lock' = ConvertTo-TextYN $ABkjob.ScheduleOptions.BackupAtLock
                                                        'Backup At Target Connection' = ConvertTo-TextYN $ABkjob.ScheduleOptions.BackupAtTargetConnection
                                                        'Eject Storage After Backup' = ConvertTo-TextYN $ABkjob.ScheduleOptions.EjectStorageAfterBackup
                                                        'Backup Timeout' = Switch ([string]::IsNullOrEmpty($ABkjob.ScheduleOptions.BackupTimeout)) {
                                                            $true { '--' }
                                                            $false { "$($ABkjob.ScheduleOptions.BackupTimeout) $($ABkjob.ScheduleOptions.BackupTimeoutType)" }
                                                            default { "Unknown" }
                                                        }
                                                    }
                                                    $OutObj = [pscustomobject]$inobj

                                                    $TableParams = @{
                                                        Name = "Schedule Options - $($ABkjob.Name)"
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
    end {}

}
