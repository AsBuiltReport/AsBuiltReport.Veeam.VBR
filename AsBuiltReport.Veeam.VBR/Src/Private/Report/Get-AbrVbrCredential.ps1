
function Get-AbrVbrCredential {
    <#
    .SYNOPSIS
    Used by As Built Report to returns credentials managed by Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR credential information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrCredential
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Veeam VBR Credential'
    }

    process {
        try {
            if ($Credentials = Get-VBRCredentials) {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($Credential in $Credentials) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $Credential.Name
                                $LocalizedData.ChangeTime = switch ($Credential.ChangeTimeUtc) {
                                    '' { '--'; break }
                                    $Null { '--'; break }
                                    default { $Credential.ChangeTimeUtc.ToShortDateString() }
                                }
                                $LocalizedData.Description = $Credential.Description
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "Security Credentials $($Credential.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 35, 20, 45
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                    try {
                        if ($CloudCredentials = Get-VBRCloudProviderCredentials) {
                            Section -Style Heading4 $LocalizedData.ServiceProviderHeading {
                                Paragraph $LocalizedData.ServiceProviderParagraph
                                BlankLine
                                $OutObj = @()
                                foreach ($CloudCredential in $CloudCredentials) {
                                    try {

                                        $inObj = [ordered] @{
                                            $LocalizedData.Name = $CloudCredential.Name
                                            $LocalizedData.Description = $CloudCredential.Description
                                        }
                                        $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                    } catch {
                                        Write-PScriboMessage -IsWarning "Service Provider Credentials $($CloudCredential.Name) Section: $($_.Exception.Message)"
                                    }
                                }

                                $TableParams = @{
                                    Name = "$($LocalizedData.ServiceProviderTableHeading) - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 50, 50
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Service Provider Credentials Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Security Credentials Section: $($_.Exception.Message)"
            Show-AbrDebugExecutionTime -End -TitleMessage 'Veeam VBR Credential'
        }
    }
    end {}

}