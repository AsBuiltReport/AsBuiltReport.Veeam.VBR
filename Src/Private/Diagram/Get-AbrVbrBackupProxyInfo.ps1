function Get-AbrBackupProxyInfo {
    <#
    .SYNOPSIS
        Function to extract veeam backup & replication backup proxy information.
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


    param
    (
        # Backup Proxy Type
        [ValidateSet('vmware', 'hyperv', 'nas')]
        [string] $Type

    )
    process {
        Write-PScriboMessage "Collecting Backup Proxy information from $($VBRServer)."
        try {
            $BPType = switch ($Type) {
                'vmware' { Get-VBRViProxy }
                'hyperv' { Get-VBRHvProxy }
                'nas' { Get-VBRNASProxyServer }

            }
            $BackupProxies = $BPType
            $BackupProxyInfo = @()
            if ($BackupProxies) {
                foreach ($BackupProxy in $BackupProxies) {

                    $Hostname = switch ($Type) {
                        'vmware' { $BackupProxy.Host.Name }
                        'hyperv' { $BackupProxy.Host.Name }
                        'nas' { $BackupProxy.Server.Name }
                    }

                    $Status = switch ($Type) {
                        'vmware' {
                            switch ($BackupProxy.isDisabled) {
                                $false { 'Enabled' }
                                $true { 'Disabled' }
                            }
                        }
                        'hyperv' {
                            switch ($BackupProxy.isDisabled) {
                                $false { 'Enabled' }
                                $true { 'Disabled' }
                            }
                        }
                        'nas' {
                            switch ($BackupProxy.IsEnabled) {
                                $false { 'Disabled' }
                                $true { 'Enabled' }
                            }
                        }
                    }

                    $BPRows = [ordered]@{
                        IP = Get-NodeIP -Hostname $Hostname
                        Status = $Status
                        Type = switch ($Type) {
                            'vmware' { $BackupProxy.Host.Type }
                            'hyperv' {
                                switch ($BackupProxy.Info.Type) {
                                    'HvOffhost' { 'Off-Host Backup' }
                                    'HvOnhost' { 'On-Host Backup' }
                                }
                            }
                            'nas' { 'File Backup' }
                        }
                        Concurrent_Tasks = switch ($Type) {
                            'vmware' { $BackupProxy.MaxTasksCount }
                            'hyperv' { $BackupProxy.MaxTasksCount }
                            'nas' { $BackupProxy.ConcurrentTaskNumber }
                        }
                    }

                    $IconType = switch ($Type) {
                        'vmware' { 'VBR_Proxy_Server' }
                        'hyperv' { 'VBR_Proxy_Server' }
                        'nas' { 'VBR_AGENT_Server' }
                    }

                    $TempBackupProxyInfo = [PSCustomObject]@{
                        Name = "$($Hostname.toUpper().split('.')[0])"
                        Label = Add-DiaNodeIcon -Name "$($Hostname.toUpper().split('.')[0])" -IconType $IconType -Align 'Center' -Rows $BPRows -ImagesObj $Images -IconDebug $IconDebug -FontSize 18 -FontBold
                        AditionalInfo = $BPRows
                    }

                    $BackupProxyInfo += $TempBackupProxyInfo
                }
            }

            return $BackupProxyInfo
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}