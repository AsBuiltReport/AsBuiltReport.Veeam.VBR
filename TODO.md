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



Set-Location C:\Users\jocolon\

$password = ConvertTo-SecureString "P@ssw0rd@26@26@" -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential ("veeamadmin", $password)

Connect-VBRServer -Server veeam-vbr13-01v.pharmax.local -Credential $cred

Import-Module AsBuiltReport.Veeam.VBR -Force

New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr13-01v.pharmax.local -AsBuiltConfigFilePath C:\Users\jocolon\AsBuiltReport\AsBuiltReport.json -OutputFolderPath C:\Users\jocolon\AsBuiltReport\ -Credential $cred -Format HTML -ReportConfigFilePath C:\Users\jocolon\AsBuiltReport\AsBuiltReport.Veeam.VBR.json -EnableHealthCheck



Set-Location C:\Users\jocolon\

$password = ConvertTo-SecureString "p@ssw0rd" -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential ("pharmax\administrator", $password)

Connect-VBRServer -Server veeam-vbr-01v.pharmax.local -Credential $cred

Import-Module AsBuiltReport.Veeam.VBR -Force

New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr-01v.pharmax.local -AsBuiltConfigFilePath C:\Users\jocolon\AsBuiltReport\AsBuiltReport.json -OutputFolderPath C:\Users\jocolon\AsBuiltReport\ -Credential $cred -Format Word -ReportConfigFilePath C:\Users\jocolon\AsBuiltReport\AsBuiltReport.Veeam.VBR.json -EnableHealthCheck
