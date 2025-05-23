
function Get-AbrVbrPhysicalInfrastructure {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Physical Infrastructure inventory
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
        Write-PScriboMessage "Discovering Veeam VBR Physical Infrastructure inventory from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Physical Infrastructure'
    }

    process {
        try {
            if (($VbrLicenses | Where-Object { $_.Status -ne "Expired" }) -and $InventObjs) {
                Section -Style Heading3 'Physical Infrastructure' {
                    Paragraph "The following sections detail configuration information about managed physical infrastructure."
                    BlankLine
                    try {
                        Section -Style Heading4 'Protection Groups Summary' {
                            $OutObj = @()
                            foreach ($InventObj in $InventObjs) {
                                try {
                                    Write-PScriboMessage "Discovered $($InventObj.Name) Protection Group."
                                    $inObj = [ordered] @{
                                        'Name' = $InventObj.Name
                                        'Type' = $InventObj.Type
                                        'Container' = $InventObj.Container
                                        'Schedule' = $InventObj.ScheduleOptions
                                        'Enabled' = $InventObj.Enabled
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "Protection Groups Summary $($InventObj.Name) Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "Protection Groups - $VeeamBackupServer"
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
                                    Section -Style Heading5 "Protection Group Configuration" {
                                        foreach ($InventObj in $InventObjs) {
                                            try {
                                                if ($InventObj.Type -eq 'Custom' -and $InventObj.Container.Type -eq 'ActiveDirectory') {
                                                    try {
                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC "$($InventObj.Name)" {
                                                            Write-PScriboMessage "Discovered $($InventObj.Name) Protection Group Setting."
                                                            $inObj = [ordered] @{
                                                                'Domain' = ($InventObj).Container.Domain
                                                                'Backup Objects' = $InventObj.Container.Entity | ForEach-Object { "Name: $(($_).Name)`r`nType: $(($_).Type)`r`nDistinguished Name: $(($_).DistinguishedName)`r`n" }
                                                                'Exclude VM' = ($InventObj).Container.ExcludeVMs
                                                                'Exclude Computers' = ($InventObj).Container.ExcludeComputers
                                                                'Exclude Offline Computers' = ($InventObj).Container.ExcludeOfflineComputers
                                                                'Excluded Entity' = ($InventObj).Container.ExcludedEntity -join ", "
                                                                'Master Credentials' = ($InventObj).Container.MasterCredentials
                                                                'Deployment Options' = "Install Agent: $($InventObj.DeploymentOptions.InstallAgent)`r`nUpgrade Automatically: $($InventObj.DeploymentOptions.UpgradeAutomatically)`r`nInstall Driver: $($InventObj.DeploymentOptions.InstallDriver)`r`nReboot If Required: $($InventObj.DeploymentOptions.RebootIfRequired)"
                                                            }
                                                            if (($InventObj.NotificationOptions.EnableAdditionalNotification) -like 'True') {
                                                                $inObj.add('Notification Options', ("Send Time: $($InventObj.NotificationOptions.SendTime)`r`nAdditional Address: [$($InventObj.NotificationOptions.AdditionalAddress)]`r`nUse Notification Options: $($InventObj.NotificationOptions.UseNotificationOptions)`r`nSubject: $($InventObj.NotificationOptions.NotificationSubject)"))
                                                            }

                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "Protection Group Configuration - $($InventObj.Name)"
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
                                                            Write-PScriboMessage "Discovered $($InventObj.Name) Protection Group Setting."
                                                            $inObj = [ordered] @{
                                                                'Deployment Options' = "Install Agent: $($InventObj.DeploymentOptions.InstallAgent)`r`nUpgrade Automatically: $($InventObj.DeploymentOptions.UpgradeAutomatically)`r`nInstall Driver: $($InventObj.DeploymentOptions.InstallDriver)`r`nReboot If Required: $($InventObj.DeploymentOptions.RebootIfRequired)"
                                                            }
                                                            if (($InventObj.NotificationOptions.EnableAdditionalNotification) -like 'True') {
                                                                $inObj.add('Notification Options', ("Send Time: $($InventObj.NotificationOptions.SendTime)`r`nAdditional Address: [$($InventObj.NotificationOptions.AdditionalAddress)]`r`nUse Notification Options: $($InventObj.NotificationOptions.UseNotificationOptions)`r`nSubject: $($InventObj.NotificationOptions.NotificationSubject)"))
                                                            }

                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "Protection Group Configuration - $($InventObj.Name)"
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