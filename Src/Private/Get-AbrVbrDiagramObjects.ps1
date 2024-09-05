function Get-IconType {
    <#
    .SYNOPSIS
        Used by Veeam.Diagrammer to translate repository type to icon type object.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    param(
        [string]$String
    )

    $IconType = Switch ($String) {
        'LinuxLocal' { 'VBR_Linux_Repository' }
        'WinLocal' { 'VBR_Windows_Repository' }
        'Cloud' { 'VBR_Cloud_Repository' }
        'AmazonS3Compatible' { 'VBR_Amazon_S3_Compatible' }
        'AmazonS3Glacier' { 'VBR_Amazon_S3_Compatible' }
        'AmazonS3' { 'VBR_Amazon_S3' }
        'AzureArchive' { 'VBR_Azure_Blob' }
        'AzureBlob' { 'VBR_Azure_Blob' }
        'DDBoost' { 'VBR_Deduplicating_Storage' }
        'HPStoreOnceIntegration' { 'VBR_Deduplicating_Storage' }
        'ExaGrid' { 'VBR_Deduplicating_Storage' }
        'SanSnapshotOnly' { 'VBR_Storage_NetApp' }
        'Proxy' { 'VBR_Repository' }
        'ProxyServer' { 'VBR_Proxy_Server' }
        'ESXi' { 'VBR_ESXi_Server' }
        'HyperVHost' { 'Hyper-V_host' }
        'ManuallyDeployed' { 'VBR_AGENT_MC' }
        'IndividualComputers' { 'VBR_AGENT_IC' }
        'ActiveDirectory' { 'VBR_AGENT_AD' }
        'CSV' { 'VBR_AGENT_CSV' }
        'CifsShare' {'VBR_NAS'}
        'NfsShare' {'VBR_NAS'}
        default { 'VBR_No_Icon' }
    }

    return $IconType
}

function Get-RoleType {
    <#
    .SYNOPSIS
        Used by Veeam.Diagrammer to translate role type to function type object.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    param(
        [string]$String
    )

    $RoleType = Switch ($String) {
        'LinuxLocal' { 'Linux Local' }
        'WinLocal' { 'Windows Local' }
        'DDBoost' { 'Dedup Appliances' }
        'HPStoreOnceIntegration' { 'Dedup Appliances' }
        'ExaGrid' { 'Dedup Appliances' }
        'InfiniGuard' { 'Dedup Appliances' }
        'Cloud' { 'Cloud' }
        'SanSnapshotOnly' { 'SAN' }
        "vmware" { 'VMware Backup Proxy' }
        "hyperv" { 'HyperV Backup Proxy' }
        "agent" { 'Agent & Files Backup Proxy' }
        "nas" { 'NAS Backup Proxy' }
        "CifsShare" { 'SMB Share' }
        "NfsShare" { 'NFS Share' }
        default { 'Unknown' }
    }

    return $RoleType
}

