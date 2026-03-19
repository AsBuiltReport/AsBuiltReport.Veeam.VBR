
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
                            'Name' = $Bkjob.Name
                            'Type' = $Bkjob.TypeToString
                            'Status' = switch ($Bkjob.IsScheduleEnabled) {
                                'False' { 'Disabled' }
                                'True' { 'Enabled' }
                            }
                            'Latest Result' = $Bkjob.info.LatestStatus
                            'Scheduled?' = switch ($Bkjob.IsScheduleEnabled) {
                                'True' { 'Yes' }
                                'False' { 'No' }
                                default { 'Unknown' }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Jobs Section: $($_.Exception.Message)"
                    }
                }

                if ($HealthCheck.Jobs.Status) {
                    $OutObj | Where-Object { $_.'Latest Result' -eq 'Failed' } | Set-Style -Style Critical -Property 'Latest Result'
                    $OutObj | Where-Object { $_.'Latest Result' -eq 'Warning' } | Set-Style -Style Warning -Property 'Latest Result'
                    $OutObj | Where-Object { $_.'Latest Result' -eq 'Success' } | Set-Style -Style Ok -Property 'Latest Result'
                    $OutObj | Where-Object { $_.'Status' -eq 'Disabled' } | Set-Style -Style Warning -Property 'Status'
                    $OutObj | Where-Object { $_.'Scheduled?' -eq 'No' } | Set-Style -Style Warning -Property 'Scheduled?'
                }

                $TableParams = @{
                    Name = "Backup Jobs - $VeeamBackupServer"
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
                        'Success' = ($Alljobs | Where-Object { $_ -eq 'Success' } | Measure-Object).Count
                        'Warning' = ($Alljobs | Where-Object { $_ -eq 'Warning' } | Measure-Object).Count
                        'Failed' = ($Alljobs | Where-Object { $_ -eq 'Failed' } | Measure-Object).Count
                        'None' = ($Alljobs | Where-Object { $_ -eq 'None' } | Measure-Object).Count
                    }

                    $chartLabels = [string[]]$sampleData.Keys
                    $chartValues = [double[]]$sampleData.Values

                    $statusCustomPalette = @('#DFF0D0', '#FFF4C7', '#FEDDD7', '#878787')

                    $chartFileItem = New-BarChart -Title 'Jobs Latest Result' -Values $chartValues -Labels $chartLabels -LabelXAxis 'Category' -LabelYAxis 'Value' -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Horizontal -LegendAlignment UpperCenter -AxesMarginsTop 0.5 -TitleFontBold -TitleFontSize 16

                } catch {
                    Write-PScriboMessage -IsWarning "Backup Jobs chart section: $($_.Exception.Message)"
                }
                if ($OutObj) {
                    if ($chartFileItem) {
                        Image -Text 'Backup Jobs - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    Section -Style Heading3 'Backup Jobs' {
                        Paragraph 'The following section lists all backup jobs configured in Veeam Backup & Replication, along with their current status and last run result.'
                        BlankLine
                        Section -ExcludeFromTOC -Style NOTOCHeading4 'Backup Job Status' {
                            $OutObj | Sort-Object -Property Name | Table @TableParams
                        }
                        # Disable until fixing code issues
                        # if ($Bkjobs) {
                        #     try {
                        #         Section -ExcludeFromTOC -Style NOTOCHeading4 'Backup Jobs Duration' {
                        #             $OutObj = @()
                        #             foreach ($Bkjob in $Bkjobs) {
                        #                 try {
                        #                     $Duration = $Null
                        #                     $StandardDeviation = $Null
                        #                     if ($BKJobSession = Get-VBRSession -Job $Bkjob | Select-Object -First 10) {
                        #                         try {
                        #                             $Duration = Get-AvgTimeDuration -InputObject $BKJobSession -StartTime 'CreationTime' -EndTime 'EndTime'
                        #                         } catch {
                        #                             Out-Null
                        #                         }
                        #                     }
                        #                     if ($BKJobSession) {
                        #                         try {
                        #                             $StandardDeviation = (Get-StrdDevDuration -JobSessions $BKJobSession).StandardDeviation
                        #                         } catch {
                        #                             Out-Null
                        #                         }
                        #                     }
                        #                     $inObj = [ordered] @{
                        #                         'Name' = $Bkjob.Name
                        #                         'Last Backup Duration' = Switch ([string]::IsNullOrEmpty($BKJobSession)) {
                        #                             $true { '--' }
                        #                             $false { Get-TimeDuration -TimeSpan (New-TimeSpan -Start $BKJobSession[0].CreationTime -End $BKJobSession[0].EndTime) }
                        #                         }
                        #                         'Last 10 Backup AVG Duration' = Switch ([string]::IsNullOrEmpty($Duration)) {
                        #                             $true { '--' }
                        #                             $false { $Duration }
                        #                             default { 'Unknown' }
                        #                         }
                        #                         'Standard Deviation' = Switch ([string]::IsNullOrEmpty($StandardDeviation)) {
                        #                             $true { '--' }
                        #                             $false { $StandardDeviation }
                        #                             default { 'Unknown' }
                        #                         }
                        #                     }
                        #                     $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        #                 } catch {
                        #                     Write-PScriboMessage -IsWarning "Backup Jobs $($Bkjob.Name) Time Table: $($_.Exception.Message)"
                        #                 }
                        #             }

                        #             $TableParams = @{
                        #                 Name = "Backup Jobs Time - $VeeamBackupServer"
                        #                 List = $false
                        #                 ColumnWidths = 40, 20, 20, 20
                        #             }
                        #             if ($Report.ShowTableCaptions) {
                        #                 $TableParams['Caption'] = "- $($TableParams.Name)"
                        #             }

                        #             $OutObj | Sort-Object -Property Name | Table @TableParams
                        #         }
                        #     } catch {
                        #         Write-PScriboMessage -IsWarning "Backup Jobs Time Section: $($_.Exception.Message)"
                        #     }
                        # }
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
