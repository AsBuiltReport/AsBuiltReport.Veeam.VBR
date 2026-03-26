
function Get-AbrVbrScaleOutRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR ScaleOut Backup Repository Information
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
        Write-PScriboMessage "Discovering Veeam V&R ScaleOut Backup Repository information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrScaleOutRepository
        Show-AbrDebugExecutionTime -Start -TitleMessage 'ScaleOut Backup Repository'
    }

    process {
        try {
            if ($BackupRepos = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($BackupRepo in $BackupRepos) {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $BackupRepo.Name
                                $LocalizedData.PerformanceTier = $BackupRepo.Extent.Name
                                $LocalizedData.CapacityTier = switch ($BackupRepo.CapacityExtents.Repository.Name) {
                                    $null { $LocalizedData.NotConfigured }
                                    default { $BackupRepo.CapacityExtents.Repository.Name }
                                }
                                $LocalizedData.ArchiveTier = switch ($BackupRepo.ArchiveExtent.Repository.Name) {
                                    $null { $LocalizedData.NotConfigured }
                                    default { $BackupRepo.ArchiveExtent.Repository.Name }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Table: $($_.Exception.Message)"
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.SOBRTable) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 25, 25, 25, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                    #---------------------------------------------------------------------------------------------#
                    #                               SOBR Configuration Section                                    #
                    #---------------------------------------------------------------------------------------------#
                    if ($InfoLevel.Infrastructure.SOBR -ge 2) {
                        try {
                            Section -Style Heading4 $LocalizedData.ConfigHeading {
                                Paragraph $LocalizedData.ConfigParagraph
                                BlankLine
                                #---------------------------------------------------------------------------------------------#
                                #                                   Per SOBR Section                                          #
                                #---------------------------------------------------------------------------------------------#
                                foreach ($BackupRepo in $BackupRepos) {
                                    Section -Style Heading5 $($BackupRepo.Name) {
                                        try {
                                            #---------------------------------------------------------------------------------------------#
                                            #                               General Configuration Section                                 #
                                            #---------------------------------------------------------------------------------------------#
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.GeneralSettings {
                                                $OutObj = @()

                                                $inObj = [ordered] @{
                                                    $LocalizedData.PlacementPolicy = ($BackupRepo.PolicyType -creplace '([A-Z\W_]|\d+)(?<![a-z])', ' $&').trim()
                                                    $LocalizedData.UsePerVMBackupFiles = $BackupRepo.UsePerVMBackupFiles
                                                    $LocalizedData.PerformFullWhenExtentOffline = $BackupRepo.PerformFullWhenExtentOffline
                                                    $LocalizedData.UseCapacityTier = $BackupRepo.EnableCapacityTier
                                                    $LocalizedData.EncryptDataUploadedToObjectStorage = $BackupRepo.EncryptionEnabled
                                                    $LocalizedData.EncryptionKey = switch ($BackupRepo.EncryptionKey.Description) {
                                                        $null { $LocalizedData.Disabled }
                                                        default { $BackupRepo.EncryptionKey.Description }
                                                    }
                                                    $LocalizedData.MoveBackupFileOlderThan = $BackupRepo.OperationalRestorePeriod
                                                    $LocalizedData.OverridePolicyEnabled = $BackupRepo.OverridePolicyEnabled
                                                    $LocalizedData.OverrideSpaceThreshold = $BackupRepo.OverrideSpaceThreshold
                                                    $LocalizedData.UseArchiveGFSTier = $BackupRepo.ArchiveTierEnabled
                                                    $LocalizedData.ArchiveGFSBackupOlderThan = "$($BackupRepo.ArchivePeriod) days"
                                                    $LocalizedData.StoreArchivedBackupAsStandaloneFulls = $BackupRepo.ArchiveFullBackupModeEnabled
                                                    $LocalizedData.CostOptimizedArchiveEnabled = $BackupRepo.CostOptimizedArchiveEnabled
                                                    $LocalizedData.Description = $BackupRepo.Description
                                                }

                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                if ($HealthCheck.Infrastructure.Settings) {
                                                    $OutObj | Where-Object { $_.$($LocalizedData.EncryptDataUploadedToObjectStorage) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.EncryptDataUploadedToObjectStorage
                                                }

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.GeneralSettings) - $($BackupRepo.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }

                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }

                                                $OutObj | Table @TableParams
                                                if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_.$($LocalizedData.EncryptDataUploadedToObjectStorage) -like 'No' })) {
                                                    Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                    BlankLine
                                                    Paragraph {
                                                        Text $LocalizedData.BestPractice -Bold
                                                        Text $LocalizedData.BestPracticeEncryptDesc
                                                    }
                                                    BlankLine
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "ScaleOut Backup Repository General Settings Table: $($_.Exception.Message)"
                                        }
                                        foreach ($Extent in $BackupRepo.Extent) {
                                            try {
                                                #---------------------------------------------------------------------------------------------#
                                                #                               Performace Tier Section                                       #
                                                #---------------------------------------------------------------------------------------------#
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.PerformanceTierSection {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $Extent.Name
                                                        $LocalizedData.Repository = $Extent.Repository.Name
                                                        $LocalizedData.Path = $Extent.Repository.FriendlyPath
                                                        $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size (($Extent).Repository).GetContainer().CachedTotalSpace.InBytesAsUInt64
                                                        $LocalizedData.UsedSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size (($Extent).Repository).GetContainer().CachedFreeSpace.InBytesAsUInt64
                                                        $LocalizedData.Status = $Extent.Status
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Infrastructure.Settings) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.Status) -ne 'Normal' } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.PerformanceTierTable) - $($Extent.Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Performance Tier Table: $($_.Exception.Message)"
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                               Capacity Tier Section                                         #
                                        #---------------------------------------------------------------------------------------------#
                                        foreach ($CapacityExtent in $BackupRepo.CapacityExtents) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.CapacityTierSection {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = ($CapacityExtent.Repository).Name
                                                        $LocalizedData.ServicePoint = ($CapacityExtent.Repository).ServicePoint
                                                        $LocalizedData.Type = ($CapacityExtent.Repository).Type
                                                        $LocalizedData.AmazonS3Folder = ($CapacityExtent.Repository).AmazonS3Folder
                                                        $LocalizedData.UseGatewayServer = ($CapacityExtent.Repository).UseGatewayServer
                                                        $LocalizedData.GatewayServer = switch ((($CapacityExtent.Repository).GatewayServer.Name).length) {
                                                            0 { $LocalizedData.Auto }
                                                            default { ($CapacityExtent.Repository).GatewayServer.Name }
                                                        }
                                                        $LocalizedData.ImmutabilityPeriod = $CapacityExtent.Repository.ImmutabilityPeriod
                                                        $LocalizedData.ImmutabilityEnabled = $CapacityExtent.Repository.BackupImmutabilityEnabled
                                                        $LocalizedData.SizeLimitEnabled = ($CapacityExtent.Repository).SizeLimitEnabled
                                                        $LocalizedData.SizeLimit = ($CapacityExtent.Repository).SizeLimit
                                                    }
                                                    if (($CapacityExtent.Repository).Type -eq 'AmazonS3') {
                                                        $inObj.remove($LocalizedData.ServicePoint)
                                                        $inObj.add($LocalizedData.UseIAStorageClass, (($CapacityExtent.Repository).EnableIAStorageClass))
                                                        $inObj.add($LocalizedData.UseOZIAStorageClass, (($CapacityExtent.Repository).EnableOZIAStorageClass))
                                                    } elseif (($CapacityExtent.Repository).Type -eq 'AzureBlob') {
                                                        $inObj.remove($LocalizedData.ServicePoint)
                                                        $inObj.remove($LocalizedData.AmazonS3Folder)
                                                        $inObj.add($LocalizedData.AzureBlobName, ($CapacityExtent.Repository.AzureBlobFolder).Name)
                                                        $inObj.add($LocalizedData.AzureBlobContainer, ($CapacityExtent.Repository.AzureBlobFolder).Container)
                                                    }

                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    if ($HealthCheck.Infrastructure.SOBR) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.ImmutabilityEnabled) -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.ImmutabilityEnabled
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.CapacityTierTable) - $(($CapacityExtent.Repository).Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                    if ($BackupRepo.OffloadWindowOptions) {
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.OffloadWindowSection {
                                                            Paragraph -ScriptBlock $Legend

                                                            $OutObj = @()
                                                            try {
                                                                $OutObj = Get-WindowsTimePeriod -InputTimePeriod $BackupRepo.OffloadWindowOptions

                                                                $TableParams = @{
                                                                    Name = "$($LocalizedData.OffloadWindowTable) - $(($CapacityExtent.Repository).Name)"
                                                                    List = $true
                                                                    ColumnWidths = 6, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4
                                                                    Key = 'H'
                                                                }
                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                if ($OutObj) {
                                                                    $OutObj2 = Table -Hashtable $OutObj @TableParams
                                                                    $OutObj2.Rows | Where-Object { $_.Sun -eq '0' } | Set-Style -Style OFF -Property 'Sun'
                                                                    $OutObj2.Rows | Where-Object { $_.Mon -eq '0' } | Set-Style -Style OFF -Property 'Mon'
                                                                    $OutObj2.Rows | Where-Object { $_.Tue -eq '0' } | Set-Style -Style OFF -Property 'Tue'
                                                                    $OutObj2.Rows | Where-Object { $_.Wed -eq '0' } | Set-Style -Style OFF -Property 'Wed'
                                                                    $OutObj2.Rows | Where-Object { $_.Thu -eq '0' } | Set-Style -Style OFF -Property 'Thu'
                                                                    $OutObj2.Rows | Where-Object { $_.Fri -eq '0' } | Set-Style -Style OFF -Property 'Fri'
                                                                    $OutObj2.Rows | Where-Object { $_.Sat -eq '0' } | Set-Style -Style OFF -Property 'Sat'

                                                                    $OutObj2.Rows | Where-Object { $_.Sun -eq '1' } | Set-Style -Style ON -Property 'Sun'
                                                                    $OutObj2.Rows | Where-Object { $_.Mon -eq '1' } | Set-Style -Style ON -Property 'Mon'
                                                                    $OutObj2.Rows | Where-Object { $_.Tue -eq '1' } | Set-Style -Style ON -Property 'Tue'
                                                                    $OutObj2.Rows | Where-Object { $_.Wed -eq '1' } | Set-Style -Style ON -Property 'Wed'
                                                                    $OutObj2.Rows | Where-Object { $_.Thu -eq '1' } | Set-Style -Style ON -Property 'Thu'
                                                                    $OutObj2.Rows | Where-Object { $_.Fri -eq '1' } | Set-Style -Style ON -Property 'Fri'
                                                                    $OutObj2.Rows | Where-Object { $_.Sat -eq '1' } | Set-Style -Style ON -Property 'Sat'
                                                                    $OutObj2
                                                                }
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning $_.Exception.Message
                                                            }
                                                        }
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Capacity Tier Table: $($_.Exception.Message)"
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                               Archive Tier Section                                         #
                                        #---------------------------------------------------------------------------------------------#
                                        foreach ($ArchiveExtent in $BackupRepo.ArchiveExtent) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.ArchiveTierSection {
                                                    $OutObj = @()

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = ($ArchiveExtent.Repository).Name
                                                        $LocalizedData.Type = ($ArchiveExtent.Repository).ArchiveType
                                                        $LocalizedData.UseGatewayServer = ($ArchiveExtent.Repository).UseGatewayServer
                                                        $LocalizedData.GatewayServer = switch ((($ArchiveExtent.Repository).GatewayServer.Name).length) {
                                                            0 { $LocalizedData.Auto }
                                                            default { ($ArchiveExtent.Repository).GatewayServer.Name }
                                                        }
                                                    }
                                                    if (($ArchiveExtent.Repository).ArchiveType -eq 'AzureArchive') {
                                                        $inObj.add($LocalizedData.AzureServiceType, ($ArchiveExtent.Repository.AzureBlobFolder).ServiceType)
                                                        $inObj.add($LocalizedData.AzureBlobName, ($ArchiveExtent.Repository.AzureBlobFolder).Name)
                                                        $inObj.add($LocalizedData.AzureBlobContainer, ($ArchiveExtent.Repository.AzureBlobFolder).Container)
                                                    }

                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.ArchiveTierTable) - $(($ArchiveExtent.Repository).Name)"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Archive Tier Table: $($_.Exception.Message)"
                                            }
                                        }

                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Configuration Section: $($_.Exception.Message)"
                        }
                    }
                    if ($Options.EnableDiagrams -and (Get-VBRBackupRepository -ScaleOut)) {
                        try {
                            try {
                                $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-Sobr' -DiagramOutput base64
                            } catch {
                                Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Diagram: $($_.Exception.Message)"
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
                            Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Diagram Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Document: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'ScaleOut Backup Repository'
    }

}