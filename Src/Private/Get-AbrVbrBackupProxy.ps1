
function Get-AbrVbrBackupProxy {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Proxies Information
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam V&R Backup Proxies information from $System."
    }

    process {
        if (((Get-VBRViProxy).count -gt 0) -or ((Get-VBRHvProxy).count -gt 0)) {
            Section -Style Heading3 'Backup Proxies' {
                Paragraph "The following section provides a summary of the Veeam Backup Proxies"
                BlankLine
                $BackupProxies = Get-VBRViProxy
                if ($BackupProxies) {
                    Section -Style Heading4 'VMware Backup Proxies' {
                        $OutObj = @()
                        if ((Get-VBRServerSession).Server) {
                            try {
                                if ($InfoLevel.Infrastructure.Proxy -eq 1) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    Write-PScriboMessage "Collecting Summary Information."
                                    foreach ($BackupProxy in $BackupProxies) {
                                        Write-PscriboMessage "Discovered $($BackupProxy.Name) Repository."
                                        $inObj = [ordered] @{
                                            'Name' = $BackupProxy.Name
                                            'Type' = $BackupProxy.Type
                                            'Max Tasks Count' = $BackupProxy.MaxTasksCount
                                            'Disabled' = ConvertTo-TextYN $BackupProxy.IsDisabled
                                            'Status' = Switch (($BackupProxy.Host).IsUnavailable) {
                                                'False' {'Available'}
                                                'True' {'Unavailable'}
                                                default {($BackupProxy.Host).IsUnavailable}
                                            }
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }

                                    if ($HealthCheck.Infrastructure.Proxy) {
                                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                    }

                                    $TableParams = @{
                                        Name = "Backup Proxy Information - $($BackupProxy.Name)"
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
                                                'False' {'Available'}
                                                'True' {'Unavailable'}
                                                default {($BackupProxy.Host).IsUnavailable}
                                            }
                                        }
                                        $OutObj = [pscustomobject]$inobj

                                        if ($HealthCheck.Infrastructure.Proxy) {
                                            $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                        }

                                        $TableParams = @{
                                            Name = "Backup Proxy Information - $($BackupProxy.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }

                            try {
                                if ($InfoLevel.Infrastructure.Proxy -ge 3) {
                                    Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                    Write-PScriboMessage "Collecting Hardware Information."
                                    $BackupProxies = Get-VBRViProxy | Where-Object {$_.Host.Type -eq "Windows"}
                                    foreach ($BackupProxy in $BackupProxies) {
                                        try {
                                            Write-PscriboMessage "Collecting Backup Proxy Hardware information from $($BackupProxy.Host.Name)."
                                            $CimSession = New-CimSession $BackupProxy.Host.Name -Credential $Credential -Authentication Default
                                            $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication Default
                                            if ($PssSession) {
                                                $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                            }
                                            if ($HW) {
                                                $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                                $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                                $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                                Remove-PSSession -Session $PssSession
                                                Remove-CimSession $CimSession
                                                Section -Style Heading4 "$($BackupProxy.Host.Name.Split(".")[0]) Hardware Information" {
                                                    $OutObj = @()
                                                    $inObj = [ordered] @{
                                                        'Name' = $HW.CsDNSHostName
                                                        'Windows Product Name' = $HW.WindowsProductName
                                                        'Windows Current Version' = $HW.WindowsCurrentVersion
                                                        'Windows Build Number' = $HW.OsVersion
                                                        'Windows Install Type' = $HW.WindowsInstallationType
                                                        'AD Domain' = $HW.CsDomain
                                                        'Windows Installation Date' = $HW.OsInstallDate
                                                        'Time Zone' = $HW.TimeZone
                                                        'License Type' = $License.ProductKeyChannel
                                                        'Partial Product Key' = $License.PartialProductKey
                                                        'Manufacturer' = $HW.CsManufacturer
                                                        'Model' = $HW.CsModel
                                                        'Serial Number' = $HostBIOS.SerialNumber
                                                        'Bios Type' = $HW.BiosFirmwareType
                                                        'BIOS Version' = $HostBIOS.Version
                                                        'Processor Manufacturer' = $HWCPU[0].Manufacturer
                                                        'Processor Model' = $HWCPU[0].Name
                                                        'Number of CPU Cores' = $HWCPU[0].NumberOfCores
                                                        'Number of Logical Cores' = $HWCPU[0].NumberOfLogicalProcessors
                                                        'Physical Memory (GB)' = ConvertTo-FileSizeString $HW.CsTotalPhysicalMemory
                                                    }
                                                    $OutObj += [pscustomobject]$inobj

                                                    if ($HealthCheck.Infrastructure.Server) {
                                                        $OutObj | Where-Object { $_.'Number of CPU Cores' -lt 4} | Set-Style -Style Warning -Property 'Number of CPU Cores'
                                                        $OutObj | Where-Object { $_.'Physical Memory (GB)' -lt 8} | Set-Style -Style Warning -Property 'Physical Memory (GB)'
                                                    }

                                                    $TableParams = @{
                                                        Name = "Backup Proxy Hardware Information - $($BackupProxy.Host.Name.Split(".")[0])"
                                                        List = $true
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                            if ($HealthCheck.Infrastructure.Server) {
                                try {
                                    if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                                        Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                        Write-PScriboMessage "Collecting Veeam Services Information."
                                        $BackupProxies = Get-VBRViProxy | Where-Object {$_.Host.Type -eq "Windows"}
                                        foreach ($BackupProxy in $BackupProxies) {
                                            try {
                                                $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication Default
                                                $Available = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service "W32Time" | Select-Object DisplayName, Name, Status}
                                                Write-PscriboMessage "Collecting Backup Proxy Service information from $($BackupServer.Name)."
                                                if ($PssSession) {
                                                    $Services = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service Veeam*}
                                                }
                                                if ($PssSession) {
                                                    Remove-PSSession -Session $PssSession
                                                }
                                                if ($Available) {
                                                    Section -Style Heading4 "HealthCheck - $($BackupProxy.Host.Name.Split(".")[0]) Services Status" {
                                                        $OutObj = @()
                                                        foreach ($Service in $Services) {
                                                            Write-PscriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupServer.Namr)."
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
                                                            Name = "HealthCheck - Services Status - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
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
                if ((Get-VBRServerSession).Server) {
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
                                            Write-PscriboMessage "Discovered $($BackupProxy.Name) Proxy."
                                            $inObj = [ordered] @{
                                                'Name' = $BackupProxy.Name
                                                'Type' = $BackupProxy.Type
                                                'Max Tasks Count' = $BackupProxy.MaxTasksCount
                                                'Disabled' = ConvertTo-TextYN $BackupProxy.IsDisabled
                                                'Status' = Switch (($BackupProxy.Host).IsUnavailable) {
                                                    'False' {'Available'}
                                                    'True' {'Unavailable'}
                                                    default {($BackupProxy.Host).IsUnavailable}
                                                }
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }

                                    if ($HealthCheck.Infrastructure.Proxy) {
                                        $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                    }

                                    $TableParams = @{
                                        Name = "Backup Proxy Information - $($BackupProxy.Name)"
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
                                            Write-PscriboMessage "Discovered $($BackupProxy.Name) Repository."
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
                                                    'False' {'Available'}
                                                    'True' {'Unavailable'}
                                                    default {($BackupProxy.Host).IsUnavailable}
                                                }
                                            }
                                            $OutObj = [pscustomobject]$inobj

                                            if ($HealthCheck.Infrastructure.Proxy) {
                                                $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                            }

                                            $TableParams = @{
                                                Name = "Backup Proxy Information - $($BackupProxy.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                                try {
                                    if ($InfoLevel.Infrastructure.Proxy -ge 3) {
                                        Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                        Write-PScriboMessage "Collecting Hardware Information."
                                        $BackupProxies = Get-VBRHvProxy
                                        foreach ($BackupProxy in $BackupProxies) {
                                            try {
                                                Write-PscriboMessage "Collecting Backup Proxy Hardware information from $($BackupProxy.Host.Name)."
                                                $CimSession = New-CimSession $BackupProxy.Host.Name -Credential $Credential -Authentication Default
                                                $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication Default
                                                if ($PssSession) {
                                                    $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                                }
                                                if ($HW) {
                                                    $License = Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                                    $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                                    $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                                    Remove-PSSession -Session $PssSession
                                                    Remove-CimSession $CimSession
                                                    Section -Style Heading4 "$($BackupProxy.Host.Name.Split(".")[0]) Hardware Information" {
                                                        $OutObj = @()
                                                        $inObj = [ordered] @{
                                                            'Name' = $HW.CsDNSHostName
                                                            'Windows Product Name' = $HW.WindowsProductName
                                                            'Windows Current Version' = $HW.WindowsCurrentVersion
                                                            'Windows Build Number' = $HW.OsVersion
                                                            'Windows Install Type' = $HW.WindowsInstallationType
                                                            'AD Domain' = $HW.CsDomain
                                                            'Windows Installation Date' = $HW.OsInstallDate
                                                            'Time Zone' = $HW.TimeZone
                                                            'License Type' = $License.ProductKeyChannel
                                                            'Partial Product Key' = $License.PartialProductKey
                                                            'Manufacturer' = $HW.CsManufacturer
                                                            'Model' = $HW.CsModel
                                                            'Serial Number' = $HostBIOS.SerialNumber
                                                            'Bios Type' = $HW.BiosFirmwareType
                                                            'BIOS Version' = $HostBIOS.Version
                                                            'Processor Manufacturer' = $HWCPU[0].Manufacturer
                                                            'Processor Model' = $HWCPU[0].Name
                                                            'Number of CPU Cores' = $HWCPU[0].NumberOfCores
                                                            'Number of Logical Cores' = $HWCPU[0].NumberOfLogicalProcessors
                                                            'Physical Memory (GB)' = ConvertTo-FileSizeString $HW.CsTotalPhysicalMemory
                                                        }
                                                        $OutObj += [pscustomobject]$inobj

                                                        if ($HealthCheck.Infrastructure.Server) {
                                                            $OutObj | Where-Object { $_.'Number of CPU Cores' -lt 4} | Set-Style -Style Warning -Property 'Number of CPU Cores'
                                                            $OutObj | Where-Object { $_.'Physical Memory (GB)' -lt 8} | Set-Style -Style Warning -Property 'Physical Memory (GB)'
                                                        }

                                                        $TableParams = @{
                                                            Name = "Backup Proxy Hardware Information - $($BackupProxy.Host.Name.Split(".")[0])"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }
                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                }
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                    }
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                                if ($HealthCheck.Infrastructure.Server) {
                                    try {
                                        if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                                            Write-PScriboMessage "Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                                            Write-PScriboMessage "Collecting Veeam Service Information."
                                            $BackupProxies = Get-VBRHvProxy
                                            foreach ($BackupProxy in $BackupProxies) {
                                                try {
                                                    $PssSession = New-PSSession $BackupProxy.Host.Name -Credential $Credential -Authentication Default
                                                    $Available = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service "W32Time" | Select-Object DisplayName, Name, Status}
                                                    Write-PscriboMessage "Collecting Backup Proxy Service information from $($BackupServer.Name)."
                                                    if ($PssSession) {
                                                        $Services = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service Veeam*}
                                                    }
                                                    if ($PssSession) {
                                                        Remove-PSSession -Session $PssSession
                                                    }
                                                    if ($Available) {
                                                        Section -Style Heading4 "HealthCheck - $($BackupProxy.Host.Name.Split(".")[0]) Services Status" {
                                                            $OutObj = @()
                                                            foreach ($Service in $Services) {
                                                                Write-PscriboMessage "Collecting '$($Service.DisplayName)' status on $($BackupServer.Namr)."
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
                                                                Name = "HealthCheck - Services Status - $($BackupProxies.Host.Name.Split(".")[0])"
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
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
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
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }

                }
            }
        }
    }
    end {}

}