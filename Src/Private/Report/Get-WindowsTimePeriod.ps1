function Get-WindowsTimePeriod {
    <#
    .SYNOPSIS
    Used by As Built Report to generate time period table.
    .DESCRIPTION
    .NOTES
        Version:        0.1.0
        Author:         Jonathan Colon
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param
    (
        [Parameter (
            Position = 0,
            Mandatory)]
        [System.Array]
        $InputTimePeriod
    )

    $OutObj = @()
    $Hours24 = [ordered]@{
        0 = 12
        1 = 1
        2 = 2
        3 = 3
        4 = 4
        5 = 5
        6 = 6
        7 = 7
        8 = 8
        9 = 9
        10 = 10
        11 = 11
        12 = 12
        13 = 1
        14 = 2
        15 = 3
        16 = 4
        17 = 5
        18 = 6
        19 = 7
        20 = 8
        21 = 9
        22 = 10
        23 = 11
    }
    $ScheduleTimePeriod = $InputTimePeriod -split '(.{48})' | Where-Object { $_ }

    foreach ($OBJ in $Hours24.GetEnumerator()) {

        $inObj = [ordered] @{
            'H' = $OBJ.Value
            'Sun' = $ScheduleTimePeriod[0].Split(',')[$OBJ.Key]
            'Mon' = $ScheduleTimePeriod[1].Split(',')[$OBJ.Key]
            'Tue' = $ScheduleTimePeriod[2].Split(',')[$OBJ.Key]
            'Wed' = $ScheduleTimePeriod[3].Split(',')[$OBJ.Key]
            'Thu' = $ScheduleTimePeriod[4].Split(',')[$OBJ.Key]
            'Fri' = $ScheduleTimePeriod[5].Split(',')[$OBJ.Key]
            'Sat' = $ScheduleTimePeriod[6].Split(',')[$OBJ.Key]
        }
        $OutObj += $inobj
    }

    return $OutObj

} # end