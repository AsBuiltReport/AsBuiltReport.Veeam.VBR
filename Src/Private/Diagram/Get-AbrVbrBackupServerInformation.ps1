function Get-AbrBackupServerInformation {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication server information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.8.24
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]

    param
    (

    )
    process {
        try {
            if (($VbrVersion -gt 13) -and (-not (Get-VBRServer | Where-Object { $_.Description -eq 'Backup server' -and $_.Type -eq 'Linux' })) -and $ClientOSVersion -eq 'Win32NT') {
                if (-not $IsLocalServer) {
                    if (Test-WSMan -Credential $Credential -Authentication Negotiate -ComputerName $VBRServer -ErrorAction SilentlyContinue) {
                        $PssSession = try { New-PSSession $VBRServer -Credential $Credential -Authentication Negotiate -ErrorAction Stop -Name 'PSSBackupServerDiagram' } catch {
                            Write-Error "Veeam.Diagrammer: New-PSSession: Unable to connect to $($VBRServer), WinRM disabled or not configured."
                            Write-Error -Message $_.Exception.Message
                        }
                    } else {
                        Write-Error "Veeam.Diagrammer: Test-WSMan: Unable to connect to $($VBRServer), WinRM disabled or not configured."
                    }
                }
            }
            Write-PScriboMessage "Collecting Backup Server information from $($VBRServer)."

            if ($IsLocalServer) {
                $VeeamInfo = & {
                    $VeeamVersion = Get-ChildItem -Recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion
                    $VeeamDBFlavor = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations'
                    $VeeamDBInfo12 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\$($VeeamDBFlavor.SqlActiveConfiguration)"
                    $VeeamDBInfo11 = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication'
                    return [PSCustomObject]@{
                        Version = $VeeamVersion.DisplayVersion
                        DBFlavor = $VeeamDBFlavor
                        DBInfo12 = $VeeamDBInfo12
                        DBInfo11 = $VeeamDBInfo11
                    }
                }
                $VeeamBuild = Get-VBRBackupServerInfo
            } else {
                if ($PssSession) {
                    $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock {
                        $VeeamVersion = Get-ChildItem -Recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion
                        $VeeamDBFlavor = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations'
                        $VeeamDBInfo12 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\$($VeeamDBFlavor.SqlActiveConfiguration)"
                        $VeeamDBInfo11 = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication'
                        return [PSCustomObject]@{
                            Version = $VeeamVersion.DisplayVersion
                            DBFlavor = $VeeamDBFlavor
                            DBInfo12 = $VeeamDBInfo12
                            DBInfo11 = $VeeamDBInfo11
                        }
                    }
                } else {
                    $VeeamBuild = Get-VBRBackupServerInfo
                }
            }

            $VeeamDBInfo = if ($VeeamInfo.DBInfo11.SqlServerName) {
                $VeeamInfo.DBInfo11.SqlServerName
            } elseif ($VeeamInfo.DBInfo12.SqlServerName) {
                $VeeamInfo.DBInfo12.SqlServerName
            } elseif ($VeeamInfo.DBInfo12.SqlHostName) {
                switch ($VeeamInfo.DBInfo12.SqlHostName) {
                    'localhost' { $VBRServer }
                    default { $VeeamInfo.DBInfo12.SqlHostName }
                }
            } else {
                $VBRServer
            }

            if ($VBRServer) {
                $Roles = if ($VeeamDBInfo -eq $VBRServer) { 'Backup and Database' } else { 'Backup Server' }
                $DBType = $VeeamInfo.DBFlavor.SqlActiveConfiguration

                $Rows = [ordered] @{
                    IP = Get-NodeIP -Hostname $VBRServer
                    Role = $Roles
                }

                if ($VeeamInfo.Version) {
                    $Rows.add('Version', $VeeamInfo.Version)
                } elseif ($VeeamBuild) {
                    $Rows.add('Version', $VeeamBuild.Build)
                } else {
                    $Rows.add('Version', 'Unknown')
                }

                if ($DBType) {
                    $Rows.add('Database Type', $DBType)
                }

                $Rows = [PSCustomObject]$Rows

                $script:BackupServerInfo = [PSCustomObject]@{
                    Name = $VBRServer.split('.')[0]
                    Label = Add-DiaNodeIcon -Name "$($VBRServer.split('.')[0])" -IconType 'VBR_Server' -Align 'Center' -RowsOrdered $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $BackupServerBGColor -CellBackgroundColor $BackupServerBGColor
                    Spacer = Add-DiaNodeIcon -Name ' ' -IconType 'VBR_Bid_Arrow' -Align 'Center' -ImagesObj $Images -IconDebug $IconDebug -TableBackgroundColor $BackupServerBGColor -CellBackgroundColor $BackupServerBGColor
                }
            }

            $DatabaseServer = $VeeamDBInfo
            if ($DatabaseServer) {
                $DBPort = if ($VeeamInfo.DBFlavor.SqlActiveConfiguration -eq 'PostgreSql') { "$($VeeamInfo.DBInfo12.SqlHostPort)/TCP" } else { '1433/TCP' }
                $DatabaseServerIP = Get-NodeIP -Hostname $DatabaseServer

                $Rows = [ordered] @{
                    IP = $DatabaseServerIP
                    Role = 'Database Server'
                }

                if ($VeeamInfo.DBInfo12.SqlInstanceName) {
                    $Rows.add('Instance', $VeeamInfo.DBInfo12.SqlInstanceName)
                }

                if ($VeeamInfo.DBInfo12.SqlDatabaseName) {
                    $Rows.add('Database', $VeeamInfo.DBInfo12.SqlDatabaseName)
                }

                $Rows.add('DB Port', $DBPort)


                $Rows = [PSCustomObject]$Rows

                $DBIconType = if ($VeeamInfo.DBFlavor.SqlActiveConfiguration -eq 'PostgreSql') { 'VBR_Server_DB_PG' } else { 'VBR_Server_DB' }

                $script:DatabaseServerInfo = [PSCustomObject]@{
                    Name = $DatabaseServer.split('.')[0]
                    Label = Add-DiaNodeIcon -Name "$($DatabaseServer.split('.')[0])" -IconType $DBIconType -Align 'Center' -RowsOrdered $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $BackupServerBGColor -CellBackgroundColor $BackupServerBGColor
                    DBPort = $DBPort
                }
            }

            $EMServer = [Veeam.Backup.Core.SBackupOptions]::GetEnterpriseServerInfo()
            if ($EMServer.ServerName) {
                $EMServerIP = Get-NodeIP -Hostname $EMServer.ServerName

                $Rows = [PSCustomObject] [ordered] @{
                    IP = $EMServerIP
                    Role = 'Enterprise Manager Server'
                }

                $script:EMServerInfo = [PSCustomObject]@{
                    Name = $EMServer.ServerName.split('.')[0]
                    Label = Add-DiaNodeIcon -Name "$($EMServer.ServerName.split('.')[0])" -IconType 'VBR_Server_EM' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $BackupServerBGColor -CellBackgroundColor $BackupServerBGColor
                }
            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {
        if ($PssSession) {
            Remove-PSSession $PssSession
        }
    }
}
