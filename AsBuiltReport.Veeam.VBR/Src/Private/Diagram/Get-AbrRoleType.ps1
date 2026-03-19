function Get-AbrRoleType {
    <#
    .SYNOPSIS
        Translates a role type string to a function type object.

    .DESCRIPTION
        The Get-AbrRoleType function takes a string input representing a role type and translates it into a more descriptive function type object. This is used by Veeam.Diagrammer to provide meaningful role descriptions.

    .PARAMETER String
        The role type string to be translated. Possible values include:
        - LinuxLocal
        - LinuxHardened
        - WinLocal
        - DDBoost
        - HPStoreOnceIntegration
        - ExaGrid
        - InfiniGuard
        - Cloud
        - SanSnapshotOnly
        - vmware
        - hyperv
        - agent
        - nas
        - CifsShare
        - Nfs

    .RETURNS
        A string representing the translated function type object. Possible return values include:
        - Linux Local
        - Linux Hardened
        - Windows Local
        - Dedup Appliances
        - Cloud
        - SAN
        - VMware Backup Proxy
        - Hyper-V Backup Proxy
        - Agent and Files Backup Proxy
        - NAS Backup Proxy
        - SMB Share
        - NFS Share
        - Unknown

    .NOTES
        Version: 0.6.5
        Author: Jonathan Colon

    .EXAMPLE
        PS C:\> Get-AbrRoleType -String 'LinuxLocal'
        Linux Local

        PS C:\> Get-AbrRoleType -String 'vmware'
        VMware Backup Proxy

    .LINK
        https://github.com/veeam/veeam-diagrammer
    #>

    param(
        [string]$String
    )

    $RoleType = switch ($String) {
        'LinuxLocal' { 'Linux Local' }
        'LinuxHardened' { 'Linux Hardened' }
        'WinLocal' { 'Windows Local' }
        'DDBoost' { 'Dedup Appliances' }
        'HPStoreOnceIntegration' { 'Dedup Appliances' }
        'ExaGrid' { 'Dedup Appliances' }
        'InfiniGuard' { 'Dedup Appliances' }
        'Cloud' { 'Cloud' }
        'SanSnapshotOnly' { 'SAN' }
        'vmware' { 'VMware Backup Proxy' }
        'hyperv' { 'Hyper-V Backup Proxy' }
        'agent' { 'Agent and Files Backup Proxy' }
        'nas' { 'NAS Backup Proxy' }
        'CifsShare' { 'SMB Share' }
        'Nfs' { 'NFS Share' }
        default { 'Unknown' }
    }
    return $RoleType
}