function Get-AbrVbrCloudConnectBS {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Backup Storage
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.0
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Backup Storage information from $System."
    }

    process {
        try {
            if (Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -in @("Enterprise")}) {
                if (((Get-VBRCloudTenant).Resources.Repository).count -gt 0) {
                    $CloudObjects = (Get-VBRCloudTenant).Resources
                    Section -Style Heading3 'Backup Storage' {
                        Paragraph "The following section provides information about Veeam Cloud Connect configured Backup Storage."
                        BlankLine
                        foreach ($CloudObject in ($CloudObjects.Repository | Sort-Object -Property Name -Unique)) {
                            try {
                                $PercentFree = 0
                                if (@($($CloudObject.GetContainer().CachedTotalSpace.InGigabytes),$($CloudObject.GetContainer().CachedFreeSpace.InGigabytes)) -ne 0) {
                                    $UsedSpace = ($($CloudObject.GetContainer().CachedTotalSpace.InGigabytes-$($CloudObject.GetContainer().CachedFreeSpace.InGigabytes)))
                                    if ($UsedSpace -ne 0) {
                                        $PercentFree = $([Math]::Round($UsedSpace/$($CloudObject.GetContainer().CachedTotalSpace.InGigabytes) * 100))
                                    }
                                }
                                Section -Style Heading4 $CloudObject.Name {
                                    $OutObj = @()
                                    try {
                                        Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Backup Storage information."

                                        $inObj = [ordered] @{
                                            'Type' = $CloudObject.TypeDisplay
                                            'Path' = Switch ([string]::IsNullOrEmpty($CloudObject.FriendlyPath)) {
                                                $true {'-'}
                                                $false {$CloudObject.FriendlyPath}
                                                default {'Unknown'}
                                            }
                                            'Total Space' = "$($CloudObject.GetContainer().CachedTotalSpace.InGigabytes) GB"
                                            'Free Space' = "$($CloudObject.GetContainer().CachedFreeSpace.InGigabytes) GB"
                                            'Used Space %' = $PercentFree
                                            'Status' = Switch ($CloudObject.IsUnavailable) {
                                                'False' {'Available'}
                                                'True' {'Unavailable'}
                                                default {$CloudObject.IsUnavailable}
                                            }
                                            'Description' = $CloudObject.Description
                                        }

                                        $OutObj = [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Backup Storage - $($CloudObject.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        try {
                                            $CloutTenant = Get-VBRCloudTenant
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 'Tenant Utilization' {
                                                $OutObj = @()
                                                try {
                                                    foreach ($Tenant in ($CloutTenant | Where-Object {$_.Resources.Repository.Name -eq $CloudObject.Name})) {
                                                        Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Tenant utilization."
                                                        foreach ($Storage in ($Tenant.Resources | Where-Object {$_.Repository.Name -eq $CloudObject.Name})) {
                                                            $inObj = [ordered] @{
                                                                'Name' = $Tenant.Name
                                                                'Quota' = "$([math]::Round($Storage.RepositoryQuota / 1Kb, 2)) GB"
                                                                'Used Space' = Switch ([string]::IsNullOrEmpty($Storage.UsedSpace)) {
                                                                    $true {'-'}
                                                                    $false {"$(Convert-Size -From MB -To GB -Value $Storage.UsedSpace) GB"}
                                                                    default {'Unknown'}
                                                                }
                                                                'Used Space %' = $Storage.UsedSpacePercentage
                                                                'Path' = Switch ([string]::IsNullOrEmpty($Storage.RepositoryQuotaPath)) {
                                                                    $true {'-'}
                                                                    $false {$Storage.RepositoryQuotaPath}
                                                                    default {'Unknown'}
                                                                }
                                                            }

                                                            $OutObj += [pscustomobject]$inobj
                                                        }
                                                    }

                                                    if ($HealthCheck.CloudConnect.BackupStorage) {
                                                        $OutObj | Where-Object { $_.'Used Space %' -gt 85} | Set-Style -Style Warning -Property 'Used Space %'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Tenant Utilization - $($CloudObject.Name)"
                                                        List = $false
                                                        ColumnWidths = 28, 15, 15, 15, 27
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning "Tenant Utilization - $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Tenant Utilization Section: $($_.Exception.Message)"
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "Tenant Utilization Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "$($CloudObject.Name) Cloud Backup Storage Section: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Cloud Backup Storage Section: $($_.Exception.Message)"
        }
    }
    end {}

}