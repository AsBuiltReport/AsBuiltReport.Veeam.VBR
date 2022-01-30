
function Get-AbrVbrCredential {
    <#
    .SYNOPSIS
    Used by As Built Report to returns credentials managed by Veeam Backup & Replication.


    .DESCRIPTION
    .NOTES
        Version:        0.2.0
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
        try {
            if ((Get-VBRCredentials).count -gt 0) {
                Section -Style Heading4 'Security Credentials' {
                    Paragraph "The following table provide information on the credentials managed by Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    $Credentials = Get-VBRCredentials
                    foreach ($Credential in $Credentials) {
                        try {
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
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    $TableParams = @{
                        Name = "Security Credentials - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                        List = $false
                        ColumnWidths = 35, 20, 45
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    try {
                        $CloudCredentials = Get-VBRCloudProviderCredentials
                        if (($CloudCredentials).count -gt 0) {
                            Section -Style Heading4 'Service Provider Credentials' {
                                Paragraph "The following table provide information about service provider credentials managed by Veeam Backup & Replication."
                                BlankLine
                                $OutObj = @()
                                foreach ($CloudCredential in $CloudCredentials) {
                                    try {
                                        Write-PscriboMessage "Discovered $($CloudCredential.Name) Server."
                                        $inObj = [ordered] @{
                                            'Name' = $CloudCredential.Name
                                            'Description' = $CloudCredential.Description
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "Service Provider Credentials - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                    List = $false
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            }
                        }
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