
function Get-AbrVbrCloudConnectGP {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway Pools
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.1
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud Gateway Pools information from $System."
    }

    process {
        try {
            if (Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -in @("Enterprise")}) {
                if ((Get-VBRCloudGatewayPool).count -gt 0) {
                    Section -Style Heading3 'Gateways Pools' {
                        Paragraph "The following section provides summary information about configured Cloud Gateways Pools."
                        BlankLine
                        try {
                            $CloudObjects = Get-VBRCloudGatewayPool | Sort-Object -Property Name
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {
                                    Write-PscriboMessage "Discovered $($CloudObject.Name) Cloud Gateway Pools information."

                                    $inObj = [ordered] @{
                                        'Name' = $CloudObject.Name
                                        'Cloud Gateway Servers' = $CloudObject.CloudGateways -join ", "
                                        'Description' = $CloudObject.Description
                                    }

                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "Gateways Pools $($CloudObject.Name) Section: $($_.Exception.Message)"
                                }
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

                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Gateways Pools Section: $($_.Exception.Message)"
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