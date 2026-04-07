# VBR As-Built Report — GUI Launcher

A desktop GUI for **AsBuiltReport.Veeam.VBR** built with [GliderUI](https://github.com/mdgrs-mei/GliderUI) (Avalonia).  
Runs entirely in **PowerShell 7** — no child PS5.1 process required.

## Requirements

| Requirement | How to install |
|---|---|
| PowerShell 7.4+ | [github.com/PowerShell/PowerShell](https://github.com/PowerShell/PowerShell/releases) |
| GliderUI | `Install-PSResource -Name GliderUI` *(auto-installed on first run)* |
| AsBuiltReport.Core | `Install-PSResource -Name AsBuiltReport.Core` |
| AsBuiltReport.Veeam.VBR | `Install-PSResource -Name AsBuiltReport.Veeam.VBR` |
| Veeam B&R console | Must be installed on the machine running the report |

## Usage

```powershell
# Open any PowerShell 7 terminal, then:
pwsh .\GUI\Start-AsBuiltReportVBR.ps1
```

GliderUI is auto-installed on first run if not already present.

## GUI Fields

### 🔌 Server Connection
| Field | Description |
|---|---|
| VBR Server | Hostname or IP of the Veeam Backup & Replication server |
| Port | API port (default `9392`) |
| Username | `DOMAIN\username` or local `username` |
| Password | Account password (masked) |

### 📄 Report Output
| Field | Description |
|---|---|
| Report Name | Output filename (without extension) |
| Format | HTML, Word, Text — select one or more |
| Output Folder | Destination folder (Browse button or type path) |
| Report Style | `Veeam` (green+gray branding) or `Default` (AsBuiltReport theme) |
| Language | `en-US` or `es-ES` |

### ⚙️ Options
| Field | Description |
|---|---|
| Enable Diagrams | Generate infrastructure topology diagrams |
| Export Diagrams | Export diagrams as PDF files |
| Hardware Inventory | Include hardware inventory (slower) |
| Use New Icons | Use updated Veeam icon set |
| Enable Health Check | Append health check findings |
| Add Timestamp | Append timestamp to output filename |
| Diagram Theme | `White`, `Black`, or `Neon` diagram background |
| Diagram Columns | Number of diagram node columns (1–10) |

### 📊 Info Level
Per-section verbosity control: `0 - Off`, `1 - Enabled`, `2 - Adv Summary`, `3 - Detailed`.  
Covers: Backup Server, Proxy, Repository, Backup Jobs, Replication, Tape, Cloud Connect.

## How It Works

1. Fill in the fields and click **▶ Generate Report**
2. The GUI writes a temporary JSON config to `%TEMP%`
3. `New-AsBuiltReport` is called directly in a PS7 background runspace — no subprocess needed
4. Output streams line-by-line into the **Output Log** area
5. Click **✕ Cancel** at any time to abort
6. The temp config file is deleted after the run completes