function Get-VbrBackupServerInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication server information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.8.6
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]

    Param
    (

    )
    process {
        try {
            # $CimSession = New-CimSession $BackupServers.Name -Credential $Credential -Authentication Negotiate
            # $PssSession = New-PSSession $BackupServers.Name -Credential $Credential -Authentication Negotiate
            $CimSession = try { New-CimSession $BackupServers.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -Name 'CIMBackupServerDiagram' -ErrorAction Stop } catch { Write-PScriboMessage -IsWarning "Backup Server Section: New-CimSession: Unable to connect to $($BackupServers.Name): $($_.Exception.MessageId)" }

            $PssSession = try { New-PSSession $BackupServers.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication -ErrorAction Stop -Name 'PSSBackupServerDiagram' } catch {
                if (-Not $_.Exception.MessageId) {
                    $ErrorMessage = $_.FullyQualifiedErrorId
                } else { $ErrorMessage = $_.Exception.MessageId }
                Write-PScriboMessage -IsWarning "Backup Server Section: New-PSSession: Unable to connect to $($BackupServers.Name): $ErrorMessage"
            }
            Write-PScriboMessage "Collecting Backup Server information from $($BackupServers.Name)."
            try {
                $VeeamVersion = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ChildItem -Recurse HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -match 'Veeam Backup & Replication Server' } | Select-Object -Property DisplayVersion }
            } catch { $_ }
            try {
                $VeeamDBFlavor = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations' }
            } catch { $_ }
            try {
                $VeeamDBInfo12 = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path "HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication\DatabaseConfigurations\$(($Using:VeeamDBFlavor).SqlActiveConfiguration)" }
            } catch { $_ }
            try {
                $VeeamDBInfo11 = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
            } catch { $_ }

            if ($VeeamDBInfo11.SqlServerName) {
                $VeeamDBInfo = $VeeamDBInfo11.SqlServerName
            } elseif ($VeeamDBInfo12.SqlServerName) {
                $VeeamDBInfo = $VeeamDBInfo12.SqlServerName
            } elseif ($VeeamDBInfo12.SqlHostName) {
                $VeeamDBInfo = Switch ($VeeamDBInfo12.SqlHostName) {
                    'localhost' { $BackupServers.Name }
                    default { $VeeamDBInfo12.SqlHostName }
                }
            } else {
                $VeeamDBInfo = $BackupServers.Name
            }

            try {
                if ($BackupServers) {

                    if ($VeeamDBInfo -eq $BackupServers.Name) {
                        $Roles = 'Backup and Database'
                        $DBType = $VeeamDBFlavor.SqlActiveConfiguration
                    } else {
                        $Roles = 'Backup Server'
                    }

                    $Rows = @{
                        Role = $Roles
                        IP = Get-NodeIP -Hostname $BackupServers.Name
                    }

                    if ($VeeamVersion) {
                        $Rows.add('Version', $VeeamVersion.DisplayVersion)
                    }

                    if ($VeeamDBInfo -eq $BackupServers.Name) {
                        $Rows.add('DB Type', $DBType)
                    }

                    $script:BackupServerInfo = [PSCustomObject]@{
                        Name = $BackupServers.Name.split(".")[0]
                        Label = Get-DiaNodeIcon -Name "$($BackupServers.Name.split(".")[0])" -IconType "VBR_Server" -Align "Center" -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug
                    }
                }
            } catch {
                $_
            }
            try {
                $DatabaseServer = $VeeamDBInfo
                if ($VeeamDBFlavor.SqlActiveConfiguration -eq "PostgreSql") {
                    $DBPort = "$($VeeamDBInfo12.SqlHostPort)/TCP"
                } else {
                    $DBPort = "1433/TCP"
                }

                if ($DatabaseServer) {
                    $DatabaseServerIP = Get-NodeIP -Hostname $DatabaseServer

                    $Rows = @{
                        Role = 'Database Server'
                        IP = $DatabaseServerIP
                    }

                    if ($VeeamDBInfo.SqlInstanceName) {
                        $Rows.add('Instance', $VeeamDBInfo.SqlInstanceName)
                    }
                    if ($VeeamDBInfo.SqlDatabaseName) {
                        $Rows.add('Database', $VeeamDBInfo.SqlDatabaseName)
                    }

                    if ($VeeamDBFlavor.SqlActiveConfiguration -eq "PostgreSql") {
                        $DBIconType = "VBR_Server_DB_PG"
                    } else {
                        $DBIconType = "VBR_Server_DB"
                    }

                    $script:DatabaseServerInfo = [PSCustomObject]@{
                        Name = $DatabaseServer.split(".")[0]
                        Label = Get-DiaNodeIcon -Name "$($DatabaseServer.split(".")[0])" -IconType $DBIconType -Align "Center" -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug
                        DBPort = $DBPort
                    }
                }
            } catch {
                $_
            }

            try {
                $EMServer = [Veeam.Backup.Core.SBackupOptions]::GetEnterpriseServerInfo()
                if ($EMServer.ServerName) {
                    $EMServerIP = Get-NodeIP -Hostname $EMServer.ServerName

                    $Rows = @{
                        Role = 'Enterprise Manager Server'
                        IP = $EMServerIP
                    }

                    $script:EMServerInfo = [PSCustomObject]@{
                        Name = $EMServer.ServerName.split(".")[0]
                        Label = Get-DiaNodeIcon -Name "$($EMServer.ServerName.split(".")[0])" -IconType "VBR_Server_EM" -Align "Center" -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug
                    }
                }
            } catch {
                $_
            }
        } catch {
            $_
        }
    }
    end {
        Remove-CimSession $CimSession
        Remove-PSSession $PssSession
    }
}

