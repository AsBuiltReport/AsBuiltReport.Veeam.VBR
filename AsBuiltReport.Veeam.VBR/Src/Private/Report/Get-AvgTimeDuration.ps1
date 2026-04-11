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
        $TimeDurationObj += New-TimeSpan -Start $Object.$StartTime -End $Object.$EndTime
    }

    # Calculate AVG TimeDuration of job sessions
    $AverageTimeSpan = New-TimeSpan -Seconds (($TimeDurationObj.TotalSeconds | Measure-Object -Average).Average)

    return (Get-TimeDuration -TimeSpan $AverageTimeSpan)
}