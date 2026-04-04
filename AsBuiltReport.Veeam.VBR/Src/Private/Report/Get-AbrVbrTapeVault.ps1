
function Get-AbrVbrTapeVault {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Tape Vault Information
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
        $LocalizedData = $reportTranslate.GetAbrVbrTapeVault
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Tape Vaults'
    }

    process {
        try {
            if ($VbrLicenses | Where-Object { $_.Edition -in @('EnterprisePlus', 'Enterprise') -and $_.Status -ne 'Expired' }) {
                if ($TapeObjs = Get-VBRTapeVault | Sort-Object -Property Name) {
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph $LocalizedData.Paragraph
                        BlankLine
                        $OutObj = @()
                        try {
                            foreach ($TapeObj in $TapeObjs) {
                                try {

                                    $inObj = [ordered] @{
                                        $LocalizedData.Name = $TapeObj.Name
                                        $LocalizedData.Description = $TapeObj.Description
                                        $LocalizedData.AutomaticProtect = $TapeObj.Protect
                                        $LocalizedData.Location = try {(Get-VBRLocation -Object $TapeObj -ErrorAction SilentlyContinue).Location} catch { '--' }
                                    }
                                    $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                                } catch {
                                    Write-PScriboMessage -IsWarning "Tape Vaults $($TapeObj.Name) Table: $($_.Exception.Message)"
                                }
                            }

                            if ($HealthCheck.Tape.BestPractice) {
                                $OutObj | Where-Object { $_.$LocalizedData.Description -eq '--' } | Set-Style -Style Warning -Property $LocalizedData.Description
                                $OutObj | Where-Object { $_.$LocalizedData.Description -match 'Created by' } | Set-Style -Style Warning -Property $LocalizedData.Description
                            }

                            $TableParams = @{
                                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                                List = $false
                                ColumnWidths = 32, 32, 16, 20
                            }

                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Table @TableParams
                            if ($HealthCheck.Tape.BestPractice) {
                                if ($OutObj | Where-Object { $_.$LocalizedData.Description -match 'Created by' -or $_.$LocalizedData.Description -eq '--' }) {
                                    Paragraph $LocalizedData.HealthCheck -Bold -Underline
                                    BlankLine
                                    Paragraph {
                                        Text $LocalizedData.BestPractice -Bold
                                        Text $LocalizedData.BPDescription
                                    }
                                    BlankLine
                                }
                            }
                        } catch {
                            Write-PScriboMessage -IsWarning "Tape Vaults Section: $($_.Exception.Message)"
                        }
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Tape Vaults Document: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Tape Vaults'
    }

}
