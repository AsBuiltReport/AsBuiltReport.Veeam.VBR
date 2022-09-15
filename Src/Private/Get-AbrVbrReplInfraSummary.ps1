
function Get-AbrVbrReplInfraSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Replication Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
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
        Write-PscriboMessage "Discovering Veeam VBR Replication Summary from $System."
    }

    process {
        try {
            Section -Style NOTOCHeading3 -ExcludeFromTOC 'Replication' {
                $OutObj = @()
                $Replicas = Get-VBRReplica
                $FailOverPlans = Get-VBRFailoverPlan
                $inObj = [ordered] @{
                    'Number of Replicas' = $Replicas.Count
                    'Number of Failover Plans' = $FailOverPlans.Count
                }
                $OutObj += [pscustomobject]$inobj

                $TableParams = @{
                    Name = "Replication Summary - $VeeamBackupServer"
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