
function Get-AbrVbrManagedServer {
    <#
    .SYNOPSIS
    Used by As Built Report to returns hosts connected to the backup infrastructure.
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
        Write-PScriboMessage "Discovering Veeam VBR Virtualization Servers and Hosts information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Virtualization Servers and Hosts'
    }

    process {
        try {
            if ($ManagedServers = Get-VBRServer) {
                Section -Style Heading3 'Virtualization Servers and Hosts' {
                    $OutObj = @()
                    foreach ($ManagedServer in $ManagedServers) {
                        try {
                            Write-PScriboMessage "Discovered $($ManagedServer.Name) managed server."
                            $inObj = [ordered] @{
                                'Name' = $ManagedServer.Name
                                'Description' = $ManagedServer.Info.TypeDescription
                                'Status' = Switch ($ManagedServer.IsUnavailable) {
                                    'False' { 'Available' }
                                    'True' { 'Unavailable' }
                                    default { $ManagedServer.IsUnavailable }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Virtualization Servers and Hosts $($ManagedServer.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Infrastructure.Status) {
                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                    }

                    $TableParams = @{
                        Name = "Managed Servers - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 50, 35, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Description' | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Virtualization Servers and Hosts Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Virtualization Servers and Hosts'
    }

}