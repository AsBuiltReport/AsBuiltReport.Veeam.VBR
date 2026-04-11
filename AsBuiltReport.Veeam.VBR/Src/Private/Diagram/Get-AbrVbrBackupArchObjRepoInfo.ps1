function Get-AbrBackupArchObjRepoInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication archive object storage repository information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        1.0.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]

    param
    (

    )
    process {
        Write-PScriboMessage "Collecting Archive Object Storage Repository information from $($VBRServer)."
        try {
            $ArchObjStorages = Get-VbrArchiveObjectStorageRepository
            $ArchObjStorageInfo = @()
            if ($ArchObjStorages) {
                foreach ($ArchObjStorage in $ArchObjStorages) {

                    if ($ArchObjStorage.AmazonS3Folder) {
                        $Folder = $ArchObjStorage.AmazonS3Folder
                        $Container = 'N/A'
                    } elseif ($ArchObjStorage.AzureBlobFolder) {
                        $Folder = $ArchObjStorage.AzureBlobFolder.Name
                        $Container = $ArchObjStorage.AzureBlobFolder.Container
                    } else { $Folder = 'Unknown' }

                    $Rows = @{
                        Type = $ArchObjStorage.ArchiveType
                        Folder = $Folder
                        Gateway = & {
                            if (-not $ArchObjStorage.UseGatewayServer) {
                                switch ($ArchObjStorage.GatewayMode) {
                                    'Gateway' {
                                        switch (($ArchObjStorage.GatewayServer | Measure-Object).count) {
                                            0 { 'Disable' }
                                            1 { $ArchObjStorage.GatewayServer.Name.Split('.')[0] }
                                            default { 'Automatic' }
                                        }
                                    }
                                    'Direct' { 'Direct' }
                                    default { 'Unknown' }
                                }
                            } else {
                                switch (($ArchObjStorage.GatewayServer | Measure-Object).count) {
                                    0 { 'Disable' }
                                    1 { $ArchObjStorage.GatewayServer.Name.Split('.')[0] }
                                    default { 'Automatic' }
                                }
                            }
                        }
                        Container = $Container
                    }

                    $TempObjStorageInfo = [PSCustomObject]@{
                        Name = "$($ArchObjStorage.Name)"
                        Label = Add-NodeIcon -Name $($ArchObjStorage.Name) -IconType 'VBR_Cloud_Repository' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor
                        AditionalInfo = $Rows
                    }
                    $ArchObjStorageInfo += $TempObjStorageInfo
                }
            }

            return $ArchObjStorageInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}