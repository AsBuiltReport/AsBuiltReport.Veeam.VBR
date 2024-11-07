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
    Param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string] $TEXT
    )

    switch ($TEXT) {
        "" { "--"; break }
        " " { "--"; break }
        $Null { "--"; break }
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
        Version:        0.1.0
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
        [int64]
        $Size
    )

    $Unit = Switch ($Size) {
        { $Size -gt 1PB } { 'PB' ; Break }
        { $Size -gt 1TB } { 'TB' ; Break }
        { $Size -gt 1GB } { 'GB' ; Break }
        { $Size -gt 1Mb } { 'MB' ; Break }
        Default { 'KB' }
    }
    return "$([math]::Round(($Size / $("1" + $Unit)), 0)) $Unit"
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
        Name = $ChartAreaName
        AxisXTitle = $AxisXTitle
        AxisYTitle = $AxisYTitle
        NoAxisXMajorGridLines = $true
        NoAxisYMajorGridLines = $true
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

    $sampleData | Add-ColumnChartSeries @addChartSeriesParams

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
        Get-TimeDuration -$TimeSpan
    .LINK
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory
        )]
        [TimeSpan] $TimeSpan
    )

    if ($TimeSpan.Days -gt 0) {
        $TimeSpan.ToString("dd\.hh\:mm\:ss")
    } else {
        $TimeSpan.ToString("hh\:mm\:ss")
    }
}

function Get-TimeDurationSum {
    <#
    .SYNOPSIS
        Used by As Built Report to convert inputobject Duration time to TimeFormat.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
        Get-TimeDurationSum -$InputObject $Variable -StartTime $StartObjct -EndTime $EndObject
    .LINK
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory
        )]
        [Object[]] $InputObject,
        [String] $StartTime,
        [String] $EndTime

    )

    $TimeDurationObj = @()
    foreach ($Object in $InputObject) {
        $TimeDurationObj += (New-TimeSpan -Start $Object.$StartTime -End $Object.$EndTime).TotalSeconds
    }

    return ($TimeDurationObj | Measure-Object -Sum).Sum
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
        Get-AvgTimeDuration -$InputObject $Variable -StartTime $StartObjct -EndTime $EndObject
    .LINK
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter (
            Position = 0,
            Mandatory
        )]
        [Object[]] $InputObject,
        [String] $StartTime,
        [String] $EndTime

    )

    $TimeDurationObj = @()
    foreach ($Object in $InputObject) {
        $TimeDurationObj += New-TimeSpan -Start $Object.$StartTime -End $Object.$EndTime
    }

    # Calculate AVG TimeDuration of job sessions
    $AverageTimeSpan = New-TimeSpan -Seconds (($TimeDurationObj.TotalSeconds | Measure-Object -Average).Average)

    return (Get-TimeDuration -TimeSpan $AverageTimeSpan)
}

function Get-StrdDevDuration {
    <#
    .SYNOPSIS
        Used by As Built Report to convert jobs session Duration time to Standard Deviation TimeFormat.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
        Get-StrdDevDuration -$JobTimeSpan
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
        $TimeDurationObj += (New-TimeSpan -Start $JobSession.CreationTime -End $JobSession.EndTime).TotalSeconds
    }

    # Calculate AVG TimeDuration of job sessions
    $StrdDevDuration = Get-StandardDeviation -value $TimeDurationObj

    return $StrdDevDuration
}


