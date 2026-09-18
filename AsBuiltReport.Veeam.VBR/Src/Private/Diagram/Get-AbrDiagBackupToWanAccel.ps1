function Get-AbrDiagBackupToWanAccel {
    <#
    .SYNOPSIS
        Function to build Backup Server to Wan Accelerator diagram.
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
            $WanAccel = Get-AbrBackupWanAccelInfo
            if ($BackupServerInfo) {
                if ($WanAccel) {

                    if ($WanAccel.Name.Count -eq 1) {
                        $WanAccelColumnSize = 1
                    } elseif ($ColumnSize) {
                        $WanAccelColumnSize = $ColumnSize
                    } else {
                        $WanAccelColumnSize = $WanAccel.Name.Count
                    }

                    Add-HtmlNodeTable -Name 'WanAccelServer' -ImagesObj $Images -inputObject ($WanAccel | ForEach-Object { if (Get-ValidateIP $_.Name) { $_.Name } else { $_.Name.split('.')[0] } }) -Align 'Center' -iconType 'VBR_Wan_Accel' -ColumnSize $WanAccelColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo ($WanAccel.AditionalInfo ) -Subgraph -SubgraphIconType 'VBR_Wan_Accel' -SubgraphLabel 'Wan Accelerators' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $FontColor -TableBorderColor $Edgecolor -TableBorder '1' -FontSize 18 -SubgraphLabelFontColor $Fontcolor -SubgraphLabelFontSize 22 -SubgraphFontBold -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -NodeObject

                    Add-NodeEdge -From BackupServers -To WanAccelServer -EdgeColor $Edgecolor -EdgeStyle dashed -EdgeThickness 3 -EdgeLength 3

                }

            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}