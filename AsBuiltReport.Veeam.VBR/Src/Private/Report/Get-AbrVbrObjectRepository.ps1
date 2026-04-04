
function Get-AbrVbrObjectRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Object Storage Repository Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.24
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
        Write-PScriboMessage "Discovering Veeam V&R Object Storage Repository information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrObjectRepository
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Object Storage Repository'
    }

    process {
        try {
            if ($ObjectRepos = Get-VBRObjectStorageRepository | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($ObjectRepo in $ObjectRepos) {
                        if ($Null -ne $ObjectRepo.ConnectionType) {
                            try {

                                $inObj = [ordered] @{
                                    $LocalizedData.Name = $ObjectRepo.Name
                                    $LocalizedData.Type = $ObjectRepo.Type
                                    $LocalizedData.ConnectionType = $ObjectRepo.ConnectionType
                                    $LocalizedData.GatewayServer = switch ($ObjectRepo.ConnectionType) {
                                        'Direct' { $LocalizedData.DirectMode }
                                        'Gateway' { $ObjectRepo.GatewayServer.Name }
                                        default { $LocalizedData.Unknown }
                                    }
                                }

                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Preferred Networks $($ObjectRepo.Name) Section: $($_.Exception.Message)"
                            }
                        } else {
                            try {

                                $inObj = [ordered] @{
                                    $LocalizedData.Name = $ObjectRepo.Name
                                    $LocalizedData.Type = $ObjectRepo.Type
                                    $LocalizedData.UseGatewayServer = $ObjectRepo.UseGatewayServer
                                    $LocalizedData.GatewayServer = switch ($ObjectRepo.GatewayServer.Name) {
                                        '' { $LocalizedData.Dash; break }
                                        $Null { $LocalizedData.Dash; break }
                                        default { $ObjectRepo.GatewayServer.Name.split('.')[0] }
                                    }
                                }

                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Preferred Networks $($ObjectRepo.Name) Section: $($_.Exception.Message)"
                            }
                        }
                    }



                    if ($HealthCheck.Infrastructure.BR) {
                        $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property ($LocalizedData.Status)
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
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
                            if ($ObjectRepos) {
                                Section -Style Heading4 $LocalizedData.ConfigHeading {
                                    Paragraph $LocalizedData.ConfigParagraph
                                    BlankLine
                                    foreach ($ObjectRepo in $ObjectRepos) {
                                        try {
                                            Section -Style NOTOCHeading4 -ExcludeFromTOC "$($ObjectRepo.Name)" {
                                                $OutObj = @()

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = ($ObjectRepo).Name
                                                    $LocalizedData.ServicePoint = ($ObjectRepo).ServicePoint
                                                    $LocalizedData.Type = ($ObjectRepo).Type
                                                    $LocalizedData.AmazonS3Folder = ($ObjectRepo).AmazonS3Folder
                                                    $LocalizedData.ImmutabilityPeriod = $ObjectRepo.ImmutabilityPeriod
                                                    $LocalizedData.ImmutabilityEnabled = $ObjectRepo.BackupImmutabilityEnabled
                                                    $LocalizedData.SizeLimitEnabled = ($ObjectRepo).SizeLimitEnabled
                                                    $LocalizedData.SizeLimit = ($ObjectRepo).SizeLimit

                                                }

                                                if ($Null -ne ($ObjectRepo).UseGatewayServer) {
                                                    $inObj.add($LocalizedData.UseGatewayServer, ($ObjectRepo.UseGatewayServer))
                                                    $inObj.add($LocalizedData.GatewayServer, $ObjectRepo.GatewayServer.Name)
                                                }
                                                if ($Null -ne $ObjectRepo.ConnectionType) {
                                                    $inObj.add($LocalizedData.ConnectionType, $ObjectRepo.ConnectionType)
                                                }
                                                if (($ObjectRepo).ConnectionType -eq 'Gateway') {
                                                    $inObj.add($LocalizedData.GatewayServer, $ObjectRepo.GatewayServer.Name)
                                                }
                                                if (($ObjectRepo).Type -eq 'AmazonS3') {
                                                    $inObj.remove($LocalizedData.ServicePoint)
                                                    $inObj.add($LocalizedData.UseIAStorageClass, (($ObjectRepo).EnableIAStorageClass))
                                                    $inObj.add($LocalizedData.UseOZIAStorageClass, (($ObjectRepo).EnableOZIAStorageClass))
                                                } elseif (($ObjectRepo).Type -eq 'AzureBlob') {
                                                    $inObj.remove($LocalizedData.ServicePoint)
                                                    $inObj.remove($LocalizedData.AmazonS3Folder)
                                                    $inObj.remove($LocalizedData.ImmutabilityPeriod)
                                                    $inObj.remove($LocalizedData.ImmutabilityEnabled)
                                                    $inObj.add($LocalizedData.AzureBlobName, ($ObjectRepo.AzureBlobFolder).Name)
                                                    $inObj.add($LocalizedData.AzureBlobContainer, ($ObjectRepo.AzureBlobFolder).Container)
                                                } elseif (($ObjectRepo).Type -eq 'GoogleCloudStorage') {
                                                    $inObj.remove($LocalizedData.ServicePoint)
                                                    $inObj.remove($LocalizedData.AmazonS3Folder)
                                                    $inObj.remove($LocalizedData.ImmutabilityPeriod)
                                                    $inObj.add($LocalizedData.FolderName, $ObjectRepo.Folder)
                                                    $inObj.add($LocalizedData.EnableNearlineStorageClass, $ObjectRepo.EnableNearlineStorageClass)
                                                    $inObj.add($LocalizedData.EnableColdlineStorageClass, $ObjectRepo.EnableColdlineStorageClass)
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                if ($HealthCheck.Infrastructure.BR) {
                                                    $OutObj | Where-Object { $_."$($LocalizedData.ImmutabilityEnabled)" -eq $LocalizedData.No } | Set-Style -Style Warning -Property $LocalizedData.ImmutabilityEnabled
                                                }

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.TableHeading) - $($ObjectRepo.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                                if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_."$($LocalizedData.ImmutabilityEnabled)" -eq $LocalizedData.No })) {
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
                                            Write-PScriboMessage -IsWarning "Object Storage Repository Configuration $($ObjectRepo.Name) Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Object Storage Repository Configuration Section: $($_.Exception.Message)"
                        }
                    }
                }
                #---------------------------------------------------------------------------------------------#
                #                            Archive Object Storage Repository Section                        #
                #---------------------------------------------------------------------------------------------#
                try {
                    if ($ObjectRepoArchives = Get-VBRArchiveObjectStorageRepository | Sort-Object -Property Name) {
                        Section -Style Heading3 $LocalizedData.ArchiveHeading {
                            Paragraph $LocalizedData.ArchiveParagraph
                            BlankLine
                            foreach ($ObjectRepoArchive in $ObjectRepoArchives) {
                                try {
                                    Section -Style NOTOCHeading4 -ExcludeFromTOC "$($ObjectRepoArchive.Name)" {
                                        $OutObj = @()

                                        $inObj = [ordered] @{
                                            $LocalizedData.GatewayServer = switch ($ObjectRepoArchive.GatewayServer.Name) {
                                                '' { $LocalizedData.AutoSelected; break }
                                                $Null { $LocalizedData.AutoSelected; break }
                                                default { $ObjectRepoArchive.GatewayServer.Name.split('.')[0] }
                                            }
                                            $LocalizedData.GatewayServerEnabled = $ObjectRepoArchive.UseGatewayServer
                                            $LocalizedData.ImmutabilityEnabled = $ObjectRepoArchive.BackupImmutabilityEnabled
                                            $LocalizedData.ArchiveType = $ObjectRepoArchive.ArchiveType
                                        }
                                        if ($ObjectRepoArchive.ArchiveType -eq 'AmazonS3Glacier') {
                                            $inObj.add($LocalizedData.DeepArchive, ($ObjectRepoArchive.UseDeepArchive))
                                            $inObj.add($LocalizedData.ProxyInstanceType, $ObjectRepoArchive.AmazonProxySpec.InstanceType)
                                            $inObj.add($LocalizedData.ProxyInstancevCPU, $ObjectRepoArchive.AmazonProxySpec.InstanceType.vCPUs)
                                            $inObj.add($LocalizedData.ProxyInstanceMemory, ([Math]::Round($ObjectRepoArchive.AmazonProxySpec.InstanceType.Memory * 1MB / 1GB)))
                                            $inObj.add($LocalizedData.ProxySubnet, $ObjectRepoArchive.AmazonProxySpec.Subnet)
                                            $inObj.add($LocalizedData.ProxySecurityGroup, $ObjectRepoArchive.AmazonProxySpec.SecurityGroup)
                                            $inObj.add($LocalizedData.ProxyAvailabilityZone, $ObjectRepoArchive.AmazonProxySpec.Subnet.AvailabilityZone)


                                        } elseif ($ObjectRepoArchive.ArchiveType -eq 'AzureArchive') {
                                            $inObj.add($LocalizedData.ServiceType, $ObjectRepoArchive.AzureBlobFolder.ServiceType)
                                            $inObj.add($LocalizedData.ArchiveContainer, $ObjectRepoArchive.AzureBlobFolder.Container)
                                            $inObj.add($LocalizedData.ArchiveFolder, $ObjectRepoArchive.AzureBlobFolder.Name)
                                            $inObj.add($LocalizedData.ProxyResourceGroup, $ObjectRepoArchive.AzureProxySpec.ResourceGroup)
                                            $inObj.add($LocalizedData.ProxyNetwork, $ObjectRepoArchive.AzureProxySpec.Network)
                                            $inObj.add($LocalizedData.ProxyVMSize, $ObjectRepoArchive.AzureProxySpec.VMSize)
                                            $inObj.add($LocalizedData.ProxyVMvCPU, $ObjectRepoArchive.AzureProxySpec.VMSize.Cores)
                                            $inObj.add($LocalizedData.ProxyVMMemory, ([Math]::Round($ObjectRepoArchive.AzureProxySpec.VMSize.Memory * 1MB / 1GB)))
                                            $inObj.add($LocalizedData.ProxyVMMaxDisks, $ObjectRepoArchive.AzureProxySpec.VMSize.MaxDisks)
                                            $inObj.add($LocalizedData.ProxyVMLocation, $ObjectRepoArchive.AzureProxySpec.VMSize.Location)
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Infrastructure.BR) {
                                            $OutObj | Where-Object { $_."$($LocalizedData.ImmutabilityEnabled)" -eq $LocalizedData.No } | Set-Style -Style Warning -Property $LocalizedData.ImmutabilityEnabled
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.ArchiveTableHeading) - $($ObjectRepoArchive.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        if (($HealthCheck.Infrastructure.BestPractice) -and ($OutObj | Where-Object { $_."$($LocalizedData.ImmutabilityEnabled)" -eq $LocalizedData.No })) {
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
                                    Write-PScriboMessage -IsWarning "Archive Object Storage Repository $($ObjectRepoArchive.Name) Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Archive Object Storage Repository Section: $($_.Exception.Message)"
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Object Storage Repository Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Object Storage Repository'
    }

}