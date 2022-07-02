
function Get-AbrVbrScaleOutRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR ScaleOut Backup Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.2
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
                                'Capacity Tier' = $BackupRepo.CapacityExtent.Name
                                'Archive Tier' = $BackupRepo.ArchiveExtent.Name
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }

                    $TableParams = @{
                        Name = "Scale Backup Repository - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 25, 15, 30
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
                                $BackupRepos = Get-VBRBackupRepository -ScaleOut
                                #---------------------------------------------------------------------------------------------#
                                #                                   Per SOBR Section                                          #
                                #---------------------------------------------------------------------------------------------#
                                foreach ($BackupRepo in $BackupRepos) {
                                    Section -Style Heading5 "$($BackupRepo.Name)" {
                                        foreach ($Extent in $BackupRepo.Extent) {
                                            try {
                                                #---------------------------------------------------------------------------------------------#
                                                #                               Performace Tier Section                                       #
                                                #---------------------------------------------------------------------------------------------#
                                                Section -Style Heading6 "Performance Tier" {
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
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                               Capacity Tier Section                                         #
                                        #---------------------------------------------------------------------------------------------#
                                        foreach ($CapacityExtent in $BackupRepo.CapacityExtent) {
                                            try {
                                                Section -Style Heading6 "Capacity Tier" {
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
                                                        $inObj.remove('Immutability Period')
                                                        $inObj.add('Azure Blob Name', ($CapacityExtent.Repository.AzureBlobFolder).Name)
                                                        $inObj.add('Azure Blob Container', ($CapacityExtent.Repository.AzureBlobFolder).Container)
                                                    }

                                                    $OutObj += [pscustomobject]$inobj
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
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                               Archive Tier Section                                         #
                                        #---------------------------------------------------------------------------------------------#
                                        foreach ($ArchiveExtent in $BackupRepo.ArchiveExtent) {
                                            try {
                                                Section -Style Heading6 "Archive Tier" {
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
                                                    }
                                                    if (($ArchiveExtent.Repository).ArchiveType -eq 'AmazonS3Glacier') {
                                                        $inObj.add('Backup Immutability Enabled', (ConvertTo-TextYN ($ArchiveExtent.Repository).BackupImmutabilityEnabled))
                                                    } elseif (($ArchiveExtent.Repository).ArchiveType -eq 'AzureArchive') {
                                                        $inObj.add('Azure Service Type', ($ArchiveExtent.Repository.AzureBlobFolder).ServiceType)
                                                        $inObj.add('Azure Blob Name', ($ArchiveExtent.Repository.AzureBlobFolder).Name)
                                                        $inObj.add('Azure Blob Container', ($ArchiveExtent.Repository.AzureBlobFolder).Container)
                                                    }

                                                    $OutObj += [pscustomobject]$inobj
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
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }

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