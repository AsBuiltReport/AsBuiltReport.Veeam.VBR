
function Get-AbrVbrLocation {
    <#
    .SYNOPSIS
    Used by As Built Report to returns geographical locations created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR locations information from $System."
    }

    process {
        try {
            $Locations = Get-VBRLocation
            if ($Locations) {
                Section -Style Heading3 'Geographical Locations' {
                    Paragraph "The following section provide a summary about geographical locations."
                    BlankLine
                    try {
                        $OutObj = @()
                        foreach ($Location in $Locations) {
                            try {
                                Write-PScriboMessage "Discovered $($Location.Name) location."
                                $inObj = [ordered] @{
                                    'Name' = $Location.Name
                                    'id' = $Location.id
                                }
                                $OutObj += [pscustomobject]$inobj
                            } catch {
                                Write-PScriboMessage -IsWarning "Geographical Locations $($Location.Name) Section: $($_.Exception.Message)"
                            }
                        }

                        $TableParams = @{
                            Name = "Location - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 50, 50
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property Name | Table @TableParams
                    } catch {
                        Write-PScriboMessage -IsWarning "Geographical Locations Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Geographical Locations Section: $($_.Exception.Message)"
        }
    }
    end {}

}
