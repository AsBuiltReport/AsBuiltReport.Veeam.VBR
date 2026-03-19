
function Get-AbrVbrInstalledLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Infrastructure Installed Licenses
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.24
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
        Show-AbrDebugExecutionTime -Start -TitleMessage 'License information'
    }

    process {
        if ($VbrLicenses) {
            Section -Style Heading3 'License Information' {
                Paragraph 'The following section provides a summary of the Veeam Backup & Replication licenses installed on this server, including edition, expiration date, and instance usage.'
                BlankLine
                try {
                    Section -Style Heading4 'Installed License Information' {
                        $OutObj = @()
                        try {
                            foreach ($License in $VbrLicenses) {

                                $inObj = [ordered] @{
                                    'Licensed To' = $License.LicensedTo
                                    'Edition' = $License.Edition
                                    'Type' = $License.Type
                                    'Status' = $License.Status
                                    'Expiration Date' = switch ($License.ExpirationDate) {
                                        '' { '--'; break }
                                        $Null { '--'; break }
                                        default { $License.ExpirationDate.ToLongDateString() }
                                    }
                                    'Support Id' = $License.SupportId
                                    'Support Expiration Date' = switch ($License.SupportExpirationDate) {
                                        '' { '--'; break }
                                        $Null { '--'; break }
                                        default { $License.SupportExpirationDate.ToLongDateString() }
                                    }
                                    'Auto Update Enabled' = $License.AutoUpdateEnabled
                                    'Free Agent Instance' = $License.FreeAgentInstanceConsumptionEnabled
                                    'Cloud Connect' = $License.CloudConnect
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Installed License Information $($License.LicensedTo) Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.Status) {
                            $OutObj | Where-Object { $_.'Status' -eq 'Expired' } | Set-Style -Style Critical -Property 'Status'
                            $OutObj | Where-Object { $_.'Type' -eq 'Evaluation' } | Set-Style -Style Warning -Property 'Type'
                        }

                        $TableParams = @{
                            Name = "Licenses - $VeeamBackupServer"
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
                                            'Instances Capacity' = $License.LicensedInstancesNumber
                                            'Used Instances' = $License.UsedInstancesNumber
                                            'New Instances' = $License.NewInstancesNumber
                                            'Rental Instances' = $License.RentalInstancesNumber
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Instance $($License.LicensedTo) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "Instance License Usage - $VeeamBackupServer"
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

                                    $statusCustomPalette = @('#DFF0D0', '#FFF4C7', '#FEDDD7', '#878787')

                                    $chartFileItem = New-PieChart -Title ' ' -Values $chartValues -Labels $chartLabels -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Vertical -LegendAlignment UpperRight -TitleFontBold -TitleFontSize 16

                                } catch {
                                    Write-PScriboMessage -IsWarning "Instance License Usage chart section: $($_.Exception.Message)"
                                }
                                if ($OutObj) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Instance License Usage' {
                                        if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                            Image -Text 'Instance License Usage - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                                        }
                                        BlankLine
                                        $OutObj | Table @TableParams
                                        #---------------------------------------------------------------------------------------------#
                                        #                                  Per Instance Section                                       #
                                        #---------------------------------------------------------------------------------------------#
                                        try {
                                            $Licenses = ($VbrLicenses | Select-Object -ExpandProperty InstanceLicenseSummary).Object
                                            if ($Licenses) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Per Instance Type License Usage' {
                                                    $OutObj = @()
                                                    try {
                                                        foreach ($License in $Licenses) {

                                                            $inObj = [ordered] @{
                                                                'Type' = $License.Type
                                                                'Count' = $License.Count
                                                                'Multiplier' = $License.Multiplier
                                                                'Used Instances' = $License.UsedInstancesNumber
                                                            }
                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Per Instance Type $($License.LicensedTo) Section: $($_.Exception.Message)"
                                                    }

                                                    $TableParams = @{
                                                        Name = "Per Instance Type - $VeeamBackupServer"
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
                                            'Licensed Sockets' = $License.LicensedSocketsNumber
                                            'Used Sockets Licenses' = $License.UsedSocketsNumber
                                            'Remaining Sockets Licenses' = $License.RemainingSocketsNumber
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "CPU Socket License Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "CPU Socket Usage - $VeeamBackupServer"
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

                                    $statusCustomPalette = @('#DFF0D0', '#FFF4C7', '#FEDDD7', '#878787')

                                    $chartFileItem = New-PieChart -Title ' ' -Values $chartValues -Labels $chartLabels -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Vertical -LegendAlignment UpperRight -TitleFontBold -TitleFontSize 16
                                } catch {
                                    Write-PScriboMessage -IsWarning "CPU Socket Usage chart section: $($_.Exception.Message)"
                                }
                                if ($OutObj) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'CPU Socket License Usage' {
                                        if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                            Image -Text 'CPU Socket License Usage - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
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
                                            'Licensed Capacity in TB' = $License.LicensedCapacityTb
                                            'Used Capacity in TB' = $License.UsedCapacityTb
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Capacity License Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "Capacity License Usage - $VeeamBackupServer"
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

                                    $statusCustomPalette = @('#DFF0D0', '#FFF4C7', '#FEDDD7', '#878787')

                                    $chartFileItem = New-PieChart -Title ' ' -Values $chartValues -Labels $chartLabels -EnableCustomColorPalette -CustomColorPalette $statusCustomPalette -Width 600 -Height 400 -Format base64 -EnableLegend -LegendOrientation Vertical -LegendAlignment UpperRight -TitleFontBold -TitleFontSize 16
                                } catch {
                                    Write-PScriboMessage -IsWarning "Capacity License Usage chart section: $($_.Exception.Message)"
                                }
                                if ($OutObj) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Capacity License Usage' {
                                        if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                            Image -Text 'Capacity License Usage - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Capacity License Section: $($_.Exception.Message)"
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "License Information Section: $($_.Exception.Message)"
                }
            }
        }
    }

    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'License information'
    }

}