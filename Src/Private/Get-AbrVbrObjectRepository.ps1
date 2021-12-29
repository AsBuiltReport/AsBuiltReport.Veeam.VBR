
function Get-AbrVbrObjectRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Object Storage Repository Information
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
        Write-PscriboMessage "Discovering Veeam V&R Object Storage Repository information from $System."
    }

    process {
        Section -Style Heading3 'Object Storage Repository' {
            Paragraph "The following section provides a summary of the Veeam Object Storage Repository."
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $ObjectRepos = Get-VBRObjectStorageRepository
                    foreach ($ObjectRepo in $ObjectRepos) {
                        Write-PscriboMessage "Discovered $($ObjectRepo.Name) Repository."
                        $inObj = [ordered] @{
                            'Name' = $ObjectRepo.Name
                            'Type' = $ObjectRepo.Type
                            'Use Gateway Server' = $ObjectRepo.UseGatewayServer
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
                    Name = "Object Storage Repository Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                    List = $false
                    ColumnWidths = 30, 25, 15, 30
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
            try {
                Section -Style Heading4 "Archive Object Storage Repository" {
                    Paragraph "The following section provides a detailed information of the Archive Object Storage Backup Repository"
                    BlankLine
                    $ObjectRepoArchives = Get-VBRArchiveObjectStorageRepository
                    foreach ($ObjectRepoArchive in $ObjectRepoArchives) {
                        try {
                            Section -Style Heading5 "$($ObjectRepoArchive.Name)" {
                                Paragraph "The following section provides a detailed information of the $($ObjectRepoArchive.Name) Backup Repository"
                                BlankLine
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
                                    $inObj.add('AWS Proxy Instance Memory', $ObjectRepoArchive.AmazonProxySpec.InstanceType.Memory)
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
                                    $inObj.add('Azure Proxy VM Memory', $ObjectRepoArchive.AzureProxySpec.VMSize.Memory)
                                    $inObj.add('Azure Proxy VM Max Disks', $ObjectRepoArchive.AzureProxySpec.VMSize.MaxDisks)
                                    $inObj.add('Azure Proxy VM Location', $ObjectRepoArchive.AzureProxySpec.VMSize.Location)
                                }
                                $OutObj += [pscustomobject]$inobj

                                $TableParams = @{
                                    Name = "Archive Object Storage Repository Information - $($ObjectRepoArchive.Name)"
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
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
        }
    }
    end {}

}