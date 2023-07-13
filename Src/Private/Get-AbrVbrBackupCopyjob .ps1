
function Get-AbrVbrBackupCopyjob  {
    <#
    .SYNOPSIS
        Used by As Built Report to returns backup copy jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.0
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
        Write-PscriboMessage "Discovering Veeam VBR Backup Copy jobs information from $System."
    }

    process {
        try {
            $BkCopyjobs = Get-VBRBackupCopyJob -WarningAction SilentlyContinue
            if ($BkCopyjobs) {
                Section -Style Heading3 'Backup Copy Jobs' {
                    Paragraph "The following section list backup copy jobs created within Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    foreach ($BkCopyjob in $BkCopyjobs) {
                        try {
                            Write-PscriboMessage "Discovered $($BkCopyjob.Name) backup copy."
                            $inObj = [ordered] @{
                                'Name' = $BkCopyjob.Name
                                'Copy Mode' = $BkCopyjob.Mode
                                'Status' = Switch ($BkCopyjob.JobEnabled) {
                                    'False' {'Disabled'}
                                    'True' {'Enabled'}
                                }
                                'Latest Result' = $BkCopyjob.LastResult
                                'Scheduled?' = $BkCopyjob.ScheduleOptions.Type
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Backup Copy Jobs $($BkCopyjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Jobs.Status) {
                        $OutObj | Where-Object { $_.'Latest Result' -eq 'Failed' } | Set-Style -Style Critical -Property 'Latest Result'
                        $OutObj | Where-Object { $_.'Latest Result' -eq 'Warning' } | Set-Style -Style Warning -Property 'Latest Result'
                        $OutObj | Where-Object { $_.'Status' -eq 'Disabled' } | Set-Style -Style Warning -Property 'Status'
                    }

                    $TableParams = @{
                        Name = "Backup Copy Jobs - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 40, 15, 15, 15, 15
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' |Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Backup Copy Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}

}
