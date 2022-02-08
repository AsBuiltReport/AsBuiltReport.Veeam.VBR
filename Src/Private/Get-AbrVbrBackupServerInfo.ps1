
function Get-AbrVbrBackupServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
            if ((Get-VBRServer -Type Local).count -gt 0) {
                Section -Style Heading3 'Backup Server Information' {
                    Paragraph "The following table details a summary of the local Veeam Backup Server"
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $BackupServers = Get-VBRServer -Type Local
                            foreach ($BackupServer in $BackupServers) {
                                $CimSession = New-CimSession $BackupServer.Name -Credential $Credential -Authentication Default
                                $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication Default
                                $SecurityOptions = Get-VBRSecurityOptions
                                Write-PscriboMessage "Collecting Backup Server information from $($BackupServer.Name)."
                                try {
                                    $VeeamVersion = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { get-childitem -recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | get-itemproperty | Where-Object { $_.DisplayName  -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion }
                                } catch {Write-PscriboMessage -IsWarning $_.Exception.Message}
                                try {
                                    $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                                } catch {Write-PscriboMessage -IsWarning $_.Exception.Message}
                                Write-PscriboMessage "Discovered $BackupServer Server."
                                $inObj = [ordered] @{
                                    'Server Name' = $BackupServer.Name
                                    'Version' = Switch (($VeeamVersion).count) {
                                        0 {"-"}
                                        default {$VeeamVersion.DisplayVersion}
                                    }
                                    'Database Server' = Switch (($VeeamInfo.SqlServerName).count) {
                                        0 {"-"}
                                        default {$VeeamInfo.SqlServerName}
                                    }
                                    'Database Instance' = Switch (($VeeamInfo.SqlInstanceName).count) {
                                        0 {"None"}
                                        default {$VeeamInfo.SqlInstanceName}
                                    }
                                    'Database Name' = Switch (($VeeamInfo.SqlDatabaseName).count) {
                                        0 {"-"}
                                        default {$VeeamInfo.SqlDatabaseName}
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
                            Write-PscriboMessage -IsWarning $_.Exception.Message
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
                            Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                            if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                $BackupServer = Get-VBRServer -Type Local
                                Write-PscriboMessage "Collecting Backup Server Inventory Summary from $($BackupServer.Name)."
                                $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                $License =  Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                if ($HW) {
                                    Section -Style Heading4 'Inventory Summary' {
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
                                            'Number of CPU Cores' = $HWCPU[0].NumberOfCores
                                            'Number of Logical Cores' = $HWCPU[0].NumberOfLogicalProcessors
                                            'Physical Memory (GB)' = ConvertTo-FileSizeString $HW.CsTotalPhysicalMemory
                                        }
                                        $OutObj += [pscustomobject]$inobj

                                        if ($HealthCheck.Infrastructure.Server) {
                                            $OutObj | Where-Object { $_.'Number of CPU Cores' -lt 4} | Set-Style -Style Warning -Property 'Number of CPU Cores'
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
                                        #---------------------------------------------------------------------------------------------#
                                        #                       Backup Server Local Disk Inventory Section                            #
                                        #---------------------------------------------------------------------------------------------#
                                        if ($InfoLevel.Infrastructure.BackupServer -ge 3) {
                                            try {
                                                $HostDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -ne "iSCSI" -and $_.BusType -ne "Fibre Channel" } }
                                                if ($HostDisks) {
                                                    Section -Style Heading5 'Local Disks' {
                                                        Blankline
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
                                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                            #---------------------------------------------------------------------------------------------#
                                            #                       Backup Server SAN Disk Inventory Section                              #
                                            #---------------------------------------------------------------------------------------------#
                                            try {
                                                $SanDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -Eq "iSCSI" -or $_.BusType -Eq "Fibre Channel" } }
                                                if ($SanDisks) {
                                                    Section -Style Heading5 'SAN Disks' {
                                                        Blankline
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
                                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                       Backup Server Volume Inventory Section                                #
                                        #---------------------------------------------------------------------------------------------#
                                        try {
                                            $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock {  Get-Volume | Where-Object {$_.DriveType -ne "CD-ROM" -and $NUll -ne $_.DriveLetter} }
                                            if ($HostVolumes) {
                                                Section -Style Heading5 'Host Volumes' {
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
                                                            Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                        #---------------------------------------------------------------------------------------------#
                                        #                       Backup Server Network Inventory Section                               #
                                        #---------------------------------------------------------------------------------------------#
                                        if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                            try {
                                                $HostAdapters = Invoke-Command -Session $PssSession { Get-NetAdapter }
                                                if ($HostAdapters) {
                                                    Section -Style Heading3 'Network Adapters' {
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
                                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                            try {
                                                $NetIPs = Invoke-Command -Session $PssSession { Get-NetIPConfiguration | Where-Object -FilterScript { ($_.NetAdapter.Status -Eq "Up") } }
                                                if ($NetIPs) {
                                                    Section -Style Heading3 'IP Address' {
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
                                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
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
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {
        if ($PssSession) {Remove-PSSession -Session $PssSession}
        if ($CimSession) {Remove-CimSession $CimSession}
    }

}