
function Get-AbrVbrCloudConnectCG {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Gateway information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCloudConnectCG
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Cloud Connect Gateway'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' }) {
                if ($CloudObjects = Get-VBRCloudGateway | Sort-Object -Property Name) {
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        try {
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {
                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $CloudObject.Name
                                        $LocalizedData.DNSIP = $CloudObject.IpAddress
                                        $LocalizedData.NetworkMode = $CloudObject.NetworkMode
                                        $LocalizedData.NATPort = $CloudObject.NATPort
                                        $LocalizedData.IncomingPort = $CloudObject.IncomingPort
                                        $LocalizedData.Enabled = $CloudObject.Enabled
                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -ge 2) {
                                        $CloudGPObjects = Get-VBRCloudGatewayPool
                                        $CGPool = switch ([string]::IsNullOrEmpty(($CloudGPObjects | Where-Object { $CloudObject.Name -in $_.CloudGateways.Name }).Name)) {
                                            $true { '--' }
                                            $false { ($CloudGPObjects | Where-Object { $CloudObject.Name -in $_.CloudGateways.Name }).Name }
                                            default { '--' }
                                        }
                                        $inObj.add($LocalizedData.CloudGatewayPool, $CGPool)
                                        $inObj.add($LocalizedData.Description, $CloudObject.Description)

                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -eq 1) {
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -ge 2) {

                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeading) - $($CloudObject.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        if ($HealthCheck.Jobs.BestPractice) {
                                            if ($OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' -or $_.$($LocalizedData.Description) -eq '--' }) {
                                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                BlankLine
                                                Paragraph {
                                                    Text $LocalizedData.BestPractice -Bold
                                                    Text $LocalizedData.BPText
                                                }
                                                BlankLine
                                            }
                                        }

                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Cloud Gateways $($CloudObject.Name) Section: $($_.Exception.Message)"
                                }

                            }

                            if ($InfoLevel.CloudConnect.CloudGateway -eq 1) {
                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 28, 28, 11, 11, 11, 11
                                }

                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Cloud Gateways Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Cloud Gateways Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage 'Cloud Connect Gateway'
        }
    }
    end {}

}