
function Get-AbrVbrBackupjobNutanix {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Nutanix backup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.23
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
        Write-PScriboMessage "Discovering Veeam VBR Nutanix Backup jobs information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Nutanix Backup Jobs"
    }

    process {
        try {
            if ($Bkjobs = [Veeam.Backup.Core.CBackupJob]::GetAll() | Where-Object { $_.TypeToString -like "*Nutanix*" } | Sort-Object -Property 'Name') {
                Section -Style Heading3 'Nutanix Backup Jobs' {
                    Paragraph "This section provides detailed information about Nutanix backup jobs configured in Veeam Backup & Replication, including their status and latest results."
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Write-PScriboMessage "Discovered $($Bkjob.Name) Backup Job."
                            $inObj = [ordered] @{
                                'Name' = $Bkjob.Name
                                'Type' = $Bkjob.TypeToString
                                'Status' = switch ($Bkjob.IsScheduleEnabled) {
                                    'False' { 'Disabled' }
                                    'True' { 'Enabled' }
                                }
                                'Latest Result' = $Bkjob.info.LatestStatus
                                'Scheduled?' = switch ($Bkjob.IsScheduleEnabled) {
                                    'True' { 'Yes' }
                                    'False' { 'No' }
                                    default { 'Unknown' }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Nutanix Backup Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Jobs.Status) {
                        $OutObj | Where-Object { $_.'Latest Result' -eq 'Failed' } | Set-Style -Style Critical -Property 'Latest Result'
                        $OutObj | Where-Object { $_.'Latest Result' -eq 'Warning' } | Set-Style -Style Warning -Property 'Latest Result'
                        $OutObj | Where-Object { $_.'Latest Result' -eq 'Success' } | Set-Style -Style Ok -Property 'Latest Result'
                        $OutObj | Where-Object { $_.'Status' -eq 'Disabled' } | Set-Style -Style Warning -Property 'Status'
                        $OutObj | Where-Object { $_.'Scheduled?' -eq 'No' } | Set-Style -Style Warning -Property 'Scheduled?'
                    }

                    $TableParams = @{
                        Name = "Nutanix Backup Jobs - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 41, 20, 13, 13, 13
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Nutanix Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage "Nutanix Backup Jobs"
    }

}
