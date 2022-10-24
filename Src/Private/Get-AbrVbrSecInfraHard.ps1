
function Get-AbrVbrSecInfraHard {
    <#
    .SYNOPSIS
    Used by As Built Report to returns security infrastructure hardening recomendations from Veeam Backup & Replication.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.6.0
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
        Write-PscriboMessage "Discovering Veeam VBR security infrastructure hardening recomendations from $System."
    }

    process {
        try {
            $Servers = Get-VBRServer
            $BackupServer = Get-VBRServer -Type Local
            Section -Style Heading3 "Backup & Replication Server ($($BackupServer.Name.ToString().ToUpper().Split(".")[0]))" {
                if (($BackupServer).count -gt 0) {
                    $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                    $Software = @()
                    $SoftwareX64 = Invoke-Command -Session $PssSession -ScriptBlock {Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object -Property DisplayName,Publisher,InstallDate | Sort-Object -Property DisplayName}
                    $SoftwareX86 = Invoke-Command -Session $PssSession -ScriptBlock {Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object -Property DisplayName,Publisher,InstallDate | Sort-Object -Property DisplayName}
                    Remove-PSSession -Session $PssSession

                    If ($SoftwareX64) {
                        $Software += $SoftwareX64
                    }
                    If ($SoftwareX86) {
                        $Software += $SoftwareX86
                    }

                    try {
                        $Unused = if ( $Software ) {
                            $OutObj = @()
                            foreach ($APP in ($Software | Where-Object {($_.Publisher -notlike "Microsoft*" -and $_.DisplayName -notlike "VMware*" -and $_.DisplayName -notlike "Microsoft*" -and $_.DisplayName -notlike "*Veeam*") -and ($Null -ne $_.Publisher -or $Null -ne $_.DisplayName)})) {
                                try {
                                    $inObj = [ordered] @{
                                        'Name' = $APP.DisplayName
                                        'Publisher' = ConvertTo-EmptyToFiller $APP.Publisher
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            $TableParams = @{
                                Name = "Non-essential software programs - $($BackupServer.Name.ToString().ToUpper().Split(".")[0])"
                                List = $false
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        }
                        if ($Unused) {
                            Section -Style Heading4 'Remove Unused Components' {
                                Paragraph "Remove all non-essential software programs and utilities from the deployed Veeam components. While these programs may offer useful features to the administrator, if they provide 'back-door' access to the system, they must be removed during the hardening process. Think about additional software like web browsers, java, adobe reader and such. All parts which do not belong to the operating system or to active Veeam components, remove it. It will make maintaining an up-to-date patch level much easier."
                                BlankLine
                                $Unused
                                Paragraph 'Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#remove-unused-components' -Bold
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }

                    try {
                        $Console = if ( $Software ) {
                            $OutObj = @()
                            foreach ($APP in ($Software | Where-Object {($_.DisplayName -like "Veeam Explorer*" -or $_.DisplayName -like "Veeam Backup & Replication Console") -and ($Null -ne $_.Publisher -or $Null -ne $_.DisplayName)})) {
                                try {
                                    $inObj = [ordered] @{
                                        'Name' = $APP.DisplayName
                                        'Publisher' = ConvertTo-EmptyToFiller $APP.Publisher
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            $TableParams = @{
                                Name = "Backup & Replication Console - $($BackupServer.Name.ToString().ToUpper().Split(".")[0])"
                                List = $false
                                ColumnWidths = 50, 50
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                        }
                        if ($Console) {
                            Section -Style Heading4 'Remove Backup & Replication Console' {
                                Paragraph "Remove the Veeam Backup & Replication Console from the Veeam Backup & Replication server. The console is installed locally on the backup server by default."
                                BlankLine
                                $Console
                                Paragraph 'Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#how-to-remove-the-veeam-backup--replication-console' -Bold
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                    try {
                        $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                        $Available = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service "W32Time" | Select-Object DisplayName, Name, Status}
                        $Services = Invoke-Command -Session $PssSession -ScriptBlock {Get-Service VeeamNFSSvc}
                        Remove-PSSession -Session $PssSession
                        $vPowerNFS = if ( $Services ) {
                            $OutObj = @()
                            foreach ($Service in $Services) {
                                try {
                                    $inObj = [ordered] @{
                                        'Display Name' = $Service.DisplayName
                                        'Short Name' = $Service.Name
                                        'Status' = $Service.Status
                                    }
                                    $OutObj += [pscustomobject]$inobj
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning $_.Exception.Message
                                }
                            }
                            $TableParams = @{
                                Name = "vPower NFS Services Status - $($BackupServer.Name.ToString().ToUpper().Split(".")[0])"
                                List = $false
                                ColumnWidths = 34, 33, 33
                            }
                            if ($Report.ShowTableCaptions) {
                                $TableParams['Caption'] = "- $($TableParams.Name)"
                            }
                            $OutObj | Sort-Object -Property 'Display Name' | Table @TableParams
                        }
                        if ($vPowerNFS) {
                            Section -Style Heading4 'Switch off the vPower NFS Service' {
                                Paragraph "Stop the Veeam vPower NFS Service if you do not plan on using the following Veeam features: SureBackup, Instant Recovery, or Other-OS File Level Recovery (FLR) operations."
                                BlankLine
                                $vPowerNFS
                                Paragraph 'Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#remove-unused-components' -Bold
                            }
                        }
                    }
                    catch {
                        Write-PscriboMessage -IsWarning $_.Exception.Message
                    }
                }
            }
            try {
                $OutObj = @()
                Write-PscriboMessage "Collecting Enterprise Manager information from $($BackupServer.Name)."
                $EMInfo = [Veeam.Backup.Core.SBackupOptions]::GetEnterpriseServerInfo()
                $EMObj = if ($EMInfo) {
                    Section -Style Heading4 "Enterprise Manager Server ($($EMInfo.ServerName.ToString().ToUpper().Split(".")[0]))" {
                        $inObj = [ordered] @{
                            'Server Name' = Switch ($EMInfo.ServerName) {
                                $Null {'Not Connected'}
                                default {$EMInfo.ServerName}
                            }
                            'Server URL' = Switch ($EMInfo.URL) {
                                $Null {'Not Connected'}
                                default {$EMInfo.URL}
                            }
                            'Skip License Push' = ConvertTo-TextYN $EMInfo.SkipLicensePush
                            'Is Connected' = ConvertTo-TextYN $EMInfo.IsConnected
                        }

                        $OutObj = [pscustomobject]$inobj

                        $TableParams = @{
                            Name = "Enterprise Manager - $($BackupServer.Name.Split(".")[0])"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                    }
                }
                if ($EMObj) {
                    Section -Style Heading3 'Enterprise Manager' {
                        Paragraph "When Enterprise Manager is not in use de-install it and remove it from your environment."
                        $EMObj
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
            Section -Style Heading3 'Console Access' {
                Paragraph "The Veeam Backup & Replication console is a client-side component that provides access to the backup server. The console lets several backup operators and admins log in to Veeam Backup & Replication simultaneous and perform all kind of data protection and disaster recovery operations as if you work on the backup server.

                Install the Veeam Backup & Replication console on a central management server that is, positioned in a DMZ and protected with 2-factor authentication. Do NOT install the console on the local desktops of backup & recovery admins."
            }
            try {
                $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                $secEditPath = Invoke-Command -Session $PssSession -ScriptBlock {[System.Environment]::ExpandEnvironmentVariables("%SystemRoot%\system32\secedit.exe")}
                $tempFile = Invoke-Command -Session $PssSession -ScriptBlock {[System.IO.Path]::GetTempFileName()}

                $exportArguments = '/export /cfg "{0}" /quiet' -f $tempFile
                $importArguments = '/configure /db secedit.sdb /cfg "{0}" /quiet' -f $tempFile

                Invoke-Command -Session $PssSession -ScriptBlock {Start-Process -FilePath $using:secEditPath -ArgumentList $using:exportArguments -Wait}

                $policyConfig = Invoke-Command -Session $PssSession -ScriptBlock {Get-Content -Path $using:tempFile}

                Remove-PSSession -Session $PssSession

                $Regex = [Regex]::new("(?<=System Access)(.*)(?=Event Audit)")

                $Match = $Regex.Match($policyConfig)

                $policyConfigs = [RegEx]::Matches($Match.Value.Split(']['),"\w+ = \w+").value

                $policyConfigHash = @{}

                foreach ($policyConfig in $policyConfigs) {
                    $policyConfigSplitted = $policyConfig.split()
                    $policyConfigHash[$policyConfigSplitted[0]] = $policyConfigSplitted[2]
                }
                $PasswordPolicyConfiObj = if ($policyConfigHash) {
                    Section -Style Heading4 "Password Management Policy" {
                        Paragraph "Use a clever Password management policy, which works for your organization. Enforcing the use of strong passwords across your infrastructure is a valuable control. It's more challenging for attackers to guess passwords/crack hashes to gain unauthorized access to critical systems.

                        Selecting passwords of 10 characters with a mixture of upper and lowercase letters, numbers and special characters is a good start for user accounts.

                        For Admin accounts adding 2-factor authentication is also a must to secure the infrastructure.

                        And for service accounts use 25+ characters combined with a password tool for easier management. An Admin can copy and paste the password when needed, increasing security of the service accounts."
                        BlankLine
                        $OutObj = @()
                        $inObj = [ordered] @{
                            'Password Must Meet Complexity Requirements' = Switch ($policyConfigHash.PasswordComplexity) {
                                1 {'Yes'}
                                0 {'No'}
                                default {'Unknown'}
                            }
                            'Max Password Age' = $policyConfigHash.MaximumPasswordAge
                            'Min Password Age' = $policyConfigHash.MinimumPasswordAge
                            'Min Password Length' = $policyConfigHash.MinimumPasswordLength
                            'Enforce Password History' = $policyConfigHash.PasswordHistorySize
                            'Store Password using Reversible Encryption' = Switch ($policyConfigHash.ClearTextPassword) {
                                1 {'Yes'}
                                0 {'No'}
                                default {'Unknown'}
                            }
                        }

                        $OutObj = [pscustomobject]$inobj

                        $TableParams = @{
                            Name = "Password Management Policy - $($BackupServer.Name.Split(".")[0])"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        Paragraph 'Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#password-management-policy' -Bold
                    }
                }
                $LockpolicyConfiObj = if ($policyConfigHash) {
                    Section -Style Heading4 "Lockout Policy" {
                        Paragraph "Use a Lockout policy that complements a clever password management policy. Accounts will be locked after a small number of incorrect attempts. This can stop password guessing attacks dead in the water. But be careful that this can also lock everyone out of the backup & replication system for a period! For service accounts, sometimes it is better just to raise alarms fast. Instead of locking the accounts. This way you gain visibility into suspicious behavior towards your data/infrastructure."
                        BlankLine
                        $OutObj = @()
                        $inObj = [ordered] @{
                            'Account Lockout Thresholds' = $policyConfigHash.LockoutBadCount
                            'Account Lockout Duration Age' = $policyConfigHash.LockoutDuration
                            'Reset account lockout counter after' = $policyConfigHash.ResetLockoutCount
                        }

                        $OutObj = [pscustomobject]$inobj

                        $TableParams = @{
                            Name = "Lockout Policy - $($BackupServer.Name.Split(".")[0])"
                            List = $true
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        Paragraph 'Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#lockout-policy' -Bold
                    }
                }
                if ($PasswordPolicyConfiObj -or $LockpolicyConfiObj) {
                    Section -Style Heading3 'Roles and Users' {
                        Paragraph "Deploy an Access Control policy, managing access to management components is crucial for a good protection. Use the principle of least privilege. Provide the minimal privilege needed for some operation to occur. An attacker who gained high-privilege access to backup infrastructure servers can get credentials of user accounts and compromise other systems in your environment. Make sure that all accounts have a specific role and that they are added to that specific group.

                        Containment to keep the attackers from moving around too easily. Some standard measures and policies are:

                        *  Do not use user accounts for admin access, reducing incidents and accidents.
                        *  Give every Veeam admin his own admin account or add their admin account to the appropriate security group within Veeam, for traceability and easy adding and removal.
                        *  Only give out access to what is needed for the job.
                        *  Limit users who can log in using Remote Desktop and/or Veeam Backup Console.
                        *  Add 2-factor authentication to highly valuable assets.
                        *  Monitor your accounts for suspicious activity.

                        A role assigned to the user defines the user activity scope: what operations in Veeam Backup & Replication the user can perform."
                        BlankLine
                        try {
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
                            Paragraph 'Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#roles-and-users' -Bold
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }

                        $PasswordPolicyConfiObj
                        $LockpolicyConfiObj
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
            try {
                $VCInventObjs = Get-VBRServer | Where-Object {$_.Type -eq 'VC'}
                $vSphereCredObj = if ($VCInventObjs) {
                    Section -Style Heading4 "VMware vSphere Credentials" {
                        Paragraph 'If VMware vCenter Server is added to the backup infrastructure, an account with reduced permissions can be used. Use the minimum permissions for your use-case. See Required Permissions document:

                        *  https://helpcenter.veeam.com/docs/backup/permissions/installation.html?ver=110

                        For example Hot-Add backup requires the delte disk permission. You can also consider elevating permissions for restores.'
                        try {
                            Section -Style Heading5 'vCenter Server' {
                                $OutObj = @()
                                foreach ($InventObj in $VCInventObjs) {
                                    try {
                                        $inObj = [ordered] @{
                                            'Name' = $InventObj.Name
                                            'Credential' = ($InventObj).GetSoapCreds().User
                                        }

                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "vCenter Servers - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 40, 60
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
                        $ESXiInventObjs = Get-VBRServer | Where-Object {$_.Type -eq 'Esxi' -and $_.IsStandaloneEsx() -eq 'True'}
                        if ($ESXiInventObjs) {
                            try {
                                Section -Style Heading5 'Standalone ESXi Server' {
                                    $OutObj = @()
                                    foreach ($InventObj in $ESXiInventObjs) {
                                        try {
                                            $inObj = [ordered] @{
                                                'Name' = $InventObj.Name
                                                'Credential' = ($InventObj).GetSoapCreds().User
                                            }

                                            $OutObj += [pscustomobject]$inobj
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "ESXi Servers - $VeeamBackupServer"
                                        List = $false
                                        ColumnWidths = 40, 60
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
                    }
                }
                if ($vSphereCredObj -or $EsxiCredObj) {
                    Section -Style Heading3 'Required Permissions' {
                        Paragraph "Use the principle of least privilege. Provide the minimal required permissions needed for the accounts to run. The accounts used for installing and using Veeam Backup & Replication must have the following permissions:

                        *  https://helpcenter.veeam.com/docs/backup/vsphere/required_permissions.html?ver=110

                        Backup proxies must be considered the target for compromise. During backup, proxies obtain from the backup server credentials required to access virtual infrastructure servers. A person having administrator privileges on a backup proxy can intercept the credentials and use them to access the virtual infrastructure."
                        $vSphereCredObj
                        Paragraph "Reference: https://helpcenter.veeam.com/docs/backup/permissions/installation.html?ver=110" -Bold
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
            try {
                $PssSession = New-PSSession $BackupServer.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                $Updates = Invoke-Command -Session $PssSession -ScriptBlock {(New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsHidden=0 and IsInstalled=0").Updates | Select-Object Title,KBArticleIDs}
                Remove-PSSession -Session $PssSession
                $UpdatesObj = if ($Updates) {
                    Section -Style Heading4 "Ensure timely guest OS updates on backup infrastructure servers" {
                        Paragraph 'Install the latest updates and patches on backup infrastructure servers to minimize the risk of exploiting guest OS vulnerabilities by attackers.'
                        try {
                            Section -Style Heading5 "Backup & Replication Server ($($BackupServer.Name.ToString().ToUpper().Split(".")[0]))" {
                                try {
                                    $Software = @()
                                    $OutObj = @()

                                    foreach ($Update in $Updates) {
                                        try {
                                            $inObj = [ordered] @{
                                                'KB Article' = "KB$($Update.KBArticleIDs)"
                                                'Name' = $Update.Title
                                            }
                                            $OutObj += [pscustomobject]$inobj
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                        }
                                    }

                                    $TableParams = @{
                                        Name = "Missing Windows Updates - $($BackupServer.Name.ToString().ToUpper().Split(".")[0])"
                                        List = $false
                                        ColumnWidths = 40, 60
                                    }
                                    if ($Report.ShowTableCaptions) {
                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                    }
                                    $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                }
                                catch {
                                    Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Backup & Replication Server - Installed Software Update Table)"
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                        try {
                            $ViBackupProxies = Get-VBRViProxy | Where-Object {$_.Host.Type -eq "Windows"}
                            $HvBackupProxies = Get-VBRHvProxy | Where-Object {$_.Host.Type -eq "Windows"}
                            $BackupProxies = @()
                            $BackupProxies += $ViBackupProxies
                            $BackupProxies += $HvBackupProxies
                            if ($BackupProxies) {
                                Section -Style Heading5 "Backup Proxy Servers" {
                                    foreach ($BackupProxy in $BackupProxies) {
                                        if (($BackupProxie.Host.id.Guid -notin $BackupServer.id.Guid)) {
                                            try {
                                                $PssSession = New-PSSession $BackupProxy.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                                                $Updates = Invoke-Command -Session $PssSession -ScriptBlock {(New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsHidden=0 and IsInstalled=0").Updates | Select-Object Title,KBArticleIDs}
                                                Remove-PSSession -Session $PssSession
                                                if ($Updates) {
                                                    $Software = @()
                                                    $OutObj = @()
                                                    foreach ($Update in $Updates) {
                                                        try {
                                                            $inObj = [ordered] @{
                                                                'KB Article' = "KB$($Update.KBArticleIDs)"
                                                                'Name' = $Update.Title
                                                            }
                                                            $OutObj += [pscustomobject]$inobj
                                                        }
                                                        catch {
                                                            Write-PscriboMessage -IsWarning $_.Exception.Message
                                                        }
                                                    }

                                                    $TableParams = @{
                                                        Name = "Missing Windows Updates - $($BackupProxy.Name.ToString().ToUpper().Split(".")[0])"
                                                        List = $false
                                                        ColumnWidths = 40, 60
                                                    }
                                                    if ($Report.ShowTableCaptions) {
                                                        $TableParams['Caption'] = "- $($TableParams.Name)"
                                                    }
                                                    if ($OutObj) {
                                                        Section -Style Heading6 "$($BackupProxy.Name.ToString().ToUpper().Split(".")[0])" {
                                                            $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                        }

                                                    }
                                                }
                                            }
                                            catch {
                                                Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Backup Proxy Servers- Installed Software Update Table)"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                        try {
                            $BackupRepos = Get-VBRBackupRepository | Where-Object {$_.Type -eq "WinLocal"}
                            if ($BackupRepos) {
                                $BRObj = foreach ($BackupRepo in $BackupRepos) {
                                    if ((($BackupRepo.id.Guid -notin $BackupServer.id.Guid) -and ($BackupRepo.id.Guid -notin $BackupProxies.id.Guid))) {
                                        try {
                                            $PssSession = New-PSSession $BackupRepo.Host.Name -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                                            $Updates = Invoke-Command -Session $PssSession -ScriptBlock {(New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsHidden=0 and IsInstalled=0").Updates | Select-Object Title,KBArticleIDs}
                                            Remove-PSSession -Session $PssSession
                                            if ($Updates) {
                                                $Software = @()
                                                $OutObj = @()
                                                foreach ($Update in $Updates) {
                                                    try {
                                                        $inObj = [ordered] @{
                                                            'KB Article' = SWitch ($Update.KBArticleIDs -match '^\d+$') {
                                                                $false {'Unknown'}
                                                                default {"KB$($Update.KBArticleIDs)"}
                                                            }
                                                            'Name' = $Update.Title
                                                        }
                                                        $OutObj += [pscustomobject]$inobj
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                }

                                                $TableParams = @{
                                                    Name = "Missing Windows Updates - $($BackupRepo.Host.Name.ToString().ToUpper().Split(".")[0])"
                                                    List = $false
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                if ($OutObj) {
                                                    Section -Style Heading6 "$($BackupRepo.Host.Name.ToString().ToUpper().Split(".")[0])" {
                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                    }

                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Installed Software Update Table)"
                                        }
                                    }
                                }
                                if ($BRObj) {
                                    Section -Style Heading5 "Backup Repository Servers" {
                                        $BRObj
                                    }

                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                        try {
                            $WANAccels = Get-VBRWANAccelerator
                            if ($WANAccels) {
                                $WANObj = foreach ($WANAccel in $WANAccels) {
                                    if (($WANAccel.HostId.Guid -notin $BackupServer.id.Guid) -and ($WANAccel.HostId.Guid -notin $BackupRepos.Host.id.Guid) -and ($WANAccel.HostId.Guid -notin $BackupProxies.Host.id.Guid)) {
                                        try {
                                            $PssSession = New-PSSession ($Servers | Where-Object {$_.id -eq ($WANAccel).HostId.Guid}).Info.DnsName -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                                            $Updates = Invoke-Command -Session $PssSession -ScriptBlock {(New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsHidden=0 and IsInstalled=0").Updates | Select-Object Title,KBArticleIDs}
                                            Remove-PSSession -Session $PssSession
                                            if ($Updates) {
                                                $Software = @()
                                                $OutObj = @()
                                                foreach ($Update in $Updates) {
                                                    try {
                                                        $inObj = [ordered] @{
                                                            'KB Article' = SWitch ($Update.KBArticleIDs -match '^\d+$') {
                                                                $false {'Unknown'}
                                                                default {"KB$($Update.KBArticleIDs)"}
                                                            }
                                                            'Name' = $Update.Title
                                                        }
                                                        $OutObj += [pscustomobject]$inobj
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                }

                                                $TableParams = @{
                                                    Name = "Missing Windows Updates - $($WANAccel.Name.ToString().ToUpper().Split(".")[0])"
                                                    List = $false
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                if ($OutObj) {
                                                    Section -Style Heading6 "$($WANAccel.Name.ToString().ToUpper().Split(".")[0])" {
                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                    }

                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (WAN Accelerators Servers- Installed Software Update Table)"
                                        }
                                    }
                                }
                                if ($WANObj) {
                                    Section -Style Heading5 "WAN Accelerators Servers" {
                                        $WANObj
                                    }

                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                        try {
                            $TapeServers = Get-VBRTapeServer
                            if ($TapeServers) {
                                $TapeObj = foreach ($TapeServer in $TapeServers) {
                                    if (($TapeServer.ServerId.Guid -notin $BackupServer.id.Guid) -and ($TapeServer.ServerId.Guid -notin $BackupRepos.Host.id.Guid) -and ($TapeServer.ServerId.Guid -notin $BackupProxies.Host.id.Guid) -and ($TapeServer.ServerId.Guid -notin $WANAccels.HostId.Guid)) {
                                        try {
                                            $PssSession = New-PSSession ($Servers | Where-Object {$_.id -eq ($TapeServer).ServerId.Guid}).Info.DnsName -Credential $Credential -Authentication $Options.PSDefaultAuthentication
                                            $Updates = Invoke-Command -Session $PssSession -ScriptBlock {(New-Object -ComObject Microsoft.Update.Session).CreateupdateSearcher().Search("IsHidden=0 and IsInstalled=0").Updates | Select-Object Title,KBArticleIDs}
                                            Remove-PSSession -Session $PssSession
                                            if ($Updates) {
                                                $Software = @()
                                                $OutObj = @()
                                                foreach ($Update in $Updates) {
                                                    try {
                                                        $inObj = [ordered] @{
                                                            'KB Article' = SWitch ($Update.KBArticleIDs -match '^\d+$') {
                                                                $false {'Unknown'}
                                                                default {"KB$($Update.KBArticleIDs)"}
                                                            }
                                                            'Name' = $Update.Title
                                                        }
                                                        $OutObj += [pscustomobject]$inobj
                                                    }
                                                    catch {
                                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                                    }
                                                }

                                                $TableParams = @{
                                                    Name = "Missing Windows Updates - $($TapeServer.Name.ToString().ToUpper().Split(".")[0])"
                                                    List = $false
                                                    ColumnWidths = 40, 60
                                                }
                                                if ($Report.ShowTableCaptions) {
                                                    $TableParams['Caption'] = "- $($TableParams.Name)"
                                                }
                                                if ($OutObj) {
                                                    Section -Style Heading6 "$($TapeServer.Name.ToString().ToUpper().Split(".")[0])" {
                                                        $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                                                    }

                                                }
                                            }
                                        }
                                        catch {
                                            Write-PscriboMessage -IsWarning "$($_.Exception.Message) (Tape Servers- Installed Software Update Table)"
                                        }
                                    }
                                }
                                if ($TapeObj) {
                                    Section -Style Heading5 "Tape Servers" {
                                        $TapeObj
                                    }

                                }
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning $_.Exception.Message
                        }
                    }
                }
                if ($UpdatesObj) {
                    Section -Style Heading3 'Patching and Updates' {
                        Paragraph "Patch operating systems, software, and firmware on Veeam components. Most hacks succeed because there is already vulnerable software in use which is not up-to-date with current patch levels. So make sure all software and hardware where Veeam components are running are up-to-date. One of the most possible causes of a credential theft are missing guest OS updates and use of outdated authentication protocols."
                        Paragraph 'Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#patching-and-updates' -Bold
                        $UpdatesObj
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
            try {
                $Bkjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.TypetoString -notlike '*Agent*' -and $_.TypetoString -notlike '*File*'}
                $ABkjobs = Get-VBRComputerBackupJob | Sort-Object -Property Name
                $FSjobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object {$_.TypeToString -like 'File Backup'} | Sort-Object -Property Name
                $BKJobsObj = if ($BKJobs) {
                    Section -Style Heading4 "Backup Jobs Encryption Status" {
                        Paragraph 'Data security is an important part of the backup strategy. You must protect your information from unauthorized access, especially if you back up sensitive VM data to off-site locations or archive it to tape. To keep your data safe, you can use data encryption.'
                        try {
                            Section -Style Heading5 'Backup Jobs' {
                                $OutObj = @()
                                foreach ($BKJob in $BKJobs) {
                                    try {
                                        $inObj = [ordered] @{
                                            'Name' = $BKJob.Name
                                            'Storage Encryption' = ConvertTo-TextYN $Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                            'Encryption Key' = Switch ($Bkjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                $false {'None'}
                                                default {(Get-VBREncryptionKey | Where-Object { $_.id -eq $Bkjob.Info.PwdKeyId }).Description}
                                            }
                                        }

                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "Backup Jobs - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 34, 33, 33
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
                        try {
                            Section -Style Heading5 'Agent Backup Jobs' {
                                $OutObj = @()
                                foreach ($ABkjob in $ABkjobs) {
                                    try {
                                        $inObj = [ordered] @{
                                            'Name' = $ABkjob.Name
                                            'Enabled Backup File Encryption' = ConvertTo-TextYN $ABkjob.StorageOptions.EncryptionEnabled
                                            'Encryption Key' = Switch ($ABkjob.StorageOptions.EncryptionEnabled) {
                                                $false {'None'}
                                                default {(Get-VBREncryptionKey | Where-Object { $_.id -eq $ABkjob.StorageOptions.EncryptionKey.Id }).Description}
                                            }
                                        }

                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "Agent Backup Jobs - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 34, 33, 33
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
                        try {
                            Section -Style Heading5 'File Share Backup Jobs' {
                                $OutObj = @()
                                foreach ($FSjob in $FSjobs) {
                                    try {
                                        $inObj = [ordered] @{
                                            'Name' = $FSjob.Name
                                            'Enabled Backup File Encryption' = ConvertTo-TextYN $FSjob.Options.BackupStorageOptions.StorageEncryptionEnabled
                                            'Encryption Key' = Switch ($FSjob.Options.BackupStorageOptions.StorageEncryptionEnabled) {
                                                $false {'None'}
                                                default {(Get-VBREncryptionKey | Where-Object { $_.id -eq $FSjob.Info.PwdKeyId }).Description}
                                            }
                                        }

                                        $OutObj += [pscustomobject]$inobj
                                    }
                                    catch {
                                        Write-PscriboMessage -IsWarning $_.Exception.Message
                                    }
                                }

                                $TableParams = @{
                                    Name = "File Share Backup Jobs - $VeeamBackupServer"
                                    List = $false
                                    ColumnWidths = 34, 33, 33
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
                }
                if ($BKJobsObj) {
                    Section -Style Heading3 'Encryption' {
                        Paragraph "Backup and replica data is a highly potential source of vulnerability. To secure data stored in backups and replicas, follow these guidelines:

                        * Ensure physical security of target servers. Check that only authorized personnel have access to the room where your target servers (backup repositories and hosts) reside.

                        * Restrict user access to backups and replicas. Check that only authorized users have permissions to access backups and replicas on target servers.

                        * Encrypt data in backups. Use Veeam Backup & Replication inbuilt encryption to protect data in backups. To guarantee security of data in backups, follow Encryption Best Practices."
                        BlankLine
                        Paragraph "Reference: https://bp.veeam.com/vbr/Security/infrastructure_hardening.html#encryption" -Bold
                        $BKJobsObj
                    }
                }
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}
