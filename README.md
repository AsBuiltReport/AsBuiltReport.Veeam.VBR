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
<p align="center">
    <a href='https://ko-fi.com/F1F8DEV80' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://cdn.ko-fi.com/cdn/kofi1.png?v=3'            border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>
</p>

#### This project is community maintained and has no sponsorship from Veeam, its employees or any of its affiliates.

# Veeam VBR As Built Report

Veeam VBR As Built Report is a PowerShell module which works in conjunction with [AsBuiltReport.Core](https://github.com/AsBuiltReport/AsBuiltReport.Core).

[AsBuiltReport](https://github.com/AsBuiltReport/AsBuiltReport) is an open-sourced community project which utilises PowerShell to produce as-built documentation in multiple document formats for multiple vendors and technologies.

Please refer to the AsBuiltReport [website](https://www.asbuiltreport.com) for more detailed information about this project.

# :books: Sample Reports

## Sample Report - Veeam Style with EnableHealthCheck

Sample Veeam VBR As Built Report HTML file: [Sample Report](https://htmlpreview.github.io/?https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/dev/Samples/Sample%20Veeam%20Backup%20%26%20Replication%20As%20Built%20Report.html)

## Sample Diagram

Sample Veeam VBR As Built Report Diagram file: [Sample Diagram](Samples/AsBuiltReport.Veeam.VBR.png)

![Sample Diagram](Samples/AsBuiltReport.Veeam.VBR.png)

# :beginner: Getting Started

Below are the instructions on how to install, configure and generate a Veeam VBR As Built report.

## :floppy_disk: Supported Versions
<!-- ********** Update supported Veeam versions ********** -->
The Veeam VBR As Built Report supports the following Veeam Backup & Replication version;

- Veeam Backup & Replication v12+ (Standard, Enterprise & Enterprise Plus Edition)

:exclamation:Community Edition is not supported:exclamation:

## :no_entry_sign: Unsupported Versions

The versions 10 and 11 are no longer supported by Veeam. So I will not be performing compatibility tests with those versions. The report may work on previous versions but I do not guarantee and will not address issues related to pre-v12.

[Veeam Product Lifecycle Policy](https://www.veeam.com/product-lifecycle.html)

### PowerShell

This report is compatible with the following PowerShell versions;

<!-- ********** Update supported PowerShell versions ********** -->
| Windows PowerShell 5.1 | PowerShell 7 |
| :--------------------: | :----------: |
|   :white_check_mark:   |     :x:      |

## :wrench: System Requirements

PowerShell 5.1 and the following PowerShell modules are required for generating a Veeam VBR As Built report.

- [Veeam.Backup.PowerShell Module](https://helpcenter.veeam.com/docs/backup/powershell/getting_started.html?ver=110)
- [PScriboCharts Module](https://github.com/iainbrighton/PScriboCharts)
- [AsBuiltReport.Core Module](https://github.com/AsBuiltReport/AsBuiltReport.Core)
- [Veeam.Diagrammer Module](https://github.com/rebelinux/Veeam.Diagrammer)
- [Diagrammer.Core Module](https://github.com/rebelinux/Diagrammer.Core)


### :closed_lock_with_key: Required Privileges

Only users with Veeam Backup Administrator role assigned can generate a Veeam VBR As Built Report.

## :package: Module Installation

### PowerShell

```powershell
Install-Module -Name AsBuiltReport.Veeam.VBR
```

### GitHub

If you are unable to use the PowerShell Gallery, you can still install the module manually. Ensure you repeat the following steps for the [system requirements](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR#wrench-system-requirements) also.

1. Download the code package / [latest release](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/releases/latest) zip from GitHub
2. Extract the zip file
3. Copy the folder `AsBuiltReport.Veeam.VBR` to a path that is set in `$env:PSModulePath`.
4. Open a PowerShell terminal window and unblock the downloaded files with

    ```powershell
    $path = (Get-Module -Name AsBuiltReport.Veeam.VBR -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Src\Public\*.ps1; Unblock-File -Path $path\Src\Private\*.ps1
    ```

5. Close and reopen the PowerShell terminal window.

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable PSModulePath if you want to use another path._

## :pencil2: Configuration

The Veeam VBR As Built Report utilizes a JSON file to allow configuration of report information, options, detail and healthchecks.

A Veeam VBR report configuration file can be generated by executing the following command;

```powershell
New-AsBuiltReportConfig -Report Veeam.VBR -FolderPath <User specified folder> -Filename <Optional>
```

Executing this command will copy the default Veeam VBR report JSON configuration to a user specified folder.

All report settings can then be configured via the JSON file.

The following provides information of how to configure each schema within the report's JSON file.

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

| Sub-Schema              | Setting             | Default | Description                                                      |
| ----------------------- | ------------------- | ------- | ---------------------------------------------------------------- |
| BackupServerPort        | TCP Port            | 9392    | Set the backup server service's custom port.                     |
| PSDefaultAuthentication | Negotiate/Kerberos  | Default | Set the PSRemoting authentication method                         |
| EnableHardwareInventory | true / false        | false   | Toggle to enable/disable of Hardware information                 |
| ReportStyle             | Veeam/AsBuiltReport | Veeam   | Allow to set report style template.                              |
| EnableDiagrams          | true / false        | false   | Toggle to enable/disable of Infrastructure Diagrams              |
| EnableDiagramsDebug     | true/false          | false   | Toggle to enable/disable diagram debug option.                   |
| DiagramWaterMark        | string              | empty   | Used to set the diagram waterMark.                               |
| ExportDiagrams          | true/false          | true   | Toggle to enable/disable diagram export option.                  |
| EnableDiagramSignature  | true/false          | false   | Toggle to enable/disable diagram signature (button right corner) |
| SignatureAuthorName     | string              | empty   | Toggle to set signature author name.                             |
| SignatureCompanyName    | string              | empty   | Toggle to set signature company name.                            |

###### * Note: In order to generate the infrastructure diagram, the Veeam.Diagrammer module requires the following windows application [Graphviz](https://graphviz.org/download/#windows) >= v9.0

### InfoLevel

The **InfoLevel** schema allows configuration of each section of the report at a granular level. The following sections can be set.

There are 4 levels (0-3) of detail granularity for each section as follows;

| Setting | InfoLevel   | Description                                                          |
| :-----: | ----------- | -------------------------------------------------------------------- |
|    0    | Disabled    | Does not collect or display any information                          |
|    1    | Enabled     | Provides summarised information for a collection of objects          |
|    2    | Adv Summary | Provides condensed, detailed information for a collection of objects |
|    3    | Detailed    | Provides detailed information for individual objects                 |

The table below outlines the default and maximum **InfoLevel** settings for each Backup Infrastructure section.

| Sub-Schema      | Default Setting | Maximum Setting |
| --------------- | :-------------: | :-------------: |
| BackupServe     |        1        |        3        |
| Proxy           |        1        |        3        |
| Settings        |        1        |        2        |
| BR              |        1        |        2        |
| Licenses        |        1        |        1        |
| SOBR            |        1        |        2        |
| WANAccel        |        1        |        1        |
| ServiceProvider |        1        |        2        |
| SureBackup      |        1        |        2        |

The table below outlines the default and maximum **InfoLevel** settings for each Tape Infrastructure section.

| Sub-Schema | Default Setting | Maximum Setting |
| ---------- | :-------------: | :-------------: |
| Server     |        1        |        1        |
| Library    |        1        |        2        |
| MediaPool  |        1        |        2        |
| Vault      |        1        |        1        |
| NDMP       |        1        |        1        |

The table below outlines the default and maximum **InfoLevel** settings for each Inventory section.

| Sub-Schema | Default Setting | Maximum Setting |
| ---------- | :-------------: | :-------------: |
| VI         |        1        |        1        |
| PHY        |        1        |        2        |
| FileShare  |        1        |        1        |

The table below outlines the default and maximum **InfoLevel** settings for each Storage Infrastructure section.

| Sub-Schema | Default Setting | Maximum Setting |
| ---------- | :-------------: | :-------------: |
| ONTAP      |        1        |        2        |
| ISILON     |        1        |        2        |

The table below outlines the default and maximum **InfoLevel** settings for each Backup Jobs section.

| Sub-Schema  | Default Setting | Maximum Setting |
| ----------- | :-------------: | :-------------: |
| Backup      |        1        |        2        |
| BackupCopy  |        1        |        2        |
| Tape        |        1        |        2        |
| Surebackup  |        1        |        2        |
| Agent       |        1        |        2        |
| FileShare   |        1        |        2        |
| Replication |        1        |        2        |
| Restores    |        0        |        1        |

The table below outlines the default and maximum **InfoLevel** settings for each Replication section.

| Sub-Schema   | Default Setting | Maximum Setting |
| ------------ | :-------------: | :-------------: |
| Replica      |        1        |        2        |
| FailoverPlan |        1        |        1        |

The table below outlines the default and maximum **InfoLevel** settings for each Cloud Connect section.

| Sub-Schema       | Default Setting | Maximum Setting |
| ---------------- | :-------------: | :-------------: |
| Certificate      |        1        |        1        |
| PublicIP         |        1        |        1        |
| CloudGateway     |        1        |        2        |
| GatewayPools     |        1        |        1        |
| Tenants          |        1        |        2        |
| BackupStorage    |        1        |        1        |
| ReplicaResources |        1        |        2        |

### Healthcheck

The **Healthcheck** schema is used to toggle health checks on or off.

## :computer: Examples

There are a few examples listed below on running the AsBuiltReport script against a Veeam Backup Server. Refer to the `README.md` file in the main AsBuiltReport project repository for more examples.

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

- Since many of Veeam's features depend on the Standard+ license, the Community edition is not supported.
- If the Veeam Backup Server is not joined to an Active Directory domain (WorkGroup Auth), the PSDefaultAuthentication option must be set to Negotiate. If it is not, some of the report sections will be missing.
- This project uses the PScribo module to generate the report. It has been identified that the EvotecIT module `PSWriteWord` uses the same cmdlet names. In order for this report to be generated correctly it is necessary to uninstall the `PSWriteWord` module.
