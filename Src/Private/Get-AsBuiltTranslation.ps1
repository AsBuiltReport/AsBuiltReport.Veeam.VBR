function Get-AsBuiltTranslation {
    <#
        .SYNOPSIS
        Get asbuilt translation.
        .DESCRIPTION

        .LINK
            https://github.com/AsBuiltReport/AsBuiltReport.Core
        .LINK
            https://www.asbuiltreport.com/user-guide/new-asbuiltconfig/
    #>
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The category of the translation (e.g., "Message", "Keyword")'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Category,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'The product (e.g., "vCenter")'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Product
    )

    # Load translations for the globally set language
    $translations = Load-Translations -Language $Options.Language

    # Load English translations as a fallback
    $englishTranslations = Load-Translations -Language "en-US"

    # Check if translations are loaded and if the specified product, category, and key exist
    if ($translations -and $translations.$Product -and $translations.$Product.$Category) {
        # Return the translation for the specified key within the category and product
        return $translations.$Product.$Category
    } elseif ($englishTranslations -and $englishTranslations.$Product -and $englishTranslations.$Product.$Category) {
        # Return the English translation as a fallback
        Write-PScriboMessage "Translation in category '$Category' for product '$Product' not found. Using English fallback."
        return $englishTranslations.$Product.$Category
    } else {
        # Output a warning if the key is not found in any translations
        Write-PScriboMessage "Translation in category '$Category' for product '$Product' not found in any language."
        return $Key  # Return the key itself if no translation is found
    }
}