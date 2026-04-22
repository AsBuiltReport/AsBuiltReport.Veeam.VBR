#Requires -RunAsAdministrator

using namespace GliderUI
using namespace GliderUI.Avalonia
using namespace GliderUI.Avalonia.Controls
using namespace GliderUI.Avalonia.Platform.Storage
using namespace GliderUI.Avalonia.Media

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
            GliderUI 0.2.0+  (auto-installed on first run) — Install-PSResource -Name GliderUI -Version 0.2.0 -Scope CurrentUser -TrustRepository
            AsBuiltReport.Core                    — Install-PSResource -Name AsBuiltReport.Core
            AsBuiltReport.Veeam.VBR               — Install-PSResource -Name AsBuiltReport.Veeam.VBR
            Veeam B&R console / PS module         — must be installed on this machine
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]

    [CmdletBinding()]
    param()

    if ($PSVersionTable.PSVersion.Major -lt 7 -or ($PSVersionTable.PSVersion.Major -eq 7 -and $PSVersionTable.PSVersion.Minor -lt 4)) {
        throw "Start-AsBuiltReportVBR requires PowerShell 7.4+ and Veeam Backup & Replication v13+. Current PowerShell version: $($PSVersionTable.PSVersion)"
    }

    # ── Bootstrap GliderUI ──────────────────────────────────────────────────────
    $requiredGliderUIVersion = [version]'0.2.0'

    if (-not (Get-Module -ListAvailable -Name GliderUI)) {
        Write-Host 'GliderUI not found — installing from PSGallery…' -ForegroundColor Cyan
        Install-PSResource -Name GliderUI -Version $requiredGliderUIVersion -Scope CurrentUser -TrustRepository
    }

    $gliderMod = Get-Module -ListAvailable -Name GliderUI |
    Sort-Object Version -Descending |
    Select-Object -First 1

    if ($null -eq $gliderMod -or $gliderMod.Version -lt $requiredGliderUIVersion) {
        $found = if ($null -eq $gliderMod) { 'not installed' } else { "v$($gliderMod.Version)" }
        Write-Error ("GliderUI v{0} or later is required (found: {1}).`nInstall it with: Install-PSResource -Name GliderUI -Version {0} -Scope CurrentUser -TrustRepository`n. After installing, restart PowerShell console." -f $requiredGliderUIVersion, $found)
        return
    }

    Import-Module GliderUI -Force

    # Thread-safe store shared between the main runspace and the report runspace
    $syncHash = [Hashtable]::Synchronized(@{
            CancelRequested = $false
            IsBusy = $false
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

    # Wraps a password TextBox with an eye-toggle button.
    # Returns a StackPanel to use as a FormRow -Control.
    function New-PasswordRow ($PasswordTextBox) {
        $btn = [Button]::new()
        $btn.Content = '👁'
        $btn.Padding = '6,2,6,2'
        $btn.VerticalAlignment = 'Center'
        $btn.AddClick({
                if ($PasswordTextBox.PasswordChar -eq [char]0) {
                    $PasswordTextBox.PasswordChar = [char]'●'
                } else {
                    $PasswordTextBox.PasswordChar = [char]0
                }
            }.GetNewClosure())

        $row = [StackPanel]::new()
        $row.Orientation = 'Horizontal'
        $row.Spacing = 6
        $row.Children.Add($PasswordTextBox)
        $row.Children.Add($btn)
        return $row
    }

    function New-DrawerMenuItem ([string]$Title, [string]$IconGeometry, $Page, $NavigationPage) {
        $icon = [PathIcon]::new()
        $icon.Data = [Geometry]::Parse($IconGeometry)

        $textBlock = [TextBlock]::new()
        $textBlock.Text = $Title
        $textBlock.VerticalAlignment = 'Center'

        $panel = [StackPanel]::new()
        $panel.Orientation = 'Horizontal'
        $panel.Spacing = 8
        $panel.Children.Add($icon)
        $panel.Children.Add($textBlock)

        $button = [Button]::new()
        $button.HorizontalAlignment = 'Stretch'
        $button.Padding = 12
        $button.Background = [SolidColorBrush]::new([Colors]::Transparent, 1)
        $button.Content = $panel
        $button.AddClick({
                param($argumentList)
                $targetPage, $navPage = $argumentList
                $navPage.ReplaceAsync($targetPage) | Out-Null
            }, @($Page, $NavigationPage))
        return $button
    }

    # ── Connection Controls ─────────────────────────────────────────────────────
    $txtServer = [TextBox]::new()
    $txtServer.Width = 175
    $txtServer.Watermark = 'Backup Server FQDN'

    $txtPort = [TextBox]::new()
    $txtPort.Text = '443'
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
    $txtUser.Watermark = 'username@domain'

    $txtPass = [TextBox]::new()
    $txtPass.Width = 200
    $txtPass.Watermark = 'Password'
    try { $txtPass.PasswordChar = [char]'●' } catch { Out-Null }

    # ── Saved Connections ─────────────────────────────────────────────────────────
    $savedConnPath = if ($IsWindows) {
        [System.IO.Path]::Combine($env:USERPROFILE, 'AsBuiltReport', 'VBR-SavedConnections.json')
    } else {
        [System.IO.Path]::Combine($env:HOME, 'AsBuiltReport', 'VBR-SavedConnections.json')
    }

    $loadSavedConns = {
        if (Test-Path $savedConnPath) {
            try {
                $raw = Get-Content -Path $savedConnPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($null -eq $raw) { return @() }
                return @($raw)
            } catch { return @() }
        }
        return @()
    }.GetNewClosure()

    $saveSavedConns = {
        param ([array]$Connections)
        $dir = Split-Path $savedConnPath -Parent
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        if ($Connections.Count -eq 0) {
            '[]' | Set-Content -Path $savedConnPath -Encoding UTF8
        } else {
            $Connections | ConvertTo-Json -Depth 3 | Set-Content -Path $savedConnPath -Encoding UTF8
        }
    }.GetNewClosure()

    $cboSavedConn = [ComboBox]::new()
    $cboSavedConn.Width = 262

    $refreshSavedConnCombo = {
        $cboSavedConn.Items.Clear()
        foreach ($c in (& $loadSavedConns)) {
            $cboSavedConn.Items.Add("$($c.Server):$($c.Port) ($($c.Username))") | Out-Null
        }
    }.GetNewClosure()
    & $refreshSavedConnCombo

    $cboSavedConn.AddSelectionChanged({
            $idx = $cboSavedConn.SelectedIndex
            if ($idx -lt 0) { return }
            $conns = & $loadSavedConns
            if ($idx -ge $conns.Count) { return }
            $sel = $conns[$idx]
            $txtServer.Text = $sel.Server
            $txtPort.Text = [string]$sel.Port
            $txtUser.Text = $sel.Username
            $txtPass.Text = ''
        })

    $btnSaveConn = [Button]::new()
    $btnSaveConn.Content = '💾 Save Connection'
    $btnSaveConn.AddClick({
            $srv = $txtServer.Text.Trim()
            $prt = if ($txtPort.Text -match '^\d+$') { [int]$txtPort.Text } else { 443 }
            $usr = $txtUser.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($srv) -or [string]::IsNullOrWhiteSpace($usr)) {
                $syncHash.lblConfigStatus.Text = '⚠ Enter Server and Username before saving a connection.'
                return
            }
            $conns = [System.Collections.ArrayList]@()
            foreach ($c in (& $loadSavedConns)) { $conns.Add($c) | Out-Null }
            $dup = $conns | Where-Object { $_.Server -eq $srv -and $_.Port -eq $prt -and $_.Username -eq $usr }
            if (-not $dup) {
                $conns.Add([PSCustomObject]@{ Server = $srv; Port = $prt; Username = $usr }) | Out-Null
                & $saveSavedConns -Connections @($conns)
                & $refreshSavedConnCombo
                $syncHash.lblConfigStatus.Text = "✅ Connection saved: $srv ($usr)"
            } else {
                $syncHash.lblConfigStatus.Text = "ℹ Connection already exists: $srv ($usr)"
            }
        })

    $btnDeleteConn = [Button]::new()
    $btnDeleteConn.Content = '🗑 Delete'
    $btnDeleteConn.AddClick({
            $idx = $cboSavedConn.SelectedIndex
            if ($idx -lt 0) {
                $syncHash.lblConfigStatus.Text = '⚠ Select a saved connection to delete.'
                return
            }
            $conns = [System.Collections.ArrayList]@()
            foreach ($c in (& $loadSavedConns)) { $conns.Add($c) | Out-Null }
            if ($idx -ge $conns.Count) { return }
            $removed = $conns[$idx]
            $conns.RemoveAt($idx)
            & $saveSavedConns -Connections @($conns)
            $cboSavedConn.SelectedIndex = -1
            & $refreshSavedConnCombo
            $syncHash.lblConfigStatus.Text = "🗑 Deleted: $($removed.Server) ($($removed.Username))"
        })

    $savedConnActionsRow = [StackPanel]::new()
    $savedConnActionsRow.Orientation = 'Horizontal'
    $savedConnActionsRow.Spacing = 6
    $savedConnActionsRow.Children.Add($btnSaveConn)
    $savedConnActionsRow.Children.Add($btnDeleteConn)

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
    $txtOutput.Text = if ($IsWindows) {
        [System.IO.Path]::Combine(
            [System.IO.Path]::Combine($env:USERPROFILE, 'Documents', 'AsBuiltReport'))
    } else {
        [System.IO.Path]::Combine(
            [System.IO.Path]::Combine($env:HOME, 'AsBuiltReport'))
    }

    $btnBrowse = [Button]::new()
    $btnBrowse.Content = 'Browse…'
    $btnBrowse.AddClick({
            try {
                $btnBrowse.IsEnabled = $false
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
            } finally {
                $btnBrowse.IsEnabled = $true
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
    $swHealthChk = [ToggleSwitch]::new(); $swHealthChk.IsChecked = $false
    $swTimestamp = [ToggleSwitch]::new(); $swTimestamp.IsChecked = $false

    $txtColSize = [TextBox]::new()
    $txtColSize.Text = '3'
    $txtColSize.Width = 80
    $txtColSize.Watermark = 'columns'

    $cboDiagramTheme = [ComboBox]::new()
    $cboDiagramTheme.Width = 120
    @('White', 'Black', 'Neon') | ForEach-Object { $cboDiagramTheme.Items.Add($_) | Out-Null }
    $cboDiagramTheme.SelectedIndex = 0

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
    $txtLog.FontSize = 16
    $txtLog.TextWrapping = 'Wrap'
    $txtLog.Watermark = 'Output log will appear here…'
    try { $txtLog.FontFamily = 'Consolas,Courier New,Monospace' } catch { Out-Null }
    $syncHash.txtLog = $txtLog

    $chkVerbose = [CheckBox]::new()
    $chkVerbose.Content = '🔍Verbose'
    $chkVerbose.IsChecked = $false
    $chkVerbose.HorizontalAlignment = 'Right'
    $chkVerbose.VerticalAlignment = 'Center'
    $chkVerbose.Margin = '0,0,8,0'
    $syncHash.chkVerbose = $chkVerbose

    # ── Action Buttons ──────────────────────────────────────────────────────────
    $btnCancel = [Button]::new()
    $btnCancel.Content = '✕ Cancel'
    $btnCancel.IsVisible = $false
    $btnCancel.Margin = '0,0,0,0'
    $btnCancel.AddClick({
            $syncHash.CancelRequested = $true
            $rps = $syncHash.reportPS
            if ($null -ne $rps) { $rps.Stop() }
        })
    $syncHash.btnCancel = $btnCancel

    $btnExportLog = [Button]::new()
    $btnExportLog.Content = '💾 Export Log'
    $btnExportLog.Margin = '0,0,0,0'
    $btnExportLog.AddClick({
            try {
                $btnExportLog.IsEnabled = $false
                $logText = $syncHash.txtLog.Text
                if ([string]::IsNullOrWhiteSpace($logText)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Log is empty — nothing to export.'
                    return
                }
                $storageProvider = [Window]::GetTopLevel($btnExportLog).StorageProvider
                if ($null -eq $storageProvider) { return }
                $saveOpts = [FilePickerSaveOptions]::new()
                $saveOpts.Title = 'Export Output Log'
                $saveOpts.SuggestedFileName = "VBR-AsBuiltReport-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
                $file = $storageProvider.SaveFilePickerAsync($saveOpts).WaitForCompleted()
                if ($null -ne $file) {
                    $logText | Set-Content -Path $file.Path.LocalPath -Encoding UTF8
                    $syncHash.lblConfigStatus.Text = "✅ Log exported: $(Split-Path $file.Path.LocalPath -Leaf)"
                }
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Log export failed: $_"
            } finally {
                $btnExportLog.IsEnabled = $true
            }
        })

    $btnGenerate = [Button]::new()
    $btnGenerate.Content = '▶ Generate Report'
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
        DiagramTheme = $cboDiagramTheme
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
        Verbose = $chkVerbose
    }

    $generateCallback.ScriptBlock = {
        param ($ui)

        $sh = $ui.SyncHash
        if ($sh.IsBusy) {
            $sh.lblConfigStatus.Text = '⚠ Another operation is already running. Please wait.'
            return
        }
        $sh.IsBusy = $true
        $sh.CancelRequested = $false
        $sh.progressBar.IsVisible = $true
        $sh.btnCancel.IsVisible = $true
        $sh.txtLog.Text = ''

        # Enable New-AsBuiltReport verbose output if the checkbox is checked in the UI.
        $verboseEnabled = $ui.Verbose.IsChecked -eq $true
        function Write-Logging ([string]$Msg, [string]$Level = '', [bool]$AddTimestamp = $false) {
            $ts = Get-Date -Format 'HH:mm:ss'
            if ($Level -eq '') {
                if ($AddTimestamp) {
                    $sh.txtLog.Text += "[$ts] $Msg`n"
                } else {
                    $sh.txtLog.Text += "$Msg`n"
                }
            } else {
                if ($AddTimestamp) {
                    $sh.txtLog.Text += "[$ts][$Level] $Msg`n"
                } else {
                    $sh.txtLog.Text += "[$Level] $Msg`n"
                }
            }
            $sh.txtLog.CaretIndex = $sh.txtLog.Text.Length
        }

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
                    DiagramType = [ordered]@{
                        CloudConnect = $true
                        CloudConnectTenant = $true
                        Infrastructure = $true
                        FileProxy = $true
                        HyperVProxy = $true
                        Repository = $true
                        Sobr = $true
                        Tape = $true
                        ProtectedGroup = $true
                        vSphereProxy = $true
                        WanAccelerator = $true
                        HACluster = $true
                    }
                    NewIcons = $NewIcons
                    EnableDiagramDebug = $false
                    DiagramWaterMark = ''
                    ExportDiagramsFormat = @('pdf')
                    EnableDiagramSignature = $false
                    SignatureAuthorName = ''
                    SignatureCompanyName = ''
                    PSDefaultAuthentication = 'Default'
                    RoundUnits = 1
                    UpdateCheck = $true
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
                    Tape = [ordered]@{ Library = $LvlTape; MediaPool = $LvlTape
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

        # ── Collect values ───────────────────────────────────────────────────────
        $server = $ui.Server.Text.Trim()
        $port = if ($ui.Port.Text -match '^\d+$') { [int]$ui.Port.Text } else { 443 }
        $username = $ui.Username.Text.Trim()
        $password = $ui.Password.Text
        $reportName = $ui.ReportName.Text.Trim()
        $outPath = $ui.OutPath.Text.Trim()
        $style = [string]$ui.Style.SelectedItem
        $lang = [string]$ui.Lang.SelectedItem
        $colSize = if ($ui.DiagColSize.Text -match '^\d+$') { [int]$ui.DiagColSize.Text } else { 3 }
        $configPath = $ui.ConfigPath.Text.Trim()
        $abrConfigPath = $ui.AbrConfigPath.Text.Trim()

        $formats = @()
        if ($ui.FmtHTML.IsChecked -eq $true) { $formats += 'Html' }
        if ($ui.FmtWord.IsChecked -eq $true) { $formats += 'Word' }
        if ($ui.FmtText.IsChecked -eq $true) { $formats += 'Text' }
        if ($formats.Count -eq 0) { $formats = @('Html') }

        $enableDiagrams = [bool]$ui.Diagrams.IsChecked
        $exportDiagrams = [bool]$ui.ExportDia.IsChecked
        $hwInventory = [bool]$ui.HWInv.IsChecked
        $newIcons = [bool]$ui.NewIcons.IsChecked
        $healthCheck = [bool]$ui.HealthChk.IsChecked
        $addTimestamp = [bool]$ui.Timestamp.IsChecked

        # Parse InfoLevel (first char = number)
        $lvlInfrastructure = [int]([string]$ui.LvlInfrastructure.SelectedItem).Substring(0, 1)
        $lvlTape = [int]([string]$ui.LvlTape.SelectedItem).Substring(0, 1)
        $lvlInventory = [int]([string]$ui.LvlInventory.SelectedItem).Substring(0, 1)
        $lvlStorage = [int]([string]$ui.LvlStorage.SelectedItem).Substring(0, 1)
        $lvlReplication = [int]([string]$ui.LvlReplication.SelectedItem).Substring(0, 1)
        $lvlCloudConnect = [int]([string]$ui.LvlCloudConnect.SelectedItem).Substring(0, 1)
        $lvlJobs = [int]([string]$ui.LvlJobs.SelectedItem).Substring(0, 1)

        # ── Validation ───────────────────────────────────────────────────────────
        if ([string]::IsNullOrWhiteSpace($server)) {
            Write-Logging 'VBR Server address is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; $sh.IsBusy = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($username)) {
            Write-Logging 'Username is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; $sh.IsBusy = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($password)) {
            Write-Logging 'Password is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; $sh.IsBusy = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($outPath)) {
            $outPath = if ($IsWindows) {
                [System.IO.Path]::Combine(
                    [System.IO.Path]::Combine($env:USERPROFILE, 'Documents', 'AsBuiltReport'))
            } else {
                [System.IO.Path]::Combine(
                    [System.IO.Path]::Combine($env:HOME, 'AsBuiltReport'))
            }
        }
        if (-not (Test-Path $outPath)) {
            New-Item -Path $outPath -ItemType Directory -Force | Out-Null
            Write-Logging "Created output folder: $outPath"
        }
        if ([string]::IsNullOrWhiteSpace($reportName)) { $reportName = 'Veeam VBR As-Built Report' }
        if ([string]::IsNullOrWhiteSpace($abrConfigPath)) {
            Write-Logging 'AsBuiltReport config file path is required. Use the "⚙️ AsBuiltReport Global Settings" section to create one, then set the path above.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; $sh.IsBusy = $false; return
        }
        if (-not (Test-Path $abrConfigPath)) {
            Write-Logging "AsBuiltReport config file not found: $abrConfigPath" 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; $sh.IsBusy = $false; return
        }

        Write-Logging "Target  : $server (port $port)"
        Write-Logging "User    : $username"
        Write-Logging "Formats : $($formats -join ', ')"
        Write-Logging "Output  : $outPath"

        # ── Import modules in this runspace ──────────────────────────────────────
        Write-Logging 'Loading AsBuiltReport modules…'
        try {
            Import-Module AsBuiltReport.Core, AsBuiltReport.Chart, AsBuiltReport.Diagram, AsBuiltReport.Veeam.VBR -Force -ErrorAction Stop
        } catch {
            Write-Logging "Failed to load modules: $_" 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.btnCancel.IsVisible = $false; $sh.IsBusy = $false; return
        }

        # ── Resolve ReportConfigFilePath ──────────────────────────────────────────
        # Use the saved config file from Config Management if it exists;
        # otherwise build a temp config from the current UI control values.
        $tempConfig = $null
        if (-not [string]::IsNullOrWhiteSpace($configPath) -and (Test-Path $configPath)) {
            $reportConfigFilePath = $configPath
            Write-Logging "Using config file: $(Split-Path $configPath -Leaf)"
        } else {
            function Get-Level ($cbo) { [int]([string]$cbo.SelectedItem).Substring(0, 1) }

            $configObj = Build-VbrConfigObject `
                -ReportName $reportName `
                -Style $style `
                -Lang $lang `
                -Port $port `
                -Theme ([string]$ui.DiagramTheme.SelectedItem) `
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

            $tempConfig = [System.IO.Path]::Combine($env:TEMP, "VBR_cfg_$(New-Guid).json")
            $configObj | ConvertTo-Json -Depth 6 | Set-Content -Path $tempConfig -Encoding UTF8
            $reportConfigFilePath = $tempConfig
            Write-Logging 'Using config built from UI controls.'
        }

        # ── Invoke New-AsBuiltReport ──────────────────────────────────────────────
        $nestedPS = $null
        $nestedRunspace = $null
        try {
            if ($sh.CancelRequested) { Write-Logging 'Cancelled before start.' 'WARN'; return }

            Write-Logging 'Starting report generation…'

            # New-AsBuiltReport -Report Veeam.VBR -Target <server> -Username <user> -Password <pass>
            #   -Format Html,Word -OutputFolderPath <path> -ReportConfigFilePath <json>
            $params = @{
                Report = 'Veeam.VBR'
                Target = $server
                Username = $username
                Password = $password
                OutputFolderPath = $outPath
                Format = $formats
                ReportConfigFilePath = $reportConfigFilePath
            }

            if ($addTimestamp) { $params['Timestamp'] = $true }
            if ($healthCheck) { $params['EnableHealthCheck'] = $true }
            if ($verboseEnabled) { $params['Verbose'] = $true }

            $params['AsBuiltConfigFilePath'] = $abrConfigPath
            Write-Logging "Using AsBuiltReport config file: $(Split-Path $abrConfigPath -Leaf)"

            New-AsBuiltReport @params *>&1 | ForEach-Object {
                $line = if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    Write-Logging "$($_.Exception.Message)" 'ERROR'
                    return
                } elseif ($_ -is [System.Management.Automation.WarningRecord]) {
                    Write-Logging "$($_.Message)" 'WARN'
                    return
                } elseif ($_ -is [System.Management.Automation.VerboseRecord]) {
                    if ($verboseEnabled) {
                        Write-Logging "$($_.Message)" 'VERBOSE'
                    }
                    return
                } elseif ($_ -is [System.Management.Automation.InformationRecord]) {
                    "$($_.MessageData)"
                } else {
                    "$_"
                }
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    Write-Logging $line
                }
            }
        } catch {
            Write-Logging $_.Exception.Message 'ERROR'
            if ($_.ScriptStackTrace) { Write-Logging $_.ScriptStackTrace 'ERROR' }
        } finally {
            if ($null -ne $tempConfig) {
                Remove-Item -Path $tempConfig -Force -ErrorAction SilentlyContinue
            }
            $sh.progressBar.IsVisible = $false
            $sh.btnCancel.IsVisible = $false
            $sh.IsBusy = $false
        }
    }

    $btnGenerate.AddClick($generateCallback)

    # ── Config Management Controls ───────────────────────────────────────────────
    $txtConfigPath = [TextBox]::new()
    $txtConfigPath.Width = 298
    $txtConfigPath.Watermark = 'Path to .json config file'
    $txtConfigPath.Text = if ($IsWindows) {
        [System.IO.Path]::Combine(
            $env:USERPROFILE, 'AsBuiltReport', 'AsBuiltReport.Veeam.VBR.json')
    } else {
        [System.IO.Path]::Combine(
            $env:HOME, 'AsBuiltReport', 'AsBuiltReport.Veeam.VBR.json')
    }

    $btnBrowseConfig = [Button]::new()
    $btnBrowseConfig.Content = 'Browse…'
    $btnBrowseConfig.AddClick({
            try {
                $btnBrowseConfig.IsEnabled = $false
                $storageProvider = [Window]::GetTopLevel($btnBrowseConfig).StorageProvider
                if ($null -eq $storageProvider) {
                    Write-Host 'Storage provider not available.' -ForegroundColor Yellow
                    return
                }
                $options = [FilePickerOpenOptions]::new()
                $options.Title = 'Select Veeam.VBR JSON File'
                $JsonConfigFile = $storageProvider.OpenFilePickerAsync($options).WaitForCompleted()
                if ($JsonConfigFile -and $JsonConfigFile.Count -gt 0) {
                    $txtConfigPath.Text = $JsonConfigFile.Path.LocalPath
                }
            } catch {
                Write-Host "Folder picker error: $_" -ForegroundColor Red
            } finally {
                $btnBrowseConfig.IsEnabled = $true
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

    # ── AsBuiltReport Global Config (AsBuiltReport.json) ─────────────────────────
    $txtAbrConfigPath = [TextBox]::new()
    $txtAbrConfigPath.Width = 298
    $txtAbrConfigPath.Watermark = 'Required: path to AsBuiltReport.json'

    $btnBrowseAbrConfig = [Button]::new()
    $btnBrowseAbrConfig.Content = 'Browse…'
    $btnBrowseAbrConfig.AddClick({
            try {
                $btnBrowseAbrConfig.IsEnabled = $false
                $storageProvider = [Window]::GetTopLevel($btnBrowseAbrConfig).StorageProvider
                if ($null -eq $storageProvider) { return }
                $options = [FilePickerOpenOptions]::new()
                $options.Title = 'Select AsBuiltReport.json'
                $options.AllowMultiple = $false
                $picked = $storageProvider.OpenFilePickerAsync($options).WaitForCompleted()
                if ($picked -and $picked.Count -gt 0) {
                    $txtAbrConfigPath.Text = $picked[0].Path.LocalPath
                    $syncHash.lblConfigStatus.Text = "📄 AsBuiltReport config selected: $(Split-Path $txtAbrConfigPath.Text -Leaf)"
                }
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Browse error: $_"
            } finally {
                $btnBrowseAbrConfig.IsEnabled = $true
            }
        })

    $abrConfigPathRow = [StackPanel]::new()
    $abrConfigPathRow.Orientation = 'Horizontal'
    $abrConfigPathRow.Spacing = 8
    $abrConfigPathRow.Children.Add($txtAbrConfigPath)
    $abrConfigPathRow.Children.Add($btnBrowseAbrConfig)
    # Late-bind controls created after ArgumentList; must be set after the TextBox objects exist
    $generateCallback.ArgumentList['ConfigPath'] = $txtConfigPath
    $generateCallback.ArgumentList['AbrConfigPath'] = $txtAbrConfigPath

    # ── AsBuiltReport Global Settings editor ─────────────────────────────────────────
    # Company
    $txtAbrCoFullName = [TextBox]::new(); $txtAbrCoFullName.Width = 298; $txtAbrCoFullName.Watermark = 'e.g. Acme Corporation'
    $txtAbrCoShortName = [TextBox]::new(); $txtAbrCoShortName.Width = 298; $txtAbrCoShortName.Watermark = 'e.g. ACME'
    $txtAbrCoContact = [TextBox]::new(); $txtAbrCoContact.Width = 298; $txtAbrCoContact.Watermark = 'Contact person'
    $txtAbrCoPhone = [TextBox]::new(); $txtAbrCoPhone.Width = 298; $txtAbrCoPhone.Watermark = 'e.g. +1-800-555-0100'
    $txtAbrCoAddress = [TextBox]::new(); $txtAbrCoAddress.Width = 298; $txtAbrCoAddress.Watermark = 'Street, City, Country'
    $txtAbrCoEmail = [TextBox]::new(); $txtAbrCoEmail.Width = 298; $txtAbrCoEmail.Watermark = 'company@example.com'
    # Report
    $txtAbrRptAuthor = [TextBox]::new(); $txtAbrRptAuthor.Width = 298; $txtAbrRptAuthor.Watermark = 'Report author'
    # Email
    $txtAbrMailServer = [TextBox]::new(); $txtAbrMailServer.Width = 298; $txtAbrMailServer.Watermark = 'smtp.example.com'
    $txtAbrMailPort = [TextBox]::new(); $txtAbrMailPort.Width = 298; $txtAbrMailPort.Watermark = '587'
    $txtAbrMailFrom = [TextBox]::new(); $txtAbrMailFrom.Width = 298; $txtAbrMailFrom.Watermark = 'from@example.com'
    $txtAbrMailTo = [TextBox]::new(); $txtAbrMailTo.Width = 298; $txtAbrMailTo.Watermark = 'to@example.com, other@example.com'
    $txtAbrMailBody = [TextBox]::new(); $txtAbrMailBody.Width = 298; $txtAbrMailBody.Watermark = 'Email body text'
    $swAbrMailUseSSL = [ToggleSwitch]::new(); $swAbrMailUseSSL.IsChecked = $true
    $swAbrMailCreds = [ToggleSwitch]::new(); $swAbrMailCreds.IsChecked = $true
    # UserFolder
    $txtAbrFolderPath = [TextBox]::new(); $txtAbrFolderPath.Width = 298; $txtAbrFolderPath.Watermark = '.\AsBuiltReport'

    # Helper: populate all fields from a parsed JSON object
    $loadAbrFields = {
        param ([hashtable]$j)
        $txtAbrCoFullName.Text = if ($j.Company.FullName) { $j.Company.FullName }  else { '' }
        $txtAbrCoShortName.Text = if ($j.Company.ShortName) { $j.Company.ShortName } else { '' }
        $txtAbrCoContact.Text = if ($j.Company.Contact) { $j.Company.Contact }   else { '' }
        $txtAbrCoPhone.Text = if ($j.Company.Phone) { $j.Company.Phone }     else { '' }
        $txtAbrCoAddress.Text = if ($j.Company.Address) { $j.Company.Address }   else { '' }
        $txtAbrCoEmail.Text = if ($j.Company.Email) { $j.Company.Email }     else { '' }
        $txtAbrRptAuthor.Text = if ($j.Report.Author) { $j.Report.Author }     else { '' }
        $txtAbrMailServer.Text = if ($j.Email.Server) { $j.Email.Server }      else { '' }
        $txtAbrMailPort.Text = if ($j.Email.Port) { $j.Email.Port }        else { '' }
        $txtAbrMailFrom.Text = if ($j.Email.From) { $j.Email.From }        else { '' }
        $txtAbrMailTo.Text = if ($j.Email.To) { ($j.Email.To -join ', ') } else { '' }
        $txtAbrMailBody.Text = if ($j.Email.Body) { $j.Email.Body }        else { '' }
        $swAbrMailUseSSL.IsChecked = if ($null -ne $j.Email.UseSSL) { [bool]$j.Email.UseSSL }      else { $true }
        $swAbrMailCreds.IsChecked = if ($null -ne $j.Email.Credentials) { [bool]$j.Email.Credentials } else { $true }
        $txtAbrFolderPath.Text = if ($j.UserFolder.Path) { $j.UserFolder.Path } else {
            if ($IsWindows) { [System.IO.Path]::Combine($env:USERPROFILE, 'Documents', 'AsBuiltReport') } else { [System.IO.Path]::Combine($env:HOME, 'AsBuiltReport') }
        }
    }

    # Helper: build the config ordered hashtable from current field values
    $buildAbrConfig = {
        $toList = ([string]$txtAbrMailTo.Text).Trim() -split '\s*,\s*' | Where-Object { $_ -ne '' }
        $portRaw = ([string]$txtAbrMailPort.Text).Trim()
        $portVal = if ($portRaw -match '^\d+$') { [int]$portRaw } else { $null }

        return [ordered]@{
            Company = [ordered]@{
                FullName = ([string]$txtAbrCoFullName.Text).Trim()
                Phone = ([string]$txtAbrCoPhone.Text).Trim()
                Address = ([string]$txtAbrCoAddress.Text).Trim()
                ShortName = ([string]$txtAbrCoShortName.Text).Trim()
                Contact = ([string]$txtAbrCoContact.Text).Trim()
                Email = ([string]$txtAbrCoEmail.Text).Trim()
            }
            Email = [ordered]@{
                Credentials = [bool]$swAbrMailCreds.IsChecked
                Body = ([string]$txtAbrMailBody.Text).Trim()
                From = ([string]$txtAbrMailFrom.Text).Trim()
                UseSSL = [bool]$swAbrMailUseSSL.IsChecked
                Server = ([string]$txtAbrMailServer.Text).Trim()
                To = if ($toList.Count -gt 0) { @($toList) } else { @() }
                Port = $portVal
            }
            Report = [ordered]@{ Author = ([string]$txtAbrRptAuthor.Text).Trim() }
            UserFolder = [ordered]@{ Path = ([string]$txtAbrFolderPath.Text).Trim() }
        }
    }.GetNewClosure()
    # Also store in syncHash so click handlers always find it regardless of scope
    $syncHash.buildAbrConfig = $buildAbrConfig

    # Helper: validate required fields; returns $null on success or an error message
    $validateAbrRequired = {
        $missing = @()
        if ([string]::IsNullOrWhiteSpace($txtAbrCoFullName.Text)) { $missing += 'Full Name' }
        if ([string]::IsNullOrWhiteSpace($txtAbrCoShortName.Text)) { $missing += 'Short Name' }
        if ([string]::IsNullOrWhiteSpace($txtAbrCoContact.Text)) { $missing += 'Contact' }
        if ([string]::IsNullOrWhiteSpace($txtAbrCoEmail.Text)) { $missing += 'Email' }
        if ([string]::IsNullOrWhiteSpace($txtAbrRptAuthor.Text)) { $missing += 'Author' }
        if ([string]::IsNullOrWhiteSpace($txtAbrFolderPath.Text)) { $missing += 'Path' }
        if ($missing.Count -gt 0) {
            return "⚠ Required fields missing: $($missing -join ', ')"
        }
        return $null
    }.GetNewClosure()
    $syncHash.validateAbrRequired = $validateAbrRequired

    # New button — fills form data into a new file chosen via Save dialog
    $btnAbrNew = [Button]::new()
    $btnAbrNew.Content = '🆕 Create New'
    $btnAbrNew.Margin = '0,0,8,0'
    $btnAbrNew.AddClick({
            try {
                $btnAbrNew.IsEnabled = $false
                # Open a Save dialog so the user picks where the new file will live
                $storageProvider = [Window]::GetTopLevel($btnAbrNew).StorageProvider
                if ($null -eq $storageProvider) {
                    $syncHash.lblConfigStatus.Text = '⚠ Cannot open save dialog.'
                    return
                }
                $defaultDir = if ($IsWindows) {
                    [System.IO.Path]::Combine(
                        [System.IO.Path]::Combine($env:USERPROFILE, 'Documents', 'AsBuiltReport'))
                } else {
                    [System.IO.Path]::Combine(
                        [System.IO.Path]::Combine($env:HOME, 'AsBuiltReport'))
                }
                if (-not (Test-Path $defaultDir)) { New-Item -Path $defaultDir -ItemType Directory -Force | Out-Null }
                $saveOpts = [FilePickerSaveOptions]::new()
                $saveOpts.Title = 'Create New AsBuiltReport Config File'
                $saveOpts.SuggestedFileName = 'AsBuiltReport.json'
                $saveOpts.DefaultExtension = 'json'
                $file = $storageProvider.SaveFilePickerAsync($saveOpts).WaitForCompleted()
                if ($null -eq $file) { return }   # user cancelled
                if ($null -eq $file.Path) {
                    $syncHash.lblConfigStatus.Text = '⚠ Could not resolve file path from dialog.'
                    return
                }

                # Validate required fields before writing
                $validationError = & $syncHash.validateAbrRequired
                if ($null -ne $validationError) {
                    $syncHash.lblConfigStatus.Text = $validationError
                    return
                }

                # Write current form data to the chosen path
                $dest = $file.Path.LocalPath
                $cfg = & $syncHash.buildAbrConfig
                $destDir = Split-Path $dest -Parent
                if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
                $cfg | ConvertTo-Json -Depth 4 | Set-Content -Path $dest -Encoding UTF8

                # Update the AsBuiltReport Config File field so Generate can use it
                $txtAbrConfigPath.Text = $dest
                $syncHash.lblConfigStatus.Text = "✅ Created: $(Split-Path $dest -Leaf)"
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Create failed: $_"
            } finally {
                $btnAbrNew.IsEnabled = $true
            }
        })

    # Load button — reads the path from $txtAbrConfigPath and populates fields
    $btnAbrLoad = [Button]::new()
    $btnAbrLoad.Content = '📂 Load from File'
    $btnAbrLoad.Margin = '0,0,8,0'
    $btnAbrLoad.AddClick({
            try {
                $btnAbrLoad.IsEnabled = $false
                $src = if ($txtAbrConfigPath.Text) { $txtAbrConfigPath.Text.Trim() } else { '' }
                if ([string]::IsNullOrWhiteSpace($src) -or -not (Test-Path $src)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Set a valid AsBuiltReport.json path first.'
                    return
                }
                $j = Get-Content -Path $src -Raw | ConvertFrom-Json -AsHashtable
                & $loadAbrFields $j
                $syncHash.lblConfigStatus.Text = "✅ Loaded: $(Split-Path $src -Leaf)"
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Load failed: $_"
            } finally {
                $btnAbrLoad.IsEnabled = $true
            }
        })

    # Helper: build the config ordered hashtable from current field values
    # Save button — opens a Save dialog when no path is set; otherwise writes in-place
    $btnAbrSave = [Button]::new()
    $btnAbrSave.Content = '💾 Save to File'
    $btnAbrSave.AddClick({
            try {
                $btnAbrSave.IsEnabled = $false
                $validationError = & $syncHash.validateAbrRequired
                if ($null -ne $validationError) {
                    $syncHash.lblConfigStatus.Text = $validationError
                    return
                }
                if ([string]::IsNullOrWhiteSpace($txtAbrConfigPath.Text)) {
                    $syncHash.lblConfigStatus.Text = '❌ Please provide a config file path before saving.'
                    return
                } else {
                    $dest = $txtAbrConfigPath.Text.Trim()
                }
                $cfg = & $syncHash.buildAbrConfig
                $destDir = Split-Path $dest -Parent
                if (-not (Test-Path $destDir)) { New-Item -Path $destDir -ItemType Directory -Force | Out-Null }
                $cfg | ConvertTo-Json -Depth 4 | Set-Content -Path $dest -Encoding UTF8
                $syncHash.lblConfigStatus.Text = "✅ Saved: $(Split-Path $dest -Leaf)"
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Save failed: $_"
            } finally {
                $btnAbrSave.IsEnabled = $true
            }
        })

    # Action row (New + Load + Save)
    $abrActionRow = [StackPanel]::new()
    $abrActionRow.Orientation = 'Horizontal'
    $abrActionRow.Margin = '0,10,0,0'
    $abrActionRow.Children.Add($btnAbrNew)
    $abrActionRow.Children.Add($btnAbrLoad)
    $abrActionRow.Children.Add($btnAbrSave)

    $Text = [TextBlock]::new()
    $Text.Text = '* Required'
    $Text.FontSize = 12
    $Text.Margin = '0,0,0,8'
    $Text.TextAlignment = 'Right'

    # Content panel inside the expander
    $abrInnerPanel = [StackPanel]::new()
    $abrInnerPanel.Spacing = 2
    $abrInnerPanel.Margin = '4,4,4,8'
    $abrInnerPanel.Children.Add(($Text))
    $abrInnerPanel.Children.Add((New-SectionTitle '🏢 Company'))
    $abrInnerPanel.Children.Add((New-FormRow -Label '* Full Name' -Control $txtAbrCoFullName))
    $abrInnerPanel.Children.Add((New-FormRow -Label '* Short Name' -Control $txtAbrCoShortName))
    $abrInnerPanel.Children.Add((New-FormRow -Label '* Contact' -Control $txtAbrCoContact))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'Phone' -Control $txtAbrCoPhone))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'Address' -Control $txtAbrCoAddress))
    $abrInnerPanel.Children.Add((New-FormRow -Label '* Email' -Control $txtAbrCoEmail))
    $abrInnerPanel.Children.Add((New-SectionTitle '📝 Report'))
    $abrInnerPanel.Children.Add((New-FormRow -Label '* Author' -Control $txtAbrRptAuthor))
    $abrInnerPanel.Children.Add((New-SectionTitle '📧 Email'))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'SMTP Server' -Control $txtAbrMailServer))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'Port' -Control $txtAbrMailPort))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'From' -Control $txtAbrMailFrom))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'To (comma-sep.)' -Control $txtAbrMailTo))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'Body' -Control $txtAbrMailBody))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'Use SSL' -Control $swAbrMailUseSSL))
    $abrInnerPanel.Children.Add((New-FormRow -Label 'Credentials' -Control $swAbrMailCreds))
    $abrInnerPanel.Children.Add((New-SectionTitle '📁 User Folder'))
    $abrInnerPanel.Children.Add((New-FormRow -Label '* Path' -Control $txtAbrFolderPath))
    $abrInnerPanel.Children.Add($abrActionRow)

    # Expander — collapsed by default
    $abrExpander = [Expander]::new()
    $abrExpander.Header = '⚙️ AsBuiltReport Global Settings'
    $abrExpander.IsExpanded = $false
    $abrExpander.Margin = '0,8,0,0'
    $abrExpander.Content = $abrInnerPanel

    # ── Save Config Button ────────────────────────────────────────────────────────
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
                DiagramType = [ordered]@{
                    CloudConnect = $true
                    CloudConnectTenant = $true
                    Infrastructure = $true
                    FileProxy = $true
                    HyperVProxy = $true
                    Repository = $true
                    Sobr = $true
                    Tape = $true
                    ProtectedGroup = $true
                    vSphereProxy = $true
                    WanAccelerator = $true
                    HACluster = $true
                }
                NewIcons = $NewIcons
                EnableDiagramDebug = $false
                DiagramWaterMark = ''
                ExportDiagramsFormat = @('pdf')
                EnableDiagramSignature = $false
                SignatureAuthorName = ''
                SignatureCompanyName = ''
                PSDefaultAuthentication = 'Default'
                RoundUnits = 1
                UpdateCheck = $true
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

    $btnSaveConfig = [Button]::new()
    $btnSaveConfig.Content = '💾 Save Config'
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

                function Get-LevelVal ($cbo) { [int]([string]$cbo.SelectedItem).Substring(0, 1) }

                $configObj = Build-VbrConfigObject `
                    -ReportName ($txtReportName.Text.Trim()) `
                    -Style ([string]$cboStyle.SelectedItem) `
                    -Theme ([string]$cboDiagramTheme.SelectedItem) `
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
    $btnLoadConfig.Content = '📂 Load Config'
    $btnLoadConfig.HorizontalAlignment = 'Stretch'
    $btnLoadConfig.HorizontalContentAlignment = 'Center'
    $btnLoadConfig.Width = 196
    $btnLoadConfig.Margin = '4,0,0,0'

    $btnLoadConfig.AddClick({
            $btnLoadConfig.IsEnabled = $false
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
                if ($json.Options.DiagramTheme) { Set-ComboByValue $cboDiagramTheme $json.Options.DiagramTheme }

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
            } finally {
                $btnLoadConfig.IsEnabled = $true
            }
        })

    # ── Open Config Button ────────────────────────────────────────────────────────
    $btnOpenConfig = [Button]::new()
    $btnOpenConfig.Content = '📝 Open Config'
    $btnOpenConfig.HorizontalAlignment = 'Stretch'
    $btnOpenConfig.HorizontalContentAlignment = 'Center'
    $btnOpenConfig.Width = 196
    $btnOpenConfig.Margin = '4,0,0,0'

    $btnOpenConfig.AddClick({
            $btnOpenConfig.IsEnabled = $false
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
            } finally {
                $btnOpenConfig.IsEnabled = $true
            }
        })

    # ── Task Scheduler Section ────────────────────────────────────────────────────

    # Script path
    $txtSchedScriptPath = [TextBox]::new()
    $txtSchedScriptPath.Width = 298
    $txtSchedScriptPath.Text = if ($IsWindows) {
        [System.IO.Path]::Combine($env:USERPROFILE, 'AsBuiltReport', 'AsBuiltReport-VBR.ps1')
    } else {
        [System.IO.Path]::Combine($env:HOME, 'AsBuiltReport', 'AsBuiltReport-VBR.ps1')
    }

    $btnBrowseSchedScript = [Button]::new()
    $btnBrowseSchedScript.Content = 'Browse…'
    $btnBrowseSchedScript.AddClick({
            try {
                $btnBrowseSchedScript.IsEnabled = $false
                $sp = [Window]::GetTopLevel($btnBrowseSchedScript).StorageProvider
                if ($null -eq $sp) { return }
                $opts = [FilePickerSaveOptions]::new()
                $opts.Title = 'Save Schedule Script As'
                $opts.SuggestedFileName = 'AsBuiltReport-VBR.ps1'
                $opts.DefaultExtension = 'ps1'
                $file = $sp.SaveFilePickerAsync($opts).WaitForCompleted()
                if ($null -ne $file) { $txtSchedScriptPath.Text = $file.Path.LocalPath }
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Browse error: $_"
            } finally {
                $btnBrowseSchedScript.IsEnabled = $true
            }
        })

    $schedScriptPathRow = [StackPanel]::new()
    $schedScriptPathRow.Orientation = 'Horizontal'
    $schedScriptPathRow.Spacing = 8
    $schedScriptPathRow.Children.Add($txtSchedScriptPath)
    $schedScriptPathRow.Children.Add($btnBrowseSchedScript)

    # Schedule frequency and day-of-week
    $cboSchedFrequency = [ComboBox]::new()
    $cboSchedFrequency.Width = 140
    @('Daily', 'Weekly', 'Every 4 Weeks') | ForEach-Object { $cboSchedFrequency.Items.Add($_) | Out-Null }
    $cboSchedFrequency.SelectedIndex = 1  # Weekly default

    $cboSchedDayOfWeek = [ComboBox]::new()
    $cboSchedDayOfWeek.Width = 140
    @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday') | ForEach-Object {
        $cboSchedDayOfWeek.Items.Add($_) | Out-Null
    }
    $cboSchedDayOfWeek.SelectedIndex = 0  # Sunday default

    # Day row — initially visible (default is Weekly)
    $schedDayRow = New-FormRow -Label 'Day of Week' -Control $cboSchedDayOfWeek -LabelWidth 165
    $schedDayRow.IsVisible = $true

    $cboSchedFrequency.AddSelectionChanged({
            $schedDayRow.IsVisible = ([string]$cboSchedFrequency.SelectedItem -eq 'Weekly')
        })

    # Start time, task name, run-as credentials
    $txtSchedTime = [TextBox]::new()
    $txtSchedTime.Width = 100
    $txtSchedTime.Text = '06:00'
    $txtSchedTime.Watermark = 'HH:mm'

    $txtSchedTaskName = [TextBox]::new()
    $txtSchedTaskName.Width = 200
    $txtSchedTaskName.Text = 'AsBuiltReport.VBR'

    $txtSchedRunAs = [TextBox]::new()
    $txtSchedRunAs.Width = 200
    $txtSchedRunAs.Watermark = 'DOMAIN\username or user@domain'
    try {
        $txtSchedRunAs.Text = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    } catch {
        $txtSchedRunAs.Text = ''
    }

    $txtSchedTaskPass = [TextBox]::new()
    $txtSchedTaskPass.Width = 200
    $txtSchedTaskPass.Watermark = 'Windows account password (for task registration)'
    try { $txtSchedTaskPass.PasswordChar = [char]'●' } catch { Out-Null }

    # Options toggles
    $swSchedHighest = [ToggleSwitch]::new(); $swSchedHighest.IsChecked = $true
    $swSchedSendEmail = [ToggleSwitch]::new(); $swSchedSendEmail.IsChecked = $false
    $swSchedTimestamp = [ToggleSwitch]::new(); $swSchedTimestamp.IsChecked = $true

    # ── Export Script Button ──────────────────────────────────────────────────────
    $btnExportScript = [Button]::new()
    $btnExportScript.Content = '📜 Export Script'
    $btnExportScript.Margin = '0,0,8,0'
    $btnExportScript.AddClick({
            try {
                $btnExportScript.IsEnabled = $false

                if ($syncHash.IsBusy) {
                    $syncHash.lblConfigStatus.Text = '⚠ Another operation is already running. Please wait.'
                    return
                }

                $scriptPath = $txtSchedScriptPath.Text.Trim()
                if ([string]::IsNullOrWhiteSpace($scriptPath)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Set a script path before exporting.'
                    return
                }

                $srv = $txtServer.Text.Trim()
                $prt = if ($txtPort.Text -match '^\d+$') { [int]$txtPort.Text } else { 443 }
                $usr = $txtUser.Text.Trim()
                $pwds = $txtPass.Text

                if ([string]::IsNullOrWhiteSpace($srv)) {
                    $syncHash.lblConfigStatus.Text = '⚠ VBR Server address is required.'
                    return
                }
                if ([string]::IsNullOrWhiteSpace($usr)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Username is required.'
                    return
                }
                if ([string]::IsNullOrWhiteSpace($pwds)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Enter the VBR password before exporting the script (it will be stored encrypted).'
                    return
                }

                # Derive encrypted-password XML path alongside the script
                $pwdXmlPath = [System.IO.Path]::ChangeExtension($scriptPath, 'xml')
                $scriptDir = Split-Path $scriptPath -Parent
                if (-not (Test-Path $scriptDir)) { New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null }

                # Encrypt the VBR password with Windows DPAPI via Export-Clixml
                $secPwd = ConvertTo-SecureString $pwds -AsPlainText -Force
                $secPwd | Export-Clixml -Path $pwdXmlPath

                # Collect current form values
                $outPath = $txtOutput.Text.Trim()
                $vbrCfg = $txtConfigPath.Text.Trim()
                $abrCfg = $txtAbrConfigPath.Text.Trim()

                $fmts = @()
                if ($chkHTML.IsChecked -eq $true) { $fmts += "'Html'" }
                if ($chkWord.IsChecked -eq $true) { $fmts += "'Word'" }
                if ($chkText.IsChecked -eq $true) { $fmts += "'Text'" }
                if ($fmts.Count -eq 0) { $fmts = @("'Html'") }
                $fmtStr = $fmts -join ', '
                $addTs = [bool]$swSchedTimestamp.IsChecked
                $sendEmail = [bool]$swSchedSendEmail.IsChecked
                $genDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

                # Build optional parameter lines
                $optLines = ''
                if (-not [string]::IsNullOrWhiteSpace($vbrCfg)) {
                    $optLines += "`n    ReportConfigFilePath  = '$vbrCfg'"
                }
                if (-not [string]::IsNullOrWhiteSpace($abrCfg)) {
                    $optLines += "`n    AsBuiltConfigFilePath = '$abrCfg'"
                }
                if ($addTs) { $optLines += "`n    Timestamp             = `$true" }
                if ($sendEmail) { $optLines += "`n    SendEmail             = `$true" }

                $scriptContent = @"
#Requires -Version 7.4
<#
.SYNOPSIS
    AsBuiltReport.Veeam.VBR — Automated Scheduled Report
.NOTES
    Generated : $genDate
    Target    : $srv (port $prt)
    User      : $usr

    SECURITY: Password.xml is encrypted with Windows DPAPI.
    It can only be decrypted on this machine by the same Windows account that exported it:
    '$($env:USERDOMAIN)\$($env:USERNAME)'.
    Ensure the scheduled task runs as that same Windows account, and do NOT copy Password.xml
    to another machine or user profile.
#>

# Import encrypted VBR credential (Windows DPAPI — tied to the exporting Windows account on this machine)
`$securePassword = Import-Clixml -Path '$pwdXmlPath'
`$vbrCredential  = [PSCredential]::new('$usr', `$securePassword)

# Import required modules
Import-Module AsBuiltReport.Core, AsBuiltReport.Chart, AsBuiltReport.Diagram, AsBuiltReport.Veeam.VBR -Force

# Report parameters
`$params = @{
    Report           = 'Veeam.VBR'
    Target           = '$srv'
    Username         = `$vbrCredential.UserName
    Password         = `$vbrCredential.GetNetworkCredential().Password
    Format           = @($fmtStr)
    OutputFolderPath = '$outPath'$optLines
}

New-AsBuiltReport @params
"@

                $scriptContent | Set-Content -Path $scriptPath -Encoding UTF8
                $syncHash.lblConfigStatus.Text = "✅ Script exported to $(Split-Path $scriptPath -Leaf)  |  Encrypted password: $(Split-Path $pwdXmlPath -Leaf)"
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Export failed: $_"
            } finally {
                $btnExportScript.IsEnabled = $true
            }
        })

    # ── Register Task Button ──────────────────────────────────────────────────────
    $btnRegisterTask = [Button]::new()
    $btnRegisterTask.Content = '📅 Register Task'
    $btnRegisterTask.AddClick({
            try {
                $btnRegisterTask.IsEnabled = $false

                if ($syncHash.IsBusy) {
                    $syncHash.lblConfigStatus.Text = '⚠ Another operation is already running. Please wait.'
                    return
                }

                if (-not $IsWindows) {
                    $syncHash.lblConfigStatus.Text = '⚠ Windows Task Scheduler is only available on Windows.'
                    return
                }

                $scriptPath = $txtSchedScriptPath.Text.Trim()
                $taskName = $txtSchedTaskName.Text.Trim()
                $runAsUser = $txtSchedRunAs.Text.Trim()
                $runAsPass = $txtSchedTaskPass.Text
                $freq = [string]$cboSchedFrequency.SelectedItem
                $timeStr = $txtSchedTime.Text.Trim()
                $highest = [bool]$swSchedHighest.IsChecked

                if ([string]::IsNullOrWhiteSpace($scriptPath) -or -not (Test-Path $scriptPath)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Script not found — click "📜 Export Script" first.'
                    return
                }
                if ([string]::IsNullOrWhiteSpace($taskName)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Task name is required.'
                    return
                }
                if ([string]::IsNullOrWhiteSpace($runAsUser)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Run-as user is required.'
                    return
                }
                if ([string]::IsNullOrWhiteSpace($runAsPass)) {
                    $syncHash.lblConfigStatus.Text = '⚠ Windows account password is required to register the task.'
                    return
                }
                if ($timeStr -notmatch '^\d{1,2}:\d{2}$') {
                    $syncHash.lblConfigStatus.Text = '⚠ Start time must be in HH:mm format (e.g. 06:00).'
                    return
                }

                $startTime = [datetime]::ParseExact($timeStr, 'H:mm', [System.Globalization.CultureInfo]::InvariantCulture)

                # Resolve pwsh.exe
                $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
                if ([string]::IsNullOrWhiteSpace($pwshPath)) { $pwshPath = Join-Path $PSHOME 'pwsh.exe' }

                # Build trigger
                $trigger = switch ($freq) {
                    'Daily' { New-ScheduledTaskTrigger -Daily -At $startTime }
                    'Weekly' {
                        $day = [string]$cboSchedDayOfWeek.SelectedItem
                        New-ScheduledTaskTrigger -Weekly -DaysOfWeek $day -At $startTime
                    }
                    'Every 4 Weeks' {
                        $day = [string]$cboSchedDayOfWeek.SelectedItem
                        New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek $day -At $startTime
                    }
                    default { New-ScheduledTaskTrigger -Weekly -DaysOfWeek 'Sunday' -At $startTime }
                }

                $action = New-ScheduledTaskAction -Execute $pwshPath `
                    -Argument "-NonInteractive -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
                $settings = New-ScheduledTaskSettingsSet `
                    -ExecutionTimeLimit (New-TimeSpan -Hours 4) `
                    -RestartCount 0 `
                    -StartWhenAvailable

                $regParams = @{
                    TaskName = $taskName
                    Action = $action
                    Trigger = $trigger
                    Settings = $settings
                    Description = 'Automated AsBuiltReport.Veeam.VBR report — managed by GUI'
                    User = $runAsUser
                    Password = $runAsPass
                    Force = $true
                }
                if ($highest) { $regParams['RunLevel'] = 'Highest' }

                Register-ScheduledTask @regParams | Out-Null
                $syncHash.lblConfigStatus.Text = "✅ Task '$taskName' registered — next run: $startTime ($freq)"
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Task registration failed: $_"
            } finally {
                $btnRegisterTask.IsEnabled = $true
            }
        })

    # Schedule action buttons row
    $schedActionRow = [StackPanel]::new()
    $schedActionRow.Orientation = 'Horizontal'
    $schedActionRow.Margin = '0,10,0,0'
    $schedActionRow.Spacing = 8
    $schedActionRow.Children.Add($btnExportScript)
    $schedActionRow.Children.Add($btnRegisterTask)

    # Assemble scheduler inner panel
    $schedInnerPanel = [StackPanel]::new()
    $schedInnerPanel.Spacing = 2
    $schedInnerPanel.Margin = '4,4,4,8'
    $schedInnerPanel.Children.Add((New-SectionTitle '📜 Script'))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Script Path' -Control $schedScriptPathRow -LabelWidth 165))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Add Timestamp' -Control $swSchedTimestamp -LabelWidth 165))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Send Email' -Control $swSchedSendEmail -LabelWidth 165))
    $schedInnerPanel.Children.Add((New-SectionTitle '🕐 Schedule'))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Frequency' -Control $cboSchedFrequency -LabelWidth 165))
    $schedInnerPanel.Children.Add($schedDayRow)
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Start Time (HH:mm)' -Control $txtSchedTime -LabelWidth 165))
    $schedInnerPanel.Children.Add((New-SectionTitle '⚙️ Task Settings'))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Task Name' -Control $txtSchedTaskName -LabelWidth 165))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Run As User' -Control $txtSchedRunAs -LabelWidth 165))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'User Password' -Control (New-PasswordRow $txtSchedTaskPass) -LabelWidth 165))
    $schedInnerPanel.Children.Add((New-FormRow -Label 'Highest Privileges' -Control $swSchedHighest -LabelWidth 165))
    $schedInnerPanel.Children.Add($schedActionRow)


    # ── Export Diagrams Controls ─────────────────────────────────────────────────
    $chkDiaFmtPng = [CheckBox]::new(); $chkDiaFmtPng.Content = 'PNG'; $chkDiaFmtPng.IsChecked = $true
    $chkDiaFmtPdf = [CheckBox]::new(); $chkDiaFmtPdf.Content = 'PDF'; $chkDiaFmtPdf.IsChecked = $false
    $chkDiaFmtSvg = [CheckBox]::new(); $chkDiaFmtSvg.Content = 'SVG'; $chkDiaFmtSvg.IsChecked = $false
    $chkDiaFmtDot = [CheckBox]::new(); $chkDiaFmtDot.Content = 'DOT'; $chkDiaFmtDot.IsChecked = $false
    $chkDiaFmtJpg = [CheckBox]::new(); $chkDiaFmtJpg.Content = 'JPG'; $chkDiaFmtJpg.IsChecked = $false

    $diaFmtPanel = [StackPanel]::new()
    $diaFmtPanel.Orientation = 'Horizontal'
    $diaFmtPanel.Spacing = 14
    @($chkDiaFmtPng, $chkDiaFmtPdf, $chkDiaFmtSvg, $chkDiaFmtDot, $chkDiaFmtJpg) | ForEach-Object {
        $diaFmtPanel.Children.Add($_) | Out-Null
    }

    # Dedicated output folder for the Export Diagrams page.
    $txtDiaOutput = [TextBox]::new()
    $txtDiaOutput.Width = 220
    $txtDiaOutput.Text = if ($IsWindows) {
        [System.IO.Path]::Combine($env:USERPROFILE, 'Documents', 'AsBuiltReport')
    } else {
        [System.IO.Path]::Combine($env:HOME, 'AsBuiltReport')
    }

    $btnDiaBrowse = [Button]::new()
    $btnDiaBrowse.Content = 'Browse…'
    $btnDiaBrowse.AddClick({
            try {
                $btnDiaBrowse.IsEnabled = $false
                $storageProvider = [Window]::GetTopLevel($btnDiaBrowse).StorageProvider
                if ($null -eq $storageProvider) { return }
                $options = [FolderPickerOpenOptions]::new()
                $options.Title = 'Select Diagram Output Folder'
                $folders = $storageProvider.OpenFolderPickerAsync($options).WaitForCompleted()
                if ($folders -and $folders.Count -gt 0) {
                    $txtDiaOutput.Text = $folders[0].Path.LocalPath
                }
            } catch {
                Write-Host "Folder picker error: $_" -ForegroundColor Red
            } finally {
                $btnDiaBrowse.IsEnabled = $true
            }
        })

    $diaOutputPathRow = [StackPanel]::new()
    $diaOutputPathRow.Orientation = 'Horizontal'
    $diaOutputPathRow.Spacing = 8
    $diaOutputPathRow.Children.Add($txtDiaOutput)
    $diaOutputPathRow.Children.Add($btnDiaBrowse)

    # Dedicated port for Export — defaults to 443 (VBR default), distinct from the
    # shared report port which defaults to 443.
    $txtDiaPort = [TextBox]::new()
    $txtDiaPort.Width = 80
    $txtDiaPort.Text = '443'
    $txtDiaPort.Watermark = 'port'

    # Server connection controls specific to the Export Diagrams page
    $txtDiaServer = [TextBox]::new()
    $txtDiaServer.Width = 175
    $txtDiaServer.Watermark = 'Backup Server FQDN'

    $diaServerRow = [StackPanel]::new()
    $diaServerRow.Orientation = 'Horizontal'
    $diaServerRow.Spacing = 6
    $diaServerRow.Children.Add($txtDiaServer)
    $diaServerRow.Children.Add((New-InlineLabel 'Port'))
    $diaServerRow.Children.Add($txtDiaPort)

    $txtDiaUser = [TextBox]::new()
    $txtDiaUser.Width = 200
    $txtDiaUser.Watermark = 'username@domain'

    $txtDiaPass = [TextBox]::new()
    $txtDiaPass.Width = 200
    $txtDiaPass.Watermark = 'Password'
    try { $txtDiaPass.PasswordChar = [char]'●' } catch { Out-Null }

    # ── Saved Connections for Export Diagrams page ────────────────────────────────
    # Shares the same JSON file as the Report page so connections are cross-page.
    $cboDiaSavedConn = [ComboBox]::new()
    $cboDiaSavedConn.Width = 262

    $refreshDiaSavedConnCombo = {
        $cboDiaSavedConn.Items.Clear()
        foreach ($c in (& $loadSavedConns)) {
            $cboDiaSavedConn.Items.Add("$($c.Server):$($c.Port) ($($c.Username))") | Out-Null
        }
    }.GetNewClosure()
    & $refreshDiaSavedConnCombo

    $cboDiaSavedConn.AddSelectionChanged({
            $idx = $cboDiaSavedConn.SelectedIndex
            if ($idx -lt 0) { return }
            $conns = & $loadSavedConns
            if ($idx -ge $conns.Count) { return }
            $sel = $conns[$idx]
            $txtDiaServer.Text = $sel.Server
            $txtDiaPort.Text = [string]$sel.Port
            $txtDiaUser.Text = $sel.Username
            $txtDiaPass.Text = ''
        })

    $btnDiaSaveConn = [Button]::new()
    $btnDiaSaveConn.Content = '💾 Save Connection'
    $btnDiaSaveConn.AddClick({
            $srv = $txtDiaServer.Text.Trim()
            $prt = if ($txtDiaPort.Text -match '^\d+$') { [int]$txtDiaPort.Text } else { 443 }
            $usr = $txtDiaUser.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($srv) -or [string]::IsNullOrWhiteSpace($usr)) {
                $syncHash.lblConfigStatus.Text = '⚠ Enter Server and Username before saving a connection.'
                return
            }
            $conns = [System.Collections.ArrayList]@()
            foreach ($c in (& $loadSavedConns)) { $conns.Add($c) | Out-Null }
            $dup = $conns | Where-Object { $_.Server -eq $srv -and $_.Port -eq $prt -and $_.Username -eq $usr }
            if (-not $dup) {
                $conns.Add([PSCustomObject]@{ Server = $srv; Port = $prt; Username = $usr }) | Out-Null
                & $saveSavedConns -Connections @($conns)
                & $refreshSavedConnCombo
                $syncHash.lblConfigStatus.Text = "✅ Connection saved: $srv ($usr)"
            } else {
                $syncHash.lblConfigStatus.Text = "ℹ Connection already exists: $srv ($usr)"
            }
        })

    $btnDiaDeleteConn = [Button]::new()
    $btnDiaDeleteConn.Content = '🗑 Delete'
    $btnDiaDeleteConn.AddClick({
            $idx = $cboDiaSavedConn.SelectedIndex
            if ($idx -lt 0) {
                $syncHash.lblConfigStatus.Text = '⚠ Select a saved connection to delete.'
                return
            }
            $conns = [System.Collections.ArrayList]@()
            foreach ($c in (& $loadSavedConns)) { $conns.Add($c) | Out-Null }
            if ($idx -ge $conns.Count) { return }
            $removed = $conns[$idx]
            $conns.RemoveAt($idx)
            & $saveSavedConns -Connections @($conns)
            $cboDiaSavedConn.SelectedIndex = -1
            & $refreshSavedConnCombo
            $syncHash.lblConfigStatus.Text = "🗑 Deleted: $($removed.Server) ($($removed.Username))"
        })

    $diaSavedConnActionsRow = [StackPanel]::new()
    $diaSavedConnActionsRow.Orientation = 'Horizontal'
    $diaSavedConnActionsRow.Spacing = 6
    $diaSavedConnActionsRow.Children.Add($btnDiaSaveConn)
    $diaSavedConnActionsRow.Children.Add($btnDiaDeleteConn)

    # Redefine $refreshSavedConnCombo to keep both combos in sync.
    # The Report page's Save/Delete buttons look up this variable at call-time,
    # so they automatically pick up this new version that refreshes both.
    $refreshSavedConnCombo = {
        $cboSavedConn.Items.Clear()
        $cboDiaSavedConn.Items.Clear()
        foreach ($c in (& $loadSavedConns)) {
            $label = "$($c.Server):$($c.Port) ($($c.Username))"
            $cboSavedConn.Items.Add($label) | Out-Null
            $cboDiaSavedConn.Items.Add($label) | Out-Null
        }
    }.GetNewClosure()

    # Multi-select ListBox: leave empty to export all diagram types.
    # Note: Backup-to-CloudConnect-Tenant always uses left-to-right regardless of Direction.
    $lstDiaTypes = [ListBox]::new()
    $lstDiaTypes.SelectionMode = 'Multiple'
    $lstDiaTypes.Height = 172
    @(
        'Backup-Infrastructure',
        'Backup-to-Repository',
        'Backup-to-Sobr',
        'Backup-to-vSphere-Proxy',
        'Backup-to-HyperV-Proxy',
        'Backup-to-File-Proxy',
        'Backup-to-WanAccelerator',
        'Backup-to-Tape',
        'Backup-to-ProtectedGroup',
        'Backup-to-CloudConnect',
        'Backup-to-CloudConnect-Tenant',
        'Backup-to-HACluster'
    ) | ForEach-Object { $lstDiaTypes.Items.Add($_) | Out-Null }

    $btnDiaSelectAll = [Button]::new()
    $btnDiaSelectAll.Content = 'Select All'
    $btnDiaSelectAll.Margin = '0,0,6,0'
    $btnDiaSelectAll.AddClick({ $lstDiaTypes.SelectAll() })

    $btnDiaClearAll = [Button]::new()
    $btnDiaClearAll.Content = 'Clear'
    $btnDiaClearAll.AddClick({ $lstDiaTypes.UnselectAll() })

    $diaTypeActionsRow = [StackPanel]::new()
    $diaTypeActionsRow.Orientation = 'Horizontal'
    $diaTypeActionsRow.Margin = '0,4,0,0'
    $diaTypeActionsRow.Children.Add($btnDiaSelectAll)
    $diaTypeActionsRow.Children.Add($btnDiaClearAll)

    $btnExportDiagram = [Button]::new()
    $btnExportDiagram.Content = '🖼 Export Diagrams'
    $btnExportDiagram.HorizontalAlignment = 'Stretch'
    $btnExportDiagram.HorizontalContentAlignment = 'Center'
    $btnExportDiagram.FontSize = 14
    $btnExportDiagram.FontWeight = 'SemiBold'
    $btnExportDiagram.Margin = '0,14,0,0'
    $syncHash.btnExportDiagram = $btnExportDiagram

    $exportDiagramCallback = [EventCallback]::new()
    $exportDiagramCallback.RunspaceMode = 'RunspacePoolAsyncUI'
    $exportDiagramCallback.DisabledControlsWhileProcessing = $btnExportDiagram
    $exportDiagramCallback.ArgumentList = @{
        SyncHash = $syncHash
        Server = $txtDiaServer
        Port = $txtDiaPort
        Username = $txtDiaUser
        Password = $txtDiaPass
        OutPath = $txtDiaOutput
        DiagTheme = $cboDiagramTheme
        DiagColSize = $txtColSize
        NewIcons = $swNewIcons
        FmtPng = $chkDiaFmtPng
        FmtPdf = $chkDiaFmtPdf
        FmtSvg = $chkDiaFmtSvg
        FmtDot = $chkDiaFmtDot
        FmtJpg = $chkDiaFmtJpg
        DiaTypes = $lstDiaTypes
        Verbose = $chkVerbose
    }

    $exportDiagramCallback.ScriptBlock = {
        param ($ui)
        $sh = $ui.SyncHash

        if ($sh.IsBusy) {
            $sh.lblConfigStatus.Text = '⚠ Another operation is already running. Please wait.'
            return
        }
        $sh.IsBusy = $true
        $sh.progressBar.IsVisible = $true
        $sh.txtLog.Text = ''

        $verboseEnabled = $ui.Verbose.IsChecked -eq $true

        function Write-Logging ([string]$Msg, [string]$Level = '', [bool]$AddTimestamp = $false) {
            $ts = Get-Date -Format 'HH:mm:ss'
            if ($Level -eq '') {
                $sh.txtLog.Text += if ($AddTimestamp) { "[$ts] $Msg`n" } else { "$Msg`n" }
            } else {
                $sh.txtLog.Text += if ($AddTimestamp) { "[$ts][$Level] $Msg`n" } else { "[$Level] $Msg`n" }
            }
            $sh.txtLog.CaretIndex = $sh.txtLog.Text.Length
        }

        # Snapshot all UI values up-front before any long-running work.
        $server = $ui.Server.Text.Trim()
        $port = if ($ui.Port.Text -match '^\d+$') { $ui.Port.Text } else { '9392' }
        $username = $ui.Username.Text.Trim()
        $password = $ui.Password.Text
        $outPath = $ui.OutPath.Text.Trim()
        $theme = [string]$ui.DiagTheme.SelectedItem
        $colSize = if ($ui.DiagColSize.Text -match '^\d+$') { [int]$ui.DiagColSize.Text } else { 3 }
        $newIcons = $ui.NewIcons.IsChecked -eq $true

        $formats = @()
        if ($ui.FmtPng.IsChecked -eq $true) { $formats += 'png' }
        if ($ui.FmtPdf.IsChecked -eq $true) { $formats += 'pdf' }
        if ($ui.FmtSvg.IsChecked -eq $true) { $formats += 'svg' }
        if ($ui.FmtDot.IsChecked -eq $true) { $formats += 'dot' }
        if ($ui.FmtJpg.IsChecked -eq $true) { $formats += 'jpg' }
        if ($formats.Count -eq 0) { $formats = @('png') }

        # Snapshot the ListBox selection — empty means all types.
        $selectedTypes = @($ui.DiaTypes.SelectedItems | ForEach-Object { "$_" })
        if ($selectedTypes.Count -eq 0) { $selectedTypes = @('All') }

        if ([string]::IsNullOrWhiteSpace($server)) {
            Write-Logging 'VBR Server address is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.IsBusy = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($username)) {
            Write-Logging 'Username is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.IsBusy = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($password)) {
            Write-Logging 'Password is required.' 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.IsBusy = $false; return
        }
        if ([string]::IsNullOrWhiteSpace($outPath)) {
            $outPath = [System.IO.Path]::GetTempPath()
        }
        if (-not (Test-Path $outPath)) {
            New-Item -Path $outPath -ItemType Directory -Force | Out-Null
            Write-Logging "Created output folder: $outPath"
        }

        Write-Logging "Target    : $server (port $port)"
        Write-Logging "User      : $username"
        Write-Logging "Formats   : $($formats -join ', ')"
        Write-Logging "Theme     : $theme"
        Write-Logging "Types     : $($selectedTypes -join ', ')"
        Write-Logging "Output    : $outPath"

        Write-Logging 'Loading AsBuiltReport modules…'
        try {
            Import-Module AsBuiltReport.Core, AsBuiltReport.Chart, AsBuiltReport.Diagram, AsBuiltReport.Veeam.VBR -Force -ErrorAction Stop
        } catch {
            Write-Logging "Failed to load modules: $_" 'ERROR'
            $sh.progressBar.IsVisible = $false; $sh.IsBusy = $false; return
        }

        try {
            Write-Logging 'Starting diagram export…'

            $secPwd = ConvertTo-SecureString $password -AsPlainText -Force
            $credential = [PSCredential]::new($username, $secPwd)

            $params = @{
                Target = $server
                Credential = $credential
                OutputFolderPath = $outPath
                Format = $formats
                DiagramTheme = $theme
                ColumnSize = $colSize
                Port = $port
                DiagramType = $selectedTypes
            }
            if ($newIcons) { $params['NewIcons'] = $true }
            if ($verboseEnabled) { $params['Verbose'] = $true }

            Export-AsBuiltReportVBRDiagram @params *>&1 | ForEach-Object {
                if ($_ -is [System.Management.Automation.ErrorRecord]) {
                    Write-Logging "$($_.Exception.Message)" 'ERROR'
                } elseif ($_ -is [System.Management.Automation.WarningRecord]) {
                    Write-Logging "$($_.Message)" 'WARN'
                } elseif ($_ -is [System.Management.Automation.VerboseRecord]) {
                    if ($verboseEnabled) { Write-Logging "$($_.Message)" 'VERBOSE' }
                } elseif ($_ -is [System.Management.Automation.InformationRecord]) {
                    $line = "$($_.MessageData)"
                    if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Logging $line }
                } else {
                    $line = "$_"
                    if (-not [string]::IsNullOrWhiteSpace($line)) { Write-Logging $line }
                }
            }
            Write-Logging -Msg "✅ Diagram export completed. Files saved to: $outPath" -Level '' -AddTimestamp $true
        } catch {
            Write-Logging $_.Exception.Message 'ERROR'
            if ($_.ScriptStackTrace) { Write-Logging $_.ScriptStackTrace 'ERROR' }

        } finally {
            $sh.progressBar.IsVisible = $false
            $sh.IsBusy = $false
        }
    }

    $btnExportDiagram.AddClick($exportDiagramCallback)

    # Left column: Server Connection
    $diaConnPanel = [StackPanel]::new()
    $diaConnPanel.Spacing = 2
    $diaConnPanel.Children.Add((New-SectionTitle '🔌 Server Connection'))
    $diaConnPanel.Children.Add((New-FormRow -Label 'Saved Connections' -Control $cboDiaSavedConn -LabelWidth 130))
    $diaConnPanel.Children.Add((New-FormRow -Label 'VBR Server' -Control $diaServerRow -LabelWidth 130))
    $diaConnPanel.Children.Add((New-FormRow -Label 'Username' -Control $txtDiaUser -LabelWidth 130))
    $diaConnPanel.Children.Add((New-FormRow -Label 'Password' -Control (New-PasswordRow $txtDiaPass) -LabelWidth 130))
    $diaConnPanel.Children.Add((New-FormRow -Label '' -Control $diaSavedConnActionsRow -LabelWidth 130))

    # Right column: Diagram Types
    $diaTypesPanel = [StackPanel]::new()
    $diaTypesPanel.Spacing = 2
    $diaTypesPanel.Children.Add((New-SectionTitle '📐 Diagram Types'))
    $diaTypesPanel.Children.Add((New-FormRow -Label 'Select (empty = All)' -Control $lstDiaTypes -LabelWidth 165))
    $diaTypesPanel.Children.Add($diaTypeActionsRow)

    # Two-column top grid: Server Connection | Diagram Types
    $diaTopGrid = [Grid]::new()
    $diaTopGrid.ColumnDefinitions = [ColumnDefinitions]::Parse('*, *')
    $diaTopGrid.ColumnSpacing = 24
    $diaTopGrid.Margin = '0,0,0,4'
    [Grid]::SetColumn($diaConnPanel, 0)
    [Grid]::SetColumn($diaTypesPanel, 1)
    $diaTopGrid.Children.Add($diaConnPanel)
    $diaTopGrid.Children.Add($diaTypesPanel)

    # Bottom strip: Output format + folder (full width)
    $diaOutputPanel = [StackPanel]::new()
    $diaOutputPanel.Spacing = 2
    $diaOutputPanel.Margin = '0,4,0,0'
    $diaOutputPanel.Children.Add((New-SectionTitle '📁 Output'))
    $diaOutputPanel.Children.Add((New-FormRow -Label 'Format' -Control $diaFmtPanel))
    $diaOutputPanel.Children.Add((New-FormRow -Label 'Output Folder' -Control $diaOutputPathRow))

    $exportDiagInnerPanel = [StackPanel]::new()
    $exportDiagInnerPanel.Spacing = 2
    $exportDiagInnerPanel.Margin = '4,4,4,8'
    $exportDiagInnerPanel.Children.Add($diaTopGrid)
    $exportDiagInnerPanel.Children.Add($diaOutputPanel)
    $exportDiagInnerPanel.Children.Add($btnExportDiagram)


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

    # Row 1: Server Connection | Report Output — two-column side-by-side grid
    $topGrid = [Grid]::new()
    $topGrid.ColumnDefinitions = [ColumnDefinitions]::Parse('*, *')
    $topGrid.ColumnSpacing = 24
    $topGrid.Margin = '0,4,0,0'

    $connPanel = [StackPanel]::new()
    $connPanel.Spacing = 2
    $connPanel.Children.Add((New-SectionTitle '🔌 Server Connection'))
    $connPanel.Children.Add((New-FormRow -Label 'Saved Connections' -Control $cboSavedConn -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'VBR Server' -Control $serverRow -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'Username' -Control $txtUser -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label 'Password' -Control (New-PasswordRow $txtPass) -LabelWidth 130))
    $connPanel.Children.Add((New-FormRow -Label '' -Control $savedConnActionsRow -LabelWidth 130))
    [Grid]::SetColumn($connPanel, 0)
    $topGrid.Children.Add($connPanel)

    $outPanel = [StackPanel]::new()
    $outPanel.Spacing = 2
    $outPanel.Children.Add((New-SectionTitle '📄 Report Output'))
    $outPanel.Children.Add((New-FormRow -Label 'Report Name' -Control $txtReportName -LabelWidth 130))
    $outPanel.Children.Add((New-FormRow -Label 'Format' -Control $fmtPanel -LabelWidth 130))
    $outPanel.Children.Add((New-FormRow -Label 'Output Folder' -Control $outputPathRow -LabelWidth 130))
    $outPanel.Children.Add((New-FormRow -Label 'Report Style' -Control $styleRow -LabelWidth 130))
    [Grid]::SetColumn($outPanel, 1)
    $topGrid.Children.Add($outPanel)

    $mainPanel.Children.Add($topGrid)

    # Row 2: Options | Info Level — two-column side-by-side grid
    $bottomGrid = [Grid]::new()
    $bottomGrid.ColumnDefinitions = [ColumnDefinitions]::Parse('*, *')
    $bottomGrid.ColumnSpacing = 24
    $bottomGrid.Margin = '0,4,0,0'

    $optPanel = [StackPanel]::new()
    $optPanel.Spacing = 2
    $optPanel.Children.Add((New-SectionTitle '⚙️ Options'))
    $optPanel.Children.Add((New-FormRow -Label 'Enable Diagrams' -Control $swDiagrams -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Export Diagrams' -Control $swExportDia -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Hardware Inventory' -Control $swHWInv -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Use New Icons' -Control $swNewIcons -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Enable Health Check' -Control $swHealthChk -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Add Timestamp' -Control $swTimestamp -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Diagram Columns' -Control $txtColSize -LabelWidth 165))
    $optPanel.Children.Add((New-FormRow -Label 'Diagram Theme' -Control $cboDiagramTheme -LabelWidth 165))
    [Grid]::SetColumn($optPanel, 0)
    $bottomGrid.Children.Add($optPanel)

    $lvlPanel = [StackPanel]::new()
    $lvlPanel.Spacing = 2
    $lvlPanel.Children.Add((New-SectionTitle '📊 Info Level'))
    $lvlPanel.Children.Add((New-FormRow -Label 'Infrastructure' -Control $cboLvlInfrastructure))
    $lvlPanel.Children.Add((New-FormRow -Label 'Tape' -Control $cboLvlTape))
    $lvlPanel.Children.Add((New-FormRow -Label 'Inventory' -Control $cboLvlInventory))
    $lvlPanel.Children.Add((New-FormRow -Label 'Storage' -Control $cboLvlStorage))
    $lvlPanel.Children.Add((New-FormRow -Label 'Replication' -Control $cboLvlReplication))
    $lvlPanel.Children.Add((New-FormRow -Label 'Cloud Connect' -Control $cboLvlCloudConnect))
    $lvlPanel.Children.Add((New-FormRow -Label 'Jobs' -Control $cboLvlJobs))
    [Grid]::SetColumn($lvlPanel, 1)
    $bottomGrid.Children.Add($lvlPanel)

    $mainPanel.Children.Add($bottomGrid)

    # Section: Config Management
    $mainPanel.Children.Add((New-SectionTitle '🗂️ Config Management'))

    $cfgBtnRow = [StackPanel]::new()
    $cfgBtnRow.Orientation = 'Horizontal'
    $cfgBtnRow.Margin = '0,4,0,0'
    $cfgBtnRow.Children.Add($btnSaveConfig)
    $cfgBtnRow.Children.Add($btnLoadConfig)
    $cfgBtnRow.Children.Add($btnOpenConfig)

    $mainPanel.Children.Add((New-FormRow -Label '📄 Veeam VBR Config File' -Control $configPathRow))
    $mainPanel.Children.Add($cfgBtnRow)
    $mainPanel.Children.Add((New-FormRow -Label '📄 AsBuiltReport Config File' -Control $abrConfigPathRow))
    $mainPanel.Children.Add($abrExpander)

    # Generate button
    $mainPanel.Children.Add($btnGenerate)

    # Log area — header row: title (left) + Export Log button (right)
    $logTitle = [TextBlock]::new()
    $logTitle.Text = '📋 Output Log'
    $logTitle.FontSize = 13
    $logTitle.FontWeight = 'SemiBold'
    $logTitle.VerticalAlignment = 'Center'

    $logHeaderGrid = [Grid]::new()
    $logHeaderGrid.Margin = '0,14,0,6'
    $logHeaderGrid.ColumnDefinitions.Add(
        [ColumnDefinition]::new([GridLength]::new(1, [GridUnitType]::Star)))
    $logHeaderGrid.ColumnDefinitions.Add(
        [ColumnDefinition]::new([GridLength]::new(0, [GridUnitType]::Auto)))
    $logHeaderGrid.ColumnDefinitions.Add(
        [ColumnDefinition]::new([GridLength]::new(0, [GridUnitType]::Auto)))
    [Grid]::SetColumn($logTitle, 0)
    [Grid]::SetColumn($chkVerbose, 1)
    [Grid]::SetColumn($btnExportLog, 2)
    $logHeaderGrid.Children.Add($logTitle)
    $logHeaderGrid.Children.Add($chkVerbose)
    $logHeaderGrid.Children.Add($btnExportLog)

    # Cancel button row — right-aligned, only visible during generation
    $btnOpenOutputFolder = [Button]::new()
    $btnOpenOutputFolder.Content = '📁 Open Output Folder'
    $btnOpenOutputFolder.Margin = '0,0,8,0'
    $btnOpenOutputFolder.AddClick({
            $path = $txtOutput.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($path)) {
                $syncHash.lblConfigStatus.Text = '⚠ No output folder set.'
                return
            }
            if (-not (Test-Path $path)) {
                $syncHash.lblConfigStatus.Text = "⚠ Output folder not found: $path"
                return
            }
            try {
                Start-Process $path
            } catch {
                $syncHash.lblConfigStatus.Text = "❌ Could not open folder: $_"
            }
        })

    $logActionsRow = [StackPanel]::new()
    $logActionsRow.Orientation = 'Horizontal'
    $logActionsRow.HorizontalAlignment = 'Right'
    $logActionsRow.Margin = '0,6,0,0'
    $logActionsRow.Children.Add($btnOpenOutputFolder)
    $logActionsRow.Children.Add($btnCancel)

    $scrollView = [ScrollViewer]::new()
    $scrollView.Content = $mainPanel

    # ── Drawer Pages ─────────────────────────────────────────────────────────────
    $reportPage = [ContentPage]::new()
    $reportPage.Header = 'Report'
    $reportPage.Content = $scrollView

    $schedInnerPanel.Margin = '28,20,28,24'
    $schedScrollView = [ScrollViewer]::new()
    $schedScrollView.Content = $schedInnerPanel
    $schedulePage = [ContentPage]::new()
    $schedulePage.Header = '📅 Schedule Task'
    $schedulePage.Content = $schedScrollView

    $exportDiagInnerPanel.Margin = '28,20,28,24'
    $diagScrollView = [ScrollViewer]::new()
    $diagScrollView.Content = $exportDiagInnerPanel
    $diagramsPage = [ContentPage]::new()
    $diagramsPage.Header = '🖼 Export Diagrams'
    $diagramsPage.Content = $diagScrollView

    $navigationPage = [NavigationPage]::new()
    $navigationPage.Content = $reportPage

    # MDI path geometry for nav icons
    $reportGeometry = 'M6,2A2,2 0 0,0 4,4V20A2,2 0 0,0 6,22H18A2,2 0 0,0 20,20V8L14,2H6M6,4H13V9H18V20H6V4M8,12V14H16V12H8M8,16V18H13V16H8Z'
    $schedGeometry = 'M19,3H18V1H16V3H8V1H6V3H5C3.89,3 3,3.89 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19V5C21,3.89 20.1,3 19,3M19,19H5V8H19V19Z'
    $diagGeometry = 'M8.5,13.5L11,16.5L14.5,12L19,18H5M21,19V5C21,3.89 20.1,3 19,3H5A2,2 0 0,0 3,5V19A2,2 0 0,0 5,21H19A2,2 0 0,0 21,19Z'

    $btnNavReport = New-DrawerMenuItem -Title 'Report' -IconGeometry $reportGeometry -Page $reportPage -NavigationPage $navigationPage
    $btnNavSchedule = New-DrawerMenuItem -Title 'Schedule' -IconGeometry $schedGeometry -Page $schedulePage -NavigationPage $navigationPage
    $btnNavDiagrams = New-DrawerMenuItem -Title 'Export Diagrams' -IconGeometry $diagGeometry -Page $diagramsPage -NavigationPage $navigationPage

    $drawerMenuPanel = [StackPanel]::new()
    $drawerMenuPanel.Margin = 12
    $drawerMenuPanel.Children.Add($btnNavReport)
    $drawerMenuPanel.Children.Add($btnNavSchedule)
    $drawerMenuPanel.Children.Add($btnNavDiagrams)

    $drawerMenu = [ContentPage]::new()
    $drawerMenu.Content = $drawerMenuPanel

    $drawerHeader = [TextBlock]::new()
    $drawerHeader.Text = 'Navigation'
    $drawerHeader.FontSize = 16
    $drawerHeader.FontWeight = 'SemiBold'
    $drawerHeader.VerticalAlignment = 'Center'
    $drawerHeader.Padding = '16,10,12,10'

    $drawerPage = [DrawerPage]::new()
    $drawerPage.DrawerHeader = $drawerHeader
    $drawerPage.Drawer = $drawerMenu
    $drawerPage.Content = $navigationPage

    # ── Shared bottom strip (log + status — visible from all drawer pages) ────────
    $sharedBottomPanel = [StackPanel]::new()
    $sharedBottomPanel.Margin = '28,4,28,16'
    $sharedBottomPanel.Children.Add($progressBar)
    $sharedBottomPanel.Children.Add($logHeaderGrid)
    $sharedBottomPanel.Children.Add($txtLog)
    $sharedBottomPanel.Children.Add($logActionsRow)
    $sharedBottomPanel.Children.Add($lblConfigStatus)

    # ── Outer grid: drawer (fills space) above shared log strip ──────────────────
    $outerGrid = [Grid]::new()
    $outerGrid.RowDefinitions.Add([RowDefinition]::new([GridLength]::new(1, [GridUnitType]::Star)))
    $outerGrid.RowDefinitions.Add([RowDefinition]::new([GridLength]::new(0, [GridUnitType]::Auto)))
    [Grid]::SetRow($drawerPage, 0)
    [Grid]::SetRow($sharedBottomPanel, 1)
    $outerGrid.Children.Add($drawerPage)
    $outerGrid.Children.Add($sharedBottomPanel)

    # ── Window ──────────────────────────────────────────────────────────────────
    $win = [Window]::new()
    $win.Title = 'Veeam VBR — As-Built Report Generator'
    $win.Width = 1050
    $win.Height = 920
    $win.MinWidth = 880
    $win.MinHeight = 500
    $win.Content = $outerGrid

    $win.Show()
    $win.WaitForClosed()
}