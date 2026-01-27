function Get-AbrBackupObjectRepoInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication object storage repository information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.8.24
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
        Write-PScriboMessage "Collecting Object Storage Repository information from $($VBRServer)."
        try {
            $ObjStorages = Get-VBRObjectStorageRepository
            $ObjStorageInfo = @()
            if ($ObjStorages) {
                foreach ($ObjStorage in $ObjStorages) {

                    if ($ObjStorage.AmazonS3Folder) {
                        $Folder = $ObjStorage.AmazonS3Folder
                    } elseif ($ObjStorage.AzureBlobFolder) {
                        $Folder = $ObjStorage.AzureBlobFolder
                    } else { $Folder = 'Unknown' }

                    $Rows = @{
                        Type = $ObjStorage.Type
                        Folder = $Folder
                        Gateway = & {
                            if (-not $ObjStorage.UseGatewayServer) {
                                switch ($ObjStorage.ConnectionType) {
                                    'Gateway' {
                                        switch (($ObjStorage.GatewayServer | Measure-Object).count) {
                                            0 { 'Disable' }
                                            1 { $ObjStorage.GatewayServer.Name.Split('.')[0] }
                                            default { 'Automatic' }
                                        }
                                    }
                                    'Direct' { 'Direct' }
                                    default { 'Unknown' }
                                }
                            } else {
                                switch (($ObjStorage.GatewayServer | Measure-Object).count) {
                                    0 { 'Disable' }
                                    1 { $ObjStorage.GatewayServer.Name.Split('.')[0] }
                                    default { 'Automatic' }
                                }
                            }
                        }
                    }

                    $TempObjStorageInfo = [PSCustomObject]@{
                        Name = "$($ObjStorage.Name)"
                        Label = Add-DiaNodeIcon -Name $($ObjStorage.Name) -IconType 'VBR_Cloud_Repository' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontBold
                        AditionalInfo = $Rows
                    }
                    $ObjStorageInfo += $TempObjStorageInfo
                }
            }

            return $ObjStorageInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}