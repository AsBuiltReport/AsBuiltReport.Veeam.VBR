
function Get-AbrVbrCloudConnectCert {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud SSL Certificate
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud SSL Certificate information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Cloud Connect SSL Certificate"
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.CloudConnect -ne "Disabled" }) {
                if ($CloudObjects = Get-VBRCloudGatewayCertificate) {
                    Section -Style Heading3 'Gateway Certificate' {
                        Paragraph "The following section provides information about Cloud Gateways SSL Certificate."
                        BlankLine
                        try {
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {
                                    Write-PScriboMessage "Discovered $($CloudObject.DisplayName) Cloud Gateway SSL Certificate information."

                                    $inObj = [ordered] @{
                                        'Name' = $CloudObject.DisplayName
                                        'Subject Name' = $CloudObject.SubjectName
                                        'Issuer Name' = $CloudObject.IssuerName
                                        'Issued Date' = $CloudObject.NotBefore
                                        'Expiration Date' = $CloudObject.NotAfter
                                        'Thumbprint' = $CloudObject.Thumbprint
                                        'Serial Number' = $CloudObject.SerialNumber
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                } catch {
                                    Write-PScriboMessage -IsWarning "$($CloudObject.DisplayName) Gateway SSL Certificate Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "Gateway SSL Certificate - $VeeamBackupServer"
                                List = $true
                                ColumnWidths = 40, 60
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                        } catch {
                            Write-PScriboMessage -IsWarning "Gateway SSL Certificate Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Gateway Certificate Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage "Cloud Connect SSL Certificate"
        }
    }
    end {}

}