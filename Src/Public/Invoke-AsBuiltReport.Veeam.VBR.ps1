function Invoke-AsBuiltReport.Veeam.VBR {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VBR in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.12
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

    # Import Report Configuration
    $script:Report = $ReportConfig.Report
    $script:InfoLevel = $ReportConfig.InfoLevel
    $script:Options = $ReportConfig.Options

    $script:RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

    $MainTranslate = Get-AsBuiltTranslation -Product "Main" -Category "Message"

    #Requires -Version 5.1
    #Requires -PSEdition Desktop
    #Requires -RunAsAdministrator
    #Requires -Modules @{ ModuleName="Veeam.Backup.PowerShell"; MaximumVersion="12.2.0.334" }

    if ($psISE) {
        Write-Error -Message "You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window."
        break
    }

    Write-PScriboMessage -Plugin "Module" -IsWarning $MainTranslate.MessageURL
    Write-PScriboMessage -Plugin "Module" -IsWarning $MainTranslate.MessageUpdate
    Write-PScriboMessage -Plugin "Module" -IsWarning $MainTranslate.MessageDocumentation
    Write-PScriboMessage -Plugin "Module" -IsWarning $MainTranslate.MessageIssues
    Write-PScriboMessage -Plugin "Module" -IsWarning $MainTranslate.MessageAffiliates


    # Check the current AsBuiltReport.Veeam.VBR module
    Try {
        $InstalledVersion = Get-Module -ListAvailable -Name AsBuiltReport.Veeam.VBR -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

        if ($InstalledVersion) {
            Write-PScriboMessage -Plugin "Module" -IsWarning "AsBuiltReport.Veeam.VBR $($InstalledVersion.ToString()) is currently installed."
            $LatestVersion = Find-Module -Name AsBuiltReport.Veeam.VBR -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
            if ($InstalledVersion -lt $LatestVersion) {
                Write-PScriboMessage -Plugin "Module" -IsWarning "AsBuiltReport.Veeam.VBR $($LatestVersion.ToString()) is available."
                Write-PScriboMessage -Plugin "Module" -IsWarning "Run 'Update-Module -Name AsBuiltReport.Veeam.VBR -Force' to install the latest version."
            }
        }
    } Catch {
        Write-PScriboMessage -IsWarning $_.Exception.Message
    }

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

    # Set default theme styles
    if (-Not $Options.DiagramTheme) {
        $DiagramTheme = 'White'
    } else {
        $DiagramTheme = $Options.DiagramTheme
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
                        # Get-AbrVbrInfrastructureSummary
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
                            Try {
                                Try {
                                    $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-WanAccelerator" -DiagramTheme $DiagramTheme
                                } Catch {
                                    Write-PScriboMessage -IsWarning "Wan Accelerator Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    If ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 1500) { $ImagePrty = 15 } else { $ImagePrty = 50 }
                                    Section -Style Heading3 "Wan Accelerator Diagram." {
                                        Image -Base64 $Graph -Text "Wan Accelerator Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
                                }
                            } Catch {
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
                            Try {
                                Try {
                                    $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-Repository" -DiagramTheme $DiagramTheme
                                } Catch {
                                    Write-PScriboMessage -IsWarning "Backup Repository Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    If ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 1500) { $ImagePrty = 15 } else { $ImagePrty = 50 }
                                    Section -Style Heading3 "Backup Repository Diagram" {
                                        Image -Base64 $Graph -Text "Backup Repository Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
                                }
                            } Catch {
                                Write-PScriboMessage -IsWarning "Backup Repository Diagram Section: $($_.Exception.Message)"
                            }
                        }
                    }
                    Write-PScriboMessage "Infrastructure ScaleOut Backup Repository InfoLevel set at $($InfoLevel.Infrastructure.SOBR)."
                    if ($InfoLevel.Infrastructure.SOBR -ge 1) {
                        Get-AbrVbrScaleOutRepository
                        if ($Options.EnableDiagrams -and (Get-VBRBackupRepository -ScaleOut)) {
                            Try {
                                Try {
                                    $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-Sobr" -DiagramTheme $DiagramTheme
                                } Catch {
                                    Write-PScriboMessage -IsWarning "ScaleOut Backup Repository Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    If ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 1500) { $ImagePrty = 15 } else { $ImagePrty = 50 }
                                    Section -Style Heading3 "ScaleOut Backup Repository Diagram." {
                                        Image -Base64 $Graph -Text "ScaleOut Backup Repository Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
                                }
                            } Catch {
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
                                Try {
                                    $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-Tape" -DiagramTheme $DiagramTheme
                                } Catch {
                                    Write-PScriboMessage -IsWarning "Tape Infrastructure Diagram: $($_.Exception.Message)"
                                }
                                if ($Graph) {
                                    If ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 1500) { $ImagePrty = 15 } else { $ImagePrty = 50 }
                                    Section -Style Heading3 "Tape Infrastructure Diagram." {
                                        Image -Base64 $Graph -Text "Tape Infrastructure Diagram" -Percent $ImagePrty -Align Center
                                        Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                    }
                                    BlankLine
                                }
                            } Catch {
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
                        Paragraph "The following section provides inventory information about the Virtual Infrastructure managed by Veeam Server $(((Get-VBRServerSession).Server))."
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
                                Try {
                                    Try {
                                        $Graph = New-VeeamDiagram -Target $System -Credential $Credential -Format base64 -Direction top-to-bottom -DiagramType "Backup-to-ProtectedGroup" -DiagramTheme $DiagramTheme
                                    } Catch {
                                        Write-PScriboMessage -IsWarning "Physical Infrastructure Diagram: $($_.Exception.Message)"
                                    }
                                    if ($Graph) {
                                        If ((Get-DiaImagePercent -GraphObj $Graph).Width -gt 1500) { $ImagePrty = 15 } else { $ImagePrty = 50 }
                                        Section -Style Heading3 "Physical Infrastructure Diagram." {
                                            Image -Base64 $Graph -Text "Physical Infrastructure Diagram" -Percent $ImagePrty -Align Center
                                            Paragraph "Image preview: Opens the image in a new tab to view it at full resolution." -Tabs 2
                                        }
                                        BlankLine
                                    }
                                } Catch {
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
                if ((Get-VBRReplica).count -gt 0 -or ((Get-VBRFailoverPlan).count -gt 0)) {
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
                if ($VbrLicenses | Where-Object { $_.CloudConnect -ne "Disabled" -and $_.Status -ne "Expired" }) {
                    if ((Get-VBRCloudGateway).count -gt 0 -or ((Get-VBRCloudTenant).count -gt 0)) {
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
                        Paragraph "The following section provides information about the jobs restore points in Veeam Server: $(((Get-VBRServerSession).Server))."
                        BlankLine
                        Get-AbrVbrBackupsRPSummary
                        Get-AbrVbrBackupJobsRP
                        Get-AbrVbrTapeBackupJobsRP
                    }
                }
            }

            #---------------------------------------------------------------------------------------------#
            #                          Backup Infrastructure Diagram Section                              #
            #---------------------------------------------------------------------------------------------#

            if (-Not $Options.ExportDiagramsFormat) {
                $DiagramFormat = 'png'
            } else {
                $DiagramFormat = $Options.ExportDiagramsFormat
            }
            $DiagramParams = @{
                'OutputFolderPath' = (Get-Location).Path
                'Credential' = $Credential
                'Target' = $System
                'Direction' = 'top-to-bottom'
                'DiagramType' = 'Backup-Infrastructure'
                'WaterMarkText' = $Options.DiagramWaterMark
                'WaterMarkColor' = 'DarkGreen'
                'DiagramTheme' = $DiagramTheme
            }

            if ($Options.EnableDiagramDebug) {
                $DiagramParams.Add('EnableEdgeDebug', $True)
                $DiagramParams.Add('EnableSubGraphDebug', $True)
            }

            if ($Options.EnableDiagramSignature) {
                $DiagramParams.Add('Signature', $True)
                $DiagramParams.Add('AuthorName', $Options.SignatureAuthorName)
                $DiagramParams.Add('CompanyName', $Options.SignatureCompanyName)
            }

            try {
                foreach ($Format in $DiagramFormat) {
                    $Graph = New-VeeamDiagram @DiagramParams -Format $Format -Filename "AsBuiltReport.Veeam.VBR.$($Format)"
                    if ($Graph) {
                        Write-Information "Saved 'AsBuiltReport.Veeam.VBR.$($Format)' diagram to '$((Get-Location).Path)\'." -InformationAction Continue
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "Unable to export the Infrastructure Diagram: $($_.Exception.Message)"
            }
        }
        if ((Get-VBRServerSession).Server) {
            Write-PScriboMessage "Disconecting section from $((Get-VBRServerSession).Server)"
            # Disconnect-VBRServer
        }
    }
    #endregion foreach loop
}