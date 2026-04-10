
function Get-AbrVbrTapeLibrary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Library Information
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
        Write-PScriboMessage "Discovering Veeam VBR Tape Library information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrTapeLibrary
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Tape Libraries'
    }

    process {
        try {
            if ($TapeObjs = Get-VBRTapeLibrary | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    try {
                        foreach ($TapeObj in $TapeObjs) {
                            try {
                                Section -Style Heading4 $($TapeObj.Name) {

                                    $TapeServer = (Get-VBRTapeServer | Where-Object { $_.Id -eq $TapeObj.TapeServerId }).Name
                                    $inObj = [ordered] @{
                                        $LocalizedData.LibraryName = $TapeObj.Name
                                        $LocalizedData.LibraryModel = $TapeObj.Model
                                        $LocalizedData.LibraryType = $TapeObj.Type
                                        $LocalizedData.NumberOfSlots = $TapeObj.Slots
                                        $LocalizedData.ConnectedTo = $TapeServer
                                        $LocalizedData.Enabled = $TapeObj.Enabled
                                        $LocalizedData.Status = switch ($TapeObj.State) {
                                            'Online' { $LocalizedData.Available }
                                            'Offline' { $LocalizedData.Unavailable }
                                            default { $TapeObj.State }
                                        }
                                    }

                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

                                    if ($HealthCheck.Tape.Status) {
                                        $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                                    }

                                    $TableParams = @{
                                        Name = "$($LocalizedData.TapeLibraryTable) - $($TapeObj.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    #---------------------------------------------------------------------------------------------#
                                    #                                  Tape Drives Section                                        #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        if ($DriveObjs = Get-VBRTapeDrive -Library $TapeObj.Id) {
                                            Write-PScriboMessage "Collecting $($TapeObj.Name) Tape Drives"
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.TapeDrives {
                                                $OutObj = @()
                                                try {
                                                    foreach ($DriveObj in $DriveObjs) {

                                                        $inObj = [ordered] @{
                                                            $LocalizedData.Name = $DriveObj.Name
                                                            $LocalizedData.Model = $DriveObj.Model
                                                            $LocalizedData.SerialNumber = $DriveObj.SerialNumber
                                                            $LocalizedData.Medium = switch ([string]::IsNullOrEmpty($DriveObj.Medium)) {
                                                                $true { '--' }
                                                                $false { $DriveObj.Medium }
                                                                default { $LocalizedData.Unknown }
                                                            }
                                                            $LocalizedData.Enabled = $DriveObj.Enabled
                                                            $LocalizedData.IsLocked = $DriveObj.IsLocked
                                                            $LocalizedData.State = $DriveObj.State
                                                        }
                                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                    }

                                                    if ($HealthCheck.Tape.Status) {
                                                        $OutObj | Where-Object { $_.$($LocalizedData.Status) -eq $LocalizedData.Unavailable } | Set-Style -Style Warning -Property $LocalizedData.Status
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TapeDrives) - $($TapeObj.Name)"
                                                        List = $false
                                                        ColumnWidths = 14, 18, 16, 16, 12, 12, 12
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Tape Drives $($TapeObj.Name) Section: $($_.Exception.Message)"
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Tape Drives Section: $($_.Exception.Message)"
                                    }
                                    #---------------------------------------------------------------------------------------------#
                                    #                                  Tape Medium Section                                        #
                                    #---------------------------------------------------------------------------------------------#
                                    try {
                                        if ($InfoLevel.Tape.Library -ge 2) {
                                            if ($MediumObjs = Get-VBRTapeMedium -Library $TapeObj.Id) {
                                                Write-PScriboMessage "Collecting $($TapeObj.Name) Tape Medium"
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.TapeMediums {
                                                    $OutObj = @()
                                                    foreach ($MediumObj in $MediumObjs) {
                                                        try {


                                                            $inObj = [ordered] @{
                                                                $LocalizedData.Name = $MediumObj.Name
                                                                $LocalizedData.ExpirationDate = switch (($MediumObj.ExpirationDate).count) {
                                                                    0 { '--' }
                                                                    default { $MediumObj.ExpirationDate.ToShortDateString() }
                                                                }
                                                                $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $MediumObj.Capacity
                                                                $LocalizedData.FreeSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $MediumObj.Free
                                                                $LocalizedData.Locked = $MediumObj.IsLocked
                                                                $LocalizedData.Retired = $MediumObj.IsRetired
                                                                $LocalizedData.Worm = $MediumObj.IsWorm
                                                            }
                                                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                        } catch {
                                                            Write-PScriboMessage -IsWarning "Tape Mediums $($MediumObj.Name) Section: $($_.Exception.Message)"
                                                        }
                                                    }

                                                    $TableParams = @{
                                                        Name = "$($LocalizedData.TapeMediums) - $($TapeObj.Name)"
                                                        List = $false
                                                        ColumnWidths = 30, 16, 12, 12, 10, 10, 10
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                }
                                            }
                                        }
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Tape Mediums Section: $($_.Exception.Message)"
                                    }
                                }
                            } catch {
                                Write-PScriboMessage -IsWarning "Tape Library $($TapeObj.Name) Section: $($_.Exception.Message)"
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Tape Libraries Table Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tape Libraries Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Tape Libraries'
    }

}