
function Get-AbrVbrGlobalNotificationSetting {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Global Notification options configured on Veeam Backup & Replication..
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
        Write-PScriboMessage "Discovering Veeam VBR Global Notification option information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Global Notification options'
    }

    process {
        try {
            if ($GlobalNotifications = Get-VBRGlobalNotificationOptions) {
                Section -Style Heading4 'Global Notifications' {
                    Section -ExcludeFromTOC -Style NOTOCHeading5 'Backup Storage' {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            'Warn me when free disk space is below' = Switch ($GlobalNotifications.StorageSpaceThresholdEnabled) {
                                $true { "$($GlobalNotifications.StorageSpaceThreshold)%" }
                                $false { 'Disabled' }
                                default { 'Unknown' }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.'Warn me when free disk space is below' -eq "Disabled" } | Set-Style -Style Warning -Property 'Warn me when free disk space is below'
                        }

                        $TableParams = @{
                            Name = "Backup Storage Notification - $VeeamBackupServer"
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
                    Section -ExcludeFromTOC -Style NOTOCHeading5 'Production Datastore' {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            'Warn me when free disk space is below' = Switch ($GlobalNotifications.DatastoreSpaceThresholdEnabled) {
                                $true { "$($GlobalNotifications.DatastoreSpaceThreshold)%" }
                                $false { 'Disabled' }
                                default { 'Unknown' }
                            }
                            'Skip VM processig when free disk space is below' = Switch ($GlobalNotifications.SkipVMSpaceThresholdEnabled) {
                                $true { "$($GlobalNotifications.SkipVMSpaceThreshold)%" }
                                $false { 'Disabled' }
                                default { 'Unknown' }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.'Is (Warn me when free disk space is below) Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Is (Warn me when free disk space is below) Enabled'
                            $OutObj | Where-Object { $_.'Is (Skip VM processig when free disk space is below) Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Is (Skip VM processig when free disk space is below) Enabled'
                        }

                        $TableParams = @{
                            Name = "Production Datastore Notification - $VeeamBackupServer"
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
                    Section -ExcludeFromTOC -Style NOTOCHeading5 'Support Expiration' {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            'Enable notification about support contract expiration' = $GlobalNotifications.NotifyOnSupportExpiration
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.'Is (Enable notification about support contract expiration) Enabled' -eq 'No' } | Set-Style -Style Warning -Property 'Enabled'
                        }

                        $TableParams = @{
                            Name = "Support Expiration Notification - $VeeamBackupServer"
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
                    Section -ExcludeFromTOC -Style NOTOCHeading5 'Update Notification' {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            'Check for product and hypervisor updates periodically' = $GlobalNotifications.NotifyOnUpdates
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        $TableParams = @{
                            Name = "Update Notification Notification - $VeeamBackupServer"
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
            }
        } catch {
            Write-PScriboMessage -IsWarning "Global Notifications Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Global Notification options'

    }

}