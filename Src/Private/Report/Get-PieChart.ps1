function Get-PieChart {
    <#
    .SYNOPSIS
    Used by As Built Report to generate PScriboChart pie charts.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [System.Array]
        $SampleData,
        [String]
        $ChartName,
        [String]
        $XField,
        [String]
        $YField,
        [String]
        $ChartLegendName,
        [String]
        $ChartLegendAlignment = 'Center',
        [String]
        $ChartTitleName = ' ',
        [String]
        $ChartTitleText = ' ',
        [int]
        $Width = 600,
        [int]
        $Height = 400,
        [Switch]
        $Status,
        [bool]
        $ReversePalette = $false
    )

    $StatusCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#DFF0D0')
        [System.Drawing.ColorTranslator]::FromHtml('#FFF4C7')
        [System.Drawing.ColorTranslator]::FromHtml('#FEDDD7')
        [System.Drawing.ColorTranslator]::FromHtml('#878787')
    )

    $AbrCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#d5e2ff')
        [System.Drawing.ColorTranslator]::FromHtml('#bbc9e9')
        [System.Drawing.ColorTranslator]::FromHtml('#a2b1d3')
        [System.Drawing.ColorTranslator]::FromHtml('#8999bd')
        [System.Drawing.ColorTranslator]::FromHtml('#7082a8')
        [System.Drawing.ColorTranslator]::FromHtml('#586c93')
        [System.Drawing.ColorTranslator]::FromHtml('#40567f')
        [System.Drawing.ColorTranslator]::FromHtml('#27416b')
        [System.Drawing.ColorTranslator]::FromHtml('#072e58')
    )

    $VeeamCustomPalette = @(
        [System.Drawing.ColorTranslator]::FromHtml('#ddf6ed')
        [System.Drawing.ColorTranslator]::FromHtml('#c3e2d7')
        [System.Drawing.ColorTranslator]::FromHtml('#aacec2')
        [System.Drawing.ColorTranslator]::FromHtml('#90bbad')
        [System.Drawing.ColorTranslator]::FromHtml('#77a898')
        [System.Drawing.ColorTranslator]::FromHtml('#5e9584')
        [System.Drawing.ColorTranslator]::FromHtml('#458370')
        [System.Drawing.ColorTranslator]::FromHtml('#2a715d')
        [System.Drawing.ColorTranslator]::FromHtml('#005f4b')
    )

    if ($Options.ReportStyle -eq "Veeam") {
        $BorderColor = 'DarkGreen'
    } else {
        $BorderColor = 'DarkBlue'
    }

    $exampleChart = New-Chart -Name $ChartName -Width $Width -Height $Height -BorderStyle Dash -BorderWidth 1 -BorderColor $BorderColor

    $addChartAreaParams = @{
        Chart = $exampleChart
        Name = 'exampleChartArea'
        AxisXInterval = 1
    }
    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

    if ($Status) {
        $CustomPalette = $StatusCustomPalette
    } elseif ($Options.ReportStyle -eq 'Veeam') {
        $CustomPalette = $VeeamCustomPalette

    } else {
        $CustomPalette = $AbrCustomPalette
    }

    $addChartSeriesParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = 'exampleChartSeries'
        XField = $XField
        YField = $YField
        CustomPalette = $CustomPalette
        ColorPerDataPoint = $true
        ReversePalette = $ReversePalette
    }

    $sampleData | Add-PieChartSeries @addChartSeriesParams

    $addChartLegendParams = @{
        Chart = $exampleChart
        Name = $ChartLegendName
        TitleAlignment = $ChartLegendAlignment
    }
    Add-ChartLegend @addChartLegendParams

    $addChartTitleParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = $ChartTitleName
        Text = $ChartTitleText
        Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '12', [System.Drawing.FontStyle]::Bold)
    }
    Add-ChartTitle @addChartTitleParams

    $TempPath = Resolve-Path ([System.IO.Path]::GetTempPath())

    $ChartImage = Export-Chart -Chart $exampleChart -Path $TempPath.Path -Format "PNG" -PassThru

    $ChartImageByte = switch ($PSVersionTable.PSEdition) {
        'Desktop' { Get-Content $ChartImage -Encoding byte }
        'Core' { Get-Content $ChartImage -AsByteStream -Raw }
    }

    $Base64Image = [convert]::ToBase64String($ChartImageByte)

    Remove-Item -Path $ChartImage.FullName

    return $Base64Image

} # end