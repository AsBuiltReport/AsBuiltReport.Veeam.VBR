
function Get-AbrVbrCloudConnectCert {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud SSL Certificate
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud SSL Certificate information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCloudConnectCert
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Cloud Connect SSL Certificate'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' }) {
                if ($CloudObjects = Get-VBRCloudGatewayCertificate) {
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        try {
                            $OutObj = @()
                            foreach ($CloudObject in $CloudObjects) {
                                try {


                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $CloudObject.DisplayName
                                        $LocalizedData.SubjectName = $CloudObject.SubjectName
                                        $LocalizedData.IssuerName = $CloudObject.IssuerName
                                        $LocalizedData.IssuedDate = $CloudObject.NotBefore
                                        $LocalizedData.ExpirationDate = $CloudObject.NotAfter
                                        $LocalizedData.Thumbprint = $CloudObject.Thumbprint
                                        $LocalizedData.SerialNumber = $CloudObject.SerialNumber
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                } catch {
                                    Write-PScriboMessage -IsWarning "$($CloudObject.DisplayName) Gateway SSL Certificate Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
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
            Show-AbrDebugExecutionTime -End -TitleMessage 'Cloud Connect SSL Certificate'
        }
    }
    end {}

}