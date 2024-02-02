
function Get-AbrVbrSureBackup {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR SureBackup Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.5
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
    }

    process {
        try {
            $SureBackupAGs = Get-VBRApplicationGroup | Sort-Object -Property Name
            $SureBackupVLs = Get-VBRVirtualLab  | Sort-Object -Property Name
            if ($SureBackupAGs -or $SureBackupVLs) {
                Section -Style Heading3 'SureBackup Configuration' {
                    Paragraph "The following section provides configuration information about SureBackup."
                    BlankLine
                    try {
                        if ($SureBackupAGs) {
                            Section -Style Heading4 'Application Groups' {
                                Paragraph "The following section provides a summary about Application Groups."
                                BlankLine
                                $OutObj = @()
                                try {
                                    foreach ($SureBackupAG in $SureBackupAGs) {
                                        Write-PScriboMessage "Discovered $($SureBackupAG.Name) Application Group."
                                        $inObj = [ordered] @{
                                            'Name' = $SureBackupAG.Name
                                            'VM List' = $SureBackupAG.VM -join ", "
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "SureBackup Configuration $($SureBackupAG.Name) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "Application Group - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
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
                                        Section -Style Heading5 "$($SureBackupAG.Name) VM Settings" {
                                            foreach ($VMSetting in $SureBackupAG.VM) {
                                                try {
                                                    Section -Style NOTOCHeading4 -ExcludeFromTOC $($VMSetting.Name) {
                                                        $OutObj = @()
                                                        Write-PScriboMessage "Discovered $($VMSetting.Name) Application Group VM Setting."
                                                        $inObj = [ordered] @{
                                                            'VM Name' = $VMSetting.Name
                                                            'Credentials' = ConvertTo-EmptyToFiller $VMSetting.Credentials
                                                            'Role' = ConvertTo-EmptyToFiller ($VMSetting.Role -join ", ")
                                                            'Test Script' = ConvertTo-EmptyToFiller ($VMSetting.TestScript.PredefinedApplication -join ", ")
                                                            'Startup Options' = SWitch ($VMSetting.StartupOptions) {
                                                                "" { "--"; break }
                                                                $Null { "--"; break }
                                                                default { $VMSetting.StartupOptions | ForEach-Object { "Allocated Memory: $($_.AllocatedMemory)`r`nHeartbeat Check: $(ConvertTo-TextYN $_.VMHeartBeatCheckEnabled)`r`nMaximum Boot Time: $($_.MaximumBootTime)`r`nApp Init Timeout: $($_.ApplicationInitializationTimeout)`r`nPing Check: $(ConvertTo-TextYN $_.VMPingCheckEnabled)" } }
                                                            }
                                                        }

                                                        $OutObj += [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Application Group VM Settings - $($VMSetting.Name)"
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
                    if ($SureBackupVL) {
                        try {
                            Section -Style Heading4 'Virtual Labs' {
                                Paragraph "The following section provides a summary about SureBackup Virtual Lab."
                                BlankLine
                                $OutObj = @()
                                try {
                                    foreach ($SureBackupVL in $SureBackupVLs) {
                                        Write-PScriboMessage "Discovered $($SureBackupVL.Name) Virtual Lab."
                                        $inObj = [ordered] @{
                                            'Name' = $SureBackupVL.Name
                                            'Platform' = $SureBackupVL.Platform
                                            'Physical Host' = $SureBackupVL.Server.Name.split(".")[0]
                                            'Physical Host Version' = $SureBackupVL.Server.Info.Info
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "SureBackup Virtual Labs $($SureBackupVL.Name) Section: $($_.Exception.Message)"
                                }

                                $TableParams = @{
                                    Name = "Virtual Lab - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 30, 15, 20, 35
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                if ($InfoLevel.Infrastructure.SureBackup -ge 2) {
                                    try {
                                        $SureBackupVLCs = Get-VBRViVirtualLabConfiguration | Sort-Object -Property Name
                                        if ($SureBackupVLCs) {
                                            Section -Style Heading5 "vSphere Virtual Labs Configuration" {
                                                foreach ($SureBackupVLC in $SureBackupVLCs) {
                                                    try {
                                                        Section -Style Heading6 "$($SureBackupVLC.Name) Settings" {
                                                            $OutObj = @()
                                                            Write-PScriboMessage "Discovered $($SureBackupVLC.Name) Virtual Lab."
                                                            $inObj = [ordered] @{
                                                                'Host' = $SureBackupVLC.Server.Name
                                                                'Resource Pool' = $SureBackupVLC.DesignatedResourcePoolName
                                                                'VM Folder' = $SureBackupVLC.DesignatedVMFolderName
                                                                'Cache Datastore' = $SureBackupVLC.CacheDatastore
                                                                'Proxy Appliance Enabled' = ConvertTo-TextYN $SureBackupVLC.ProxyApplianceEnabled
                                                                'Proxy Appliance' = $SureBackupVLC.ProxyAppliance
                                                                'Networking Type' = $SureBackupVLC.Type
                                                                'Production Network' = $SureBackupVLC.NetworkMapping.ProductionNetwork.NetworkName
                                                                'Isolated Network' = $SureBackupVLC.NetworkMapping.IsolatedNetworkName
                                                                'Routing Between vNics' = ConvertTo-TextYN $SureBackupVLC.RoutingBetweenvNicsEnabled
                                                                'Multi Host' = ConvertTo-TextYN $SureBackupVLC.IsMultiHost
                                                                'Static IP Mapping' = ConvertTo-TextYN $SureBackupVLC.StaticIPMappingEnabled
                                                            }

                                                            $OutObj += [pscustomobject]$inobj

                                                            $TableParams = @{
                                                                Name = "Virtual Lab Settings - $($SureBackupVLC.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                            try {
                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "vNIC Settings" {
                                                                    $OutObj = @()
                                                                    foreach ($NetworkOption in $SureBackupVLC.NetworkOptions) {
                                                                        $inObj = [ordered] @{
                                                                            'Isolated Network' = $NetworkOption.NetworkMappingRule.IsolatedNetworkName
                                                                            'VLAN ID' = $NetworkOption.NetworkMappingRule.VLANID
                                                                            'DHCP Enabled' = ConvertTo-TextYN $NetworkOption.DHCPEnabled
                                                                            'Network Properties' = "IP Address: $($NetworkOption.IPAddress)`r`nSubnet Mask: $($NetworkOption.SubnetMask)`r`nMasquerade IP: $($NetworkOption.MasqueradeIPAddress)`r`nDNS Server: $($NetworkOption.DNSServer)"
                                                                        }

                                                                        $OutObj += [pscustomobject]$inobj
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "vNIC Settings - $($SureBackupVLC.Name)"
                                                                        List = $false
                                                                        ColumnWidths = 45, 10, 10, 35
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property 'VLAN ID' | Table @TableParams
                                                                }
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "SureBackup vSphere $($SureBackupVLC.Name) vNIC Settings Section: $($_.Exception.Message)"
                                                            }
                                                            try {
                                                                if ($SureBackupVLC.IpMappingRule) {
                                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "IP Address Mapping" {
                                                                        $OutObj = @()
                                                                        foreach ($NetworkOption in $SureBackupVLC.IpMappingRule) {
                                                                            $inObj = [ordered] @{
                                                                                'Production Network' = $NetworkOption.ProductionNetwork.Name
                                                                                'Isolated IP Address' = $NetworkOption.IsolatedIPAddress
                                                                                'Access IP Address' = $NetworkOption.AccessIPAddress
                                                                                'Notes' = ConvertTo-EmptyToFiller $NetworkOption.Note
                                                                            }

                                                                            $OutObj += [pscustomobject]$inobj
                                                                        }

                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            $OutObj | Where-Object { $Null -like $_.'Notes' } | Set-Style -Style Warning -Property 'Notes'
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "IP Address Mapping - $($SureBackupVLC.Name)"
                                                                            List = $false
                                                                            ColumnWidths = 30, 15, 15, 40
                                                                        }
                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property 'Production Network' | Table @TableParams
                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            if ($OutObj | Where-Object { $Null -like $_.'Notes' }) {
                                                                                Paragraph "Health Check:" -Bold -Underline
                                                                                BlankLine
                                                                                Paragraph {
                                                                                    Text "Best Practice:" -Bold
                                                                                    Text "It is a general rule of good practice to establish well-defined notes. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                                                }
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
                                            Section -Style Heading5 "Hyper-V Virtual Labs Configuration" {
                                                foreach ($SureBackupHvVLC in $SureBackupHvVLCs) {
                                                    try {
                                                        Section -Style Heading6 "$($SureBackupHvVLC.Name) Settings" {
                                                            $OutObj = @()
                                                            Write-PScriboMessage "Discovered $($SureBackupHvVLC.Name) Virtual Lab."
                                                            $inObj = [ordered] @{
                                                                'Host' = $SureBackupHvVLC.Server.Info.DNSName
                                                                'Path' = $SureBackupHvVLC.Path
                                                                'Proxy Appliance Enabled' = ConvertTo-TextYN $SureBackupHvVLC.ProxyApplianceEnabled
                                                                'Proxy Appliance' = $SureBackupHvVLC.ProxyAppliance
                                                                'Networking Type' = $SureBackupHvVLC.Type
                                                                'Isolated Network' = $SureBackupHvVLC.IsolatedNetworkOptions.IsolatedNetworkName
                                                                'Static IP Mapping' = ConvertTo-TextYN $SureBackupHvVLC.StaticIPMappingEnabled
                                                            }

                                                            $OutObj += [pscustomobject]$inobj

                                                            $TableParams = @{
                                                                Name = "Virtual Lab Settings - $($SureBackupHvVLC.Name)"
                                                                List = $true
                                                                ColumnWidths = 40, 60
                                                            }
                                                            if ($Report.ShowTableCaptions) {
                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                            }
                                                            $OutObj | Table @TableParams
                                                            try {
                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC "vNIC Settings" {
                                                                    $OutObj = @()
                                                                    foreach ($NetworkOption in $SureBackupVL.IsolatedNetworkOptions) {
                                                                        $inObj = [ordered] @{
                                                                            'Isolated Network' = $NetworkOption.IsolatedNetworkName
                                                                            'VLAN ID' = $NetworkOption.IsolatedNetworkVLanID
                                                                            'DHCP Enabled' = ConvertTo-TextYN $NetworkOption.DHCPEnabled
                                                                            'Network Properties' = "IP Address: $($NetworkOption.IPAddress)`r`nSubnet Mask: $($NetworkOption.SubnetMask)`r`nMasquerade IP: $($NetworkOption.MasqueradeIPAddress)`r`nDNS Server: $($NetworkOption.DNSServer)"
                                                                        }

                                                                        $OutObj += [pscustomobject]$inobj
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "vNIC Settings - $($SureBackupHvVLC.Name)"
                                                                        List = $false
                                                                        ColumnWidths = 45, 10, 10, 35
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property 'VLAN ID' | Table @TableParams
                                                                }
                                                            } catch {
                                                                Write-PScriboMessage -IsWarning "SureBackup Hyper-V $($SureBackupHvVLC.Name) vNIC Settings Section: $($_.Exception.Message)"
                                                            }
                                                            try {
                                                                if ($SureBackupHvVLC.StaticIPMappingEnabled) {
                                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC "IP Address Mapping" {
                                                                        $OutObj = @()
                                                                        foreach ($NetworkOption in $SureBackupHvVLC.StaticIPMappingRule) {
                                                                            $inObj = [ordered] @{
                                                                                'Production Network' = $NetworkOption.ProductionNetwork.NetworkName
                                                                                'Isolated IP Address' = $NetworkOption.IsolatedIPAddress
                                                                                'Access IP Address' = $NetworkOption.AccessIPAddress
                                                                                'Notes' = $NetworkOption.Note
                                                                            }

                                                                            $OutObj += [pscustomobject]$inobj
                                                                        }

                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            $OutObj | Where-Object { $Null -like $_.'Notes' } | Set-Style -Style Warning -Property 'Notes'
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "IP Address Mapping - $($SureBackupHvVLC.Name)"
                                                                            List = $false
                                                                            ColumnWidths = 30, 15, 15, 40
                                                                        }
                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property 'Production Network' | Table @TableParams
                                                                        if ($HealthCheck.Infrastructure.BestPractice) {
                                                                            if ($OutObj | Where-Object { $Null -like $_.'Notes' }) {
                                                                                Paragraph "Health Check:" -Bold -Underline
                                                                                BlankLine
                                                                                Paragraph {
                                                                                    Text "Best Practice:" -Bold
                                                                                    Text "It is a general rule of good practice to establish well-defined notes. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                                                }
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
    end {}
}