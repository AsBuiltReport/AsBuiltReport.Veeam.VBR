
function Get-AbrVbrTapeInfraSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Tape Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.12
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
                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
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
            $OutObj | Table @TableParams
        } catch {
            Write-PScriboMessage -IsWarning "Tape Infrastructure Summary Section: $($_.Exception.Message)"
        }
    }
    end {}

}