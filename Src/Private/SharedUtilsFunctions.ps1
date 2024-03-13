function ConvertTo-TextYN {
    <#
    .SYNOPSIS
    Used by As Built Report to convert true or false automatically to Yes or No.
    .DESCRIPTION
    .NOTES
        Version:        0.3.0
        Author:         LEE DAILEY
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string]
        $TEXT
    )

    switch ($TEXT) {
        "" { "--" }
        $Null { "--" }
        "True" { "Yes"; break }
        "False" { "No"; break }
        default { $TEXT }
    }
} # end
function Get-UnixDate ($UnixDate) {
    <#
    .SYNOPSIS
    Used by As Built Report to convert Date to a more nice format.
    .DESCRIPTION
    .NOTES
        Version:        0.2.0
        Author:         LEE DAILEY
    .EXAMPLE
    .LINK
    #>
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($UnixDate))
} # end
function ConvertTo-EmptyToFiller {
    <#
    .SYNOPSIS
    Used by As Built Report to convert empty culumns to "--".
    .DESCRIPTION
    .NOTES
        Version:        0.5.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string]$TEXT
    )

    switch ($TEXT) {
        "" { "--"; break }
        $Null { "--"; break }
        default { $TEXT }
    }
} # end

function ConvertTo-VIobject {
    <#
    .SYNOPSIS
    Used by As Built Report to convert object to VIObject.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jon Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        $OBJECT
    )

    if (Get-View $OBJECT -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name -Unique) {
        return Get-View $OBJECT -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name -Unique
    } else {
        return $OBJECT
    }
} # end
function ConvertTo-FileSizeString {
    <#
    .SYNOPSIS
    Used by As Built Report to convert bytes automatically to GB or TB based on size.
    .DESCRIPTION
    .NOTES
        Version:        0.4.0
        Author:         LEE DAILEY
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [int64]
        $Size
    )

    switch ($Size) {
        { $_ -gt 1TB }
        { [string]::Format("{0:0} TB", $Size / 1TB); break }
        { $_ -gt 1GB }
        { [string]::Format("{0:0} GB", $Size / 1GB); break }
        { $_ -gt 1MB }
        { [string]::Format("{0:0} MB", $Size / 1MB); break }
        { $_ -gt 1KB }
        { [string]::Format("{0:0} KB", $Size / 1KB); break }
        { $_ -gt 0 }
        { [string]::Format("{0} B", $Size); break }
        { $_ -eq 0 }
        { "0 KB"; break }
        default
        { "0 KB" }
    }
} # end
function Get-VeeamNetStat {
    <#
    .SYNOPSIS
        Used by As Built Report to gather veeam network statistics information.
    .DESCRIPTION
        Function used to gathers information about any running processes.
    .NOTES
        Version:        0.1.0
        Author:         CEvans
        Github:         cevans3505
    .EXAMPLE
        Get-VeeamNetStats | Where-Object { $_.ProcessName -Like "*veeam*" } | Sort-Object -Property State,LocalPort | Format-Table -Autosize
    .LINK
        https://gist.github.com/cevans3505/e5b95021d3e744878e018b6b5638eea2
    #>

    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $Session
    )

    $properties = 'Protocol', 'LocalAddress', 'LocalPort'
    $properties += 'RemoteAddress', 'RemotePort', 'State', 'ProcessName', 'PID'

    Invoke-Command -Session $Session -ScriptBlock { netstat -ano } | Select-String -Pattern '\s+(TCP|UDP)' | ForEach-Object {

        $item = $_.Line.Split(  " ", [System.StringSplitOptions]::RemoveEmptyEntries )

        if ( $item[1] -NotMatch '^\[::' ) {

            if ( ( $la -eq $item[1] -As [ipaddress] ).AddressFamily -Eq 'InterNetworkV6' ) {
                $localAddress = $la.IPAddressToString
                $localPort = $item[1].Split( '\]:' )[-1]
            } else {
                $localAddress = $item[1].Split( ':' )[0]
                $localPort = $item[1].Split( ':' )[-1]
            }

            if ( ( $ra -eq $item[2] -As [ipaddress] ).AddressFamily -Eq 'InterNetworkV6' ) {
                $remoteAddress = $ra.IPAddressToString
                $remotePort = $item[2].Split( '\]:' )[-1]
            } else {
                $remoteAddress = $item[2].Split( ':' )[0]
                $remotePort = $item[2].Split( ':' )[-1]
            }

            New-Object PSObject -Property @{
                PID = $item[-1]
                ProcessName = ( Invoke-Command  -Session $Session -ScriptBlock { Get-Process -Id ($using:item)[-1] -ErrorAction SilentlyContinue }).Name
                Protocol = $item[0]
                LocalAddress = $localAddress
                LocalPort = $localPort
                RemoteAddress = $remoteAddress
                RemotePort = $remotePort
                State = if ( $item[0] -Eq 'tcp' ) { $item[3] } else { $Null }
            } | Select-Object -Property $properties
        }
    }
}

