
function Get-AbrVbrInfrastructureSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Infrastructure Summary.
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
        Write-PScriboMessage "Discovering Veeam VBR Infrastructure Summary from $System."
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
                $InstanceLicenses = ($VbrLicenses).InstanceLicenseSummary
                $SocketLicenses = ($VbrLicenses).SocketLicenseSummary
                $CapacityLicenses = ($VbrLicenses).CapacityLicenseSummary
                $WANAccels = (Get-VBRWANAccelerator).count
                try {
                    $ServiceProviders = (Get-VBRCloudProvider).count
                } Catch {
                    Write-PScriboMessage -IsWarning "Infrastructure Service Providers Summary Section: $($_.Exception.Message)"
                    $ServiceProviders = 0
                }
                try {
                    $SureBackupAGs = (Get-VBRApplicationGroup).count
                    $SureBackupVLs = (Get-VBRVirtualLab).count
                } Catch {
                    Write-PScriboMessage -IsWarning "Infrastructure SureBackup Summary Section: $($_.Exception.Message)"
                    $SureBackupAGs = 0
                    $SureBackupVLs = 0
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
            } catch {
                Write-PScriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "Backup Infrastructure Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($Options.EnableCharts) {
                try {
                    $inObj.Remove('Instance Licenses (Total/Used)')
                    $inObj.Remove('Socket Licenses (Total/Used)')
                    $inObj.Remove('Capacity Licenses (Total/Used)')
                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                    $chartFileItem = Get-PieChart -SampleData $sampleData -ChartName 'BackupInfrastructure' -XField 'Category' -YField 'Value' -ChartLegendName 'Infrastructure'
                } catch {
                    Write-PScriboMessage -IsWarning "Backup Infrastructure chart section: $($_.Exception.Message)"
                }
            }

            if ($OutObj) {
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Backup Infrastructure Inventory' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Backup Infrastructure - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}