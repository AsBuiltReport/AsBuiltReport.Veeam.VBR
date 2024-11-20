
function Get-AbrVbrWANAccelerator {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam WAN Accelerator Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.13
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
        $WanAcceltranslate = Get-AsBuiltTranslation -Product "Infrastructure" -Category "WANAccel"
    }

    process {
        try {
            $WANAccels = Get-VBRWANAccelerator | Sort-Object -Property Name
            if (($VbrLicenses | Where-Object { $_.Edition -in @("EnterprisePlus") }) -and $WANAccels) {
                Section -Style Heading3 $WanAcceltranslate.WanAccelheading {
                    Paragraph $WanAcceltranslate.WanAccelparagraph
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
                                    $WanAcceltranslate.WanAccelName = $WANAccel.Name
                                    $WanAcceltranslate.WanAccelHostName = $WANAccel.GetHost().Name
                                    $WanAcceltranslate.WanAccelIsPublic  = $WANAccel.GetType().IsPublic
                                    $WanAcceltranslate.WanAccelManagementPort = "$($WANAccel.GetWaMgmtPort())\TCP"
                                    $WanAcceltranslate.WanAccelServiceIPAddress  = $ServiceIPAddress
                                    $WanAcceltranslate.WanAccelTrafficPort  = "$($WANAccel.GetWaTrafficPort())\TCP"
                                    $WanAcceltranslate.WanAccelMaxTasksCount  = $WANAccel.FindWaHostComp().Options.MaxTasksCount
                                    $WanAcceltranslate.WanAccelDownloadStreamCount  = $WANAccel.FindWaHostComp().Options.DownloadStreamCount
                                    $WanAcceltranslate.WanAccelEnablePerformanceMode  = $WANAccel.FindWaHostComp().Options.EnablePerformanceMode
                                    $WanAcceltranslate.WanAccelConfiguredCache  = $IsWaHasAnyCaches
                                    $WanAcceltranslate.WanAccelCachePath  = $WANAccel.FindWaHostComp().Options.CachePath
                                    $WanAcceltranslate.WanAccelMaxCacheSize  = "$($WANAccel.FindWaHostComp().Options.MaxCacheSize) $($WANAccel.FindWaHostComp().Options.SizeUnit)"
                                }
                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                $TableParams = @{
                                    Name = "$($WanAcceltranslate.WanAccelheading3) - $($WANAccel.GetHost().Name)"
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