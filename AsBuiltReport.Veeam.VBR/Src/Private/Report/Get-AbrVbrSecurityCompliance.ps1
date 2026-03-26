
function Get-AbrVbrSecurityCompliance {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Security & Compliance Summary.
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
        Write-PScriboMessage "Discovering Veeam VBR Security & Compliance Summary from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrSecurityCompliance
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Security & Compliance summary'

    }

    process {
        try {
            try {
                try {
                    # Force new scan
                    $Null = Start-VBRSecurityComplianceAnalyzer -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    Start-Sleep -Seconds 15
                    # Capture scanner results
                    $SecurityCompliances = switch ($VbrVersion) {
                        { $_ -ge 13 } {
                            Get-VBRSecurityComplianceAnalyzerResults -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                        }
                        default {
                            [Veeam.Backup.DBManager.CDBManager]::Instance.BestPractices.GetAll()
                        }

                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Security & Compliance summary command: $($_.Exception.Message)"
                }
                $RuleTypes = @{
                    'WindowsScriptHostDisabled' = $LocalizedData.WindowsScriptHostDisabled
                    'BackupServicesUnderLocalSystem' = $LocalizedData.BackupServicesUnderLocalSystem
                    'OutdatedSslAndTlsDisabled' = $LocalizedData.OutdatedSslAndTlsDisabled
                    'ManualLinuxHostAuthentication' = $LocalizedData.ManualLinuxHostAuthentication
                    'CSmbSigningAndEncryptionEnabled' = $LocalizedData.CSmbSigningAndEncryptionEnabled
                    'ViProxyTrafficEncrypted' = $LocalizedData.ViProxyTrafficEncrypted
                    'JobsTargetingCloudRepositoriesEncrypted' = $LocalizedData.JobsTargetingCloudRepositoriesEncrypted
                    'LLMNRDisabled' = $LocalizedData.LLMNRDisabled
                    'ImmutableOrOfflineMediaPresence' = $LocalizedData.ImmutableOrOfflineMediaPresence
                    'OsBucketsInComplianceMode' = $LocalizedData.OsBucketsInComplianceMode
                    'BackupServerUpToDate' = $LocalizedData.BackupServerUpToDate
                    'BackupServerInProductionDomain' = $LocalizedData.BackupServerInProductionDomain
                    'ReverseIncrementalInUse' = $LocalizedData.ReverseIncrementalInUse
                    'ConfigurationBackupEncryptionEnabled' = $LocalizedData.ConfigurationBackupEncryptionEnabled
                    'WDigestNotStorePasswordsInMemory' = $LocalizedData.WDigestNotStorePasswordsInMemory
                    'WebProxyAutoDiscoveryDisabled' = $LocalizedData.WebProxyAutoDiscoveryDisabled
                    'ContainBackupCopies' = $LocalizedData.ContainBackupCopies
                    'SMB1ProtocolDisabled' = $LocalizedData.SMB1ProtocolDisabled
                    'EmailNotificationsEnabled' = $LocalizedData.EmailNotificationsEnabled
                    'RemoteRegistryDisabled' = $LocalizedData.RemoteRegistryDisabled
                    'PasswordsRotation' = $LocalizedData.PasswordsRotation
                    'WinRmServiceDisabled' = $LocalizedData.WinRmServiceDisabled
                    'MfaEnabledInBackupConsole' = $LocalizedData.MfaEnabledInBackupConsole
                    'HardenedRepositorySshDisabled' = $LocalizedData.HardenedRepositorySshDisabled
                    'LinuxServersUsingSSHKeys' = $LocalizedData.LinuxServersUsingSSHKeys
                    'RemoteDesktopServiceDisabled' = $LocalizedData.RemoteDesktopServiceDisabled
                    'ConfigurationBackupEnabled' = $LocalizedData.ConfigurationBackupEnabled
                    'WindowsFirewallEnabled' = $LocalizedData.WindowsFirewallEnabled
                    'ConfigurationBackupEnabledAndEncrypted' = $LocalizedData.ConfigurationBackupEnabledAndEncrypted
                    'HardenedRepositoryNotVirtual' = $LocalizedData.HardenedRepositoryNotVirtual
                    'ConfigurationBackupRepositoryNotLocal' = $LocalizedData.ConfigurationBackupRepositoryNotLocal
                    'LossProtectionEnabled' = $LocalizedData.LossProtectionEnabled
                    'TrafficEncryptionEnabled' = $LocalizedData.TrafficEncryptionEnabled
                    'NetBiosDisabled' = $LocalizedData.NetBiosDisabled
                    'LsassProtectedProcess' = $LocalizedData.LsassProtectedProcess
                    'HardenedRepositoryNotContainsNBDProxies' = $LocalizedData.HardenedRepositoryNotContainsNBDProxies
                    'PostgreSqlUseRecommendedSettings' = $LocalizedData.PostgreSqlUseRecommendedSettings
                    'PasswordsComplexityRules' = $LocalizedData.PasswordsComplexityRules
                    'FirewallEnabled' = $LocalizedData.FirewallEnabled
                    'EncryptionPasswordsComplexityRules' = $LocalizedData.EncryptionPasswordsComplexityRules
                    'CredentialsPasswordsComplexityRules' = $LocalizedData.CredentialsPasswordsComplexityRules
                    'CredentialsGuardConfigured' = $LocalizedData.CredentialsGuardConfigured
                    'LinuxAuditBinariesOwnerIsRoot' = $LocalizedData.LinuxAuditBinariesOwnerIsRoot
                    'LinuxAuditdConfigured' = $LocalizedData.LinuxAuditdConfigured
                    'LinuxDisableProblematicServices' = $LocalizedData.LinuxDisableProblematicServices
                    'LinuxOsHasVaRandomization' = $LocalizedData.LinuxOsHasVaRandomization
                    'LinuxOsIsFipsEnabled' = $LocalizedData.LinuxOsIsFipsEnabled
                    'LinuxOsUsesTcpSyncookies' = $LocalizedData.LinuxOsUsesTcpSyncookies
                    'LinuxUsePasswordPolicy' = $LocalizedData.LinuxUsePasswordPolicy
                    'SecureBootEnable' = $LocalizedData.SecureBootEnable
                    'LinuxUseSecurityModule' = $LocalizedData.LinuxUseSecurityModule
                    'LinuxWorldDirectoriesPermissions' = $LocalizedData.LinuxWorldDirectoriesPermissions
                    'BackupServerHighAvailabilityEnabled' = $LocalizedData.BackupServerHighAvailabilityEnabled
                }
                $StatusObj = @{
                    'Ok' = $LocalizedData.Passed
                    'Violation' = $LocalizedData.NotImplemented
                    'UnableToCheck' = $LocalizedData.UnableToDetect
                    'Suppressed' = $LocalizedData.Suppressed
                }
                $OutObj = @()
                foreach ($SecurityCompliance in $SecurityCompliances) {
                    try {
                        $inObj = [ordered] @{
                            $LocalizedData.BestPractices = $RuleTypes[$SecurityCompliance.Type.ToString()]
                            $LocalizedData.Status = $StatusObj[$SecurityCompliance.Status.ToString()]
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning "Security & Compliance summary table: $($_.Exception.Message)"
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "Security & Compliance summary section: $($_.Exception.Message)"
            }

            if ($HealthCheck.Security.BestPractice) {
                $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.NotImplemented } | Set-Style -Style Critical -Property $LocalizedData.Status
                $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Passed } | Set-Style -Style Ok -Property $LocalizedData.Status
                $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.UnableToDetect } | Set-Style -Style Warning -Property $LocalizedData.Status
            }

            $TableParams = @{
                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                List = $false
                ColumnWidths = 70, 30
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }

            try {

                $sampleData = [ordered]@{
                    $LocalizedData.Passed = ($OutObj.$($LocalizedData.Status) | Where-Object { $_ -eq $LocalizedData.Passed } | Measure-Object).Count
                    $LocalizedData.UnableToDetect = ($OutObj.$($LocalizedData.Status) | Where-Object { $_ -eq $LocalizedData.UnableToDetect } | Measure-Object).Count
                    $LocalizedData.NotImplemented = ($OutObj.$($LocalizedData.Status) | Where-Object { $_ -eq $LocalizedData.NotImplemented } | Measure-Object).Count
                    $LocalizedData.Suppressed = ($OutObj.$($LocalizedData.Status) | Where-Object { $_ -eq $LocalizedData.Suppressed } | Measure-Object).Count
                }

                $chartLabels = [string[]]$sampleData.Keys
                $chartValues = [double[]]$sampleData.Values

                $statusCustomPalette = @('#DFF0D0', '#FFF4C7', '#FEDDD7', '#878787')

                $chartFileItem = New-BarChart -Title $LocalizedData.ChartTitle -Values $chartValues -Labels $chartLabels -LabelXAxis $LocalizedData.ChartXAxis -LabelYAxis $LocalizedData.ChartYAxis -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Horizontal -LegendAlignment UpperCenter -AxesMarginsTop 0.5 -TitleFontBold -TitleFontSize 16

            } catch {
                Write-PScriboMessage -IsWarning "Security & Compliance chart section: $($_.Exception.Message)"
            }

            if ($OutObj) {
                Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.Heading {
                    if ($chartFileItem -and ($OutObj.count | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text $LocalizedData.ChartAltText -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    BlankLine
                    $OutObj | Sort-Object -Property $LocalizedData.BestPractices | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Security & Compliance summary'
    }

}