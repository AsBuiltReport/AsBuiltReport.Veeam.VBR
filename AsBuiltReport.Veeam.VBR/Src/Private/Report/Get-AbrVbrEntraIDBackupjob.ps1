
function Get-AbrVbrEntraIDBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns entraid jobs created in Veeam Backup & Replication.
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
        Write-PScriboMessage "Discovering Veeam VBR EntraID Tenant Backup jobs information from $System."
        $LocalizedData = $reportTranslate.GetAbrVbrEntraIDBackupjob
        Show-AbrDebugExecutionTime -Start -TitleMessage 'EntraID Tenant Backup Jobs'
    }

    process {
        try {
            if ($Bkjobs = Get-VBREntraIDTenantBackupJob | Sort-Object -Property 'Name') {
                Section -Style Heading3 $LocalizedData.Heading {
                    Paragraph $LocalizedData.Paragraph
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {

                            $inObj = [ordered] @{
                                $LocalizedData.Name = $Bkjob.Name
                                $LocalizedData.Tenant = $Bkjob.Tenant.Name
                                $LocalizedData.ScheduleStatus = switch ($Bkjob.EnableSchedule) {
                                    'False' { $LocalizedData.NotScheduled }
                                    'True' { $LocalizedData.Scheduled }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "EntraID Tenant Backup Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 40, 40, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property $LocalizedData.Tenant | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "EntraID Tenant Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'EntraID Tenant Backup Jobs'
    }
}