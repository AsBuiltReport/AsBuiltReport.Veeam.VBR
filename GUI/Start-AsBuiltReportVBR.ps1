#Requires -Version 7.4
<#
.SYNOPSIS
    GUI launcher for AsBuiltReport.Veeam.VBR — runs entirely in PowerShell 7.
.DESCRIPTION
    A PowerShell 7.4+ desktop GUI (GliderUI / Avalonia) that collects connection,
    output and report options, then generates the Veeam VBR As-Built Report by
    calling New-AsBuiltReport directly — no child PS5.1 process required.
.NOTES
    Requirements:
        PowerShell 7.4+                       — to run this script
        GliderUI (auto-installed on first run) — Install-PSResource -Name GliderUI
        AsBuiltReport.Core                    — Install-PSResource -Name AsBuiltReport.Core
        AsBuiltReport.Veeam.VBR               — Install-PSResource -Name AsBuiltReport.Veeam.VBR
        Veeam B&R console / PS module         — must be installed on this machine
#>

using namespace GliderUI
using namespace GliderUI.Avalonia
using namespace GliderUI.Avalonia.Controls
using namespace GliderUI.Avalonia.Controls.Primitives

# ── Bootstrap GliderUI ──────────────────────────────────────────────────────
if (-not (Get-Module -ListAvailable -Name GliderUI)) {
    Write-Host 'GliderUI not found — installing from PSGallery…' -ForegroundColor Cyan
    Install-PSResource -Name GliderUI -Scope CurrentUser -TrustRepository
}
Import-Module GliderUI -Force

# Thread-safe store shared between the main runspace and the report runspace
$syncHash = [Hashtable]::Synchronized(@{
    CancelRequested = $false
})

# ── UI Helper Functions ─────────────────────────────────────────────────────
function New-SectionTitle ([string]$Text) {
    $tb = [TextBlock]::new()
    $tb.Text       = $Text
    $tb.FontSize   = 13
    $tb.FontWeight = 'SemiBold'
    $tb.Margin     = '0,18,0,6'
    return $tb
}

function New-FormRow ([string]$Label, $Control, [int]$LabelWidth = 185) {
    $row = [StackPanel]::new()
    $row.Orientation = 'Horizontal'
    $row.Spacing     = 10
    $row.Margin      = '0,3,0,3'

    $lbl                   = [TextBlock]::new()
    $lbl.Text              = $Label
    $lbl.Width             = $LabelWidth
    $lbl.VerticalAlignment = 'Center'
    $lbl.FontSize          = 12

    $row.Children.Add($lbl)
    $row.Children.Add($Control)
    return $row
}

function New-InlineLabel ([string]$Text) {
    $tb                   = [TextBlock]::new()
    $tb.Text              = $Text
    $tb.VerticalAlignment = 'Center'
    $tb.Margin            = '8,0,0,0'
    $tb.FontSize          = 12
    return $tb
}

# ── Connection Controls ─────────────────────────────────────────────────────
$txtServer           = [TextBox]::new()
$txtServer.Width     = 270
$txtServer.Watermark = 'hostname or IP address'

$nudPort           = [NumericUpDown]::new()
$nudPort.Value     = 9392
$nudPort.Minimum   = 1
$nudPort.Maximum   = 65535
$nudPort.Width     = 88
$nudPort.Increment = 1
try { $nudPort.FormatString = '0' } catch { }

$serverRow = [StackPanel]::new()
$serverRow.Orientation = 'Horizontal'
$serverRow.Spacing     = 6
$serverRow.Children.Add($txtServer)
$serverRow.Children.Add((New-InlineLabel 'Port'))
$serverRow.Children.Add($nudPort)

$txtUser           = [TextBox]::new()
$txtUser.Width     = 300
$txtUser.Watermark = 'DOMAIN\username  or  username'

$txtPass           = [TextBox]::new()
$txtPass.Width     = 300
$txtPass.Watermark = 'Password'
try { $txtPass.PasswordChar = [char]'●' } catch { }

# ── Output Controls ─────────────────────────────────────────────────────────
$chkHTML = [CheckBox]::new(); $chkHTML.Content = 'HTML'; $chkHTML.IsChecked = $true
$chkWord = [CheckBox]::new(); $chkWord.Content = 'Word'; $chkWord.IsChecked = $false
$chkText = [CheckBox]::new(); $chkText.Content = 'Text'; $chkText.IsChecked = $false

$fmtPanel = [StackPanel]::new()
$fmtPanel.Orientation = 'Horizontal'
$fmtPanel.Spacing     = 20
$fmtPanel.Children.Add($chkHTML)
$fmtPanel.Children.Add($chkWord)
$fmtPanel.Children.Add($chkText)

