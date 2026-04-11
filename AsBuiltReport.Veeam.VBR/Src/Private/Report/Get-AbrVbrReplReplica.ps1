
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
        $LocalizedData = $reportTranslate.GetAbrVbrReplReplica
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Replicas'
    }

    process {
        try {
            if ($Replicas = Get-VBRReplica | Sort-Object -Property VmName) {
                if ($InfoLevel.Replication.Replica -eq 1) {
                    Section -Style Heading3 $LocalizedData.Heading {
                        Paragraph ($LocalizedData.Paragraph -f $VeeamBackupServer)
                        BlankLine
                        $OutObj = @()
                        foreach ($Replica in $Replicas) {
                            foreach ($VM in $Replica.GetBackupReplicas()) {
                                $inObj = [ordered] @{
                                    $LocalizedData.VMName = $VM.VmName
                                    $LocalizedData.JobName = $Replica.JobName
                                    $LocalizedData.Type = $Replica.TypeToString
                                    $LocalizedData.State = $VM.State
                                }
                                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
                            }
                        }

                        if ($HealthCheck.Replication.Replica) {
                            $OutObj | Where-Object { $_.$($LocalizedData.State) -ne 'Ready' } | Set-Style -Style Warning -Property $LocalizedData.State
                        }

                        $TableParams = @{
                            Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                            List = $false
                            ColumnWidths = 34, 34, 22, 10
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Sort-Object -Property $LocalizedData.JobName | Table @TableParams
                    }
                }
                if ($InfoLevel.Replication.Replica -ge 2) {
                    try {
                        Section -Style Heading3 $LocalizedData.Heading {
                            Paragraph ($LocalizedData.Paragraph2 -f $VeeamBackupServer)
                            BlankLine
                            $OutObj = @()
                            foreach ($Replica in $Replicas) {
                                try {
                                    foreach ($VM in $Replica.GetBackupReplicas() | Sort-Object -Property VMName) {
                                        $inObj = [ordered] @{
                                            $LocalizedData.VMName = $VM.VmName
                                            $LocalizedData.TargetVmName = $VM.TargetVmName
                                            $LocalizedData.OriginalLocation = $VM.info.SourceLocation
                                            $LocalizedData.DestinationLocation = $VM.info.TargetLocation
                                            $LocalizedData.JobName = $Replica.JobName
                                            $LocalizedData.State = $VM.State
                                            $LocalizedData.Type = $Replica.TypeToString
                                            $LocalizedData.RestorePoints = ($VM | Get-VBRRestorePoint).count
                                            $LocalizedData.CreationTime = $Replica.CreationTime

                                        }
                                        $OutObj = [pscustomobject](ConvertTo-HashToYN $inObj)

                                        if ($HealthCheck.Replication.Replica) {
                                            $OutObj | Where-Object { $_.$($LocalizedData.State) -ne 'Ready' } | Set-Style -Style Warning -Property $LocalizedData.State
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
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Replicas'
    }

}