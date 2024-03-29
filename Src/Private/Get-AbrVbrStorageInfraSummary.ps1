
function Get-AbrVbrStorageInfraSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Storage Infrastructure Summary.
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
        Write-PScriboMessage "Discovering Veeam VBR Storage Infrastructure Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $OntapHosts = Get-NetAppHost
                $IsilonHosts = Get-VBRIsilonHost
                $IsilonVols = Get-VBRIsilonVolume
                $inObj = [ordered] @{
                    'NetApp Ontap Storage' = $OntapHosts.Count
                    'NetApp Ontap Volumes' = $OntapHosts.Count
                    'Dell Isilon Storage' = $IsilonHosts.Count
                    'Dell Isilon Volumes' = $IsilonVols.Count
                }
                $OutObj += [pscustomobject]$inobj
            } catch {
                Write-PScriboMessage -IsWarning "Storage Infrastructure Inventory Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "Storage Infrastructure Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($Options.EnableCharts) {
                try {
                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                    $chartFileItem = Get-PieChart -SampleData $sampleData -ChartName 'StorageInfrastructure' -XField 'Category' -YField 'Value' -ChartLegendName 'Infrastructure'
                } catch {
                    Write-PScriboMessage -IsWarning "Storage Infrastructure chart section: $($_.Exception.Message)"
                }
            }

            if ($OutObj) {
                Section -Style NOTOCHeading4 -ExcludeFromTOC 'Storage Infrastructure Inventory' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Storage Infrastructure Inventory - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Storage Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}