$txtOutput       = [TextBox]::new()
$txtOutput.Width = 310
$txtOutput.Text  = [System.IO.Path]::Combine($env:USERPROFILE, 'Documents', 'AsBuiltReport')

$btnBrowse         = [Button]::new()
$btnBrowse.Content = 'Browse…'
$btnBrowse.AddClick({
    try {
        # WinForms FolderBrowserDialog in a dedicated STA runspace
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $rs  = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
        $rs.ApartmentState = 'STA'
        $rs.Open()
        $ps  = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs
        [void]$ps.AddScript({
            Add-Type -AssemblyName System.Windows.Forms
            $dlg             = [System.Windows.Forms.FolderBrowserDialog]::new()
            $dlg.Description = 'Select report output folder'
            if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $dlg.SelectedPath }
        })
        $selected = $ps.Invoke()[0]
        $ps.Dispose(); $rs.Dispose()
        if (-not [string]::IsNullOrEmpty($selected)) { $txtOutput.Text = $selected }
    } catch { }
})

$outputPathRow = [StackPanel]::new()
$outputPathRow.Orientation = 'Horizontal'
$outputPathRow.Spacing     = 8
$outputPathRow.Children.Add($txtOutput)
$outputPathRow.Children.Add($btnBrowse)

$cboStyle = [ComboBox]::new()
$cboStyle.Width = 120
$cboStyle.Items.Add('Veeam')   | Out-Null
$cboStyle.Items.Add('Default') | Out-Null
$cboStyle.SelectedIndex = 0

$cboLang = [ComboBox]::new()
$cboLang.Width = 100
$cboLang.Items.Add('en-US') | Out-Null
$cboLang.Items.Add('es-ES') | Out-Null
$cboLang.SelectedIndex = 0

$styleRow = [StackPanel]::new()
$styleRow.Orientation = 'Horizontal'
$styleRow.Spacing     = 8
$styleRow.Children.Add($cboStyle)
$styleRow.Children.Add((New-InlineLabel 'Language'))
$styleRow.Children.Add($cboLang)

# ── Report Name ─────────────────────────────────────────────────────────────
$txtReportName          = [TextBox]::new()
$txtReportName.Width    = 300
$txtReportName.Text     = 'Veeam VBR As-Built Report'
$txtReportName.Watermark = 'Output filename (without extension)'

# ── Options Controls ────────────────────────────────────────────────────────
$swDiagrams  = [ToggleSwitch]::new(); $swDiagrams.IsChecked  = $true
$swExportDia = [ToggleSwitch]::new(); $swExportDia.IsChecked = $true
$swHWInv     = [ToggleSwitch]::new(); $swHWInv.IsChecked     = $false
$swNewIcons  = [ToggleSwitch]::new(); $swNewIcons.IsChecked  = $true
$swHealthChk = [ToggleSwitch]::new(); $swHealthChk.IsChecked = $true
$swTimestamp = [ToggleSwitch]::new(); $swTimestamp.IsChecked = $true

$cboDiagTheme = [ComboBox]::new()
$cboDiagTheme.Width = 120
$cboDiagTheme.Items.Add('White') | Out-Null
$cboDiagTheme.Items.Add('Black') | Out-Null
$cboDiagTheme.Items.Add('Neon')  | Out-Null
$cboDiagTheme.SelectedIndex = 0

$nudColSize           = [NumericUpDown]::new()
$nudColSize.Value     = 3
$nudColSize.Minimum   = 1
$nudColSize.Maximum   = 10
$nudColSize.Width     = 72
$nudColSize.Increment = 1
try { $nudColSize.FormatString = '0' } catch { }

# ── InfoLevel Controls ───────────────────────────────────────────────────────
function New-LevelCombo {
    $cbo = [ComboBox]::new()
    $cbo.Width = 70
    @('0 - Off', '1 - Enabled', '2 - Adv Summary', '3 - Detailed') | ForEach-Object { $cbo.Items.Add($_) | Out-Null }
    $cbo.SelectedIndex = 1
    return $cbo
}

$cboLvlBackupServer  = New-LevelCombo
$cboLvlProxy         = New-LevelCombo
$cboLvlRepository    = New-LevelCombo
$cboLvlBackupJobs    = New-LevelCombo
$cboLvlReplica       = New-LevelCombo
$cboLvlTape          = New-LevelCombo
$cboLvlCloudConnect  = New-LevelCombo

# ── Progress Bar & Log ──────────────────────────────────────────────────────
$progressBar                 = [ProgressBar]::new()
$progressBar.IsIndeterminate = $true
$progressBar.IsVisible       = $false
$progressBar.Margin          = '0,8,0,4'
$syncHash.progressBar        = $progressBar

