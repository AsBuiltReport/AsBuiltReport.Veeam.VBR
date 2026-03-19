# Copilot Instructions for AsBuiltReport.Veeam.VBR

## Project Overview

This module generates as-built documentation reports (HTML, Word, Text) for Veeam Backup & Replication (VBR) infrastructure. It plugs into the [AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport.Core) framework via `Invoke-AsBuiltReport.Veeam.VBR`, which is the sole public entry point.

**Runtime constraint:** Windows PowerShell 5.1 **only** — PS7/PowerShell Core is not supported. VBR v12+ (Windows/Appliance installs). VBR v13 is explicitly unsupported due to .NET Core changes.

## Lint Command

PSScriptAnalyzer runs automatically on push/PR via `.github/workflows/PSScriptAnalyzer.yml`. To run it locally:

```powershell
Invoke-ScriptAnalyzer -Path .\Src -Recurse -Settings .\.github\workflows\PSScriptAnalyzerSettings.psd1
```

There are no Pester tests and no build script.

## Architecture

```
Invoke-AsBuiltReport.Veeam.VBR.ps1   ← single public function; orchestrates entire report
Src/Private/Report/Get-AbrVbr*.ps1   ← 91 report section functions (one per VBR feature area)
Src/Private/Diagram/Get-Abr*.ps1     ← 56 diagram helper functions
AsBuiltReport.Veeam.VBR.psm1         ← dot-sources all Src/**/*.ps1; exports Public + Diagram + Report
AsBuiltReport.Veeam.VBR.json         ← user-facing config: InfoLevel, HealthCheck, Options schemas
```

The framework calls `Invoke-AsBuiltReport.Veeam.VBR` with `$Target`, `$Credential`, and a parsed `$ReportConfig`. The function imports config into three `$script:` variables (`$script:InfoLevel`, `$script:HealthCheck`, `$script:Options`) and then calls each `Get-AbrVbr*` function in sequence, wrapped in `Section` blocks from PScribo.

## Key Conventions

### Function & Variable Naming

- Report section functions: `Get-AbrVbr<FeatureName>` (e.g., `Get-AbrVbrBackupRepository`)
- Diagram functions: `Get-Abr<DiagramType>` (e.g., `Get-AbrVbrDiagramBackupProxy`)
- Output collection: `$OutObj` (array), individual item: `$inObj` (ordered hashtable)
- Script-scope config: `$script:InfoLevel`, `$script:HealthCheck`, `$script:Options`, `$script:TextInfo`

### Standard Report Section Structure

Every `Get-AbrVbr*` function follows this skeleton:

```powershell
function Get-AbrVbr<Name> {
    [CmdletBinding()]
    param()

    begin {
        Write-PScriboMessage "Discovering Veeam VBR <Name>."
        Show-AbrDebugExecutionTime -Start -TitleMessage '<Name>'
    }

    process {
        try {
            [Array]$Data = Get-VBR<ObjectType> | Sort-Object -Property Name
            if ($Data) {
                $OutObj = @()
                foreach ($Item in $Data) {
                    try {
                        $inObj = [ordered] @{
                            'Name'   = $Item.Name
                            'Status' = $Item.Status
                            # ...
                        }
                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                    } catch {
                        Write-PScriboMessage -IsWarning "<Name>: $($_.Exception.Message)"
                    }
                }

                if ($HealthCheck.<Category>.<Section>) {
                    # Apply Set-Style -Style Warning/Critical/OK to $OutObj rows
                }

                Section -Style Heading3 '<Title>' {
                    $OutObj | Table -Name '<Title>'
                }

                if ($InfoLevel.<Category>.<Section> -ge 2) {
                    # Detailed per-item sub-sections
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "<Name> Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage '<Name>'
    }
}
```

### InfoLevel Gates

InfoLevel values (0–3) come from `$script:InfoLevel.<Category>.<Section>`:

- `0` — section disabled entirely
- `1` — summary table
- `2` — advanced summary (additional columns or sub-tables)
- `3` — full detail (per-item sections, hardware inventory, etc.)

Gate detailed content with:
```powershell
if ($InfoLevel.Infrastructure.BR -ge 2) { ... }
```

### Health Check Highlighting

Health checks are boolean flags from `$script:HealthCheck.<Category>.<Section>`. When enabled, apply PScribo styles to `$OutObj` rows before passing to `Table`:

