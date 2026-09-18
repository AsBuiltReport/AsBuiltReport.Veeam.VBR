
function Get-ValidateIP {
    <#
    .SYNOPSIS
        Used by As Built Report to validate if the input is a valid IP address.
    .DESCRIPTION

    .NOTES
        Version:        0.1.0
        Author:         AsBuiltReport Organization

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param (
        [Parameter (Position = 0, Mandatory)]
        [AllowEmptyString()]
        [string] $Pattern
    )

    $ip = [ipaddress]::None

    if ([ipaddress]::TryParse($Pattern, [ref]$ip)) {
        return $true
    } else {
        return $false
    }
} # end function Get-ValidateIP