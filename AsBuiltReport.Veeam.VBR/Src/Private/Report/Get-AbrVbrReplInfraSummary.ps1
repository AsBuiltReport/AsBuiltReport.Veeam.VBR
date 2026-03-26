function Get-AbrVbrReplInfraSummary {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Replication Summary.
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
        Write-PScriboMessage "Discovering Veeam VBR Replication Summary from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrReplInfraSummary
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Replication Summary'
    }

    process {
        try {
            $OutObj = @()
            $Replicas = Get-VBRReplica
            $FailOverPlans = Get-VBRFailoverPlan
            $inObj = [ordered] @{
                $LocalizedData.Replicas = $Replicas.Count
                $LocalizedData.FailoverPlans = $FailOverPlans.Count
            }
            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)

            $TableParams = @{
                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph $LocalizedData.Paragraph
                BlankLine
                $OutObj | Table @TableParams
            }
        } catch {
            Write-PScriboMessage -IsWarning "Replication Summary Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Replication Summary'
    }

}