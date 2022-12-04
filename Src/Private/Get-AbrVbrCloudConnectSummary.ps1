function Get-AbrVbrCloudConnectSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Cloud Connect Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.0
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Connect Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $CloudConnectRR = Get-VBRCloudHardwarePlan
                $CloudConnectTenant = Get-VBRCloudTenant
                $CloudConnectGW = Get-VBRCloudGateway
                $CloudConnectGWPool = Get-VBRCloudGatewayPool
                $CloudConnectPublicIP = Get-VBRCloudPublicIP
                $CloudConnectBS = (Get-VBRCloudTenant).Resources.Repository

                $inObj = [ordered] @{
                    'Cloud Gateways' = $CloudConnectGW.Count
                    'Gateway Pools' = $CloudConnectGWPool.Count
                    'Tenants' = $CloudConnectTenant.Count
                    'Backup Storage' = $CloudConnectBS.Count
                    'Public IP Addresses' = $CloudConnectPublicIP.Count
                    'Hardware Plans' = $CloudConnectRR.Count
                }
                $OutObj += [pscustomobject]$inobj
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }

            $TableParams = @{
                Name = "Cloud Connect Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($Options.EnableCharts) {
                try {
                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category';  Expression = {$_.key}},@{ Name = 'Value';  Expression = {$_.value}} | Sort-Object -Property 'Category'

                    $exampleChart = New-Chart -Name TapeInfrastructure -Width 600 -Height 400

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
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Cloud Connect Infrastructure' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Cloud Connect Infrastructure - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}