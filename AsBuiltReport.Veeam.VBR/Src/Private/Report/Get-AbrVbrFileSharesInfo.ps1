
function Get-AbrVbrFileSharesInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam File Share Information
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
        $LocalizedData = $reportTranslate.GetAbrVbrFileSharesInfo
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'File Share'
    }

    process {
        if ($ShareObjs = Get-VBRNASServer -WarningAction SilentlyContinue) {
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph ($LocalizedData.Paragraph -f $VeeamBackupServer)
                BlankLine
                $OutObj = @()
                try {
                    foreach ($ShareObj in $ShareObjs) {
                        $Path = $Null
                        try {
                            if ($ShareObj.Type -eq 'FileServer') {
                                $Path = $ShareObj.Name
                                $AccessCredentials = $ShareObj.Server.ProxyServicesCreds.Name
                            } else {
                                $Path = Get-VBRNASServerPath -Server $ShareObj
                                $AccessCredentials = $ShareObj.AccessCredentials
                            }

                            $inObj = [ordered] @{
                                $LocalizedData.Path = $Path
                                $LocalizedData.Type = switch ($ShareObj.Type) {
                                    'FileServer' { $LocalizedData.FileServerType }
                                    'SANSMB' { $LocalizedData.NASFilerType }
                                    'SMB' { $LocalizedData.SMBShareType }
                                    'NFS' { $LocalizedData.NFSShareType }
                                    'SANNFS' { $LocalizedData.NASFilerType }
                                    default { $ShareObj.Type }
                                }
                                $LocalizedData.BackupIOControl = $ShareObj.BackupIOControlLevel
                                $LocalizedData.Credentials = switch (($AccessCredentials).count) {
                                    0 { $LocalizedData.None }
                                    default { $AccessCredentials }
                                }
                                $LocalizedData.CacheRepository = $ShareObj.CacheRepository.Name
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "File Shares $($Path) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 30, 13, 12, 22, 23
                    }

                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property $LocalizedData.Path | Table @TableParams
                } catch {
                    Write-PScriboMessage -IsWarning "File Shares Section: $($_.Exception.Message)"
                }
            }
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'File Share'
    }

}
