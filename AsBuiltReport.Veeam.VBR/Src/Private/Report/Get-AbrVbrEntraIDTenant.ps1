
function Get-AbrVbrEntraIDTenant {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam EntraID Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.0
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
        $LocalizedData = $reportTranslate.GetAbrVbrEntraIDTenant
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'EntraID Tenant'
    }

    process {
        if ($EntraIDObjs = Get-VBREntraIDTenant) {
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph ($LocalizedData.Paragraph -f $VeeamBackupServer)
                BlankLine
                $OutObj = @()
                try {
                    foreach ($EntraIDObj in $EntraIDObjs) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $EntraIDObj.Name
                                $LocalizedData.AzureTenantId = $EntraIDObj.AzureTenantId
                                $LocalizedData.ApplicationId = $EntraIDObj.ApplicationId
                                $LocalizedData.Region = $EntraIDObj.Region
                                $LocalizedData.CacheRepository = $EntraIDObj.CacheRepository.Name
                                $LocalizedData.Description = $EntraIDObj.Description
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Entra ID Tenant Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.BestPractice) {
                            $OutObj | Where-Object { $_.$LocalizedData.Description -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                            $OutObj | Where-Object { $_.$LocalizedData.Description -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                        }

                        $TableParams = @{
                            Name = "$($EntraIDObj.Name) - $VeeamBackupServer"
                            List = $True
                            ColumnWidths = 40, 60
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                        if ($HealthCheck.Infrastructure.BestPractice) {
                            if ($OutObj | Where-Object { $_.$LocalizedData.Description -match 'Created by' -or $_.$LocalizedData.Description -eq '--' }) {
                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text $LocalizedData.BestPractice -Bold
                                    Text $LocalizedData.BPDescription
                                }
                                BlankLine
                            }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Entra ID Tenant Section: $($_.Exception.Message)"
                }
            }
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'EntraID Tenant'
    }

}
