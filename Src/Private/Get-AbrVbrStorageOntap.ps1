
function Get-AbrVbrStorageOntap {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve NetApp Ontap Storage Information
    .DESCRIPTION
    .NOTES
        Version:        0.3.1
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
        Write-PscriboMessage "Discovering NetApp Ontap Storage information connected to $System."
    }

    process {
        try {
            if ((Get-NetAppHost).count -gt 0) {
                Section -Style Heading3 'NetApp Ontap Storage' {
                    Paragraph "Returns NetApp storage volumes added to the backup infrastructure."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        try {
                            $OntapObjs = Get-NetAppHost
                            foreach ($OntapObj in $OntapObjs) {
                                Section -Style Heading4 "$($OntapObj.Name)" {
                                    try {
                                        Write-PscriboMessage "Discovered $($OntapObj.Name) NetApp Host."
                                        $inObj = [ordered] @{
                                            'DnsName' = Switch (($OntapObj.Info.HostInstanceId).count) {
                                                0 {$OntapObj.Info.DnsName}
                                                default {$OntapObj.Info.HostInstanceId}
                                            }
                                            'Type' = $OntapObj.NaOptions.HostType
                                            'ConnPoints' = $OntapObj.ConnPoints
                                            'Credential' = (Get-VBRCredentials | Where-Object { $_.Id -eq $OntapObj.Info.CredsId }).Description
                                            'License' = $OntapObj.NaOptions.License
                                            'Description' = $OntapObj.Description
                                        }

                                        $OutObj = [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "NetApp Host - $($OntapObj.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
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