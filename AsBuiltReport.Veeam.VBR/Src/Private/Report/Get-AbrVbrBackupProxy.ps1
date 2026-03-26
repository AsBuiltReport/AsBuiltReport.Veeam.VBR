
function Get-AbrVbrBackupProxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Proxies Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.9.0
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
        Write-PScriboMessage "Discovering Veeam V&R Backup Proxies information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupProxy
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Proxies'
    }

    process {
        try {
            if (((Get-VBRViProxy).count -gt 0) -or ((Get-VBRHvProxy).count -gt 0)) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    if ($BackupProxies = Get-VBRViProxy | Sort-Object -Property Name) {
                        Section -Style Heading4 $LocalizedData.VMwareHeading {
                            $OutObj = @()
                            try {
                                if ($InfoLevel.Infrastructure.Proxy -eq 1) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    Write-PScriboMessage 'Collecting Summary Information.'
                                    foreach ($BackupProxy in $BackupProxies) {

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $BackupProxy.Name
                                            $LocalizedData.Type = $BackupProxy.Type
                                            $LocalizedData.MaxTasksCount = $BackupProxy.MaxTasksCount
                                            $LocalizedData.Disabled = $BackupProxy.IsDisabled
                                            $LocalizedData.Status = switch (($BackupProxy.Host).IsUnavailable) {
                                                'False' { $LocalizedData.Available }
                                                'True' { $LocalizedData.Unavailable }
                                                default { ($BackupProxy.Host).IsUnavailable }
                                            }
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    }

                                    if ($HealthCheck.Infrastructure.Proxy) {
                                        $OutObj | Where-Object { $_."$($LocalizedData.Status)" -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                                        List = $false
                                        ColumnWidths = 35, 15, 15, 15, 20
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                                if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    foreach ($BackupProxy in $BackupProxies) {
                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $BackupProxy.Name
                                            $LocalizedData.HostName = $BackupProxy.Host.Name
                                            $LocalizedData.Type = $BackupProxy.Type
                                            $LocalizedData.Disabled = $BackupProxy.IsDisabled
                                            $LocalizedData.MaxTasksCount = $BackupProxy.MaxTasksCount
                                            $LocalizedData.UseSsl = $BackupProxy.UseSsl
                                            $LocalizedData.FailoverToNetwork = $BackupProxy.FailoverToNetwork
                                            $LocalizedData.TransportMode = $BackupProxy.TransportMode
                                            $LocalizedData.ChassisType = $BackupProxy.ChassisType
                                            $LocalizedData.OsType = $BackupProxy.Host.Type
                                            $LocalizedData.ServicesCredential = $BackupProxy.Host.ProxyServicesCreds.Name
                                            $LocalizedData.Status = switch (($BackupProxy.Host).IsUnavailable) {
                                                'False' { $LocalizedData.Available }
                                                'True' { $LocalizedData.Unavailable }
                                                default { ($BackupProxy.Host).IsUnavailable }
                                            }
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Infrastructure.Proxy) {
                                            $OutObj | Where-Object { $_."$($LocalizedData.Status)" -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.TableHeading) - $($BackupProxy.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "VMware Backup Proxies Section: $($_.Exception.Message)"
                            }
                            #---------------------------------------------------------------------------------------------#
                            #                    VMware Backup Proxy Inventory Summary Section                             #
                            #---------------------------------------------------------------------------------------------#
                            try {
                                Write-PScriboMessage "Hardware Inventory Status set as $($Options.EnableHardwareInventory)."
                                if ($Options.EnableHardwareInventory) {
                                    Write-PScriboMessage 'Collecting Hardware/Software Inventory Summary.'
                                    if ($BackupProxies = Get-VBRViProxy | Where-Object { $_.Host.Type -eq 'Windows' } | Sort-Object -Property Name) {
                                        $vSphereVBProxyObj = foreach ($BackupProxy in $BackupProxies) {
                                            if ($ClientOSVersion -eq 'Win32NT') {
                                                if (Test-WSMan -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ComputerName $BackupProxy.Host.Name -ErrorAction SilentlyContinue) {
                                                    try {
                                                        Write-PScriboMessage "Collecting Backup Proxy Inventory Summary from $($BackupProxy.Host.Name)."
                                                        $CimSession = try { New-CimSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -Name 'HardwareInventory' -ErrorAction Stop } catch { Write-PScriboMessage -IsWarning "VMware Backup Proxies Hardware/Software Section: New-CimSession: Unable to connect to $($BackupProxy.Host.Name): $($_.Exception.MessageId)" }

                                                        $PssSession = try { New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop -Name 'VMwareHardwareInventory' } catch {
                                                            if (-not $_.Exception.MessageId) {
                                                                $ErrorMessage = $_.FullyQualifiedErrorId
                                                            } else { $ErrorMessage = $_.Exception.MessageId }
                                                            Write-PScriboMessage -IsWarning "VMware Backup Proxies Hardware/Software Section: New-PSSession: Unable to connect to $($BackupProxy.Host.Name): $ErrorMessage"
                                                        }
                                                        if ($PssSession) {
                                                            $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                                        } else { Write-PScriboMessage -IsWarning "VMware Backup Proxies Hardware/Software Inventory: Unable to connect to $($BackupProxy.Host.Name)" }
                                                        if ($HW) {
                                                            $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                                            $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                                            $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                                            Section -Style Heading5 $($BackupProxy.Host.Name.Split('.')[0]) {
                                                                $OutObj = @()
                                                                $inObj = [ordered] @{
                                                                    $LocalizedData.Name = $HW.CsDNSHostName
                                                                    $LocalizedData.WindowsProductName = $HW.WindowsProductName
                                                                    $LocalizedData.WindowsCurrentVersion = $HW.WindowsCurrentVersion
                                                                    $LocalizedData.WindowsBuildNumber = $HW.OsVersion
                                                                    $LocalizedData.WindowsInstallType = $HW.WindowsInstallationType
                                                                    $LocalizedData.ActiveDirectoryDomain = $HW.CsDomain
                                                                    $LocalizedData.WindowsInstallationDate = $HW.OsInstallDate
                                                                    $LocalizedData.TimeZone = $HW.TimeZone
                                                                    $LocalizedData.LicenseType = $License.ProductKeyChannel
                                                                    $LocalizedData.PartialProductKey = $License.PartialProductKey
                                                                    $LocalizedData.Manufacturer = $HW.CsManufacturer
                                                                    $LocalizedData.Model = $HW.CsModel
                                                                    $LocalizedData.SerialNumber = $HWBIOS.SerialNumber
                                                                    $LocalizedData.BiosType = $HW.BiosFirmwareType
                                                                    $LocalizedData.BiosVersion = $HWBIOS.Version
                                                                    $LocalizedData.ProcessorManufacturer = $HWCPU[0].Manufacturer
                                                                    $LocalizedData.ProcessorModel = $HWCPU[0].Name
                                                                    $LocalizedData.NumberOfCpuCores = $HWCPU[0].NumberOfCores
                                                                    $LocalizedData.NumberOfLogicalCores = $HWCPU[0].NumberOfLogicalProcessors
                                                                    $LocalizedData.PhysicalMemoryGb = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $HW.CsTotalPhysicalMemory
                                                                }
                                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                if ($HealthCheck.Infrastructure.Server) {
                                                                    $OutObj | Where-Object { $_."$($LocalizedData.NumberOfCpuCores)" -lt 4 } | Set-Style -Style Warning -Property $LocalizedData.NumberOfCpuCores
                                                                    if ([int]([regex]::Matches($OutObj."$($LocalizedData.PhysicalMemoryGb)", '\d+(?!.*\d+)').value) -lt 8) { $OutObj | Set-Style -Style Warning -Property $LocalizedData.PhysicalMemoryGb }
                                                                }

                                                                $TableParams = @{
                                                                    Name = "$($LocalizedData.InventoryTableHeading) - $($BackupProxy.Host.Name.Split('.')[0])"
                                                                    List = $true
                                                                    ColumnWidths = 40, 60
                                                                }
                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                $OutObj | Table @TableParams
                                                                #---------------------------------------------------------------------------------------------#
                                                                #                       Backup Proxy Local Disk Inventory Section                            #
                                                                #---------------------------------------------------------------------------------------------#
                                                                if ($InfoLevel.Infrastructure.Proxy -ge 3) {
                                                                    try {
                                                                        $HostDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -ne 'iSCSI' -and $_.BusType -ne 'Fibre Channel' } }
                                                                        if ($HostDisks) {
                                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.LocalDisksHeading {
                                                                                $LocalDiskReport = @()
                                                                                foreach ($Disk in $HostDisks) {
                                                                                    try {
                                                                                        $TempLocalDiskReport = [PSCustomObject]@{
                                                                                            $LocalizedData.DiskNumber = $Disk.Number
                                                                                            $LocalizedData.Model = $Disk.Model
                                                                                            $LocalizedData.SerialNumber = $Disk.SerialNumber
                                                                                            $LocalizedData.PartitionStyle = $Disk.PartitionStyle
                                                                                            $LocalizedData.DiskSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Disk.Size
                                                                                        }
                                                                                        $LocalDiskReport += $TempLocalDiskReport
                                                                                    } catch {
                                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies Local Disks $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "$($LocalizedData.LocalDisksTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                    List = $false
                                                                                    ColumnWidths = 20, 20, 20, 20, 20
                                                                                }
                                                                                if ($Report.ShowTableCaptions) {
                                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                }
                                                                                $LocalDiskReport | Sort-Object -Property $LocalizedData.DiskNumber | Table @TableParams
                                                                            }
                                                                        }
                                                                    } catch {
                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies Fibre Channel Section: $($_.Exception.Message)"
                                                                    }
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    #                       Backup Proxy SAN Disk Inventory Section                              #
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    try {
                                                                        $SanDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -eq 'iSCSI' -or $_.BusType -eq 'Fibre Channel' } }
                                                                        if ($SanDisks) {
                                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SanDisksHeading {
                                                                                $SanDiskReport = @()
                                                                                foreach ($Disk in $SanDisks) {
                                                                                    try {
                                                                                        $TempSanDiskReport = [PSCustomObject]@{
                                                                                            $LocalizedData.DiskNumber = $Disk.Number
                                                                                            $LocalizedData.Model = $Disk.Model
                                                                                            $LocalizedData.SerialNumber = $Disk.SerialNumber
                                                                                            $LocalizedData.PartitionStyle = $Disk.PartitionStyle
                                                                                            $LocalizedData.DiskSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Disk.Size
                                                                                        }
                                                                                        $SanDiskReport += $TempSanDiskReport
                                                                                    } catch {
                                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies Fibre Channel $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "$($LocalizedData.SanDisksTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                    List = $false
                                                                                    ColumnWidths = 20, 20, 20, 20, 20
                                                                                }
                                                                                if ($Report.ShowTableCaptions) {
                                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                }
                                                                                $SanDiskReport | Sort-Object -Property $LocalizedData.DiskNumber | Table @TableParams
                                                                            }
                                                                        }
                                                                    } catch {
                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies Fibre Channel Section: $($_.Exception.Message)"
                                                                    }
                                                                }
                                                                try {
                                                                    $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock { Get-Volume | Where-Object { $_.DriveType -ne 'CD-ROM' -and $NUll -ne $_.DriveLetter } }
                                                                    if ($HostVolumes) {
                                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.HostVolumesHeading {
                                                                            $HostVolumeReport = @()
                                                                            foreach ($HostVolume in $HostVolumes) {
                                                                                try {
                                                                                    $TempHostVolumeReport = [PSCustomObject]@{
                                                                                        $LocalizedData.DriveLetter = $HostVolume.DriveLetter
                                                                                        $LocalizedData.FileSystemLabel = $HostVolume.FileSystemLabel
                                                                                        $LocalizedData.FileSystem = $HostVolume.FileSystem
                                                                                        $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $HostVolume.Size
                                                                                        $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $HostVolume.SizeRemaining
                                                                                        $LocalizedData.HealthStatus = $HostVolume.HealthStatus
                                                                                    }
                                                                                    $HostVolumeReport += $TempHostVolumeReport
                                                                                } catch {
                                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Host Volumes $($HostVolume.DriveLetter) Section: $($_.Exception.Message)"
                                                                                }
                                                                            }
                                                                            $TableParams = @{
                                                                                Name = "$($LocalizedData.VolumesTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                List = $false
                                                                                ColumnWidths = 15, 15, 15, 20, 20, 15
                                                                            }
                                                                            if ($Report.ShowTableCaptions) {
                                                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                            }
                                                                            $HostVolumeReport | Sort-Object -Property $LocalizedData.DriveLetter | Table @TableParams
                                                                        }
                                                                    }
                                                                } catch {
                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Host Volumes Section: $($_.Exception.Message)"
                                                                }
                                                                #---------------------------------------------------------------------------------------------#
                                                                #                       Backup Proxy Network Inventory Section                               #
                                                                #---------------------------------------------------------------------------------------------#
                                                                if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                                                                    try {
                                                                        $HostAdapters = Invoke-Command -Session $PssSession { Get-NetAdapter }
                                                                        if ($HostAdapters) {
                                                                            Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.NetworkAdaptersHeading {
                                                                                $HostAdaptersReport = @()
                                                                                foreach ($HostAdapter in $HostAdapters) {
                                                                                    try {
                                                                                        $TempHostAdaptersReport = [PSCustomObject]@{
                                                                                            $LocalizedData.AdapterName = $HostAdapter.Name
                                                                                            $LocalizedData.AdapterDescription = $HostAdapter.InterfaceDescription
                                                                                            $LocalizedData.MacAddress = $HostAdapter.MacAddress
                                                                                            $LocalizedData.LinkSpeed = $HostAdapter.LinkSpeed
                                                                                        }
                                                                                        $HostAdaptersReport += $TempHostAdaptersReport
                                                                                    } catch {
                                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies Network Adapter $($HostAdapter.Name) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "$($LocalizedData.NetworkAdaptersTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                    List = $false
                                                                                    ColumnWidths = 30, 35, 20, 15
                                                                                }
                                                                                if ($Report.ShowTableCaptions) {
                                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                }
                                                                                $HostAdaptersReport | Sort-Object -Property $LocalizedData.AdapterName | Table @TableParams
                                                                            }
                                                                        }
                                                                    } catch {
                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies Network Adapter Section: $($_.Exception.Message)"
                                                                    }
                                                                    try {
                                                                        $NetIPs = Invoke-Command -Session $PssSession { Get-NetIPConfiguration | Where-Object -FilterScript { ($_.NetAdapter.Status -eq 'Up') } }
                                                                        if ($NetIPs) {
                                                                            Section -Style NOTOCHeading4 -ExcludeFromTOC $LocalizedData.IpAddressHeading {
                                                                                $NetIpsReport = @()
                                                                                foreach ($NetIp in $NetIps) {
                                                                                    try {
                                                                                        $TempNetIpsReport = [PSCustomObject]@{
                                                                                            $LocalizedData.InterfaceName = $NetIp.InterfaceAlias
                                                                                            $LocalizedData.InterfaceDescription = $NetIp.InterfaceDescription
                                                                                            $LocalizedData.IPv4Addresses = $NetIp.IPv4Address.IPAddress -join ','
                                                                                            $LocalizedData.SubnetMask = $NetIp.IPv4Address[0].PrefixLength
                                                                                            $LocalizedData.IPv4Gateway = $NetIp.IPv4DefaultGateway.NextHop
                                                                                        }
                                                                                        $NetIpsReport += $TempNetIpsReport
                                                                                    } catch {
                                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies IP Address $($NetIp.InterfaceAlias) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "$($LocalizedData.IpAddressTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                    List = $false
                                                                                    ColumnWidths = 25, 25, 20, 10, 20
                                                                                }
                                                                                if ($Report.ShowTableCaptions) {
                                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                }
                                                                                $NetIpsReport | Sort-Object -Property $LocalizedData.InterfaceName | Table @TableParams
                                                                            }
                                                                        }
                                                                    } catch {
                                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies IP Address Section: $($_.Exception.Message)"
                                                                    }
                                                                }
                                                            }
                                                            if ($PssSession) {
                                                                # Remove used PSSession
                                                                Write-PScriboMessage "Clearing PowerShell Session $($PssSession.Id)"
                                                                Remove-PSSession -Session $PssSession
                                                            }

                                                            if ($CimSession) {
                                                                # Remove used CIMSession
                                                                Write-PScriboMessage "Clearing CIM Session $($CimSession.Id)"
                                                                Remove-CimSession -CimSession $CimSession
                                                            }
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies Section: $($_.Exception.Message)"
                                                    }
                                                } else {
                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Section: Unable to connect to $($BackupProxies.Host.Name) throuth WinRM, removing server from Hardware Inventory section"
                                                }
                                            }
                                        }
                                        if ($vSphereVBProxyObj) {
                                            Section -Style Heading4 $LocalizedData.HardwareSoftwareHeading {
                                                $vSphereVBProxyObj
                                            }
                                        }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "VMware Backup Proxies Hardware & Software Inventory Section: $($_.Exception.Message)"
                            }
                            #---------------------------------------------------------------------------------------------#
                            #                    VMware Backup Proxy Service information Section                           #
                            #---------------------------------------------------------------------------------------------#
                            if ($HealthCheck.Infrastructure.Server) {
                                try {
                                    if ($InfoLevel.Infrastructure.Proxy -ge 1 -and $Options.EnableHardwareInventory) {
                                        Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                        Write-PScriboMessage 'Collecting Veeam Services Information.'
                                        $BackupProxies = Get-VBRViProxy | Where-Object { $_.Host.Type -eq 'Windows' } | Sort-Object -Property Name
                                        foreach ($BackupProxy in $BackupProxies) {
                                            if ($ClientOSVersion -eq 'Win32NT') {
                                                if (Test-WSMan -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ComputerName $BackupProxy.Host.Name -ErrorAction SilentlyContinue) {
                                                    try {
                                                        # $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction SilentlyContinue
                                                        $PssSession = try { New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop -Name 'VMwareBackupProxyService' } catch {
                                                            if (-not $_.Exception.MessageId) {
                                                                $ErrorMessage = $_.FullyQualifiedErrorId
                                                            } else { $ErrorMessage = $_.Exception.MessageId }
                                                            Write-PScriboMessage -IsWarning "Backup Proxy Service Section: New-PSSession: Unable to connect to $($BackupProxy.Host.Name): $ErrorMessage"
                                                        }
                                                        if ($PssSession) {
                                                            $Available = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service 'W32Time' | Select-Object DisplayName, Name, Status }
                                                            Write-PScriboMessage "Collecting Backup Proxy Service information from $($BackupProxy.Name)."
                                                            $Services = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service Veeam* }
                                                            if ($PssSession) {
                                                                Remove-PSSession -Session $PssSession
                                                            }
                                                            if ($Available -and $Services) {
                                                                Section -Style NOTOCHeading4 -ExcludeFromTOC "$($LocalizedData.HealthCheckSectionPrefix) $($BackupProxy.Host.Name.Split('.')[0]) $($LocalizedData.ServicesStatus)" {
                                                                    $OutObj = @()
                                                                    foreach ($Service in $Services) {
                                                                        Write-PScriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupProxy.Name)."
                                                                        $inObj = [ordered] @{
                                                                            $LocalizedData.DisplayName = $Service.DisplayName
                                                                            $LocalizedData.ShortName = $Service.Name
                                                                            $LocalizedData.Status = $Service.Status
                                                                        }
                                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                                    }

                                                                    if ($HealthCheck.Infrastructure.Server) {
                                                                        $OutObj | Where-Object { $_."$($LocalizedData.Status)" -notlike 'Running' } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.HealthCheckServicesTableHeading) - $($BackupProxy.Host.Name.Split('.')[0])"
                                                                        List = $false
                                                                        ColumnWidths = 45, 35, 20
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property $LocalizedData.DisplayName | Table @TableParams
                                                                }
                                                            }
                                                        } else { Write-PScriboMessage -IsWarning "VMware Backup Proxies Services Status Section: Unable to connect to $($BackupProxy.Host.Name)" }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "VMware Backup Proxies $($BackupProxy.Host.Name) Services Status Section: $($_.Exception.Message)"
                                                    }
                                                } else {
                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Section: Unable to connect to $($BackupProxies.Host.Name) throuth WinRM, removing server from Veeam Services section"
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Services Status Section: $($_.Exception.Message)"
                                }
                            }
                            if ($Options.EnableDiagrams) {
                                try {
                                    try {
                                        $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-vSphere-Proxy' -DiagramOutput base64
                                    } catch {
                                        Write-PScriboMessage -IsWarning "VMware Backup Proxy Diagram: $($_.Exception.Message)"
                                    }
                                    if ($Graph) {
                                        $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                        PageBreak
                                        Section -Style Heading3 $LocalizedData.VMwareDiagramHeading {
                                            Image -Base64 $Graph -Text $LocalizedData.VMwareDiagramAltText -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
                                            PageBreak
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "VMware Backup Proxy Diagram Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                       Hyper-V Backup Prxy information Section                               #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        if ($BackupProxies = Get-VBRHvProxy | Sort-Object -Property Name) {
                            Section -Style Heading4 $LocalizedData.HyperVHeading {
                                $OutObj = @()
                                if ($InfoLevel.Infrastructure.Proxy -eq 1) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    Write-PScriboMessage 'Collecting Summary Information.'
                                    foreach ($BackupProxy in $BackupProxies) {
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name = $BackupProxy.Name
                                                $LocalizedData.Type = $BackupProxy.Type
                                                $LocalizedData.MaxTasksCount = $BackupProxy.MaxTasksCount
                                                $LocalizedData.Disabled = $BackupProxy.IsDisabled
                                                $LocalizedData.Status = switch (($BackupProxy.Host).IsUnavailable) {
                                                    'False' { $LocalizedData.Available }
                                                    'True' { $LocalizedData.Unavailable }
                                                    default { ($BackupProxy.Host).IsUnavailable }
                                                }
                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies $($BackupProxy.Name) Section: $($_.Exception.Message)"
                                        }
                                    }

                                    if ($HealthCheck.Infrastructure.Proxy) {
                                        $OutObj | Where-Object { $_."$($LocalizedData.Status)" -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                                        List = $false
                                        ColumnWidths = 35, 15, 15, 15, 20
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                                if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    foreach ($BackupProxy in $BackupProxies) {
                                        try {

                                            $inObj = [ordered] @{
                                                $LocalizedData.Name = $BackupProxy.Name
                                                $LocalizedData.HostName = $BackupProxy.Host.Name
                                                $LocalizedData.Type = $BackupProxy.Type
                                                $LocalizedData.Disabled = $BackupProxy.IsDisabled
                                                $LocalizedData.MaxTasksCount = $BackupProxy.MaxTasksCount
                                                $LocalizedData.AutoDetectVolumes = $BackupProxy.Options.IsAutoDetectVolumes
                                                $LocalizedData.OsType = $BackupProxy.Host.Type
                                                $LocalizedData.ServicesCredential = $BackupProxy.Host.ProxyServicesCreds.Name
                                                $LocalizedData.Status = switch (($BackupProxy.Host).IsUnavailable) {
                                                    'False' { $LocalizedData.Available }
                                                    'True' { $LocalizedData.Unavailable }
                                                    default { ($BackupProxy.Host).IsUnavailable }
                                                }
                                            }
                                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                            if ($HealthCheck.Infrastructure.Proxy) {
                                                $OutObj | Where-Object { $_."$($LocalizedData.Status)" -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.TableHeading) - $($BackupProxy.Host.Name.Split('.')[0])"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies $($BackupProxy.Name) Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                    Hyper-V Backup Proxy Inventory Summary Section                         #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    Write-PScriboMessage "Hardware Inventory Status set as $($Options.EnableHardwareInventory)."
                                    if ($Options.EnableHardwareInventory) {
                                        Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                        Write-PScriboMessage 'Collecting Hardware/Software Inventory Summary.'
                                        if ($BackupProxies = Get-VBRHvProxy | Sort-Object -Property Name) {
                                            $HyperVBProxyObj = foreach ($BackupProxy in $BackupProxies) {
                                                if ($ClientOSVersion -eq 'Win32NT') {
                                                    if (Test-WSMan -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ComputerName $BackupProxy.Host.Name -ErrorAction SilentlyContinue) {
                                                        try {
                                                            Write-PScriboMessage "Collecting Backup Proxy Inventory Summary from $($BackupProxy.Host.Name)."
                                                            # $CimSession = New-CimSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                                                            # $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction SilentlyContinue
                                                            $CimSession = try { New-CimSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -Name 'HardwareInventory' -ErrorAction Stop } catch { Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Hardware/Software Section: New-CimSession: Unable to connect to $($BackupProxy.Host.Name): $($_.Exception.MessageId)" }

                                                            $PssSession = try { New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop -Name 'HyperVHardwareInventory' } catch {
                                                                if (-not $_.Exception.MessageId) {
                                                                    $ErrorMessage = $_.FullyQualifiedErrorId
                                                                } else { $ErrorMessage = $_.Exception.MessageId }
                                                                Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Hardware/Software Section: New-PSSession: Unable to connect to $($BackupProxy.Host.Name): $ErrorMessage"
                                                            }
                                                            if ($PssSession) {
                                                                $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                                            } else { Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Inventory Section: Unable to connect to $($BackupProxy.Host.Name)" }
                                                            if ($HW) {
                                                                $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                                                $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                                                $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                                                Section -Style Heading5 $($BackupProxy.Host.Name.Split('.')[0]) {
                                                                    $OutObj = @()
                                                                    $inObj = [ordered] @{
                                                                        $LocalizedData.Name = $HW.CsDNSHostName
                                                                        $LocalizedData.WindowsProductName = $HW.WindowsProductName
                                                                        $LocalizedData.WindowsCurrentVersion = $HW.WindowsCurrentVersion
                                                                        $LocalizedData.WindowsBuildNumber = $HW.OsVersion
                                                                        $LocalizedData.WindowsInstallType = $HW.WindowsInstallationType
                                                                        $LocalizedData.ActiveDirectoryDomain = $HW.CsDomain
                                                                        $LocalizedData.WindowsInstallationDate = $HW.OsInstallDate
                                                                        $LocalizedData.TimeZone = $HW.TimeZone
                                                                        $LocalizedData.LicenseType = $License.ProductKeyChannel
                                                                        $LocalizedData.PartialProductKey = $License.PartialProductKey
                                                                        $LocalizedData.Manufacturer = $HW.CsManufacturer
                                                                        $LocalizedData.Model = $HW.CsModel
                                                                        $LocalizedData.SerialNumber = $HWBIOS.SerialNumber
                                                                        $LocalizedData.BiosType = $HW.BiosFirmwareType
                                                                        $LocalizedData.BiosVersion = $HWBIOS.Version
                                                                        $LocalizedData.ProcessorManufacturer = $HWCPU[0].Manufacturer
                                                                        $LocalizedData.ProcessorModel = $HWCPU[0].Name
                                                                        $LocalizedData.NumberOfCpuCores = $HWCPU[0].NumberOfCores
                                                                        $LocalizedData.NumberOfLogicalCores = $HWCPU[0].NumberOfLogicalProcessors
                                                                        $LocalizedData.PhysicalMemoryGb = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $HW.CsTotalPhysicalMemory
                                                                    }
                                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                                    if ($HealthCheck.Infrastructure.Server) {
                                                                        $OutObj | Where-Object { $_."$($LocalizedData.NumberOfCpuCores)" -lt 4 } | Set-Style -Style Warning -Property $LocalizedData.NumberOfCpuCores
                                                                        if ([int]([regex]::Matches($OutObj."$($LocalizedData.PhysicalMemoryGb)", '\d+(?!.*\d+)').value) -lt 8) { $OutObj | Set-Style -Style Warning -Property $LocalizedData.PhysicalMemoryGb }
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "$($LocalizedData.InventoryTableHeading) - $($BackupProxy.Host.Name.Split('.')[0])"
                                                                        List = $true
                                                                        ColumnWidths = 40, 60
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Table @TableParams
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    #                       Backup Proxy Local Disk Inventory Section                            #
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    if ($InfoLevel.Infrastructure.Proxy -ge 3) {
                                                                        try {
                                                                            $HostDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -ne 'iSCSI' -and $_.BusType -ne 'Fibre Channel' } }
                                                                            if ($HostDisks) {
                                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.LocalDisksHeading {
                                                                                    $LocalDiskReport = @()
                                                                                    foreach ($Disk in $HostDisks) {
                                                                                        try {
                                                                                            $TempLocalDiskReport = [PSCustomObject]@{
                                                                                                $LocalizedData.DiskNumber = $Disk.Number
                                                                                                $LocalizedData.Model = $Disk.Model
                                                                                                $LocalizedData.SerialNumber = $Disk.SerialNumber
                                                                                                $LocalizedData.PartitionStyle = $Disk.PartitionStyle
                                                                                                $LocalizedData.DiskSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Disk.Size
                                                                                            }
                                                                                            $LocalDiskReport += $TempLocalDiskReport
                                                                                        } catch {
                                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Local Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                        }
                                                                                    }
                                                                                    $TableParams = @{
                                                                                        Name = "$($LocalizedData.LocalDisksTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                        List = $false
                                                                                        ColumnWidths = 20, 20, 20, 20, 20
                                                                                    }
                                                                                    if ($Report.ShowTableCaptions) {
                                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                    }
                                                                                    $LocalDiskReport | Sort-Object -Property $LocalizedData.DiskNumber | Table @TableParams
                                                                                }
                                                                            }
                                                                        } catch {
                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Local Disk Section: $($_.Exception.Message)"
                                                                        }
                                                                        #---------------------------------------------------------------------------------------------#
                                                                        #                       Backup Proxy SAN Disk Inventory Section                              #
                                                                        #---------------------------------------------------------------------------------------------#
                                                                        try {
                                                                            $SanDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -eq 'iSCSI' -or $_.BusType -eq 'Fibre Channel' } }
                                                                            if ($SanDisks) {
                                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.SanDisksHeading {
                                                                                    $SanDiskReport = @()
                                                                                    foreach ($Disk in $SanDisks) {
                                                                                        try {
                                                                                            $TempSanDiskReport = [PSCustomObject]@{
                                                                                                $LocalizedData.DiskNumber = $Disk.Number
                                                                                                $LocalizedData.Model = $Disk.Model
                                                                                                $LocalizedData.SerialNumber = $Disk.SerialNumber
                                                                                                $LocalizedData.PartitionStyle = $Disk.PartitionStyle
                                                                                                $LocalizedData.DiskSize = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Disk.Size
                                                                                            }
                                                                                            $SanDiskReport += $TempSanDiskReport
                                                                                        } catch {
                                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies SAN Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                        }
                                                                                    }
                                                                                    $TableParams = @{
                                                                                        Name = "$($LocalizedData.SanDisksTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                        List = $false
                                                                                        ColumnWidths = 20, 20, 20, 20, 20
                                                                                    }
                                                                                    if ($Report.ShowTableCaptions) {
                                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                    }
                                                                                    $SanDiskReport | Sort-Object -Property $LocalizedData.DiskNumber | Table @TableParams
                                                                                }
                                                                            }
                                                                        } catch {
                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Local Disk Section: $($_.Exception.Message)"
                                                                        }
                                                                    }
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    #                       Backup Proxy Volume Inventory Section                                #
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    try {
                                                                        $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock { Get-Volume | Where-Object { $_.DriveType -ne 'CD-ROM' -and $NUll -ne $_.DriveLetter } }
                                                                        if ($HostVolumes) {
                                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.HostVolumesHeading {
                                                                                $HostVolumeReport = @()
                                                                                foreach ($HostVolume in $HostVolumes) {
                                                                                    try {
                                                                                        $TempHostVolumeReport = [PSCustomObject]@{
                                                                                            $LocalizedData.DriveLetter = $HostVolume.DriveLetter
                                                                                            $LocalizedData.FileSystemLabel = $HostVolume.FileSystemLabel
                                                                                            $LocalizedData.FileSystem = $HostVolume.FileSystem
                                                                                            $LocalizedData.Size = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $HostVolume.Size
                                                                                            $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $HostVolume.SizeRemaining
                                                                                            $LocalizedData.HealthStatus = $HostVolume.HealthStatus
                                                                                        }
                                                                                        $HostVolumeReport += $TempHostVolumeReport
                                                                                    } catch {
                                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Host Volume $($HostVolume.DriveLetter) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "$($LocalizedData.VolumesTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                    List = $false
                                                                                    ColumnWidths = 15, 15, 15, 20, 20, 15
                                                                                }
                                                                                if ($Report.ShowTableCaptions) {
                                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                }
                                                                                $HostVolumeReport | Sort-Object -Property $LocalizedData.DriveLetter | Table @TableParams
                                                                            }
                                                                        }
                                                                    } catch {
                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Host Volume Section: $($_.Exception.Message)"
                                                                    }
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    #                       Backup Proxy Network Inventory Section                               #
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                                                                        try {
                                                                            $HostAdapters = Invoke-Command -Session $PssSession { Get-NetAdapter }
                                                                            if ($HostAdapters) {
                                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.NetworkAdaptersHeading {
                                                                                    $HostAdaptersReport = @()
                                                                                    foreach ($HostAdapter in $HostAdapters) {
                                                                                        try {
                                                                                            $TempHostAdaptersReport = [PSCustomObject]@{
                                                                                                $LocalizedData.AdapterName = $HostAdapter.Name
                                                                                                $LocalizedData.AdapterDescription = $HostAdapter.InterfaceDescription
                                                                                                $LocalizedData.MacAddress = $HostAdapter.MacAddress
                                                                                                $LocalizedData.LinkSpeed = $HostAdapter.LinkSpeed
                                                                                            }
                                                                                            $HostAdaptersReport += $TempHostAdaptersReport
                                                                                        } catch {
                                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Network Adapter $($HostAdapter.Name) Section: $($_.Exception.Message)"
                                                                                        }
                                                                                    }
                                                                                    $TableParams = @{
                                                                                        Name = "$($LocalizedData.NetworkAdaptersTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                        List = $false
                                                                                        ColumnWidths = 30, 35, 20, 15
                                                                                    }
                                                                                    if ($Report.ShowTableCaptions) {
                                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                    }
                                                                                    $HostAdaptersReport | Sort-Object -Property $LocalizedData.AdapterName | Table @TableParams
                                                                                }
                                                                            }
                                                                        } catch {
                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Network Adapter Section: $($_.Exception.Message)"
                                                                        }
                                                                        try {
                                                                            $NetIPs = Invoke-Command -Session $PssSession { Get-NetIPConfiguration | Where-Object -FilterScript { ($_.NetAdapter.Status -eq 'Up') } }
                                                                            if ($NetIPs) {
                                                                                Section -Style NOTOCHeading6 -ExcludeFromTOC $LocalizedData.IpAddressHeading {
                                                                                    $NetIpsReport = @()
                                                                                    foreach ($NetIp in $NetIps) {
                                                                                        try {
                                                                                            $TempNetIpsReport = [PSCustomObject]@{
                                                                                                $LocalizedData.InterfaceName = $NetIp.InterfaceAlias
                                                                                                $LocalizedData.InterfaceDescription = $NetIp.InterfaceDescription
                                                                                                $LocalizedData.IPv4Addresses = $NetIp.IPv4Address.IPAddress -join ','
                                                                                                $LocalizedData.SubnetMask = $NetIp.IPv4Address[0].PrefixLength
                                                                                                $LocalizedData.IPv4Gateway = $NetIp.IPv4DefaultGateway.NextHop
                                                                                            }
                                                                                            $NetIpsReport += $TempNetIpsReport
                                                                                        } catch {
                                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies IP Address $($NetIp.InterfaceAlias) Section: $($_.Exception.Message)"
                                                                                        }
                                                                                    }
                                                                                    $TableParams = @{
                                                                                        Name = "$($LocalizedData.IpAddressTableHeading) - $($BackupProxies.Host.Name.Split('.')[0])"
                                                                                        List = $false
                                                                                        ColumnWidths = 25, 25, 20, 10, 20
                                                                                    }
                                                                                    if ($Report.ShowTableCaptions) {
                                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                                    }
                                                                                    $NetIpsReport | Sort-Object -Property $LocalizedData.InterfaceName | Table @TableParams
                                                                                }
                                                                            }
                                                                        } catch {
                                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies IP Address Section: $($_.Exception.Message)"
                                                                        }
                                                                    }
                                                                }
                                                                if ($PssSession) {
                                                                    # Remove used PSSession
                                                                    Write-PScriboMessage "Clearing PowerShell Session $($PssSession.Id)"
                                                                    Remove-PSSession -Session $PssSession
                                                                }

                                                                if ($CimSession) {
                                                                    # Remove used CIMSession
                                                                    Write-PScriboMessage "Clearing CIM Session $($CimSession.Id)"
                                                                    Remove-CimSession -CimSession $CimSession
                                                                }
                                                            }
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Hardware & Software Inventory Section: $($_.Exception.Message)"
                                                        }
                                                    } else {
                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Section: Unable to connect to $($BackupProxies.Host.Name) throuth WinRM, removing server from Hardware Inventory section"
                                                    }
                                                }
                                            }
                                            if ($HyperVBProxyObj) {
                                                Section -Style Heading4 $LocalizedData.HardwareSoftwareHeading {
                                                    $HyperVBProxyObj
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Section: $($_.Exception.Message)"
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                    Hyper-V Backup Proxy Service information Section                          #
                                #---------------------------------------------------------------------------------------------#
                                if ($HealthCheck.Infrastructure.Server) {
                                    try {
                                        if ($InfoLevel.Infrastructure.Proxy -ge 1 -and ($Options.EnableHardwareInventory)) {
                                            Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                            Write-PScriboMessage 'Collecting Veeam Service Information.'
                                            $BackupProxies = Get-VBRHvProxy | Sort-Object -Property Name
                                            foreach ($BackupProxy in $BackupProxies) {
                                                if ($ClientOSVersion -eq 'Win32NT') {

                                                    if (Test-WSMan -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ComputerName $BackupProxy.Host.Name -ErrorAction SilentlyContinue) {
                                                        try {
                                                            $PssSession = try { New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop -Name 'HyperVBackupProxyService' } catch {
                                                                if (-not $_.Exception.MessageId) {
                                                                    $ErrorMessage = $_.FullyQualifiedErrorId
                                                                } else { $ErrorMessage = $_.Exception.MessageId }
                                                                Write-PScriboMessage -IsWarning "Hyper-V Backup Proxy Service Section: New-PSSession: Unable to connect to $($BackupProxy.Host.Name): $ErrorMessage"
                                                            }
                                                            if ($PssSession) {
                                                                $Available = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service 'W32Time' | Select-Object DisplayName, Name, Status }
                                                                Write-PScriboMessage "Collecting Backup Proxy Service information from $($BackupProxy.Name)."
                                                                $Services = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service Veeam* }
                                                                if ($PssSession) {
                                                                    Remove-PSSession -Session $PssSession
                                                                }
                                                                if ($Available -and $Services) {
                                                                    Section -Style NOTOCHeading4 -ExcludeFromTOC "$($LocalizedData.HealthCheckSectionPrefix) $($BackupProxy.Host.Name.Split('.')[0]) $($LocalizedData.ServicesStatus)" {
                                                                        $OutObj = @()
                                                                        foreach ($Service in $Services) {
                                                                            Write-PScriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupProxy.Name)."
                                                                            $inObj = [ordered] @{
                                                                                $LocalizedData.DisplayName = $Service.DisplayName
                                                                                $LocalizedData.ShortName = $Service.Name
                                                                                $LocalizedData.Status = $Service.Status
                                                                            }
                                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                                        }

                                                                        if ($HealthCheck.Infrastructure.Server) {
                                                                            $OutObj | Where-Object { $_."$($LocalizedData.Status)" -notlike 'Running' } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.HealthCheckServicesTableHeading) - $($BackupProxy.Host.Name.Split('.')[0])"
                                                                            List = $false
                                                                            ColumnWidths = 45, 35, 20
                                                                        }
                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property $LocalizedData.DisplayName | Table @TableParams
                                                                    }
                                                                }
                                                            } else { Write-PScriboMessage -IsWarning "VMware Backup Proxies Services Status Section: Unable to connect to $($BackupProxy.Host.Name)" }
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Services Status - $($BackupProxy.Host.Name.Split('.')[0]) Section: $($_.Exception.Message)"
                                                        }
                                                    } else {
                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Section: Unable to connect to $($BackupProxies.Host.Name) throuth WinRM, removing server from Veeam Services section"
                                                    }
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Services Status Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($Options.EnableDiagrams) {
                                    try {
                                        try {
                                            $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-HyperV-Proxy' -DiagramOutput base64
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxy Diagram: $($_.Exception.Message)"
                                        }
                                        if ($Graph) {
                                            $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                            PageBreak
                                            Section -Style Heading3 $LocalizedData.HyperVDiagramHeading {
                                                Image -Base64 $Graph -Text $LocalizedData.HyperVDiagramAltText -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
                                                PageBreak
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxy Diagram Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Proxies Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Proxies'
    }

}