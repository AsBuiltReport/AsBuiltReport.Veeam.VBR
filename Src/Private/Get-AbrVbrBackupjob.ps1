
function Get-AbrVbrBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.4
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
            if ((Get-VBRJob -WarningAction SilentlyContinue).count -gt 0) {
                $OutObj = @()
                $Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-object {$_.TypeToString -ne 'Windows Agent Backup' -and $_.TypeToString -ne 'Hyper-V Replication' -and $_.TypeToString -ne 'VMware Replication'}
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
                            'Target Repository' = Switch ($Bkjob.info.TargetRepositoryId) {
                                '00000000-0000-0000-0000-000000000000' {$Bkjob.TargetDir}
                                {$Null -eq (Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name} {(Get-VBRBackupRepository -ScaleOut | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                                default {(Get-VBRBackupRepository | Where-Object {$_.Id -eq $Bkjob.info.TargetRepositoryId}).Name}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }

                $TableParams = @{
                    Name = "Backup Jobs - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 25, 20, 15, 15, 25
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
                    if ((Get-VSBJob -ErrorAction SilentlyContinue).GetLastResult()) {
                        $Alljobs += (Get-VSBJob).GetLastResult()
                    }
                    $sampleData = $Alljobs | Group-Object
                    $exampleChart = New-Chart -Name BackupJobs -Width 600 -Height 400

                    $addChartAreaParams = @{
                        Chart                 = $exampleChart
                        Name                  = 'BackupJobs'
                        AxisXTitle            = 'Status'
                        AxisYTitle            = 'Count'
                        NoAxisXMajorGridLines = $true
                        NoAxisYMajorGridLines = $true
                    }
                    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                    $addChartSeriesParams = @{
                        Chart             = $exampleChart
                        ChartArea         = $exampleChartArea
                        Name              = 'exampleChartSeries'
                        XField            = 'Name'
                        YField            = 'Count'
                        Palette           = 'Green'
                        ColorPerDataPoint = $true
                    }
                    $sampleData | Add-ColumnChartSeries @addChartSeriesParams

                    $addChartTitleParams = @{
                        Chart     = $exampleChart
                        ChartArea = $exampleChartArea
                        Name      = 'BackupJob'
                        Text      = 'Jobs Latest Result'
                        Font      = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                    }
                    Add-ChartTitle @addChartTitleParams

                    $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru

                    if ($PassThru)
                    {
                        Write-Output -InputObject $chartFileItem
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Account Security Assessment Table)"
                }
                if ($OutObj) {
                    if ($chartFileItem) {
                        Image -Text 'Backup Repository - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
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
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}
