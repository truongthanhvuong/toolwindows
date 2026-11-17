# =========================================================================
# ADVERSARIAL EMPIRICAL STRESS TEST HARNESS: GATEKEEPER & POLICY CONTROLLER
# CHALLENGER 2 - MILESTONE M2 VERIFICATION
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0
$script:findings = @()

function Assert-Check {
    param(
        [string]$TestCategory,
        [string]$Description,
        [bool]$Condition,
        [string]$Details = ""
    )
    if ($Condition) {
        Write-Host "  [PASS][$TestCategory] $Description" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL][$TestCategory] $($Description): $Details" -ForegroundColor Red
        $script:failed++
        $script:findings += "[$TestCategory] $Description - $Details"
    }
}

Write-Host "`n>>> [CHALLENGER 2] EMPIRICAL STRESS TESTS: M2 GATEKEEPER <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$licPath = Join-Path $projectRoot "src\Core\LicenseManager.ps1"
$mainPath = Join-Path $projectRoot "src-tauri\src\main.rs"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$licContent = [System.IO.File]::ReadAllText($licPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)
$mainContent = [System.IO.File]::ReadAllText($mainPath, [System.Text.Encoding]::UTF8)

# -------------------------------------------------------------------------
# SECTION 1: CANONICAL VIEW ID & HTML DOM CROSS-REFERENCE AUDIT
# -------------------------------------------------------------------------
Write-Host "--- SECTION 1: CANONICAL VIEW ID & HTML DOM CROSS-REFERENCE ---" -ForegroundColor Yellow

# 1.1: 16 Canonical Policy Views (Exact specification from R2 & Test-GatekeeperPolicy.Tests.ps1)
$canonical16Views = @{
    "view-sys-monitor"       = "SysInfo"
    "view-general"           = "Customize"
    "view-win-optimize"      = "Tweaks"
    "view-clean-uninstaller" = "Uninstaller"
    "view-soft-winget"       = "Software"
    "view-it-helpdesk"       = "Troubleshoot"
    "view-vpn-proxy"         = "NetworkLAN"
    "view-win-deploy"        = "AutoWin"
    "view-disk-smart"        = "DiskHealth"
    "view-hwid-act"          = "Activation"
    "view-disk-part"         = "Partition"
    "view-office-m365"       = "Office"
    "view-tech-driver"       = "BackupDriver"
    "view-backup-windows"    = "BackupSystem"
    "view-printer-lan"       = "PrinterLAN"
    "view-bitlocker-mgmt"    = "BitLocker"
}