function Get-VbrBackupSvrDiagramObj {
    <#
    .SYNOPSIS
        Function to build Backup Server object.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.8.6
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]

    Param
    (

    )
    process {
        try {
            SubGraph BackupServer -Attributes @{Label = 'Management'; labelloc = 'b'; labeljust = "r"; style = "rounded"; bgcolor = "#ceedc4"; fontcolor = '#005f4b'; fontsize = 18; penwidth = 2 } {
                if (($DatabaseServerInfo.Name -ne $BackupServerInfo.Name) -and $EMServerInfo) {
                    Write-PScriboMessage "Collecting Backup Server, Database Server and Enterprise Manager Information."
                    $BSHASHTABLE = @{}
                    $DBHASHTABLE = @{}
                    $EMHASHTABLE = @{}

                    $BackupServerInfo.psobject.properties | ForEach-Object { $BSHASHTABLE[$_.Name] = $_.Value }
                    $DatabaseServerInfo.psobject.properties | ForEach-Object { $DBHASHTABLE[$_.Name] = $_.Value }
                    $EMServerInfo.psobject.properties | ForEach-Object { $EMHASHTABLE[$_.Name] = $_.Value }

                    Node $BackupServerInfo.Name -Attributes @{Label = $BSHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }
                    Node $DatabaseServerInfo.Name -Attributes @{Label = $DBHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }
                    Node $EMServerInfo.Name -Attributes @{Label = $EMHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }

                    if ($Dir -eq 'LR') {
                        Rank $EMServerInfo.Name, $DatabaseServerInfo.Name
                        Edge -From $EMServerInfo.Name -To $BackupServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; }
                        Edge -From $DatabaseServerInfo.Name -To $BackupServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; xlabel = $DatabaseServerInfo.DBPort }
                    } else {
                        Rank $EMServerInfo.Name, $BackupServerInfo.Name, $DatabaseServerInfo.Name
                        Edge -From $EMServerInfo.Name -To $BackupServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; }
                        Edge -From $BackupServerInfo.Name -To $DatabaseServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; xlabel = $DatabaseServerInfo.DBPort }
                    }
                } elseif (($DatabaseServerInfo.Name -ne $BackupServerInfo.Name) -and (-Not $EMServerInfo)) {
                    Write-PScriboMessage "Not Enterprise Manager Found: Collecting Backup Server and Database server Information."
                    $BSHASHTABLE = @{}
                    $DBHASHTABLE = @{}

                    $BackupServerInfo.psobject.properties | ForEach-Object { $BSHASHTABLE[$_.Name] = $_.Value }
                    $DatabaseServerInfo.psobject.properties | ForEach-Object { $DBHASHTABLE[$_.Name] = $_.Value }

                    Node $BackupServerInfo.Name -Attributes @{Label = $BSHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }
                    Node $DatabaseServerInfo.Name -Attributes @{Label = $DBHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }

                    if ($Dir -eq 'LR') {
                        Rank $BackupServerInfo.Name, $DatabaseServerInfo.Name
                        Edge -From $DatabaseServerInfo.Name -To $BackupServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; xlabel = $DatabaseServerInfo.DBPort }
                    } else {
                        Rank $BackupServerInfo.Name, $DatabaseServerInfo.Name
                        Edge -From $BackupServerInfo.Name -To $DatabaseServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; xlabel = $DatabaseServerInfo.DBPort }
                    }
                } elseif ($EMServerInfo -and ($DatabaseServerInfo.Name -eq $BackupServerInfo.Name)) {
                    Write-PScriboMessage "Database server colocated with Backup Server: Collecting Backup Server and Enterprise Manager Information."
                    $BSHASHTABLE = @{}
                    $EMHASHTABLE = @{}

                    $BackupServerInfo.psobject.properties | ForEach-Object { $BSHASHTABLE[$_.Name] = $_.Value }
                    $EMServerInfo.psobject.properties | ForEach-Object { $EMHASHTABLE[$_.Name] = $_.Value }

                    Node $BackupServerInfo.Name -Attributes @{Label = $BSHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }
                    Node $EMServerInfo.Name -Attributes @{Label = $EMHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }

                    if ($Dir -eq 'LR') {
                        Rank $EMServerInfo.Name, $BackupServerInfo.Name
                        Edge -From $EMServerInfo.Name -To $BackupServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; }
                    } else {
                        Rank $EMServerInfo.Name, $BackupServerInfo.Name
                        Edge -From $BackupServerInfo.Name -To $EMServerInfo.Name @{arrowtail = "normal"; arrowhead = "normal"; minlen = 3; }
                    }
                } else {
                    Write-PScriboMessage "Database server colocated with Backup Server and no Enterprise Manager found: Collecting Backup Server Information."
                    $BSHASHTABLE = @{}
                    $BackupServerInfo.psobject.properties | ForEach-Object { $BSHASHTABLE[$_.Name] = $_.Value }
                    Node Left @{Label = 'Left'; style = $EdgeDebug.style; color = $EdgeDebug.color; shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                    Node Leftt @{Label = 'Leftt'; style = $EdgeDebug.style; color = $EdgeDebug.color; shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                    Node Right @{Label = 'Right'; style = $EdgeDebug.style; color = $EdgeDebug.color; shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                    Node $BackupServerInfo.Name -Attributes @{Label = $BSHASHTABLE.Label; fillColor = '#ceedc4'; shape = 'plain'; fontsize = 14; fontname = "Segoe Ui" }
                    Edge Left, Leftt, $BackupServerInfo.Name, Right @{style = $EdgeDebug.style; color = $EdgeDebug.color }
                    Rank Left, Leftt, $BackupServerInfo.Name, Right
                }
            }
        } catch {
            $_
        }
    }
    end {}
}

