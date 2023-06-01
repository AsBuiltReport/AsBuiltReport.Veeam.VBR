
function Get-AbrVbrScaleOutRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR ScaleOut Backup Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.2
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
        Write-PscriboMessage "Discovering Veeam V&R ScaleOut Backup Repository information from $System."
    }

    process {
        try {
            if ((Get-VBRBackupRepository -ScaleOut).count -gt 0) {
                Section -Style Heading3 'ScaleOut Backup Repository' {
                    Paragraph "The following section provides a summary about ScaleOut Backup Repository"
                    BlankLine
                    $OutObj = @()
                    try {
                        $BackupRepos = Get-VBRBackupRepository -ScaleOut
                        foreach ($BackupRepo in $BackupRepos) {
                            Write-PscriboMessage "Discovered $($BackupRepo.Name) Repository."
                            $inObj = [ordered] @{
                                'Name' = $BackupRepo.Name
                                'Performance Tier' = $BackupRepo.Extent.Name
                                'Capacity Tier' = Switch ($BackupRepo.CapacityExtent.Repository.Name) {
                                    $null {'Not configured'}
                                    default {$BackupRepo.CapacityExtent.Repository.Name}
                                }
                                'Archive Tier' = Switch ($BackupRepo.ArchiveExtent.Repository.Name) {
                                    $null {'Not configured'}
                                    default {$BackupRepo.ArchiveExtent.Repository.Name}
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "ScaleOut Backup Repository Table: $($_.Exception.Message)"
                    }

                    $TableParams = @{
                        Name = "Scale Backup Repository - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 25, 25, 25, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    #---------------------------------------------------------------------------------------------#
                    #                               SOBR Configuration Section                                    #
                    #---------------------------------------------------------------------------------------------#
                    if ($InfoLevel.Infrastructure.SOBR -ge 2) {
                        try {
                            Section -Style Heading4 "ScaleOut Backup Repository Configuration" {
                                Paragraph "The following section provides a detailed information about the ScaleOut Backup Repository"
                                BlankLine
                                $BackupRepos = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name
                                #---------------------------------------------------------------------------------------------#
                                #                                   Per SOBR Section                                          #
                                #---------------------------------------------------------------------------------------------#
                                foreach ($BackupRepo in $BackupRepos) {
                                    Section -Style Heading5 $($BackupRepo.Name) {
                                        try {
                                            #---------------------------------------------------------------------------------------------#
                                            #                               General Configuration Section                                 #
                                            #---------------------------------------------------------------------------------------------#
                                            Section -Style NOTOCHeading6 -ExcludeFromTOC "General Settings" {
                                                $OutObj = @()
                                                Write-PscriboMessage "Discovered $($BackupRepo.Name) General Settings."
                                                $inObj = [ordered] @{
                                                    'Placement Policy' = ($BackupRepo.PolicyType -creplace  '([A-Z\W_]|\d+)(?<![a-z])',' $&').trim()
                                                    'Use Per VM Backup Files' = ConvertTo-TextYN $BackupRepo.UsePerVMBackupFiles
                                                    'Perform Full When Extent Offline' = ConvertTo-TextYN $BackupRepo.PerformFullWhenExtentOffline
                                                    'Use Capacity Tier' = ConvertTo-TextYN $BackupRepo.EnableCapacityTier
                                                    'Encrypt data uploaded to Object Storage' = ConvertTo-TextYN $BackupRepo.EncryptionEnabled
                                                    'Encryption Key' = Switch ($BackupRepo.EncryptionKey.Description) {
                                                        $null {'Disabled'}
                                                        default {$BackupRepo.EncryptionKey.Description}
                                                    }
                                                    'Move backup file older than' = $BackupRepo.OperationalRestorePeriod
                                                    'Override Policy Enabled' = ConvertTo-TextYN $BackupRepo.OverridePolicyEnabled
                                                    'Override Space Threshold' = $BackupRepo.OverrideSpaceThreshold
                                                    'Use Archive GFS Tier' = ConvertTo-TextYN $BackupRepo.ArchiveTierEnabled
                                                    'Archive GFS Backup older than' = "$($BackupRepo.ArchivePeriod) days"
                                                    'Store archived backup as standalone fulls' = ConvertTo-TextYN $BackupRepo.ArchiveFullBackupModeEnabled
                                                    'Cost Optimized Archive Enabled' = ConvertTo-TextYN $BackupRepo.CostOptimizedArchiveEnabled
                                                    'Description' = $BackupRepo.Description
                                                }

                                                $OutObj = [pscustomobject]$inobj

                                                if ($HealthCheck.Infrastructure.Settings) {
                                                    $OutObj | Where-Object { $_.'Encrypt data uploaded to Object Storage' -like 'No'} | Set-Style -Style Warning -Property 'Encrypt data uploaded to Object Storage'
                                                }

                                                $TableParams = @{
                                                    Name = "General Settings - $($BackupRepo.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }

                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }

                                                $OutObj | Table @TableParams
                                                if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_.'Encrypt data uploaded to Object Storage' -like 'No'})) {
                                                    Paragraph "Health Check:" -Italic -Bold -Underline
                                                    Paragraph "Best Practice: Veeam Backup & Replication allows you to encrypt offloaded data. With the Encrypt data uploaded to object storage setting selected, the entire collection of blocks along with the metadata will be encrypted while being offloaded regardless of the jobs encryption settings. This helps you protect the data from an unauthorized access." -Italic -Bold
                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "ScaleOut Backup Repository General Settings Table: $($_.Exception.Message)"
                                        }
                                        foreach ($Extent in $BackupRepo.Extent) {
                                            try {
                                                #---------------------------------------------------------------------------------------------#
                                                #                               Performace Tier Section                                       #
                                                #---------------------------------------------------------------------------------------------#
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Performance Tier" {
                                                    $OutObj = @()
                                                    Write-PscriboMessage "Discovered $($Extent.Name) Performance Tier."
                                                    $inObj = [ordered] @{
                                                        'Name' = $Extent.Name
                                                        'Repository' = $Extent.Repository.Name
                                                        'Path' = $Extent.Repository.FriendlyPath
                                                        'Total Space' = "$((($BackupRepo.Extent).Repository).GetContainer().CachedTotalSpace.InGigabytes) GB"
                                                        'Used Space' = "$((($BackupRepo.Extent).Repository).GetContainer().CachedFreeSpace.InGigabytes) GB"
                                                        'Status' = $Extent.Status
                                                    }
                                                    $OutObj += [pscustomobject]$inobj

                                                    if ($HealthCheck.Infrastructure.Settings) {
                                                        $OutObj | Where-Object { $_.'Status' -ne 'Normal'} | Set-Style -Style Warning -Property 'Status'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Performance Tier - $($Extent.Name)"
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
                                                Write-PscriboMessage -IsWarning "ScaleOut Backup Repository Performance Tier Table: $($_.Exception.Message)"
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                               Capacity Tier Section                                         #
                                        #---------------------------------------------------------------------------------------------#
                                        foreach ($CapacityExtent in $BackupRepo.CapacityExtent) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Capacity Tier" {
                                                    $OutObj = @()
                                                    Write-PscriboMessage "Discovered $(($CapacityExtent.Repository).Name) Capacity Tier."
                                                    $inObj = [ordered] @{
                                                        'Name' = ($CapacityExtent.Repository).Name
                                                        'Service Point' = ($CapacityExtent.Repository).ServicePoint
                                                        'Type' =  ($CapacityExtent.Repository).Type
                                                        'Amazon S3 Folder' =  ($CapacityExtent.Repository).AmazonS3Folder
                                                        'Use Gateway Server' = ConvertTo-TextYN ($CapacityExtent.Repository).UseGatewayServer
                                                        'Gateway Server' = Switch ((($CapacityExtent.Repository).GatewayServer.Name).length) {
                                                            0 {"Auto"}
                                                            default {($CapacityExtent.Repository).GatewayServer.Name}
                                                        }
                                                        'Immutability Period' = $CapacityExtent.Repository.ImmutabilityPeriod
                                                        'Immutability Enabled'= ConvertTo-TextYN $CapacityExtent.Repository.BackupImmutabilityEnabled
                                                        'Size Limit Enabled' = ConvertTo-TextYN ($CapacityExtent.Repository).SizeLimitEnabled
                                                        'Size Limit' = ($CapacityExtent.Repository).SizeLimit
                                                    }
                                                    if (($CapacityExtent.Repository).Type -eq 'AmazonS3') {
                                                        $inObj.remove('Service Point')
                                                        $inObj.add('Use IA Storage Class', (ConvertTo-TextYN ($CapacityExtent.Repository).EnableIAStorageClass))
                                                        $inObj.add('Use OZ IA Storage Class', (ConvertTo-TextYN ($CapacityExtent.Repository).EnableOZIAStorageClass))
                                                    } elseif (($CapacityExtent.Repository).Type -eq 'AzureBlob') {
                                                        $inObj.remove('Service Point')
                                                        $inObj.remove('Amazon S3 Folder')
                                                        $inObj.add('Azure Blob Name', ($CapacityExtent.Repository.AzureBlobFolder).Name)
                                                        $inObj.add('Azure Blob Container', ($CapacityExtent.Repository.AzureBlobFolder).Container)
                                                    }

                                                    $OutObj += [pscustomobject]$inobj

                                                    if ($HealthCheck.Infrastructure.SOBR) {
                                                        $OutObj | Where-Object { $_.'Immutability Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Immutability Enabled'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Capacity Tier - $(($CapacityExtent.Repository).Name)"
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
                                                Write-PscriboMessage -IsWarning "ScaleOut Backup Repository Capacity Tier Table: $($_.Exception.Message)"
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                               Archive Tier Section                                         #
                                        #---------------------------------------------------------------------------------------------#
                                        foreach ($ArchiveExtent in $BackupRepo.ArchiveExtent) {
                                            try {
                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "Archive Tier" {
                                                    $OutObj = @()
                                                    Write-PscriboMessage "Discovered $(($ArchiveExtent.Repository).Name) Archive Tier."
                                                    $inObj = [ordered] @{
                                                        'Name' = ($ArchiveExtent.Repository).Name
                                                        'Type' =  ($ArchiveExtent.Repository).ArchiveType
                                                        'Use Gateway Server' = ConvertTo-TextYN ($ArchiveExtent.Repository).UseGatewayServer
                                                        'Gateway Server' = Switch ((($ArchiveExtent.Repository).GatewayServer.Name).length) {
                                                            0 {"Auto"}
                                                            default {($ArchiveExtent.Repository).GatewayServer.Name}
                                                        }
                                                        'Immutability Enabled' = ConvertTo-TextYN $ArchiveExtent.Repository.BackupImmutabilityEnabled
                                                    }
                                                    if (($ArchiveExtent.Repository).ArchiveType -eq 'AzureArchive') {
                                                        $inObj.add('Azure Service Type', ($ArchiveExtent.Repository.AzureBlobFolder).ServiceType)
                                                        $inObj.add('Azure Blob Name', ($ArchiveExtent.Repository.AzureBlobFolder).Name)
                                                        $inObj.add('Azure Blob Container', ($ArchiveExtent.Repository.AzureBlobFolder).Container)
                                                    }

                                                    $OutObj += [pscustomobject]$inobj

                                                    if ($HealthCheck.Infrastructure.SOBR) {
                                                        $OutObj | Where-Object { $_.'Immutability Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Immutability Enabled'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Archive Tier - $(($ArchiveExtent.Repository).Name)"
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
                                                Write-PscriboMessage -IsWarning "ScaleOut Backup Repository Archive Tier Table: $($_.Exception.Message)"
                                            }
                                        }

                                    }
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "ScaleOut Backup Repository Configuration Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "ScaleOut Backup Repository Document: $($_.Exception.Message)"
        }
    }
    end {}

}