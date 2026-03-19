function Get-AbrApplicationGroupsInfo {
    <#
    .SYNOPSIS
    Retrieves information about Veeam Backup & Replication (VBR) Application Groups.

    .DESCRIPTION
    The Get-AbrApplicationGroupsInfo function collects and returns detailed information about
    the Application Groups configured in the Veeam Backup & Replication server. It includes
    the name of each Application Group, the count of machines in each group, and an icon type
    associated with the Application Groups.

    .PARAMETER None
    This function does not take any parameters.

    .OUTPUTS
    System.Object
    Returns a collection of custom objects containing the following properties:
    - Name: The name of the Application Group.
    - AditionalInfo: An ordered dictionary containing additional information such as the machine count.
    - IconType: The icon type associated with the Application Groups.

    .EXAMPLE
    PS C:\> Get-AbrApplicationGroupsInfo
    This example retrieves and displays information about all Application Groups in the Veeam Backup & Replication server.

    .NOTES
    This function uses the Get-AbrApplicationGroup cmdlet to retrieve the Application Groups and
    the Get-AbrIconType function to determine the icon type.

    Author: Jonathan Colon
    Date: 2024-12-31
    Version: 1.0
    #>
    param ()
    try {
        Write-PScriboMessage "Collecting Application Groups information from $($VBRServer)."
        $ApplicationGroups = Get-VBRApplicationGroup

        if ($ApplicationGroups) {
            $ApplicationGroupsInfo = $ApplicationGroups | ForEach-Object {
                $inobj = [ordered] @{
                    'Machine Count' = ($_.VM | Measure-Object).Count
                }

                $IconType = Get-AbrIconType -String 'ApplicationGroups'

                [PSCustomObject] @{
                    Name = $_.Name
                    AditionalInfo = $inobj
                    IconType = $IconType
                }
            }
            return $ApplicationGroupsInfo
        }

    } catch {
        Write-PScriboMessage $_.Exception.Message
    }
}