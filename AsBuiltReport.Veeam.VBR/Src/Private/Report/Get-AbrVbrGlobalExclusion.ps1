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
        $LocalizedData = $reportTranslate.GetAbrVbrGlobalExclusion
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Global Exclusion settings'
    }

    process {
        try {
            if ($MalwareDetectionExclusions = Get-VBRMalwareDetectionExclusion) {
                Section -Style Heading4 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    try {
                        Write-PScriboMessage ($LocalizedData.CollectingMalware -f $System)
                        Section -ExcludeFromTOC -Style Heading5 $LocalizedData.HeadingMalware {
                            foreach ($MalwareDetectionExclusion in $MalwareDetectionExclusions) {
                                $OutObj = @()

                                $inObj = [ordered] @{
                                    $LocalizedData.Name = $MalwareDetectionExclusion.Name
                                    $LocalizedData.Platform = $MalwareDetectionExclusion.Platform
                                    $LocalizedData.Note = $MalwareDetectionExclusion.Note
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeadingMalware) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 33, 33, 34
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Malware Detection Exclusions Section: $($_.Exception.Message)"
                    }
                    if ($VMExclusions = Get-VBRVMExclusion) {
                        try {
                            Write-PScriboMessage ($LocalizedData.CollectingVM -f $System)
                            Section -ExcludeFromTOC -Style Heading5 $LocalizedData.HeadingVM {
                                foreach ($VMExclusion in $VMExclusions) {
                                    $OutObj = @()

                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $VMExclusion.Name
                                        $LocalizedData.Platform = $VMExclusion.Platform
                                        $LocalizedData.Note = $VMExclusion.Note
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.TableHeadingVM) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 33, 33, 34
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
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
