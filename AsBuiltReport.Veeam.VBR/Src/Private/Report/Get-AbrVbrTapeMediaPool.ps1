
function Get-AbrVbrTapeMediaPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Media Pools Information
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
        Write-PScriboMessage "Discovering Veeam VBR Tape Media Pools information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrTapeMediaPool
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Tape Media Pools'
    }

    process {
        try {
            if ($PoolObjs = Get-VBRTapeMediaPool) {
                #---------------------------------------------------------------------------------------------#
                #                            Tape Media Pools Section                                         #
                #---------------------------------------------------------------------------------------------#
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($PoolObj in $PoolObjs) {
                            try {
                                if ($PoolObj.Type -ne 'Custom') {
                                    $Capacity = ((Get-VBRTapeMedium -MediaPool $PoolObj.Name).Capacity | Measure-Object -Sum).Sum
                                    $FreeSpace = ((Get-VBRTapeMedium -MediaPool $PoolObj.Name).Free | Measure-Object -Sum).Sum
                                } else {
                                    $Capacity = $PoolObj.Capacity
                                    $FreeSpace = $PoolObj.FreeSpace
                                }

                                $inObj = [ordered] @{
                                    $LocalizedData.Name = $PoolObj.Name
                                    $LocalizedData.Type = $PoolObj.Type
                                    $LocalizedData.TapeCount = ((Get-VBRTapeMediaPool -Id $PoolObj.Id).Medium).count
                                    $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Capacity
                                    $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $FreeSpace
                                    $LocalizedData.TapeLibrary = ($PoolObj.GlobalOptions.LibraryId | ForEach-Object { Get-VBRTapeLibrary -Id $_ }).Name
                                }

                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            } catch {
                                Write-PScriboMessage -IsWarning "Tape Media Pools $($PoolObj.Name) Table: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 24, 15, 12, 12, 12, 25
                        }

                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    } catch {
                        Write-PScriboMessage -IsWarning "Tape Media Pools Section: $($_.Exception.Message)"
                    }
                }
                #---------------------------------------------------------------------------------------------#
                #                       Tape Media Pools Configuration Section                                #
                #---------------------------------------------------------------------------------------------#
                Write-PScriboMessage ($LocalizedData.InfoLevel -f $InfoLevel.Tape.MediaPool)
                if ($InfoLevel.Tape.MediaPool -ge 2) {
                    Write-PScriboMessage $LocalizedData.DiscoveringPerPool
                    if ($PoolObjs) {
                        Section -Style Heading3 $LocalizedData.ConfigHeading {
                            foreach ($PoolObj in ($PoolObjs | Where-Object { $_.Type -eq 'Gfs' -or $_.Type -eq 'Custom' } | Sort-Object -Property 'Name')) {
                                Write-PScriboMessage ($LocalizedData.DiscoveringPool -f $PoolObj.Name)
                                #---------------------------------------------------------------------------------------------#
                                #                            Tape Media Pools - Tape Library Sub-Section                      #
                                #---------------------------------------------------------------------------------------------#
                                Section -Style Heading4 $PoolObj.Name {
                                    try {
                                        Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.TapeLibrarySection {
                                            Write-PScriboMessage ($LocalizedData.DiscoveringTapeLibrary -f $PoolObj.Name)
                                            $OutObj = @()
                                            foreach ($TapeLibrary in $PoolObj.GlobalOptions.LibraryId) {
                                                try {
                                                    if ($TapeLibraryObj = Get-VBRTapeLibrary -Id $TapeLibrary.Guid) {
                                                        if ($PoolObj.Type -ne 'Custom') {
                                                            $Capacity = ((Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibrary.Guid }).Capacity | Measure-Object -Sum).Sum
                                                            $FreeSpace = ((Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibrary.Guid }).Free | Measure-Object -Sum).Sum
                                                        } else {
                                                            $Capacity = $PoolObj.Capacity
                                                            $FreeSpace = $PoolObj.FreeSpace
                                                        }
                                                        $TapeDrives = @()
                                                        foreach ($Drive in $TapeLibraryObj.Drives) {
                                                            $TapeDrives += "$($LocalizedData.Drive) $($Drive.Address + 1)"
                                                        }

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.LibraryName = $TapeLibraryObj.Name
                                                            $LocalizedData.LibraryId = $TapeLibraryObj.Id
                                                            $LocalizedData.Type = $TapeLibraryObj.Type
                                                            $LocalizedData.State = $TapeLibraryObj.State
                                                            $LocalizedData.Model = $TapeLibraryObj.Model
                                                            $LocalizedData.Drives = $TapeDrives -join ', '
                                                            $LocalizedData.Slots = $TapeLibraryObj.Slots
                                                            $LocalizedData.TapeCount = ((Get-VBRTapeMediaPool -Id $PoolObj.Id).Medium).count
                                                            $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $Capacity
                                                            $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $FreeSpace
                                                            $LocalizedData.AddTapeFromFreePool = $PoolObj.MoveFromFreePool
                                                            $LocalizedData.Description = switch ([string]::IsNullOrEmpty($TapeLibraryObj.Description)) {
                                                                $true { '--' }
                                                                $false { $TapeLibraryObj.Description }
                                                                default { $LocalizedData.Unknown }
                                                            }
                                                            $LocalizedData.LibraryMode = switch ($PoolObj.GlobalOptions.Mode) {
                                                                'CrossLibraryParalleing' { $LocalizedData.ActiveAlways }
                                                                'Failover' { $LocalizedData.PassiveFailover }
                                                            }
                                                        }

                                                        if ($PoolObj.GlobalOptions.Mode -eq 'Failover') {
                                                            $inObj.add($LocalizedData.WhenActiveOffline, ($PoolObj.GlobalOptions.NextLibOffline))
                                                            $inObj.add($LocalizedData.WhenActiveNoMedia, ($PoolObj.GlobalOptions.NextLibNoMedia))
                                                        }

                                                        if (($PoolObj.GlobalOptions.LibraryId).count -eq 1) {
                                                            $inObj.Remove($LocalizedData.LibraryMode)
                                                            $inObj.Remove($LocalizedData.WhenActiveOffline)
                                                            $inObj.Remove($LocalizedData.WhenActiveNoMedia)
                                                            $inObj.add($LocalizedData.LibraryMode, $LocalizedData.ActiveAlways)
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        if ($HealthCheck.Tape.BestPractice) {
                                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                                            $OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                                        }

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.TapeLibrarySection) - $($PoolObj.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                        if ($HealthCheck.Tape.BestPractice) {
                                                            if ($OutObj | Where-Object { $_.$($LocalizedData.Description) -match 'Created by' -or $_.$($LocalizedData.Description) -eq '--' }) {
                                                                Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                                                BlankLine
                                                                Paragraph {
                                                                    Text $LocalizedData.BestPractice -Bold
                                                                    Text $LocalizedData.BestPracticeDesc
                                                                }
                                                                BlankLine
                                                            }
                                                        }
                                                        #---------------------------------------------------------------------------------------------#
                                                        #                          Tape Media Pools - Tape Medium Sub-Section                         #
                                                        #---------------------------------------------------------------------------------------------#
                                                        try {
                                                            if ($TapeMediums = Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibraryObj.Id }) {
                                                                Section -ExcludeFromTOC -Style NOTOCHeading6 $LocalizedData.TapeMediums {
                                                                    $OutObj = @()
                                                                    if ($TapeMediums) {
                                                                        foreach ($TapeMedium in $TapeMediums) {
                                                                            try {

                                                                                $inObj = [ordered] @{
                                                                                    $LocalizedData.Name = $TapeMedium.Name
                                                                                    $LocalizedData.IsWorm = $TapeMedium.IsWorm
                                                                                    $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $TapeMedium.Capacity
                                                                                    $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $TapeMedium.Free
                                                                                    $LocalizedData.TapeLibrary = switch ($TapeMedium.LibraryId) {
                                                                                        $Null { '--' }
                                                                                        '00000000-0000-0000-0000-000000000000' { $LocalizedData.Unknown }
                                                                                        default { (Get-VBRTapeLibrary -Id $TapeMedium.LibraryId).Name }
                                                                                    }
                                                                                }

                                                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                                            } catch {
                                                                                Write-PScriboMessage -IsWarning "Tape Medium $($TapeMedium.Name) Table: $($_.Exception.Message)"
                                                                            }
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "$($LocalizedData.TapeMediums) - $($TapeLibraryObj.Name)"
                                                                            List = $false
                                                                            ColumnWidths = 20, 20, 20, 20, 20
                                                                        }

                                                                        if ($Report.ShowTableCaptions) {
                                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                                        }
                                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                                    }
                                                                }
                                                            }
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Tape Medium Section: $($_.Exception.Message)"
                                                        }
                                                    }
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Tape Library $($TapeLibraryObj.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Tape Media Pool Configration Section: $($_.Exception.Message)"
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                          Tape Media Pools - Tape Media Set Sub-Section                      #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        if ($PoolObj.MediaSetName) {
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.MediaSetSection {
                                                $OutObj = @()
                                                $inObj = [ordered] @{
                                                    $LocalizedData.Name = $PoolObj.MediaSetName
                                                    $LocalizedData.AutoCreateMediaSet = switch ($PoolObj.MediaSetCreationPolicy.Type) {
                                                        'Never' { $LocalizedData.NeverCreateMediaSet }
                                                        'Always' { $LocalizedData.AlwaysCreateMediaSet }
                                                        'Daily' {
                                                            switch ($PoolObj.MediaSetCreationPolicy.DailyOptions.Type) {
                                                                'Everyday' { $LocalizedData.DailyEveryDay -f $PoolObj.MediaSetCreationPolicy.DailyOptions.Period.ToString() }
                                                                'SelectedDays' { $LocalizedData.DailySelectedDays -f $PoolObj.MediaSetCreationPolicy.DailyOptions.Period.ToString(), $PoolObj.MediaSetCreationPolicy.DailyOptions.DayOfWeek }
                                                                default { $LocalizedData.Unknown }
                                                            }
                                                        }
                                                        default { $LocalizedData.Unknown }
                                                    }
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.MediaSetTable) - $($PoolObj.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }

                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                            }
                                        }
                                        if ($PoolObj.DailyMediaSetOptions) {
                                            $MediaSetOptions = @('DailyMediaSetOptions', 'WeeklyMediaSetOptions', 'MonthlyMediaSetOptions', 'QuarterlyMediaSetOptions', 'YearlyMediaSetOptions')
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.GfsMediaSetSection {
                                                foreach ($MediaSetOption in $MediaSetOptions) {
                                                    $SectionTitle = ($MediaSetOption -creplace '([A-Z\W_]|\d+)(?<![a-z])', ' $&').trim()
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $SectionTitle {
                                                        $OutObj = @()
                                                        $inObj = [ordered] @{
                                                            $LocalizedData.OverrideProtectionPeriod = $PoolObj.$MediaSetOption.OverwritePeriod
                                                            $LocalizedData.MediumColumn = $PoolObj.$MediaSetOption.MediaSetPolicy.Medium.Name -join ', '
                                                            $LocalizedData.MediaSetName = $PoolObj.$MediaSetOption.MediaSetPolicy.Name
                                                            $LocalizedData.AddTapesAutomatically = $PoolObj.$MediaSetOption.MediaSetPolicy.MoveFromMediaPoolAutomatically
                                                            $LocalizedData.AppendBackupFiles = $PoolObj.$MediaSetOption.MediaSetPolicy.AppendToCurrentTape
                                                        }
                                                        if ($PoolObj.$MediaSetOption.MediaSetPolicy.MoveOfflineToVault) {
                                                            $inObj.add($LocalizedData.MoveOfflineTapeVault, ($PoolObj.$MediaSetOption.MediaSetPolicy.MoveOfflineToVault))
                                                            $inObj.add($LocalizedData.Vault, $PoolObj.$MediaSetOption.MediaSetPolicy.Vault)
                                                        }

                                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                                        $TableParams = @{
                                                            Name = "$($LocalizedData.GfsMediaSetTable) - $($SectionTitle)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Table @TableParams
                                                    }
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Tape Media Set $($PoolObj.MediaSetName) Section - $($_.Exception.Message)"
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                          Tape Media Pools - Retention Sub-Section                           #
                                    #---------------------------------------------------------------------------------------------#
                                    if ($PoolObj.Type -eq 'Custom') {
                                        try {
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.RetentionSection {
                                                $OutObj = @()
                                                $inObj = [ordered] @{
                                                    $LocalizedData.DataRetentionPolicy = switch ($PoolObj.RetentionPolicy.Type) {
                                                        'Never' { $LocalizedData.NeverOverwriteData }
                                                        'Cyclic' { $LocalizedData.DoNotProtectData }
                                                        'Period' { $LocalizedData.ProtectDataFor -f $PoolObj.RetentionPolicy.Value, $PoolObj.RetentionPolicy.Period }
                                                        default { $LocalizedData.Unknown }
                                                    }
                                                    $LocalizedData.OfflineMediaTracking = $PoolObj.MoveOfflineToVault
                                                }

                                                if ($PoolObj.MoveOfflineToVault) {
                                                    $inobj.add($LocalizedData.MoveOfflineTapeMediaVault, $PoolObj.Vault)
                                                }

                                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                                $TableParams = @{
                                                    Name = "$($LocalizedData.MediaSetTable) - $($PoolObj.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }

                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                            }
                                        } catch {
                                            Write-PScriboMessage -IsWarning "Tape Media Set $($PoolObj.Name) Retention Section: $($_.Exception.Message)"
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                          Tape Media Pools - Options Sub-Section                             #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        Section -ExcludeFromTOC -Style NOTOCHeading5 $LocalizedData.OptionsSection {
                                            $OutObj = @()
                                            $inObj = [ordered] @{
                                                $LocalizedData.EnableParallelProcessing = $PoolObj.MultiStreamingOptions.Enabled
                                                $LocalizedData.JobsPointedToPool = $LocalizedData.TapeDrivesSimultaneously -f $PoolObj.MultiStreamingOptions.NumberOfStreams
                                                $LocalizedData.EnableParallelChains = $PoolObj.MultiStreamingOptions.SplitJobFilesBetweenDrives
                                                $LocalizedData.UseEncryption = $PoolObj.EncryptionOptions.Enabled
                                            }

                                            if ($PoolObj.EncryptionOptions.Enabled) {
                                                $inobj.add($LocalizedData.EncryptionPassword, (Get-VBREncryptionKey | Where-Object { $_.Id -eq $PoolObj.EncryptionOptions.Key.Id }).Description)
                                            }

                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                            $TableParams = @{
                                                Name = "$($LocalizedData.MediaSetTable) - $($PoolObj.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Tape Media Set $($PoolObj.Name) Options Section: $($_.Exception.Message)"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tape Media Pools Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Tape Media Pools'
    }
}