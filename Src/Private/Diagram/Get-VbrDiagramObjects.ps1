# Proxy Graphviz Cluster
function Get-VbrProxyInfo {
    <#
    .SYNOPSIS
    Retrieves information about Veeam Backup & Replication proxies.

    .DESCRIPTION
    The Get-VbrProxyInfo function collects information about Veeam Backup & Replication proxies from the VBR server.
    It retrieves both vSphere and Hyper-V proxies and formats the information into a custom object with additional details.

    .PARAMETER None
    This function does not take any parameters.

    .OUTPUTS
    System.Object
    Returns a collection of custom objects containing proxy information, including the proxy type, maximum tasks, and icon type.

    .EXAMPLE
    PS C:\> Get-VbrProxyInfo
    Collects and returns information about Veeam Backup & Replication proxies from the VBR server.

    .NOTES
    Author: Jonathan Colon
    Date: 2024-12-30
    Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting proxy information from $($VBRServer)."
        $Proxies = @(Get-VBRViProxy) + @(Get-VBRHvProxy)

        if ($Proxies) {
            $ProxiesInfo = $Proxies | ForEach-Object {
                $inobj = [ordered] @{
                    'Type' = switch ($_.Type) {
                        'Vi' { 'vSphere' }
                        'HvOffhost' { 'Off host' }
                        'HvOnhost' { 'On host' }
                        default { $_.Type }
                    }
                    'Max Tasks' = $_.Options.MaxTasksCount
                }

                $IconType = Get-IconType -String 'ProxyServer'

                [PSCustomObject] @{
                    Name = $_.Host.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
        }

        return $ProxiesInfo

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Nas Proxy Graphviz Cluster
function Get-VbrNASProxyInfo {
    <#
    .SYNOPSIS
    Retrieves information about NAS proxies from the Veeam Backup & Replication server.

    .DESCRIPTION
    The Get-VbrNASProxyInfo function collects and returns information about NAS proxies configured on the Veeam Backup & Replication server.
    It retrieves the proxy server details, including whether they are enabled and the maximum number of concurrent tasks they can handle.

    .PARAMETERS
    This function does not take any parameters.

    .OUTPUTS
    System.Object
    Returns a collection of PSCustomObject containing the following properties:
    - Name: The name of the NAS proxy server.
    - AditionalInfo: An ordered dictionary with the following keys:
        - Enabled: Indicates whether the proxy server is enabled ('Yes' or 'No').
        - Max Tasks: The maximum number of concurrent tasks the proxy server can handle.
    - IconType: The icon type associated with the proxy server.

    .EXAMPLE
    PS C:\> Get-VbrNASProxyInfo
    Collects and displays information about NAS proxies from the Veeam Backup & Replication server.

    .NOTES
    This function uses the Get-VBRNASProxyServer cmdlet to retrieve the NAS proxy server information and the Get-IconType function to determine the icon type.
    Author: Jonathan Colon
    Date: 2024-12-30
    Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting NAS Proxy information from $($VBRServer)."
        $Proxies = Get-VBRNASProxyServer

        if ($Proxies) {
            $ProxiesInfo = $Proxies | ForEach-Object {
                $inobj = [ordered] @{
                    'Enabled' = if ($_.IsEnabled) { 'Yes' } else { 'No' }
                    'Max Tasks' = $_.ConcurrentTaskNumber
                }

                $IconType = Get-IconType -String 'ProxyServer'

                [PSCustomObject] @{
                    Name = $_.Server.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
        }

        return $ProxiesInfo

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Wan Accel Graphviz Cluster
function Get-VbrWanAccelInfo {
    <#
    .SYNOPSIS
        Retrieves information about WAN Accelerators from the Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-VbrWanAccelInfo function collects and returns information about WAN Accelerators configured on the Veeam Backup & Replication server.
        It retrieves details such as cache size and traffic port for each WAN Accelerator.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject containing the name and additional information (cache size and traffic port) of each WAN Accelerator.

    .EXAMPLE
        PS C:\> Get-VbrWanAccelInfo
        Retrieves and displays information about all WAN Accelerators from the Veeam Backup & Replication server.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and imported.
        Ensure that you have the necessary permissions to access the Veeam Backup & Replication server.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Wan Accel information from $($VBRServer)."
        $WanAccels = Get-VBRWANAccelerator

        if ($WanAccels) {
            $WanAccelsInfo = $WanAccels | ForEach-Object {
                $inobj = [ordered] @{
                    'CacheSize' = "$($_.FindWaHostComp().Options.MaxCacheSize) $($_.FindWaHostComp().Options.SizeUnit)"
                    'TrafficPort' = "$($_.GetWaTrafficPort())/TCP"
                }

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }
            }
        }

        return $WanAccelsInfo

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Repositories Graphviz Cluster
function Get-VbrRepositoryInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication repositories.

    .DESCRIPTION
        The Get-VbrRepositoryInfo function collects and returns detailed information about Veeam Backup & Replication repositories, excluding certain types such as SanSnapshotOnly, AmazonS3Compatible, WasabiS3, and SmartObjectS3. It also includes information about Scale-Out Backup Repositories and their extents.

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject containing repository information including server name, repository type, total space, used space, and icon type.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and configured.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    .EXAMPLE
        PS C:\> Get-VbrRepositoryInfo
        Retrieves and displays information about all Veeam Backup & Replication repositories.

    #>
    param ()
    try {
        Write-Verbose "Collecting Repository information from $($VBRServer)."
        $Repositories = Get-VBRBackupRepository | Where-Object { $_.Type -notin @('SanSnapshotOnly', 'AmazonS3Compatible', 'WasabiS3', 'SmartObjectS3') } | Sort-Object -Property Name
        $ScaleOuts = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name

        if ($ScaleOuts) {
            $Extents = Get-VBRRepositoryExtent -Repository $ScaleOuts | Sort-Object -Property Name
            $Repositories += $Extents.Repository
        }

        if ($Repositories) {
            $RepositoriesInfo = $Repositories | ForEach-Object {
                $Role = Get-RoleType -String $_.Type

                $Rows = [ordered] @{
                    'Server' = if ($_.Host.Name) { $_.Host.Name.Split('.')[0] } else { 'N/A' }
                    'Repo Type' = $Role
                    'Total Space' = (ConvertTo-FileSizeString -Size $_.GetContainer().CachedTotalSpace.InBytesAsUInt64)
                    'Used Space' = (ConvertTo-FileSizeString -Size $_.GetContainer().CachedFreeSpace.InBytesAsUInt64)
                }

                $BackupType = if (($Role -ne 'Dedup Appliances') -and ($Role -ne 'SAN') -and ($_.Host.Name -in $ViBackupProxy.Host.Name -or $_.Host.Name -in $HvBackupProxy.Host.Name)) {
                    'Proxy'
                } else { $_.Type }

                $IconType = Get-IconType -String $BackupType

                [PSCustomObject] @{
                    Name = "$((Remove-SpecialChar -String $_.Name -SpecialChars '\').toUpper())"
                    AditionalInfo = $Rows
                    IconType = $IconType
                }
            }

            return $RepositoriesInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Object Repositories Graphviz Cluster
function Get-VbrObjectRepoInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication object repositories.

    .DESCRIPTION
        The Get-VbrObjectRepoInfo function queries and returns detailed information about object repositories configured in Veeam Backup & Replication.
        This includes details such as repository name, type, capacity, and other relevant properties.

    .PARAMETER RepoName
        The name of the repository to retrieve information for. If not specified, information for all repositories will be returned.

    .EXAMPLE
        Get-VbrObjectRepoInfo -RepoName "MyRepository"
        Retrieves information about the repository named "MyRepository".

    .EXAMPLE
        Get-VbrObjectRepoInfo
        Retrieves information about all configured object repositories.

    .NOTES
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>

    param ()
    try {
        Write-Verbose "Collecting Object Repository information from $($VBRServer)."
        $ObjectRepositories = Get-VBRObjectStorageRepository
        if ($ObjectRepositories) {
            $ObjectRepositoriesInfo = $ObjectRepositories | ForEach-Object {
                $inobj = [ordered] @{
                    'Type' = $_.Type
                    'Folder' = if ($_.AmazonS3Folder) {
                        $_.AmazonS3Folder
                    } elseif ($_.AzureBlobFolder) {
                        $_.AzureBlobFolder
                    } else { 'Unknown' }
                    'Gateway' = if (-not $_.UseGatewayServer) {
                        switch ($_.ConnectionType) {
                            'Gateway' {
                                switch (($_.GatewayServer | Measure-Object).Count) {
                                    0 { 'Disable' }
                                    1 { $_.GatewayServer.Name.Split('.')[0] }
                                    default { 'Automatic' }
                                }
                            }
                            'Direct' { 'Direct' }
                            default { 'Unknown' }
                        }
                    } else {
                        switch (($_.GatewayServer | Measure-Object).Count) {
                            0 { 'Disable' }
                            1 { $_.GatewayServer.Name.Split('.')[0] }
                            default { 'Automatic' }
                        }
                    }
                }

                $IconType = Get-IconType -String $_.Type

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $ObjectRepositoriesInfo
        }
    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Archive Object Repositories Graphviz Cluster
function Get-VbrArchObjectRepoInfo {
    <#
    .SYNOPSIS
    Retrieves information about Veeam Backup & Replication archive object repositories.

    .DESCRIPTION
    The Get-VbrArchObjectRepoInfo function retrieves detailed information about the archive object repositories configured in Veeam Backup & Replication.

    .EXAMPLE
    Get-VbrArchObjectRepoInfo

    This example retrieves information about all archive object repositories.

    .OUTPUTS
    System.Object
    Returns objects containing information about the archive object repositories.

    .NOTES
    Author: Jonathan Colon
    Date: 2024-12-30
    Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Archive Object Repository information from $($VBRServer)."
        $ArchObjStorages = Get-VBRArchiveObjectStorageRepository | Sort-Object -Property Name
        if ($ArchObjStorages) {
            $ArchObjRepositoriesInfo = $ArchObjStorages | ForEach-Object {
                $inobj = [ordered] @{
                    'Type' = $_.ArchiveType
                    'Gateway' = if (-not $_.UseGatewayServer) {
                        switch ($_.GatewayMode) {
                            'Gateway' {
                                switch (($_.GatewayServer | Measure-Object).Count) {
                                    0 { 'Disable' }
                                    1 { $_.GatewayServer.Name.Split('.')[0] }
                                    default { 'Automatic' }
                                }
                            }
                            'Direct' { 'Direct' }
                            default { 'Unknown' }
                        }
                    } else {
                        switch (($_.GatewayServer | Measure-Object).Count) {
                            0 { 'Disable' }
                            1 { $_.GatewayServer.Name.Split('.')[0] }
                            default { 'Automatic' }
                        }
                    }
                }

                $IconType = Get-IconType -String $_.ArchiveType

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $ArchObjRepositoriesInfo
        }
    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Scale-Out Backup Repository Graphviz Cluster
function Get-VbrSOBRInfo {
    <#
    .SYNOPSIS
        Retrieves information about Scale-Out Backup Repositories (SOBR) from a Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-VbrSOBRInfo function collects and returns information about Scale-Out Backup Repositories (SOBR) from a Veeam Backup & Replication server.
        It retrieves the SOBR details, including the placement policy and encryption status, and returns them as a custom PowerShell object.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a custom PowerShell object containing the name of the SOBR and additional information such as placement policy and encryption status.

    .EXAMPLE
        PS C:\> Get-VbrSOBRInfo
        Retrieves and displays information about all Scale-Out Backup Repositories from the connected Veeam Backup & Replication server.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and connected to a Veeam Backup & Replication server.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Scale-Out Backup Repository information from $($VBRServer)."
        $SOBR = Get-VBRBackupRepository -ScaleOut | Sort-Object -Property Name

        if ($SOBR) {
            $SOBRInfo = $SOBR | ForEach-Object {
                $inobj = [ordered] @{
                    'Placement Policy' = $_.PolicyType
                    'Encryption Enabled' = if ($_.EncryptionEnabled) { 'Yes' } else { 'No' }
                }

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                }
            }
            return $SOBRInfo
        }
    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}
# Storage Infrastructure Graphviz Cluster
function Get-VbrSANInfo {
    <#
    .SYNOPSIS
        Retrieves information about SAN (Storage Area Network) hosts from the Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-VbrSANInfo function collects and returns information about SAN hosts, specifically NetApp and Dell Isilon hosts, from the Veeam Backup & Replication server. It gathers the host names and their types, processes additional information, and returns a custom object with the collected data.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a collection of custom objects containing the SAN host name, additional information, and icon type.

    .EXAMPLE
        PS C:\> Get-VbrSANInfo
        Retrieves and displays information about SAN hosts from the Veeam Backup & Replication server.

    .NOTES
        This function uses the Get-NetAppHost and Get-VBRIsilonHost cmdlets to retrieve SAN host information. It processes the data to include additional information and icon types for each host.
        Author: Jonathan Colon
        Date: 2024-12-30
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Storage Infrastructure information from $($VBRServer)."
        $SANHost = @(
            Get-NetAppHost | Select-Object -Property Name, @{ Name = 'Type'; Expression = { 'Netapp' } }
            Get-VBRIsilonHost | Select-Object -Property Name, @{ Name = 'Type'; Expression = { 'Dell' } }
        )

        if ($SANHost) {
            $SANHostInfo = $SANHost | ForEach-Object {
                try {
                    $IconType = Get-IconType -String $_.Type
                    $inobj = [ordered] @{
                        'Type' = switch ($_.Type) {
                            'Netapp' { 'NetApp Ontap' }
                            'Dell' { 'Dell Isilon' }
                            default { 'Unknown' }
                        }
                    }

                    [PSCustomObject] @{
                        Name = $_.Name
                        AditionalInfo = $inobj
                        IconType = $IconType
                    }
                } catch {
                    Write-Verbose "Error: Unable to process $($_.Name) from Storage Infrastructure table: $($_.Exception.Message)"
                }
            }
        }

        return $SANHostInfo

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Tape Servers Graphviz Cluster
function Get-VbrTapeServersInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication Tape Servers.

    .DESCRIPTION
        The Get-VbrTapeServersInfo function collects and returns information about Tape Servers from the Veeam Backup & Replication server.
        It sorts the Tape Servers by their name and provides additional availability information.

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject with the following properties:
            - Name: The name of the Tape Server.
            - AditionalInfo: An ordered dictionary containing the availability status of the Tape Server.

    .EXAMPLE
        PS C:\> Get-VbrTapeServersInfo
        Retrieves and displays information about all Tape Servers from the Veeam Backup & Replication server.

    .NOTES
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Tape Servers information from $($VBRServer)."
        $TapeServers = Get-VBRTapeServer | Sort-Object -Property Name

        if ($TapeServers) {
            $TapeServersInfo = $TapeServers | ForEach-Object {
                $inobj = [ordered] @{
                    'Is Available' = if ($_.IsAvailable) { 'Yes' } elseif (-not $_.IsAvailable) { 'No' } else { '--' }
                }

                [PSCustomObject] @{
                    Name = $_.Name.split('.')[0]
                    AditionalInfo = $inobj
                }
            }
            return $TapeServersInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Tape Library Graphviz Cluster
function Get-VbrTapeLibraryInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication (VBR) Tape Libraries.

    .DESCRIPTION
        The Get-VbrTapeLibraryInfo function collects and returns information about Tape Libraries from a Veeam Backup & Replication server.
        It retrieves the Tape Libraries, sorts them by name, and formats the information into a custom object.

    .PARAMETERS
        None

    .OUTPUTS
        PSCustomObject
            A custom object containing the name and additional information (state, type, model) of each Tape Library.

    .EXAMPLE
        PS C:\> Get-VbrTapeLibraryInfo
        Retrieves and displays information about all Tape Libraries from the VBR server.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and imported.
        Ensure that you have the necessary permissions to access the VBR server and retrieve Tape Library information.
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Tape Library information from $($VBRServer)."
        $TapeLibraries = Get-VBRTapeLibrary | Sort-Object -Property Name

        if ($TapeLibraries) {
            $TapeLibrariesInfo = $TapeLibraries | ForEach-Object {
                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = [ordered] @{
                        'State' = $_.State
                        'Type' = $_.Type
                        'Model' = $_.Model
                    }
                }
            }
            return $TapeLibrariesInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Tape Library Graphviz Cluster
function Get-VbrTapeVaultInfo {
    <#
    .SYNOPSIS
        Retrieves information about Tape Vaults from the Veeam Backup & Replication server.

    .DESCRIPTION
        The Get-VbrTapeVaultInfo function collects and returns information about Tape Vaults from the Veeam Backup & Replication server.
        It sorts the Tape Vaults by their names and provides additional information about their protection status.

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
        Returns a collection of PSCustomObject with the following properties:
            - Name: The name of the Tape Vault.
            - AditionalInfo: A hashtable containing the protection status of the Tape Vault.

    .EXAMPLE
        PS C:\> Get-VbrTapeVaultInfo
        Retrieves and displays information about all Tape Vaults from the Veeam Backup & Replication server.

    .NOTES
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Tape Vault information from $($VBRServer)."
        $TapeVaults = Get-VBRTapeVault | Sort-Object -Property Name

        if ($TapeVaults) {
            $TapeVaultsInfo = $TapeVaults | ForEach-Object {
                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = [ordered] @{
                        'Protect' = if ($_.Protect) { 'Yes' } else { 'No' }
                    }
                }
            }
            return $TapeVaultsInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# Service Provider Graphviz Cluster
function Get-VbrServiceProviderInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication (VBR) service providers.

    .DESCRIPTION
        The Get-VbrServiceProviderInfo function collects and returns information about service providers configured in Veeam Backup & Replication.
        It sorts the service providers by their DNS name and categorizes them based on the types of resources they have enabled (BaaS, DRaaS, vCD, or Unknown).

    .PARAMETERS
        None

    .OUTPUTS
        System.Object
            Returns a collection of PSCustomObject containing the DNS name and additional information about each service provider.

    .EXAMPLE
        PS C:\> Get-VbrServiceProviderInfo
        Retrieves and displays information about the service providers configured in Veeam Backup & Replication.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and imported.
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Service Provider information from $($VBRServer)."
        $ServiceProviders = Get-VBRCloudProvider | Sort-Object -Property 'DNSName'

        if ($ServiceProviders) {
            $ServiceProvidersInfo = $ServiceProviders | ForEach-Object {
                $cloudConnectType = if ($_.ResourcesEnabled -and $_.ReplicationResourcesEnabled) {
                    'BaaS and DRaaS'
                } elseif ($_.ResourcesEnabled) {
                    'BaaS'
                } elseif ($_.ReplicationResourcesEnabled) {
                    'DRaas'
                } elseif ($_.vCDReplicationResources) {
                    'vCD'
                } else { 'Unknown' }

                $inobj = [ordered] @{
                    'Cloud Connect Type' = $cloudConnectType
                    'Managed By Provider' = ConvertTo-TextYN $_.IsManagedByProvider
                }

                [PSCustomObject] @{
                    Name = $_.DNSName
                    AditionalInfo = $inobj
                }
            }
            return $ServiceProvidersInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# SureBackup Virtual Lab Graphviz Cluster
function Get-VbrVirtualLabInfo {
    <#
    .SYNOPSIS
        Retrieves information about Veeam Backup & Replication Virtual Labs.

    .DESCRIPTION
        The Get-VbrVirtualLabInfo function collects and returns information about Virtual Labs configured in Veeam Backup & Replication.
        It retrieves the Virtual Lab details, including platform type and server name, and formats the information into a custom object.

    .PARAMETER None
        This function does not take any parameters.

    .OUTPUTS
        System.Object
            Returns a custom object containing the name, additional information, and icon type of each Virtual Lab.

    .EXAMPLE
        PS C:\> Get-VbrVirtualLabInfo
        Retrieves and displays information about all Virtual Labs configured in Veeam Backup & Replication.

    .NOTES
        This function requires the Veeam Backup & Replication PowerShell module to be installed and configured.
        The function uses the Get-VBRVirtualLab cmdlet to retrieve Virtual Lab information.
        Author: Jonathan Colon
        Date: 2024-12-31
        Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting VirtualLab information from $($VBRServer)."
        $VirtualLab = Get-VBRVirtualLab

        if ($VirtualLab) {
            $VirtualLabInfo = $VirtualLab | ForEach-Object {
                $inobj = [ordered] @{
                    'Platform' = switch ($_.Platform) {
                        'HyperV' { 'Microsoft Hyper-V' }
                        'VMWare' { 'VMWare vSphere' }
                        default { $_.Platform }
                    }
                    'Server' = $_.Server.Name
                }

                $IconType = Get-IconType -String 'VirtualLab'

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $VirtualLabInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}

# SureBackup Application Groups Graphviz Cluster
function Get-VbrApplicationGroupsInfo {
    <#
    .SYNOPSIS
    Retrieves information about Veeam Backup & Replication (VBR) Application Groups.

    .DESCRIPTION
    The Get-VbrApplicationGroupsInfo function collects and returns detailed information about
    the Application Groups configured in the Veeam Backup & Replication server. It includes
    the name of each Application Group, the count of machines in each group, and an icon type
    associated with the Application Groups.

    .PARAMETER None
    This function does not take any parameters.

    .OUTPUTS
    System.Object
    Returns a collection of custom objects containing the following properties:
    - Name: The name of the Application Group.
    - AditionalInfo: An ordered dictionary containing additional information such as the machine count.
    - IconType: The icon type associated with the Application Groups.

    .EXAMPLE
    PS C:\> Get-VbrApplicationGroupsInfo
    This example retrieves and displays information about all Application Groups in the Veeam Backup & Replication server.

    .NOTES
    This function uses the Get-VBRApplicationGroup cmdlet to retrieve the Application Groups and
    the Get-IconType function to determine the icon type.

    Author: Jonathan Colon
    Date: 2024-12-31
    Version: 1.0
    #>
    param ()
    try {
        Write-Verbose "Collecting Application Groups information from $($VBRServer)."
        $ApplicationGroups = Get-VBRApplicationGroup

        if ($ApplicationGroups) {
            $ApplicationGroupsInfo = $ApplicationGroups | ForEach-Object {
                $inobj = [ordered] @{
                    'Machine Count' = ($_.VM | Measure-Object).Count
                }

                $IconType = Get-IconType -String 'ApplicationGroups'

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $ApplicationGroupsInfo
        }

    } catch {
        Write-Verbose -Message $_.Exception.Message
    }
}
