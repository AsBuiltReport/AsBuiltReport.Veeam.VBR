
function Get-AbrVbrBackupToTape {
    <#
    .SYNOPSIS
        Used by As Built Report to returns tape backup jobs configuration created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.4.0
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
        Write-PscriboMessage "Discovering Veeam VBR Tape Backup jobs configuration information from $System."
    }

    process {
        try {
            if ((Get-VBRTapeJob).count -gt 0) {
                Section -Style Heading3 'Backup To Tape Job Configuration' {
                    Paragraph "The following section details backup to tape jobs configuration."
                    BlankLine
                    $OutObj = @()
                    $TBkjobs = Get-VBRTapeJob | Where-Object {$_.Type -eq 'BackupToTape'}
                    if ($TBkjobs) {
                        foreach ($TBkjob in $TBkjobs) {
                            Section -Style Heading4 "$($TBkjob.Name) Configuration" {
                                Section -Style Heading5 'Backups Information' {
                                    $OutObj = @()
                                    try {
                                        Write-PscriboMessage "Discovered $($TBkjob.Name) common information."
                                        if ($TBkjob.Object.Group -eq 'BackupRepository') {
                                            $RepoSize = $TBkjob.Object | Where-Object {$_.Group -eq 'BackupRepository'}
                                            $TotalBackupSize = (($TBkjob.Object.info.IncludedSize | Measure-Object -Sum ).Sum) + ($RepoSize.GetContainer().CachedTotalSpace.InBytes - $RepoSize.GetContainer().CachedFreeSpace.InBytes)
                                        } else {$TotalBackupSize = ($TBkjob.Object.info.IncludedSize | Measure-Object -Sum).Sum}

                                        $inObj = [ordered] @{
                                            'Name' = $TBkjob.Name
                                            'Type' = $TBkjob.Type
                                            'Total Backup Size' = ConvertTo-FileSizeString $TotalBackupSize
                                            'Next Run' = Switch ($TBkjob.Enabled) {
                                                'False' {'Disabled'}
                                                default {$TBkjob.NextRun}
                                            }
                                            'Description' = $TBkjob.Description
                                        }
                                        $OutObj = [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Common Information - $($TBkjob.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }
                                if ($TBkjob.Object) {
                                    Section -Style Heading5 'Object to Process' {
                                        $OutObj = @()
                                        try {
                                            foreach ($LinkedBkJob in $TBkjob.Object) {
                                                try {
                                                    Write-PscriboMessage "Discovered $($LinkedBkJob.Name) object to process."
                                                    if ($LinkedBkJob.Type) {
                                                        $Repository = $LinkedBkJob.Name
                                                        $Type = 'Repository'
                                                    } else {
                                                        $Repository = $LinkedBkJob.GetTargetRepository().Name
                                                        $Type = 'Backup Job'
                                                    }
                                                    if ($LinkedBkJob.Group -eq 'BackupRepository') {
                                                        $TotalBackupSize = ConvertTo-FileSizeString ($LinkedBkJob.GetContainer().CachedTotalSpace.InBytes - $LinkedBkJob.GetContainer().CachedFreeSpace.InBytes)
                                                    } else {$TotalBackupSize = ConvertTo-FileSizeString $LinkedBkJob.Info.IncludedSize}

                                                    $inObj = [ordered] @{
                                                        'Name' = $LinkedBkJob.Name
                                                        'Type' = $Type
                                                        'Size' = $TotalBackupSize
                                                        'Repository' = $Repository
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }
                                                catch {
                                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Objects - $($TBkjob.Name)"
                                                List = $false
                                                ColumnWidths = 35, 25, 15, 25
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
                                }
                            }
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
