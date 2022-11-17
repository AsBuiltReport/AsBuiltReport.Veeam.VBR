
function Get-AbrVbrCloudConnectCert {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud SSL Certificate
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
        Write-PscriboMessage "Discovering Veeam VBR Cloud SSL Certificate information from $System."
    }

    process {
        try {
            if ((Get-VBRInstalledLicense | Where-Object {$_.CloudConnect -in @("Enterprise")}) -and (Get-VBRCloudGatewayCertificate).count -gt 0) {
                Section -Style Heading3 'Cloud Gateway Certificate' {
                    Paragraph "The following section provides information about Cloud Gateways SSL Certificate."
                    BlankLine
                    try {
                        $CloudObjects = Get-VBRCloudGatewayCertificate
                        $OutObj = @()
                        foreach ($CloudObject in $CloudObjects) {
                            try {
                                Write-PscriboMessage "Discovered $($CloudObject.DisplayName) Cloud Gateway SSL Certificate information."

                                $inObj = [ordered] @{
                                    'Name' = $CloudObject.DisplayName
                                    'Subject Name' = $CloudObject.SubjectName
                                    'Issuer Name' = $CloudObject.IssuerName
                                    'Issued Date' = $CloudObject.NotBefore
                                    'Expiration Date' = $CloudObject.NotAfter
                                    'Thumbprint' = $CloudObject.Thumbprint
                                    'Serial Number' = $CloudObject.SerialNumber
                                }

                                $OutObj += [pscustomobject]$inobj

                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Cloud Gateways SSL Certificate - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
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