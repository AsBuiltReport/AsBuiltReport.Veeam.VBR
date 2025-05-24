
function Get-AbrVbrDiagrammer {
    <#
    .SYNOPSIS
    Used by As Built Report to get the Veeam.Diagrammer diagram.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.21
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
        [ValidateSet('Backup-to-Tape', 'Backup-to-File-Proxy', 'Backup-to-HyperV-Proxy', 'Backup-to-vSphere-Proxy', 'Backup-to-Repository', 'Backup-to-Sobr', 'Backup-to-WanAccelerator', 'Backup-to-ProtectedGroup', 'Backup-Infrastructure', 'Backup-to-CloudConnect')]
        [string]$DiagramType = 'Backup-Infrastructure',
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('png', 'pdf', 'base64', 'jpg', 'svg')]
        [string]$DiagramOutput,
        [Switch]$ExportPath = $false
    )

    begin {
        Write-PScriboMessage "Generating Veeam diagram ($DiagramType) from Backup Server $System."
    }

    process {
        try {
            # Set default theme styles
            if (-Not $Options.DiagramTheme) {
                $DiagramTheme = 'White'
            } else {
                $DiagramTheme = $Options.DiagramTheme
            }
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
                'Backup-to-CloudConnect' = 'CloudConnect'
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
                "ColumnSize" = Switch ([string]::IsNullOrEmpty($Options.DiagramColumnSize)) {
                    $true { 3 }
                    $false {
                        Switch ($Options.DiagramColumnSize) {
                            0 { 3 }
                            default { $Options.DiagramColumnSize }
                        }
                    }
                    default { 3 }
                }
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
            try {
                foreach ($Format in $DiagramFormat) {
                    if ($Format -eq "base64") {
                        $Graph = New-VeeamDiagram @DiagramParams -DiagramType $DiagramType -Format $Format
                        if ($Graph) {
                            $Graph
                        }
                    } else {
                        $Graph = New-VeeamDiagram @DiagramParams -DiagramType $DiagramType -Format $Format -Filename "AsBuiltReport.Veeam.VBR-$($DiagramTypeHash[$DiagramType]).$($Format)"
                        if ($Graph) {
                            if ($ExportPath) {
                                $FilePath = Join-Path -Path $OutputFolderPath -ChildPath "AsBuiltReport.Veeam.VBR-$($DiagramTypeHash[$DiagramType]).$($Format)"
                                if (Test-Path -Path $FilePath) {
                                    $FilePath
                                } else {
                                    Write-PScriboMessage -IsWarning "Unable to export the $DiagramType Diagram: $($_.Exception.Message)"
                                }
                            } else {
                                Write-Information "Saved 'AsBuiltReport.Veeam.VBR-$($DiagramTypeHash[$DiagramType]).$($Format)' diagram to '$($OutputFolderPath)'." -InformationAction Continue
                            }
                        }
                    }
                }
            } catch {
                Write-PScriboMessage -IsWarning "Unable to export the $($DiagramTypeHash[$DiagramType]) Diagram: $($_.Exception.Message)"
            }
        } catch {
            Write-PScriboMessage -IsWarning "Unable to get the $($DiagramTypeHash[$DiagramType]) Diagram: $($_.Exception.Message)"
        }
    }
    end {}
}