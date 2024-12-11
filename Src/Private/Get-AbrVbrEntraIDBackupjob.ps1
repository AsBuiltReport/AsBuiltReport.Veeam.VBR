
function Get-AbrVbrEntraIDBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns entraid jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.13
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
    }

    process {
        try {
            if ($Bkjobs = Get-VBREntraIDTenantBackupJob | Sort-Object -Property 'Name') {
                Section -Style Heading3 'EntraID Tenant Backup Jobs' {
                    Paragraph "The following section list entraid tenant jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    foreach ($Bkjob in $Bkjobs) {
                        try {
                            Write-PScriboMessage "Discovered $($Bkjob.Name) Backup Job."
                            $inObj = [ordered] @{
                                'Name' = $Bkjob.Name
                                'Tenant' = $Bkjob.Tenant.Name
                                'Schedule Status' = Switch ($Bkjob.EnableSchedule) {
                                    'False' { 'Not Scheduled' }
                                    'True' { 'Scheduled' }
                                }
                            }
                            $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                        } catch {
                            Write-PScriboMessage -IsWarning "EntraID Tenant Backup Jobs $($SBkjob.Name) Section: $($_.Exception.Message)"
                        }
                    }

                    $TableParams = @{
                        Name = "EntraID Tenant Backup Jobs - $VeeamBackupServer"
                        List = $false
                        ColumnWidths = 40, 40, 20
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Sort-Object -Property 'Tenant' | Table @TableParams
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "EntraID Tenant Backup Jobs Section: $($_.Exception.Message)"
        }
    }
    end {}
}