function Get-StandardDeviation {
    <#
        .Synopsis
            This script will find the standard deviation, given a set of numbers.
        .DESCRIPTION
            This script will find the standard deviation, given a set of numbers.

            Written by Mike Roberts (Ginger Ninja)
            Version: 0.5
        .EXAMPLE
            .\Get-StandardDeviation.ps1

            Using this method you will need to input numbers one line at a time, and then hit enter twice when done.
            --------------------------------------------------------------------------------------------------------
            PS > .\Get-StandardDeviation.ps1

                cmdlet Get-StandardDeviation at command pipeline position 1
                Supply values for the following parameters:
                value[0]: 12345
                value[1]: 0
                value[2]:


                Original Numbers           : 12345,0
                Standard Deviation         : 8729.23321374793
                Rounded Number (2 decimal) : 8729.23
                Rounded Number (3 decimal) : 8729.233
                --------------------------------------------------------------------------------------------------------
        .EXAMPLE
            .\Get-StandardDeviation.ps1 -value 12345,0
        .LINK
            http://www.gngrninja.com/script-ninja/2016/5/1/powershell-calculating-standard-deviation
        .NOTES
            Be sure to enter at least 2 numbers, separated by a comma if using the -value parameter.
    #>
    #Begin function Get-StandardDeviation
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [decimal[]] $value
    )

    #Simple if to see if the value matches digits, and also that there is more than one number.
    if ($value -match '\d+' -and $value.Count -gt 1) {

        #Variables used later
        [decimal]$newNumbers = $Null
        [decimal]$stdDev = $null

        #Get the average and count via Measure-Object
        $avgCount = $value | Measure-Object -Average | Select-Object Average, Count

        #Iterate through each of the numbers and get part of the variance via some PowerShell math.
        ForEach ($number in $value) {

            $newNumbers += [Math]::Pow(($number - $avgCount.Average), 2)

        }

        #Finish the variance calculation, and get the square root to finally get the standard deviation.
        $stdDev = [math]::Sqrt($($newNumbers / ($avgCount.Count - 1)))

        #Create an array so we can add the object we create to it. This is incase we want to perhaps add some more math functions later.
        [System.Collections.ArrayList]$formattedObjectArray = @()

        #Create a hashtable collection for the properties of the object
        $formattedProperty = @{'StandardDeviation' = [Math]::Round($stdDev, 2) }

        #Create the object we'll add to the array, with the properties set above
        $fpO = New-Object psobject -Property $formattedProperty

        #Add that object to this array
        $formattedObjectArray.Add($fpO) | Out-Null

        #Return the array object with the selected objects defined, as well as formatting.
        Return $formattedObjectArray

    } else {

        #Display an error if there are not enough numbers
        Write-PScriboMessage "You did not enter enough numbers!"
    }
} #End function Get-StandardDeviation

function Get-VBRDebugObject {

    [CmdletBinding()]
    param (
    )

    $script:ProxiesDebug = [PSCustomObject]@(
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-00000000000001' }
            'Type' = "Vi"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-02' }
            'Type' = "Vi"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-03' }
            'Type' = "Vi"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-04' }
            'Type' = "HvOffhost"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-0500000000000' }
            'Type' = "HvOffhost"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-06' }
            'Type' = "HvOnhost"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
    )


    $script:Repositories = @{
        Name = "Repository1", "Repository2", "Repository3", "Repository4", "Repository5", "Repository6", "Repository7"
    }


    $script:ObjectRepositories = @{
        Name = "ObjectRepositor1", "ObjectRepositor2", "ObjectRepositor3", "ObjectRepositor4", "ObjectRepositor5", "ObjectRepositor6", "ObjectRepositor7"
    }
}

function New-VBRConnection {
    <#
    .SYNOPSIS
        Uses New-VBRConnection to store the connection in a global parameter
    .DESCRIPTION
        Creates a Veeam Server connection and stores it in global variable $Global:DefaultVeeamBR.
        An FQDN or IP, credentials, and ignore certificate boolean
    .OUTPUTS
        Returns the Veeam Server connection.
    .EXAMPLE
    New-VBRConnection -Endpoint <FQDN or IP> -Port <default 9419> -Credential $(Get-Credential)

    #>

    [CmdletBinding()]
    Param(

        [Parameter(Position = 0, mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Position = 1, mandatory = $true)]
        [string]$Port,

        [Parameter(Mandatory = $true, ParameterSetName = "Credential")]
        [ValidateNotNullOrEmpty()]
        [Management.Automation.PSCredential]$Credential

    )

    $apiUrl = "https://$($Endpoint):$($Port)/api/oauth2/token"

    $User = $Credential.UserName
    $Pass = $Credential.GetNetworkCredential().Password

    # Define the headers for the API request
    $headers = @{
        "Content-Type" = "application/x-www-form-urlencoded"
        "x-api-version" = "1.1-rev0"
    }

    ## TO-DO: Grant_type options
    $body = @{
        "grant_type" = "password"
        "username" = $User
        "password" = $Pass
    }

    # Send an authentication request to obtain a session token
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -Body $body -SkipCertificateCheck

        if (($response.access_token) -or ($response.StatusCode -eq 200) ) {
            Write-Output "Successfully authenticated."
            $VBRAuthentication = [PSCustomObject]@{
                Session_endpoint = $Endpoint
                Session_port = $Port
                Session_access_token = $response.access_token
            }

            return $VBRAuthentication
        } else {
            Write-Output "Authentication failed. Status code: $($response.StatusCode), Message: $($response.Content)"
        }
    } catch {
        Write-Output "An error occurred: $($_.Exception.Message)"
    }
}

