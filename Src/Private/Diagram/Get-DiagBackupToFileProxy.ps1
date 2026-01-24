function Get-DiagBackupToFileProxy {
    <#
    .SYNOPSIS
        Function to build Backup Server to Proxy diagram.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.6.38
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
            $FileBackupProxy = Get-VbrBackupProxyInfo -Type 'nas'
            if ($BackupServerInfo) {
                if ($FileBackupProxy) {

                    if ($FileBackupProxy.Name.Count -le 1) {
                        $FileBackupProxyColumnSize = 1
                    } elseif ($ColumnSize) {
                        $FileBackupProxyColumnSize = $ColumnSize
                    } else {
                        $FileBackupProxyColumnSize = $FileBackupProxy.Name.Count
                    }

                    Node FileProxies @{Label = (Add-DiaHtmlNodeTable -Name 'FileProxies' -ImagesObj $Images -inputObject ($FileBackupProxy | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Proxy_Server' -ColumnSize $FileBackupProxyColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $FileBackupProxy.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Proxy' -SubgraphLabel 'File Backup Proxies' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor '#000000' -TableBorderColor $Edgecolor -TableBorder '1' -FontSize 18 -SubgraphLabelFontSize 26 -SubgraphFontBold -SubgraphLabelFontColor $Fontcolor); shape = 'plain'; fontsize = 14; fontname = 'Segoe Ui' }

                    Edge -From BackupServers -To FileProxies @{minlen = 3 }

                }
            }
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}