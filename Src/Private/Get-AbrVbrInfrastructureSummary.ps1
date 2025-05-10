
function Get-AbrVbrInfrastructureSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Infrastructure Summary'
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
                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
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

            $OutObj | Table @TableParams

        } catch {
            Write-PScriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage 'Infrastructure Summary'

        }
    }
    end {}

}