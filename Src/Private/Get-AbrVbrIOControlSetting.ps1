
function Get-AbrVbrIOControlSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns storage latency control settings on the production datastores.


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
        Write-PscriboMessage "Discovering Veeam VBR storage latency control settings information from $System."
    }

    process {
        if ((Get-VBRStorageLatencyControlOptions).count -gt 0) {
            Section -Style Heading4 'Storage Latency Control Options' {
                $OutObj = @()
                if ((Get-VBRServerSession).Server) {
                    try {
                        $StorageLatencyControls = Get-VBRStorageLatencyControlOptions
                        foreach ($StorageLatencyControl in $StorageLatencyControls) {
                            $inObj = [ordered] @{
                                'Latency Limit' = "$($StorageLatencyControl.LatencyLimitMs)/ms"
                                'Throttling IO Limit' = "$($StorageLatencyControl.ThrottlingIOLimitMs)/ms"
                                'Enabled' = ConvertTo-TextYN $StorageLatencyControl.Enabled
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
                        Name = "Storage Latency Control Options - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                        List = $false
                        ColumnWidths = 35, 35, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    try {
                        if (Get-VBRAdvancedLatencyOptions) {
                            Section -Style Heading5 'Per Datastore Latency Control Options' {
                                $OutObj = @()
                                if ((Get-VBRServerSession).Server) {
                                    try {
                                        $StorageLatencyControls = Get-VBRAdvancedLatencyOptions
                                        foreach ($StorageLatencyControl in $StorageLatencyControls) {
                                            $inObj = [ordered] @{
                                                'Datastore Name' = $StorageLatencyControl.DatastoreId
                                                'Latency Limit' = "$($StorageLatencyControl.LatencyLimitMs)/ms"
                                                'Throttling IO Limit' = "$($StorageLatencyControl.ThrottlingIOLimitMs)/ms"
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }

                                    $TableParams = @{
                                        Name = "Per Datastore Latency Control Options - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                        List = $false
                                        ColumnWidths = 40, 30, 30
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
            }
        }
    }
    end {}

}