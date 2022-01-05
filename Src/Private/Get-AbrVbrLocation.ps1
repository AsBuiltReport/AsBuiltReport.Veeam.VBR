
function Get-AbrVbrLocation {
    <#
    .SYNOPSIS
    Used by As Built Report to returns geographical locations created in Veeam Backup & Replication.


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
        Write-PscriboMessage "Discovering Veeam VBR locations information from $System."
    }

    process {
        if ((Get-VBRLocation).count -gt 0) {
            Section -Style Heading3 'Geographical Locations' {
                Paragraph "The following section list geographical locations created in Veeam Backup & Replication."
                BlankLine
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
                        Name = "Location Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                        List = $false
                        ColumnWidths = 50, 50
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
        }
    }
    end {}

}