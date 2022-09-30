
function Get-AbrVbrObjectRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Object Storage Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.5
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
        Write-PscriboMessage "Discovering Veeam V&R Object Storage Repository information from $System."
    }

    process {
        try {
            if ((Get-VBRObjectStorageRepository).count -gt 0) {
                Section -Style Heading3 'Object Storage Repository' {
                    Paragraph "The following section provides a summary about the Veeam Object Storage Repository."
                    BlankLine
                    $OutObj = @()
                    try {
                        $ObjectRepos = Get-VBRObjectStorageRepository
                        foreach ($ObjectRepo in $ObjectRepos) {
                            Write-PscriboMessage "Discovered $($ObjectRepo.Name) Repository."
                            $inObj = [ordered] @{
                                'Name' = $ObjectRepo.Name
                                'Type' = $ObjectRepo.Type
                                'Use Gateway Server' = ConvertTo-TextYN $ObjectRepo.UseGatewayServer
                                'Gateway Server' = Switch ($ObjectRepo.GatewayServer.Name) {
                                    "" {"-"; break}
                                    $Null {"-"; break}
                                    default {$ObjectRepo.GatewayServer.Name.split(".")[0]}
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
                        Name = "Object Storage Repository - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 25, 15, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    #---------------------------------------------------------------------------------------------#
                    #                        Per Object Storage Repository Configuration Section                  #
                    #---------------------------------------------------------------------------------------------#
                    if ($InfoLevel.Infrastructure.BR -ge 2) {
                        try {
                            if ((Get-VBRObjectStorageRepository).count -gt 0) {
                                Section -Style Heading4 "Object Storage Repository Configuration" {
                                    Paragraph "The following section provides detailed information about Object Storage Backup Repository"
                                    BlankLine
                                    $ObjectRepos = Get-VBRObjectStorageRepository | Sort-Object -Property Name
                                    foreach ($ObjectRepo in $ObjectRepos) {
                                        try {
                                            Section -Style NOTOCHeading4 -ExcludeFromTOC "$($ObjectRepo.Name)" {
                                                $OutObj = @()
                                                Write-PscriboMessage "Discovered $($ObjectRepo.Name) Object Backup Repository."
                                                $inObj = [ordered] @{
                                                    'Name' = ($ObjectRepo).Name
                                                    'Service Point' = ($ObjectRepo).ServicePoint
                                                    'Type' =  ($ObjectRepo).Type
                                                    'Amazon S3 Folder' =  ($ObjectRepo).AmazonS3Folder
                                                    'Use Gateway Server' = ConvertTo-TextYN ($ObjectRepo).UseGatewayServer
                                                    'Gateway Server' = Switch ((($ObjectRepo).GatewayServer.Name).length) {
                                                        0 {"Auto"}
                                                        default {($ObjectRepo).GatewayServer.Name}
                                                    }
                                                    'Immutability Period' = $ObjectRepo.ImmutabilityPeriod
                                                    'Size Limit Enabled' = ConvertTo-TextYN ($ObjectRepo).SizeLimitEnabled
                                                    'Size Limit' = ($ObjectRepo).SizeLimit
                                                }
                                                if (($ObjectRepo).Type -eq 'AmazonS3') {
                                                    $inObj.remove('Service Point')
                                                    $inObj.add('Use IA Storage Class', (ConvertTo-TextYN ($ObjectRepo).EnableIAStorageClass))
                                                    $inObj.add('Use OZ IA Storage Class', (ConvertTo-TextYN ($ObjectRepo).EnableOZIAStorageClass))
                                                } elseif (($ObjectRepo).Type -eq 'AzureBlob') {
                                                    $inObj.remove('Service Point')
                                                    $inObj.remove('Amazon S3 Folder')
                                                    $inObj.remove('Immutability Period')
                                                    $inObj.add('Azure Blob Name', ($ObjectRepo.AzureBlobFolder).Name)
                                                    $inObj.add('Azure Blob Container', ($ObjectRepo.AzureBlobFolder).Container)
                                                }
                                                $OutObj = [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Object Storage Repository - $($ObjectRepo.Name)"
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
                #---------------------------------------------------------------------------------------------#
                #                            Archive Object Storage Repository Section                        #
                #---------------------------------------------------------------------------------------------#
                try {
                    if ((Get-VBRArchiveObjectStorageRepository).count -gt 0) {
                        Section -Style Heading3 "Archive Object Storage Repository" {
                            Paragraph "The following section provides detailed information about Archive Object Storage Backup Repository"
                            BlankLine
                            $ObjectRepoArchives = Get-VBRArchiveObjectStorageRepository | Sort-Object -Property Name
                            foreach ($ObjectRepoArchive in $ObjectRepoArchives) {
                                try {
                                    Section -Style NOTOCHeading4 -ExcludeFromTOC "$($ObjectRepoArchive.Name)" {
                                        $OutObj = @()
                                        Write-PscriboMessage "Discovered $($ObjectRepoArchive.Name) Backup Repository."
                                        $inObj = [ordered] @{
                                            'Gateway Server' = Switch ($ObjectRepoArchive.GatewayServer.Name) {
                                                "" {"Auto Selected"; break}
                                                $Null {"Auto Selected"; break}
                                                default {$ObjectRepoArchive.GatewayServer.Name.split(".")[0]}
                                            }
                                            'Gateway Server Enabled' = ConvertTo-TextYN $ObjectRepoArchive.UseGatewayServer
                                            'Archive Type' = $ObjectRepoArchive.ArchiveType
                                        }
                                        if ($ObjectRepoArchive.ArchiveType -eq 'AmazonS3Glacier') {
                                            $inObj.add('AWS Deep Archive', (ConvertTo-TextYN $ObjectRepoArchive.UseDeepArchive))
                                            $inObj.add('AWS Backup Immutability', (ConvertTo-TextYN ($ObjectRepoArchive.BackupImmutabilityEnabled)))
                                            $inObj.add('AWS Proxy Instance Type', $ObjectRepoArchive.AmazonProxySpec.InstanceType)
                                            $inObj.add('AWS Proxy Instance vCPU', $ObjectRepoArchive.AmazonProxySpec.InstanceType.vCPUs)
                                            $inObj.add('AWS Proxy Instance Memory', ([Math]::Round($ObjectRepoArchive.AmazonProxySpec.InstanceType.Memory*1MB/1GB)))
                                            $inObj.add('AWS Proxy Subnet', $ObjectRepoArchive.AmazonProxySpec.Subnet)
                                            $inObj.add('AWS Proxy Security Group', $ObjectRepoArchive.AmazonProxySpec.SecurityGroup)
                                            $inObj.add('AWS Proxy Availability Zone', $ObjectRepoArchive.AmazonProxySpec.Subnet.AvailabilityZone)


                                        } elseif ($ObjectRepoArchive.ArchiveType -eq 'AzureArchive') {
                                            $inObj.add('Azure Service Type', $ObjectRepoArchive.AzureBlobFolder.ServiceType)
                                            $inObj.add('Azure Archive Container', $ObjectRepoArchive.AzureBlobFolder.Container)
                                            $inObj.add('Azure Archive Folder', $ObjectRepoArchive.AzureBlobFolder.Name)
                                            $inObj.add('Azure Proxy Resource Group', $ObjectRepoArchive.AzureProxySpec.ResourceGroup)
                                            $inObj.add('Azure Proxy Network', $ObjectRepoArchive.AzureProxySpec.Network)
                                            $inObj.add('Azure Proxy VM Size', $ObjectRepoArchive.AzureProxySpec.VMSize)
                                            $inObj.add('Azure Proxy VM vCPU', $ObjectRepoArchive.AzureProxySpec.VMSize.Cores)
                                            $inObj.add('Azure Proxy VM Memory', ([Math]::Round($ObjectRepoArchive.AzureProxySpec.VMSize.Memory*1MB/1GB)))
                                            $inObj.add('Azure Proxy VM Max Disks', $ObjectRepoArchive.AzureProxySpec.VMSize.MaxDisks)
                                            $inObj.add('Azure Proxy VM Location', $ObjectRepoArchive.AzureProxySpec.VMSize.Location)
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Archive Object Storage Repository - $($ObjectRepoArchive.Name)"
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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}