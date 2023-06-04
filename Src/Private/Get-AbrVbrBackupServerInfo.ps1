
function Get-AbrVbrBackupServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.1
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
        Write-PscriboMessage "Discovering Veeam V&R Server information from $System."
    }

    process {
        try {
            $BackupServers = Get-VBRServer -Type Local
            if (($BackupServers).count -gt 0) {
                Section -Style Heading3 'Backup Server' {
                    $OutObj = @()
                    try {
                        foreach ($BackupServer in $BackupServers) {
                            $CimSession = New-CimSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                            $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                            $SecurityOptions = Get-VBRSecurityOptions
                            Write-PscriboMessage "Collecting Backup Server information from $($BackupServer.Name)."
                            try {
                                $VeeamVersion = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { get-childitem -recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | get-itemproperty | Where-Object { $_.DisplayName  -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion }
                            } catch {Write-PscriboMessage -IsWarning "Backup Server Inkoke-Command Section: $($_.Exception.Message)"}
                            try {
                                $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                            } catch {Write-PscriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)"}
                            try {
                                $VeeamDBFlavor = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations' }
                            } catch {Write-PscriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)"}
                            try {
                                $VeeamDBInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\$(($Using:VeeamDBFlavor).SqlActiveConfiguration)" }
                            } catch {Write-PscriboMessage -IsWarning "Backup Server Invoke-Command Section: $($_.Exception.Message)"}
                            Write-PscriboMessage "Discovered $BackupServer Server."
                            $inObj = [ordered] @{
                                'Server Name' = $BackupServer.Name
                                'Version' = Switch (($VeeamVersion).count) {
                                    0 {"-"}
                                    default {$VeeamVersion.DisplayVersion}
                                }
                                'Database Server' = Switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlServerName)) {
                                    $true {"-"}
                                    $false {$VeeamDBInfo.SqlServerName}
                                    default {'Unknown'}
                                }
                                'Database Instance' = Switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlInstanceName)) {
                                    $true {"-"}
                                    $false {$VeeamDBInfo.SqlInstanceName}
                                    default {'Unknown'}
                                }
                                'Database Name' = Switch ([string]::IsNullOrEmpty($VeeamDBInfo.SqlDatabaseName)) {
                                    $true {"-"}
                                    $false {$VeeamDBInfo.SqlDatabaseName}
                                    default {'Unknown'}
                                }
                                'Connection Ports' = Switch (($VeeamInfo.BackupServerPort).count) {
                                    0 {"-"}
                                    default {"Backup Server Port: $($VeeamInfo.BackupServerPort)`r`nSecure Connections Port: $($VeeamInfo.SecureConnectionsPort)`r`nCloud Server Port: $($VeeamInfo.CloudServerPort)`r`nCloud Service Port: $($VeeamInfo.CloudSvcPort)"}
                                }
                                'Install Path' = Switch (($VeeamInfo.CorePath).count) {
                                    0 {"-"}
                                    default {$VeeamInfo.CorePath}
                                }
                                'Audit Logs Path' = $SecurityOptions.AuditLogsPath
                                'Compress Old Audit Logs' = ConvertTo-TextYN $SecurityOptions.CompressOldAuditLogs
                                'Fips Compliant Mode' = Switch ($SecurityOptions.FipsCompliantModeEnabled) {
                                    'True' {"Enabled"}
                                    'False' {"Disabled"}
                                }
                                'Logging Level' = $VeeamInfo.LoggingLevel

                            }

                            if ($Null -notlike $VeeamInfo.LogDirectory) {
                                $inObj.add('Log Directory', ($VeeamInfo.LogDirectory))
                            }

                            $OutObj += [pscustomobject]$inobj
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Backup Server Section: $($_.Exception.Message)"
                    }

                    if ($HealthCheck.Infrastructure.BackupServer) {
                        $OutObj | Where-Object { $_.'Logging Level' -gt 4} | Set-Style -Style Warning -Property 'Logging Level'
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
                    #---------------------------------------------------------------------------------------------#
                    #                       Backup Server Inventory Summary Section                               #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        Write-PScriboMessage "Hardware Inventory Status set as $($Options.EnableHardwareInventory)."
                        if ($Options.EnableHardwareInventory) {
                            $BackupServer = Get-VBRServer -Type Local
                            Write-PscriboMessage "Collecting Backup Server Inventory Summary from $($BackupServer.Name)."
                            $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                            $License =  Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                            $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                            $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                            if ($HW) {
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
                                        'Physical Memory (GB)' = ConvertTo-FileSizeString $HW.CsTotalPhysicalMemory
                                    }
                                    $OutObj += [pscustomobject]$inobj

                                    if ($HealthCheck.Infrastructure.Server) {
                                        $OutObj | Where-Object { $_.'Number of CPU Cores' -lt 2} | Set-Style -Style Warning -Property 'Number of CPU Cores'
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
                                        if (([int]([regex]::Matches($OutObj.'Physical Memory (GB)', "\d+(?!.*\d+)").value) -lt 8) -or ($OutObj | Where-Object { $_.'Number of CPU Cores' -lt 2})) {
                                            Paragraph "Health Check:" -Italic -Bold -Underline
                                            Paragraph "Best Practice: Recommended Veeam Backup Server minimum configuration is two CPU cores and 8GB RAM." -Italic -Bold
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
                                                                'Disk Size' = "$([Math]::Round($Disk.Size / 1Gb)) GB"
                                                            }
                                                            $LocalDiskReport += $TempLocalDiskReport
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning "Backup Server Local Disk $($Disk.Number) Section: $($_.Exception.Message)"
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
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Backup Server Local Disk Section: $($_.Exception.Message)"
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
                                                                'Disk Size' = "$([Math]::Round($Disk.Size / 1Gb)) GB"
                                                            }
                                                            $SanDiskReport += $TempSanDiskReport
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning "Backup Server SAN Disk $($Disk.Number) Section: $($_.Exception.Message)"
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
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Backup Server SAN Disk Section: $($_.Exception.Message)"
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                       Backup Server Volume Inventory Section                                #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock {  Get-Volume | Where-Object {$_.DriveType -ne "CD-ROM" -and $NUll -ne $_.DriveLetter} }
                                        if ($HostVolumes) {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'Host Volumes' {
                                                $HostVolumeReport = @()
                                                ForEach ($HostVolume in $HostVolumes) {
                                                    try {
                                                        $TempHostVolumeReport = [PSCustomObject]@{
                                                            'Drive Letter' = $HostVolume.DriveLetter
                                                            'File System Label' = $HostVolume.FileSystemLabel
                                                            'File System' = $HostVolume.FileSystem
                                                            'Size' = "$([Math]::Round($HostVolume.Size / 1gb)) GB"
                                                            'Free Space' = "$([Math]::Round($HostVolume.SizeRemaining / 1gb)) GB"
                                                            'Health Status' = $HostVolume.HealthStatus
                                                        }
                                                        $HostVolumeReport += $TempHostVolumeReport
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning "Backup Server Host Volume $($HostVolume.DriveLetter) Section: $($_.Exception.Message)"
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
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
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
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning "Backup Server Host Volume $($HostAdapter.Name) Section: $($_.Exception.Message)"
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
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
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
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning "Backup Server Host Volume $($NetIp.InterfaceAlias) Section: $($_.Exception.Message)"
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
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "Backup Server Host Volume Section: $($_.Exception.Message)"
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Backup Server Inventory Summary Section: $($_.Exception.Message)"
                    }
                    try {
                        Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                        if ($InfoLevel.Infrastructure.BackupServer -ge 3) {
                            $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                            $DefaultRegistryHash = @{
                                "AgentLogging" = "1"
                                "AgentLogOptions" = "flush"
                                "LoggingLevel" = "4"
                                "VNXBlockNaviSECCliPath" = "C:\Program Files\Veeam\Backup and Replication\Backup\EMC Navisphere CLI\NaviSECCli.exe"
                                "VNXeUemcliPath"= "C:\Program Files\Veeam\Backup and Replication\Backup\EMC Unisphere CLI\3.0.1\uemcli.exe"
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
                            }
                            if ($VeeamInfo) {
                                $OutObj = @()
                                $Hashtable = $VeeamInfo | ForEach-Object {
                                    foreach ($prop in $_.psobject.Properties.Where({ $_.Name -notlike 'PS*'})) {
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
                                                0 {'-'}
                                                1 {$Registry.Value}
                                                default {$Registry.Value -Join ', '}

                                            }
                                        }
                                        $OutObj += [pscustomobject]$inobj
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
                    catch {
                        Write-PscriboMessage -IsWarning "Backup Server Non-Default Registry Keys Section: $($_.Exception.Message)"
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                             Backup Server Services Information Section                      #
                    #---------------------------------------------------------------------------------------------#
                    if ($HealthCheck.Infrastructure.Server) {
                        $BackupServer = Get-VBRServer -Type Local
                        try {
                            Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                            if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                $Available = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service "W32Time" | Select-Object DisplayName, Name, Status}
                                Write-PscriboMessage "Collecting Backup Server Service Summary from $($BackupServer.Name)."
                                $Services = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service Veeam*}
                                if ($Available) {
                                    Section -Style Heading4 "HealthCheck - Services Status" {
                                        $OutObj = @()
                                        foreach ($Service in $Services) {
                                            Write-PscriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupServer.Name)."
                                            $inObj = [ordered] @{
                                                'Display Name' = $Service.DisplayName
                                                'Short Name' = $Service.Name
                                                'Status' = $Service.Status
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        }

                                        if ($HealthCheck.Infrastructure.Server) {
                                            $OutObj | Where-Object { $_.'Status' -notlike 'Running'} | Set-Style -Style Warning -Property 'Status'
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
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Backup Server Service Status Section: $($_.Exception.Message)"
                        }
                        try {
                            Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                            if ($InfoLevel.Infrastructure.BackupServer -ge 3) {
                                $NetStats = Get-VeeamNetStat -Session $PssSession | Where-Object { $_.ProcessName -Like "*veeam*" } | Sort-Object -Property State,LocalPort
                                Write-PscriboMessage "Collecting Backup Server Network Statistics from $($BackupServer.Name)."
                                if ($NetStats) {
                                    Section -Style Heading4 "HealthCheck - Network Statistics" {
                                        $OutObj = @()
                                        foreach ($NetStat in $NetStats) {
                                            try {
                                                $inObj = [ordered] @{
                                                    'Proto' = $NetStat.Protocol
                                                    'Local IP' = $NetStat.LocalAddress
                                                    'Local Port' = $NetStat.LocalPort
                                                    'Remote IP' = $NetStat.RemoteAddress
                                                    'Remote Port' = $NetStat.RemotePort
                                                    'State' = $NetStat.State
                                                    'Process Name' = $NetStat.ProcessName
                                                    'PID' = $NetStat.PID
                                                }
                                                $OutObj += [pscustomobject]$inobj
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning "Backup Server Network Statistics $($NetStat.Protocol) Section: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "HealthCheck - Network Statistics - $($BackupServer.Name.Split(".")[0])"
                                            List = $false
                                            ColumnWidths = 8, 16, 8, 16, 9, 16, 19, 8
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Backup Server Network Statistics Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Backup Server Section: $($_.Exception.Message)"
        }
    }
    end {
        if ($PssSession) {Remove-PSSession -Session $PssSession}
        if ($CimSession) {Remove-CimSession $CimSession}
    }

}