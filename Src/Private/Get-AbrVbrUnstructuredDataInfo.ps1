
function Get-AbrVbrUnstructuredDataInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Unstructured Data Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.3
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
        Write-PscriboMessage "Discovering Veeam VBR Unstructured Data information from $System."
    }

    process {
        $ShareObjs = Get-VBRUnstructuredServer
        if ($ShareObjs) {
            Section -Style Heading3 'Unstructured Data' {
                Paragraph "The following table provides a summary about the unstructured data backed-up by Veeam Server $(((Get-VBRServerSession).Server))."
                Section -Style Heading4 'File Servers' {
                    $OutObj = @()
                    try {
                        foreach ($ShareObj in $ShareObjs | Where-Object {$_.Type -eq "FileServer"}) {
                            try {
                                Write-PscriboMessage "Discovered $($ShareObj.Name) Server."
                                $inObj = [ordered] @{
                                    'Name' = $ShareObj.Name
                                    'Backup IO Control' = $ShareObj.BackupIOControlLevel
                                    'Credentials' = Switch ([string]::IsNullOrEmpty($ShareObj.Server.ProxyServicesCreds.Name)) {
                                        $true {"--"}
                                        $false {$ShareObj.Server.ProxyServicesCreds.Name}
                                        default {"Unknown"}
                                    }
                                    'Cache Repository' = $ShareObj.CacheRepository.Name
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Unstructured Data File Server Item: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "File Servers - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 30, 15, 28, 27
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-object -Property 'Name' | Table @TableParams
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Unstructured Data File Server Section: $($_.Exception.Message)"
                    }
                }
                Section -Style Heading4 'NAS Fillers' {
                    $OutObj = @()
                    try {
                        foreach ($ShareObj in $ShareObjs | Where-Object {$_.Type -eq "SANSMB"}) {
                            $Path = $Null
                            try {
                                if ($ShareObj.Type -eq 'FileServer') {
                                    $Path = $ShareObj.Name
                                    $AccessCredentials = $ShareObj.Server.ProxyServicesCreds.Name
                                } else {
                                    $Path = Get-VBRNASServerPath -Server $ShareObj
                                    $AccessCredentials = $ShareObj.AccessCredentials
                                }
                                Write-PscriboMessage "Discovered $($Path) Share."
                                $inObj = [ordered] @{
                                    'Path' = $Path
                                    'Type' = switch ($ShareObj.Type) {
                                        "FileServer" {"File Server"}
                                        "SANSMB" {"NAS Filler"}
                                        "SMB" {"SMB Share"}
                                        "NFS" {"NFS Share"}
                                        "SANNFS" {"NAS Filler"}
                                        Default {$ShareObj.Type}
                                    }
                                    'Backup IO Control' = $ShareObj.BackupIOControlLevel
                                    'Credentials' = Switch (($AccessCredentials).count) {
                                        0 {"None"}
                                        default {$AccessCredentials}
                                    }
                                    'Cache Repository' = $ShareObj.CacheRepository.Name
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Unstructured Data $($Path) Section: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "NAS Fillers - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 30, 13, 12, 22, 23
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-object -Property 'Path' | Table @TableParams
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Unstructured Data NAS Fillers Section: $($_.Exception.Message)"
                    }
                }
                Section -Style Heading4 'File Shares' {
                    $OutObj = @()
                    try {
                        foreach ($ShareObj in $ShareObjs | Where-Object {$_.Type -eq "SMB" -or $_.Type -eq "NFS"}) {
                            $Path = $Null
                            try {
                                if ($ShareObj.Type -eq 'FileServer') {
                                    $Path = $ShareObj.Name
                                    $AccessCredentials = $ShareObj.Server.ProxyServicesCreds.Name
                                } else {
                                    $Path = Get-VBRNASServerPath -Server $ShareObj
                                    $AccessCredentials = $ShareObj.AccessCredentials
                                }
                                Write-PscriboMessage "Discovered $($Path) Share."
                                $inObj = [ordered] @{
                                    'Path' = $Path
                                    'Type' = switch ($ShareObj.Type) {
                                        "FileServer" {"File Server"}
                                        "SANSMB" {"NAS Filler"}
                                        "SMB" {"SMB Share"}
                                        "NFS" {"NFS Share"}
                                        "SANNFS" {"NAS Filler"}
                                        Default {$ShareObj.Type}
                                    }
                                    'Backup IO Control' = $ShareObj.BackupIOControlLevel
                                    'Credentials' = Switch (($AccessCredentials).count) {
                                        0 {"None"}
                                        default {$AccessCredentials}
                                    }
                                    'Cache Repository' = $ShareObj.CacheRepository.Name
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Unstructured Data $($Path) Section: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "File Shares - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 30, 13, 12, 22, 23
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-object -Property 'Path' | Table @TableParams
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Unstructured Data File Shares Section: $($_.Exception.Message)"
                    }
                }
                Section -Style Heading4 'Object Storage' {
                    $OutObj = @()
                    try {
                        foreach ($ShareObj in $ShareObjs | Where-Object {$_.Type -eq "AzureBlobServer" -or $_.Type -eq "AmazonS3Server" -or $_.Type -eq "S3CompatibleServer"}) {
                            try {
                                Write-PscriboMessage "Discovered $($ShareObj.Name) Server."
                                $inObj = [ordered] @{
                                    'Name' = $ShareObj.FriendlyName
                                    'Region' = ConvertTo-EmptyToFiller $ShareObj.Info
                                    'Account' = Switch ([string]::IsNullOrEmpty($ShareObj.Account.Name)) {
                                        $true {"--"}
                                        $false {$ShareObj.Account.Name}
                                        default {"Unknown"}
                                    }
                                    'Backup IO Control' = $ShareObj.BackupIOControlLevel
                                    'Cache Repository' = $ShareObj.CacheRepository.Name
                                }

                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Unstructured Data Object Storage Item: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "Object Storage - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 25, 20, 20, 15, 20
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-object -Property 'Name' | Table @TableParams
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Unstructured Data Object Storage Section: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
    end {}

}