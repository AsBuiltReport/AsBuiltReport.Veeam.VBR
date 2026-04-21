
function Export-AsBuiltReportVBRDiagram {
    <#
    .SYNOPSIS
        Exports Veeam VBR infrastructure diagrams to disk without generating a full As-Built Report.
    .DESCRIPTION
        Connects to one or more Veeam Backup & Replication servers and exports the requested
        diagram types to the specified output folder. No AsBuiltReport framework or PScribo
        document context is required - the function is fully standalone.
    .PARAMETER Target
        One or more FQDNs of Veeam VBR servers to connect to. IP addresses are not supported.
    .PARAMETER Credential
        PSCredential used to authenticate to the VBR server.
    .PARAMETER Username
        Username for authenticating to the VBR server. Used when Credential is not provided.
    .PARAMETER Password
        Password for the specified Username. If omitted you will be prompted securely.
    .PARAMETER DiagramType
        One or more diagram types to export, or 'All' to export every available type.
        Defaults to 'All'.
    .PARAMETER Format
        Output file format(s). Supported values: pdf, svg, png, dot, jpg.
        Defaults to 'png'.
    .PARAMETER OutputFolderPath
        Directory where exported diagram files are saved.
        Defaults to the system temporary folder.
    .PARAMETER Direction
        Layout direction of the diagram. 'top-to-bottom' or 'left-to-right'.
        Defaults to 'top-to-bottom'.
    .PARAMETER DiagramTheme
        Visual theme. 'Black', 'White', or 'Neon'. Defaults to 'White'.
    .PARAMETER ColumnSize
        Number of icon columns in each node table. Defaults to 3.
    .PARAMETER Port
        TCP port used to connect to the VBR server. Defaults to 9392.
    .PARAMETER WaterMarkText
        Optional watermark text overlaid on the output image (not supported for SVG).
    .PARAMETER NewIcons
        Use the newer Veeam icon set instead of the classic icons.
    .PARAMETER EnableDiagramDebug
        Enable debug visualisation of subgraphs, edges, and nodes.
    .PARAMETER IsLocalServer
        Indicate that the local machine is the VBR backup server.
    .PARAMETER Signature
        Add an author/company footer signature to the diagram.
        Requires -AuthorName and -CompanyName.
    .PARAMETER AuthorName
        Author name shown in the diagram signature footer.
    .PARAMETER CompanyName
        Company name shown in the diagram signature footer.
    .EXAMPLE
        $cred = Get-Credential
        Export-AsBuiltReportVBRDiagram -Target 'vbr01.contoso.com' -Credential $cred -OutputFolderPath 'C:\Diagrams'

        Exports all available diagrams as PNG files to C:\Diagrams.
    .EXAMPLE
        Export-AsBuiltReportVBRDiagram -Target 'vbr01.contoso.com' -Credential $cred `
            -DiagramType 'Backup-Infrastructure','Backup-to-Repository' `
            -Format 'pdf','svg' -OutputFolderPath 'C:\Diagrams' -DiagramTheme 'Neon'

        Exports two specific diagram types in both PDF and SVG using the Neon theme.
    .NOTES
        Version:    1.0.0
        Author:     Jonathan Colon
        Twitter:    @jcolonfzenpr
        GitHub:     rebelinux
    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]

    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    param (
        [Parameter(
            Position = 0,
            Mandatory = $true,
            HelpMessage = 'FQDN of the Veeam VBR server'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Server', 'IP')]
        [String[]] $Target,

        [Parameter(
            Position = 1,
            Mandatory = $true,
            ParameterSetName = 'Credential',
            HelpMessage = 'Credentials to authenticate to the VBR server'
        )]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $Credential,

        [Parameter(
            Position = 2,
            Mandatory = $true,
            ParameterSetName = 'UsernameAndPassword',
            HelpMessage = 'Username to authenticate to the VBR server'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Username,

        [Parameter(
            Position = 3,
            Mandatory = $false,
            ParameterSetName = 'UsernameAndPassword',
            HelpMessage = 'Password for the specified username'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Password,

        [Parameter(
            Mandatory = $false,
            HelpMessage = "Diagram type(s) to export, or 'All' for every available type"
        )]
        [ValidateSet(
            'All',
            'Backup-Infrastructure',
            'Backup-to-Repository',
            'Backup-to-Sobr',
            'Backup-to-vSphere-Proxy',
            'Backup-to-HyperV-Proxy',
            'Backup-to-File-Proxy',
            'Backup-to-WanAccelerator',
            'Backup-to-Tape',
            'Backup-to-ProtectedGroup',
            'Backup-to-CloudConnect',
            'Backup-to-CloudConnect-Tenant',
            'Backup-to-HACluster'
        )]
        [string[]] $DiagramType = 'All',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Output file format(s)'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('pdf', 'svg', 'png', 'dot', 'jpg')]
        [Array] $Format = 'png',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Folder path where diagram files are saved'
        )]
        [ValidateScript({
                if (Test-Path -Path $_) { $true } else { throw "Path '$_' not found." }
            })]
        [string] $OutputFolderPath = [System.IO.Path]::GetTempPath(),

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Layout direction of the diagram'
        )]
        [ValidateSet('top-to-bottom', 'left-to-right')]
        [string] $Direction = 'top-to-bottom',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Visual theme for the diagram'
        )]
        [ValidateSet('Black', 'White', 'Neon')]
        [string] $DiagramTheme = 'White',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Number of icon columns per node table'
        )]
        [ValidateRange(1, [int]::MaxValue)]
        [int] $ColumnSize = 3,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'TCP port of the VBR server'
        )]
        [string] $Port = '9392',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Watermark text overlaid on the output image'
        )]
        [string] $WaterMarkText = '',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Use the newer Veeam icon set'
        )]
        [Switch] $NewIcons,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Enable debug visualisation of subgraphs, edges, and nodes'
        )]
        [Switch] $EnableDiagramDebug,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Indicate that the local machine is the VBR backup server'
        )]
        [Switch] $IsLocalServer,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Add an author/company footer signature to the diagram'
        )]
        [Switch] $Signature,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Author name for the diagram signature footer'
        )]
        [string] $AuthorName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Company name for the diagram signature footer'
        )]
        [string] $CompanyName
    )

    begin {
        Get-AbrVbrRequiredModule -Name 'Veeam.Backup.PowerShell' -Version '1.0'

        if ($Signature -and ([string]::IsNullOrEmpty($AuthorName) -or [string]::IsNullOrEmpty($CompanyName))) {
            throw 'Export-AsBuiltReportVBRDiagram: -AuthorName and -CompanyName are required when -Signature is specified.'
        }

        if ($PSCmdlet.ParameterSetName -eq 'UsernameAndPassword') {
            if (-not $Password) {
                $SecurePassword = Read-Host "Password for user '$Username'" -AsSecureString
            } else {
                $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
            }
            $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        }

        $AllDiagramTypes = @(
            'Backup-Infrastructure',
            'Backup-to-Repository',
            'Backup-to-Sobr',
            'Backup-to-vSphere-Proxy',
            'Backup-to-HyperV-Proxy',
            'Backup-to-File-Proxy',
            'Backup-to-WanAccelerator',
            'Backup-to-Tape',
            'Backup-to-ProtectedGroup',
            'Backup-to-CloudConnect',
            'Backup-to-CloudConnect-Tenant',
            'Backup-to-HACluster'
        )

        # Build the $script:Options object that Get-AbrVbrDiagrammer reads.
        # This mirrors the structure of AsBuiltReport.Veeam.VBR.json Options section.
        $script:Options = [PSCustomObject]@{
            DiagramTheme           = $DiagramTheme
            DiagramColumnSize      = $ColumnSize
            DiagramWaterMark       = $WaterMarkText
            NewIcons               = $NewIcons.IsPresent
            EnableDiagramDebug     = $EnableDiagramDebug.IsPresent
            IsLocalServer          = $IsLocalServer.IsPresent
            UpdateCheck            = $false
            EnableDiagramSignature = $Signature.IsPresent
            SignatureAuthorName    = $AuthorName
            SignatureCompanyName   = $CompanyName
            ExportDiagramsFormat   = $Format
            BackupServerPort       = $Port
        }
    }

    process {
        foreach ($System in $Target) {
            if (Select-String -InputObject $System -Pattern '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                Write-Warning "Export-AsBuiltReportVBRDiagram: Use FQDN instead of IP address for '$System'. Skipping."
                continue
            }

            # Establish VBR connection.
            # $System, $Credential, and $OutputFolderPath are kept as local variables so that
            # Get-AbrVbrDiagrammer can resolve them via PowerShell's scope chain.
            try {
                Get-AbrVbrServerConnection
            } catch {
                Write-Warning "Export-AsBuiltReportVBRDiagram: Failed to connect to '$System' - $($_.Exception.Message)"
                continue
            }

            Write-Host "  - Exporting Veeam VBR diagrams for '$System' to '$OutputFolderPath'..."

            $TypesToExport = if ($DiagramType -contains 'All') { $AllDiagramTypes } else { $DiagramType }

            # Enumerate Cloud Connect tenants when the type is requested
            $Tenants = @()
            if ($TypesToExport -contains 'Backup-to-CloudConnect-Tenant') {
                try {
                    $Tenants = Get-VBRCloudTenant | Select-Object -ExpandProperty Name | Sort-Object
                    if (-not $Tenants) {
                        Write-Warning "Export-AsBuiltReportVBRDiagram: No Cloud Connect tenants found on '$System'. Skipping 'Backup-to-CloudConnect-Tenant'."
                    }
                } catch {
                    Write-Warning "Export-AsBuiltReportVBRDiagram: Could not retrieve Cloud Connect tenants from '$System' - $($_.Exception.Message)"
                }
            }

            foreach ($Type in $TypesToExport) {
                if ($Type -eq 'Backup-to-CloudConnect-Tenant') {
                    if (-not $Tenants) { continue }
                    foreach ($Tenant in $Tenants) {
                        try {
                            Get-AbrVbrDiagrammer -DiagramType $Type -Tenant $Tenant -Direction 'left-to-right'
                        } catch {
                            Write-Warning "Export-AsBuiltReportVBRDiagram: '$Type' (tenant '$Tenant') - $($_.Exception.Message)"
                        }
                    }
                } else {
                    try {
                        Get-AbrVbrDiagrammer -DiagramType $Type -Direction $Direction
                    } catch {
                        Write-Warning "Export-AsBuiltReportVBRDiagram: '$Type' - $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    end {}
}