# Proxy Graphviz Cluster
function Get-VbrProxyInfo {
    param (
    )
    try {
        Write-PScriboMessage "Collecting Proxy information from $VeeamBackupServer."
        $Proxies = @()
        $Proxies += Get-VBRViProxy
        $Proxies += Get-VBRHvProxy

        if ($Proxies) {
            if ($Options.DiagramObjDebug) {
                $Proxies = $ProxiesDebug
            }

            $ProxiesInfo = @()

            $Proxies | ForEach-Object {
                $inobj = [ordered] @{
                    'Type' = Switch ($_.Type) {
                        'Vi' { 'vSphere' }
                        'HvOffhost' { 'Off host' }
                        'HvOnhost' { 'On host' }
                        default { $_.Type }
                    }
                    'Max Tasks' = $_.Options.MaxTasksCount
                }

                $IconType = Get-IconType -String 'ProxyServer'

                $TempProxyInfo = [PSCustomObject]@{
                    Name = $_.Host.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }

                $ProxiesInfo += $TempProxyInfo
            }
        }

        return $ProxiesInfo

    } catch {
        $_
    }

}

# Wan Accel Graphviz Cluster
function Get-VbrWanAccelInfo {
    param (
    )
    try {
        Write-PScriboMessage "Collecting Wan Accel information from $VeeamBackupServer."
        $WanAccels = Get-VBRWANAccelerator

        if ($WanAccels) {
            if ($Options.DiagramObjDebug) {
                $WanAccels = $WanAccelsDebug
            }

            $WanAccelsInfo = @()

            $WanAccels | ForEach-Object {
                $inobj = [ordered] @{
                    'CacheSize' = "$($_.FindWaHostComp().Options.MaxCacheSize) $($_.FindWaHostComp().Options.SizeUnit)"
                    'TrafficPort' = "$($_.GetWaTrafficPort())/TCP"
                }

                $TempWanAccelInfo = [PSCustomObject]@{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }

                $WanAccelsInfo += $TempWanAccelInfo
            }
        }

        return $WanAccelsInfo

    } catch {
        $_
    }

}

