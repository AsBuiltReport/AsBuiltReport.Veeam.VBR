
function Get-AbrVbrInfrastructureSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Infrastructure Summary.
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
        Write-PscriboMessage "Discovering Veeam VBR Infrastructure Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
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
                    $SureBackupAGs = (Get-VBRApplicationGroup).count
                    $SureBackupVLs = (Get-VBRVirtualLab).count
                    $inObj = [ordered] @{
                        'Number of Backup Proxies' = $BackupProxies
                        'Number of Managed Servers' = $BackupServers
                        'Number of Backup Repositories' = $BackupRepo
                        'Number of SOBR Repositories' = $SOBRRepo
                        'Number of Object Repository' = $ObjectStorageRepo
                        'Number of WAN Accelerator' = $WANAccels
                        'Number of SureBackup Application Group' = $SureBackupAGs
                        'Number of SureBackup Virtual Lab' = $SureBackupVLs
                        'Number of Locations' = $Locations
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
                    Name = "Executive Summary - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                    List = $true
                    ColumnWidths = 50, 50
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}