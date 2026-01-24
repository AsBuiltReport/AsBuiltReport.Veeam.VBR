function Get-VbrRequiredModule {
    <#
    .SYNOPSIS
    Function to check if the required version of Veeam.Backup.PowerShell is installed
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.6.38
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]

    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Version
    )
    process {
        switch ($PSVersionTable.PSEdition) {
            'Core' {
                switch ($PSVersionTable.Platform) {
                    'Unix' {
                        $script:ClientOSVersion = 'Unix'
                        if (Test-Path '/opt/veeam/powershell/Veeam.Backup.PowerShell/Veeam.Backup.PowerShell.psd1' ) {
                            $MyModulePath = '/opt/veeam/powershell/Veeam.Backup.PowerShell/'
                            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
                        }
                    }
                    'Win32NT' {
                        $script:ClientOSVersion = 'Win32NT'
                        if (Test-Path 'C:\Program Files\Veeam\Backup and Replication\Console\' ) {
                            $MyModulePath = 'C:\Program Files\Veeam\Backup and Replication\Console\'
                            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
                        } elseif (Test-Path 'D:\Program Files\Veeam\Backup and Replication\Console\' ) {
                            $MyModulePath = 'D:\Program Files\Veeam\Backup and Replication\Console\'
                            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
                        } elseif (Test-Path 'E:\Program Files\Veeam\Backup and Replication\Console\' ) {
                            $MyModulePath = 'E:\Program Files\Veeam\Backup and Replication\Console\'
                            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
                        }
                    }
                }
            }
            'Desktop' {
                $script:ClientOSVersion = 'Win32NT'
                if (Test-Path 'C:\Program Files\Veeam\Backup and Replication\Console\' ) {
                    $MyModulePath = 'C:\Program Files\Veeam\Backup and Replication\Console\'
                    $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
                } elseif (Test-Path 'D:\Program Files\Veeam\Backup and Replication\Console\' ) {
                    $MyModulePath = 'D:\Program Files\Veeam\Backup and Replication\Console\'
                    $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
                } elseif (Test-Path 'E:\Program Files\Veeam\Backup and Replication\Console\' ) {
                    $MyModulePath = 'E:\Program Files\Veeam\Backup and Replication\Console\'
                    $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
                }
            }
        }
        if ($Modules = Get-Module -ListAvailable -Name Veeam.Backup.PowerShell) {
            try {
                Write-Verbose 'Trying to import Veeam B&R modules.'
                $Modules | Import-Module -DisableNameChecking -Global -WarningAction SilentlyContinue
            } catch {
                Write-Error 'Failed to load Veeam Modules'
            }
        }

        Write-Verbose 'Identifying Veeam Powershell module version.'
        if ($Module = Get-Module -ListAvailable -Name Veeam.Backup.PowerShell) {
            try {
                $script:VbrVersion = $Module.Version.ToString()
                Write-Verbose "Using Veeam Powershell module version $($VbrVersion)."
            } catch {
                Write-Error 'Failed to get Version from Module'
            }
        }
        # Check if the required version of VMware PowerCLI is installed
        $RequiredModule = Get-Module -ListAvailable -Name $Name
        $ModuleVersion = '{0}.{1}' -f $RequiredModule.Version.Major, $RequiredModule.Version.Minor
        if ($ModuleVersion -eq '.') {
            if ($ClientOSVersion -eq 'Unix') {
                throw "$Name $Version or higher is required to run the Veeam.Diagrammer. Install the Veeam PowerShell module for linux that provide the required modules (https://helpcenter.veeam.com/docs/vbr/powershell/running_ps_sessions_linux.html?ver=13)."
            } else {
                throw "$Name $Version or higher is required to run the Veeam.Diagrammer. Install the Veeam Backup & Replication console that provide the required modules."
            }
        }

        if ($ModuleVersion -lt $Version) {
            if ($ClientOSVersion -eq 'Unix') {
                throw "$Name $Version or higher is required to run the Veeam.Diagrammer. Update the Veeam PowerShell module for linux that provide the required modules (https://helpcenter.veeam.com/docs/vbr/powershell/running_ps_sessions_linux.html?ver=13)."
            } else {
                throw "$Name $Version or higher is required to run the Veeam.Diagrammer. Update the Veeam Backup & Replication console that provide the required modules."
            }
        }
    }
    end {}
}
