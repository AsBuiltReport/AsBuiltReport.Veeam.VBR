
function Get-AbrVbrServiceProvider {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Service Providers
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Service Providers information from $System."
    }

    process {
        try {
            if ((Get-VBRInstalledLicense | Where-Object {$_.Edition -in @("EnterprisePlus")}) -and (Get-VBRCloudProvider).count -gt 0) {
                Section -Style Heading3 'Cloud Service Providers' {
                    Paragraph "The following section provides a summary about configured Veeam Cloud Connect Service Providers."
                    BlankLine
                    try {
                        $CloudProviders = Get-VBRCloudProvider
                        $OutObj = @()
                        foreach ($CloudProvider in $CloudProviders) {
                            try {
                                Write-PscriboMessage "Discovered $($CloudProvider.DNSName) Service Provider."
                                if ($CloudProvider.ResourcesEnabled) {
                                    $WanAcceleration = $CloudProvider.Resources.WanAccelerationEnabled
                                }
                                elseif ($CloudProvider.ReplicationResourcesEnabled) {
                                    $WanAcceleration = $CloudProvider.ReplicationResources.WanAcceleratorEnabled
                                }

                                if ($CloudProvider.ResourcesEnabled) {
                                    $VCCType = 'Cloud Repositories'
                                }
                                elseif ($CloudProvider.ReplicationResourcesEnabled) {
                                    $VCCType = 'Replication Resources'
                                }

                                $inObj = [ordered] @{
                                    'DNS Name' = $CloudProvider.DNSName
                                    'Cloud Connect Type' = $VCCType
                                    'Wan Acceleration' = ConvertTo-TextYN $WanAcceleration
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Cloud Service Providers - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 35, 35, 30
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($InfoLevel.Infrastructure.ServiceProvider -ge 2) {
                            try {
                                foreach ($CloudProvider in $CloudProviders) {
                                    Section -Style Heading3 $CloudProvider.DNSName {
                                        $OutObj = @()
                                        Write-PscriboMessage "Discovered $($CloudProvider.DNSName) Service Provider."
                                        $inObj = [ordered] @{
                                            'DNS Name' = $CloudProvider.DNSName
                                            'Ip Address' = $CloudProvider.IpAddress
                                            'Port' = $CloudProvider.Port
                                            'Credentials' = $CloudProvider.Credentials
                                            'Certificate Expiration Date' = $CloudProvider.Certificate.NotAfter
                                            'Managed By Service Provider' = ConvertTo-TextYN $CloudProvider.IsManagedByProvider
                                        }
                                        if ($CloudProvider.ResourcesEnabled) {
                                            $inObj.add('BaaS Resources Enabled', (ConvertTo-TextYN $CloudProvider.ResourcesEnabled))
                                            $inObj.add('Repository Name', $CloudProvider.Resources.RepositoryName)
                                            $inObj.add('Allocated Resources', "$([Math]::Round($CloudProvider.Resources.RepositoryAllocatedSpace / 1024))GB")
                                            $inObj.add('Description', $CloudProvider.Description)
                                        }

                                        if ($CloudProvider.ReplicationResourcesEnabled) {
                                            $inObj.add('DRaaS Replication Enabled', (ConvertTo-TextYN $CloudProvider.ReplicationResourcesEnabled))
                                            $inObj.add('Hardware Plan Name', $CloudProvider.ReplicationResources.HardwarePlanName)
                                            $inObj.add('Allocated CPU Resources', $CloudProvider.ReplicationResources.CPU)
                                            $inObj.add('Allocated Memory Resources', $CloudProvider.ReplicationResources.Memory)
                                            $inObj.add('Allocated Datastore Resources', "$([Math]::Round($CloudProvider.ReplicationResources.Datastore.DatastoreAllocatedSpace / 1024))GB")
                                            $inObj.add('Network Count', $CloudProvider.ReplicationResources.NetworkCount)
                                            $inObj.add('Public Ip Enabled', (ConvertTo-TextYN $CloudProvider.ReplicationResources.PublicIpEnabled))
                                            # if ($CloudProvider.ReplicationResources.PublicIpEnabled) {
                                            #     $inObj.add('Public Ip', $CloudProvider.ReplicationResources.PublicIp)
                                            # }
                                            $inObj.add('Description', $CloudProvider.Description)
                                        }

                                        $OutObj = [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Cloud Service Providers - $($CloudProvider.DNSName)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
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
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}