```powershell
if ($HealthCheck.Infrastructure.BR) {
    $OutObj | Where-Object { $_.'Status' -ne 'OK' } | Set-Style -Style Warning -Property 'Status'
}
```

Available styles: `OK`, `Warning`, `Critical`, `Info`.

### Boolean Display

Always wrap the final `$inObj` hashtable with `ConvertTo-HashToYN` to convert `$true`/`$false` to `"Yes"`/`"No"`:

```powershell
$OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
```

### Veeam API Usage

- Primary: `Veeam.Backup.PowerShell` cmdlets (`Get-VBRJob`, `Get-VBRBackupRepository`, etc.) — must be loaded on the VBR server
- Low-level: Direct assembly calls for objects not exposed via cmdlets, e.g. `[Veeam.Backup.Core.CBackupJob]::GetAll()` for Nutanix jobs
- Remote system info: `New-CimSession` + `Get-CimInstance` (Win32_ComputerSystem, Win32_OperatingSystem, Win32_Processor)
- Credentials/connectivity handled by `New-VBRConnection.ps1` and `Get-AbrVbrServerConnection.ps1`

### PScribo Document Building

Use PScribo primitives inside `Section` blocks:
- `Table` — structured data output
- `Paragraph` — free text
- `BlankLine` — spacing
- `Image` — diagrams/charts
- `Section -Style Heading2/Heading3/Heading4` — nested sections

Charts are generated via `AsBuiltReport.Chart` (`New-BarChart`, `New-StackedBarChart`) and diagrams via `AsBuiltReport.Diagram` + custom `New-AbrVeeamDiagram`.

## Diagram Conventions

### Library & Rendering Stack

Diagrams use **PSGraph** (PowerShell wrapper for Graphviz). The rendering pipeline is:

```
Invoke-AsBuiltReport.Veeam.VBR.ps1
  → Get-AbrVbrDiagrammer.ps1          (wrapper; resolves options → params)
    → New-AbrVeeamDiagram.ps1          (orchestrator; builds Graph block, calls diagram functions)
      → Get-AbrDiag*.ps1              (emit Node/Edge/SubGraph primitives inline)
      → Export-AbrDiagram.ps1         (Graphviz render → PNG/SVG/PDF/Base64)
```

### File Naming & Location

All diagram code lives in `Src/Private/Diagram/`. Three sub-categories of files exist:

| Prefix | Role | Example |
|---|---|---|
| `Get-AbrDiag*.ps1` | Emit nodes/edges for one diagram type | `Get-AbrDiagBackupToRepo.ps1` |
| `Get-Abr*Info.ps1` | Collect Veeam data for diagrams | `Get-AbrBackupRepoInfo.ps1` |
| Everything else | Helpers / orchestration | `New-AbrVeeamDiagram.ps1`, `Images.ps1` |

Diagram data-collection functions (`Get-Abr*Info.ps1`) are **separate** from report data functions. Do not reuse report `Get-AbrVbr*` functions inside diagram code.

### Graph Primitives

PSGraph maps directly to Graphviz DOT. The four primitives used throughout:

```powershell
# Root container — called once in New-AbrVeeamDiagram.ps1
Graph -Name VeeamVBR -Attributes $MainGraphAttributes {

    Node @{ shape = 'none'; style = 'filled'; fillColor = 'transparent'; fontsize = 14 }  # defaults
    Edge @{ style = 'dashed'; dir = 'both'; arrowtail = 'dot'; penwidth = 1.5 }           # defaults

    SubGraph MainGraph -Attributes @{ Label = ...; labelloc = 't' } {
        Get-AbrDiagBackupServer        # emits Node definitions inline
        Get-AbrDiagBackupToRepo        # emits Node + Edge definitions inline
    }
}
```

`Get-AbrDiag*` functions output PSGraph primitives **directly to the pipeline** — they do not return values. They are called inside a `Graph { }` or `SubGraph { }` block.

### Node Labels: `Add-HtmlNodeTable` and `Add-HtmlSubGraph`

Nodes use `shape = 'plain'` with an HTML table as their label. Two helper functions build these labels:

