
function Get-AbrVbrBackupRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.9.0
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
        Write-PScriboMessage "Discovering Veeam VBR Backup Repository information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupRepository
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Repository'
    }

    process {
        try {
            [Array]$BackupRepos = Get-VBRBackupRepository | Where-Object { $_.Type -ne 'SanSnapshotOnly' } | Sort-Object -Property Name
            [Array]$ScaleOuts = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name
            if ($ScaleOuts) {
                $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts | Sort-Object -Property Name
                $BackupRepos += $Extents.Repository
            }
            if ($BackupRepos) {
                $OutObj = @()
                try {
                    foreach ($BackupRepo in $BackupRepos) {

                        $PercentFree = 0
                        if (@($($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes), $($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes)) -ne 0) {
                            $UsedSpace = ($($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes - $($BackupRepo.GetContainer().CachedFreeSpace.InGigabytes)))
                            if ($UsedSpace -ne 0) {
                                $PercentFree = $([Math]::Round($UsedSpace / $($BackupRepo.GetContainer().CachedTotalSpace.InGigabytes) * 100))
                            }
                        }
                        $inObj = [ordered] @{
                            $LocalizedData.Name = $BackupRepo.Name
                            $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupRepo.GetContainer().CachedTotalSpace.InBytesAsUInt64
                            $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupRepo.GetContainer().CachedFreeSpace.InBytesAsUInt64
                            $LocalizedData.UsedSpacePct = $PercentFree
                            $LocalizedData.FreeSpacePct = 100 - $PercentFree
                            $LocalizedData.Status = switch ($BackupRepo.IsUnavailable) {
                                'False' { $LocalizedData.Available }
                                'True' { $LocalizedData.Unavailable }
                                default { $BackupRepo.IsUnavailable }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Backup Repository Section: $($_.Exception.Message)"
                }

                if ($HealthCheck.Infrastructure.BR) {
                    $OutObj | Where-Object { $_."$($LocalizedData.Status)" -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                    $OutObj | Where-Object { $_."$($LocalizedData.UsedSpacePct)" -ge 75 } | Set-Style -Style Warning -Property $LocalizedData.UsedSpacePct
                    $OutObj | Where-Object { $_."$($LocalizedData.UsedSpacePct)" -ge 90 } | Set-Style -Style Critical -Property $LocalizedData.UsedSpacePct
                }

                $TableParams = @{
                    Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                    List = $false
                    Columns = $LocalizedData.Name, $LocalizedData.TotalSpace, $LocalizedData.FreeSpace, $LocalizedData.UsedSpacePct, $LocalizedData.Status
                    ColumnWidths = 46, 12, 12, 17, 13
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                if ($OutObj) {
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        try {
                            $sampleData = $OutObj | Select-Object $LocalizedData.Name, $LocalizedData.UsedSpacePct, $LocalizedData.FreeSpacePct

                            $chartLabels = [string[]]$sampleData."$($LocalizedData.Name)"
                            $chartCategories = @($LocalizedData.UsedSpacePct, $LocalizedData.FreeSpacePct)
                            $chartUsedValues = [double[]]@($sampleData."$($LocalizedData.UsedSpacePct)")
                            $chartFreeValues = [double[]]@($sampleData."$($LocalizedData.FreeSpacePct)")
                            $chartValues = @()
                            foreach ($i in $chartLabels) {
                                $chartValues += , @($chartUsedValues[$chartLabels.IndexOf($i)], $chartFreeValues[$chartLabels.IndexOf($i)])
                            }

                            $statusCustomPalette = @('#9CFFA3', '#FFF3C4', '#FECDD1', '#ADACAF')

                            $chartFileItem = New-StackedBarChart -Title $LocalizedData.ChartTitle -Values $chartValues -Labels $chartLabels -LegendCategories $chartCategories -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 600 -Format base64 -TitleFontBold -TitleFontSize 16 -AreaOrientation Horizontal -LabelXAxis $LocalizedData.ChartXAxis -LabelYAxis $LocalizedData.ChartYAxis
                        } catch {
                            Write-PScriboMessage -IsWarning "Backup Repository graph Section: $($_.Exception.Message)"
                        }

                        if ($chartFileItem) {
                            Image -Text $LocalizedData.ChartAltText -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }

                        BlankLine
                        $OutObj | Sort-Object -Property $LocalizedData.UsedSpacePct | Table @TableParams
                        #---------------------------------------------------------------------------------------------#
                        #                        Backup Repository Configuration Section                              #
                        #---------------------------------------------------------------------------------------------#
                        if ($InfoLevel.Infrastructure.BR -ge 2) {
                            try {
                                Section -Style Heading4 $LocalizedData.ConfigHeading {
                                    Paragraph $LocalizedData.ConfigParagraph
                                    BlankLine
                                    foreach ($BackupRepo in $BackupRepos) {
                                        try {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $($BackupRepo.Name) {
                                                $OutObj = @()

                                                $inObj = [ordered] @{
                                                    $LocalizedData.ExtentOfScaleOut = (($ScaleOuts | Where-Object { ($Extents | Where-Object { $_.name -eq $BackupRepo.Name }).ParentId -eq $_.Id }).Name)
                                                    $LocalizedData.BackupProxy = switch ([string]::IsNullOrEmpty(($BackupRepo.Host).Name)) {
                                                        $true { $LocalizedData.Dash }
                                                        $false { ($BackupRepo.Host).Name }
                                                        default { $LocalizedData.Unknown }
                                                    }
                                                    $LocalizedData.IntegrationType = $BackupRepo.TypeDisplay
                                                    $LocalizedData.Path = switch ([string]::IsNullOrEmpty($BackupRepo.FriendlyPath)) {
                                                        $true { $LocalizedData.Dash }
                                                        $false { $BackupRepo.FriendlyPath }
                                                        default { $LocalizedData.Unknown }
                                                    }
                                                    $LocalizedData.ConnectionType = $BackupRepo.Type
                                                    $LocalizedData.MaxTaskCount = switch ([string]::IsNullOrEmpty($BackupRepo.Options.IsTaskCountUnlim)) {
                                                        $true {
                                                            switch ([string]::IsNullOrEmpty($BackupRepo.Options.MaxTasksCount)) {
                                                                $true { $LocalizedData.Dash }
                                                                $false { $BackupRepo.Options.MaxTasksCount }
                                                                default { $LocalizedData.Unknown }
                                                            }
                                                        }
                                                        $false { $BackupRepo.Options.MaxTaskCount }
                                                        default { $LocalizedData.Unknown }
                                                    }
                                                    $LocalizedData.DataRateLimit = switch ($BackupRepo.Options.CombinedDataRateLimit) {
                                                        $Null { $LocalizedData.Unlimited }
                                                        0 { $LocalizedData.Unlimited }
                                                        default { "$($BackupRepo.Options.CombinedDataRateLimit) MB/s" }
                                                    }
                                                    $LocalizedData.UseNfsOnMountHost = $BackupRepo.UseNfsOnMountHost
                                                    $LocalizedData.SanSnapshotOnly = $BackupRepo.IsSanSnapshotOnly
                                                    $LocalizedData.DedupStorage = $BackupRepo.IsDedupStorage
                                                    $LocalizedData.SplitStoragesPerVm = $BackupRepo.SplitStoragesPerVm
                                                    $LocalizedData.ImmutabilitySupported = $BackupRepo.IsImmutabilitySupported
                                                    $LocalizedData.ImmutabilityEnabled = $BackupRepo.GetImmutabilitySettings().IsEnabled
                                                    $LocalizedData.ImmutabilityInterval = $BackupRepo.GetImmutabilitySettings().IntervalDays
                                                    $LocalizedData.VersionOfCreation = $BackupRepo.VersionOfCreation
                                                    $LocalizedData.HasBackupChainLengthLimitation = $BackupRepo.HasBackupChainLengthLimitation
                                                }
                                                if ($null -eq $inObj[$LocalizedData.ExtentOfScaleOut]) {
                                                    $inObj.Remove($LocalizedData.ExtentOfScaleOut)
                                                }

                                                if ($BackupRepo.Type -in @('GoogleCloudStorage')) {
                                                    $inObj.Add($LocalizedData.RegionId, ($BackupRepos.GoogleCloudOptions.RegionId))
                                                    $inObj.Add($LocalizedData.RegionType, ($BackupRepos.GoogleCloudOptions.RegionType))
                                                    $inObj.Add($LocalizedData.BucketName, ($BackupRepos.GoogleCloudOptions.BucketName))
                                                    $inObj.Add($LocalizedData.FolderName, ($BackupRepos.GoogleCloudOptions.FolderName))
                                                    $inObj.Add($LocalizedData.StorageClass, ($BackupRepos.GoogleCloudOptions.StorageClass))
                                                    $inObj.Add($LocalizedData.EnableNearlineStorageClass, ($BackupRepos.GoogleCloudOptions.EnableNearlineStorageClass))
                                                    $inObj.Add($LocalizedData.EnableColdlineStorageClass, ($BackupRepos.GoogleCloudOptions.EnableColdlineStorageClass))
                                                    $inObj.Remove($LocalizedData.Path)
                                                }

                                                if ($BackupRepo.Type -in @('AmazonS3Compatible', 'WasabiS3', 'GoogleCloudStorage')) {
                                                    $inObj.Add($LocalizedData.ObjectLockEnabled, ($BackupRepo.ObjectLockEnabled))
                                                }

                                                if ($BackupRepo.Type -in @('AmazonS3Compatible', 'WasabiS3', 'GoogleCloudStorage')) {
                                                    $inObj.Add($LocalizedData.MountServer, (Get-VBRServer | Where-Object { $_.id -eq $BackupRepo.MountHostId.Guid }).Name)
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                if ($HealthCheck.Infrastructure.BR) {
                                                    $OutObj | Where-Object { $_."$($LocalizedData.ImmutabilitySupported)" -eq $LocalizedData.Yes } | Set-Style -Style OK -Property $LocalizedData.ImmutabilitySupported
                                                    $OutObj | Where-Object { $_."$($LocalizedData.ImmutabilitySupported)" -eq $LocalizedData.Yes -and $_."$($LocalizedData.ImmutabilityEnabled)" -eq $LocalizedData.No } | Set-Style -Style Warning -Property $LocalizedData.ImmutabilityEnabled
                                                }

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.TableHeading) - $($BackupRepo.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams

                                                if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_."$($LocalizedData.ImmutabilitySupported)" -eq $LocalizedData.Yes -and $_."$($LocalizedData.ImmutabilityEnabled)" -eq $LocalizedData.No })) {
                                                    Paragraph $LocalizedData.HealthCheckTitle -Bold -Underline
                                                    BlankLine
                                                    Paragraph {
                                                        Text $LocalizedData.BestPracticeTitle -Bold
                                                        Text $LocalizedData.BestPracticeText
                                                    }
                                                    BlankLine
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Backup Repository Configuration $($BackupRepo.Name) Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Backup Repository Configuration Section: $($_.Exception.Message)"
                            }
                        }
                        if ($Options.EnableDiagrams) {
                            try {
                                try {
                                    $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-Repository' -DiagramOutput base64
                                } catch {
                                    Write-PScriboMessage -IsWarning "Backup Repository Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                    PageBreak
                                    Section -Style Heading4 $LocalizedData.DiagramHeading {
                                        Image -Base64 $Graph -Text $LocalizedData.DiagramAltText -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
                                        PageBreak
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Backup Repository Diagram Section: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Repository Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Repository'
    }

}