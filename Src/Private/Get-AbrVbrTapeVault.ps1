
function Get-AbrVbrTapeVault {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Tape Vault Information
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
        Write-PscriboMessage "Discovering Veeam VBR Tape Vault information from $System."
    }

    process {
        if ((Get-VBRTapeVault).count -gt 0) {
            Section -Style Heading3 'Tape Vaults' {
                $OutObj = @()
                if ((Get-VBRServerSession).Server) {
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
                            Name = "Tape Vault - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
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
    end {}

}