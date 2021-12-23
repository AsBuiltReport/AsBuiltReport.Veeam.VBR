
function Get-AbrVbrBackupProxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Proxies Information
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
        Write-PscriboMessage "Discovering Veeam V&R Backup Proxies information from $System."
    }

    process {
        Section -Style Heading3 'Backup Proxies' {
            Paragraph "The following section provides a summary of the Veeam Backup Proxies"
            BlankLine
            Section -Style Heading4 'VMware Backup Proxies' {
                Paragraph "The following section provides a summary of the VMware Backup Proxies"
                BlankLine
                $OutObj = @()
                if ((Get-VBRServerSession).Server) {
                    try {
                        $BackupProxies = Get-VBRViProxy
                        foreach ($BackupProxy in $BackupProxies) {
                            Write-PscriboMessage "Discovered $($BackupProxy.Name) Repository."
                            $inObj = [ordered] @{
                                'Name' = $BackupProxy.Name
                                'Disabled' = ConvertTo-TextYN $BackupProxy.IsDisabled
                                'Max Tasks Count' = $BackupProxy.MaxTasksCount
                                'Use Ssl' = ConvertTo-TextYN $BackupProxy.UseSsl
                                'Failover To Network' = ConvertTo-TextYN $BackupProxy.FailoverToNetwork
                                'Transport Mode' = $BackupProxy.TransportMode
                                'Chassis Type' = $BackupProxy.ChassisType
                                'OS Type' = $BackupProxy.Host.Type
                                'Services Credential' = $BackupProxy.Host.ProxyServicesCreds.Name
                                'Status' = Switch (($BackupProxy.Host).IsUnavailable) {
                                    'False' {'Available'}
                                    'True' {'Unavailable'}
                                    default {($BackupProxy.Host).IsUnavailable}
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                    }
                    catch {
                        Write-PscriboMessage $_.Exception.Message
                    }

                    $TableParams = @{
                        Name = "Backup Proxy Information - $($BackupProxy.Name)"
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