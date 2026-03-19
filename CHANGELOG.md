# :arrows_clockwise: Veeam VBR As Built Report Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

##### This project is community maintained and has no sponsorship from Veeam, its employees or any of its affiliates.

## [0.9.0] - 2026-03-??

### :arrows_clockwise: Changed

- Update module version to `v0.9.0`
- Upgrade AsBuiltReport.Chart module to `v0.3.0`
- Migrate charts to use AsBuiltReport.Chart charting functions
- Migrate diagrams to use AsBuiltReport.Diagram diagramming functions
- Update module references in README.md for Veeam VBR As Built Report
- Reorganize module structure - moved module files to AsBuiltReport.Veeam.VBR/ subdirectory

## [0.8.26] - 2026-02-20

### :arrows_clockwise: Changed

- Update module version to `v0.8.26`
- Upgrade AsBuiltReport.Core module to `v1.6.2`
- Modify entity retrieval functions for improved timeout handling
- Add timeout handling for vSphere inventory queries
- Enable Nutanix Backup Job information collection

### :bug: Fixed

- Fix issue preventing the report to complete

## [0.8.25] - 2026-01-29

### :arrows_clockwise: Changed

- Update module version to `v0.8.25`

### :bug: Fixed

- Fix issue while trying to generate backup server diagrams from local Backup server
- Fix repository diagram issues
- Fix issue when enabling verbose logging
- Fix issue preventing the report to complete

## [0.8.24] - 2026-01-25

## :toolbox: Added

