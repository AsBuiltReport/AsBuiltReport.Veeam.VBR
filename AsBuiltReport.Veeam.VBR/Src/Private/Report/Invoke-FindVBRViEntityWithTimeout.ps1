function Invoke-FindVBRViEntityWithTimeout {
    <#
        .SYNOPSIS
        Specifies connection and filtering options for retrieving vSphere inventory objects.

        .DESCRIPTION
        Use these parameters to control which categories of vSphere inventory objects are returned and how long to wait for a server response. Only one (or a meaningful combination) of the scope switches should typically be used to narrow the query. If multiple conflicting switches are supplied the implementation should define precedence or raise an error.

        .PARAMETER TimeoutSeconds
        Maximum number of seconds to wait for the operation (such as connecting to the vCenter/ESXi host or fetching inventory) before timing out. Defaults to 30 seconds.

        .PARAMETER Server
        The target vCenter or ESXi server hostname or IP address against which the inventory query or connection is performed.

        .PARAMETER Name
        Optional name filter used to match inventory objects. Supports exact or pattern matching depending on implementation.

        .PARAMETER HostsAndDatastoresOnly
        When specified, limits the result set to host systems and datastores only.

        .PARAMETER VMAndTemplatesOnly
        When specified, returns only virtual machines and VM templates.

        .PARAMETER DatastoresAndVMsOnly
        When specified, limits results to datastores plus virtual machines (excluding other object types).

        .PARAMETER HostsAndClustersOnly
        When specified, returns only ESXi hosts and cluster objects.

        .PARAMETER ResourcePoolsOnly
        When specified, returns only resource pool objects.

        .PARAMETER ServersOnly
        When specified, returns only top-level server (vCenter / ESXi) objects, excluding subordinate inventory items.

        .NOTES
        Choose only the switch or combination that matches the desired inventory scope to avoid unnecessary data retrieval. TimeoutSeconds may need adjustment for large environments.

        .EXAMPLE
        # Retrieve only hosts and clusters from a specified vCenter within a 60 second timeout.
        # (Example usage assumes these parameters belong to a function.)
        Invoke-FindVBRViEntityWithTimeout -Server vcsa01.lab.local -TimeoutSeconds 60 -HostsAndClustersOnly

        .EXAMPLE
        # Fetch virtual machines matching a name pattern.
        Invoke-FindVBRViEntityWithTimeout -Server vcsa01.lab.local -Name "Web*" -VMAndTemplatesOnly
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'HostsAndDatastoresOnly')]
        [Parameter(ParameterSetName = 'VMAndTemplatesOnly')]
        [Parameter(ParameterSetName = 'DatastoresAndVMsOnly')]
        [Parameter(ParameterSetName = 'HostsAndClustersOnly')]
        [Parameter(ParameterSetName = 'ResourcePoolsOnly')]
        [Parameter(ParameterSetName = 'ServersOnly')]
        [Parameter(HelpMessage = 'Maximum number of seconds to wait before timing out. Default is 30.', ParameterSetName = 'Default')]
        [int]$TimeoutSeconds = 30,

        [Parameter(ParameterSetName = 'HostsAndDatastoresOnly')]
        [Parameter(ParameterSetName = 'VMAndTemplatesOnly')]
        [Parameter(ParameterSetName = 'DatastoresAndVMsOnly')]
        [Parameter(ParameterSetName = 'HostsAndClustersOnly')]
        [Parameter(ParameterSetName = 'ResourcePoolsOnly')]
        [Parameter(ParameterSetName = 'ServersOnly')]
        [Parameter(HelpMessage = 'The target vCenter or ESXi server hostname or IP address.', ParameterSetName = 'Default')]
        [string]$Server,

        [Parameter(ParameterSetName = 'HostsAndDatastoresOnly')]
        [Parameter(ParameterSetName = 'VMAndTemplatesOnly')]
        [Parameter(ParameterSetName = 'DatastoresAndVMsOnly')]
        [Parameter(ParameterSetName = 'HostsAndClustersOnly')]
        [Parameter(ParameterSetName = 'ResourcePoolsOnly')]
        [Parameter(ParameterSetName = 'ServersOnly')]
        [Parameter(HelpMessage = 'Specifies an array of VMware object names. The cmdlet will return entities with these names.', ParameterSetName = 'Default')]
        [string]$Name,

        [Parameter(HelpMessage = 'Limits the result set to host systems and datastores only.', ParameterSetName = 'HostsAndDatastoresOnly')]
        [switch]$HostsAndDatastoresOnly,

        [Parameter(HelpMessage = 'Returns only virtual machines and VM templates.', ParameterSetName = 'VMAndTemplatesOnly')]
        [switch]$VMAndTemplatesOnly,

        [Parameter(HelpMessage = 'Limits results to datastores plus virtual machines.', ParameterSetName = 'DatastoresAndVMsOnly')]
        [switch]$DatastoresAndVMsOnly,

        [Parameter(HelpMessage = 'Returns only ESXi hosts and cluster objects.', ParameterSetName = 'HostsAndClustersOnly')]
        [switch]$HostsAndClustersOnly,

        [Parameter(HelpMessage = 'Returns only resource pool objects.', ParameterSetName = 'ResourcePoolsOnly')]
        [switch]$ResourcePoolsOnly,

        [Parameter(HelpMessage = 'Returns only top-level server objects (vCenter/ESXi).', ParameterSetName = 'ServersOnly')]
        [switch]$ServersOnly
    )

    begin {
    }

    process {
        # Prepare an isolated runspace
        $runspace = [runspacefactory]::CreateRunspace()
        $runspace.Open()

        # Pass switch state into runspace
        $runspace.SessionStateProxy.SetVariable('HostsAndDatastoresOnly', $HostsAndDatastoresOnly.IsPresent)
        $runspace.SessionStateProxy.SetVariable('VMAndTemplatesOnly', $VMAndTemplatesOnly.IsPresent)
        $runspace.SessionStateProxy.SetVariable('DatastoresAndVMsOnly', $DatastoresAndVMsOnly.IsPresent)
        $runspace.SessionStateProxy.SetVariable('HostsAndClustersOnly', $HostsAndClustersOnly.IsPresent)
        $runspace.SessionStateProxy.SetVariable('ResourcePoolsOnly', $ResourcePoolsOnly.IsPresent)
        $runspace.SessionStateProxy.SetVariable('ServersOnly', $ServersOnly.IsPresent)
        $runspace.SessionStateProxy.SetVariable('Server', $Server)
        $runspace.SessionStateProxy.SetVariable('Name', $Name)

        $ps = [powershell]::Create()
        $ps.Runspace = $runspace

        # Build the script to execute
        $null = $ps.AddScript({
                $CommandSet = @{}
                if ($Server) {
                    $CommandSet.Add('Server', $Server )
                }

                if ($Name) {
                    $CommandSet.Add('Name', $Name )
                }
                if ($HostsAndDatastoresOnly) {
                    Find-VBRViEntity @CommandSet -HostsAndDatastores
                } elseif ($VMAndTemplatesOnly) {
                    Find-VBRViEntity @CommandSet -VMsAndTemplates
                } elseif ($DatastoresAndVMsOnly) {
                    Find-VBRViEntity @CommandSet -DatastoresAndVMs
                } elseif ($HostsAndClustersOnly) {
                    Find-VBRViEntity @CommandSet -HostsAndClusters
                } elseif ($ResourcePoolsOnly) {
                    Find-VBRViEntity @CommandSet -ResourcePools
                } elseif ($ServersOnly) {
                    Find-VBRViEntity @CommandSet -Servers
                } else {
                    Find-VBRViEntity @CommandSet
                }
            })

        # Start async invocation
        $async = $ps.BeginInvoke()

        # Wait for completion up to timeout
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutSeconds * 1000)) {
            try { $ps.Stop() } catch { Out-Null }
            $runspace.Close()
            Write-Verbose "Timeout after $TimeoutSeconds seconds waiting for Find-VBRViEntity."
        }

        # Collect results
        $result = $ps.EndInvoke($async)
        $runspace.Close()
        return $result
    }
    end {}
}