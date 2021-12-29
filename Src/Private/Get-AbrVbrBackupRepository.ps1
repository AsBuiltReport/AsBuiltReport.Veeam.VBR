
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
        Write-PscriboMessage "Discovering Veeam VBR Backup Repository information from $System."
    }

    process {
        Section -Style Heading3 'Backup Repository' {
            Paragraph "The following section provides a summary of the Veeam Backup Server."
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
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                if ($HealthCheck.Infrastructure.BR) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
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
                if ($InfoLevel.Infrastructure.BR -ge 2) {
                    try {
                        Section -Style Heading4 "Backup Repository Configuration" {
                            Paragraph "The following section provides a detailed information of the Veeam Backup Repository Configuration"
                            BlankLine
                            $BackupRepos = Get-VBRBackupRepository
                            foreach ($BackupRepo in $BackupRepos) {
                                try {
                                    Section -Style Heading5 "$($BackupRepo.Name)" {
                                        Paragraph "The following section provides a detailed information of the $($BackupRepo.Name) Backup Repository"
                                        BlankLine
                                        $OutObj = @()
                                        Write-PscriboMessage "Discovered $($BackupRepo.Name) Backup Repository."
                                        $inObj = [ordered] @{
                                            'Backup Proxy' = ($BackupRepo.Host).Name
                                            'Integration Type' = $BackupRepo.TypeDisplay
                                            'Path' = $BackupRepo.Path
                                            'Connection Type' = $BackupRepo.Type
                                            'Max Task Count' = $BackupRepo.Options.MaxTaskCount
                                            'Use Nfs On Mount Host' = ConvertTo-TextYN $BackupRepo.UseNfsOnMountHost
                                            'San Snapshot Only' = ConvertTo-TextYN $BackupRepo.IsSanSnapshotOnly
                                            'Dedup Storage' = ConvertTo-TextYN $BackupRepo.IsDedupStorage
                                            'Split Storages Per Vm' = ConvertTo-TextYN $BackupRepo.SplitStoragesPerVm
                                            'Immutability Supported' = ConvertTo-TextYN $BackupRepo.IsImmutabilitySupported
                                            'Version Of Creation' = $BackupRepo.VersionOfCreation
                                            'Has Backup Chain Length Limitation' = ConvertTo-TextYN $BackupRepo.HasBackupChainLengthLimitation
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        if ($HealthCheck.Infrastructure.BR) {
                                            $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                        }

                                        $TableParams = @{
                                            Name = "Backup Repository Information - $($BackupRepo.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        }
    }
    end {}

}