$txtLog               = [TextBox]::new()
$txtLog.IsReadOnly    = $true
$txtLog.AcceptsReturn = $true
$txtLog.Height        = 220
$txtLog.FontSize      = 11
$txtLog.TextWrapping  = 'Wrap'
$txtLog.Watermark     = 'Output log will appear here…'
try { $txtLog.FontFamily = 'Consolas,Courier New,Monospace' } catch { }
$syncHash.txtLog = $txtLog

# ── Action Buttons ──────────────────────────────────────────────────────────
$btnCancel                     = [Button]::new()
$btnCancel.Content             = '✕  Cancel'
$btnCancel.IsVisible           = $false
$btnCancel.HorizontalAlignment = 'Right'
$btnCancel.Margin              = '0,6,0,0'
$btnCancel.AddClick({ $syncHash.CancelRequested = $true })
$syncHash.btnCancel = $btnCancel

$btnGenerate                            = [Button]::new()
$btnGenerate.Content                    = '▶  Generate Report'
$btnGenerate.HorizontalAlignment        = 'Stretch'
$btnGenerate.HorizontalContentAlignment = 'Center'
$btnGenerate.FontSize                   = 14
$btnGenerate.FontWeight                 = 'SemiBold'
$btnGenerate.Margin                     = '0,22,0,0'
$btnGenerate.Classes.Add('accent')
$syncHash.btnGenerate = $btnGenerate

# ── Generate Callback (PS7 background runspace — no child process needed) ───
$generateCallback                              = [EventCallback]::new()
$generateCallback.RunspaceMode                 = 'RunspacePoolAsyncUI'
$generateCallback.DisabledControlsWhileProcessing = $btnGenerate

$generateCallback.ArgumentList = @{
    SyncHash    = $syncHash
    Server      = $txtServer
    Port        = $nudPort
    Username    = $txtUser
    Password    = $txtPass
    ReportName  = $txtReportName
    OutPath     = $txtOutput
    FmtHTML     = $chkHTML
    FmtWord     = $chkWord
    FmtText     = $chkText
    Style       = $cboStyle
    Lang        = $cboLang
    DiagTheme   = $cboDiagTheme
    DiagColSize = $nudColSize
    Diagrams    = $swDiagrams
    ExportDia   = $swExportDia
    HWInv       = $swHWInv
    NewIcons    = $swNewIcons
    HealthChk   = $swHealthChk
    Timestamp   = $swTimestamp
    LvlBackupServer = $cboLvlBackupServer
    LvlProxy        = $cboLvlProxy
    LvlRepository   = $cboLvlRepository
    LvlBackupJobs   = $cboLvlBackupJobs
    LvlReplica      = $cboLvlReplica
    LvlTape         = $cboLvlTape
    LvlCloudConnect = $cboLvlCloudConnect
}