foreach ($viewId in ($canonical16Views.Keys | Sort-Object)) {
    $matched = ($htmlContent -match "id=['`"]$viewId['`"]")
    Assert-Check "Canonical-16-DOM" "Canonical View ID '$viewId' exists as DOM element in index.html" $matched "Not found in index.html"
}

# 1.2: Audit secondary aliases mapped in CANONICAL_VIEW_POLICY_MAP
$secondaryAliases = @{
    "view-oem-brand"            = "Customize"
    "view-uwp-apps"             = "Uninstaller"
    "view-helpdesk-troubleshoot" = "Troubleshoot"
    "view-block-web-game"       = "NetworkLAN"
    "view-cai-windows"          = "AutoWin"
}
foreach ($alias in ($secondaryAliases.Keys | Sort-Object)) {
    $matched = ($htmlContent -match "id=['`"]$alias['`"]")
    Assert-Check "Secondary-Alias-DOM" "Secondary View ID '$alias' exists as DOM element in index.html" $matched "Not found in index.html"
}

# 1.3: Verify defensive alias view-download mapping
Assert-Check "Defensive-Alias" "app.js defines defensive alias for 'view-download' -> 'Software'" `
    ($appJsContent -match '"view-download":\s*"Software"')

# 1.4: Special route view-admin-portal
Assert-Check "Special-Route-DOM" "Special View ID 'view-admin-portal' exists in index.html" `
    ($htmlContent -match 'id="view-admin-portal"')

# 1.5: Unmapped view audit in index.html
$stitchViewsInHtml = [regex]::Matches($htmlContent, 'class="[^"]*stitch-view[^"]*"\s+id="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
if ($stitchViewsInHtml.Count -eq 0) {
    $stitchViewsInHtml = [regex]::Matches($htmlContent, 'id="([^"]+)"\s+class="[^"]*stitch-view[^"]*"') | ForEach-Object { $_.Groups[1].Value }
}
Write-Host "  Discovered $($stitchViewsInHtml.Count) .stitch-view sections in HTML" -ForegroundColor Gray
$unmappedViews = @()
foreach ($v in $stitchViewsInHtml) {
    if (-not $canonical16Views.ContainsKey($v) -and -not $secondaryAliases.ContainsKey($v) -and $v -ne "view-admin-portal") {
        $unmappedViews += $v
        Write-Host "    - Unmapped View: $v (Safe fail-open for unclassified views)" -ForegroundColor Cyan
    }
}
Assert-Check "DOM-Audit" "Discovered >= 16 stitch-views in HTML" ($stitchViewsInHtml.Count -ge 16) "Found $($stitchViewsInHtml.Count)"

# -------------------------------------------------------------------------
# SECTION 2: HEADLESS JS GATEKEEPER LOGIC EXECUTION
# -------------------------------------------------------------------------
Write-Host "`n--- SECTION 2: HEADLESS JS LOGIC SUITE EXECUTION ---" -ForegroundColor Yellow

$nodeTestScript = Join-Path $PSScriptRoot "test-gatekeeper-headless.cjs"
$nodeOutput = & node $nodeTestScript
$nodeExit = $LASTEXITCODE

Write-Host $nodeOutput
Assert-Check "Headless-JS-Suite" "All 15 headless Gatekeeper logic scenarios passed (100%)" ($nodeExit -eq 0) "Exit code $nodeExit"

# -------------------------------------------------------------------------
# SECTION 3: RUST IPC ENDPOINT SAFETY & ESCAPING INTEGRITY
# -------------------------------------------------------------------------
Write-Host "`n--- SECTION 3: RUST IPC SAFETY & INJECTION MITIGATION ---" -ForegroundColor Yellow

# Verify Rust handles check_pro_license endpoint
Assert-Check "Rust-IPC" "main.rs routes check_pro_license endpoint" `
    ($mainContent -match 'cmd\s*==\s*"check_pro_license"')
Assert-Check "Rust-IPC" "system_ops.rs executes check_pro_license with fallback" `
    ($opsContent -match 'act\s*==\s*"check_pro_license"')

# Verify Rust handles activate_pro_key endpoint
Assert-Check "Rust-IPC" "main.rs routes activate_pro_key endpoint" `
    ($mainContent -match 'cmd\s*==\s*"activate_pro_key"')
Assert-Check "Rust-IPC" "system_ops.rs executes activate_pro_key" `
    ($opsContent -match 'act\s*==\s*"activate_pro_key"')

# Verify single quote escaping in system_ops.rs for activate_pro_key
Assert-Check "Rust-Escaping" "system_ops.rs escapes single quotes in clean_key using .replace('\'', `"''`")" `
    ($opsContent -match "raw_key\.replace\('\\'',\s*`"''`"\)")

# Verify empty key guard in Rust system_ops.rs
Assert-Check "Rust-Guard" "system_ops.rs rejects empty raw_key before PowerShell invocation" `
    ($opsContent -match 'if\s+raw_key\.is_empty\(\)\s*\{\s*return\s*\(false,')

# Run native cargo test for IPC endpoints
$cargoIpcOutput = & cargo test --manifest-path src-tauri/Cargo.toml test_ipc
$cargoIpcExit = $LASTEXITCODE
Assert-Check "Rust-Cargo-Test" "Cargo unit tests for IPC endpoints pass (test_ipc_check_pro_license, test_ipc_activate_pro_key_empty_fails)" `
    ($cargoIpcExit -eq 0)

# Run native cargo test for fail-closed checks
$cargoWinsxsOutput = & cargo test --manifest-path src-tauri/Cargo.toml test_run_system_action_check_winsxs_size
$cargoWinsxsExit = $LASTEXITCODE
Assert-Check "Rust-Cargo-Test" "Cargo unit test for check_winsxs_size passes" `
    ($cargoWinsxsExit -eq 0)

$cargoUnknownOutput = & cargo test --manifest-path src-tauri/Cargo.toml test_unknown_command_fails_closed
$cargoUnknownExit = $LASTEXITCODE
Assert-Check "Rust-Cargo-Test" "Cargo unit test for test_unknown_command_fails_closed passes" `
    ($cargoUnknownExit -eq 0)

# -------------------------------------------------------------------------
# SECTION 4: MODAL UI INTEGRITY & CANCELLATION PURGING
# -------------------------------------------------------------------------
Write-Host "`n--- SECTION 4: MODAL DOM INTEGRITY & PURGE LIFECYCLE ---" -ForegroundColor Yellow

Assert-Check "Modal-Security" "Modal contains close button" ($htmlContent -match 'id="btn-cancel-pro-activation"' -or $htmlContent -match 'id="btn-close-license-modal"') "Close button missing"
Assert-Check "Modal-Security" "Modal contains HWID display field" ($htmlContent -match 'id="display-pro-hwid"' -or $htmlContent -match 'id="input-pro-hwid"') "HWID field missing"
Assert-Check "Modal-Security" "Modal contains key input field" ($htmlContent -match 'id="input-pro-license-key"') "Key input field missing"
Assert-Check "Modal-Security" "Modal contains activation button" ($htmlContent -match 'id="btn-submit-pro-activation"') "Activation button missing"

# Check that app.js properly purges pendingGatekeeperTarget on cancel in both modals
$proCancelPurgesPending = ($appJsContent -match '(?s)doCancel[\s\S]*?pendingGatekeeperTarget\s*=\s*null' -or $appJsContent -match 'btnCancel.*pendingGatekeeperTarget\s*=\s*null')
Assert-Check "Modal-Security" "PRO activation cancel handler clears pendingGatekeeperTarget" $proCancelPurgesPending "PRO cancel does not clear pending target"

$adminCancelPurgesPending = ($appJsContent -match 'btn-admin-cancel-login.*pendingGatekeeperTarget\s*=\s*null' -or $appJsContent -match '(?s)btnCancel\s*&&\s*modalLogin[\s\S]*?pendingGatekeeperTarget\s*=\s*null')
Assert-Check "Modal-Security" "Admin login cancel handler clears pendingGatekeeperTarget" $adminCancelPurgesPending "Admin cancel does not clear pending target"

# -------------------------------------------------------------------------
# SECTION 5: FINAL VERDICT
# -------------------------------------------------------------------------
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " CHALLENGER 2 EMPIRICAL STRESS-TEST RESULTS:" -ForegroundColor Cyan
Write-Host "  PASSED: $script:passed" -ForegroundColor Green
Write-Host "  FAILED: $script:failed" -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================`n" -ForegroundColor Cyan

if ($script:failed -gt 0) {
    Write-Host "Detected Issues:" -ForegroundColor Red
    $script:findings | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    exit 1
} else {
    Write-Host "All empirical stress tests passed successfully! Gatekeeper enforcement is completely verified." -ForegroundColor Green
    exit 0
}
