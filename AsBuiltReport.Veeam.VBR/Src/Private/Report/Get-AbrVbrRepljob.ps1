
function Get-AbrVbrRepljob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns replication jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Replication jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrRepljob
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Replication Jobs'
    }

    process {
        try {
            if ($Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -eq 'VMware Replication' -or $_.TypeToString -eq 'Hyper-V Replication' } | Sort-Object -Property Name) {
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
                                $LocalizedData.LastRun = switch ($Bkjob.FindLastSession().EndTimeUTC) {
                                    $null { $LocalizedData.Never }
                                    default { $Bkjob.FindLastSession().EndTimeUTC }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Replication Jobs $($Bkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 25, 20, 15, 15, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property Name | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Replication Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Replication Jobs'
    }

}
