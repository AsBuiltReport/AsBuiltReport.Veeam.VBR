
function Get-AbrVbrTapeVault {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Vault Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.1
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
        Write-PscriboMessage "Discovering Veeam VBR Tape Vault information from $System."
    }

    process {
        try {
            if (Get-VBRInstalledLicense | Where-Object {$_.Edition -in @("EnterprisePlus","Enterprise") -and $_.Status -ne "Expired"}) {
                if ((Get-VBRTapeVault).count -gt 0) {
                    Section -Style Heading3 'Tape Vaults' {
                        $OutObj = @()
                        try {
                            $TapeObjs = Get-VBRTapeVault
                            foreach ($TapeObj in $TapeObjs) {
                                try {
                                    Write-PscriboMessage "Discovered $($TapeObj.Name) Type Vault."
                                    $inObj = [ordered] @{
                                        'Name' = $TapeObj.Name
                                        'Description' = $TapeObj.Description
                                        'Automatic Protect' = ConvertTo-TextYN $TapeObj.Protect
                                        'Location' = ConvertTo-EmptyToFiller (Get-VBRLocation -Object $TapeObj -ErrorAction SilentlyContinue)
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "Tape Vault - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 32, 32, 16, 20
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
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