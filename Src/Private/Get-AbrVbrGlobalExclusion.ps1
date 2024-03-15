function Get-AbrVbrGlobalExclusion {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Global Exclusion settings configured on Veeam Backup & Replication..
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.5
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
    }

    process {
        try {
            $MalwareDetectionExclusions = Get-VBRMalwareDetectionExclusion
            $VMExclusions = Get-VBRVMExclusion
            if ($MalwareDetectionExclusions) {
                Section -Style Heading4 'Global Exclusions' {
                    try {
                        Write-PScriboMessage "Discovering Veeam VBR Malware Detection Exclusions settings information from $System."
                        Section -ExcludeFromTOC -Style Heading5 'Malware Detection Exclusions' {
                            foreach ($MalwareDetectionExclusion in $MalwareDetectionExclusions) {
                                $OutObj = @()

                                $inObj = [ordered] @{
                                    'Name' = $MalwareDetectionExclusion.Name
                                    'Platform' = $MalwareDetectionExclusion.Platform
                                    'Note' = ConvertTo-EmptyToFiller $MalwareDetectionExclusion.Note
                                }
                                $OutObj += [pscustomobject]$inobj
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
                    if ($VMExclusions) {
                        try {
                            Write-PScriboMessage "Discovering Veeam VBR VM Exclusions settings information from $System."
                            Section -ExcludeFromTOC -Style Heading5 'VM Exclusions' {
                                foreach ($VMExclusion in $VMExclusions) {
                                    $OutObj = @()

                                    $inObj = [ordered] @{
                                        'Name' = $VMExclusion.Name
                                        'Platform' = $VMExclusion.Platform
                                        'Note' = ConvertTo-EmptyToFiller $VMExclusion.Note
                                    }
                                    $OutObj += [pscustomobject]$inobj
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
    end {}

}