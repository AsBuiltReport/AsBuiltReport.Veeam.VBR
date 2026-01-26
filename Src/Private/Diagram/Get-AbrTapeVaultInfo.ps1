function Get-AbrTapeVaultInfo {
    <#
    .SYNOPSIS
        Retrieves information about Tape Vaults from the Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-AbrTapeVaultInfo function collects and returns information about Tape Vaults from the Veeam Backup & Replication server.
        It sorts the Tape Vaults by their names and provides additional information about their protection status.

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
        Returns a collection of PSCustomObject with the following properties:
            - Name: The name of the Tape Vault.
            - AditionalInfo: A hashtable containing the protection status of the Tape Vault.

    .EXAMPLE
        PS C:\> Get-AbrTapeVaultInfo
        Retrieves and displays information about all Tape Vaults from the Veeam Backup & Replication server.

    .NOTES
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Tape Vault information from $($VBRServer)."
        $TapeVaults = Get-VBRTapeVault | Sort-Object -Property Name

        if ($TapeVaults) {
            $TapeVaultsInfo = $TapeVaults | ForEach-Object {
                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = [ordered] @{
                        'Protect' = if ($_.Protect) { 'Yes' } else { 'No' }
                    }
                }
            }
            return $TapeVaultsInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}