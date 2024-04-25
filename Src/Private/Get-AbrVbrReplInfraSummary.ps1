
function Get-AbrVbrReplInfraSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Replication Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.6
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
        Write-PScriboMessage "Discovering Veeam VBR Replication Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            $Replicas = Get-VBRReplica
            $FailOverPlans = Get-VBRFailoverPlan
            $inObj = [ordered] @{
                'Replicas' = $Replicas.Count
                'Failover Plans' = $FailOverPlans.Count
            }
            $OutObj += [pscustomobject]$inobj

            $TableParams = @{
                Name = "Replication Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        } catch {
            Write-PScriboMessage -IsWarning "Replication Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}