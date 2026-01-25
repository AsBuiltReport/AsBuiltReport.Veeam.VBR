function Get-AbrDiagBackupToRepo {
    <#
    .SYNOPSIS
        Function to build a Backup Server to Repository diagram.
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

    param
    (

    )

    begin {
    }

    process {
        try {
            $BackupRepo = Get-AbrBackupRepoInfo
            $LocalBackupRepo = Get-AbrBackupRepoInfo | Where-Object { $_.Role -like '*Local' -or $_.Role -like '*Hardened' }
            $DedupBackupRepo = Get-AbrBackupRepoInfo | Where-Object { $_.Role -like 'Dedup*' }
            $ObjStorage = Get-AbrBackupObjectRepoInfo
            $ArchiveObjStorage = Get-AbrBackupArchObjRepoInfo
            $NASBackupRepo = Get-AbrBackupRepoInfo | Where-Object { $_.Role -like '*Share' }
            $CloudBackupRepo = Get-AbrBackupRepoInfo | Where-Object { $_.Role -like 'Cloud' }

            if ($BackupServerInfo) {
                if ($BackupRepo) {
                    $RepoSubgraphArray = @()

                    if ($LocalBackupRepo) {
                        if ($LocalBackupRepo.Name.Count -eq 1) {
                            $LocalBackupRepoColumnSize = 1
                        } elseif ($ColumnSize) {
                            $LocalBackupRepoColumnSize = $ColumnSize
                        } else {
                            $LocalBackupRepoColumnSize = $LocalBackupRepo.Name.Count
                        }
                        try {

                            $LocalBackupRepoArray = Add-DiaHtmlNodeTable -Name 'LocalBackupRepoArray' -ImagesObj $Images -inputObject ($LocalBackupRepo | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Repository' -ColumnSize $LocalBackupRepoColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($LocalBackupRepo.AditionalInfo ) -FontSize 18 -SubgraphFontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Local Backup Repositories table Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }
                        try {

                            $LocalBackupRepoSubgraph = Add-DiaHtmlSubGraph -Name 'LocalBackupRepoSubgraph' -ImagesObj $Images -TableArray $LocalBackupRepoArray -Align 'Center' -IconDebug $IconDebug -Label 'Local Repositories' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $LocalBackupRepoColumnSize -FontSize 24 -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Local Backup Repositories Subgraph. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($LocalBackupRepoSubgraph) {
                            $RepoSubgraphArray += $LocalBackupRepoSubgraph
                        }
                    }
                    if ($NASBackupRepo) {
                        if ($NASBackupRepo.Name.Count -eq 1) {
                            $NASBackupRepoColumnSize = 1
                        } elseif ($ColumnSize) {
                            $NASBackupRepoColumnSize = $ColumnSize
                        } else {
                            $NASBackupRepoColumnSize = $NASBackupRepo.Name.Count
                        }
                        try {

                            $NASBackupRepoArray = Add-DiaHtmlNodeTable -Name 'NASBackupRepoArray' -ImagesObj $Images -inputObject ($NASBackupRepo | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_NAS' -ColumnSize $NASBackupRepoColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($NASBackupRepo.AditionalInfo ) -FontSize 18 -SubgraphFontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create NAS Backup Repositories table Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        try {
                            $NASBackupRepoSubgraph = Add-DiaHtmlSubGraph -Name 'NASBackupRepoSubgraph' -ImagesObj $Images -TableArray $NASBackupRepoArray -Align 'Center' -IconDebug $IconDebug -Label 'NAS Repositories' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $NASBackupRepoColumnSize -FontSize 24 -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create NAS Backup Repositories Subgraph. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($NASBackupRepoSubgraph) {
                            $RepoSubgraphArray += $NASBackupRepoSubgraph
                        }
                    }
                    if ($DedupBackupRepo) {
                        if ($DedupBackupRepo.Name.Count -eq 1) {
                            $DedupBackupRepoColumnSize = 1
                        } elseif ($ColumnSize) {
                            $DedupBackupRepoColumnSize = $ColumnSize
                        } else {
                            $DedupBackupRepoColumnSize = $DedupBackupRepo.Name.Count
                        }
                        try {

                            $DedupBackupRepoArray = Add-DiaHtmlNodeTable -Name 'DedupBackupRepoArray' -ImagesObj $Images -inputObject ($DedupBackupRepo | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Deduplicating_Storage' -ColumnSize $DedupBackupRepoColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($DedupBackupRepo.AditionalInfo ) -FontSize 18 -SubgraphFontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Dedup Backup Repositories table Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        try {
                            $DedupBackupRepoSubgraph = Add-DiaHtmlSubGraph -Name 'DedupBackupRepoSubgraph' -ImagesObj $Images -TableArray $DedupBackupRepoArray -Align 'Center' -IconDebug $IconDebug -Label 'Deduplicating Storage Appliances' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $DedupBackupRepoColumnSize -FontSize 24 -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Dedup Backup Repositories Subgraph. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($DedupBackupRepoSubgraph) {
                            $RepoSubgraphArray += $DedupBackupRepoSubgraph
                        }
                    }
                    if ($ObjStorage) {
                        if ($DedupBackupRepo.Name.Count -eq 1) {
                            $ObjStorageColumnSize = 1
                        } elseif ($ColumnSize) {
                            $ObjStorageColumnSize = $ColumnSize
                        } else {
                            $ObjStorageColumnSize = $ObjStorage.Name.Count
                        }
                        try {
                            $ObjStorageArray = Add-DiaHtmlNodeTable -Name 'ObjStorageArray' -ImagesObj $Images -inputObject ($ObjStorage | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Cloud_Repository' -ColumnSize $ObjStorageColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($ObjStorage.AditionalInfo ) -FontSize 18 -SubgraphFontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Object Repositories table Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        try {
                            $ObjStorageSubgraph = Add-DiaHtmlSubGraph -Name 'ObjStorageSubgraph' -ImagesObj $Images -TableArray $ObjStorageArray -Align 'Center' -IconDebug $IconDebug -Label 'Object Repositories' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $ObjStorageColumnSize -FontSize 24 -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Object Repositories Subgraph. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($ObjStorageSubgraph) {
                            $RepoSubgraphArray += $ObjStorageSubgraph
                        }
                    }
                    if ($ArchiveObjStorage) {
                        if ($ArchiveObjStorage.Name.Count -eq 1) {
                            $ArchiveObjStorageColumnSize = 1
                        } elseif ($ColumnSize) {
                            $ArchiveObjStorageColumnSize = $ColumnSize
                        } else {
                            $ArchiveObjStorageColumnSize = $ArchiveObjStorage.Name.Count
                        }
                        try {
                            $ArchiveObjStorageArray = Add-DiaHtmlNodeTable -Name 'ArchiveObjStorageArray' -ImagesObj $Images -inputObject ($ArchiveObjStorage | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Cloud_Repository' -ColumnSize $ArchiveObjStorageColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($ArchiveObjStorage.AditionalInfo ) -FontSize 18 -SubgraphFontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Archive Object Repositories table Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }
                        try {

                            $ArchiveObjStorageSubgraph = Add-DiaHtmlSubGraph -Name 'ArchiveObjStorageSubgraph' -ImagesObj $Images -TableArray $ArchiveObjStorageArray -Align 'Center' -IconDebug $IconDebug -Label 'Archive Object Repositories' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $ArchiveObjStorageColumnSize -FontSize 24 -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Archive Object Repositories Subgraph. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($ArchiveObjStorageSubgraph) {
                            $RepoSubgraphArray += $ArchiveObjStorageSubgraph
                        }
                    }

                    if ($CloudBackupRepo) {
                        if ($CloudBackupRepo.Name.Count -eq 1) {
                            $CloudBackupRepoColumnSize = 1
                        } elseif ($ColumnSize) {
                            $CloudBackupRepoColumnSize = $ColumnSize
                        } else {
                            $CloudBackupRepoColumnSize = $CloudBackupRepo.Name.Count
                        }
                        try {

                            $CloudBackupRepoArray = Add-DiaHtmlNodeTable -Name 'CloudBackupRepoArray' -ImagesObj $Images -inputObject ($CloudBackupRepo | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Cloud_Repository' -ColumnSize $CloudBackupRepoColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($CloudBackupRepo.AditionalInfo ) -FontSize 18 -SubgraphFontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Cloud Backup Repositories table Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }
                        try {

                            $CloudBackupRepoSubgraph = Add-DiaHtmlSubGraph -Name 'CloudBackupRepoSubgraph' -ImagesObj $Images -TableArray $CloudBackupRepoArray -Align 'Center' -IconDebug $IconDebug -Label 'Cloud Repositories' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $CloudBackupRepoColumnSize -FontSize 24 -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Cloud Backup Repositories Subgraph. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($CloudBackupRepoSubgraph) {
                            $RepoSubgraphArray += $CloudBackupRepoSubgraph
                        }
                    }

                    if ($RepoSubgraphArray) {
                        if ($SOBRArray.Count -eq 1) {
                            $RepoSubgraphArrayColumnSize = 1
                        } elseif ($ColumnSize) {
                            $RepoSubgraphArrayColumnSize = $ColumnSize
                        } else {
                            $RepoSubgraphArrayColumnSize = $RepoSubgraphArray.Count
                        }
                        Node -Name MainSubGraph -Attributes @{Label = (Add-DiaHtmlSubGraph -Name 'MainSubGraph' -ImagesObj $Images -TableArray $RepoSubgraphArray -Align 'Center' -IconDebug $IconDebug -Label 'Backup Repositories' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $RepoSubgraphArrayColumnSize -FontSize 26 -FontBold); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                    }

                    Edge -From BackupServers -To MainSubGraph @{minlen = 3 }
                }
            }
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}