function Get-AbrNASProxyInfo {
    <#
    .SYNOPSIS
    Retrieves information about NAS proxies from the Veeam Backup & Replication server.

    .DESCRIPTION
    The Get-AbrNASProxyInfo function collects and returns information about NAS proxies configured on the Veeam Backup & Replication server.
    It retrieves the proxy server details, including whether they are enabled and the maximum number of concurrent tasks they can handle.

    .PARAMETERS
    This function does not take any parameters.

    .OUTPUTS
    System.Object
    Returns a collection of PSCustomObject containing the following properties:
    - Name: The name of the NAS proxy server.
    - AditionalInfo: An ordered dictionary with the following keys:
        - Enabled: Indicates whether the proxy server is enabled ('Yes' or 'No').
        - Max Tasks: The maximum number of concurrent tasks the proxy server can handle.
    - IconType: The icon type associated with the proxy server.

    .EXAMPLE
    PS C:\> Get-AbrNASProxyInfo
    Collects and displays information about NAS proxies from the Veeam Backup & Replication server.

    .NOTES
    This function uses the Get-AbrNASProxyServer cmdlet to retrieve the NAS proxy server information and the Get-AbrIconType function to determine the icon type.
    Author: Jonathan Colon
    Date: 2024-12-30
    Version: 1.0
    #>
    param ()
    try {
        Write-PScriboMessage "Collecting NAS Proxy information from $($VBRServer)."
        $Proxies = Get-VBRNASProxyServer

        if ($Proxies) {
            $ProxiesInfo = $Proxies | ForEach-Object {
                $inobj = [ordered] @{
                    'Enabled' = if ($_.IsEnabled) { 'Yes' } else { 'No' }
                    'Max Tasks' = $_.ConcurrentTaskNumber
                }

                $IconType = Get-AbrIconType -String 'ProxyServer'

                [PSCustomObject] @{
                    Name = $_.Server.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
        }

        return $ProxiesInfo

    } catch {
        Write-PScriboMessage $_.Exception.Message
    }
}