# Repositories Graphviz Cluster
function Get-VbrRepositoryInfo {
    param (
    )

    [Array]$Repositories = Get-VBRBackupRepository | Where-Object { $_.Type -notin @("SanSnapshotOnly", "AmazonS3Compatible", "WasabiS3", "SmartObjectS3") } | Sort-Object -Property Name
    [Array]$ScaleOuts = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name
    if ($ScaleOuts) {
        $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts | Sort-Object -Property Name
        $Repositories += $Extents.Repository
    }
    if ($Repositories) {
        $RepositoriesInfo = @()

        foreach ($Repository in $Repositories) {
            $IconType = Get-IconType
            $Role = Get-RoleType -String $Repository.Type

            $Rows = [ordered]@{}

            if ($Repository.Host.Name) {
                $Rows.add('Server', $Repository.Host.Name.Split('.')[0])
            } else {
                $Rows.add('Server', 'N/A')
            }
            $Rows.add('Repo Type', $Role)
            $Rows.add('Total Space', "$(($Repository).GetContainer().CachedTotalSpace.InGigabytes) GB")
            $Rows.add('Used Space', "$(($Repository).GetContainer().CachedFreeSpace.InGigabytes) GB")

            if (($Role -ne 'Dedup Appliances') -and ($Role -ne 'SAN') -and ($Repository.Host.Name -in $ViBackupProxy.Host.Name -or $Repository.Host.Name -in $HvBackupProxy.Host.Name)) {
                $BackupType = 'Proxy'
            } else { $BackupType = $Repository.Type }

            $IconType = Get-IconType -String $BackupType

            $TempBackupRepoInfo = [PSCustomObject]@{
                Name = "$((Remove-SpecialChar -String $Repository.Name -SpecialChars '\').toUpper()) "
                AditionalInfo = $Rows
                IconType = $IconType
            }

            $RepositoriesInfo += $TempBackupRepoInfo
        }
        return $RepositoriesInfo
    }

}

# Object Repositories Graphviz Cluster
function Get-VbrObjectRepoInfo {
    param (
    )

    $ObjectRepositories = Get-VBRObjectStorageRepository
    if ($ObjectRepositories) {

        $ObjectRepositoriesInfo = @()

        $ObjectRepositories | ForEach-Object {
            $inobj = @{
                'Type' = $_.Type
                'Folder' = & {
                    if ($_.AmazonS3Folder) {
                        $_.AmazonS3Folder
                    } elseif ($_.AzureBlobFolder) {
                        $_.AzureBlobFolder
                    } else { 'Unknown' }
                }
                'Gateway' = & {
                    if (-Not $_.UseGatewayServer) {
                        Switch ($_.ConnectionType) {
                            'Gateway' {
                                switch (($_.GatewayServer | Measure-Object).count) {
                                    0 { "Disable" }
                                    1 { $_.GatewayServer.Name.Split('.')[0] }
                                    Default { 'Automatic' }
                                }
                            }
                            'Direct' { 'Direct' }
                            default { 'Unknown' }
                        }
                    } else {
                        switch (($_.GatewayServer | Measure-Object).count) {
                            0 { "Disable" }
                            1 { $_.GatewayServer.Name.Split('.')[0] }
                            Default { 'Automatic' }
                        }
                    }
                }
            }

            $IconType = Get-IconType -String $_.Type

            $TempObjectRepositoriesInfo = [PSCustomObject]@{
                Name = $_.Name
                AditionalInfo = $inobj
                IconType = $IconType
            }
            $ObjectRepositoriesInfo += $TempObjectRepositoriesInfo
        }
        return $ObjectRepositoriesInfo
    }
}


