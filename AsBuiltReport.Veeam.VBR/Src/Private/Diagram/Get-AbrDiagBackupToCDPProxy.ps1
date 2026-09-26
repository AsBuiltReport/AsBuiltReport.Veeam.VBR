function Get-AbrDiagBackupToCDPProxy {
    <#
    .SYNOPSIS
        Function to build Backup Server to Proxy diagram.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        1.0.8
        Author:         AsBuiltReport Organization
        Twitter:        @asbuiltreport
        Github:         asbuiltreport
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]

    param
    (

    )

    begin {
    }

    process {
        try {
            $CDPBackupProxy = Get-AbrBackupProxyInfo -Type 'cdp'
            if ($BackupServerInfo) {
                if ($CDPBackupProxy) {

                    if ($CDPBackupProxy.Name.Count -le 1) {
                        $CDPBackupProxyColumnSize = 1
                    } elseif ($ColumnSize) {
                        $CDPBackupProxyColumnSize = $ColumnSize
                    } else {
                        $CDPBackupProxyColumnSize = $CDPBackupProxy.Name.Count
                    }

                    Add-HtmlNodeTable -Name 'CDPProxies' -ImagesObj $Images -inputObject ($CDPBackupProxy | ForEach-Object { if (Get-ValidateIP $_.Name) { $_.Name } else { $_.Name.split('.')[0] } }) -Align 'Center' -iconType 'VBR_Proxy_Server' -ColumnSize $CDPBackupProxyColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $CDPBackupProxy.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Proxy' -SubgraphLabel 'CDP Backup Proxies' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $Fontcolor -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -TableBorderColor $Edgecolor -TableBorder '1' -FontSize 18 -SubgraphLabelFontSize 26 -SubgraphFontBold -SubgraphLabelFontColor $Fontcolor -NodeObject

                    Add-NodeEdge -From BackupServers -To CDPProxies -EdgeColor $Edgecolor -EdgeStyle dashed -EdgeThickness 3 -EdgeLength 3

                }
            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}