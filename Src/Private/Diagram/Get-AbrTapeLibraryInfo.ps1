function Get-AbrTapeLibraryInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication (VBR) Tape Libraries.

    .DESCRIPTION
        The Get-AbrTapeLibraryInfo function collects and returns information about Tape Libraries from a Veeam Backup & Replication server.
        It retrieves the Tape Libraries, sorts them by name, and formats the information into a custom object.

    .PARAMETERS
        None

    .OUTPUTS
        PSCustomObject
            A custom object containing the name and additional information (state, type, model) of each Tape Library.

    .EXAMPLE
        PS C:\> Get-AbrTapeLibraryInfo
        Retrieves and displays information about all Tape Libraries from the VBR server.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and imported.
        Ensure that you have the necessary permissions to access the VBR server and retrieve Tape Library information.
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Tape Library information from $($VBRServer)."
        $TapeLibraries = Get-VBRTapeLibrary | Sort-Object -Property Name

        if ($TapeLibraries) {
            $TapeLibrariesInfo = $TapeLibraries | ForEach-Object {
                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = [ordered] @{
                        'State' = $_.State
                        'Type' = $_.Type
                        'Model' = $_.Model
                    }
                }
            }
            return $TapeLibrariesInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}