
function Get-AbrVbrReplReplica {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Replica Information.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
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
        Write-PscriboMessage "Discovering Veeam VBR Replicas from $System."
    }

    process {
        try {
            try {
                $Replicas = Get-VBRReplica
                if ($Replicas) {
                    if ($InfoLevel.Replication.Replica -eq 1) {
                        Section -Style Heading3 'Replicas' {
                            Paragraph "The following section details replica information from Veeam Server $(((Get-VBRServerSession).Server))."
                            BlankLine
                            $OutObj = @()
                            foreach ($Replica in $Replicas) {
                                foreach ($VM in $Replica.GetBackupReplicas()) {
                                    $inObj = [ordered] @{
                                        'VM Name' = $VM.VmName
                                        'Job Name' = $Replica.JobName
                                        'Type' = $Replica.TypeToString
                                        'Restore Points' = ($VM | Get-VBRRestorePoint).count
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
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
                                Paragraph "The following section details replica information from Veeam Server $(((Get-VBRServerSession).Server))."
                                BlankLine
                                $OutObj = @()
                                foreach ($Replica in $Replicas) {
                                    try {
                                        foreach ($VM in $Replica.GetBackupReplicas()) {
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
                                            $OutObj = [pscustomobject]$inobj

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
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}