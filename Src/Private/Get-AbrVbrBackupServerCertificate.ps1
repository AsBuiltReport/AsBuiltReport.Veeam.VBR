
function Get-AbrVbrBackupServerCertificate {
    <#
    .SYNOPSIS
    Used by As Built Report to returns TLS certificates configured on Veeam Backup & Replication.


    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR TLS certificates information from $System."
    }

    process {
        if ((Get-VBRBackupServerCertificate).count -gt 0) {
            Section -Style Heading4 'Backup Server TLS Certificate' {
                BlankLine
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
                        Name = "TLS Certificate information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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
    end {}

}