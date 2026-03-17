function New-AbrVeeamDiagram {
    <#
    .SYNOPSIS
        Generates comprehensive diagrams of Veeam Backup & Replication (VBR) infrastructure in multiple formats using PSGraph and Graphviz.

    .DESCRIPTION
        This script automates the creation of detailed visual diagrams representing the architecture and relationships within a Veeam Backup & Replication environment. It supports various diagram types and output formats, enabling administrators to visualize backup infrastructure components, their connections, and data flows. Customization options include layout direction, themes, node and section separation, edge styles, and branding elements such as logos and watermarks.

    .PARAMETER DiagramType
        Specifies the type of Veeam VBR diagram to generate.
        Supported values:
            - 'Backup-to-Sobr'
            - 'Backup-to-vSphere-Proxy'
            - 'Backup-to-HyperV-Proxy'
            - 'Backup-to-Repository'
            - 'Backup-to-WanAccelerator'
            - 'Backup-to-Tape'
            - 'Backup-to-File-Proxy'
            - 'Backup-to-ProtectedGroup'
            - 'Backup-Infrastructure'
            - 'Backup-to-CloudConnect'
            - 'Backup-to-CloudConnect-Tenant'

    .PARAMETER Target
        One or more IP addresses or FQDNs of Veeam VBR servers to connect to.
        Multiple targets can be specified, separated by commas.

    .PARAMETER Port
        Optional. The port number for connecting to the Veeam VBR Service.
        Default: 9392

    .PARAMETER Credential
        A PSCredential object containing the username and password for authentication to the target system.

    .PARAMETER Username
        The username for authenticating to the target system. Used if Credential is not provided.

    .PARAMETER Password
        The password for authenticating to the target system. Used if Credential is not provided.

    .PARAMETER Format
        Specifies one or more output formats for the generated diagram.
        Supported values: PDF, PNG, DOT, SVG
        Multiple formats can be specified, separated by commas.

    .PARAMETER Direction
        Sets the layout direction of the diagram.
        Supported values: 'top-to-bottom', 'left-to-right'
        Default: 'top-to-bottom'

    .PARAMETER Theme
        Sets the visual theme of the diagram.
        Supported values: 'Black', 'White', 'Neon'
        Default: 'White'

    .PARAMETER NodeSeparation
        Adjusts the spacing between nodes in the diagram.
        Default: 0.60

    .PARAMETER SectionSeparation
        Adjusts the spacing between sections (subgraphs) in the diagram.
        Default: 0.75

    .PARAMETER EdgeType
        Defines the style of edge lines connecting nodes.
        Supported values: 'polyline', 'curved', 'ortho', 'line', 'spline'
        Default: 'spline'
        See: https://graphviz.org/docs/attrs/splines/

    .PARAMETER OutputFolderPath
        The directory path where the generated diagram files will be saved.

    .PARAMETER Filename
        The base filename for the generated diagram files.

    .PARAMETER DraftMode
        Switch. Enables debugging visualization for subgraphs, edges & nodes.

    .PARAMETER EnableErrorDebug
        Switch. Enables detailed error debugging output.

    .PARAMETER AuthorName
        The name of the author to include in the diagram footer signature.

    .PARAMETER CompanyName
        The company name to include in the diagram footer signature.

    .PARAMETER Logo
        Path to a custom logo image to replace the default Veeam logo.
        Recommended size: 400px x 100px or smaller.

    .PARAMETER SignatureLogo
        Path to a custom signature logo image for the diagram footer.
        Recommended size: 120px x 130px or smaller.

    .PARAMETER Signature
        Switch. Adds a footer signature to the diagram. Requires AuthorName and CompanyName.

    .PARAMETER WatermarkText
        Text to be used as a watermark on the output image (not supported for SVG format).

    .PARAMETER WatermarkColor
        The color of the watermark text.
        Default: 'Green'

    .PARAMETER ColumnSize
        Sets the number of columns in the node table layout.
        Default: 4

    .PARAMETER NewIcons
        Switch. Enables the use of new icons for the diagram (default: false).

    .PARAMETER IsLocalServer
        Switch. Indicates if the local machine is the backup server (default: false).

    .PARAMETER UpdateCheck
        Switch. Enables checking for updates to the Veeam.Diagrammer and Diagrammer.Core modules.

    .EXAMPLE
        New-AbrVeeamDiagram -DiagramType 'Backup-Infrastructure' -Target 'vbr01.contoso.com' -Format 'PDF,PNG' -Theme 'Neon' -OutputFolderPath 'C:\Diagrams'

    .NOTES
        Requires PSGraph and Graphviz to be installed and available in the system path.
        For best results, ensure all image assets meet the recommended size guidelines.

    .NOTES
        Version:        0.8.24
        Author(s):      Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Kevin Marquette (@KevinMarquette) - PSGraph module
                        Prateek Singh (@PrateekKumarSingh) - AzViz module

    .LINK
        https://github.com/rebelinux/Veeam.Diagrammer
        https://github.com/KevinMarquette/PSGraph
        https://github.com/PrateekKumarSingh/AzViz
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingUserNameAndPassWordParams', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]

    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName = 'Credential'
    )]

    #Requires -RunAsAdministrator

    param (

        [Parameter(
            Position = 0,
            Mandatory = $true,
            HelpMessage = 'Please provide the IP/FQDN of the system'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Server', 'IP')]
        [String[]] $Target,

        [Parameter(
            Position = 1,
            Mandatory = $true,
            HelpMessage = 'Please provide credentials to connect to the system',
            ParameterSetName = 'Credential'
        )]
        [ValidateNotNullOrEmpty()]
        [PSCredential] $Credential,

        [Parameter(
            Position = 2,
            Mandatory = $true,
            HelpMessage = 'Please provide the username to connect to the target system',
            ParameterSetName = 'UsernameAndPassword'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Username,

        [Parameter(
            Position = 3,
            Mandatory = $false,
            HelpMessage = 'Please provide the password to connect to the target system',
            ParameterSetName = 'UsernameAndPassword'
        )]
        [ValidateNotNullOrEmpty()]
        [String] $Password,

        [Parameter(
            Position = 4,
            Mandatory = $false,
            HelpMessage = 'Please provide the diagram output format'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('pdf', 'svg', 'png', 'dot', 'base64', 'jpg')]
        [Array] $Format = 'pdf',

        [Parameter(
            Position = 5,
            Mandatory = $false,
            HelpMessage = 'TCP Port of target Veeam Backup Server'
        )]
        [string] $Port = '9392',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Use it to set the diagram theme. (Black/White/Neon)'
        )]
        [ValidateSet('Black', 'White', 'Neon')]
        [string] $DiagramTheme = 'White',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Direction in which resource are plotted on the visualization'
        )]
        [ValidateSet('left-to-right', 'top-to-bottom')]
        [string] $Direction = 'top-to-bottom',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Please provide the path to the diagram output file'
        )]
        [ValidateScript( {
                if (Test-Path -Path $_) {
                    $true
                } else {
                    throw "Path $_ not found!"
                }
            })]
        [string] $OutputFolderPath = [System.IO.Path]::GetTempPath(),

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Please provide the path to the custom logo used for Signature'
        )]
        [ValidateScript( {
                if (Test-Path -Path $_) {
                    $true
                } else {
                    throw "File $_ not found!"
                }
            })]
        [string] $SignatureLogo,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Please provide the path to the custom logo'
        )]
        [ValidateScript( {
                if (Test-Path -Path $_) {
                    $true
                } else {
                    throw "File $_ not found!"
                }
            })]
        [string] $Logo,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Specify the Diagram filename'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (($Format | Measure-Object).count -lt 2) {
                    $true
                } else {
                    throw 'Format value must be unique if Filename is especified.'
                }
            })]
        [String] $Filename,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Controls how edges lines appear in visualization'
        )]
        [ValidateSet('polyline', 'curved', 'ortho', 'line', 'spline')]
        [string] $EdgeType = 'spline',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Controls Node separation ratio in visualization'
        )]
        [ValidateSet(0, 1, 2, 3)]
        [string] $NodeSeparation = .60,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Controls Section (Subgraph) separation ratio in visualization'
        )]
        [ValidateSet(0, 1, 2, 3)]
        [string] $SectionSeparation = .75,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Tenant name to be used in the diagram (if applicable, e.g., for multi-tenant environments)'
        )]
        [string] $TenantName,

        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Controls type of Veeam VBR generated diagram'
        )]
        [ValidateSet('Backup-to-Tape', 'Backup-to-File-Proxy', 'Backup-to-HyperV-Proxy', 'Backup-to-vSphere-Proxy', 'Backup-to-Repository', 'Backup-to-Sobr', 'Backup-to-WanAccelerator', 'Backup-to-ProtectedGroup', 'Backup-Infrastructure', 'Backup-to-CloudConnect', 'Backup-to-CloudConnect-Tenant')]
        [string] $DiagramType,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to enable debugging visualization of subgraph, edges & nodes'
        )]
        [Switch] $DraftMode = $false,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to enable error debugging'
        )]
        [Switch] $EnableErrorDebug = $false,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to set footer signature Author Name'
        )]
        [string] $AuthorName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to set footer signature Company Name'
        )]
        [string] $CompanyName,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow the creation of footer signature'
        )]
        [Switch] $Signature = $false,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to add a watermark to the output image (Not supported in svg format)'
        )]
        [string] $WaterMarkText,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to specified the color used for the watermark text'
        )]
        [string] $WaterMarkColor = 'Green',

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to specified the size of the node column size'
        )]
        [ValidateScript( {
                if ($_ -gt 0) {
                    $true
                } else {
                    throw 'ColumnSize must be a positive integer greater than zero.'
                }
            })]
        [int] $ColumnSize = 4,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to use Veeam new icons instead of the old ones (default: false, use NewIcons = $true to enable it)'
        )]
        [switch] $NewIcons = $false,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Specify if the local machine is the backup server'
        )]
        [switch] $IsLocalServer = $false,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Specify if the local machine is the backup server'
        )]
        [bool] $UpdateCheck = $true
    )

    begin {

        if ($psISE) {
            Write-Error -Message 'You cannot run this script inside the PowerShell ISE. Please execute it from the PowerShell Command Window.'
            break
        }

        if ($DiagramType -eq 'Backup-to-CloudConnect-Tenant' -and ([string]::IsNullOrEmpty($TenantName) -eq $true)) {
            throw 'TenantName must be a used with the Backup-to-CloudConnect-Tenant diagram type.'
        }

        $Verbose = if ($PSBoundParameters.ContainsKey('Verbose')) {
            $PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent
        } else {
            $false
        }

        if ($EnableErrorDebug) {
            $global:VerbosePreference = 'Continue'
            $global:DebugPreference = 'Continue'
        } else {
            $global:VerbosePreference = 'SilentlyContinue'
            $global:DebugPreference = 'SilentlyContinue'
        }

        #@tpcarman
        # If Username and Password parameters used, convert specified Password to secure string and store in $Credential
        if ($Username) {
            if (-not $Password) {
                # If the Password parameter is not provided, prompt for it securely
                $SecurePassword = Read-Host "Password for user '$Username'" -AsSecureString
            } else {
                # If the Password parameter is provided, convert it to secure string
                $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
            }
            $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        }

        if (($Format -ne 'base64') -and !(Test-Path $OutputFolderPath)) {
            Write-Error "OutputFolderPath '$OutputFolderPath' is not a valid folder path."
            break
        }

        if ($Signature -and (([string]::IsNullOrEmpty($AuthorName)) -or ([string]::IsNullOrEmpty($CompanyName)))) {
            throw 'New-AbrVeeamDiagram : AuthorName and CompanyName must be defined if the Signature option is specified'
        }

        $MainGraphLabel = switch ($DiagramType) {
            'Backup-to-Sobr' { 'Scale-Out Backup Repository Diagram' }
            'Backup-to-File-Proxy' { 'File Backup Proxy Diagram' }
            'Backup-to-vSphere-Proxy' { 'VMware Backup Proxy Diagram' }
            'Backup-to-HyperV-Proxy' { 'HyperV Backup Proxy Diagram' }
            'Backup-to-Repository' { 'Backup Repository Diagram' }
            'Backup-to-WanAccelerator' { 'Wan Accelerators Diagram' }
            'Backup-to-Tape' { 'Tape Infrastructure Diagram' }
            'Backup-to-ProtectedGroup' { 'Physical Infrastructure Diagram' }
            'Backup-Infrastructure' { 'Backup Infrastructure Diagram' }
            'Backup-to-CloudConnect' { 'Cloud Connect Infrastructure Diagram' }
            'Backup-to-CloudConnect-Tenant' { "Cloud Connect $TenantName Resources Diagram" }
        }
        if ($Format -ne 'Base64') {
            Write-AbrColorOutput -Color 'Green' -String ("Please wait while the '{0}' is being generated." -f $MainGraphLabel)
            Write-AbrColorOutput -Color 'White' -String ' - Please refer to the Veeam.Diagrammer github website for more detailed information about this project.'
            Write-AbrColorOutput -Color 'White' -String ' - Documentation: https://github.com/rebelinux/Veeam.Diagrammer'
            Write-AbrColorOutput -Color 'White' -String ' - Issues or bug reporting: https://github.com/rebelinux/Veeam.Diagrammer/issues'
            Write-AbrColorOutput -Color 'White' -String ' - This project is community maintained and has no sponsorship from Veeam, its employees or any of its affiliates.'


            # Check the version of the dependency modules
            if ($UpdateCheck) {
                $ModuleArray = @('Veeam.Diagrammer', 'Diagrammer.Core')

                foreach ($Module in $ModuleArray) {
                    try {
                        $InstalledVersion = Get-Module -ListAvailable -Name $Module -ErrorAction SilentlyContinue | Sort-Object -Property Version -Descending | Select-Object -First 1 -ExpandProperty Version

                        if ($InstalledVersion) {
                            Write-AbrColorOutput -Color 'White' -String " - $Module module v$($InstalledVersion.ToString()) is currently installed."
                            $LatestVersion = Find-Module -Name $Module -Repository PSGallery -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version
                            if ($InstalledVersion -lt $LatestVersion) {
                                Write-AbrColorOutput -Color 'White' -String "  - $Module module v$($LatestVersion.ToString()) is available." -Color Red
                                Write-AbrColorOutput -Color 'White' -String "  - Run 'Update-Module -Name $Module -Force' to install the latest version." -Color Red
                            }
                        }
                    } catch {
                        Write-Error $_.Exception.Message
                    }
                }
            }
        }

        $IconDebug = $false

        if ($DraftMode) {
            $script:EdgeDebug = @{style = 'filled'; color = 'red' }
            $script:SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $script:NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
            $script:NodeDebugEdge = @{color = 'black'; style = 'red'; shape = 'plain' }
            $IconDebug = $true
        } else {
            $script:SubGraphDebug = @{style = 'invis'; color = 'gray' }
            $script:NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
            $script:NodeDebugEdge = @{color = 'transparent'; style = 'transparent'; shape = 'none' }
            $script:EdgeDebug = @{style = 'invis'; color = 'red' }
        }

        # Used to set diagram theme
        if ($DiagramTheme -eq 'Black') {
            $MainGraphBGColor = 'Black'
            $Edgecolor = 'White'
            $Fontcolor = 'White'
            $NodeFontcolor = 'White'
            $EdgeArrowSize = 1
            $EdgeLineWidth = 3
            $BackupServerBGColor = 'Black'
            $BackupServerFontColor = 'White'
        } elseif ($DiagramTheme -eq 'Neon') {
            $MainGraphBGColor = 'grey14'
            $Edgecolor = 'gold2'
            $Fontcolor = 'gold2'
            $NodeFontcolor = 'gold2'
            $EdgeArrowSize = 1
            $EdgeLineWidth = 3
            $BackupServerBGColor = 'grey14'
            $BackupServerFontColor = 'gold2'
        } elseif ($DiagramTheme -eq 'White') {
            $MainGraphBGColor = 'White'
            $Edgecolor = '#71797E'
            $Fontcolor = '#565656'
            $NodeFontcolor = 'Black'
            $EdgeArrowSize = 1
            $EdgeLineWidth = 3
            $BackupServerBGColor = switch ($NewIcons) {
                $true { '#dbdddf' }
                $false { '#ceedc4' }
            }
            $BackupServerFontColor = switch ($NewIcons) {
                $true { '#565656' }
                $false { '#005f4b' }
            }
        }

        $script:NewIcons = $false

        $RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $IconPath = Join-Path "$RootPath\Tools" 'icons'
        # $ImagePath = Join-Path $RootPath 'Private\Diagram\Images.ps1'

        # . $ImagePath

        if ($DiagramType -eq 'Backup-Infrastructure') {

            $Dir = 'TB'
        } else {
            $Dir = switch ($Direction) {
                'top-to-bottom' { 'TB' }
                'left-to-right' { 'LR' }
            }
        }

        # Validate Custom logo
        if ($Logo) {
            $CustomLogo = Test-AbrLogo -LogoPath (Get-ChildItem -Path $Logo).FullName -IconPath $IconPath -ImagesObj $Images
        } else {
            $CustomLogo = 'VBR_Logo'
        }
        # Validate Custom Signature Logo
        if ($SignatureLogo) {
            $CustomSignatureLogo = Test-AbrLogo -LogoPath (Get-ChildItem -Path $SignatureLogo).FullName -IconPath $IconPath -ImagesObj $Images
        }

        $MainGraphAttributes = @{
            pad = 1.0
            rankdir = $Dir
            splines = $EdgeType
            penwidth = 1.5
            fontname = 'Segoe Ui Black'
            fontcolor = $Fontcolor
            fontsize = 32
            style = 'dashed'
            labelloc = 't'
            imagepath = $IconPath
            nodesep = $NodeSeparation
            ranksep = $SectionSeparation
            bgcolor = $MainGraphBGColor

        }
    }

    process {

        foreach ($System in $Target) {

            if (Select-String -InputObject $System -Pattern '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                throw "Please use the Fully Qualified Domain Name (FQDN) instead of an IP address when connecting to the Backup Server: $System"
            }

            try {

                $script:VBRServer = (Get-VBRServerSession).Server

            } catch { throw "Unable to get Veeam Backup & Replication Server information: $System" }

            Get-AbrBackupServerInformation

            if ($BackupServerInfo) {
                Write-PScriboMessage 'Backup Server Information collected'
            } else {
                throw 'No Backup Server Information available to diagram'
            }

            $script:diGraph = Graph -Name VeeamVBR -Attributes $MainGraphAttributes {
                # Node default theme
                Node @{
                    # label = ''
                    shape = 'none'
                    labelloc = 't'
                    style = 'filled'
                    fillColor = 'transparent'
                    fontsize = 14
                    imagescale = $true
                    fontcolor = $NodeFontcolor
                }
                # Edge default theme
                Edge @{
                    style = 'dashed'
                    dir = 'both'
                    arrowtail = 'dot'
                    color = $Edgecolor
                    penwidth = $EdgeLineWidth
                    arrowsize = $EdgeArrowSize
                    fontcolor = $Edgecolor
                }

                if ($Signature) {
                    Write-PScriboMessage 'Generating diagram signature'
                    if ($CustomSignatureLogo) {
                        $Signature = (Add-HtmlSignatureTable -ImagesObj $Images -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -TableBorderColor $Edgecolor -CellBorder 0 -Align 'left' -Logo $CustomSignatureLogo -IconDebug $IconDebug)
                    } else {
                        $Signature = (Add-HtmlSignatureTable -ImagesObj $Images -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -TableBorderColor $Edgecolor -CellBorder 0 -Align 'left' -Logo 'VBR_LOGO_Footer' -IconDebug $IconDebug)
                    }
                } else {
                    Write-PScriboMessage 'No diagram signature specified'
                    $Signature = ' '
                }

                SubGraph OUTERDRAWBOARD1 -Attributes @{Label = $Signature; fontsize = 24; penwidth = 1.5; labelloc = 'b'; labeljust = 'r'; style = $SubGraphDebug.style; color = $SubGraphDebug.color } {
                    SubGraph MainGraph -Attributes @{Label = (Add-HtmlLabel -ImagesObj $Images -Label $MainGraphLabel -IconType $CustomLogo -IconDebug $IconDebug -IconWidth 300 -IconHeight 90 -FontName 'Segoe Ui Black' -FontColor $Fontcolor -Fontsize 28); fontsize = 24; penwidth = 0; labelloc = 't'; labeljust = 'c' } {

                        if ($DiagramType -eq 'Backup-to-HyperV-Proxy') {
                            Get-AbrDiagBackupServer
                            $BackuptoHyperVProxy = Get-AbrDiagBackupToHvProxy | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoHyperVProxy) {
                                $BackuptoHyperVProxy
                            } else {
                                throw 'No HyperV Proxy Infrastructure available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-vSphere-Proxy') {
                            Get-AbrDiagBackupServer
                            $BackuptovSphereProxy = Get-AbrDiagBackupToViProxy | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptovSphereProxy) {
                                $BackuptovSphereProxy
                            } else {
                                throw 'No vSphere Proxy Infrastructure available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-File-Proxy') {
                            Get-AbrDiagBackupServer
                            $BackuptoFileProxy = Get-AbrDiagBackupToFileProxy | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoFileProxy) {
                                $BackuptoFileProxy
                            } else {
                                throw 'No File Proxy Infrastructure available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-WanAccelerator') {
                            Get-AbrDiagBackupServer
                            $BackuptoWanAccelerator = Get-AbrDiagBackupToWanAccel | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoWanAccelerator) {
                                $BackuptoWanAccelerator
                            } else {
                                throw 'No Wan Accelerators available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-Repository') {
                            Get-AbrDiagBackupServer
                            $BackuptoRepository = Get-AbrDiagBackupToRepo | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoRepository) {
                                $BackuptoRepository
                            } else {
                                throw 'No Backup Repository available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-ProtectedGroup') {
                            Get-AbrDiagBackupServer
                            $BackuptoProtectedGroup = Get-AbrDiagBackupToProtectedGroup | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoProtectedGroup) {
                                $BackuptoProtectedGroup
                            } else {
                                throw 'No Backup Protected Group available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-Tape') {
                            Get-AbrDiagBackupServer
                            $BackupToTape = Get-AbrDiagBackupToTape | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackupToTape) {
                                $BackupToTape
                            } else {
                                throw 'No Tape Infrastructure available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-Sobr') {
                            Get-AbrDiagBackupServer
                            $BackuptoSobr = Get-AbrDiagBackupToSobr | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoSobr) {
                                $BackuptoSobr
                            } else {
                                throw 'No Scale-Out Backup Repository available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-Infrastructure') {
                            Get-AbrDiagBackupServer
                            $BackupInfra = Get-AbrInfraDiagram | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackupInfra) {
                                $BackupInfra
                            } else {
                                throw 'No Backup Infrastructure available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-CloudConnect') {
                            Get-AbrDiagBackupServer
                            $BackuptoCloudConnect = Get-AbrDiagBackupToCloudConnect | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoCloudConnect) {
                                $BackuptoCloudConnect
                            } else {
                                throw 'No Cloud Connect infrastructure available to diagram'
                            }
                        } elseif ($DiagramType -eq 'Backup-to-CloudConnect-Tenant') {
                            $BackuptoCloudConnectTenant = Get-AbrDiagBackupToCloudConnectTenant | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch
                            if ($BackuptoCloudConnectTenant) {
                                $BackuptoCloudConnectTenant
                            } else {
                                throw 'No Cloud Connect Tenant infrastructure available to diagram'
                            }
                        }
                    }
                }
            }
        }
    }
    end {
        if ($diGraph) {
            #Export Diagram
            foreach ($OutputFormat in $Format) {

                $OutputDiagram = Export-AbrDiagram -GraphObj ($diGraph | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch) -ErrorDebug $EnableErrorDebug -Format $OutputFormat -Filename $Filename -OutputFolderPath $OutputFolderPath -WaterMarkText $WaterMarkText -WaterMarkColor $WaterMarkColor -IconPath $IconPath -Verbose:$Verbose -Rotate $Rotate

                if ($OutputDiagram) {
                    if ($OutputFormat -ne 'Base64') {
                        # If not Base64 format return image path
                        Write-AbrColorOutput -Color 'White' -String ("Diagrammer diagram '{0}' has been saved to '{1}'" -f $OutputDiagram.Name, $OutputDiagram.Directory)
                    } else {
                        Write-PScriboMessage 'Displaying Base64 string'
                        # Return Base64 string
                        $OutputDiagram
                    }
                }
            }
        }

        if ($EnableErrorDebug) {
            $global:VerbosePreference = 'SilentlyContinue'
            $global:DebugPreference = 'SilentlyContinue'
        }
    }
}