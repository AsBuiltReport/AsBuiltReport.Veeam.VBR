
function Get-AbrVbrInstalledLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Infrastructure Installed Licenses
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.0
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
        Write-PScriboMessage "Discovering Veeam V&R License information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrInstalledLicense
        Show-AbrDebugExecutionTime -Start -TitleMessage 'License information'
    }

    process {
        if ($VbrLicenses) {
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph $LocalizedData.Paragraph
                BlankLine
                $OutObj = @()
                        try {
                            foreach ($License in $VbrLicenses) {

                                $inObj = [ordered] @{
                                    $LocalizedData.LicensedTo = $License.LicensedTo
                                    $LocalizedData.Edition = $License.Edition
                                    $LocalizedData.Type = $License.Type
                                    $LocalizedData.Status = $License.Status
                                    $LocalizedData.ExpirationDate = switch ($License.ExpirationDate) {
                                        '' { $LocalizedData.Dash; break }
                                        `$Null { $LocalizedData.Dash; break }
                                        default { $License.ExpirationDate.ToLongDateString() }
                                    }
                                    $LocalizedData.SupportId = $License.SupportId
                                    $LocalizedData.SupportExpirationDate = switch ($License.SupportExpirationDate) {
                                        '' { $LocalizedData.Dash; break }
                                        `$Null { $LocalizedData.Dash; break }
                                        default { $License.SupportExpirationDate.ToLongDateString() }
                                    }
                                    $LocalizedData.AutoUpdateEnabled = $License.AutoUpdateEnabled
                                    $LocalizedData.FreeAgentInstance = $License.FreeAgentInstanceConsumptionEnabled
                                    $LocalizedData.CloudConnect = $License.CloudConnect
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Installed License Information $($License.LicensedTo) Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.Status) {
                            $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq 'Expired' } | Set-Style -Style Critical -Property ($LocalizedData.Status)
                            $OutObj | Where-Object { $_.$($LocalizedData.Type) -eq 'Evaluation' } | Set-Style -Style Warning -Property ($LocalizedData.Type)
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableLicenses) - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        #---------------------------------------------------------------------------------------------#
                        #                                  Instance Section                                           #
                        #---------------------------------------------------------------------------------------------#
                        try {
                            $Licenses = $VbrLicenses | Select-Object -ExpandProperty InstanceLicenseSummary
                            if ($Licenses.LicensedInstancesNumber -gt 0) {
                                $OutObj = @()
                                try {
                                    foreach ($License in $Licenses) {

                                        $inObj = [ordered] @{
                                            $LocalizedData.InstancesCapacity = $License.LicensedInstancesNumber
                                            $LocalizedData.UsedInstances = $License.UsedInstancesNumber
                                            $LocalizedData.NewInstances = $License.NewInstancesNumber
                                            $LocalizedData.RentalInstances = $License.RentalInstancesNumber
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Instance $($License.LicensedTo) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.TableInstanceUsage) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 25, 25, 25, 25
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                try {
                                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                                    $chartLabels = [string[]]$sampleData.Category
                                    $chartValues = [double[]]$sampleData.Value

                                    $statusCustomPalette = @('#DFF0D0', '#FFF3C4', '#FECDD1', '#ADACAF')

                                    $chartFileItem = New-PieChart -Title ' ' -Values $chartValues -Labels $chartLabels -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Vertical -LegendAlignment UpperRight -TitleFontBold -TitleFontSize 16

                                } catch {
                                    Write-PScriboMessage -IsWarning "Instance License Usage chart section: $($_.Exception.Message)"
                                }
                                if ($OutObj) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.InstanceUsageHeading {
                                        if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                            Image -Text $LocalizedData.ChartAltInstanceUsage -Align 'Center' -Percent 100 -Base64 $chartFileItem
                                        }
                                        BlankLine
                                        $OutObj | Table @TableParams
                                        #---------------------------------------------------------------------------------------------#
                                        #                                  Per Instance Section                                       #
                                        #---------------------------------------------------------------------------------------------#
                                        try {
                                            $Licenses = ($VbrLicenses | Select-Object -ExpandProperty InstanceLicenseSummary).Object
                                            if ($Licenses) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.PerInstanceHeading {
                                                    $OutObj = @()
                                                    try {
                                                        foreach ($License in $Licenses) {

                                                            $inObj = [ordered] @{
                                                                $LocalizedData.Type = $License.Type
                                                                $LocalizedData.Count = $License.Count
                                                                $LocalizedData.Multiplier = $License.Multiplier
                                                                $LocalizedData.UsedInstances = $License.UsedInstancesNumber
                                                            }
                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Per Instance Type $($License.LicensedTo) Section: $($_.Exception.Message)"
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TablePerInstance) - $VeeamBackupServer"
                                                        List = $false
                                                        ColumnWidths = 25, 25, 25, 25
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Instance License Usage Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Instance License Section: $($_.Exception.Message)"
                        }
                        #---------------------------------------------------------------------------------------------#
                        #                                  CPU Socket License Section                                 #
                        #---------------------------------------------------------------------------------------------#
                        try {
                            $Licenses = $VbrLicenses | Select-Object -ExpandProperty SocketLicenseSummary
                            if ($Licenses.LicensedSocketsNumber -gt 0) {
                                $OutObj = @()
                                try {
                                    foreach ($License in $Licenses) {

                                        $inObj = [ordered] @{
                                            $LocalizedData.LicensedSockets = $License.LicensedSocketsNumber
                                            $LocalizedData.UsedSocketsLicenses = $License.UsedSocketsNumber
                                            $LocalizedData.RemainingSocketsLicenses = $License.RemainingSocketsNumber
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "CPU Socket License Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.TableCPUSocket) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 33, 33, 34
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                try {
                                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                                    $chartLabels = [string[]]$sampleData.Category
                                    $chartValues = [double[]]$sampleData.Value

                                    $statusCustomPalette = @('#DFF0D0', '#FFF3C4', '#FECDD1', '#ADACAF')

                                    $chartFileItem = New-PieChart -Title ' ' -Values $chartValues -Labels $chartLabels -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Vertical -LegendAlignment UpperRight -TitleFontBold -TitleFontSize 16
                                } catch {
                                    Write-PScriboMessage -IsWarning "CPU Socket Usage chart section: $($_.Exception.Message)"
                                }
                                if ($OutObj) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.CPUSocketHeading {
                                        if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                            Image -Text $LocalizedData.ChartAltCPUSocket -Align 'Center' -Percent 100 -Base64 $chartFileItem
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "CPU Socket License Section: $($_.Exception.Message)"
                        }
                        #---------------------------------------------------------------------------------------------#
                        #                                  Capacity License Section                                   #
                        #---------------------------------------------------------------------------------------------#
                        try {
                            $Licenses = $VbrLicenses | Select-Object -ExpandProperty CapacityLicenseSummary
                            if ($Licenses.LicensedCapacityTb -gt 0) {
                                $OutObj = @()
                                try {
                                    foreach ($License in $Licenses) {

                                        $inObj = [ordered] @{
                                            $LocalizedData.LicensedCapacityTb = $License.LicensedCapacityTb
                                            $LocalizedData.UsedCapacityTb = $License.UsedCapacityTb
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Capacity License Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.TableCapacity) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                try {
                                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                                    $chartLabels = [string[]]$sampleData.Category
                                    $chartValues = [double[]]$sampleData.Value

                                    $statusCustomPalette = @('#DFF0D0', '#FFF3C4', '#FECDD1', '#ADACAF')

                                    $chartFileItem = New-PieChart -Title ' ' -Values $chartValues -Labels $chartLabels -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Vertical -LegendAlignment UpperRight -TitleFontBold -TitleFontSize 16
                                } catch {
                                    Write-PScriboMessage -IsWarning "Capacity License Usage chart section: $($_.Exception.Message)"
                                }
                                if ($OutObj) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.CapacityHeading {
                                        if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                            Image -Text $LocalizedData.ChartAltCapacity -Align 'Center' -Percent 100 -Base64 $chartFileItem
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Capacity License Section: $($_.Exception.Message)"
                        }
            }
        }
    }

    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'License information'
    }

}