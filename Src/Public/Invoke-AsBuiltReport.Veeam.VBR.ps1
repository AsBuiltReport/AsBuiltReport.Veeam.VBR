function Invoke-AsBuiltReport.Veeam.VBR {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VBR in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.4
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>

	# Do not remove or add to these parameters
    param (
        [String[]] $Target,
        [PSCredential] $Credential
    )

    Write-PScriboMessage -IsWarning "Please refer to the AsBuiltReport.Veeam.VBR github website for more detailed information about this project."
    Write-PScriboMessage -IsWarning "Do not forget to update your report configuration file after each new version release."
    Write-PScriboMessage -IsWarning "Documentation: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR"
    Write-PScriboMessage -IsWarning "Issues or bug reporting: https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR/issues"

    # Check the current AsBuiltReport.Veeam.VBR module
    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Veeam.VBR -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -IsWarning "AsBuiltReport.Veeam.VBR $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Veeam.VBR -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($LatestVersion -gt $InstalledVersion) {
                Write-PScriboMessage -IsWarning "AsBuiltReport.Veeam.VBR $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -IsWarning "Run 'Update-Module -Name AsBuiltReport.Veeam.VBR -Force' to install the latest version."
            }
        }
    } Catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }

    # Import Report Configuration
    $Report = $ReportConfig.Report
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

    #region foreach loop
    foreach ($System in $Target) {
        Get-AbrVbrRequiredModule -Name 'Veeam.Backup.PowerShell' -Version '1.0'
        Get-AbrVbrServerConnection
        $VeeamBackupServer = ((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0]
        $script:VbrLicenses = Get-VBRInstalledLicense
        Section -Style Heading1 $($VeeamBackupServer) {
            Paragraph "The following section provides an overview of the implemented components of Veeam Backup & Replication."
            BlankLine
            #---------------------------------------------------------------------------------------------#
            #                            Backup Infrastructure Section                                    #
            #---------------------------------------------------------------------------------------------#
            if ($InfoLevel.Infrastructure.PSObject.Properties.Value -ne 0) {
                Section -Style Heading2 'Backup Infrastructure' {
                    Paragraph "The following section details configuration information about the Backup Server: $($VeeamBackupServer)"
                    BlankLine
                    if ($InfoLevel.Infrastructure.BackupServer -ge 1) {
                        Get-AbrVbrInfrastructureSummary
                        Get-AbrVbrSecurityCompliance
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
                            Get-AbrVbrIOControlSetting
                            Get-AbrVbrBackupServerCertificate
                            Get-AbrVbrNetworkTrafficRule
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
                            Try {
                                $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-WanAccelerator"
                            } Catch {
                                Write-PscriboMessage -IsWarning "Wan Accelerator Diagram: $($_.Exception.Message)"
                            }
                            if ($Graph) {
                                PageBreak
                                Section -Style Heading3 "Wan Accelerator Diagram." {
                                    Image -Base64 $Graph -Text "Wan Accelerator Diagram" -Percent 20 -Align Center
                                    Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                }
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
                            Try {
                                $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-Repository"
                            } Catch {
                                Write-PscriboMessage -IsWarning "Backup Repository Diagram: $($_.Exception.Message)"
                            }
                            if ($Graph) {
                                PageBreak
                                Section -Style Heading3 "Backup Repository Diagram." {
                                    Image -Base64 $Graph -Text "Backup Repository Diagram" -Percent 20 -Align Center
                                    Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                }
                            }
                        }
                    }
                    Write-PScriboMessage "Infrastructure ScaleOut Backup Repository InfoLevel set at $($InfoLevel.Infrastructure.SOBR)."
                    if ($InfoLevel.Infrastructure.SOBR -ge 1) {
                        Get-AbrVbrScaleOutRepository
                        if ($Options.EnableDiagrams -and (Get-VBRBackupRepository -ScaleOut)) {
                            Try {
                                $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-Sobr"
                            } Catch {
                                Write-PscriboMessage -IsWarning "ScaleOut Backup Repository Diagram: $($_.Exception.Message)"
                            }
                            if ($Graph) {
                                PageBreak
                                Section -Style Heading3 "ScaleOut Backup Repository Diagram." {
                                    Image -Base64 $Graph -Text "ScaleOut Backup Repository Diagram" -Percent 20 -Align Center
                                    Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                }
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
                        Paragraph "The following section details Tape Infrastructure configuration information"
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
                            Try {
                                $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-Tape"
                            } Catch {
                                Write-PscriboMessage -IsWarning "Tape Infrastructure Diagram: $($_.Exception.Message)"
                            }
                            if ($Graph) {
                                PageBreak
                                Section -Style Heading3 "Tape Infrastructure Diagram." {
                                    Image -Base64 $Graph -Text "Tape Infrastructure Diagram" -Percent 20 -Align Center
                                    Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                }
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
                        Paragraph "The following section provides inventory information about the Virtual Infrastructure managed by Veeam Server $(((Get-VBRServerSession).Server))."
                        BlankLine
                        Get-AbrVbrInventorySummary
                        Write-PScriboMessage "Virtual Inventory InfoLevel set at $($InfoLevel.Inventory.VI)."
                        if ($InfoLevel.Inventory.VI -ge 1) {
                            Get-AbrVbrVirtualInfrastructure
                        }
                        Write-PScriboMessage "Physical Inventory InfoLevel set at $($InfoLevel.Inventory.PHY)."
                        if ($InfoLevel.Inventory.PHY -ge 1) {
                            Get-AbrVbrPhysicalInfrastructure

                        }
                        Write-PScriboMessage "File Shares Inventory InfoLevel set at $($InfoLevel.Inventory.FileShare)."
                        if ($InfoLevel.Inventory.FileShare -ge 1) {
                            if ($VbrVersion -lt 12.1) {
                                Get-AbrVbrFileSharesInfo
                            } else {
                                Get-AbrVbrUnstructuredDataInfo
                            }
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
                        Paragraph "The following section provides information about the storage infrastructure managed by Veeam Server $(((Get-VBRServerSession).Server))."
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
                if ((Get-VBRReplica).count -gt 0 -or ((Get-VBRFailoverPlan).count -gt 0))  {
                    Section -Style Heading2 'Replication' {
                        Paragraph "The following section provides information about the replications managed by Veeam Server $(((Get-VBRServerSession).Server))."
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
                if ($VbrLicenses | Where-Object {$_.CloudConnect -ne "Disabled" -and $_.Status -ne "Expired"}) {
                    if ((Get-VBRCloudGateway).count -gt 0 -or ((Get-VBRCloudTenant).count -gt 0))  {
                        Section -Style Heading2 'Cloud Connect' {
                            Paragraph "The following section provides information about Cloud Connect components from server $(((Get-VBRServerSession).Server))."
                            BlankLine
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
                        Paragraph "The following section provides information about the configured jobs in Veeam Server: $(((Get-VBRServerSession).Server))."
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
                        Write-PScriboMessage "Backup Copy Jobs InfoLevel set at $($InfoLevel.Jobs.BackupCopy)."
                        if ($InfoLevel.Jobs.BackupCopy -ge 1 -and ((Get-Item "C:\Program Files\Veeam\Backup and Replication\Console\Veeam.Backup.PowerShell.dll").VersionInfo.ProductVersion -ge 12)) {
                            Get-AbrVbrBackupCopyjob
                            Get-AbrVbrBackupCopyjobConf
                        }
                    }
                }
            }
        }
        #Disconnect-VBRServer
	}
	#endregion foreach loop
}
