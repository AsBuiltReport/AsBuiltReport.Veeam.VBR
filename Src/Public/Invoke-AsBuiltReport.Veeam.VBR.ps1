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
                if ($InfoLevel.Infrastructure.WANAccel -ge 1) {
                    Get-AbrVbrInstalledLicense
                }
                if ($InfoLevel.Infrastructure.Proxy -ge 1) {
                    Get-AbrVbrBackupProxy
                }
                if ($InfoLevel.Infrastructure.WANAccel -ge 1) {
                    Get-AbrVbrWANAccelerator
                }
                if ($InfoLevel.Infrastructure.SureBackup -ge 1) {
                    Get-AbrVbrSureBackup
                }
                Get-AbrVbrBackupRepository
                Get-AbrVbrScaleOutRepository
            }
        }
	}
	#endregion foreach loop
}
