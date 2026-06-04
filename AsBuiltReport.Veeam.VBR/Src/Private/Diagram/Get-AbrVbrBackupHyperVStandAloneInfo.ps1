function Get-AbrBackupHyperVStandAloneInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication hyperv hypervisor information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        1.0.3
        Author:         AsBuiltReport Organization
        Twitter:        @asbuiltreport
        Github:         asbuiltreport
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]

    param
    (

    )
    process {
        Write-PScriboMessage "Collecting HyperV Standalone HyperVisor information from $($VBRServer)."
        try {
            $HyObjs = Get-VBRServer | Where-Object { $_.Type -eq 'HvServer' -and $_.Parentid -eq '00000000-0000-0000-0000-000000000000' }
            $HyObjsInfo = @()
            if ($HyObjs) {
                foreach ($HyObj in $HyObjs) {
                    try {
                        $Rows = @{
                            IP = Get-AbrNodeIP -Hostname $HyObj.Info.DnsName
                            Version = switch ([string]::IsNullOrEmpty($HyObj.Info.Info)) {
                                $true { 'Unknown' }
                                $false { try { $HyObj.Info.Info.Split('(')[1].split('build:')[0] } catch { 'Unknown' } }
                                default { 'Unknown' }
                            }
                        }

                        $TempHyObjsInfo = [PSCustomObject]@{
                            Name = $HyObj.Name
                            Label = Add-NodeIcon -Name $HyObj.Name -IconType 'VBR_HyperV_Server' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor
                            AditionalInfo = $Rows
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