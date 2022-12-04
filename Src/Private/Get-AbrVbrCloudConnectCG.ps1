
function Get-AbrVbrCloudConnectCG {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Gateway information from $System."
    }

    process {
        try {
            if (Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -in @("Enterprise")}) {
                if ((Get-VBRCloudGateway).count -gt 0) {
                    Section -Style Heading3 'Cloud Gateways' {
                        Paragraph "The following section provides summary information about configured Cloud Gateways."
                        BlankLine
                        try {
                            $CloudObjects = Get-VBRCloudGateway | Sort-Object -Property Name
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {
                                    Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Gateway information."

                                    $inObj = [ordered] @{
                                        'Name' = $CloudObject.Name
                                        'DNS/IP' = $CloudObject.IpAddress
                                        'Network Mode' = $CloudObject.NetworkMode
                                        'NAT Port' = $CloudObject.NATPort
                                        'Incoming Port' = $CloudObject.IncomingPort
                                        'Enabled' = ConvertTo-TextYN $CloudObject.Enabled
                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -ge 2) {
                                        $CloudGPObjects = Get-VBRCloudGatewayPool
                                        $CGPool = Switch ([string]::IsNullOrEmpty(($CloudGPObjects | where-Object {$CloudObject.Name -in $_.CloudGateways.Name}).Name)) {
                                            $true {'-'}
                                            $false {($CloudGPObjects | where-Object {$CloudObject.Name -in $_.CloudGateways.Name}).Name}
                                            default {'-'}
                                        }
                                        $inObj.add('Cloud Gateway Pool', $CGPool)
                                        $inObj.add('Description', $CloudObject.Description)

                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -eq 1) {
                                        $OutObj += [pscustomobject]$inobj
                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -ge 2) {

                                        $OutObj = [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Cloud Gateways - $($CloudObject.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }

                            }

                            if ($InfoLevel.CloudConnect.CloudGateway -eq 1) {
                                $TableParams = @{
                                    Name = "Cloud Gateways - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 28, 28, 11, 11, 11, 11
                                }

                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
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