function Get-AbrVbrBackupsRPSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backups Restore Point Summary
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.11
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
        Write-PScriboMessage "RestorePoint InfoLevel set at $($InfoLevel.Jobs.Restores)."
    }

    process {
        try {
            $BackupJobs = Get-VBRBackup | Sort-Object -Property Name
            $BackupJobs += Get-VBRTapeBackup -WarningAction SilentlyContinue | Sort-Object -Property Name

            if ($BackupJobs) {
                Write-PScriboMessage "Collecting Veeam VBR Restore Point."
                $RestorePointInfo = @()
                foreach ($BackupJob in $BackupJobs) {
                    if ($BackupJobRestorePoints = Get-VBRRestorePoint -Backup $BackupJob) {
                        try {
                            if ($FullRP = $BackupJobRestorePoints |  Where-Object { $_.Type -eq 'Full' -and -Not $_.IsCorrupted -and $_.CompletionTimeUtc -gt $_.CreationTimeUTC }) {
                                try {
                                    $FullDuration = Get-TimeDurationSum -InputObject $FullRP -StartTime 'CreationTimeUTC' -EndTime 'CompletionTimeUtc'
                                    $FullDurationAvg = Get-TimeDuration -TimeSpan ([timespan]::fromseconds(($FullDuration / $FullRP.Count)))
                                } catch {
                                    $FullDurationAvg = '--'
                                }
                            } else {
                                $FullDurationAvg = '--'
                            }

                            if ($IncrementRP = $BackupJobRestorePoints |  Where-Object { $_.Type -eq 'Increment' -and -Not $_.IsCorrupted -and $_.CompletionTimeUtc -gt $_.CreationTimeUTC } ) {
                                try {
                                    $IncrementDuration = Get-TimeDurationSum -InputObject $IncrementRP -StartTime 'CreationTimeUTC' -EndTime 'CompletionTimeUtc'
                                    $IncrementDurationAvg = Get-TimeDuration -TimeSpan ([timespan]::fromseconds(($IncrementDuration / $IncrementRP.Count)))
                                } catch {
                                    $IncrementDurationAvg = '--'
                                }
                            } else {
                                $IncrementDurationAvg = '--'
                            }

                            $inObj = [ordered] @{
                                'Job Name' = $BackupJob.Name
                                'Oldest Backup' = $BackupJobRestorePoints[0].CreationTimeUTC
                                'Newest Backup' = $BackupJobRestorePoints[-1].CreationTimeUTC
                                'Full Count' = ($BackupJobRestorePoints |  Where-Object { $_.Type -eq 'Full' }).Count
                                'Increment Count ' = ($BackupJobRestorePoints |  Where-Object { $_.Type -eq 'Increment' }).Count
                                'Average Full Duration' = $FullDurationAvg
                                'Average Increment Duration ' = $IncrementDurationAvg
                            }
                            $RestorePointInfo += [PSCustomObject]$InObj

                        } catch {
                            Write-PScriboMessage -IsWarning "Restore Point table: $($_.Exception.Message)"
                        }
                    }
                }

                $TableParams = @{
                    Name = "Restore Points - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 22, 14, 14, 12, 12, 14, 12
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $RestorePointInfo | Sort-Object -Property 'Job Name' | Table @TableParams

            }
        } catch {
            Write-PScriboMessage -IsWarning "Restore Point Section: $($_.Exception.Message)"
        }
    }
    end {}
}