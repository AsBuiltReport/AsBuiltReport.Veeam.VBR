
function Get-AbrVbrPhysicalInfrastructure {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Physical Infrastructure inventory
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
        Write-PScriboMessage "Discovering Veeam VBR Physical Infrastructure inventory from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrPhysicalInfrastructure
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Physical Infrastructure'
    }

    process {
        try {
            if (($VbrLicenses | Where-Object { $_.Status -ne 'Expired' }) -and $InventObjs) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    try {
                        Section -Style Heading4 $LocalizedData.ProtGroupSummaryHeading {
                            $OutObj = @()
                            foreach ($InventObj in $InventObjs) {
                                try {

                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $InventObj.Name
                                        $LocalizedData.Type = $InventObj.Type
                                        $LocalizedData.Container = $InventObj.Container
                                        $LocalizedData.Schedule = $InventObj.ScheduleOptions
                                        $LocalizedData.Enabled = $InventObj.Enabled
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "Protection Groups Summary $($InventObj.Name) Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableProtGroups) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 23, 23, 23, 16, 15
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            #---------------------------------------------------------------------------------------------#
                            #                            Protection Groups Detailed Section                               #
                            #---------------------------------------------------------------------------------------------#
                            if ($InfoLevel.Inventory.PHY -ge 2) {
                                try {
                                    $OutObj = @()
                                    Section -Style Heading5 $LocalizedData.ProtGroupConfigHeading {
                                        foreach ($InventObj in $InventObjs) {
                                            try {
                                                if ($InventObj.Type -eq 'Custom' -and $InventObj.Container.Type -eq 'ActiveDirectory') {
                                                    try {
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "$($InventObj.Name)" {

                                                            $inObj = [ordered] @{
                                                                $LocalizedData.Domain = ($InventObj).Container.Domain
                                                                $LocalizedData.BackupObjects = $InventObj.Container.Entity | ForEach-Object { "Name: $(($_).Name)`r`nType: $(($_).Type)`r`nDistinguished Name: $(($_).DistinguishedName)`r`n" }
                                                                $LocalizedData.ExcludeVM = ($InventObj).Container.ExcludeVMs
                                                                $LocalizedData.ExcludeComputers = ($InventObj).Container.ExcludeComputers
                                                                $LocalizedData.ExcludeOfflineComputers = ($InventObj).Container.ExcludeOfflineComputers
                                                                $LocalizedData.ExcludedEntity = ($InventObj).Container.ExcludedEntity -join ', '
                                                                $LocalizedData.MasterCredentials = ($InventObj).Container.MasterCredentials
                                                                $LocalizedData.DeploymentOptions = "$($LocalizedData.InstallAgent): $($InventObj.DeploymentOptions.InstallAgent)`r`n$($LocalizedData.UpgradeAutomatically): $($InventObj.DeploymentOptions.UpgradeAutomatically)`r`n$($LocalizedData.InstallDriver): $($InventObj.DeploymentOptions.InstallDriver)`r`n$($LocalizedData.RebootIfRequired): $($InventObj.DeploymentOptions.RebootIfRequired)"
                                                            }
                                                            if (($InventObj.NotificationOptions.EnableAdditionalNotification) -like 'True') {
                                                                $inObj.add($LocalizedData.NotificationOptions, ("$($LocalizedData.SendTime): $($InventObj.NotificationOptions.SendTime)`r`n$($LocalizedData.AdditionalAddress): [$($InventObj.NotificationOptions.AdditionalAddress)]`r`n$($LocalizedData.UseNotificationOptions): $($InventObj.NotificationOptions.UseNotificationOptions)`r`n$($LocalizedData.Subject): $($InventObj.NotificationOptions.NotificationSubject)"))
                                                            }

                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "$($LocalizedData.TableProtGroupConfig) - $($InventObj.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }

                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Protection Groups Configuration $($InventObj.Name) Section: $($_.Exception.Message)"
                                                    }
                                                } elseif ($InventObj.Type -eq 'ManuallyAdded' -and $InventObj.Container.Type -eq 'IndividualComputers') {
                                                    try {
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "$($InventObj.Name)" {

                                                            $inObj = [ordered] @{
                                                                $LocalizedData.DeploymentOptions = "$($LocalizedData.InstallAgent): $($InventObj.DeploymentOptions.InstallAgent)`r`n$($LocalizedData.UpgradeAutomatically): $($InventObj.DeploymentOptions.UpgradeAutomatically)`r`n$($LocalizedData.InstallDriver): $($InventObj.DeploymentOptions.InstallDriver)`r`n$($LocalizedData.RebootIfRequired): $($InventObj.DeploymentOptions.RebootIfRequired)"
                                                            }
                                                            if (($InventObj.NotificationOptions.EnableAdditionalNotification) -like 'True') {
                                                                $inObj.add($LocalizedData.NotificationOptions, ("$($LocalizedData.SendTime): $($InventObj.NotificationOptions.SendTime)`r`n$($LocalizedData.AdditionalAddress): [$($InventObj.NotificationOptions.AdditionalAddress)]`r`n$($LocalizedData.UseNotificationOptions): $($InventObj.NotificationOptions.UseNotificationOptions)`r`n$($LocalizedData.Subject): $($InventObj.NotificationOptions.NotificationSubject)"))
                                                            }

                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "$($LocalizedData.TableProtGroupConfig) - $($InventObj.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }

                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Protection Groups Configuration $($InventObj.Name) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Protection Groups Configuration Section: $($_.Exception.Message)"
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Protection Groups Configuration Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Protection Groups Summary Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Physical Infrastructure Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Physical Infrastructure'
    }

}