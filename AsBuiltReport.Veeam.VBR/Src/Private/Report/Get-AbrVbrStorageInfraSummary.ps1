
function Get-AbrVbrStorageInfraSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Storage Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        $LocalizedData = $reportTranslate.GetAbrVbrStorageInfraSummary
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Storage Infrastructure Summary'
    }

    process {
        try {
            $OutObj = @()
            try {
                $OntapHosts = Get-NetAppHost
                $IsilonHosts = Get-VBRIsilonHost
                $IsilonVols = Get-VBRIsilonVolume
                $inObj = [ordered] @{
                    $LocalizedData.NetAppOntapStorage = $OntapHosts.Count
                    $LocalizedData.NetAppOntapVolumes = $OntapHosts.Count
                    $LocalizedData.DellIsilonStorage = $IsilonHosts.Count
                    $LocalizedData.DellIsilonVolumes = $IsilonVols.Count
                }
                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
            } catch {
                Write-PScriboMessage -IsWarning "Storage Infrastructure Inventory Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
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
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Storage Infrastructure Summary'
    }

}
