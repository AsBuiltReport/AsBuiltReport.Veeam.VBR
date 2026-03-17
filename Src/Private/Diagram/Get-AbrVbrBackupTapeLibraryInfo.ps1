function Get-AbrBackupTapeLibraryInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication tape libraries information.
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
    [OutputType([System.Object[]])]

    param (
        [string] $TapeServer
    )

    process {
        Write-PScriboMessage "Collecting Tape Library information from $($VBRServer)."
        try {

            if ($TapeServer) {
                $TapeLibraries = Get-VBRTapeLibrary -TapeServer $TapeServer
            } else { $TapeLibraries = Get-VBRTapeLibrary }

            $BackupTapelibraryInfo = @()
            if ($TapeLibraries) {
                foreach ($TapeLibrary in $TapeLibraries) {

                    $Rows = [ordered ]@{
                        Role = 'Tape Library'
                        State = $TapeLibrary.State
                        Type = $TapeLibrary.Type
                    }


                    $TempBackupTapelibraryInfo = [PSCustomObject]@{
                        Name = "$((Remove-SpecialCharacter -String $TapeLibrary.Name -SpecialChars '\').toUpper())_$(Get-Random)"
                        Label = Add-NodeIcon -Name "$((Remove-SpecialCharacter -String $TapeLibrary.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Tape_Library' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                        TapeServerId = $TapeLibrary.TapeServerId
                        Id = $TapeLibrary.Id
                    }

                    $BackupTapelibraryInfo += $TempBackupTapelibraryInfo
                }
            }

            return $BackupTapelibraryInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}