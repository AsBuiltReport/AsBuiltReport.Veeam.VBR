function Get-AbrBackupTapeServerInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication tape servers information.
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
    [OutputType([System.Object[]])]

    param (
    )

    process {
        Write-PScriboMessage "Collecting Tape Servers information from $($VBRServer)."
        try {

            $TapeServers = Get-VBRTapeServer

            $BackupTapeServersInfo = @()
            if ($TapeServers) {
                foreach ($TapeServer in $TapeServers) {

                    $Rows = @{
                        IP = Get-AbrNodeIP -Hostname $TapeServer.Name
                        Role = 'Tape Server'
                        State = switch ($TapeServer.IsAvailable) {
                            'True' { 'Available' }
                            'False' { 'Unavailable' }
                        }
                    }


                    $TempBackupTapeServersInfo = [PSCustomObject]@{
                        Name = $TapeServer.Name
                        Label = Add-NodeIcon -Name "$((Remove-SpecialCharacter -String $TapeServer.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Tape_Server' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor
                        Id = $TapeServer.Id
                    }

                    $BackupTapeServersInfo += $TempBackupTapeServersInfo
                }
            }

            return $BackupTapeServersInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}