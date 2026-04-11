function Get-AbrVbrAgentBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns computer backup jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Agent Backup jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrAgentBackupjob
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Agent Backup Jobs'
    }

    process {
        try {
            if ($ABkjobs = Get-VBRComputerBackupJob) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($ABkjob in $ABkjobs) {
                        try {
                            $inObj = [ordered] @{
                                $LocalizedData.Name = $ABkjob.Name
                                $LocalizedData.Type = $ABkjob.Type
                                $LocalizedData.OSPlatform = $ABkjob.OSPlatform
                                $LocalizedData.BackupObject = $ABkjob.BackupObject
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Agent Backup Jobs $($ABkjob.Name) Section: $($_.Exception.Message)"
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
                    $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Agent Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Agent Backup Jobs'
    }

}
