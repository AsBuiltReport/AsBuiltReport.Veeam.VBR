
function Get-AbrVbrTapeLibrary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Tape Library Information
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR Tape Library information from $System."
    }

    process {
        if ((Get-VBRTapeLibrary).count -gt 0) {
            Section -Style Heading3 'Tape Libraries Summary' {
                Paragraph "The following section provides summary information on Veeam Tape Server connected Tape Library."
                BlankLine
                $OutObj = @()
                if ((Get-VBRServerSession).Server) {
                    try {
                        $TapeObjs = Get-VBRTapeLibrary
                        foreach ($TapeObj in $TapeObjs) {
                            try {
                                Write-PscriboMessage "Discovered $($TapeObj.Name) Type Library."
                                $TapeServer = (Get-VBRTapeServer | Where-Object {$_.Id -eq $TapeObj.TapeServerId}).Name
                                $inObj = [ordered] @{
                                    'Library Name' = $TapeObj.Name
                                    'Library Model' = $TapeObj.Model
                                    'Library Type' = $TapeObj.Type
                                    'Number of Slots' = $TapeObj.Slots
                                    'Connected to' = $TapeServer
                                    'Enabled' = ConvertTo-TextYN $TapeObj.Enabled
                                    'Status' = Switch ($TapeObj.State) {
                                        'Online' {'Available'}
                                        'Offline' {'Unavailable'}
                                        default {$TapeObj.State}
                                    }
                                }
                                $OutObj = [pscustomobject]$inobj

                                if ($HealthCheck.Tape.Status) {
                                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                }

                                $TableParams = @{
                                    Name = "Tape Library - $($TapeObj.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }

                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                                $DriveObjs = Get-VBRTapeDrive -Library $TapeObj.Id
                                if ($DriveObjs) {
                                    Write-PscriboMessage "Collecting $($TapeObj.Name) Tape Drives"
                                    Section -Style Heading4 "$($TapeObj.Name) Tape Drives" {
                                        Paragraph "The following section provides information on $($TapeObj.Name) Tape Drives."
                                        BlankLine
                                        $OutObj = @()
                                        if ((Get-VBRServerSession).Server) {
                                            try {
                                                foreach ($DriveObj in $DriveObjs) {
                                                    Write-PscriboMessage "Discovered $($DriveObj.Name) Type Drive."
                                                    $inObj = [ordered] @{
                                                        'Name' = $DriveObj.Name
                                                        'Model' = $DriveObj.Model
                                                        'Serial Number' = $DriveObj.SerialNumber
                                                        'Medium' = $DriveObj.Medium
                                                        'Enabled' = ConvertTo-TextYN $DriveObj.Enabled
                                                        'Is Locked' = ConvertTo-TextYN $DriveObj.IsLocked
                                                        'State' = $DriveObj.State
                                                    }
                                                    $OutObj += [pscustomobject]$inobj
                                                }

                                                if ($HealthCheck.Tape.Status) {
                                                    $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                                                }

                                                $TableParams = @{
                                                    Name = "Tape Drives - $($TapeObj.Name)"
                                                    List = $false
                                                    ColumnWidths = 14, 18, 16, 16, 12, 12, 12
                                                }

                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Table @TableParams
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning $_.Exception.Message
                                            }
                                        }
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        }
    }
    end {}

}