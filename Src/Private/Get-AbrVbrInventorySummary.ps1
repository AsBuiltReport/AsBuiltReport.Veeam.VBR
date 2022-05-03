
function Get-AbrVbrInventorySummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Inventory Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.1
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
        Write-PscriboMessage "Discovering Veeam VBR Inventory Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $vCenter = Get-VBRServer | Where-Object {$_.Type -eq 'VC'}
                    $ESXi = Get-VBRServer | Where-Object {$_.Type -eq 'ESXi'}
                    $HvCluster = Get-VBRServer | Where-Object {$_.Type -eq 'HvCluster'}
                    $HvServer = Get-VBRServer | Where-Object {$_.Type -eq 'HvServer'}
                    $ProtectionGroups = Get-VBRProtectionGroup
                    $Shares = Get-VBRNASServer
                    $inObj = [ordered] @{
                        'Number of vCenter Servers' = $vCenter.Count
                        'Number of ESXi Servers' = $ESXi.Count
                        'Number of Hyper-V Clusters' = $HvCluster.Count
                        'Number of Hyper-V Servers' = $HvServer.Count
                        'Number of Protection Groups' = $ProtectionGroups.Count
                        'Number of File Shares' = $Shares.Count
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