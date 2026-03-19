function New-VBRConnection {
    <#
    .SYNOPSIS
        Uses New-VBRConnection to store the connection in a global parameter
    .DESCRIPTION
        Creates a Veeam Server connection and stores it in global variable $Global:DefaultVeeamBR.
        An FQDN or IP, credentials, and ignore certificate boolean
    .OUTPUTS
        Returns the Veeam Server connection.
    .EXAMPLE
    New-VBRConnection -Endpoint <FQDN or IP> -Port <default 9419> -Credential $(Get-Credential)

    #>

    [CmdletBinding()]
    param(

        [Parameter(Position = 0, mandatory = $true)]
        [string]$Endpoint,

        [Parameter(Position = 1, mandatory = $true)]
        [string]$Port,

        [Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
        [ValidateNotNullOrEmpty()]
        [Management.Automation.PSCredential]$Credential

    )

    $apiUrl = "https://$($Endpoint):$($Port)/api/oauth2/token"

    $User = $Credential.UserName
    $Pass = $Credential.GetNetworkCredential().Password

    # Define the headers for the API request
    $headers = @{
        'Content-Type' = 'application/x-www-form-urlencoded'
        'x-api-version' = '1.1-rev0'
    }

    ## TO-DO: Grant_type options
    $body = @{
        'grant_type' = 'password'
        'username' = $User
        'password' = $Pass
    }

    # Send an authentication request to obtain a session token
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -Body $body -SkipCertificateCheck

        if (($response.access_token) -or ($response.StatusCode -eq 200) ) {
            Write-Output 'Successfully authenticated.'
            $VBRAuthentication = [PSCustomObject]@{
                Session_endpoint = $Endpoint
                Session_port = $Port
                Session_access_token = $response.access_token
            }

            return $VBRAuthentication
        } else {
            Write-Output "Authentication failed. Status code: $($response.StatusCode), Message: $($response.Content)"
        }
    } catch {
        Write-Output "An error occurred: $($_.Exception.Message)"
    }
}