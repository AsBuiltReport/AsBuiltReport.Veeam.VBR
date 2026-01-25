function Get-AbrObjectRepoInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication object repositories.

    .DESCRIPTION
        The Get-AbrObjectRepoInfo function queries and returns detailed information about object repositories configured in Veeam Backup & Replication.
        This includes details such as repository name, type, capacity, and other relevant properties.

    .PARAMETER RepoName
        The name of the repository to retrieve information for. If not specified, information for all repositories will be returned.

    .EXAMPLE
        Get-AbrObjectRepoInfo -RepoName "MyRepository"
        Retrieves information about the repository named "MyRepository".

    .EXAMPLE
        Get-AbrObjectRepoInfo
        Retrieves information about all configured object repositories.

    .NOTES
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>

    param ()
    try {
        Write-Verbose "Collecting Object Repository information from $($VBRServer)."
        $ObjectRepositories = Get-VBRObjectStorageRepository
        if ($ObjectRepositories) {
            $ObjectRepositoriesInfo = $ObjectRepositories | ForEach-Object {
                $inobj = [ordered] @{
                    'Type' = $_.Type
                    'Folder' = if ($_.AmazonS3Folder) {
                        $_.AmazonS3Folder
                    } elseif ($_.AzureBlobFolder) {
                        $_.AzureBlobFolder
                    } else { 'Unknown' }
                    'Gateway' = if (-not $_.UseGatewayServer) {
                        switch ($_.ConnectionType) {
                            'Gateway' {
                                switch (($_.GatewayServer | Measure-Object).Count) {
                                    0 { 'Disable' }
                                    1 { $_.GatewayServer.Name.Split('.')[0] }
                                    default { 'Automatic' }
                                }
                            }
                            'Direct' { 'Direct' }
                            default { 'Unknown' }
                        }
                    } else {
                        switch (($_.GatewayServer | Measure-Object).Count) {
                            0 { 'Disable' }
                            1 { $_.GatewayServer.Name.Split('.')[0] }
                            default { 'Automatic' }
                        }
                    }
                }

                $IconType = Get-AbrIconType -String $_.Type

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $ObjectRepositoriesInfo
        }
    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}