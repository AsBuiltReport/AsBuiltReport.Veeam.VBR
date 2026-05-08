
function Get-AbrVbrLog {
    <#
    .SYNOPSIS
        Collects diagnostic information for AsBuiltReport.Veeam.VBR troubleshooting.
    .DESCRIPTION
        Gathers environment, module, PowerShell session, Veeam connectivity, and error
        information from the current session and the machine running the report. Output
        is written to a structured JSON file and, optionally, to the console.
    .PARAMETER OutputFolderPath
        Directory where the diagnostic bundle (JSON file) is saved.
        Defaults to the system temporary folder.
    .PARAMETER IncludeErrorDetails
        When specified, captures the full $Error collection including stack traces.
        By default only the most recent 25 errors are included (without stack traces).
    .PARAMETER PassThru
        Returns the diagnostic object to the pipeline in addition to writing the file.
    .EXAMPLE
        Get-AbrVbrLog

        Saves a diagnostic JSON to the system temp folder.
    .EXAMPLE
        Get-AbrVbrLog -OutputFolderPath 'C:\Logs' -IncludeErrorDetails -PassThru

        Saves a full diagnostic JSON (with stack traces) to C:\Logs and returns the
        object to the pipeline.
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Github:         rebelinux
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope = 'Function')]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, HelpMessage = 'Directory where the diagnostic bundle is saved.')]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [String] $OutputFolderPath = ([System.IO.Path]::GetTempPath()),

        [Parameter(Mandatory = $false, HelpMessage = 'Include full stack traces for every error in $Error.')]
        [Switch] $IncludeErrorDetails,

        [Parameter(Mandatory = $false, HelpMessage = 'Return the diagnostic object to the pipeline.')]
        [Switch] $PassThru
    )

    begin {
        Write-Verbose 'Collect-AbrVbrLogs: Starting diagnostic collection.'
        $TimeStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $FileName = "AbrVbrDiagnostics_$TimeStamp.json"
        $OutputFile = Join-Path -Path $OutputFolderPath -ChildPath $FileName
    }

    process {
        $Diag = [ordered] @{}

        # --- Collection timestamp -----------------------------------------------
        $Diag['CollectedAt'] = (Get-Date -Format 'o')

        # --- PowerShell session info --------------------------------------------
        try {
            $Diag['PowerShellSession'] = [ordered] @{
                PSVersion = $PSVersionTable.PSVersion.ToString()
                PSEdition = $PSVersionTable.PSEdition
                BuildVersion = $PSVersionTable.BuildVersion.ToString()
                CLRVersion = if ($PSVersionTable.CLRVersion) { $PSVersionTable.CLRVersion.ToString() } else { 'N/A' }
                WSManStackVersion = if ($PSVersionTable.WSManStackVersion) { $PSVersionTable.WSManStackVersion.ToString() } else { 'N/A' }
                OS = $PSVersionTable.OS
                Platform = $PSVersionTable.Platform
                ExecutionPolicy = (Get-ExecutionPolicy -Scope Process).ToString()
                CurrentPrincipal = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                IsAdministrator = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                HostName = $Host.Name
                HostVersion = $Host.Version.ToString()
                PID = $PID
            }
        } catch {
            $Diag['PowerShellSession'] = "Error collecting PowerShell session info: $($_.Exception.Message)"
        }

        # --- Machine / OS info --------------------------------------------------
        try {
            $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
            $CS = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
            $CPU = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
            $Diag['Machine'] = [ordered] @{
                ComputerName = $env:COMPUTERNAME
                Domain = $CS.Domain
                Manufacturer = $CS.Manufacturer
                Model = $CS.Model
                TotalMemoryGB = [math]::Round($CS.TotalPhysicalMemory / 1GB, 2)
                OSCaption = $OS.Caption
                OSVersion = $OS.Version
                OSBuildNumber = $OS.BuildNumber
                OSArchitecture = $OS.OSArchitecture
                OSLastBootUpTime = $OS.LastBootUpTime.ToString('o')
                CPUName = $CPU.Name
                CPUCores = $CPU.NumberOfCores
                CPULogicalProc = $CPU.NumberOfLogicalProcessors
                TimeZone = (Get-TimeZone).DisplayName
            }
        } catch {
            $Diag['Machine'] = "Error collecting machine info: $($_.Exception.Message)"
        }

        # --- Relevant installed modules -----------------------------------------
        try {
            $RelevantModuleNames = @(
                'AsBuiltReport.Veeam.VBR',
                'AsBuiltReport.Core',
                'AsBuiltReport.Chart',
                'AsBuiltReport.Diagram',
                'Veeam.Backup.PowerShell',
                'PScribo',
                'PSGraph'
            )
            $ModuleInfo = foreach ($ModName in $RelevantModuleNames) {
                $Mods = Get-Module -ListAvailable -Name $ModName -ErrorAction SilentlyContinue |
                Sort-Object -Property Version -Descending
                if ($Mods) {
                    foreach ($Mod in $Mods) {
                        [ordered] @{
                            Name = $Mod.Name
                            Version = $Mod.Version.ToString()
                            Path = $Mod.ModuleBase
                            Description = $Mod.Description
                        }
                    }
                } else {
                    [ordered] @{
                        Name = $ModName
                        Version = 'Not installed'
                        Path = $null
                        Description = $null
                    }
                }
            }
            $Diag['InstalledModules'] = @($ModuleInfo)
        } catch {
            $Diag['InstalledModules'] = "Error collecting module info: $($_.Exception.Message)"
        }

        # --- Currently loaded modules in session --------------------------------
        try {
            $Diag['LoadedModules'] = @(
                Get-Module | Sort-Object -Property Name | ForEach-Object {
                    [ordered] @{
                        Name = $_.Name
                        Version = $_.Version.ToString()
                        Path = $_.ModuleBase
                    }
                }
            )
        } catch {
            $Diag['LoadedModules'] = "Error collecting loaded modules: $($_.Exception.Message)"
        }

        # --- AsBuiltReport.Veeam.VBR runtime config (script-scope vars) --------
        try {
            $RuntimeConfig = [ordered] @{}
            foreach ($VarName in @('InfoLevel', 'HealthCheck', 'Options', 'Report')) {
                $ScopeVar = Get-Variable -Name $VarName -Scope Script -ErrorAction SilentlyContinue
                if ($ScopeVar) {
                    $RuntimeConfig[$VarName] = $ScopeVar.Value
                } else {
                    $RuntimeConfig[$VarName] = '<not set>'
                }
            }
            $Diag['VBRReportConfig'] = $RuntimeConfig
        } catch {
            $Diag['VBRReportConfig'] = "Error collecting VBR report config: $($_.Exception.Message)"
        }

        # --- Veeam VBR connection state -----------------------------------------
        try {
            $VBRServer = [Veeam.Backup.Core.CBackupServerInfo]::GetCurrentBackupServerInfo()
            $Diag['VeeamServer'] = [ordered] @{
                ServerName = $VBRServer.DnsName
                Version = $VBRServer.ProductVersion.ToString()
            }
        } catch {
            # Fallback: use Connect-VBRServer state if the class is unavailable
            try {
                $ConnState = [Veeam.Backup.Connection.VBRConnection]::Current
                if ($ConnState) {
                    $Diag['VeeamServer'] = [ordered] @{
                        ServerName = $ConnState.BackupServerName
                        IsConnected = $ConnState.IsConnected
                    }
                } else {
                    $Diag['VeeamServer'] = 'No active VBR connection detected.'
                }
            } catch {
                $Diag['VeeamServer'] = 'Veeam assemblies not loaded or no connection: ' + $_.Exception.Message
            }
        }

        # --- $Error variable collection -----------------------------------------
        try {
            $MaxErrors = if ($IncludeErrorDetails) { $Error.Count } else { [math]::Min(25, $Error.Count) }
            $ErrorCollection = for ($i = 0; $i -lt $MaxErrors; $i++) {
                $Err = $Error[$i]
                if ($null -eq $Err) { continue }
                $ErrObj = [ordered] @{
                    Index = $i
                    Message = $Err.Exception.Message
                    Type = $Err.Exception.GetType().FullName
                    Category = $Err.CategoryInfo.Category.ToString()
                    TargetName = $Err.CategoryInfo.TargetName
                    ScriptName = $Err.InvocationInfo.ScriptName
                    LineNumber = $Err.InvocationInfo.ScriptLineNumber
                    Line = $Err.InvocationInfo.Line -replace '\s+', ' '
                    CommandName = $Err.InvocationInfo.MyCommand.Name
                }
                if ($IncludeErrorDetails) {
                    $ErrObj['StackTrace'] = $Err.Exception.StackTrace
                    $ErrObj['InnerException'] = if ($Err.Exception.InnerException) { $Err.Exception.InnerException.Message } else { $null }
                }
                $ErrObj
            }
            $Diag['ErrorLog'] = [ordered] @{
                TotalErrors = $Error.Count
                CapturedErrors = $MaxErrors
                FullDetails = $IncludeErrorDetails.IsPresent
                Errors = @($ErrorCollection)
            }
        } catch {
            $Diag['ErrorLog'] = "Error collecting `$Error log: $($_.Exception.Message)"
        }

        # --- Environment variables (safe subset) --------------------------------
        try {
            $SafeEnvVars = @('COMPUTERNAME', 'USERNAME', 'USERDOMAIN', 'USERDNSDOMAIN',
                'OS', 'PROCESSOR_ARCHITECTURE', 'NUMBER_OF_PROCESSORS',
                'TEMP', 'TMP', 'APPDATA', 'LOCALAPPDATA', 'PSModulePath')
            $EnvInfo = [ordered] @{}
            foreach ($VarName in $SafeEnvVars) {
                $EnvInfo[$VarName] = [System.Environment]::GetEnvironmentVariable($VarName)
            }
            $Diag['EnvironmentVariables'] = $EnvInfo
        } catch {
            $Diag['EnvironmentVariables'] = "Error collecting environment variables: $($_.Exception.Message)"
        }

        # --- Write output file --------------------------------------------------
        $DiagObject = [pscustomobject] $Diag
        try {
            $DiagObject | ConvertTo-Json | Set-Content -Path $OutputFile -Encoding UTF8 -Force
            Write-Host "  [Collect-AbrVbrLogs] Diagnostic bundle saved to: $OutputFile" -ForegroundColor Green
        } catch {
            Write-Warning "Collect-AbrVbrLogs: Failed to write diagnostic file '$OutputFile': $($_.Exception.Message)"
        }

        if ($PassThru) {
            $DiagObject
        }
    }

    end {
        Write-Verbose 'Collect-AbrVbrLogs: Diagnostic collection complete.'
    }
}
