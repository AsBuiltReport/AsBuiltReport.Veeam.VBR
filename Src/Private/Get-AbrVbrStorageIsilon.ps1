
function Get-AbrVbrStorageIsilon {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Dell Isilon Storage Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.11
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
        Write-PScriboMessage "Discovering Dell Isilon Storage information connected to $System."
    }

    process {
        if ($IsilonHosts = Get-VBRIsilonHost) {
            Section -Style Heading3 'Dell Isilon Storage' {
                Paragraph "The following section details information about Dell storage infrastructure."
                BlankLine
                $OutObj = @()
                foreach ($IsilonHost in $IsilonHosts) {
                    Section -Style Heading4 $($IsilonHost.Name) {
                        try {
                            Write-PScriboMessage "Discovered $($IsilonHost.Name) Isilon Host."
                            $UsedCred = Get-VBRCredentials | Where-Object { $_.Id -eq $IsilonHost.Info.CredsId }
                            $IsilonOptions = [xml]$IsilonHost.info.Options
                            $inObj = [ordered] @{
                                'DNS Name' = Switch (($IsilonHost.Info.HostInstanceId).count) {
                                    0 { $IsilonHost.Info.DnsName }
                                    default { $IsilonHost.Info.HostInstanceId }
                                }
                                'Description' = $IsilonHost.Description
                                'Used Credential' = Switch (($UsedCred).count) {
                                    0 { "--" }
                                    default { "$($UsedCred.Name) - ($($UsedCred.Description))" }
                                }
                                'Connection Address' = $IsilonOptions.IsilonHostOptions.AdditionalAddresses.IP -join ", "
                                'Connection Port' = "$($IsilonOptions.IsilonHostOptions.Port)\TCP"
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
                                    if ($IsilonVols = Get-VBRIsilonVolume -Host $IsilonHost) {
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC 'Volumes' {
                                            $OutObj = @()
                                            foreach ($IsilonVol in $IsilonVols) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($IsilonVol.Name) NetApp Volume."
                                                    $inObj = [ordered] @{
                                                        'Name' = $IsilonVol.Name
                                                        'Total Space' = ConvertTo-FileSizeString -Size  $IsilonVol.Size
                                                        'Used Space' = ConvertTo-FileSizeString -Size  $IsilonVol.ConsumedSpace
                                                        'Thin Provision' = ConvertTo-TextYN $IsilonVol.IsThinProvision
                                                    }

                                                    $OutObj += [pscustomobject]$inobj
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Dell Isilon Storage $($IsilonVol.Name) Volumes Section: $($_.Exception.Message)"
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
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Dell Isilon Storage Volume Section: $($_.Exception.Message)"
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Dell Isilon Storage Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        }
    }
    end {}

}