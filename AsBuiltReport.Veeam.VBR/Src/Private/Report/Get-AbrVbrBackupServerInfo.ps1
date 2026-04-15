
function Get-AbrVbrBackupServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.1
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
        Write-PScriboMessage "Discovering Veeam VB&R Server information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrBackupServerInfo
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Backup Server'
    }

    process {
        try {
            $script:BackupServers = switch ($VbrVersion) {
                { $_ -lt 13 } { Get-VBRServer -Type Local }
                default { Get-VBRServer | Where-Object { $_.Description -eq 'Backup server' } }
            }
            if (($VbrVersion -gt 13) -and (Get-VBRServer | Where-Object { $_.Description -eq 'Backup server' -and $_.Type -eq 'Linux' } )) {
                $VeeamVersion = @{
                    DisplayVersion = $VbrVersion
                }
                $VeeamDBFlavor = @{
                    SqlActiveConfiguration = 'PostgreSql'
                }

                $VeeamDBInfo = @{
                    SqlDatabaseName = 'VeeamBackup'
                    SqlHostName = 'localhost'
                    SqlHostPort = '5432'
                }

                $VeeamInfo = @{
                    BackupServerPort = '443'
                    SecureConnectionsPort = '443'
                    CloudServerPort = '10003'
                    CloudSvcPort = '6169'
                    CorePath = '/opt/veeam'
                }
            }
            if ($BackupServers) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($BackupServer in $BackupServers) {
                            if (-not ($BackupServer.Type -eq 'Linux' -and $BackupServer.Description -eq 'Backup server')) {
                                if ($ClientOSVersion -eq 'Win32NT') {
                                    $CimSession = try { New-CimSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -Name 'CIMBackupServer' -ErrorAction Stop } catch { Write-PScriboMessage -IsWarning "Backup Server Section: New-CimSession: Unable to connect to $($BackupServer.Name): $($_.Exception.MessageId)" }
                                }

                                if ($ClientOSVersion -eq 'Win32NT') {
                                    $PssSession = try { New-PSSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop -Name 'PSSBackupServer' } catch {
                                        if (-not $_.Exception.MessageId) {
                                            $ErrorMessage = $_.FullyQualifiedErrorId
                                        } else { $ErrorMessage = $_.Exception.MessageId }
                                        Write-PScriboMessage -IsWarning "Backup Server Section: New-PSSession: Unable to connect to $($BackupServer.Name): $ErrorMessage"
                                    }
                                }
                            }
                            $SecurityOptions = Get-VBRSecurityOptions
                            if ($CimSession) {
                                try { $DomainJoined = Get-CimInstance -Class Win32_ComputerSystem -Property PartOfDomain -CimSession $CimSession } catch { 'Unknown' }
                            }
                            Write-PScriboMessage ($LocalizedData.Collecting -f $BackupServer.Name)

                            if (-not ($BackupServer.Type -eq 'Linux' -and $BackupServer.Description -eq 'Backup server')) {
                                if ($PssSession) {
                                    try {
                                        $script:VeeamVersion = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ChildItem -Recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion }
                                    } catch { Write-PScriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)" }
                                    try {
                                        $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                                    } catch { Write-PScriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)" }
                                    try {
                                        $VeeamDBFlavor = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations' }
                                    } catch { Write-PScriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)" }
                                    try {
                                        $VeeamDBInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\$(($Using:VeeamDBFlavor).SqlActiveConfiguration)" }
                                    } catch { Write-PScriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)" }
                                } else {
                                    Write-PScriboMessage -IsWarning "Backup Server Section: Unable to get Backup Server information: WinRM disabled or not configured on $($BackupServer.Name)."
                                }
                            }


                            $inObj = [ordered] @{
                                $LocalizedData.ServerName = $BackupServer.Name
                                $LocalizedData.IsDomainJoined = $DomainJoined.PartOfDomain
                                $LocalizedData.Version = switch (($VeeamVersion).count) {
                                    0 { '--' }
                                    default { $VeeamVersion.DisplayVersion }
                                }
                                $LocalizedData.DatabaseType = switch ([string]::IsNullOrEmpty($VeeamDBFlavor.SqlActiveConfiguration)) {
                                    $true { '--' }
                                    $false { $VeeamDBFlavor.SqlActiveConfiguration }
                                    default { 'Unknown' }
                                }
                                $LocalizedData.DatabaseName = switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlDatabaseName)) {
                                    $true { '--' }
                                    $false { $VeeamDBInfo.SqlDatabaseName }
                                    default { 'Unknown' }
                                }
                                $LocalizedData.DatabaseServer = switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlHostName)) {
                                    $true { '--' }
                                    $false { $VeeamDBInfo.SqlHostName }
                                    default { 'Unknown' }
                                }
                                $LocalizedData.DatabasePort = switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlHostPort)) {
                                    $true { '--' }
                                    $false { "$($VeeamDBInfo.SqlHostPort)/TCP" }
                                    default { 'Unknown' }
                                }
                                $LocalizedData.ConnectionPorts = switch (($VeeamInfo.BackupServerPort).count) {
                                    0 { '--' }
                                    default { "Backup Server Port: $($VeeamInfo.BackupServerPort)`r`nSecure Connections Port: $($VeeamInfo.SecureConnectionsPort)`r`nCloud Server Port: $($VeeamInfo.CloudServerPort)`r`nCloud Service Port: $($VeeamInfo.CloudSvcPort)" }
                                }
                                $LocalizedData.InstallPath = switch (($VeeamInfo.CorePath).count) {
                                    0 { '--' }
                                    default { $VeeamInfo.CorePath }
                                }
                                $LocalizedData.AuditLogsPath = $SecurityOptions.AuditLogsPath
                                $LocalizedData.CompressOldAuditLogs = $SecurityOptions.CompressOldAuditLogs
                                $LocalizedData.FipsCompliantMode = switch ($SecurityOptions.FipsCompliantModeEnabled) {
                                    'True' { 'Enabled' }
                                    'False' { 'Disabled' }
                                }
                                $LocalizedData.LinuxHostAuthentication = switch ($SecurityOptions.HostPolicy.Type) {
                                    'All' { 'Add all discovered host to the list automatically' }
                                    'KnownHosts' { 'Add unknown host to the list manually' }
                                }
                                $LocalizedData.LoggingLevel = $VeeamInfo.LoggingLevel

                            }

                            if ($Null -notlike $VeeamInfo.LogDirectory) {
                                $inObj.add($LocalizedData.LogDirectory, ($VeeamInfo.LogDirectory))
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server Section: $($_.Exception.Message)"
                    }

                    if ($HealthCheck.Infrastructure.BackupServer) {
                        $OutObj | Where-Object { $_."$($LocalizedData.LoggingLevel)" -gt 4 } | Set-Style -Style Warning -Property $LocalizedData.LoggingLevel
                        $OutObj | Where-Object { $_."$($LocalizedData.IsDomainJoined)" -eq 'Yes' } | Set-Style -Style Warning -Property $LocalizedData.IsDomainJoined
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $($BackupServer.Name.Split('.')[0])"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    if ($HealthCheck.Infrastructure.BestPractice) {
                        if ($OutObj | Where-Object { $_."$($LocalizedData.IsDomainJoined)" -eq 'Yes' }) {
                            Paragraph $LocalizedData.healthCheck -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text $LocalizedData.bestPractice -Bold
                                Text $LocalizedData.domainJoinBestPracticeText
                            }
                            BlankLine
                            Paragraph {
                                Text $LocalizedData.Reference -Bold
                                Text $LocalizedData.domainJoinReference
                            }
                            BlankLine
                        }
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                  Backup Server Inventory & Software Summary Section                         #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        Write-PScriboMessage "Hardware Inventory Status set as $($Options.EnableHardwareInventory)."
                        if ($Options.EnableHardwareInventory -and ($PssSession)) {
                            Write-PScriboMessage ($LocalizedData.CollectingInventory -f $BackupServer.Name)
                            if ($CimSession) {
                                $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                            }

                            if ($HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }) {
                                Section -Style Heading4 $LocalizedData.HWInventoryHeading {
                                    $OutObj = @()
                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $HW.CsDNSHostName
                                        $LocalizedData.WindowsProductName = $HW.WindowsProductName
                                        $LocalizedData.WindowsCurrentVersion = $HW.WindowsCurrentVersion
                                        $LocalizedData.WindowsBuildNumber = $HW.OsVersion
                                        $LocalizedData.WindowsInstallType = $HW.WindowsInstallationType
                                        $LocalizedData.ADDomain = $HW.CsDomain
                                        $LocalizedData.WindowsInstallDate = $HW.OsInstallDate
                                        $LocalizedData.TimeZone = $HW.TimeZone
                                        $LocalizedData.LicenseType = $License.ProductKeyChannel
                                        $LocalizedData.PartialProductKey = $License.PartialProductKey
                                        $LocalizedData.Manufacturer = $HW.CsManufacturer
                                        $LocalizedData.Model = $HW.CsModel
                                        $LocalizedData.SerialNumber = $HWBIOS.SerialNumber
                                        $LocalizedData.BiosType = $HW.BiosFirmwareType
                                        $LocalizedData.BIOSVersion = $HWBIOS.Version
                                        $LocalizedData.ProcessorManufacturer = $HWCPU[0].Manufacturer
                                        $LocalizedData.ProcessorModel = $HWCPU[0].Name
                                        $LocalizedData.CPUCores = ($HWCPU.NumberOfCores | Measure-Object -Sum).Sum
                                        $LocalizedData.LogicalCores = ($HWCPU.NumberOfLogicalProcessors | Measure-Object -Sum).Sum
                                        $LocalizedData.PhysicalMemory = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $HW.CsTotalPhysicalMemory
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                    if ($HealthCheck.Infrastructure.Server) {
                                        $OutObj | Where-Object { $_."$($LocalizedData.CPUCores)" -lt 2 } | Set-Style -Style Warning -Property $LocalizedData.CPUCores
                                        if ([int]([regex]::Matches($OutObj."$($LocalizedData.PhysicalMemory)", '\d+(?!.*\d+)').value) -lt 8) { $OutObj | Set-Style -Style Warning -Property $LocalizedData.PhysicalMemory }
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.HWInventoryHeading) - $($BackupServer.Name.Split('.')[0])"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    if ($HealthCheck.Infrastructure.BestPractice) {
                                        if (([int]([regex]::Matches($OutObj."$($LocalizedData.PhysicalMemory)", '\d+(?!.*\d+)').value) -lt 8) -or ($OutObj | Where-Object { $_."$($LocalizedData.CPUCores)" -lt 2 })) {
                                            Paragraph $LocalizedData.healthCheck -Bold -Underline
                                            BlankLine
                                            Paragraph {
                                                Text $LocalizedData.bestPractice -Bold
                                                Text $LocalizedData.minConfigBestPracticeText
                                            }
                                            BlankLine
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                       Backup Server Local Disk Inventory Section                            #
                                    #---------------------------------------------------------------------------------------------#
                                    if ($InfoLevel.Infrastructure.BackupServer -ge 3) {
                                        try {
                                            $HostDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -ne 'iSCSI' -and $_.BusType -ne 'Fibre Channel' } }
                                            if ($HostDisks) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.LocalDisksHeading {
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
                                                            Write-PScriboMessage -IsWarning "Backup Server Local Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeading) - $($LocalizedData.LocalDisksHeading)"
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
                                            Write-PScriboMessage -IsWarning "Backup Server Local Disk Section: $($_.Exception.Message)"
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                       Backup Server SAN Disk Inventory Section                              #
                                        #---------------------------------------------------------------------------------------------#
                                        try {
                                            $SanDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -eq 'iSCSI' -or $_.BusType -eq 'Fibre Channel' } }
                                            if ($SanDisks) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SANDisksHeading {
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
                                                            Write-PScriboMessage -IsWarning "Backup Server SAN Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeading) - $($LocalizedData.SANDisksHeading)"
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
                                            Write-PScriboMessage -IsWarning "Backup Server SAN Disk Section: $($_.Exception.Message)"
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                       Backup Server Volume Inventory Section                                #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock { Get-Volume | Where-Object { $_.DriveType -ne 'CD-ROM' -and $NUll -ne $_.DriveLetter } }
                                        if ($HostVolumes) {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.HostVolumesHeading {
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
                                                        Write-PScriboMessage -IsWarning "Backup Server Host Volume $($HostVolume.DriveLetter) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                $TableParams = @{
                                                    Name = "$($LocalizedData.TableHeading) - $($LocalizedData.HostVolumesHeading)"
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
                                        Write-PScriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                       Backup Server Network Inventory Section                               #
                                    #---------------------------------------------------------------------------------------------#
                                    if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                        try {
                                            $HostAdapters = Invoke-Command -Session $PssSession { Get-NetAdapter }
                                            if ($HostAdapters) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.NetworkAdaptersHeading {
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
                                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume $($HostAdapter.Name) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeading) - $($LocalizedData.NetworkAdaptersHeading)"
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
                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
                                        }
                                        try {
                                            $NetIPs = Invoke-Command -Session $PssSession { Get-NetIPConfiguration | Where-Object -FilterScript { ($_.NetAdapter.Status -eq 'Up') } }
                                            if ($NetIPs) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.IPAddressHeading {
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
                                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume $($NetIp.InterfaceAlias) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TableHeading) - $($LocalizedData.IPAddressHeading)"
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
                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            } else {
                                Write-PScriboMessage -IsWarning "Backup Server Section: Unable to get Backup Server Hardware information: WinRM disabled or not configured on $($BackupServer.Name)."
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server Inventory Summary Section: $($_.Exception.Message)"
                    }
                    try {
                        Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                        if ($InfoLevel.Infrastructure.BackupServer -ge 3 -and $Options.EnableHardwareInventory -and ($PssSession)) {
                            if ($PssSession) {
                                $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                                $DefaultRegistryHash = @{
                                    'AgentLogging' = '1'
                                    'AgentLogOptions' = 'flush'
                                    'LoggingLevel' = '4'
                                    'VNXBlockNaviSECCliPath' = 'C:\Program Files\Veeam\Backup and Replication\Backup\EMC Navisphere CLI\NaviSECCli.exe'
                                    'VNXeUemcliPath' = 'C:\Program Files\Veeam\Backup and Replication\Backup\EMC Unisphere CLI\3.0.1\uemcli.exe'
                                    'SqlLockInfo' = ''
                                    'CloudServerPort' = '10003'
                                    'SqlDatabaseName' = 'VeeamBackup'
                                    'SqlInstanceName' = 'VEEAMSQL2016'
                                    'SqlServerName' = ''
                                    'SqlLogin' = ''
                                    'CorePath' = 'C:\Program Files\Veeam\Backup and Replication\Backup\'
                                    'BackupServerPort' = '9392'
                                    'SecureConnectionsPort' = '9401'
                                    'VddkReadBufferSize' = '0'
                                    'EndPointServerPort' = '10001'
                                    'SqlSecuredPassword' = ''
                                    'IsComponentsUpdateRequired' = '0'
                                    'LicenseAutoUpdate' = '1'
                                    'CloudSvcPort' = '6169'
                                    'VBRServiceRestartNeeded' = '0'
                                    'ImportServers' = '0'
                                    'MaxLogCount' = '10'
                                    'MaxLogSize' = '10240'
                                    'RunspaceId' = '0000'
                                    'ProviderCredentialsId' = ''
                                    'ProviderInfo' = ''
                                    'ProviderId' = ''
                                    'EntraIdSqlHostName' = 'localhost'
                                    'EntraIdSqlHostPort' = '5432'
                                    'EntraIdSqlPassword' = ''
                                    'EntraIdSqlServiceName' = 'postgresql-x64-15'
                                    'EntraIdSqlUserName' = 'postgres'
                                    'HighestDetectedVMCVersion' = ''
                                }
                                if ($VeeamInfo) {
                                    $OutObj = @()
                                    $Hashtable = $VeeamInfo | ForEach-Object {
                                        foreach ($prop in $_.psobject.Properties.Where({ $_.Name -notlike 'PS*' })) {
                                            [pscustomobject] @{
                                                Key = $prop.Name
                                                Value = $prop.Value
                                            }
                                        }
                                    }
                                    foreach ($Registry in $Hashtable) {
                                        if ($Registry.Key -notin $DefaultRegistryHash.Keys) {
                                            $inObj = [ordered] @{
                                                $LocalizedData.RegistryKey = $Registry.Key
                                                $LocalizedData.RegistryValue = switch (($Registry.Value).count) {
                                                    0 { '--' }
                                                    1 { $Registry.Value }
                                                    default { $Registry.Value -join ', ' }
                                                }
                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.NonDefaultRegistryHeading) - $($BackupServer.Name.Split('.')[0])"
                                        List = $false
                                        ColumnWidths = 50, 50
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                }
                                if ($OutObj) {
                                    Section -Style Heading4 $LocalizedData.NonDefaultRegistryHeading {
                                        $OutObj | Sort-Object -Property $LocalizedData.RegistryKey | Table @TableParams
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server Non-Default Registry Keys Section: $($_.Exception.Message)"
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                             Backup Server Services Information Section                      #
                    #---------------------------------------------------------------------------------------------#
                    if ($HealthCheck.Infrastructure.Server) {
                        if ($PssSession -and $Options.EnableHardwareInventory) {
                            try {
                                Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                                if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                    Write-PScriboMessage ($LocalizedData.CollectingServices -f $BackupServer.Name)
                                    $Available = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service 'W32Time' | Select-Object DisplayName, Name, Status }
                                    if ($Available) {
                                        $Services = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service Veeam* }
                                        Section -Style Heading4 $LocalizedData.ServicesStatusHeading {
                                            $OutObj = @()
                                            foreach ($Service in $Services) {
                                                Write-PScriboMessage ($LocalizedData.CollectingServiceStatus -f $Service.DisplayName, $BackupServer.Name)
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
                                                Name = "$($LocalizedData.ServicesStatusHeading) - $($BackupServer.Name.Split('.')[0])"
                                                List = $false
                                                ColumnWidths = 45, 35, 20
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Backup Server Service Status Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                        Backup Server High Availability Section                            #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        Write-PScriboMessage $LocalizedData.CollectingHA
                        $HACluster = Get-VBRHighAvailabilityCluster
                        if ($HACluster) {
                            Section -Style Heading4 $LocalizedData.HAHeading {
                                $OutObj = @()
                                $inObj = [ordered] @{
                                    $LocalizedData.HAClusterEndpoint         = $HACluster.ClusterEndpoint
                                    $LocalizedData.HAClusterDnsName          = $HACluster.ClusterDnsName
                                    $LocalizedData.HAIsHealthyCluster        = $HACluster.IsHealthyCluster
                                    $LocalizedData.HAIsFailoverInProgress    = $HACluster.IsFailoverInProgress
                                    $LocalizedData.HAIsAnyActivityInProgress = $HACluster.IsAnyActivityInProgress
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                if ($HealthCheck.Infrastructure.BackupServer) {
                                    $OutObj | Where-Object { $_."$($LocalizedData.HAIsHealthyCluster)" -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.HAIsHealthyCluster
                                    $OutObj | Where-Object { $_."$($LocalizedData.HAIsFailoverInProgress)" -eq 'Yes' } | Set-Style -Style Warning -Property $LocalizedData.HAIsFailoverInProgress
                                    $OutObj | Where-Object { $_."$($LocalizedData.HAIsAnyActivityInProgress)" -eq 'Yes' } | Set-Style -Style Warning -Property $LocalizedData.HAIsAnyActivityInProgress
                                }

                                $TableParams = @{
                                    Name         = "$($LocalizedData.HAHeading) - $($BackupServer.Name.Split('.')[0])"
                                    List         = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams

                                #-------------------------------------------------------------------------------------#
                                #                            HA Cluster Nodes Sub-Section                             #
                                #-------------------------------------------------------------------------------------#
                                try {
                                    $HANodes = @($HACluster.Primary) + @($HACluster.Secondary)
                                    if ($HANodes) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.HANodesHeading {
                                            $NodesObj = @()
                                            foreach ($Node in $HANodes) {
                                                try {
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.HAHostname = $Node.Hostname
                                                        $LocalizedData.HARole     = $Node.Role
                                                        $LocalizedData.Status     = $Node.Status
                                                    }
                                                    $NodesObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "HA Cluster Node $($Node.Hostname) Section: $($_.Exception.Message)"
                                                }
                                            }

                                            if ($HealthCheck.Infrastructure.BackupServer) {
                                                $NodesObj | Where-Object { $_."$($LocalizedData.Status)" -ne 'Online' } | Set-Style -Style Warning -Property $LocalizedData.Status
                                            }

                                            $TableParams = @{
                                                Name         = "$($LocalizedData.HANodesHeading) - $($BackupServer.Name.Split('.')[0])"
                                                List         = $false
                                                ColumnWidths = 40, 30, 30
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $NodesObj | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "HA Cluster Nodes Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server High Availability Section: $($_.Exception.Message)"
                    }
                    if ($HealthCheck.Infrastructure.BestPractice -and $PssSession) {
                        try {
                            $UpdObj = @()
                            $Updates = Invoke-Command -Session $PssSession -ScriptBlock { (New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search('IsHidden=0 and IsInstalled=0').Updates | Select-Object Title, KBArticleIDs }
                            $UpdObj += if ($Updates) {
                                $OutObj = @()
                                foreach ($Update in $Updates) {
                                    try {
                                        $inObj = [ordered] @{
                                            $LocalizedData.KBArticle = "KB$($Update.KBArticleIDs)"
                                            $LocalizedData.Name = $Update.Title
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.OperatingSystem.Updates) {
                                            $OutObj | Set-Style -Style Warning
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $OutObj | Set-Style -Style Warning

                                $TableParams = @{
                                    Name = "$($LocalizedData.MissingUpdatesHeading) - $($BackupServer.Name.Split('.')[0])"
                                    List = $false
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            }
                            if ($UpdObj) {
                                Section -Style Heading4 $LocalizedData.MissingUpdatesHeading {
                                    Paragraph $LocalizedData.MissingUpdatesParagraph
                                    BlankLine
                                    $UpdObj
                                }
                                Paragraph $LocalizedData.healthCheck -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text $LocalizedData.securityBestPractices -Bold
                                    Text $LocalizedData.securityPatchBestPracticeText
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Backup Server Section: $($_.Exception.Message)"
        }
    }
    end {
        if ($PssSession) { Remove-PSSession -Session $PssSession }
        if ($CimSession) { Remove-CimSession $CimSession }
        Show-AbrDebugExecutionTime -End -TitleMessage 'Backup Server Inventory Summary'
    }

}