
function Get-AbrVbrEmailNotificationSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Email Notification settings configured on Veeam Backup & Replication..
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.2
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
        Write-PscriboMessage "Discovering Veeam VBR Email Notification settings information from $System."
    }

    process {
        try {
            $EmailSettings = Get-VBRMailNotificationConfiguration
            if ($EmailSettings) {
                Section -Style Heading4 'Email Notification' {
                    $OutObj = @()
                    foreach ($EmailSetting in $EmailSettings) {
                        $inObj = [ordered] @{
                            'Email Recipient' = $EmailSetting.Recipient
                            'Email Sender' = $EmailSetting.Sender
                            'SMTP Server' = $EmailSetting.SmtpServer
                            'Email Subject' = $EmailSetting.Subject
                            'SSL Enabled' = ConvertTo-TextYN $EmailSetting.SSLEnabled
                            'Auth Enabled' = ConvertTo-TextYN $EmailSetting.AuthEnabled
                            'Credentials' = $EmailSetting.Credentials.Name
                            'Daily Reports Time' = $EmailSetting.DailyReportsTime.ToShortTimeString()
                            'Enabled' = ConvertTo-TextYN $EmailSetting.Enabled
                            'Notify On' = Switch ($EmailSetting.NotifyOnSuccess) {
                                "" {"-"; break}
                                $Null {"-"; break}
                                default {"Notify On Success: $(ConvertTo-TextYN $EmailSetting.NotifyOnSuccess)`r`nNotify On Warning: $(ConvertTo-TextYN $EmailSetting.NotifyOnWarning)`r`nNotify On Failure: $(ConvertTo-TextYN $EmailSetting.NotifyOnFailure)`r`nNotify On Last Retry Only: $(ConvertTo-TextYN $EmailSetting.NotifyOnLastRetryOnly)"}
                            }
                        }
                        $OutObj += [pscustomobject]$inobj
                    }

                    if ($HealthCheck.Infrastructure.Settings) {
                        $OutObj | Where-Object { $_.'Enabled' -like 'No'} | Set-Style -Style Warning -Property 'Enabled'
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
                        Paragraph "Health Check:" -Italic -Bold -Underline
                        Paragraph "Best Practice: Veeam recommends configuring email notifications to be able to receive alerts with the results of jobs performed on the backup server." -Italic -Bold
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Email Notification Section: $($_.Exception.Message)"
        }
    }
    end {}

}