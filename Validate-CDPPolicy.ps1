<#
.SYNOPSIS
    Validates CDP Policy properties used by Get-AbrVbrCDPPolicy and Get-AbrVbrCDPPolicyConf.
.DESCRIPTION
    Run this on a Windows machine with Veeam B&R installed to verify that
    all properties/methods relied on by the CDP report section are accessible.
.NOTES
    Requires: Windows PowerShell 5.1, Veeam Backup & Replication (Enterprise Plus)
#>


# --- Connect ---
try {
    Connect-VBRServer -Server 'veeam-vbr-00a.pharmax.local' -User 'veeamadmin' -Password 'P@ssw0rd@26@26@@' -ErrorAction Stop
    Write-Host "[OK] Connected to VBR server" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Cannot connect: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# --- Cmdlet availability ---
if (-not (Get-Command 'Get-VBRCDPPolicy' -ErrorAction SilentlyContinue)) {
    Write-Host "[FAIL] Get-VBRCDPPolicy cmdlet not found (Enterprise Plus required)" -ForegroundColor Red
    Disconnect-VBRServer -ErrorAction SilentlyContinue
    exit 1
}
Write-Host "[OK] Get-VBRCDPPolicy cmdlet is available" -ForegroundColor Green

# --- Retrieve policies ---
$CDPPolicies = Get-VBRCDPPolicy -ErrorAction SilentlyContinue | Sort-Object Name
if (-not $CDPPolicies) {
    Write-Host "[WARN] No CDP policies found — create at least one policy before running this validation" -ForegroundColor Yellow
    Disconnect-VBRServer -ErrorAction SilentlyContinue
    exit 0
}
Write-Host "[OK] Found $($CDPPolicies.Count) CDP policy(ies)" -ForegroundColor Green

foreach ($Policy in $CDPPolicies) {
    Write-Host "`n=== Policy: $($Policy.Name) ===" -ForegroundColor Cyan

    # --- PolicyState (replaces IsEnabled) ---
    Write-Host "`n  -- PolicyState --" -ForegroundColor Cyan
    if ($Policy.PSObject.Properties['PolicyState']) {
        $ps = $Policy.PolicyState
        Write-Host "  [OK] .PolicyState = $ps  (type: $($ps.GetType().Name))" -ForegroundColor Green
        Write-Host "       Enum values available: $([Enum]::GetNames($ps.GetType()) -join ', ')"
    } else {
        Write-Host "  [FAIL] .PolicyState not found" -ForegroundColor Red
    }

    # --- LastState ---
    if ($Policy.PSObject.Properties['LastState']) {
        $ls = $Policy.LastState
        Write-Host "  [OK] .LastState = $ls  (type: $($ls.GetType().Name))" -ForegroundColor Green
        Write-Host "       Enum values: $([Enum]::GetNames($ls.GetType()) -join ', ')"
    }

    # --- LastResult ---
    Write-Host "  [OK] .LastResult = $($Policy.LastResult)  (type: $($Policy.LastResult.GetType().Name))" -ForegroundColor Green

    # --- NextRun / Description / Id ---
    Write-Host "  [OK] .NextRun = $($Policy.NextRun)" -ForegroundColor Green
    Write-Host "  [OK] .Description = $($Policy.Description)" -ForegroundColor Green
    Write-Host "  [OK] .Id = $($Policy.Id)" -ForegroundColor Green

    # --- Source VMs via EntityId ---
    Write-Host "`n  -- Source VMs --" -ForegroundColor Cyan
    if ($Policy.PSObject.Properties['EntityId'] -and $Policy.EntityId) {
        Write-Host "  [OK] .EntityId count: $($Policy.EntityId.Count)" -ForegroundColor Green
        Write-Host "       First EntityId: $($Policy.EntityId[0])"
        try {
            $vm = Find-VBRViEntity -Name '*' -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $Policy.EntityId[0] } | Select-Object -First 1
            if ($vm) {
                Write-Host "  [OK] Resolved via Find-VBRViEntity: $($vm.Name)" -ForegroundColor Green
                Write-Host "       VM properties: $($vm.PSObject.Properties.Name -join ', ')"
            } else {
                Write-Host "  [WARN] Could not resolve EntityId via Find-VBRViEntity" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  [WARN] Find-VBRViEntity error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # --- RetentionOptions ---
    Write-Host "`n  -- RetentionOptions --" -ForegroundColor Cyan
    if ($Policy.PSObject.Properties['RetentionOptions'] -and $Policy.RetentionOptions) {
        $ro = $Policy.RetentionOptions
        Write-Host "  [OK] .RetentionOptions type: $($ro.GetType().FullName)" -ForegroundColor Green
        $ro.PSObject.Properties | ForEach-Object {
            $val = $_.Value
            $typeName = if ($null -ne $val) { $val.GetType().Name } else { 'null' }
            Write-Host "    .$($_.Name) = $val  (type: $typeName)"
        }
    } else {
        Write-Host "  [WARN] .RetentionOptions is null/missing" -ForegroundColor Yellow
    }

    # --- NetworkMappingEnabled ---
    Write-Host "`n  -- Network Mapping --" -ForegroundColor Cyan
    Write-Host "  .NetworkMappingEnabled = $($Policy.NetworkMappingEnabled)  (type: $($Policy.NetworkMappingEnabled.GetType().Name))"

    # --- SourceNetwork ---
    Write-Host "`n  -- SourceNetwork --" -ForegroundColor Cyan
    if ($Policy.PSObject.Properties['SourceNetwork'] -and $Policy.SourceNetwork) {
        Write-Host "  [OK] .SourceNetwork count: $($Policy.SourceNetwork.Count)" -ForegroundColor Green
        $Policy.SourceNetwork | ForEach-Object {
            Write-Host "  Type: $($_.GetType().FullName)"
            $_.PSObject.Properties | ForEach-Object {
                $val = $_.Value
                $typeName = if ($null -ne $val) { $val.GetType().Name } else { 'null' }
                Write-Host "    .$($_.Name) = $val  (type: $typeName)"
            }
        }
    } else {
        Write-Host "  [INFO] .SourceNetwork is empty (no network mapping configured)" -ForegroundColor Yellow
    }

    # --- TargetNetwork ---
    Write-Host "`n  -- TargetNetwork --" -ForegroundColor Cyan
    if ($Policy.PSObject.Properties['TargetNetwork'] -and $Policy.TargetNetwork) {
        Write-Host "  [OK] .TargetNetwork count: $($Policy.TargetNetwork.Count)" -ForegroundColor Green
        $Policy.TargetNetwork | ForEach-Object {
            Write-Host "  Type: $($_.GetType().FullName)"
            $_.PSObject.Properties | ForEach-Object {
                $val = $_.Value
                $typeName = if ($null -ne $val) { $val.GetType().Name } else { 'null' }
                Write-Host "    .$($_.Name) = $val  (type: $typeName)"
            }
        }
    } else {
        Write-Host "  [INFO] .TargetNetwork is empty (no network mapping configured)" -ForegroundColor Yellow
    }

    # --- ReIPRule ---
    Write-Host "`n  -- ReIPRule --" -ForegroundColor Cyan
    if ($Policy.PSObject.Properties['ReIPRule'] -and $Policy.ReIPRule) {
        Write-Host "  [OK] .ReIPRule count: $($Policy.ReIPRule.Count)" -ForegroundColor Green
        $Policy.ReIPRule | ForEach-Object {
            Write-Host "  Type: $($_.GetType().FullName)"
            $_.PSObject.Properties | ForEach-Object {
                $val = $_.Value
                $typeName = if ($null -ne $val) { $val.GetType().Name } else { 'null' }
                Write-Host "    .$($_.Name) = $val  (type: $typeName)"
            }
        }
    } else {
        Write-Host "  [INFO] .ReIPRule is empty (no re-IP rules configured)" -ForegroundColor Yellow
    }

    # --- GuestProcessingOptions ---
    Write-Host "`n  -- GuestProcessingOptions --" -ForegroundColor Cyan
    if ($Policy.PSObject.Properties['GuestProcessingOptions'] -and $Policy.GuestProcessingOptions) {
        $gpo = $Policy.GuestProcessingOptions
        Write-Host "  [OK] .GuestProcessingOptions type: $($gpo.GetType().FullName)" -ForegroundColor Green
        $gpo.PSObject.Properties | ForEach-Object {
            $val = $_.Value
            $typeName = if ($null -ne $val) { $val.GetType().Name } else { 'null' }
            Write-Host "    .$($_.Name) = $val  (type: $typeName)"
        }
    } else {
        Write-Host "  [INFO] .GuestProcessingOptions is null/missing" -ForegroundColor Yellow
    }

    # --- ApplicationProcessingEnabled ---
    Write-Host "`n  -- ApplicationProcessingEnabled --" -ForegroundColor Cyan
    Write-Host "  .ApplicationProcessingEnabled = $($Policy.ApplicationProcessingEnabled)"

    # --- Proxy info ---
    Write-Host "`n  -- Proxy & General --" -ForegroundColor Cyan
    Write-Host "  .SourceProxyId  : $($Policy.SourceProxyId -join ', ')"
    Write-Host "  .TargetProxyId  : $($Policy.TargetProxyId -join ', ')"
    Write-Host "  .Suffix         : $($Policy.Suffix)"
    Write-Host "  .PolicyType     : $($Policy.PolicyType)"
    Write-Host "  .CompressionLevel: $($Policy.CompressionLevel)"
}

Write-Host "`n[DONE] Validation complete" -ForegroundColor Cyan
Disconnect-VBRServer -ErrorAction SilentlyContinue
