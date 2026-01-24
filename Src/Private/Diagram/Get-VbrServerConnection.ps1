function Get-VbrServerConnection {
    <#
    .SYNOPSIS
        Establishes a connection to a Veeam Backup & Replication (B&R) Server.

    .DESCRIPTION
        This function is used by the Veeam.Diagrammer to connect to a Veeam B&R Server.
        It builds a diagram of the Veeam VBR configuration in various formats such as PDF, PNG, and SVG using Psgraph.
        The function checks for an existing connection to the Veeam server and reuses it if available.
        If no connection exists or the existing connection is to a different server, it establishes a new connection.

    .PARAMETER Port
        The TCP Port of the target Veeam Backup Server.

    .NOTES
        Version:        0.6.38
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        GitHub:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer

    .EXAMPLE
        PS> Get-VbrServerConnection -Port 9392
        Establishes a connection to the Veeam Backup Server on port 9392.

    .EXAMPLE
        PS> Get-VbrServerConnection -Port 9392 -Verbose
        Establishes a connection to the Veeam Backup Server on port 9392 with verbose output.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            HelpMessage = 'TCP Port of target Veeam Backup Server'
        )]
        [string]$Port
    )

    begin {
        Write-Verbose -Message 'Establishing initial connection to Backup Server.'

        $Port = switch ($VbrVersion) {
            { $_ -ge 13 } { 443 }
            default { $Port }
        }
    }

    process {
        Write-Verbose -Message 'Looking for existing Veeam server connection.'
        $OpenConnection = (Get-VBRServerSession).Server

        if ($OpenConnection -eq $System) {
            Write-Verbose -Message 'Existing Veeam server connection found.'
        } else {
            if ($null -ne $OpenConnection) {
                Write-Verbose -Message 'Disconnecting from current Veeam server connection.'
                Disconnect-VBRServer
            }

            Write-Verbose -Message "Connecting to $System with provided credentials."
            try {
                switch ($VbrVersion) {
                    { $_ -ge 13 } {
                        Connect-VBRServer -Server $System -User $Credential.UserName -Password (ConvertFrom-SecureString -SecureString $Credential.Password -AsPlainText) -Port $Port -ForceAcceptTlsCertificate
                    }
                    default {
                        Connect-VBRServer -Server $System -Credential $Credential -Port $Port
                    }
                }
            } catch {
                Write-Verbose -Message $_.Exception.Message
                throw "Failed to connect to Veeam Backup Server Host $($System):$($Port) with username $($Credential.USERNAME)"
            }
        }

        Write-Verbose -Message "Validating connection to $System."
        $NewConnection = (Get-VBRServerSession).Server
        if ($null -eq $NewConnection) {
            throw "Failed to connect to Veeam Backup Server Host $($System):$($Port) with username $($Credential.USERNAME)"
        } else {
            Write-Verbose -Message "Successfully connected to $($System):$($Port) Backup Server."
        }
    }

    end {}
}
