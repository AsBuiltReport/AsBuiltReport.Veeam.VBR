
function Get-AbrVbrWANAccelerator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam WAN Accelerator Information
    .DESCRIPTION
    .NOTES
        Version:        0.3.0
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
        Write-PscriboMessage "Discovering Veeam VBR WAN Accelerator information from $System."
    }

    process {
        try {
            if ((Get-VBRInstalledLicense | Where-Object {$_.Edition -in @("EnterprisePlus")}) -and (Get-VBRWANAccelerator).count -gt 0) {
                Section -Style Heading3 'WAN Accelerators' {
                    Paragraph "The following section provides information on WAN Accelerator. WAN accelerators are responsible for global data caching and data deduplication"
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $WANAccels = Get-VBRWANAccelerator
                            foreach ($WANAccel in $WANAccels) {
                                $IsWaHasAnyCaches = 'Unknown'
                                try {
                                    Write-PscriboMessage "Discovered $($WANAccel.Name) Wan Accelerator."
                                    try {
                                        $IsWaHasAnyCaches = $WANAccel.IsWaHasAnyCaches()
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                    $inObj = [ordered] @{
                                        'Name' = $WANAccel.Name
                                        'Host Name' = $WANAccel.GetHost().Name
                                        'Is Public' = ConvertTo-TextYN $WANAccel.GetType().IsPublic
                                        'Management Port' = "$($WANAccel.GetWaMgmtPort())\TCP"
                                        'Service IP Address' = $WANAccel.GetWaConnSpec().Endpoints.IP -join ", "
                                        'Traffic Port' = "$($WANAccel.GetWaTrafficPort())\TCP"
                                        'Max Tasks Count' = $WANAccel.FindWaHostComp().Options.MaxTasksCount
                                        'Download Stream Count' = $WANAccel.FindWaHostComp().Options.DownloadStreamCount
                                        'Enable Performance Mode' = ConvertTo-TextYN $WANAccel.FindWaHostComp().Options.EnablePerformanceMode
                                        'Configured Cache' = $IsWaHasAnyCaches
                                        'Cache Path' = $WANAccel.FindWaHostComp().Options.CachePath
                                        'Max Cache Size' = "$($WANAccel.FindWaHostComp().Options.MaxCacheSize) $($WANAccel.FindWaHostComp().Options.SizeUnit)"
                                    }
                                    $OutObj = [pscustomobject]$inobj

                                    if ($HealthCheck.Infrastructure.Proxy) {
                                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                    }

                                    $TableParams = @{
                                        Name = "Wan Accelerator - $($WANAccel.GetHost().Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}