```powershell
# Single group of items with icons
$label = Add-HtmlNodeTable `
    -Name       'WanAccelNodes' `
    -inputObject ($WanAccels | ForEach-Object { $_.Name.Split('.')[0] }) `
    -iconType   'VBR_Wan_Accel' `
    -ColumnSize $ColumnSize `
    -Subgraph                           # wrap in a rounded border
    -SubgraphLabel 'WAN Accelerators' `
    -SubgraphIconType 'VBR_Wan_Accel'

Node WanAccelServer @{ Label = $label; shape = 'plain' }

# Nest multiple node tables into one container
$combined = Add-HtmlSubGraph `
    -Name       'ReposSubGraph' `
    -TableArray @($localTable, $dedupTable, $cloudTable) `
    -Label      'Backup Repositories' `
    -TableStyle 'dashed,rounded'

Node MainSubGraph @{ Label = $combined; shape = 'plain' }
```

Always strip FQDNs to short names for readability: `$_.Name.Split('.')[0]`.

### Edges

```powershell
Edge BackupServers -To HvProxies @{ minlen = 3 }
```

`minlen` controls minimum edge length (spacing). Use `3` as the standard value between major node groups.

### Icon Resolution

Icon names are resolved through `Get-AbrIconType` (maps Veeam object type strings → icon keys) and the `Images.ps1` dictionary (maps icon keys → PNG filenames). When adding a new node type, check both files for the correct key rather than guessing the icon name.

### Diagram Types

There are 11 named diagram types (the `ValidateSet` in `New-AbrVeeamDiagram`):

```
Backup-Infrastructure          # always generated when EnableDiagrams = true
Backup-to-Repository
Backup-to-Sobr
Backup-to-vSphere-Proxy
Backup-to-HyperV-Proxy
Backup-to-File-Proxy
Backup-to-WanAccelerator       # only if WAN accelerators exist
Backup-to-Tape                 # only if tape servers + libraries exist
Backup-to-ProtectedGroup
Backup-to-CloudConnect
Backup-to-CloudConnect-Tenant
```

Each type maps to a specific `Get-AbrDiag*.ps1` function (or set of functions) called inside `New-AbrVeeamDiagram`.

### Themes

Three themes (`$Options.DiagramTheme`): `White` (default), `Black`, `Neon`. Theme controls `$NodeFontcolor`, `$Edgecolor`, `$EdgeLineWidth`, and subgraph fill colors. All theme variables are set in `New-AbrVeeamDiagram.ps1` before the `Graph { }` block.

### Embedding Diagrams in the Report

Diagrams are rendered to **Base64** and embedded inline with PScribo's `Image` primitive:

```powershell
$Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-Infrastructure' -DiagramOutput base64

Section -Style Heading2 'Backup Infrastructure Diagram' {
    Image -Base64 $Graph -Text 'Backup Infrastructure Diagram' -Align Center `
          -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height
}
```

`$BestAspectRatio` is computed from report output dimensions to maintain proportions. When `$Options.ExportDiagrams` is set, diagrams are also written to disk in `$Options.ExportDiagramsFormat` (png/svg/pdf).

### Adding a New Diagram Type

1. Add a `Get-Abr*Info.ps1` data-collection function if new Veeam data is needed.
2. Create `Get-AbrDiagBackupTo<Type>.ps1` — emit `Node`/`Edge`/`SubGraph` primitives inside the function body (no `return`).
3. Add the new type string to the `ValidateSet` in `New-AbrVeeamDiagram.ps1` and add a matching `if` branch that calls your function inside the `Graph { }` block.
4. Add conditional invocation in `Invoke-AsBuiltReport.Veeam.VBR.ps1` (guarded by relevant `$Options.EnableDiagrams` and data-existence checks).

## Adding a New Report Section

1. Create `Src/Private/Report/Get-AbrVbr<Name>.ps1` following the skeleton above.
2. Add the call in `Invoke-AsBuiltReport.Veeam.VBR.ps1` inside the appropriate `Section` block, gated by the relevant `$InfoLevel` check.
3. Add corresponding `InfoLevel` and `HealthCheck` keys to `AsBuiltReport.Veeam.VBR.json` if introducing a new category.
4. The `.psm1` auto-discovers and dot-sources all files under `Src/` — no manifest changes needed.

## PR & Branch Workflow

- Target PRs against the `dev` branch (not `main`)
- Rebase onto `upstream/dev` before opening a PR
- PSScriptAnalyzer must pass (enforced by CI)
- Follow existing indentation and style — no style-only reformatting PRs
