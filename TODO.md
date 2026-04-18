- [ ] Add Job RansomwareOptions
- [ ] Nutanix Backup Jobs
  - [ ] Fix
    - [x] Backup Proxy	(Unknown)
    - [ ] Validate Data Transfer (Wan Accelerators)
    - [x] Backup Repository	(Snap mode)
- [ ] Fix Immutability Supported column in Repositories table
- [ ] Fix Storage-Level Corruption Guard (SLCG)

- [x] Add Schedule option to the GUI
  - [x] https://community.veeam.com/blogs-and-podcasts-57/documentation-by-asbuiltreport-9990?tid=9990&fid=57
- [ ] Add High Availability Cluster to the Backup Server Diagram object
- [x] Add High Availability Cluster to the Backup Server section in report
- [x] Fix AsBuiltReport Global Config New form
  - [x] Add * to required fields
  - [x] Add validation to required fields
- [x] Make AsBuiltReport Global Config Save button to error if no Config file path is provided
- [x] Add Verbose logging to AsBuiltReport Gui (besides the Export Log button)
- [x] Add Save capability to the server connection form in the GUI. Add a drop down to select from saved connections. Dont save passwords, just server, port and username. When a connection is selected, populate the server and username fields in the form, but still require the user to enter the password for security reasons.

Set-Location C:\Users\jocolon\

$password = ConvertTo-SecureString "P@ssw0rd@26@26@@" -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential ("veeamadmin", $password)

Connect-VBRServer -Server veeam-vbr-00a.pharmax.local -Credential $cred

Import-Module AsBuiltReport.Veeam.VBR -Force

New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr-00a.pharmax.local -AsBuiltConfigFilePath $env:HOME\script\AsBuiltReport.json -OutputFolderPath $env:HOME -Credential $cred -Format HTML -ReportConfigFilePath $env:HOME\script\AsBuiltReport.Veeam.VBR.json -EnableHealthCheck



Set-Location C:\Users\jocolon\

$password = ConvertTo-SecureString "p@ssw0rd" -AsPlainText -Force

$Cred = New-Object System.Management.Automation.PSCredential ("pharmax\administrator", $password)

Connect-VBRServer -Server veeam-vbr-01v.pharmax.local -Credential $cred

Import-Module AsBuiltReport.Veeam.VBR -Force

New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr-01v.pharmax.local -AsBuiltConfigFilePath C:\Users\jocolon\AsBuiltReport\AsBuiltReport.json -OutputFolderPath C:\Users\jocolon\AsBuiltReport\ -Credential $cred -Format Word -ReportConfigFilePath C:\Users\jocolon\AsBuiltReport\AsBuiltReport.Veeam.VBR.json -EnableHealthCheck
