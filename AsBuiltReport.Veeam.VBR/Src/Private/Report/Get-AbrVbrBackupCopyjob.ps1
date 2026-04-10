
function Get-AbrVbrBackupCopyjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns backup copy jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.0
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
        Write-PScriboMessage "Discovering Veeam VBR Backup Copy jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupCopyjob
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Copy Jobs'
    }

    process {
        try {
            if ($BkCopyjobs = Get-VBRBackupCopyJob -WarningAction SilentlyContinue) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($BkCopyjob in $BkCopyjobs) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $BkCopyjob.Name
                                $LocalizedData.CopyMode = $BkCopyjob.Mode
                                $LocalizedData.Status = switch ($BkCopyjob.JobEnabled) {
                                    'False' { $LocalizedData.Disabled }
                                    'True' { $LocalizedData.Enabled }
                                }
                                $LocalizedData.LatestResult = $BkCopyjob.LastResult
                                $LocalizedData.ScheduledQ = $BkCopyjob.ScheduleOptions.Type
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Backup Copy Jobs $($BkCopyjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Jobs.Status) {
                        $OutObj | Where-Object { $_."$($LocalizedData.LatestResult)" -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_."$($LocalizedData.LatestResult)" -eq 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_."$($LocalizedData.Status)" -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.Status
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 40, 15, 15, 15, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Copy Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Copy Jobs'
    }

}
