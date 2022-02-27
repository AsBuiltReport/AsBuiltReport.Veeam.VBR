
function Get-AbrVbrBackupServerCertificate {
    <#
    .SYNOPSIS
    Used by As Built Report to returns TLS certificates configured on Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Discovering Veeam VBR TLS certificates information from $System."
    }

    process {
        try {
            if ((Get-VBRBackupServerCertificate).count -gt 0) {
                Section -Style Heading4 'Backup Server TLS Certificate' {
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $TLSSettings = Get-VBRBackupServerCertificate
                            foreach ($EmailSetting in $TLSSettings) {
                                $inObj = [ordered] @{
                                    'Friendly Name' = $TLSSettings.FriendlyName
                                    'Subject Name' = $TLSSettings.SubjectName
                                    'Issuer Name' = $TLSSettings.IssuerName
                                    'Expiration Date' = $TLSSettings.NotAfter.ToShortDateString()
                                    'Issued Date' = $TLSSettings.NotBefore.ToShortDateString()
                                    'Thumbprint' = $TLSSettings.Thumbprint
                                    'SerialNumber' = $TLSSettings.SerialNumber
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.'Enabled' -like 'No'} | Set-Style -Style Warning -Property 'Enabled'
                        }

                        $TableParams = @{
                            Name = "TLS Certificate - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
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