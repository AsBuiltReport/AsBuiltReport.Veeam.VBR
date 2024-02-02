
function Get-AbrVbrWANAccelerator {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam WAN Accelerator Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.5
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
        Write-PScriboMessage "Discovering Veeam VBR WAN Accelerator information from $System."
    }

    process {
        try {
            $WANAccels = Get-VBRWANAccelerator | Sort-Object -Property Name
            if (($VbrLicenses | Where-Object { $_.Edition -in @("EnterprisePlus") }) -and $WANAccels) {
                Section -Style Heading3 'WAN Accelerators' {
                    Paragraph "The following section provides information about WAN Accelerator. WAN accelerators are responsible for global data caching and data deduplication."
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($WANAccel in $WANAccels) {
                            $IsWaHasAnyCaches = 'Unknown'
                            try {
                                Write-PScriboMessage "Discovered $($WANAccel.Name) Wan Accelerator."
                                try {
                                    $IsWaHasAnyCaches = $WANAccel.IsWaHasAnyCaches()
                                } catch {
                                    Write-PScriboMessage -IsWarning "Wan Accelerator $($WANAccel.Name) IsWaHasAnyCaches() Item: $($_.Exception.Message)"
                                }
                                try {
                                    $ServiceIPAddress = $WANAccel.GetWaConnSpec().Endpoints.IP -join ", "
                                } catch {
                                    Write-PScriboMessage -IsWarning "Wan Accelerator $($WANAccel.Name) GetWaConnSpec() Item: $($_.Exception.Message)"
                                }
                                $inObj = [ordered] @{
                                    'Name' = $WANAccel.Name
                                    'Host Name' = $WANAccel.GetHost().Name
                                    'Is Public' = ConvertTo-TextYN $WANAccel.GetType().IsPublic
                                    'Management Port' = "$($WANAccel.GetWaMgmtPort())\TCP"
                                    'Service IP Address' = $ServiceIPAddress
                                    'Traffic Port' = "$($WANAccel.GetWaTrafficPort())\TCP"
                                    'Max Tasks Count' = $WANAccel.FindWaHostComp().Options.MaxTasksCount
                                    'Download Stream Count' = $WANAccel.FindWaHostComp().Options.DownloadStreamCount
                                    'Enable Performance Mode' = ConvertTo-TextYN $WANAccel.FindWaHostComp().Options.EnablePerformanceMode
                                    'Configured Cache' = ConvertTo-TextYN $IsWaHasAnyCaches
                                    'Cache Path' = $WANAccel.FindWaHostComp().Options.CachePath
                                    'Max Cache Size' = "$($WANAccel.FindWaHostComp().Options.MaxCacheSize) $($WANAccel.FindWaHostComp().Options.SizeUnit)"
                                }
                                $OutObj = [pscustomobject]$inobj

                                if ($HealthCheck.Infrastructure.Proxy) {
                                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
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
                            } catch {
                                Write-PScriboMessage -IsWarning "Wan Accelerator $($WANAccel.Name) Table: $($_.Exception.Message)"
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Wan Accelerator Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Wan Accelerator Document: $($_.Exception.Message)"
        }
    }
    end {}

}