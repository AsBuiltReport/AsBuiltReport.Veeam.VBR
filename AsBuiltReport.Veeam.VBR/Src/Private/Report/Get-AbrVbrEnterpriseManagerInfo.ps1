
function Get-AbrVbrEnterpriseManagerInfo {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Enterprise Manager Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        $LocalizedData = $reportTranslate.GetAbrVbrEnterpriseManagerInfo
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Enterprise Manager Information'
    }

    process {
        try {
            if ($BackupServers) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($BackupServer in $BackupServers) {
                        Write-PScriboMessage ($LocalizedData.CollectingNode -f $BackupServer.Name)
                        $EMInfo = [Veeam.Backup.Core.SBackupOptions]::GetEnterpriseServerInfo()
                        if ($EMInfo) {
                            $inObj = [ordered] @{
                                $LocalizedData.ServerName = switch ([string]::IsNullOrEmpty($EMInfo.ServerName)) {
                                    $true { $LocalizedData.NotConnected }
                                    default { $EMInfo.ServerName }
                                }
                                $LocalizedData.ServerURL = switch ([string]::IsNullOrEmpty($EMInfo.URL)) {
                                    $true { $LocalizedData.NotConnected }
                                    default { $EMInfo.URL }
                                }
                                $LocalizedData.SkipLicensePush = $EMInfo.SkipLicensePush
                                $LocalizedData.IsConnected = $EMInfo.IsConnected
                            }
                        }

                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($OutObj) {

                            if ($HealthCheck.Infrastructure.BackupServer) {
                                $OutObj | Where-Object { $_.$LocalizedData.SkipLicensePush -eq 'Yes' } | Set-Style -Style Warning -Property $LocalizedData.SkipLicensePush
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($BackupServer.Name.Split('.')[0])"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.$LocalizedData.SkipLicensePush -eq 'Yes' })) {
                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text $LocalizedData.BestPractice -Bold
                                    Text $LocalizedData.BPEnterpriseManager
                                }
                                BlankLine
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Enterprise Manager Information Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Enterprise Manager Information'
    }

}
