function Get-AbrVbrCloudConnectBS {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Backup Storage
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Backup Storage information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCloudConnectBS
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Cloud Backup Storage'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' }) {
                if (((Get-VBRCloudTenant).Resources.Repository).count -gt 0) {
                    $CloudObjects = (Get-VBRCloudTenant).Resources
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        foreach ($CloudObject in ($CloudObjects.Repository | Sort-Object -Property Name -Unique)) {
                            try {
                                $PercentFree = 0
                                if (@($($CloudObject.GetContainer().CachedTotalSpace.InGigabytes), $($CloudObject.GetContainer().CachedFreeSpace.InGigabytes)) -ne 0) {
                                    $UsedSpace = ($($CloudObject.GetContainer().CachedTotalSpace.InGigabytes - $($CloudObject.GetContainer().CachedFreeSpace.InGigabytes)))
                                    if ($UsedSpace -ne 0) {
                                        $PercentFree = $([Math]::Round($UsedSpace / $($CloudObject.GetContainer().CachedTotalSpace.InGigabytes) * 100))
                                    }
                                }
                                Section -Style Heading4 $CloudObject.Name {
                                    $OutObj = @()
                                    try {
                                        $inObj = [ordered] @{
                                            $LocalizedData.Type = $CloudObject.TypeDisplay
                                            $LocalizedData.Path = switch ([string]::IsNullOrEmpty($CloudObject.FriendlyPath)) {
                                                $true { '--' }
                                                $false { $CloudObject.FriendlyPath }
                                                default { $LocalizedData.Unknown }
                                            }
                                            $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CloudObject.GetContainer().CachedTotalSpace.InBytesAsUInt64
                                            $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $CloudObject.GetContainer().CachedFreeSpace.InBytesAsUInt64
                                            $LocalizedData.UsedSpacePct = $PercentFree
                                            $LocalizedData.Status = switch ($CloudObject.IsUnavailable) {
                                                'False' { $LocalizedData.Available }
                                                'True' { $LocalizedData.Unavailable }
                                                default { $CloudObject.IsUnavailable }
                                            }
                                            $LocalizedData.Description = $CloudObject.Description
                                        }

                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeading) - $($CloudObject.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                        try {
                                            $CloudTenant = Get-VBRCloudTenant | Sort-Object -Property Name
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.TenantUtilizationSubHeading {
                                                $OutObj = @()
                                                try {
                                                    foreach ($Tenant in ($CloudTenant | Where-Object { $_.Resources.Repository.Name -eq $CloudObject.Name })) {

                                                        foreach ($Storage in ($Tenant.Resources | Where-Object { $_.Repository.Name -eq $CloudObject.Name })) {
                                                            $inObj = [ordered] @{
                                                                $LocalizedData.Name = $Tenant.Name
                                                                $LocalizedData.Quota = ConvertTo-FileSizeString -Size (Convert-Size -From MB -To Bytes -Value $Storage.RepositoryQuota) -RoundUnits $Options.RoundUnits
                                                                $LocalizedData.UsedSpace = switch ([string]::IsNullOrEmpty($Storage.UsedSpace)) {
                                                                    $true { '--' }
                                                                    $false { ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size (Convert-Size -From MB -To Bytes -Value $Storage.UsedSpace) }
                                                                    default { $LocalizedData.Unknown }
                                                                }
                                                                $LocalizedData.UsedSpacePct = $Storage.UsedSpacePercentage
                                                                $LocalizedData.Path = switch ([string]::IsNullOrEmpty($Storage.RepositoryQuotaPath)) {
                                                                    $true { '--' }
                                                                    $false { $Storage.RepositoryQuotaPath }
                                                                    default { $LocalizedData.Unknown }
                                                                }
                                                            }

                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                        }
                                                    }

                                                    if ($HealthCheck.CloudConnect.BackupStorage) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.UsedSpacePct) -gt 85 } | Set-Style -Style Warning -Property $LocalizedData.UsedSpacePct
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TenantUtilizationTable) - $($CloudObject.Name)"
                                                        List = $false
                                                        ColumnWidths = 28, 15, 15, 15, 27
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Tenant Utilization - $($CloudObject.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Tenant Utilization Section: $($_.Exception.Message)"
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Tenant Utilization Section: $($_.Exception.Message)"
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "$($CloudObject.Name) Cloud Backup Storage Section: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Cloud Backup Storage Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage 'Cloud Backup Storage'
        }
    }
    end {}

}