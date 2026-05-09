
function Get-AbrVbrCDPPolicyConf {
    <#
    .SYNOPSIS
        Used by As Built Report to returns CDP policy configuration from Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR CDP policy configuration information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCDPPolicyConf
        Show-AbrDebugExecutionTime -Start -TitleMessage 'CDP Policy Configuration'
    }

    process {
        try {
            if ($CDPPolicies = Get-VBRCDPPolicy -ErrorAction SilentlyContinue | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    foreach ($CDPPolicy in $CDPPolicies) {
                        try {
                            Section -Style Heading4 $($CDPPolicy.Name) {
                                # Common Information
                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.CommonInfoSection {
                                    $OutObj = @()
                                    try {
                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $CDPPolicy.Name
                                            $LocalizedData.Id = $CDPPolicy.Id
                                            $LocalizedData.PolicyState = switch ($CDPPolicy.PolicyState) {
                                                'Disabled' { $LocalizedData.Disabled }
                                                'Running' { $LocalizedData.Running }
                                                'InitialSync' { $LocalizedData.InitialSync }
                                                default { $CDPPolicy.PolicyState }
                                            }
                                            $LocalizedData.LastResult = $CDPPolicy.LastResult
                                            $LocalizedData.LastState = $CDPPolicy.LastState
                                            $LocalizedData.NextRun = switch ($CDPPolicy.NextRun) {
                                                $null { $LocalizedData.NA }
                                                default { $CDPPolicy.NextRun }
                                            }
                                            $LocalizedData.Suffix = $CDPPolicy.Suffix
                                            $LocalizedData.CompressionLevel = $CDPPolicy.CompressionLevel
                                            $LocalizedData.Description = switch ($CDPPolicy.Description) {
                                                { $null -eq $_ -or $_ -eq '' } { $LocalizedData.NA }
                                                default { $CDPPolicy.Description }
                                            }
                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            $OutObj | Where-Object { $_."$($LocalizedData.Description)" -eq $LocalizedData.NA -or $_."$($LocalizedData.Description)" -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                            $OutObj | Where-Object { $_."$($LocalizedData.LastResult)" -eq 'Failed' } | Set-Style -Style Critical -Property $LocalizedData.LastResult
                                            $OutObj | Where-Object { $_."$($LocalizedData.LastResult)" -eq 'Warning' } | Set-Style -Style Warning -Property $LocalizedData.LastResult
                                        }

                                        $TableParams = @{
                                            Name = "$($LocalizedData.CommonInfoTable) - $($CDPPolicy.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams

                                        if ($HealthCheck.Jobs.BestPractice) {
                                            if ($OutObj | Where-Object { $_."$($LocalizedData.Description)" -match 'Created by' -or $_."$($LocalizedData.Description)" -eq $LocalizedData.NA }) {
                                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                BlankLine
                                                Paragraph {
                                                    Text $LocalizedData.BestPractice -Bold
                                                    Text $LocalizedData.DescriptionBestPracticeText
                                                }
                                                BlankLine
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "CDP Policy Common Information $($CDPPolicy.Name): $($_.Exception.Message)"
                                    }
                                }

                                # Network Mapping section
                                try {
                                    if ($CDPPolicy.NetworkMappingEnabled -and $CDPPolicy.SourceNetwork -and $CDPPolicy.TargetNetwork) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.NetworkMappingSection {
                                            $OutObj = @()
                                            for ($i = 0; $i -lt $CDPPolicy.SourceNetwork.Count; $i++) {
                                                try {
                                                    $Tgt = if ($i -lt $CDPPolicy.TargetNetwork.Count) { $CDPPolicy.TargetNetwork[$i] } else { $null }
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.SourceNetwork = $CDPPolicy.SourceNetwork[$i].NetworkName
                                                        $LocalizedData.TargetNetwork = if ($Tgt) { $Tgt.NetworkName } else { $LocalizedData.NA }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "CDP Policy Network Mapping $($CDPPolicy.Name): $($_.Exception.Message)"
                                                }
                                            }
                                            $TableParams = @{
                                                Name = "$($LocalizedData.NetworkMappingTable) - $($CDPPolicy.Name)"
                                                List = $false
                                                ColumnWidths = 50, 50
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "CDP Policy Network Mapping Section $($CDPPolicy.Name): $($_.Exception.Message)"
                                }

                                # Re-IP Rules section
                                try {
                                    if ($CDPPolicy.ReIPRule) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.ReIPRuleSection {
                                            $OutObj = @()
                                            foreach ($Rule in $CDPPolicy.ReIPRule) {
                                                try {
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.SourceIP = $Rule.SourceIp
                                                        $LocalizedData.SourceMask = $Rule.SourceMask
                                                        $LocalizedData.TargetIP = $Rule.TargetIp
                                                        $LocalizedData.TargetMask = $Rule.TargetMask
                                                        $LocalizedData.TargetGateway = $Rule.TargetGateway
                                                        $LocalizedData.DNS = switch ($Rule.DNS) {
                                                            { $null -eq $_ -or $_.Count -eq 0 } { $LocalizedData.NA }
                                                            default { $Rule.DNS -join ', ' }
                                                        }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "CDP Policy Re-IP Rule $($CDPPolicy.Name): $($_.Exception.Message)"
                                                }
                                            }
                                            $TableParams = @{
                                                Name = "$($LocalizedData.ReIPRuleTable) - $($CDPPolicy.Name)"
                                                List = $false
                                                ColumnWidths = 20, 15, 20, 15, 15, 15
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "CDP Policy Re-IP Rules Section $($CDPPolicy.Name): $($_.Exception.Message)"
                                }

                                # Protected VMs section — resolved from EntityId via Find-VBRViEntity
                                try {
                                    if ($CDPPolicy.EntityId) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.SourceVMsSection {
                                            $OutObj = @()
                                            $ViEntities = Find-VBRViEntity -ErrorAction SilentlyContinue
                                            foreach ($EntityRef in $CDPPolicy.EntityId) {
                                                try {
                                                    $VM = $ViEntities | Where-Object { $_.Id -eq $EntityRef } | Select-Object -First 1
                                                    $inObj = [ordered] @{
                                                        $LocalizedData.VMName = if ($VM) { $VM.Name } else { $EntityRef }
                                                        $LocalizedData.Location = if ($VM) { $VM.Path } else { $LocalizedData.NA }
                                                    }
                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "CDP Policy Source VMs $($CDPPolicy.Name): $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.SourceVMsTable) - $($CDPPolicy.Name)"
                                                List = $false
                                                ColumnWidths = 50, 50
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property $LocalizedData.VMName | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "CDP Policy Source VMs Section $($CDPPolicy.Name): $($_.Exception.Message)"
                                }

                                # Guest Processing section
                                try {
                                    if ($CDPPolicy.ApplicationProcessingEnabled) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.GuestProcessingSection {
                                            $OutObj = @()
                                            try {
                                                $gpo = $CDPPolicy.GuestProcessingOptions
                                                $inObj = [ordered] @{
                                                    $LocalizedData.AppProcessingEnabled = $CDPPolicy.ApplicationProcessingEnabled
                                                    $LocalizedData.GuestOSCredentials = switch ($gpo.GuestOSCredentials) {
                                                        $null { $LocalizedData.NA }
                                                        default { $gpo.GuestOSCredentials.ToString() }
                                                    }
                                                    $LocalizedData.GuestInteractionProxy = switch ($gpo.GuestInteractionProxy) {
                                                        { $null -eq $_ -or @($_).Count -eq 0 } { $LocalizedData.Automatic }
                                                        default { (@($gpo.GuestInteractionProxy) | ForEach-Object { $_.Name }) -join ', ' }
                                                    }
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "CDP Policy Guest Processing $($CDPPolicy.Name): $($_.Exception.Message)"
                                            }
                                            $TableParams = @{
                                                Name = "$($LocalizedData.GuestProcessingTable) - $($CDPPolicy.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "CDP Policy Guest Processing Section $($CDPPolicy.Name): $($_.Exception.Message)"
                                }

                                # Retention / RPO settings
                                try {
                                    if ($CDPPolicy.RetentionOptions) {
                                        $ro = $CDPPolicy.RetentionOptions
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.RPOSection {
                                            $OutObj = @()
                                            try {
                                                $inObj = [ordered] @{
                                                    $LocalizedData.RPOFrequency = "$($ro.RPOFrequency) $($ro.RPOFrequencyType)"
                                                    $LocalizedData.ShortTermRetention = "$($ro.ShortTermRetentionInterval) $($ro.ShortTermRetentionIntervalType)"
                                                    $LocalizedData.LongTermRetentionFrequency = "$($ro.LongTermRetentionFrequency) $($ro.LongTermRetentionFrequencyType)"
                                                    $LocalizedData.LongTermRetentionPoints = $ro.LongTermRetentionNumber
                                                    $LocalizedData.RPOWarningEnabled = $ro.EnableRPOMarkAsWarning
                                                    $LocalizedData.RPOWarningThreshold = "$($ro.MarkJobAsWarningThreshold) $($ro.RPOMarkAsWarningIntervalType)"
                                                    $LocalizedData.RPOErrorEnabled = $ro.EnableRPOMarkAsError
                                                    $LocalizedData.RPOErrorThreshold = "$($ro.MarkJobAsErrorThreshold) $($ro.RPOMarkAsErrorIntervalType)"
                                                }
                                                $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)
                                            } catch {
                                                Write-PScriboMessage -IsWarning "CDP Policy RPO $($CDPPolicy.Name): $($_.Exception.Message)"
                                            }

                                            if ($HealthCheck.Jobs.BestPractice) {
                                                $OutObj | Where-Object { $_."$($LocalizedData.RPOWarningEnabled)" -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.RPOWarningEnabled
                                                $OutObj | Where-Object { $_."$($LocalizedData.RPOErrorEnabled)" -eq 'No' } | Set-Style -Style Warning -Property $LocalizedData.RPOErrorEnabled
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.RPOTable) - $($CDPPolicy.Name)"
                                                List = $true
                                                ColumnWidths = 50, 50
                                            }
                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Table @TableParams

                                            if ($HealthCheck.Jobs.BestPractice) {
                                                if ($OutObj | Where-Object { $_."$($LocalizedData.RPOWarningEnabled)" -eq 'No' -or $_."$($LocalizedData.RPOErrorEnabled)" -eq 'No' }) {
                                                    Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                    BlankLine
                                                    Paragraph {
                                                        Text $LocalizedData.BestPractice -Bold
                                                        Text $LocalizedData.RPOBestPracticeText
                                                    }
                                                    BlankLine
                                                }
                                            }
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "CDP Policy RPO Section $($CDPPolicy.Name): $($_.Exception.Message)"
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "CDP Policy $($CDPPolicy.Name) Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "CDP Policy Configuration Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'CDP Policy Configuration'
    }

}
