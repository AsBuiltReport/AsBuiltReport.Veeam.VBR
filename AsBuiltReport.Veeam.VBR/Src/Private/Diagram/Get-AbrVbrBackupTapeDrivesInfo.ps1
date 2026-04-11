function Get-AbrBackupTapeDrivesInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication tape drives information.
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
        [string] $TapeLibrary
    )

    process {
        Write-PScriboMessage "Collecting Tape Drives information from $($VBRServer)."
        try {

            if ($TapeLibrary) {
                $TapeDrives = Get-VBRTapeDrive -Library $TapeLibrary
            } else { $TapeDrives = Get-VBRTapeDrive }

            $BackupTapeDriveInfo = @()
            if ($TapeDrives) {
                foreach ($TapeDrive in $TapeDrives) {

                    $Rows = [ordered ]@{
                        # Role = 'Tape Drive'
                        'Serial#' = $TapeDrive.SerialNumber
                        Model = $TapeDrive.Model
                        'Drive ID' = $TapeDrive.Name
                    }


                    $TempBackupTapeDriveInfo = [PSCustomObject]@{
                        Name = $TapeDrive.Name
                        Label = Add-NodeIcon -Name "$((Remove-SpecialCharacter -String ("Drive $($TapeDrive.Address + 1)").split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Tape_Drive' -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold -TableBackgroundColor $MainGraphBGColor -CellBackgroundColor $MainGraphBGColor -FontColor $Fontcolor
                        LibraryId = $TapeDrive.LibraryId
                        Id = $TapeDrive.Id
                        AditionalInfo = $Rows
                    }

                    $BackupTapeDriveInfo += $TempBackupTapeDriveInfo
                }
            }

            return $BackupTapeDriveInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}