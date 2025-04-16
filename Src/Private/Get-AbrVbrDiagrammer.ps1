
function Get-AbrVbrDiagrammer {
    <#
    .SYNOPSIS
    Used by As Built Report to get the Veeam.Diagrammer diagram.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.17
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Backup-to-Tape', 'Backup-to-File-Proxy', 'Backup-to-HyperV-Proxy', 'Backup-to-vSphere-Proxy', 'Backup-to-Repository', 'Backup-to-Sobr', 'Backup-to-WanAccelerator', 'Backup-to-ProtectedGroup', 'Backup-Infrastructure', 'All')]
        [string]$DiagramType = 'Backup-Infrastructure',
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('png', 'pdf', 'base64', 'jpg', 'svg')]
        [string]$DiagramOutput = 'png'
    )

    begin {
        Write-PScriboMessage "Getting Veeam diagram for $System."
    }

    process {
        try {
            $DiagramTypeArray = @()
            $DiagramTypeHash = @{
                'Backup-Infrastructure' = 'Infrastructure'
                'Backup-to-File-Proxy' = 'FileProxy'
                'Backup-to-HyperV-Proxy' = 'HyperVProxy'
                'Backup-to-ProtectedGroup' = 'ProtectedGroup'
                'Backup-to-Repository' = 'Repository'
                'Backup-to-Sobr' = 'Sobr'
                'Backup-to-Tape' = 'Tape'
                'Backup-to-vSphere-Proxy' = 'vSphereProxy'
                'Backup-to-WanAccelerator' = 'WanAccelerator'
            }

            if (-Not $Options.DiagramType) {
                $DiagramTypeArray += 'All'
            } elseif ($Options.DiagramType) {
                $DiagramTypeArray = $Options.DiagramType
            } else {
                $DiagramType = 'All'
            }

            if (-Not $Options.ExportDiagramsFormat) {
                $DiagramFormat = 'png'
            } elseif ($DiagramOutput) {
                $DiagramFormat = $DiagramOutput
            } else {
                $DiagramFormat = $Options.ExportDiagramsFormat
            }
            $DiagramParams = @{
                'OutputFolderPath' = $OutputFolderPath
                'Credential' = $Credential
                'Target' = $System
                'Direction' = 'top-to-bottom'
                'WaterMarkText' = $Options.DiagramWaterMark
                'WaterMarkColor' = 'DarkGreen'
                'DiagramTheme' = $DiagramTheme
            }

            if ($Options.EnableDiagramDebug) {
                $DiagramParams.Add('EnableEdgeDebug', $True)
                $DiagramParams.Add('EnableSubGraphDebug', $True)
            }

            if ($Options.EnableDiagramSignature) {
                $DiagramParams.Add('Signature', $True)
                $DiagramParams.Add('AuthorName', $Options.SignatureAuthorName)
                $DiagramParams.Add('CompanyName', $Options.SignatureCompanyName)
            }

            if ($DiagramType -eq 'All') {
                try {
                    foreach ($DiagramTypeItem in $DiagramTypeHash.Keys) {
                        foreach ($Format in $DiagramFormat) {
                            if ($Format -eq "base64") {
                                $Graph = New-VeeamDiagram @DiagramParams -DiagramType $DiagramTypeItem -Format $Format
                                if ($Graph) {
                                    $Graph
                                }
                            } else {
                                $Graph = New-VeeamDiagram @DiagramParams -DiagramType $DiagramTypeItem  -Format $Format -Filename "AsBuiltReport.Veeam.VBR-($($DiagramTypeHash[$DiagramTypeItem])).$($Format)"
                                if ($Graph) {
                                    Write-Information "Saved 'AsBuiltReport.Veeam.VBR-($($DiagramTypeHash[$DiagramTypeItem])).$($Format)' diagram to '$($OutputFolderPath)'." -InformationAction Continue
                                }
                            }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Unable to export the Infrastructure Diagram: $($_.Exception.Message)"
                }
            } else {
                try {
                    foreach ($Format in $DiagramFormat) {
                        if ($Format -eq "base64") {
                            $Graph = New-VeeamDiagram @DiagramParams -DiagramType $DiagramType -Format $Format
                            if ($Graph) {
                                $Graph
                            }
                        } else {
                            $Graph = New-VeeamDiagram @DiagramParams -DiagramType $DiagramType -Format $Format -Filename "AsBuiltReport.Veeam.VBR-($($DiagramTypeHash[$DiagramType])).$($Format)"
                            if ($Graph) {
                                Write-Information "Saved 'AsBuiltReport.Veeam.VBR-($($DiagramTypeHash[$DiagramType])).$($Format)' diagram to '$($OutputFolderPath)'." -InformationAction Continue
                            }
                        }
                    }
                } catch {
                    Write-PScriboMessage -IsWarning "Unable to export the Infrastructure Diagram: $($_.Exception.Message)"
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Unable to get the Infrastructure Diagram: $($_.Exception.Message)"
        }
    }
    end {}
}