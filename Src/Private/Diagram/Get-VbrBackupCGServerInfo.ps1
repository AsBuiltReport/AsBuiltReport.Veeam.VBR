function Get-VbrBackupCGServerInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication cloud gateway servers information.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.6.36
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
        Write-Verbose -Message "Collecting Cloud Gateway Servers information from $($VBRServer)."
        try {

            $BackupCGServersInfo = @()
            if ($CloudObjects = Get-VBRCloudGateway | Sort-Object -Property Name) {
                # $CloudGatewayPoolServers = (Get-VBRCloudGatewayPool).CloudGateways.Name
                foreach ($CloudObject in $CloudObjects) {

                    $AditionalInfo = [PSCustomObject] [ordered] @{
                        IP = $CloudObject.IpAddress
                        'Network Mode' = $CloudObject.NetworkMode
                        'Incoming Port' = $CloudObject.IncomingPort
                        'NAT Port' = $CloudObject.NATPort
                        State = switch ($CloudObject.Enabled) {
                            'True' { 'Enabled' }
                            'False' { 'Disabled' }
                        }
                    }


                    $TempBackupCGServersInfo = [PSCustomObject]@{
                        Name = $CloudObject.Name
                        Label = Add-DiaNodeIcon -Name "$((Remove-SpecialChar -String $CloudObject.Name.split('.')[0] -SpecialChars '\').toUpper())" -IconType 'VBR_Cloud_Connect_Gateway' -Align 'Center' -AditionalInfo $AditionalInfo -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                        Id = $CloudObject.Id
                        AditionalInfo = $AditionalInfo
                    }

                    $BackupCGServersInfo += $TempBackupCGServersInfo
                }
            }

            return $BackupCGServersInfo
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}