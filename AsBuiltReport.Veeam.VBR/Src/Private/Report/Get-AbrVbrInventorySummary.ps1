
function Get-AbrVbrInventorySummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Inventory Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.20
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
        $LocalizedData = $reportTranslate.GetAbrVbrInventorySummary
        Write-PScriboMessage ($LocalizedData.Collecting -f $System)
        Show-AbrDebugExecutionTime -Start -TitleMessage 'Inventory Summary'
    }

    process {
        try {
            $OutObj = @()
            try {
                $vCenter = Get-VBRServer | Where-Object { $_.Type -eq 'VC' }
                $ESXi = Get-VBRServer | Where-Object { $_.Type -eq 'ESXi' }
                $HvCluster = Get-VBRServer | Where-Object { $_.Type -eq 'HvCluster' }
                $HvServer = Get-VBRServer | Where-Object { $_.Type -eq 'HvServer' }
                $ProtectionGroups = try {
                    Get-VBRProtectionGroup | Sort-Object -Property Name
                } catch {
                    Write-PScriboMessage -IsWarning "Physical Infrastructure Inventory Summary Cmdlet: $($_.Exception.Message)"
                }
                if ($VbrVersion -lt 12.1) {
                    $Shares = Get-VBRNASServer -WarningAction SilentlyContinue
                } else {
                    $FileServers = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq 'FileServer' }
                    $NASFillers = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq 'SANSMB' }
                    $FileShares = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq 'SMB' -or $_.Type -eq 'NFS' }
                    $ObjectStorage = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq 'AzureBlobServer' -or $_.Type -eq 'AmazonS3Server' -or $_.Type -eq 'S3CompatibleServer' }
                }
                $inObj = [ordered] @{
                    $LocalizedData.vCenterServers = ($vCenter | Measure-Object).Count
                    $LocalizedData.ESXiServers = ($ESXi | Measure-Object).Count
                    $LocalizedData.HyperVClusters = ($HvCluster | Measure-Object).Count
                    $LocalizedData.HyperVServers = ($HvServer | Measure-Object).Count
                    $LocalizedData.ProtectionGroups = ($ProtectionGroups | Measure-Object).Count
                }

                if ($VbrVersion -lt 12.1) {
                    $inObj.add($LocalizedData.FileShares, ($Shares | Measure-Object).Count)
                } else {
                    $inObj.add($LocalizedData.FileServer, ($FileServers | Measure-Object).Count)
                    $inObj.add($LocalizedData.NASFilers, ($NASFillers | Measure-Object).Count)
                    $inObj.add($LocalizedData.FileShares, ($FileShares | Measure-Object).Count)
                    $inObj.add($LocalizedData.ObjectStorage, ($ObjectStorage | Measure-Object).Count)
                }

                $OutObj += [pscustomobject](ConvertTo-HashToYN $inObj)
            } catch {
                Write-PScriboMessage -IsWarning "Inventory Summary Table: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "$($LocalizedData.TableHeading) - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        } catch {
            Write-PScriboMessage -IsWarning "Inventory Summary Section: $($_.Exception.Message)"
        }
    }
    end {
        Show-AbrDebugExecutionTime -End -TitleMessage 'Inventory Summary'

    }

}
