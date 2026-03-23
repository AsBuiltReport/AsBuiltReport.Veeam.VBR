function Get-AbrVbrNDMPInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam NDMP Servers Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.24
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
        Write-PScriboMessage "Discovering Veeam VBR NDMP Servers information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'NDMP Servers'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.Edition -in @('EnterprisePlus', 'Enterprise') -and $_.Status -ne 'Expired' }) {
                if ($NDMPObjs = Get-VBRNDMPServer | Sort-Object -Property Name) {
                    Section -Style Heading3 'NDMP Servers' {
                        Paragraph 'The following section lists all NDMP servers added to the Veeam Backup & Replication infrastructure, including credentials, port, and assigned gateway server.'
                        BlankLine
                        $OutObj = @()
                        try {
                            foreach ($NDMPObj in $NDMPObjs) {
                                try {

                                    $inObj = [ordered] @{
                                        'Name' = $NDMPObj.Name
                                        'Credentials' = $NDMPObj.Credentials
                                        'Port' = $NDMPObj.Port
                                        'Gateway' = switch ($NDMPObj.SelectedGatewayId) {
                                            '00000000-0000-0000-0000-000000000000' { 'Automatic' }
                                            default { (Get-VBRServer | Where-Object { $_.Id -eq $NDMPObj.SelectedGatewayId }).Name }
                                        }
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "NDMP Servers $($NDMPObj.Name) Section: $($_.Exception.Message)"
                                }
                            }

                            $TableParams = @{
                                Name = "NDMP Servers - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 35, 20, 10, 35
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                        } catch {
                            Write-PScriboMessage -IsWarning "NDMP Servers Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "NDMP Servers Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'NDMP Servers'
    }

}