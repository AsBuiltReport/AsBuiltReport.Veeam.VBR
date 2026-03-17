function Get-AbrBackupvSphereStandAloneInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication vsphere Hypervisor information.
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

    param
    (

    )
    process {
        Write-PScriboMessage "Collecting vSphere HyperVisor information from $($VBRServer)."
        try {
            $ViObjs = Get-VBRServer | Where-Object { $_.Type -eq 'ESXi' -and $_.Parentid -eq '00000000-0000-0000-0000-000000000000' }
            $ViObjsInfo = @()
            if ($ViObjs) {
                foreach ($ViObj in $ViObjs) {
                    try {
                        $Rows = @{
                            IP = Get-AbrNodeIP -Hostname $ViObj.Info.DnsName
                            Version = switch ([string]::IsNullOrEmpty($ViObj.Info.ViVersion)) {
                                $true { 'Unknown' }
                                $false { $ViObj.Info.ViVersion }
                                default { 'Unknown' }
                            }
                        }

                        $TempViObjsInfo = [PSCustomObject]@{
                            Name = $ViObj.Name
                            Label = Add-NodeIcon -Name $ViObj.Name -IconType 'VBR_ESXi_Server' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontBold
                            AditionalInfo = $Rows
                        }
                        $ViObjsInfo += $TempViObjsInfo
                    } catch {
                        Write-PScriboMessage $_.Exception.Message
                    }
                }
            }

            return $ViObjsInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}