
function Get-AbrVbrSureBackup {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR SureBackup Information
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
        Write-PscriboMessage "Discovering Veeam VBR SureBackup information from $System."
    }

    process {
        Section -Style Heading3 'SureBackup Configuration' {
            Paragraph "The following section provides a summary of the Veeam SureBackup."
            BlankLine
            try {
                Section -Style Heading3 'SureBackup Application Groups' {
                    Paragraph "The following section provides a summary of the Veeam SureBackup Application Groups."
                    BlankLine
                    $OutObj = @()
                    try {
                        $SureBackupAGs = Get-VBRApplicationGroup
                        foreach ($SureBackupAG in $SureBackupAGs) {
                            Write-PscriboMessage "Discovered $($SureBackupAG.Name) Application Group."
                            $inObj = [ordered] @{
                                'Name' = $SureBackupAG.Name
                                'Platform' = $SureBackupAG.Platform
                                'VM List' = $SureBackupAG.VM -join ", "
                            }
                            $OutObj += [pscustomobject]$inobj
                        }
                    }
                    catch {
                        Write-PscriboMessage $_.Exception.Message
                    }

                    $TableParams = @{
                        Name = "SureBackup Application Group - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                        List = $false
                        ColumnWidths = 30, 20, 50
                    }
                    if ($Report.ShowTableCaptions) {
                        $TableParams['Caption'] = "- $($TableParams.Name)"
                    }
                    $OutObj | Table @TableParams
                }
            }
            catch {
                Write-PscriboMessage $_.Exception.Message
            }
            if ($InfoLevel.Infrastructure.SureBackup -ge 2) {
                try {
                    $SureBackupAGs = Get-VBRApplicationGroup
                    Section -Style Heading4 "$($VMSetting.Name) VM Settings" {
                        Paragraph "The following section provides a detailed information of the VM Application Group Settings"
                        BlankLine
                        foreach ($SureBackupAG in $SureBackupAGs) {
                            try {
                                foreach ($VMSetting in $SureBackupAG.VM) {
                                    Section -Style Heading5 "$($VMSetting.Name) VM Settings" {
                                        Paragraph "The following section provides a detailed information of the VM Application Group Settings"
                                        BlankLine
                                        $OutObj = @()
                                        Write-PscriboMessage "Discovered $($VMSetting.Name) Application Group VM Setting."
                                        $inObj = [ordered] @{
                                            'VM Name' = $VMSetting.Name
                                            'Credentials' = $VMSetting.Credentials
                                            'Role' = $VMSetting.Role -join ", "
                                            'Test Script' = $VMSetting.TestScript.PredefinedApplication -join ", "
                                            'Startup Options' = SWitch ($VMSetting.StartupOptions) {
                                                "" {"-"; break}
                                                $Null {"-"; break}
                                                default {$VMSetting.StartupOptions | ForEach-Object {"Allocated Memory: $($_.AllocatedMemory)`r`nHeartbeat Check: $(ConvertTo-TextYN $_.VMHeartBeatCheckEnabled)`r`nMaximum Boot Time: $($_.MaximumBootTime)`r`nApp Init Timeout: $($_.ApplicationInitializationTimeout)`r`nPing Check: $(ConvertTo-TextYN $_.VMPingCheckEnabled)"}}
                                            }
                                        }

                                        $OutObj += [pscustomobject]$inobj

                                        $TableParams = @{
                                            Name = "Application Group VM Settings - $($VMSetting.Name)"
                                            List = $true
                                            ColumnWidths = 40, 60
                                        }
                                        if ($Report.ShowTableCaptions) {
                                            $TableParams['Caption'] = "- $($TableParams.Name)"
                                        }
                                        $OutObj | Table @TableParams
                                    }
                                }
                            }
                            catch {
                                Write-PscriboMessage $_.Exception.Message
                            }
                        }
                    }
                }
                catch {
                    Write-PscriboMessage $_.Exception.Message
                }
            }
        }
    }
    end {}

}