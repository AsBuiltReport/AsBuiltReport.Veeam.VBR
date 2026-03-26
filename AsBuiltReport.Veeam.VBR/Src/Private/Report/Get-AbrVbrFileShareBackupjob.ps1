
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
        $LocalizedData = $reportTranslate.GetAbrVbrFileShareBackupjob
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'File Share Backup Jobs'
    }

    process {
        try {
            if ($FSBkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -like 'File Backup' -or $_.TypeToString -like 'Object Storage Backup' }) {
                if ($VbrVersion -lt 12.1) {
                    $BSName = $LocalizedData.FileShareBackupJobs
                } else {
                    $BSName = $LocalizedData.UnstructuredDataBackupJobs
                }
                Section -Style Heading3 $BSName {
                    Paragraph ($LocalizedData.Paragraph -f $BSName.ToLower())
                    BlankLine
                    $OutObj = @()
                    foreach ($FSBkjob in $FSBkjobs) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $FSBkjob.Name
                                $LocalizedData.Type = $FSBkjob.TypeToString
                                $LocalizedData.Status = switch ($FSBkjob.IsScheduleEnabled) {
                                    'False' { $LocalizedData.Disabled }
                                    'True' { $LocalizedData.Enabled }
                                }
                                $LocalizedData.LatestResult = $FSBkjob.info.LatestStatus
                                $LocalizedData.LastRun = switch ($FSBkjob.FindLastSession()) {
                                    $Null { $LocalizedData.Unknown }
                                    default { $FSBkjob.FindLastSession().EndTimeUTC }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "$($BSName.ToLower()) $($FSBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Jobs.Status) {
                        $OutObj | Where-Object { $_.$LocalizedData.LatestResult -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_.$LocalizedData.LatestResult -eq 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_.$LocalizedData.Status -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.Status
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
                    $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
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
