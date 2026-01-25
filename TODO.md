- [ ] Improve Paragraph section
- [ ] Add Job RansomwareOptions
- [x] Fix Tenant diagram size mismatch
- [x] Add per tenant diagram to the Tenant Configuration section
  - [x] Fix Diagram Export
- [ ] Nutanix Backup Jobs
  - [ ] Fix
    - [x] Backup Proxy	(Unknown)
    - [ ] Validate Data Transfer (Wan Accelerators)
    - [x] Backup Repository	(Snap mode)
- [x] Fix Security & Compliance Best Practices section
- [ ] Fix Immutability Supported column in Repositories table
- [ ] Fix Storage-Level Corruption Guard (SLCG)
- [x] Integrate Veeam.Diagrammer diagrams to the main report

```powershell
Set-Location /home/rebelinux/

$password = ConvertTo-SecureString "p@ssw0rd" -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential ("administrator@pharmax.local", $password)

Connect-VBRServer -Server veeam-vbr-01v.pharmax.local -Credential $Cred

Import-Module PScribo -Force
Import-Module AsBuiltReport.Veeam.VBR -Force
Import-Module Diagrammer.Core -Force

New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr-01v.pharmax.local -AsBuiltConfigFilePath /home/rebelinux/script/AsBuiltReport.json -OutputFolderPath /home/rebelinux/script/ -Credential $Cred -Format HTML -ReportConfigFilePath /home/rebelinux/script/AsBuiltReport.Veeam.VBR.json -EnableHealthCheck
```
