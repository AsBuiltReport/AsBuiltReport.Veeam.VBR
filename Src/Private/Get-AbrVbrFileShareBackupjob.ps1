
function Get-AbrVbrFileShareBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns file share jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.4
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
        Write-PscriboMessage "Discovering Veeam VBR File Share Backup jobs information from $System."
    }

    process {
        try {
            $FSBkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.TypeToString -like 'File Backup'}
            if ($FSBkjobs.count -gt 0) {
                Section -Style Heading3 'File Share Backup Jobs' {
                    Paragraph "The following section list file share backup jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    foreach ($FSBkjob in $FSBkjobs) {
                        try {
                            Write-PscriboMessage "Discovered $($FSBkjob.Name) file share."
                            $inObj = [ordered] @{
                                'Name' = $FSBkjob.Name
                                'Type' = $FSBkjob.TypeToString
                                'Status' = Switch ($FSBkjob.IsScheduleEnabled) {
                                    'False' {'Disabled'}
                                    'True' {'Enabled'}
                                }
                                'Latest Result' = $FSBkjob.info.LatestStatus
                                'Last Run' = Switch ($FSBkjob.FindLastSession()) {
                                    $Null {'Unknown'}
                                    default {$FSBkjob.FindLastSession().EndTimeUTC}
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }

                    $TableParams = @{
                        Name = "File Share Backup Jobs - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 25, 20, 15, 15, 25
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' |Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}