$generateCallback.ScriptBlock = {
    param ($ui)

    $sh = $ui.SyncHash
    $sh.CancelRequested       = $false
    $sh.progressBar.IsVisible = $true
    $sh.btnCancel.IsVisible   = $true
    $sh.txtLog.Text           = ''

    function Write-Log ([string]$Msg, [string]$Level = 'INFO') {
        $ts = Get-Date -Format 'HH:mm:ss'
        $sh.txtLog.Text += "[$ts][$Level] $Msg`n"
    }

    # ── Collect values ───────────────────────────────────────────────────────
    $server     = $ui.Server.Text.Trim()
    $port       = [int]$ui.Port.Value
    $username   = $ui.Username.Text.Trim()
    $password   = $ui.Password.Text
    $reportName = $ui.ReportName.Text.Trim()
    $outPath    = $ui.OutPath.Text.Trim()
    $style      = [string]$ui.Style.SelectedItem
    $lang       = [string]$ui.Lang.SelectedItem
    $theme      = [string]$ui.DiagTheme.SelectedItem
    $colSize    = [int]$ui.DiagColSize.Value

    $formats = @()
    if ($ui.FmtHTML.IsChecked -eq $true) { $formats += 'HTML' }
    if ($ui.FmtWord.IsChecked -eq $true) { $formats += 'Word' }
    if ($ui.FmtText.IsChecked -eq $true) { $formats += 'Text' }
    if ($formats.Count -eq 0)            { $formats  = @('HTML') }

    $enableDiagrams = [bool]$ui.Diagrams.IsChecked
    $exportDiagrams = [bool]$ui.ExportDia.IsChecked
    $hwInventory    = [bool]$ui.HWInv.IsChecked
    $newIcons       = [bool]$ui.NewIcons.IsChecked
    $healthCheck    = [bool]$ui.HealthChk.IsChecked
    $addTimestamp   = [bool]$ui.Timestamp.IsChecked

    # Parse InfoLevel (first char = number) — passed to Build-VbrConfigObject below
    $lvlBackupServer = [int]([string]$ui.LvlBackupServer.SelectedItem)[0]
    $lvlProxy        = [int]([string]$ui.LvlProxy.SelectedItem)[0]
    $lvlRepository   = [int]([string]$ui.LvlRepository.SelectedItem)[0]
    $lvlBackupJobs   = [int]([string]$ui.LvlBackupJobs.SelectedItem)[0]
    $lvlReplica      = [int]([string]$ui.LvlReplica.SelectedItem)[0]
    $lvlTape         = [int]([string]$ui.LvlTape.SelectedItem)[0]
    $lvlCloudConnect = [int]([string]$ui.LvlCloudConnect.SelectedItem)[0]

    # ── Validation ───────────────────────────────────────────────────────────
    if ([string]::IsNullOrWhiteSpace($server)) {
        Write-Log 'VBR Server address is required.' 'ERROR'
        $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
    }
    if ([string]::IsNullOrWhiteSpace($username)) {
        Write-Log 'Username is required.' 'ERROR'
        $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
    }
    if ([string]::IsNullOrWhiteSpace($password)) {
        Write-Log 'Password is required.' 'ERROR'
        $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
    }
    if ([string]::IsNullOrWhiteSpace($outPath)) {
        $outPath = Join-Path $env:USERPROFILE 'Documents\AsBuiltReport'
    }
    if (-not (Test-Path $outPath)) {
        New-Item -Path $outPath -ItemType Directory -Force | Out-Null
        Write-Log "Created output folder: $outPath"
    }
    if ([string]::IsNullOrWhiteSpace($reportName)) { $reportName = 'Veeam VBR As-Built Report' }

    Write-Log "Target   : $server`:$port"
    Write-Log "Username : $username"
    Write-Log "Formats  : $($formats -join ', ')"
    Write-Log "Output   : $outPath"
    Write-Log "Style    : $style  |  Language: $lang"

    # ── Import modules in this runspace ──────────────────────────────────────
    Write-Log 'Loading AsBuiltReport modules…'
    try {
        Import-Module AsBuiltReport.Core    -Force -ErrorAction Stop
        Import-Module AsBuiltReport.Veeam.VBR -Force -ErrorAction Stop
    } catch {
        Write-Log "Failed to load modules: $_" 'ERROR'
        $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
    }

    # ── Build config using shared helper ────────────────────────────────────────
    function Get-Level ($cbo) { [int]([string]$cbo.SelectedItem)[0] }

    $configObj = Build-VbrConfigObject `
        -ReportName   $reportName `
        -Style        $style `
        -Lang         $lang `
        -Port         $port `
        -Theme        $theme `
        -ColSize      $colSize `
        -EnableDiagrams $enableDiagrams `
        -ExportDiagrams $exportDiagrams `
        -HWInv        $hwInventory `
        -NewIcons     $newIcons `
        -HealthCheck  $healthCheck `
        -LvlBackupServer (Get-Level $ui.LvlBackupServer) `
        -LvlProxy        (Get-Level $ui.LvlProxy) `
        -LvlRepository   (Get-Level $ui.LvlRepository) `
        -LvlBackupJobs   (Get-Level $ui.LvlBackupJobs) `
        -LvlReplica      (Get-Level $ui.LvlReplica) `
        -LvlTape         (Get-Level $ui.LvlTape) `
        -LvlCloudConnect (Get-Level $ui.LvlCloudConnect)

    $tempConfig = Join-Path $env:TEMP "VBR_AsBuilt_$(New-Guid).json"
    $configObj | ConvertTo-Json -Depth 6 | Set-Content -Path $tempConfig -Encoding UTF8

    # ── Build credential and invoke New-AsBuiltReport ─────────────────────────
    try {
        if ($sh.CancelRequested) { Write-Log 'Cancelled before start.' 'WARN'; return }

        Write-Log 'Starting report generation (PS7 native)…'
        $secPass = ConvertTo-SecureString $password -AsPlainText -Force
        $cred    = [System.Management.Automation.PSCredential]::new($username, $secPass)

        $params = @{
            Report               = 'Veeam.VBR'
            Target               = $server
            Credential           = $cred
            OutputFolderPath     = $outPath
            Format               = $formats
            ReportConfigFilePath = $tempConfig
        }
        if ($addTimestamp)  { $params['Timestamp']         = $true }
        if ($healthCheck)   { $params['EnableHealthCheck'] = $true }

        New-AsBuiltReport @params

        Write-Log ''
        Write-Log "Report saved to: $outPath" 'SUCCESS'
    } catch {
        Write-Log $_.Exception.Message 'ERROR'
        if ($_.ScriptStackTrace) { Write-Log $_.ScriptStackTrace 'ERROR' }
    } finally {
        Remove-Item -Path $tempConfig -Force -ErrorAction SilentlyContinue
        $sh.progressBar.IsVisible = $false
        $sh.btnCancel.IsVisible   = $false
    }
}

