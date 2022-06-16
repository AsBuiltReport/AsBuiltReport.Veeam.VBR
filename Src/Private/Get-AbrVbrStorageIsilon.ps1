
function Get-AbrVbrStorageIsilon {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Dell Isilon Storage Information
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
        Write-PscriboMessage "Discovering Dell Isilon Storage information connected to $System."
    }

    process {
        try {
            if ((Get-VBRIsilonHost).count -gt 0) {
                Section -Style Heading3 'Dell Isilon Storage' {
                    Paragraph "The following section details information about Dell storage infrastructure."
                    BlankLine
                    $OutObj = @()
                    try {
                        $IsilonHosts = Get-VBRIsilonHost
                        foreach ($IsilonHost in $IsilonHosts) {
                            Section -Style Heading4 "$($IsilonHost.Name)" {
                                try {
                                    Write-PscriboMessage "Discovered $($IsilonHost.Name) Isilon Host."
                                    $UsedCred = Get-VBRCredentials | Where-Object { $_.Id -eq $IsilonHost.Info.CredsId}
                                    $IsilonOptions = [xml]$IsilonHost.info.Options
                                    $inObj = [ordered] @{
                                        'DNS Name' = Switch (($IsilonHost.Info.HostInstanceId).count) {
                                            0 {$IsilonHost.Info.DnsName}
                                            default {$IsilonHost.Info.HostInstanceId}
                                        }
                                        'Description' = $IsilonHost.Description
                                        'Used Credential' = Switch (($UsedCred).count) {
                                            0 {"-"}
                                            default {"$($UsedCred.Name) - ($($UsedCred.Description))"}
                                        }
                                        'Connnection Address' = $IsilonOptions.IsilonHostOptions.AdditionalAddresses.IP -join ", "
                                        'Connnection Port' =  "$($IsilonOptions.IsilonHostOptions.Port)\TCP"
                                    }

                                    $OutObj = [pscustomobject]$inobj

                                    $TableParams = @{
                                        Name = "Isilon Host - $($IsilonHost.Name)"
                                        List = $true
                                        ColumnWidths = 40, 60
                                    }

                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Table @TableParams
                                    if ($InfoLevel.Storage.Isilon -ge 2) {
                                        try {
                                            $IsilonVols = Get-VBRIsilonVolume -Host $IsilonHost
                                            if ($IsilonVols) {
                                                Section -Style Heading5 'Volumes' {
                                                    $OutObj = @()
                                                    foreach ($IsilonVol in $IsilonVols) {
                                                        try {
                                                            Write-PscriboMessage "Discovered $($IsilonVol.Name) NetApp Volume."
                                                            $inObj = [ordered] @{
                                                                'Name' = $IsilonVol.Name
                                                                'Total Space' = ConvertTo-FileSizeString $IsilonVol.Size
                                                                'Used Space' = ConvertTo-FileSizeString $IsilonVol.ConsumedSpace
                                                                'Thin Provision' = ConvertTo-TextYN $IsilonVol.IsThinProvision
                                                            }

                                                            $OutObj += [pscustomobject]$inobj
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                                        }
                                                    }

                                                    $TableParams = @{
                                                        Name = "Isilon Volumes - $($IsilonHost.Name)"
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