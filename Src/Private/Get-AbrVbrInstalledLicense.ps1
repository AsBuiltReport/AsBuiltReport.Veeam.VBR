
function Get-AbrVbrInstalledLicense {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Infrastructure Installed Licenses
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.4
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
        Write-PscriboMessage "Discovering Veeam V&R License information from $System."
    }

    process {
        try {
            if ((Get-VBRInstalledLicense).count -gt 0) {
                Section -Style Heading3 'License Information' {
                    Paragraph "The following section provides a summary about the installed licenses"
                    BlankLine
                    try {
                        $Licenses = Get-VBRInstalledLicense
                        if ($Licenses) {
                            Section -Style Heading4 'Installed License Information' {
                                $OutObj = @()
                                try {
                                    $Licenses = Get-VBRInstalledLicense
                                    foreach ($License in $Licenses) {
                                        Write-PscriboMessage "Discovered $($License.Edition) license."
                                        $inObj = [ordered] @{
                                            'Licensed To' = $License.LicensedTo
                                            'Edition' = $License.Edition
                                            'Type' = $License.Type
                                            'Status' = $License.Status
                                            'Expiration Date' = Switch ($License.ExpirationDate) {
                                                "" {"-"; break}
                                                $Null {'-'; break}
                                                default {$License.ExpirationDate.ToLongDateString()}
                                            }
                                            'Support Id' = $License.SupportId
                                            'Support Expiration Date' = Switch ($License.SupportExpirationDate) {
                                                "" {"-"; break}
                                                $Null {'-'; break}
                                                default {$License.SupportExpirationDate.ToLongDateString()}
                                            }
                                            'Auto Update Enabled' = ConvertTo-TextYN $License.AutoUpdateEnabled
                                            'Free Agent Instance' = ConvertTo-TextYN $License.FreeAgentInstanceConsumptionEnabled
                                            'Cloud Connect' = $License.CloudConnect
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }

                                if ($HealthCheck.Infrastructure.Status) {
                                    $OutObj | Where-Object { $_.'Status' -eq 'Expired'} | Set-Style -Style Critical -Property 'Status'
                                    $OutObj | Where-Object { $_.'Type' -eq 'Evaluation'} | Set-Style -Style Warning -Property 'Type'
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
                                    $Licenses = Get-VBRInstalledLicense | Select-Object -ExpandProperty InstanceLicenseSummary
                                    if ($Licenses.LicensedInstancesNumber -gt 0) {
                                        $OutObj = @()
                                        try {
                                            foreach ($License in $Licenses) {
                                                Write-PscriboMessage "Discovered $($Licenses.LicensedInstancesNumber) Instance licenses."
                                                $inObj = [ordered] @{
                                                    'Instances Capacity' = $License.LicensedInstancesNumber
                                                    'Used Instances' = $License.UsedInstancesNumber
                                                    'New Instances' = $License.NewInstancesNumber
                                                    'Rental Instances' = $License.RentalInstancesNumber
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                            $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category';  Expression = {$_.key}},@{ Name = 'Value';  Expression = {$_.value}} | Sort-Object -Property 'Category'

                                            $exampleChart = New-Chart -Name InstanceLicenseUsage -Width 600 -Height 400

                                            $addChartAreaParams = @{
                                                Chart = $exampleChart
                                                Name  = 'exampleChartArea'
                                            }
                                            $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                                            $addChartSeriesParams = @{
                                                Chart             = $exampleChart
                                                ChartArea         = $exampleChartArea
                                                Name              = 'exampleChartSeries'
                                                XField            = 'Category'
                                                YField            = 'Value'
                                                Palette           = 'Green'
                                                ColorPerDataPoint = $true
                                            }
                                            $exampleChartSeries = $sampleData | Add-PieChartSeries @addChartSeriesParams -PassThru

                                            $addChartLegendParams = @{
                                                Chart             = $exampleChart
                                                Name              = 'Category'
                                                TitleAlignment    = 'Center'
                                            }
                                            Add-ChartLegend @addChartLegendParams

                                            $addChartTitleParams = @{
                                                Chart     = $exampleChart
                                                ChartArea = $exampleChartArea
                                                Name      = ' '
                                                Text      = ' '
                                                Font      = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                                            }
                                            Add-ChartTitle @addChartTitleParams

                                            $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $($_.Exception.Message)
                                        }
                                        if ($OutObj) {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'Instance License Usage' {
                                                if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                                    Image -Text 'Instance License Usage - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
                                                }
                                                $OutObj | Table @TableParams
                                                #---------------------------------------------------------------------------------------------#
                                                #                                  Per Instance Section                                       #
                                                #---------------------------------------------------------------------------------------------#
                                                try {
                                                    $Licenses = (Get-VBRInstalledLicense | Select-Object -ExpandProperty InstanceLicenseSummary).Object
                                                    if ($Licenses) {
                                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Per Instance Type License Usage' {
                                                            $OutObj = @()
                                                            try {
                                                                foreach ($License in $Licenses) {
                                                                    Write-PscriboMessage "Discovered $($Licenses.Type) Instance licenses."
                                                                    $inObj = [ordered] @{
                                                                        'Type' = $License.Type
                                                                        'Count' = $License.Count
                                                                        'Multiplier' = $License.Multiplier
                                                                        'Used Instances' = $License.UsedInstancesNumber
                                                                    }
                                                                    $OutObj += [pscustomobject]$inobj
                                                                }
                                                            }
                                                            catch {
                                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                #---------------------------------------------------------------------------------------------#
                                #                                  CPU Socket License Section                                 #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    $Licenses = Get-VBRInstalledLicense | Select-Object -ExpandProperty SocketLicenseSummary
                                    if ($Licenses.LicensedSocketsNumber -gt 0) {
                                        $OutObj = @()
                                        try {
                                            foreach ($License in $Licenses) {
                                                Write-PscriboMessage "Discovered $($Licenses.LicensedSocketsNumber) CPU Socket licenses."
                                                $inObj = [ordered] @{
                                                    'Licensed Sockets' = $License.LicensedSocketsNumber
                                                    'Used Sockets Licenses' = $License.UsedSocketsNumber
                                                    'Remaining Sockets Licenses' = $License.RemainingSocketsNumber
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                            $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category';  Expression = {$_.key}},@{ Name = 'Value';  Expression = {$_.value}} | Sort-Object -Property 'Category'

                                            $exampleChart = New-Chart -Name CPUSocketUsage -Width 600 -Height 400

                                            $addChartAreaParams = @{
                                                Chart = $exampleChart
                                                Name  = 'exampleChartArea'
                                            }
                                            $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                                            $addChartSeriesParams = @{
                                                Chart             = $exampleChart
                                                ChartArea         = $exampleChartArea
                                                Name              = 'exampleChartSeries'
                                                XField            = 'Category'
                                                YField            = 'Value'
                                                Palette           = 'Green'
                                                ColorPerDataPoint = $true
                                            }
                                            $exampleChartSeries = $sampleData | Add-PieChartSeries @addChartSeriesParams -PassThru

                                            $addChartLegendParams = @{
                                                Chart             = $exampleChart
                                                Name              = 'Category'
                                                TitleAlignment    = 'Center'
                                            }
                                            Add-ChartLegend @addChartLegendParams

                                            $addChartTitleParams = @{
                                                Chart     = $exampleChart
                                                ChartArea = $exampleChartArea
                                                Name      = ' '
                                                Text      = ' '
                                                Font      = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                                            }
                                            Add-ChartTitle @addChartTitleParams

                                            $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $($_.Exception.Message)
                                        }
                                        if ($OutObj) {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'CPU Socket License Usage' {
                                                if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                                    Image -Text 'CPU Socket License Usage - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
                                                }
                                                $OutObj | Table @TableParams
                                            }
                                        }
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                                  Capacity License Section                                   #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    $Licenses = Get-VBRInstalledLicense | Select-Object -ExpandProperty CapacityLicenseSummary
                                    if ($Licenses.LicensedCapacityTb -gt 0) {
                                        $OutObj = @()
                                        try {
                                            foreach ($License in $Licenses) {
                                                Write-PscriboMessage "Discovered $($Licenses.LicensedCapacityTb) Capacity licenses."
                                                $inObj = [ordered] @{
                                                    'Licensed Capacity in TB' = $License.LicensedCapacityTb
                                                    'Used Capacity in TB' = $License.UsedCapacityTb
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                            $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category';  Expression = {$_.key}},@{ Name = 'Value';  Expression = {$_.value}} | Sort-Object -Property 'Category'

                                            $exampleChart = New-Chart -Name CapacityLicenseUsage -Width 600 -Height 400

                                            $addChartAreaParams = @{
                                                Chart = $exampleChart
                                                Name  = 'exampleChartArea'
                                            }
                                            $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                                            $addChartSeriesParams = @{
                                                Chart             = $exampleChart
                                                ChartArea         = $exampleChartArea
                                                Name              = 'exampleChartSeries'
                                                XField            = 'Category'
                                                YField            = 'Value'
                                                Palette           = 'Green'
                                                ColorPerDataPoint = $true
                                            }
                                            $exampleChartSeries = $sampleData | Add-PieChartSeries @addChartSeriesParams -PassThru

                                            $addChartLegendParams = @{
                                                Chart             = $exampleChart
                                                Name              = 'Category'
                                                TitleAlignment    = 'Center'
                                            }
                                            Add-ChartLegend @addChartLegendParams

                                            $addChartTitleParams = @{
                                                Chart     = $exampleChart
                                                ChartArea = $exampleChartArea
                                                Name      = ' '
                                                Text      = ' '
                                                Font      = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                                            }
                                            Add-ChartTitle @addChartTitleParams

                                            $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $($_.Exception.Message)
                                        }
                                        if ($OutObj) {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'Capacity License Usage' {
                                                if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                                                    Image -Text 'Capacity License Usage - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
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
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
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