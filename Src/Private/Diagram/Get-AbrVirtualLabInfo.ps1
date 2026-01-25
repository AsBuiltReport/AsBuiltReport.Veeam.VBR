function Get-AbrVirtualLabInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication Virtual Labs.

    .DESCRIPTION
        The Get-AbrVirtualLabInfo function collects and returns information about Virtual Labs configured in Veeam Backup & Replication.
        It retrieves the Virtual Lab details, including platform type and server name, and formats the information into a custom object.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a custom object containing the name, additional information, and icon type of each Virtual Lab.

    .EXAMPLE
        PS C:\> Get-AbrVirtualLabInfo
        Retrieves and displays information about all Virtual Labs configured in Veeam Backup & Replication.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and configured.
        The function uses the Get-AbrVirtualLab cmdlet to retrieve Virtual Lab information.
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting VirtualLab information from $($VBRServer)."
        $VirtualLab = Get-VBRVirtualLab

        if ($VirtualLab) {
            $VirtualLabInfo = $VirtualLab | ForEach-Object {
                $inobj = [ordered] @{
                    'Platform' = switch ($_.Platform) {
                        'HyperV' { 'Microsoft Hyper-V' }
                        'VMWare' { 'VMWare vSphere' }
                        default { $_.Platform }
                    }
                    'Server' = $_.Server.Name
                }

                $IconType = Get-AbrIconType -String 'VirtualLab'

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $VirtualLabInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}