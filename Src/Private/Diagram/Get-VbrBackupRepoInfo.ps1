function Get-VbrBackupRepoInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication backup repository information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.6.36
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]

    param (
    )

    process {
        Write-Verbose -Message "Collecting Backup Repository information from $($VBRServer)."
        try {
            [Array]$BackupRepos = Get-VBRBackupRepository
            [Array]$ScaleOuts = Get-VBRBackupRepository -ScaleOut
            $ViBackupProxy = Get-VBRViProxy
            $HvBackupProxy = Get-VBRHvProxy

            if ($ScaleOuts) {
                $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts
                $BackupRepos += $Extents.Repository
            }
            $BackupRepoInfo = @()
            if ($BackupRepos) {
                foreach ($BackupRepo in $BackupRepos) {

                    $Role = Get-RoleType -String $BackupRepo.Type

                    $Rows = @{}

                    if ($Role -like '*Local' -or $Role -like '*Hardened' -or $Role -like 'Cloud') {
                        $Rows.add('Server', $BackupRepo.Host.Name.Split('.')[0])
                        $Rows.add('Path', $BackupRepo.FriendlyPath)
                        $Rows.add('Total-Space', (ConvertTo-FileSizeString -Size $BackupRepo.GetContainer().CachedTotalSpace.InBytesAsUInt64))
                        $Rows.add('Used-Space', (ConvertTo-FileSizeString -Size ($BackupRepo).GetContainer().CachedFreeSpace.InBytesAsUInt64))
                    } elseif ($Role -like 'Dedup*') {
                        $Rows.add('DedupType', $BackupRepo.TypeDisplay)
                        $Rows.add('Total-Space', (ConvertTo-FileSizeString -Size ($BackupRepo).GetContainer().CachedTotalSpace.InBytesAsUInt64))
                        $Rows.add('Used-Space', (ConvertTo-FileSizeString -Size ($BackupRepo).GetContainer().CachedFreeSpace.InBytesAsUInt64))
                    } elseif ($Role -like '*Share') {
                        $Rows.add('Path', $BackupRepo.FriendlyPath)
                        $Rows.add('Total-Space', (ConvertTo-FileSizeString -Size ($BackupRepo).GetContainer().CachedTotalSpace.InBytesAsUInt64))
                        $Rows.add('Used-Space', (ConvertTo-FileSizeString -Size ($BackupRepo).GetContainer().CachedFreeSpace.InBytesAsUInt64))
                    } else {
                        $Rows.add('Server', 'Uknown')
                        $Rows.add('Path', 'Uknown')
                        $Rows.add('Total-Space', '0 B')
                        $Rows.add('Used-Space', '0 B')
                    }

                    if (($Role -ne 'Dedup Appliances') -and ($Role -ne 'SAN') -and ($Role -notlike '*Share') -and ($BackupRepo.Host.Name -in $ViBackupProxy.Host.Name -or $BackupRepo.Host.Name -in $HvBackupProxy.Host.Name)) {
                        $BackupType = 'Proxy'
                    } else { $BackupType = $BackupRepo.Type }

                    $Type = Get-IconType -String $BackupType

                    $TempBackupRepoInfo = [PSCustomObject]@{
                        Name = "$((Remove-SpecialChar -String $BackupRepo.Name -SpecialChars '\').toUpper())"
                        Label = Add-DiaNodeIcon -Name "$((Remove-SpecialChar -String $BackupRepo.Name -SpecialChars '\').toUpper())" -IconType $Type -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontBold
                        Role = $Role
                        AditionalInfo = $Rows
                    }

                    $BackupRepoInfo += $TempBackupRepoInfo
                }
            }

            return $BackupRepoInfo
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}