function Get-AbrVbrCloudConnectSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Cloud Connect Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.12
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
                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
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

            $OutObj | Table @TableParams

        } catch {
            Write-PScriboMessage -IsWarning "Cloud Connect Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}