function Convert-Size {
    [cmdletbinding()]
    param(
        [validateset("Bytes", "KB", "MB", "GB", "TB")]
        [string]$From,
        [validateset("Bytes", "KB", "MB", "GB", "TB")]
        [string]$To,
        [Parameter(Mandatory = $true)]
        [double]$Value,
        [int]$Precision = 4
    )
    switch ($From) {
        "Bytes" { $value = $Value }
        "KB" { $value = $Value * 1024 }
        "MB" { $value = $Value * 1024 * 1024 }
        "GB" { $value = $Value * 1024 * 1024 * 1024 }
        "TB" { $value = $Value * 1024 * 1024 * 1024 * 1024 }
    }

    switch ($To) {
        "Bytes" { return $value }
        "KB" { $Value = $Value / 1KB }
        "MB" { $Value = $Value / 1MB }
        "GB" { $Value = $Value / 1GB }
        "TB" { $Value = $Value / 1TB }

    }

    return [Math]::Round($value, $Precision, [MidPointRounding]::AwayFromZero)
}

function Get-ImagePercent {
    <#
    .SYNOPSIS
    Used by As Built Report to get base64 image percentage calculated from image width.
    This low the diagram image to fit the report page margins
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([System.Int32])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [string]
        $Graph
    )
    $Image_FromStream = [System.Drawing.Image]::FromStream((New-Object System.IO.MemoryStream(, [convert]::FromBase64String($Graph))))
    If ($Image_FromStream.Width -gt 1500) {
        return 10
    } else {
        return 30
    }
} # end

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
    Param
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
        $Height = 400
    )

    $exampleChart = New-Chart -Name $ChartName -Width $Width -Height $Height

    $addChartAreaParams = @{
        Chart = $exampleChart
        Name = 'exampleChartArea'
    }
    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

    $addChartSeriesParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = 'exampleChartSeries'
        XField = $XField
        YField = $YField
        Palette = 'Green'
        ColorPerDataPoint = $true
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
        Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
    }
    Add-ChartTitle @addChartTitleParams

    $TempPath = Resolve-Path ([System.IO.Path]::GetTempPath())

    $ChartImage = Export-Chart -Chart $exampleChart -Path $TempPath.Path -Format "PNG" -PassThru

    $Base64Image = [convert]::ToBase64String((Get-Content $ChartImage -Encoding byte))

    Remove-Item -Path $ChartImage.FullName

    return $Base64Image

} # end

