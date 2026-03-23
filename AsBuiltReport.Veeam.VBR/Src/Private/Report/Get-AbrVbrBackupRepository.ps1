
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
                            'Name' = $BackupRepo.Name
                            'Total Space' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupRepo.GetContainer().CachedTotalSpace.InBytesAsUInt64
                            'Free Space' = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $BackupRepo.GetContainer().CachedFreeSpace.InBytesAsUInt64
                            'Used Space %' = $PercentFree
                            'Free Space %' = 100 - $PercentFree
                            'Status' = switch ($BackupRepo.IsUnavailable) {
                                'False' { 'Available' }
                                'True' { 'Unavailable' }
                                default { $BackupRepo.IsUnavailable }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Backup Repository Section: $($_.Exception.Message)"
                }

                if ($HealthCheck.Infrastructure.BR) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                    $OutObj | Where-Object { $_.'Used Space %' -ge 75 } | Set-Style -Style Warning -Property 'Used Space %'
                    $OutObj | Where-Object { $_.'Used Space %' -ge 90 } | Set-Style -Style Critical -Property 'Used Space %'
                }

                $TableParams = @{
                    Name = "Backup Repository - $VeeamBackupServer"
                    List = $false
                    Columns = 'Name', 'Total Space', 'Free Space', 'Used Space %', 'Status'
                    ColumnWidths = 46, 12, 12, 17, 13
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }

                if ($OutObj) {
                    Section -Style Heading3 'Backup Repository' {
                        Paragraph 'The following section summarizes all configured backup repositories, including total capacity, available free space, and current utilization.'
                        BlankLine
                        try {
                            $sampleData = $OutObj | Select-Object Name, 'Used Space %', 'Free Space %'

                            $chartLabels = [string[]]$sampleData.Name
                            $chartCategories = @('Used Space %', 'Free Space %')
                            $chartUsedValues = [double[]]@($sampleData.'Used Space %')
                            $chartFreeValues = [double[]]@($sampleData.'Free Space %')
                            $chartValues = @()
                            foreach ($i in $chartLabels) {
                                $chartValues += , @($chartUsedValues[$chartLabels.IndexOf($i)], $chartFreeValues[$chartLabels.IndexOf($i)])
                            }

                            $statusCustomPalette = @('#DFF0D0', '#FFF4C7', '#FEDDD7', '#878787')

                            $chartFileItem = New-StackedBarChart -Title '% Space Utilization' -Values $chartValues -Labels $chartLabels -LegendCategories $chartCategories -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 600 -Format base64 -TitleFontBold -TitleFontSize 16 -AreaOrientation Horizontal -LabelXAxis 'Backup Repositories' -LabelYAxis 'Percentage'
                        } catch {
                            Write-PScriboMessage -IsWarning "Backup Repository graph Section: $($_.Exception.Message)"
                        }

                        if ($chartFileItem) {
                            Image -Text 'Backup Repository - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                        }

                        BlankLine
                        $OutObj | Sort-Object -Property 'Used Space %' | Table @TableParams
                        #---------------------------------------------------------------------------------------------#
                        #                        Backup Repository Configuration Section                              #
                        #---------------------------------------------------------------------------------------------#
                        if ($InfoLevel.Infrastructure.BR -ge 2) {
                            try {
                                Section -Style Heading4 'Backup Repository Configuration' {
                                    Paragraph 'The following section provides detailed configuration information for each backup repository, including storage type, path, and retention settings.'
                                    BlankLine
                                    foreach ($BackupRepo in $BackupRepos) {
                                        try {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $($BackupRepo.Name) {
                                                $OutObj = @()

                                                $inObj = [ordered] @{
                                                    'Extent of ScaleOut Backup Repository' = (($ScaleOuts | Where-Object { ($Extents | Where-Object { $_.name -eq $BackupRepo.Name }).ParentId -eq $_.Id }).Name)
                                                    'Backup Proxy' = switch ([string]::IsNullOrEmpty(($BackupRepo.Host).Name)) {
                                                        $true { '--' }
                                                        $false { ($BackupRepo.Host).Name }
                                                        default { 'Unknown' }
                                                    }
                                                    'Integration Type' = $BackupRepo.TypeDisplay
                                                    'Path' = switch ([string]::IsNullOrEmpty($BackupRepo.FriendlyPath)) {
                                                        $true { '--' }
                                                        $false { $BackupRepo.FriendlyPath }
                                                        default { 'Unknown' }
                                                    }
                                                    'Connection Type' = $BackupRepo.Type
                                                    'Max Task Count' = switch ([string]::IsNullOrEmpty($BackupRepo.Options.IsTaskCountUnlim)) {
                                                        $true {
                                                            switch ([string]::IsNullOrEmpty($BackupRepo.Options.MaxTasksCount)) {
                                                                $true { '--' }
                                                                $false { $BackupRepo.Options.MaxTasksCount }
                                                                default { 'Unknown' }
                                                            }
                                                        }
                                                        $false { $BackupRepo.Options.MaxTaskCount }
                                                        default { 'Unknown' }
                                                    }
                                                    'Data Rate Limit' = switch ($BackupRepo.Options.CombinedDataRateLimit) {
                                                        $Null { 'Unlimited' }
                                                        0 { 'Unlimited' }
                                                        default { "$($BackupRepo.Options.CombinedDataRateLimit) MB/s" }
                                                    }
                                                    'Use Nfs On Mount Host' = $BackupRepo.UseNfsOnMountHost
                                                    'San Snapshot Only' = $BackupRepo.IsSanSnapshotOnly
                                                    'Dedup Storage' = $BackupRepo.IsDedupStorage
                                                    'Split Storages Per Vm' = $BackupRepo.SplitStoragesPerVm
                                                    'Immutability Supported' = $BackupRepo.IsImmutabilitySupported
                                                    'Immutability Enabled' = $BackupRepo.GetImmutabilitySettings().IsEnabled
                                                    'Immutability Interval' = $BackupRepo.GetImmutabilitySettings().IntervalDays
                                                    'Version Of Creation' = $BackupRepo.VersionOfCreation
                                                    'Has Backup Chain Length Limitation' = $BackupRepo.HasBackupChainLengthLimitation
                                                }
                                                if ($null -eq $inObj.'Extent of ScaleOut Backup Repository') {
                                                    $inObj.Remove('Extent of ScaleOut Backup Repository')
                                                }

                                                if ($BackupRepo.Type -in @('GoogleCloudStorage')) {
                                                    $inObj.Add('Region Id', ($BackupRepos.GoogleCloudOptions.RegionId))
                                                    $inObj.Add('Region Type', ( $BackupRepos.GoogleCloudOptions.RegionType))
                                                    $inObj.Add('Bucket Name', ( $BackupRepos.GoogleCloudOptions.BucketName))
                                                    $inObj.Add('Folder Name', ( $BackupRepos.GoogleCloudOptions.FolderName))
                                                    $inObj.Add('Storage Class', ( $BackupRepos.GoogleCloudOptions.StorageClass))
                                                    $inObj.Add('Enable Nearline Storage Class', ( $BackupRepos.GoogleCloudOptions.EnableNearlineStorageClass))
                                                    $inObj.Add('Enable Coldline Storage Class', ( $BackupRepos.GoogleCloudOptions.EnableColdlineStorageClass))
                                                    $inObj.Remove('Path')
                                                }

                                                if ($BackupRepo.Type -in @('AmazonS3Compatible', 'WasabiS3', 'GoogleCloudStorage')) {
                                                    $inObj.Add('Object Lock Enabled', ($BackupRepo.ObjectLockEnabled))
                                                }

                                                if ($BackupRepo.Type -in @('AmazonS3Compatible', 'WasabiS3', 'GoogleCloudStorage')) {
                                                    $inObj.Add('Mount Server', (Get-VBRServer | Where-Object { $_.id -eq $BackupRepo.MountHostId.Guid }).Name)
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

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
                                                    Paragraph 'Health Check:' -Bold -Underline
                                                    BlankLine
                                                    Paragraph {
                                                        Text 'Best Practice:' -Bold
                                                        Text 'Veeam recommend to implement Immutability where it is supported. It is done for increased security: immutability protects your data from loss as a result of attacks, malware activity or any other injurious actions.'
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
                                    Section -Style Heading4 'Backup Repository Diagram' {
                                        Image -Base64 $Graph -Text 'Backup Repository Diagram' -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
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