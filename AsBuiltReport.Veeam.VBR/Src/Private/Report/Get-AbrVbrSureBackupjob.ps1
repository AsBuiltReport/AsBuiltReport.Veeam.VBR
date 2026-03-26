
function Get-AbrVbrSureBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns surebackup jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR SureBackup jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrSureBackupjob
        Show-AbrDebugExecutionTime -Start -TitleMessage 'SureBackup Jobs'
    }

    process {
        try {
            if ($SBkjobs = Get-VBRSureBackupJob | Sort-Object -Property 'Job Name') {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($SBkjob in $SBkjobs) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $SBkjob.Name
                                $LocalizedData.Status = switch ($SBkjob.IsEnabled) {
                                    'False' { $LocalizedData.Disabled }
                                    'True' { $LocalizedData.Enabled }
                                }
                                $LocalizedData.ScheduleEnabled = switch ($SBkjob.ScheduleEnabled) {
                                    'False' { $LocalizedData.NotScheduled }
                                    'True' { $LocalizedData.Scheduled }
                                }
                                $LocalizedData.LatestResult = $SBkjob.LastResult
                                $LocalizedData.VirtualLab = switch ($SBkjob.VirtualLab.Name) {
                                    $true { $LocalizedData.NotApplicable }
                                    $false { $SBkjob.VirtualLab.Name }
                                    default { $LocalizedData.NA }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "SureBackup Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 15, 15, 15, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "SureBackup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'SureBackup Jobs'
    }

}
