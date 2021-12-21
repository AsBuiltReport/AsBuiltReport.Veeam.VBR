
function Get-AbrVbrScaleOutRepository {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR ScaleOut Backup Repository Information
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
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
        Write-PscriboMessage "Discovering Veeam V&R ScaleOut Backup Repository information from $System."
    }

    process {
        Section -Style Heading2 'ScaleOut Backup Repository' {
            Paragraph "The following section provides a summary of the ScaleOut Backup Repository"
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
                try {
                    $BackupRepos = Get-VBRBackupRepository -ScaleOut
                    foreach ($BackupRepo in $BackupRepos) {
                        Write-PscriboMessage "Discovered $($BackupRepo.Name) Repository."
                        $inObj = [ordered] @{
                            'Name' = $BackupRepo.Name
                            'Extent' = $BackupRepo.Extent
                            'Capacity Extent' = $BackupRepo.CapacityExtent
                            'Capacity Extent Status' = ($BackupRepo.CapacityExtent).Status
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage $_.Exception.Message
                }

                $TableParams = @{
                    Name = "Scale Backup Repository Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                    List = $false
                    ColumnWidths = 30, 25, 30, 15
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
            }
        }
    }
    end {}

}