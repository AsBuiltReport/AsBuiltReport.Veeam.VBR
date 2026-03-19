function Get-StandardDeviation {
    <#
        .Synopsis
            This script will find the standard deviation, given a set of numbers.
        .DESCRIPTION
            This script will find the standard deviation, given a set of numbers.

            Written by Mike Roberts (Ginger Ninja)
            Version: 0.5
        .EXAMPLE
            .\Get-StandardDeviation.ps1

            Using this method you will need to input numbers one line at a time, and then hit enter twice when done.
            --------------------------------------------------------------------------------------------------------
            PS > .\Get-StandardDeviation.ps1

                cmdlet Get-StandardDeviation at command pipeline position 1
                Supply values for the following parameters:
                value[0]: 12345
                value[1]: 0
                value[2]:


                Original Numbers           : 12345,0
                Standard Deviation         : 8729.23321374793
                Rounded Number (2 decimal) : 8729.23
                Rounded Number (3 decimal) : 8729.233
                --------------------------------------------------------------------------------------------------------
        .EXAMPLE
            .\Get-StandardDeviation.ps1 -value 12345,0
        .LINK
            http://www.gngrninja.com/script-ninja/2016/5/1/powershell-calculating-standard-deviation
        .NOTES
            Be sure to enter at least 2 numbers, separated by a comma if using the -value parameter.
    #>
    #Begin function Get-StandardDeviation
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]
        [decimal[]] $value
    )

    #Simple if to see if the value matches digits, and also that there is more than one number.
    if ($value -match '\d+' -and $value.Count -gt 1) {

        #Variables used later
        [decimal]$newNumbers = $Null
        [decimal]$stdDev = $null

        #Get the average and count via Measure-Object
        $avgCount = $value | Measure-Object -Average | Select-Object Average, Count

        #Iterate through each of the numbers and get part of the variance via some PowerShell math.
        foreach ($number in $value) {

            $newNumbers += [Math]::Pow(($number - $avgCount.Average), 2)

        }

        #Finish the variance calculation, and get the square root to finally get the standard deviation.
        $stdDev = [math]::Sqrt($($newNumbers / ($avgCount.Count - 1)))

        #Create an array so we can add the object we create to it. This is incase we want to perhaps add some more math functions later.
        [System.Collections.ArrayList]$formattedObjectArray = @()

        #Create a hashtable collection for the properties of the object
        $formattedProperty = @{'StandardDeviation' = [Math]::Round($stdDev, 2) }

        #Create the object we'll add to the array, with the properties set above
        $fpO = New-Object psobject -Property $formattedProperty

        #Add that object to this array
        $formattedObjectArray.Add($fpO) | Out-Null

        #Return the array object with the selected objects defined, as well as formatting.
        return $formattedObjectArray

    } else {

        #Display an error if there are not enough numbers
        Write-PScriboMessage 'You did not enter enough numbers!'
    }
}