# Archive Object Repositories Graphviz Cluster
function Get-VbrArchObjectRepoInfo {
    param (
    )

    $ArchObjStorages = Get-VBRArchiveObjectStorageRepository | Sort-Object -Property Name
    if ($ArchObjStorages) {

        $ArchObjRepositoriesInfo = @()

        $ArchObjStorages | ForEach-Object {
            $inobj = @{
                Type = $_.ArchiveType
                Gateway = & {
                    if (-Not $_.UseGatewayServer) {
                        Switch ($_.GatewayMode) {
                            'Gateway' {
                                switch (($_.GatewayServer | Measure-Object).count) {
                                    0 { "Disable" }
                                    1 { $_.GatewayServer.Name.Split('.')[0] }
                                    Default { 'Automatic' }
                                }
                            }
                            'Direct' { 'Direct' }
                            default { 'Unknown' }
                        }
                    } else {
                        switch (($_.GatewayServer | Measure-Object).count) {
                            0 { "Disable" }
                            1 { $_.GatewayServer.Name.Split('.')[0] }
                            Default { 'Automatic' }
                        }
                    }
                }
            }

            $IconType = Get-IconType -String $_.ArchiveType

            $TempArchObjectRepositoriesInfo = [PSCustomObject]@{
                Name = $_.Name
                AditionalInfo = $inobj
                IconType = $IconType
            }
            $ArchObjRepositoriesInfo += $TempArchObjectRepositoriesInfo
        }
        return $ArchObjRepositoriesInfo
    }
}

# Scale-Out Backup Repository Graphviz Cluster
function Get-VbrSOBRInfo {
    param (
    )
    try {
        Write-PScriboMessage "Collecting Scale-Out Backup Repository information from $VeeamBackupServer."
        $SOBR = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name

        if ($SOBR) {
            if ($Options.DiagramObjDebug) {
                $SOBR = $SOBRDebug
            }

            $SOBRInfo = @()

            $SOBR | ForEach-Object {
                $inobj = [ordered] @{
                    'Placement Policy' = $_.PolicyType
                    'Encryption Enabled' = switch ($_.EncryptionEnabled) {
                        "" { "--" }
                        $Null { "--" }
                        "True" { "Yes"; break }
                        "False" { "No"; break }
                        default { $_.EncryptionEnabled }
                    }
                }

                $TempSOBRInfo = [PSCustomObject]@{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }

                $SOBRInfo += $TempSOBRInfo
            }
        }

        return $SOBRInfo

    } catch {
        $_
    }

}

# Tape Servers Graphviz Cluster
function Get-VbrTapeServersInfo {
    param (
    )
    try {
        Write-PScriboMessage "Collecting Tape Servers information from $VeeamBackupServer."
        $TapeServers = Get-VBRTapeServer | Sort-Object -Property Name

        if ($TapeServers) {

            $TapeServernfo = @()

            $TapeServers | ForEach-Object {
                $inobj = [ordered] @{
                    'Is Available' = switch ($_.IsAvailable) {
                        "" { "--" }
                        $Null { "--" }
                        "True" { "Yes"; break }
                        "False" { "No"; break }
                        default { $_.IsAvailable }
                    }
                }

                $TempTapeServernfo = [PSCustomObject]@{
                    Name = $_.Name.split('.')[0]
                    AditionalInfo = $inobj
                }

                $TapeServernfo += $TempTapeServernfo
            }
        }

        return $TapeServernfo

    } catch {
        $_
    }

}

