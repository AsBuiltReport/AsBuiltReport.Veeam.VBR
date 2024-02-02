
function Get-AbrVbrTapeInfraSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Tape Infrastructure Summary.
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
        Write-PScriboMessage "Discovering Veeam VBR Tape Infrastructure Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $TapeServer = Get-VBRTapeServer
                $TapeLibrary = Get-VBRTapeLibrary
                $TapeMediaPool = Get-VBRTapeMediaPool
                $TapeVault = Get-VBRTapeVault
                $TapeDrive = Get-VBRTapeDrive
                $TapeMedium = Get-VBRTapeMedium
                $inObj = [ordered] @{
                    'Tape Servers' = $TapeServer.Count
                    'Tape Library' = $TapeLibrary.Count
                    'Tape MediaPool' = $TapeMediaPool.Count
                    'Tape Vault' = $TapeVault.Count
                    'Tape Drives' = $TapeDrive.Count
                    'Tape Medium' = $TapeMedium.Count
                }
                $OutObj += [pscustomobject]$inobj
            } catch {
                Write-PScriboMessage -IsWarning "Tape Infrastructure Summary Table Section: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "Tape Infrastructure Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            if ($Options.EnableCharts) {
                try {
                    $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category'; Expression = { $_.key } }, @{ Name = 'Value'; Expression = { $_.value } } | Sort-Object -Property 'Category'

                    $chartFileItem = Get-PieChart -SampleData $sampleData -ChartName 'TapeInfrastructure' -XField 'Category' -YField 'Value' -ChartLegendName 'Infrastructure'
                } catch {
                    Write-PScriboMessage -IsWarning "Tape Infrastructure chart section: $($_.Exception.Message)"
                }
            }

            if ($OutObj) {
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Tape Infrastructure' {
                    if ($Options.EnableCharts -and $chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Tape Infrastructure - Diagram' -Align 'Center' -Percent 100 -Base64 $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tape Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}