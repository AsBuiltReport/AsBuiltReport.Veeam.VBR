
function Get-AbrVbrWANAccelerator {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam WAN Accelerator Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.9.0
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
        $LocalizedData = $reportTranslate.GetAbrVbrWANAccelerator
        Show-AbrDebugExecutionTime -Start -TitleMessage 'WAN Accelerators'
    }

    process {
        try {
            $WANAccels = Get-VBRWANAccelerator | Sort-Object -Property Name
            if (($VbrLicenses | Where-Object { $_.Edition -in @('EnterprisePlus') }) -and $WANAccels) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($WANAccel in $WANAccels) {
                            $IsWaHasAnyCaches = 'Unknown'
                            try {

                                try {
                                    $IsWaHasAnyCaches = $WANAccel.IsWaHasAnyCaches()
                                } catch {
                                    Write-PScriboMessage -IsWarning "WAN Accelerator $($WANAccel.Name) IsWaHasAnyCaches() Item: $($_.Exception.Message)"
                                }
                                try {
                                    $ServiceIPAddress = $WANAccel.GetWaConnSpec().Endpoints.IP -join ', '
                                } catch {
                                    Write-PScriboMessage -IsWarning "WAN Accelerator $($WANAccel.Name) GetWaConnSpec() Item: $($_.Exception.Message)"
                                }
                                $inObj = [ordered] @{
                                    $LocalizedData.Name = $WANAccel.Name
                                    $LocalizedData.HostName = $WANAccel.GetHost().Name
                                    $LocalizedData.IsPublic = $WANAccel.GetType().IsPublic
                                    $LocalizedData.ManagementPort = & {
                                        switch ($VbrVersion) {
                                            { $_ -ge 13 } { try { "$($WANAccel.GetMgmtConnSpec().Endpoints.Port)\TCP" } catch { Out-Null } }
                                            default { try { "$($WANAccel.GetWaMgmtPort())\TCP" } catch { Out-Null } }
                                        }
                                    }
                                    $LocalizedData.ServiceIPAddress = $ServiceIPAddress
                                    $LocalizedData.TrafficPort = & { try { "$($WANAccel.GetWaTrafficPort())\TCP" } catch { Out-Null } }
                                    $LocalizedData.MaxTasksCount = & { try { $WANAccel.FindWaHostComp().Options.MaxTasksCount } catch { Out-Null } }
                                    $LocalizedData.DownloadStreamCount = & { try { $WANAccel.FindWaHostComp().Options.DownloadStreamCount } catch { Out-Null } }
                                    $LocalizedData.EnablePerformanceMode = & { try { $WANAccel.FindWaHostComp().Options.EnablePerformanceMode } catch { Out-Null } }
                                    $LocalizedData.ConfiguredCache = $IsWaHasAnyCaches
                                    $LocalizedData.CachePath = & { try { $WANAccel.FindWaHostComp().Options.CachePath } catch { Out-Null } }
                                    $LocalizedData.MaxCacheSize = & { try { "$($WANAccel.FindWaHostComp().Options.MaxCacheSize) $($WANAccel.FindWaHostComp().Options.SizeUnit)" } catch { Out-Null } }
                                }
                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                if ($HealthCheck.Infrastructure.Proxy) {
                                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeading) - $($WANAccel.GetHost().Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }

                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            } catch {
                                Write-PScriboMessage -IsWarning "WAN Accelerator $($WANAccel.Name) Table: $($_.Exception.Message)"
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "WAN Accelerator Section: $($_.Exception.Message)"
                    }
                    if ($Options.EnableDiagrams) {
                        try {
                            try {
                                $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-WanAccelerator' -DiagramOutput base64
                            } catch {
                                Write-PScriboMessage -IsWarning "WAN Accelerator Diagram: $($_.Exception.Message)"
                            }
                            if ($Graph) {
                                $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                PageBreak
                                Section -Style Heading4 $LocalizedData.DiagramHeading {
                                    Image -Base64 $Graph -Text $LocalizedData.DiagramText -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
                                    PageBreak
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "WAN Accelerator Diagram Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "WAN Accelerator Document: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'WAN Accelerators'
    }

}