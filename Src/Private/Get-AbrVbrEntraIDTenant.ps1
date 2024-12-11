
function Get-AbrVbrEntraIDTenant {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam EntraID Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.13
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
        Write-PScriboMessage "Discovering Veeam VBR EntraID information from $System."
    }

    process {
        if ($EntraIDObjs = Get-VBREntraIDTenant) {
            Section -Style Heading3 'Entra ID Tenant' {
                Paragraph "The following table provides a summary about the EntraID information from Veeam Server $VeeamBackupServer."
                BlankLine
                $OutObj = @()
                try {
                    foreach ($EntraIDObj in $EntraIDObjs) {
                        try {
                            Write-PScriboMessage "Discovered $($EntraIDObj.Name) EntraID Tenant."
                            $inObj = [ordered] @{
                                'Name' = $EntraIDObj.Name
                                'Azure Tenant Id' = $EntraIDObj.AzureTenantId
                                'Application Id' = $EntraIDObj.ApplicationId
                                'Region' = $EntraIDObj.Region
                                'Cache Repository' = $EntraIDObj.CacheRepository.Name
                                'Description' = $EntraIDObj.Description
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Entra ID Tenant Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.BestPractice) {
                            $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                        }

                        $TableParams = @{
                            Name = "$($EntraIDObj.Name) - $VeeamBackupServer"
                            List = $True
                            ColumnWidths = 40, 60
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        if ($HealthCheck.Infrastructure.BestPractice) {
                            if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $_.'Description' -eq '--' }) {                                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Best Practice:" -Bold
                                    Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
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
    end {}

}