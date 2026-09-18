
function Get-AbrVbrDiagrammer {
    <#
    .SYNOPSIS
    Used by As Built Report to get the Veeam.Diagrammer diagram.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.8
        Author:         AsBuiltReport Organization
        Twitter:        @asbuiltreport
        Github:         asbuiltreport
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Backup-to-Tape', 'Backup-to-File-Proxy', 'Backup-to-HyperV-Proxy', 'Backup-to-vSphere-Proxy', 'Backup-to-Repository', 'Backup-to-Sobr', 'Backup-to-WanAccelerator', 'Backup-to-ProtectedGroup', 'Backup-Infrastructure', 'Backup-to-CloudConnect', 'Backup-to-CloudConnect-Tenant', 'Backup-to-HACluster')]
        [string]$DiagramType = 'Backup-Infrastructure',
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('png', 'pdf', 'base64', 'jpg', 'svg')]
        [string]$DiagramOutput,
        [Switch]$ExportPath = $false,
        [string]$Tenant,
        [ValidateSet('top-to-bottom', 'left-to-right')]
        [string] $Direction = 'top-to-bottom'
    )

    begin {
        Write-PScriboMessage "Generating Veeam diagram ($DiagramType) from Backup Server $System."
    }

    process {
        try {
            # Set the image paths for the diagram
            if ($Options.NewIcons) {
                $script:Images = @{
                    'VBR_Server' = 'New_VBR_server.png'
                    'VBR_Repository' = 'New_VBR_Repository.png'
                    'VBR_Veeam_Repository' = 'New_Veeam_Repository.png'
                    'VBR_NAS' = 'New_NAS.png'
                    'VBR_Deduplicating_Storage' = 'New_Deduplication.png'
                    'VBR_Linux_Repository' = 'New_Linux_Repository.png'
                    'VBR_Windows_Repository' = 'New_Windows_Repository.png'
                    'VBR_Cloud_Repository' = 'New_Cloud_Repository.png'
                    'VBR_Cloud_Connect' = 'New_Cloud_Connect.png'
                    'VBR_Cloud_Connect_Gateway' = 'New_VSPC_server.png'
                    'VBR_Cloud_Connect_Gateway_Pools' = 'New_Folder.png'
                    'VBR_Object_Repository' = 'New_Object_storage.png'
                    'VBR_Object' = 'New_Object_storage.png'
                    'VBR_Amazon_S3_Compatible' = 'New_S3-compatible.png'
                    'VBR_Amazon_S3' = 'New_AWS_S3.png'
                    'VBR_Azure_Blob' = 'New_Azure_Blob.png'
                    'VBR_Server_DB' = 'New_Microsoft_SQL.png'
                    'VBR_Proxy' = 'New_Proxy.png'
                    'VBR_Proxy_Server' = 'New_Proxy.png'
                    'VBR_Wan_Accel' = 'New_WAN_accelerator.png'
                    'VBR_SOBR' = 'New_Scale-out_Backup_Repository.png'
                    'VBR_SOBR_Repo' = 'New_Scale_out_Backup_Repository.png'
                    'VBR_LOGO' = 'Veeam_logo_new.png'
                    'VBR_No_Icon' = 'no_icon.png'
                    'VBR_Blank_Filler' = 'BlankFiller.png'
                    'VBR_Storage_NetApp' = 'Storage_NetApp.png'
                    'VBR_vCenter_Server' = 'New_VMware_vSphere.png'
                    'VBR_ESXi_Server' = 'New_Hypervisor.png'
                    'VBR_HyperV_Server' = 'New_Hypervisor.png'
                    'VBR_Esxi_AHV_HyperV_Server' = 'New_Hypervisor.png'
                    'VBR_Server_EM' = 'New_Veeam_Backup_Enterprise_Manager.png'
                    'VBR_Tape_Server' = 'New_VBR_server.png'
                    'VBR_Tape_Library' = 'New_Tape_Library.png'
                    'VBR_Tape_Drive' = 'New_Server_1U.png'
                    'VBR_Tape_Vaults' = 'New_Tape_Drive.png'
                    'VBR_Server_DB_PG' = 'New_PostgreSQL.png'
                    'VBR_LOGO_Footer' = 'verified_recoverability.png'
                    'VBR_AGENT_Container' = 'New_Folder.png'
                    'VBR_AGENT_AD' = 'New_VBR_server.png'
                    'VBR_AGENT_MC' = 'New_Tasks.png'
                    'VBR_AGENT_IC' = 'New_Workstation.png'
                    'VBR_AGENT_CSV' = 'CSV_Computers.png'
                    'VBR_AGENT_AD_Logo' = 'New_Microsoft_Active_Directory.png'
                    'VBR_AGENT_CSV_Logo' = 'New_File.png'
                    'VBR_AGENT_Server' = 'New_Veeam_Agent.png'
                    'VBR_vSphere' = 'New_VMware_vSphere.png'
                    'VBR_HyperV' = 'New_Microsoft_SCVMM.png'
                    'VBR_Tape' = 'New_Tape_Drive.png'
                    'VBR_Service_Providers' = 'New_VSPC_server.png'
                    'VBR_Service_Providers_Server' = 'New_Service_Provider_Server.png'
                    'VBR_NetApp' = 'New_Storage_array.png'
                    'VBR_Dell' = 'New_Storage_array.png'
                    'VBR_SAN' = 'New_Storage_array.png'
                    'VBR_Virtual_Lab' = 'New_Hypervisor.png'
                    'VBR_SureBackup' = 'New_SureBackup.png'
                    'VBR_Application_Groups' = 'New_Service.png'
                    'VBR_vSphere_Cluster' = 'New_Cluster.png'
                    'VBR_HyperV_Cluster' = 'New_Cluster.png'
                    'VBR_Server_HA' = 'New_Cluster.png'
                    'VBR_Microsoft_Entra_ID' = 'New_Microsoft_Entra_ID.png'
                    'VBR_Bid_Arrow' = 'BidirectionalArrow.png'
                    'VBR_Hardware_Resources' = 'New_CPU.png'
                    'VBR_Cloud_Network_Extension' = 'New_Hardware_controller.png'
                    'VBR_Cloud_Storage' = 'New_Datastore.png'
                    'VBR_Cloud_Connect_vCD' = 'New_VMware_vCloud_Director.png'
                    'VBR_Cloud_Connect_Server' = 'New_VMware_vCloud_Director.png'
                    'VBR_Cloud_Connect_VM' = 'New_VM_with_a_snapshot.png'
                    'VBR_Cloud_Sub_Tenant' = 'New_User_group.png'
                    'VBR_GrayArrow' = 'GrayArrow.png'
                    'VBR_Webconsole' = 'Webconsole.png'
                    'VBR_Data_Cloud_Vault' = 'VeeamDataCloudVault.png'
                    'VBR_Data_Cloud_Archive' = 'VeeamDataCloud.png'
                }
            } else {
                $script:Images = @{
                    'VBR_Server' = 'VBR_server.png'
                    'VBR_Repository' = 'VBR_Repository.png'
                    'VBR_Veeam_Repository' = 'Veeam_Repository.png'
                    'VBR_NAS' = 'NAS.png'
                    'VBR_Deduplicating_Storage' = 'Deduplication.png'
                    'VBR_Linux_Repository' = 'Linux_Repository.png'
                    'VBR_Windows_Repository' = 'Windows_Repository.png'
                    'VBR_Cloud_Repository' = 'Cloud_Repository.png'
                    'VBR_Cloud_Connect' = 'Veeam_Cloud_Connect.png'
                    'VBR_Cloud_Connect_Gateway' = 'VSPC_server.png'
                    'VBR_Cloud_Connect_Gateway_Pools' = 'Folder.png'
                    'VBR_Object_Repository' = 'Object_Storage.png'
                    'VBR_Object' = 'Object_Storage_support.png'
                    'VBR_Amazon_S3_Compatible' = 'S3-compatible.png'
                    'VBR_Amazon_S3' = 'AWS S3.png'
                    'VBR_Azure_Blob' = 'Azure Blob.png'
                    'VBR_Server_DB' = 'Microsoft_SQL_DB.png'
                    'VBR_Proxy' = 'Veeam_Proxy.png'
                    'VBR_Proxy_Server' = 'Proxy_Server.png'
                    'VBR_Wan_Accel' = 'WAN_accelerator.png'
                    'VBR_SOBR' = 'Logo_SOBR.png'
                    'VBR_SOBR_Repo' = 'Scale_out_Backup_Repository.png'
                    'VBR_LOGO' = 'Veeam_logo_new.png'
                    'VBR_No_Icon' = 'no_icon.png'
                    'VBR_Blank_Filler' = 'BlankFiller.png'
                    'VBR_Storage_NetApp' = 'Storage_NetApp.png'
                    'VBR_vCenter_Server' = 'vCenter_server.png'
                    'VBR_ESXi_Server' = 'ESXi_host.png'
                    'VBR_HyperV_Server' = 'Hyper-V_host.png'
                    'VBR_Esxi_AHV_HyperV_Server' = 'ESXi_Hyper-V_AHV_host.png'
                    'VBR_Server_EM' = 'Veeam_Backup_Enterprise_Manager.png'
                    'VBR_Tape_Server' = 'Tape_Server.png'
                    'VBR_Tape_Library' = 'Tape_Library.png'
                    'VBR_Tape_Drive' = 'Tape_Drive.png'
                    'VBR_Tape_Vaults' = 'Tape encrypted.png'
                    'VBR_Server_DB_PG' = 'PostGre_SQL_DB.png'
                    'VBR_LOGO_Footer' = 'verified_recoverability.png'
                    'VBR_AGENT_Container' = 'Folder.png'
                    'VBR_AGENT_AD' = 'Server.png'
                    'VBR_AGENT_MC' = 'Task list.png'
                    'VBR_AGENT_IC' = 'Workstation.png'
                    'VBR_AGENT_CSV' = 'CSV_Computers.png'
                    'VBR_AGENT_AD_Logo' = 'Microsoft Active Directory.png'
                    'VBR_AGENT_CSV_Logo' = 'File.png'
                    'VBR_AGENT_Server' = 'Server_with_Veeam_Agent.png'
                    'VBR_vSphere' = 'VMware_vSphere.png'
                    'VBR_HyperV' = 'Microsoft_SCVMM.png'
                    'VBR_Tape' = 'Tape.png'
                    'VBR_Service_Providers' = 'Veeam_Service_Provider_Console.png'
                    'VBR_Service_Providers_Server' = 'Veeam_Service_Provider_Server.png'
                    'VBR_NetApp' = 'Storage_with_snapshot.png'
                    'VBR_Dell' = 'Storage_with_snapshot.png'
                    'VBR_SAN' = 'Storage_Stack.png'
                    'VBR_Virtual_Lab' = 'Virtual_host.png'
                    'VBR_SureBackup' = 'SureBackup.png'
                    'VBR_Application_Groups' = 'Service-Application.png'
                    'VBR_vSphere_Cluster' = 'Server_Cluster.png'
                    'VBR_HyperV_Cluster' = 'Server_Cluster.png'
                    'VBR_Server_HA' = 'Server_Cluster.png'
                    'VBR_Microsoft_Entra_ID' = 'Microsoft_Entra_ID.png'
                    'VBR_Bid_Arrow' = 'BidirectionalArrow.png'
                    'VBR_Hardware_Resources' = 'RAM.png'
                    'VBR_Cloud_Network_Extension' = 'Hardware_controller.png'
                    'VBR_Cloud_Storage' = 'Datastore.png'
                    'VBR_Cloud_Connect_vCD' = 'VMware vCloud Director.png'
                    'VBR_Cloud_Connect_Server' = 'vCloud_Director_server.png'
                    'VBR_Cloud_Connect_VM' = 'VM_with_a_snapshot.png'
                    'VBR_Cloud_Sub_Tenant' = 'SubTenant.png'
                    'VBR_GrayArrow' = 'GrayArrow.png'
                    'VBR_Webconsole' = 'Webconsole.png'
                    'VBR_Data_Cloud_Vault' = 'New_S3-compatible.png'
                    'VBR_Data_Cloud_Archive' = 'New_S3-compatible.png'
                }
            }
            # Set default theme styles
            if (-not $Options.DiagramTheme) {
                $DiagramTheme = 'White'
                $DiagramFontColor = 'DarkGreen'
            } else {
                $DiagramTheme = $Options.DiagramTheme
                if ($DiagramTheme -eq 'Black') {
                    $DiagramFontColor = 'White'
                } elseif ($DiagramTheme -eq 'White') {
                    $DiagramFontColor = 'DarkGreen'
                } elseif ($DiagramTheme -eq 'Neon') {
                    $DiagramFontColor = 'gold'
                } else {
                    $DiagramFontColor = 'DarkGreen'
                }
            }
            $DiagramTypeHash = @{
                'Backup-Infrastructure' = 'Infrastructure'
                'Backup-to-File-Proxy' = 'FileProxy'
                'Backup-to-HyperV-Proxy' = 'HyperVProxy'
                'Backup-to-ProtectedGroup' = 'ProtectedGroup'
                'Backup-to-Repository' = 'Repository'
                'Backup-to-Sobr' = 'Sobr'
                'Backup-to-Tape' = 'Tape'
                'Backup-to-vSphere-Proxy' = 'vSphereProxy'
                'Backup-to-WanAccelerator' = 'WanAccelerator'
                'Backup-to-CloudConnect' = 'CloudConnect'
                'Backup-to-CloudConnect-Tenant' = 'CloudConnectTenant'
                'Backup-to-HACluster' = 'HACluster'
            }

            if (-not $Options.ExportDiagramsFormat) {
                $DiagramFormat = 'png'
            } elseif ($DiagramOutput) {
                $DiagramFormat = $DiagramOutput
            } else {
                $DiagramFormat = $Options.ExportDiagramsFormat
            }

            $DiagramLabel = switch ($DiagramType) {
                'Backup-to-Sobr' { 'Scale-Out Backup Repository Diagram' }
                'Backup-to-File-Proxy' { 'File Backup Proxy Diagram' }
                'Backup-to-vSphere-Proxy' { 'VMware Backup Proxy Diagram' }
                'Backup-to-HyperV-Proxy' { 'Hyper-V Backup Proxy Diagram' }
                'Backup-to-Repository' { 'Backup Repository Diagram' }
                'Backup-to-WanAccelerator' { 'WAN Accelerators Diagram' }
                'Backup-to-Tape' { 'Tape Infrastructure Diagram' }
                'Backup-to-ProtectedGroup' { 'Physical Infrastructure Diagram' }
                'Backup-Infrastructure' { 'Backup Infrastructure Diagram' }
                'Backup-to-CloudConnect' { 'Cloud Connect Infrastructure Diagram' }
                'Backup-to-CloudConnect-Tenant' { "Cloud Connect $Tenant Resources Diagram" }
                'Backup-to-HACluster' { 'High Availability Diagram' }
            }
            $IconDebug = $false
            $IconPath = Join-Path -Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Tools\icons'
            $ColumnSize = switch ([string]::IsNullOrEmpty($Options.DiagramColumnSize)) {
                $true { 3 }
                $false {
                    switch ($Options.DiagramColumnSize) {
                        0 { 3 }
                        default { $Options.DiagramColumnSize }
                    }
                }
                default { 3 }
            }
            $NewIcons = [bool]$Options.NewIcons
            $TenantName = $Tenant
            $DiagramParams = @{
                'OutputFolderPath' = $OutputFolderPath
                'MainDiagramLabel' = $DiagramLabel
                'MainDiagramLabelFontsize' = 28
                'MainDiagramLabelFontname' = 'Segoe Ui Black'
                'IconPath' = $IconPath
                'ImagesObj' = $Images
                'LogoName' = 'VBR_LOGO'
                'SignatureLogoName' = 'VBR_LOGO_Footer'
                'WaterMarkText' = $Options.DiagramWaterMark
                'WaterMarkColor' = $DiagramFontColor
                'Direction' = if ($DiagramType -eq 'Backup-Infrastructure') { 'top-to-bottom' } else { $Direction }
                'EdgeType' = 'spline'
                'EdgeLineWidth' = 3
                'MainGraphBGColor' = 'White'
                'Edgecolor' = '#71797E'
                'Fontcolor' = '#565656'
                'NodeFontcolor' = 'Black'
                'SignatureTableBorderColor' = '#71797E'
                'SignatureTableBackgroundColor' = 'White'
                'MainDiagramLabelFontColor' = '#565656'
                'MainDiagramLabelTableBackgroundColor' = 'White'
            }

            if ($DiagramTheme -eq 'Black') {
                $DiagramParams['MainGraphBGColor'] = 'Black'
                $DiagramParams['Edgecolor'] = 'White'
                $DiagramParams['Fontcolor'] = 'White'
                $DiagramParams['NodeFontcolor'] = 'White'
                $DiagramParams['WaterMarkColor'] = 'White'
                $DiagramParams['SignatureTableBorderColor'] = 'Black'
                $DiagramParams['SignatureTableBackgroundColor'] = 'Black'
                $DiagramParams['MainDiagramLabelFontColor'] = 'White'
                $DiagramParams['MainDiagramLabelTableBackgroundColor'] = 'Black'
            } elseif ($DiagramTheme -eq 'Neon') {
                $DiagramParams['MainGraphBGColor'] = 'grey14'
                $DiagramParams['Edgecolor'] = 'gold2'
                $DiagramParams['Fontcolor'] = 'gold2'
                $DiagramParams['NodeFontcolor'] = 'gold2'
                $DiagramParams['WaterMarkColor'] = '#FFD700'
                $DiagramParams['SignatureTableBorderColor'] = 'gold2'
                $DiagramParams['SignatureTableBackgroundColor'] = 'grey14'
                $DiagramParams['MainDiagramLabelFontColor'] = 'gold2'
                $DiagramParams['MainDiagramLabelTableBackgroundColor'] = 'grey14'
            }

            if ($Options.EnableDiagramDebug) {
                $DiagramParams.Add('DraftMode', $True)
                $DiagramParams.Add('EnableErrorDebug', $True)
            }

            if ($Options.EnableDiagramSignature) {
                $DiagramParams.Add('Signature', $True)
                $DiagramParams.Add('AuthorName', $Options.SignatureAuthorName)
                $DiagramParams.Add('CompanyName', $Options.SignatureCompanyName)
            }
            try {
                $DiagramGraph = & {
                    if ($DiagramType -eq 'Backup-to-CloudConnect-Tenant' -and [string]::IsNullOrEmpty($TenantName)) {
                        throw 'TenantName must be used with the Backup-to-CloudConnect-Tenant diagram type.'
                    }

                    $script:NewIcons = $NewIcons
                    if ($Options.EnableDiagramDebug) {
                        $script:EdgeDebug = @{style = 'filled'; color = 'red' }
                        $script:SubGraphDebug = @{style = 'dashed'; color = 'red' }
                        $script:NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
                        $script:NodeDebugEdge = @{color = 'black'; style = 'red'; shape = 'plain' }
                    } else {
                        $script:SubGraphDebug = @{style = 'invis'; color = 'gray' }
                        $script:NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
                        $script:NodeDebugEdge = @{color = 'transparent'; style = 'transparent'; shape = 'none' }
                        $script:EdgeDebug = @{style = 'invis'; color = 'red' }
                    }

                    if ($DiagramTheme -eq 'Black') {
                        $MainGraphBGColor = 'Black'
                        $TableBorderColor = 'White'
                        $Edgecolor = 'White'
                        $Fontcolor = 'White'
                        $NodeFontcolor = 'White'
                        $EdgeArrowSize = 1
                        $EdgeLineWidth = 3
                        $BackupServerBGColor = 'Black'
                        $BackupServerFontColor = 'White'
                    } elseif ($DiagramTheme -eq 'Neon') {
                        $MainGraphBGColor = 'grey14'
                        $TableBorderColor = 'gold2'
                        $Edgecolor = 'gold2'
                        $Fontcolor = 'gold2'
                        $NodeFontcolor = 'gold2'
                        $EdgeArrowSize = 1
                        $EdgeLineWidth = 3
                        $BackupServerBGColor = 'grey14'
                        $BackupServerFontColor = 'gold2'
                    } else {
                        $MainGraphBGColor = 'White'
                        $TableBorderColor = '#71797E'
                        $Edgecolor = '#71797E'
                        $Fontcolor = '#565656'
                        $NodeFontcolor = 'Black'
                        $EdgeArrowSize = 1
                        $EdgeLineWidth = 3
                        $BackupServerBGColor = if ($NewIcons) { '#dbdddf' } else { '#ceedc4' }
                        $BackupServerFontColor = if ($NewIcons) { '#565656' } else { '#007F49' }
                    }

                    try {
                        $script:VBRServer = (Get-VBRServerSession).Server
                    } catch {
                        throw "Unable to get Veeam Backup & Replication Server information: $System"
                    }

                    Get-AbrBackupServerInformation
                    if (-not $BackupServerInfo) {
                        throw 'No Backup Server Information available to diagram'
                    }
                    Write-PScriboMessage 'Backup Server Information collected'

                    switch ($DiagramType) {
                        'Backup-to-HyperV-Proxy' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToHvProxy
                            if (-not $DiagramContent) { throw 'No Hyper-V Proxy Infrastructure available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-vSphere-Proxy' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToViProxy
                            if (-not $DiagramContent) { throw 'No vSphere Proxy Infrastructure available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-File-Proxy' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToFileProxy
                            if (-not $DiagramContent) { throw 'No File Proxy Infrastructure available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-WanAccelerator' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToWanAccel
                            if (-not $DiagramContent) { throw 'No WAN Accelerators available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-Repository' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToRepo
                            if (-not $DiagramContent) { throw 'No Backup Repository available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-ProtectedGroup' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToProtectedGroup
                            if (-not $DiagramContent) { throw 'No Backup Protected Group available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-Tape' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToTape
                            if (-not $DiagramContent) { throw 'No Tape Infrastructure available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-Sobr' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToSobr
                            if (-not $DiagramContent) { throw 'No Scale-Out Backup Repository available to diagram' }
                            $DiagramContent
                        }
                        'Backup-Infrastructure' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrInfraDiagram
                            if (-not $DiagramContent) { throw 'No Backup Infrastructure available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-CloudConnect' {
                            Get-AbrDiagBackupServer
                            $DiagramContent = Get-AbrDiagBackupToCloudConnect
                            if (-not $DiagramContent) { throw 'No Cloud Connect infrastructure available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-CloudConnect-Tenant' {
                            $DiagramContent = Get-AbrDiagBackupToCloudConnectTenant
                            if (-not $DiagramContent) { throw 'No Cloud Connect Tenant infrastructure available to diagram' }
                            $DiagramContent
                        }
                        'Backup-to-HACluster' {
                            $DiagramContent = Get-AbrDiagBackupToHACluster
                            if (-not $DiagramContent) { throw 'No HA Cluster infrastructure available to diagram' }
                            $DiagramContent
                        }
                    }
                }
                if (-not $DiagramGraph) {
                    return
                }
                $DiagramParams.Add('InputObject', $DiagramGraph)

                foreach ($Format in $DiagramFormat) {
                    if ($Format -eq 'base64') {
                        $DiagramParams['Format'] = $Format
                        $Graph = New-AbrDiagram @DiagramParams
                        if ($Graph) {
                            $Graph
                        }
                    } else {
                        $DiagramFileBase = if ($Tenant) {
                            "AsBuiltReport.Veeam.VBR-$($DiagramTypeHash[$DiagramType])-$(Remove-SpecialCharacter -String $Tenant -SpecialChars '\/:*?"<>|')"
                        } else {
                            "AsBuiltReport.Veeam.VBR-$($DiagramTypeHash[$DiagramType])"
                        }
                        $DiagramParams['Format'] = $Format
                        $DiagramParams['Filename'] = $DiagramFileBase
                        $Null = New-AbrDiagram @DiagramParams
                        if ($ExportPath) {
                            $FilePath = Join-Path -Path $OutputFolderPath -ChildPath "$DiagramFileBase.$Format"
                            if (Test-Path -Path $FilePath) {
                                $FilePath
                            } else {
                                Write-PScriboMessage -IsWarning "Unable to export the $DiagramType Diagram: '$FilePath' not found after generation."
                            }
                        } else {
                            Write-Host "Saved '$DiagramFileBase.$Format' diagram to '$($OutputFolderPath)'."
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "Unable to export the $($DiagramTypeHash[$DiagramType]) Diagram: $($_.Exception.Message)"
            }
        } catch {
            Write-PScriboMessage -IsWarning "Unable to get the $($DiagramTypeHash[$DiagramType]) Diagram: $($_.Exception.Message)"
        }
    }
    end {}
}