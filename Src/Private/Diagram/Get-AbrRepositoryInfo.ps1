function Get-AbrRepositoryInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication repositories.

    .DESCRIPTION
        The Get-AbrRepositoryInfo function collects and returns detailed information about Veeam Backup & Replication repositories, excluding certain types such as SanSnapshotOnly, AmazonS3Compatible, WasabiS3, and SmartObjectS3. It also includes information about Scale-Out Backup Repositories and their extents.

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject containing repository information including server name, repository type, total space, used space, and icon type.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and configured.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    .EXAMPLE
        PS C:\> Get-AbrRepositoryInfo
        Retrieves and displays information about all Veeam Backup & Replication repositories.

    #>
    param ()
    try {
        Write-Verbose "Collecting Repository information from $($VBRServer)."
        $Repositories = Get-VBRBackupRepository | Where-Object { $_.Type -notin @('SanSnapshotOnly', 'AmazonS3Compatible', 'WasabiS3', 'SmartObjectS3') } | Sort-Object -Property Name
        $ScaleOuts = Get-AbrBackupRepository -ScaleOut | Sort-Object -Property Name

        if ($ScaleOuts) {
            $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts | Sort-Object -Property Name
            $Repositories += $Extents.Repository
        }

        if ($Repositories) {
            $RepositoriesInfo = $Repositories | ForEach-Object {
                $Role = Get-AbrRoleType -String $_.Type

                $Rows = [ordered] @{
                    'Server' = if ($_.Host.Name) { $_.Host.Name.Split('.')[0] } else { 'N/A' }
                    'Repo Type' = $Role
                    'Total Space' = (ConvertTo-FileSizeString -Size $_.GetContainer().CachedTotalSpace.InBytesAsUInt64)
                    'Used Space' = (ConvertTo-FileSizeString -Size $_.GetContainer().CachedFreeSpace.InBytesAsUInt64)
                }

                $BackupType = if (($Role -ne 'Dedup Appliances') -and ($Role -ne 'SAN') -and ($_.Host.Name -in $ViBackupProxy.Host.Name -or $_.Host.Name -in $HvBackupProxy.Host.Name)) {
                    'Proxy'
                } else { $_.Type }

                $IconType = Get-AbrIconType -String $BackupType

                [PSCustomObject] @{
                    Name = "$((Remove-SpecialChar -String $_.Name -SpecialChars '\').toUpper())"
                    AditionalInfo = $Rows
                    IconType = $IconType
                }
            }

            return $RepositoriesInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}