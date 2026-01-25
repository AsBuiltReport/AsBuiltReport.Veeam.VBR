function Get-DiagBackupToCloudConnect {
    <#
    .SYNOPSIS
        Function to build Backup Server to Cloud Connect diagram.
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
        # Cloud Connect Graphviz Cluster
        $CloudConnectInfraArray = @()

        if ($CGServerInfo = Get-VbrBackupCGServerInfo) {
            if ($CGServerInfo.Name.Count -eq 1) {
                $CGServerNodeColumnSize = 1
            } elseif ($ColumnSize) {
                $CGServerNodeColumnSize = $ColumnSize
            } else {
                $CGServerNodeColumnSize = $CGServerInfo.Name.Count
            }
            try {
                $CGServerNode = Add-DiaHtmlNodeTable -Name 'CGServerNode' -ImagesObj $Images -inputObject $CGServerInfo.Name -Align 'Center' -iconType 'VBR_Cloud_Connect_Gateway' -ColumnSize $CGServerNodeColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CGServerInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Service_Providers_Server' -SubgraphLabel 'Gateway Servers' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -FontColor $Fontcolor -SubgraphFontBold

                $CloudConnectInfraArray += $CGServerNode
            } catch {
                Write-Verbose 'Error: Unable to create CloudGateway server Objects. Disabling the section'
                Write-Debug "Error Message: $($_.Exception.Message)"
            }
            if ($CGPoolInfo = Get-VbrBackupCGPoolInfo) {
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
                    Write-Verbose 'Error: Unable to create CGPoolInfo Objects. Disabling the section'
                    Write-Debug "Error Message: $($_.Exception.Message)"
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

                        $CloudConnectInfraArray += $CGPoolNodesSubGraph
                    }
                } catch {
                    Write-Verbose 'Error: Unable to create CGPoolInfo SubGraph Objects. Disabling the section'
                    Write-Debug "Error Message: $($_.Exception.Message)"
                }
            }

            if ($CCBSInfo = Get-VbrBackupCCBackupStorageInfo) {
                if ($CCBSInfo.Name.count -le 5) {
                    $CCBSInfocolumnSize = $CCBSInfo.Name.count
                } elseif ($ColumnSize) {
                    $CCBSInfocolumnSize = $ColumnSize
                } else {
                    $CCBSInfocolumnSize = 5
                }
                try {
                    $CCBSNode = Add-DiaHtmlNodeTable -Name 'CCBSNode' -ImagesObj $Images -inputObject $CCBSInfo.Name -Align 'Center' -iconType $CCBSInfo.IconType -ColumnSize $CCBSInfocolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCBSInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Repository' -SubgraphLabel 'Backup Storage' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -FontColor $Fontcolor -SubgraphFontBold

                    $CloudConnectInfraArray += $CCBSNode
                } catch {
                    Write-Verbose 'Error: Unable to create CCBSNode Objects. Disabling the section'
                    Write-Debug "Error Message: $($_.Exception.Message)"
                }
            }
            if ($CCRRInfo = Get-VbrBackupCCReplicaResourcesInfo) {
                if ($CCRRInfo.Name.count -le 5) {
                    $CCRRInfocolumnSize = $CCRRInfo.Name.count
                } elseif ($ColumnSize) {
                    $CCRRInfocolumnSize = $ColumnSize
                } else {
                    $CCRRInfocolumnSize = 5
                }
                try {
                    $CCRRNode = Add-DiaHtmlNodeTable -Name 'CCRRNode' -ImagesObj $Images -inputObject $CCRRInfo.Name -Align 'Center' -iconType 'VBR_Hardware_Resources' -ColumnSize $CCRRInfocolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCRRInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Hardware_Resources' -SubgraphLabel 'Replica Resources' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -FontColor $Fontcolor -SubgraphFontBold

                    $CloudConnectInfraArray += $CCRRNode
                } catch {
                    Write-Verbose 'Error: Unable to create CCRRNode Objects. Disabling the section'
                    Write-Debug "Error Message: $($_.Exception.Message)"
                }
            }
            if ($CCVCDRRInfo = Get-VbrBackupCCvCDReplicaResourcesInfo) {
                if ($CCVCDRRInfo.Name.count -le 5) {
                    $CCVCDRRInfocolumnSize = $CCVCDRRInfo.Name.count
                } elseif ($ColumnSize) {
                    $CCVCDRRInfocolumnSize = $ColumnSize
                } else {
                    $CCVCDRRInfocolumnSize = 5
                }
                try {
                    $CCVCDRRNode = Add-DiaHtmlNodeTable -Name 'CCVCDRRNode' -ImagesObj $Images -inputObject $CCVCDRRInfo.Name -Align 'Center' -iconType 'VBR_Cloud_Connect_vCD' -ColumnSize $CCVCDRRInfocolumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CCVCDRRInfo.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Cloud_Connect_Server' -SubgraphLabel 'Replica Org vDCs' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -TableBorderColor '#71797E' -TableBorder '1' -SubgraphLabelFontSize 22 -FontSize 18 -FontColor $Fontcolor -SubgraphFontBold

                    $CloudConnectInfraArray += $CCVCDRRNode
                } catch {
                    Write-Verbose 'Error: Unable to create CCVCDRRNode Objects. Disabling the section'
                    Write-Debug "Error Message: $($_.Exception.Message)"
                }
            }
        }
        if ($CGServerInfo -and $CGServerNode) {
            if ($CloudConnectInfraArray.count -le 5) {
                $CGServerSubGraphcolumnSize = $CloudConnectInfraArray.count
            } elseif ($ColumnSize) {
                $CGServerSubGraphcolumnSize = $ColumnSize
            } else {
                $CGServerSubGraphcolumnSize = 4
            }
            try {
                $CGServerSubGraph = Node -Name 'CloudConnectInfra' -Attributes @{Label = (Add-DiaHtmlSubGraph -Name 'CGServerSubGraph' -ImagesObj $Images -TableArray $CloudConnectInfraArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Cloud_Connect' -Label 'Cloud Connect Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $CGServerSubGraphcolumnSize -FontSize 24 -FontBold); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
            } catch {
                Write-Verbose 'Error: Unable to create CloudConnectInfra SubGraph Objects. Disabling the section'
                Write-Debug "Error Message: $($_.Exception.Message)"
            }

            if ($CGServerSubGraph) {
                $CGServerSubGraph
                Edge BackupServers -To CloudConnectInfra @{minlen = 3; }
            }
        }
    }
    end {}
}