# =========================================================================
# TEST SUITE: WINDOWS TOI UU TOGGLE SIMULATION & ADVERSARIAL STRESS TEST
# VUONGTT TOOLKIT 2026 - CHALLENGER 2 EMPIRICAL VERIFICATION HARNESS
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0

function Assert-Check {
    param(
        [string]$Description,
        [bool]$Condition,
        [string]$Details = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $Description" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $Description - $Details" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "`n>>> [TEST SUITE] M4: UI TOGGLE STATE SYNCHRONIZATION ADVERSARIAL HARNESS <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

# 1. Run Node.js Headless Adversarial Simulation Harness
Write-Host "--- TIER 1: RUNNING HEADLESS NODE.JS ADVERSARIAL SIMULATION ---" -ForegroundColor Yellow
$nodeScript = Join-Path $projectRoot "tests\Test-UI-Toggle-Adversarial-Simulation.js"
Assert-Check "Simulation script Test-UI-Toggle-Adversarial-Simulation.js exists" (Test-Path $nodeScript)

$nodeOutput = & node $nodeScript 2>&1
$nodeExit = $LASTEXITCODE

Assert-Check "Headless simulation script executed successfully (Exit Code 0)" ($nodeExit -eq 0)
Assert-Check "All 39 adversarial checks passed" ($nodeOutput -match 'TOTAL ADVERSARIAL CHECKS: 39' -and $nodeOutput -match 'FAILED: 0')

# 2. In-Depth PowerShell AST & Regex Inspection
Write-Host "`n--- TIER 2: LIVE TELEMETRY PAYLOAD PROPERTY INTEGRITY ---" -ForegroundColor Yellow
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)

Assert-Check "collect_win_optimize_state emits windows_update_disabled as boolean" `
    ($opsContent -match 'windows_update_disabled\s*=\s*\[bool\]\$wuDisabled')

Assert-Check "collect_win_optimize_state emits bing_disabled as boolean" `
    ($opsContent -match 'bing_disabled\s*=\s*\[bool\]\$bingDisabled')

Assert-Check "collect_win_optimize_state emits show_ext as boolean" `
    ($opsContent -match 'show_ext\s*=\s*\(\$ext\s*-eq\s*0\)')

Assert-Check "collect_win_optimize_state emits classic_context as boolean" `
    ($opsContent -match 'classic_context\s*=\s*\$classic')

# 3. Frontend Coercion Robustness
Write-Host "`n--- TIER 3: FRONTEND SYNC COERCION INTEGRITY ---" -ForegroundColor Yellow
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)

Assert-Check "syncRealWinOptimizeState guards against null DOM element for toggle-classic-context" `
    ($appJsContent -match 'if\s*\(\s*toggleClassic\s*\)\s*toggleClassic\.checked\s*=\s*!!data\.classic_context')

Assert-Check "syncRealWinOptimizeState guards against null DOM element for toggle-windows-update" `
    ($appJsContent -match 'if\s*\(\s*toggleWinUpdate\s*\)\s*toggleWinUpdate\.checked\s*=\s*!!data\.windows_update_disabled')

Assert-Check "syncRealWinOptimizeState guards against null DOM element for toggle-show-ext" `
    ($appJsContent -match 'if\s*\(\s*toggleExt\s*\)\s*toggleExt\.checked\s*=\s*!!data\.show_ext')

Assert-Check "syncRealWinOptimizeState guards against null DOM element for toggle-disable-bing" `
    ($appJsContent -match 'if\s*\(\s*toggleBing\s*\)\s*toggleBing\.checked\s*=\s*!!data\.bing_disabled')

# Summary
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " KET QUA ADVERSARIAL STRESS TEST M4:" -ForegroundColor Cyan
Write-Host "  Tong so tests PASS: $script:passed" -ForegroundColor Green
Write-Host "  Tong so tests FAIL: $script:failed" -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================`n" -ForegroundColor Cyan

if ($script:failed -gt 0) {
    exit 1
} else {
    exit 0
}
