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
    param
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