$btnGenerate.AddClick($generateCallback)

# ── Config Helper: build the config object from current UI controls ─────────
function Build-VbrConfigObject {
    param (
        [string]$ReportName, [string]$Style, [string]$Lang,
        [int]$Port, [string]$Theme, [int]$ColSize,
        [bool]$EnableDiagrams, [bool]$ExportDiagrams, [bool]$HWInv,
        [bool]$NewIcons, [bool]$HealthCheck,
        [int]$LvlBackupServer, [int]$LvlProxy, [int]$LvlRepository,
        [int]$LvlBackupJobs, [int]$LvlReplica, [int]$LvlTape, [int]$LvlCloudConnect
    )
    return [ordered]@{
        Report  = [ordered]@{
            Name                = $ReportName
            Version             = '1.0'
            Status              = 'Released'
            Language            = $Lang
            ShowCoverPageImage  = $true
            ShowTableOfContents = $true
            ShowHeaderFooter    = $true
            ShowTableCaptions   = $true
        }
        Options = [ordered]@{
            ReportStyle             = $Style
            BackupServerPort        = $Port
            EnableDiagrams          = $EnableDiagrams
            ExportDiagrams          = $ExportDiagrams
            EnableHardwareInventory = $HWInv
            DiagramTheme            = $Theme
            DiagramColumnSize       = $ColSize
            NewIcons                = $NewIcons
            EnableDiagramDebug      = $false
            DiagramWaterMark        = ''
            ExportDiagramsFormat    = @('pdf')
            EnableDiagramSignature  = $false
            SignatureAuthorName     = ''
            SignatureCompanyName    = ''
            PSDefaultAuthentication = 'Default'
            RoundUnits              = 1
            UpdateCheck             = $false
            IsLocalServer           = $false
            ShowExecutionTime       = $false
        }
        InfoLevel = [ordered]@{
            Infrastructure = [ordered]@{
                BackupServer    = $LvlBackupServer
                BR              = $LvlRepository
                Licenses        = 1
                Proxy           = $LvlProxy
                Settings        = 1
                SOBR            = $LvlRepository
                ServiceProvider = 1
                SureBackup      = 1
                WANAccel        = 1
            }
            Tape = [ordered]@{
                Library = $LvlTape; MediaPool = $LvlTape
                NDMP    = $LvlTape; Server    = $LvlTape; Vault = $LvlTape
            }
            Inventory   = [ordered]@{ EntraID = 1; FileShare = 1; Nutanix = 1; PHY = 1; VI = 1 }
            Storage     = [ordered]@{ ISILON = 1; ONTAP = 1 }
            Replication = [ordered]@{ FailoverPlan = $LvlReplica; Replica = $LvlReplica }
            CloudConnect = [ordered]@{
                BackupStorage = $LvlCloudConnect; Certificate      = $LvlCloudConnect
                CloudGateway  = $LvlCloudConnect; GatewayPools     = $LvlCloudConnect
                PublicIP      = $LvlCloudConnect; ReplicaResources = $LvlCloudConnect
                Tenants       = $LvlCloudConnect
            }
            Jobs = [ordered]@{
                Agent = $LvlBackupJobs; Backup = $LvlBackupJobs; BackupCopy = $LvlBackupJobs
                EntraID = $LvlBackupJobs; FileShare = $LvlBackupJobs; Nutanix = $LvlBackupJobs
                Surebackup = $LvlBackupJobs; Replication = $LvlReplica; Restores = 0; Tape = $LvlTape
            }
        }
        HealthCheck = [ordered]@{
            Infrastructure = [ordered]@{
                BackupServer = $HealthCheck; Proxy = $HealthCheck; Settings = $HealthCheck
                BR = $HealthCheck; SOBR = $HealthCheck; Server = $HealthCheck
                Status = $HealthCheck; BestPractice = $HealthCheck
            }
            Tape         = [ordered]@{ Status = $HealthCheck; BestPractice = $HealthCheck }
            Replication  = [ordered]@{ Status = $HealthCheck; BestPractice = $HealthCheck }
            Security     = [ordered]@{ BestPractice = $HealthCheck }
            CloudConnect = [ordered]@{
                Tenants = $HealthCheck; BackupStorage = $HealthCheck
                ReplicaResources = $HealthCheck; BestPractice = $HealthCheck
            }
            Jobs = [ordered]@{ Status = $HealthCheck; BestPractice = $HealthCheck }
        }
    }
}

