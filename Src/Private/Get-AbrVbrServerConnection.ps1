function Get-AbrVbrServerConnection {
    <#
    .SYNOPSIS
    Used by As Built Report to establish conection to Veeam B&R Server.
    .DESCRIPTION
    .NOTES
        Version:        0.3.1
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Establishing initial connection to Backup Server: $($System)."
    }

    process {
        Write-PScriboMessage "Looking for veeam existing server connection."
        #Code taken from @vMarkus_K
        $OpenConnection = (Get-VBRServerSession).Server
        if($OpenConnection -eq $System) {
            Write-PScriboMessage "Existing veeam server connection found"
        }
        elseif ($null -eq $OpenConnection) {
            Write-PScriboMessage "No existing veeam server connection found"
            try {
                Write-PScriboMessage "Connecting to $($System) with $($Credential.USERNAME) credentials"
                Connect-VBRServer -Server $System -Credential $Credential -Port $Options.BackupServerPort
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
                Throw "Failed to connect to Veeam Backup Server Host $($System):$($Options.BackupServerPort) with username $($Credential.USERNAME)"
            }
        }
        else {
            Write-PScriboMessage "Actual veeam server connection not equal to $($System). Disconecting connection."
            Disconnect-VBRServer
            try {
                Write-PScriboMessage "Trying to open a new connection to $($System)"
                Connect-VBRServer -Server $System -Credential $Credential -Port $Options.BackupServerPort
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
                Throw "Failed to connect to Veeam Backup Server Host $($System):$($Options.BackupServerPort) with username $($Credential.USERNAME)"
            }
        }
        Write-PScriboMessage "Validating connection to $($System)"
        $NewConnection = (Get-VBRServerSession).Server
        if ($null -eq $NewConnection) {
            Write-PscriboMessage -IsWarning $_.Exception.Message
            Throw "Failed to connect to Veeam Backup Server Host $($System):$($Options.BackupServerPort) with username $($Credential.USERNAME)"
        }
        elseif ($NewConnection) {
            Write-PScriboMessage "Successfully connected to $($System):$($Options.BackupServerPort) Backup Server."
        }
    }
    end {}

}