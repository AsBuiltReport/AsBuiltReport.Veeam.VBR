
function Get-AbrVbrRepljob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns replication jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.0
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
        Write-PscriboMessage "Discovering Veeam VBR Replication jobs information from $System."
    }

    process {
        try {
            $Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-object {$_.TypeToString -eq 'VMware Replication' -or $_.TypeToString -eq 'Hyper-V Replication'}
            if (($Bkjobs).count -gt 0) {
                Section -Style Heading3 'Replication Jobs' {
                    Paragraph "The following section list replication jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        foreach ($Bkjob in $Bkjobs) {
                            try {
                                Write-PscriboMessage "Discovered $($Bkjob.Name) replication job."
                                $inObj = [ordered] @{
                                    'Name' = $Bkjob.Name
                                    'Type' = $Bkjob.TypeToString
                                    'Status' = Switch ($Bkjob.IsScheduleEnabled) {
                                        'False' {'Disabled'}
                                        'True' {'Enabled'}
                                    }
                                    'Latest Result' = $Bkjob.info.LatestStatus
                                    'Last Run' = $Bkjob.FindLastSession().EndTimeUTC
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "Replication Jobs - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $false
                            ColumnWidths = 25, 20, 15, 15, 25
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property Name |Table @TableParams
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
