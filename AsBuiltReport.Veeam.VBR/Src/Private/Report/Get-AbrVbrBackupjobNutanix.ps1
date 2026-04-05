
function Get-AbrVbrBackupjobNutanix {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Nutanix backup jobs created in Veeam Backup & Replication.
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
        $LocalizedData = $reportTranslate.GetAbrVbrBackupjobNutanix
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Nutanix Backup Jobs'
    }

    process {
        try {
            if ($Bkjobs = [Veeam.Backup.Core.CBackupJob]::GetAll() | Where-Object { $_.TypeToString -like '*Nutanix*' } | Sort-Object -Property 'Name') {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $Bkjob.Name
                                $LocalizedData.Type = $Bkjob.TypeToString
                                $LocalizedData.Status = switch ($Bkjob.IsScheduleEnabled) {
                                    'False' { $LocalizedData.Disabled }
                                    'True' { $LocalizedData.Enabled }
                                }
                                $LocalizedData.LatestResult = $Bkjob.info.LatestStatus
                                $LocalizedData.Scheduled = switch ($Bkjob.IsScheduleEnabled) {
                                    'True' { $LocalizedData.Yes }
                                    'False' { $LocalizedData.No }
                                    default { $LocalizedData.Unknown }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Nutanix Backup Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Jobs.Status) {
                        $OutObj | Where-Object { $_.$LocalizedData.LatestResult -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_.$LocalizedData.LatestResult -eq 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_.$LocalizedData.LatestResult -eq 'Success' } | Set-Style -Style Ok -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_.$LocalizedData.Status -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.Status
                        $OutObj | Where-Object { $_.$LocalizedData.Scheduled -eq $LocalizedData.No } | Set-Style -Style Warning -Property $LocalizedData.Scheduled
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 41, 20, 13, 13, 13
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Nutanix Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Nutanix Backup Jobs'
    }

}
