<p align="center">
    <a href="https://www.asbuiltreport.com/" alt="AsBuiltReport"></a>
            <img src='https://avatars.githubusercontent.com/u/42958564' width="8%" height="8%" /></a>
</p>
<p align="center">
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Veeam.VBR/" alt="PowerShell Gallery Version">
        <img src="https://img.shields.io/powershellgallery/v/AsBuiltReport.Veeam.VBR.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Veeam.VBR/" alt="PS Gallery Downloads">
        <img src="https://img.shields.io/powershellgallery/dt/AsBuiltReport.Veeam.VBR.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.Veeam.VBR/" alt="PS Platform">
        <img src="https://img.shields.io/powershellgallery/p/AsBuiltReport.Veeam.VBR.svg" /></a>
</p>
<p align="center">
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/graphs/commit-activity" alt="GitHub Last Commit">
        <img src="https://img.shields.io/github/last-commit/AsBuiltReport/AsBuiltReport.Veeam.VBR/master.svg" /></a>
    <a href="https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/master/LICENSE" alt="GitHub License">
        <img src="https://img.shields.io/github/license/AsBuiltReport/AsBuiltReport.Veeam.VBR.svg" /></a>
    <a href="https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/graphs/contributors" alt="GitHub Contributors">
        <img src="https://img.shields.io/github/contributors/AsBuiltReport/AsBuiltReport.Veeam.VBR.svg"/></a>
</p>
<p align="center">
    <a href="https://twitter.com/AsBuiltReport" alt="Twitter">
            <img src="https://img.shields.io/twitter/follow/AsBuiltReport.svg?style=social"/></a>
</p>

> [!WARNING]
> I have recently been contacted to ask about the status of this project. Maintaining this report and all the tools that make this project work is time and resource consuming. If you want to keep this project alive, support its development by donating through ko-fi.

<p align="center">
    <a href='https://ko-fi.com/F1F8DEV80' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://ko-fi.com/img/githubbutton_sm.svg' border='0' alt='Want to keep alive this project? Support me on Ko-fi' /></a>
</p>

#### Community Maintained Project

This project is maintained by the community and is not sponsored by Veeam, its employees, or any affiliates.

# Veeam VBR As Built Report

