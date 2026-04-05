
function Get-AbrVbrKMSInfo {
    <#
    .SYNOPSIS
    Used by As Built Report to returns KMS configuration.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        1.0.0
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
        Write-PScriboMessage "Discovering Veeam VBR Key Management Server information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrKMSInfo
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Key Management Server'
    }

    process {
        try {
            if ($KMSServers = Get-VBRKMSServer | Sort-Object -Property Name) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($KMSServer in $KMSServers) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $KMSServer.Name
                                $LocalizedData.CACertificate = $KMSServer.CACertificate
                                $LocalizedData.ClientCertificate = $KMSServer.ClientCertificate
                                $LocalizedData.Port = "TCP/$($KMSServer.Port)"
                                $LocalizedData.Description = $KMSServer.Description
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Key Management Server $($KMSServer.Name) Section: $($_.Exception.Message)"
                        }
                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $($KMSServer.Name)"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Key Management Server Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Key Management Server'

    }

}