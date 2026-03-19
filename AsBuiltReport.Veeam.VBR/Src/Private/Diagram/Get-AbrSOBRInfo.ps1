function Get-AbrSOBRInfo {
    <#
    .SYNOPSIS
        Retrieves information about Scale-Out Backup Repositories (SOBR) from a Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-AbrSOBRInfo function collects and returns information about Scale-Out Backup Repositories (SOBR) from a Veeam Backup & Replication server.
        It retrieves the SOBR details, including the placement policy and encryption status, and returns them as a custom PowerShell object.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a custom PowerShell object containing the name of the SOBR and additional information such as placement policy and encryption status.

    .EXAMPLE
        PS C:\> Get-AbrSOBRInfo
        Retrieves and displays information about all Scale-Out Backup Repositories from the connected Veeam Backup & Replication server.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and connected to a Veeam Backup & Replication server.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>
    param ()
    try {
        Write-PScriboMessage "Collecting Scale-Out Backup Repository information from $($VBRServer)."
        $SOBR = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name

        if ($SOBR) {
            $SOBRInfo = $SOBR | ForEach-Object {
                $inobj = [ordered] @{
                    'Placement Policy' = $_.PolicyType
                    'Encryption Enabled' = if ($_.EncryptionEnabled) { 'Yes' } else { 'No' }
                }

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }
            }
            return $SOBRInfo
        }
    } catch {
        Write-PScriboMessage $_.Exception.Message
    }
}