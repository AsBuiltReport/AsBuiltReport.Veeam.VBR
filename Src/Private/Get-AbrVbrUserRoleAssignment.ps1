
function Get-AbrVbrUserRoleAssignment {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Veeam VBR roles assigned to a user or a user group.


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
        Write-PscriboMessage "Discovering Veeam VBR Roles information from $System."
    }

    process {
        Section -Style Heading4 'Roles and Users' {
            Paragraph "The following section provides information on the role that are assigned to a user or a user group."
            BlankLine
            $OutObj = @()
            if ((Get-VBRServerSession).Server) {
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
                    Name = "Roles and Users Information - $(((Get-VBRServerSession).Server).ToString().ToUpper().Split(".")[0])"
                    List = $false
                    ColumnWidths = 45, 15, 40
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