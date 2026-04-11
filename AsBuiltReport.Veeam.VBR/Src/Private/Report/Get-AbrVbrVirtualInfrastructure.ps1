
function Get-AbrVbrVirtualInfrastructure {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Virtual Infrastructure inventory
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.26
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
        Write-PScriboMessage "Discovering Veeam VBR Virtual Infrastructure inventory from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrVirtualInfrastructure
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Virtual Infrastructure'
    }

    process {
        try {
            if ($VbrServer = Get-VBRServer) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    #---------------------------------------------------------------------------------------------#
                    #                            VMware vSphere information Section                               #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        if ($VbrServer | Where-Object { $_.Type -eq 'VC' -or $_.Type -eq 'ESXi' }) {
                            Section -Style Heading4 $LocalizedData.VMwareHeading {
                                Paragraph $LocalizedData.VMwareParagraph
                                BlankLine
                                $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'VC' }
                                if ($InventObjs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.VCenterHeading {
                                        $OutObj = @()
                                        foreach ($InventObj in $InventObjs) {
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $InventObj.Name
                                                    $LocalizedData.Version = ($InventObj).Info.Info
                                                    $LocalizedData.ChildHost = $InventObj.GetChilds().Name -join ', '
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware vCenter $($InventObj.Name) Table: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableVCenter) - $VeeamBackupServer"
                                            List = $false
                                            ColumnWidths = 33, 33, 34
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                    }
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                            VMware Esxi information Section                                  #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'ESXi' }
                                    if ($InventObjs) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.EsxiHostHeading {
                                            $OutObj = @()
                                            foreach ($InventObj in $InventObjs) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $InventObj.Name
                                                        $LocalizedData.Version = ($InventObj).Info.Info
                                                        $LocalizedData.ConnectedVcenter = try { (Find-VBRViEntity -Name $InventObj.Name -ServersOnly).Path.split('\')[0] } catch { Out-Null }
                                                    }

                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Esxi Host $($InventObj.Name) Table: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableEsxiHosts) - $VeeamBackupServer"
                                                List = $false
                                                ColumnWidths = 40, 20, 40
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Esxi Host Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "VMware vSphere Section: $($_.Exception.Message)"
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                         Microsoft Hyper-V Cluster information Section                       #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        if ($VbrServer | Where-Object { $_.Type -eq 'HvCluster' -or $_.Type -eq 'HvServer' }) {
                            Section -Style Heading4 $LocalizedData.HyperVHeading {
                                $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'HvCluster' }
                                if ($InventObjs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.HyperVClustersHeading {
                                        $OutObj = @()
                                        foreach ($InventObj in $InventObjs) {
                                            try {

                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $InventObj.Name
                                                    $LocalizedData.Credentials = ($InventObj).ProxyServicesCreds.Name
                                                    $LocalizedData.ChildHost = $InventObj.GetChilds().Name -join ', '
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Hyper-V Clusters $($InventObj.Name) Table: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHyperVClusters) - $VeeamBackupServer"
                                            List = $false
                                            ColumnWidths = 34, 33, 33
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                    }
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                         Microsoft Hyper-V Host information Section                          #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'HvServer' }
                                    if ($InventObjs) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.HyperVHostHeading {
                                            $OutObj = @()
                                            foreach ($InventObj in $InventObjs) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $InventObj.Name
                                                        $LocalizedData.Version = ($InventObj).Info.Info
                                                        #'Hyper-V CLuster' = (Find-VBRHvEntity -Name $InventObj.Name).Path.split("\")[0]
                                                    }

                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Hyper-V Host $($InventObj.Name) Table: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHyperVHosts) - $VeeamBackupServer"
                                                List = $false
                                                ColumnWidths = 40, 60
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Hyper-V Host Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Microsoft Hyper-V Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Virtual Infrastructure Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Virtual Infrastructure'
    }

}