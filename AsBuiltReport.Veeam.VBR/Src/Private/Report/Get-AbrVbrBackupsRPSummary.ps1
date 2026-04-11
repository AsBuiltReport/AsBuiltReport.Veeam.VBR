function Get-AbrVbrBackupsRPSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backups Restore Point Summary
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
        $LocalizedData = $reportTranslate.GetAbrVbrBackupsRPSummary
        Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Jobs.Restores)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Restore Points'
    }

    process {
        try {
            $BackupJobs = Get-VBRBackup | Sort-Object -Property Name
            $BackupJobs += Get-VBRTapeBackup -WarningAction SilentlyContinue | Sort-Object -Property Name

            if ($BackupJobs) {
                Write-PScriboMessage $LocalizedData.Collecting
                $RestorePointInfo = @()
                foreach ($BackupJob in $BackupJobs) {
                    if ($BackupJobRestorePoints = Get-VBRRestorePoint -Backup $BackupJob) {
                        try {
                            if ($FullRP = $BackupJobRestorePoints | Where-Object { $_.Type -eq 'Full' -and -not $_.IsCorrupted -and $_.CompletionTimeUtc -gt $_.CreationTimeUTC }) {
                                try {
                                    $FullDuration = Get-TimeDurationSum -InputObject $FullRP -StartTime 'CreationTimeUTC' -EndTime 'CompletionTimeUtc'
                                    $FullDurationAvg = Get-TimeDuration -TimeSpan ([timespan]::fromseconds(($FullDuration / $FullRP.Count)))
                                } catch {
                                    $FullDurationAvg = $LocalizedData.NA
                                }
                            } else {
                                $FullDurationAvg = $LocalizedData.NA
                            }

                            if ($IncrementRP = $BackupJobRestorePoints | Where-Object { $_.Type -eq 'Increment' -and -not $_.IsCorrupted -and $_.CompletionTimeUtc -gt $_.CreationTimeUTC } ) {
                                try {
                                    $IncrementDuration = Get-TimeDurationSum -InputObject $IncrementRP -StartTime 'CreationTimeUTC' -EndTime 'CompletionTimeUtc'
                                    $IncrementDurationAvg = Get-TimeDuration -TimeSpan ([timespan]::fromseconds(($IncrementDuration / $IncrementRP.Count)))
                                } catch {
                                    $IncrementDurationAvg = $LocalizedData.NA
                                }
                            } else {
                                $IncrementDurationAvg = $LocalizedData.NA
                            }

                            $inObj = [ordered] @{
                                $LocalizedData.JobName = $BackupJob.Name
                                $LocalizedData.OldestBackup = $BackupJobRestorePoints[0].CreationTimeUTC
                                $LocalizedData.NewestBackup = $BackupJobRestorePoints[-1].CreationTimeUTC
                                $LocalizedData.FullCount = ($BackupJobRestorePoints | Where-Object { $_.Type -eq 'Full' }).Count
                                $LocalizedData.IncrementCount = ($BackupJobRestorePoints | Where-Object { $_.Type -eq 'Increment' }).Count
                                $LocalizedData.AverageFullDuration = $FullDurationAvg
                                $LocalizedData.AverageIncrementDuration = $IncrementDurationAvg
                            }
                            $RestorePointInfo += [pscustomobject](ConvertTo-HashToYN $inObj)

                        } catch {
                            Write-PScriboMessage -IsWarning "Restore Point table: $($_.Exception.Message)"
                        }
                    }
                }

                $TableParams = @{
                    Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 22, 14, 14, 12, 12, 14, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $RestorePointInfo | Sort-Object -Property $LocalizedData.JobName | Table @TableParams

            }
        } catch {
            Write-PScriboMessage -IsWarning "Restore Point Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Restore Points'
    }
}
