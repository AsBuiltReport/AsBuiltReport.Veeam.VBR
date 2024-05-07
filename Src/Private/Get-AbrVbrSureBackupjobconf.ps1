
function Get-AbrVbrSureBackupjobconf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns surebackup jobs for vmware created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR SureBackup jobs configuration information from $System."
    }

    process {
        try {
            $SBkjobs = Get-VBRSureBackupJob | Sort-Object -Property Name
            if ($SBkjobs) {
                Section -Style Heading3 'SureBackup Job Configuration' {
                    Paragraph "The following section provide detailed jobs configuration about Surebackup."
                    BlankLine
                    $OutObj = @()
                    foreach ($SBkjob in $SBkjobs) {
                        try {
                            Section -Style Heading4 $($SBkjob.Name) {
                                try {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Common Information' {
                                        $OutObj = @()
                                        Write-PScriboMessage "Discovered $($SBkjob.Name) common information."
                                        $inObj = [ordered] @{
                                            'Name' = $SBkjob.Name
                                            'Last Run' = $SBkjob.LastRun
                                            'Next Run' = Switch ($SBkjob.Enabled) {
                                                'False' { 'Disabled' }
                                                default { $SBkjob.NextRun }
                                            }
                                            'Description' = ConvertTo-EmptyToFiller $SBkjob.Description
                                        }
                                        $OutObj = [pscustomobject]$inobj

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                        }

                                        $TableParams = @{
                                            Name = "Common Information - $($SBkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if ($HealthCheck.Jobs.BestPractice) {
                                            if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $_.'Description' -eq "--" }) {
                                                Paragraph "Health Check:" -Bold -Underline
                                                BlankLine
                                                Paragraph {
                                                    Text "Best Practice:" -Bold
                                                    Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Virtual Lab' {
                                            $OutObj = @()
                                            Write-PScriboMessage "Discovered $($SBkjob.VirtualLab.Name) virtual lab."
                                            $inObj = [ordered] @{
                                                'Name' = $SBkjob.VirtualLab.Name
                                                'Description' = $SBkjob.VirtualLab.Description
                                                'Physical Host' = $SBkjob.VirtualLab.Server.Name
                                                'Physical Host Version' = $SBkjob.VirtualLab.Server.Info.Info
                                            }
                                            if ($SBkjob.VirtualLab.Platform -eq "HyperV" -and (Get-VBRHvVirtualLabConfiguration)) {
                                                $inObj.add('Destination', (Get-VBRHvVirtualLabConfiguration -Id $SBkjob.VirtualLab.Id).Path)
                                            }
                                            if ($SBkjob.VirtualLab.Platform -eq "VMWare") {
                                                $inObj.add('Datastore', (Get-VBRViVirtualLabConfiguration -Id $SBkjob.VirtualLab.Id).CacheDatastore)
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Virtual Lab - $($SBkjob.Name)"
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Application Group' {
                                            $OutObj = @()
                                            Write-PScriboMessage "Discovered $($SBkjob.ApplicationGroup.Name) application group."
                                            $inObj = [ordered] @{
                                                'Name' = $SBkjob.ApplicationGroup.Name
                                                'Virtual Machines' = $SBkjob.ApplicationGroup.VM -join ", "
                                                'Keep Application Group Running' = ConvertTo-TextYN $SBkjob.KeepApplicationGroupRunning
                                                'Description' = $SBkjob.ApplicationGroup.Description
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Application Group - $($SBkjob.Name)"
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Linked Jobs' {
                                            $OutObj = @()
                                            foreach ($LinkedJob in $SBkjob.LinkedJob) {
                                                Write-PScriboMessage "Discovered $($LinkedJob.Job.Name) linked job."
                                                $inObj = [ordered] @{
                                                    'Name' = $LinkedJob.Job.Name
                                                    'Roles' = Switch ([string]::IsNullOrEmpty($LinkedJob.Role)) {
                                                        $true { 'Not Defined' }
                                                        $false { $LinkedJob.Role -join "," }
                                                        default { 'Unknown' }
                                                    }
                                                    'Description' = $LinkedJob.Job.Description
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                            $TableParams = @{
                                                Name = "Linked Jobs - $($SBkjob.Name)"
                                                List = $false
                                                ColumnWidths = 30, 30, 40
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                            if (($InfoLevel.Jobs.Surebackup -ge 2) -and $SBkjob.LinkToJobs) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC 'Verification Options' {
                                                        $OutObj = @()
                                                        foreach ($LinkedJob in $SBkjob.LinkedJob) {
                                                            Write-PScriboMessage "Discovered $($LinkedJob.Job.Name) verification options."
                                                            $inObj = [ordered] @{
                                                                'Job Name' = $LinkedJob.Job.Name
                                                                'Amount of memory to Allocate to VM' = "$($LinkedJob.StartupOptions.AllocatedMemory) percent"
                                                                'Maximum allowed boot time' = "$($LinkedJob.StartupOptions.MaximumBootTime) sec"
                                                                'Application Initialization Timeout' = "$($LinkedJob.StartupOptions.ApplicationInitializationTimeout) sec"
                                                                'VM heartbeat is present' = ConvertTo-TextYN $LinkedJob.StartupOptions.VMHeartBeatCheckEnabled
                                                                'VM respond to ping on any interface' = ConvertTo-TextYN $LinkedJob.StartupOptions.VMPingCheckEnabled
                                                                'Automatically disable Windows Firewall' = ConvertTo-TextYN $LinkedJob.StartupOptions.WindowsFirewallDisabled
                                                                'VM Role' = ConvertTo-EmptyToFiller ($LinkedJob.ScriptOptions.PredefinedApplication -join ", ")
                                                                'VM Test Script' = Switch ([string]::IsNullOrEmpty(($LinkedJob.ScriptOptions | ForEach-Object { if ($_.Name) { $_.Name } }))) {
                                                                    $true { '--' }
                                                                    $false { ($LinkedJob.ScriptOptions) | ForEach-Object { if ($_.Name) { "Name: $($_.Name), Path: $($_.Path), Argument: $($_.Argument)" } } }
                                                                    default { "Uknown" }
                                                                }
                                                                'Credentials' = Switch ($LinkedJob.Credentials.Description) {
                                                                    $Null { 'None' }
                                                                    default { $LinkedJob.Credentials.Description }
                                                                }
                                                            }
                                                            $OutObj = [pscustomobject]$inobj

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
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Per VM Verification Rules' {
                                                            $OutObj = @()
                                                            foreach ($LinkedJobVM in $SBkjob.LinkedJob.VM) {
                                                                Write-PScriboMessage "Discovered $($LinkedJobVM.Name) verification rules."
                                                                $inObj = [ordered] @{
                                                                    'VM Name' = $LinkedJobVM.Name
                                                                    'Excluded' = ConvertTo-TextYN $LinkedJobVM.IsExcluded
                                                                    'VM Role' = ConvertTo-EmptyToFiller ($LinkedJobVM.Role -join ", ")
                                                                    'VM Test Script' = Switch ([string]::IsNullOrEmpty(($LinkedJobVM.TestScript | ForEach-Object { if ($_.Name) { $_.Name } }))) {
                                                                        $true { '--' }
                                                                        $false { ($LinkedJobVM.TestScript) | ForEach-Object { if ($_.Name) { "Name: $($_.Name),Path: $($_.Path),Argument: $($_.Argument)" } } }
                                                                        default { "Uknown" }
                                                                    }
                                                                    'Credentials' = Switch ($LinkedJobVM.Credentials.Description) {
                                                                        $Null { 'None' }
                                                                        default { $LinkedJobVM.Credentials.Description }
                                                                    }
                                                                }
                                                                $OutObj += [pscustomobject]$inobj
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
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Settings' {
                                        $OutObj = @()
                                        Write-PScriboMessage "Discovered $($SBkjob.Name) job settings."
                                        $inObj = [ordered] @{
                                            'Backup file integrity scan' = ConvertTo-TextYN $SBkjob.VerificationOptions.EnableDiskContentValidation
                                            'Skip validation for application group VM' = ConvertTo-TextYN $SBkjob.VerificationOptions.DisableApplicationGroupValidation
                                            'Malware Scan' = ConvertTo-TextYN $SBkjob.VerificationOptions.EnableMalwareScan
                                            'YARA Scan' = ConvertTo-TextYN $SBkjob.VerificationOptions.EnableYARAScan
                                            'YARA Rules' = ConvertTo-EmptyToFiller $SBkjob.VerificationOptions.YARAScanRule
                                            'Scan the entire image' = ConvertTo-TextYN $SBkjob.VerificationOptions.EnableEntireImageScan
                                            'Skip application group machine from malware scan' = ConvertTo-TextYN $SBkjob.VerificationOptions.DisableApplicationGroupMalwareScan
                                            'Send SNMP trap' = ConvertTo-TextYN $SBkjob.VerificationOptions.EnableSNMPNotification
                                            'Send Email notification' = ConvertTo-TextYN $SBkjob.VerificationOptions.EnableEmailNotification
                                            'Email recipients' = $SBkjob.VerificationOptions.Address
                                            'Use custom notification settings' = $SBkjob.VerificationOptions.UseCustomEmailSettings
                                        }

                                        if ($SBkjob.VerificationOptions.UseCustomEmailSettings) {
                                            $inObj.Add("Custom Subject", $SBkjob.VerificationOptions.Subject)
                                            $inObj.Add("Notify On Success", $SBkjob.VerificationOptions.NotifyOnSuccess)
                                            $inObj.Add("Notify On Warning", $SBkjob.VerificationOptions.NotifyOnWarning)
                                            $inObj.Add("Notify On Error", $SBkjob.VerificationOptions.NotifyOnError)
                                        }

                                        $OutObj = [pscustomobject]$inobj

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
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Schedule' {
                                        $OutObj = @()
                                        try {
                                            Write-PScriboMessage "Discovered $($SBkjob.Name) schedule options."
                                            $inObj = [ordered] @{
                                                'Wait for backup jobs' = "$($SBkjob.ScheduleOptions.WaitTimeMinutes) minutes"
                                            }

                                            if ($SBkjob.ScheduleOptions.Type -eq "Daily") {
                                                $Schedule = "Daily at this time: $($SBkjob.ScheduleOptions.DailyOptions.Period),`r`nDays: $($SBkjob.ScheduleOptions.DailyOptions.Type),`r`nDay Of Week: $($SBkjob.ScheduleOptions.DailyOptions.DayOfWeek)"
                                            } elseif ($SBkjob.ScheduleOptions.Type -eq "Monthly") {
                                                if ($SBkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth -eq 'OnDay') {
                                                    $Schedule = "Monthly at this time: $($SBkjob.ScheduleOptions.MonthlyOptions.Period),`r`nThis Day: $($SBkjob.ScheduleOptions.MonthlyOptions.DayOfMonth),`r`nMonths: $($SBkjob.ScheduleOptions.MonthlyOptions.Months)"
                                                } else {
                                                    $Schedule = "Monthly at this time: $($SBkjob.ScheduleOptions.MonthlyOptions.Period),`r`nDays Number of Month: $($SBkjob.ScheduleOptions.MonthlyOptions.DayNumberInMonth),`r`nDay Of Week: $($SBkjob.ScheduleOptions.MonthlyOptions.DayOfWeek),`r`nMonth: $($SBkjob.ScheduleOptions.MonthlyOptions.Months)"
                                                }
                                            } elseif ($SBkjob.ScheduleOptions.Type -eq "AfterJob") {
                                                $Schedule = Switch ($SBkjob.ScheduleOptions.AfterJobId) {
                                                    $Null { 'Unknown' }
                                                    default { " After Job: $((Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.Id -eq $SBkjob.ScheduleOptions.AfterJobId}).Name)" }
                                                }
                                            } elseif ($TBkjob.ScheduleOptions.Type -eq "AfterNewBackup") {
                                                $Schedule = 'After New Backup File Appears'
                                            }
                                            $inObj.add("Run Automatically", ($Schedule))

                                            $OutObj += [pscustomobject]$inobj
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
    end {}

}
