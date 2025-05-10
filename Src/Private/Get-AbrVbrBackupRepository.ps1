
function Get-AbrVbrBackupRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        Show-AbrDebugExecutionTime -Start -TitleMessage "Backup Repository"
    }

    process {
        try {
            [Array]$BackupRepos = Get-VBRBackupRepository | Where-Object { $_.Type -ne "SanSnapshotOnly" } | Sort-Object -Property Name
            [Array]$ScaleOuts = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name
            if ($ScaleOuts) {
                $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts | Sort-Object -Property Name
                $BackupRepos += $Extents.Repository
            }
            if ($BackupRepos) {
                $OutObj = @()
                try {
                    foreach ($BackupRepo in $BackupRepos) {
                        Write-PScriboMessage "Discovered $($BackupRepo.Name) Repository."
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
                            'Status' = Switch ($BackupRepo.IsUnavailable) {
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
                        Paragraph "The following section provides Backup Repository summary information."
                        BlankLine
                        try {
                            $sampleData = $OutObj | Select-Object Name, 'Used Space %', 'Free Space %'

                            $CustomPalette1 = @(
                                [System.Drawing.ColorTranslator]::FromHtml('#565656')

                            )
                            if ($Options.ReportStyle -eq "Veeam") {
                                $CustomPalette = @(
                                    [System.Drawing.ColorTranslator]::FromHtml('#565656')
                                    [System.Drawing.ColorTranslator]::FromHtml('#DFF0D0')
                                )
                                $CustomPalette2 = @(
                                    [System.Drawing.ColorTranslator]::FromHtml('#DFF0D0')
                                )
                            } else {
                                $CustomPalette = @(
                                    [System.Drawing.ColorTranslator]::FromHtml('#565656')
                                    [System.Drawing.ColorTranslator]::FromHtml('#d5e2ff')
                                )
                                $CustomPalette2 = @(
                                    [System.Drawing.ColorTranslator]::FromHtml('#d5e2ff')
                                )
                            }
                            $exampleChart = New-Chart -Name BKRepo -Width 600 -Height 600 -BorderStyle Dash -BorderWidth 1 -CustomPalette $CustomPalette -BorderColor DarkGreen

                            $addChartAreaParams = @{
                                Chart = $exampleChart
                                Name = 'exampleChartArea'
                                AxisXTitle = 'Backup Repositories'
                                AxisYTitle = '%'
                                NoAxisXMajorGridLines = $true
                                NoAxisYMajorGridLines = $true
                                AxisXLabelFont = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '8')
                                AxisXTitleFont = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '10')
                                AxisYLabelFont = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '8')
                                AxisYTitleFont = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '10')
                                NoAxisYMargin = $true
                                AxisXInterval = 1
                            }
                            $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                            $addChartSeriesParams = @{
                                Chart = $exampleChart
                                ChartArea = $exampleChartArea
                                XField = 'Name'
                                ColorPerDataPoint = $true
                            }

                            $sampleData | Add-StackedBarChartSeries @addChartSeriesParams -Name 'USEDSPACE' -YField 'Used Space %' -LegendText 'Used' -CustomPalette $CustomPalette1 -LabelForeColor 'White'
                            $sampleData | Add-StackedBarChartSeries @addChartSeriesParams -Name 'FREESPACE' -YField 'Free Space %' -LegendText 'Free' -CustomPalette $CustomPalette2
                            $addChartTitleParams = @{
                                Chart = $exampleChart
                                ChartArea = $exampleChartArea
                                Name = 'PercentUsedSpace'
                                Text = '% Space Utilization'
                                Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '12', [System.Drawing.FontStyle]::Bold)
                            }

                            Add-ChartTitle @addChartTitleParams

                            $addChartLegendParams = @{
                                Chart = $exampleChart
                                Name = 'Repository Utilization'
                                TitleAlignment = 'Center'
                                Style = 'Row'
                                Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Segoe Ui', '8')
                                Dock = 'Bottom'
                            }
                            Add-ChartLegend @addChartLegendParams

                            $TempPath = Resolve-Path ([System.IO.Path]::GetTempPath())

                            $ChartImage = Export-Chart -Chart $exampleChart -Path $TempPath.Path -Format "PNG" -PassThru

                            try {
                                $chartFileItem = [convert]::ToBase64String((Get-Content $ChartImage -Encoding byte))
                            } catch {
                                Write-PScriboMessage -IsWarning "Backup Repository Base64String: $($_.Exception.Message)"
                            }

                            Remove-Item -Path $ChartImage.FullName
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
                                Section -Style Heading4 "Backup Repository Configuration" {
                                    Paragraph "The following section provides a detailed information of the Veeam Backup Repository Configuration."
                                    BlankLine
                                    foreach ($BackupRepo in $BackupRepos) {
                                        try {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $($BackupRepo.Name) {
                                                $OutObj = @()
                                                Write-PScriboMessage "Discovered $($BackupRepo.Name) Backup Repository."
                                                $inObj = [ordered] @{
                                                    'Extent of ScaleOut Backup Repository' = (($ScaleOuts | Where-Object { ($Extents | Where-Object { $_.name -eq $BackupRepo.Name }).ParentId -eq $_.Id }).Name)
                                                    'Backup Proxy' = Switch ([string]::IsNullOrEmpty(($BackupRepo.Host).Name)) {
                                                        $true { '--' }
                                                        $false { ($BackupRepo.Host).Name }
                                                        default { 'Unknown' }
                                                    }
                                                    'Integration Type' = $BackupRepo.TypeDisplay
                                                    'Path' = Switch ([string]::IsNullOrEmpty($BackupRepo.FriendlyPath)) {
                                                        $true { '--' }
                                                        $false { $BackupRepo.FriendlyPath }
                                                        default { 'Unknown' }
                                                    }
                                                    'Connection Type' = $BackupRepo.Type
                                                    'Max Task Count' = Switch ([string]::IsNullOrEmpty($BackupRepo.Options.MaxTaskCount)) {
                                                        $true {
                                                            Switch ([string]::IsNullOrEmpty($BackupRepo.Options.MaxTasksCount)) {
                                                                $true { '--' }
                                                                $false { $BackupRepo.Options.MaxTasksCount }
                                                                default { 'Unknown' }
                                                            }
                                                        }
                                                        $false { $BackupRepo.Options.MaxTaskCount }
                                                        default { 'Unknown' }
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
                                                    Paragraph "Health Check:" -Bold -Underline
                                                    BlankLine
                                                    Paragraph {
                                                        Text "Best Practice:" -Bold
                                                        Text "Veeam recommend to implement Immutability where it is supported. It is done for increased security: immutability protects your data from loss as a result of attacks, malware activity or any other injurious actions."
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
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Repository Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage "Backup Repository"
    }

}