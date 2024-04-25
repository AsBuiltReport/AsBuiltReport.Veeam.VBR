
function Get-AbrVbrStorageInfraSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Storage Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.6
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
        Write-PScriboMessage "Discovering Veeam VBR Storage Infrastructure Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $OntapHosts = Get-NetAppHost
                $IsilonHosts = Get-VBRIsilonHost
                $IsilonVols = Get-VBRIsilonVolume
                $inObj = [ordered] @{
                    'NetApp Ontap Storage' = $OntapHosts.Count
                    'NetApp Ontap Volumes' = $OntapHosts.Count
                    'Dell Isilon Storage' = $IsilonHosts.Count
                    'Dell Isilon Volumes' = $IsilonVols.Count
                }
                $OutObj += [pscustomobject]$inobj
            } catch {
                Write-PScriboMessage -IsWarning "Storage Infrastructure Inventory Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "Storage Infrastructure Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }

            $OutObj | Table @TableParams

        } catch {
            Write-PScriboMessage -IsWarning "Storage Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}