# Variable translating Icon to Image Path ($IconPath)
$script:Images = @{
    "VBR_Server" = "VBR_server.png"
    "VBR_Repository" = "VBR_Repository.png"
    "VBR_NAS" = "NAS.png"
    "VBR_Deduplicating_Storage" = "Deduplication.png"
    "VBR_Linux_Repository" = "Linux_Repository.png"
    "VBR_Windows_Repository" = "Windows_Repository.png"
    "VBR_Cloud_Repository" = "Cloud_Repository.png"
    "VBR_Object_Repository" = "Object_Storage.png"
    "VBR_Object" = "Object_Storage_support.png"
    "VBR_Amazon_S3_Compatible" = "S3-compatible.png"
    "VBR_Amazon_S3" = "AWS S3.png"
    "VBR_Azure_Blob" = "Azure Blob.png"
    "VBR_Server_DB" = "Microsoft_SQL_DB.png"
    "VBR_Proxy" = "Veeam_Proxy.png"
    "VBR_Proxy_Server" = "Proxy_Server.png"
    "VBR_Wan_Accel" = "WAN_accelerator.png"
    "VBR_SOBR" = "Logo_SOBR.png"
    "VBR_SOBR_Repo" = "Scale_out_Backup_Repository.png"
    "VBR_LOGO" = "Veeam_logo.png"
    "VBR_No_Icon" = "no_icon.png"
    'VBR_Storage_NetApp' = "Storage_NetApp.png"
    'VBR_vCenter_Server' = 'vCenter_server.png'
    'VBR_ESXi_Server' = 'ESXi_host.png'
    'VBR_HyperV_Server' = 'Hyper-V_host.png'
    'VBR_Server_EM' = 'Veeam_Backup_Enterprise_Manager.png'
    'VBR_Tape_Server' = 'Tape_Server.png'
    'VBR_Tape_Library' = 'Tape_Library.png'
    'VBR_Tape_Drive' = 'Tape_Drive.png'
    'VBR_Tape_Vaults' = 'Tape encrypted.png'
    "VBR_Server_DB_PG" = "PostGre_SQL_DB.png"
    "VBR_LOGO_Footer" = "verified_recoverability.png"
    "VBR_AGENT_Container" = "Folder.png"
    "VBR_AGENT_AD" = "Server.png"
    "VBR_AGENT_MC" = "Task list.png"
    "VBR_AGENT_IC" = "Workstation.png"
    "VBR_AGENT_CSV" = "CSV_Computers.png"
    "VBR_AGENT_AD_Logo" = "Microsoft Active Directory.png"
    "VBR_AGENT_CSV_Logo" = "File.png"
    "VBR_AGENT_Server" = "Server_with_Veeam_Agent.png"
    "VBR_vSphere" = "VMware_vSphere.png"
    "VBR_HyperV" = "Microsoft_SCVMM.png"
    "VBR_Tape" = "Tape.png"
    "VBR_Service_Providers" = "Veeam_Service_Provider_Console.png"
    "VBR_Service_Providers_Server" = "Veeam_Service_Provider_Server.png"
}

function ConvertTo-HashToYN {
    <#
    .SYNOPSIS
        Used by As Built Report to convert array content true or false automatically to Yes or No.
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [Parameter (Position = 0, Mandatory)]
        [AllowEmptyString()]
        [Hashtable] $TEXT
    )

    $result = [ordered] @{}
    foreach ($i in $inObj.GetEnumerator()) {
        try {
            $result.add($i.Key, (ConvertTo-TextYN $i.Value))
        } catch {
            Write-PScriboMessage -IsWarning "Unable to process $($i.key) values"
        }
    }
    if ($result) {
        return $result
    } else { return $TEXT }
} # end