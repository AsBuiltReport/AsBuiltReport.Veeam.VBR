
function Get-AbrVbrObjectRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Object Storage Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.0
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
                    $ObjectRepos = Get-VBRObjectStorageRepository
                    foreach ($ObjectRepo in $ObjectRepos) {
                        if ($Null -ne $ObjectRepo.ConnectionType) {
                            try {
                                Write-PscriboMessage "Discovered $($ObjectRepo.Name) Repository."
                                $inObj = [ordered] @{
                                    'Name' = $ObjectRepo.Name
                                    'Type' = $ObjectRepo.Type
                                    'Connection Type' = $ObjectRepo.ConnectionType
                                    'Gateway Server' = Switch ($ObjectRepo.ConnectionType) {
                                        'Direct' {'Direct Mode'}
                                        'Gateway' {$ObjectRepo.GatewayServer.Name}
                                        default {'Unknown'}
                                    }
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Preferred Networks $($ObjectRepo.Name) Section: $($_.Exception.Message)"
                            }
                        } else {
                            try {
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
                            catch {
                                Write-PscriboMessage -IsWarning "Preferred Networks $($ObjectRepo.Name) Section: $($_.Exception.Message)"
                            }
                        }
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
                                                    'Immutability Period' = $ObjectRepo.ImmutabilityPeriod
                                                    'Immutability Enabled'= ConvertTo-TextYN $ObjectRepo.BackupImmutabilityEnabled
                                                    'Size Limit Enabled' = ConvertTo-TextYN ($ObjectRepo).SizeLimitEnabled
                                                    'Size Limit' = ($ObjectRepo).SizeLimit

                                                }

                                                if ($Null -ne ($ObjectRepo).UseGatewayServer) {
                                                    $inObj.add('Use Gateway Server', (ConvertTo-TextYN $ObjectRepo.UseGatewayServer))
                                                    $inObj.add('Gateway Server', $ObjectRepo.GatewayServer.Name)
                                                }
                                                if ($Null -ne $ObjectRepo.ConnectionType) {
                                                    $inObj.add('Connection Type', $ObjectRepo.ConnectionType)
                                                }
                                                if (($ObjectRepo).ConnectionType -eq 'Gateway') {
                                                    $inObj.add('Gateway Server', $ObjectRepo.GatewayServer.Name)
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

                                                if ($HealthCheck.Infrastructure.BR) {
                                                    $OutObj | Where-Object { $_.'Immutability Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Immutability Enabled'
                                                }

                                                $TableParams = @{
                                                    Name = "Object Storage Repository - $($ObjectRepo.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                                if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_.'Immutability Enabled' -eq 'No' })) {
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
                                            Write-PscriboMessage -IsWarning "Object Storage Repository Configuration $($ObjectRepo.Name) Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Object Storage Repository Configuration Section: $($_.Exception.Message)"
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
                                            'Immutability Enabled' = ConvertTo-TextYN $ObjectRepoArchive.BackupImmutabilityEnabled
                                            'Archive Type' = $ObjectRepoArchive.ArchiveType
                                        }
                                        if ($ObjectRepoArchive.ArchiveType -eq 'AmazonS3Glacier') {
                                            $inObj.add('Deep Archive', (ConvertTo-TextYN $ObjectRepoArchive.UseDeepArchive))
                                            $inObj.add('Proxy Instance Type', $ObjectRepoArchive.AmazonProxySpec.InstanceType)
                                            $inObj.add('Proxy Instance vCPU', $ObjectRepoArchive.AmazonProxySpec.InstanceType.vCPUs)
                                            $inObj.add('Proxy Instance Memory', ([Math]::Round($ObjectRepoArchive.AmazonProxySpec.InstanceType.Memory*1MB/1GB)))
                                            $inObj.add('Proxy Subnet', $ObjectRepoArchive.AmazonProxySpec.Subnet)
                                            $inObj.add('Proxy Security Group', $ObjectRepoArchive.AmazonProxySpec.SecurityGroup)
                                            $inObj.add('Proxy Availability Zone', $ObjectRepoArchive.AmazonProxySpec.Subnet.AvailabilityZone)


                                        } elseif ($ObjectRepoArchive.ArchiveType -eq 'AzureArchive') {
                                            $inObj.add('Service Type', $ObjectRepoArchive.AzureBlobFolder.ServiceType)
                                            $inObj.add('Archive Container', $ObjectRepoArchive.AzureBlobFolder.Container)
                                            $inObj.add('Archive Folder', $ObjectRepoArchive.AzureBlobFolder.Name)
                                            $inObj.add('Proxy Resource Group', $ObjectRepoArchive.AzureProxySpec.ResourceGroup)
                                            $inObj.add('Proxy Network', $ObjectRepoArchive.AzureProxySpec.Network)
                                            $inObj.add('Proxy VM Size', $ObjectRepoArchive.AzureProxySpec.VMSize)
                                            $inObj.add('Proxy VM vCPU', $ObjectRepoArchive.AzureProxySpec.VMSize.Cores)
                                            $inObj.add('Proxy VM Memory', ([Math]::Round($ObjectRepoArchive.AzureProxySpec.VMSize.Memory*1MB/1GB)))
                                            $inObj.add('Proxy VM Max Disks', $ObjectRepoArchive.AzureProxySpec.VMSize.MaxDisks)
                                            $inObj.add('Proxy VM Location', $ObjectRepoArchive.AzureProxySpec.VMSize.Location)
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        if ($HealthCheck.Infrastructure.BR) {
                                            $OutObj | Where-Object { $_.'Immutability Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Immutability Enabled'
                                        }

                                        $TableParams = @{
                                            Name = "Archive Object Storage Repository - $($ObjectRepoArchive.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_.'Immutability Enabled' -eq 'No'})) {
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
                                    Write-PscriboMessage -IsWarning "Archive Object Storage Repository $($ObjectRepoArchive.Name) Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "Archive Object Storage Repository Section: $($_.Exception.Message)"
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Object Storage Repository Section: $($_.Exception.Message)"
        }
    }
    end {}

}