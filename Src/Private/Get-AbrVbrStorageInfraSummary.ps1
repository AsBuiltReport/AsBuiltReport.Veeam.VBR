
function Get-AbrVbrStorageInfraSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Storage Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
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
        Write-PscriboMessage "Discovering Veeam VBR Storage Infrastructure Summary from $System."
    }

    process {
        try {
            Section -Style NOTOCHeading3 -ExcludeFromTOC 'Storage Infrastructure' {
                $OutObj = @()
                try {
                    $OntapHosts = Get-NetAppHost
                    $OntapVols = Get-NetAppVolume
                    $IsilonHosts = Get-VBRIsilonHost
                    $IsilonVols = Get-VBRIsilonVolume
                    $inObj = [ordered] @{
                        'Number of NetApp Ontap Storage' = $OntapHosts.Count
                        'Number of NetApp Ontap Volumes' = $OntapHosts.Count
                        'Number of Dell Isilon Storage' = $IsilonHosts.Count
                        'Number of Dell Isilon Volumes' = $IsilonVols.Count
                    }
                    $OutObj += [pscustomobject]$inobj
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                $TableParams = @{
                    Name = "Storage Infrastructure Summary - $VeeamBackupServer"
                    List = $true
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
    end {}

}