
function Get-AbrVbrEmailNotificationSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Email Notification settings configured on Veeam Backup & Replication..
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        Write-PScriboMessage "Discovering Veeam VBR Email Notification settings information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage "Email Notification Settings"
    }

    process {
        try {
            if ($EmailSettings = Get-VBRMailNotificationConfiguration) {
                Section -Style Heading4 'Email Notification' {
                    $OutObj = @()
                    foreach ($EmailSetting in $EmailSettings) {
                        $inObj = [ordered] @{
                            'Email Recipient' = $EmailSetting.Recipient
                            'Email Sender' = $EmailSetting.Sender
                            'SMTP Server' = $EmailSetting.SmtpServer
                            'Email Subject' = $EmailSetting.Subject
                            'SSL Enabled' = $EmailSetting.SSLEnabled
                            'Auth Enabled' = $EmailSetting.AuthEnabled
                            'Credentials' = $EmailSetting.Credentials.Name
                            'Daily Reports Time' = $EmailSetting.DailyReportsTime.ToShortTimeString()
                            'Enabled' = $EmailSetting.Enabled
                            'Notify On' = Switch ($EmailSetting.NotifyOnSuccess) {
                                "" { "--"; break }
                                $Null { "--"; break }
                                default { "Notify On Success: $($EmailSetting.NotifyOnSuccess)`r`nNotify On Warning: $($EmailSetting.NotifyOnWarning)`r`nNotify On Failure: $($EmailSetting.NotifyOnFailure)`r`nNotify On Last Retry Only: $($EmailSetting.NotifyOnLastRetryOnly)" }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($HealthCheck.Infrastructure.Settings) {
                        $OutObj | Where-Object { $_.'Enabled' -like 'No' } | Set-Style -Style Warning -Property 'Enabled'
                    }

                    $TableParams = @{
                        Name = "Email Notification Settings - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.'Enabled' -eq 'No' })) {
                        Paragraph "Health Check:" -Bold -Underline
                        BlankLine
                        Paragraph {
                            Text "Best Practice:" -Bold
                            Text "Veeam recommends configuring email notifications to be able to receive alerts with the results of jobs performed on the backup server."
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Email Notification Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage "Email Notification Settings"
        }
    }
    end {}

}