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
    param
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