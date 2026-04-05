
function Get-AbrVbrTapeServer {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Server Information
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
        $LocalizedData = $reportTranslate.GetAbrVbrTapeServer
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Tape Servers'
    }

    process {
        try {
            if ($TapeObjs = Get-VBRTapeServer) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($TapeObj in $TapeObjs) {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $TapeObj.Name
                                $LocalizedData.Description = $TapeObj.Description
                                $LocalizedData.Status = switch ($TapeObj.IsAvailable) {
                                    'True' { $LocalizedData.Available }
                                    'False' { $LocalizedData.Unavailable }
                                    default { $TapeObj.IsUnavailable }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }

                        if ($HealthCheck.Tape.Status) {
                            $OutObj | Where-Object { $_.$LocalizedData.Status -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                        }

                        if ($HealthCheck.Tape.BestPractice) {
                            $OutObj | Where-Object { $_.$LocalizedData.Description -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                            $OutObj | Where-Object { $_.$LocalizedData.Description -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 25, 50, 25
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                        if ($HealthCheck.Tape.BestPractice) {
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
                    } catch {
                        Write-PScriboMessage -IsWarning "Tape Servers Table: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tape Servers Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Tape Servers'
    }

}
