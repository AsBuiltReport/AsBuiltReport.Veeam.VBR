
function Get-AbrDiagBackupToHACluster {
    <#
    .SYNOPSIS
        Function to build a Veeam VBR High Availability Cluster diagram.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        1.0.0
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
                    $HAClusterNodesSubGraph = Add-HtmlSubGraph -Name 'HAClusterNodesSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $HAClusterNodesArray -Align 'Center' -IconDebug $IconDebug -IconType 'VBR_Server_HA' -Label 'Cluster Nodes' -LabelPos 'top' -FontColor $BackupServerFontColor -FontSize 22 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $BackupServerBGColor -ColumnSize $HAClusterNodesColumnSize -FontBold
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
                        $HAClusterSubGraph = Add-HtmlSubGraph -Name 'HAClusterSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $HAClusterNodesSubGraph -Align 'Right' -IconDebug $IconDebug -Label "Status: $ClusterStatus" -LabelPos 'down' -FontColor $BackupServerFontColor -FontSize 14 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold
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
                        if ($HAClusterInfo.DnsNode) {
                            $NITableArray = @($HAClusterInfo.DnsNode, $HAClusterInfo.EndpointNode)

                            try {
                                Add-HtmlNodeTable -Name NA -ImagesObj $Images -inputObject $NITableArray -Align 'Center' -IconDebug $IconDebug -iconType 'VBR_Tape_Drive' -Subgraph -SubgraphLabel ' '

                                # Add-HtmlSubGraph -Name Network -ImagesObj $Images -TableArray $NITableArray -Align 'Center' -IconDebug $IconDebug -Label ' ' -LabelPos 'top' -FontColor $Fontcolor -FontSize 24 -TableBorderColor $Edgecolor -TableBorder 1 -TableBackgroundColor $MainGraphBGColor -ColumnSize 2 -FontBold -TableStyle 'dashed'

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

                            Add-NodeEdge -From NetworkInfrastructure -To HAClusterServers -EdgeColor $MainGraphBGColor -EdgeStyle solid -LabelDistance 1
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}
