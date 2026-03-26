
function Get-AbrVbrSureBackupjobconf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns surebackup jobs for vmware created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR SureBackup jobs configuration information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrSureBackupjobconf
        Show-AbrDebugExecutionTime -Start -TitleMessage 'SureBackup Job Configuration'
    }

    process {
        try {
            if ($SBkjobs = Get-VBRSureBackupJob | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($SBkjob in $SBkjobs) {
                        try {
                            Section -Style Heading4 $($SBkjob.Name) {
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.CommonInfoSection {
                                        $OutObj = @()

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $SBkjob.Name
                                            $LocalizedData.LastRun = $SBkjob.LastRun
                                            $LocalizedData.NextRun = switch ($SBkjob.Enabled) {
                                                'False' { $LocalizedData.Disabled }
                                                default { $SBkjob.NextRun }
                                            }
                                            $LocalizedData.Description = $SBkjob.Description
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.CommonInfoTable) - $($SBkjob.Name)"
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
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "SureBackup $($SBkjob.Name) Common Information Section: $($_.Exception.Message)"
                                }
                                try {
                                    if ($SBkjob.VirtualLab) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.VirtualLabSection {
                                            $OutObj = @()

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name = $SBkjob.VirtualLab.Name
                                                $LocalizedData.Description = $SBkjob.VirtualLab.Description
                                                $LocalizedData.PhysicalHost = $SBkjob.VirtualLab.Server.Name
                                                $LocalizedData.PhysicalHostVersion = $SBkjob.VirtualLab.Server.Info.Info
                                            }
                                            if ($SBkjob.VirtualLab.Platform -eq 'HyperV' -and (Get-VBRHvVirtualLabConfiguration)) {
                                                $inObj.add($LocalizedData.Destination, (Get-VBRHvVirtualLabConfiguration -Id $SBkjob.VirtualLab.Id).Path)
                                            }
                                            if ($SBkjob.VirtualLab.Platform -eq 'VMWare') {
                                                $inObj.add($LocalizedData.Datastore, (Get-VBRViVirtualLabConfiguration -Id $SBkjob.VirtualLab.Id).CacheDatastore)
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                            $TableParams = @{
                                                Name = "$($LocalizedData.VirtualLabTable) - $($SBkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "SureBackup Virtual Lab $($SBkjob.Name) Section: $($_.Exception.Message)"
                                }
                                if ($SBkjob.ApplicationGroup) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.ApplicationGroupSection {
                                            $OutObj = @()

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name = $SBkjob.ApplicationGroup.Name
                                                $LocalizedData.VirtualMachines = $SBkjob.ApplicationGroup.VM -join ', '
                                                $LocalizedData.KeepAppGroupRunning = $SBkjob.KeepApplicationGroupRunning
                                                $LocalizedData.Description = $SBkjob.ApplicationGroup.Description
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                            $TableParams = @{
                                                Name = "$($LocalizedData.AppGroupTable) - $($SBkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "SureBackup Application Group $($SBkjob.Name) Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($SBkjob.LinkToJobs) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.LinkedJobsSection {
                                            $OutObj = @()
                                            foreach ($LinkedJob in $SBkjob.LinkedJob) {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $LinkedJob.Job.Name
                                                    $LocalizedData.Roles = switch ([string]::IsNullOrEmpty($LinkedJob.Role)) {
                                                        $true { $LocalizedData.NotDefined }
                                                        $false { $LinkedJob.Role -join ',' }
                                                        default { $LocalizedData.Unknown }
                                                    }
                                                    $LocalizedData.Description = $LinkedJob.Job.Description
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            }
                                            $TableParams = @{
                                                Name = "$($LocalizedData.LinkedJobsTable) - $($SBkjob.Name)"
                                                List = $false
                                                ColumnWidths = 30, 30, 40
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if (($InfoLevel.Jobs.Surebackup -ge 2) -and $SBkjob.LinkToJobs) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.VerificationOptionsSection {
                                                        $OutObj = @()
                                                        foreach ($LinkedJob in $SBkjob.LinkedJob) {

                                                            $inObj = [ordered] @{
                                                                'Job Name' = $LinkedJob.Job.Name
                                                                'Amount of memory to Allocate to VM' = "$($LinkedJob.StartupOptions.AllocatedMemory) percent"
                                                                'Maximum allowed boot time' = "$($LinkedJob.StartupOptions.MaximumBootTime) sec"
                                                                'Application Initialization Timeout' = "$($LinkedJob.StartupOptions.ApplicationInitializationTimeout) sec"
                                                                'VM heartbeat is present' = $LinkedJob.StartupOptions.VMHeartBeatCheckEnabled
                                                                'VM respond to ping on any interface' = $LinkedJob.StartupOptions.VMPingCheckEnabled
                                                                'Automatically disable Windows Firewall' = $LinkedJob.StartupOptions.WindowsFirewallDisabled
                                                                'VM Role' = ($LinkedJob.ScriptOptions.PredefinedApplication -join ', ')
                                                                'VM Test Script' = switch ([string]::IsNullOrEmpty(($LinkedJob.ScriptOptions | ForEach-Object { if ($_.Name) { $_.Name } }))) {
                                                                    $true { '--' }
                                                                    $false { ($LinkedJob.ScriptOptions) | ForEach-Object { if ($_.Name) { "Name: $($_.Name), Path: $($_.Path), Argument: $($_.Argument)" } } }
                                                                    default { 'Uknown' }
                                                                }
                                                                'Credentials' = switch ($LinkedJob.Credentials.Description) {
                                                                    $Null { 'None' }
                                                                    default { $LinkedJob.Credentials.Description }
                                                                }
                                                            }
                                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "Verification Options - $($SBkjob.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                        }
                                                    }
                                                    if ($SBkjob.LinkedJob.VM) {
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.PerVMVerificationSection {
                                                            $OutObj = @()
                                                            foreach ($LinkedJobVM in $SBkjob.LinkedJob.VM) {

                                                                $inObj = [ordered] @{
                                                                    'VM Name' = $LinkedJobVM.Name
                                                                    'Excluded' = $LinkedJobVM.IsExcluded
                                                                    'VM Role' = ($LinkedJobVM.Role -join ', ')
                                                                    'VM Test Script' = switch ([string]::IsNullOrEmpty(($LinkedJobVM.TestScript | ForEach-Object { if ($_.Name) { $_.Name } }))) {
                                                                        $true { '--' }
                                                                        $false { ($LinkedJobVM.TestScript) | ForEach-Object { if ($_.Name) { "Name: $($_.Name),Path: $($_.Path),Argument: $($_.Argument)" } } }
                                                                        default { 'Uknown' }
                                                                    }
                                                                    'Credentials' = switch ($LinkedJobVM.Credentials.Description) {
                                                                        $Null { 'None' }
                                                                        default { $LinkedJobVM.Credentials.Description }
                                                                    }
                                                                }
                                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                            }

                                                            $TableParams = @{
                                                                Name = "Per VM Verification Rules - $($SBkjob.Name)"
                                                                List = $false
                                                                ColumnWidths = 21, 11, 20, 28, 20
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Sort-Object -Property 'VM Name' | Table @TableParams
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "SureBackup Verification Options $($SBkjob.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "SureBackup Linked Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
                                    }
                                }
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SettingsSection {
                                        $OutObj = @()

                                        $inObj = [ordered] @{
                                            'Backup file integrity scan' = $SBkjob.VerificationOptions.EnableDiskContentValidation
                                            'Skip validation for application group VM' = $SBkjob.VerificationOptions.DisableApplicationGroupValidation
                                            'Malware Scan' = $SBkjob.VerificationOptions.EnableMalwareScan
                                            'YARA Scan' = $SBkjob.VerificationOptions.EnableYARAScan
                                            'YARA Rules' = $SBkjob.VerificationOptions.YARAScanRule
                                            'Scan the entire image' = $SBkjob.VerificationOptions.EnableEntireImageScan
                                            'Skip application group machine from malware scan' = $SBkjob.VerificationOptions.DisableApplicationGroupMalwareScan
                                            'Send SNMP trap' = $SBkjob.VerificationOptions.EnableSNMPNotification
                                            'Send Email notification' = $SBkjob.VerificationOptions.EnableEmailNotification
                                            'Email recipients' = $SBkjob.VerificationOptions.Address
                                            'Use custom notification settings' = $SBkjob.VerificationOptions.UseCustomEmailSettings
                                        }

                                        if ($SBkjob.VerificationOptions.UseCustomEmailSettings) {
                                            $inObj.Add('Custom Subject', $SBkjob.VerificationOptions.Subject)
                                            $inObj.Add('Notify On Success', $SBkjob.VerificationOptions.NotifyOnSuccess)
                                            $inObj.Add('Notify On Warning', $SBkjob.VerificationOptions.NotifyOnWarning)
                                            $inObj.Add('Notify On Error', $SBkjob.VerificationOptions.NotifyOnError)
                                        }

                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "Settings - $($SBkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "SureBackup Settings $($SBkjob.Name) Section: $($_.Exception.Message)"
                                }
                                if ($SBkjob.ScheduleEnabled) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.ScheduleSection {
                                        $OutObj = @()
                                        try {

                                            $inObj = [ordered] @{
                                                'Wait for backup jobs' = "$($SBkjob.ScheduleOptions.WaitTimeMinutes) minutes"
                                            }

                                            if ($SBkjob.ScheduleOptions.Type -eq 'Daily') {
                                                $Schedule = "Daily at this time: $($SBkjob.ScheduleOptions.DailyOptions.Period),`r`nDays: $($SBkjob.ScheduleOptions.DailyOptions.Type),`r`nDay Of Week: $($SBkjob.ScheduleOptions.DailyOptions.DayOfWeek)"
                                            } elseif ($SBkjob.ScheduleOptions.Type -eq 'Monthly') {
                                                if ($SBkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth -eq 'OnDay') {
                                                    $Schedule = "Monthly at this time: $($SBkjob.ScheduleOptions.MonthlyOptions.Period),`r`nThis Day: $($SBkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nMonths: $($SBkjob.ScheduleOptions.MonthlyOptions.Months)"
                                                } else {
                                                    $Schedule = "Monthly at this time: $($SBkjob.ScheduleOptions.MonthlyOptions.Period),`r`nDays Number of Month: $($SBkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($SBkjob.ScheduleOptions.MonthlyOptions.DayOfWeek),`r`nMonth: $($SBkjob.ScheduleOptions.MonthlyOptions.Months)"
                                                }
                                            } elseif ($SBkjob.ScheduleOptions.Type -eq 'AfterJob') {
                                                $Schedule = switch ($SBkjob.ScheduleOptions.AfterJobId) {
                                                    $Null { 'Unknown' }
                                                    default { " After Job: $((Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.Id -eq $SBkjob.ScheduleOptions.AfterJobId}).Name)" }
                                                }
                                            } elseif ($TBkjob.ScheduleOptions.Type -eq 'AfterNewBackup') {
                                                $Schedule = 'After New Backup File Appears'
                                            }
                                            $inObj.add('Run Automatically', ($Schedule))

                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "SureBackup Schedule $($SBkjob.Name) Section: $($_.Exception.Message)"
                                        }

                                        $TableParams = @{
                                            Name = "Schedule - $($SBkjob.Name)"
                                            List = $True
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "SureBackup Job Configuration $($SBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "SureBackup Job Configuration Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'SureBackup Job Configuration'
    }

}
