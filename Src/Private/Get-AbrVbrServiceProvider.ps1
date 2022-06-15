
function Get-AbrVbrServiceProvider {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Service Providers
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.1
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
                    Paragraph "The following section provides a summary about configured Veeam Cloud Service Providers."
                    BlankLine
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $CloudProviders = Get-VBRCloudProvider
                            foreach ($CloudProvider in $CloudProviders) {
                                try {
                                    $OutObj = @()
                                    Write-PscriboMessage "Discovered $($CloudProvider.DNSName) Service Provider."
                                    $inObj = [ordered] @{
                                        'DNS Name' = $CloudProvider.DNSName
                                        'Repository Name' = $CloudProvider.Resources.RepositoryName
                                        'Allocated Space' = "$([Math]::Round($CloudProvider.Resources.RepositoryAllocatedSpace / 1024))GB"
                                        'Wan Acceleration' = $CloudProvider.Resources.WanAccelerationEnabled
                                    }
                                    $OutObj = [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "Cloud Service Providers - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                List = $false
                                ColumnWidths = 30, 30, 20, 20
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
                                                'BaaS Resources Enabled' = ConvertTo-TextYN $CloudProvider.ResourcesEnabled
                                                'DRaaS Replication Enabled' = ConvertTo-TextYN $CloudProvider.ReplicationResourcesEnabled
                                                'Managed By Service Provider' = ConvertTo-TextYN $CloudProvider.IsManagedByProvider
                                                'Description' = $CloudProvider.Description
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
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}