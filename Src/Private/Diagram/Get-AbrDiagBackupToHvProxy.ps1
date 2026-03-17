function Get-AbrDiagBackupToHvProxy {
    <#
    .SYNOPSIS
        Function to build Backup Server to Proxy diagram.
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
        try {
            $HyperVBackupProxy = Get-AbrBackupProxyInfo -Type 'hyperv'
            if ($HyperVBackupProxy) {

                if ($HyperVBackupProxy.Name.Count -eq 1) {
                    $HyperVBackupProxyColumnSize = 1
                } elseif ($ColumnSize) {
                    $HyperVBackupProxyColumnSize = $ColumnSize
                } else {
                    $HyperVBackupProxyColumnSize = $HyperVBackupProxy.Name.Count
                }

                Node HvProxies @{Label = (Add-HtmlNodeTable -Name 'HvProxies' -ImagesObj $Images -inputObject ($HyperVBackupProxy | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Proxy_Server' -ColumnSize $HyperVBackupProxyColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $HyperVBackupProxy.AditionalInfo -Subgraph -SubgraphIconType 'VBR_HyperV' -SubgraphLabel 'Hyper-V Backup Proxies' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor '#000000' -SubgraphLabelFontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder '1' -FontSize 18 -SubgraphLabelFontSize 22 -SubgraphFontBold); shape = 'plain'; fontsize = 18; fontname = 'Segoe Ui' }

                Edge BackupServers -To HvProxies @{minlen = 3 }
            }

            # Hyper-V Graphviz Cluster
            if ($vSphereObj = Get-AbrBackupHyperVClusterInfo | Sort-Object) {
                $VivCenterNodes = @()
                $VivCenterNodesAll = @()
                foreach ($vCenter in $vSphereObj) {
                    $vCenterNodeArray = @()
                    $ViClustersNodes = @()
                    $vCenterNodeArray += $vCenter.Label

                    try {
                        if ($vCenter.Childs.Name.Count -eq 1) {
                            $HyperVBackupProxyColumnSize = 1
                        } elseif ($ColumnSize) {
                            $HyperVBackupProxyColumnSize = $ColumnSize
                        } else {
                            $HyperVBackupProxyColumnSize = $vCenter.Childs.Name.Count
                        }

                        $ViClustersChildsNodes = Add-HtmlTable -Name 'ViClustersChildsNodes' -ImagesObj $Images -Rows $vCenter.Childs.Name -ALIGN 'Center' -ColumnSize $HyperVBackupProxyColumnSize -IconDebug $IconDebug -FontColor '#000000' -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 0 -NoFontBold -FontSize 18 -SubgraphFontBold

                    } catch {
                        Write-PScriboMessage 'Error: Unable to create Hyper-V Hosts table Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    try {
                        if ($ViClustersChildsNodes) {
                            if ($ViClustersChildsNodes.Count -eq 1) {
                                $ViClustersNodesColumnSize = 1
                            } elseif ($ColumnSize) {
                                $ViClustersNodesColumnSize = $ColumnSize
                            } else {
                                $ViClustersNodesColumnSize = $ViClustersChildsNodes.Count
                            }
                            $ViClustersNodes += Add-HtmlSubGraph -Name 'ViClustersNodes' -ImagesObj $Images -TableArray $ViClustersChildsNodes -Align 'Center' -IconDebug $IconDebug -Label 'Hosts' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $ViClustersNodesColumnSize -FontSize 18 -FontBold
                            $vCenterNodeArray += $ViClustersNodes
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create Hyper-V Hosts Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    try {
                        if ($vCenterNodeArray) {
                            $VivCenterNodes += Add-HtmlSubGraph -Name 'VivCenterNodes' -ImagesObj $Images -TableArray $vCenterNodeArray -Align 'Center' -IconDebug $IconDebug -Label 'Cluster Servers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 20 -FontBold
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create Hyper-V Cluster Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                try {
                    if ($vCenterNodeArray) {
                        if ($VivCenterNodes.Count -eq 1) {
                            $VivCenterNodesAllColumnSize = 1
                        } elseif ($ColumnSize) {
                            $VivCenterNodesAllColumnSize = $ColumnSize
                        } else {
                            $VivCenterNodesAllColumnSize = $VivCenterNodes.Count
                        }
                        $VivCenterNodesAll += Add-HtmlSubGraph -Name 'VivCenterNodesAll' -ImagesObj $Images -TableArray $VivCenterNodes -Align 'Center' -IconDebug $IconDebug -Label 'Hyper-V Clusters' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $VivCenterNodesAllColumnSize -FontSize 22 -FontBold
                    }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create Hyper-V Cluster Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }

            if ($HyperVServerObj = Get-AbrBackupHyperVStandAloneInfo | Sort-Object) {

                if ($HyperVServerObj.Name.Count -eq 1) {
                    $HyperVServerObjColumnSize = 1
                } elseif ($ColumnSize) {
                    $HyperVServerObjColumnSize = $ColumnSize
                } else {
                    $HyperVServerObjColumnSize = $HyperVServerObj.Name.Count
                }

                try {

                    $ViStandAloneNodes = Add-HtmlNodeTable -Name 'ViStandAloneNodes' -ImagesObj $Images -inputObject ($HyperVServerObj | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_HyperV_Server' -ColumnSize $HyperVServerObjColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $HyperVServerObj.AditionalInfo -Subgraph -SubgraphLabel ' ' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder '1' -FontBold
                } catch {
                    Write-PScriboMessage 'Error: Unable to create Hyper-V StandAlone Hosts Table. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($ViStandAloneNodes) {
                    try {
                        $VivCenterNodesAll += Add-HtmlSubGraph -Name 'ViStandAloneNodes' -ImagesObj $Images -TableArray $ViStandAloneNodes -Align 'Center' -IconDebug $IconDebug -Label 'Hyper-V StandAlone Hosts' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 22 -FontBold
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create Hyper-V StandAlone Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
            }

            if ($VivCenterNodesAll) {

                if ($Dir -eq 'LR') {
                    try {
                        $ViClustersSubgraphNode = Node -Name 'HvCluster' -Attributes @{Label = (Add-HtmlSubGraph -Name 'HvCluster' -ImagesObj $Images -TableArray $VivCenterNodesAll -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_HyperV' -Label 'Microsoft Hyper-V Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 24 -FontBold); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create HvCluster Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                } else {
                    try {
                        $ViClustersSubgraphNode = Node -Name 'HvCluster' -Attributes @{Label = (Add-HtmlSubGraph -Name 'HvCluster' -ImagesObj $Images -TableArray $VivCenterNodesAll -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_HyperV' -Label 'Microsoft Hyper-V Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 24 -FontBold); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create HvCluster Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                if ($ViClustersSubgraphNode) {
                    $ViClustersSubgraphNode
                    if ($HyperVBackupProxy) {
                        Edge HvProxies -To HvCluster @{minlen = 2 }
                    } else {
                        Edge BackupServers -To HvCluster @{minlen = 3 }
                    }
                }
            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}