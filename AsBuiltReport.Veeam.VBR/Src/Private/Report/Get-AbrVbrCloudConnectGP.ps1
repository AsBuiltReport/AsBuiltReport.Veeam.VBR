
function Get-AbrVbrCloudConnectGP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway Pools
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
        $LocalizedData = $reportTranslate.GetAbrVbrCloudConnectGP
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Cloud Connect Gateway Pools'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' }) {
                if ($CloudObjects = Get-VBRCloudGatewayPool | Sort-Object -Property Name) {
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        try {
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {

                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $CloudObject.Name
                                        $LocalizedData.CloudGatewayServers = $CloudObject.CloudGateways -join ', '
                                        $LocalizedData.Description = $CloudObject.Description
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "Gateways Pools $($CloudObject.Name) Section: $($_.Exception.Message)"
                                }
                            }

                            if ($HealthCheck.Jobs.BestPractice) {
                                $OutObj | Where-Object { $_.$LocalizedData.Description -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                $OutObj | Where-Object { $_.$LocalizedData.Description -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 34, 33, 33
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                            if ($HealthCheck.Jobs.BestPractice) {
                                if ($OutObj | Where-Object { $_.$LocalizedData.Description -match 'Created by' -or $_.$LocalizedData.Description -eq '--' }) {
                                    Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text $LocalizedData.BestPractice -Bold
                                        Text $LocalizedData.BPDescription
                                    }
                                    BlankLine
                                }
                            }

                        } catch {
                            Write-PScriboMessage -IsWarning "Gateways Pools Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Cloud Connect Gateway Pools'
    }

}
