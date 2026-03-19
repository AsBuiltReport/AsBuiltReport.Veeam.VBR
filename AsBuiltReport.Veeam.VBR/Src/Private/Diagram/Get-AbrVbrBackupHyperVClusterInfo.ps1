function Get-AbrBackupHyperVClusterInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication hyperv hypervisor information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.9.0
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
        Write-PScriboMessage "Collecting HyperV HyperVisor information from $($VBRServer)."
        try {
            $HyObjs = Get-VBRServer | Where-Object { $_.Type -eq 'HvCluster' }
            $HyObjsInfo = @()
            if ($HyObjs) {
                foreach ($HyObj in $HyObjs) {
                    try {
                        $HvHosts = Get-VBRServer | Where-Object { $_.Type -eq 'HvServer' -and $_.ParentId -match $HyObj.Id }
                        $Rows = @{
                            IP = Get-AbrNodeIP -Hostname $HyObj.Info.DnsName
                        }

                        $TempHyObjsInfo = [PSCustomObject]@{
                            Name = $HyObj.Info.HostInstanceIdV2
                            Label = Add-NodeIcon -Name $HyObj.Name -IconType 'VBR_HyperV_Cluster' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                            AditionalInfo = $Rows
                            Childs = & {
                                foreach ($HvHost in $HvHosts) {
                                    $Rows = @{
                                        IP = Get-AbrNodeIP -Hostname $HvHost.Info.DnsName
                                        Version = $HvHost.Info.HvVersion
                                    }
                                    [PSCustomObject]@{
                                        Name = $HvHost.Name
                                        Label = Add-NodeIcon -Name $HvHost.Name -IconType 'VBR_HyperV_Server' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                                        AditionalInfo = $Rows
                                    }
                                }
                            }
                        }
                        $HyObjsInfo += $TempHyObjsInfo
                    } catch {
                        Write-PScriboMessage $_.Exception.Message
                    }
                }
            }

            return $HyObjsInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}