
function Get-AbrVbrSureBackup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR SureBackup Information
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
        Write-PScriboMessage "Discovering Veeam VBR SureBackup information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrSureBackup
        Show-AbrDebugExecutionTime -Start -TitleMessage 'SureBackup Configuration'
    }

    process {
        try {
            $SureBackupAGs = Get-VBRApplicationGroup | Sort-Object -Property Name
            $SureBackupVLs = Get-VBRVirtualLab | Sort-Object -Property Name
            if ($SureBackupAGs -or $SureBackupVLs) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    try {
                        if ($SureBackupAGs) {
                            Section -Style Heading4 $LocalizedData.ApplicationGroupsHeading {
                                Paragraph $LocalizedData.ApplicationGroupsParagraph
                                BlankLine
                                $OutObj = @()
                                try {
                                    foreach ($SureBackupAG in $SureBackupAGs) {

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $SureBackupAG.Name
                                            $LocalizedData.VMList = $SureBackupAG.VM -join ', '
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "SureBackup Configuration $($SureBackupAG.Name) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.AppGroupTable) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "SureBackup Configuration Section: $($_.Exception.Message)"
                    }
                    if ($SureBackupAGs) {
                        if ($InfoLevel.Infrastructure.SureBackup -ge 2) {
                            try {
                                foreach ($SureBackupAG in $SureBackupAGs) {
                                    if ($SureBackupAG.VM) {
                                        Section -Style Heading5 "$($SureBackupAG.Name) $($LocalizedData.VMSettingsSuffix)" {
                                            foreach ($VMSetting in $SureBackupAG.VM) {
                                                try {
                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $($VMSetting.Name) {
                                                        $OutObj = @()

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.VMName = $VMSetting.Name
                                                            $LocalizedData.Credentials = $VMSetting.Credentials
                                                            $LocalizedData.Role = ($VMSetting.Role -join ', ')
                                                            $LocalizedData.TestScript = ($VMSetting.TestScript.PredefinedApplication -join ', ')
                                                            $LocalizedData.StartupOptions = switch ($VMSetting.StartupOptions) {
                                                                '' { '--'; break }
                                                                $Null { '--'; break }
                                                                default { $VMSetting.StartupOptions | ForEach-Object { "Allocated Memory: $($_.AllocatedMemory)`r`nHeartbeat Check: $($_.VMHeartBeatCheckEnabled)`r`nMaximum Boot Time: $($_.MaximumBootTime)`r`nApp Init Timeout: $($_.ApplicationInitializationTimeout)`r`nPing Check: $($_.VMPingCheckEnabled)" } }
                                                            }
                                                        }

                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.AppGroupVMSettingsTable) - $($VMSetting.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "SureBackup Application Group VM Settings $($VMSetting.Name) Section: $($_.Exception.Message)"
                                                }
                                            }

                                        }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "SureBackup Application Group VM Settings Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    if ($SureBackupVLs) {
                        try {
                            Section -Style Heading4 $LocalizedData.VirtualLabsHeading {
                                Paragraph $LocalizedData.VirtualLabsParagraph
                                BlankLine
                                $OutObj = @()
                                try {
                                    foreach ($SureBackupVL in $SureBackupVLs) {

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $SureBackupVL.Name
                                            $LocalizedData.Platform = $SureBackupVL.Platform
                                            $LocalizedData.PhysicalHost = $SureBackupVL.Server.Name.split('.')[0]
                                            $LocalizedData.PhysicalHostVersion = $SureBackupVL.Server.Info.Info
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "SureBackup Virtual Labs $($SureBackupVL.Name) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.VirtualLabTable) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 30, 15, 20, 35
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                                if ($InfoLevel.Infrastructure.SureBackup -ge 2) {
                                    try {
                                        $SureBackupVLCs = Get-VBRViVirtualLabConfiguration | Sort-Object -Property Name
                                        if ($SureBackupVLCs) {
                                            Section -Style Heading5 $LocalizedData.vSphereVLCHeading {
                                                foreach ($SureBackupVLC in $SureBackupVLCs) {
                                                    try {
                                                        Section -Style Heading6 "$($SureBackupVLC.Name) $($LocalizedData.SettingsSuffix)" {
                                                            $OutObj = @()

                                                            $inObj = [ordered] @{
                                                                $LocalizedData.Host = $SureBackupVLC.Server.Name
                                                                $LocalizedData.ResourcePool = $SureBackupVLC.DesignatedResourcePoolName
                                                                $LocalizedData.VMFolder = $SureBackupVLC.DesignatedVMFolderName
                                                                $LocalizedData.CacheDatastore = $SureBackupVLC.CacheDatastore
                                                                $LocalizedData.ProxyApplianceEnabled = $SureBackupVLC.ProxyApplianceEnabled
                                                                $LocalizedData.ProxyAppliance = $SureBackupVLC.ProxyAppliance
                                                                $LocalizedData.NetworkingType = $SureBackupVLC.Type
                                                                $LocalizedData.ProductionNetwork = $SureBackupVLC.NetworkMapping.ProductionNetwork.NetworkName
                                                                $LocalizedData.IsolatedNetwork = $SureBackupVLC.NetworkMapping.IsolatedNetworkName
                                                                $LocalizedData.RoutingBetweenvNics = $SureBackupVLC.RoutingBetweenvNicsEnabled
                                                                $LocalizedData.MultiHost = $SureBackupVLC.IsMultiHost
                                                                $LocalizedData.StaticIPMapping = $SureBackupVLC.StaticIPMappingEnabled
                                                            }

                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "$($LocalizedData.VirtualLabSettingsTable) - $($SureBackupVLC.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                            try {
                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.vNICSettingsHeading {
                                                                    $OutObj = @()
                                                                    foreach ($NetworkOption in $SureBackupVLC.NetworkOptions) {
                                                                        $inObj = [ordered] @{
                                                                            $LocalizedData.IsolatedNetwork = $NetworkOption.NetworkMappingRule.IsolatedNetworkName
                                                                            $LocalizedData.VLANID = $NetworkOption.NetworkMappingRule.VLANID
                                                                            $LocalizedData.DHCPEnabled = $NetworkOption.DHCPEnabled
                                                                            $LocalizedData.NetworkProperties = "IP Address: $($NetworkOption.IPAddress)`r`nSubnet Mask: $($NetworkOption.SubnetMask)`r`nMasquerade IP: $($NetworkOption.MasqueradeIPAddress)`r`nDNS Server: $($NetworkOption.DNSServer)"
                                                                        }

                                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.vNICSettingsTable) - $($SureBackupVLC.Name)"
                                                                        List = $false
                                                                        ColumnWidths = 45, 10, 10, 35
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property $LocalizedData.VLANID | Table @TableParams
                                                                }
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "SureBackup vSphere $($SureBackupVLC.Name) vNIC Settings Section: $($_.Exception.Message)"
                                                            }
                                                            try {
                                                                if ($SureBackupVLC.IpMappingRule) {
                                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.IPAddressMappingHeading {
                                                                        $OutObj = @()
                                                                        foreach ($NetworkOption in $SureBackupVLC.IpMappingRule) {
                                                                            $inObj = [ordered] @{
                                                                                $LocalizedData.ProductionNetwork = $NetworkOption.ProductionNetwork.Name
                                                                                $LocalizedData.IsolatedIPAddress = $NetworkOption.IsolatedIPAddress
                                                                                $LocalizedData.AccessIPAddress = $NetworkOption.AccessIPAddress
                                                                                $LocalizedData.Notes = $NetworkOption.Note
                                                                            }

                                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                                        }

                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            $OutObj | Where-Object { $Null -like $_.$($LocalizedData.Notes) } | Set-Style -Style Warning -Property $LocalizedData.Notes
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.IPAddressMappingTable) - $($SureBackupVLC.Name)"
                                                                            List = $false
                                                                            ColumnWidths = 30, 15, 15, 40
                                                                        }
                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property $LocalizedData.ProductionNetwork | Table @TableParams
                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            if ($OutObj | Where-Object { $Null -like $_.$($LocalizedData.Notes) }) {
                                                                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                                                BlankLine
                                                                                Paragraph {
                                                                                    Text $LocalizedData.BestPractice -Bold
                                                                                    Text $LocalizedData.BestPracticeNotesDesc
                                                                                }
                                                                                BlankLine
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "SureBackup vSphere $($SureBackupVLC.Name) IP Address Mapping Section: $($_.Exception.Message)"
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "SureBackup vSphere $($SureBackupVLC.Name) Settings Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "SureBackup vSphere Virtual Labs Configuration Section: $($_.Exception.Message)"
                                    }
                                    try {
                                        $SureBackupHvVLCs = try { Get-VBRHvVirtualLabConfiguration | Sort-Object -Property Name } catch { $Null }
                                        if ($SureBackupHvVLCs) {
                                            Section -Style Heading5 $LocalizedData.HvVLCHeading {
                                                foreach ($SureBackupHvVLC in $SureBackupHvVLCs) {
                                                    try {
                                                        Section -Style Heading6 "$($SureBackupHvVLC.Name) $($LocalizedData.SettingsSuffix)" {
                                                            $OutObj = @()

                                                            $inObj = [ordered] @{
                                                                $LocalizedData.Host = $SureBackupHvVLC.Server.Info.DNSName
                                                                $LocalizedData.Path = $SureBackupHvVLC.Path
                                                                $LocalizedData.ProxyApplianceEnabled = $SureBackupHvVLC.ProxyApplianceEnabled
                                                                $LocalizedData.ProxyAppliance = $SureBackupHvVLC.ProxyAppliance
                                                                $LocalizedData.NetworkingType = $SureBackupHvVLC.Type
                                                                $LocalizedData.IsolatedNetwork = $SureBackupHvVLC.IsolatedNetworkOptions.IsolatedNetworkName
                                                                $LocalizedData.StaticIPMapping = $SureBackupHvVLC.StaticIPMappingEnabled
                                                            }

                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                            $TableParams = @{
                                                                Name = "$($LocalizedData.VirtualLabSettingsTable) - $($SureBackupHvVLC.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                            try {
                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.vNICSettingsHeading {
                                                                    $OutObj = @()
                                                                    foreach ($NetworkOption in $SureBackupVL.IsolatedNetworkOptions) {
                                                                        $inObj = [ordered] @{
                                                                            $LocalizedData.IsolatedNetwork = $NetworkOption.IsolatedNetworkName
                                                                            $LocalizedData.VLANID = $NetworkOption.IsolatedNetworkVLanID
                                                                            $LocalizedData.DHCPEnabled = $NetworkOption.DHCPEnabled
                                                                            $LocalizedData.NetworkProperties = "IP Address: $($NetworkOption.IPAddress)`r`nSubnet Mask: $($NetworkOption.SubnetMask)`r`nMasquerade IP: $($NetworkOption.MasqueradeIPAddress)`r`nDNS Server: $($NetworkOption.DNSServer)"
                                                                        }

                                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.vNICSettingsTable) - $($SureBackupHvVLC.Name)"
                                                                        List = $false
                                                                        ColumnWidths = 45, 10, 10, 35
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property $LocalizedData.VLANID | Table @TableParams
                                                                }
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "SureBackup Hyper-V $($SureBackupHvVLC.Name) vNIC Settings Section: $($_.Exception.Message)"
                                                            }
                                                            try {
                                                                if ($SureBackupHvVLC.StaticIPMappingEnabled) {
                                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.IPAddressMappingHeading {
                                                                        $OutObj = @()
                                                                        foreach ($NetworkOption in $SureBackupHvVLC.StaticIPMappingRule) {
                                                                            $inObj = [ordered] @{
                                                                                $LocalizedData.ProductionNetwork = $NetworkOption.ProductionNetwork.NetworkName
                                                                                $LocalizedData.IsolatedIPAddress = $NetworkOption.IsolatedIPAddress
                                                                                $LocalizedData.AccessIPAddress = $NetworkOption.AccessIPAddress
                                                                                $LocalizedData.Notes = $NetworkOption.Note
                                                                            }

                                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                                        }

                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            $OutObj | Where-Object { $Null -like $_.$($LocalizedData.Notes) } | Set-Style -Style Warning -Property $LocalizedData.Notes
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.IPAddressMappingTable) - $($SureBackupHvVLC.Name)"
                                                                            List = $false
                                                                            ColumnWidths = 30, 15, 15, 40
                                                                        }
                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property $LocalizedData.ProductionNetwork | Table @TableParams
                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            if ($OutObj | Where-Object { $Null -like $_.$($LocalizedData.Notes) }) {
                                                                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                                                BlankLine
                                                                                Paragraph {
                                                                                    Text $LocalizedData.BestPractice -Bold
                                                                                    Text $LocalizedData.BestPracticeNotesDesc
                                                                                }
                                                                                BlankLine
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "SureBackup Hyper-V $($SureBackupHvVLC.Name) IP Address Mapping Section: $($_.Exception.Message)"
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "SureBackup $($SureBackupHvVLC.Name) Settings Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "SureBackup Hyper-V Virtual Labs Configuration Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "SureBackup Virtual Labs Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "SureBackup Configuration Document: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'SureBackup Configuration'
    }
}