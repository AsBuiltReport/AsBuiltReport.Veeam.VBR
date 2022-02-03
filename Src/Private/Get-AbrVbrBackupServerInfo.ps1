
function Get-AbrVbrBackupServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
    .DESCRIPTION
    .NOTES
        Version:        0.3.0
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
                                $SecurityOptions = Get-VBRSecurityOptions
                                Write-PscriboMessage "Collecting Backup Server information from $($BackupServer.Name)."
                                $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication Default
                                try {
                                    $VeeamVersion = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { get-childitem -recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | get-itemproperty | Where-Object { $_.DisplayName  -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion }
                                } catch {Write-PscriboMessage -IsWarning $_.Exception.Message}
                                try {
                                    $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                                } catch {Write-PscriboMessage -IsWarning $_.Exception.Message}
                                Write-PscriboMessage "Discovered $BackupServer Server."
                                Remove-PSSession -Session $PssSession
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
                        #                       Backup Server Hardware Information Section                            #
                        #---------------------------------------------------------------------------------------------#
                        try {
                            Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                            if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                $BackupServer = Get-VBRServer -Type Local
                                Write-PscriboMessage "Collecting Backup Server Hardware information from $($BackupServer.Name)."
                                $CimSession = New-CimSession $BackupServer.Name -Credential $Credential -Authentication Default
                                $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication Default
                                $HW = Invoke-Command -Session $PssSession -ScriptBlock { Get-ComputerInfo }
                                $License =  Get-CimInstance -Query 'Select * from SoftwareLicensingProduct' -CimSession $CimSession | Where-Object { $_.LicenseStatus -eq 1 }
                                $HWCPU = Get-CimInstance -Class Win32_Processor -CimSession $CimSession
                                $HWBIOS = Get-CimInstance -Class Win32_Bios -CimSession $CimSession
                                Remove-PSSession -Session $PssSession
                                Remove-CimSession $CimSession
                                if ($HW) {
                                    Section -Style Heading4 'Hardware Information' {
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
                                            Name = "Backup Server Hardware - $($BackupServer.Name.Split(".")[0])"
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
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                        #---------------------------------------------------------------------------------------------#
                        #                             Backup Server Services Information Section                      #
                        #---------------------------------------------------------------------------------------------#
                        if ($HealthCheck.Infrastructure.Server) {
                            try {
                                Write-PScriboMessage "Infrastructure Backup Server InfoLevel set at $($InfoLevel.Infrastructure.BackupServer)."
                                if ($InfoLevel.Infrastructure.BackupServer -ge 2) {
                                    $BackupServer = Get-VBRServer -Type Local
                                    $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication Default
                                    $Available = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service "W32Time" | Select-Object DisplayName, Name, Status}
                                    Write-PscriboMessage "Collecting Backup Server Hardware information from $($BackupServer.Name)."
                                    $Services = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service Veeam*}
                                    Remove-PSSession -Session $PssSession
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
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}
