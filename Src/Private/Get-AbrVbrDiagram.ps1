function Get-AbrVbrDiagram {
    <#
    .SYNOPSIS
        Diagram the configuration of Veeam Backup & Replication infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .DESCRIPTION
        Diagram the configuration of Veeam Backup & Replication infrastructure in PDF/SVG/DOT/PNG formats using PSGraph and Graphviz.
    .PARAMETER Format
        Specifies the output format of the diagram.
        The supported output formats are PDF, PNG, DOT & SVG.
        Multiple output formats may be specified, separated by a comma.
    .PARAMETER NodeSeparation
        Controls Node separation ratio in visualization
        By default, NodeSeparation will be set to .60.
    .PARAMETER SectionSeparation
        Controls Section (Subgraph) separation ratio in visualization
        By default, NodeSeparation will be set to .75.
    .PARAMETER EdgeType
        Controls how edges lines appear in visualization
        The supported edge type are:
            'polyline', 'curved', 'ortho', 'line', 'spline'
        By default, EdgeType will be set to spline.
        References: https://graphviz.org/docs/attrs/splines/
    .PARAMETER OutputFolderPath
        Specifies the folder path to save the diagram.
    .PARAMETER Filename
        Specifies a filename for the diagram.
    .PARAMETER EnableEdgeDebug
        Control to enable edge debugging ( Dummy Edge and Node lines ).
    .PARAMETER EnableSubGraphDebug
        Control to enable subgraph debugging ( Subgraph Lines ).
    .PARAMETER EnableErrorDebug
        Control to enable error debugging.
    .PARAMETER AuthorName
        Allow to set footer signature Author Name.
    .PARAMETER CompanyName
        Allow to set footer signature Company Name.
    .PARAMETER Logo
        Allow to change the Veeam logo to a custom one.
        Image should be 400px x 100px or less in size.
    .PARAMETER SignatureLogo
        Allow to change the Diagrammer signature logo to a custom one.
        Image should be 120px x 130px or less in size.
    .PARAMETER Signature
        Allow the creation of footer signature.
        AuthorName and CompanyName must be set to use this property.
    .NOTES
        Version:        0.8.9
        Author(s):      Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Kevin Marquette (@KevinMarquette) -  PSGraph module
        Credits:        Prateek Singh (@PrateekKumarSingh) - AzViz module
    .LINK
        https://github.com/rebelinux/
        https://github.com/KevinMarquette/PSGraph
        https://github.com/PrateekKumarSingh/AzViz
    #>

    [Diagnostics.CodeAnalysis.SuppressMessage(
        'PSUseShouldProcessForStateChangingFunctions',
        ''
    )]

    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName = 'Credential'
    )]
    param (

        [Parameter(
            Position = 4,
            Mandatory = $false,
            HelpMessage = 'Please provide the diagram output format'
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('pdf', 'svg', 'png', 'dot', 'base64')]
        [Array] $Format = 'pdf',

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
        [String] $Filename,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Controls how edges lines appear in visualization'
        )]
        [ValidateSet('polyline', 'curved', 'ortho', 'line', 'spline')]
        [string] $EdgeType = 'line',

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
            HelpMessage = 'Allow to enable edge debugging ( Dummy Edge and Node lines)'
        )]
        [Switch] $EnableEdgeDebug = $false,

        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Allow to enable subgraph debugging ( Subgraph Lines )'
        )]
        [Switch] $EnableSubGraphDebug = $false,
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
        [Switch] $Signature = $false
    )


    begin {

        # Variable translating Icon to Image Path ($IconPath)
        $script:Images = @{
            "VBR_Server" = "VBR_server.png"
            "VBR_Repository" = "VBR_Repository.png"
            "VBR_Deduplicating_Storage" = "Deduplicating_Storage.png"
            "VBR_Linux_Repository" = "Linux_Repository.png"
            "VBR_Windows_Repository" = "Windows_Repository.png"
            "VBR_Cloud_Repository" = "Cloud_Repository.png"
            "VBR_Object_Repository" = "Object_Storage.png"
            "VBR_Object" = "Object_Storage_support.png"
            "VBR_Server_DB" = "Microsoft_SQL_DB.png"
            "VBR_Proxy" = "Veeam_Proxy.png"
            "VBR_Proxy_Server" = "Proxy_Server.png"
            "VBR_Wan_Accel" = "WAN_accelerator.png"
            "VBR_SOBR" = "Logo_SOBR.png"
            "VBR_SOBR_Repo" = "Scale_out_Backup_Repository.png"
            "VBR_LOGO" = "Veeam_logo.png"
            "VBR_No_Icon" = "no_icon.png"
            'VBR_Storage_NetApp' = "Storage_NetApp.png"
            'VBR_vCenter_Server' = 'vCenter_server.png'
            'VBR_ESXi_Server' = 'ESXi_host.png'
            'VBR_HyperV_Server' = 'Hyper-V_host.png'
            'VBR_Server_EM' = 'Veeam_Backup_Enterprise_Manager.png'
            'VBR_Tape_Server' = 'Tape_Server.png'
            'VBR_Tape_Library' = 'Tape_Library.png'
            'VBR_Tape_Drive' = 'Tape_Drive.png'
            'VBR_Tape_Vaults' = 'Tape encrypted.png'
            "VBR_Server_DB_PG" = "PostGre_SQL_DB.png"
            "VBR_LOGO_Footer" = "verified_recoverability.png"
            "VBR_AGENT_Container" = "Folder.png"
            "VBR_AGENT_AD" = "Server.png"
            "VBR_AGENT_MC" = "Task list.png"
            "VBR_AGENT_IC" = "Workstation.png"
            "VBR_AGENT_CSV" = "CSV_Computers.png"
            "VBR_AGENT_AD_Logo" = "Microsoft Active Directory.png"
            "VBR_AGENT_CSV_Logo" = "File.png"
            "VBR_AGENT_Server" = "Server_with_Veeam_Agent.png"
            "VBR_vSphere" = "VMware_vSphere.png"
            "VBR_HyperV" = "Microsoft_SCVMM.png"
            "VBR_Tape" = "Tape.png"
            "VBR_Service_Providers" = "Veeam_Service_Provider_Console.png"
            "VBR_Service_Providers_Server" = "Veeam_Service_Provider_Server.png"
        }

        if (($Format -ne "base64") -and !(Test-Path $OutputFolderPath)) {
            Write-Error "OutputFolderPath '$OutputFolderPath' is not a valid folder path."
            break
        }

        if ($Signature -and (([string]::IsNullOrEmpty($AuthorName)) -or ([string]::IsNullOrEmpty($CompanyName)))) {
            throw "Get-AbrVbrDiagram: AuthorName and CompanyName must be defined if the Signature option is specified"
        }

        $MainGraphLabel = "Backup &amp; Replication Infrastructure"

        $IconDebug = $false

        if ($EnableEdgeDebug) {
            $EdgeDebug = @{style = 'filled'; color = 'red' }
            $IconDebug = $true
        } else { $EdgeDebug = @{style = 'invis'; color = 'red' } }

        if ($EnableSubGraphDebug) {
            $SubGraphDebug = @{style = 'dashed'; color = 'red' }
            $NodeDebug = @{color = 'black'; style = 'red'; shape = 'plain' }
            $IconDebug = $true
        } else {
            $SubGraphDebug = @{style = 'invis'; color = 'gray' }
            $NodeDebug = @{color = 'transparent'; style = 'transparent'; shape = 'point' }
        }

        $RootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $IconPath = Join-Path $RootPath 'icons'
        $Dir = 'top-to-bottom'

        # Validate Custom logo
        if ($Logo) {
            $CustomLogo = Test-Logo -LogoPath (Get-ChildItem -Path $Logo).FullName -IconPath $IconPath -ImagesObj $Images
        } else {
            $CustomLogo = "VBR_LOGO"
        }
        # Validate Custom Signature Logo
        if ($SignatureLogo) {
            $CustomSignatureLogo = Test-Logo -LogoPath (Get-ChildItem -Path $SignatureLogo).FullName -IconPath $IconPath -ImagesObj $Images
        }

        $MainGraphAttributes = @{
            pad = 1
            rankdir = $Dir
            overlap = 'false'
            splines = $EdgeType
            penwidth = 1.5
            fontname = "Segoe Ui Black"
            fontcolor = '#005f4b'
            fontsize = 32
            style = "dashed"
            labelloc = 't'
            imagepath = $IconPath
            nodesep = $NodeSeparation
            ranksep = $SectionSeparation
        }
    }

    process {

        # Graph default atrributes
        $script:Graph = Graph -Name VeeamVBR -Attributes $MainGraphAttributes {
            # Node default theme
            Node @{
                label = ''
                shape = 'none'
                labelloc = 't'
                style = 'filled'
                fillColor = '#71797E'
                fontsize = 14;
                imagescale = $true
            }
            # Edge default theme
            Edge @{
                style = 'dashed'
                dir = 'both'
                arrowtail = 'dot'
                color = '#71797E'
                penwidth = 3
                arrowsize = 1
            }

            # Signature Section
            if ($Signature) {
                Write-PScriboMessage "Generating diagram signature"
                if ($CustomSignatureLogo) {
                    $Signature = (Get-DiaHTMLTable -ImagesObj $Images -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -CellBorder 0 -Align 'left' -Logo $CustomSignatureLogo -IconDebug $IconDebug)
                } else {
                    $Signature = (Get-DiaHTMLTable -ImagesObj $Images -Rows "Author: $($AuthorName)", "Company: $($CompanyName)" -TableBorder 2 -CellBorder 0 -Align 'left' -Logo "VBR_LOGO_Footer" -IconDebug $IconDebug)
                }
            } else {
                Write-PScriboMessage "No diagram signature specified"
                $Signature = " "
            }

            #---------------------------------------------------------------------------------------------#
            #                             Graphviz Clusters (SubGraph) Section                            #
            #               SubGraph can be use to bungle the Nodes together like a single entity         #
            #                     SubGraph allow you to have a graph within a graph                       #
            #                PSgraph: https://psgraph.readthedocs.io/en/latest/Command-SubGraph/          #
            #                      Graphviz: https://graphviz.org/docs/attrs/cluster/                     #
            #---------------------------------------------------------------------------------------------#

            # Subgraph OUTERDRAWBOARD1 used to draw the footer signature (bottom-right corner)
            SubGraph OUTERDRAWBOARD1 -Attributes @{Label = $Signature; fontsize = 24; penwidth = 1.5; labelloc = 'b'; labeljust = "r"; style = $SubGraphDebug.style; color = $SubGraphDebug.color } {
                # Subgraph MainGraph used to draw the main drawboard.
                SubGraph MainGraph -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label $MainGraphLabel -IconType $CustomLogo -IconDebug $IconDebug -IconWidth 250 -IconHeight 80); fontsize = 24; penwidth = 0; labelloc = 't'; labeljust = "c" } {

                    if ($BackupServers) {

                        #-----------------------------------------------------------------------------------------------#
                        #                                Graphviz Node Section                                          #
                        #                 Nodes are Graphviz elements used to define a object entity                    #
                        #                Nodes can have attribues like Shape, HTML Labels, Styles etc..                 #
                        #               PSgraph: https://psgraph.readthedocs.io/en/latest/Command-Node/                 #
                        #                     Graphviz: https://graphviz.org/doc/info/shapes.html                       #
                        #-----------------------------------------------------------------------------------------------#

                        # Used for debugging
                        if ($Options.DiagramObjDebug) {
                            Get-VBRDebugObject
                        }

                        # Get Veeam Backup Server Infrastructure Information
                        # This create the Backup Server, Database and Enterprise Manager Objects
                        # Here Veeam Pwershell Module are used to retreive the information
                        Get-VBRBackupServerInfo

                        # Build Backup Server Graphviz Cluster
                        Get-VbrBackupSvrDiagramObj

                        # Proxy Graphviz Cluster
                        $Proxie = Get-VbrProxyInfo
                        if ($Proxies) {

                            SubGraph ProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxies" -IconType "VBR_Proxy" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                if ($Proxies | Where-Object { $_.AditionalInfo.Type -eq "vSphere" }) {
                                    SubGraph ViProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "VMware Proxies" -IconType "VBR_vSphere" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                        Node ViProxies @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject (($Proxies | Where-Object { $_.AditionalInfo.Type -eq "vSphere" }) | ForEach-Object { $_.Name.split('.')[0] }) -Align "Center" -iconType "VBR_Proxy_Server" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo ($Proxies.AditionalInfo | Where-Object { $_.Type -eq "vSphere" })); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                                    }
                                }

                                if ($Proxies.AditionalInfo | Where-Object { $_.Type -eq "Off host" -or $_.Type -eq "On host" }) {
                                    SubGraph HvProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Hyper-V Proxies" -IconType "VBR_HyperV" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                        Node HvProxies @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject (($Proxies | Where-Object { $_.AditionalInfo.Type -eq "Off host" -or $_.AditionalInfo.Type -eq "On host" }).Name | ForEach-Object { $_.split('.')[0] }) -Align "Center" -iconType "VBR_Proxy_Server" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo ($Proxies.AditionalInfo | Where-Object { $_.Type -eq "Off host" -or $_.Type -eq "On host" })); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                                    }
                                }
                            }
                        } else {
                            SubGraph ProxyServer -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Proxies" -IconType "VBR_Proxy" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node -Name Proxies -Attributes @{Label = 'No Backup Proxies'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # SOBR Graphviz Cluster
                        $SOBR = Get-VbrSOBRInfo
                        if ($SOBR) {
                            SubGraph SOBR -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Scale-Out Backup Repositories" -IconType "VBR_SOBR" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node SOBRRepo @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($SOBR | ForEach-Object { $_.Name.split('.')[0] }) -Align "Center" -iconType "VBR_SOBR_Repo" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $SOBR.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

                            }
                        }

                        # Repositories Graphviz Cluster
                        $RepositoriesInfo = Get-VbrRepositoryInfo
                        if ($RepositoriesInfo) {
                            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "VBR_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node Repositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $RepositoriesInfo.Name -Align "Center" -iconType "VBR_Windows_Repository" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $RepositoriesInfo.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                            }
                        } else {
                            SubGraph Repos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Backup Repositories" -IconType "VBR_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                Node -Name Repositories -Attributes @{Label = 'No Backup Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "3"; height = "2"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }
                        # Object Repositories Graphviz Cluster
                        $ObjectRepositoriesInfos = Get-VbrObjectRepoInfo
                        $ArchObjRepositoriesInfos = Get-VbrArchObjectRepoInfo
                        if ($ObjectRepositoriesInfo -or $ArchObjRepositoriesInfo) {
                            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Storage" -IconType "VBR_Object" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                if ($ObjectRepositoriesInfo) {
                                    SubGraph ObjectRepo -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Repositories" -IconType "VBR_Object_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                        Node ObjectRepositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $ObjectRepositoriesInfo.Name -Align "Center" -iconType "VBR_Object_Repository" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ObjectRepositoriesInfo.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                                    }
                                }

                                if ($ArchObjRepositoriesInfo) {
                                    SubGraph ArchObjectRepo -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Archives Object Repositories" -IconType "VBR_Object_Repository" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                        Node ArchObjectRepositories @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $ArchObjRepositoriesInfo.Name -Align "Center" -iconType "VBR_Object_Repository" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ArchObjRepositoriesInfo.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                                    }
                                }
                            }
                        } else {
                            SubGraph ObjectRepos -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Object Storage" -IconType "VBR_Object" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node -Name ObjectRepo -Attributes @{Label = 'No Object Storage Repositories'; shape = "rectangle"; labelloc = 'c'; fixedsize = $true; width = "4"; height = "3"; fillColor = 'transparent'; penwidth = 0 }
                            }
                        }

                        # WanAccels Graphviz Cluster
                        $WanAccels = Get-VbrWanAccelInfo
                        if ($WanAccels) {
                            SubGraph WanAccels -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Wan Accelerators" -IconType "VBR_Wan_Accel" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node WanAccelServer @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject ($WanAccels | ForEach-Object { $_.Name.split('.')[0] }) -Align "Center" -iconType "VBR_Wan_Accel" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $WanAccels.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }

                            }
                        }

                        # # Tapes Graphviz Cluster
                        $TapeServerInfo = Get-VbrTapeServersInfo
                        $TapeLibraryInfo = Get-VbrTapeLibraryInfo
                        $TapeVaultInfo = Get-VbrTapeVaultInfo
                        if ($TapeServerInfo) {
                            SubGraph TapeInfra -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Tape Infrastructure" -IconType "VBR_Tape" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {
                                SubGraph TapeServers -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Tape Servers" -IconType "VBR_Tape_Server" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                    Node TapeServer @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $TapeServerInfo.Name -Align "Center" -iconType "VBR_Tape_Server" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $TapeServerInfo.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                                }

                                if ($TapeLibraryInfo) {
                                    SubGraph TapeLibraries -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Tape Library" -IconType "VBR_Tape_Library" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                        Node TapeLibrary @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $TapeLibraryInfo.Name -Align "Center" -iconType "VBR_Tape_Library" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $TapeLibraryInfo.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                                    }
                                }

                                if ($TapeVaultInfo) {
                                    SubGraph TapeVaults -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Tape Vaults" -IconType "VBR_Tape_Vaults" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 'b'; style = 'dashed,rounded' } {

                                        Node TapeVault @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $TapeVaultInfo.Name -Align "Center" -iconType "VBR_Tape_Vaults" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $TapeVaultInfo.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                                    }
                                }
                            }
                        }

                        $ServiceProviderInfo = Get-VbrServiceProviderInfo
                        if ($ServiceProviderInfo) {
                            SubGraph ServiceProviders -Attributes @{Label = (Get-DiaHTMLLabel -ImagesObj $Images -Label "Service Providers" -IconType "VBR_Service_Providers" -SubgraphLabel -IconDebug $IconDebug); fontsize = 18; penwidth = 1.5; labelloc = 't'; style = 'dashed,rounded' } {

                                Node ServiceProvider @{Label = (Get-DiaHTMLNodeTable -ImagesObj $Images -inputObject $ServiceProviderInfo.Name -Align "Center" -iconType "VBR_Service_Providers_Server" -columnSize 3 -IconDebug $IconDebug -MultiIcon -AditionalInfo $ServiceProviderInfo.AditionalInfo); shape = 'plain'; fillColor = 'transparent'; fontsize = 14; fontname = "Segoe Ui" }
                            }
                        }

                        # Veeam VBR elements point of connection (Dummy Nodes!)
                        $Node = @('VBRServerPointSpace', 'VBRProxyPoint', 'VBRProxyPointSpace', 'VBRRepoPoint')

                        if ($WanAccels) {
                            $Node += 'VBRWanAccelPoint', 'VBRRepoPointSpace'
                        } else {
                            $Node += 'VBRRepoPointSpace'

                        }

                        if ($TapeServerInfo) {
                            $Node += 'VBRTapePoint'
                        }

                        if ($ServiceProviderInfo) {
                            $Node += 'VBRServiceProviderPoint'
                        }

                        Node $Node -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebug.color; fillColor = $NodeDebug.style; shape = $NodeDebug.shape }

                        $NodeStartEnd = @('VBRStartPoint', 'VBREndPointSpace')
                        Node $NodeStartEnd -NodeScript { $_ } @{Label = { $_ } ; fontcolor = $NodeDebug.color; shape = 'point'; fixedsize = 'true'; width = .2 ; height = .2 }

                        #---------------------------------------------------------------------------------------------#
                        #                             Graphviz Rank Section                                           #
                        #                     Rank allow to put Nodes on the same group level                         #
                        #         PSgraph: https://psgraph.readthedocs.io/en/stable/Command-Rank-Advanced/            #
                        #                     Graphviz: https://graphviz.org/docs/attrs/rank/                         #
                        #---------------------------------------------------------------------------------------------#

                        # Put the dummy node in the same rank to be able to create a horizontal line
                        Rank $NodeStartEnd, $Node

                        #---------------------------------------------------------------------------------------------#
                        #                             Graphviz Edge Section                                           #
                        #                   Edges are Graphviz elements use to interconnect Nodes                     #
                        #                 Edges can have attribues like Shape, Size, Styles etc..                     #
                        #              PSgraph: https://psgraph.readthedocs.io/en/latest/Command-Edge/                #
                        #                      Graphviz: https://graphviz.org/docs/edges/                             #
                        #---------------------------------------------------------------------------------------------#

                        # Connect the Dummy Node in a straight line
                        # VBRStartPoint --- VBRServerPointSpace --- VBRProxyPoint --- VBRProxyPointSpace --- VBRRepoPoint --- VBREndPointSpace
                        Edge -From VBRStartPoint -To VBRServerPointSpace @{minlen = 20; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VBRServerPointSpace -To VBRProxyPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VBRProxyPoint -To VBRProxyPointSpace @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VBRProxyPointSpace -To VBRRepoPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        Edge -From VBRRepoPoint -To VBRRepoPointSpace @{minlen = 16; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }

                        if ($TapeServerInfo -and $WanAccels -and $ServiceProviderInfo) {
                            Edge -From VBRRepoPointSpace -To VBRWanAccelPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            Edge -From VBRWanAccelPoint -To VBRTapePoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            Edge -From VBRTapePoint -To VBRServiceProviderPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            $LastPoint = 'VBRServiceProviderPoint'

                        } elseif ($TapeServerInfo -and (-Not $WanAccels) -and $ServiceProviderInfo) {
                            Edge -From VBRRepoPointSpace -To VBRTapePoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            Edge -From VBRTapePoint -To VBRServiceProviderPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            $LastPoint = 'VBRServiceProviderPoint'
                        } elseif ($TapeServerInfo -and (-Not $WanAccels) -and (-Not $ServiceProviderInfo)) {
                            Edge -From VBRRepoPointSpace -To VBRTapePoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            $LastPoint = 'VBRTapePoint'
                        } elseif ((-Not $TapeServerInfo) -and $WanAccels -and $ServiceProviderInfo) {
                            Edge -From VBRRepoPointSpace -To VBRWanAccelPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            Edge -From VBRWanAccelPoint -To VBRServiceProviderPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            $LastPoint = 'VBRServiceProviderPoint'
                        } elseif ((-Not $TapeServerInfo) -and (-Not $WanAccels) -and $ServiceProviderInfo) {
                            Edge -From VBRRepoPointSpace -To VBRServiceProviderPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            $LastPoint = 'VBRServiceProviderPoint'

                        } elseif ((-Not $TapeServerInfo) -and $WanAccels -and (-Not $ServiceProviderInfo)) {
                            Edge -From VBRRepoPointSpace -To VBRWanAccelPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            $LastPoint = 'VBRWanAccelPoint'
                        } elseif ($TapeServerInfo -and $WanAccels -and (-Not $ServiceProviderInfo)) {
                            Edge -From VBRRepoPointSpace -To VBRWanAccelPoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            Edge -From VBRWanAccelPoint -To VBRTapePoint @{minlen = 12; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                            $LastPoint = 'VBRTapePoint'
                        } elseif ((-Not $TapeServerInfo) -and (-Not $WanAccels) -and (-Not $ServiceProviderInfo)) {
                            $LastPoint = 'VBRRepoPointSpace'
                        }

                        ####################################################################################
                        #                                                                                  #
                        #      This section connect the Infrastructure component to the Dummy Points       #
                        #                                                                                  #
                        ####################################################################################

                        # Connect Veeam Backup server to the Dummy line
                        Edge -From $BackupServerInfo.Name -To VBRServerPointSpace @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

                        # Connect Veeam Proxies Server to the Dummy line
                        if ($Proxies | Where-Object { $_.AditionalInfo.Type -eq 'vSphere' }) {
                            Edge -From VBRProxyPoint -To ViProxies @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
                        } else {
                            Edge -From VBRProxyPoint -To HvProxies @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
                        }
                        # Connect Veeam Repository to the Dummy line
                        Edge -From VBRRepoPoint -To Repositories @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }

                        # Connect Veeam Object Repository to the Dummy line
                        if ($ObjectRepositoriesInfo) {
                            Edge -To VBRRepoPoint -From ObjectRepositories @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }

                        } elseif ($ArchObjRepositoriesInfo) {
                            Edge -To VBRRepoPoint -From ArchObjectRepositories @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
                        } else {
                            Edge -To VBRRepoPoint -From ObjectRepo @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
                        }

                        # Connect Veeam Wan Accelerator to the Dummy line
                        if ($WanAccels) {
                            Edge -From WanAccelServer -To VBRWanAccelPoint @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
                        }

                        # Connect Veeam Scale-Out Backup Repository to the Dummy line
                        if ($SOBR) {
                            Edge -From VBRRepoPointSpace -To SOBRRepo @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
                        }

                        # Connect Veeam Tape Infra to VBRTapePoint Dummy line
                        if ($TapeServerInfo) {
                            Edge -From VBRTapePoint -To TapeServer @{minlen = 2; arrowtail = 'none'; arrowhead = 'dot'; style = 'dashed' }
                        }

                        # Connect Veeam ServiceProvider Infra to VBRServiceProviderPoint Dummy line
                        if ($ServiceProviderInfo) {
                            Edge -From ServiceProvider -To VBRServiceProviderPoint @{minlen = 2; arrowtail = 'dot'; arrowhead = 'none'; style = 'dashed' }
                        }

                        ####################################################################################
                        #                                                                                  #
                        #   This section connect the Last Infrastructure component to VBREndPointSpace     #
                        #                                                                                  #
                        ####################################################################################

                        if ($LastPoint) {
                            Edge -From $LastPoint -To VBREndPointSpace @{minlen = 30; arrowtail = 'none'; arrowhead = 'none'; style = 'filled' }
                        }
                    }
                }
            }
        }
    }
    end {
        foreach ($OutputFormat in $Format) {
            #Export the Diagram
            if ($Graph) {
                Export-Diagrammer -GraphObj ($Graph | Select-String -Pattern '"([A-Z])\w+"\s\[label="";style="invis";shape="point";]' -NotMatch) -ErrorDebug $EnableErrorDebug -Format $OutputFormat -Filename "$Filename.$OutputFormat" -OutputFolderPath $OutputFolderPath -WaterMarkText $Options.DiagramWaterMark -WaterMarkColor "Green" -IconPath $IconPath
            } else {
                Write-PScriboMessage -IsWarning "No Graph object found. Disabling diagram section"
            }
        }
    }
}