- Add dependency version check
- Add sponsor information to the module header
- Add timeout handling for vSphere inventory queries
- Add additional security compliance checks for Veeam VBR Linux appliance
- Add option to control the module update check process. Fix [#229](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/229)
- Add support for running the report from Linux using `Veeam PowerShell module for Linux`

### :arrows_clockwise: Changed

- Update module version to `v0.8.24`
- Upgrade Diagrammer.Core module to `v0.2.37`
- Update GitHub release workflow to use latest checkout action version
- Update GitHub release workflow to use latest bluesky-post-action version
- Update GitHub CodeQL workflow to use latest checkout action version
- Refactor Veeam Backup & Replication scripts to improve server information retrieval
- Update TODO list with new tasks for security and compliance improvements
- Implement pwsh best practices
- Migrate Veeam.Diagrammer diagrams to the main report
- Enable Export of diagrams in PDF format by default

### :x: Remove

- Remove noisy logging messages during report execution
- Remove Veeam.Diagrammer dependency (Project no longer Maintained)

### :bug: Fixed

- Fix error in Unix system not finding default report configuration file
- Fix Invoke-FindVBRViEntityWithTimeout not finding object in Unix based OS
- Fix diagram size not respecting document border size

## [0.8.23] - 2025-07-30

## :toolbox: Added

- Add support for Nutanix backup jobs
- Add option to enable use of updated Veeam icons in generated diagrams

### :arrows_clockwise: Changed

- Update module version to v0.8.23
- Upgrade Veeam.Diagrammer module to v0.8.24
- Upgrade Diagrammer.Core module to v0.2.28

### :bug: Fixed

- Close #205

## [0.8.22] - 2025-07-23

## :toolbox: Added

- Add Cloud Connect infrastructure diagram
- Add per Tenant resources diagram

### :arrows_clockwise: Changed

- Updated Get-AbrVbrCloudConnectTenant to include diagram generation
- Modified Invoke-AsBuiltReport to handle tenant-specific diagrams
- Improved handling of diagram parameters and outputs
- Updated changelog and version numbers across scripts
- Refactor diagram section in Get-AbrVbrCloudConnectTenant function for improved error handling and clarity

### :arrows_clockwise: Changed

- Bump module to v0.8.22
- Bump Veeam.Diagrammer module to v0.8.24
- Bump Diagrammer.Core module to v0.2.27
- Update workflow to use Windows 2022 for publishing PowerShell module


## [0.8.21] - 2025-05-17

## :toolbox: Added

- Add a condition to verify the version of dependent modules
- Add DiagramColumnSize option
- Refine dependency version checks

### :arrows_clockwise: Changed

- Bump module version to 0.8.21
- Bump Veeam.Diagrammer module to version 0.6.29
- Improve handling of diagram image resolution calculations

### :bug: Fixed

- Resolve an error occurring in the infrastructure diagram when exporting to Word format
- Resolve [#217](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/217)
- Resolve an issue where the Infrastructure Summary was unintentionally disabled

## [0.8.20] - 2025-05-10

### :arrows_clockwise: Changed

- Bump module version to 0.8.20
- Bump Veeam.Diagrammer module version to 0.6.27
- Bump Diagrammer.Core module version to 0.2.26
- Modify copyright year
- Enhance execution time logging in Veeam report functions

### :bug: Fixed

- Fix #215

## [0.8.19] - 2025-04-30

### :arrows_clockwise: Changed

- Bump module version to 0.8.19
- Bump Veeam.Diagrammer module version to 0.6.26
- Enhance diagram generation messages
- Improve diagram image quality settings

## [0.8.18] - 2025-04-27

## :toolbox: Added

- Add code to allow the exporting of the Veeam diagram
  - Infrastructure
  - FileProxy
  - HyperVProxy
  - Repository
  - Sobr
  - Tape
  - ProtectedGroup
  - vSphereProxy
  - WanAccelerator
- Enhance Veeam report configuration and diagram functionality by adding EntraID and Nutanix options
- Refining diagram theme handling in the diagrammer function.

## [0.8.17] - 2025-04-18

## :toolbox: Added

- Add Backup Infrastructure diagram to the main report

### :arrows_clockwise: Changed

- Increase Diagrammer.Core minimum requirement to v0.2.24
- Increase Veeam.Diagrammer minimum requirement to v0.6.24
- Increase AsBuiltReport.Core to v1.4.3
- Introduce Get-AbrVbrDiagrammer function for improved diagram handling
- Refactor Invoke-AsBuiltReport.Veeam.VBR to utilize new Get-AbrVbrDiagrammer function
- Enable diagram generation options in configuration file.

## [0.8.16] - 2025-04-09

### :arrows_clockwise: Changed

- Increase Diagrammer.Core minimum requirement to v0.2.21
- Increase Veeam.Diagrammer minimum requirement to v0.6.22
- Increase AsBuiltReport.Core to v1.4.3

### :bug: Fixed

- Fix issue where the Syslog Event Filter section displayed content even when no configuration was available
- Fix issue causing WinRM connection failures in the Backup Server section

## [0.8.15] - 2025-03-05

### :arrows_clockwise: Changed

- Increase Diagrammer.Core minimum requirement to v0.2.19
- Increase Veeam.Diagrammer minimum requirement to v0.6.20
- Increase AsBuiltReport.Core to v1.4.2.1
- Flag report as incompatible with Veeam Backup & Replication v13
- Update diagram and report sample files

## [0.8.14] - 2025-01-30

## :toolbox: Added

- Add support for vMWare Cloud Director backup job
- Add option to set the RoundUnits of the storage usages

### :arrows_clockwise: Changed

- Storage units in the report are set to 1 round by default
- Increase AsBuiltReport.Core to v1.4.2

### :bug: Fixed

- Fix [#197](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/197)
- Fix [#198](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/198)

## [0.8.13] - 2024-12-11

## :toolbox: Added

- Add EntraID Tenant configuration
  - Add Objects Backup Job information
  - Add EntraID Tenant information to the Infrastructure diagram
- Update Malware detection setting
  - Add Signature Detection
- Update Security & Compliance Best Practice content
- Add Syslog Event Filter information
- Add Google Cloud Storage repository information
- Add VMware Infrastructure information to the Infrastructure diagram

### :arrows_clockwise: Changed

- Increase Veeam.Diagrammer minimum requirement to v0.6.18
- Change the infrastructure diagram default save location to $OutputFolderPath
- Increase AsBuiltReport.Core to v1.4.1

### :bug: Fixed

- Fix error "A positional parameter cannot be found that accepts argument '-'" at Get-AbrVbrConfigurationBackupSetting cmdlet
- Fix ConvertTo-HashToYN cmdlet not generating an ordereddictionary output

## [0.8.12] - 2024-11-22

### :arrows_clockwise: Changed

- Improve detection of empty fields in tables
- Improve detection of true/false elements in tables
- Improve support for Veeam B&R v11
- Update GitHub release workflow to add post to Bluesky social platform
- Increase Diagrammer.Core minimum requirement to v0.2.13
- Increase Veeam.Diagrammer minimum requirement to v0.6.16

### :bug: Fixed

- Fix [#187](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/187)
- Fix Cloud Connect tenant expiration date healthcheck
- Fix VbrVersion variable not getting populated

## [0.8.11] - 2024-10-30

## :toolbox: Added

- Add diagram theming option (Black/White/Neon)
- Add code to properly display space information

### :arrows_clockwise: Changed

- Increase Diagrammer.Core minimum requirement to v0.2.11
- Increase Veeam.Diagrammer minimum requirement to v0.6.12
- Improve connection validation throuth WinRM
- Deny connection to backup server by Ip Address

### :bug: Fixed

- Fix SOBR capacity extent members table
- Fix Unstructured Data section displaying section when no data is available
- Fix [#179](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/179)
- Fix [#181](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/181)
- Fix [#182](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/182)

## [0.8.10] - 2024-09-12

### :arrows_clockwise: Changed

- Migrate infrastructure diagram to Veeam.Diagrammer

### :arrows_clockwise: Changed

- Increase Diagrammer.Core minimum requirement to v0.2.7
- Increase Veeam.Diagrammer minimum requirement to v0.6.6

### Remove

- Remove unused icons folder and images

## [0.8.9] - 2024-08-31

## :toolbox: Added

- Add ExportDiagramsFormat option that allows specifying the format of the exported diagrams
  - Supported formats are dot, pdf, png, svg
- Compatibility tests with v12.2 were performed

### :arrows_clockwise: Changed

- Increase Diagrammer.Core minimum requirement to v0.2.3
- Increase Veeam.Diagrammer minimum requirement to v0.6.2

### :bug: Fixed

- Fix bug while exporting diagram in svg format
- Improve error handling when infrastructure components are missing
- Fix [#169](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/169)

## [0.8.8] - 2024-07-26

## :toolbox: Added

- Add Tape Infrastructure to the diagram
  - Tape Server
  - Tape Library
  - Tape Vault
- Add Service Provider to the diagram
- Improve Infrastructure diagram error handling

## [0.8.7] - 2024-05-28

## :toolbox: Added

- Update the ReadMe file to reflect conflicts with PSWriteWord module
- Update the Eomm/why-don-t-you-tweet action to v2.0.0
- General code cleanup/improvements

### :arrows_clockwise: Changed

- Disable the Backup Restore section (Some users reported issues with this section)
- Increase Veeam.Diagrammer module minimum requirement to v0.6.0

### :bug: Fixed

- Fix sorting of table [A-Z].

## [0.8.6] - 2024-04-29

## :toolbox: Added

- Add Backup Infrastructure Diagram (WIP)
- Close [#155](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/155)
- Add vCD Resources to Service Provider section
- Add Backup Repository Space Utilization chart

### :arrows_clockwise: Changed

- Increase AsBuiltReport.Core modules to v1.4.0
- Migrate NOTOCHeading3 to NOTOCHeading4 to fix section heading
- Change charts palette to follow new AsBuiltReport.Core theme


### :bug: Fixed

- Fix [#149](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/149)
- Fix [#151](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/151)
- Fix [#150](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/150)

### :x: Remove

- Remove EnableCharts option.
- Remove Infrastructure Charts

## [0.8.5] - 2024-03-15

## :toolbox: Added

- Added Option => History section
- Improved Role & Users section
  - Added Global MFA settings
  - Added Auto logoff on inactivity setting
  - Added Four-eye Authorization setting
  - Added HealthCheck conditions
- Added Backup Time Duration table to the Jobs Summary. Close [#144](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/144)
- Added Restore point reporting. Close [#143](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/143)
- Added Automatically disable Windows Firewall option to the SureBackup verification section

### :arrows_clockwise: Changed

- Removed Graphviz install check code. (No need to manually install Graphviz)
- Code Cleanup
- Increased Veeam.Diagrammer module requirement to v0.5.9

### :bug: Fixed

- Improved error handling on the Diagram section.
- Fixed issue with the Veeam.Diagrammer module.
- Resolved issue that prevented SureBackup Virtual Lab information to be collected. Fix [#142](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/142)
- Resolved issue in the Malware Global Exclusions section. Fix [#145](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/145)
- Resolved an issue related to Protection Group licensing. Fix [#146](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/146)

## [0.8.4] - 2024-01-16

## :toolbox: Added

- Added Veeam Best Practice Analyzer support
- Added support for Key Management Server configuration
- Added Protection Group diagram support
- Added support for more Backup Repository types:
  - Wasabi
  - BackBlaze

### :arrows_clockwise: Changed

- Improved the total processing timeof the report

### :bug: Fixed

- Fix [#131](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/131)
- Fix [#132](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/132)
- Fix [#133](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/133)
- Fix [#134](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/134)


## [0.8.3] - 2023-12-29

## :toolbox: Added

- Initial diagramming support
- v12.1 support:
  - File Backup Advanced Setting (ACL Handling) collection
  - Object Storage Backup Jobs
  - Object Storage data source (Unstructured Data) collection
  - Global Exclusions information
  - Malware Detection information
  - SureBackup Job content analisys (Malware Detection)
  - Event Forwarding (Syslog)
  - Linux host authentication setting

### :bug: Fixed

- Close [#114](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/114)
- Close [#115](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/115)
- Close [#116](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/116)
- Close [#117](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/117)
- Close [#118](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/118)
- Close [#119](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/119)
- Close [#120](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/120)
- Fix [#121](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/121) @carceneaux

## [0.8.2] - 2023-10-12

### :bug: Fixed

- Fixed misspelled module name in file /Src/Public/Invoke-AsBuiltReport.Veeam.VBR.ps1. Fix #110

## [0.8.1] - 2023-10-03

### :x: Remove

- Removed Infrastructure Hardening section

## [0.8.0] - 2023-07-13

## :toolbox: Added

- Added a separated Backup Copy Job section for v12 edition

### :arrows_clockwise: Changed

- Improved Health Check recommendations

### :bug: Fixed

- Fix [#104](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/104)

## [0.7.3] - 2023-06-13

## :toolbox: Added

- Added Network Traffic Rules - Throttling Windows Time Period information
- Added Backup Server Domain Joined health check

## [0.7.2] - 2023-06-04

## :toolbox: Added

- Added HealthCheck recommendations
- Added Global Notification options
- Added SOBR Capacity Tier - Offload Window Time Period information
- Updated Report Sample Files

### :arrows_clockwise: Changed

- Visually improved the Backup Window Time Period table

### :bug: Fixed

- Fix [#99](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/99)
- Fix [#100](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/100)

## [0.7.1] - 2023-03-07

### :arrows_clockwise: Changed

- Improved bug and feature request templates.
- Improved support for version 12
- Changed Required Modules to AsBuiltReport.Core v1.3.0
- Improved Error Logging

### :bug: Fixed

- Fix [#83](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/83)
- Fix [#84](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/84)
- Fix [#85](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/83)
- Fix [#86](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/86)
- Fix [#88](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/88)
- Fix [#89](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/89)
- Fix [#90](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/90)
- Fix [#96](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/96)

## [0.7.0] - 2022-12-03

## :toolbox: Added

- Added support for Cloud Connect.

### :arrows_clockwise: Changed

- Added 'EnableCharts' option to enable/disable the creation of Charts in report (Disabled by default).
- Added 'EnableHardwareInventory' option to enable/disable the collection of HW inventory (Disabled by default).
- The Infrastructure Security Hardening section has been modified so it is disabled by default.
- The Executive Summary section has been removed. The summary table has been moved to each corresponding section.
- The service providers section has been improved.

### :bug: Fixed

- Close [#78](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/78)
- Close [#79](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/79)
- Close [#80](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/80)

## [0.6.0] - 2022-10-28

## :toolbox: Added

- Added Infrastructure Hardening section
- Added per Tape Media Pool configuration information (InfoLevel 2) [#71](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/71)
  - Tape Library Sub-Section
  - Tape Mediums Sub-Section
  - Media Set & Gfs Media Set Sub-Section
  - Retention Sub-Section
  - Options Sub-Section

### :bug: Fixed

- Close [#63](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/63)
- Fix [#70](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/70)
- Close [#71](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/71)
- Resolve [#72](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/72)
- Fix [#75](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/75)

## [0.5.5] - 2022-10-02

## :toolbox: Added

- Addeds support for schedule backup windows on Backup Jobs

### :arrows_clockwise: Changed

- Improved table sorting
- Added BlankLine between charts and table content

### :bug: Fixed

- Fixes [#56](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/56)
- Fixes [#57](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/57)
- Fixes [#58](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/58)
- Fixes [#60](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/60)
- Fixes [#62](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/62)
- Fixes [#64](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/64)

## [0.5.4] - 2022-09-17

## :toolbox: Added

- Added support for File Share Backup Job information
- Added support for Backup Jobs GFS Policy information
- Added Simple Chart support

### :bug: Fixed

- Fixes [#49](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/49)
- Fixes [#50](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/50)

## [0.5.3] - 2022-08-21

### :arrows_clockwise: Changed

- Improvement to the report's table of contents

### :bug: Fixed

- Fixes [#46](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/46)

## [0.5.2] - 2022-07-05

## :toolbox: Added

- Added Replication Resource to the Cloud Service Provider section
- Improvements to the Object Storage Repository section
  - Added InfoLevel 2 support (Per Object Storage Repo Configuration)
- Improvements to Scale-Out Backup Repository section
  - Added SOBR General settings sub-section
  - Added FriendlyPath to the Performance Tier sub-section
  - Added Archive Tier sub-section

### :bug: Fixed

- Fixed Cloud Service Provider section only displaying last object element.

## [0.5.1] - 2022-06-15

## :toolbox: Added

- Added Cloud Service Provider Summary
  - Added per Service Provider Configuration subsection
- Added Initial v12 support :)

### :bug: Fixed

- Code refactoring
- Reviewed Paragraph Section

## [0.5.0] - 2022-05-12

## :toolbox: Added

- Added Replication Section @rebelinux
  - Replica Information
    - Added Optional InfoLevel 2 information (Adv Summary)
  - Failover Plan Information
    - Added Virtual Machine Boot Order reporting
- Added Replication Job Configuration information @rebelinux
  - Added Optional InfoLevel 2 information (Adv Summary)
    - Advanced Settings (Traffic)
    - Advanced Settings (Notification)
    - Advanced Settings (vSphere)
    - Advanced Settings (Integration)
    - Advanced Settings (Script)

### :bug: Fixed

- Fix for not connected Enterprise Manager.

## [0.4.1] - 2022-05-02

## :toolbox: Added

- Added Backup Repository information about Immutability. @vNote42
  - Immutability Enabled: yes/no
  - Immutability Interval
- New Health Check about Immutability. @vNote42
  - If Repo supports Immutability and Immutability is disabled: Warning
- Added per section summary information. @rebelinux
- Removed SQLServer module dependency. @rebelinux
- Added VMware/Hyper-V job VM count. @rebelinux
- Added detailed repository information of ScaleOut Backup Repository extents @vNote42
  - Information of parent SOBR is also included
- Added the Option PSDefaultAuthentication used to set the PSRemoting authentication method over WinRM @rebelinux
  - Kerberos for Domain joined devices (Kerberos authentication)
  - Negotiate for Workgroup devices (NTLM authentication)
- Added Agent Backup Job Configuration information @rebelinux
  - Job Mode information
    - Worstation
    - Server
    - No Failover Support in this release (Don't have the resources to develop this feature)
  - Protected Computer Objects information
  - Backup Mode information
    - Entire Computer
    - Volume Level Backup
    - File Level Backup
  - Destination information (Jobs Managed by Agent)
    - Local Storage
    - Shared Folder
    - Veeam Backup Repository
    - Sadly no Veeam Cloud Connect Repository Support (Don't have the resources to develop this feature)
  - Storage information (Jobs Managed by Server)
    - Secondary Target Job information
  - Backup Cache information
  - Job Scheduling information

### :bug: Fixed

- Fix authentication error in Workgroup enviroments #31

## [0.4.0] - 2022-02-27

## :toolbox: Added

- Added Backup Job Configuration information
  - VMware type Backup Jobs
    - VMware Backup Copy Jobs
  - Hyper-V Backup Jobs
    - Hyper-V Backup Copy Jobs
  - Tape Backup Job Configuration
    - Backup to Tape Jobs
    - File to Tape Jobs
  - SureBackup Job Configuration
    - VMware SureBackup Jobs
- Added Configuration Backup Section

### :arrows_clockwise: Changed

- Updated GitHub Action release workflow to send automated tweets on each release

## [0.3.1] - 2022-02-8

## :toolbox: Added

- Added option to set veeam custom tcp port (BackupServerPort)
- Added Volume Format to the BackupServer/Proxy section
- Added BackupServer/Proxy Network Interface Information
- Added process network Statistics ($InfoLevel.Infrastructure.BackupServer -ge 3)
- Added Storage Infrastructure section
  - Added NetApp Ontap support
  - Added Dell Isilon support
- Added initial Backup Job section
  - Added Tape Backup Job information
  - Added SureBackup Job information
  - Added Agent Backup Job information

### :arrows_clockwise: Changed

- Migrated Sample URL to htmlpreview.github.io

### :bug: Fixed

- Fixes Include Veeam Network Statistics in report #13
- Fixes Backup Server physical memory (GB) < 8 always returns true #14
- Fixes Add Veeam Backup\Repo Network Interface Information #15
- Fixes Add Backup Server\Repo Volume Format #16
- Fixes Add option to set veeam custom tcp port #17

## [0.3.0] - 2022-01-30

## :toolbox: Added

- Added File Share section.
- Added Veeam version information.
- Implemented table sorting on primary key.
- Added aditional backup server health checks
- Added Enterprise Manager Information
- Added Service Provider credential information

### :arrows_clockwise: Changed

- Improved table caption content.
- Changed ReadMe to include Supported Licenses Edtion.
- Added SQLServer module to manifest file

### :bug: Fixed

- Fix missing Infolevel sections.

## [0.2.0] - 2022-01-14

## :toolbox: Added

- Added if Condition to better validate License Edition.
- Added more try/case statements.
- Added Aditional Tape Infrastructure Sections.
  - Added Tape MediaPools Information.
  - Added NDMP Server Information.
- Added Initial Inventory Section Information.
  - Added Virtual Infrastructure Section.
    - Added VMware vSpere Section.
    - Added Microsoft Hyper-V Section.
  - Added Physical Infrastructure Section.
    - Added Protection Group Summary Section.
      - Added Protection Group Detailed Configuration.

### :arrows_clockwise: Changed

- Removed unneeded paragraph section.
- Changed ReadMe to include Supported Licenses Edtion.

### :bug: Fixed

- Fix many try/case statements

## [0.1.0] - 2022-01-05

## :toolbox: Added

- Added Backup Server Information.
  - Added Backup Server Hardware Inventory.
  - Added Backup Server Health Check.
    - Added Veaam services status check.
- Added License Information support.
  - Added Per Instance License Usage.
  - Added Per CPU Socket License Usage.
  - Added Capacity License Usage.
- Added General Option (Settings) Information.
  - Added support for Email Notification Settings
  - Added Storage Latency Control Options.
    - Added support for Per Datastore Latency Control Options.
  - Added support for Backup Server TLS Certificate Information.
  - Added Network Traffic Rules verification.
    - Added information of Preferred Networks settings.
- Added Security related Information.
  - Role and Users Information.
  - Credentils Information.
- Added Backup Proxy Infomation.
  - Added Health Check Support.
  - Added VMware Proxy Information.
  - Added Hyper-V Proxy Information.
- Added Wan Accelerator Information.
- Added Backup Repository Information.
  - Added Configuration Information.
  - Added ScaleOut Repository Information.
    - Added Performance Extent Information.
    - Added Capacity Extent Information.
  - Added Object Storage Support.
- Added SureBackup Information.
  - Added Application Group Information
    - Added per VM settings,
- Added Virtual Labs Information.
  - Added Configuration Information.
    - Added Per Virtual Lab Setting.
      - Added vNic Settings.
      - Added IP Address Mapping.
- Added Location Information
- Added Virtualization Servers and Hosts Information
- Added Tape Infrastructure Information.
  - Added Tape Server Information.
  - Added Tape Library Information.
    - Added Per Library Tape Drive Information.
  - Added Tape Vault Information.
- Added Veeam Logo to Cover Page.
