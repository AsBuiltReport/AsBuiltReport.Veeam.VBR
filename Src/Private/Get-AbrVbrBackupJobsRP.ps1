function Get-AbrVbrBackupJobsRP {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Restore Point
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.12
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
            if ($BackupJobs = Get-VBRBackup | Sort-Object -Property Name) {
                Write-PScriboMessage "Collecting Veeam VBR Restore Point."
                Section -Style Heading3 'Backup Restore Points' {
                    Paragraph "The following section details per Backup Job restore points."
                    BlankLine
                    foreach ($BackupJob in $BackupJobs) {
                        if ($BackupJobRestorePoints = Get-VBRRestorePoint -Backup $BackupJob | Sort-Object -Property VMName, CreationTimeUt, Type) {
                            Section -ExcludeFromTOC -Style NOTOCHeading4  $BackupJob.Name {
                                $RestorePointInfo = @()
                                foreach ($RestorePoint in $BackupJobRestorePoints) {
                                    try {
                                        $DedupRatio = $RestorePoint.GetStorage().stats.DedupRatio
                                        $CompressRatio = $RestorePoint.GetStorage().stats.CompressRatio
                                        if ($DedupRatio -gt 1) { $DedupRatio = 100 / $DedupRatio } else { $DedupRatio = 1 }
                                        if ($CompressRatio -gt 1) { $CompressRatio = 100 / $CompressRatio } else { $CompressRatio = 1 }

                                        $inObj = [ordered] @{
                                            'VM Name' = $RestorePoint.VMName
                                            'Backup Type' = $RestorePoint.Algorithm
                                            'Backup Size' = (ConvertTo-FileSizeString -Size $RestorePoint.GetStorage().stats.BackupSize)
                                            'Dedub Ratio' = [Math]::Round($DedupRatio, 2)
                                            'Compress Ratio' = [Math]::Round($CompressRatio, 2)
                                            'Reduction' = [Math]::Round(($DedupRatio * $CompressRatio), 2)
                                        }
                                        $RestorePointInfo += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Restore Point table: $($_.Exception.Message)"
                                    }
                                }

                                $TableParams = @{
                                    Name = "Restore Points - $($BackupJob.Name)"
                                    List = $false
                                    ColumnWidths = 40, 12, 12, 12, 12, 12
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $RestorePointInfo | Table @TableParams
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Restore Point Section: $($_.Exception.Message)"
        }
    }
    end {}
}