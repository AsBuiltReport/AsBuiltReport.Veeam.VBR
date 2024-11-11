
function Get-AbrVbrAgentBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns computer backup jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Agent Backup jobs information from $System."
    }

    process {
        try {
            if ($ABkjobs = Get-VBRComputerBackupJob) {
                Section -Style Heading3 'Agent Backup Jobs' {
                    Paragraph "The following section list agent backup jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    foreach ($ABkjob in $ABkjobs) {
                        try {
                            Write-PScriboMessage "Discovered $($ABkjob.Name) location."
                            $inObj = [ordered] @{
                                'Name' = $ABkjob.Name
                                'Type' = $ABkjob.Type
                                'OS Platform' = $ABkjob.OSPlatform
                                'Backup Object' = $ABkjob.BackupObject
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Agent Backup Jobs $($ABkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "Agent Backup Jobs - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 25, 15, 30
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Agent Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}

}
