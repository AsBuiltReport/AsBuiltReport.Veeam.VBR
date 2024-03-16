
function Get-AbrVbrBackupProxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Proxies Information
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
        Write-PScriboMessage "Discovering Veeam V&R Backup Proxies information from $System."
    }

    process {
        try {
            if (((Get-VBRViProxy).count -gt 0) -or ((Get-VBRHvProxy).count -gt 0)) {
                Section -Style Heading3 'Backup Proxies' {
                    Paragraph "The following section provides a summary of the Veeam Backup Proxies"
                    BlankLine
                    $BackupProxies = Get-VBRViProxy
                    if ($BackupProxies) {
                        Section -Style Heading4 'VMware Backup Proxies' {
                            $OutObj = @()
                            try {
                                if ($InfoLevel.Infrastructure.Proxy -eq 1) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    Write-PScriboMessage "Collecting Summary Information."
                                    foreach ($BackupProxy in $BackupProxies) {
                                        Write-PScriboMessage "Discovered $($BackupProxy.Name) Repository."
                                        $inObj = [ordered] @{
                                            'Name' = $BackupProxy.Name
                                            'Type' = $BackupProxy.Type
                                            'Max Tasks Count' = $BackupProxy.MaxTasksCount
                                            'Disabled' = ConvertTo-TextYN $BackupProxy.IsDisabled
                                            'Status' = Switch (($BackupProxy.Host).IsUnavailable) {
                                                'False' { 'Available' }
                                                'True' { 'Unavailable' }
                                                default { ($BackupProxy.Host).IsUnavailable }
                                            }
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }

                                    if ($HealthCheck.Infrastructure.Proxy) {
                                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                                    }

                                    $TableParams = @{
                                        Name = "Backup Proxy - $VeeamBackupServer"
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
                                    Write-PScriboMessage "Collecting Detailed Information."
                                    foreach ($BackupProxy in $BackupProxies) {
                                        $inObj = [ordered] @{
                                            'Name' = $BackupProxy.Name
                                            'Host Name' = $BackupProxy.Host.Name
                                            'Type' = $BackupProxy.Type
                                            'Disabled' = ConvertTo-TextYN $BackupProxy.IsDisabled
                                            'Max Tasks Count' = $BackupProxy.MaxTasksCount
                                            'Use Ssl' = ConvertTo-TextYN $BackupProxy.UseSsl
                                            'Failover To Network' = ConvertTo-TextYN $BackupProxy.FailoverToNetwork
                                            'Transport Mode' = $BackupProxy.TransportMode
                                            'Chassis Type' = $BackupProxy.ChassisType
                                            'OS Type' = $BackupProxy.Host.Type
                                            'Services Credential' = ConvertTo-EmptyToFiller $BackupProxy.Host.ProxyServicesCreds.Name
                                            'Status' = Switch (($BackupProxy.Host).IsUnavailable) {
                                                'False' { 'Available' }
                                                'True' { 'Unavailable' }
                                                default { ($BackupProxy.Host).IsUnavailable }
                                            }
                                        }
                                        $OutObj = [pscustomobject]$inobj

                                        if ($HealthCheck.Infrastructure.Proxy) {
                                            $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                                        }

                                        $TableParams = @{
                                            Name = "Backup Proxy - $($BackupProxy.Name)"
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
                                    Write-PScriboMessage "Collecting Hardware/Software Inventory Summary."
                                    $BackupProxies = Get-VBRViProxy | Where-Object { $_.Host.Type -eq "Windows" }
                                    if ($BackupProxies) {
                                        $vSphereVBProxyObj = foreach ($BackupProxy in $BackupProxies) {
                                            if (Test-Connection -ComputerName $BackupProxy.Host.Name -Quiet -Count 2) {
                                                try {
                                                    Write-PScriboMessage "Collecting Backup Proxy Inventory Summary from $($BackupProxy.Host.Name)."
                                                    $CimSession = New-CimSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                                                    $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction SilentlyContinue
                                                    if ($PssSession) {
                                                        $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                                    } else { Write-PScriboMessage -IsWarning "VMware Backup Proxies Hardware/Software Inventory: Unable to connect to $($BackupProxy.Host.Name)" }
                                                    if ($HW) {
                                                        $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                                        $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                                        $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                                        Section -Style Heading5 $($BackupProxy.Host.Name.Split(".")[0]) {
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
                                                                $OutObj | Where-Object { $_.'Number of CPU Cores' -lt 4 } | Set-Style -Style Warning -Property 'Number of CPU Cores'
                                                                if ([int]([regex]::Matches($OutObj.'Physical Memory (GB)', "\d+(?!.*\d+)").value) -lt 8) { $OutObj | Set-Style -Style Warning -Property 'Physical Memory (GB)' }
                                                            }

                                                            $TableParams = @{
                                                                Name = "Backup Proxy Inventory - $($BackupProxy.Host.Name.Split(".")[0])"
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
                                                                    $HostDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -ne "iSCSI" -and $_.BusType -ne "Fibre Channel" } }
                                                                    if ($HostDisks) {
                                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Local Disks' {
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
                                                                                } catch {
                                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Local Disks $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                }
                                                                            }
                                                                            $TableParams = @{
                                                                                Name = "Local Disks - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Fibre Channel Section: $($_.Exception.Message)"
                                                                }
                                                                #---------------------------------------------------------------------------------------------#
                                                                #                       Backup Proxy SAN Disk Inventory Section                              #
                                                                #---------------------------------------------------------------------------------------------#
                                                                try {
                                                                    $SanDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -Eq "iSCSI" -or $_.BusType -Eq "Fibre Channel" } }
                                                                    if ($SanDisks) {
                                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'SAN Disks' {
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
                                                                                } catch {
                                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Fibre Channel $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                }
                                                                            }
                                                                            $TableParams = @{
                                                                                Name = "SAN Disks - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Fibre Channel Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                            try {
                                                                $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock { Get-Volume | Where-Object { $_.DriveType -ne "CD-ROM" -and $NUll -ne $_.DriveLetter } }
                                                                if ($HostVolumes) {
                                                                    Section -Style NOTOCHeading6 -ExcludeFromTOC 'Host Volumes' {
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
                                                                            } catch {
                                                                                Write-PScriboMessage -IsWarning "VMware Backup Proxies Host Volumes $($HostVolume.DriveLetter) Section: $($_.Exception.Message)"
                                                                            }
                                                                        }
                                                                        $TableParams = @{
                                                                            Name = "Volumes - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                Write-PScriboMessage -IsWarning "VMware Backup Proxies Host Volumes Section: $($_.Exception.Message)"
                                                            }
                                                            #---------------------------------------------------------------------------------------------#
                                                            #                       Backup Proxy Network Inventory Section                               #
                                                            #---------------------------------------------------------------------------------------------#
                                                            if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                                                                try {
                                                                    $HostAdapters = Invoke-Command -Session $PssSession { Get-NetAdapter }
                                                                    if ($HostAdapters) {
                                                                        Section -Style NOTOCHeading3 -ExcludeFromTOC 'Network Adapters' {
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
                                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Network Adapter $($HostAdapter.Name) Section: $($_.Exception.Message)"
                                                                                }
                                                                            }
                                                                            $TableParams = @{
                                                                                Name = "Network Adapters - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Network Adapter Section: $($_.Exception.Message)"
                                                                }
                                                                try {
                                                                    $NetIPs = Invoke-Command -Session $PssSession { Get-NetIPConfiguration | Where-Object -FilterScript { ($_.NetAdapter.Status -Eq "Up") } }
                                                                    if ($NetIPs) {
                                                                        Section -Style NOTOCHeading3 -ExcludeFromTOC 'IP Address' {
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
                                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies IP Address $($NetIp.InterfaceAlias) Section: $($_.Exception.Message)"
                                                                                }
                                                                            }
                                                                            $TableParams = @{
                                                                                Name = "IP Address - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies IP Address Section: $($_.Exception.Message)"
                                                                }
                                                            }
                                                        }
                                                        Remove-PSSession -Session $PssSession
                                                        Remove-CimSession $CimSession
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies  Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                        if ($vSphereVBProxyObj) {
                                            Section -Style Heading4 "Hardware & Software Inventory" {
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
                                    if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                                        Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                        Write-PScriboMessage "Collecting Veeam Services Information."
                                        $BackupProxies = Get-VBRViProxy | Where-Object { $_.Host.Type -eq "Windows" }
                                        foreach ($BackupProxy in $BackupProxies) {
                                            if (Test-Connection -ComputerName $BackupProxy.Host.Name -Quiet -Count 2) {
                                                try {
                                                    $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction SilentlyContinue
                                                    if ($PssSession) {
                                                        $Available = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service "W32Time" | Select-Object DisplayName, Name, Status }
                                                        Write-PScriboMessage "Collecting Backup Proxy Service information from $($BackupProxy.Name)."
                                                        $Services = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service Veeam* }
                                                        if ($PssSession) {
                                                            Remove-PSSession -Session $PssSession
                                                        }
                                                        if ($Available -and $Services) {
                                                            Section -Style NOTOCHeading4 -ExcludeFromTOC "HealthCheck - $($BackupProxy.Host.Name.Split(".")[0]) Services Status" {
                                                                $OutObj = @()
                                                                foreach ($Service in $Services) {
                                                                    Write-PScriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupProxy.Name)."
                                                                    $inObj = [ordered] @{
                                                                        'Display Name' = $Service.DisplayName
                                                                        'Short Name' = $Service.Name
                                                                        'Status' = $Service.Status
                                                                    }
                                                                    $OutObj += [pscustomobject]$inobj
                                                                }

                                                                if ($HealthCheck.Infrastructure.Server) {
                                                                    $OutObj | Where-Object { $_.'Status' -notlike 'Running' } | Set-Style -Style Warning -Property 'Status'
                                                                }

                                                                $TableParams = @{
                                                                    Name = "HealthCheck - Services Status - $($BackupProxy.Host.Name.Split(".")[0])"
                                                                    List = $false
                                                                    ColumnWidths = 45, 35, 20
                                                                }
                                                                if ($Report.ShowTableCaptions) {
                                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                }
                                                                $OutObj | Sort-Object -Property 'Display Name' | Table @TableParams
                                                            }
                                                        }
                                                    } else { Write-PScriboMessage -IsWarning "VMware Backup Proxies Services Status Section: Unable to connect to $($BackupProxy.Host.Name)" }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies $($BackupProxy.Host.Name) Services Status Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "VMware Backup Proxies Services Status Section: $($_.Exception.Message)"
                                }
                            }
                            if ($Options.EnableDiagrams) {
                                Try {
                                    Try {
                                        $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-vSphere-Proxy"
                                    } Catch {
                                        Write-PScriboMessage -IsWarning "VMware Backup Proxy Diagram: $($_.Exception.Message)"
                                    }
                                    if ($Graph) {
                                        Section -Style Heading3 "VMware Backup Proxy Diagram." {
                                            Image -Base64 $Graph -Text "VMware Backup Proxy Diagram" -Percent (Get-ImagePercent -Graph $Graph) -Align Center
                                            Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                        }
                                        BlankLine
                                    }
                                } Catch {
                                    Write-PScriboMessage -IsWarning "VMware Backup Proxy Diagram Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                       Hyper-V Backup Prxy information Section                               #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        $BackupProxies = Get-VBRHvProxy
                        if ($BackupProxies) {
                            Section -Style Heading4 'Hyper-V Backup Proxies' {
                                $OutObj = @()
                                if ($InfoLevel.Infrastructure.Proxy -eq 1) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    Write-PScriboMessage "Collecting Summary Information."
                                    foreach ($BackupProxy in $BackupProxies) {
                                        try {
                                            Write-PScriboMessage "Discovered $($BackupProxy.Name) Proxy."
                                            $inObj = [ordered] @{
                                                'Name' = $BackupProxy.Name
                                                'Type' = $BackupProxy.Type
                                                'Max Tasks Count' = $BackupProxy.MaxTasksCount
                                                'Disabled' = ConvertTo-TextYN $BackupProxy.IsDisabled
                                                'Status' = Switch (($BackupProxy.Host).IsUnavailable) {
                                                    'False' { 'Available' }
                                                    'True' { 'Unavailable' }
                                                    default { ($BackupProxy.Host).IsUnavailable }
                                                }
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies $($BackupProxy.Name) Section: $($_.Exception.Message)"
                                        }
                                    }

                                    if ($HealthCheck.Infrastructure.Proxy) {
                                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                                    }

                                    $TableParams = @{
                                        Name = "Backup Proxy - $VeeamBackupServer"
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
                                    Write-PScriboMessage "Collecting Detailed Information."
                                    foreach ($BackupProxy in $BackupProxies) {
                                        try {
                                            Write-PScriboMessage "Discovered $($BackupProxy.Name) Repository."
                                            $inObj = [ordered] @{
                                                'Name' = $BackupProxy.Name
                                                'Host Name' = $BackupProxy.Host.Name
                                                'Type' = $BackupProxy.Type
                                                'Disabled' = ConvertTo-TextYN $BackupProxy.IsDisabled
                                                'Max Tasks Count' = $BackupProxy.MaxTasksCount
                                                'AutoDetect Volumes' = ConvertTo-TextYN $BackupProxy.Options.IsAutoDetectVolumes
                                                'OS Type' = $BackupProxy.Host.Type
                                                'Services Credential' = ConvertTo-EmptyToFiller $BackupProxy.Host.ProxyServicesCreds.Name
                                                'Status' = Switch (($BackupProxy.Host).IsUnavailable) {
                                                    'False' { 'Available' }
                                                    'True' { 'Unavailable' }
                                                    default { ($BackupProxy.Host).IsUnavailable }
                                                }
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            if ($HealthCheck.Infrastructure.Proxy) {
                                                $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                                            }

                                            $TableParams = @{
                                                Name = "Backup Proxy - $($BackupProxy.Host.Name.Split(".")[0])"
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
                                        Write-PScriboMessage "Collecting Hardware/Software Inventory Summary."
                                        $BackupProxies = Get-VBRHvProxy
                                        if ($BackupProxies) {
                                            $HyperVBProxyObj = foreach ($BackupProxy in $BackupProxies) {
                                                if (Test-Connection -ComputerName $BackupProxy.Host.Name -Quiet -Count 2) {
                                                    try {
                                                        Write-PScriboMessage "Collecting Backup Proxy Inventory Summary from $($BackupProxy.Host.Name)."
                                                        $CimSession = New-CimSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                                                        $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction SilentlyContinue
                                                        if ($PssSession) {
                                                            $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                                        } else { Write-PScriboMessage -IsWarning "VMware Backup Proxies Inventory Section: Unable to connect to $($BackupProxy.Host.Name)" }
                                                        if ($HW) {
                                                            $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                                            $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                                            $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                                            Section -Style Heading5 $($BackupProxy.Host.Name.Split(".")[0]) {
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
                                                                    $OutObj | Where-Object { $_.'Number of CPU Cores' -lt 4 } | Set-Style -Style Warning -Property 'Number of CPU Cores'
                                                                    if ([int]([regex]::Matches($OutObj.'Physical Memory (GB)', "\d+(?!.*\d+)").value) -lt 8) { $OutObj | Set-Style -Style Warning -Property 'Physical Memory (GB)' }
                                                                }

                                                                $TableParams = @{
                                                                    Name = "Backup Proxy Inventory - $($BackupProxy.Host.Name.Split(".")[0])"
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
                                                                        $HostDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -ne "iSCSI" -and $_.BusType -ne "Fibre Channel" } }
                                                                        if ($HostDisks) {
                                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Local Disks' {
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
                                                                                    } catch {
                                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Local Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "Local Disks - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Local Disk Section: $($_.Exception.Message)"
                                                                    }
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    #                       Backup Proxy SAN Disk Inventory Section                              #
                                                                    #---------------------------------------------------------------------------------------------#
                                                                    try {
                                                                        $SanDisks = Invoke-Command -Session $PssSession -ScriptBlock { Get-Disk | Where-Object { $_.BusType -Eq "iSCSI" -or $_.BusType -Eq "Fibre Channel" } }
                                                                        if ($SanDisks) {
                                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC 'SAN Disks' {
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
                                                                                    } catch {
                                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies SAN Disk $($Disk.Number) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "SAN Disks - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Local Disk Section: $($_.Exception.Message)"
                                                                    }
                                                                }
                                                                #---------------------------------------------------------------------------------------------#
                                                                #                       Backup Proxy Volume Inventory Section                                #
                                                                #---------------------------------------------------------------------------------------------#
                                                                try {
                                                                    $HostVolumes = Invoke-Command -Session $PssSession -ScriptBlock { Get-Volume | Where-Object { $_.DriveType -ne "CD-ROM" -and $NUll -ne $_.DriveLetter } }
                                                                    if ($HostVolumes) {
                                                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Host Volumes' {
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
                                                                                } catch {
                                                                                    Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Host Volume $($HostVolume.DriveLetter) Section: $($_.Exception.Message)"
                                                                                }
                                                                            }
                                                                            $TableParams = @{
                                                                                Name = "Volumes - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                    Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Host Volume Section: $($_.Exception.Message)"
                                                                }
                                                                #---------------------------------------------------------------------------------------------#
                                                                #                       Backup Proxy Network Inventory Section                               #
                                                                #---------------------------------------------------------------------------------------------#
                                                                if ($InfoLevel.Infrastructure.Proxy -ge 2) {
                                                                    try {
                                                                        $HostAdapters = Invoke-Command -Session $PssSession { Get-NetAdapter }
                                                                        if ($HostAdapters) {
                                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC 'Network Adapters' {
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
                                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Network Adapter $($HostAdapter.Name) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "Network Adapters - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Network Adapter Section: $($_.Exception.Message)"
                                                                    }
                                                                    try {
                                                                        $NetIPs = Invoke-Command -Session $PssSession { Get-NetIPConfiguration | Where-Object -FilterScript { ($_.NetAdapter.Status -Eq "Up") } }
                                                                        if ($NetIPs) {
                                                                            Section -Style NOTOCHeading6 -ExcludeFromTOC 'IP Address' {
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
                                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies IP Address $($NetIp.InterfaceAlias) Section: $($_.Exception.Message)"
                                                                                    }
                                                                                }
                                                                                $TableParams = @{
                                                                                    Name = "IP Address - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies IP Address Section: $($_.Exception.Message)"
                                                                    }
                                                                }
                                                            }
                                                            Remove-PSSession -Session $PssSession
                                                            Remove-CimSession $CimSession
                                                        }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Hardware & Software Inventory Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                            if ($HyperVBProxyObj) {
                                                Section -Style Heading4 'Hardware & Software Inventory' {
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
                                        if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                                            Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                            Write-PScriboMessage "Collecting Veeam Service Information."
                                            $BackupProxies = Get-VBRHvProxy
                                            foreach ($BackupProxy in $BackupProxies) {
                                                if (Test-Connection -ComputerName $BackupProxy.Host.Name -Quiet -Count 2) {
                                                    try {
                                                        $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction SilentlyContinue
                                                        if ($PssSession) {
                                                            $Available = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service "W32Time" | Select-Object DisplayName, Name, Status }
                                                            Write-PScriboMessage "Collecting Backup Proxy Service information from $($BackupProxy.Name)."
                                                            $Services = Invoke-Command -Session $PssSession -ScriptBlock { Get-Service Veeam* }
                                                            if ($PssSession) {
                                                                Remove-PSSession -Session $PssSession
                                                            }
                                                            if ($Available -and $Services) {
                                                                Section -Style NOTOCHeading4 -ExcludeFromTOC "HealthCheck - $($BackupProxy.Host.Name.Split(".")[0]) Services Status" {
                                                                    $OutObj = @()
                                                                    foreach ($Service in $Services) {
                                                                        Write-PScriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupProxy.Name)."
                                                                        $inObj = [ordered] @{
                                                                            'Display Name' = $Service.DisplayName
                                                                            'Short Name' = $Service.Name
                                                                            'Status' = $Service.Status
                                                                        }
                                                                        $OutObj += [pscustomobject]$inobj
                                                                    }

                                                                    if ($HealthCheck.Infrastructure.Server) {
                                                                        $OutObj | Where-Object { $_.'Status' -notlike 'Running' } | Set-Style -Style Warning -Property 'Status'
                                                                    }

                                                                    $TableParams = @{
                                                                        Name = "HealthCheck - Services Status - $($BackupProxy.Host.Name.Split(".")[0])"
                                                                        List = $false
                                                                        ColumnWidths = 45, 35, 20
                                                                    }
                                                                    if ($Report.ShowTableCaptions) {
                                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                    }
                                                                    $OutObj | Sort-Object -Property 'Display Name' | Table @TableParams
                                                                }
                                                            }
                                                        } else { Write-PScriboMessage -IsWarning "VMware Backup Proxies Services Status Section: Unable to connect to $($BackupProxy.Host.Name)" }
                                                    } catch {
                                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Services Status - $($BackupProxy.Host.Name.Split(".")[0]) Section: $($_.Exception.Message)"
                                                    }
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Hyper-V Backup Proxies Services Status Section: $($_.Exception.Message)"
                                    }
                                }
                                if ($Options.EnableDiagrams) {
                                    Try {
                                        Try {
                                            $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-HyperV-Proxy"
                                        } Catch {
                                            Write-PScriboMessage -IsWarning "HyperV Backup Proxy Diagram: $($_.Exception.Message)"
                                        }
                                        if ($Graph) {
                                            Section -Style Heading3 "HyperV Backup Proxy Diagram." {
                                                Image -Base64 $Graph -Text "HyperV Backup Proxy Diagram" -Percent (Get-ImagePercent -Graph $Graph) -Align Center
                                                Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                            }
                                            BlankLine
                                        }
                                    } Catch {
                                        Write-PScriboMessage -IsWarning "HyperV Backup Proxy Diagram Section: $($_.Exception.Message)"
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
    end {}

}