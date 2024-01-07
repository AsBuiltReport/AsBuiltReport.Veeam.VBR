
function Get-AbrVbrSecurityCompliance {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Security & Compliance Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.4
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
        Write-PscriboMessage "Discovering Veeam VBR Security & Compliance Summary from $System."
    }

    process {
        try {
            try {
                try {
                    # Force new scan
                    start-VBRSecurityComplianceAnalyzer -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    Start-Sleep -Seconds 15
                    # Capture scanner results
                    $SecurityCompliances = [Veeam.Backup.DBManager.CDBManager]::Instance.BestPractices.GetAll()
                } Catch {
                    Write-PscriboMessage -IsWarning "Security & Compliance summary command: $($_.Exception.Message)"
                }
                $RuleTypes = @{
                    'WindowsScriptHostDisabled' = 'Windows Script Host is disabled'
                    'BackupServicesUnderLocalSystem' = 'Backup services run under the LocalSystem account'
                    'OutdatedSslAndTlsDisabled' = 'Outdated SSL And TLS are Disabled'
                    'ManualLinuxHostAuthentication' = 'Unknown Linux servers are not trusted automatically'
                    'CSmbSigningAndEncryptionEnabled' = 'SMB v3 signing is enabled'
                    'ViProxyTrafficEncrypted' = 'Host to proxy traffic encryption shoul be enable for the Network transport mode'
                    'JobsTargetingCloudRepositoriesEncrypted' = 'Backup jobs to cloud repositories is encrypted'
                    'LLMNRDisabled' = 'Link-Local Multicast Name Resolution (LLMNR) is disabled'
                    'ImmutableOrOfflineMediaPresence' = 'Immutable or offline media is used'
                    'OsBucketsInComplianceMode' = 'Os Buckets In Compliance Mode'
                    'BackupServerUpToDate' = 'Backup Server is Up To Date'
                    'BackupServerInProductionDomain' = 'Computer is Workgroup member'
                    'ReverseIncrementalInUse' = 'Reverse incremental backup mode is not used'
                    'ConfigurationBackupEncryptionEnabled' = 'Configuration backup encryption is enabled'
                    'WDigestNotStorePasswordsInMemory' = 'WDigest credentials caching is disabled'
                    'WebProxyAutoDiscoveryDisabled' = 'Web Proxy Auto-Discovery service (WinHttpAutoProxySvc) is disabled'
                    'ContainBackupCopies' = 'All backups have at least one copy (the 3-2-1 backup rule)'
                    'SMB1ProtocolDisabled' = 'SMB 1.0 is disabled'
                    'EmailNotificationsEnabled' = 'Email notifications are enabled'
                    'RemoteRegistryDisabled' = 'Remote registry service is disabled'
                    'PasswordsRotation' = 'Credentials and encryption passwords rotates annually'
                    'WinRmServiceDisabled' = 'Remote powershell is disabled (WinRM service)'
                    'MfaEnabledInBackupConsole' = 'MFA is enabled'
                    'HardenedRepositorySshDisabled' = 'Hardened repositories have SSH disabled'
                    'LinuxServersUsingSSHKeys' = 'Linux servers have password-based authentication disabled'
                    'RemoteDesktopServiceDisabled' = 'Remote desktop protocol is disabled'
                    'ConfigurationBackupEnabled' = 'Configuration backup is enabled'
                    'WindowsFirewallEnabled' = 'Windows firewall is enabled'
                    'ConfigurationBackupEnabledAndEncrypted' = 'Configuration backup is enabled and use encryption'
                    'HardenedRepositoryNotVirtual' = 'Hardened repositories are not hosted in virtual machines'
                    'ConfigurationBackupRepositoryNotLocal' ='The configuration backup is not stored on the backup server'
                    'LossProtectionEnabled' = 'Password loss protection is enabled'
                    'TrafficEncryptionEnabled' = 'Encryption network rules added for LAN traffic'
                }
                $StatusObj = @{
                    'Ok' = "Passed"
                    'Violation' = "Not Implemented"
                    'UnableToCheck' = "Unable to detect"
                    'Suppressed' = "Suppressed"
                }
                $OutObj = @()
                foreach ($SecurityCompliance in $SecurityCompliances) {
                    try {
                        # Write-PscriboMessage -IsWarning "$($SecurityCompliance.Type) = $($RuleTypes[$SecurityCompliance.Type.ToString()])"
                        $inObj = [ordered] @{
                            'Best Practice' = $RuleTypes[$SecurityCompliance.Type.ToString()]
                            'Status' = $StatusObj[$SecurityCompliance.Status.ToString()]
                        }
                        $OutObj += [pscustomobject]$inobj
                    } catch {
                        Write-PscriboMessage -IsWarning "Security & Compliance summary table: $($_.Exception.Message)"
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning "Security & Compliance summary section: $($_.Exception.Message)"
            }

            if ($HealthCheck.Security.BestPractice) {
                $OutObj | Where-Object { $_.'Status' -eq 'Not Implemented'} | Set-Style -Style Critical -Property 'Status'
            }

            $TableParams = @{
                Name = "Security & Compliance - $VeeamBackupServer"
                List = $false
                ColumnWidths = 70, 30
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($Options.EnableCharts) {
                try {
                    $sampleData = $OutObj.status | Group-Object
                    $exampleChart = New-Chart -Name BackupJobs -Width 600 -Height 400

                    $addChartAreaParams = @{
                        Chart                 = $exampleChart
                        Name                  = 'SecurityCompliance'
                        AxisXTitle            = 'Status'
                        AxisYTitle            = 'Count'
                        NoAxisXMajorGridLines = $true
                        NoAxisYMajorGridLines = $true
                    }
                    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                    $addChartSeriesParams = @{
                        Chart             = $exampleChart
                        ChartArea         = $exampleChartArea
                        Name              = 'exampleChartSeries'
                        XField            = 'Name'
                        YField            = 'Count'
                        Palette           = 'Green'
                        ColorPerDataPoint = $true
                    }
                    $sampleData | Add-ColumnChartSeries @addChartSeriesParams

                    $addChartTitleParams = @{
                        Chart     = $exampleChart
                        ChartArea = $exampleChartArea
                        Name      = 'SecurityCompliance'
                        Text      = 'Security & Compliance'
                        Font      = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                    }
                    Add-ChartTitle @addChartTitleParams

                    $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru

                    if ($PassThru)
                    {
                        Write-Output -InputObject $chartFileItem
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $($_.Exception.Message)
                }
            }
            if ($OutObj) {
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Security & Compliance' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($OutObj.count | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Security & Compliance - Chart' -Align 'Center' -Percent 100 -Path $chartFileItem
                    }
                    BlankLine
                    $OutObj | Sort-Object -Property 'Best Practice' | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}