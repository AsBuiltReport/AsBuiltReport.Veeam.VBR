function Get-AbrVbrEventForwarding {
    <#
    .SYNOPSIS
    Used by As Built Report to returns Event Forwarding settings configured on Veeam Backup & Replication..
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.3
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
        Write-PScriboMessage "Discovering Veeam VBR Event Forwarding settings information from $System."
    }

    process {
        try {
            $SNMPSettings = (Get-VBRSNMPOptions).Receiver
            $SyslogSettings = try { Get-VBRSyslogServer } catch { Write-PScriboMessage "No syslog server configured" }
            Section -Style Heading4 'Event Forwarding' {
                $OutObj = @()

                $inObj = [ordered] @{
                    'SNMP Servers' = Switch ([string]::IsNullOrEmpty($SNMPSettings)) {
                        $true { "--" }
                        $false { $SNMPSettings | ForEach-Object { "Receiver: $($_.ReceiverIP), Port: $($_.ReceiverPort), Community: $($_.CommunityString)" } }
                        default { "Unknown" }
                    }
                    'Syslog Servers' = Switch ([string]::IsNullOrEmpty($SyslogSettings)) {
                        $true { "--" }
                        $false { $SyslogSettings | ForEach-Object { "Receiver: $($_.ServerHost), Port: $($_.Port), Protocol: $($_.Protocol)" } }
                        default { "Unknown" }
                    }
                }
                $OutObj += [pscustomobject]$inobj

                if ($HealthCheck.Infrastructure.Settings) {
                    $OutObj | Where-Object { $_.'Syslog Servers' -eq '--' } | Set-Style -Style Warning -Property 'Syslog Servers'
                }

                $TableParams = @{
                    Name = "Event Forwarding - $VeeamBackupServer"
                    List = $true
                    ColumnWidths = 40, 60
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Table @TableParams
                if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.'Syslog Servers' -eq '--' })) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph {
                        Text "Security Best Practice:" -Bold
                        Text "It is a recommends best practice to configure Event Forwarding to an external SIEM or Log Collector to increase the organization security posture."
                    }
                    BlankLine
                }
            }
        } catch {
            Write-PScriboMessage -IsWarning "Event Forwarding Section: $($_.Exception.Message)"
        }
    }
    end {}

}