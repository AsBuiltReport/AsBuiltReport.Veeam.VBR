
function Get-AbrVbrAgentBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns computer backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
        Write-PscriboMessage "Discovering Veeam VBR Agent Backup jobs information from $System."
    }

    process {
        try {
            if ((Get-VBRComputerBackupJob).count -gt 0) {
                Section -Style Heading3 'Agent Backup Jobs' {
                    Paragraph "The following section list agent backup jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        $ABkjobs = Get-VBRComputerBackupJob
                        foreach ($ABkjob in $ABkjobs) {
                            try {
                                Write-PscriboMessage "Discovered $($ABkjob.Name) location."
                                $inObj = [ordered] @{
                                    'Name' = $ABkjob.Name
                                    'Type' = $ABkjob.Type
                                    'OS Platform' = $ABkjob.OSPlatform
                                    'BackupObject' = $ABkjob.BackupObject
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Agent Backup Jobs - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $false
                            ColumnWidths = 30, 25, 15, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}
