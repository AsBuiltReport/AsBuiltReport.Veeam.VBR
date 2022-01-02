
function Get-AbrVbrEmailNotificationSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Email Notification settings configured on Veeam Backup & Replication..


    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR Email Notification settings information from $System."
    }

    process {
        Section -Style Heading4 'Email Notification Settings' {
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
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
                    Name = "Email Notification Settings - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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
    end {}

}