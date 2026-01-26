function Get-AbrSANInfo {
    <#
    .SYNOPSIS
        Retrieves information about SAN (Storage Area Network) hosts from the Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-AbrSANInfo function collects and returns information about SAN hosts, specifically NetApp and Dell Isilon hosts, from the Veeam Backup & Replication server. It gathers the host names and their types, processes additional information, and returns a custom object with the collected data.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a collection of custom objects containing the SAN host name, additional information, and icon type.

    .EXAMPLE
        PS C:\> Get-AbrSANInfo
        Retrieves and displays information about SAN hosts from the Veeam Backup & Replication server.

    .NOTES
        This function uses the Get-NetAppHost and Get-AbrIsilonHost cmdlets to retrieve SAN host information. It processes the data to include additional information and icon types for each host.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Storage Infrastructure information from $($VBRServer)."
        $SANHost = @(
            Get-NetAppHost | Select-Object -Property Name, @{ Name = 'Type'; Expression = { 'Netapp' } }
            Get-VBRIsilonHost | Select-Object -Property Name, @{ Name = 'Type'; Expression = { 'Dell' } }
        )

        if ($SANHost) {
            $SANHostInfo = $SANHost | ForEach-Object {
                try {
                    $IconType = Get-AbrIconType -String $_.Type
                    $inobj = [ordered] @{
                        'Type' = switch ($_.Type) {
                            'Netapp' { 'NetApp Ontap' }
                            'Dell' { 'Dell Isilon' }
                            default { 'Unknown' }
                        }
                    }

                    [PSCustomObject] @{
                        Name = $_.Name
                        AditionalInfo = $inobj
                        IconType = $IconType
                    }
                } catch {
                    Write-Verbose "Error: Unable to process $($_.Name) from Storage Infrastructure table: $($_.Exception.Message)"
                }
            }
        }

        return $SANHostInfo

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}