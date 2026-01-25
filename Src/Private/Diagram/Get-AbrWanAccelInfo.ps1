function Get-AbrWanAccelInfo {
    <#
    .SYNOPSIS
        Retrieves information about WAN Accelerators from the Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-AbrWanAccelInfo function collects and returns information about WAN Accelerators configured on the Veeam Backup & Replication server.
        It retrieves details such as cache size and traffic port for each WAN Accelerator.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject containing the name and additional information (cache size and traffic port) of each WAN Accelerator.

    .EXAMPLE
        PS C:\> Get-AbrWanAccelInfo
        Retrieves and displays information about all WAN Accelerators from the Veeam Backup & Replication server.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and imported.
        Ensure that you have the necessary permissions to access the Veeam Backup & Replication server.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Wan Accel information from $($VBRServer)."
        $WanAccels = Get-VBRWANAccelerator

        if ($WanAccels) {
            $WanAccelsInfo = $WanAccels | ForEach-Object {
                $inobj = [ordered] @{
                    'CacheSize' = "$($_.FindWaHostComp().Options.MaxCacheSize) $($_.FindWaHostComp().Options.SizeUnit)"
                    'TrafficPort' = "$($_.GetWaTrafficPort())/TCP"
                }

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }
            }
        }

        return $WanAccelsInfo

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}