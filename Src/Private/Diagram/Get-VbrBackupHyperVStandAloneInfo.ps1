function Get-VbrBackupHyperVStandAloneInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication hyperv hypervisor information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.6.36
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
        Write-Verbose -Message "Collecting HyperV HyperVisor information from $($VBRServer)."
        try {
            $HyObjs = Get-VBRServer | Where-Object { $_.Type -eq 'HvServer' -and $_.Parentid -eq '00000000-0000-0000-0000-000000000000' }
            $HyObjsInfo = @()
            if ($HyObjs) {
                foreach ($HyObj in $HyObjs) {
                    try {
                        $Rows = @{
                            IP = Get-NodeIP -Hostname $HyObj.Info.DnsName
                            Version = switch ([string]::IsNullOrEmpty($HyObj.Info.Info)) {
                                $true { 'Unknown' }
                                $false { $HyObj.Info.Info.Split('()')[1].split('build:')[0] }
                                default { 'Unknown' }
                            }
                        }

                        $TempHyObjsInfo = [PSCustomObject]@{
                            Name = $HyObj.Name
                            Label = Add-DiaNodeIcon -Name $HyObj.Name -IconType 'VBR_HyperV_Server' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontBold
                            AditionalInfo = $Rows
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