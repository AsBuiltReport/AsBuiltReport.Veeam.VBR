
function Get-AbrVbrInventorySummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Inventory Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.1
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
        Write-PscriboMessage "Discovering Veeam VBR Inventory Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $vCenter = Get-VBRServer | Where-Object {$_.Type -eq 'VC'}
                $ESXi = Get-VBRServer | Where-Object {$_.Type -eq 'ESXi'}
                $HvCluster = Get-VBRServer | Where-Object {$_.Type -eq 'HvCluster'}
                $HvServer = Get-VBRServer | Where-Object {$_.Type -eq 'HvServer'}
                $ProtectionGroups = Get-VBRProtectionGroup
                if ($VbrVersion -lt 12.1) {
                    $Shares = Get-VBRNASServer -WarningAction SilentlyContinue
                } else {
                    $FileServers = Get-VBRUnstructuredServer | Where-Object {$_.Type -eq "FileServer"}
                    $NASFillers = Get-VBRUnstructuredServer | Where-Object {$_.Type -eq "SANSMB"}
                    $FileShares = Get-VBRUnstructuredServer | Where-Object {$_.Type -eq "SMB" -or $_.Type -eq "NFS"}
                    $ObjectStorage = Get-VBRUnstructuredServer | Where-Object {$_.Type -eq "AzureBlobServer" -or $_.Type -eq "AmazonS3Server" -or $_.Type -eq "S3CompatibleServer"}
                }
                $inObj = [ordered] @{
                    'vCenter Servers' = $vCenter.Count
                    'ESXi Servers' = $ESXi.Count
                    'Hyper-V Clusters' = $HvCluster.Count
                    'Hyper-V Servers' = $HvServer.Count
                    'Protection Groups' = $ProtectionGroups.Count
                }

                if ($VbrVersion -lt 12.1) {
                    $inObj.add('File Shares',$Shares.Count)
                } else {
                    $inObj.add('File Server',$FileServers.Count)
                    $inObj.add('NAS Fillers',$NASFillers.Count)
                    $inObj.add('File Shares',$FileShares.Count)
                    $inObj.add('Object Storage',$ObjectStorage.Count)
                }

                $OutObj += [pscustomobject]$inobj
            }
            catch {
                Write-PscriboMessage -IsWarning "Inventory Summary Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "Inventory Summary - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($Options.EnableCharts) {
                try {
                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category';  Expression = {$_.key}},@{ Name = 'Value';  Expression = {$_.value}} | Sort-Object -Property 'Category'

                    $exampleChart = New-Chart -Name Inventory -Width 600 -Height 400

                    $addChartAreaParams = @{
                        Chart = $exampleChart
                        Name  = 'exampleChartArea'
                    }
                    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                    $addChartSeriesParams = @{
                        Chart             = $exampleChart
                        ChartArea         = $exampleChartArea
                        Name              = 'exampleChartSeries'
                        XField            = 'Category'
                        YField            = 'Value'
                        Palette           = 'Green'
                        ColorPerDataPoint = $true
                    }
                    $exampleChartSeries = $sampleData | Add-PieChartSeries @addChartSeriesParams -PassThru

                    $addChartLegendParams = @{
                        Chart             = $exampleChart
                        Name              = 'Infrastructure'
                        TitleAlignment    = 'Center'
                    }
                    Add-ChartLegend @addChartLegendParams

                    $addChartTitleParams = @{
                        Chart     = $exampleChart
                        ChartArea = $exampleChartArea
                        Name      = ' '
                        Text      = ' '
                        Font      = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                    }
                    Add-ChartTitle @addChartTitleParams

                    $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru
                }
                catch {
                    Write-PscriboMessage -IsWarning $($_.Exception.Message)
                }
            }
            if ($OutObj) {
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Inventory' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Inventory - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Inventory Summary Section: $($_.Exception.Message)"s
        }
    }
    end {}

}