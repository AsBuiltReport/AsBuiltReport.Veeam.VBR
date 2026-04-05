function Get-AbrBackupProtectedGroupInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication protected group information.
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
        Write-PScriboMessage "Collecting Protected Group information from $($VBRServer)."
        try {
            [Array]$ProtectedGroups = Get-VBRProtectionGroup

            $ProtectedGroupInfo = @()
            if ($ProtectedGroups) {
                foreach ($ProtectedGroup in $ProtectedGroups) {

                    $Rows = @{
                        'Type' = $ProtectedGroup.Type
                        'Status' = switch ($ProtectedGroup.Enabled) {
                            $true { 'Enabled' }
                            $false { 'Disabled' }
                            default { 'Unknown' }
                        }
                        'Schedule' = $ProtectedGroup.ScheduleOptions.PolicyType
                    }

                    $Type = Get-AbrIconType -String $ProtectedGroup.Container.Type

                    $TempProtectedGroupInfo = [PSCustomObject]@{
                        Name = "$((Remove-SpecialCharacter -String $ProtectedGroup.Name -SpecialChars '\').toUpper())"
                        Label = Add-NodeIcon -Name "$((Remove-SpecialCharacter -String $ProtectedGroup.Name -SpecialChars '\').toUpper())" -IconType $Type -Align 'Center' -Rows $Rows -ImagesObj $Images -IconDebug $IconDebug -FontBold
                        Container = $ProtectedGroup.Container.Type
                        Object = $ProtectedGroup
                    }

                    $ProtectedGroupInfo += $TempProtectedGroupInfo
                }
            }

            return $ProtectedGroupInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}