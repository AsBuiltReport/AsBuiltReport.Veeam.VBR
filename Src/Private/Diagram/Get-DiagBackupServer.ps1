function Get-DiagBackupServer {
    <#
    .SYNOPSIS
        Function to build Backup Server object.
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

    param()

    process {
        try {

            $BackupServerInfoArray = @()

            if (( -not $DatabaseServerInfo.Name ) -and ( -not $EMServerInfo.Name ) -and ($BackupServerInfo.Name)) {
                Write-Verbose -Message 'Collecting Backup Server Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
            } elseif (($DatabaseServerInfo.Name -ne $BackupServerInfo.Name) -and ($EMServerInfo.Name -ne $BackupServerInfo.Name )) {
                Write-Verbose -Message 'Collecting Backup Server, Database Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $EMServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $BackupServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $DatabaseServerInfo.Label
            } elseif (($DatabaseServerInfo.Name -ne $BackupServerInfo.Name) -and (-not $EMServerInfo)) {
                Write-Verbose -Message 'Not Enterprise Manager Found: Collecting Backup Server and Database server Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $DatabaseServerInfo.Label
            } elseif (($EMServerInfo.Name -eq $BackupServerInfo.Name) -and ($DatabaseServerInfo.Name -eq $BackupServerInfo.Name)) {
                Write-Verbose -Message 'Database and Enterprise Manager server collocated with Backup Server: Collecting Backup Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
            } elseif (($EMServerInfo.Name -eq $BackupServerInfo.Name) -and ($DatabaseServerInfo.Name -ne $BackupServerInfo.Name)) {
                Write-Verbose -Message 'Enterprise Maneger server colocated with Backup Server: Collecting Backup Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $BackupServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $DatabaseServerInfo.Label
            } elseif ($EMServerInfo -and ($DatabaseServerInfo.Name -eq $BackupServerInfo.Name)) {
                Write-Verbose -Message 'Database server colocated with Backup Server: Collecting Backup Server and Enterprise Manager Information.'

                $BackupServerInfoArray += $EMServerInfo.Label
                $BackupServerInfoArray += $BackupServerInfo.Spacer
                $BackupServerInfoArray += $BackupServerInfo.Label
            } else {
                Write-Verbose -Message 'Collecting Backup Server Information.'
                $BackupServerInfoArray += $BackupServerInfo.Label
            }


            if ($BackupServerInfoArray) {

                $columnSize = $BackupServerInfoArray.Count

                $BackupServerInfoSubGraph = Add-DiaHtmlSubGraph -Name 'BackupServerInfoSubGraph' -CellSpacing 4 -ImagesObj $Images -TableArray $BackupServerInfoArray -Align 'Center' -IconDebug $IconDebug -Label 'Backup Server' -LabelPos 'top' -FontColor $BackupServerFontColor -FontSize 26 -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '0' -TableBackgroundColor $BackupServerBGColor -ColumnSize $columnSize -FontBold

                Add-DiaHtmlSubGraph -Name BackupServers -ImagesObj $Images -TableArray $BackupServerInfoSubGraph -Align 'Right' -IconDebug $IconDebug -Label 'Management' -LabelPos 'down' -FontColor $Fontcolor -FontSize 14 -TableStyle 'rounded' -TableBorderColor $Edgecolor -TableBorder '2' -TableBackgroundColor $BackupServerBGColor -ColumnSize 1 -FontBold -GraphvizAttributes @{style = 'filled,rounded'; shape = 'plain'; fillColor = $BackupServerBGColor; fontsize = 14; fontname = 'Segoe Ui' } -NodeObject

            } else {
                throw 'No Backup Server Information Found.'
            }

        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}