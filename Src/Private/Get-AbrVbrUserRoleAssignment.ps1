
function Get-AbrVbrUserRoleAssignment {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Veeam VBR roles assigned to a user or a user group.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.3
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
        Write-PscriboMessage "Discovering Veeam VBR Roles information from $System."
    }

    process {
        try {
            Section -Style Heading3 'Roles and Users' {
                Paragraph "The following section provides information about roles assigned to users or groups."
                BlankLine
                $OutObj = @()
                try {
                    $RoleAssignments = Get-VBRUserRoleAssignment
                    foreach ($RoleAssignment in $RoleAssignments) {
                        Write-PscriboMessage "Discovered $($RoleAssignment.Name) Server."
                        $inObj = [ordered] @{
                            'Name' = $RoleAssignment.Name
                            'Type' = $RoleAssignment.Type
                            'Role' = $RoleAssignment.Role
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning $_.Exception.Message
                }

                $TableParams = @{
                    Name = "Roles and Users - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 45, 15, 40
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}