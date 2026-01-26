function Get-AbrBackupCGPoolInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication cloud gateway pool information.
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
    )

    process {
        Write-Verbose -Message "Collecting Cloud Gateway Pool information from $($VBRServer)."
        try {

            $BackupCGPoolsInfo = @()
            if ($CloudObjects = Get-VBRCloudGatewayPool | Sort-Object -Property Name) {
                foreach ($CloudObject in $CloudObjects) {

                    $TempBackupCGPoolsInfo = [PSCustomObject]@{
                        Name = $CloudObject.Name
                        Label = Add-DiaNodeIcon -Name "$((Remove-SpecialChar -String $CloudObject.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Cloud_Connect_Gateway' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                        Id = $CloudObject.Id
                        CloudGateways = $CloudObject.CloudGateways
                    }

                    $BackupCGPoolsInfo += $TempBackupCGPoolsInfo
                }
            }

            return $BackupCGPoolsInfo
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}