function Get-AbrArchObjectRepoInfo {
    <#
    .SYNOPSIS
    Retrieves information about Veeam Backup & Replication archive object repositories.

    .DESCRIPTION
    The Get-AbrArchObjectRepoInfo function retrieves detailed information about the archive object repositories configured in Veeam Backup & Replication.

    .EXAMPLE
    Get-AbrArchObjectRepoInfo

    This example retrieves information about all archive object repositories.

    .OUTPUTS
    System.Object
    Returns objects containing information about the archive object repositories.

    .NOTES
    Author: Jonathan Colon
    Date: 2024-12-30
    Version: 1.0
    #>
    param ()
    try {
        Write-PScriboMessage "Collecting Archive Object Repository information from $($VBRServer)."
        $ArchObjStorages = Get-VBRArchiveObjectStorageRepository | Sort-Object -Property Name
        if ($ArchObjStorages) {
            $ArchObjRepositoriesInfo = $ArchObjStorages | ForEach-Object {
                $inobj = [ordered] @{
                    'Type' = $_.ArchiveType
                    'Gateway' = if (-not $_.UseGatewayServer) {
                        switch ($_.GatewayMode) {
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

                $IconType = Get-AbrIconType -String $_.ArchiveType

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $ArchObjRepositoriesInfo
        }
    } catch {
        Write-PScriboMessage $_.Exception.Message
    }
}