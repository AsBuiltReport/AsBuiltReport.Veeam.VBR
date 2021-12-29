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
        Section -Style Heading1 'VEEAM Implementation Report' {
            Paragraph "The following section provides a summary of the components implemented on the Veeam Backup & Replication Service"
            BlankLine
            Section -Style Heading2 'Backup Infrastructure' {
                Paragraph "The following section provides a summary of the components implemented on the Veeam Backup Infrastructure"
                BlankLine
                Get-AbrVbrServerInfo
                Get-AbrVbrUserRoleAssignment
                Get-AbrVbrCredential
                Get-AbrVbrLocation
                Write-PScriboMessage "Infrastructure Licenses InfoLevel set at $($InfoLevel.Infrastructure.Licenses)."
                if ($InfoLevel.Infrastructure.Licenses -ge 1) {
                    Get-AbrVbrInstalledLicense
                }
                Write-PScriboMessage "Infrastructure Backup Proxy InfoLevel set at $($InfoLevel.Infrastructure.Proxy)."
                if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                    Get-AbrVbrBackupProxy
                }
                Write-PScriboMessage "Infrastructure WAN Accelerator InfoLevel set at $($InfoLevel.Infrastructure.WANAccel)."
                if ($InfoLevel.Infrastructure.WANAccel -ge 1) {
                    Get-AbrVbrWANAccelerator
                }
                Write-PScriboMessage "Infrastructure SureBackup InfoLevel set at $($InfoLevel.Infrastructure.SureBackup)."
                if ($InfoLevel.Infrastructure.SureBackup -ge 1) {
                    Get-AbrVbrSureBackup
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
            }
        }
        #Disconnect-VBRServer
	}
	#endregion foreach loop
}