# ── Config Management Controls ───────────────────────────────────────────────
$txtConfigPath          = [TextBox]::new()
$txtConfigPath.Width    = 298
$txtConfigPath.Watermark = 'Path to .json config file'
$txtConfigPath.Text     = [System.IO.Path]::Combine(
    $env:USERPROFILE, 'Documents', 'AsBuiltReport', 'AsBuiltReport.Veeam.VBR.json')

$btnBrowseConfig         = [Button]::new()
$btnBrowseConfig.Content = 'Browse…'
$btnBrowseConfig.AddClick({
    try {
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $rs  = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($iss)
        $rs.ApartmentState = 'STA'; $rs.Open()
        $ps  = [System.Management.Automation.PowerShell]::Create()
        $ps.Runspace = $rs
        [void]$ps.AddScript({
            Add-Type -AssemblyName System.Windows.Forms
            $dlg = [System.Windows.Forms.OpenFileDialog]::new()
            $dlg.Title  = 'Select AsBuiltReport Config File'
            $dlg.Filter = 'JSON Config|*.json|All Files|*.*'
            if ($dlg.ShowDialog() -eq 'OK') { $dlg.FileName }
        })
        $selected = $ps.Invoke()[0]
        $ps.Dispose(); $rs.Dispose()
        if (-not [string]::IsNullOrEmpty($selected)) { $txtConfigPath.Text = $selected }
    } catch { }
})

$configPathRow = [StackPanel]::new()
$configPathRow.Orientation = 'Horizontal'
$configPathRow.Spacing     = 8
$configPathRow.Children.Add($txtConfigPath)
$configPathRow.Children.Add($btnBrowseConfig)

$lblConfigStatus          = [TextBlock]::new()
$lblConfigStatus.FontSize = 11
$lblConfigStatus.Margin   = '0,4,0,0'
$lblConfigStatus.Text     = ''
$syncHash.lblConfigStatus = $lblConfigStatus

# ── Save Config Button ────────────────────────────────────────────────────────
$btnSaveConfig                            = [Button]::new()
$btnSaveConfig.Content                    = '💾  Save Config'
$btnSaveConfig.HorizontalAlignment        = 'Stretch'
$btnSaveConfig.HorizontalContentAlignment = 'Center'
$btnSaveConfig.Width                      = 196
$btnSaveConfig.Margin                     = '0,0,4,0'

$btnSaveConfig.AddClick({
    $destPath = $txtConfigPath.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($destPath)) {
        $syncHash.lblConfigStatus.Text = '⚠ Please enter a destination path first.'
        return
    }

    try {
        # Ensure parent folder exists
        $parent = Split-Path $destPath -Parent
        if (-not [string]::IsNullOrEmpty($parent) -and -not (Test-Path $parent)) {
            New-Item -Path $parent -ItemType Directory -Force | Out-Null
        }

        function Get-LevelVal ($cbo) { [int]([string]$cbo.SelectedItem)[0] }

        $configObj = Build-VbrConfigObject `
            -ReportName   ($txtReportName.Text.Trim() -or 'Veeam VBR As-Built Report') `
            -Style        ([string]$cboStyle.SelectedItem) `
            -Lang         ([string]$cboLang.SelectedItem) `
            -Port         ([int]$nudPort.Value) `
            -Theme        ([string]$cboDiagTheme.SelectedItem) `
            -ColSize      ([int]$nudColSize.Value) `
            -EnableDiagrams ([bool]$swDiagrams.IsChecked) `
            -ExportDiagrams ([bool]$swExportDia.IsChecked) `
            -HWInv        ([bool]$swHWInv.IsChecked) `
            -NewIcons     ([bool]$swNewIcons.IsChecked) `
            -HealthCheck  ([bool]$swHealthChk.IsChecked) `
            -LvlBackupServer (Get-LevelVal $cboLvlBackupServer) `
            -LvlProxy        (Get-LevelVal $cboLvlProxy) `
            -LvlRepository   (Get-LevelVal $cboLvlRepository) `
            -LvlBackupJobs   (Get-LevelVal $cboLvlBackupJobs) `
            -LvlReplica      (Get-LevelVal $cboLvlReplica) `
            -LvlTape         (Get-LevelVal $cboLvlTape) `
            -LvlCloudConnect (Get-LevelVal $cboLvlCloudConnect)

        $configObj | ConvertTo-Json -Depth 6 | Set-Content -Path $destPath -Encoding UTF8
        $syncHash.lblConfigStatus.Text = "✅ Config saved: $destPath"
    } catch {
        $syncHash.lblConfigStatus.Text = "❌ Save failed: $_"
    }
})

