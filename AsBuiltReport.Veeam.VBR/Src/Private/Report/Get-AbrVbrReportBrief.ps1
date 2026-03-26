
function Get-AbrVbrReportBrief {
    <#
    .SYNOPSIS
    Used by As Built Report to generate a one-page report brief for Veeam VBR
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.9.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        GitHub:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PScriboMessage "Generating Veeam VB&R Report Brief from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrReportBrief
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Report Brief'
    }

    process {
        try {
            Section -Style Heading1 $LocalizedData.Heading -ExcludeFromTOC {
                Paragraph $LocalizedData.Paragraph
                BlankLine

                # Report metadata
                try {
                    $ServerSession = Get-VBRServerSession
                    $inObj = [ordered] @{
                        $LocalizedData.ReportName = $Report.Name
                        $LocalizedData.ReportVersion = $Report.Version
                        $LocalizedData.TargetServer = $VeeamBackupServer
                        $LocalizedData.ServerFQDN = $ServerSession.Server
                        $LocalizedData.VBRProductVersion = $VbrVersion
                        $LocalizedData.GeneratedOn = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                    }
                    $OutObj = [pscustomobject]$inObj

                    $TableParams = @{
                        Name = "$($LocalizedData.TableReportOverview) - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                } catch {
                    Write-PScriboMessage -IsWarning "Report Brief - Report Overview Section: $($_.Exception.Message)"
                }

                BlankLine

                # License summary
                try {
                    if ($VbrLicenses) {
                        $inObj = [ordered] @{
                            $LocalizedData.LicenseType = $VbrLicenses.Type
                            $LocalizedData.LicenseStatus = $VbrLicenses.Status
                            $LocalizedData.LicensedInstances = $VbrLicenses.LicensedInstancesNumber
                            $LocalizedData.UsedInstances = $VbrLicenses.UsedInstancesNumber
                            $LocalizedData.ExpirationDate = switch ($VbrLicenses.ExpirationDate) {
                                $Null { $LocalizedData.NA }
                                default { $VbrLicenses.ExpirationDate.ToShortDateString() }
                            }
                            $LocalizedData.SupportExpiration = switch ($VbrLicenses.SupportExpirationDate) {
                                $Null { $LocalizedData.NA }
                                default { $VbrLicenses.SupportExpirationDate.ToShortDateString() }
                            }
                        }
                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                        $TableParams = @{
                            Name = "$($LocalizedData.TableLicenseSummary) - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Report Brief - License Summary Section: $($_.Exception.Message)"
                }

                BlankLine

                # Infrastructure counts summary
                try {
                    $ViProxyCount = (Get-VBRViProxy -ErrorAction SilentlyContinue | Measure-Object).Count
                    $HvProxyCount = (Get-VBRHvProxy -ErrorAction SilentlyContinue | Measure-Object).Count
                    $RepoCount = (Get-VBRBackupRepository -ErrorAction SilentlyContinue | Measure-Object).Count
                    $SOBRCount = (Get-VBRBackupRepository -ScaleOut -ErrorAction SilentlyContinue | Measure-Object).Count
                    $ManagedServerCount = (Get-VBRServer -ErrorAction SilentlyContinue | Measure-Object).Count
                    $BackupJobCount = (Get-VBRJob -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Measure-Object).Count
                    $ComputerBackupJobCount = (Get-VBRComputerBackupJob -ErrorAction SilentlyContinue | Measure-Object).Count
                    $BackupCopyJobCount = (Get-VBRBackupCopyJob -ErrorAction SilentlyContinue | Measure-Object).Count
                    $ProtectedVmCount = try { (Get-VBRRestorePoint | Select-Object { $_.VmName } -Unique).Count } catch { 0 }

                    $inObj = [ordered] @{
                        'VMware Backup Proxies' = $ViProxyCount
                        'Hyper-V Backup Proxies' = $HvProxyCount
                        'Backup Repositories' = $RepoCount
                        'Scale-Out Backup Repositories' = $SOBRCount
                        'Managed Servers' = $ManagedServerCount
                        'Backup Jobs' = $BackupJobCount
                        'Computer Backup Jobs' = $ComputerBackupJobCount
                        'Backup Copy Jobs' = $BackupCopyJobCount
                        'Protected VMs' = $ProtectedVmCount
                    }
                    $OutObj = [pscustomobject]$inObj

                    $TableParams = @{
                        Name = "Infrastructure Summary - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 60, 40
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                } catch {
                    Write-PScriboMessage -IsWarning "Report Brief - Infrastructure Summary Section: $($_.Exception.Message)"
                }

                BlankLine

                # Report scope — which InfoLevel sections are enabled
                try {
                    $OutObj = @()
                    $ScopeMap = [ordered] @{
                        'Backup Infrastructure' = ($InfoLevel.Infrastructure.PSObject.Properties.Value | Measure-Object -Maximum).Maximum
                        'Tape Infrastructure' = ($InfoLevel.Tape.PSObject.Properties.Value | Measure-Object -Maximum).Maximum
                        'Inventory' = ($InfoLevel.Inventory.PSObject.Properties.Value | Measure-Object -Maximum).Maximum
                        'Storage Infrastructure' = ($InfoLevel.Storage.PSObject.Properties.Value | Measure-Object -Maximum).Maximum
                        'Replication' = ($InfoLevel.Replication.PSObject.Properties.Value | Measure-Object -Maximum).Maximum
                        'Cloud Connect' = ($InfoLevel.CloudConnect.PSObject.Properties.Value | Measure-Object -Maximum).Maximum
                        'Jobs' = ($InfoLevel.Jobs.PSObject.Properties.Value | Measure-Object -Maximum).Maximum
                    }

                    foreach ($Entry in $ScopeMap.GetEnumerator()) {
                        $StatusText = switch ($Entry.Value) {
                            0 { 'Disabled' }
                            1 { 'Enabled (Summary)' }
                            2 { 'Enabled (Advanced Summary)' }
                            3 { 'Enabled (Detailed)' }
                            default { "Enabled (Level $($Entry.Value))" }
                        }
                        $inObj = [ordered] @{
                            'Section' = $Entry.Key
                            'Detail Level' = $StatusText
                        }
                        $OutObj += [pscustomobject]$inObj
                    }

                    $TableParams = @{
                        Name = "Report Scope - $VeeamBackupServer"
                        List = $false
                        Headers = 'Section', 'Detail Level'
                        Columns = 'Section', 'Detail Level'
                        ColumnWidths = 60, 40
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                } catch {
                    Write-PScriboMessage -IsWarning "Report Brief - Report Scope Section: $($_.Exception.Message)"
                }
            }
            PageBreak
        } catch {
            Write-PScriboMessage -IsWarning "Report Brief Section: $($_.Exception.Message)"
        }
    }

    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Report Brief'
    }
}
