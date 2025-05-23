
function Get-AbrVbrCloudConnectPublicIP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Public IP
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Public IP information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Cloud Connect Public IP"
    }

    process {
        if ($VbrLicenses | Where-Object { $_.CloudConnect -ne "Disabled" }) {
            if ((Get-VBRCloudGatewayPool).count -gt 0) {
                Section -Style Heading3 'Public IP' {
                    Paragraph "The following section provides information about Cloud Public IP."
                    BlankLine
                    try {
                        $CloudObjects = Get-VBRCloudPublicIP
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            try {
                                $inObj = [ordered] @{
                                    'IP Address' = $CloudObject.IpAddress
                                    'Assigned Tenant' = Switch ([string]::IsNullOrEmpty($CloudObject.TenantId)) {
                                        $true { '--' }
                                        $false { (Get-VBRCloudTenant -Id $CloudObject.TenantId).Name }
                                        default { 'Unknown' }
                                    }
                                }

                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                            } catch {
                                Write-PScriboMessage -IsWarning "Cloud Public IP $($CloudObject.IpAddress) Section: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "Public IP - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 40, 60
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    } catch {
                        Write-PScriboMessage -IsWarning "Cloud Public IP Section: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage "Cloud Connect Public IP"
    }

}