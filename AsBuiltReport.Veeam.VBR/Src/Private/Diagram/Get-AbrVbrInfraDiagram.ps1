function Get-AbrInfraDiagram {
    <#
    .SYNOPSIS
        Generates a diagram of the Veeam Backup & Replication infrastructure configuration in various formats using PSGraph and Graphviz.
    .DESCRIPTION
        This script creates a visual representation of the Veeam Backup & Replication infrastructure configuration. The output can be generated in PDF, SVG, DOT, or PNG formats. It leverages the PSGraph module for PowerShell and Graphviz for rendering the diagrams.
    .NOTES
        Version:        1.0.0
        Author(s):      Jonathan Colon
        Twitter:        @jcolonfzenpr
        GitHub:         rebelinux
        Credits:        Kevin Marquette (@KevinMarquette) - PSGraph module
                        Prateek Singh (@PrateekKumarSingh) - AzViz module
    .LINK
        GitHub Repository: https://github.com/rebelinux/
        PSGraph Module:    https://github.com/KevinMarquette/PSGraph
        AzViz Module:      https://github.com/PrateekKumarSingh/AzViz
    #>

    begin {
        Write-PScriboMessage "Collecting Backup Infrastructure information from $($VBRServer)."
    }

    process {
        if ($VBRServer) {

            #-----------------------------------------------------------------------------------------------#
            #                                Graphviz Node Section                                          #
            #                 Nodes are Graphviz elements used to define an object entity                   #
            #                Nodes can have attributes like Shape, HTML Labels, Styles, etc.                #
            #               PSGraph: https://psgraph.readthedocs.io/en/latest/Command-Node/                 #
            #                     Graphviz: https://graphviz.org/doc/info/shapes.html                       #
            #-----------------------------------------------------------------------------------------------#

            # EntraID Graphviz Cluster
            if ($EntraID = Get-AbrBackupEntraIDInfo) {
                try {
                    $EntraIDNode = Node EntraID @{Label = (Add-HtmlNodeTable -Name 'EntraIDNode' -ImagesObj $Images -inputObject $EntraID.Name -Align 'Center' -iconType 'VBR_Microsoft_Entra_ID' -ColumnSize 2 -IconDebug $IconDebug -MultiIcon -AditionalInfo $EntraID.AditionalInfo -Subgraph -SubgraphLabel 'Entra ID Tenants' -SubgraphFontBold -SubgraphLabelPos 'top' -SubgraphIconType 'VBR_Microsoft_Entra_ID' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontColor $FontColor -SubgraphLabelFontSize 22 -FontSize 18 -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor); shape = 'plain'; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create EntraID Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }
            if ($EntraID -and $EntraIDNode) {
                $EntraIDNode
            }

            # Proxy Graphviz Cluster
            if ($Proxies = Get-AbrProxyInfo) {

                try {
                    if (($Proxies | Where-Object { $_.AditionalInfo.Type -eq 'vSphere' }).Name) {
                        $ProxiesVi = Add-HtmlNodeTable -Name 'ProxiesVi' -ImagesObj $Images -inputObject (($Proxies | Where-Object { $_.AditionalInfo.Type -eq 'vSphere' }) | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Proxy_Server' -ColumnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo ($Proxies.AditionalInfo | Where-Object { $_.Type -eq 'vSphere' }) -Subgraph -SubgraphIconType 'VBR_vSphere' -SubgraphLabel 'VMware Proxies' -SubgraphLabelPos 'top' -FontColor $FontColor -SubgraphLabelFontColor $FontColor -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                    }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create ProxiesVSphere Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                try {
                    if (($Proxies | Where-Object { $_.AditionalInfo.Type -eq 'Off host' -or $_.AditionalInfo.Type -eq 'On host' }).Name) {
                        $ProxiesHv = Add-HtmlNodeTable -Name 'ProxiesHv' -ImagesObj $Images -inputObject (($Proxies | Where-Object { $_.AditionalInfo.Type -eq 'Off host' -or $_.AditionalInfo.Type -eq 'On host' }).Name | ForEach-Object { $_.split('.')[0] }) -Align 'Center' -iconType 'VBR_Proxy_Server' -ColumnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo ($Proxies.AditionalInfo | Where-Object { $_.Type -eq 'Off host' -or $_.Type -eq 'On host' }) -Subgraph -SubgraphIconType 'VBR_HyperV' -SubgraphLabel 'Hyper-V Proxies' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $FontColor -SubgraphLabelFontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                    }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create ProxiesHyperV Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($NASProxies = Get-AbrNASProxyInfo) {
                    try {
                        $ProxiesNas = Add-HtmlNodeTable -Name 'ProxiesNas' -ImagesObj $Images -inputObject (($NASProxies).Name | ForEach-Object { $_.split('.')[0] }) -Align 'Center' -iconType 'VBR_Proxy_Server' -ColumnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo ($NASProxies.AditionalInfo) -Subgraph -SubgraphIconType 'VBR_NAS' -SubgraphLabel 'NAS Proxies' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $FontColor -SubgraphLabelFontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create ProxiesNas Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
            }

            if ($Proxies -and ($ProxiesVi -or $ProxiesHv -or $ProxiesNas)) {

                $ProxyNodesArray = @()

                if ($ProxiesVi) {
                    $ProxyNodesArray += $ProxiesVi
                }
                if ($ProxiesHv) {
                    $ProxyNodesArray += $ProxiesHv
                }
                if ($NASProxies) {
                    $ProxyNodesArray += $ProxiesNas
                }

                try {
                    $ProxiesSubgraphNode = Node -Name 'Proxies' -Attributes @{Label = (Add-HtmlSubGraph -Name 'Proxies' -ImagesObj $Images -TableArray $ProxyNodesArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Proxy' -Label 'Backup Proxies' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 3 -FontSize 24 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create Proxies SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($ProxiesSubgraphNode) {
                    $ProxiesSubgraphNode
                }

            } else {
                SubGraph ProxyServer -Attributes @{Label = (Add-HtmlLabel -Name 'ProxyServer' -ImagesObj $Images -Label 'Backup Proxies' -IconType 'VBR_Proxy' -SubgraphLabel -IconDebug $IconDebug -FontBold -TableBackgroundColor $MainGraphBGColor -FontColor $FontColor); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                    Node -Name Proxies -Attributes @{Label = 'No Backup Proxies'; shape = 'rectangle'; labelloc = 'c'; fixedsize = $true; width = '3'; height = '2'; penwidth = 0 }
                }
            }

            # vSphere Graphviz Cluster
            $vSphereObj = Get-AbrBackupvSphereInfo | Sort-Object
            if ($vSphereObj) {
                $VivCenterNodes = @()
                foreach ($vCenter in $vSphereObj) {
                    $vCenterNodeArray = @()
                    $ViClustersNodes = @()
                    $vCenterNodeArray += $vCenter.Label
                    try {
                        $ViClustersChildsNodes = foreach ($ViCluster in $vCenter.Childs) {
                            if ($ViCluster.EsxiHost.Name) {
                                Add-HtmlTable -Name 'ViClustersChildsNodes' -ImagesObj $Images -Rows $ViCluster.EsxiHost.Name -ALIGN 'Center' -ColumnSize 3 -IconDebug $IconDebug -Subgraph -SubgraphIconType 'VBR_ESXi_Server' -SubgraphLabel $ViCluster.Name -SubgraphLabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 1 -FontSize 22 -SubgraphFontBold -NoFontBold -SubgraphTableStyle 'dashed,rounded' -TableBackgroundColor $MainGraphBGColor
                            } else {
                                Add-HtmlTable -Name 'ViClustersChildsNodes' -ImagesObj $Images -Rows 'No Esxi Host' -ALIGN 'Center' -ColumnSize 3 -IconDebug $IconDebug -Subgraph -SubgraphIconType 'VBR_ESXi_Server' -SubgraphLabel $ViCluster.Name -SubgraphLabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 1 -FontSize 22 -NoFontBold -SubgraphFontBold -SubgraphTableStyle 'dashed,rounded' -TableBackgroundColor $MainGraphBGColor
                            }
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create vSphere Esxi table Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    try {
                        if ($ViClustersChildsNodes) {
                            if ($ViClustersChildsNodes.count -le 5) {
                                $columnSize = $ViClustersChildsNodes.count
                            } else {
                                $columnSize = 5
                            }
                            $ViClustersNodes += Add-HtmlSubGraph -Name 'ViClustersNodes' -ImagesObj $Images -TableArray $ViClustersChildsNodes -Align 'Center' -IconDebug $IconDebug -Label 'vSphere Clusters' -LabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $columnSize -FontSize 22 -FontBold -TableBackgroundColor $MainGraphBGColor
                            $vCenterNodeArray += $ViClustersNodes
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create vSphere Clusters Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    try {
                        if ($vCenterNodeArray) {
                            $VivCenterNodes += Add-HtmlSubGraph -Name 'VivCenterNodes' -ImagesObj $Images -TableArray $vCenterNodeArray -Align 'Center' -IconDebug $IconDebug -Label 'vCenter Server' -LabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 22 -FontBold -TableBackgroundColor $MainGraphBGColor
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create vCenter Server Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                if ($VivCenterNodes) {
                    $columnSize = & {
                        if (($VivCenterNodes | Measure-Object).count -le 1 ) {
                            return 1
                        } else {
                            return 4
                        }
                    }
                    try {
                        $ViClustersSubgraphNode = Add-HtmlSubGraph -Name 'ViClustersSubgraphNode' -ImagesObj $Images -TableArray $VivCenterNodes -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_vSphere' -Label 'VMware vSphere Infrastructure' -LabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $columnSize -FontSize 24 -FontBold -TableBackgroundColor $MainGraphBGColor
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create ViCluster Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                if ($vSphereServerObj = Get-AbrBackupvSphereStandAloneInfo | Sort-Object) {

                    $columnSize = & {
                        if (($vSphereServerObj | Measure-Object).count -le 1 ) {
                            return 1
                        } else {
                            return 4
                        }
                    }

                    try {
                        [array]$ViStandAloneNodes = (Add-HtmlNodeTable -Name 'ViStandAloneNodes' -ImagesObj $Images -inputObject ($vSphereServerObj | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_ESXi_Server' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $vSphereServerObj.AditionalInfo -Subgraph -SubgraphLabel ' ' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -FontBold -FontColor $FontColor -SubgraphLabelFontColor $FontColor -FontSize 22 -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor)
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create vSphere StandAlone Table. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }

                    if ($ViStandAloneNodes) {
                        try {
                            $ViStandAloneSubgraph += Add-HtmlSubGraph -Name 'ViStandAloneSubgraph' -ImagesObj $Images -TableArray $ViStandAloneNodes -Align 'Center' -IconDebug $IconDebug -Label 'ESXi StandAlone Hosts' -LabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $columnSize -FontSize 24 -FontBold -TableBackgroundColor $MainGraphBGColor
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create vSphere StandAlone Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }
                    }
                }
            }

            # HyperV Graphviz Cluster
            if ($HyperVObj = Get-AbrBackupHyperVClusterInfo | Sort-Object) {
                $HvHyperVObjNodes = @()
                foreach ($HyperV in $HyperVObj) {
                    $HyperVNodeArray = @()
                    $HvClustersNodes = @()
                    $HyperVNodeArray += $HyperV.Label
                    try {
                        $HvClustersChildsNodes = & {
                            if ($HyperV.Childs.Name) {
                                Add-HtmlTable -Name 'HvClustersChildsNodes' -ImagesObj $Images -Rows $HyperV.Childs.Name -ALIGN 'Center' -ColumnSize 3 -IconDebug $IconDebug -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 0 -NoFontBold -FontSize 22 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor
                            } else {
                                Add-HtmlTable -Name 'HvClustersChildsNodes' -ImagesObj $Images -Rows 'No HyperV Host' -ALIGN 'Center' -ColumnSize $columnSize -IconDebug $IconDebug -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 0 -NoFontBold -FontSize 22 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor
                            }
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create HyperV host table Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    try {
                        if ($HvClustersChildsNodes) {
                            $HvClustersNodes += Add-HtmlSubGraph -Name 'HvClustersNodes' -ImagesObj $Images -TableArray $HvClustersChildsNodes -Align 'Center' -IconDebug $IconDebug -Label 'Hyper-V Servers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 3 -FontSize 22 -FontBold -TableBackgroundColor $MainGraphBGColor
                            $HyperVNodeArray += $HvClustersNodes
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create HyperV Hosts Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    try {
                        if ($HyperVNodeArray) {
                            $HvHyperVObjNodes += Add-HtmlSubGraph -Name 'HvHyperVObjNodes' -ImagesObj $Images -TableArray $HyperVNodeArray -Align 'Center' -IconDebug $IconDebug -Label 'Hyper-V Cluster' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 22 -FontBold -TableBackgroundColor $MainGraphBGColor
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create HyperV Server Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                if ($HvHyperVObjNodes) {
                    try {
                        $HvClustersSubgraphNode = Add-HtmlSubGraph -Name 'HvClustersSubgraphNode' -ImagesObj $Images -TableArray $HvHyperVObjNodes -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_HyperV' -Label 'Microsoft HyperV Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 3 -FontSize 24 -FontBold -TableBackgroundColor $MainGraphBGColor
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create HvCluster Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                if ($HyperVServerObj = Get-AbrBackupHyperVStandAloneInfo | Sort-Object) {

                    $columnSize = & {
                        if (($HyperVServerObj | Measure-Object).count -le 1 ) {
                            return 1
                        } else {
                            return 4
                        }
                    }

                    try {

                        $HvStandAloneNodes = (Add-HtmlNodeTable -Name 'HvStandAloneNodes' -ImagesObj $Images -inputObject ($HyperVServerObj | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_HyperV_Server' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $HyperVServerObj.AditionalInfo -Subgraph -SubgraphLabel ' ' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder '1' -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -SubgraphLabelFontColor $Fontcolor)
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create Hyper-V StandAlone Hosts Table. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }

                    if ($HvStandAloneNodes) {
                        try {
                            $HvStandAloneNodesSubgraph += Add-HtmlSubGraph -Name 'HvStandAloneNodesSubgraph' -ImagesObj $Images -TableArray $HvStandAloneNodes -Align 'Center' -IconDebug $IconDebug -Label 'Hyper-V StandAlone Hosts' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $columnSize -FontSize 22 -FontBold -TableBackgroundColor $MainGraphBGColor
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create Hyper-V StandAlone Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }
                    }
                }
            }

            if ($HvClustersSubgraphNode -or $ViClustersSubgraphNode -or $ViStandAloneSubgraph -or $HvStandAloneNodesSubgraph) {

                $VirtualNodesArray = @()

                if ($vSphereObj) {
                    $VirtualNodesArray += $ViClustersSubgraphNode
                    if ($ViStandAloneSubgraph) {
                        $VirtualNodesArray += $ViStandAloneSubgraph
                    }
                }

                if ($HyperVObj) {
                    $VirtualNodesArray += $HvClustersSubgraphNode
                    if ($HvStandAloneNodesSubgraph) {
                        $VirtualNodesArray += $HvStandAloneNodesSubgraph
                    }
                }

                try {
                    $VirtualNodesArraySubgraphNode = Node -Name 'VirtualInfra' -Attributes @{Label = (Add-HtmlSubGraph -Name 'VirtualInfra' -ImagesObj $Images -TableArray $VirtualNodesArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Proxy' -Label 'Virtual Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 26 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create SureBackup SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($VirtualNodesArraySubgraphNode) {
                    $VirtualNodesArraySubgraphNode
                }

            }

            # Repository Graphviz Cluster
            $OnpremStorageArray = @()

            # SOBR Graphviz Cluster
            if ($SOBR = Get-AbrSOBRInfo) {
                try {
                    if ($SOBR.Name.count -le 5) {
                        $columnSize = $SOBR.Name.count
                    } else {
                        $columnSize = 5
                    }
                    $SOBRNode = Add-HtmlNodeTable -Name 'SOBRNode' -ImagesObj $Images -inputObject $SOBR.Name -Align 'Center' -iconType 'VBR_SOBR_Repo' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $SOBR.AditionalInfo -Subgraph -SubgraphLabel 'Scale-Out Backup Repositories' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphLabelPos top -SubgraphTableStyle 'dashed,rounded' -SubgraphLabelFontColor $Fontcolor -FontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphIconType 'VBR_SOBR' -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                    $OnpremStorageArray += $SOBRNode
                } catch {
                    Write-PScriboMessage 'Error: Unable to create SOBR Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }

            # SAN Infrastructure Graphviz Cluster
            if ($SAN = Get-AbrSANInfo) {
                try {
                    if ($SAN.Name.count -le 5) {
                        $columnSize = $SAN.Name.count
                    } else {
                        $columnSize = 5
                    }
                    $SANNode = Add-HtmlNodeTable -Name 'SANNode' -ImagesObj $Images -inputObject $SAN.Name -Align 'Center' -iconType $SAN.IconType -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $SAN.AditionalInfo -SubgraphLabelFontSize 22 -FontSize 18 -Subgraph -SubgraphLabel 'Storage Infrastructure' -SubgraphLabelPos top -SubgraphTableStyle 'dashed,rounded' -SubgraphLabelFontColor $Fontcolor -FontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphIconType 'VBR_SAN' -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                    $OnpremStorageArray += $SANNode
                } catch {
                    Write-PScriboMessage 'Error: Unable to create SAN Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }
            # Repositories Graphviz Cluster
            if ($RepositoriesInfo = Get-AbrRepositoryInfo) {
                if ($RepositoriesInfo.Name.count -le 5) {
                    $columnSize = $RepositoriesInfo.Name.count
                } else {
                    $columnSize = 5
                }
                try {
                    $RepositoriesNode = Add-HtmlNodeTable -Name 'RepositoriesNode' -ImagesObj $Images -inputObject $RepositoriesInfo.Name -Align 'Center' -iconType $RepositoriesInfo.IconType -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $RepositoriesInfo.AditionalInfo -Subgraph -SubgraphLabel 'Backup Repositories' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphLabelPos top -SubgraphTableStyle 'dashed,rounded' -SubgraphLabelFontColor $FontColor -FontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphIconType 'VBR_Repository' -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                    $OnpremStorageArray += $RepositoriesNode
                } catch {
                    Write-PScriboMessage 'Error: Unable to create Repositories Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }

            if ($OnpremStorageArray) {
                try {
                    $OnpremStorageSubgraphNode = Node -Name 'Repositories' -Attributes @{Label = (Add-HtmlSubGraph -Name 'Repositories' -ImagesObj $Images -TableArray $OnpremStorageArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Proxy' -Label 'On-Premises Storage Infrastructure' -LabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 26 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create OnPremStorage SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }



                if ($OnpremStorageSubgraphNode) {
                    $OnpremStorageSubgraphNode
                }
            }

            # Object Repositories Graphviz Cluster
            if ($ObjectRepositoriesInfo = Get-AbrObjectRepoInfo) {
                if ($ObjectRepositoriesInfo.Name.count -le 5) {
                    $columnSize = $ObjectRepositoriesInfo.Name.count
                } else {
                    $columnSize = 5
                }
                try {
                    $ObjectRepositoriesNode = Add-HtmlNodeTable -Name 'ObjectRepositoriesNode' -ImagesObj $Images -inputObject $ObjectRepositoriesInfo.Name -Align 'Center' -iconType $ObjectRepositoriesInfo.Icontype -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $ObjectRepositoriesInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_vSphere' -SubgraphLabel 'Object Repositories' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -SubgraphLabelFontColor $FontColor -FontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                } catch {
                    Write-PScriboMessage 'Error: Unable to create ObjectRepositories Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }

            # Archive Object Repositories Graphviz Cluster
            if ($ArchObjRepositoriesInfo = Get-AbrArchObjectRepoInfo) {
                if ($ArchObjRepositoriesInfo.Name.count -le 5) {
                    $columnSize = $ArchObjRepositoriesInfo.Name.count
                } else {
                    $columnSize = 5
                }
                try {
                    $ArchObjRepositoriesNode = Add-HtmlNodeTable -Name 'ArchObjRepositoriesNode' -ImagesObj $Images -inputObject $ArchObjRepositoriesInfo.Name -Align 'Center' -iconType $ArchObjRepositoriesInfo.Icontype -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $ArchObjRepositoriesInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_vSphere' -SubgraphLabel 'Archives Object Repositories' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -SubgraphLabelFontColor $FontColor -FontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor
                } catch {
                    Write-PScriboMessage 'Error: Unable to create ArchiveObjectRepositories Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }
            if (($ObjectRepositoriesInfo -or $ArchObjRepositoriesInfo) -and ($ObjectRepositoriesNode -or $ArchObjRepositoriesNode)) {
                $ObjStorageNodeArray = @()

                if ($ObjectRepositoriesNode) {
                    $ObjStorageNodeArray += $ObjectRepositoriesNode
                }

                if ($ArchObjRepositoriesNode) {
                    $ObjStorageNodeArray += $ArchObjRepositoriesNode
                }

                try {
                    $ObjStorageSubgraphNode = Node -Name 'ObjectRepos' -Attributes @{Label = (Add-HtmlSubGraph -Name 'ObjectRepos' -ImagesObj $Images -TableArray $ObjStorageNodeArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Object' -Label 'Object Storage' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 26 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create SureBackup SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($ObjStorageSubgraphNode) {
                    $ObjStorageSubgraphNode
                }
            }

            # WanAccels Graphviz Cluster
            if ($WanAccels = Get-AbrWanAccelInfo) {
                if ($WanAccels.Name.count -le 5) {
                    $columnSize = $WanAccels.Name.count
                } else {
                    $columnSize = 5
                }
                try {
                    $WanAccelsNode = Node WanAccelServer @{Label = (Add-HtmlNodeTable -Name 'WanAccelServer' -ImagesObj $Images -inputObject ($WanAccels | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Wan_Accel' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $WanAccels.AditionalInfo -Subgraph -SubgraphLabel 'Wan Accelerators' -SubgraphLabelPos 'top' -SubgraphIconType 'VBR_Wan_Accel' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor); shape = 'plain'; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create WanAccelerators Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }
            if ($WanAccels -and $WanAccelsNode) {
                $WanAccelsNode
            }

            # Tapes Graphviz Cluster
            $TapeInfraArray = @()

            if ($TapeServerInfo = Get-AbrTapeServersInfo) {
                try {
                    if ($TapeServerInfo.Name.count -le 5) {
                        $columnSize = $TapeServerInfo.Name.count
                    } else {
                        $columnSize = 5
                    }
                    $TapeServerNode = Add-HtmlNodeTable -Name 'TapeServerNode' -ImagesObj $Images -inputObject $TapeServerInfo.Name -Align 'Center' -iconType 'VBR_Tape_Server' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $TapeServerInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Tape_Server' -SubgraphLabel 'Tape Servers' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor

                    $TapeInfraArray += $TapeServerNode
                } catch {
                    Write-PScriboMessage 'Error: Unable to create TapeServers Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
                if ($TapeLibraryInfo = Get-AbrTapeLibraryInfo) {
                    if ($TapeLibraryInfo.Name.count -le 5) {
                        $columnSize = $TapeLibraryInfo.Name.count
                    } else {
                        $columnSize = 5
                    }
                    try {
                        $TapeLibraryNode = Add-HtmlNodeTable -Name 'TapeLibraryNode' -ImagesObj $Images -inputObject $TapeLibraryInfo.Name -Align 'Center' -iconType 'VBR_Tape_Library' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $TapeLibraryInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Tape_Library' -SubgraphLabel 'Tape Libraries' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor

                        $TapeInfraArray += $TapeLibraryNode
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create TapeLibrary Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
                if ($TapeVaultInfo = Get-AbrTapeVaultInfo) {
                    if ($TapeVaultInfo.Name.count -le 5) {
                        $columnSize = $TapeVaultInfo.Name.count
                    } else {
                        $columnSize = 5
                    }
                    try {
                        $TapeVaultNode = Add-HtmlNodeTable -Name 'TapeVaultNode' -ImagesObj $Images -inputObject $TapeVaultInfo.Name -Align 'Center' -iconType 'VBR_Tape_Vaults' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $TapeVaultInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Tape_Vaults' -SubgraphLabel 'Tape Vaults' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor
                        $TapeInfraArray += $TapeVaultNode
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create TapeVault Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
            }
            if ($TapeServerInfo -and $TapeServerNode) {
                try {
                    $TapeServerSubGraph = Node -Name 'TapeInfra' -Attributes @{Label = (Add-HtmlSubGraph -Name 'TapeInfra' -ImagesObj $Images -TableArray $TapeInfraArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Tape' -Label 'Tape Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 24 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create TapeInfra SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($TapeServerSubGraph) {
                    $TapeServerSubGraph
                }
            }

            # ServiceProvider Graphviz Cluster
            if ($ServiceProviderInfo = Get-AbrServiceProviderInfo) {
                try {
                    $ServiceProviderNode = Add-HtmlNodeTable -Name 'ServiceProviderNode' -ImagesObj $Images -inputObject $ServiceProviderInfo.Name -Align 'Center' -iconType 'VBR_Service_Providers_Server' -ColumnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ServiceProviderInfo.AditionalInfo -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor
                } catch {
                    Write-PScriboMessage 'Error: Unable to create ServiceProvider Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }
            }
            if ($ServiceProviderInfo -and $ServiceProviderNode) {

                try {
                    $ServiceProviderSubgraphNode = Node -Name ServiceProviders -Attributes @{Label = (Add-HtmlSubGraph -Name 'ServiceProviders' -ImagesObj $Images -TableArray $ServiceProviderNode -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Service_Providers' -Label 'Service Providers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 2 -FontSize 22 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create ServiceProviders SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($ServiceProviderSubgraphNode) {
                    $ServiceProviderSubgraphNode
                }
            }

            # SureBackup Graphviz Cluster
            if (($VirtualLab = Get-AbrVirtualLabInfo -and ($ApplicationGroups = Get-AbrApplicationGroupsInfo))) {
                if ($VirtualLab) {
                    if ($VirtualLab.Name.count -le 2) {
                        $columnSize = $VirtualLab.Name.count
                    } else {
                        $columnSize = 2
                    }
                    try {
                        $VirtualLabNode = Add-HtmlNodeTable -Name 'VirtualLabNode' -ImagesObj $Images -inputObject $VirtualLab.Name -Align 'Center' -iconType $VirtualLab.IconType -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $VirtualLab.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Virtual_Lab' -SubgraphLabel 'Virtual Labs' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -SubgraphLabelFontColor $Fontcolor
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create VirtualLab Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
                if ($ApplicationGroups) {
                    if ($ApplicationGroups.Name.count -le 2) {
                        $columnSize = $ApplicationGroups.Name.count
                    } else {
                        $columnSize = 2
                    }
                    try {
                        $ApplicationGroupsNode = Add-HtmlNodeTable -Name 'ApplicationGroupsNode' -ImagesObj $Images -inputObject $ApplicationGroups.Name -Align 'Center' -iconType $ApplicationGroups.IconType -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $ApplicationGroups.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Virtual_Lab' -SubgraphLabel 'Application Groups' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -SubgraphLabelFontColor $Fontcolor
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create VirtualLab Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }

                $SureBackupSubgraphNodeArray = @()

                # ApplicationGroups Graphviz Cluster
                if ($ApplicationGroups -and $ApplicationGroupsNode) {

                    $SureBackupSubgraphNodeArray += $ApplicationGroupsNode
                }

                # VirtualLab Graphviz Cluster
                if ($VirtualLab -and $VirtualLabNode) {

                    $SureBackupSubgraphNodeArray += $VirtualLabNode
                }

                try {
                    $SureBackupSubgraphNode = Node -Name 'SureBackup' -Attributes @{Label = (Add-HtmlSubGraph -Name 'SureBackup' -ImagesObj $Images -TableArray $SureBackupSubgraphNodeArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_SureBackup' -Label 'SureBackup' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 22 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create SureBackup SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($SureBackupSubgraphNode) {
                    $SureBackupSubgraphNode
                }
            }

            # Cloud Connect Graphviz Cluster
            $CloudConnectInfraArray = @()

            if ($CGServerInfo = Get-AbrBackupCGServerInfo) {
                if ($CGPoolInfo = Get-AbrBackupCGPoolInfo) {
                    try {
                        $CGPoolNode = foreach ($CGPool in $CGPoolInfo) {
                            if ($CGPoolInfo.CloudGateways) {
                                if ($CGPoolInfo.CloudGateways.count -le 5) {
                                    $columnSize = $CGPoolInfo.CloudGateways.count
                                } else {
                                    $columnSize = 5
                                }
                                Add-HtmlTable -Name 'CGPoolNode' -ImagesObj $Images -Rows $CGPool.CloudGateways.Name.split('.')[0] -ALIGN 'Center' -ColumnSize $columnSize -IconDebug $IconDebug -Subgraph -SubgraphIconType 'VBR_Cloud_Connect_Gateway' -SubgraphLabel $CGPool.Name -SubgraphLabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 0 -NoFontBold -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor
                            } else {
                                Add-HtmlTable -Name 'CGPoolNode' -ImagesObj $Images -Rows 'No Cloud Gateway Server' -ALIGN 'Center' -ColumnSize 1 -IconDebug $IconDebug -Subgraph -SubgraphIconType 'VBR_Cloud_Connect_Gateway' -SubgraphLabel $CGPool.Name -SubgraphLabelPos 'top' -FontColor $FontColor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder 0 -NoFontBold -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor
                            }
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CGPoolInfo Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                    try {
                        if ($CGPoolNode) {
                            if ($CGPoolNode.count -le 5) {
                                $columnSize = $CGPoolNode.count
                            } else {
                                $columnSize = 5
                            }
                            $CGPoolNodesSubGraph += Add-HtmlSubGraph -Name 'CGPoolNodesSubGraph' -ImagesObj $Images -TableArray $CGPoolNode -Align 'Center' -IconDebug $IconDebug -Label 'Gateway Pools' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $columnSize -FontSize 22 -IconType 'VBR_Cloud_Connect_Gateway_Pools' -FontBold -TableBackgroundColor $MainGraphBGColor

                            $CloudConnectInfraArray += $CGPoolNodesSubGraph
                        }
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CGPoolInfo SubGraph Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
                if ($CGServerInfo.Name.count -le 5) {
                    $columnSize = $CGServerInfo.Name.count
                } else {
                    $columnSize = 5
                }
                try {
                    $CGServerNode = Add-HtmlNodeTable -Name 'CGServerNode' -ImagesObj $Images -inputObject $CGServerInfo.Name -Align 'Center' -iconType 'VBR_Cloud_Connect_Gateway' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CGServerInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Service_Providers_Server' -SubgraphLabel 'Gateway Servers' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor

                    $CloudConnectInfraArray += $CGServerNode
                } catch {
                    Write-PScriboMessage 'Error: Unable to create CloudGateway server Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }


                if ($CCBSInfo = Get-AbrBackupCCBackupStorageInfo) {
                    if ($CCBSInfo.Name.count -le 5) {
                        $columnSize = $CCBSInfo.Name.count
                    } else {
                        $columnSize = 5
                    }
                    try {
                        $CCBSNode = Add-HtmlNodeTable -Name 'CCBSNode' -ImagesObj $Images -inputObject $CCBSInfo.Name -Align 'Center' -iconType $CCBSInfo.IconType -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCBSInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Repository' -SubgraphLabel 'Backup Storage' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor

                        $CloudConnectInfraArray += $CCBSNode
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CCBSNode Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
                if ($CCRRInfo = Get-AbrBackupCCReplicaResourcesInfo) {
                    if ($CCRRInfo.Name.count -le 5) {
                        $columnSize = $CCRRInfo.Name.count
                    } else {
                        $columnSize = 5
                    }
                    try {
                        $CCRRNode = Add-HtmlNodeTable -Name 'CCRRNode' -ImagesObj $Images -inputObject $CCRRInfo.Name -Align 'Center' -iconType 'VBR_Hardware_Resources' -ColumnSize $columnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCRRInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Hardware_Resources' -SubgraphLabel 'Replica Resources' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor

                        $CloudConnectInfraArray += $CCRRNode
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CCRRNode Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
                if ($CCVCDRRInfo = Get-AbrBackupCCvCDReplicaResourcesInfo) {
                    if ($CCVCDRRInfo.Name.count -le 5) {
                        $CCVCDRRInfocolumnSize = $CCVCDRRInfo.Name.count
                    } elseif ($ColumnSize) {
                        $CCVCDRRInfocolumnSize = $ColumnSize
                    } else {
                        $CCVCDRRInfocolumnSize = 5
                    }
                    try {
                        $CCVCDRRNode = Add-HtmlNodeTable -Name 'CCVCDRRNode' -ImagesObj $Images -inputObject $CCVCDRRInfo.Name -Align 'Center' -iconType 'VBR_Cloud_Connect_vCD' -ColumnSize $CCVCDRRInfocolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCVCDRRInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Cloud_Connect_Server' -SubgraphLabel 'Replica Org vDCs' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor $TableBorderColor -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -SubgraphFontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -SubgraphLabelFontColor $Fontcolor

                        $CloudConnectInfraArray += $CCVCDRRNode
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create CCVCDRRNode Objects. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }
                }
            }
            if ($CGServerInfo -and $CGServerNode) {
                try {
                    $CGServerSubGraph = Node -Name 'CloudConnectInfra' -Attributes @{Label = (Add-HtmlSubGraph -Name 'CloudConnectInfra' -ImagesObj $Images -TableArray $CloudConnectInfraArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Cloud_Connect' -Label 'Cloud Connect Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 24 -FontBold -TableBackgroundColor $MainGraphBGColor); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                } catch {
                    Write-PScriboMessage 'Error: Unable to create CloudConnectInfra SubGraph Objects. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($CGServerSubGraph) {
                    $CGServerSubGraph
                }
            }

            if ($DiagramTheme -eq 'Black') {
                $NodeFillColor = 'White'
            } elseif ($DiagramTheme -eq 'Neon') {
                $NodeFillColor = 'Gold2'
            } else {
                $NodeFillColor = '#71797E'
            }

            # Veeam VBR elements point of connection (Dummy Nodes!)
            $Node = @('VBRServerPointSpace', 'VBRProxyPoint', 'VBRProxyPointSpace', 'VBRRepoPoint')
            $NodeEdge = @()

            $LastPoint = 'VBRRepoPoint'

            if ($WanAccels) {
                $Node += 'VBRRepoPointSpace', 'VBRWanAccelPoint'
                $NodeEdge += 'VBRRepoPointSpace', 'VBRWanAccelPoint'
                $LastPoint = 'VBRWanAccelPoint'
            } else {
                $Node += 'VBRRepoPointSpace'
                $NodeEdge += 'VBRRepoPointSpace'
                $LastPoint = 'VBRRepoPointSpace'
            }

            if ($TapeServerInfo) {
                $Node += 'VBRTapePoint'
                $NodeEdge += 'VBRTapePoint'
                $LastPoint = 'VBRTapePoint'
            }

            if ($ServiceProviderInfo) {
                $Node += 'VBRServiceProviderPoint'
                $NodeEdge += 'VBRServiceProviderPoint'
                $LastPoint = 'VBRServiceProviderPoint'
            }

            if ($VirtualLabNode -or $ApplicationGroups) {
                $Node += 'VBRSureBackupPoint'
                $NodeEdge += 'VBRSureBackupPoint'
                $LastPoint = 'VBRSureBackupPoint'
            }

            if ($CGServerInfo) {
                $Node += 'VBRCloudConnectPoint'
                $NodeEdge += 'VBRCloudConnectPoint'
                $LastPoint = 'VBRCloudConnectPoint'
            }

            Node $Node -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebug.color; fillColor = $NodeDebug.style; shape = $NodeDebug.shape }

            $NodeStartEnd = @('VBRStartPoint', 'VBREndPointSpace')
            Node $NodeStartEnd -NodeScript { $_ } @{Label = { $_ }; fillColor = $Edgecolor; fontcolor = $NodeDebug.color; shape = 'point'; fixedsize = 'true'; width = .2 ; height = .2 }
            #---------------------------------------------------------------------------------------------#
            #                             Graphviz Rank Section                                           #
            #                     Rank allow to put Nodes on the same group level                         #
            #         PSgraph: https://psgraph.readthedocs.io/en/stable/Command-Rank-Advanced/            #
            #                     Graphviz: https://graphviz.org/docs/attrs/rank/                         #
            #---------------------------------------------------------------------------------------------#

            # Put the dummy node in the same rank to be able to create a horizontal line
            Rank $NodeStartEnd, $Node

            #---------------------------------------------------------------------------------------------#
            #                             Graphviz Edge Section                                           #
            #                   Edges are Graphviz elements use to interconnect Nodes                     #
            #                 Edges can have attribues like Shape, Size, Styles etc..                     #
            #              PSgraph: https://psgraph.readthedocs.io/en/latest/Command-Edge/                #
            #                      Graphviz: https://graphviz.org/docs/edges/                             #
            #---------------------------------------------------------------------------------------------#

            # LastPoint Min length
            $LastPointMinLen = 30
            # Connect the Dummy Node in a straight line
            # VBRStartPoint --- VBRServerPointSpace --- VBRProxyPoint --- VBRProxyPointSpace --- VBRRepoPoint --- VBREndPointSpace
            Edge -From VBRStartPoint -To VBRServerPointSpace @{minlen = 25; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
            Edge -From VBRServerPointSpace -To VBRProxyPoint @{minlen = 25; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
            if ($ProxiesVi -and $ProxiesHv -and $ProxiesNas ) {
                Edge -From VBRProxyPoint -To VBRProxyPointSpace @{minlen = 20; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
            } else {
                Edge -From VBRProxyPoint -To VBRProxyPointSpace @{minlen = 18; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
            }
            Edge -From VBRProxyPointSpace -To VBRRepoPoint @{minlen = 20; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
            Edge -From VBRRepoPoint -To VBRRepoPointSpace @{minlen = 20; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }

            # Connect the available Points
            $index = 0
            foreach ($Element in $NodeEdge) {
                $index++
                Edge -From $Element -To $NodeEdge[$index] @{minlen = 18; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
            }

            ####################################################################################
            #                                                                                  #
            #      This section connect the Infrastructure component to the Dummy Points       #
            #                                                                                  #
            ####################################################################################

            # Connect Veeam Backup server to the Dummy line
            Edge -From BackupServers -To VBRServerPointSpace @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

            # Connect Microsoft Entra ID Node to the Dummy line
            if ($EntraIDNode) {
                Edge -From EntraID -To VBRProxyPoint @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
            }

            # Connect Veeam Proxies Server to the Dummy line
            if ($ProxiesSubgraphNode) {
                Edge -From VBRProxyPoint -To Proxies @{minlen = 1; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
            }

            # Connect vCenter Servers Cluster to the Dummy line
            if ($ViClustersSubgraphNode -or $HvClustersSubgraphNode) {
                Edge -From Proxies -To VirtualInfra @{minlen = 1; arrowtail = 'dot'; arrowhead = 'dot'; style = 'dashed' }
            }

            # Connect Veeam Repository to the Dummy line
            Edge -From VBRRepoPoint -To Repositories @{minlen = 1; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

            # Connect Veeam Object Repository to the Dummy line
            if ($ObjStorageSubgraphNode) {
                Edge -To VBRRepoPoint -From ObjectRepos @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
            }

            # Connect Veeam Wan Accelerator to the Dummy line
            if ($WanAccels -and $WanAccelsNode) {
                Edge -From WanAccelServer -To VBRWanAccelPoint @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
            }

            # Connect Veeam Tape Infra to VBRTapePoint Dummy line
            if ($TapeServerInfo -and $TapeServerNode) {
                Edge -From VBRTapePoint -To TapeInfra @{minlen = 1; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
            }

            # Connect Veeam ServiceProvider Infra to VBRServiceProviderPoint Dummy line
            if ($ServiceProviderSubgraphNode) {
                Edge -From ServiceProviders -To VBRServiceProviderPoint @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
            }

            # Connect Veeam Object Repository to the Dummy line
            if ($SureBackupSubgraphNode) {
                Edge -From SureBackup -To VBRSureBackupPoint @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
            }

            # Connect Veeam Cloud Connect object to the Dummy line
            if ($CGServerSubGraph) {
                Edge -From VBRCloudConnectPoint -To CloudConnectInfra @{minlen = 1; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
            }

            ####################################################################################
            #                                                                                  #
            #   This section connect the Last Infrastructure component to VBREndPointSpace     #
            #                                                                                  #
            ####################################################################################

            if ($LastPoint) {
                Edge -From $LastPoint -To VBREndPointSpace @{minlen = $LastPointMinLen; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
            }
        }
    }
    end {}
}