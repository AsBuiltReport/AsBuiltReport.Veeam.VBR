
function Get-AbrVbrBackupServerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Backup Server Information
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
        Write-PscriboMessage "Discovering Veeam V&R Server information from $System."
    }

    process {
        Section -Style Heading3 'Backup Server Information' {
            Paragraph "The following section provides a summary of the local Veeam Backup Server"
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $BackupServers = Get-VBRServer -Type Local
                    foreach ($BackupServer in $BackupServers) {
                        $SecurityOptions = Get-VBRSecurityOptions
                        Write-PscriboMessage "Discovered $BackupServer Server."
                        $inObj = [ordered] @{
                            'Server Name' = $BackupServer.Name
                            'Description' = $BackupServer.Description
                            'Type' = $BackupServer.Type
                            'Status' = Switch ($BackupServer.IsUnavailable) {
                                'False' {'Available'}
                                'True' {'Unavailable'}
                                default {$BackupServer.IsUnavailable}
                            }
                            'Api Version' = $BackupServer.ApiVersion
                            'Audit Logs Path' = $SecurityOptions.AuditLogsPath
                            'Compress Old Audit Logs' = ConvertTo-TextYN $SecurityOptions.CompressOldAuditLogs
                            'Fips Compliant Mode' = Switch ($SecurityOptions.FipsCompliantModeEnabled) {
                                'True' {"Enabled"}
                                'False' {"Disabled"}
                            }

                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                if ($HealthCheck.Infrastructure.Server) {
                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                }

                $TableParams = @{
                    Name = "Backup Server Information - $($BackupServer.Name.Split(".")[0])"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
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
                                    Name = "Backup Server Hardware Information - $($BackupServer.Name.Split(".")[0])"
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
                            Section -Style Heading4 "Veeam Services Status" {
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
                                    Name = "Veeam Services Status - $($BackupServer.Name.Split(".")[0])"
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
    end {}

}