function Invoke-AsBuiltReport.Veeam.VBR {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VBR in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.23
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "", Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope = "Function")]

    # Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    #Requires -Version 5.1
    #Requires -PSEdition Desktop
    #Requires -RunAsAdministrator

    if ($psISE) {
        Write-Error -Message "You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window."
        break
    }

    Get-AbrVbrRequiredModule -Name 'Veeam.Backup.PowerShell' -Version '1.0'

    Write-Host "- Please refer to the AsBuiltReport.Veeam.VBR github website for more detailed information about this project."
    Write-Host "- Do not forget to update your report configuration file after each new version release."
    Write-Host "- Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR"
    Write-Host "- Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues"
    Write-Host "- This project is community maintained and has no sponsorship from Veeam, its employees or any of its affiliates."


    # Check the version of the dependency modules
    $ModuleArray = @('AsBuiltReport.Veeam.VBR', 'Veeam.Diagrammer', 'Diagrammer.Core')

    foreach ($Module in $ModuleArray) {
        try {
            $InstalledVersion = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

            if ($InstalledVersion) {
                Write-Host "- $Module module v$($InstalledVersion.ToString()) is currently installed."
                $LatestVersion = Find-Module -Name $Module -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
                if ($InstalledVersion -lt $LatestVersion) {
                    Write-Host "  - $Module module v$($LatestVersion.ToString()) is available." -ForegroundColor Red
                    Write-Host "  - Run 'Update-Module -Name $Module -Force' to install the latest version." -ForegroundColor Red
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning $_.Exception.Message
        }
    }

    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options

    # Set Custom styles for Veeam theme template
    if ($Options.ReportStyle -eq "Veeam") {
        & "$PSScriptRoot\..\..\AsBuiltReport.Veeam.VBR.Style.ps1"
        $Legend = {
            Text 'Enabled \' -Color 81BC50 -Bold
            Text ' Disabled' -Color dddf62 -Bold
        }
    } else {
        # Set Custom styles for Default AsBuiltReport template
        Style -Name 'ON' -Size 8 -BackgroundColor '4c7995' -Color 4c7995
        Style -Name 'OFF' -Size 8 -BackgroundColor 'ADDBDB' -Color ADDBDB
        $Legend = {
            Text 'Enabled \' -Color 4c7995 -Bold
            Text ' Disabled' -Color ADDBDB -Bold
        }
    }

    # Used to set values to TitleCase where required
    $script:TextInfo = (Get-Culture).TextInfo

    # Identify installed Veeam module version
    $script:VbrVersion = (Get-Module -ListAvailable -Name Veeam.Backup.PowerShell).Version.ToString()

    #region foreach loop
    foreach ($System in $Target) {
        if (Select-String -InputObject $System -Pattern "^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$") {
            throw "Please use the FQDN instead of an IP address to connect to the Backup Server: $System"
        }
        Get-AbrVbrServerConnection
        $VeeamBackupServer = ((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0]
        $script:VbrLicenses = Get-VBRInstalledLicense

        Section -Style Heading1 $($VeeamBackupServer) -Orientation Portrait {
            Paragraph "This section provides an overview of the key components implemented in Veeam Backup & Replication."
            BlankLine

            if ($Options.EnableDiagrams) {
                try {
                    try {
                        $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-Infrastructure' -DiagramOutput base64
                    } catch {
                        Write-PScriboMessage -IsWarning "Backup Infrastructure Diagram: $($_.Exception.Message)"
                    }
                    if ($Graph) {
                        if ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 600) { $ImagePrty = 5 } else { $ImagePrty = 10 }
                        Section -Style Heading2 "Backup Infrastructure Diagram." {
                            Image -Base64 $Graph -Text "Backup Infrastructure Diagram" -Align Center -Percent $ImagePrty
                            Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Backup Infrastructure Diagram Section: $($_.Exception.Message)"
                }
            }
            #---------------------------------------------------------------------------------------------#
            #                            Backup Infrastructure Section                                    #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Infrastructure.PSObject.Properties.Value -ne 0) {
                Section -Style Heading2 'Backup Infrastructure' {
                    Paragraph "This section provides detailed configuration information for the Backup Server: $($VeeamBackupServer)."
                    BlankLine
                    if ($InfoLevel.Infrastructure.BackupServer -ge 1) {
                        Get-AbrVbrInfrastructureSummary
                        if ($VbrVersion -ge 12) {
                            Get-AbrVbrSecurityCompliance
                        }
                        Get-AbrVbrBackupServerInfo
                        Get-AbrVbrEnterpriseManagerInfo
                    }
                    Write-PScriboMessage "Infrastructure Licenses InfoLevel set at $($InfoLevel.Infrastructure.Licenses)."
                    if ($InfoLevel.Infrastructure.Licenses -ge 1) {
                        Get-AbrVbrInstalledLicense
                    }
                    Write-PScriboMessage "Infrastructure Settings InfoLevel set at $($InfoLevel.Infrastructure.Settings)."
                    if ($InfoLevel.Infrastructure.Settings -ge 1) {
                        Section -Style Heading3 'General Options' {
                            Paragraph "The following section details Veaam Backup & Replication general setting. General settings are applied to all jobs, backup infrastructure components and other objects managed by the backup server."
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

                    Write-PScriboMessage "Infrastructure Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                    if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                        Get-AbrVbrBackupProxy
                    }
                    Write-PScriboMessage "Infrastructure WAN Accelerator InfoLevel set at $($InfoLevel.Infrastructure.WANAccel)."
                    if ($InfoLevel.Infrastructure.WANAccel -ge 1) {
                        Get-AbrVbrWANAccelerator
                        if ($Options.EnableDiagrams -and ((Get-VBRWANAccelerator).count -gt 0)) {
                            try {
                                try {
                                    $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-WanAccelerator' -DiagramOutput base64
                                } catch {
                                    Write-PScriboMessage -IsWarning "Wan Accelerator Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    if ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 600) { $ImagePrty = 20 } else { $ImagePrty = 30 }
                                    Section -Style Heading3 "Wan Accelerator Diagram." {
                                        Image -Base64 $Graph -Text "Wan Accelerator Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Wan Accelerator Diagram Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    Write-PScriboMessage "Infrastructure Service Provider InfoLevel set at $($InfoLevel.Infrastructure.ServiceProvider)."
                    if ($InfoLevel.Infrastructure.ServiceProvider -ge 1) {
                        Get-AbrVbrServiceProvider
                    }
                    Write-PScriboMessage "Infrastructure Backup Repository InfoLevel set at $($InfoLevel.Infrastructure.BR)."
                    if ($InfoLevel.Infrastructure.BR -ge 1) {
                        Get-AbrVbrBackupRepository
                        Get-AbrVbrObjectRepository
                        if ($Options.EnableDiagrams) {
                            try {
                                try {
                                    $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-Repository' -DiagramOutput base64
                                } catch {
                                    Write-PScriboMessage -IsWarning "Backup Repository Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    if ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 600) { $ImagePrty = 20 } else { $ImagePrty = 30 }
                                    Section -Style Heading3 "Backup Repository Diagram" {
                                        Image -Base64 $Graph -Text "Backup Repository Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Backup Repository Diagram Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    Write-PScriboMessage "Infrastructure ScaleOut Backup Repository InfoLevel set at $($InfoLevel.Infrastructure.SOBR)."
                    if ($InfoLevel.Infrastructure.SOBR -ge 1) {
                        Get-AbrVbrScaleOutRepository
                        if ($Options.EnableDiagrams -and (Get-VBRBackupRepository -ScaleOut)) {
                            try {
                                try {
                                    $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-Sobr' -DiagramOutput base64
                                } catch {
                                    Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    if ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 600) { $ImagePrty = 20 } else { $ImagePrty = 30 }
                                    Section -Style Heading3 "ScaleOut Backup Repository Diagram." {
                                        Image -Base64 $Graph -Text "ScaleOut Backup Repository Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Diagram Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    Write-PScriboMessage "Infrastructure SureBackup InfoLevel set at $($InfoLevel.Infrastructure.SureBackup)."
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
                    Section -Style Heading2 'Tape Infrastructure' {
                        Paragraph "This section provides detailed configuration information for the Tape Infrastructure."
                        BlankLine
                        Get-AbrVbrTapeInfraSummary
                        Write-PScriboMessage "Tape Server InfoLevel set at $($InfoLevel.Tape.Server)."
                        if ($InfoLevel.Tape.Server -ge 1) {
                            Get-AbrVbrTapeServer
                        }
                        Write-PScriboMessage "Tape Library InfoLevel set at $($InfoLevel.Tape.Library)."
                        if ($InfoLevel.Tape.Library -ge 1) {
                            Get-AbrVbrTapeLibrary
                        }
                        Write-PScriboMessage "Tape MediaPool InfoLevel set at $($InfoLevel.Tape.MediaPool)."
                        if ($InfoLevel.Tape.MediaPool -ge 1) {
                            Get-AbrVbrTapeMediaPool
                        }
                        Write-PScriboMessage "Tape Vault InfoLevel set at $($InfoLevel.Tape.Vault)."
                        if ($InfoLevel.Tape.Vault -ge 1) {
                            Get-AbrVbrTapeVault
                        }
                        Write-PScriboMessage "Tape NDMP InfoLevel set at $($InfoLevel.Tape.NDMP)."
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
                                    if ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 600) { $ImagePrty = 20 } else { $ImagePrty = 30 }
                                    Section -Style Heading3 "Tape Infrastructure Diagram." {
                                        Image -Base64 $Graph -Text "Tape Infrastructure Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
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
                    Section -Style Heading2 'Inventory' {
                        Paragraph "This section provides detailed inventory information about the virtual infrastructure managed by Veeam Backup Server $VeeamBackupServer."
                        BlankLine
                        Get-AbrVbrInventorySummary
                        Write-PScriboMessage "Virtual Inventory InfoLevel set at $($InfoLevel.Inventory.VI)."
                        if ($InfoLevel.Inventory.VI -ge 1) {
                            Get-AbrVbrVirtualInfrastructure
                        }
                        Write-PScriboMessage "Physical Inventory InfoLevel set at $($InfoLevel.Inventory.PHY)."
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
                                        if ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 600) { $ImagePrty = 10 } else { $ImagePrty = 20 }
                                        Section -Style Heading3 "Physical Infrastructure Diagram." {
                                            Image -Base64 $Graph -Text "Physical Infrastructure Diagram" -Percent $ImagePrty -Align Center
                                            Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                        }
                                        BlankLine
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Physical Infrastructure Diagram Section: $($_.Exception.Message)"
                                }
                            }
                        }
                        Write-PScriboMessage "File Shares Inventory InfoLevel set at $($InfoLevel.Inventory.FileShare)."
                        if ($InfoLevel.Inventory.FileShare -ge 1) {
                            if ($VbrVersion -lt 12.1) {
                                Get-AbrVbrFileSharesInfo
                            } else {
                                Get-AbrVbrUnstructuredDataInfo
                            }
                        }
                        Write-PScriboMessage "EntraID Inventory InfoLevel set at $($InfoLevel.Inventory.EntraID)."
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
                    Section -Style Heading2 'Storage Infrastructure' {
                        Paragraph "This section provides detailed information about the storage infrastructure components managed by Veeam Backup Server $VeeamBackupServer."
                        BlankLine
                        Get-AbrVbrStorageInfraSummary
                        Write-PScriboMessage "NetApp Ontap InfoLevel set at $($InfoLevel.Storage.Ontap)."
                        if ($InfoLevel.Storage.Ontap -ge 1) {
                            Get-AbrVbrStorageOntap
                        }
                        Write-PScriboMessage "Dell Isilon InfoLevel set at $($InfoLevel.Storage.Isilon)."
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
                    Section -Style Heading2 'Replication' {
                        Paragraph "This section provides detailed information about the replication jobs and failover plans managed by Veeam Backup Server $VeeamBackupServer."
                        BlankLine
                        Get-AbrVbrReplInfraSummary
                        Write-PScriboMessage "Replica InfoLevel set at $($InfoLevel.Replication.Replica)."
                        if ($InfoLevel.Replication.Replica -ge 1) {
                            Get-AbrVbrReplReplica
                        }
                        Write-PScriboMessage "Failover Plan InfoLevel set at $($InfoLevel.Replication.FailoverPlan)."
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
                if ($VbrLicenses | Where-Object { $_.CloudConnect -ne "Disabled" -and $_.Status -ne "Expired" }) {
                    if ((Get-VBRCloudGateway).count -gt 0 -or ((Get-VBRCloudTenant).count -gt 0)) {
                        Section -Style Heading2 'Cloud Connect' {
                            Paragraph "The following section provides information about Cloud Connect components from server $VeeamBackupServer."
                            BlankLine
                            if ($Options.EnableDiagrams) {
                                try {
                                    try {
                                        $Graph = Get-AbrVbrDiagrammer -DiagramType 'Backup-to-CloudConnect' -DiagramOutput base64
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Cloud Connect Infrastructure Diagram: $($_.Exception.Message)"
                                    }
                                    if ($Graph) {
                                        if ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 600) { $ImagePrty = 10 } else { $ImagePrty = 20 }
                                        Section -Style Heading3 "Cloud Connect Infrastructure Diagram." {
                                            Image -Base64 $Graph -Text "Cloud Connect Infrastructure Diagram" -Percent $ImagePrty -Align Center
                                            Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                        }
                                        BlankLine
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Cloud Connect Infrastructure Diagram Section: $($_.Exception.Message)"
                                }
                            }
                            Get-AbrVbrCloudConnectSummary
                            Get-AbrVbrCloudConnectStatus
                            Write-PScriboMessage "Cloud Certificate InfoLevel set at $($InfoLevel.CloudConnect.Certificate)."
                            if ($InfoLevel.CloudConnect.Certificate -ge 1) {
                                Get-AbrVbrCloudConnectCert
                            }
                            Write-PScriboMessage "Cloud Public IP InfoLevel set at $($InfoLevel.CloudConnect.PublicIP)."
                            if ($InfoLevel.CloudConnect.PublicIP -ge 1) {
                                Get-AbrVbrCloudConnectPublicIP
                            }
                            Write-PScriboMessage "Cloud Gateway InfoLevel set at $($InfoLevel.CloudConnect.CloudGateway)."
                            if ($InfoLevel.CloudConnect.CloudGateway -ge 1) {
                                Get-AbrVbrCloudConnectCG
                            }
                            Write-PScriboMessage "Gateway Pools InfoLevel set at $($InfoLevel.CloudConnect.GatewayPools)."
                            if ($InfoLevel.CloudConnect.GatewayPools -ge 1) {
                                Get-AbrVbrCloudConnectGP
                            }
                            Write-PScriboMessage "Tenants InfoLevel set at $($InfoLevel.CloudConnect.Tenants)."
                            if ($InfoLevel.CloudConnect.Tenants -ge 1) {
                                Get-AbrVbrCloudConnectTenant
                            }
                            Write-PScriboMessage "Backup Storage InfoLevel set at $($InfoLevel.CloudConnect.BackupStorage)."
                            if ($InfoLevel.CloudConnect.BackupStorage -ge 1) {
                                Get-AbrVbrCloudConnectBS
                            }
                            Write-PScriboMessage "Backup Storage InfoLevel set at $($InfoLevel.CloudConnect.ReplicaResources)."
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
                    Section -Style Heading2 'Jobs Summary' {
                        Paragraph "This section details all configured jobs in Veeam Backup & Replication on server $VeeamBackupServer."
                        BlankLine
                        Write-PScriboMessage "Backup Jobs InfoLevel set at $($InfoLevel.Jobs.Backup)."
                        if ($InfoLevel.Jobs.Backup -ge 1) {
                            Get-AbrVbrBackupjob
                            Get-AbrVbrBackupjobVMware
                            Get-AbrVbrBackupjobHyperV
                        }
                        Write-PScriboMessage "Replication Jobs InfoLevel set at $($InfoLevel.Jobs.Replication)."
                        if ($InfoLevel.Jobs.Replication -ge 1) {
                            Get-AbrVbrRepljob
                            Get-AbrVbrRepljobVMware
                            Get-AbrVbrRepljobHyperV
                        }
                        Write-PScriboMessage "Tape Jobs InfoLevel set at $($InfoLevel.Jobs.Tape)."
                        if ($InfoLevel.Jobs.Tape -ge 1) {
                            Get-AbrVbrTapejob
                            Get-AbrVbrBackupToTape
                            Get-AbrVbrFileToTape
                        }
                        Write-PScriboMessage "SureBackup Jobs InfoLevel set at $($InfoLevel.Jobs.SureBackup)."
                        if ($InfoLevel.Jobs.SureBackup -ge 1) {
                            Get-AbrVbrSureBackupjob
                            Get-AbrVbrSureBackupjobconf
                        }
                        Write-PScriboMessage "Agent Jobs InfoLevel set at $($InfoLevel.Jobs.Agent)."
                        if ($InfoLevel.Jobs.Agent -ge 1) {
                            Get-AbrVbrAgentBackupjob
                            Get-AbrVbrAgentBackupjobConf
                        }
                        Write-PScriboMessage "File Share Jobs InfoLevel set at $($InfoLevel.Jobs.FileShare)."
                        if ($InfoLevel.Jobs.FileShare -ge 1) {
                            Get-AbrVbrFileShareBackupjob
                            Get-AbrVbrFileShareBackupjobConf
                        }
                        Write-PScriboMessage "Entra ID Jobs InfoLevel set at $($InfoLevel.Jobs.EntraID)."
                        if ($InfoLevel.Jobs.EntraID -ge 1 -and ($VbrVersion -ge 12.3)) {
                            Get-AbrVbrEntraIDBackupjob
                            Get-AbrVbrEntraIDBackupjobConf
                        }
                        Write-PScriboMessage "Nutanix Jobs InfoLevel set at $($InfoLevel.Jobs.Nutanix)."
                        if ($InfoLevel.Jobs.Nutanix -ge 1 -and ($VbrVersion -ge 12)) {
                            Get-AbrVbrBackupjobNutanix
                            Get-AbrVbrBackupjobNutanixConf
                        }
                        Write-PScriboMessage "Backup Copy Jobs InfoLevel set at $($InfoLevel.Jobs.BackupCopy)."
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
                    Section -Style Heading2 'Backups Summary' {
                        Paragraph "The following section provides information about the jobs restore points in Veeam Server: $VeeamBackupServer."
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
                Write-Host " "
                Write-Host "ExportDiagrams option enabled: Exporting diagrams:"
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
                Write-Host " "
            }
        }

        if ((Get-VBRServerSession).Server) {
            Write-PScriboMessage "Disconecting section from $((Get-VBRServerSession).Server)"
            # Disconnect-VBRServer
        }
    }
    #endregion foreach loop
}