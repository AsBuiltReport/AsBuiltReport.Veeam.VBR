
function Get-AbrVbrBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.23
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
        Write-PScriboMessage "Discovering Veeam VBR Backup jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupjob
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Jobs'
    }

    process {
        try {
            if ($Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -ne 'Windows Agent Backup' -and $_.TypeToString -ne 'Hyper-V Replication' -and $_.TypeToString -ne 'VMware Replication' } | Sort-Object -Property Name) {
                $Bkjobs += [Veeam.Backup.Core.CBackupJob]::GetAll() | Where-Object { $_.TypeToString -like '*Nutanix*' } | Sort-Object -Property 'Name'
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
                        Write-PScriboMessage -IsWarning "Backup Jobs Section: $($_.Exception.Message)"
                    }
                }

                if ($HealthCheck.Jobs.Status) {
                    $OutObj | Where-Object { $_.$($LocalizedData.LatestResult) -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LatestResult
                    $OutObj | Where-Object { $_.$($LocalizedData.LatestResult) -eq 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LatestResult
                    $OutObj | Where-Object { $_.$($LocalizedData.LatestResult) -eq 'Success' } | Set-Style -Style Ok -Property $LocalizedData.LatestResult
                    $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.Status
                    $OutObj | Where-Object { $_.$($LocalizedData.Scheduled) -eq $LocalizedData.No } | Set-Style -Style Warning -Property $LocalizedData.Scheduled
                }

                $TableParams = @{
                    Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 41, 20, 13, 13, 13
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                try {
                    $Alljobs = @()
                    if ($Bkjobs.info.LatestStatus) {
                        $Alljobs += $Bkjobs.info.LatestStatus
                    }
                    if ((Get-VBRTapeJob -ErrorAction SilentlyContinue).LastResult) {
                        $Alljobs += (Get-VBRTapeJob).LastResult
                    }
                    if ((Get-VBRSureBackupJob -ErrorAction SilentlyContinue).LastResult) {
                        $Alljobs += (Get-VBRSureBackupJob -ErrorAction SilentlyContinue).LastResult
                    }

                    $sampleData = [ordered]@{
                        ($LocalizedData.Success) = ($Alljobs | Where-Object { $_ -eq 'Success' } | Measure-Object).Count
                        ($LocalizedData.Warning) = ($Alljobs | Where-Object { $_ -eq 'Warning' } | Measure-Object).Count
                        ($LocalizedData.Failed) = ($Alljobs | Where-Object { $_ -eq 'Failed' } | Measure-Object).Count
                        ($LocalizedData.None) = ($Alljobs | Where-Object { $_ -eq 'None' } | Measure-Object).Count
                    }

                    $chartLabels = [string[]]$sampleData.Keys
                    $chartValues = [double[]]$sampleData.Values

                    $statusCustomPalette = @('#DFF0D0', '#FFF4C7', '#FEDDD7', '#878787')

                    $chartFileItem = New-BarChart -Title $LocalizedData.ChartTitle -Values $chartValues -Labels $chartLabels -LabelXAxis 'Category' -LabelYAxis 'Value' -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Horizontal -LegendAlignment UpperCenter -AxesMarginsTop 0.5 -TitleFontBold -TitleFontSize 16

                } catch {
                    Write-PScriboMessage -IsWarning "Backup Jobs chart section: $($_.Exception.Message)"
                }
                if ($OutObj) {
                    if ($chartFileItem) {
                        Image -Text $LocalizedData.ChartText -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        Section -ExcludeFromTOC -Style NOTOCHeading4 $LocalizedData.JobStatusSection {
                            $OutObj | Sort-Object -Property Name | Table @TableParams
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Jobs'
    }

}
