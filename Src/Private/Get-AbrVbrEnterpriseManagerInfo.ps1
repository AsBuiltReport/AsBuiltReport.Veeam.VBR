
function Get-AbrVbrEnterpriseManagerInfo {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Enterprise Manager Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Enterprise Manager information from $System."
    }

    process {
        try {
            if ((Get-VBRServer -Type Local).count -gt 0) {
                Section -Style Heading3 'Enterprise Manager Information' {
                    Paragraph "The following table details Enterprise Manager information from the local Veeam Backup Server"
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $BackupServers = Get-VBRServer -Type Local
                            foreach ($BackupServer in $BackupServers) {
                            Write-PscriboMessage "Collecting Enterprise Manager information from $($BackupServer.Name)."
                            $EMInfo = [Veeam.Backup.Core.SBackupOptions]::GetEnterpriseServerInfo()
                                if ($EMInfo) {
                                    $inObj = [ordered] @{
                                        'Server Name' = Switch ($EMInfo.ServerName) {
                                            $Null {'Not Connected'}
                                            default {$EMInfo.ServerName}
                                        }
                                        'Server URL' = Switch ($EMInfo.URL) {
                                            $Null {'Not Connected'}
                                            default {$EMInfo.URL}
                                        }
                                        'Skip License Push' = ConvertTo-TextYN $EMInfo.SkipLicensePush
                                        'Is Connected' = ConvertTo-TextYN $EMInfo.IsConnected
                                    }
                                }

                                $OutObj = [pscustomobject]$inobj

                                if ($OutObj) {

                                    $TableParams = @{
                                        Name = "Enterprise Manager - $($BackupServer.Name.Split(".")[0])"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}