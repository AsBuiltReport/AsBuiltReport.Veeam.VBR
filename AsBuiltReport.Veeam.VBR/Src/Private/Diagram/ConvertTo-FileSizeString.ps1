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
    param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [int64] $Size,
        [Parameter(
            Position = 1,
            Mandatory = $false,
            HelpMessage = 'Please provide the source space unit'
        )]
        [ValidateSet('MB', 'GB', 'TB', 'PB')]
        [string] $SourceSpaceUnit,
        [Parameter(
            Position = 2,
            Mandatory = $false,
            HelpMessage = 'Please provide the space unit to output'
        )]
        [ValidateSet('MB', 'GB', 'TB', 'PB')]
        [string] $TargetSpaceUnit,
        [Parameter(
            Position = 3,
            Mandatory = $false,
            HelpMessage = 'Please provide the value to round the storage unit'
        )]
        [int] $RoundUnits = 0
    )

    if ($SourceSpaceUnit) {
        return "$([math]::Round(($Size * $('1' + $SourceSpaceUnit) / $('1' + $TargetSpaceUnit)), $RoundUnits)) $TargetSpaceUnit"
    } else {
        $Unit = switch ($Size) {
            { $Size -gt 1PB } { 'PB' ; break }
            { $Size -gt 1TB } { 'TB' ; break }
            { $Size -gt 1GB } { 'GB' ; break }
            { $Size -gt 1Mb } { 'MB' ; break }
            default { 'KB' }
        }
        return "$([math]::Round(($Size / $('1' + $Unit)), $RoundUnits)) $Unit"
    }
} # end