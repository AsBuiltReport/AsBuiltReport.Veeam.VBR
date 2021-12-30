
function Get-AbrVbrServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
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
        Write-PscriboMessage "Discovering Veeam V&R Server information from $System."
    }

    process {
        Section -Style Heading3 'Backup Server Information' {
            Paragraph "The following section provides a summary of the Veeam Backup Server"
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $BackupServers = Get-VBRServer -Type Local
                    foreach ($BackupServer in $BackupServers) {
                        $SecurityOptions = Get-VBRSecurityOptions
                        Write-PscriboMessage "Discovered $BackupServer Server."
                        $inObj = [ordered] @{
                            'Server Name' = $BackupServer.Name
                            'Description' = $BackupServer.Description
                            'Type' = $BackupServer.Type
                            'Status' = Switch ($BackupServer.IsUnavailable) {
                                'False' {'Available'}
                                'True' {'Unavailable'}
                                default {$BackupServer.IsUnavailable}
                            }
                            'Api Version' = $BackupServer.ApiVersion
                            'Audit Logs Path' = $SecurityOptions.AuditLogsPath
                            'Compress Old Audit Logs' = ConvertTo-TextYN $SecurityOptions.CompressOldAuditLogs
                            'Fips Compliant Mode' = Switch ($SecurityOptions.FipsCompliantModeEnabled) {
                                'True' {"Enabled"}
                                'False' {"Disabled"}
                            }

                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                if ($HealthCheck.Infrastructure.Server) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Backup Server Information - $($BackupServer.Name.Split(".")[0])"
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
    end {}

}