# ── Load Config Button ────────────────────────────────────────────────────────
$btnLoadConfig                            = [Button]::new()
$btnLoadConfig.Content                    = '📂  Load Config'
$btnLoadConfig.HorizontalAlignment        = 'Stretch'
$btnLoadConfig.HorizontalContentAlignment = 'Center'
$btnLoadConfig.Width                      = 196
$btnLoadConfig.Margin                     = '4,0,0,0'

$btnLoadConfig.AddClick({
    $srcPath = $txtConfigPath.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($srcPath) -or -not (Test-Path $srcPath)) {
        $syncHash.lblConfigStatus.Text = '⚠ Config file not found.'
        return
    }

    try {
        $json = Get-Content -Path $srcPath -Raw -Encoding UTF8 | ConvertFrom-Json

        # Helper: find ComboBox index for a value, default to 0
        function Set-ComboByValue ($cbo, [string]$value) {
            for ($i = 0; $i -lt $cbo.Items.Count; $i++) {
                if ([string]$cbo.Items[$i] -eq $value) { $cbo.SelectedIndex = $i; return }
            }
            $cbo.SelectedIndex = 0
        }

        # Helper: set InfoLevel combo (index = int value 0-3)
        function Set-LevelCombo ($cbo, $value) {
            $idx = [Math]::Max(0, [Math]::Min(3, [int]$value))
            $cbo.SelectedIndex = $idx
        }

        # Report section
        if ($json.Report.Name)     { $txtReportName.Text = $json.Report.Name }
        if ($json.Report.Language) { Set-ComboByValue $cboLang $json.Report.Language }

        # Options section
        if ($null -ne $json.Options.BackupServerPort) { $nudPort.Value   = $json.Options.BackupServerPort }
        if ($json.Options.ReportStyle)                { Set-ComboByValue $cboStyle $json.Options.ReportStyle }
        if ($json.Options.DiagramTheme)               { Set-ComboByValue $cboDiagTheme $json.Options.DiagramTheme }
        if ($null -ne $json.Options.DiagramColumnSize){ $nudColSize.Value = $json.Options.DiagramColumnSize }
        if ($null -ne $json.Options.EnableDiagrams)   { $swDiagrams.IsChecked  = [bool]$json.Options.EnableDiagrams }
        if ($null -ne $json.Options.ExportDiagrams)   { $swExportDia.IsChecked = [bool]$json.Options.ExportDiagrams }
        if ($null -ne $json.Options.EnableHardwareInventory) { $swHWInv.IsChecked = [bool]$json.Options.EnableHardwareInventory }
        if ($null -ne $json.Options.NewIcons)         { $swNewIcons.IsChecked = [bool]$json.Options.NewIcons }

        # InfoLevel section
        if ($null -ne $json.InfoLevel) {
            if ($null -ne $json.InfoLevel.Infrastructure) {
                Set-LevelCombo $cboLvlBackupServer $json.InfoLevel.Infrastructure.BackupServer
                Set-LevelCombo $cboLvlProxy        $json.InfoLevel.Infrastructure.Proxy
                Set-LevelCombo $cboLvlRepository   $json.InfoLevel.Infrastructure.BR
            }
            if ($null -ne $json.InfoLevel.Jobs) {
                Set-LevelCombo $cboLvlBackupJobs $json.InfoLevel.Jobs.Backup
            }
            if ($null -ne $json.InfoLevel.Replication) {
                Set-LevelCombo $cboLvlReplica $json.InfoLevel.Replication.Replica
            }
            if ($null -ne $json.InfoLevel.Tape) {
                Set-LevelCombo $cboLvlTape $json.InfoLevel.Tape.Library
            }
            if ($null -ne $json.InfoLevel.CloudConnect) {
                Set-LevelCombo $cboLvlCloudConnect $json.InfoLevel.CloudConnect.Tenants
            }
        }

        # HealthCheck section — any true value means health checks are on
        if ($null -ne $json.HealthCheck) {
            $anyHC = $json.HealthCheck.PSObject.Properties.Value |
                     Where-Object { $_ -is [System.Management.Automation.PSCustomObject] } |
                     ForEach-Object { $_.PSObject.Properties.Value } |
                     Where-Object { $_ -eq $true } |
                     Select-Object -First 1
            $swHealthChk.IsChecked = ($null -ne $anyHC)
        }

        $syncHash.lblConfigStatus.Text = "✅ Config loaded: $(Split-Path $srcPath -Leaf)"
    } catch {
        $syncHash.lblConfigStatus.Text = "❌ Load failed: $_"
    }
})

# ── Assemble Main Layout ────────────────────────────────────────────────────
$mainPanel        = [StackPanel]::new()
$mainPanel.Margin = '28,20,28,24'
$mainPanel.Spacing = 2

# Header
$headerPanel                     = [StackPanel]::new()
$headerPanel.HorizontalAlignment = 'Center'
$headerPanel.Spacing             = 4
$headerPanel.Margin              = '0,0,0,4'

