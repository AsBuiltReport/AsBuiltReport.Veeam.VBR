function Invoke-AsBuiltReport.Veeam.VBR {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VBR in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.9.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '', Scope = 'Function')]


    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    #Requires -RunAsAdministrator

    if ($psISE) {
        Write-Error -Message 'You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window.'
        break
    }

    Get-AbrVbrRequiredModule -Name 'Veeam.Backup.PowerShell' -Version '1.0'


    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options

    # Check the version of the dependency modules
    if ($Options.UpdateCheck) {
        Write-ReportModuleInfo -ModuleName 'Veeam.VBR'
    }
    Write-Host '  - To sponsor this project, please visit: ' -NoNewline
    Write-Host 'https://ko-fi.com/F1F8DEV80' -ForegroundColor Cyan

    if ($Options.UpdateCheck) {
        Write-Host '  - Getting dependency information:'
        # Check the version of the dependency modules
        $ModuleArray = @('AsBuiltReport.Core', 'AsBuiltReport.Chart', 'AsBuiltReport.Diagram')

        foreach ($Module in $ModuleArray) {
            try {
                $InstalledVersion = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

                if ($InstalledVersion) {
                    Write-Host "    - $Module module v$($InstalledVersion.ToString()) is currently installed."
                    $LatestVersion = Find-Module -Name $Module -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
                    if ($InstalledVersion -lt $LatestVersion) {
                        Write-Host "      - $Module module v$($LatestVersion.ToString()) is available." -ForegroundColor Red
                        Write-Host "      - Run 'Update-Module -Name $Module -Force' to install the latest version." -ForegroundColor Red
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning $_.Exception.Message
            }
        }
    }

    # Set Custom styles for Veeam theme template
    if ($Options.ReportStyle -eq 'Veeam') {
        & "$PSScriptRoot\..\..\AsBuiltReport.Veeam.VBR.Style.ps1"
        $Legend = {
            Text "$($reportTranslate.InvokeAsBuiltReportVeeamVBR.LegendEnabled) \" -Color 81BC50 -Bold
            Text " $($reportTranslate.InvokeAsBuiltReportVeeamVBR.LegendDisabled)" -Color dddf62 -Bold
        }
    } else {
        # Set Custom styles for Default AsBuiltReport template
        Style -Name 'ON' -Size 8 -BackgroundColor '4c7995' -Color 4c7995
        Style -Name 'OFF' -Size 8 -BackgroundColor 'ADDBDB' -Color ADDBDB
        $Legend = {
            Text "$($reportTranslate.InvokeAsBuiltReportVeeamVBR.LegendEnabled) \" -Color 4c7995 -Bold
            Text " $($reportTranslate.InvokeAsBuiltReportVeeamVBR.LegendDisabled)" -Color ADDBDB -Bold
        }
    }

    # Used to set values to TitleCase where required
    $script:TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($System in $Target) {
        if (Select-String -InputObject $System -Pattern '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
            throw "Please use the FQDN instead of an IP address to connect to the Backup Server: $System"
        }
        Get-AbrVbrServerConnection
        $VeeamBackupServer = ((Get-VBRServerSession).Server).ToString().ToUpper().Split('.')[0]
        $script:VbrLicenses = Get-VBRInstalledLicense

        Section -Style Heading1 $($VeeamBackupServer) {
            Paragraph $reportTranslate.InvokeAsBuiltReportVeeamVBR.ServerOverviewParagraph
            BlankLine

            #---------------------------------------------------------------------------------------------#
            #                            Backup Infrastructure Section                                    #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Infrastructure.PSObject.Properties.Value -ne 0) {
                Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.BackupInfrastructure {
                    Paragraph ($reportTranslate.InvokeAsBuiltReportVeeamVBR.BackupInfrastructureParagraph -f $VeeamBackupServer)
                    BlankLine
                    if ($Options.EnableDiagrams) {
                        try {
                            try {
                                $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-Infrastructure' -DiagramOutput base64
                            } catch {
                                Write-PScriboMessage -IsWarning "Backup Infrastructure Diagram: $($_.Exception.Message)"
                            }
                            if ($Graph) {
                                $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                Section -Style Heading3 $reportTranslate.InvokeAsBuiltReportVeeamVBR.BackupInfrastructureDiagram {
                                    Image -Base64 $Graph -Text 'Backup Infrastructure Diagram' -Align Center -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height
                                    PageBreak
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Backup Infrastructure Diagram Section: $($_.Exception.Message)"
                        }
                    }
                    if ($InfoLevel.Infrastructure.BackupServer -ge 1) {
                        Get-AbrVbrInfrastructureSummary
                        if ($VbrVersion -ge 12) {
                            Get-AbrVbrSecurityCompliance
                        }
                        Get-AbrVbrBackupServerInfo
                        Get-AbrVbrEnterpriseManagerInfo
                    }
                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureLicenses -f $InfoLevel.Infrastructure.Licenses)
                    if ($InfoLevel.Infrastructure.Licenses -ge 1) {
                        Get-AbrVbrInstalledLicense
                    }
                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureSettings -f $InfoLevel.Infrastructure.Settings)
                    if ($InfoLevel.Infrastructure.Settings -ge 1) {
                        Section -Style Heading3 $reportTranslate.InvokeAsBuiltReportVeeamVBR.GeneralOptions {
                            Paragraph $reportTranslate.InvokeAsBuiltReportVeeamVBR.GeneralOptionsParagraph
                            BlankLine
                            Get-AbrVbrConfigurationBackupSetting
                            Get-AbrVbrEmailNotificationSetting
                            if ($VbrVersion -ge 12.1) {
                                Get-AbrVbrEventForwarding
                            }
                            Get-AbrVbrGlobalNotificationSetting
                            Get-AbrVbrHistorySetting
                            Get-AbrVbrIOControlSetting
                            Get-AbrVbrBackupServerCertificate
                            if ($VbrVersion -ge 12) {
                                Get-AbrVbrNetworkTrafficRule
                            }
                            if ($VbrVersion -ge 12.1) {
                                Get-AbrVbrMalwareDetectionOption
                                Get-AbrVbrGlobalExclusion
                            }
                        }
                    }

                    Get-AbrVbrUserRoleAssignment
                    Get-AbrVbrCredential
                    if ($VbrVersion -ge 12.1) {
                        Get-AbrVbrKMSInfo
                    }
                    Get-AbrVbrLocation
                    Get-AbrVbrManagedServer

                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureProxy -f $InfoLevel.Infrastructure.Proxy)
                    if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                        Get-AbrVbrBackupProxy
                    }
                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureWANAccel -f $InfoLevel.Infrastructure.WANAccel)
                    if ($InfoLevel.Infrastructure.WANAccel -ge 1) {
                        Get-AbrVbrWANAccelerator
                    }
                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureServiceProvider -f $InfoLevel.Infrastructure.ServiceProvider)
                    if ($InfoLevel.Infrastructure.ServiceProvider -ge 1) {
                        Get-AbrVbrServiceProvider
                    }
                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureBR -f $InfoLevel.Infrastructure.BR)
                    if ($InfoLevel.Infrastructure.BR -ge 1) {
                        Get-AbrVbrBackupRepository
                        Get-AbrVbrObjectRepository
                    }
                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureSOBR -f $InfoLevel.Infrastructure.SOBR)
                    if ($InfoLevel.Infrastructure.SOBR -ge 1) {
                        Get-AbrVbrScaleOutRepository
                    }
                    Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInfrastructureSureBackup -f $InfoLevel.Infrastructure.SureBackup)
                    if ($InfoLevel.Infrastructure.SureBackup -ge 1) {
                        Get-AbrVbrSureBackup
                    }
                }
            }
            #---------------------------------------------------------------------------------------------#
            #                            Tape Infrastructure Section                                      #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Tape.PSObject.Properties.Value -ne 0) {
                if ((Get-VBRTapeServer).count -gt 0) {
                    Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.TapeInfrastructure {
                        Paragraph $reportTranslate.InvokeAsBuiltReportVeeamVBR.TapeInfrastructureParagraph
                        BlankLine
                        Get-AbrVbrTapeInfraSummary
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelTapeServer -f $InfoLevel.Tape.Server)
                        if ($InfoLevel.Tape.Server -ge 1) {
                            Get-AbrVbrTapeServer
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelTapeLibrary -f $InfoLevel.Tape.Library)
                        if ($InfoLevel.Tape.Library -ge 1) {
                            Get-AbrVbrTapeLibrary
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelTapeMediaPool -f $InfoLevel.Tape.MediaPool)
                        if ($InfoLevel.Tape.MediaPool -ge 1) {
                            Get-AbrVbrTapeMediaPool
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelTapeVault -f $InfoLevel.Tape.Vault)
                        if ($InfoLevel.Tape.Vault -ge 1) {
                            Get-AbrVbrTapeVault
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelTapeNDMP -f $InfoLevel.Tape.NDMP)
                        if ($InfoLevel.Tape.NDMP -ge 1) {
                            Get-AbrVbrNDMPInfo
                        }

                        if ($Options.EnableDiagrams -and ((Get-VBRTapeServer).count -gt 0) -and ((Get-VBRTapeLibrary).count -gt 0)) {
                            try {
                                try {
                                    $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-Tape' -DiagramOutput base64
                                } catch {
                                    Write-PScriboMessage -IsWarning "Tape Infrastructure Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                    PageBreak
                                    Section -Style Heading3 $reportTranslate.InvokeAsBuiltReportVeeamVBR.TapeInfrastructureDiagram {
                                        Image -Base64 $Graph -Text 'Tape Infrastructure Diagram' -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
                                        PageBreak
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Tape Infrastructure Diagram Section: $($_.Exception.Message)"
                            }
                        }
                    }
                }
            }
            #---------------------------------------------------------------------------------------------#
            #                                  Inventory Section                                          #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Inventory.PSObject.Properties.Value -ne 0) {
                if ((Get-VBRServer).count -gt 0) {
                    Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.Inventory {
                        Paragraph ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InventoryParagraph -f $VeeamBackupServer)
                        BlankLine
                        Get-AbrVbrInventorySummary
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInventoryVI -f $InfoLevel.Inventory.VI)
                        if ($InfoLevel.Inventory.VI -ge 1) {
                            Get-AbrVbrVirtualInfrastructure
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInventoryPHY -f $InfoLevel.Inventory.PHY)
                        if ($InfoLevel.Inventory.PHY -ge 1) {
                            $InventObjs = try {
                                Get-VBRProtectionGroup | Sort-Object -Property Name
                            } catch {
                                Write-PScriboMessage -IsWarning "Physical Infrastructure Summary Cmdlet Section: $($_.Exception.Message)"
                            }

                            Get-AbrVbrPhysicalInfrastructure

                            if ($Options.EnableDiagrams -and $InventObjs) {
                                try {
                                    try {
                                        $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-ProtectedGroup' -DiagramOutput base64
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Physical Infrastructure Diagram: $($_.Exception.Message)"
                                    }
                                    if ($Graph) {
                                        $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                        PageBreak
                                        Section -Style Heading3 $reportTranslate.InvokeAsBuiltReportVeeamVBR.PhysicalInfrastructureDiagram {
                                            Image -Base64 $Graph -Text 'Physical Infrastructure Diagram' -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
                                            PageBreak
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Physical Infrastructure Diagram Section: $($_.Exception.Message)"
                                }
                            }
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInventoryFileShare -f $InfoLevel.Inventory.FileShare)
                        if ($InfoLevel.Inventory.FileShare -ge 1) {
                            if ($VbrVersion -lt 12.1) {
                                Get-AbrVbrFileSharesInfo
                            } else {
                                Get-AbrVbrUnstructuredDataInfo
                            }
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelInventoryEntraID -f $InfoLevel.Inventory.EntraID)
                        if (($InfoLevel.Inventory.EntraID -ge 1) -and ($VbrVersion -ge 12.3)) {
                            Get-AbrVbrEntraIDTenant
                        }
                    }
                }
            }
            #---------------------------------------------------------------------------------------------#
            #                                  Storage Infrastructure Section                             #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Storage.PSObject.Properties.Value -ne 0) {
                if ((Get-NetAppHost).count -gt 0) {
                    Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.StorageInfrastructure {
                        Paragraph ($reportTranslate.InvokeAsBuiltReportVeeamVBR.StorageInfrastructureParagraph -f $VeeamBackupServer)
                        BlankLine
                        Get-AbrVbrStorageInfraSummary
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelStorageOntap -f $InfoLevel.Storage.Ontap)
                        if ($InfoLevel.Storage.Ontap -ge 1) {
                            Get-AbrVbrStorageOntap
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelStorageIsilon -f $InfoLevel.Storage.Isilon)
                        if ($InfoLevel.Storage.Isilon -ge 1) {
                            Get-AbrVbrStorageIsilon
                        }
                    }
                }
            }
            #---------------------------------------------------------------------------------------------#
            #                                   Replication Section                                       #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Replication.PSObject.Properties.Value -ne 0) {
                if ((Get-VBRReplica).count -gt 0 -or ((Get-VBRFailoverPlan).count -gt 0)) {
                    Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.Replication {
                        Paragraph ($reportTranslate.InvokeAsBuiltReportVeeamVBR.ReplicationParagraph -f $VeeamBackupServer)
                        BlankLine
                        Get-AbrVbrReplInfraSummary
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelReplicationReplica -f $InfoLevel.Replication.Replica)
                        if ($InfoLevel.Replication.Replica -ge 1) {
                            Get-AbrVbrReplReplica
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelReplicationFailoverPlan -f $InfoLevel.Replication.FailoverPlan)
                        if ($InfoLevel.Replication.FailoverPlan -ge 1) {
                            Get-AbrVbrReplFailoverPlan
                        }
                    }
                }
            }
            #---------------------------------------------------------------------------------------------#
            #                                Cloud Connect Section                                        #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.CloudConnect.PSObject.Properties.Value -ne 0) {
                if ($VbrLicenses | Where-Object { $_.CloudConnect -ne 'Disabled' -and $_.Status -ne 'Expired' }) {
                    if ((Get-VBRCloudGateway).count -gt 0 -or ((Get-VBRCloudTenant).count -gt 0)) {
                        Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.CloudConnect {
                            Paragraph ($reportTranslate.InvokeAsBuiltReportVeeamVBR.CloudConnectParagraph -f $VeeamBackupServer)
                            BlankLine
                            if ($Options.EnableDiagrams) {
                                try {
                                    try {
                                        $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-CloudConnect' -DiagramOutput base64
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Cloud Connect Infrastructure Diagram: $($_.Exception.Message)"
                                    }
                                    if ($Graph) {
                                        $BestAspectRatio = Get-BestImageAspectRatio -GraphObj $Graph -MaxWidth 600 -MaxHeight 600
                                        PageBreak
                                        Section -Style Heading3 $reportTranslate.InvokeAsBuiltReportVeeamVBR.CloudConnectInfrastructureDiagram {
                                            Image -Base64 $Graph -Text 'Cloud Connect Infrastructure Diagram' -Width $BestAspectRatio.Width -Height $BestAspectRatio.Height -Align Center
                                            PageBreak
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Cloud Connect Infrastructure Diagram Section: $($_.Exception.Message)"
                                }
                            }
                            Get-AbrVbrCloudConnectSummary
                            Get-AbrVbrCloudConnectStatus
                            Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelCloudCertificate -f $InfoLevel.CloudConnect.Certificate)
                            if ($InfoLevel.CloudConnect.Certificate -ge 1) {
                                Get-AbrVbrCloudConnectCert
                            }
                            Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelCloudPublicIP -f $InfoLevel.CloudConnect.PublicIP)
                            if ($InfoLevel.CloudConnect.PublicIP -ge 1) {
                                Get-AbrVbrCloudConnectPublicIP
                            }
                            Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelCloudGateway -f $InfoLevel.CloudConnect.CloudGateway)
                            if ($InfoLevel.CloudConnect.CloudGateway -ge 1) {
                                Get-AbrVbrCloudConnectCG
                            }
                            Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelCloudGatewayPools -f $InfoLevel.CloudConnect.GatewayPools)
                            if ($InfoLevel.CloudConnect.GatewayPools -ge 1) {
                                Get-AbrVbrCloudConnectGP
                            }
                            Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelCloudTenants -f $InfoLevel.CloudConnect.Tenants)
                            if ($InfoLevel.CloudConnect.Tenants -ge 1) {
                                Get-AbrVbrCloudConnectTenant
                            }
                            Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelCloudBackupStorage -f $InfoLevel.CloudConnect.BackupStorage)
                            if ($InfoLevel.CloudConnect.BackupStorage -ge 1) {
                                Get-AbrVbrCloudConnectBS
                            }
                            Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelCloudReplicaResources -f $InfoLevel.CloudConnect.ReplicaResources)
                            if ($InfoLevel.CloudConnect.ReplicaResources -ge 1) {
                                Get-AbrVbrCloudConnectRR
                            }
                        }
                    }
                }
            }
            #---------------------------------------------------------------------------------------------#
            #                                  Backup Jobs Section                                        #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Jobs.PSObject.Properties.Value -ne 0) {
                if (((Get-VBRJob -WarningAction SilentlyContinue).count -gt 0) -or ((Get-VBRTapeJob).count -gt 0) -or ((Get-VBRSureBackupJob).count -gt 0)) {
                    Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.Jobs {
                        Paragraph ($reportTranslate.InvokeAsBuiltReportVeeamVBR.JobsParagraph -f $VeeamBackupServer)
                        BlankLine
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsBackup -f $InfoLevel.Jobs.Backup)
                        if ($InfoLevel.Jobs.Backup -ge 1) {
                            Get-AbrVbrBackupjob
                            Get-AbrVbrBackupjobVMware
                            Get-AbrVbrBackupjobHyperV
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsReplication -f $InfoLevel.Jobs.Replication)
                        if ($InfoLevel.Jobs.Replication -ge 1) {
                            Get-AbrVbrRepljob
                            Get-AbrVbrRepljobVMware
                            Get-AbrVbrRepljobHyperV
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsTape -f $InfoLevel.Jobs.Tape)
                        if ($InfoLevel.Jobs.Tape -ge 1) {
                            Get-AbrVbrTapejob
                            Get-AbrVbrBackupToTape
                            Get-AbrVbrFileToTape
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsSureBackup -f $InfoLevel.Jobs.SureBackup)
                        if ($InfoLevel.Jobs.SureBackup -ge 1) {
                            Get-AbrVbrSureBackupjob
                            Get-AbrVbrSureBackupjobconf
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsAgent -f $InfoLevel.Jobs.Agent)
                        if ($InfoLevel.Jobs.Agent -ge 1) {
                            Get-AbrVbrAgentBackupjob
                            Get-AbrVbrAgentBackupjobConf
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsFileShare -f $InfoLevel.Jobs.FileShare)
                        if ($InfoLevel.Jobs.FileShare -ge 1) {
                            Get-AbrVbrFileShareBackupjob
                            Get-AbrVbrFileShareBackupjobConf
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsEntraID -f $InfoLevel.Jobs.EntraID)
                        if ($InfoLevel.Jobs.EntraID -ge 1 -and ($VbrVersion -ge 12.3)) {
                            Get-AbrVbrEntraIDBackupjob
                            Get-AbrVbrEntraIDBackupjobConf
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsNutanix -f $InfoLevel.Jobs.Nutanix)
                        if ($InfoLevel.Jobs.Nutanix -ge 1 -and ($VbrVersion -ge 12)) {
                            Get-AbrVbrBackupjobNutanix
                            Get-AbrVbrBackupjobNutanixConf
                        }
                        Write-PScriboMessage ($reportTranslate.InvokeAsBuiltReportVeeamVBR.InfoLevelJobsBackupCopy -f $InfoLevel.Jobs.BackupCopy)
                        if ($InfoLevel.Jobs.BackupCopy -ge 1 -and ($VbrVersion -ge 12)) {
                            Get-AbrVbrBackupCopyjob
                            Get-AbrVbrBackupCopyjobConf
                        }
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                             Backup Restore Points Section                                   #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Jobs.Restores -gt 0) {
                if (((Get-VBRBackup -WarningAction SilentlyContinue).count -gt 0) -or ((Get-VBRTapeJob).count -gt 0) -or ((Get-VBRSureBackupJob).count -gt 0)) {
                    Section -Style Heading2 $reportTranslate.InvokeAsBuiltReportVeeamVBR.BackupRestorePoints {
                        Paragraph ($reportTranslate.InvokeAsBuiltReportVeeamVBR.BackupRestorePointsParagraph -f $VeeamBackupServer)
                        BlankLine
                        Get-AbrVbrBackupsRPSummary
                        Get-AbrVbrBackupJobsRP
                        Get-AbrVbrTapeBackupJobsRP
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                          Export Diagram Section                                             #
            #---------------------------------------------------------------------------------------------#

            if ($Options.ExportDiagrams) {
                Write-Host ' '
                Write-Host 'ExportDiagrams option enabled: Exporting diagrams:'
                $DiagramTypeHash = @{
                    'CloudConnect' = 'Backup-to-CloudConnect'
                    'CloudConnectTenant' = 'Backup-to-CloudConnect-Tenant'
                    'Infrastructure' = 'Backup-Infrastructure'
                    'FileProxy' = 'Backup-to-File-Proxy'
                    'HyperVProxy' = 'Backup-to-HyperV-Proxy'
                    'ProtectedGroup' = 'Backup-to-ProtectedGroup'
                    'Repository' = 'Backup-to-Repository'
                    'Sobr' = 'Backup-to-Sobr'
                    'Tape' = 'Backup-to-Tape'
                    'vSphereProxy' = 'Backup-to-vSphere-Proxy'
                    'WanAccelerator' = 'Backup-to-WanAccelerator'
                }
                $Options.DiagramType.PSobject.Properties | ForEach-Object {
                    try {
                        if ($_.Value) {
                            if ($DiagramTypeHash[$_.Name] -eq 'Backup-to-CloudConnect-Tenant') {
                                $Tenants = Get-VBRCloudTenant | Select-Object -Property Name | Sort-Object
                                foreach ($Tenant in $Tenants.Name) {
                                    Get-AbrVbrDiagrammer -DiagramType $DiagramTypeHash[$_.Name] -Tenant $Tenant -Direction 'left-to-right'
                                }
                            } else {
                                Get-AbrVbrDiagrammer -DiagramType $DiagramTypeHash[$_.Name]
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Export Diagram $($_.Name) Error: $($_.Exception.Message)"
                    }
                }
                Write-Host ' '
            }
        }
    }
    #endregion foreach loop
}