
function Get-AbrVbrTapeServer {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Tape Server Information
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
        Write-PscriboMessage "Discovering Veeam VBR Tape Server information from $System."
    }

    process {
        $TapeObjs = Get-VBRTapeServer
        if ($TapeObjs) {
            Section -Style Heading3 'Tape Servers' {
                Paragraph "The following section provides summary information on Tape Servers."
                BlankLine
                $OutObj = @()
                if ((Get-VBRServerSession).Server) {
                    try {
                        foreach ($TapeObj in $TapeObjs) {
                            Write-PscriboMessage "Discovered $($TapeObj.Name) Type Server."
                            $inObj = [ordered] @{
                                'Name' = $TapeObj.Name
                                'Description' = $TapeObj.Description
                                'Status' = Switch ($TapeObj.IsAvailable) {
                                    'True' {'Available'}
                                    'False' {'Unavailable'}
                                    default {$TapeObj.IsUnavailable}
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }

                        if ($HealthCheck.Tape.Status) {
                            $OutObj | Where-Object { $_.'Status' -eq 'Unavailable'} | Set-Style -Style Warning -Property 'Status'
                        }

                        $TableParams = @{
                            Name = "Tape Server - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $false
                            ColumnWidths = 25, 50, 25
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
    end {}

}