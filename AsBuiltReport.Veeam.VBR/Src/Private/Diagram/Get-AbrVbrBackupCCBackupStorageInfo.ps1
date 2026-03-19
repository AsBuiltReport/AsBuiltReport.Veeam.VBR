function Get-AbrBackupCCBackupStorageInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication cloud connect backup storage information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.9.0
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
        Write-PScriboMessage "Collecting Cloud Connect Backup Storage information from $($VBRServer)."
        try {

            $BackupCCBKStorageInfo = @()

            if ($CloudObjects = (Get-VBRCloudTenant).Resources | Sort-Object -Property RepositoryFriendlyName) {
                foreach ($CloudObject in ($CloudObjects.Repository | Sort-Object -Property Name -Unique)) {

                    $Type = Get-AbrIconType -String $CloudObject.Type

                    $AditionalInfo = [PSCustomObject] [ordered] @{
                        Type = $CloudObject.Type
                        'Total Space' = ConvertTo-FileSizeString -Size $CloudObject.GetContainer().CachedTotalSpace.InBytesAsUInt64
                        'Free Space' = ConvertTo-FileSizeString -Size $CloudObject.GetContainer().CachedFreeSpace.InBytesAsUInt64
                        Path = switch ([string]::IsNullOrEmpty($CloudObject.FriendlyPath)) {
                            $true { 'Unknown' }
                            $false { $CloudObject.FriendlyPath }
                            default { '--' }
                        }
                    }

                    $TempBackupCCBKStorageInfo = [PSCustomObject]@{
                        Name = $CloudObject.Name
                        Label = Add-NodeIcon -Name "$((Remove-SpecialCharacter -String $CloudObject.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType $Type -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                        Id = $CloudObject.Id
                        AditionalInfo = $AditionalInfo
                        IconType = $Type
                    }

                    $BackupCCBKStorageInfo += $TempBackupCCBKStorageInfo
                }
            }

            return $BackupCCBKStorageInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
            return $BackupCCBKStorageInfo
        }
    }
    end {}
}