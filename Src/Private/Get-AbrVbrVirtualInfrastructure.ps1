
function Get-AbrVbrVirtualInfrastructure {
    <#
    .SYNOPSIS
        Used by As Built Report to retrieve Veeam Virtual Infrastructure inventory
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.5
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
        Write-PScriboMessage "Discovering Veeam VBR Virtual Infrastructure inventory from $System."
    }

    process {
        try {
            $VbrServer = Get-VBRServer
            if ($VbrServer) {
                Section -Style Heading3 'Virtual Infrastructure' {
                    Paragraph "The following sections detail the configuration about managed virtual servers backed-up by Veeam Server $(((Get-VBRServerSession).Server))."
                    BlankLine
                    #---------------------------------------------------------------------------------------------#
                    #                            VMware vSphere information Section                               #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        if ($VbrServer | Where-Object { $_.Type -eq 'VC' -or $_.Type -eq 'ESXi' }) {
                            Section -Style Heading4 'VMware vSphere' {
                                Paragraph "The following section details information about VMware Virtual Infrastructure backed-up by Veeam Server $(((Get-VBRServerSession).Server))."
                                BlankLine
                                $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'VC' }
                                if ($InventObjs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'VMware vCenter' {
                                        $OutObj = @()
                                        foreach ($InventObj in $InventObjs) {
                                            try {
                                                Write-PScriboMessage "Discovered $($InventObj.Name) vCenter Server."
                                                $inObj = [ordered] @{
                                                    'Name' = $InventObj.Name
                                                    'Version' = ($InventObj).Info.Info
                                                    'Child Host' = $InventObj.GetChilds().Name -join ", "
                                                }

                                                $OutObj += [pscustomobject]$inobj
                                            } catch {
                                                Write-PScriboMessage -IsWarning "VMware vCenter $($InventObj.Name) Table: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "vCenter Servers - $VeeamBackupServer"
                                            List = $false
                                            ColumnWidths = 33, 33, 34
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                    }
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                            VMware Esxi information Section                                  #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'ESXi' }
                                    if ($InventObjs) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Esxi Host' {
                                            $OutObj = @()
                                            foreach ($InventObj in $InventObjs) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($InventObj.Name) ESXi Host."
                                                    $inObj = [ordered] @{
                                                        'Name' = $InventObj.Name
                                                        'Version' = ($InventObj).Info.Info
                                                        #'Connected Vcenter' = (Find-VBRViEntity -Name $InventObj.Name).Path.split("\")[0]
                                                    }

                                                    $OutObj += [pscustomobject]$inobj
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Esxi Host $($InventObj.Name) Table: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Esxi Hosts - $VeeamBackupServer"
                                                List = $false
                                                ColumnWidths = 40, 60
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Esxi Host Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "VMware vSphere Section: $($_.Exception.Message)"
                    }
                    #---------------------------------------------------------------------------------------------#
                    #                         Microsoft Hyper-V Cluster information Section                       #
                    #---------------------------------------------------------------------------------------------#
                    try {
                        if ($VbrServer | Where-Object { $_.Type -eq 'HvCluster' -or $_.Type -eq 'HvServer' }) {
                            Section -Style Heading4 'Microsoft Hyper-V' {
                                $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'HvCluster' }
                                if ($InventObjs) {
                                    Section -Style NOTOCHeading5 -ExcludeFromTOC 'Hyper-V Clusters' {
                                        $OutObj = @()
                                        foreach ($InventObj in $InventObjs) {
                                            try {
                                                Write-PScriboMessage "Discovered $($InventObj.Name) Hyper-V Cluster."
                                                $inObj = [ordered] @{
                                                    'Name' = $InventObj.Name
                                                    'Credentials' = ($InventObj).ProxyServicesCreds.Name
                                                    'Child Host' = $InventObj.GetChilds().Name -join ", "
                                                }

                                                $OutObj += [pscustomobject]$inobj
                                            } catch {
                                                Write-PScriboMessage -IsWarning "Hyper-V Clusters $($InventObj.Name) Table: $($_.Exception.Message)"
                                            }
                                        }

                                        $TableParams = @{
                                            Name = "Hyper-V Clusters - $VeeamBackupServer"
                                            List = $false
                                            ColumnWidths = 34, 33, 33
                                        }

                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Sort-Object -Property 'Name' |  Table @TableParams
                                    }
                                }
                                #---------------------------------------------------------------------------------------------#
                                #                         Microsoft Hyper-V Host information Section                          #
                                #---------------------------------------------------------------------------------------------#
                                try {
                                    $InventObjs = $VbrServer | Where-Object { $_.Type -eq 'HvServer' }
                                    if ($InventObjs) {
                                        Section -Style NOTOCHeading6 -ExcludeFromTOC 'Hyper-V Host' {
                                            $OutObj = @()
                                            foreach ($InventObj in $InventObjs) {
                                                try {
                                                    Write-PScriboMessage "Discovered $($InventObj.Name) Hyper-V Host."
                                                    $inObj = [ordered] @{
                                                        'Name' = $InventObj.Name
                                                        'Version' = ($InventObj).Info.Info
                                                        #'Hyper-V CLuster' = (Find-VBRHvEntity -Name $InventObj.Name).Path.split("\")[0]
                                                    }

                                                    $OutObj += [pscustomobject]$inobj
                                                } catch {
                                                    Write-PScriboMessage -IsWarning "Hyper-V Host $($InventObj.Name) Table: $($_.Exception.Message)"
                                                }
                                            }

                                            $TableParams = @{
                                                Name = "Hyper-V Hosts - $VeeamBackupServer"
                                                List = $false
                                                ColumnWidths = 40, 60
                                            }

                                            if ($Report.ShowTableCaptions) {
                                                $TableParams['Caption'] = "- $($TableParams.Name)"
                                            }
                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                        }
                                    }
                                } catch {
                                    Write-PScriboMessage -IsWarning "Hyper-V Host Section: $($_.Exception.Message)"
                                }
                            }
                        }
                    } catch {
                        Write-PScriboMessage -IsWarning "Microsoft Hyper-V Section: $($_.Exception.Message)"
                    }
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Virtual Infrastructure Section: $($_.Exception.Message)"
        }
    }
    end {}

}