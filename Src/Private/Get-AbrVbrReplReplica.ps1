
function Get-AbrVbrReplReplica {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Replica Information.
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
        Write-PScriboMessage "Discovering Veeam VBR Replicas from $System."
    }

    process {
        try {
            if ($Replicas = Get-VBRReplica | Sort-Object -Property VmName) {
                if ($InfoLevel.Replication.Replica -eq 1) {
                    Section -Style Heading3 'Replicas' {
                        Paragraph "The following section details replica information from Veeam Server $VeeamBackupServer."
                        BlankLine
                        $OutObj = @()
                        foreach ($Replica in $Replicas) {
                            foreach ($VM in $Replica.GetBackupReplicas()) {
                                $inObj = [ordered] @{
                                    'VM Name' = $VM.VmName
                                    'Job Name' = $Replica.JobName
                                    'Type' = $Replica.TypeToString
                                    'State' = $VM.State
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }
                        }

                        if ($HealthCheck.Replication.Replica) {
                            $OutObj | Where-Object { $_.'State' -ne 'Ready' } | Set-Style -Style Warning -Property 'State'
                        }

                        $TableParams = @{
                            Name = "Replicas - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 34, 34, 22, 10
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property 'Job Name' | Table @TableParams
                    }
                }
                if ($InfoLevel.Replication.Replica -ge 2) {
                    try {
                        Section -Style Heading3 'Replicas' {
                            Paragraph "The following section details replica information from Veeam Server $VeeamBackupServer."
                            BlankLine
                            $OutObj = @()
                            foreach ($Replica in $Replicas) {
                                try {
                                    foreach ($VM in $Replica.GetBackupReplicas() | Sort-Object -Property VMName) {
                                        $inObj = [ordered] @{
                                            'VM Name' = $VM.VmName
                                            'Target Vm Name' = $VM.TargetVmName
                                            'Original Location' = $VM.info.SourceLocation
                                            'Destination Location' = $VM.info.TargetLocation
                                            'Job Name' = $Replica.JobName
                                            'State' = $VM.State
                                            'Type' = $Replica.TypeToString
                                            'Restore Points' = ($VM | Get-VBRRestorePoint).count
                                            'Creation Time' = $Replica.CreationTime

                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Replication.Replica) {
                                            $OutObj | Where-Object { $_.'State' -ne 'Ready' } | Set-Style -Style Warning -Property 'State'
                                        }

                                        $TableParams = @{
                                            Name = "$($Replica.JobName) - $($VM.VmName)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Replica $($Replica.JobName) Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Replica Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Replica Section: $($_.Exception.Message)"
        }
    }
    end {}

}