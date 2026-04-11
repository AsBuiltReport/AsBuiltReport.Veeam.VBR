function Get-AbrProxyInfo {
    <#
    .SYNOPSIS
    Retrieves information about Veeam Backup & Replication proxies.

    .DESCRIPTION
    The Get-AbrProxyInfo function collects information about Veeam Backup & Replication proxies from the VBR server.
    It retrieves both vSphere and Hyper-V proxies and formats the information into a custom object with additional details.

    .PARAMETER None
    This function does not take any parameters.

    .OUTPUTS
    System.Object
    Returns a collection of custom objects containing proxy information, including the proxy type, maximum tasks, and icon type.

    .EXAMPLE
    PS C:\> Get-AbrProxyInfo
    Collects and returns information about Veeam Backup & Replication proxies from the VBR server.

    .NOTES
    Author: Jonathan Colon
    Date: 2024-12-30
    Version: 1.0
    #>
    param ()
    try {
        Write-PScriboMessage "Collecting proxy information from $($VBRServer)."
        $Proxies = @(Get-VBRViProxy) + @(Get-VBRHvProxy)

        if ($Proxies) {
            $ProxiesInfo = $Proxies | ForEach-Object {
                $inobj = [ordered] @{
                    'Type' = switch ($_.Type) {
                        'Vi' { 'vSphere' }
                        'HvOffhost' { 'Off host' }
                        'HvOnhost' { 'On host' }
                        default { $_.Type }
                    }
                    'Max Tasks' = $_.Options.MaxTasksCount
                }

                $IconType = Get-AbrIconType -String 'ProxyServer'

                [PSCustomObject] @{
                    Name = $_.Host.Name
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