function Get-AbrBackupvSphereInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication vsphere hypervisor information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        1.0.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]

    param
    (

    )
    process {
        try {
            $HyObjs = Get-VBRServer | Where-Object { $_.Type -eq 'VC' }
            $HyObjsInfo = @()
            if ($HyObjs) {
                foreach ($HyObj in $HyObjs) {
                    Write-Verbose -Message "Collecting vSphere HyperVisor information from $($HyObj.Name)."
                    try {
                        $ESXis = Invoke-FindVBRViEntityWithTimeout -Server $HyObj.Name -HostsAndClustersOnly | Where-Object { ($_.type -eq 'esx') }

                        $Rows = @{
                            IP = Get-AbrNodeIP -Hostname $HyObj.Info.DnsName
                            Version = switch ([string]::IsNullOrEmpty($HyObj.Info.ViVersion)) {
                                $true { 'Unknown' }
                                default { $HyObj.Info.ViVersion }
                            }
                        }

                        $TempHyObjsInfo = [PSCustomObject]@{
                            Name = $HyObj.Name
                            Label = Add-NodeIcon -Name $HyObj.Name -IconType 'VBR_vCenter_Server' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                            AditionalInfo = $Rows
                            Childs = & {
                                $VIClusters = Invoke-FindVBRViEntityWithTimeout -Server $HyObj.Name -HostsAndClustersOnly | Where-Object { ($_.type -eq 'cluster') }

                                foreach ($Cluster in $VIClusters) {
                                    [PSCustomObject]@{
                                        Name = $Cluster.Name
                                        Label = Add-NodeIcon -Name $Cluster.Name -IconType 'VBR_vSphere_Cluster' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                                        EsxiHost = foreach ($Esxi in $ESXis | Where-Object { $_.path -match $Cluster.Name }) {
                                            $Rows = @{
                                                IP = Get-AbrNodeIP -Hostname $Esxi.Info.DnsName
                                                Version = switch ([string]::IsNullOrEmpty($Esxi.Info.ViVersion)) {
                                                    $true { 'Unknown' }
                                                    default { $Esxi.Info.ViVersion }
                                                }
                                            }
                                            [PSCustomObject]@{
                                                Name = $Esxi.Name
                                                Label = Add-NodeIcon -Name $Esxi.Name -IconType 'VBR_ESXi_Server' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                                                AditionalInfo = $Rows
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        $HyObjsInfo += $TempHyObjsInfo
                    } catch {
                        Write-Verbose -Message $_.Exception.Message
                    }
                }
            }

            return $HyObjsInfo
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}