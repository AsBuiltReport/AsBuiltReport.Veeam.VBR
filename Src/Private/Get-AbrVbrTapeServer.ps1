
function Get-AbrVbrTapeServer {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Server Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.7
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
        Write-PScriboMessage "Discovering Veeam VBR Tape Server information from $System."
    }

    process {
        try {
            if ($TapeObjs = Get-VBRTapeServer) {
                Section -Style Heading3 'Tape Servers' {
                    $OutObj = @()
                    try {
                        foreach ($TapeObj in $TapeObjs) {
                            Write-PScriboMessage "Discovered $($TapeObj.Name) Type Server."
                            $inObj = [ordered] @{
                                'Name' = $TapeObj.Name
                                'Description' = $TapeObj.Description
                                'Status' = Switch ($TapeObj.IsAvailable) {
                                    'True' { 'Available' }
                                    'False' { 'Unavailable' }
                                    default { $TapeObj.IsUnavailable }
                                }
                            }
                            $OutObj += [pscustomobject]$inobj
                        }

                        if ($HealthCheck.Tape.Status) {
                            $OutObj | Where-Object { $_.'Status' -eq 'Unavailable' } | Set-Style -Style Warning -Property 'Status'
                        }

                        if ($HealthCheck.Tape.BestPractice) {
                            $OutObj | Where-Object { $Null -like $_.'Description' } | Set-Style -Style Warning -Property 'Description'
                            $OutObj | Where-Object { $_.'Description' -match "Created by" } | Set-Style -Style Warning -Property 'Description'
                        }

                        $TableParams = @{
                            Name = "Tape Server - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 25, 50, 25
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
                    } catch {
                        Write-PScriboMessage -IsWarning "Tape Servers Table: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tape Servers Section: $($_.Exception.Message)"
        }
    }
    end {}

}