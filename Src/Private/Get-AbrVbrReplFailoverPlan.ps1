
function Get-AbrVbrReplFailoverPlan {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam VBR Failover Plan Information.
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
        Write-PscriboMessage "Discovering Veeam VBR Failover Plans from $System."
    }

    process {
        try {
            $FailOverPlans = Get-VBRFailoverPlan
            if ($FailOverPlans) {
                Section -Style Heading3 'Failover Plans' {
                    Paragraph "The following section details failover plan information from Veeam Server $(((Get-VBRServerSession).Server))."
                    $OutObj = @()
                    foreach ($FailOverPlan in $FailOverPlans) {
                        try {
                            Section -Style Heading4 $($FailOverPlan.Name) {
                                $inObj = [ordered] @{
                                    'Platform' = $FailOverPlan.Platform
                                    'Status' = $FailOverPlan.Status
                                    'Pre Failover Script Enabled' = ConvertTo-TextYN $FailOverPlan.PreFailoverScriptEnabled
                                    'Pre Failover Command' = ConvertTo-EmptyToFiller $FailOverPlan.PrefailoverCommand
                                    'Post Failover Script Enabled' = ConvertTo-TextYN $FailOverPlan.PostFailoverScriptEnabled
                                    'Post Failover Command' = ConvertTo-EmptyToFiller $FailOverPlan.PostfailoverCommand
                                    'VM Count' = $FailOverPlan.VmCount
                                    'Description' = $FailOverPlan.Description
                                }
                                $OutObj = [pscustomobject]$inobj

                                $TableParams = @{
                                    Name = "Failover Plan - $($FailOverPlan.Name)"
                                    List = $true
                                    ColumnWidths = 40, 60
                                }
                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                                if ($InfoLevel.Replication.FailoverPlan -ge 2) {
                                    if ($FailOverPlan) {
                                        try {
                                            Section -Style NOTOCHeading5 -ExcludeFromTOC 'Virtual Machines' {
                                                $OutObj = @()
                                                foreach ($FailOverPlansVM in $FailOverPlan.FailoverPlanObject) {
                                                    try {
                                                        if ($FailOverPlan.Platform -eq 'VMWare') {
                                                            Write-PscriboMessage "Discovering $($FailOverPlan.Name) VMware VM information."
                                                            $VMInfo = Find-VBRViEntity -Name $FailOverPlansVM
                                                        } Else {
                                                            Write-PscriboMessage "Discovering $($FailOverPlan.Name) Hyper-V VM information."
                                                            $VMInfo = Find-VBRHvEntity -Name $FailOverPlansVM
                                                        }
                                                        if ($VMInfo) {
                                                            Write-PscriboMessage "Discovered $($VMInfo.Name) VM information."
                                                        }
                                                        $inObj = [ordered] @{
                                                            'VM Name' = Switch ($VMInfo.Name) {
                                                                $Null {'Unknown'}
                                                                default {$VMInfo.Name}
                                                            }
                                                            'Boot Order' = $FailOverPlansVM.BootOrder
                                                            'Boot Delay' = $FailOverPlansVM.BootDelay
                                                        }
                                                        $OutObj += [pscustomobject]$inobj
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                }

                                                $TableParams = @{
                                                    Name = "Virtual Machines - $($FailOverPlan.Name)"
                                                    List = $false
                                                    ColumnWidths = 40, 30, 30
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                $OutObj | Sort-Object -Property 'Job Name' | Table @TableParams
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
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
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}