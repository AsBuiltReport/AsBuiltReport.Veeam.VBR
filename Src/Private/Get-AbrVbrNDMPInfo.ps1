
function Get-AbrVbrNDMPInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam NDMP Servers Information
    .DESCRIPTION
    .NOTES
        Version:        0.2.0
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
        Write-PscriboMessage "Discovering Veeam VBR NDMP Servers information from $System."
    }

    process {
        try {
            if ((Get-VBRInstalledLicense | Where-Object {$_.Edition -in @("EnterprisePlus","Enterprise")} -and (Get-VBRNDMPServer).count -gt 0)) {
                Section -Style Heading3 'NDMP Servers' {
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $NDMPObjs = Get-VBRNDMPServer | Where-Object {$_.Port -ne 0}
                            foreach ($NDMPObj in $NDMPObjs) {
                                try {
                                    Write-PscriboMessage "Discovered $($NDMPObj.Name) NDMP Server."
                                    $inObj = [ordered] @{
                                        'Name' = $NDMPObj.Name
                                        'Credentials' = $NDMPObj.Credentials
                                        'Port' = $NDMPObj.Port
                                        'Gateway' = switch ($NDMPObj.SelectedGatewayId) {
                                            "00000000-0000-0000-0000-000000000000" {"Automatic"}
                                            Default {(Get-VBRServer | Where-Object {$_.Id -eq $NDMPObj.SelectedGatewayId}).Name}
                                        }
                                    }

                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }

                            $TableParams = @{
                                Name = "NDMP Servers - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                List = $false
                                ColumnWidths = 35, 20, 10, 35
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