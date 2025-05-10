
function Get-AbrVbrCredential {
    <#
    .SYNOPSIS
    Used by As Built Report to returns credentials managed by Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR credential information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Veeam VBR Credential"
    }

    process {
        try {
            if ($Credentials = Get-VBRCredentials) {
                Section -Style Heading3 'Security Credentials' {
                    Paragraph "The following table provide information about the credentials managed by Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    foreach ($Credential in $Credentials) {
                        try {
                            Write-PScriboMessage "Discovered $($Credential.Name) Server."
                            $inObj = [ordered] @{
                                'Name' = $Credential.Name
                                'Change Time' = Switch ($Credential.ChangeTimeUtc) {
                                    "" { "--"; break }
                                    $Null { '--'; break }
                                    default { $Credential.ChangeTimeUtc.ToShortDateString() }
                                }
                                'Description' = $Credential.Description
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Security Credentials $($Credential.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "Security Credentials - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 35, 20, 45
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    try {
                        if ($CloudCredentials = Get-VBRCloudProviderCredentials) {
                            Section -Style Heading3 'Service Provider Credentials' {
                                Paragraph "The following table provide information about the service provider credentials managed by Veeam Backup & Replication."
                                BlankLine
                                $OutObj = @()
                                foreach ($CloudCredential in $CloudCredentials) {
                                    try {
                                        Write-PScriboMessage "Discovered $($CloudCredential.Name) Server."
                                        $inObj = [ordered] @{
                                            'Name' = $CloudCredential.Name
                                            'Description' = $CloudCredential.Description
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Service Provider Credentials $($CloudCredential.Name) Section: $($_.Exception.Message)"
                                    }
                                }

                                $TableParams = @{
                                    Name = "Service Provider Credentials - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Service Provider Credentials Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Security Credentials Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage "Veeam VBR Credential"
        }
    }
    end {}

}