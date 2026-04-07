#Requires -Version 7.4

using namespace GliderUI
using namespace GliderUI.Avalonia
using namespace GliderUI.Avalonia.Controls
using namespace GliderUI.Avalonia.Platform.Storage

function Start-AsBuiltReportVBR {
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

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]

    [CmdletBinding()]
    param()

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
        $tb.Text = $Text
        $tb.FontSize = 13
        $tb.FontWeight = 'SemiBold'
        $tb.Margin = '0,18,0,6'
        return $tb
    }

    function New-FormRow ([string]$Label, $Control, [int]$LabelWidth = 185) {
        $row = [StackPanel]::new()
        $row.Orientation = 'Horizontal'
        $row.Spacing = 10
        $row.Margin = '0,3,0,3'

        $lbl = [TextBlock]::new()
        $lbl.Text = $Label
        $lbl.Width = $LabelWidth
        $lbl.VerticalAlignment = 'Center'
        $lbl.FontSize = 12

        $row.Children.Add($lbl)
        $row.Children.Add($Control)
        return $row
    }

    function New-InlineLabel ([string]$Text) {
        $tb = [TextBlock]::new()
        $tb.Text = $Text
        $tb.VerticalAlignment = 'Center'
        $tb.Margin = '8,0,0,0'
        $tb.FontSize = 12
        return $tb
    }

    # ── Connection Controls ─────────────────────────────────────────────────────
    $txtServer = [TextBox]::new()
    $txtServer.Width = 175
    $txtServer.Watermark = 'hostname or IP address'

    $txtPort = [TextBox]::new()
    $txtPort.Text = '9392'
    $txtPort.Width = 80
    $txtPort.Watermark = 'port'

    $serverRow = [StackPanel]::new()
    $serverRow.Orientation = 'Horizontal'
    $serverRow.Spacing = 6
    $serverRow.Children.Add($txtServer)
    $serverRow.Children.Add((New-InlineLabel 'Port'))
    $serverRow.Children.Add($txtPort)

    $txtUser = [TextBox]::new()
    $txtUser.Width = 200
    $txtUser.Watermark = 'DOMAIN\username  or  username'

    $txtPass = [TextBox]::new()
    $txtPass.Width = 200
    $txtPass.Watermark = 'Password'
    try { $txtPass.PasswordChar = [char]'●' } catch { Out-Null }

    # ── Output Controls ─────────────────────────────────────────────────────────
    $chkHTML = [CheckBox]::new(); $chkHTML.Content = 'HTML'; $chkHTML.IsChecked = $true
    $chkWord = [CheckBox]::new(); $chkWord.Content = 'Word'; $chkWord.IsChecked = $false
    $chkText = [CheckBox]::new(); $chkText.Content = 'Text'; $chkText.IsChecked = $false

    $fmtPanel = [StackPanel]::new()
    $fmtPanel.Orientation = 'Horizontal'
    $fmtPanel.Spacing = 20
    $fmtPanel.Children.Add($chkHTML)
    $fmtPanel.Children.Add($chkWord)
    $fmtPanel.Children.Add($chkText)

    $txtOutput = [TextBox]::new()
    $txtOutput.Width = 240
    $txtOutput.Text = [System.IO.Path]::Combine($env:USERPROFILE, 'Documents', 'AsBuiltReport')

    $btnBrowse = [Button]::new()
    $btnBrowse.Content = 'Browse…'
    $btnBrowse.AddClick({
            try {
                $storageProvider = [Window]::GetTopLevel($btnBrowse).StorageProvider
                if ($null -eq $storageProvider) {
                    Write-Host 'Storage provider not available.' -ForegroundColor Yellow
                    return
                }
                $options = [FolderPickerOpenOptions]::new()
                $options.Title = 'Select Output Folder Path'
                $folders = $storageProvider.OpenFolderPickerAsync($options).WaitForCompleted()
                if ($folders -and $folders.Count -gt 0) {
                    $txtOutput.Text = $folders[0].Path.LocalPath
                }
            } catch {
                Write-Host "Folder picker error: $_" -ForegroundColor Red
            }
        })

    $outputPathRow = [StackPanel]::new()
    $outputPathRow.Orientation = 'Horizontal'
    $outputPathRow.Spacing = 8
    $outputPathRow.Children.Add($txtOutput)
    $outputPathRow.Children.Add($btnBrowse)

    $cboStyle = [ComboBox]::new()
    $cboStyle.Width = 120
    $cboStyle.Items.Add('Veeam') | Out-Null
    $cboStyle.Items.Add('Default') | Out-Null
    $cboStyle.SelectedIndex = 0

    $cboLang = [ComboBox]::new()
    $cboLang.Width = 100
    $cboLang.Items.Add('en-US') | Out-Null
    $cboLang.Items.Add('es-ES') | Out-Null
    $cboLang.SelectedIndex = 0

    $styleRow = [StackPanel]::new()
    $styleRow.Orientation = 'Horizontal'
    $styleRow.Spacing = 8
    $styleRow.Children.Add($cboStyle)
    $styleRow.Children.Add((New-InlineLabel 'Language'))
    $styleRow.Children.Add($cboLang)

    # ── Report Name ─────────────────────────────────────────────────────────────
    $txtReportName = [TextBox]::new()
    $txtReportName.Width = 300
    $txtReportName.Text = 'Veeam VBR As-Built Report'
    $txtReportName.Watermark = 'Output filename (without extension)'

    # ── Options Controls ────────────────────────────────────────────────────────
    $swDiagrams = [ToggleSwitch]::new(); $swDiagrams.IsChecked = $true
    $swExportDia = [ToggleSwitch]::new(); $swExportDia.IsChecked = $true
    $swHWInv = [ToggleSwitch]::new(); $swHWInv.IsChecked = $false
    $swNewIcons = [ToggleSwitch]::new(); $swNewIcons.IsChecked = $true
    $swHealthChk = [ToggleSwitch]::new(); $swHealthChk.IsChecked = $true
    $swTimestamp = [ToggleSwitch]::new(); $swTimestamp.IsChecked = $true

    $txtColSize = [TextBox]::new()
    $txtColSize.Text = '3'
    $txtColSize.Width = 80
    $txtColSize.Watermark = 'columns'

    # ── InfoLevel Controls ───────────────────────────────────────────────────────
    function New-LevelCombo {
        $cbo = [ComboBox]::new()
        $cbo.Width = 160
        @('0 - Off', '1 - Enabled', '2 - Adv Summary', '3 - Detailed') | ForEach-Object { $cbo.Items.Add($_) | Out-Null }
        $cbo.SelectedIndex = 1
        return $cbo
    }

    $cboLvlInfrastructure = New-LevelCombo
    $cboLvlTape = New-LevelCombo
    $cboLvlInventory = New-LevelCombo
    $cboLvlStorage = New-LevelCombo
    $cboLvlReplication = New-LevelCombo
    $cboLvlCloudConnect = New-LevelCombo
    $cboLvlJobs = New-LevelCombo

    # ── Progress Bar & Log ──────────────────────────────────────────────────────
    $progressBar = [ProgressBar]::new()
    $progressBar.IsIndeterminate = $true
    $progressBar.IsVisible = $false
    $progressBar.Margin = '0,8,0,4'
    $syncHash.progressBar = $progressBar

    $txtLog = [TextBox]::new()
    $txtLog.IsReadOnly = $true
    $txtLog.AcceptsReturn = $true
    $txtLog.Height = 220
    $txtLog.FontSize = 11
    $txtLog.TextWrapping = 'Wrap'
    $txtLog.Watermark = 'Output log will appear here…'
    try { $txtLog.FontFamily = 'Consolas,Courier New,Monospace' } catch { Out-Null }
    $syncHash.txtLog = $txtLog

    # ── Action Buttons ──────────────────────────────────────────────────────────
    $btnCancel = [Button]::new()
    $btnCancel.Content = '✕  Cancel'
    $btnCancel.IsVisible = $false
    $btnCancel.HorizontalAlignment = 'Right'
    $btnCancel.Margin = '0,6,0,0'
    $btnCancel.AddClick({ $syncHash.CancelRequested = $true })
    $syncHash.btnCancel = $btnCancel

    $btnGenerate = [Button]::new()
    $btnGenerate.Content = '▶  Generate Report'
    $btnGenerate.HorizontalAlignment = 'Stretch'
    $btnGenerate.HorizontalContentAlignment = 'Center'
    $btnGenerate.FontSize = 14
    $btnGenerate.FontWeight = 'SemiBold'
    $btnGenerate.Margin = '0,22,0,0'
    $btnGenerate.Classes.Add('accent')
    $syncHash.btnGenerate = $btnGenerate

    # ── Generate Callback (PS7 background runspace — no child process needed) ───
    $generateCallback = [EventCallback]::new()
    $generateCallback.RunspaceMode = 'RunspacePoolAsyncUI'
    $generateCallback.DisabledControlsWhileProcessing = $btnGenerate

    $generateCallback.ArgumentList = @{
        SyncHash = $syncHash
        Server = $txtServer
        Port = $txtPort
        Username = $txtUser
        Password = $txtPass
        ReportName = $txtReportName
        OutPath = $txtOutput
        FmtHTML = $chkHTML
        FmtWord = $chkWord
        FmtText = $chkText
        Style = $cboStyle
        Lang = $cboLang
        DiagColSize = $txtColSize
        Diagrams = $swDiagrams
        ExportDia = $swExportDia
        HWInv = $swHWInv
        NewIcons = $swNewIcons
        HealthChk = $swHealthChk
        Timestamp = $swTimestamp
        LvlInfrastructure = $cboLvlInfrastructure
        LvlTape = $cboLvlTape
        LvlInventory = $cboLvlInventory
        LvlStorage = $cboLvlStorage
        LvlReplication = $cboLvlReplication
        LvlCloudConnect = $cboLvlCloudConnect
        LvlJobs = $cboLvlJobs
    }

    $generateCallback.ScriptBlock = {
        param ($ui)

        $sh = $ui.SyncHash
        $sh.CancelRequested = $false
        $sh.progressBar.IsVisible = $true
        $sh.btnCancel.IsVisible = $true
        $sh.txtLog.Text = ''

        function Write-Logging ([string]$Msg, [string]$Level = 'INFO') {
            $ts = Get-Date -Format 'HH:mm:ss'
            $sh.txtLog.Text += "[$ts][$Level] $Msg`n"
        }

        # ── Collect values ───────────────────────────────────────────────────────
        $server = $ui.Server.Text.Trim()
        $port = [int]$ui.Port.Text
        $username = $ui.Username.Text.Trim()
        $password = $ui.Password.Text
        $reportName = $ui.ReportName.Text.Trim()
        $outPath = $ui.OutPath.Text.Trim()
        $style = [string]$ui.Style.SelectedItem
        $lang = [string]$ui.Lang.SelectedItem
        $theme = [string]$ui.DiagTheme.SelectedItem
        $colSize = [int]$ui.DiagColSize.Text

        $formats = @()
        if ($ui.FmtHTML.IsChecked -eq $true) { $formats += 'HTML' }
        if ($ui.FmtWord.IsChecked -eq $true) { $formats += 'Word' }
        if ($ui.FmtText.IsChecked -eq $true) { $formats += 'Text' }
        if ($formats.Count -eq 0) { $formats = @('HTML') }

        $enableDiagrams = [bool]$ui.Diagrams.IsChecked
        $exportDiagrams = [bool]$ui.ExportDia.IsChecked
        $hwInventory = [bool]$ui.HWInv.IsChecked
        $newIcons = [bool]$ui.NewIcons.IsChecked
        $healthCheck = [bool]$ui.HealthChk.IsChecked
        $addTimestamp = [bool]$ui.Timestamp.IsChecked

        # Parse InfoLevel (first char = number) — passed to Build-VbrConfigObject below
        $lvlInfrastructure = [int]([string]$ui.LvlInfrastructure.SelectedItem)[0]
        $lvlTape = [int]([string]$ui.LvlTape.SelectedItem)[0]
        $lvlInventory = [int]([string]$ui.LvlInventory.SelectedItem)[0]
        $lvlStorage = [int]([string]$ui.LvlStorage.SelectedItem)[0]
        $lvlReplication = [int]([string]$ui.LvlReplication.SelectedItem)[0]
        $lvlCloudConnect = [int]([string]$ui.LvlCloudConnect.SelectedItem)[0]
        $lvlJobs = [int]([string]$ui.LvlJobs.SelectedItem)[0]

        # ── Validation ───────────────────────────────────────────────────────────
        if ([string]::IsNullOrWhiteSpace($server)) {
            Write-Logging 'VBR Server address is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($username)) {
            Write-Logging 'Username is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($password)) {
            Write-Logging 'Password is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($outPath)) {
            $outPath = Join-Path $env:USERPROFILE 'Documents\AsBuiltReport'
        }
        if (-not (Test-Path $outPath)) {
            New-Item -Path $outPath -ItemType Directory -Force | Out-Null
            Write-Logging "Created output folder: $outPath"
        }
        if ([string]::IsNullOrWhiteSpace($reportName)) { $reportName = 'Veeam VBR As-Built Report' }

        Write-Logging "Target   : $server`:$port"
        Write-Logging "Username : $username"
        Write-Logging "Formats  : $($formats -join ', ')"
        Write-Logging "Output   : $outPath"
        Write-Logging "Style    : $style  |  Language: $lang"

        # ── Import modules in this runspace ──────────────────────────────────────
        Write-Logging 'Loading AsBuiltReport modules…'
        try {
            Import-Module AsBuiltReport.Core -Force -ErrorAction Stop
            Import-Module AsBuiltReport.Veeam.VBR -Force -ErrorAction Stop
        } catch {
            Write-Logging "Failed to load modules: $_" 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; return
        }

        # ── Build config using shared helper ────────────────────────────────────────
        function Get-Level ($cbo) { [int]([string]$cbo.SelectedItem)[0] }

        $configObj = Build-VbrConfigObject `
            -ReportName $reportName `
            -Style $style `
            -Lang $lang `
            -Port $port `
            -Theme $theme `
            -ColSize $colSize `
            -EnableDiagrams $enableDiagrams `
            -ExportDiagrams $exportDiagrams `
            -HWInv $hwInventory `
            -NewIcons $newIcons `
            -HealthCheck $healthCheck `
            -LvlInfrastructure (Get-Level $ui.LvlInfrastructure) `
            -LvlTape (Get-Level $ui.LvlTape) `
            -LvlInventory (Get-Level $ui.LvlInventory) `
            -LvlStorage (Get-Level $ui.LvlStorage) `
            -LvlReplication (Get-Level $ui.LvlReplication) `
            -LvlCloudConnect (Get-Level $ui.LvlCloudConnect) `
            -LvlJobs (Get-Level $ui.LvlJobs)

        $tempConfig = Join-Path $env:TEMP "VBR_AsBuilt_$(New-Guid).json"
        $configObj | ConvertTo-Json -Depth 6 | Set-Content -Path $tempConfig -Encoding UTF8

        # ── Build credential and invoke New-AsBuiltReport ─────────────────────────
        try {
            if ($sh.CancelRequested) { Write-Logging 'Cancelled before start.' 'WARN'; return }

            Write-Logging 'Starting report generation (PS7 native)…'
            $secPass = ConvertTo-SecureString $password -AsPlainText -Force
            $cred = [System.Management.Automation.PSCredential]::new($username, $secPass)

            $params = @{
                Report = 'Veeam.VBR'
                Target = $server
                Credential = $cred
                OutputFolderPath = $outPath
                Format = $formats
                ReportConfigFilePath = $tempConfig
            }
            if ($addTimestamp) { $params['Timestamp'] = $true }
            if ($healthCheck) { $params['EnableHealthCheck'] = $true }

            New-AsBuiltReport @params

            Write-Logging ''
            Write-Logging "Report saved to: $outPath" 'SUCCESS'
        } catch {
            Write-Logging $_.Exception.Message 'ERROR'
            if ($_.ScriptStackTrace) { Write-Logging $_.ScriptStackTrace 'ERROR' }
        } finally {
            Remove-Item -Path $tempConfig -Force -ErrorAction SilentlyContinue
            $sh.progressBar.IsVisible = $false
            $sh.btnCancel.IsVisible = $false
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
            [int]$LvlInfrastructure, [int]$LvlTape, [int]$LvlInventory,
            [int]$LvlStorage, [int]$LvlReplication, [int]$LvlCloudConnect, [int]$LvlJobs
        )
        return [ordered]@{
            Report = [ordered]@{
                Name = $ReportName
                Version = '1.0'
                Status = 'Released'
                Language = $Lang
                ShowCoverPageImage = $true
                ShowTableOfContents = $true
                ShowHeaderFooter = $true
                ShowTableCaptions = $true
            }
            Options = [ordered]@{
                ReportStyle = $Style
                BackupServerPort = $Port
                EnableDiagrams = $EnableDiagrams
                ExportDiagrams = $ExportDiagrams
                EnableHardwareInventory = $HWInv
                DiagramTheme = $Theme
                DiagramColumnSize = $ColSize
                NewIcons = $NewIcons
                EnableDiagramDebug = $false
                DiagramWaterMark = ''
                ExportDiagramsFormat = @('pdf')
                EnableDiagramSignature = $false
                SignatureAuthorName = ''
                SignatureCompanyName = ''
                PSDefaultAuthentication = 'Default'
                RoundUnits = 1
                UpdateCheck = $false
                IsLocalServer = $false
                ShowExecutionTime = $false
            }
            InfoLevel = [ordered]@{
                Infrastructure = [ordered]@{
                    BackupServer = $LvlInfrastructure
                    BR = $LvlInfrastructure
                    Licenses = $LvlInfrastructure
                    Proxy = $LvlInfrastructure
                    Settings = $LvlInfrastructure
                    SOBR = $LvlInfrastructure
                    ServiceProvider = $LvlInfrastructure
                    SureBackup = $LvlInfrastructure
                    WANAccel = $LvlInfrastructure
                }
                Tape = [ordered]@{
                    Library = $LvlTape; MediaPool = $LvlTape
                    NDMP = $LvlTape; Server = $LvlTape; Vault = $LvlTape
                }
                Inventory = [ordered]@{ EntraID = $LvlInventory; FileShare = $LvlInventory; Nutanix = $LvlInventory; PHY = $LvlInventory; VI = $LvlInventory }
                Storage = [ordered]@{ ISILON = $LvlStorage; ONTAP = $LvlStorage }
                Replication = [ordered]@{ FailoverPlan = $LvlReplication; Replica = $LvlReplication }
                CloudConnect = [ordered]@{
                    BackupStorage = $LvlCloudConnect; Certificate = $LvlCloudConnect
                    CloudGateway = $LvlCloudConnect; GatewayPools = $LvlCloudConnect
                    PublicIP = $LvlCloudConnect; ReplicaResources = $LvlCloudConnect
                    Tenants = $LvlCloudConnect
                }
                Jobs = [ordered]@{
                    Agent = $LvlJobs; Backup = $LvlJobs; BackupCopy = $LvlJobs
                    EntraID = $LvlJobs; FileShare = $LvlJobs; Nutanix = $LvlJobs
                    Surebackup = $LvlJobs; Replication = $LvlReplication; Restores = 0; Tape = $LvlTape
                }
            }
            HealthCheck = [ordered]@{
                Infrastructure = [ordered]@{
                    BackupServer = $HealthCheck; Proxy = $HealthCheck; Settings = $HealthCheck
                    BR = $HealthCheck; SOBR = $HealthCheck; Server = $HealthCheck
                    Status = $HealthCheck; BestPractice = $HealthCheck
                }
                Tape = [ordered]@{ Status = $HealthCheck; BestPractice = $HealthCheck }
                Replication = [ordered]@{ Status = $HealthCheck; BestPractice = $HealthCheck }
                Security = [ordered]@{ BestPractice = $HealthCheck }
                CloudConnect = [ordered]@{
                    Tenants = $HealthCheck; BackupStorage = $HealthCheck
                    ReplicaResources = $HealthCheck; BestPractice = $HealthCheck
                }
                Jobs = [ordered]@{ Status = $HealthCheck; BestPractice = $HealthCheck }
            }
        }
    }

    # ── Config Management Controls ───────────────────────────────────────────────
    $txtConfigPath = [TextBox]::new()
    $txtConfigPath.Width = 298
    $txtConfigPath.Watermark = 'Path to .json config file'
    $txtConfigPath.Text = if ($IsWindows) {
        [System.IO.Path]::Combine(
            $env:USERPROFILE, 'Documents', 'AsBuiltReport', 'AsBuiltReport.Veeam.VBR.json')
    } else {
        [System.IO.Path]::Combine(
            $env:HOME, 'Documents', 'AsBuiltReport', 'AsBuiltReport.Veeam.VBR.json')
    }

    $btnBrowseConfig = [Button]::new()
    $btnBrowseConfig.Content = 'Browse…'
    $btnBrowseConfig.AddClick({
            try {
                $storageProvider = [Window]::GetTopLevel($btnBrowseConfig).StorageProvider
                if ($null -eq $storageProvider) {
                    Write-Host 'Storage provider not available.' -ForegroundColor Yellow
                    return
                }
                $options = [FilePickerOpenOptions]::new()
                $options.Title = 'Select Veeam.VBR JSON File'
                $JsonConfigFile = $storageProvider.OpenFilePickerAsync($options).WaitForCompleted()
                if ($JsonConfigFile -and $JsonConfigFile.Count -gt 0) {
                    $txtConfigPath.Text = $JsonConfigFile.Path.AbsolutePath
                }
            } catch {
                Write-Host "Folder picker error: $_" -ForegroundColor Red
            }
        })

    $configPathRow = [StackPanel]::new()
    $configPathRow.Orientation = 'Horizontal'
    $configPathRow.Spacing = 8
    $configPathRow.Children.Add($txtConfigPath)
    $configPathRow.Children.Add($btnBrowseConfig)

    $lblConfigStatus = [TextBlock]::new()
    $lblConfigStatus.FontSize = 11
    $lblConfigStatus.Margin = '0,4,0,0'
    $lblConfigStatus.Text = ''
    $syncHash.lblConfigStatus = $lblConfigStatus

    # ── Save Config Button ────────────────────────────────────────────────────────
    $btnSaveConfig = [Button]::new()
    $btnSaveConfig.Content = '💾  Save Config'
    $btnSaveConfig.HorizontalAlignment = 'Stretch'
    $btnSaveConfig.HorizontalContentAlignment = 'Center'
    $btnSaveConfig.Width = 196
    $btnSaveConfig.Margin = '0,0,4,0'

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
                    -ReportName ($txtReportName.Text.Trim() -or 'Veeam VBR As-Built Report') `
                    -Style ([string]$cboStyle.SelectedItem) `
                    -Lang ([string]$cboLang.SelectedItem) `
                    -Port ([int]$txtPort.Text) `
                    -ColSize ([int]$txtColSize.Text) `
                    -EnableDiagrams ([bool]$swDiagrams.IsChecked) `
                    -ExportDiagrams ([bool]$swExportDia.IsChecked) `
                    -HWInv ([bool]$swHWInv.IsChecked) `
                    -NewIcons ([bool]$swNewIcons.IsChecked) `
                    -HealthCheck ([bool]$swHealthChk.IsChecked) `
                    -LvlInfrastructure (Get-LevelVal $cboLvlInfrastructure) `
                    -LvlTape (Get-LevelVal $cboLvlTape) `
                    -LvlInventory (Get-LevelVal $cboLvlInventory) `
                    -LvlStorage (Get-LevelVal $cboLvlStorage) `
                    -LvlReplication (Get-LevelVal $cboLvlReplication) `
                    -LvlCloudConnect (Get-LevelVal $cboLvlCloudConnect) `
                    -LvlJobs (Get-LevelVal $cboLvlJobs)

                $configObj | ConvertTo-Json -Depth 6 | Set-Content -Path $destPath -Encoding UTF8
                $syncHash.lblConfigStatus.Text = "✅ Config saved: $destPath"
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Save failed: $_"
            }
        })

    # ── Load Config Button ────────────────────────────────────────────────────────
    $btnLoadConfig = [Button]::new()
    $btnLoadConfig.Content = '📂  Load Config'
    $btnLoadConfig.HorizontalAlignment = 'Stretch'
    $btnLoadConfig.HorizontalContentAlignment = 'Center'
    $btnLoadConfig.Width = 196
    $btnLoadConfig.Margin = '4,0,0,0'

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
                if ($json.Report.Name) { $txtReportName.Text = $json.Report.Name }
                if ($json.Report.Language) { Set-ComboByValue $cboLang $json.Report.Language }

                # Options section
                if ($null -ne $json.Options.BackupServerPort) { $txtPort.Text = [string]$json.Options.BackupServerPort }
                if ($json.Options.ReportStyle) { Set-ComboByValue $cboStyle $json.Options.ReportStyle }
                if ($null -ne $json.Options.DiagramColumnSize) { $txtColSize.Text = [string]$json.Options.DiagramColumnSize }
                if ($null -ne $json.Options.EnableDiagrams) { $swDiagrams.IsChecked = [bool]$json.Options.EnableDiagrams }
                if ($null -ne $json.Options.ExportDiagrams) { $swExportDia.IsChecked = [bool]$json.Options.ExportDiagrams }
                if ($null -ne $json.Options.EnableHardwareInventory) { $swHWInv.IsChecked = [bool]$json.Options.EnableHardwareInventory }
                if ($null -ne $json.Options.NewIcons) { $swNewIcons.IsChecked = [bool]$json.Options.NewIcons }

                # InfoLevel section
                if ($null -ne $json.InfoLevel) {
                    if ($null -ne $json.InfoLevel.Infrastructure) {
                        Set-LevelCombo $cboLvlInfrastructure $json.InfoLevel.Infrastructure.BackupServer
                    }
                    if ($null -ne $json.InfoLevel.Tape) {
                        Set-LevelCombo $cboLvlTape $json.InfoLevel.Tape.Library
                    }
                    if ($null -ne $json.InfoLevel.Inventory) {
                        Set-LevelCombo $cboLvlInventory $json.InfoLevel.Inventory.VI
                    }
                    if ($null -ne $json.InfoLevel.Storage) {
                        Set-LevelCombo $cboLvlStorage $json.InfoLevel.Storage.ONTAP
                    }
                    if ($null -ne $json.InfoLevel.Replication) {
                        Set-LevelCombo $cboLvlReplication $json.InfoLevel.Replication.Replica
                    }
                    if ($null -ne $json.InfoLevel.CloudConnect) {
                        Set-LevelCombo $cboLvlCloudConnect $json.InfoLevel.CloudConnect.Tenants
                    }
                    if ($null -ne $json.InfoLevel.Jobs) {
                        Set-LevelCombo $cboLvlJobs $json.InfoLevel.Jobs.Backup
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

    # ── Open Config Button ────────────────────────────────────────────────────────
    $btnOpenConfig = [Button]::new()
    $btnOpenConfig.Content = '📝  Open Config'
    $btnOpenConfig.HorizontalAlignment = 'Stretch'
    $btnOpenConfig.HorizontalContentAlignment = 'Center'
    $btnOpenConfig.Width = 196
    $btnOpenConfig.Margin = '4,0,0,0'

    $btnOpenConfig.AddClick({
            $srcPath = $txtConfigPath.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($srcPath)) {
                $syncHash.lblConfigStatus.Text = '⚠ Please enter a config file path first.'
                return
            }
            if (-not (Test-Path $srcPath)) {
                $syncHash.lblConfigStatus.Text = '⚠ Config file not found.'
                return
            }
            try {
                Start-Process -FilePath $srcPath
                $syncHash.lblConfigStatus.Text = "📝 Opened: $(Split-Path $srcPath -Leaf)"
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Could not open file: $_"
            }
        })

    # ── Assemble Main Layout ────────────────────────────────────────────────────
    $mainPanel = [StackPanel]::new()
    $mainPanel.Margin = '28,20,28,24'
    $mainPanel.Spacing = 2

    # Header
    $headerPanel = [StackPanel]::new()
    $headerPanel.HorizontalAlignment = 'Center'
    $headerPanel.Spacing = 4
    $headerPanel.Margin = '0,0,0,4'

    $hTitle = [TextBlock]::new()
    $hTitle.Text = 'Veeam Backup & Replication'
    $hTitle.FontSize = 22
    $hTitle.FontWeight = 'Bold'
    $hTitle.HorizontalAlignment = 'Center'

    $hSub = [TextBlock]::new()
    $hSub.Text = 'As-Built Report Generator'
    $hSub.FontSize = 13
    $hSub.HorizontalAlignment = 'Center'

    $headerPanel.Children.Add($hTitle)
    $headerPanel.Children.Add($hSub)
    $mainPanel.Children.Add($headerPanel)

    # Section: Connection + Options — two-column side-by-side grid
    $twoColGrid = [Grid]::new()
    $twoColGrid.ColumnDefinitions = [ColumnDefinitions]::Parse('*, *')
    $twoColGrid.ColumnSpacing = 24
    $twoColGrid.Margin = '0,4,0,0'

    $connPanel = [StackPanel]::new()
    $connPanel.Spacing = 2
    $connPanel.Children.Add((New-SectionTitle '🔌  Server Connection'))
    $connPanel.Children.Add((New-FormRow -Label 'VBR Server' -Control $serverRow -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'Username' -Control $txtUser -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'Password' -Control $txtPass -LabelWidth 130))
    $connPanel.Children.Add((New-SectionTitle '📄  Report Output'))
    $connPanel.Children.Add((New-FormRow -Label 'Report Name' -Control $txtReportName -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'Format' -Control $fmtPanel -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'Output Folder' -Control $outputPathRow -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'Report Style' -Control $styleRow -LabelWidth 130))
    [Grid]::SetColumn($connPanel, 0)
    $twoColGrid.Children.Add($connPanel)

    $optPanel = [StackPanel]::new()
    $optPanel.Spacing = 2
    $optPanel.Children.Add((New-SectionTitle '⚙️  Options'))
    $optPanel.Children.Add((New-FormRow -Label 'Enable Diagrams' -Control $swDiagrams -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Export Diagrams' -Control $swExportDia -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Hardware Inventory' -Control $swHWInv -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Use New Icons' -Control $swNewIcons -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Enable Health Check' -Control $swHealthChk -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Add Timestamp' -Control $swTimestamp -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Diagram Columns' -Control $txtColSize -LabelWidth 165))
    [Grid]::SetColumn($optPanel, 1)
    $twoColGrid.Children.Add($optPanel)

    $mainPanel.Children.Add($twoColGrid)

    $mainPanel.Children.Add((New-SectionTitle '📊  Info Level'))
    $mainPanel.Children.Add((New-FormRow -Label 'Infrastructure' -Control $cboLvlInfrastructure))
    $mainPanel.Children.Add((New-FormRow -Label 'Tape' -Control $cboLvlTape))
    $mainPanel.Children.Add((New-FormRow -Label 'Inventory' -Control $cboLvlInventory))
    $mainPanel.Children.Add((New-FormRow -Label 'Storage' -Control $cboLvlStorage))
    $mainPanel.Children.Add((New-FormRow -Label 'Replication' -Control $cboLvlReplication))
    $mainPanel.Children.Add((New-FormRow -Label 'Cloud Connect' -Control $cboLvlCloudConnect))
    $mainPanel.Children.Add((New-FormRow -Label 'Jobs' -Control $cboLvlJobs))

    # Section: Config Management
    $mainPanel.Children.Add((New-SectionTitle '🗂️  Config Management'))

    $cfgBtnRow = [StackPanel]::new()
    $cfgBtnRow.Orientation = 'Horizontal'
    $cfgBtnRow.Margin = '0,4,0,0'
    $cfgBtnRow.Children.Add($btnSaveConfig)
    $cfgBtnRow.Children.Add($btnLoadConfig)
    $cfgBtnRow.Children.Add($btnOpenConfig)

    $mainPanel.Children.Add((New-FormRow -Label 'Config File' -Control $configPathRow))
    $mainPanel.Children.Add($cfgBtnRow)
    $mainPanel.Children.Add($lblConfigStatus)

    # Generate button + progress
    $mainPanel.Children.Add($btnGenerate)
    $mainPanel.Children.Add($progressBar)

    # Log area
    $logTitle = [TextBlock]::new()
    $logTitle.Text = '📋  Output Log'
    $logTitle.FontSize = 13
    $logTitle.FontWeight = 'SemiBold'
    $logTitle.Margin = '0,14,0,6'
    $mainPanel.Children.Add($logTitle)
    $mainPanel.Children.Add($txtLog)
    $mainPanel.Children.Add($btnCancel)

    $scrollView = [ScrollViewer]::new()
    $scrollView.Content = $mainPanel

    # ── Window ──────────────────────────────────────────────────────────────────
    $win = [Window]::new()
    $win.Title = 'Veeam VBR — As-Built Report Generator'
    $win.Width = 1050
    $win.Height = 920
    $win.MinWidth = 880
    $win.MinHeight = 500
    $win.Content = $scrollView

    $win.Show()
    $win.WaitForClosed()
}
