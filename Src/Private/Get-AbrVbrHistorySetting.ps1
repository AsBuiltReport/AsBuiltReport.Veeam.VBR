
function Get-AbrVbrHistorySetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Email Notification settings configured on Veeam Backup & Replication..
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.7
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
        Write-PScriboMessage "Discovering Veeam VBR History settings information from $System."
    }

    process {
        try {
            if ($HistorySettings = Get-VBRHistoryOptions) {
                Section -Style Heading4 'History Retention' {
                    $OutObj = @()
                    $inObj = [ordered] @{
                        'Keep All Sessions' = ConvertTo-TextYN $HistorySettings.KeepAllSessions
                        'Retention Limit' = "$($HistorySettings.RetentionLimitWeeks) weeks"
                    }
                    $OutObj = [pscustomobject]$inobj

                    $TableParams = @{
                        Name = "History Settings - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "History Setting Section: $($_.Exception.Message)"
        }
    }
    end {}

}