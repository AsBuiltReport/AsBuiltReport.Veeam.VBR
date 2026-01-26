function Get-AbrBackupWanAccelInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication wan accelerator information.
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
        Write-Verbose -Message "Collecting Wan Accelerator information from $($VBRServer)."
        try {
            $WANACCELS = Get-VBRWANAccelerator
            $WANACCELInfo = @()
            if ($WANACCELS) {
                foreach ($WANACCEL in $WANACCELS) {

                    $AdditionalInfo = [PSCustomObject]@{
                        IP = Get-NodeIP -Hostname $WANACCEL.Name
                        TrafficPort = "$($WANAccel.GetWaTrafficPort())/TCP"
                        'Cache Path' = & {
                            if ($WANAccel.FindWaHostComp().Options.CachePath) {
                                $WANAccel.FindWaHostComp().Options.CachePath
                            } else {
                                'N/A'
                            }
                        }
                        'Cache Size' = & {
                            if ($WANAccel.FindWaHostComp().Options.MaxCacheSize) {
                                "$($WANAccel.FindWaHostComp().Options.MaxCacheSize) $($WANAccel.FindWaHostComp().Options.SizeUnit)"
                            } else {
                                'N/A'
                            }
                        }
                    }



                    $TempWANACCELInfo = [PSCustomObject]@{
                        Name = "$($WANACCEL.Name.toUpper().split('.')[0])";
                        Label = Add-DiaNodeIcon -Name "$($WANACCEL.Name.toUpper().split('.')[0])" -IconType 'VBR_Wan_Accel' -Align 'Center' -Rows $AdditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontBold
                        AditionalInfo = $AdditionalInfo
                        IconType = 'VBR_Wan_Accel'
                    }
                    $WANACCELInfo += $TempWANACCELInfo
                }
            }

            return $WANACCELInfo
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}