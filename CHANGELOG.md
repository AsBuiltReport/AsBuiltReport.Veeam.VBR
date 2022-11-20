# :arrows_clockwise: Veeam VBR As Built Report Changelog

## [0.7.0] - 2022-11-28

### Added

- Added Cloud Connect Section

### Changed

- Added Option 'EnableGraph' false by default to allow to modify Charts in report

### Fixed

- Close [#78](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/78)
- Close [#79](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/79)

## [0.6.0] - 2022-10-28

### Added

- Added Infrastructure Hardening section
- Added per Tape Media Pool configuration information (InfoLevel 2) [#71](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/71)
  - Tape Library Sub-Section
  - Tape Mediums Sub-Section
  - Media Set & Gfs Media Set Sub-Section
  - Retention Sub-Section
  - Options Sub-Section

### Fixed

- Close [#63](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/63)
- Fix [#70](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/70)
- Close [#71](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/71)
- Resolve [#72](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/72)
- Fix [#75](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/75)

## [0.5.5] - 2022-10-02

### Added

- Addeds support for schedule backup windows on Backup Jobs

### Changed

- Improved table sorting
- Added BlankLine between charts and table content

### Fixed

- Fixes [#56](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/56)
- Fixes [#57](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/57)
- Fixes [#58](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/58)
- Fixes [#60](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/60)
- Fixes [#62](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/62)
- Fixes [#64](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/64)

## [0.5.4] - 2022-09-17

### Added

- Added support for File Share Backup Job information
- Added support for Backup Jobs GFS Policy information
- Added Simple Chart support

### Fixed

- Fixes [#49](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/49)
- Fixes [#50](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/50)

## [0.5.3] - 2022-08-21

### Changed

- Improvement to the report's table of contents

### Fixed

- Fixes [#46](https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues/46)

## [0.5.2] - 2022-07-05

### Added

- Added Replication Resource to the Cloud Service Provider section
- Improvements to the Object Storage Repository section
  - Added InfoLevel 2 support (Per Object Storage Repo Configuration)
- Improvements to Scale-Out Backup Repository section
  - Added SOBR General settings sub-section
  - Added FriendlyPath to the Performance Tier sub-section
  - Added Archive Tier sub-section

### Fixed

- Fixed Cloud Service Provider section only displaying last object element.

## [0.5.1] - 2022-06-15

### Added

- Added Cloud Service Provider Summary
  - Added per Service Provider Configuration subsection
- Added Initial v12 support :)

### Fixed

- Code refactoring
- Reviewed Paragraph Section

## [0.5.0] - 2022-05-12

### Added

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

### Fixed

- Fix for not connected Enterprise Manager.

## [0.4.1] - 2022-05-02

### Added

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

### Fixed

- Fix authentication error in Workgroup enviroments #31

## [0.4.0] - 2022-02-27

### Added

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

### Changed

- Updated GitHub Action release workflow to send automated tweets on each release

## [0.3.1] - 2022-02-8

### Added

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

### Changed

- Migrated Sample URL to htmlpreview.github.io

### Fixed

- Fixes Include Veeam Network Statistics in report #13
- Fixes Backup Server physical memory (GB) < 8 always returns true #14
- Fixes Add Veeam Backup\Repo Network Interface Information #15
- Fixes Add Backup Server\Repo Volume Format #16
- Fixes Add option to set veeam custom tcp port #17

## [0.3.0] - 2022-01-30

### Added

- Added File Share section.
- Added Veeam version information.
- Implemented table sorting on primary key.
- Added aditional backup server health checks
- Added Enterprise Manager Information
- Added Service Provider credential information

### Changed

- Improved table caption content.
- Changed ReadMe to include Supported Licenses Edtion.
- Added SQLServer module to manifest file

### Fixed

- Fix missing Infolevel sections.

## [0.2.0] - 2022-01-14

### Added

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

### Changed

- Removed unneeded paragraph section.
- Changed ReadMe to include Supported Licenses Edtion.

### Fixed

- Fix many try/case statements

## [0.1.0] - 2022-01-05

### Added

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
