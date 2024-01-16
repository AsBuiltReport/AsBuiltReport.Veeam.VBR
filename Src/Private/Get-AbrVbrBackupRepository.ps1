
function Get-AbrVbrBackupRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.4
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
            [Array]$BackupRepos = Get-VBRBackupRepository | Where-Object {$_.Type -ne "SanSnapshotOnly"} | Sort-Object -Property Name
            [Array]$ScaleOuts = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name
            if ($ScaleOuts) {
                $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts | Sort-Object -Property Name
                $BackupRepos += $Extents.Repository
            }
            if ($BackupRepos) {
                $OutObj = @()
                try {
                    foreach ($BackupRepo in $BackupRepos) {
                        Write-PscriboMessage "Discovered $($BackupRepo.Name) Repository."
                        $PercentFree = 0
                        if (@($($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes),$($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes)) -ne 0) {
                            $UsedSpace = ($($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes-$($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes)))
                            if ($UsedSpace -ne 0) {
                                $PercentFree = $([Math]::Round($UsedSpace/$($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes) * 100))
                            }
                        }
                        $inObj = [ordered] @{
                            'Name' = $BackupRepo.Name
                            'Total Space' = "$($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes) Gb"
                            'Free Space' = "$($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes) Gb"
                            'Used Space %' = $PercentFree
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
                    Write-PscriboMessage -IsWarning "Backup Repository Section: $($_.Exception.Message)"
                }

                if ($HealthCheck.Infrastructure.BR) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                    $OutObj | Where-Object { $_.'Used Space %' -ge 75} | Set-Style -Style Warning -Property 'Used Space %'
                    $OutObj | Where-Object { $_.'Used Space %' -ge 90} | Set-Style -Style Critical -Property 'Used Space %'
                }

                $TableParams = @{
                    Name = "Backup Repository - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 30, 18, 18, 19, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                if ($Options.EnableCharts) {
                    try {
                        $sampleData = $OutObj | Select-Object -Property 'Name','Used Space %'

                        $chartFileItem = Get-PieChart -SampleData $sampleData -ChartName 'BackupRepository' -XField 'Name' -YField 'Used Space %' -ChartLegendName 'Backup Repository' -ChartTitleName 'UsedSpace' -ChartTitleText 'Percentage of Used Space'
                    } catch {
                        Write-PscriboMessage -IsWarning "Backup Repository chart section: $($_.Exception.Message)"
                    }
                }

                if ($OutObj) {
                    Section -Style Heading3 'Backup Repository' {
                        Paragraph "The following section provides Backup Repository summary information."
                        BlankLine
                        if ($Options.EnableCharts -and $chartFileItem) {
                            Image -Text 'Backup Repository - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }
                        BlankLine
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
                                                    'Backup Proxy' = Switch ([string]::IsNullOrEmpty(($BackupRepo.Host).Name)) {
                                                        $true {'--'}
                                                        $false {($BackupRepo.Host).Name}
                                                        default {'Unknown'}
                                                    }
                                                    'Integration Type' = $BackupRepo.TypeDisplay
                                                    'Path' = Switch ([string]::IsNullOrEmpty($BackupRepo.FriendlyPath)) {
                                                        $true {'--'}
                                                        $false {$BackupRepo.FriendlyPath}
                                                        default {'Unknown'}
                                                    }
                                                    'Connection Type' = $BackupRepo.Type
                                                    'Max Task Count' = Switch ([string]::IsNullOrEmpty($BackupRepo.Options.MaxTaskCount)) {
                                                        $true {
                                                            Switch ([string]::IsNullOrEmpty($BackupRepo.Options.MaxTasksCount)) {
                                                                $true {'--'}
                                                                $false {$BackupRepo.Options.MaxTasksCount}
                                                                default {'Unknown'}
                                                            }
                                                        }
                                                        $false {$BackupRepo.Options.MaxTaskCount}
                                                        default {'Unknown'}
                                                    }
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

                                                if ($BackupRepo.Type -in @('AmazonS3Compatible','WasabiS3')) {
                                                    $inObj.Add('Object Lock Enabled', (ConvertTo-TextYN $BackupRepo.ObjectLockEnabled))
                                                }

                                                if ($BackupRepo.Type -in @('AmazonS3Compatible','WasabiS3')) {
                                                    $inObj.Add('Mount Server', (Get-VBRServer | Where-Object {$_.id -eq $BackupRepo.MountHostId.Guid}).Name)
                                                }

                                                $OutObj += [pscustomobject]$inobj

                                                if ($HealthCheck.Infrastructure.BR) {
                                                    $OutObj | Where-Object { $_.'Immutability Supported' -eq 'Yes' } | Set-Style -Style OK -Property 'Immutability Supported'
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

                                                if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_.'Immutability Supported' -eq 'Yes' -and $_.'Immutability Enabled' -eq 'No' })) {
                                                    Paragraph "Health Check:" -Bold -Underline
                                                    BlankLine
                                                    Paragraph {
                                                        Text "Best Practice:" -Bold
                                                        Text "Veeam recommend to implement Immutability where it is supported. It is done for increased security: immutability protects your data from loss as a result of attacks, malware activity or any other injurious actions."
                                                    }
                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Backup Repository Configuration $($BackupRepo.Name) Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Backup Repository Configuration Section: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Backup Repository Section: $($_.Exception.Message)"
        }
    }
    end {}

}