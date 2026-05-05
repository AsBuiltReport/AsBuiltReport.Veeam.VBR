
function Get-AbrVbrCDPPolicy {
    <#
    .SYNOPSIS
        Used by As Built Report to returns CDP policies created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR CDP policies information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCDPPolicy
        Show-AbrDebugExecutionTime -Start -TitleMessage 'CDP Policies'
    }

    process {
        try {
            if ($CDPPolicies = Get-VBRCDPPolicy -ErrorAction SilentlyContinue | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($CDPPolicy in $CDPPolicies) {
                        try {
                            $inObj = [ordered] @{
                                $LocalizedData.Name = $CDPPolicy.Name
                                $LocalizedData.PolicyState = switch ($CDPPolicy.PolicyState) {
                                    'Disabled' { $LocalizedData.Disabled }
                                    'Running' { $LocalizedData.Running }
                                    'InitialSync' { $LocalizedData.InitialSync }
                                    default { $CDPPolicy.PolicyState }
                                }
                                $LocalizedData.LatestResult = $CDPPolicy.LastResult
                                $LocalizedData.NextRun = switch ($CDPPolicy.NextRun) {
                                    $null { $LocalizedData.NA }
                                    default { $CDPPolicy.NextRun }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "CDP Policy $($CDPPolicy.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    if ($HealthCheck.Jobs.Status) {
                        $OutObj | Where-Object { $_."$($LocalizedData.LatestResult)" -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_."$($LocalizedData.LatestResult)" -eq 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_."$($LocalizedData.LatestResult)" -eq 'Success' } | Set-Style -Style Ok -Property $LocalizedData.LatestResult
                        $OutObj | Where-Object { $_."$($LocalizedData.PolicyState)" -eq $LocalizedData.Disabled } | Set-Style -Style Warning -Property $LocalizedData.PolicyState
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 40, 20, 20, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "CDP Policies Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'CDP Policies'
    }

}
