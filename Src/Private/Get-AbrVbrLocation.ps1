
function Get-AbrVbrLocation {
    <#
    .SYNOPSIS
    Used by As Built Report to returns geographical locations created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.7.1
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
                    Paragraph "The following section provide a summary about geographical locations."
                    BlankLine
                    try {
                        $OutObj = @()

                        $Locations = Get-VBRLocation
                        foreach ($Location in $Locations) {
                            try {
                                Write-PscriboMessage "Discovered $($Location.Name) location."
                                $inObj = [ordered] @{
                                    'Name' = $Location.Name
                                    'id' = $Location.id
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning "Geographical Locations $($Location.Name) Section: $($_.Exception.Message)"
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
                    }
                    catch {
                        Write-PscriboMessage -IsWarning "Geographical Locations Section: $($_.Exception.Message)"
                    }
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Geographical Locations Section: $($_.Exception.Message)"
        }
    }
    end {}

}
