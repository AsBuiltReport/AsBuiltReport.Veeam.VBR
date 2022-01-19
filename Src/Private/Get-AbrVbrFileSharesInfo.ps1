
function Get-AbrVbrFileSharesInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam File Share Information
    .DESCRIPTION
    .NOTES
        Version:        0.2.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR File Share information from $System."
    }

    process {
        try {
            if ((Get-VBRNASServer).count -gt 0) {
                Section -Style Heading3 'File Shares' {
                    Paragraph "The following table summarizes the file shares backed-up by Veeam Server $(((Get-VBRServerSession).Server))."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $ShareObjs = Get-VBRNASServer
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
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "File Shares - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                List = $false
                                ColumnWidths = 30, 13, 12, 22, 23
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-object -Property 'Path' | Table @TableParams
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