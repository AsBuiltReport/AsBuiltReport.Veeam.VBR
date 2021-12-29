
function Get-AbrVbrCredential {
    <#
    .SYNOPSIS
    Used by As Built Report to returns credentials managed by Veeam Backup & Replication.


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
        Write-PscriboMessage "Discovering Veeam VBR credential information from $System."
    }

    process {
        Section -Style Heading3 'Security Credentials' {
            Paragraph "The following section provides credentials managed by Veeam Backup & Replication."
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $Credentials = Get-VBRCredentials
                    foreach ($Credential in $Credentials) {
                        Write-PscriboMessage "Discovered $($Credential.Name) Server."
                        $inObj = [ordered] @{
                            'Name' = $Credential.Name
                            'Change Time' = Switch ($Credential.ChangeTimeUtc) {
                                "" {"-"; break}
                                $Null {'-'; break}
                                default {$Credential.ChangeTimeUtc.ToShortDateString()}
                            }
                            'Description' = $Credential.Description
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                $TableParams = @{
                    Name = "Security Credentials Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                    List = $false
                    ColumnWidths = 35, 20, 45
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
    }
    end {}

}