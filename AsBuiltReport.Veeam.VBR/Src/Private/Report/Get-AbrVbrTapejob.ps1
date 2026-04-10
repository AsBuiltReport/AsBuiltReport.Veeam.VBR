
function Get-AbrVbrTapejob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns tape backup jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Tape Backup jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrTapejob
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Tape Backup Jobs'
    }

    process {
        try {
            if ($TBkjobs = Get-VBRTapeJob | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($TBkjob in $TBkjobs) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $TBkjob.Name
                                $LocalizedData.Type = ($TBkjob.Type -creplace '([A-Z\W_]|\d+)(?<![a-z])', ' $&').trim()
                                $LocalizedData.LatestStatus = $TBkjob.LastResult
                                $LocalizedData.TargetRepository = $TBkjob.Target
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Tape Backup Jobs $($TBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 25, 15, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tape Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Tape Backup Jobs'
    }

}
