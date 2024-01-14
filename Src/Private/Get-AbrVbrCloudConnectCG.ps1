
function Get-AbrVbrCloudConnectCG {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Gateway
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.4
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
            if ($VbrLicenses | Where-Object {$_.CloudConnect -ne "Disabled"}) {
                $CloudObjects = Get-VBRCloudGateway | Sort-Object -Property Name
                if ($CloudObjects) {
                    Section -Style Heading3 'Cloud Gateways' {
                        Paragraph "The following section provides summary information about configured Cloud Gateways."
                        BlankLine
                        try {
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
                                            $true {'--'}
                                            $false {($CloudGPObjects | where-Object {$CloudObject.Name -in $_.CloudGateways.Name}).Name}
                                            default {'--'}
                                        }
                                        $inObj.add('Cloud Gateway Pool', $CGPool)
                                        $inObj.add('Description', $CloudObject.Description)

                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -eq 1) {
                                        $OutObj += [pscustomobject]$inobj
                                    }

                                    if ($InfoLevel.CloudConnect.CloudGateway -ge 2) {

                                        $OutObj = [pscustomobject]$inobj
                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $Null -like $_.'Description' } | Set-Style -Style Warning -Property 'Description'
                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                        }

                                        $TableParams = @{
                                            Name = "Cloud Gateways - $($CloudObject.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        if ($HealthCheck.Jobs.BestPractice) {
                                            if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $Null -like $_.'Description'}) {
                                                Paragraph "Health Check:" -Bold -Underline
                                                BlankLine
                                                Paragraph {
                                                    Text "Best Practice:" -Bold
                                                    Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                }
                                            }
                                        }

                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "Cloud Gateways $($CloudObject.Name) Section: $($_.Exception.Message)"
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
                            Write-PscriboMessage -IsWarning "Cloud Gateways Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Cloud Gateways Section: $($_.Exception.Message)"
        }
    }
    end {}

}