Veeam VBR As Built Report is a PowerShell module that works in conjunction with [AsBuiltReport.Core](https://github.com/AsBuiltReport/AsBuiltReport.Core).

[AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport) is an open-source community project that utilizes PowerShell to produce as-built documentation in multiple formats for various vendors and technologies.

For more detailed information about this project, please visit the AsBuiltReport [website](https://www.asbuiltreport.com).

# :books: Sample Reports

## Sample Report - Veeam Style with EnableHealthCheck

Sample Veeam VBR As Built Report HTML file: [Sample Report](https://htmlpreview.github.io/?https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/dev/Samples/Sample%20Veeam%20Backup%20%26%20Replication%20As%20Built%20Report.html)

## Sample Diagram

Sample Veeam VBR As Built Report Diagram file: [Sample Diagram](Samples/AsBuiltReport.Veeam.VBR.png)

![Sample Diagram](Samples/AsBuiltReport.Veeam.VBR.png)

# :beginner: Getting Started

Below are the instructions on how to install, configure, and generate a Veeam VBR As Built report.

## :floppy_disk: Supported Versions

The Veeam VBR As Built Report supports the following Veeam Backup & Replication versions:

- Veeam Backup & Replication v11+ (Standard, Enterprise & Enterprise Plus Edition)
- Veeam Backup & Replication v12+ (Standard, Enterprise & Enterprise Plus Edition)

:exclamation: Community Edition is not supported :exclamation:

## :no_entry_sign: Unsupported Versions

- Veeam versions 10 and earlier are no longer supported. Compatibility with these versions is not guaranteed, and any issues related to versions prior to v11 will not be addressed.
- Veeam version 13 and later are not supported.

[Veeam Product Lifecycle Policy](https://www.veeam.com/product-lifecycle.html)

### PowerShell

This report is compatible with the following PowerShell versions:

| Windows PowerShell 5.1 | PowerShell 7 |
| :--------------------: | :----------: |
|   :white_check_mark:   |     :x:      |

## :wrench: System Requirements

PowerShell 5.1 and the following PowerShell modules are required to generate a Veeam VBR As Built report:

- [AsBuiltReport.Core Module](https://github.com/AsBuiltReport/AsBuiltReport.Core)
- [Diagrammer.Core Module](https://github.com/rebelinux/Diagrammer.Core)
- [PScribo Module](https://github.com/iainbrighton/PScribo)
- [PScriboCharts Module](https://github.com/iainbrighton/PScriboCharts)
- [PSGraph Module](https://github.com/KevinMarquette/PSGraph)
- [Veeam.Backup.PowerShell Module](https://helpcenter.veeam.com/docs/backup/powershell/getting_started.html?ver=110)
- [Veeam.Diagrammer Module](https://github.com/rebelinux/Veeam.Diagrammer)

### :closed_lock_with_key: Required Privileges

Only users with the Veeam Backup Administrator role can generate a Veeam VBR As Built Report.

## :package: Module Installation

### PowerShell

```powershell
Install-Module -Name AsBuiltReport.Veeam.VBR
```

### GitHub

If you cannot use the PowerShell Gallery, you can install the module manually. Ensure you repeat the following steps for the [system requirements](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR#wrench-system-requirements) as well.

1. Download the code package / [latest release](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/releases/latest) zip from GitHub.
2. Extract the zip file.
3. Copy the folder `AsBuiltReport.Veeam.VBR` to a path set in `$env:PSModulePath`.
4. Open a PowerShell terminal window and unblock the downloaded files with:

    ```powershell
    $path = (Get-Module -Name AsBuiltReport.Veeam.VBR -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Src\Public\*.ps1; Unblock-File -Path $path\Src\Private\*.ps1
    ```

5. Close and reopen the PowerShell terminal window.

_Note: You can install the module to other paths by adding a new entry to the environment variable PSModulePath._

## :pencil2: Configuration

The Veeam VBR As Built Report uses a JSON file to configure report information, options, detail, and health checks.

A Veeam VBR report configuration file can be generated by executing the following command:

```powershell
New-AsBuiltReportConfig -Report Veeam.VBR -FolderPath <User specified folder> -Filename <Optional>
```

Executing this command will copy the default Veeam VBR report JSON configuration to a user-specified folder.

All report settings can then be configured via the JSON file.

The following provides information on how to configure each schema within the report's JSON file.

### Report

The **Report** schema provides configuration of the Veeam VBR report information.

| Sub-Schema          | Setting      | Default                   | Description                                                  |
| ------------------- | ------------ | ------------------------- | ------------------------------------------------------------ |
| Name                | User defined | Veeam VBR As Built Report | The name of the As Built Report                              |
| Version             | User defined | 1.0                       | The report version                                           |
| Status              | User defined | Released                  | The report release status                                    |
| ShowCoverPageImage  | true / false | true                      | Toggle to enable/disable the display of the cover page image |
| ShowTableOfContents | true / false | true                      | Toggle to enable/disable table of contents                   |
| ShowHeaderFooter    | true / false | true                      | Toggle to enable/disable document headers & footers          |
| ShowTableCaptions   | true / false | true                      | Toggle to enable/disable table captions/numbering            |

### Options

The **Options** schema allows certain options within the report to be toggled on or off.

| Sub-Schema              | Setting                    | Default | Description                                                                   |
| Sub-Schema              | Setting                    | Default | Description                                                                   |
| ----------------------- | -------------------------- | ------- | ----------------------------------------------------------------------------- |
| BackupServerPort        | TCP Port                   | 9392    | Set the backup server service's custom port.                                  |
| DiagramTheme            | string                     | White   | Set the diagram theme (Black/White/Neon)                                      |
| DiagramWaterMark        | string                     | empty   | Set the diagram watermark                                                     |
| EnableDiagrams          | true / false               | false   | Toggle to enable/disable infrastructure diagrams                              |
| EnableDiagramsDebug     | true / false               | false   | Toggle to enable/disable diagram debug option                                 |
| EnableDiagramSignature  | true / false               | false   | Toggle to enable/disable diagram signature (bottom right corner)              |
| EnableHardwareInventory | true / false               | false   | Toggle to enable/disable hardware information                                 |
| ExportDiagrams          | true / false               | true    | Toggle to enable/disable diagram export option                                |
| ExportDiagramsFormat    | string array               | png     | Set the format used to export the infrastructure diagram (dot, png, pdf, svg) |
| PSDefaultAuthentication | Default/Kerberos/Negotiate | Default | Set the PSRemoting authentication method                                      |
| ReportStyle             | Veeam/AsBuiltReport        | Veeam   | Set the report style template                                                 |
| RoundUnits              | int                        | 1       | Set the value to round the storage unit                                       |
| SignatureAuthorName     | string                     | empty   | Set the signature author name                                                 |
| SignatureCompanyName    | string                     | empty   | Set the signature company name                                                |

### InfoLevel

The **InfoLevel** schema allows configuration of each section of the report at a granular level. The following sections can be set.

There are 4 levels (0-3) of detail granularity for each section as follows:

| Setting | InfoLevel   | Description                                                          |
| :-----: | ----------- | -------------------------------------------------------------------- |
|    0    | Disabled    | Does not collect or display any information                          |
|    1    | Enabled     | Provides summarized information for a collection of objects          |
|    2    | Adv Summary | Provides condensed, detailed information for a collection of objects |
|    3    | Detailed    | Provides detailed information for individual objects                 |

The table below outlines the default and maximum **InfoLevel** settings for each Backup Infrastructure section.

| Sub-Schema      | Default Setting | Maximum Setting |
| --------------- | :-------------: | :-------------: |
| BackupServer    |        1        |        3        |
| BR              |        1        |        2        |
| Licenses        |        1        |        1        |
| Proxy           |        1        |        3        |
| ServiceProvider |        1        |        2        |
| Settings        |        1        |        2        |
| SOBR            |        1        |        2        |
| SureBackup      |        1        |        2        |
| WANAccel        |        1        |        1        |

The table below outlines the default and maximum **InfoLevel** settings for each Tape Infrastructure section.

| Sub-Schema | Default Setting | Maximum Setting |
| --------------- | :-------------: | :-------------: |
| Library    |        1        |        2        |
| MediaPool  |        1        |        2        |
| NDMP       |        1        |        1        |
| Server     |        1        |        1        |
| Vault      |        1        |        1        |

The table below outlines the default and maximum **InfoLevel** settings for each Inventory section.

| Sub-Schema | Default Setting | Maximum Setting |
| --------------- | :-------------: | :-------------: |
| EntraID    |        1        |        1        |
| FileShare  |        1        |        1        |
| PHY        |        1        |        2        |
| VI         |        1        |        1        |

The table below outlines the default and maximum **InfoLevel** settings for each Storage Infrastructure section.

| Sub-Schema | Default Setting | Maximum Setting |
| ---------- | :-------------: | :-------------: |
| ISILON     |        1        |        2        |
| ONTAP      |        1        |        2        |

The table below outlines the default and maximum **InfoLevel** settings for each Backup Jobs section.

| Sub-Schema  | Default Setting | Maximum Setting |
| ----------- | :-------------: | :-------------: |
| Agent       |        1        |        2        |
| Backup      |        1        |        2        |
| BackupCopy  |        1        |        2        |
| EntraID     |        1        |        2        |
| FileShare   |        1        |        2        |
| Replication |        1        |        2        |
| Restores    |        0        |        1        |
| Surebackup  |        1        |        2        |
| Tape        |        1        |        2        |

The table below outlines the default and maximum **InfoLevel** settings for each Replication section.

| Sub-Schema   | Default Setting | Maximum Setting |
| ------------ | :-------------: | :-------------: |
| FailoverPlan |        1        |        1        |
| Replica      |        1        |        2        |

The table below outlines the default and maximum **InfoLevel** settings for each Cloud Connect section.

| Sub-Schema       | Default Setting | Maximum Setting |
| --------------- | :-------------: | :-------------: |
| BackupStorage    |        1        |        1        |
| Certificate      |        1        |        1        |
| CloudGateway     |        1        |        2        |
| GatewayPools     |        1        |        1        |
| PublicIP         |        1        |        1        |
| ReplicaResources |        1        |        2        |
| Tenants          |        1        |        2        |

### Healthcheck

The **Healthcheck** schema is used to toggle health checks on or off.

## :computer: Examples

Below are a few examples of running the AsBuiltReport script against a Veeam Backup Server. Refer to the `README.md` file in the main AsBuiltReport project repository for more examples.

```powershell
# Generate a Veeam VBR As Built Report for Backup Server 'veeam-vbr.pharmax.local' using specified credentials. Export report to HTML & DOCX formats. Use default report style. Append timestamp to report filename. Save reports to 'C:\Users\Jon\Documents'
PS C:\> New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr.pharmax.local -Username 'Domain\veeam_admin' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -Timestamp

# Generate a Veeam VBR As Built Report for Backup Server veeam-vbr.pharmax.local using specified credentials and report configuration file. Export report to Text, HTML & DOCX formats. Use default report style. Save reports to 'C:\Users\Jon\Documents'. Display verbose messages to the console.
PS C:\> New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr.pharmax.local -Username 'Domain\veeam_admin' -Password 'P@ssw0rd' -Format Text,Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -ReportConfigFilePath 'C:\Users\Jon\AsBuiltReport\AsBuiltReport.Veeam.VBR.json' -Verbose

# Generate a Veeam VBR As Built Report for Backup Server veeam-vbr.pharmax.local using stored credentials. Export report to HTML & Text formats. Use default report style. Highlight environment issues within the report. Save reports to 'C:\Users\Jon\Documents'.
PS C:\> $Creds = Get-Credential
PS C:\> New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr.pharmax.local -Credential $Creds -Format Html,Text -OutputFolderPath 'C:\Users\Jon\Documents' -EnableHealthCheck

# Generate a Veeam VBR As Built Report for Backup Server veeam-vbr.pharmax.local using stored credentials. Export report to HTML & DOCX formats. Use default report style. Reports are saved to the user profile folder by default. Attach and send reports via e-mail.
PS C:\> New-AsBuiltReport -Report Veeam.VBR -Target veeam-vbr.pharmax.local -Username 'Domain\veeam_admin' -Password 'P@ssw0rd' -Format Html,Word -OutputFolderPath 'C:\Users\Jon\Documents' -SendEmail
```

## :x: Known Issues

- Many of Veeam's features depend on the Standard+ license, so the Community edition is not supported.
- If the Veeam Backup Server is not joined to an Active Directory domain (WorkGroup Auth), the PSDefaultAuthentication option must be set to Negotiate. Otherwise, some report sections will be missing.
- This project uses the PScribo module to generate the report. It has been detected that the EvotecIT PSWriteWord module uses the same cmdlet names. To generate the report correctly, it is required to uninstall the PSWriteWord module.
