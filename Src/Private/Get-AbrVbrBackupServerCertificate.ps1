
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
        Show-AbrDebugExecutionTime -Start -TitleMessage "Backup Server TLS Certificate"
    }

    process {
        try {
            if ($TLSSettings = Get-VBRBackupServerCertificate) {
                Section -Style Heading4 'Backup Server TLS Certificate' {
                    $OutObj = @()
                    try {
                        foreach ($EmailSetting in $TLSSettings) {
                            $inObj = [ordered] @{
                                'Friendly Name' = $TLSSettings.FriendlyName
                                'Subject Name' = $TLSSettings.SubjectName
                                'Issuer Name' = $TLSSettings.IssuerName
                                'Expiration Date' = $TLSSettings.NotAfter.ToShortDateString()
                                'Issued Date' = $TLSSettings.NotBefore.ToShortDateString()
                                'Thumbprint' = $TLSSettings.Thumbprint
                                'Serial Number' = $TLSSettings.SerialNumber
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server TLS Certificate Section: $($_.Exception.Message)"
                    }

                    if ($HealthCheck.Infrastructure.Settings) {
                        $OutObj | Where-Object { $_.'Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Enabled'
                    }

                    $TableParams = @{
                        Name = "TLS Certificate - $VeeamBackupServer"
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
        Show-AbrDebugExecutionTime -End -TitleMessage "Backup Server TLS Certificate"
    }

}