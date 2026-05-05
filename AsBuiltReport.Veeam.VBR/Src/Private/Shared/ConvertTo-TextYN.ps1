function ConvertTo-TextYN {
    <#
    .SYNOPSIS
        Converts a boolean string representation to "Yes" or "No".

    .DESCRIPTION
        This function is used to convert boolean string values ("True" or "False") to their corresponding
        textual representations ("Yes" or "No"). If the input is an empty string, a space, or null, it returns "--".
        Any other input is returned as-is.

    .PARAMETER TEXT
        The string value to be converted. It can be "True", "False", an empty string, a space, or null.

    .OUTPUTS
        [String] The converted string value.

    .NOTES
        Version: 0.3.0
        Author: LEE DAILEY

    .EXAMPLE
        PS C:\> ConvertTo-TextYN -TEXT "True"
        Yes

        PS C:\> ConvertTo-TextYN -TEXT "False"
        No

        PS C:\> ConvertTo-TextYN -TEXT ""
        --

        PS C:\> ConvertTo-TextYN -TEXT " "
        --

        PS C:\> ConvertTo-TextYN -TEXT $Null
        --

        PS C:\> ConvertTo-TextYN -TEXT "Maybe"
        Maybe

    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [OutputType([String])]
    param (
        [Parameter (
            Position = 0,
            Mandatory)]
        [AllowEmptyString()]
        [string] $TEXT
    )

    switch ($TEXT) {
        '' { '--'; break }
        ' ' { '--'; break }
        $Null { '--'; break }
        'True' { 'Yes'; break }
        'False' { 'No'; break }
        default { $TEXT }
    }
} # end