
function Get-AbrVbrAgentBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns computer backup jobs configuration created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.1
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
        Write-PscriboMessage "Discovering Veeam VBR Agent Backup jobs configuration information from $System."
    }

    process {
        try {
            if ((Get-VBRComputerBackupJob).count -gt 0) {
                Section -Style Heading3 'Agent Backup Jobs Configuration' {
                    Paragraph "The following section details agent backup jobs configuration created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        $ABkjobs = Get-VBRComputerBackupJob
                        foreach ($ABkjob in $ABkjobs) {
                            try {
                                Section -Style Heading4 "$($ABkjob.Name) Configuration" {
                                    Section -Style Heading5 'Job Mode' {
                                        $OutObj = @()
                                        try {
                                            Write-PscriboMessage "Discovered $($ABkjob.Name) common information."
                                            $inObj = [ordered] @{
                                                'Name' = $ABkjob.Name
                                                'Id' = $ABkjob.Id
                                                'Type' = $ABkjob.Type
                                                'Mode' = Switch ($ABkjob.Mode) {
                                                    'ManagedByBackupServer' {'Managed by Backup Server'}
                                                    'ManagedByAgent' {'Managed by Agent'}
                                                    default {$ABkjob.Mode}
                                                }
                                                'Description' = $ABkjob.Description
                                                'Priority' = Switch ($ABkjob.IsHighPriority) {
                                                    'True' {'High Priority'}
                                                    'False' {'Normal Priority'}
                                                }
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Job Mode - $($ABkjob.Name)"
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
                                    try {
                                        Section -Style Heading5 'Protected Computers' {
                                            $OutObj = @()
                                            foreach ($BackupObject in $ABkjob.BackupObject) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($BackupObject.Name) protected computer information."
                                                    $inObj = [ordered] @{
                                                        'Name' = $BackupObject.Name
                                                        'Type' = SWitch ($BackupObject.Type) {
                                                            $Null {'Computer'}
                                                            default {$BackupObject.Type}
                                                        }
                                                        'Enabled' = ConvertTo-TextYN $BackupObject.Enabled
                                                        'Container' = Switch ($BackupObject.Container) {
                                                            $Null {'Individual Computer'}
                                                            'ActiveDirectory' {'Active Directory'}
                                                            'ManuallyDeployed' {'Manually Deployed'}
                                                            'IndividualComputers' {'Individual Computers'}
                                                            default {$BackupObject.Container}
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                    try {
                                        Section -Style Heading5 'Backup Mode' {
                                            $OutObj = @()
                                            try {
                                                Write-PscriboMessage "Discovered $($ABkjob.Name) backup mode information."
                                                $inObj = [ordered] @{
                                                    'Backup Mode' = Switch ($ABkjob.BackupType) {
                                                        'EntireComputer' {'Entire Computer'}
                                                        'SelectedVolumes' {'Volume Level Backup'}
                                                        'SelectedFiles' {'File Level Backup (slower)'}
                                                    }
                                                }
                                                if ($ABkjob.BackupType -eq 'EntireComputer') {
                                                    $inObj.add('Include external USB drives',(ConvertTo-TextYN $ABkjob.UsbDrivesIncluded))
                                                }
                                                elseif ($ABkjob.BackupType -eq 'SelectedVolumes') {
                                                    if ($Null -ne $ABkjob.SelectedVolumes.Path) {
                                                        $inObj.add('Backup the following volumes only',($ABkjob.SelectedVolumes.Path -join ', '))
                                                    }
                                                    elseif ($Null -ne $ABkjob.ExcludedVolumes.Path) {
                                                        $inObj.add('Backup all volumes except the following',($ABkjob.ExcludedVolumes.Path -join ', '))
                                                    }

                                                }
                                                elseif ($ABkjob.BackupType -eq 'SelectedFiles') {
                                                    $inObj.add('Backup Operating System Files',(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.BackupOS))
                                                    $inObj.add('Backup Personal Files',(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.BackupPersonalFiles))
                                                    if ($ABkjob.SelectedFilesOptions.BackupPersonalFiles -eq $TRUE) {
                                                        $inObj.add('User Profile Folder to Backup',("Desktop: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Desktop),`r`nDocuments: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Documents),`r`nPictures: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Pictures),`r`nVideo: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Video),`r`nFavorites: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Favorites),`r`nDownloads: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Downloads),`r`nApplicationData: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ApplicationData),`r`nOther Files and Folders: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.Custom),`r`nExclude Roaming Profile: $(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ExcludeRoamingUsers)"))
                                                    }
                                                    $inObj.add('Backup File System Files',(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.BackupSelectedFiles))
                                                    if ($Null -ne $ABkjob.SelectedFilesOptions.SelectedFiles) {
                                                        $inObj.add('Files System Path',($ABkjob.SelectedFilesOptions.SelectedFiles -join ', '))
                                                    }
                                                    if ('' -ne $ABkjob.SelectedFilesOptions.IncludeMask) {
                                                        $inObj.add('Filter Files (Include Mask)',($ABkjob.SelectedFilesOptions.IncludeMask))
                                                    }
                                                    if ('' -ne $ABkjob.SelectedFilesOptions.ExcludeMask) {
                                                        $inObj.add('Filter Files (Exclude Mask)',($ABkjob.SelectedFilesOptions.ExcludeMask))
                                                    }
                                                    if ($ABkjob.SelectedFilesOptions.BackupPersonalFiles -eq $TRUE) {
                                                        $inObj.add('Exclude Microsoft Onedrive Folders',(ConvertTo-TextYN $ABkjob.SelectedFilesOptions.SelectedPersonalFolders.ExcludeOneDrive))
                                                    }
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                                }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                    try {
                                        Section -Style Heading5 'Destination' {
                                            $OutObj = @()
                                            try {
                                                Write-PscriboMessage "Discovered $($ABkjob.Name) destination information."
                                                if ($ABkjob.RetentionType -eq "RestoreDays") {
                                                    $RetainString = 'Retain Days To Keep'
                                                    $Retains = $ABkjob.RetentionPolicy
                                                }
                                                elseif ($ABkjob.RetentionType -eq "RestorePoints") {
                                                    $RetainString = 'Retain Points'
                                                    $Retains = $ABkjob.RetentionPolicy
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByBackupServer') {
                                                    $DestinationType = 'Veeam Backup Repository'
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByAgent') {
                                                    $DestinationType = SWitch ($ABkjob.DestinationOptions.DestinationType) {
                                                        'BackupRepository' {'Veeam Backup Repository'}
                                                        'LocalStorage' {'Local Storage'}
                                                        'NetworkFolder' {'Shared Folder'}
                                                        default {$ABkjob.DestinationOptions.DestinationType}
                                                    }
                                                }
                                                $inObj = [ordered] @{
                                                    'Destination Type' = $DestinationType
                                                    'Retention Type' = $ABkjob.RetentionType
                                                    $RetainString = $Retains
                                                }
                                                if ($ABkjob.DestinationOptions.DestinationType -eq 'BackupRepository') {
                                                    $inObj.add('Backup Server',($ABkjob.DestinationOptions.BackupServerName))
                                                    $inObj.add('Storage',($ABkjob.DestinationOptions.BackupRepository.Name))
                                                }
                                                elseif ($ABkjob.DestinationOptions.DestinationType -eq 'LocalStorage') {
                                                    $inObj.add('Local Path',($ABkjob.DestinationOptions.LocalPath))
                                                }
                                                elseif ($ABkjob.DestinationOptions.DestinationType -eq 'NetworkFolder') {
                                                    $inObj.add('Shared Folder',($ABkjob.DestinationOptions.NetworkFolderPath))
                                                    $inObj.add('Target Share Type',($ABkjob.DestinationOptions.TargetShareType))
                                                    $inObj.add('Use Network Credentials',(ConvertTo-TextYN $ABkjob.DestinationOptions.UseNetworkCredentials))
                                                    if ($ABkjob.DestinationOptions.UseNetworkCredentials) {
                                                        $inObj.add('Credentials',($ABkjob.DestinationOptions.NetworkCredentials.Name))
                                                    }
                                                }
                                                if ($ABkjob.GFSRetentionEnabled) {
                                                    $inObj.add('Keep certain full backup longer for archival purposes (GFS)',(ConvertTo-TextYN $ABkjob.GFSRetentionEnabled))
                                                    $inObj.add('Keep Weekly full backup for', ("$($ABkjob.GFSOptions.WeeklyOptions.RetentionPeriod) weeks,`r`nIf multiple backup exist use the one from: $($ABkjob.GFSOptions.WeeklyOptions.SelectedDay)"))
                                                    $inObj.add('Keep Monthly full backup for', ("$($ABkjob.GFSOptions.MonthlyOptions.RetentionPeriod) months,`r`nUse weekly full backup from the following week of the month: $($ABkjob.GFSOptions.MonthlyOptions.SelectedWeek)"))
                                                    $inObj.add('Keep Yearly full backup for', ("$($ABkjob.GFSOptions.YearlyOptions.RetentionPeriod) years,`r`nUse monthly full backup from the following month: $($ABkjob.GFSOptions.YearlyOptions.SelectedMonth)"))
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                            if ($InfoLevel.Jobs.Agent -ge 2) {
                                                try {
                                                    Section -Style Heading6 "Advanced Settings (Backup)" {
                                                        $OutObj = @()
                                                        try {
                                                            Write-PscriboMessage "Discovered $($ABkjob.Name) backup options."

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
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                                        }
                                                    }
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                                try {
                                                    Section -Style Heading6 "Advanced Settings (Maintenance)" {
                                                        $OutObj = @()
                                                        try {
                                                            Write-PscriboMessage "Discovered $($ABkjob.Name) maintenance options."

                                                            $inObj = [ordered] @{
                                                                'Storage-Level Corruption Guard (SLCG)' = ConvertTo-TextYN $ABkjob.HealthCheckOptions.Enabled
                                                            }
                                                            if ($ABkjob.HealthCheckOptions.Enabled) {
                                                                $inObj.add('SLCG Schedule Type', $ABkjob.HealthCheckOptions.ScheduleType)
                                                                $inObj.add('SLCG Schedule Day', $ABkjob.HealthCheckOptions.SelectedDays)
                                                            }
                                                            if ($ABkjob.HealthCheckOptions.ScheduleType -ne 'Weekly'-and $ABkjob.HealthCheckOptions.Enabled) {
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

                                                            $TableParams = @{
                                                                Name = "Advanced Settings (Maintenance) - $($ABkjob.Name)"
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
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                                try {
                                                    Section -Style Heading6 "Advanced Settings (Storage)" {
                                                        $OutObj = @()
                                                        Write-PscriboMessage "Discovered $($ABkjob.Name) storage options."
                                                        $inObj = [ordered] @{
                                                            'Compression Level' = $ABkjob.StorageOptions.CompressionLevel
                                                            'Storage optimization' = $ABkjob.StorageOptions.StorageOptimizationType
                                                            'Enabled Backup File Encryption' = ConvertTo-TextYN $ABkjob.StorageOptions.EncryptionEnabled
                                                            'Encryption Key' = Switch ($ABkjob.StorageOptions.EncryptionEnabled) {
                                                                $false {'None'}
                                                                default {(Get-VBREncryptionKey | Where-Object { $_.id -eq $ABkjob.StorageOptions.EncryptionKey.Id }).Description}
                                                            }
                                                        }
                                                        $OutObj = [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Advanced Settings (Storage) - $($ABkjob.Name)"
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
                                                try {
                                                    Section -Style Heading6 "Advanced Settings (Notification)" {
                                                        $OutObj = @()
                                                        Write-PscriboMessage "Discovered $($ABkjob.Name) notification options."
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
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                                if ($ABkjob.Mode -eq 'ManagedByBackupServer'-and $ABkjob.OSPlatform -eq 'Windows') {
                                                    try {
                                                        Section -Style Heading6 "Advanced Settings (Integration)" {
                                                            $OutObj = @()
                                                            Write-PscriboMessage "Discovered $($ABkjob.Name) Integration options."
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
    end {}

}
