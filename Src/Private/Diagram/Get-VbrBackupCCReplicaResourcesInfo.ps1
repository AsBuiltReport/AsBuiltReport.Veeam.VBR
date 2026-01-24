function Get-VbrBackupCCReplicaResourcesInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication cloud connect replica resources information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.6.37
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
        Write-Verbose -Message "Collecting Cloud Connect Replica Resources information from $($VBRServer)."
        try {

            $BackupCCReplicaResourcesInfo = @()

            if ($CloudObjects = Get-VBRCloudHardwarePlan | Sort-Object -Property Name) {
                foreach ($CloudObject in $CloudObjects) {

                    $AditionalInfo = [PSCustomObject] [ordered] @{
                        CPU = switch ([string]::IsNullOrEmpty($CloudObject.CPU)) {
                            $true { 'Unlimited' }
                            $false { "$([math]::Round($CloudObject.CPU / 1000, 1)) Ghz" }
                            default { '--' }
                        }
                        Memory = switch ([string]::IsNullOrEmpty($CloudObject.Memory)) {
                            $true { 'Unlimited' }
                            $false { ConvertTo-FileSizeString -Size (Convert-Size -From MB -To Bytes -Value $CloudObject.Memory) -RoundUnits 2 }
                            default { '--' }
                        }
                        Storage = ConvertTo-FileSizeString -Size (Convert-Size -From GB -To Bytes -Value ($CloudObject.Datastore.Quota | Measure-Object -Sum).Sum) -RoundUnits 2
                        Network = $CloudObject.NumberOfNetWithInternet + $CloudObject.NumberOfNetWithoutInternet
                        Platform = $CloudObject.Platform
                    }

                    $TempBackupCCReplicaResourcesInfo = [PSCustomObject]@{
                        Name = $CloudObject.Name
                        Label = Add-DiaNodeIcon -Name "$((Remove-SpecialChar -String $CloudObject.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Hardware_Resources' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                        Id = $CloudObject.Id
                        AditionalInfo = $AditionalInfo
                        Host = & {
                            $AditionalInfo = [pscustomobject]@{
                                Type = $CloudObject.Host.Type
                            }
                            if ($CloudObject.Host.Type -eq 'ESXi') {
                                $ViVersionString = if ($CloudObject.Host.Info.ViVersion) { $CloudObject.Host.Info.ViVersion.ToString() } else { 'Unknown' }
                                $AditionalInfo | Add-Member -MemberType NoteProperty -Name 'Version' -Value $ViVersionString
                            } elseif ($CloudObject.Host.Type -eq 'Cluster') {
                                $AditionalInfo | Add-Member -MemberType NoteProperty -Name 'DataCenter' -Value $CloudObject.Host.Path.Split('\')[1]
                            } elseif ($CloudObject.Host.Type -eq 'HvServer') {
                                $AditionalInfo | Add-Member -MemberType NoteProperty -Name 'Version' -Value $CloudObject.Host.Info.Info.split(' ')[3]
                            }
                            if ($CloudObject.Host.Type -eq 'Cluster' -or $CloudObject.Host.Type -eq 'ESXi') {
                                $IconType = 'VBR_ESXi_Server'
                            } elseif ($CloudObject.Host.Type -eq 'HvServer') {
                                $IconType = 'VBR_HyperV_Server'
                            } else {
                                $IconType = 'VBR_Esxi_AHV_HyperV_Server'
                            }
                            [pscustomobject]@{
                                Name = $CloudObject.Host.Name
                                Id = $CloudObject.Host.Id
                                Type = $CloudObject.Host.Type
                                Path = $CloudObject.Host.Path
                                IconType = $IconType
                                AditionalInfo = $AditionalInfo
                                Label = Add-DiaNodeIcon -Name "$((Remove-SpecialChar -String $CloudObject.Host.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Hardware_Resources' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                            }
                        }
                        Storage = & {
                            $CloudObject.Datastore | ForEach-Object {
                                $AditionalInfo = [PSCustomObject] [ordered] @{
                                    Quota = ConvertTo-FileSizeString -Size (Convert-Size -From GB -To Bytes -Value $_.Quota) -RoundUnits 2
                                    Platform = $_.Platform
                                    Datastore = & {
                                        if ($_.Platform -eq 'HyperV') {
                                            $_.Datastore
                                        } elseif ($_.Platform -eq 'VMWare') {
                                            $_.Datastore.Name
                                        } else {
                                            'Unknown'
                                        }
                                    }
                                }
                                [PSCustomObject]@{
                                    Name = $_.FriendlyName
                                    Id = $_.Id
                                    Quota = ConvertTo-FileSizeString -Size (Convert-Size -From GB -To Bytes -Value $_.Quota) -RoundUnits 2
                                    Platform = $_.Platform
                                    Datastore = $_.Datastore.Name
                                    AditionalInfo = $AditionalInfo
                                    Label = Add-DiaNodeIcon -Name $_.FriendlyName -IconType 'VBR_Cloud_Storage' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold

                                }
                            }
                        }
                    }

                    $BackupCCReplicaResourcesInfo += $TempBackupCCReplicaResourcesInfo
                }
            }

            return $BackupCCReplicaResourcesInfo
        } catch {
            Write-Verbose -Message $_.Exception.Message
            return $BackupCCReplicaResourcesInfo
        }
    }
    end {}
}