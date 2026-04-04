
function Get-AbrVbrStorageIsilon {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Dell Isilon Storage Information
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.24
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
        $LocalizedData = $reportTranslate.GetAbrVbrStorageIsilon
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Dell Isilon Storage'
    }

    process {
        if ($IsilonHosts = Get-VBRIsilonHost) {
            Section -Style Heading3 $LocalizedData.Heading {
                Paragraph $LocalizedData.Paragraph
                BlankLine
                $OutObj = @()
                foreach ($IsilonHost in $IsilonHosts) {
                    Section -Style Heading4 $($IsilonHost.Name) {
                        try {

                            $UsedCred = Get-VBRCredentials | Where-Object { $_.Id -eq $IsilonHost.Info.CredsId }
                            $IsilonOptions = [xml]$IsilonHost.info.Options
                            $inObj = [ordered] @{
                                $LocalizedData.DNSName = switch (($IsilonHost.Info.HostInstanceId).count) {
                                    0 { $IsilonHost.Info.DnsName }
                                    default { $IsilonHost.Info.HostInstanceId }
                                }
                                $LocalizedData.Description = $IsilonHost.Description
                                $LocalizedData.UsedCredential = switch (($UsedCred).count) {
                                    0 { '--' }
                                    default { "$($UsedCred.Name) - ($($UsedCred.Description))" }
                                }
                                $LocalizedData.ConnectionAddress = $IsilonOptions.IsilonHostOptions.AdditionalAddresses.IP -join ', '
                                $LocalizedData.ConnectionPort = "$($IsilonOptions.IsilonHostOptions.Port)\TCP"
                            }

                            $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                            $TableParams = @{
                                Name = "$($LocalizedData.IsilonHostTableHeading) - $($IsilonHost.Name)"
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
                                        Section -Style NOTOCHeading5 -ExcludeFromTOC $LocalizedData.VolumesSubHeading {
                                            $OutObj = @()
                                            foreach ($IsilonVol in $IsilonVols) {
                                                try {

                                                    $inObj = [ordered] @{
                                                        $LocalizedData.Name = $IsilonVol.Name
                                                        $LocalizedData.TotalSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $IsilonVol.Size
                                                        $LocalizedData.UsedSpace = ConvertTo-FileSizeString -RoundUnits $Options.RoundUnits -Size $IsilonVol.ConsumedSpace
                                                        $LocalizedData.ThinProvision = $IsilonVol.IsThinProvision
                                                    }

                                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Dell Isilon Storage $($IsilonVol.Name) Volumes Section: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "$($LocalizedData.IsilonVolumesTableHeading) - $($IsilonHost.Name)"
                                                List = $false
                                                ColumnWidths = 52, 15, 15, 18
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property $LocalizedData.Name | Table @TableParams
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
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Dell Isilon Storage'
    }

}