
function Get-AbrVbrScaleOutRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR ScaleOut Backup Repository Information
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
        Write-PscriboMessage "Discovering Veeam V&R ScaleOut Backup Repository information from $System."
    }

    process {
        Section -Style Heading3 'ScaleOut Backup Repository' {
            Paragraph "The following section provides a summary of the ScaleOut Backup Repository"
            BlankLine
            $OutObj = @()
            try {
                $BackupRepos = Get-VBRBackupRepository -ScaleOut
                foreach ($BackupRepo in $BackupRepos) {
                    Write-PscriboMessage "Discovered $($BackupRepo.Name) Repository."
                    $inObj = [ordered] @{
                        'Name' = $BackupRepo.Name
                        'Extent' = $BackupRepo.Extent
                        'Extent Status' = ($BackupRepo.Extent).Status | Sort-Object -Unique
                        'Enabled Capacity Tier' = ConvertTo-TextYN $BackupRepo.EnableCapacityTier
                        'Capacity Extent' = $BackupRepo.CapacityExtent
                        'Capacity Extent Status' = ($BackupRepo.CapacityExtent).Status | Sort-Object -Unique
                    }
                    $OutObj += [pscustomobject]$inobj
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }

            $TableParams = @{
                Name = "Scale Backup Repository Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                List = $false
                ColumnWidths = 20, 17, 16, 15, 17, 15
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
            try {
                $BackupRepos = Get-VBRBackupRepository -ScaleOut
                foreach ($BackupRepo in $BackupRepos) {
                    Section -Style Heading4 "$($BackupRepo.Name) SOBR Repository" {
                        Paragraph "The following section provides a detailed information of the ScaleOut Backup Repository"
                        BlankLine
                        foreach ($Extent in $BackupRepo.Extent) {
                            try {
                                Section -Style Heading5 "$($Extent.Name) Performance Tier" {
                                    Paragraph "The following section provides a detailed information of the Performance Tier"
                                    BlankLine
                                    $OutObj = @()
                                    Write-PscriboMessage "Discovered $($Extent.Name) Performance Tier."
                                    $inObj = [ordered] @{
                                        'Name' = $Extent.Name
                                        'Repository' = ($Extent.Repository).Name
                                        'Status' = $Extent.Status
                                        'Total Space' = "$((($BackupRepo.Extent).Repository).GetContainer().CachedTotalSpace.InGigabytes) GB"
                                        'Used Space' = "$((($BackupRepo.Extent).Repository).GetContainer().CachedFreeSpace.InGigabytes) GB"
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                    $TableParams = @{
                                        Name = "$($Extent.Name) Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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
                        foreach ($CapacityExtent in $BackupRepo.CapacityExtent) {
                            try {
                                Section -Style Heading5 "$(($CapacityExtent.Repository).Name) Capacity Tier" {
                                    Paragraph "The following section provides a detailed information of the Capacity Tier"
                                    BlankLine
                                    $OutObj = @()
                                    Write-PscriboMessage "Discovered $(($CapacityExtent.Repository).Name) Capacity Tier."
                                    $inObj = [ordered] @{
                                        'Name' = ($CapacityExtent.Repository).Name
                                        'Service Point' = ($CapacityExtent.Repository).ServicePoint
                                        'Type' =  ($CapacityExtent.Repository).Type
                                        'Amazon S3 Folder' =  ($CapacityExtent.Repository).AmazonS3Folder
                                        'Use Gateway Server' = ConvertTo-TextYN ($CapacityExtent.Repository).UseGatewayServer
                                        'Gateway Server' = ($CapacityExtent.Repository).GatewayServer.Name
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
                                        Name = "$($CapacityExtent.Repository) Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
        }
    }
    end {}

}