# Tape Library Graphviz Cluster
function Get-VbrTapeLibraryInfo {
    param (
    )
    try {
        Write-PScriboMessage "Collecting Tape Library information from $VeeamBackupServer."
        $TapeLibraries = Get-VBRTapeLibrary | Sort-Object -Property Name

        if ($TapeLibraries) {

            $TapeLibrariesInfo = @()

            $TapeLibraries | ForEach-Object {
                $inobj = [ordered] @{
                    'State' = $_.State
                    'Type' = $_.Type
                    'Model' = $_.Model
                }

                $TempTapeLibrariesInfo = [PSCustomObject]@{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }

                $TapeLibrariesInfo += $TempTapeLibrariesInfo
            }
        }

        return $TapeLibrariesInfo

    } catch {
        $_
    }

}

# Tape Library Graphviz Cluster
function Get-VbrTapeVaultInfo {
    param (
    )
    try {
        Write-PScriboMessage "Collecting Tape Vault information from $VeeamBackupServer."
        $TapeVaults = Get-VBRTapeVault | Sort-Object -Property Name

        if ($TapeVaults) {

            $TapeVaultsInfo = @()

            $TapeVaults | ForEach-Object {
                $inobj = [ordered] @{
                    'Protect' = Switch ($_.Protect) {
                        'True' { 'Yes' }
                        'False' { 'No' }
                        default { 'Unknown' }
                    }
                }

                $TempTapeVaultsInfo = [PSCustomObject]@{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }

                $TapeVaultsInfo += $TempTapeVaultsInfo
            }
        }

        return $TapeVaultsInfo

    } catch {
        $_
    }
}

# Tape Library Graphviz Cluster
function Get-VbrServiceProviderInfo {
    param (
    )
    try {
        Write-PScriboMessage "Collecting Service Provider information from $VeeamBackupServer."
        $ServiceProviders = Get-VBRCloudProvider | Sort-Object -Property 'DNSName'

        if ($ServiceProviders) {

            $ServiceProvidersInfo = @()

            $ServiceProviders | ForEach-Object {
                $inobj = [ordered] @{
                    'Cloud Connect Type' = & {
                        if ($_.ResourcesEnabled -and $_.ReplicationResourcesEnabled) {
                            'BaaS & DRaaS'
                        } elseif ($_.ResourcesEnabled) {
                            'BaaS'
                        } elseif ($_.ReplicationResourcesEnabled) {
                            'DRaas'
                        } elseif ($_.vCDReplicationResources) {
                            'vCD'
                        } else { 'Unknown' }
                    }
                    'Managed By Provider' = ConvertTo-TextYN $_.IsManagedByProvider
                }

                $TempServiceProvidersInfo = [PSCustomObject]@{
                    Name = $_.DNSName
                    AditionalInfo = $inobj
                }

                $ServiceProvidersInfo += $TempServiceProvidersInfo
            }
        }

        return $ServiceProvidersInfo

    } catch {
        $_
    }
}

function Get-VBRDebugObject {

    [CmdletBinding()]
    param (
    )

    $script:ProxiesDebug = [PSCustomObject]@(
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-00000000000001' }
            'Type' = "Vi"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-02' }
            'Type' = "Vi"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-03' }
            'Type' = "Vi"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-04' }
            'Type' = "HvOffhost"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-0500000000000' }
            'Type' = "HvOffhost"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
        @{
            'Host' = [PSCustomObject]@{ 'Name' = 'veeam-prx-06' }
            'Type' = "HvOnhost"
            'Options' = [PSCustomObject]@{ 'MaxTasksCount' = 2 }
        }
    )


    $script:Repositories = @{
        Name = "Repository1", "Repository2", "Repository3", "Repository4", "Repository5", "Repository6", "Repository7"
    }


    $script:ObjectRepositories = @{
        Name = "ObjectRepositor1", "ObjectRepositor2", "ObjectRepositor3", "ObjectRepositor4", "ObjectRepositor5", "ObjectRepositor6", "ObjectRepositor7"
    }
}