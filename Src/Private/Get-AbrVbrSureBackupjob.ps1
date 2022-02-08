
function Get-AbrVbrSureBackupjob {
    <#
    .SYNOPSIS
        Used by As Built Report to returns surebackup jobs created in Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.3.1
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
        Write-PscriboMessage "Discovering Veeam VBR SureBackup jobs information from $System."
    }

    process {
        try {
            if ((Get-VSBJob).count -gt 0) {
                Section -Style Heading3 'SureBackup Jobs' {
                    Paragraph "The following section list surebackup jobs created in Veeam Backup & Replication."
                    BlankLine
                    $OutObj = @()
                    if ((Get-VBRServerSession).Server) {
                        $SBkjobs = Get-VSBJob
                        foreach ($SBkjob in $SBkjobs) {
                            try {
                                Write-PscriboMessage "Discovered $($SBkjob.Name) location."
                                $inObj = [ordered] @{
                                    'Name' = $SBkjob.Name
                                    'Platform' = Switch ($SBkjob.info.Platform) {
                                        "EVmware" {"VMware"}
                                        "EHyperV" {"Hyper-V"}
                                    }
                                    'Latest Status' = $SBkjob.GetLastResult()
                                    'Target Repository' = Get-VBRVirtualLab -Id $SBkjob.info.VirtualLabId
                                }
                                $OutObj += [pscustomobject]$inobj
                            }
                            catch {
                                Write-PscriboMessage -IsWarning $_.Exception.Message
                            }
                        }

                        $TableParams = @{
                            Name = "SureBackup Jobs - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                            List = $false
                            ColumnWidths = 30, 25, 15, 30
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
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
