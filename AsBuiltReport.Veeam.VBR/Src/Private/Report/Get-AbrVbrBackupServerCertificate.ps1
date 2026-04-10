
function Get-AbrVbrBackupServerCertificate {
    <#
    .SYNOPSIS
    Used by As Built Report to returns TLS certificates configured on Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR TLS certificates information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupServerCertificate
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Server TLS Certificate'
    }

    process {
        try {
            if ($TLSSettings = Get-VBRBackupServerCertificate) {
                Section -Style Heading4 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($EmailSetting in $TLSSettings) {
                            $inObj = [ordered] @{
                                $LocalizedData.FriendlyName = $TLSSettings.FriendlyName
                                $LocalizedData.SubjectName = $TLSSettings.SubjectName
                                $LocalizedData.IssuerName = $TLSSettings.IssuerName
                                $LocalizedData.ExpirationDate = $TLSSettings.NotAfter.ToShortDateString()
                                $LocalizedData.IssuedDate = $TLSSettings.NotBefore.ToShortDateString()
                                $LocalizedData.Thumbprint = $TLSSettings.Thumbprint
                                $LocalizedData.SerialNumber = $TLSSettings.SerialNumber
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server TLS Certificate Section: $($_.Exception.Message)"
                    }

                    if ($HealthCheck.Infrastructure.Settings) {
                        $OutObj | Where-Object { $_.$($LocalizedData.Enabled) -like 'No' } | Set-Style -Style Warning -Property ($LocalizedData.Enabled)
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
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Server TLS Certificate Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Server TLS Certificate'
    }

}