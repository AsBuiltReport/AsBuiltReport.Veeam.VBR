
function Get-AbrVbrCloudConnectStatus {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Cloud Connect Service Status
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
        Write-PScriboMessage "Discovering Veeam VBR Cloud Connect Service Status information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCloudConnectStatus
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Cloud Connect Service Status'
    }

    process {
        if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' }) {
            if ($CloudConnectInfraStatus = Get-VBRCloudInfrastructureState) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    try {
                        $CloudConnectInfraServiceStatus = Get-VBRCloudInfrastructureServiceState
                        $OutObj = @()
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.ServerName = $VeeamBackupServer
                                $LocalizedData.GlobalStatus = $CloudConnectInfraStatus
                                $LocalizedData.ServiceState = $CloudConnectInfraServiceStatus.State
                                $LocalizedData.ServiceResponseDelay = $CloudConnectInfraServiceStatus.ServiceResponseDelay
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        } catch {
                            Write-PScriboMessage -IsWarning "Cloud Connect Service Status $($CloudObject.DisplayName) Section: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.BackupServer) {
                            $OutObj | Where-Object { $_."$($LocalizedData.GlobalStatus)" -eq 'Maintenance' } | Set-Style -Style Warning -Property $LocalizedData.GlobalStatus
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
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
        Show-AbrDebugExecutionTime -End -TitleMessage 'Cloud Connect Service Status'
    }

}