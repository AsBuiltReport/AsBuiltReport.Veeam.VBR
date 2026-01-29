function Get-AbrDiagBackupToCloudConnectTenant {
    <#
    .SYNOPSIS
        Function to build Backup Server to Cloud Connect tenant diagram.
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

    begin {
    }

    process {

        if ($CCPerTenantInfo = Get-AbrBackupCCPerTenantInfo -TenantName $TenantName) {

            # Create Tenant Node

            try {
                $TenantInfo = Node -Name 'TenantInfo' -Attributes @{
                    Label = $CCPerTenantInfo.Label;
                    shape = 'plain';
                    fillColor = 'transparent';
                    fontsize = 14;
                    fontname = 'Segoe Ui'
                }
                if ($TenantInfo) {
                    $TenantInfo
                    Edge -From 'TenantInfo' -To 'TenantGateway' -Attributes @{
                        color = $Edgecolor;
                        style = 'dashed';
                        fontname = 'Segoe Ui';
                        fontsize = 14;
                        arrowtail = 'dot';
                        arrowhead = 'dot';
                        minlen = 5;
                    }
                }

            } catch {
                Write-PScriboMessage 'Error: Unable to create TenantInfo Objects. Panic!'
                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                throw
            }

            # Create Tenant Gateway Server Node
            if (($CGServerInfo = $CCPerTenantInfo.CloudGatewayServers) -and $CCPerTenantInfo.CloudGatewaySelectionType -eq 'StandaloneGateway') {
                if ($CGServerInfo.Name.Count -eq 1) {
                    $CGServerNodeColumnSize = 1
                } elseif ($ColumnSize) {
                    $CGServerNodeColumnSize = $ColumnSize
                } else {
                    $CGServerNodeColumnSize = $CGServerInfo.Name.Count
                }
                try {
                    $CGServerNode = Add-DiaHtmlNodeTable -Name 'CGServerNode' -ImagesObj $Images -inputObject $CGServerInfo.Name -Align 'Center' -iconType 'VBR_Cloud_Connect_Gateway' -ColumnSize $CGServerNodeColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CGServerInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Service_Providers_Server' -SubgraphLabel 'Gateway Servers' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                    if ($CGServerNode) {
                        Node 'TenantGateway' -Attributes @{
                            Label = $CGServerNode;
                            shape = 'plain';
                            fillColor = 'transparent';
                            fontsize = 14;
                            fontname = 'Segoe Ui'
                        }

                        Edge -From 'TenantGateway' -To 'TenantGatewayConnector' -Attributes @{
                            color = $Edgecolor;
                            style = 'dashed';
                            fontname = 'Segoe Ui';
                            fontsize = 14
                            arrowtail = 'dot';
                            arrowhead = 'none';
                        }
                    }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create CloudGateway Server Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }

            # Create Tenant Gateway Pool Node
            if (($CGPoolInfo = $CCPerTenantInfo.CloudGatewayPools) -and $CCPerTenantInfo.CloudGatewaySelectionType -eq 'GatewayPool') {
                try {
                    $CGPoolNode = foreach ($CGPool in $CGPoolInfo) {
                        if ($CGPoolInfo.CloudGateways) {
                            if ($CGPoolInfo.CloudGateways.count -le 5) {
                                $CGPoolInfocolumnSize = $CGPoolInfo.CloudGateways.count
                            } elseif ($ColumnSize) {
                                $CGPoolInfocolumnSize = $ColumnSize
                            } else {
                                $CGPoolInfocolumnSize = 5
                            }
                            Add-DiaHtmlTable -Name 'CGPoolNode' -ImagesObj $Images -Rows $CGPool.CloudGateways.Name.split('.')[0] -ALIGN 'Center' -ColumnSize $CGPoolInfocolumnSize -IconDebug $IconDebug -Subgraph -SubgraphIconType 'VBR_Cloud_Connect_Gateway' -SubgraphLabel $CGPool.Name -SubgraphLabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -NoFontBold -FontSize 18 -SubgraphFontBold
                        } else {
                            Add-DiaHtmlTable -Name 'CGPoolNode' -ImagesObj $Images -Rows 'No Cloud Gateway Server' -ALIGN 'Center' -ColumnSize 1 -IconDebug $IconDebug -Subgraph -SubgraphIconType 'VBR_Cloud_Connect_Gateway' -SubgraphLabel $CGPool.Name -SubgraphLabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -NoFontBold -FontSize 18 -SubgraphFontBold
                        }
                    }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create CGPoolInfo Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
                try {
                    if ($CGPoolNode) {
                        if ($CGPoolNode.count -le 5) {
                            $CGPoolNodecolumnSize = $CGPoolNode.count
                        } elseif ($ColumnSize) {
                            $CGPoolNodecolumnSize = $ColumnSize
                        } else {
                            $CGPoolNodecolumnSize = 5
                        }
                        $CGPoolNodesSubGraph += Add-DiaHtmlSubGraph -Name 'CGPoolNodesSubGraph' -ImagesObj $Images -TableArray $CGPoolNode -Align 'Center' -IconDebug $IconDebug -Label 'Gateway Pools' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $CGPoolNodecolumnSize -FontSize 22 -IconType 'VBR_Cloud_Connect_Gateway_Pools' -FontBold

                        if ($CGPoolNodesSubGraph) {
                            Node 'TenantGateway' -Attributes @{
                                Label = $CGPoolNodesSubGraph;
                                shape = 'plain';
                                fillColor = 'transparent';
                                fontsize = 14;
                                fontname = 'Segoe Ui'
                            }

                            Edge -From 'TenantGateway' -To 'TenantGatewayConnector' -Attributes @{
                                color = $Edgecolor;
                                style = 'dashed';
                                fontname = 'Segoe Ui';
                                fontsize = 14
                                arrowtail = 'dot';
                                arrowhead = 'none';
                            }
                        }
                    }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create CGPoolInfo SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }

            # Create Tenant Backup Storage Node
            if ($CCBackupStorageObj = $CCPerTenantInfo.BackupResources) {
                $CloudRepoSubgraphNode = @()
                $CloudConnectTenantRRSubTenantArray = @()
                foreach ($CCBackupStorageInfo in $CCBackupStorageObj) {
                    $CloudConnectTenantBSArray = @()
                    $CloudConnectTenantBRArray = @()

                    $CloudRepoOBJNode = $CCBackupStorageInfo.Label

                    if ($CloudRepoOBJNode) {
                        $CloudConnectTenantBRArray += $CloudRepoOBJNode
                    }

                    if (($CCBackupStorageInfo.Repositories | Measure-Object).Count -le 5) {
                        $BackupRepositorycolumnSize = ($CCBackupStorageInfo.Repositories | Measure-Object).Count
                    } elseif ($ColumnSize) {
                        $BackupRepositorycolumnSize = $ColumnSize
                    } else {
                        $BackupRepositorycolumnSize = 5
                    }
                    try {
                        $CCBackupRepositoryNode = Add-DiaHtmlNodeTable -Name 'CCBackupRepositoryNode' -ImagesObj $Images -inputObject $CCBackupStorageInfo.Repositories.Name -Align 'Center' -iconType $CCBackupStorageInfo.Repositories.IconType -ColumnSize $BackupRepositorycolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCBackupStorageInfo.Repositories.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Repository' -SubgraphLabel 'Backup Repositories' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                        if ($CCBackupRepositoryNode) {
                            $CloudConnectTenantBSArray += $CCBackupRepositoryNode
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CCBackupRepositoryNode Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    if ($CCBackupStorageInfo.WanAccelerationEnabled) {
                        if (($CCBackupStorageInfo.WanAccelerator | Measure-Object).Count -le 5) {
                            $CCBSWancolumnSize = ($CCBackupStorageInfo.WanAccelerator | Measure-Object).Count
                        } elseif ($ColumnSize) {
                            $CCBSWancolumnSize = $ColumnSize
                        } else {
                            $CCBSWancolumnSize = 5
                        }
                        try {
                            $CCCloudWanAcceleratorNode = Add-DiaHtmlNodeTable -Name 'CCCloudWanAcceleratorNode' -ImagesObj $Images -inputObject $CCBackupStorageInfo.WanAccelerator.Name -Align 'Center' -iconType $CCBackupStorageInfo.WanAccelerator.IconType -ColumnSize $CCBSWancolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCBackupStorageInfo.WanAccelerator.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Wan_Accel' -SubgraphLabel 'Wan Accelerators' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                            if ($CCCloudWanAcceleratorNode) {
                                $CloudConnectTenantBSArray += $CCCloudWanAcceleratorNode
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CCCloudWanAcceleratorNode Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }
                    }

                    try {
                        if ($CloudConnectTenantBSArray) {
                            if (($CloudConnectTenantBSArray | Measure-Object).Count -le 5) {
                                $CloudConnectTenantBSArraycolumnSize = ($CloudConnectTenantBSArray | Measure-Object).Count
                            } elseif ($ColumnSize) {
                                $CloudConnectTenantBSArraycolumnSize = $ColumnSize
                            } else {
                                $CloudConnectTenantBSArraycolumnSize = 5
                            }
                            $CloudConnectTenantBSSubGraph = Add-DiaHtmlSubGraph -Name 'CloudConnectTenantBSSubGraph' -ImagesObj $Images -TableArray $CloudConnectTenantBSArray -Align 'Center' -IconDebug $IconDebug -Label 'Resources' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $CloudConnectTenantBSArraycolumnSize -FontSize 22 -FontBold

                            if ($CloudConnectTenantBSSubGraph) {
                                $CloudConnectTenantBRArray += $CloudConnectTenantBSSubGraph
                            }

                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CloudConnectTenantBSSubGraph SubGraph Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }

                    try {
                        $CloudRepoSubgraphNode += Add-DiaHtmlSubGraph -Name 'CloudRepoSubgraphNode' -ImagesObj $Images -TableArray $CloudConnectTenantBRArray -Align 'Center' -IconDebug $IconDebug -Label $CCBackupStorageInfo.Name -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 20 -FontBold
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create Cloud Resource SubGraph Nodes Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }

                    if ($CCBackupStorageInfo.SubTenant) {
                        if (($CCBackupStorageInfo.SubTenant.Name | Measure-Object).Count -le 5) {
                            $CCRRNetExtcolumnSize = ($CCBackupStorageInfo.SubTenant.Name | Measure-Object).Count
                        } elseif ($ColumnSize) {
                            $CCRRNetExtcolumnSize = $ColumnSize
                        } else {
                            $CCRRNetExtcolumnSize = 5
                        }
                        try {
                            $CCCloudSubTenantNode = Add-DiaHtmlNodeTable -Name 'CCCloudSubTenantNode' -ImagesObj $Images -inputObject $CCBackupStorageInfo.SubTenant.Name -Align 'Center' -iconType $CCBackupStorageInfo.SubTenant.IconType -ColumnSize $CCRRNetExtcolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCBackupStorageInfo.SubTenant.AditionalInfo -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                            if ($CCCloudSubTenantNode) {
                                $CloudConnectTenantRRSubTenantArray += $CCCloudSubTenantNode
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CCCloudSubTenantNode Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }
                    }
                }
                try {
                    $CloudRepoSubgraph = Add-DiaHtmlSubGraph -Name 'CloudRepoSubgraph' -ImagesObj $Images -TableArray $CloudRepoSubgraphNode -Align 'Center' -IconDebug $IconDebug -Label 'Backup Resources' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 4 -FontSize 22 -IconType 'VBR_Cloud_Storage' -FontBold
                } catch {
                    Write-PScriboMessage 'Error: Unable to create Cloud Resource SubGraph Nodes Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($CloudConnectTenantRRSubTenantArray) {
                    try {
                        $CloudConnectTenantRRSubTenantSubgraphNode = Add-DiaHtmlSubGraph -Name 'CloudConnectTenantRRSubTenantSubgraphNode' -ImagesObj $Images -TableArray $CloudConnectTenantRRSubTenantArray -Align 'Center' -IconDebug $IconDebug -Label 'SubTenants' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 4 -FontSize 22 -IconType 'VBR_Cloud_Storage' -FontBold
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create SubTenants SubGraph Nodes Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                if ($CloudRepoSubgraph) {
                    Node 'TenantBackupStorage' -Attributes @{
                        Label = $CloudRepoSubgraph;
                        shape = 'plain';
                        fillColor = 'transparent';
                        fontsize = 14;
                        fontname = 'Segoe Ui'
                    }
                }
                # Create SubTenant Node
                if ($CloudConnectTenantRRSubTenantSubgraphNode) {
                    Node 'TenantBackupStorageSubTenant' -Attributes @{
                        Label = $CloudConnectTenantRRSubTenantSubgraphNode;
                        shape = 'plain';
                        fillColor = 'transparent';
                        fontsize = 14;
                        fontname = 'Segoe Ui'
                    }

                    Edge -From 'TenantBackupStorage' -To 'TenantBackupStorageSubTenant' -Attributes @{
                        color = $Edgecolor;
                        style = 'dashed';
                        fontname = 'Segoe Ui';
                        fontsize = 14
                        arrowtail = 'dot';
                        arrowhead = 'dot';
                        minlen = 2;
                    }
                }

            }

            # Create Tenant Replica Resources Node
            if ($CCReplicaResourcesObj = $CCPerTenantInfo.ReplicationResources.HardwarePlanOptions) {
                $CloudResourcesSubgraphNode = @()
                $CloudConnectTenantRRArraySubgraph = @()

                $CloudConnectTenantRRNetworkExtensionArray = @()


                foreach ($CCReplicaResourcesInfo in $CCReplicaResourcesObj) {
                    if ($CCReplicaResourcesInfo.Name) {
                        $CloudConnectTenantReplicaResourceArray = @()
                        $CloudConnectTenantRRArray = @()

                        $CloudConnectTenantReplicaResourceArray += $CCReplicaResourcesInfo.Label

                        try {
                            if (($CCReplicaResourcesInfo.Host | Measure-Object).Count -le 5) {
                                $CCReplicaResourcesInfocolumnSize = ($CCReplicaResourcesInfo.Host | Measure-Object).Count
                            } elseif ($ColumnSize) {
                                $CCReplicaResourcesInfocolumnSize = $ColumnSize
                            } else {
                                $CCReplicaResourcesInfocolumnSize = 5
                            }

                            if ($CCReplicaResourcesInfo.Host) {
                                $CCRRHostNode = Add-DiaHtmlNodeTable -Name 'CCRRHostNode' -ImagesObj $Images -inputObject $CCReplicaResourcesInfo.Host.Name -Align 'Center' -iconType $CCReplicaResourcesInfo.Host.IconType -ColumnSize $CCReplicaResourcesInfocolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCReplicaResourcesInfo.Host.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Cloud_Connect_VM' -SubgraphLabel 'Host or Cluster' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                                $CloudConnectTenantRRArray += $CCRRHostNode
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CCRRHostNode Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        try {
                            if (($CCReplicaResourcesInfo.Storage | Measure-Object).Count -le 5) {
                                $CCReplicaResourcesInfocolumnSize = ($CCReplicaResourcesInfo.Storage | Measure-Object).Count
                            } elseif ($ColumnSize) {
                                $CCReplicaResourcesInfocolumnSize = $ColumnSize
                            } else {
                                $CCReplicaResourcesInfocolumnSize = 5
                            }

                            if ($CCReplicaResourcesInfo.Storage) {
                                $CCRRStorageNode = Add-DiaHtmlNodeTable -Name 'CCRRStorageNode' -ImagesObj $Images -inputObject $CCReplicaResourcesInfo.Storage.Name -Align 'Center' -iconType 'VBR_Cloud_Repository' -ColumnSize $CCReplicaResourcesInfocolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCReplicaResourcesInfo.Storage.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Cloud_Repository' -SubgraphLabel 'Storage' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                                $CloudConnectTenantRRArray += $CCRRStorageNode
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CCRRStorageNode Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        if ($CCReplicaResourcesInfo.WanAcceleration) {
                            if (($CCReplicaResourcesInfo.WanAcceleration | Measure-Object).Count -le 5) {
                                $CCRRWancolumnSize = ($CCReplicaResourcesInfo.WanAcceleration | Measure-Object).Count
                            } elseif ($ColumnSize) {
                                $CCRRWancolumnSize = $ColumnSize
                            } else {
                                $CCRRWancolumnSize = 5
                            }
                            try {
                                $CCCloudWanAcceleratorNode = Add-DiaHtmlNodeTable -Name 'CCCloudWanAcceleratorNode' -ImagesObj $Images -inputObject $CCReplicaResourcesInfo.WanAcceleration.Name -Align 'Center' -iconType $CCReplicaResourcesInfo.WanAcceleration.IconType -ColumnSize $CCRRWancolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCReplicaResourcesInfo.WanAcceleration.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Wan_Accel' -SubgraphLabel 'Wan Accelerators' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                                if ($CCCloudWanAcceleratorNode) {
                                    $CloudConnectTenantRRArray += $CCCloudWanAcceleratorNode
                                }
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create CCCloudWanAcceleratorNode Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                        }

                        try {
                            if ($CloudConnectTenantRRArray) {
                                if (($CloudConnectTenantRRArray | Measure-Object).Count -le 5) {
                                    $CloudConnectTenantRRArraycolumnSize = ($CloudConnectTenantRRArray | Measure-Object).Count
                                } elseif ($ColumnSize) {
                                    $CloudConnectTenantRRArraycolumnSize = $ColumnSize
                                } else {
                                    $CloudConnectTenantRRArraycolumnSize = 5
                                }
                                $CloudConnectTenantRRSubGraph = Add-DiaHtmlSubGraph -Name 'CloudConnectTenantRRSubGraph' -ImagesObj $Images -TableArray $CloudConnectTenantRRArray -Align 'Center' -IconDebug $IconDebug -Label 'Resources' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $CloudConnectTenantRRArraycolumnSize -FontSize 22 -FontBold

                                if ($CloudConnectTenantRRSubGraph) {
                                    $CloudConnectTenantReplicaResourceArray += $CloudConnectTenantRRSubGraph
                                }

                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CloudConnectTenantRRSubGraph SubGraph Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        try {
                            if ($CloudConnectTenantReplicaResourceArray) {
                                $CloudConnectTenantRRArraySubgraph += Add-DiaHtmlSubGraph -Name 'CloudConnectTenantRRArraySubgraph' -ImagesObj $Images -TableArray $CloudConnectTenantReplicaResourceArray -Align 'Center' -IconDebug $IconDebug -Label $CCReplicaResourcesInfo.Name -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 22 -FontBold
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CCRRNode Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        if ($CCReplicaResourcesInfo.NetworkExtensions) {
                            if (($CCReplicaResourcesInfo.NetworkExtensions.Name | Measure-Object).Count -le 5) {
                                $CCRRNetExtcolumnSize = ($CCReplicaResourcesInfo.NetworkExtensions.name | Measure-Object).Count
                            } elseif ($ColumnSize) {
                                $CCRRNetExtcolumnSize = $ColumnSize
                            } else {
                                $CCRRNetExtcolumnSize = 5
                            }
                            try {
                                $CCCloudNetworkExtensionsNode = Add-DiaHtmlNodeTable -Name 'CCCloudNetworkExtensionsNode' -ImagesObj $Images -inputObject $CCReplicaResourcesInfo.NetworkExtensions.Name -Align 'Center' -iconType $CCReplicaResourcesInfo.NetworkExtensions.IconType -ColumnSize $CCRRNetExtcolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCReplicaResourcesInfo.NetworkExtensions.AditionalInfo -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                                if ($CCCloudNetworkExtensionsNode) {
                                    $CloudConnectTenantRRNetworkExtensionArray += $CCCloudNetworkExtensionsNode
                                }
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create CCCloudNetworkExtensionsNode Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                        }
                    }
                }

                if ($CloudConnectTenantRRNetworkExtensionArray) {
                    try {
                        $CloudConnectTenantRRNExtensionSubgraphNode = Add-DiaHtmlSubGraph -Name 'CloudConnectTenantRRNExtensionSubgraphNode' -ImagesObj $Images -TableArray $CloudConnectTenantRRNetworkExtensionArray -Align 'Center' -IconDebug $IconDebug -Label 'Network Extension Appliances' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 4 -FontSize 22 -IconType 'VBR_Hardware_Resources' -FontBold
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create Cloud Resource SubGraph Nodes Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                try {
                    $CloudResourcesSubgraphNode = Add-DiaHtmlSubGraph -Name 'CloudResourcesSubgraphNode' -ImagesObj $Images -TableArray $CloudConnectTenantRRArraySubgraph -Align 'Center' -IconDebug $IconDebug -Label 'Replica Resources' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 4 -FontSize 22 -IconType 'VBR_Hardware_Resources' -FontBold
                } catch {
                    Write-PScriboMessage 'Error: Unable to create Cloud Resource SubGraph Nodes Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($CloudResourcesSubgraphNode) {
                    Node 'TenantReplicaResources' -Attributes @{
                        Label = $CloudResourcesSubgraphNode;
                        shape = 'plain';
                        fillColor = 'transparent';
                        fontsize = 14;
                        fontname = 'Segoe Ui'
                    }
                }

                if ($CloudConnectTenantRRNExtensionSubgraphNode) {
                    Node 'TenantReplicaResourcesNetworkExtension' -Attributes @{
                        Label = $CloudConnectTenantRRNExtensionSubgraphNode;
                        shape = 'plain';
                        fillColor = 'transparent';
                        fontsize = 14;
                        fontname = 'Segoe Ui'
                    }

                    Edge -From 'TenantReplicaResources' -To 'TenantReplicaResourcesNetworkExtension' -Attributes @{
                        color = $Edgecolor;
                        style = 'dashed';
                        fontname = 'Segoe Ui';
                        fontsize = 14
                        arrowtail = 'dot';
                        arrowhead = 'dot';
                        minlen = 3;
                    }
                }
            }


            # Create Tenant vCD Replica Resources Node
            if ($CCvCDReplicaResourcesObj = $CCPerTenantInfo.vCDReplicationResources.OrganizationvDCOptions) {
                $CloudvCDResourcesSubgraphNode = @()
                $CloudConnectTenantvCDRRArraySubgraph = @()

                $CloudConnectTenantvCDRRNetworkExtensionArray = @()


                foreach ($CCvCDReplicaResourcesInfo in $CCvCDReplicaResourcesObj) {
                    $CloudConnectTenantvCDReplicaResourceArray = @()
                    $CloudConnectTenantvCDRRArray = @()

                    $CloudConnectTenantvCDReplicaResourceArray += $CCvCDReplicaResourcesInfo.Label

                    if ($CCvCDReplicaResourcesInfo.WanAcceleration) {
                        if (($CCvCDReplicaResourcesInfo.WanAcceleration | Measure-Object).Count -le 5) {
                            $CCvCDRRWancolumnSize = ($CCvCDReplicaResourcesInfo.WanAcceleration | Measure-Object).Count
                        } elseif ($ColumnSize) {
                            $CCvCDRRWancolumnSize = $ColumnSize
                        } else {
                            $CCvCDRRWancolumnSize = 5
                        }
                        try {
                            $CCCloudvCDWanAcceleratorNode = Add-DiaHtmlNodeTable -Name 'CCCloudvCDWanAcceleratorNode' -ImagesObj $Images -inputObject $CCvCDReplicaResourcesInfo.WanAcceleration.Name -Align 'Center' -iconType $CCvCDReplicaResourcesInfo.WanAcceleration.IconType -ColumnSize $CCvCDRRWancolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCvCDReplicaResourcesInfo.WanAcceleration.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Wan_Accel' -SubgraphLabel 'Wan Accelerators' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                            if ($CCCloudvCDWanAcceleratorNode) {
                                $CloudConnectTenantvCDRRArray += $CCCloudvCDWanAcceleratorNode
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CCCloudvCDWanAcceleratorNode Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }
                    }

                    try {
                        if ($CloudConnectTenantvCDRRArray) {
                            if (($CloudConnectTenantvCDRRArray | Measure-Object).Count -le 5) {
                                $CloudConnectTenantvCDRRArraycolumnSize = ($CloudConnectTenantvCDRRArray | Measure-Object).Count
                            } elseif ($ColumnSize) {
                                $CloudConnectTenantvCDRRArraycolumnSize = $ColumnSize
                            } else {
                                $CloudConnectTenantvCDRRArraycolumnSize = 5
                            }
                            $CloudConnectTenantvCDRRSubGraph = Add-DiaHtmlSubGraph -Name 'CloudConnectTenantvCDRRSubGraph' -ImagesObj $Images -TableArray $CloudConnectTenantvCDRRArray -Align 'Center' -IconDebug $IconDebug -Label 'Resources' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $CloudConnectTenantvCDRRArraycolumnSize -FontSize 22 -FontBold

                            if ($CloudConnectTenantvCDRRSubGraph) {
                                $CloudConnectTenantvCDReplicaResourceArray += $CloudConnectTenantvCDRRSubGraph
                            }

                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CloudConnectTenantvCDRRSubGraph SubGraph Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }

                    try {
                        if ($CloudConnectTenantvCDReplicaResourceArray) {
                            $CloudConnectTenantvCDRRArraySubgraph += Add-DiaHtmlSubGraph -Name 'CloudConnectTenantvCDReplicaResourceArray' -ImagesObj $Images -TableArray $CloudConnectTenantvCDReplicaResourceArray -Align 'Center' -IconDebug $IconDebug -Label $CCvCDReplicaResourcesInfo.Name -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 22 -FontBold

                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CloudConnectTenantvCDRRArraySubgraph Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }

                    if ($CCvCDReplicaResourcesInfo.NetworkExtensions) {
                        if (($CCvCDReplicaResourcesInfo.NetworkExtensions.Name | Measure-Object).Count -le 5) {
                            $CCvCDRRNetExtcolumnSize = ($CCvCDReplicaResourcesInfo.NetworkExtensions.Name | Measure-Object).Count
                        } elseif ($ColumnSize) {
                            $CCvCDRRNetExtcolumnSize = $ColumnSize
                        } else {
                            $CCvCDRRNetExtcolumnSize = 5
                        }
                        try {
                            $CCCloudvCDNetworkExtensionsNode = Add-DiaHtmlNodeTable -Name 'CCCloudvCDNetworkExtensionsNode' -ImagesObj $Images -inputObject $CCvCDReplicaResourcesInfo.NetworkExtensions.Name -Align 'Center' -iconType $CCvCDReplicaResourcesInfo.NetworkExtensions.IconType -ColumnSize $CCvCDRRNetExtcolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCvCDReplicaResourcesInfo.NetworkExtensions.AditionalInfo -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold

                            if ($CCCloudvCDNetworkExtensionsNode) {
                                $CloudConnectTenantvCDRRNetworkExtensionArray += $CCCloudvCDNetworkExtensionsNode
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CCCloudvCDNetworkExtensionsNode Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }
                    }
                }

                if ($CloudConnectTenantvCDRRNetworkExtensionArray) {
                    try {
                        $CloudConnectTenantvCDRRNExtensionSubgraphNode = Add-DiaHtmlSubGraph -Name 'CloudConnectTenantvCDRRNExtensionSubgraphNode' -ImagesObj $Images -TableArray $CloudConnectTenantvCDRRNetworkExtensionArray -Align 'Center' -IconDebug $IconDebug -Label 'Network Extension Appliances' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 4 -FontSize 22 -IconType 'VBR_Hardware_Resources' -FontBold
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CloudvCDRRNExtensionSubgraphNode Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                try {
                    $CloudvCDResourcesSubgraphNode = Add-DiaHtmlSubGraph -Name 'CloudvCDResourcesSubgraphNode' -ImagesObj $Images -TableArray $CloudConnectTenantvCDRRArraySubgraph -Align 'Center' -IconDebug $IconDebug -Label 'vDC Replica Resources' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 4 -FontSize 22 -IconType 'VBR_Hardware_Resources' -FontBold
                } catch {
                    Write-PScriboMessage 'Error: Unable to create CloudvCDResourcesSubgraphNode Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($CloudvCDResourcesSubgraphNode) {
                    Node 'TenantReplicaResources' -Attributes @{
                        Label = $CloudvCDResourcesSubgraphNode;
                        shape = 'plain';
                        fillColor = 'transparent';
                        fontsize = 14;
                        fontname = 'Segoe Ui'
                    }
                }

                if ($CloudConnectTenantvCDRRNExtensionSubgraphNode) {
                    Node 'TenantReplicaResourcesNetworkExtension' -Attributes @{
                        Label = $CloudConnectTenantvCDRRNExtensionSubgraphNode;
                        shape = 'plain';
                        fillColor = 'transparent';
                        fontsize = 14;
                        fontname = 'Segoe Ui'
                    }

                    Edge -From 'TenantReplicaResources' -To 'TenantReplicaResourcesNetworkExtension' -Attributes @{
                        color = $Edgecolor;
                        style = 'dashed';
                        fontname = 'Segoe Ui';
                        fontsize = 14
                        arrowtail = 'dot';
                        arrowhead = 'dot';
                        minlen = 3;
                    }
                }
            }

            if (($CloudResourcesSubgraphNode -or $CloudvCDResourcesSubgraphNode) -and $CloudRepoSubgraph) {
                Rank 'TenantBackupStorage', 'TenantBackupStorageConnector'
                Rank 'TenantReplicaResources', 'TenantReplicaResourcesConnector'
                # Create Edge Connector Nodes
                Add-DiaInvertedTShapeLine -InvertedTStart 'TenantBackupStorageConnector' -InvertedTStartLineLength 5 -InvertedTMiddleTop 'TenantGatewayConnector' -InvertedTEndLineLength 5 -LineColor $Edgecolor -LineStyle 'dashed' -IconDebug $IconDebug -LineWidth $EdgeLineWidth -InvertedTEnd 'TenantReplicaResourcesConnector'

                Edge -From 'TenantReplicaResourcesConnector' -To 'TenantReplicaResources' -Attributes @{
                    color = $Edgecolor;
                    style = 'dashed';
                    fontname = 'Segoe Ui';
                    fontsize = 14
                    arrowtail = 'none';
                    arrowhead = 'dot';
                }
                Edge -From 'TenantBackupStorage' -To 'TenantBackupStorageConnector' -Attributes @{
                    color = $Edgecolor;
                    style = 'dashed';
                    fontname = 'Segoe Ui';
                    fontsize = 14
                    arrowtail = 'dot';
                    arrowhead = 'none';
                }
            } elseif ($CloudResourcesSubgraphNode -or $CloudvCDResourcesSubgraphNode) {
                # Create Edge Connector Nodes
                Add-DiaVerticalLine -VStart 'TenantGatewayConnector' -VEnd 'TenantReplicaResourcesConnector' -LineColor $Edgecolor -LineStyle 'dashed' -IconDebug $IconDebug -LineWidth $EdgeLineWidth

                Edge -From 'TenantReplicaResourcesConnector' -To 'TenantReplicaResources' -Attributes @{
                    color = $Edgecolor;
                    style = 'dashed';
                    fontname = 'Segoe Ui';
                    fontsize = 14
                    arrowtail = 'none';
                    arrowhead = 'dot';
                }
            } elseif ($CloudRepoSubgraph) {
                # Create Edge Connector Nodes
                Add-DiaVerticalLine -VStart 'TenantGatewayConnector' -VEnd 'TenantBackupStorageConnector' -LineColor $Edgecolor -LineStyle 'dashed' -IconDebug $IconDebug -LineWidth $EdgeLineWidth

                Edge -From 'TenantBackupStorageConnector' -To 'TenantBackupStorage' -Attributes @{
                    color = $Edgecolor;
                    style = 'dashed';
                    fontname = 'Segoe Ui';
                    fontsize = 14
                    arrowtail = 'none';
                    arrowhead = 'dot';
                }
            }
        }
    }
    end {}
}