
function Get-AbrVbrSureBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns surebackup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.1
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
        Write-PscriboMessage "Discovering Veeam VBR SureBackup jobs information from $System."
    }

    process {
        try {
            if ((Get-VBRSureBackupJob).count -gt 0) {
                Section -Style Heading3 'SureBackup Jobs' {
                    Paragraph "The following section list surebackup jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    $SBkjobs = Get-VBRSureBackupJob | Sort-Object -Property 'Job Name'
                    foreach ($SBkjob in $SBkjobs) {
                        try {
                            Write-PscriboMessage "Discovered $($SBkjob.Name) location."
                            $inObj = [ordered] @{
                                'Name' = $SBkjob.Name
                                'Status' = Switch ($SBkjob.IsEnabled) {
                                    'False' {'Disabled'}
                                    'True' {'Enabled'}
                                }
                                'Schedule Enabled' = Switch ($SBkjob.ScheduleEnabled) {
                                    'False' {'Not Scheduled'}
                                    'True' {'Scheduled'}
                                }
                                'Latest Result' = $SBkjob.LastResult
                                'Virtual Lab' = $SBkjob.VirtualLab.Name
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "SureBackup Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "SureBackup Jobs - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 15, 15, 15, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "SureBackup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}

}
