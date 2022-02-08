
function Get-AbrVbrLocation {
    <#
    .SYNOPSIS
    Used by As Built Report to returns geographical locations created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
        Write-PscriboMessage "Discovering Veeam VBR locations information from $System."
    }

    process {
        try {
            if ((Get-VBRLocation).count -gt 0) {
                Section -Style Heading3 'Geographical Locations' {
                    Paragraph "The following section list geographical locations created in Veeam Backup & Replication."
                    BlankLine
                    try {
                        $OutObj = @()
                        if ((Get-VBRServerSession).Server) {
                            try {
                                $Locations = Get-VBRLocation
                                foreach ($Location in $Locations) {
                                    Write-PscriboMessage "Discovered $($Location.Name) location."
                                    $inObj = [ordered] @{
                                        'Name' = $Location.Name
                                        'id' = $Location.id
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }

                            $TableParams = @{
                                Name = "Location - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                List = $false
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
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
