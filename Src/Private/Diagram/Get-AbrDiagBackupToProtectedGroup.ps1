function Get-AbrDiagBackupToProtectedGroup {
    <#
    .SYNOPSIS
        Function to build a Backup Server to Protected Group diagram.
    .DESCRIPTION
        Build a diagram of the configuration of Veeam VBR in PDF/PNG/SVG formats using Psgraph.
    .NOTES
        Version:        0.8.24
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
    #>
    [CmdletBinding()]

    param
    (

    )

    begin {
    }

    process {
        try {
            $ProtectedGroups = Get-AbrBackupProtectedGroupInfo
            $ADContainer = $ProtectedGroups | Where-Object { $_.Container -eq 'ActiveDirectory' }
            $ManualContainer = $ProtectedGroups | Where-Object { $_.Container -eq 'ManuallyDeployed' }
            $IndividualContainer = $ProtectedGroups | Where-Object { $_.Container -eq 'IndividualComputers' }
            $CSVContainer = $ProtectedGroups | Where-Object { $_.Container -eq 'CSV' }

            if ($ProtectedGroups.Container) {
                try {
                    $FileBackupProxy = Get-AbrBackupProxyInfo -Type 'nas'
                    if ($BackupServerInfo) {
                        if ($FileBackupProxy) {
                            if ($FileBackupProxy.Name.Count -eq 1) {
                                $FileBackupProxyColumnSize = 1
                            } elseif ($ColumnSize) {
                                $FileBackupProxyColumnSize = $ColumnSize
                            } else {
                                $FileBackupProxyColumnSize = $FileBackupProxy.Name.Count
                            }

                            Node FileProxies @{Label = (Add-HtmlNodeTable -Name 'FileProxies' -ImagesObj $Images -inputObject ($FileBackupProxy | ForEach-Object { $_.Name.split('.')[0] }) -Align 'Center' -iconType 'VBR_Proxy_Server' -ColumnSize $FileBackupProxyColumnSize -IconDebug $IconDebug -MultiIcon -AditionalInfo $FileBackupProxy.AditionalInfo -Subgraph -SubgraphIconType 'VBR_Proxy' -SubgraphLabel 'File Backup Proxies' -SubgraphLabelPos 'top' -SubgraphTableStyle 'dashed,rounded' -FontColor '#000000'-TableBorderColor $Edgecolor -TableBorder '1' -SubgraphLabelFontSize 24 -FontSize 18 -SubgraphFontBold -SubgraphLabelFontColor $Fontcolor); shape = 'plain'; fontsize = 14; fontname = 'Segoe Ui' }

                            Edge BackupServers -To FileProxies @{minlen = 3 }

                        }
                    }
                } catch {
                    Write-PScriboMessage $_.Exception.Message
                }
                if ($ProtectedGroups) {
                    $ComputerAgentsArray = @()
                    if ($ADContainer) {
                        try {
                            $ADCNodes = foreach ($PGOBJ in ($ADContainer | Sort-Object -Property Name)) {
                                $PGHASHTABLE = @{}
                                $PGOBJ.psobject.properties | ForEach-Object { $PGHASHTABLE[$_.Name] = $_.Value }

                                $Ous = @()

                                $Status = switch ($PGOBJ.Object.Enabled) {
                                    $true { 'Enabled' }
                                    $false { 'Disabled' }
                                    default { 'Unknown' }
                                }

                                $Ous += $PGOBJ.Object.Container.Entity | ForEach-Object {
                                    "<B>OUs</B> : $($_.DistinguishedName)"
                                }
                                $Rows = @(
                                    "<B>Type</B>: $($PGOBJ.Object.Type) <B>Status</B>: $($Status) <B>Schedule</B>: $($PGOBJ.Object.ScheduleOptions.PolicyType)"
                                    "<B>Domain</B> : $($PGOBJ.Object.Container.Domain) <B>Distribution Server</B> : $($PGOBJ.Object.DeploymentOptions.DistributionServer.Name)"
                                    $Ous
                                )

                                Convert-DiaTableToHTML -Label $PGOBJ.Name -Name $PGOBJ.Name -Row $Rows -HeaderColor '#005f4b' -HeaderFontColor 'white' -BorderColor 'black' -FontSize 14 -IconDebug $IconDebug -HTMLOutput $true
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create ADCNodes Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        if ($ADCNodes) {
                            if ($ADCNodes.Count -eq 1) {
                                $ADCNodesColumnSize = 1
                            } elseif ($ColumnSize) {
                                $ADCNodesColumnSize = $ColumnSize
                            } else {
                                $ADCNodesColumnSize = $ADCNodes.Count
                            }
                            try {
                                $ADCNodesSubgraph = Add-HtmlSubGraph -Name 'ADCNodesSubgraph' -ImagesObj $Images -TableArray $ADCNodes -Align 'Center' -IconDebug $IconDebug -Label 'Active Directory Computers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $ADCNodesColumnSize -IconType 'VBR_AGENT_AD' -FontSize 18 -FontBold
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create ADCNodesSubgraph Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                            $ComputerAgentsArray += $ADCNodesSubgraph
                        }
                    }
                    if ($ManualContainer) {
                        try {
                            $MCNodes = foreach ($PGOBJ in ($ManualContainer | Sort-Object -Property Name)) {
                                $PGHASHTABLE = @{}
                                $PGOBJ.psobject.properties | ForEach-Object { $PGHASHTABLE[$_.Name] = $_.Value }

                                $Status = switch ($PGOBJ.Enabled) {
                                    $true { 'Enabled' }
                                    $false { 'Disabled' }
                                    default { 'Unknown' }
                                }

                                $Rows = @(
                                    "<B>Type</B>: $($PGOBJ.Object.Type) <B>Status</B>: $($Status) <B>Schedule</B>: $($PGOBJ.Object.ScheduleOptions.PolicyType)"
                                )

                                Convert-DiaTableToHTML -Label $PGOBJ.Name -Name $PGOBJ.Name -Row $Rows -HeaderColor '#005f4b' -HeaderFontColor 'white' -BorderColor 'black' -FontSize 14 -IconDebug $IconDebug -HTMLOutput $true
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create MCNodes Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        if ($MCNodes) {
                            if ($MCNodes.Count -eq 1) {
                                $MCNodesColumnSize = 1
                            } elseif ($ColumnSize) {
                                $MCNodesColumnSize = $ColumnSize
                            } else {
                                $MCNodesColumnSize = $MCNodes.Count
                            }
                            try {
                                $MCNodesSubgraph = Add-HtmlSubGraph -Name 'MCNodesSubgraph' -ImagesObj $Images -TableArray $MCNodes -Align 'Center' -IconDebug $IconDebug -Label 'Manual Computers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $MCNodesColumnSize -IconType 'VBR_AGENT_MC' -FontSize 18 -FontBold
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create MCNodesSubgraph Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                            $ComputerAgentsArray += $MCNodesSubgraph
                        }
                    }
                    if ($IndividualContainer) {
                        try {
                            $ICCNodes = foreach ($PGOBJ in ($IndividualContainer | Sort-Object -Property Name)) {
                                $PGHASHTABLE = @{}
                                $PGOBJ.psobject.properties | ForEach-Object { $PGHASHTABLE[$_.Name] = $_.Value }

                                $Status = switch ($PGOBJ.Enabled) {
                                    $true { 'Enabled' }
                                    $false { 'Disabled' }
                                    default { 'Unknown' }
                                }


                                $Entities = @()
                                $Entities += $PGOBJ.Object.Container.CustomCredentials | ForEach-Object {
                                    "<B>Host Name</B> : $($_.HostName)"
                                }

                                $Rows = @(
                                    "<B>Type</B>: $($PGOBJ.Object.Type) <B>Status</B>: $($Status) <B>Schedule</B>: $($PGOBJ.Object.ScheduleOptions.PolicyType)"
                                    "<B>Distribution Server</B> : $($PGOBJ.Object.DeploymentOptions.DistributionServer.Name)"
                                    $Entities
                                )

                                Convert-DiaTableToHTML -Label $PGOBJ.Name -Name $PGOBJ.Name -Row $Rows -HeaderColor '#005f4b' -HeaderFontColor 'white' -BorderColor 'black' -FontSize 14 -IconDebug $IconDebug -HTMLOutput $true
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create ICCNodes Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        if ($ICCNodes) {
                            if ($ICCNodes.Count -eq 1) {
                                $ICCNodesColumnSize = 1
                            } elseif ($ColumnSize) {
                                $ICCNodesColumnSize = $ColumnSize
                            } else {
                                $ICCNodesColumnSize = $ICCNodes.Count
                            }
                            try {
                                $ICCNodesSubgraph = Add-HtmlSubGraph -Name 'ICCNodesSubgraph' -ImagesObj $Images -TableArray $ICCNodes -Align 'Center' -IconDebug $IconDebug -Label 'Individual Computers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $ICCNodesColumnSize -IconType 'VBR_AGENT_IC' -FontSize 18 -FontBold
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create ICCNodesSubgraph Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                            $ComputerAgentsArray += $ICCNodesSubgraph
                        }
                    }
                    if ($CSVContainer) {
                        try {
                            $CSVCNodes = foreach ($PGOBJ in ($CSVContainer | Sort-Object -Property Name)) {
                                $PGHASHTABLE = @{}
                                $PGOBJ.psobject.properties | ForEach-Object { $PGHASHTABLE[$_.Name] = $_.Value }
                                $Rows = @(
                                    "<B>Type</B>: $($PGOBJ.Object.Type) <B>Status</B>: $($Status) <B>Schedule</B>: $($PGOBJ.Object.ScheduleOptions.PolicyType)"
                                    "<B>Distribution Server</B> : $($PGOBJ.Object.DeploymentOptions.DistributionServer.Name)"
                                    "<B>CSV File</B> : $($PGOBJ.Object.Container.Path)"
                                    "<B>Credential</B> : $($PGOBJ.Object.Container.MasterCredentials.Name)"
                                )

                                Convert-DiaTableToHTML -Label $PGOBJ.Name -Name $PGOBJ.Name -Row $Rows -HeaderColor '#005f4b' -HeaderFontColor 'white' -BorderColor 'black' -FontSize 14 -IconDebug $IconDebug -HTMLOutput $true
                            }
                        } catch {
                            Write-PScriboMessage 'Error: Unable to create CSVCNodes Objects. Disabling the section'
                            Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                        }

                        if ($CSVCNodes) {
                            if ($CSVCNodes.Count -eq 1) {
                                $CSVCNodesColumnSize = 1
                            } elseif ($ColumnSize) {
                                $CSVCNodesColumnSize = $ColumnSize
                            } else {
                                $CSVCNodesColumnSize = $CSVCNodes.Count
                            }
                            try {
                                $CSVCNodesSubgraph = Add-HtmlSubGraph -Name 'CSVCNodesSubgraph' -ImagesObj $Images -TableArray $CSVCNodes -Align 'Center' -IconDebug $IconDebug -Label 'CSV Computers' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $CSVCNodesColumnSize -IconType 'VBR_AGENT_CSV_Logo' -FontSize 18 -FontBold
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create CSVCNodesSubgraph Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                            $ComputerAgentsArray += $CSVCNodesSubgraph
                        }
                    }

                    if ($ComputerAgentsArray) {
                        if ($ComputerAgentsArray.Count -eq 1) {
                            $ComputerAgentsArrayColumnSize = 1
                        } elseif ($ColumnSize) {
                            $ComputerAgentsArrayColumnSize = $ColumnSize
                        } else {
                            $ComputerAgentsArrayColumnSize = $ComputerAgentsArray.Count
                        }
                        if ($Dir -eq 'LR') {
                            try {
                                $ComputerAgentSubGraph = Node -Name 'ComputerAgentsSubgraph' -Attributes @{Label = (Add-HtmlSubGraph -Name 'ComputerAgentsSubgraph' -ImagesObj $Images -TableArray $ComputerAgentsArray -Align 'Center' -IconDebug $IconDebug -Label 'Protected Groups' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $ComputerAgentsArrayColumnSize -FontSize 26 -SubgraphFontBold); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create ComputerAgentsSubgraph Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                        } else {
                            try {
                                $ComputerAgentSubGraph = Node -Name 'ComputerAgentsSubgraph' -Attributes @{Label = (Add-HtmlSubGraph -Name 'ComputerAgentsSubgraph' -ImagesObj $Images -TableArray $ComputerAgentsArray -Align 'Center' -IconDebug $IconDebug -Label 'Protected Groups' -LabelPos 'top' -FontColor $Fontcolor -TableStyle 'dashed,rounded' -TableBorderColor $Edgecolor -TableBorder '1' -ColumnSize $ComputerAgentsArrayColumnSize -FontSize 26 -FontBold); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = 'Segoe Ui' }
                            } catch {
                                Write-PScriboMessage 'Error: Unable to create ComputerAgentsSubgraph Objects. Disabling the section'
                                Write-PScriboMessage "Error Message: $($_.Exception.Message)"
                            }
                        }
                    }

                    if ($ComputerAgentSubGraph) {
                        $ComputerAgentSubGraph
                        Edge -From FileProxies -To ComputerAgentsSubgraph @{minlen = 3 }
                    }
                }
            }
        } catch {
            Write-PScriboMessage $_.Exception.Message
        }
    }
    end {}
}