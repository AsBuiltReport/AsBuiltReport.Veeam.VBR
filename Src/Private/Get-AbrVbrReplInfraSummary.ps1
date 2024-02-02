
function Get-AbrVbrReplInfraSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Replication Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.5
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
            if ($Options.EnableCharts) {
                try {
                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                    $chartFileItem = Get-PieChart -SampleData $sampleData -ChartName 'ReplicationInventory' -XField 'Category' -YField 'Value' -ChartLegendName 'Infrastructure'
                } catch {
                    Write-PScriboMessage -IsWarning "Replication Inventory chart section: $($_.Exception.Message)"
                }
            }

            if ($OutObj) {
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Replication Inventory' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Replication Inventory - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Replication Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}