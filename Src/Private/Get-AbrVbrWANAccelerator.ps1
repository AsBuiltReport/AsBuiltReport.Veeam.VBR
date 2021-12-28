
function Get-AbrVbrWANAccelerator {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam WAN Accelerator Information
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
        Write-PscriboMessage "Discovering Veeam VBR WAN Accelerator information from $System."
    }

    process {
        Section -Style Heading3 'WAN Accelerators' {
            Paragraph "The following section provides a summary of the VEEAM WAN Accelerator"
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $WANAccels = Get-VBRWANAccelerator
                    foreach ($WANAccel in $WANAccels) {
                        Write-PscriboMessage "Discovered $($WANAccel.Name) Wan Accelerator."
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
                            'Configured Cache' = ConvertTo-TextYN $WANAccel.IsWaHasAnyCaches()
                            'Cache Path' = $WANAccel.FindWaHostComp().Options.CachePath
                            'Max Cache Size' = "$($WANAccel.FindWaHostComp().Options.MaxCacheSize) $($WANAccel.FindWaHostComp().Options.SizeUnit)"
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                if ($HealthCheck.Infrastructure.Proxy) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Wan Accelerator Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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