
function Get-AbrVbrAgentBackupjobConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns computer backup jobs configuration created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.1
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
        Write-PscriboMessage "Discovering Veeam VBR Agent Backup jobs configuration information from $System."
    }

    process {
        try {
            if ((Get-VBRComputerBackupJob).count -gt 0) {
                Section -Style Heading3 'Agent Backup Jobs Configuration' {
                    Paragraph "The following section details agent backup jobs configuration created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        $ABkjobs = Get-VBRComputerBackupJob
                        foreach ($ABkjob in $ABkjobs) {
                            try {
                                Section -Style Heading4 "$($ABkjob.Name) Configuration" {
                                    Section -Style Heading5 'Job Mode' {
                                        $OutObj = @()
                                        try {
                                            Write-PscriboMessage "Discovered $($ABkjob.Name) common information."
                                            $inObj = [ordered] @{
                                                'Name' = $ABkjob.Name
                                                'Id' = $ABkjob.Id
                                                'Type' = $ABkjob.Type
                                                'Mode' = Switch ($ABkjob.Mode) {
                                                    'ManagedByBackupServer' {'Managed by Backup Server'}
                                                    'ManagedByAgent' {'Managed by Agent'}
                                                    default {$ABkjob.Mode}
                                                }
                                                'Description' = $ABkjob.Description
                                                'Priority' = Switch ($ABkjob.IsHighPriority) {
                                                    'True' {'High Priority'}
                                                    'False' {'Normal Priority'}
                                                }
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Job Mode - $($ABkjob.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                    try {
                                        Section -Style Heading5 'Protected Computers' {
                                            $OutObj = @()
                                            foreach ($BackupObject in $ABkjob.BackupObject) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($BackupObject.Name) protected computer information."
                                                    $inObj = [ordered] @{
                                                        'Name' = $BackupObject.Name
                                                        'Type' = $BackupObject.Type
                                                        'Enabled' = ConvertTo-TextYN $BackupObject.Enabled
                                                        'Container' = Switch ($BackupObject.Container) {
                                                            'ActiveDirectory' {'Active Directory'}
                                                            'ManuallyDeployed' {'Manually Deployed'}
                                                            default {$BackupObject.Container}
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Protected Computers - $($ABkjob.Name)"
                                                List = $false
                                                ColumnWidths = 25, 25, 25, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
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
