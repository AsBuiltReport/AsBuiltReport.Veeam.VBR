
function Get-AbrVbrBackupServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.13
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
        Write-PScriboMessage "Discovering Veeam V&R Server information from $System."
    }

    process {
        try {
            if ($script:BackupServers = Get-VBRServer -Type Local) {
                Section -Style Heading3 'Backup Server' {
                    $OutObj = @()
                    try {
                        foreach ($BackupServer in $BackupServers) {
                            if (Test-WSMan -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ComputerName $BackupServer.Name -ErrorAction SilentlyContinue) {
                                $CimSession = try { New-CimSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -Name 'CIMBackupServer' -ErrorAction Stop } catch { Write-PScriboMessage -IsWarning "Backup Server Section: New-CimSession: Unable to connect to $($BackupServer.Name): $($_.Exception.MessageId)" }

                                $PssSession = try { New-PSSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop -Name 'PSSBackupServer' } catch {
                                    if (-Not $_.Exception.MessageId) {
                                        $ErrorMessage = $_.FullyQualifiedErrorId
                                    } else { $ErrorMessage = $_.Exception.MessageId }
                                    Write-PScriboMessage -IsWarning "Backup Server Section: New-PSSession: Unable to connect to $($BackupServer.Name): $ErrorMessage"
                                }
                                $SecurityOptions = Get-VBRSecurityOptions
                                try { $DomainJoined = Get-CimInstance -Class Win32_ComputerSystem -Property PartOfDomain -CimSession $CimSession } catch { 'Unknown' }
                                Write-PScriboMessage "Collecting Backup Server information from $($BackupServer.Name)."
                                try {
                                    $script:VeeamVersion = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ChildItem -Recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion }
                                } catch { Write-PScriboMessage -IsWarning "Backup Server Inkoke-Command Section: $($_.Exception.Message)" }
                                try {
                                    $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                                } catch { Write-PScriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)" }
                                try {
                                    $VeeamDBFlavor = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations' }
                                } catch { Write-PScriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)" }
                                try {
                                    $VeeamDBInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\$(($Using:VeeamDBFlavor).SqlActiveConfiguration)" }
                                } catch { Write-PScriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)" }
                                Write-PScriboMessage "Discovered $($BackupServer.Name) Server."
                            } else { Write-PScriboMessage -IsWarning "Backup Server Section: Unable to connect to Backup Server throuth WinRM" }
                            $inObj = [ordered] @{
                                'Server Name' = $BackupServer.Name
                                'Is Domain Joined?' = $DomainJoined.PartOfDomain
                                'Version' = Switch (($VeeamVersion).count) {
                                    0 { "--" }
                                    default { $VeeamVersion.DisplayVersion }
                                }
                                'Database Server' = Switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlServerName)) {
                                    $true { "--" }
                                    $false { $VeeamDBInfo.SqlServerName }
                                    default { 'Unknown' }
                                }
                                'Database Instance' = Switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlInstanceName)) {
                                    $true { "--" }
                                    $false { $VeeamDBInfo.SqlInstanceName }
                                    default { 'Unknown' }
                                }
                                'Database Name' = Switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlDatabaseName)) {
                                    $true { "--" }
                                    $false { $VeeamDBInfo.SqlDatabaseName }
                                    default { 'Unknown' }
                                }
                                'Connection Ports' = Switch (($VeeamInfo.BackupServerPort).count) {
                                    0 { "--" }
                                    default { "Backup Server Port: $($VeeamInfo.BackupServerPort)`r`nSecure Connections Port: $($VeeamInfo.SecureConnectionsPort)`r`nCloud Server Port: $($VeeamInfo.CloudServerPort)`r`nCloud Service Port: $($VeeamInfo.CloudSvcPort)" }
                                }
                                'Install Path' = Switch (($VeeamInfo.CorePath).count) {
                                    0 { "--" }
                                    default { $VeeamInfo.CorePath }
                                }
                                'Audit Logs Path' = $SecurityOptions.AuditLogsPath
                                'Compress Old Audit Logs' = $SecurityOptions.CompressOldAuditLogs
                                'Fips Compliant Mode' = Switch ($SecurityOptions.FipsCompliantModeEnabled) {
                                    'True' { "Enabled" }
                                    'False' { "Disabled" }
                                }
                                'Linux host authentication' = Switch ($SecurityOptions.HostPolicy.Type) {
                                    'All' { "Add all discovered host to the list automatically" }
                                    'KnownHosts' { "Add unknown host to the list manually" }
                                }
                                'Logging Level' = $VeeamInfo.LoggingLevel

                            }

                            if ($Null -notlike $VeeamInfo.LogDirectory) {
                                $inObj.add('Log Directory', ($VeeamInfo.LogDirectory))
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server Section: $($_.Exception.Message)"
                    }

                    if ($HealthCheck.Infrastructure.BackupServer) {
                        $OutObj | Where-Object { $_.'Logging Level' -gt 4 } | Set-Style -Style Warning -Property 'Logging Level'
                        $OutObj | Where-Object { $_.'Is Domain Joined?' -eq 'Yes' } | Set-Style -Style Warning -Property 'Is Domain Joined?'
                    }

                    $TableParams = @{
                        Name = "Backup Server - $($BackupServer.Name.Split(".")[0])"
                        List = $true
                        ColumnWidths = 40, 60
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                    if ($HealthCheck.Infrastructure.BestPractice) {
                        if ($OutObj | Where-Object { $_.'Is Domain Joined?' -eq 'Yes' }) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph {
                                Text "Best Practice:" -Bold
                                Text "When setting up the Veeam Availability infrastructure keep in mind the principle that a data protection system should not rely on the environment it is meant to protect in any way! This is because when your production environment goes down along with its domain controllers, it will impact your ability to perform actual restores due to the backup server's dependency on those domain controllers for backup console authentication, DNS for name resolution, etc."
                            }
                            BlankLine
                            Paragraph {
                                Text 'Reference:' -Bold
                                Text 'https://bp.veeam.com/vbr/Security/Security_domains.html'
                            }
                            BlankLine
                        }
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                  Backup Server Inventory & Software Summary Section                         #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        Write-PScriboMessage "Hardware Inventory Status set as $($Options.EnableHardwareInventory)."
                        if ($Options.EnableHardwareInventory) {
                            $BackupServer = Get-VBRServer -Type Local
                            Write-PScriboMessage "Collecting Backup Server Inventory Summary from $($BackupServer.Name)."
                            $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                            $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                            $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                            if ($HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }) {
                                Section -Style Heading4 'Hardware & Software Inventory' {
                                    $OutObj = @()
                                    $inObj = [ordered] @{
                                        'Name' = $HW.CsDNSHostName
                                        'Windows Product Name' = $HW.WindowsProductName
                                        'Windows Current Version' = $HW.WindowsCurrentVersion
                                        'Windows Build Number' = $HW.OsVersion
                                        'Windows Install Type' = $HW.WindowsInstallationType
                                        'Active Directory Domain' = $HW.CsDomain
                                        'Windows Installation Date' = $HW.OsInstallDate
                                        'Time Zone' = $HW.TimeZone
                                        'License Type' = $License.ProductKeyChannel
                                        'Partial Product Key' = $License.PartialProductKey
                                        'Manufacturer' = $HW.CsManufacturer
                                        'Model' = $HW.CsModel
                                        'Serial Number' = $HWBIOS.SerialNumber
                                        'Bios Type' = $HW.BiosFirmwareType
                                        'BIOS Version' = $HWBIOS.Version
                                        'Processor Manufacturer' = $HWCPU[0].Manufacturer
                                        'Processor Model' = $HWCPU[0].Name
                                        'Number of CPU Cores' = ($HWCPU.NumberOfCores | Measure-Object -Sum).Sum
                                        'Number of Logical Cores' = ($HWCPU.NumberOfLogicalProcessors | Measure-Object -Sum).Sum
                                        'Physical Memory (GB)' = ConvertTo-FileSizeString -Size $HW.CsTotalPhysicalMemory
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                    if ($HealthCheck.Infrastructure.Server) {
                                        $OutObj | Where-Object { $_.'Number of CPU Cores' -lt 2 } | Set-Style -Style Warning -Property 'Number of CPU Cores'
                                        if ([int]([regex]::Matches($OutObj.'Physical Memory (GB)', "\d+(?!.*\d+)").value) -lt 8) { $OutObj | Set-Style -Style Warning -Property 'Physical Memory (GB)' }
                                    }

                                    $TableParams = @{
                                        Name = "Backup Server Inventory - $($BackupServer.Name.Split(".")[0])"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    if ($HealthCheck.Infrastructure.BestPractice) {
                                        if (([int]([regex]::Matches($OutObj.'Physical Memory (GB)', "\d+(?!.*\d+)").value) -lt 8) -or ($OutObj | Where-Object { $_.'Number of CPU Cores' -lt 2 })) {
                                            Paragraph "Health Check:" -Bold -Underline
                                            BlankLine
                                            Paragraph {
                                                Text "Best Practice:" -Bold
                                                Text "Recommended Veeam Backup Server minimum configuration is two CPU cores and 8GB of RAM."
                                            }
                                            BlankLine
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                       Backup Server Local Disk Inventory Section                            #
                                    #---------------------------------------------------------------------------------------------#
                                    if ($InfoLevel.Infrastructure.BackupServer -ge 3) {
                                        try {
                                            $HostDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -ne "iSCSI" -and $_.BusType -ne "Fibre Channel" } }
                                            if ($HostDisks) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Local Disks' {
                                                    $LocalDiskReport = @()
                                                    ForEach ($Disk in $HostDisks) {
                                                        try {
                                                            $TempLocalDiskReport = [PSCustomObject]@{
                                                                'Disk Number' = $Disk.Number
                                                                'Model' = $Disk.Model
                                                                'Serial Number' = $Disk.SerialNumber
                                                                'Partition Style' = $Disk.PartitionStyle
                                                                'Disk Size' = ConvertTo-FileSizeString -Size $Disk.Size
                                                            }
                                                            $LocalDiskReport += $TempLocalDiskReport
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Backup Server Local Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "Backup Server - Local Disks"
                                                        List = $false
                                                        ColumnWidths = 20, 20, 20, 20, 20
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $LocalDiskReport | Sort-Object -Property 'Disk Number' | Table @TableParams
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Backup Server Local Disk Section: $($_.Exception.Message)"
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                       Backup Server SAN Disk Inventory Section                              #
                                        #---------------------------------------------------------------------------------------------#
                                        try {
                                            $SanDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -Eq "iSCSI" -or $_.BusType -Eq "Fibre Channel" } }
                                            if ($SanDisks) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'SAN Disks' {
                                                    $SanDiskReport = @()
                                                    ForEach ($Disk in $SanDisks) {
                                                        try {
                                                            $TempSanDiskReport = [PSCustomObject]@{
                                                                'Disk Number' = $Disk.Number
                                                                'Model' = $Disk.Model
                                                                'Serial Number' = $Disk.SerialNumber
                                                                'Partition Style' = $Disk.PartitionStyle
                                                                'Disk Size' = ConvertTo-FileSizeString -Size $Disk.Size
                                                            }
                                                            $SanDiskReport += $TempSanDiskReport
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Backup Server SAN Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "Backup Server - SAN Disks"
                                                        List = $false
                                                        ColumnWidths = 20, 20, 20, 20, 20
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $SanDiskReport | Sort-Object -Property 'Disk Number' | Table @TableParams
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
                                        $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock { Get-Volume | Where-Object { $_.DriveType -ne "CD-ROM" -and $NUll -ne $_.DriveLetter } }
                                        if ($HostVolumes) {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'Host Volumes' {
                                                $HostVolumeReport = @()
                                                ForEach ($HostVolume in $HostVolumes) {
                                                    try {
                                                        $TempHostVolumeReport = [PSCustomObject]@{
                                                            'Drive Letter' = $HostVolume.DriveLetter
                                                            'File System Label' = $HostVolume.FileSystemLabel
                                                            'File System' = $HostVolume.FileSystem
                                                            'Size' = ConvertTo-FileSizeString -Size $HostVolume.Size
                                                            'Free Space' = ConvertTo-FileSizeString -Size $HostVolume.SizeRemaining
                                                            'Health Status' = $HostVolume.HealthStatus
                                                        }
                                                        $HostVolumeReport += $TempHostVolumeReport
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Backup Server Host Volume $($HostVolume.DriveLetter) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                                $TableParams = @{
                                                    Name = "Backup Server - Volumes"
                                                    List = $false
                                                    ColumnWidths = 15, 15, 15, 20, 20, 15
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $HostVolumeReport | Sort-Object -Property 'Drive Letter' | Table @TableParams
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
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Network Adapters' {
                                                    $HostAdaptersReport = @()
                                                    ForEach ($HostAdapter in $HostAdapters) {
                                                        try {
                                                            $TempHostAdaptersReport = [PSCustomObject]@{
                                                                'Adapter Name' = $HostAdapter.Name
                                                                'Adapter Description' = $HostAdapter.InterfaceDescription
                                                                'Mac Address' = $HostAdapter.MacAddress
                                                                'Link Speed' = $HostAdapter.LinkSpeed
                                                            }
                                                            $HostAdaptersReport += $TempHostAdaptersReport
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume $($HostAdapter.Name) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "Backup Server - Network Adapters"
                                                        List = $false
                                                        ColumnWidths = 30, 35, 20, 15
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $HostAdaptersReport | Sort-Object -Property 'Adapter Name' | Table @TableParams
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
                                        }
                                        try {
                                            $NetIPs = Invoke-Command -Session $PssSession { Get-NetIPConfiguration | Where-Object -FilterScript { ($_.NetAdapter.Status -Eq "Up") } }
                                            if ($NetIPs) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'IP Address' {
                                                    $NetIpsReport = @()
                                                    ForEach ($NetIp in $NetIps) {
                                                        try {
                                                            $TempNetIpsReport = [PSCustomObject]@{
                                                                'Interface Name' = $NetIp.InterfaceAlias
                                                                'Interface Description' = $NetIp.InterfaceDescription
                                                                'IPv4 Addresses' = $NetIp.IPv4Address.IPAddress -Join ","
                                                                'Subnet Mask' = $NetIp.IPv4Address[0].PrefixLength
                                                                'IPv4 Gateway' = $NetIp.IPv4DefaultGateway.NextHop
                                                            }
                                                            $NetIpsReport += $TempNetIpsReport
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume $($NetIp.InterfaceAlias) Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                    $TableParams = @{
                                                        Name = "Backup Server - IP Address"
                                                        List = $false
                                                        ColumnWidths = 25, 25, 20, 10, 20
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $NetIpsReport | Sort-Object -Property 'Interface Name' | Table @TableParams
                                                }
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Server Inventory Summary Section: $($_.Exception.Message)"
                    }
                    try {
                        Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                        if ($InfoLevel.Infrastructure.BackupServer -ge 3) {
                            if ($PssSession) {
                                $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                                $DefaultRegistryHash = @{
                                    "AgentLogging" = "1"
                                    "AgentLogOptions" = "flush"
                                    "LoggingLevel" = "4"
                                    "VNXBlockNaviSECCliPath" = "C:\Program Files\Veeam\Backup and Replication\Backup\EMC Navisphere CLI\NaviSECCli.exe"
                                    "VNXeUemcliPath" = "C:\Program Files\Veeam\Backup and Replication\Backup\EMC Unisphere CLI\3.0.1\uemcli.exe"
                                    "SqlLockInfo" = ""
                                    "CloudServerPort" = "10003"
                                    "SqlDatabaseName" = "VeeamBackup"
                                    "SqlInstanceName" = "VEEAMSQL2016"
                                    "SqlServerName" = ""
                                    "SqlLogin" = ""
                                    "CorePath" = "C:\Program Files\Veeam\Backup and Replication\Backup\"
                                    "BackupServerPort" = "9392"
                                    "SecureConnectionsPort" = "9401"
                                    "VddkReadBufferSize" = "0"
                                    "EndPointServerPort" = "10001"
                                    "SqlSecuredPassword" = ""
                                    "IsComponentsUpdateRequired" = "0"
                                    "LicenseAutoUpdate" = "1"
                                    "CloudSvcPort" = "6169"
                                    "VBRServiceRestartNeeded" = "0"
                                    "ImportServers" = "0"
                                    "MaxLogCount" = "10"
                                    "MaxLogSize" = "10240"
                                    "RunspaceId" = "0000"
                                    "ProviderCredentialsId" = ""
                                    "ProviderInfo" = ""
                                    "ProviderId" = ""
                                    "EntraIdSqlHostName" = "localhost"
                                    "EntraIdSqlHostPort" = "5432"
                                    "EntraIdSqlPassword" = ""
                                    "EntraIdSqlServiceName" = "postgresql-x64-15"
                                    "EntraIdSqlUserName" = "postgres"
                                    "HighestDetectedVMCVersion" = ""
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
                                                'Registry Key' = $Registry.Key
                                                'Registry Value' = Switch (($Registry.Value).count) {
                                                    0 { '--' }
                                                    1 { $Registry.Value }
                                                    default { $Registry.Value -Join ', ' }
                                                }
                                            }
                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "Non-Default Registry Keys - $($BackupServer.Name.Split(".")[0])"
                                        List = $false
                                        ColumnWidths = 50, 50
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                }
                                if ($OutObj) {
                                    Section -Style Heading4 "Non-Default Registry Keys" {
                                        $OutObj | Sort-Object -Property 'Registry Key' | Table @TableParams
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
                        $BackupServer = Get-VBRServer -Type Local
                        if ($PssSession) {
                            try {
                                Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                                if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                    Write-PScriboMessage "Collecting Backup Server Service Summary from $($BackupServer.Name)."
                                    $Available = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service "W32Time" | Select-Object DisplayName, Name, Status }
                                    if ($Available) {
                                        $Services = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service Veeam* }
                                        Section -Style Heading4 "HealthCheck - Services Status" {
                                            $OutObj = @()
                                            foreach ($Service in $Services) {
                                                Write-PScriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupServer.Name)."
                                                $inObj = [ordered] @{
                                                    'Display Name' = $Service.DisplayName
                                                    'Short Name' = $Service.Name
                                                    'Status' = $Service.Status
                                                }
                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                            }

                                            if ($HealthCheck.Infrastructure.Server) {
                                                $OutObj | Where-Object { $_.'Status' -notlike 'Running' } | Set-Style -Style Warning -Property 'Status'
                                            }

                                            $TableParams = @{
                                                Name = "HealthCheck - Services Status - $($BackupServer.Name.Split(".")[0])"
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
                    if ($HealthCheck.Infrastructure.BestPractice -and $PssSession) {
                        try {
                            $UpdObj = @()
                            $Updates = Invoke-Command -Session $PssSession -ScriptBlock { (New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsHidden=0 and IsInstalled=0").Updates | Select-Object Title, KBArticleIDs }
                            $UpdObj += if ($Updates) {
                                $OutObj = @()
                                foreach ($Update in $Updates) {
                                    try {
                                        $inObj = [ordered] @{
                                            'KB Article' = "KB$($Update.KBArticleIDs)"
                                            'Name' = $Update.Title
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
                                    Name = "Missing Windows Updates - $($BackupServer.Name.Split(".")[0])"
                                    List = $false
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            }
                            if ($UpdObj) {
                                Section -Style Heading4 'Missing Windows Updates' {
                                    Paragraph "The following table provides a summary of the backup server pending/missing windows updates."
                                    BlankLine
                                    $UpdObj
                                }
                                Paragraph "Health Check:" -Bold -Underline
                                BlankLine
                                Paragraph {
                                    Text "Security Best Practices:" -Bold
                                    Text "Patch operating systems, software, and firmware on Veeam components. Most hacks succeed because there is already vulnerable software in use which is not up-to-date with current patch levels. So make sure all software and hardware where Veeam components are running are up-to-date. One of the most possible causes of a credential theft are missing guest OS updates and use of outdated authentication protocols."
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
    }

}