function Load-Translations {
    param (
        [string]$Language # The language code for which translations are needed
    )

    # Construct the file path to a JSON file containing translations for the specified language
    $filePath = Join-Path -Path (Join-Path -Path $RootPath -ChildPath "/Language") -ChildPath "$Language.json"

    # Check if the translation file exists
    if (Test-Path $filePath) {
        # Read the content of the JSON file as a raw string
        $jsonContent = Get-Content -Path $filePath -Raw -Encoding UTF8
        # Convert the JSON string into a PowerShell object and return it
        return $jsonContent | ConvertFrom-Json
    } else {
        # Output an error message if the file does not exist
        Write-PScriboMessage "Translation file for language '$Language' not found."
        return $null  # Return null if the file is not found
    }
}