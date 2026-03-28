
function Get-AbrVbrUserRoleAssignment {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Veeam VBR roles assigned to a user or a user group.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.24
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
        Write-PScriboMessage "Discovering Veeam VBR Roles information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrUserRoleAssignment
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Roles and Users'
    }

    process {
        try {
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph $LocalizedData.Paragraph
                BlankLine
                $OutObj = @()
                try {
                    $RoleAssignments = Get-VBRUserRoleAssignment
                    foreach ($RoleAssignment in $RoleAssignments) {

                        $inObj = [ordered] @{
                            $LocalizedData.Name = $RoleAssignment.Name
                            $LocalizedData.Type = $RoleAssignment.Type
                            $LocalizedData.Role = $RoleAssignment.Role
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Roles and Users Table: $($_.Exception.Message)"
                }

                if ($HealthCheck.Infrastructure.Settings) {
                    $List = @()
                    $OutObj | Where-Object { $_.$($LocalizedData.Name) -eq 'BUILTIN\Administrators' } | Set-Style -Style Warning -Property $LocalizedData.Name
                    foreach ( $OBJ in ($OutObj | Where-Object { $_.$($LocalizedData.Name) -eq 'BUILTIN\Administrators' })) {
                        $OBJ.$($LocalizedData.Name) = $OBJ.$($LocalizedData.Name) + ' (1)'
                        $List += $LocalizedData.BP1

                    }
                }

                $TableParams = @{
                    Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 45, 15, 40
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                if ($HealthCheck.Infrastructure.BestPractice -and $List) {
                    Paragraph $LocalizedData.HealthCheck -Bold -Underline
                    BlankLine
                    Paragraph $LocalizedData.SecurityBestPractice -Bold
                    List -Item $List -Numbered
                    if ($List ) {
                        Paragraph {
                            Text -Bold $LocalizedData.Reference
                        }
                        BlankLine
                        Paragraph {
                            Text $LocalizedData.BPUrl
                        }
                        BlankLine
                    }
                }
                if ($VbrVersion -ge 12) {
                    try {
                        Section -ExcludeFromTOC -Style NOTOCHeading4 $LocalizedData.SettingsSubHeading {
                            BlankLine
                            $OutObj = @()
                            try {
                                try { $MFAGlobalSetting = [Veeam.Backup.Core.SBackupOptions]::get_GlobalMFA() } catch { Out-Null }
                                try {
                                    $AutoTerminateSession = switch ($VbrVersion) {
                                        { $_ -ge 13 } { [Veeam.Backup.Core.SBackupOptions]::GetAutomaticallyTerminateSession() }
                                        default { [Veeam.Backup.Core.SBackupOptions]::get_AutoTerminateSession() }
                                    }
                                } catch { Out-Null }
                                try {
                                    $AutoTerminateSessionMin = switch ($VbrVersion) {
                                        { $_ -ge 13 } { [Veeam.Backup.Core.SBackupOptions]::GetAutomaticallyTerminateSessionTimeoutMinutes() }
                                        default { [Veeam.Backup.Core.SBackupOptions]::get_AutoTerminateSessionMinutes() }
                                    }
                                } catch { Out-Null }
                                try { $UserActionNotification = [Veeam.Backup.Core.SBackupOptions]::get_UserActionNotification() } catch { Out-Null }
                                try { $UserActionRetention = [Veeam.Backup.Core.SBackupOptions]::get_UserActionRetention() } catch { Out-Null }
                                foreach ($RoleAssignment in $RoleAssignments) {

                                    $inObj = [ordered] @{
                                        $LocalizedData.IsMFAEnabled = $MFAGlobalSetting
                                        $LocalizedData.IsAutoLogoffEnabled = $AutoTerminateSession
                                        $LocalizedData.AutoLogoffAfter = "$($AutoTerminateSessionMin) minutes"
                                        $LocalizedData.IsFourEyeEnabled = $UserActionNotification
                                        $LocalizedData.AutoRejectPending = "$($UserActionRetention) days"
                                    }
                                    $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Roles and Users Settings Table: $($_.Exception.Message)"
                            }

                            if ($HealthCheck.Infrastructure.Settings) {
                                $List = @()
                                $Num = 0
                                $OutObj | Where-Object { $_.$($LocalizedData.IsMFAEnabled) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.IsMFAEnabled
                                foreach ( $OBJ in ($OutObj | Where-Object { $_.$($LocalizedData.IsMFAEnabled) -eq 'No' })) {
                                    $Num++
                                    $OBJ.$($LocalizedData.IsMFAEnabled) = $OBJ.$($LocalizedData.IsMFAEnabled) + " ($Num)"
                                    $List += $LocalizedData.BPMfa

                                }
                                $OutObj | Where-Object { $_.$($LocalizedData.IsAutoLogoffEnabled) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.IsAutoLogoffEnabled
                                foreach ( $OBJ in ($OutObj | Where-Object { $_.$($LocalizedData.IsAutoLogoffEnabled) -eq 'No' })) {
                                    $Num++
                                    $OBJ.$($LocalizedData.IsAutoLogoffEnabled) = $OBJ.$($LocalizedData.IsAutoLogoffEnabled) + " ($Num)"
                                    $List += $LocalizedData.BPAutoLogoff

                                }
                                $OutObj | Where-Object { $_.$($LocalizedData.IsFourEyeEnabled) -like 'No' } | Set-Style -Style Warning -Property $LocalizedData.IsFourEyeEnabled
                                foreach ( $OBJ in ($OutObj | Where-Object { $_.$($LocalizedData.IsFourEyeEnabled) -eq 'No' })) {
                                    $Num++
                                    $OBJ.$($LocalizedData.IsFourEyeEnabled) = $OBJ.$($LocalizedData.IsFourEyeEnabled) + " ($Num)"
                                    $List += $LocalizedData.BPFourEye
                                }
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.SettingsTableHeading) - $VeeamBackupServer"
                                List = $True
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            if ($HealthCheck.Infrastructure.BestPractice -and $List) {
                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                BlankLine
                                Paragraph $LocalizedData.SecurityBestPractice -Bold
                                List -Item $List -Numbered
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Roles and Users Settings Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Roles and Users Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Roles and Users'
    }

}