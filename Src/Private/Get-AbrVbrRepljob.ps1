
function Get-AbrVbrRepljob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns replication jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR Replication jobs information from $System."
    }

    process {
        try {
            if ($Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $_.TypeToString -eq 'VMware Replication' -or $_.TypeToString -eq 'Hyper-V Replication' } | Sort-Object -Property Name) {
                Section -Style Heading3 'Replication Jobs' {
                    Paragraph "The following section provide a summary about replication jobs"
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Write-PScriboMessage "Discovered $($Bkjob.Name) replication job."
                            $inObj = [ordered] @{
                                'Name' = $Bkjob.Name
                                'Type' = $Bkjob.TypeToString
                                'Status' = Switch ($Bkjob.IsScheduleEnabled) {
                                    'False' { 'Disabled' }
                                    'True' { 'Enabled' }
                                }
                                'Latest Result' = $Bkjob.info.LatestStatus
                                'Last Run' = Switch ($Bkjob.FindLastSession().EndTimeUTC) {
                                    $null { 'Never' }
                                    default { $Bkjob.FindLastSession().EndTimeUTC }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Replication Jobs $($Bkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "Replication Jobs - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 25, 20, 15, 15, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property Name | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Replication Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}

}
