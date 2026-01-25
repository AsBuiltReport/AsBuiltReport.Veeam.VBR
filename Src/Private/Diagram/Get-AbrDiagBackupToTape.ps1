function Get-AbrDiagBackupToTape {
    <#
    .SYNOPSIS
        Function to build a Backup Server to Repository diagram.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.8.24
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]

    param
    (

    )

    begin {
    }

    process {
        try {
            $BackupTapeServers = Get-AbrBackupTapeServerInfo
            $BackupTapeLibrary = Get-AbrBackupTapeLibraryInfo
            $BackupTapeDrives = Get-AbrBackupTapeDrivesInfo

            if ($BackupServerInfo) {
                if ($BackupTapeServers) {
                    $TapeArray = @()
                    foreach ($TSOBJ in ($BackupTapeServers | Sort-Object -Property Name)) {
                        $TapeNodesArray = @()

                        $TapeServerNode = $TSOBJ.Label

                        if ($BackupTapeLibrary) {
                            $BKPTLOBJ = ($BackupTapeLibrary | Where-Object { $_.TapeServerId -eq $TSOBJ.Id } | Sort-Object -Property Name)
                            foreach ($TSLibraryOBJ in $BKPTLOBJ) {

                                $TapeLibraryNodesArray = @()
                                $TapeLibrarySubArrayTable = @()

                                $TapeLibraryOBJNode = $TSLibraryOBJ.Label

                                if ($TapeLibraryOBJNode) {
                                    $TapeLibraryNodesArray += $TapeLibraryOBJNode
                                }

                                if ($BackupTapeDrives) {

                                    $TapeLibraryDrives = ($BackupTapeDrives | Where-Object { $_.LibraryId -eq $TSLibraryOBJ.Id } | Sort-Object -Property Name)

                                    try {
                                        if ($TapeLibraryDrives.Name.Count -eq 1) {
                                            $TapeLibraryDriveColumnSize = 1
                                        } elseif ($ColumnSize) {
                                            $TapeLibraryDriveColumnSize = $ColumnSize
                                        } else {
                                            $TapeLibraryDriveColumnSize = $TapeLibraryDrives.Name.Count
                                        }
                                        $TapeLibraryDrivesNode = Add-DiaHtmlNodeTable -Name 'TapeLibraryDrivesNode' -ImagesObj $Images -inputObject $TapeLibraryDrives.Name -Align 'Center' -iconType 'VBR_Tape_Drive' -ColumnSize $TapeLibraryDriveColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $TapeLibraryDrives.AditionalInfo -Subgraph -SubgraphLabel 'Tape Drives' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor $Fontcolor -TableBorderColor $Edgecolor -TableBorder '1' -FontSize 18 -SubgraphFontBold

                                    } catch {
                                        Write-Verbose 'Error: Unable to create Tape Library Drives Objects. Disabling the section'
                                        Write-Debug "Error Message: $($_.Exception.Message)"
                                    }

                                    if ($TapeLibraryDrivesNode) {
                                        $TapeLibraryNodesArray += $TapeLibraryDrivesNode
                                    }
                                }

                                try {
                                    $TapeLibrarySubgraph = Add-DiaHtmlSubGraph -Name 'TapeLibrarySubgraph' -ImagesObj $Images -TableArray $TapeLibraryNodesArray -Align 'Center' -IconDebug $IconDebug -Label 'Tape Library' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 24 -FontBold
                                } catch {
                                    Write-Verbose 'Error: Unable to create Tape Library SubGraph Objects. Disabling the section'
                                    Write-Debug "Error Message: $($_.Exception.Message)"
                                }

                                if ($TapeLibrarySubgraph) {
                                    $TapeNodesArray += $TapeLibrarySubgraph
                                }
                            }
                        }

                        try {
                            if ($TapeNodesArray -eq 1) {
                                $TapeLibraryColumnSize = 1
                            } elseif ($ColumnSize) {
                                $TapeLibraryColumnSize = $ColumnSize
                            } else {
                                $TapeLibraryColumnSize = $TapeNodesArray.Count
                            }
                            $TapeLibrarySubgraphArray = Add-DiaHtmlSubGraph -Name 'TapeLibrarySubgraphArray' -ImagesObj $Images -TableArray $TapeNodesArray -Align 'Center' -IconDebug $IconDebug -Label ' ' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '0' -ColumnSize $TapeLibraryColumnSize -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Tape Library SubGraph Array Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($TapeServerNode) {
                            $TapeLibrarySubArrayTable += $TapeServerNode
                        }

                        if ($TapeLibrarySubgraphArray) {
                            $TapeLibrarySubArrayTable += $TapeLibrarySubgraphArray
                        }

                        try {
                            $TapeServerSubgraph = Add-DiaHtmlSubGraph -Name 'TapeServerSubgraph' -ImagesObj $Images -TableArray $TapeLibrarySubArrayTable -Align 'Center' -IconDebug $IconDebug -Label $TSOBJ.Name -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize 1 -FontSize 24 -FontBold
                        } catch {
                            Write-Verbose 'Error: Unable to create Tape Server SubGraph Objects. Disabling the section'
                            Write-Debug "Error Message: $($_.Exception.Message)"
                        }

                        if ($TapeServerSubgraph) {
                            $TapeArray += $TapeServerSubgraph
                        }
                    }
                    try {
                        if ($TapeArray -eq 1) {
                            $TapeServerColumnSize = 1
                        } elseif ($ColumnSize) {
                            $TapeServerColumnSize = $ColumnSize
                        } else {
                            $TapeServerColumnSize = $TapeArray.Count
                        }
                        $TapeSubgraph = Node -Name Tape -Attributes @{Label = (Add-DiaHtmlSubGraph -Name 'TapeSubgraph' -ImagesObj $Images -TableArray $TapeArray -Align 'Center' -IconDebug $IconDebug -Label 'Tape Servers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $TapeServerColumnSize -FontSize 26 -FontBold); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                    } catch {
                        Write-Verbose 'Error: Unable to create Tape SubGraph Objects. Disabling the section'
                        Write-Debug "Error Message: $($_.Exception.Message)"
                    }
                    if ($TapeSubgraph) {
                        $TapeSubgraph
                        Edge -From BackupServers -To Tape @{minlen = 3 }
                    }
                }
            }
        } catch {
            Write-Verbose -Message $_.Exception.Message
        }
    }
    end {}
}