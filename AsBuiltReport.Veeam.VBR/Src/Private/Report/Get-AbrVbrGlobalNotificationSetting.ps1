
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
        $LocalizedData = $reportTranslate.GetAbrVbrGlobalNotificationSetting
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Global Notification options'
    }

    process {
        try {
            if ($GlobalNotifications = Get-VBRGlobalNotificationOptions) {
                Section -Style Heading4 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.HeadingBackupStorage {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            $LocalizedData.WarnFreeDiskSpace = switch ($GlobalNotifications.StorageSpaceThresholdEnabled) {
                                $true { "$($GlobalNotifications.StorageSpaceThreshold)%" }
                                $false { $LocalizedData.Disabled }
                                default { $LocalizedData.Unknown }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.$($LocalizedData.WarnFreeDiskSpace) -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.WarnFreeDiskSpace
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeadingBackupStorage) - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.$($LocalizedData.Enabled) -eq 'No' })) {
                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text $LocalizedData.BestPractice -Bold
                                Text $LocalizedData.BPEmailNotification
                            }
                            BlankLine
                        }
                    }
                    Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.HeadingProductionDatastore {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            $LocalizedData.WarnFreeDiskSpace = switch ($GlobalNotifications.DatastoreSpaceThresholdEnabled) {
                                $true { "$($GlobalNotifications.DatastoreSpaceThreshold)%" }
                                $false { $LocalizedData.Disabled }
                                default { $LocalizedData.Unknown }
                            }
                            $LocalizedData.SkipVMDiskSpace = switch ($GlobalNotifications.SkipVMSpaceThresholdEnabled) {
                                $true { "$($GlobalNotifications.SkipVMSpaceThreshold)%" }
                                $false { $LocalizedData.Disabled }
                                default { $LocalizedData.Unknown }
                            }
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_."Is ($($LocalizedData.WarnFreeDiskSpace)) Enabled" -eq 'No' } | Set-Style -Style Warning -Property "Is ($($LocalizedData.WarnFreeDiskSpace)) Enabled"
                            $OutObj | Where-Object { $_."Is ($($LocalizedData.SkipVMDiskSpace)) Enabled" -eq 'No' } | Set-Style -Style Warning -Property "Is ($($LocalizedData.SkipVMDiskSpace)) Enabled"
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeadingDatastore) - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.$($LocalizedData.Enabled) -eq 'No' })) {
                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text $LocalizedData.BestPractice -Bold
                                Text $LocalizedData.BPEmailNotification
                            }
                            BlankLine
                        }
                    }
                    Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.HeadingSupport {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            $LocalizedData.SupportExpiration = $GlobalNotifications.NotifyOnSupportExpiration
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_."Is ($($LocalizedData.SupportExpiration)) Enabled" -eq 'No' } | Set-Style -Style Warning -Property 'Enabled'
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeadingSupport) - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.$($LocalizedData.Enabled) -eq 'No' })) {
                            Paragraph $LocalizedData.HealthCheck -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text $LocalizedData.BestPractice -Bold
                                Text $LocalizedData.BPEmailNotification
                            }
                            BlankLine
                        }
                    }
                    Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.HeadingUpdate {
                        $OutObj = @()
                        $inObj = [ordered] @{
                            $LocalizedData.CheckForUpdates = $GlobalNotifications.NotifyOnUpdates
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeadingUpdate) - $VeeamBackupServer"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.$($LocalizedData.Enabled) -eq 'No' })) {
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
            }
        } catch {
            Write-PScriboMessage -IsWarning "Global Notifications Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Global Notification options'

    }

}
