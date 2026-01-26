function Get-AbrTapeServersInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication Tape Servers.

    .DESCRIPTION
        The Get-AbrTapeServersInfo function collects and returns information about Tape Servers from the Veeam Backup & Replication server.
        It sorts the Tape Servers by their name and provides additional availability information.

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject with the following properties:
            - Name: The name of the Tape Server.
            - AditionalInfo: An ordered dictionary containing the availability status of the Tape Server.

    .EXAMPLE
        PS C:\> Get-AbrTapeServersInfo
        Retrieves and displays information about all Tape Servers from the Veeam Backup & Replication server.

    .NOTES
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Tape Servers information from $($VBRServer)."
        $TapeServers = Get-VBRTapeServer | Sort-Object -Property Name

        if ($TapeServers) {
            $TapeServersInfo = $TapeServers | ForEach-Object {
                $inobj = [ordered] @{
                    'Is Available' = if ($_.IsAvailable) { 'Yes' } elseif (-not $_.IsAvailable) { 'No' } else { '--' }
                }

                [PSCustomObject] @{
                    Name = $_.Name.split('.')[0]
                    AditionalInfo = $inobj
                }
            }
            return $TapeServersInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}