function Get-AbrBackupCCvCDReplicaResourcesInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication cloud connect vcd replica resources information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.8.24
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]

    param (
    )

    process {
        Write-PScriboMessage "Collecting Cloud Connect vCD Replica Resources information from $($VBRServer)."
        try {

            $BackupCCvCDReplicaResourcesInfo = @()

            if ($CloudObjects = (Get-VBRCloudTenant | Where-Object { $_.vCDReplicationResourcesEnabled }).vCDReplicationResource.OrganizationvDCOptions) {
                foreach ($CloudObject in $CloudObjects) {

                    $AditionalInfo = [PSCustomObject] [ordered] @{
                        'Used CPU' = switch ([string]::IsNullOrEmpty($CloudObject.UsedCPU)) {
                            $true { 'Unlimited' }
                            $false { "$([math]::Round($CloudObject.UsedCPU / 1000, 1)) Ghz" }
                            default { '--' }
                        }
                        'Used Memory' = switch ([string]::IsNullOrEmpty($CloudObject.UsedMemory)) {
                            $true { 'Unlimited' }
                            $false { ConvertTo-FileSizeString -Size (Convert-Size -From MB -To Bytes -Value $CloudObject.UsedMemory) -RoundUnits 2 }
                            default { '--' }
                        }
                        'Allocation Model' = switch ($CloudObject.AllocationModel) {
                            'AllocationPool' { 'Allocation Pool' }
                            'PayAsYouGo' { 'Pay As You Go' }
                            'ReservationPool' { 'Reservation Pool' }
                            default { 'Unknown' }
                        }
                        'Enabled' = switch ($CloudObject.Enabled) {
                            $true { 'Yes' }
                            $false { 'No' }
                            default { 'Unknown' }
                        }
                    }

                    $TempBackupCCvCDReplicaResourcesInfo = [PSCustomObject]@{
                        Name = $CloudObject.OrganizationvDCName
                        Label = Add-DiaNodeIcon -Name $CloudObject.OrganizationvDCName -IconType 'VBR_Cloud_Connect_vCD' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                        Id = $CloudObject.OrganizationvDCID
                        AditionalInfo = $AditionalInfo
                        WanAcceleration = & {
                            if ($CloudObject.WANAccelarationEnabled) {
                                if ($CloudObject.WANAccelerator.Name) {
                                    $WANName = $CloudObject.WANAccelerator.Name.split('.')[0]
                                    Get-AbrBackupWanAccelInfo | Where-Object { $_.Name -eq $WANName }
                                }
                            }
                        }
                    }

                    $BackupCCvCDReplicaResourcesInfo += $TempBackupCCvCDReplicaResourcesInfo
                }
            }

            return $BackupCCvCDReplicaResourcesInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
            return $BackupCCvCDReplicaResourcesInfo
        }
    }
    end {}
}