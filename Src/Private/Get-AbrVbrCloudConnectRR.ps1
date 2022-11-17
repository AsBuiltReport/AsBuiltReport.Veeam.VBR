
function Get-AbrVbrCloudConnectRR {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Replica Resources
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Connect Replica Resources information from $System."
    }

    process {
        try {
            if ((Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -in @("Enterprise")}) -and (Get-VBRCloudHardwarePlan).count -gt 0) {
                Section -Style Heading3 'Replica Resources' {
                    Paragraph "The following table provides a summary of Replica Resources."
                    BlankLine
                    try {
                        $CloudObjects = Get-VBRCloudHardwarePlan
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            try {
                                Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Connect Replica Resources information."
                                $inObj = [ordered] @{
                                    'Name' = $CloudObject.Name
                                    'Platform' = $CloudObject.Platform
                                    'CPU' = Switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                                        $true {'Unlimited'}
                                        $false {"$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz"}
                                        default {'-'}
                                    }
                                    'Memory' = Switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                                        $true {'Unlimited'}
                                        $false {"$([math]::Round($CloudObject.Memory / 1Kb, 2)) GB"}
                                        default {'-'}
                                    }
                                    'Storage Quota' = "$(($CloudObject.Datastore.Quota | Measure-Object -Sum).Sum) GB"
                                    'Network Count' = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                                    'Subscribers' = ($CloudObject.SubscribedTenantId).count
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Replica Resources - $($VeeamBackupServer)"
                            List = $false
                            ColumnWidths = 26, 12, 12, 12, 12, 12, 14
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
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}