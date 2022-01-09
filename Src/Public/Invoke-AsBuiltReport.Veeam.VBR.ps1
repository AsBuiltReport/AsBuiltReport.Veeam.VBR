function Invoke-AsBuiltReport.Veeam.VBR {
    <#
    .SYNOPSIS
        PowerShell script to document the configuration of Veeam VBR in Word/HTML/Text formats
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.1.0
        Author:         Tim Carman
        Twitter:
        Github:
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
    $Report = $ReportConfig.Report
    $InfoLevel = $ReportConfig.InfoLevel
    $Options = $ReportConfig.Options

    # Used to set values to TitleCase where required
    $TextInfo = (Get-Culture).TextInfo

	# Update/rename the $System variable and build out your code within the ForEach loop. The ForEach loop enables AsBuiltReport to generate an as built configuration against multiple defined targets.

    #region foreach loop
    foreach ($System in $Target) {
        Get-AbrVbrRequiredModule -Name 'Veeam.Backup.PowerShell' -Version '1.0'
        Get-AbrVbrServerConnection
        Section -Style Heading1 'Implementation Report' {
            Paragraph "The following section provides a summary of the implemented components on the Veeam Backup & Replication Infrastructure"
            BlankLine
            #---------------------------------------------------------------------------------------------#
            #                            Backup Infrastructure Section                                    #
            #---------------------------------------------------------------------------------------------#
            Write-PScriboMessage "Backup Infrastructure InfoLevel set at $($InfoLevel.Infrastructure.Section)."
            if ($InfoLevel.Infrastructure.Section -ge 1) {
                Section -Style Heading2 'Backup Infrastructure Summary' {
                    Get-AbrVbrInfrastructureSummary
                    Get-AbrVbrBackupServerInfo
                    Write-PScriboMessage "Infrastructure Licenses InfoLevel set at $($InfoLevel.Infrastructure.Licenses)."
                    if ($InfoLevel.Infrastructure.Licenses -ge 1) {
                        Get-AbrVbrInstalledLicense
                    }
                    Write-PScriboMessage "Infrastructure Settings InfoLevel set at $($InfoLevel.Infrastructure.Settings)."
                    if ($InfoLevel.Infrastructure.Settings -ge 1) {
                        Section -Style Heading3 'General Options' {
                            Paragraph "The following section details the Veeam Veaam B&R general setting. General settings are applied to all jobs, backup infrastructure components and other objects managed by the backup server."
                            BlankLine
                            Get-AbrVbrEmailNotificationSetting
                            Get-AbrVbrIOControlSetting
                            Get-AbrVbrBackupServerCertificate
                            Get-AbrVbrNetworkTrafficRule
                        }
                    }
                    Get-AbrVbrUserRoleAssignment
                    Get-AbrVbrCredential
                    Get-AbrVbrLocation
                    Get-AbrVbrManagedServer
                    Write-PScriboMessage "Infrastructure Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                    if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                        Get-AbrVbrBackupProxy
                    }
                    Write-PScriboMessage "Infrastructure WAN Accelerator InfoLevel set at $($InfoLevel.Infrastructure.WANAccel)."
                    if ($InfoLevel.Infrastructure.WANAccel -ge 1) {
                        Get-AbrVbrWANAccelerator
                    }
                    Write-PScriboMessage "Infrastructure Backup Repository InfoLevel set at $($InfoLevel.Infrastructure.BR)."
                    if ($InfoLevel.Infrastructure.BR -ge 1) {
                        Get-AbrVbrBackupRepository
                        Get-AbrVbrObjectRepository
                    }
                    Write-PScriboMessage "Infrastructure ScaleOut Backup Repository InfoLevel set at $($InfoLevel.Infrastructure.SOBR)."
                    if ($InfoLevel.Infrastructure.SOBR -ge 1) {
                        Get-AbrVbrScaleOutRepository
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
            Write-PScriboMessage "Tape Infrastructure InfoLevel set at $($InfoLevel.Tape.Section)."
            if ($InfoLevel.Tape.Section -ge 1) {
                if ((Get-VBRTapeServer).count -gt 0) {
                    Section -Style Heading2 'Tape Infrastructure Summary' {
                        Write-PScriboMessage "Tape Server InfoLevel set at $($InfoLevel.Tape.Server)."
                        if ($InfoLevel.Tape.Server -ge 1) {
                            Get-AbrVbrTapeServer
                            if ($InfoLevel.Tape.Library -ge 1) {
                                Get-AbrVbrTapeLibrary
                            }
                            if ($InfoLevel.Tape.MediaPool -ge 1) {
                                Get-AbrVbrTapeMediaPool
                            }
                            if ($InfoLevel.Tape.Vault -ge 1) {
                                Get-AbrVbrTapeVault
                            }
                            if ($InfoLevel.Tape.NDMP -ge 1) {
                                Get-AbrVbrNDMPInfo
                            }
                        }
                    }
                }
            }

        }
        #Disconnect-VBRServer
	}
	#endregion foreach loop
}
