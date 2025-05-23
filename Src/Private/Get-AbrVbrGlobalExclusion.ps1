function Get-AbrVbrGlobalExclusion {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Global Exclusion settings configured on Veeam Backup & Replication..
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        Write-PScriboMessage "Discovering Veeam VBR Global Exclusion settings information from $System."
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Global Exclusion settings'
    }

    process {
        try {
            if ($MalwareDetectionExclusions = Get-VBRMalwareDetectionExclusion) {
                Section -Style Heading4 'Global Exclusions' {
                    try {
                        Write-PScriboMessage "Discovering Veeam VBR Malware Detection Exclusions settings information from $System."
                        Section -ExcludeFromTOC -Style Heading5 'Malware Detection Exclusions' {
                            foreach ($MalwareDetectionExclusion in $MalwareDetectionExclusions) {
                                $OutObj = @()

                                $inObj = [ordered] @{
                                    'Name' = $MalwareDetectionExclusion.Name
                                    'Platform' = $MalwareDetectionExclusion.Platform
                                    'Note' = $MalwareDetectionExclusion.Note
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }

                            $TableParams = @{
                                Name = "Malware Detection Exclusions - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 33, 33, 34
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property Name | Table @TableParams
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Malware Detection Exclusions Section: $($_.Exception.Message)"
                    }
                    if ($VMExclusions = Get-VBRVMExclusion) {
                        try {
                            Write-PScriboMessage "Discovering Veeam VBR VM Exclusions settings information from $System."
                            Section -ExcludeFromTOC -Style Heading5 'VM Exclusions' {
                                foreach ($VMExclusion in $VMExclusions) {
                                    $OutObj = @()

                                    $inObj = [ordered] @{
                                        'Name' = $VMExclusion.Name
                                        'Platform' = $VMExclusion.Platform
                                        'Note' = $VMExclusion.Note
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                }

                                $TableParams = @{
                                    Name = "VM Exclusions - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 33, 33, 34
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property Name | Table @TableParams
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "VM Exclusions Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Global Exclusions Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Global Exclusion settings'
    }

}