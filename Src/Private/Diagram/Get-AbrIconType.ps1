function Get-AbrIconType {
    <#
    .SYNOPSIS
        Translates repository type to icon type object for Veeam.Diagrammer.

    .DESCRIPTION
        The Get-AbrIconType function takes a repository type as input and returns the corresponding icon type object.
        This is used by Veeam.Diagrammer to map different repository types to their respective icons.

    .PARAMETER String
        The repository type as a string. Possible values include:
        - LinuxLocal
        - Hardened
        - LinuxHardened
        - WinLocal
        - Cloud
        - GoogleCloudStorage
        - AmazonS3Compatible
        - AmazonS3Glacier
        - AmazonS3
        - AzureArchive
        - AzureBlob
        - DDBoost
        - HPStoreOnceIntegration
        - ExaGrid
        - SanSnapshotOnly
        - Proxy
        - ProxyServer
        - ESXi
        - HyperVHost
        - ManuallyDeployed
        - IndividualComputers
        - ActiveDirectory
        - CSV
        - CifsShare
        - Nfs
        - Netapp
        - Dell
        - VirtualLab
        - ApplicationGroups

    .EXAMPLE
        PS C:\> Get-AbrIconType -String 'LinuxLocal'
        VBR_Linux_Repository

        This example translates the 'LinuxLocal' repository type to its corresponding icon type 'VBR_Linux_Repository'.

    .LINK
        https://github.com/jocolon/Veeam.Diagrammer
    #>
    param(
        [string]$String
    )

    $IconType = switch ($String) {
        'LinuxLocal' { 'VBR_Linux_Repository' }
        'Hardened' { 'VBR_Linux_Repository' }
        'LinuxHardened' { 'VBR_Linux_Repository' }
        'WinLocal' { 'VBR_Windows_Repository' }
        'Cloud' { 'VBR_Cloud_Repository' }
        'GoogleCloudStorage' { 'VBR_Amazon_S3_Compatible' }
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
        'CifsShare' { 'VBR_NAS' }
        'Nfs' { 'VBR_NAS' }
        'Netapp' { 'VBR_NetApp' }
        'Dell' { 'VBR_Dell' }
        'VirtualLab' { 'VBR_Virtual_Lab' }
        'ApplicationGroups' { 'VBR_Application_Groups' }
        'ExtendableRepository' { 'VBR_SOBR_Repo' }
        default { 'VBR_No_Icon' }
    }

    return $IconType
}