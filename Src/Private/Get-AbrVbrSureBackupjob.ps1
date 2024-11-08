
function Get-AbrVbrSureBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns surebackup jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR SureBackup jobs information from $System."
    }

    process {
        try {
            if ($SBkjobs = Get-VBRSureBackupJob | Sort-Object -Property 'Job Name') {
                Section -Style Heading3 'SureBackup Jobs' {
                    Paragraph "The following section list surebackup jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    foreach ($SBkjob in $SBkjobs) {
                        try {
                            Write-PScriboMessage "Discovered $($SBkjob.Name) location."
                            $inObj = [ordered] @{
                                'Name' = $SBkjob.Name
                                'Status' = Switch ($SBkjob.IsEnabled) {
                                    'False' { 'Disabled' }
                                    'True' { 'Enabled' }
                                }
                                'Schedule Enabled' = Switch ($SBkjob.ScheduleEnabled) {
                                    'False' { 'Not Scheduled' }
                                    'True' { 'Scheduled' }
                                }
                                'Latest Result' = $SBkjob.LastResult
                                'Virtual Lab' = Switch ($SBkjob.VirtualLab.Name) {
                                    $true { "Not applicable" }
                                    $false { $SBkjob.VirtualLab.Name }
                                    default { "--" }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "SureBackup Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
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
        } catch {
            Write-PScriboMessage -IsWarning "SureBackup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}

}
