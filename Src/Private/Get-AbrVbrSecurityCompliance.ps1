
function Get-AbrVbrSecurityCompliance {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Security & Compliance Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.9
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
        Write-PScriboMessage "Discovering Veeam VBR Security & Compliance Summary from $System."
    }

    process {
        try {
            try {
                try {
                    # Force new scan
                    Start-VBRSecurityComplianceAnalyzer -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    Start-Sleep -Seconds 15
                    # Capture scanner results
                    $SecurityCompliances = [Veeam.Backup.DBManager.CDBManager]::Instance.BestPractices.GetAll()
                } Catch {
                    Write-PScriboMessage -IsWarning "Security & Compliance summary command: $($_.Exception.Message)"
                }
                $RuleTypes = @{
                    'WindowsScriptHostDisabled' = 'Windows Script Host is disabled'
                    'BackupServicesUnderLocalSystem' = 'Backup services run under the LocalSystem account'
                    'OutdatedSslAndTlsDisabled' = 'Outdated SSL And TLS are Disabled'
                    'ManualLinuxHostAuthentication' = 'Unknown Linux servers are not trusted automatically'
                    'CSmbSigningAndEncryptionEnabled' = 'SMB v3 signing is enabled'
                    'ViProxyTrafficEncrypted' = 'Host to proxy traffic encryption should be enable for the Network transport mode'
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
                    'ConfigurationBackupRepositoryNotLocal' = 'The configuration backup is not stored on the backup server'
                    'LossProtectionEnabled' = 'Password loss protection is enabled'
                    'TrafficEncryptionEnabled' = 'Encryption network rules added for LAN traffic'
                    'NetBiosDisabled' = 'NetBIOS protocol should be disabled on all network interfaces'
                    'LsassProtectedProcess' = 'Local Security Authority Server Service (LSASS) should be set to run as a protected process'
                    'HardenedRepositoryNotContainsNBDProxies' = 'Hardened repositories should not be used as backup proxy servers due to expanded attack surface'
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
                        Write-PScriboMessage -IsWarning "Security & Compliance summary table: $($_.Exception.Message)"
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "Security & Compliance summary section: $($_.Exception.Message)"
            }

            if ($HealthCheck.Security.BestPractice) {
                $OutObj | Where-Object { $_.'Status' -eq 'Not Implemented' } | Set-Style -Style Critical -Property 'Status'
                $OutObj | Where-Object { $_.'Status' -eq 'Passed' } | Set-Style -Style Ok -Property 'Status'
                $OutObj | Where-Object { $_.'Status' -eq 'Unable to detect' } | Set-Style -Style Warning -Property 'Status'
            }

            $TableParams = @{
                Name = "Security & Compliance - $VeeamBackupServer"
                List = $false
                ColumnWidths = 70, 30
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }

            try {

                $sampleData = [ordered]@{
                    'Passed' = ($OutObj.status | Where-Object { $_ -eq "Passed" } | Measure-Object).Count
                    'Unable to detect' = ($OutObj.status | Where-Object { $_ -eq "Unable to detect" } | Measure-Object).Count
                    'Not Implemented' = ($OutObj.status | Where-Object { $_ -eq "Not Implemented" } | Measure-Object).Count
                    'Suppressed' = ($OutObj.status | Where-Object { $_ -eq "Suppressed" } | Measure-Object).Count
                }

                $sampleDataObj = $sampleData.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } }

                $chartFileItem = Get-ColumnChart -Status -SampleData $sampleDataObj -ChartName 'SecurityCompliance' -XField 'Category' -YField 'Value' -ChartAreaName 'Infrastructure' -AxisXTitle 'Status' -AxisYTitle 'Count' -ChartTitleName 'SecurityCompliance' -ChartTitleText 'Best Practice'

            } catch {
                Write-PScriboMessage -IsWarning "Security & Compliance chart section: $($_.Exception.Message)"
            }

            if ($OutObj) {
                Section -Style NOTOCHeading4 -ExcludeFromTOC 'Security & Compliance' {
                    if ($chartFileItem -and ($OutObj.count | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Security & Compliance - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    BlankLine
                    $OutObj | Sort-Object -Property 'Best Practice' | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}