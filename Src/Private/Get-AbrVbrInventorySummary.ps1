
function Get-AbrVbrInventorySummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Inventory Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.6
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
        Write-PScriboMessage "Discovering Veeam VBR Inventory Summary from $System."
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
                    $FileServers = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq "FileServer" }
                    $NASFillers = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq "SANSMB" }
                    $FileShares = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq "SMB" -or $_.Type -eq "NFS" }
                    $ObjectStorage = Get-VBRUnstructuredServer | Where-Object { $_.Type -eq "AzureBlobServer" -or $_.Type -eq "AmazonS3Server" -or $_.Type -eq "S3CompatibleServer" }
                }
                $inObj = [ordered] @{
                    'vCenter Servers' = ($vCenter | Measure-Object).Count
                    'ESXi Servers' = ($ESXi | Measure-Object).Count
                    'Hyper-V Clusters' = ($HvCluster | Measure-Object).Count
                    'Hyper-V Servers' = ($HvServer | Measure-Object).Count
                    'Protection Groups' = ($ProtectionGroups | Measure-Object).Count
                }

                if ($VbrVersion -lt 12.1) {
                    $inObj.add('File Shares', ($Shares | Measure-Object).Count)
                } else {
                    $inObj.add('File Server', ($FileServers | Measure-Object).Count)
                    $inObj.add('NAS Fillers', ($NASFillers | Measure-Object).Count)
                    $inObj.add('File Shares', ($FileShares | Measure-Object).Count)
                    $inObj.add('Object Storage', ($ObjectStorage | Measure-Object).Count)
                }

                $OutObj += [pscustomobject]$inobj
            } catch {
                Write-PScriboMessage -IsWarning "Inventory Summary Table: $($_.Exception.Message)"
            }

            $TableParams = @{
                Name = "Inventory Summary - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            $OutObj | Table @TableParams
        } catch {
            Write-PScriboMessage -IsWarning "Inventory Summary Section: $($_.Exception.Message)"s
        }
    }
    end {}

}