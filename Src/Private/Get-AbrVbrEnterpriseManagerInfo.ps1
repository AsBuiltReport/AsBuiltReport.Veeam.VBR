
function Get-AbrVbrEnterpriseManagerInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Enterprise Manager Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
                                $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication Default
                                try {
                                    $VeeamInfo = Invoke-Command -Session $PssSession -ErrorAction SilentlyContinue -ScriptBlock { Get-ItemProperty -Path 'HKLM:\SOFTWARE\Veeam\Veeam Backup and Replication' }
                                } catch {Write-PscriboMessage -IsWarning $_.Exception.Message}
                                Remove-PSSession -Session $PssSession
                                if ($VeeamInfo) {
                                    if ($VeeamInfo.SqlInstanceName) {
                                        $EMInfo = Invoke-Sqlcmd -ServerInstance "$($VeeamInfo.SqlServerName)\$($VeeamInfo.SqlInstanceName)" -query "select value from [$($VeeamInfo.SqlDatabaseName)].[dbo].[Options] where name = 'EnterpriseServerInfo'"
                                    }
                                    else {
                                        $EMInfo = Invoke-Sqlcmd -ServerInstance $VeeamInfo.SqlServerName -query "select value from [$($VeeamInfo.SqlDatabaseName)].[dbo].[Options] where name = 'EnterpriseServerInfo'"
                                    }

                                    if ($EMInfo) {
                                        $EnterpriseManager = $([xml]$EMInfo.value).EnterpriseServerInfo
                                        $inObj = [ordered] @{
                                            'Server Name' = $EnterpriseManager.ServerName
                                            'Server URL' = $EnterpriseManager.URL
                                            'Skip License Push' = ConvertTo-TextYN $EnterpriseManager.SkipLicensePush
                                            'Is Connected' = ConvertTo-TextYN $EnterpriseManager.IsConnected
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