function Get-ColumnChart {
    <#
    .SYNOPSIS
    Used by As Built Report to generate PScriboChart column charts.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [System.Array]
        $SampleData,
        [String]
        $ChartName,
        [String]
        $AxisXTitle,
        [String]
        $AxisYTitle,
        [String]
        $XField,
        [String]
        $YField,
        [String]
        $ChartAreaName,
        [String]
        $ChartTitleName = ' ',
        [String]
        $ChartTitleText = ' ',
        [int]
        $Width = 600,
        [int]
        $Height = 400
    )

    $exampleChart = New-Chart -Name $ChartName -Width $Width -Height $Height

    $addChartAreaParams = @{
        Chart = $exampleChart
        Name = $ChartAreaName
        AxisXTitle = $AxisXTitle
        AxisYTitle = $AxisYTitle
        NoAxisXMajorGridLines = $true
        NoAxisYMajorGridLines = $true
    }
    $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

    $addChartSeriesParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = 'exampleChartSeries'
        XField = $XField
        YField = $YField
        Palette = 'Green'
        ColorPerDataPoint = $true
    }
    $sampleData | Add-ColumnChartSeries @addChartSeriesParams

    $addChartTitleParams = @{
        Chart = $exampleChart
        ChartArea = $exampleChartArea
        Name = $ChartTitleName
        Text = $ChartTitleText
        Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
    }
    Add-ChartTitle @addChartTitleParams

    $TempPath = Resolve-Path ([System.IO.Path]::GetTempPath())

    $ChartImage = Export-Chart -Chart $exampleChart -Path $TempPath.Path -Format "PNG" -PassThru

    if ($PassThru) {
        Write-Output -InputObject $chartFileItem
    }

    $Base64Image = [convert]::ToBase64String((Get-Content $ChartImage -Encoding byte))

    Remove-Item -Path $ChartImage.FullName

    return $Base64Image

} # end

function Get-WindowsTimePeriod {
    <#
    .SYNOPSIS
    Used by As Built Report to generate time period table.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [System.Array]
        $InputTimePeriod
    )

    $OutObj = @()
    $Hours24 = [ordered]@{
        0 = 12
        1 = 1
        2 = 2
        3 = 3
        4 = 4
        5 = 5
        6 = 6
        7 = 7
        8 = 8
        9 = 9
        10 = 10
        11 = 11
        12 = 12
        13 = 1
        14 = 2
        15 = 3
        16 = 4
        17 = 5
        18 = 6
        19 = 7
        20 = 8
        21 = 9
        22 = 10
        23 = 11
    }
    $ScheduleTimePeriod = $InputTimePeriod -split '(.{48})' | Where-Object { $_ }

    foreach ($OBJ in $Hours24.GetEnumerator()) {

        $inObj = [ordered] @{
            'H' = $OBJ.Value
            'Sun' = $ScheduleTimePeriod[0].Split(',')[$OBJ.Key]
            'Mon' = $ScheduleTimePeriod[1].Split(',')[$OBJ.Key]
            'Tue' = $ScheduleTimePeriod[2].Split(',')[$OBJ.Key]
            'Wed' = $ScheduleTimePeriod[3].Split(',')[$OBJ.Key]
            'Thu' = $ScheduleTimePeriod[4].Split(',')[$OBJ.Key]
            'Fri' = $ScheduleTimePeriod[5].Split(',')[$OBJ.Key]
            'Sat' = $ScheduleTimePeriod[6].Split(',')[$OBJ.Key]
        }
        $OutObj += $inobj
    }

    return $OutObj

} # end

function Get-TimeDuration {
    <#
    .SYNOPSIS
        Used by As Built Report to convert job session Duration time to TimeFormat.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
        Get-TimeDuration -$JobTimeSpan
    .LINK
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory
        )]
        [TimeSpan] $JobTimeSpan
    )

    if ($JobTimeSpan.Days -gt 0) {
        $JobTimeSpan.ToString("dd\.hh\:mm\:ss")
    } else {
        $JobTimeSpan.ToString("hh\:mm\:ss")
    }
}

function Get-AvgTimeDuration {
    <#
    .SYNOPSIS
        Used by As Built Report to convert jobs session Duration time to AVG TimeFormat.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
        Get-TimeDuration -$JobTimeSpan
    .LINK
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory
        )]
        $JobSessions
    )

    $TimeDurationObj = @()
    foreach ($JobSession in $JobSessions) {
        $TimeDurationObj += New-TimeSpan -Start $JobSession.CreationTime -End $JobSession.EndTime
    }

    # Calculate AVG TimeDuration of job sessions
    $AverageTimeSpan = New-TimeSpan -Seconds (($TimeDurationObj.TotalSeconds | Measure-Object -Sum).Sum / $JobSessions.Count)

    return (Get-TimeDuration -JobTimeSpan $AverageTimeSpan)
}