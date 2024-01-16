
function Get-AbrVbrBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.4
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
        Write-PscriboMessage "Discovering Veeam VBR Backup jobs information from $System."
    }

    process {
        try {
            if (($Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-object {$_.TypeToString -ne 'Windows Agent Backup' -and $_.TypeToString -ne 'Hyper-V Replication' -and $_.TypeToString -ne 'VMware Replication'} | Sort-Object -Property Name).count -gt 0) {
                $OutObj = @()
                foreach ($Bkjob in $Bkjobs) {
                    try {
                        Write-PscriboMessage "Discovered $($Bkjob.Name) backup job."
                        $inObj = [ordered] @{
                            'Name' = $Bkjob.Name
                            'Type' = $Bkjob.TypeToString
                            'Status' = Switch ($Bkjob.IsScheduleEnabled) {
                                'False' {'Disabled'}
                                'True' {'Enabled'}
                            }
                            'Latest Result' = $Bkjob.info.LatestStatus
                            'Scheduled?' = Switch ($Bkjob.IsScheduleEnabled) {
                                'True' {'Yes'}
                                'False' {'No'}
                                default {'Unknown'}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Backup Jobs Section: $($_.Exception.Message)"
                    }
                }

                if ($HealthCheck.Jobs.Status) {
                    $OutObj | Where-Object { $_.'Latest Result' -eq 'Failed' } | Set-Style -Style Critical -Property 'Latest Result'
                    $OutObj | Where-Object { $_.'Latest Result' -eq 'Warning' } | Set-Style -Style Warning -Property 'Latest Result'
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
                    $sampleData = $Alljobs | Group-Object

                    $chartFileItem = Get-ColumnChart -SampleData $sampleData -ChartName 'BackupJobs' -XField 'Name' -YField 'Count' -ChartAreaName 'Infrastructure' -AxisXTitle 'Status' -AxisYTitle 'Count' -ChartTitleName 'BackupJobs' -ChartTitleText 'Jobs Latest Result'

                } catch {
                    Write-PscriboMessage -IsWarning "Backup Jobs chart section: $($_.Exception.Message)"
                }
                if ($OutObj) {
                    if ($chartFileItem) {
                        Image -Text 'Backup Repository - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    Section -Style Heading3 'Backup Jobs' {
                        Paragraph "The following section list backup jobs created in Veeam Backup & Replication."
                        BlankLine
                        $OutObj | Sort-Object -Property Name |Table @TableParams
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}

}
