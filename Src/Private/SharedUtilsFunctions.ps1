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
        "" {"--"}
        $Null {"--"}
        "True" {"Yes"; break}
        "False" {"No"; break}
        default {$TEXT}
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
        "" {"--"; break}
        $Null {"--"; break}
        default {$TEXT}
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

    if (get-view $OBJECT -ErrorAction SilentlyContinue| Select-Object -ExpandProperty Name -Unique) {
        return get-view $OBJECT -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name -Unique
    }
    else {
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
        {$_ -gt 1TB}
            {[string]::Format("{0:0} TB", $Size / 1TB); break}
        {$_ -gt 1GB}
            {[string]::Format("{0:0} GB", $Size / 1GB); break}
        {$_ -gt 1MB}
            {[string]::Format("{0:0} MB", $Size / 1MB); break}
        {$_ -gt 1KB}
            {[string]::Format("{0:0} KB", $Size / 1KB); break}
        {$_ -gt 0}
            {[string]::Format("{0} B", $Size); break}
        {$_ -eq 0}
            {"0 KB"; break}
        default
            {"0 KB"}
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

    $properties = 'Protocol','LocalAddress','LocalPort'
    $properties += 'RemoteAddress','RemotePort','State','ProcessName','PID'

    invoke-command -Session $Session -ScriptBlock { netstat -ano } | Select-String -Pattern '\s+(TCP|UDP)' | ForEach-Object {

        $item = $_.Line.Split(  " ",[System.StringSplitOptions]::RemoveEmptyEntries )

        if ( $item[1] -NotMatch '^\[::' ) {

            if ( ( $la -eq $item[1] -As [ipaddress] ).AddressFamily -Eq 'InterNetworkV6' ) {
                $localAddress = $la.IPAddressToString
                $localPort = $item[1].Split( '\]:' )[-1]
            }
            else {
                $localAddress = $item[1].Split( ':' )[0]
                $localPort = $item[1].Split( ':' )[-1]
            }

            if ( ( $ra -eq $item[2] -As [ipaddress] ).AddressFamily -Eq 'InterNetworkV6' ) {
                $remoteAddress = $ra.IPAddressToString
                $remotePort = $item[2].Split( '\]:' )[-1]
            }
            else {
                $remoteAddress = $item[2].Split( ':' )[0]
                $remotePort = $item[2].Split( ':' )[-1]
            }

            New-Object PSObject -Property @{
                PID = $item[-1]
                ProcessName = ( invoke-command  -Session $Session -ScriptBlock { Get-Process -Id ($using:item)[-1] -ErrorAction SilentlyContinue }).Name
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
        [validateset("Bytes","KB","MB","GB","TB")]
        [string]$From,
        [validateset("Bytes","KB","MB","GB","TB")]
        [string]$To,
        [Parameter(Mandatory=$true)]
        [double]$Value,
        [int]$Precision = 4
    )
    switch($From) {
        "Bytes" {$value = $Value }
        "KB" {$value = $Value * 1024 }
        "MB" {$value = $Value * 1024 * 1024}
        "GB" {$value = $Value * 1024 * 1024 * 1024}
        "TB" {$value = $Value * 1024 * 1024 * 1024 * 1024}
    }

    switch ($To) {
        "Bytes" {return $value}
        "KB" {$Value = $Value/1KB}
        "MB" {$Value = $Value/1MB}
        "GB" {$Value = $Value/1GB}
        "TB" {$Value = $Value/1TB}

    }

    return [Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)
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
    $Image_FromStream = [System.Drawing.Image]::FromStream((new-object System.IO.MemoryStream(,[convert]::FromBase64String($Graph))))
    If ($Image_FromStream.Width -gt 1500) {
        return 10
    } else {
        return 20
    }
} # end