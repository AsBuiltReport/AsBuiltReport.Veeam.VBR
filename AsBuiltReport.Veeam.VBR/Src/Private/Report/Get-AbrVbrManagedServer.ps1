
function Get-AbrVbrManagedServer {
    <#
    .SYNOPSIS
    Used by As Built Report to returns hosts connected to the backup infrastructure.
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
        Write-PScriboMessage "Discovering Veeam VBR Virtualization Servers and Hosts information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrManagedServer
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Virtualization Servers and Hosts'
    }

    process {
        try {
            if ($ManagedServers = Get-VBRServer) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($ManagedServer in $ManagedServers) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $ManagedServer.Name
                                $LocalizedData.Description = $ManagedServer.Info.TypeDescription
                                $LocalizedData.Status = switch ($ManagedServer.IsUnavailable) {
                                    'False' { $LocalizedData.Available }
                                    'True' { $LocalizedData.Unavailable }
                                    default { $ManagedServer.IsUnavailable }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Virtualization Servers and Hosts $($ManagedServer.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Infrastructure.Status) {
                        $OutObj | Where-Object { $_."$($LocalizedData.Status)" -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 50, 35, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property $LocalizedData.Description | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Virtualization Servers and Hosts Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Virtualization Servers and Hosts'
    }

}