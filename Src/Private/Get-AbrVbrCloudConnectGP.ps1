
function Get-AbrVbrCloudConnectGP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway Pools
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Gateway Pools information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Cloud Connect Gateway Pools"
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.CloudConnect -ne "Disabled" }) {
                if ($CloudObjects = Get-VBRCloudGatewayPool | Sort-Object -Property Name) {
                    Section -Style Heading3 'Gateways Pools' {
                        Paragraph "The following section provides summary information about configured Cloud Gateways Pools."
                        BlankLine
                        try {
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {
                                    Write-PScriboMessage "Discovered $($CloudObject.Name) Cloud Gateway Pools information."

                                    $inObj = [ordered] @{
                                        'Name' = $CloudObject.Name
                                        'Cloud Gateway Servers' = $CloudObject.CloudGateways -join ", "
                                        'Description' = $CloudObject.Description
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "Gateways Pools $($CloudObject.Name) Section: $($_.Exception.Message)"
                                }
                            }

                            if ($HealthCheck.Jobs.BestPractice) {
                                $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                                $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                            }

                            $TableParams = @{
                                Name = "Gateways Pools - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 34, 33, 33
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            if ($HealthCheck.Jobs.BestPractice) {
                                if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $_.'Description' -eq '--' }) {
                                    Paragraph "Health Check:" -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text "Best Practice:" -Bold
                                        Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
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
        Show-AbrDebugExecutionTime -End -TitleMessage "Cloud Connect Gateway Pools"
    }

}