$hTitle                     = [TextBlock]::new()
$hTitle.Text                = 'Veeam Backup & Replication'
$hTitle.FontSize            = 22
$hTitle.FontWeight          = 'Bold'
$hTitle.HorizontalAlignment = 'Center'

$hSub                     = [TextBlock]::new()
$hSub.Text                = 'As-Built Report Generator'
$hSub.FontSize            = 13
$hSub.HorizontalAlignment = 'Center'

$headerPanel.Children.Add($hTitle)
$headerPanel.Children.Add($hSub)
$mainPanel.Children.Add($headerPanel)

# Section: Connection
$mainPanel.Children.Add((New-SectionTitle '🔌  Server Connection'))
$mainPanel.Children.Add((New-FormRow 'VBR Server'   $serverRow))
$mainPanel.Children.Add((New-FormRow 'Username'     $txtUser))
$mainPanel.Children.Add((New-FormRow 'Password'     $txtPass))

# Section: Report Output
$mainPanel.Children.Add((New-SectionTitle '📄  Report Output'))
$mainPanel.Children.Add((New-FormRow 'Report Name'   $txtReportName))
$mainPanel.Children.Add((New-FormRow 'Format'        $fmtPanel))
$mainPanel.Children.Add((New-FormRow 'Output Folder' $outputPathRow))
$mainPanel.Children.Add((New-FormRow 'Report Style'  $styleRow))

# Section: Options
$mainPanel.Children.Add((New-SectionTitle '⚙️  Options'))
$mainPanel.Children.Add((New-FormRow 'Enable Diagrams'     $swDiagrams))
$mainPanel.Children.Add((New-FormRow 'Export Diagrams'     $swExportDia))
$mainPanel.Children.Add((New-FormRow 'Hardware Inventory'  $swHWInv))
$mainPanel.Children.Add((New-FormRow 'Use New Icons'       $swNewIcons))
$mainPanel.Children.Add((New-FormRow 'Enable Health Check' $swHealthChk))
$mainPanel.Children.Add((New-FormRow 'Add Timestamp'       $swTimestamp))
$mainPanel.Children.Add((New-FormRow 'Diagram Theme'       $cboDiagTheme))
$mainPanel.Children.Add((New-FormRow 'Diagram Columns'     $nudColSize))

# Section: InfoLevel
$mainPanel.Children.Add((New-SectionTitle '📊  Info Level'))
$mainPanel.Children.Add((New-FormRow 'Backup Server'  $cboLvlBackupServer))
$mainPanel.Children.Add((New-FormRow 'Proxy'          $cboLvlProxy))
$mainPanel.Children.Add((New-FormRow 'Repository'     $cboLvlRepository))
$mainPanel.Children.Add((New-FormRow 'Backup Jobs'    $cboLvlBackupJobs))
$mainPanel.Children.Add((New-FormRow 'Replication'    $cboLvlReplica))
$mainPanel.Children.Add((New-FormRow 'Tape'           $cboLvlTape))
$mainPanel.Children.Add((New-FormRow 'Cloud Connect'  $cboLvlCloudConnect))

# Section: Config Management
$mainPanel.Children.Add((New-SectionTitle '🗂️  Config Management'))

$cfgBtnRow = [StackPanel]::new()
$cfgBtnRow.Orientation = 'Horizontal'
$cfgBtnRow.Margin      = '0,4,0,0'
$cfgBtnRow.Children.Add($btnSaveConfig)
$cfgBtnRow.Children.Add($btnLoadConfig)

$mainPanel.Children.Add((New-FormRow 'Config File' $configPathRow))
$mainPanel.Children.Add($cfgBtnRow)
$mainPanel.Children.Add($lblConfigStatus)

# Generate button + progress
$mainPanel.Children.Add($btnGenerate)
$mainPanel.Children.Add($progressBar)

# Log area
$logTitle            = [TextBlock]::new()
$logTitle.Text       = '📋  Output Log'
$logTitle.FontSize   = 13
$logTitle.FontWeight = 'SemiBold'
$logTitle.Margin     = '0,14,0,6'
$mainPanel.Children.Add($logTitle)
$mainPanel.Children.Add($txtLog)
$mainPanel.Children.Add($btnCancel)

$scrollView         = [ScrollViewer]::new()
$scrollView.Content = $mainPanel

# ── Window ──────────────────────────────────────────────────────────────────
$win           = [Window]::new()
$win.Title     = 'Veeam VBR — As-Built Report Generator'
$win.Width     = 700
$win.Height    = 920
$win.MinWidth  = 620
$win.MinHeight = 500
$win.Content   = $scrollView

$win.Show()
$win.WaitForClosed()
