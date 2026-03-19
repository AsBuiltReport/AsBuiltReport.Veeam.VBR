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
    param
    (
        [Parameter (
            Position = 0,
            Mandatory
        )]
        [TimeSpan] $TimeSpan
    )

    if ($TimeSpan.Days -gt 0) {
        $TimeSpan.ToString('dd\.hh\:mm\:ss')
    } else {
        $TimeSpan.ToString('hh\:mm\:ss')
    }
}