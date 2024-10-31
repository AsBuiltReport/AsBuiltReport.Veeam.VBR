function Get-AbrVbrRequiredModule {
    <#
    .SYNOPSIS
    Function to check if the required version of Veeam.Backup.PowerShell is installed
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.11
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]

    Param
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
        #region: Start Load VEEAM Snapin / Module
        # Loading Module or PSSnapin
        # Make sure PSModulePath includes Veeam Console
        #Code taken from @vMarkus_K
        if (Test-path "C:\Program Files\Veeam\Backup and Replication\Console\" ) {
            $MyModulePath = "C:\Program Files\Veeam\Backup and Replication\Console\"
            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
        } elseif (Test-path "D:\Program Files\Veeam\Backup and Replication\Console\" ) {
            $MyModulePath = "D:\Program Files\Veeam\Backup and Replication\Console\"
            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
        } elseif (Test-path "E:\Program Files\Veeam\Backup and Replication\Console\" ) {
            $MyModulePath = "E:\Program Files\Veeam\Backup and Replication\Console\"
            $env:PSModulePath = $env:PSModulePath + "$([System.IO.Path]::PathSeparator)$MyModulePath"
        }
        if ($Modules = Get-Module -ListAvailable -Name Veeam.Backup.PowerShell) {
            try {
                Write-PScriboMessage "Trying to import Veeam B&R modules."
                $Modules | Import-Module -WarningAction SilentlyContinue
            } catch {
                Write-PScriboMessage -IsWarning "Failed to load Veeam Modules"
            }
        } else {
            try {
                Write-PScriboMessage "No Veeam Modules found, Fallback to SnapIn."
                Add-PSSnapin -Name VeeamPSSnapIn -PassThru -ErrorAction Stop | Out-Null
            } catch {
                Write-PScriboMessage -IsWarning "Failed to load VeeamPSSnapIn and no Modules found"
            }
        }
        Write-PScriboMessage "Identifying Veeam Powershell module version."
        if ($Module = Get-Module -ListAvailable -Name Veeam.Backup.PowerShell) {
            try {
                $script:VbrVersion = $Module.Version.ToString()
                Write-PScriboMessage "Using Veeam Powershell module version $($VbrVersion)."
            } catch {
                Write-PScriboMessage -IsWarning "Failed to get Version from Module"
            }
        } else {
            try {
                Write-PScriboMessage "No Veeam Modules found, Fallback to SnapIn."
                $script:VbrVersion = (Get-PSSnapin VeeamPSSnapin -ErrorAction SilentlyContinue).PSVersion.ToString()
                if ($VbrVersion) {
                    Write-PScriboMessage "Using Veeam Powershell module version $($VbrVersion)."
                }
            } catch {
                Write-PScriboMessage -IsWarning "Failed to get Version from Module or SnapIn"
            }
        }
        # Check if the required version of VMware PowerCLI is installed
        $RequiredModule = Get-Module -ListAvailable -Name $Name
        $ModuleVersion = "$($RequiredModule.Version.Major)" + "." + "$($RequiredModule.Version.Minor)"
        if ($ModuleVersion -eq ".") {
            throw "$Name $Version or higher is required to run the Veeam VBR As Built Report. Install the Veeam Backup & Replication console that provide the required modules."
        }
        if ($ModuleVersion -lt $Version) {
            throw "$Name $Version or higher is required to run the Veeam VBR As Built Report. Update the Veeam Backup & Replication console that provide the required modules."
        }
    }
    end {}
}