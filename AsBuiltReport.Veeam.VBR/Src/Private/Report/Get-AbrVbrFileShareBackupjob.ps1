
function Get-AbrVbrFileShareBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns file share jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage ($reportTranslate.GetAbrVbrFileShareBackupjob.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'File Share Backup Jobs'
    }

    process {
        try {
            if ($FSBkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -like 'File Backup' -or $_.TypeToString -like 'Object Storage Backup' }) {
                if ($VbrVersion -lt 12.1) {
                    $BSName = $reportTranslate.GetAbrVbrFileShareBackupjob.FileShareBackupJobs
                } else {
                    $BSName = $reportTranslate.GetAbrVbrFileShareBackupjob.UnstructuredDataBackupJobs
                }
                Section -Style Heading3 $BSName {
                    Paragraph ($reportTranslate.GetAbrVbrFileShareBackupjob.Paragraph -f $BSName.ToLower())
                    BlankLine
                    $OutObj = @()
                    foreach ($FSBkjob in $FSBkjobs) {
                        try {

                            $inObj = [ordered] @{
                                $reportTranslate.GetAbrVbrFileShareBackupjob.Name = $FSBkjob.Name
                                $reportTranslate.GetAbrVbrFileShareBackupjob.Type = $FSBkjob.TypeToString
                                $reportTranslate.GetAbrVbrFileShareBackupjob.Status = switch ($FSBkjob.IsScheduleEnabled) {
                                    'False' { $reportTranslate.GetAbrVbrFileShareBackupjob.Disabled }
                                    'True' { $reportTranslate.GetAbrVbrFileShareBackupjob.Enabled }
                                }
                                $reportTranslate.GetAbrVbrFileShareBackupjob.LatestResult = $FSBkjob.info.LatestStatus
                                $reportTranslate.GetAbrVbrFileShareBackupjob.LastRun = switch ($FSBkjob.FindLastSession()) {
                                    $Null { $reportTranslate.GetAbrVbrFileShareBackupjob.Unknown }
                                    default { $FSBkjob.FindLastSession().EndTimeUTC }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "$($BSName.ToLower()) $($FSBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Jobs.Status) {
                        $OutObj | Where-Object { $_.$reportTranslate.GetAbrVbrFileShareBackupjob.LatestResult -eq 'Failed' } | Set-Style -Style Critical -Property $reportTranslate.GetAbrVbrFileShareBackupjob.LatestResult
                        $OutObj | Where-Object { $_.$reportTranslate.GetAbrVbrFileShareBackupjob.LatestResult -eq 'Warning' } | Set-Style -Style Warning -Property $reportTranslate.GetAbrVbrFileShareBackupjob.LatestResult
                        $OutObj | Where-Object { $_.$reportTranslate.GetAbrVbrFileShareBackupjob.Status -eq $reportTranslate.GetAbrVbrFileShareBackupjob.Disabled } | Set-Style -Style Warning -Property $reportTranslate.GetAbrVbrFileShareBackupjob.Status
                        $OutObj | Where-Object { $_.'Scheduled?' -eq 'No' } | Set-Style -Style Warning -Property 'Scheduled?'
                    }

                    $TableParams = @{
                        Name = "$BSName - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 25, 20, 15, 15, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property $reportTranslate.GetAbrVbrFileShareBackupjob.Name | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "$($BSName.ToLower()) Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'File Share Backup Jobs'
    }

}
