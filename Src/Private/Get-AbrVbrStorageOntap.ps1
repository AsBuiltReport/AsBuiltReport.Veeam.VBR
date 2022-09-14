
function Get-AbrVbrStorageOntap {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve NetApp Ontap Storage Information
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
        Write-PscriboMessage "Discovering NetApp Ontap Storage information connected to $System."
    }

    process {
        try {
            if ((Get-NetAppHost).count -gt 0) {
                Section -Style Heading3 'NetApp Ontap Storage' {
                    Paragraph "The following section details information about NetApp storage infrastructure."
                    BlankLine
                    $OutObj = @()
                    try {
                        $OntapHosts = Get-NetAppHost
                        foreach ($OntapHost in $OntapHosts) {
                            Section -Style Heading4 $($OntapHost.Name) {
                                try {
                                    Write-PscriboMessage "Discovered $($OntapHost.Name) NetApp Host."
                                    $UsedCred = Get-VBRCredentials | Where-Object { $_.Id -eq $OntapHost.Info.CredsId}
                                    $OntapOptions = [xml]$OntapHost.info.Options
                                    $inObj = [ordered] @{
                                        'DNS Name' = Switch (($OntapHost.Info.HostInstanceId).count) {
                                            0 {$OntapHost.Info.DnsName}
                                            default {$OntapHost.Info.HostInstanceId}
                                        }
                                        'Description' = $OntapHost.Description
                                        'Storage Type' = $OntapHost.NaOptions.HostType
                                        'Used Credential' = Switch (($UsedCred).count) {
                                            0 {"-"}
                                            default {"$($UsedCred.Name) - ($($UsedCred.Description))"}
                                        }
                                        'Connection Address' = $OntapHost.ConnPoints -join ", "
                                        'Connection Port' =  "$($OntapOptions.NaHostOptions.NaHostOptions.NaHostConnectionOptions.Port)\TCP"
                                        'Installed Licenses' = $OntapHost.NaOptions.License
                                    }

                                    $OutObj = [pscustomobject]$inobj

                                    $TableParams = @{
                                        Name = "NetApp Host - $($OntapHost.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    if ($InfoLevel.Storage.Ontap -ge 2) {
                                        try {
                                            $OntapVols = Get-NetAppVolume -Host $OntapHost
                                            if ($OntapVols) {
                                                Section -Style NOTOCHeading5 -ExcludeFromTOC 'Volumes' {
                                                    $OutObj = @()
                                                    foreach ($OntapVol in $OntapVols) {
                                                        try {
                                                            Write-PscriboMessage "Discovered $($OntapVol.Name) NetApp Volume."
                                                            $inObj = [ordered] @{
                                                                'Name' = $OntapVol.Name
                                                                'Total Space' = ConvertTo-FileSizeString $OntapVol.Size
                                                                'Used Space' = ConvertTo-FileSizeString $OntapVol.ConsumedSpace
                                                                'Thin Provision' = ConvertTo-TextYN $OntapVol.IsThinProvision
                                                            }

                                                            $OutObj += [pscustomobject]$inobj
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                                        }
                                                    }

                                                    $TableParams = @{
                                                        Name = "NetApp Volumes - $($OntapHost.Name)"
                                                        List = $false
                                                        ColumnWidths = 52, 15, 15, 18
                                                    }

                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    $OutObj | Table @TableParams
                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }
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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}