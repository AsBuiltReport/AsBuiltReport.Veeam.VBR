
function Get-AbrVbrBackupRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Repository Information
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam V&R Backup Repository information from $System."
    }

    process {
        Section -Style Heading2 'Backup Repository' {
            Paragraph "The following section provides a summary of the Veeam Backup Server"
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $BackupRepos = Get-VBRBackupRepository
                    foreach ($BackupRepo in $BackupRepos) {
                        Write-PscriboMessage "Discovered $($BackupRepo.Name) Repository."
                        $inObj = [ordered] @{
                            'Name' = $BackupRepo.Name
                            'Total Space' = "$($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes) Gb"
                            'Free Space' = "$($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes) Gb"
                            'Status' = Switch ($BackupRepo.IsUnavailable) {
                                'False' {'Available'}
                                'True' {'Unavailable'}
                                default {$BackupRepo.IsUnavailable}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage $_.Exception.Message
                }

                $TableParams = @{
                    Name = "Backup Repository Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                    List = $false
                    ColumnWidths = 30, 25, 30, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
    }
    end {}

}