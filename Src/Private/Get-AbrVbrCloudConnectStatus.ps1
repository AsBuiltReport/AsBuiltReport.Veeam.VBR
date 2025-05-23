
function Get-AbrVbrCloudConnectStatus {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Service Status
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Connect Service Status information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Cloud Connect Service Status"
    }

    process {
        if ($VbrLicenses | Where-Object { $_.CloudConnect -ne "Disabled" }) {
            if ($CloudConnectInfraStatus = Get-VBRCloudInfrastructureState) {
                Section -Style Heading3 'Service Status' {
                    Paragraph "The following section provides information about Cloud Gateways SSL Certificate."
                    BlankLine
                    try {
                        $CloudConnectInfraServiceStatus = Get-VBRCloudInfrastructureServiceState
                        $OutObj = @()
                        try {
                            Write-PScriboMessage "Discovered $($CloudObject.DisplayName) Cloud Connect Service Status information."
                            $inObj = [ordered] @{
                                'Server Name' = $VeeamBackupServer
                                'Global Status' = $CloudConnectInfraStatus
                                'Service State' = $CloudConnectInfraServiceStatus.State
                                'Service Response Delay' = $CloudConnectInfraServiceStatus.ServiceResponseDelay
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        } catch {
                            Write-PScriboMessage -IsWarning "Cloud Connect Service Status $($CloudObject.DisplayName) Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.BackupServer) {
                            $OutObj | Where-Object { $_.'Global Status' -eq 'Maintenance' } | Set-Style -Style Warning -Property 'Global Status'
                        }

                        $TableParams = @{
                            Name = "Service Status - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    } catch {
                        Write-PScriboMessage -IsWarning "Cloud Connect Service Status Section: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage "Cloud Connect Service Status"
    }

}