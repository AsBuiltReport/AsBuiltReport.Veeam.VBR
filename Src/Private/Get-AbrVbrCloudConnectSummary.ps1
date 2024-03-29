function Get-AbrVbrCloudConnectSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Cloud Connect Infrastructure Summary.
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Connect Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $CloudConnectRR = Get-VBRCloudHardwarePlan
                $CloudConnectTenant = Get-VBRCloudTenant
                $CloudConnectGW = Get-VBRCloudGateway
                $CloudConnectGWPool = Get-VBRCloudGatewayPool
                $CloudConnectPublicIP = Get-VBRCloudPublicIP
                $CloudConnectBS = (Get-VBRCloudTenant).Resources.Repository

                $inObj = [ordered] @{
                    'Cloud Gateways' = $CloudConnectGW.Count
                    'Gateway Pools' = $CloudConnectGWPool.Count
                    'Tenants' = $CloudConnectTenant.Count
                    'Backup Storage' = $CloudConnectBS.Count
                    'Public IP Addresses' = $CloudConnectPublicIP.Count
                    'Hardware Plans' = $CloudConnectRR.Count
                }
                $OutObj += [pscustomobject]$inobj
            } catch {
                Write-PScriboMessage -IsWarning "Cloud Connect Summary Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "Cloud Connect Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($Options.EnableCharts) {
                try {
                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                    $chartFileItem = Get-PieChart -SampleData $sampleData -ChartName 'CloudConnectInventory' -XField 'Category' -YField 'Value' -ChartLegendName 'Infrastructure'
                } catch {
                    Write-PScriboMessage -IsWarning "Cloud Connect Inventory chart section: $($_.Exception.Message)"
                }
            }

            if ($OutObj) {
                Section -Style NOTOCHeading4 -ExcludeFromTOC 'Cloud Connect Infrastructure' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Cloud Connect Infrastructure - Chart' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Cloud Connect Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}