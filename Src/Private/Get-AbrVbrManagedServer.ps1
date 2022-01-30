
function Get-AbrVbrManagedServer {
    <#
    .SYNOPSIS
    Used by As Built Report to returns hosts connected to the backup infrastructure.


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
        Write-PscriboMessage "Discovering Veeam VBR Managed Server information from $System."
    }

    process {
        try {
            if ((Get-VBRServer).count -gt 0) {
                Section -Style Heading3 'Virtualization Servers and Hosts' {
                    Paragraph "The following section display managed servers."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $ManagedServers = Get-VBRServer
                            foreach ($ManagedServer in $ManagedServers) {
                                Write-PscriboMessage "Discovered $($ManagedServer.Name) managed server."
                                $inObj = [ordered] @{
                                    'Name' = $ManagedServer.Name
                                    'Description' = $ManagedServer.Info.TypeDescription
                                    'Status' = Switch ($ManagedServer.IsUnavailable) {
                                        'False' {'Available'}
                                        'True' {'Unavailable'}
                                        default {$ManagedServer.IsUnavailable}
                                    }
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }

                        if ($HealthCheck.Infrastructure.Status) {
                            $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Managed Servers - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $false
                            ColumnWidths = 50, 35, 15
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Description' | Table @TableParams
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