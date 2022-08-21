
function Get-AbrVbrEmailNotificationSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Email Notification settings configured on Veeam Backup & Replication..
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
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
            if ((Get-VBRMailNotificationConfiguration).count -gt 0) {
                Section -Style Heading4 'Email Notification Settings' {
                    $OutObj = @()
                    try {
                        $EmailSettings = Get-VBRMailNotificationConfiguration
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
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
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
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}