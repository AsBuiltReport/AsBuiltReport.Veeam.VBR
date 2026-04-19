
function Get-AbrDiagBackupToHACluster {
    <#
    .SYNOPSIS
        Function to build a Veeam VBR High Availability Cluster diagram.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        1.0.1
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]

    param ()

    begin {}

    process {
        try {
            $HAClusterInfo = Get-AbrHAClusterInfo

            if ($BackupServerInfo -and $HAClusterInfo -and $HAClusterInfo.Nodes) {
                # Build node labels array: alternate labels and spacers
                $HAClusterNodesArray = @()
                $NodeCount = ($HAClusterInfo.Nodes | Measure-Object).Count

                for ($i = 0; $i -lt $NodeCount; $i++) {
                    $HAClusterNodesArray += $HAClusterInfo.Nodes[$i].Label
                    if ($i -lt ($NodeCount - 1)) {
                        $HAClusterNodesArray += $HAClusterInfo.Nodes[$i].Spacer
                    }
                }

                $HAClusterNodesColumnSize = $HAClusterNodesArray.Count

                # Inner subgraph: cluster node icons side-by-side
                try {
                    $HAClusterNodesSubGraph = Add-HtmlSubGraph -Name 'HAClusterNodesSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $HAClusterNodesArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Server_HA' -Label 'Cluster Nodes' -LabelPos 'top' -FontColor $BackupServerFontColor -FontSize 22 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $MainGraphBGColor -ColumnSize $HAClusterNodesColumnSize -FontBold
                } catch {
                    Write-PScriboMessage 'Error: Unable to create HA Cluster Nodes SubGraph. Disabling the section'
                    Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                }

                if ($HAClusterNodesSubGraph) {
                    $ClusterStatus = switch ($HAClusterInfo.IsHealthy) {
                        $true { 'Healthy' }
                        $false { 'Unhealthy' }
                        default { 'Unknown' }
                    }

                    if ($HAClusterInfo.DnsName) {
                        $HAClusterLabel = "Endpoint: $($HAClusterInfo.Endpoint)  |  DNS: $($HAClusterInfo.DnsName)"
                    } else {
                        $HAClusterLabel = "Endpoint: $($HAClusterInfo.Endpoint)"
                    }

                    # Outer subgraph: cluster container with metadata label and cluster icon
                    try {
                        $HAClusterSubGraph = Add-HtmlSubGraph -Name 'HAClusterSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $HAClusterNodesSubGraph -Align 'Right' -IconDebug $IconDebug -Label "Status: $ClusterStatus" -LabelPos 'down' -FontColor $BackupServerFontColor -FontSize 14 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -TableBackgroundColor $MainGraphBGColor -ColumnSize 1 -FontBold
                    } catch {
                        Write-PScriboMessage 'Error: Unable to create HA Cluster SubGraph. Disabling the section'
                        Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                    }

                    if ($HAClusterSubGraph) {
                        # Create the main HAClusterServers management node
                        try {
                            Add-HtmlSubGraph -Name HAClusterServers -ImagesObj $Images -TableArray $HAClusterSubGraph -Align 'Center' -IconDebug $IconDebug -Label 'High Availability Cluster' -LabelPos 'top' -FontColor $Fontcolor -FontSize 24 -TableStyle 'rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $MainGraphBGColor -ColumnSize 1 -FontBold -NodeObject
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create HA Cluster Services node. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        # Optional: separate PostgreSQL database server node
                        if ($HAClusterInfo.EndpointNode) {
                            $NITableArray = @($HAClusterInfo.EndpointNode)

                            try {
                                $NA = Add-HtmlSubGraph -Name Network -ImagesObj $Images -TableArray $NITableArray -Align 'Center' -IconDebug $IconDebug -Label 'DNS Server' -LabelPos 'top' -FontColor $Fontcolor -FontSize 24 -TableBorderColor $Edgecolor -TableBorder 1 -TableBackgroundColor $MainGraphBGColor -ColumnSize 1 -FontBold -TableStyle 'dashed' -IconType 'VBR_Server'
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create Network Infrastructure node. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }

                            try {
                                Add-HtmlSubGraph -Name NetworkInfrastructure -ImagesObj $Images -TableArray $NA -Align 'Center' -IconDebug $IconDebug -Label 'Network Infrastructure' -LabelPos 'top' -FontColor $Fontcolor -FontSize 24 -TableStyle 'rounded' -TableBorderColor $Edgecolor -TableBorder 0 -TableBackgroundColor $MainGraphBGColor -ColumnSize 2 -FontBold -NodeObject

                            } catch {
                                Write-PScriboMessage 'Error: Unable to create Network Infrastructure node. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }

                            Add-NodeEdge -From NetworkInfrastructure -To HAClusterServers -EdgeColor $Edgecolor -EdgeStyle solid -LabelDistance 1 -EdgeThickness 2 -Arrowhead box -Arrowtail box -EdgeLength 2
                        }
                    }
                    Add-NodeIcon -Name BackupConsole -LabelName 'Backup<BR/>Console' -IconType 'VBR_Webconsole' -Align 'Center' -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $MainGraphBGColor -FontColor $Fontcolor -TableLayout Vertical -IconPath $IconPath -NodeObject

                    Add-NodeSpacer -Name Spacer1 -ShapeWidth 2 -ShapeHeight 2 -IconDebug $IconDebug

                    Add-NodeEdge -From BackupConsole -To HAClusterServers -EdgeColor 'blue' -EdgeStyle solid -EdgeThickness 2 -Arrowhead normal -Arrowtail normal -EdgeLength 4

                    Add-NodeEdge -From Spacer1 -To NetworkInfrastructure -EdgeColor $MainGraphBGColor -EdgeStyle solid -EdgeThickness 1 -Arrowhead normal -Arrowtail normal -EdgeLength 2

                    Rank BackupConsole, HAClusterServers

                    Rank Spacer1, NetworkInfrastructure

                }
            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}
