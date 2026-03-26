
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
        $LocalizedData = $reportTranslate.GetAbrVbrEmailNotificationSetting
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Email Notification Settings'
    }

    process {
        try {
            if ($EmailSettings = Get-VBRMailNotificationConfiguration) {
                Section -Style Heading4 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($EmailSetting in $EmailSettings) {
                        $inObj = [ordered] @{
                            $LocalizedData.EmailRecipient = $EmailSetting.Recipient
                            $LocalizedData.EmailSender = $EmailSetting.Sender
                            $LocalizedData.SMTPServer = $EmailSetting.SmtpServer
                            $LocalizedData.EmailSubject = $EmailSetting.Subject
                            $LocalizedData.SSLEnabled = $EmailSetting.SSLEnabled
                            $LocalizedData.AuthEnabled = $EmailSetting.AuthEnabled
                            $LocalizedData.Credentials = $EmailSetting.Credentials.Name
                            $LocalizedData.DailyReportsTime = $EmailSetting.DailyReportsTime.ToShortTimeString()
                            $LocalizedData.Enabled = $EmailSetting.Enabled
                            $LocalizedData.NotifyOn = switch ($EmailSetting.NotifyOnSuccess) {
                                '' { $LocalizedData.NA; break }
                                $Null { $LocalizedData.NA; break }
                                default { "$($LocalizedData.NotifyOnSuccessLabel): $($EmailSetting.NotifyOnSuccess)`r`n$($LocalizedData.NotifyOnWarningLabel): $($EmailSetting.NotifyOnWarning)`r`n$($LocalizedData.NotifyOnFailureLabel): $($EmailSetting.NotifyOnFailure)`r`n$($LocalizedData.NotifyOnLastRetryOnlyLabel): $($EmailSetting.NotifyOnLastRetryOnly)" }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }

                    if ($HealthCheck.Infrastructure.Settings) {
                        $OutObj | Where-Object { $_.$LocalizedData.Enabled -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.Enabled
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.$LocalizedData.Enabled -eq 'No' })) {
                        Paragraph $LocalizedData.HealthCheck -Bold -Underline
                        BlankLine
                        Paragraph {
                            Text $LocalizedData.BestPractice -Bold
                            Text $LocalizedData.BPEmailNotification
                        }
                        BlankLine
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Email Notification Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage 'Email Notification Settings'
        }
    }
    end {}

}
