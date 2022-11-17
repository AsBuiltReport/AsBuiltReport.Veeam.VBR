
function Get-AbrVbrCloudConnectBS {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Backup Storage
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
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
            if ((Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -in @("Enterprise")}) -and ((Get-VBRCloudTenant).Resources.Repository).count -gt 0) {
                Section -Style Heading3 'Backup Storage' {
                    Paragraph "The following section provides information about Veeam Cloud Connect configured Backup Storage."
                    BlankLine
                    try {
                        $CloudObjects = (Get-VBRCloudTenant).Resources
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            $PercentFree = 0
                            if (@($($CloudObject.Repository.GetContainer().CachedTotalSpace.InGigabytes),$($CloudObject.Repository.GetContainer().CachedFreeSpace.InGigabytes)) -ne 0) {
                                $UsedSpace = ($($CloudObject.Repository.GetContainer().CachedTotalSpace.InGigabytes-$($CloudObject.Repository.GetContainer().CachedFreeSpace.InGigabytes)))
                                if ($UsedSpace -ne 0) {
                                    $PercentFree = $([Math]::Round($UsedSpace/$($CloudObject.Repository.GetContainer().CachedTotalSpace.InGigabytes) * 100))
                                }
                            }
                            Section -Style Heading4 $CloudObject.Repository.Name {
                                try {
                                    Write-PscriboMessage "Discovered $($CloudObject.Repository.Name) Cloud Backup Storage information."

                                    $inObj = [ordered] @{
                                        'Type' = $CloudObject.Repository.TypeDisplay
                                        'Path' = Switch ([string]::IsNullOrEmpty($CloudObject.Repository.FriendlyPath)) {
                                            $true {'-'}
                                            $false {$CloudObject.Repository.FriendlyPath}
                                            default {'Unknown'}
                                        }
                                        'Total Space' = "$($CloudObject.Repository.GetContainer().CachedTotalSpace.InGigabytes) GB"
                                        'Free Space' = "$($CloudObject.Repository.GetContainer().CachedFreeSpace.InGigabytes) GB"
                                        'Used Space %' = $PercentFree
                                        'Status' = Switch ($CloudObject.Repository.IsUnavailable) {
                                            'False' {'Available'}
                                            'True' {'Unavailable'}
                                            default {$CloudObject.Repository.IsUnavailable}
                                        }
                                        'Description' = $CloudObject.Repository.Description
                                    }

                                    $OutObj = [pscustomobject]$inobj

                                    $TableParams = @{
                                        Name = "Backup Storage - $($CloudObject.Repository.Name)"
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
                                                foreach ($Tenant in ($CloutTenant | Where-Object {$_.Resources.Repository.Name -eq $CloudObject.Repository.Name})) {
                                                    Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Tenant utilization."
                                                    foreach ($Storage in ($Tenant.Resources | Where-Object {$_.Repository.Name -eq $CloudObject.Repository.Name})) {
                                                        $inObj = [ordered] @{
                                                            'Name' = $Tenant.Name
                                                            'Quota' = "$([math]::Round($Storage.RepositoryQuota / 1Kb, 2)) GB"
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
                                                    Name = "Tenant Utilization - $($CloudObject.Repository.Name)"
                                                    List = $false
                                                    ColumnWidths = 25, 25, 25, 25
                                                }

                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
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
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}