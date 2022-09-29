
function Get-AbrVbrInfrastructureSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Infrastructure Summary.
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
        Write-PscriboMessage "Discovering Veeam VBR Infrastructure Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $BackupServers = (Get-VBRServer).Count
                $BackupProxies = (Get-VBRViProxy).count + (Get-VBRHvProxy).count
                $BackupRepo = (Get-VBRBackupRepository).count
                $SOBRRepo = (Get-VBRBackupRepository -ScaleOut).count
                $ObjectStorageRepo = (Get-VBRObjectStorageRepository).count
                $Locations = (Get-VBRLocation).count
                $InstanceLicenses = (Get-VBRInstalledLicense).InstanceLicenseSummary
                $SocketLicenses = (Get-VBRInstalledLicense).SocketLicenseSummary
                $CapacityLicenses = (Get-VBRInstalledLicense).CapacityLicenseSummary
                $WANAccels = (Get-VBRWANAccelerator).count
                $ServiceProviders = (Get-VBRCloudProvider).count
                try {
                    $SureBackupAGs = (Get-VBRApplicationGroup).count
                    $SureBackupVLs = (Get-VBRVirtualLab).count
                }
                Catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }
                $inObj = [ordered] @{
                    'Backup Proxies' = $BackupProxies
                    'Managed Servers' = $BackupServers
                    'Backup Repositories' = $BackupRepo
                    'SOBR Repositories' = $SOBRRepo
                    'Object Repository' = $ObjectStorageRepo
                    'WAN Accelerator' = $WANAccels
                    'Cloud Service Providers' = $ServiceProviders
                    'SureBackup Application Group' = $SureBackupAGs
                    'SureBackup Virtual Lab' = $SureBackupVLs
                    'Locations' = $Locations
                    'Instance Licenses (Total/Used)' = "$($InstanceLicenses.LicensedInstancesNumber)/$($InstanceLicenses.UsedInstancesNumber)"
                    'Socket Licenses (Total/Used)' = "$($SocketLicenses.LicensedSocketsNumber)/$($SocketLicenses.UsedSocketsNumber)"
                    'Capacity Licenses (Total/Used)' = "$($CapacityLicenses.LicensedCapacityTb)TB/$($CapacityLicenses.UsedCapacityTb)TB"
                }
                $OutObj += [pscustomobject]$inobj
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }

            $TableParams = @{
                Name = "Backup Infrastructure Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            try {
                $inObj.Remove('Instance Licenses (Total/Used)')
                $inObj.Remove('Socket Licenses (Total/Used)')
                $inObj.Remove('Capacity Licenses (Total/Used)')
                $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category';  Expression = {$_.key}},@{ Name = 'Value';  Expression = {$_.value}} | Sort-Object -Property 'Category'

                $exampleChart = New-Chart -Name BackupInfrastructure -Width 600 -Height 400

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
                    Name              = 'Infrastructure'
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
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Backup Infrastructure Inventory' {
                    if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Backup Infrastructure - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}