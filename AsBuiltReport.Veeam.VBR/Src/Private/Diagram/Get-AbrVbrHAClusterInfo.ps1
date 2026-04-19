
function Get-AbrHAClusterInfo {
    <#
    .SYNOPSIS
        Function to extract Veeam VBR High Availability cluster node information.
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

    process {
        try {
            Write-PScriboMessage "Collecting HA Cluster Node information from $($VBRServer)."

            $HACluster = Get-VBRHighAvailabilityCluster

            if ($HACluster) {
                $HAClusterNodeInfo = @()

                $HAClusterNodes = @($HACluster.Primary) + @($HACluster.Secondary)

                foreach ($Node in $HAClusterNodes) {
                    $NodeIP = Get-AbrNodeIP -Hostname $Node.Hostname

                    $Rows = [ordered] @{
                        # IP     = $NodeIP
                        Role = $Node.Role
                        Status = $Node.Status
                    }

                    $Rows = [PSCustomObject]$Rows

                    $HAClusterNodeInfo += [PSCustomObject]@{
                        Name = $Node.Hostname
                        Label = Add-NodeIcon -Name "$($Node.Hostname)" -IconType 'VBR_Server' -Align 'Center' -RowsOrdered $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $BackupServerBGColor -CellBackgroundColor $BackupServerBGColor -FontColor $Fontcolor
                        Spacer = Add-NodeIcon -Name ' ' -IconType 'VBR_Bid_Arrow' -Align 'Center' -ImagesObj $Images -IconDebug $IconDebug -TableBackgroundColor $BackupServerBGColor -CellBackgroundColor $BackupServerBGColor -FontColor $Fontcolor
                        Role = $Node.Role
                    }
                }

                $EndPointTable = [ordered] @{
                    'Cluster DNS' = $HACluster.ClusterDnsName
                    'Cluster IP' = $HACluster.ClusterEndpoint
                }

                $DNSNode = Add-NodeIcon -Name 'DNS Server' -IconType 'VBR_Tape_Drive' -Align 'Center' -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $BackupServerBGColor -FontColor $Fontcolor -TableLayout Vertical

                $EndpointNode = Add-NodeIcon -Name $HACluster.ClusterDnsName.split('.')[0] -IconType 'VBR_GrayArrow' -Align 'Left' -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $BackupServerBGColor -FontColor $Fontcolor -TableLayout Horizontal -AditionalInfo $EndPointTable -IconPath $IconPath


                return [PSCustomObject]@{
                    Endpoint = $HACluster.ClusterEndpoint
                    DnsName = $HACluster.ClusterDnsName
                    DnsNode = $DNSNode
                    EndpointNode = $EndpointNode
                    IsHealthy = $HACluster.IsHealthyCluster
                    IsFailover = $HACluster.IsFailoverInProgress
                    IsActive = $HACluster.IsAnyActivityInProgress
                    Nodes = $HAClusterNodeInfo
                }
            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}
