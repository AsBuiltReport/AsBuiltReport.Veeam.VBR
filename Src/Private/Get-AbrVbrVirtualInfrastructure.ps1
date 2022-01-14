
function Get-AbrVbrVirtualInfrastructure {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam Virtual Infrastructure inventory
    .DESCRIPTION
    .NOTES
        Version:        0.2.0
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR Virtual Infrastructure inventory from $System."
    }

    process {
        if ((Get-VBRServer).count -gt 0) {
            Section -Style Heading3 'Virtual Infrastructure' {
                Paragraph "The following section provides inventory information of the Veeam VirtualInfrastructure"
                if ((Get-VBRServerSession).Server) {
                    try {
                        Section -Style Heading4 'VMware vSphere' {
                            Section -Style Heading4 'VMware vCenter' {
                                $OutObj = @()
                                $InventObjs = Get-VBRServer | Where-Object {$_.Type -eq 'VC'}
                                foreach ($InventObj in $InventObjs) {
                                    try {
                                        Write-PscriboMessage "Discovered $($InventObj.Name) vCenter Server."
                                        $inObj = [ordered] @{
                                            'Name' = $InventObj.Name
                                            'Version' = ($InventObj).Info.Info
                                            'Child Host' = $InventObj.GetChilds().Name -join ", "
                                        }

                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "vCenter Servers - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                    List = $false
                                    ColumnWidths = 33, 33, 34
                                }

                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            }
                            try {
                                Section -Style Heading4 'Esxi Host' {
                                    $OutObj = @()
                                    $InventObjs = Get-VBRServer | Where-Object {$_.Type -eq 'ESXi'}
                                    foreach ($InventObj in $InventObjs) {
                                        try {
                                            Write-PscriboMessage "Discovered $($InventObj.Name) ESXi Host."
                                            $inObj = [ordered] @{
                                                'Name' = $InventObj.Name
                                                'Version' = ($InventObj).Info.Info
                                                #'Connected Vcenter' = (Find-VBRViEntity -Name $InventObj.Name).Path.split("\")[0]
                                            }

                                            $OutObj += [pscustomobject]$inobj
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "Esxi Hosts - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                        List = $false
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
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                    try {
                        Section -Style Heading4 'Microsoft Hyper-V' {
                            Section -Style Heading4 'Hyper-V Clusters' {
                                $OutObj = @()
                                $InventObjs = Get-VBRServer | Where-Object {$_.Type -eq 'HvCluster'}
                                foreach ($InventObj in $InventObjs) {
                                    try {
                                        Write-PscriboMessage "Discovered $($InventObj.Name) Hyper-V Cluster."
                                        $inObj = [ordered] @{
                                            'Name' = $InventObj.Name
                                            'Credentials' = ($InventObj).ProxyServicesCreds.Name
                                            'Child Host' = $InventObj.GetChilds().Name -join ", "
                                        }

                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "Hyper-V Clusters - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                    List = $false
                                    ColumnWidths = 34, 33, 33
                                }

                                if ($Report.ShowTableCaptions) {
                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                }
                                $OutObj | Table @TableParams
                            }
                            try {
                                Section -Style Heading4 'Hyper-V Host' {
                                    $OutObj = @()
                                    $InventObjs = Get-VBRServer | Where-Object {$_.Type -eq 'HvServer'}
                                    foreach ($InventObj in $InventObjs) {
                                        try {
                                            Write-PscriboMessage "Discovered $($InventObj.Name) Hyper-V Host."
                                            $inObj = [ordered] @{
                                                'Name' = $InventObj.Name
                                                'Version' = ($InventObj).Info.Info
                                                #'Hyper-V CLuster' = (Find-VBRHvEntity -Name $InventObj.Name).Path.split("\")[0]
                                            }

                                            $OutObj += [pscustomobject]$inobj
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "Hyper-V Hosts - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                                        List = $false
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
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
        }
    }
    end {}

}