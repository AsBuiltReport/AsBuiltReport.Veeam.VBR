
function Get-AbrVbrBackupRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR Backup Repository information from $System."
    }

    process {
        try {
            if ((Get-VBRBackupRepository).count -gt 0) {
                Section -Style Heading3 'Backup Repository' {
                    Paragraph "The following section provides Backup Repository summary information."
                    BlankLine
                    $OutObj = @()
                    try {
                        [Array]$BackupRepos = Get-VBRBackupRepository | Where-Object {$_.Type -ne "SanSnapshotOnly"}
                        [Array]$ScaleOuts = Get-VBRBackupRepository -ScaleOut
                        if ($ScaleOuts) {
                            $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts
                            $BackupRepos += $Extents.Repository
                        }
                        foreach ($BackupRepo in $BackupRepos) {
                            Write-PscriboMessage "Discovered $($BackupRepo.Name) Repository."
                            $PercentFree = 0
                            if (@($($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes),$($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes)) -ne 0) {
                                $UsedSpace = ($($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes-$($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes)))
                                if ($UsedSpace -ne 0) {
                                    $PercentFree = ($UsedSpace/$($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes)).tostring("P")
                                }
                            }
                            $inObj = [ordered] @{
                                'Name' = $BackupRepo.Name
                                'Total Space' = "$($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes) Gb"
                                'Free Space' = "$($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes) Gb"
                                'Space Used' = $PercentFree
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
                        if ([int]([regex]::Matches($OutObj.'Space Used', "\d+(?!.*\d+)").value) -ge 75) { $OutObj | Set-Style -Style Warning -Property 'Space Used' }
                        if ([int]([regex]::Matches($OutObj.'Space Used', "\d+(?!.*\d+)").value) -ge 90) { $OutObj | Set-Style -Style Critical -Property 'Space Used' }

                    }

                    $TableParams = @{
                        Name = "Backup Repository - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 18, 18, 19, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    #---------------------------------------------------------------------------------------------#
                    #                        Backup Repository Configuration Section                              #
                    #---------------------------------------------------------------------------------------------#
                    if ($InfoLevel.Infrastructure.BR -ge 2) {
                        try {
                            Section -Style Heading4 "Backup Repository Configuration" {
                                Paragraph "The following section provides a detailed information of the Veeam Backup Repository Configuration."
                                BlankLine
                                foreach ($BackupRepo in $BackupRepos) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $($BackupRepo.Name) {
                                            $OutObj = @()
                                            Write-PscriboMessage "Discovered $($BackupRepo.Name) Backup Repository."
                                            $inObj = [ordered] @{
                                                'Extent of ScaleOut Backup Repository' = (($ScaleOuts | Where-Object {($Extents | Where-Object {$_.name -eq $BackupRepo.Name}).ParentId -eq $_.Id}).Name)
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
                                                'Immutability Enabled' = ConvertTo-TextYN $BackupRepo.GetImmutabilitySettings().IsEnabled
                                                'Immutability Interval' = $BackupRepo.GetImmutabilitySettings().IntervalDays
                                                'Version Of Creation' = $BackupRepo.VersionOfCreation
                                                'Has Backup Chain Length Limitation' = ConvertTo-TextYN $BackupRepo.HasBackupChainLengthLimitation
                                            }
                                            if ($null -eq $inObj.'Extent of ScaleOut Backup Repository') {
                                                $inObj.Remove('Extent of ScaleOut Backup Repository')
                                            }
                                            $OutObj += [pscustomobject]$inobj

                                            if ($HealthCheck.Infrastructure.BR) {
                                                $OutObj | Where-Object { $_.'Immutability Supported' -eq 'Yes' -and $_.'Immutability Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Immutability Enabled'
                                            }

                                            $TableParams = @{
                                                Name = "Backup Repository - $($BackupRepo.Name)"
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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}