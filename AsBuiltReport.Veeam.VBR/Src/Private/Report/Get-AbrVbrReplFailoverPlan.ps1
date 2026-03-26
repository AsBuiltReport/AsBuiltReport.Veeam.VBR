
function Get-AbrVbrReplFailoverPlan {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Failover Plan Information.
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
        Write-PScriboMessage "Discovering Veeam VBR Failover Plans from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrReplFailoverPlan
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Failover Plans'
    }

    process {
        if ($FailOverPlans = Get-VBRFailoverPlan | Sort-Object -Property Name) {
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph ($LocalizedData.Paragraph -f $VeeamBackupServer)
                $OutObj = @()
                foreach ($FailOverPlan in $FailOverPlans) {
                    try {
                        Section -Style Heading4 $($FailOverPlan.Name) {
                            $inObj = [ordered] @{
                                $LocalizedData.Platform = $FailOverPlan.Platform
                                $LocalizedData.Status = $FailOverPlan.Status
                                $LocalizedData.PreFailoverScriptEnabled = $FailOverPlan.PreFailoverScriptEnabled
                                $LocalizedData.PreFailoverCommand = $FailOverPlan.PrefailoverCommand
                                $LocalizedData.PostFailoverScriptEnabled = $FailOverPlan.PostFailoverScriptEnabled
                                $LocalizedData.PostFailoverCommand = $FailOverPlan.PostfailoverCommand
                                $LocalizedData.VMCount = $FailOverPlan.VmCount
                                $LocalizedData.Description = $FailOverPlan.Description
                            }
                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                            if ($HealthCheck.Replication.Status) {
                                $OutObj | Where-Object { $_.$($LocalizedData.Status) -ne 'Ready' } | Set-Style -Style Warning -Property $LocalizedData.Status
                            }

                            if ($HealthCheck.Replication.BestPractice) {
                                $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $($FailOverPlan.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            if ($HealthCheck.Replication.BestPractice) {
                                if ($OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' -or $_.$($LocalizedData.Description) -eq '--' }) {
                                    Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text $LocalizedData.BestPractice -Bold
                                        Text $LocalizedData.BPText
                                    }
                                    BlankLine
                                }
                            }
                            if ($InfoLevel.Replication.FailoverPlan -ge 2) {
                                if ($FailOverPlan) {
                                    try {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.VMsSubHeading {
                                            $OutObj = @()
                                            foreach ($FailOverPlansVM in $FailOverPlan.FailoverPlanObject) {
                                                try {
                                                    if ($FailOverPlan.Platform -eq 'VMWare') {
                                                        Write-PScriboMessage "Discovering $($FailOverPlan.Name) VMware VM information."
                                                        $VMInfo = Find-VBRHvEntity -Name $FailOverPlansVM
                                                    } else {
                                                        Write-PScriboMessage "Discovering $($FailOverPlan.Name) Hyper-V VM information."
                                                        $VMInfo = Find-VBRHvEntity -Name $FailOverPlansVM
                                                    }
                                                    if ($VMInfo) {

                                                    }
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.VMName = switch ($VMInfo.Name) {
                                                            $Null { $LocalizedData.Unknown }
                                                            default { $VMInfo.Name }
                                                        }
                                                        $LocalizedData.BootOrder = $FailOverPlansVM.BootOrder
                                                        $LocalizedData.BootDelay = $FailOverPlansVM.BootDelay
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Virtual Machines $($VMInfo.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.VMsTableHeading) - $($FailOverPlan.Name)"
                                                List = $false
                                                ColumnWidths = 40, 30, 30
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Job Name' | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Virtual Machines Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Failover Plans Section: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Failover Plans'
    }

}