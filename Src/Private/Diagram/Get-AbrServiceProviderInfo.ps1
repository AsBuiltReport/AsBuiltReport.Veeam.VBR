function Get-AbrServiceProviderInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication (VBR) service providers.

    .DESCRIPTION
        The Get-AbrServiceProviderInfo function collects and returns information about service providers configured in Veeam Backup & Replication.
        It sorts the service providers by their DNS name and categorizes them based on the types of resources they have enabled (BaaS, DRaaS, vCD, or Unknown).

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject containing the DNS name and additional information about each service provider.

    .EXAMPLE
        PS C:\> Get-AbrServiceProviderInfo
        Retrieves and displays information about the service providers configured in Veeam Backup & Replication.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and imported.
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Service Provider information from $($VBRServer)."
        $ServiceProviders = Get-VBRCloudProvider | Sort-Object -Property 'DNSName'

        if ($ServiceProviders) {
            $ServiceProvidersInfo = $ServiceProviders | ForEach-Object {
                $cloudConnectType = if ($_.ResourcesEnabled -and $_.ReplicationResourcesEnabled) {
                    'BaaS and DRaaS'
                } elseif ($_.ResourcesEnabled) {
                    'BaaS'
                } elseif ($_.ReplicationResourcesEnabled) {
                    'DRaas'
                } elseif ($_.vCDReplicationResources) {
                    'vCD'
                } else { 'Unknown' }

                $inobj = [ordered] @{
                    'Cloud Connect Type' = $cloudConnectType
                    'Managed By Provider' = ConvertTo-TextYN $_.IsManagedByProvider
                }

                [PSCustomObject] @{
                    Name = $_.DNSName
                    AditionalInfo = $inobj
                }
            }
            return $ServiceProvidersInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}