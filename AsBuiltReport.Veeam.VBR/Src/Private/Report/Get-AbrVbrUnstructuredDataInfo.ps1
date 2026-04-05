
function Get-AbrVbrUnstructuredDataInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Unstructured Data Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.0
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
        Write-PScriboMessage "Discovering Veeam VBR Unstructured Data information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrUnstructuredDataInfo
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Unstructured Data'
    }

    process {
        if ($ShareObjs = Get-VBRUnstructuredServer) {
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph ($LocalizedData.Paragraph -f $VeeamBackupServer)
                $OutObj = @()
                try {
                    foreach ($ShareObj in $ShareObjs | Where-Object { $_.Type -eq 'FileServer' }) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $ShareObj.Name
                                $LocalizedData.BackupIOControl = $ShareObj.BackupIOControlLevel
                                $LocalizedData.Credentials = switch ([string]::IsNullOrEmpty($ShareObj.Server.ProxyServicesCreds.Name)) {
                                    $true { $LocalizedData.Dash }
                                    $false { $ShareObj.Server.ProxyServicesCreds.Name }
                                    default { $LocalizedData.Unknown }
                                }
                                $LocalizedData.CacheRepository = $ShareObj.CacheRepository.Name
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Unstructured Data File Server Item: $($_.Exception.Message)"
                        }
                    }
                    if ($OutObj) {
                        Section -Style Heading4 $LocalizedData.FileServersHeading {
                            $TableParams = @{
                                Name = "$($LocalizedData.TableFileServers) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 30, 15, 28, 27
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Unstructured Data File Server Section: $($_.Exception.Message)"
                }
                $OutObj = @()
                try {
                    foreach ($ShareObj in $ShareObjs | Where-Object { $_.Type -eq 'SANSMB' }) {
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
                                    'FileServer' { $LocalizedData.FileServer }
                                    'SANSMB' { $LocalizedData.NASFiler }
                                    'SMB' { $LocalizedData.SMBShare }
                                    'NFS' { $LocalizedData.NFSShare }
                                    'SANNFS' { $LocalizedData.NASFiler }
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
                            Write-PScriboMessage -IsWarning "Unstructured Data $($Path) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($OutObj) {
                        Section -Style Heading4 $LocalizedData.NASFilersHeading {
                            $TableParams = @{
                                Name = "$($LocalizedData.TableNASFilers) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 30, 13, 12, 22, 23
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Path' | Table @TableParams
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Unstructured Data NAS Filers Section: $($_.Exception.Message)"
                }
                $OutObj = @()
                try {
                    foreach ($ShareObj in $ShareObjs | Where-Object { $_.Type -eq 'SMB' -or $_.Type -eq 'NFS' }) {
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
                                    'FileServer' { $LocalizedData.FileServer }
                                    'SANSMB' { $LocalizedData.NASFiler }
                                    'SMB' { $LocalizedData.SMBShare }
                                    'NFS' { $LocalizedData.NFSShare }
                                    'SANNFS' { $LocalizedData.NASFiler }
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
                            Write-PScriboMessage -IsWarning "Unstructured Data $($Path) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($OutObj) {
                        Section -Style Heading4 $LocalizedData.FileSharesHeading {
                            $TableParams = @{
                                Name = "$($LocalizedData.TableFileShares) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 30, 13, 12, 22, 23
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Path' | Table @TableParams
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Unstructured Data File Shares Section: $($_.Exception.Message)"
                }
                $OutObj = @()
                try {
                    foreach ($ShareObj in $ShareObjs | Where-Object { $_.Type -eq 'AzureBlobServer' -or $_.Type -eq 'AmazonS3Server' -or $_.Type -eq 'S3CompatibleServer' }) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $ShareObj.FriendlyName
                                $LocalizedData.Region = $ShareObj.Info
                                $LocalizedData.Account = switch ([string]::IsNullOrEmpty($ShareObj.Account.Name)) {
                                    $true { $LocalizedData.Dash }
                                    $false { $ShareObj.Account.Name }
                                    default { $LocalizedData.Unknown }
                                }
                                $LocalizedData.BackupIOControl = $ShareObj.BackupIOControlLevel
                                $LocalizedData.CacheRepository = $ShareObj.CacheRepository.Name
                            }

                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Unstructured Data Object Storage Item: $($_.Exception.Message)"
                        }
                    }
                    if ($OutObj) {
                        Section -Style Heading4 $LocalizedData.ObjectStorageHeading {
                            $TableParams = @{
                                Name = "$($LocalizedData.TableObjectStorage) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 25, 20, 20, 15, 20
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Unstructured Data Object Storage Section: $($_.Exception.Message)"
                }
            }
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Unstructured Data'
    }

}