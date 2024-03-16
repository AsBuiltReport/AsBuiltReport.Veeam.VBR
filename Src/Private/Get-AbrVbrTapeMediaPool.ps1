
function Get-AbrVbrTapeMediaPool {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Media Pools Information
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
        Write-PScriboMessage "Discovering Veeam VBR Tape Media Pools information from $System."
    }

    process {
        try {
            $PoolObjs = Get-VBRTapeMediaPool
            if ($PoolObjs) {
                #---------------------------------------------------------------------------------------------#
                #                            Tape Media Pools Section                                         #
                #---------------------------------------------------------------------------------------------#
                Section -Style Heading3 'Tape Media Pools' {
                    $OutObj = @()
                    try {
                        foreach ($PoolObj in $PoolObjs) {
                            try {
                                if ($PoolObj.Type -ne "Custom") {
                                    $Capacity = ((Get-VBRTapeMedium -MediaPool $PoolObj.Name).Capacity | Measure-Object -Sum).Sum
                                    $FreeSpace = ((Get-VBRTapeMedium -MediaPool $PoolObj.Name).Free | Measure-Object -Sum).Sum
                                } else {
                                    $Capacity = $PoolObj.Capacity
                                    $FreeSpace = $PoolObj.FreeSpace
                                }
                                Write-PScriboMessage "Discovered $($PoolObj.Name) Media Pool."
                                $inObj = [ordered] @{
                                    'Name' = $PoolObj.Name
                                    'Type' = $PoolObj.Type
                                    'Tape Count' = ((Get-VBRTapeMediaPool -Id $PoolObj.Id).Medium).count
                                    'Total Space' = ConvertTo-FileSizeString $Capacity
                                    'Free Space' = ConvertTo-FileSizeString $FreeSpace
                                    'Tape Library' = ($PoolObj.GlobalOptions.LibraryId | ForEach-Object { Get-VBRTapeLibrary -Id $_ }).Name
                                }

                                $OutObj += [pscustomobject]$inobj
                            } catch {
                                Write-PScriboMessage -IsWarning "Tape Media Pools $($PoolObj.Name) Table: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "Tape Media Pools - $VeeamBackupServer"
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
                Write-PScriboMessage "Tape MediaPool Configuration InfoLevel set at $($InfoLevel.Tape.MediaPool)."
                if ($InfoLevel.Tape.MediaPool -ge 2) {
                    Write-PScriboMessage "Discovering Per Tape Media Pools Configuration."
                    if ($PoolObjs) {
                        Section -Style Heading3 'Tape Media Pools Configuration' {
                            foreach ($PoolObj in ($PoolObjs | Where-Object { $_.Type -eq 'Gfs' -or $_.Type -eq 'Custom' } | Sort-Object -Property 'Name')) {
                                Write-PScriboMessage "Discovering $($PoolObj.Name) Tape Media Pools Configuration."
                                #---------------------------------------------------------------------------------------------#
                                #                            Tape Media Pools - Tape Library Sub-Section                      #
                                #---------------------------------------------------------------------------------------------#
                                Section -Style Heading4 $PoolObj.Name {
                                    try {
                                        Section -ExcludeFromTOC -Style NOTOCHeading5 'Tape Library' {
                                            Write-PScriboMessage "Discovering $($PoolObj.Name) Tape Library Configuration."
                                            $OutObj = @()
                                            foreach ($TapeLibrary in $PoolObj.GlobalOptions.LibraryId) {
                                                try {
                                                    $TapeLibraryObj = Get-VBRTapeLibrary -Id $TapeLibrary.Guid
                                                    if ($TapeLibraryObj) {
                                                        if ($PoolObj.Type -ne "Custom") {
                                                            $Capacity = ((Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibrary.Guid }).Capacity | Measure-Object -Sum).Sum
                                                            $FreeSpace = ((Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibrary.Guid }).Free | Measure-Object -Sum).Sum
                                                        } else {
                                                            $Capacity = $PoolObj.Capacity
                                                            $FreeSpace = $PoolObj.FreeSpace
                                                        }
                                                        $TapeDrives = @()
                                                        foreach ($Drive in $TapeLibraryObj.Drives) {
                                                            $TapeDrives += "Drive $($Drive.Address + 1)"
                                                        }
                                                        Write-PScriboMessage "Discovered $($TapeLibraryObj.Name) Tape Library Configuration."
                                                        $inObj = [ordered] @{
                                                            'Library Name' = $TapeLibraryObj.Name
                                                            'Library Id' = $TapeLibraryObj.Id
                                                            'Type' = $TapeLibraryObj.Type
                                                            'State' = $TapeLibraryObj.State
                                                            'Model' = $TapeLibraryObj.Model
                                                            'Drives' = $TapeDrives -join ', '
                                                            'Slots' = $TapeLibraryObj.Slots
                                                            'Tape Count' = ((Get-VBRTapeMediaPool -Id $PoolObj.Id).Medium).count
                                                            'Total Space' = ConvertTo-FileSizeString $Capacity
                                                            'Free Space' = ConvertTo-FileSizeString $FreeSpace
                                                            'Add Tape from Free Media Pool Automatically when more Tape are Required' = ConvertTo-TextYN $PoolObj.MoveFromFreePool
                                                            'Description' = Switch ([string]::IsNullOrEmpty($TapeLibraryObj.Description)) {
                                                                $true { "--" }
                                                                $false { $TapeLibraryObj.Description }
                                                                default { "Unknown" }
                                                            }
                                                            'Library Mode' = Switch ($PoolObj.GlobalOptions.Mode) {
                                                                'CrossLibraryParalleing' { 'Active (Used Always)' }
                                                                'Failover' { 'Passive (Used for Failover Only)' }
                                                            }
                                                        }

                                                        if ($PoolObj.GlobalOptions.Mode -eq 'Failover') {
                                                            $inObj.add('When Active Library is Offline or in Maintenance Mode', (ConvertTo-TextYN $PoolObj.GlobalOptions.NextLibOffline))
                                                            $inObj.add('When Active Library has no free media available', (ConvertTo-TextYN $PoolObj.GlobalOptions.NextLibNoMedia))
                                                        }

                                                        if (($PoolObj.GlobalOptions.LibraryId).count -eq 1) {
                                                            $inObj.Remove('Library Mode')
                                                            $inObj.Remove('When Active Library is Offline or in Maintenance Mode')
                                                            $inObj.Remove('When Active Library has no free media available')
                                                            $inObj.add('Library Mode', 'Active (Used Always)')
                                                        }

                                                        $OutObj = [pscustomobject]$inobj

                                                        if ($HealthCheck.Tape.BestPractice) {
                                                            $OutObj | Where-Object { $_.'Description' -eq "--" } | Set-Style -Style Warning -Property 'Description'
                                                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                                                        }

                                                        $TableParams = @{
                                                            Name = "Tape Library - $($PoolObj.Name)"
                                                            List = $true
                                                            ColumnWidths = 40, 60
                                                        }

                                                        if ($Report.ShowTableCaptions) {
                                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                                        }
                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                        if ($HealthCheck.Tape.BestPractice) {
                                                            if ($OutObj | Where-Object { $_.'Description' -match 'Created by' -or $Null -like $_.'Description' }) {
                                                                Paragraph "Health Check:" -Bold -Underline
                                                                BlankLine
                                                                Paragraph {
                                                                    Text "Best Practice:" -Bold
                                                                    Text "It is a general rule of good practice to establish well-defined descriptions. This helps to speed up the fault identification process, as well as enabling better documentation of the environment."
                                                                }
                                                                BlankLine
                                                            }
                                                        }
                                                        #---------------------------------------------------------------------------------------------#
                                                        #                          Tape Media Pools - Tape Medium Sub-Section                         #
                                                        #---------------------------------------------------------------------------------------------#
                                                        try {
                                                            $TapeMediums = Get-VBRTapeMedium -MediaPool $PoolObj.Id | Where-Object { $_.LibraryId -eq $TapeLibraryObj.Id }
                                                            if ($TapeMediums) {
                                                                Section -ExcludeFromTOC -Style NOTOCHeading6 'Tape Mediums' {
                                                                    $OutObj = @()
                                                                    if ($TapeMediums) {
                                                                        foreach ($TapeMedium in $TapeMediums) {
                                                                            try {
                                                                                Write-PScriboMessage "Discovered $($TapeMedium.Name) Medium."
                                                                                $inObj = [ordered] @{
                                                                                    'Name' = $TapeMedium.Name
                                                                                    'Is Worm?' = ConvertTo-TextYN $TapeMedium.IsWorm
                                                                                    'Total Space' = ConvertTo-FileSizeString $TapeMedium.Capacity
                                                                                    'Free Space' = ConvertTo-FileSizeString $TapeMedium.Free
                                                                                    'Tape Library' = Switch ($TapeMedium.LibraryId) {
                                                                                        $Null { '--' }
                                                                                        '00000000-0000-0000-0000-000000000000' { 'Unknown' }
                                                                                        default { (Get-VBRTapeLibrary -Id $TapeMedium.LibraryId).Name }
                                                                                    }
                                                                                }

                                                                                $OutObj += [pscustomobject]$inobj
                                                                            } catch {
                                                                                Write-PScriboMessage -IsWarning "Tape Medium $($TapeMedium.Name) Table: $($_.Exception.Message)"
                                                                            }
                                                                        }

                                                                        $TableParams = @{
                                                                            Name = "Tape Mediums - $($TapeLibraryObj.Name)"
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
                                                        } Catch {
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
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 'Media Set' {
                                                $OutObj = @()
                                                $inObj = [ordered] @{
                                                    'Name' = $PoolObj.MediaSetName
                                                    'Automatically Create New Media Set' = Switch ($PoolObj.MediaSetCreationPolicy.Type) {
                                                        'Never' { 'Do not Create, Always continue using current Media Set' }
                                                        'Always' { 'Create new Media Set for every backup session' }
                                                        'Daily' {
                                                            Switch ($PoolObj.MediaSetCreationPolicy.DailyOptions.Type) {
                                                                'Everyday' { "Daily at $($PoolObj.MediaSetCreationPolicy.DailyOptions.Period.ToString()) Everyday" }
                                                                'SelectedDays' { "Daily at $($PoolObj.MediaSetCreationPolicy.DailyOptions.Period.ToString()), on these days [$($PoolObj.MediaSetCreationPolicy.DailyOptions.DayOfWeek)]" }
                                                                default { 'Unknown' }
                                                            }
                                                        }
                                                        default { 'Unknown' }
                                                    }
                                                }

                                                $OutObj += [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Media Set - $($PoolObj.Name)"
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
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 'Gfs Media Set' {
                                                foreach ($MediaSetOption in $MediaSetOptions) {
                                                    $SectionTitle = ($MediaSetOption -creplace '([A-Z\W_]|\d+)(?<![a-z])', ' $&').trim()
                                                    Section -ExcludeFromTOC -Style NOTOCHeading6 $SectionTitle {
                                                        $OutObj = @()
                                                        $inObj = [ordered] @{
                                                            'Override Protection Period' = $PoolObj.$MediaSetOption.OverwritePeriod
                                                            'Medium' = $PoolObj.$MediaSetOption.MediaSetPolicy.Medium.Name -join ', '
                                                            'Media Set Name' = $PoolObj.$MediaSetOption.MediaSetPolicy.Name
                                                            'Add Tapes from Media Pool Automatically' = ConvertTo-TextYN $PoolObj.$MediaSetOption.MediaSetPolicy.MoveFromMediaPoolAutomatically
                                                            'Append Backup Files to Incomplete Tapes' = ConvertTo-TextYN $PoolObj.$MediaSetOption.MediaSetPolicy.AppendToCurrentTape
                                                        }
                                                        if ($PoolObj.$MediaSetOption.MediaSetPolicy.MoveOfflineToVault) {
                                                            $inObj.add('Move All Offline Tape into the following Media Vault', (ConvertTo-TextYN $PoolObj.$MediaSetOption.MediaSetPolicy.MoveOfflineToVault))
                                                            $inObj.add('Vault', $PoolObj.$MediaSetOption.MediaSetPolicy.Vault)
                                                        }

                                                        $OutObj = [pscustomobject]$inobj

                                                        $TableParams = @{
                                                            Name = "Gfs Media Set - $($SectionTitle)"
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
                                    } Catch {
                                        Write-PScriboMessage -IsWarning "Tape Media Set $($PoolObj.MediaSetName) Section - $($_.Exception.Message)"
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                          Tape Media Pools - Retention Sub-Section                           #
                                    #---------------------------------------------------------------------------------------------#
                                    if ($PoolObj.Type -eq 'Custom') {
                                        try {
                                            Section -ExcludeFromTOC -Style NOTOCHeading5 'Retention' {
                                                $OutObj = @()
                                                $inObj = [ordered] @{
                                                    'Data Retention Policy' = Switch ($PoolObj.RetentionPolicy.Type) {
                                                        'Never' { 'Never Overwrite Data' }
                                                        'Cyclic' { 'Do not Protect Data (Cyclically Overwrite Tape as Required)' }
                                                        'Period' { "Protect Data for $($PoolObj.RetentionPolicy.Value) $($PoolObj.RetentionPolicy.Period)" }
                                                        default { 'Unknown' }
                                                    }
                                                    'Offline Media Tracking' = ConvertTo-TextYN $PoolObj.MoveOfflineToVault
                                                }

                                                if ($PoolObj.MoveOfflineToVault) {
                                                    $inobj.add('Move all Offline Tape from this Media Pool into The following Media Vault', $PoolObj.Vault)
                                                }

                                                $OutObj += [pscustomobject]$inobj

                                                $TableParams = @{
                                                    Name = "Media Set - $($PoolObj.Name)"
                                                    List = $true
                                                    ColumnWidths = 40, 60
                                                }

                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                            }
                                        } Catch {
                                            Write-PScriboMessage -IsWarning "Tape Media Set $($PoolObj.Name) Retention Section: $($_.Exception.Message)"
                                        }
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                          Tape Media Pools - Options Sub-Section                             #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        Section -ExcludeFromTOC -Style NOTOCHeading5 'Options' {
                                            $OutObj = @()
                                            $inObj = [ordered] @{
                                                'Enable Parallel Processing for Tape Jobs using this Media Pool' = ConvertTo-TextYN $PoolObj.MultiStreamingOptions.Enabled
                                                'Jobs Pointed to this Media Pool can use up to' = "$($PoolObj.MultiStreamingOptions.NumberOfStreams) Tape Drives Simultaneously"
                                                'Enable Parallel Processing of Backup Chains within a Single Tape Job' = ConvertTo-TextYN $PoolObj.MultiStreamingOptions.SplitJobFilesBetweenDrives
                                                'Use Encryption' = ConvertTo-TextYN $PoolObj.EncryptionOptions.Enabled
                                            }

                                            if ($PoolObj.EncryptionOptions.Enabled) {
                                                $inobj.add('Encryption Password', (Get-VBREncryptionKey | Where-Object { $_.Id -eq $PoolObj.EncryptionOptions.Key.Id }).Description)
                                            }

                                            $OutObj += [pscustomobject]$inobj

                                            $TableParams = @{
                                                Name = "Media Set - $($PoolObj.Name)"
                                                List = $true
                                                ColumnWidths = 40, 60
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    } Catch {
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
    end {}
}