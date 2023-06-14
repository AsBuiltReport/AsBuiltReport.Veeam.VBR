
function Get-AbrVbrNetworkTrafficRule {
    <#
    .SYNOPSIS
    Used by As Built Report to returns network traffic rules settings created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.3
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
        Write-PscriboMessage "Discovering Veeam VBR network traffic rules settings information from $System."
    }

    process {
        try {
            if ((Get-VBRNetworkTrafficRule).count -gt 0) {
                Section -Style Heading4 'Network Traffic Rules' {
                    Paragraph "The following section details network traffic rules settings configured on Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    try {
                        $TrafficRules = Get-VBRNetworkTrafficRule
                        foreach ($TrafficRule in $TrafficRules) {
                            $inObj = [ordered] @{
                                'Name' = $TrafficRule.Name
                                'Source IP Start' = $TrafficRule.SourceIPStart
                                'Source IP End' = ConvertTo-EmptyToFiller $TrafficRule.SourceIPEnd
                                'Target IP Start' = $TrafficRule.TargetIPStart
                                'Target IP End' = ConvertTo-EmptyToFiller $TrafficRule.TargetIPEnd
                                'Encryption Enabled' = ConvertTo-TextYN $TrafficRule.EncryptionEnabled
                                'Throttling' = "Throttling Enabled: $(ConvertTo-TextYN $TrafficRule.ThrottlingEnabled)`r`nThrottling Unit: $($TrafficRule.ThrottlingUnit)`r`nThrottling Value: $($TrafficRule.ThrottlingValue)`r`nThrottling Windows: $(ConvertTo-TextYN $TrafficRule.ThrottlingWindowEnabled)"
                            }
                            $OutObj = [pscustomobject]$inobj

                            if ($HealthCheck.Infrastructure.Settings) {
                                $OutObj | Where-Object { $_.'Encryption Enabled' -like 'No'} | Set-Style -Style Warning -Property 'Encryption Enabled'
                            }

                            $TableParams = @{
                                Name = "Network Traffic Rules - $($TrafficRule.Name)"
                                List = $true
                                ColumnWidths = 40, 60
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            if ($TrafficRule.ThrottlingWindowEnabled) {
                                Section -Style NOTOCHeading5 -ExcludeFromTOC "Throttling Windows Time Period" {
                                    Paragraph {
                                        Text 'Permited \' -Color 81BC50 -Bold
                                        Text ' Denied' -Color dddf62 -Bold
                                    }
                                    $OutObj = @()
                                    try {
                                        $Days = 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
                                        $Hours24 = [ordered]@{
                                            0 = 12
                                            1 = 1
                                            2 = 2
                                            3 = 3
                                            4 = 4
                                            5 = 5
                                            6 = 6
                                            7 = 7
                                            8 = 8
                                            9 = 9
                                            10 = 10
                                            11 = 11
                                            12 = 12
                                            13 = 1
                                            14 = 2
                                            15 = 3
                                            16 = 4
                                            17 = 5
                                            18 = 6
                                            19 = 7
                                            20 = 8
                                            21 = 9
                                            22 = 10
                                            23 = 11
                                        }
                                        $ScheduleTimePeriod = $TrafficRule.ThrottlingWindowOptions -split '(.{48})' | Where-Object {$_}

                                        foreach ($OBJ in $Hours24.GetEnumerator()) {

                                            $inObj = [ordered] @{
                                                'H' = $OBJ.Value
                                                'Sun' = $ScheduleTimePeriod[0].Split(',')[$OBJ.Key]
                                                'Mon' = $ScheduleTimePeriod[1].Split(',')[$OBJ.Key]
                                                'Tue' = $ScheduleTimePeriod[2].Split(',')[$OBJ.Key]
                                                'Wed' = $ScheduleTimePeriod[3].Split(',')[$OBJ.Key]
                                                'Thu' = $ScheduleTimePeriod[4].Split(',')[$OBJ.Key]
                                                'Fri' = $ScheduleTimePeriod[5].Split(',')[$OBJ.Key]
                                                'Sat' = $ScheduleTimePeriod[6].Split(',')[$OBJ.Key]
                                            }
                                            $OutObj += $inobj
                                        }

                                        $TableParams = @{
                                            Name = "Throttling Windows - $($TrafficRule.Name)"
                                            List = $true
                                            ColumnWidths = 6,4,3,4,4,4,4,4,4,4,4,4,4,4,3,4,4,4,4,4,4,4,4,4,4
                                            Key = 'H'
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        if ($OutObj) {
                                            $OutObj2 = Table -Hashtable $OutObj @TableParams
                                            $OutObj2.Rows | Where-Object {$_.Sun -eq "0"} | Set-Style -Style OFF -Property "Sun"
                                            $OutObj2.Rows | Where-Object {$_.Mon -eq "0"} | Set-Style -Style OFF -Property "Mon"
                                            $OutObj2.Rows | Where-Object {$_.Tue -eq "0"} | Set-Style -Style OFF -Property "Tue"
                                            $OutObj2.Rows | Where-Object {$_.Wed -eq "0"} | Set-Style -Style OFF -Property "Wed"
                                            $OutObj2.Rows | Where-Object {$_.Thu -eq "0"} | Set-Style -Style OFF -Property "Thu"
                                            $OutObj2.Rows | Where-Object {$_.Fri -eq "0"} | Set-Style -Style OFF -Property "Fri"
                                            $OutObj2.Rows | Where-Object {$_.Sat -eq "0"} | Set-Style -Style OFF -Property "Sat"

                                            $OutObj2.Rows | Where-Object {$_.Sun -eq "1"} | Set-Style -Style ON -Property "Sun"
                                            $OutObj2.Rows | Where-Object {$_.Mon -eq "1"} | Set-Style -Style ON -Property "Mon"
                                            $OutObj2.Rows | Where-Object {$_.Tue -eq "1"} | Set-Style -Style ON -Property "Tue"
                                            $OutObj2.Rows | Where-Object {$_.Wed -eq "1"} | Set-Style -Style ON -Property "Wed"
                                            $OutObj2.Rows | Where-Object {$_.Thu -eq "1"} | Set-Style -Style ON -Property "Thu"
                                            $OutObj2.Rows | Where-Object {$_.Fri -eq "1"} | Set-Style -Style ON -Property "Fri"
                                            $OutObj2.Rows | Where-Object {$_.Sat -eq "1"} | Set-Style -Style ON -Property "Sat"
                                            $OutObj2
                                        }
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "Throttling Windows Time Period Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Network Traffic Rules Section: $($_.Exception.Message)"
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                                Preferred Networks                                           #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        if ((Get-VBRPreferredNetwork).count -gt 0) {
                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'Preferred Networks' {
                                $OutObj = @()
                                $PreferedNetworks = Get-VBRPreferredNetwork
                                foreach ($PreferedNetwork in $PreferedNetworks) {
                                    try {
                                        Write-PscriboMessage "Discovered $($PreferedNetwork.CIDRNotation) Prefered Network."
                                        $inObj = [ordered] @{
                                            'IP Address' = $PreferedNetwork.IpAddress
                                            'Subnet Mask' = $PreferedNetwork.SubnetMask
                                            'CIDR Notation' = $PreferedNetwork.CIDRNotation
                                        }
                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning "Preferred Networks $($PreferedNetwork.IpAddress) Section: $($_.Exception.Message)"
                                    }
                                }

                                $TableParams = @{
                                    Name = "Preferred Networks - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 30, 30, 40
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Preferred Networks Section: $($_.Exception.Message)"
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