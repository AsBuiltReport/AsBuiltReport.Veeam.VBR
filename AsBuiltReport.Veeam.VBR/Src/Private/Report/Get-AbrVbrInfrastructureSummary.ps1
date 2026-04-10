
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
        $LocalizedData = $reportTranslate.GetAbrVbrInfrastructureSummary
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
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
                } catch {
                    Write-PScriboMessage -IsWarning "Infrastructure Service Providers Summary Section: $($_.Exception.Message)"
                    $ServiceProviders = 0
                }
                try {
                    $SureBackupAGs = (Get-VBRApplicationGroup).count
                    $SureBackupVLs = (Get-VBRVirtualLab).count
                } catch {
                    Write-PScriboMessage -IsWarning "Infrastructure SureBackup Summary Section: $($_.Exception.Message)"
                    $SureBackupAGs = 0
                    $SureBackupVLs = 0
                }
                $inObj = [ordered] @{
                    $LocalizedData.BackupProxies = $BackupProxies
                    $LocalizedData.ManagedServers = $BackupServers
                    $LocalizedData.BackupRepositories = $BackupRepo
                    $LocalizedData.SOBRRepositories = $SOBRRepo
                    $LocalizedData.ObjectRepository = $ObjectStorageRepo
                    $LocalizedData.WANAccelerator = $WANAccels
                    $LocalizedData.CloudServiceProviders = $ServiceProviders
                    $LocalizedData.SureBackupApplicationGroup = $SureBackupAGs
                    $LocalizedData.SureBackupVirtualLab = $SureBackupVLs
                    $LocalizedData.Locations = $Locations
                    $LocalizedData.InstanceLicenses = "$($InstanceLicenses.LicensedInstancesNumber)/$($InstanceLicenses.UsedInstancesNumber)"
                    $LocalizedData.SocketLicenses = "$($SocketLicenses.LicensedSocketsNumber)/$($SocketLicenses.UsedSocketsNumber)"
                    $LocalizedData.CapacityLicenses = "$($CapacityLicenses.LicensedCapacityTb)TB/$($CapacityLicenses.UsedCapacityTb)TB"
                }
                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
            } catch {
                Write-PScriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }

            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph $LocalizedData.Paragraph
                BlankLine
                $OutObj | Table @TableParams
            }

        } catch {
            Write-PScriboMessage -IsWarning "Infrastructure Summary Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage 'Infrastructure Summary'

        }
    }
    end {}

}
