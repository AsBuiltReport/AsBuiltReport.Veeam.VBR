function Get-AbrDiagBackupServer {
    <#
    .SYNOPSIS
        Function to build Backup Server object.
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

    param()

    process {
        try {

            $BackupServerInfoArray = @()

            if ((-not $DatabaseServerInfo.Name) -and (-not $EMServerInfo.Name) -and ($BackupServerInfo.Name)) {
                Write-PScriboMessage 'Collecting Backup Server Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
            } elseif (($DatabaseServerInfo.Name -ne $BackupServerInfo.Name) -and ($EMServerInfo.Name -ne $BackupServerInfo.Name)) {
                Write-PScriboMessage 'Collecting Backup Server, Database Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $EMServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $BackupServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $DatabaseServerInfo.Label
            } elseif (($DatabaseServerInfo.Name -ne $BackupServerInfo.Name) -and (-not $EMServerInfo)) {
                Write-PScriboMessage 'Not Enterprise Manager Found: Collecting Backup Server and Database server Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $DatabaseServerInfo.Label
            } elseif (($EMServerInfo.Name -eq $BackupServerInfo.Name) -and ($DatabaseServerInfo.Name -eq $BackupServerInfo.Name)) {
                Write-PScriboMessage 'Database and Enterprise Manager server collocated with Backup Server: Collecting Backup Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
            } elseif (($EMServerInfo.Name -eq $BackupServerInfo.Name) -and ($DatabaseServerInfo.Name -ne $BackupServerInfo.Name)) {
                Write-PScriboMessage 'Enterprise Manager server colocated with Backup Server: Collecting Backup Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $DatabaseServerInfo.Label
            } elseif ($EMServerInfo -and ($DatabaseServerInfo.Name -eq $BackupServerInfo.Name)) {
                Write-PScriboMessage 'Database server colocated with Backup Server: Collecting Backup Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $EMServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $BackupServerInfo.Label
            } else {
                Write-PScriboMessage 'Collecting Backup Server Information.'
                $BackupServerInfoArray += $BackupServerInfo.Label
            }

            if ($BackupServerInfoArray) {

                $columnSize = $BackupServerInfoArray.Count

                $BackupServerInfoSubGraph = Add-HtmlSubGraph -Name 'BackupServerInfoSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $BackupServerInfoArray -Align 'Center' -IconDebug $IconDebug -Label 'Backup Server' -LabelPos 'top' -FontColor $BackupServerFontColor -FontSize 26 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $BackupServerBGColor -ColumnSize $columnSize -FontBold

                if ($HAClusterInfo) {
                    Write-PScriboMessage 'Building High Availability Cluster diagram sections.'

                    # Network Infrastructure: Cluster Endpoint / DNS Server
                    SubGraph NetworkInfrastructure -Attributes @{
                        Label     = 'Network Infrastructure'
                        fontsize  = 18
                        penwidth  = 1.5
                        labelloc  = 't'
                        style     = 'dashed,rounded'
                        color     = $Edgecolor
                        bgcolor   = $BackupServerBGColor
                        fontcolor = $BackupServerFontColor
                        fontname  = 'Segoe Ui'
                    } {
                        $DNSSubGraph = Add-HtmlSubGraph -Name 'DNSSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $HAClusterInfo.DNSLabel -Align 'Center' -IconDebug $IconDebug -Label 'Cluster Endpoint' -LabelPos 'top' -FontColor $BackupServerFontColor -FontSize 26 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold
                        Add-HtmlSubGraph -Name DNSServer -ImagesObj $Images -TableArray $DNSSubGraph -Align 'Center' -IconDebug $IconDebug -Label '' -LabelPos 'down' -FontColor $Fontcolor -FontSize 14 -TableStyle 'rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold -GraphvizAttributes @{style = 'filled,rounded'; shape = 'plain'; fillColor = $BackupServerBGColor; fontsize = 14; fontname = 'Segoe Ui' } -NodeObject
                    }

                    # High Availability Cluster with Primary and Secondary nodes
                    SubGraph HACluster -Attributes @{
                        Label     = 'High Availability Cluster'
                        fontsize  = 18
                        penwidth  = 1.5
                        labelloc  = 't'
                        style     = 'dashed,rounded'
                        color     = $Edgecolor
                        bgcolor   = $BackupServerBGColor
                        fontcolor = $BackupServerFontColor
                        fontname  = 'Segoe Ui'
                    } {
                        SubGraph HAClusterPrimary -Attributes @{
                            Label     = 'Primary Node'
                            fontsize  = 16
                            penwidth  = 1.5
                            labelloc  = 'b'
                            style     = 'dashed,rounded'
                            color     = $Edgecolor
                            bgcolor   = $BackupServerBGColor
                            fontcolor = $BackupServerFontColor
                            fontname  = 'Segoe Ui'
                        } {
                            Add-HtmlSubGraph -Name BackupServers -ImagesObj $Images -TableArray $BackupServerInfoSubGraph -Align 'Right' -IconDebug $IconDebug -Label 'Backup Server' -LabelPos 'down' -FontColor $Fontcolor -FontSize 14 -TableStyle 'rounded' -TableBorderColor $Edgecolor -TableBorder '2' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold -GraphvizAttributes @{style = 'filled,rounded'; shape = 'plain'; fillColor = $BackupServerBGColor; fontsize = 14; fontname = 'Segoe Ui' } -NodeObject
                        }

                        SubGraph HAClusterSecondary -Attributes @{
                            Label     = 'Secondary Node'
                            fontsize  = 16
                            penwidth  = 1.5
                            labelloc  = 'b'
                            style     = 'dashed,rounded'
                            color     = $Edgecolor
                            bgcolor   = $BackupServerBGColor
                            fontcolor = $BackupServerFontColor
                            fontname  = 'Segoe Ui'
                        } {
                            $SecondaryInfoSubGraph = Add-HtmlSubGraph -Name 'SecondaryInfoSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $HAClusterInfo.SecondaryLabel -Align 'Center' -IconDebug $IconDebug -Label 'Backup Server' -LabelPos 'top' -FontColor $BackupServerFontColor -FontSize 26 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold
                            Add-HtmlSubGraph -Name HASecondaryServer -ImagesObj $Images -TableArray $SecondaryInfoSubGraph -Align 'Right' -IconDebug $IconDebug -Label 'Backup Server' -LabelPos 'down' -FontColor $Fontcolor -FontSize 14 -TableStyle 'rounded' -TableBorderColor $Edgecolor -TableBorder '2' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold -GraphvizAttributes @{style = 'filled,rounded'; shape = 'plain'; fillColor = $BackupServerBGColor; fontsize = 14; fontname = 'Segoe Ui' } -NodeObject
                        }

                        Edge BackupServers -To HASecondaryServer @{minlen = 3; label = 'DB Replication'; style = 'dashed'; dir = 'both'; penwidth = $EdgeLineWidth; color = $Edgecolor; fontcolor = $NodeFontcolor; fontsize = 14; fontname = 'Segoe Ui' }
                        Rank BackupServers, HASecondaryServer
                    }

                    Edge DNSServer -To BackupServers @{minlen = 2; style = 'dashed'; penwidth = $EdgeLineWidth; color = $Edgecolor }
                } else {
                    Add-HtmlSubGraph -Name BackupServers -ImagesObj $Images -TableArray $BackupServerInfoSubGraph -Align 'Right' -IconDebug $IconDebug -Label 'Management' -LabelPos 'down' -FontColor $Fontcolor -FontSize 14 -TableStyle 'rounded' -TableBorderColor $Edgecolor -TableBorder '2' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold -GraphvizAttributes @{style = 'filled,rounded'; shape = 'plain'; fillColor = $BackupServerBGColor; fontsize = 14; fontname = 'Segoe Ui' } -NodeObject
                }

            } else {
                throw 'No Backup Server Information Found.'
            }

        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}