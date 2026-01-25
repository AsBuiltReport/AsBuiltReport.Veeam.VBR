function Get-VbrBackupSobrInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication scale-out backup repository information.
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
        Write-Verbose -Message "Collecting Scale-Out Backup Repository information from $($VBRServer)."
        try {
            $Sobrs = Get-VBRBackupRepository -ScaleOut
            $SobrInfo = @()
            if ($Sobrs) {
                foreach ($Sobr in $Sobrs) {
                    $SobrRows = @{
                        'Placement Policy' = $Sobr.PolicyType
                        'Encryption Enabled' = ConvertTo-TextYN $Sobr.EncryptionEnabled
                    }

                    if ($Sobr.EncryptionEnabled) {
                        $SobrRows.add('Encryption Key', $Sobr.EncryptionKey.Description)
                    }

                    $SobrsExtents = @()

                    foreach ($Extent in $Sobr.Extent) {

                        $PerformanceRows = @{
                            'Path' = $Extent.Repository.FriendlyPath
                            'Total Space' = ConvertTo-FileSizeString -Size $Extent.Repository.GetContainer().CachedTotalSpace.InBytesAsUInt64
                            'Used Space' = ConvertTo-FileSizeString -Size $Extent.Repository.GetContainer().CachedFreeSpace.InBytesAsUInt64
                        }

                        $SobrsExtents += [ordered]@{
                            Name = Remove-SpecialChar -String $Extent.Name -SpecialChars '\'
                            IconType = Get-IconType -String $Extent.Repository.Type
                            AditionalInfo = $PerformanceRows
                        }
                    }

                    $SobrsCapacityExtents = @()

                    foreach ($CapacityExtent in $Sobr.CapacityExtents) {
                        if ($CapacityExtent.Repository.AmazonS3Folder) {
                            $CapacityFolder = $CapacityExtent.Repository.AmazonS3Folder
                        } elseif ($CapacityExtent.Repository.AzureBlobFolder) {
                            $CapacityFolder = $CapacityExtent.Repository.AzureBlobFolder
                        }

                        $CapacityRows = @{
                            Type = $CapacityExtent.Repository.Type
                            Folder = "/$($CapacityFolder)"
                            Gateway = & {
                                if (-not $CapacityExtent.Repository.UseGatewayServer) {
                                    switch ($CapacityExtent.Repository.ConnectionType) {
                                        'Gateway' {
                                            switch (($CapacityExtent.Repository.GatewayServer | Measure-Object).count) {
                                                0 { 'Disable' }
                                                1 { $CapacityExtent.Repository.GatewayServer.Name.Split('.')[0] }
                                                default { 'Automatic' }
                                            }
                                        }
                                        'Direct' { 'Direct' }
                                        default { 'Unknown' }
                                    }
                                } else {
                                    switch (($CapacityExtent.Repository.GatewayServer | Measure-Object).count) {
                                        0 { 'Disable' }
                                        1 { $CapacityExtent.Repository.GatewayServer.Name.Split('.')[0] }
                                        default { 'Automatic' }
                                    }
                                }
                            }
                        }

                        $SobrsCapacityExtents += [ordered]@{
                            Name = Remove-SpecialChar -String $CapacityExtent.Repository.Name -SpecialChars '\'
                            IconType = Get-IconType -String $CapacityExtent.Repository.Type
                            AditionalInfo = $CapacityRows
                        }
                    }

                    if ($Sobr.ArchiveExtent.Repository.AzureBlobFolder) {
                        $ArchiveFolder = $Sobr.ArchiveExtent.Repository.AzureBlobFolder
                    } else { $ArchiveFolder = 'Unknown' }

                    $ArchiveRows = [ordered]@{
                        Type = $Sobr.ArchiveExtent.Repository.ArchiveType
                        Gateway = & {
                            if (-not $Sobr.ArchiveExtent.Repository.UseGatewayServer) {
                                switch ($Sobr.ArchiveExtent.Repository.GatewayMode) {
                                    'Gateway' {
                                        switch (($Sobr.ArchiveExtent.Repository.GatewayServer | Measure-Object).count) {
                                            0 { 'Disable' }
                                            1 { $Sobr.ArchiveExtent.Repository.GatewayServer.Name.Split('.')[0] }
                                            default { 'Automatic' }
                                        }
                                    }
                                    'Direct' { 'Direct' }
                                    default { 'Unknown' }
                                }
                            } else {
                                switch (($Sobr.ArchiveExtent.Repository.GatewayServer | Measure-Object).count) {
                                    0 { 'Disable' }
                                    1 { $Sobr.ArchiveExtent.Repository.GatewayServer.Name.Split('.')[0] }
                                    default { 'Automatic' }
                                }
                            }
                        }
                    }

                    if ($Sobr.ArchiveExtent.Repository.AzureBlobFolder) {
                        $ArchiveRows.add('Folder', "/$($ArchiveFolder.Name)")
                        $ArchiveRows.add('Container', $($ArchiveFolder.Container))
                    }

                    $TempSobrInfo = [PSCustomObject]@{
                        Name = "$($Sobr.Name.toUpper())"
                        Label = Add-DiaNodeIcon -Name "$($Sobr.Name)" -IconType 'VBR_SOBR_Repo' -Align 'Center' -Rows $SobrRows -ImagesObj $Images -IconDebug $IconDebug -FontSize 16 -FontBold

                        Capacity = $SobrsCapacityExtents

                        Archive = $Sobr.ArchiveExtent.Repository | Select-Object -Property @{Name = 'Name'; Expression = { Remove-SpecialChar -String $_.Name -SpecialChars '\' } }, @{Name = 'AditionalInfo'; Expression = { $ArchiveRows } }, @{Name = 'IconType'; Expression = { Get-IconType -String $_.ArchiveType } }

                        Performance = $SobrsExtents
                    }
                    $SobrInfo += $TempSobrInfo
                }
            }

            return $SobrInfo
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}