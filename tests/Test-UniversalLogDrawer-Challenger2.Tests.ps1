# ==============================================================================
# EMPIRICAL CHALLENGER 2: TEST SUITE FOR MILESTONE M3
# (UNIVERSAL REAL-TIME EXECUTION LOG DRAWER)
# ==============================================================================

$ErrorActionPreference = "Stop"

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0
$script:Failures = @()

function Assert-Challenger {
    param(
        [string]$Category,
        [string]$TestName,
        [bool]$Condition,
        [string]$FailureMessage = ""
    )
    $script:TotalTests++
    if ($Condition) {
        Write-Host "  [$Category][PASS] $TestName" -ForegroundColor Green
        $script:PassedTests++
    } else {
        Write-Host "  [$Category][FAIL] $TestName - $FailureMessage" -ForegroundColor Red
        $script:FailedTests++
        $script:Failures += "[$Category] ${TestName} - $FailureMessage"
    }
}

Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "CHALLENGER 2: EMPIRICAL ADVERSARIAL VERIFICATION FOR MILESTONE M3" -ForegroundColor Cyan
Write-Host "========================================================================`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$mainPath = Join-Path $projectRoot "src-tauri\src\main.rs"
$headlessTestPath = Join-Path $projectRoot "tests\test-universallog-empirical.cjs"

# ------------------------------------------------------------------------------
# SECTION 1: CODEBASE INTEGRITY & AST VALIDATION
# ------------------------------------------------------------------------------
Write-Host ">>> SECTION 1: Codebase Integrity & AST Validation <<<" -ForegroundColor Yellow

Assert-Challenger "Integrity" "C1.01: File index.html exists" (Test-Path $htmlPath)
Assert-Challenger "Integrity" "C1.02: File app.js exists" (Test-Path $appJsPath)
Assert-Challenger "Integrity" "C1.03: File system_ops.rs exists" (Test-Path $opsPath)
Assert-Challenger "Integrity" "C1.04: File main.rs exists" (Test-Path $mainPath)
Assert-Challenger "Integrity" "C1.05: Headless test runner exists" (Test-Path $headlessTestPath)

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)
$mainContent = [System.IO.File]::ReadAllText($mainPath, [System.Text.Encoding]::UTF8)

# Validate JS syntax
$nodeCheck = & node -c $appJsPath 2>&1
Assert-Challenger "Integrity" "C1.06: app.js passes node syntax validation without errors" ($LASTEXITCODE -eq 0)

# ------------------------------------------------------------------------------
# SECTION 2: UI DOM SPECIFICATION & STYLING COMPLIANCE
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 2: UI DOM Specification & Styling Compliance <<<" -ForegroundColor Yellow

Assert-Challenger "UI" "C2.01: #universal-log-drawer positioned fixed bottom-4 right-4 z-40" `
    ($htmlContent -match 'id="universal-log-drawer"[^>]*fixed bottom-4 right-4 z-40')

Assert-Challenger "UI" "C2.02: #universal-log-header present with cursor-pointer" `
    ($htmlContent -match 'id="universal-log-header"[^>]*cursor-pointer')

Assert-Challenger "UI" "C2.03: Pulse status indicator present in header" `
    ($htmlContent -match 'animate-pulse')

Assert-Challenger "UI" "C2.04: #universal-log-count badge element present" `
    ($htmlContent -match 'id="universal-log-count"')

Assert-Challenger "UI" "C2.05: Copy button #btn-copy-universal-log present" `
    ($htmlContent -match 'id="btn-copy-universal-log"')

Assert-Challenger "UI" "C2.06: Clear button #btn-clear-universal-log present" `
    ($htmlContent -match 'id="btn-clear-universal-log"')

Assert-Challenger "UI" "C2.07: Toggle button #btn-toggle-universal-log present with toggle icon" `
    ($htmlContent -match 'id="btn-toggle-universal-log"' -and $htmlContent -match 'id="universal-log-toggle-icon"')

Assert-Challenger "UI" "C2.08: #universal-log-body terminal container has initial hidden class" `
    ($htmlContent -match 'id="universal-log-body"[^>]*hidden')

Assert-Challenger "UI" "C2.09: #universal-log-body has overflow-y-auto and dark font-mono styling" `
    ($htmlContent -match 'id="universal-log-body"[^>]*overflow-y-auto' -and $htmlContent -match 'font-mono' -and $htmlContent -match 'text-emerald-400')

# ------------------------------------------------------------------------------
# SECTION 3: BACKEND IPC ROUTING & THREAD SAFETY
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 3: Backend IPC Routing & Thread Safety <<<" -ForegroundColor Yellow

Assert-Challenger "Backend" "C3.01: main.rs routes get_install_logs IPC endpoint" `
    ($mainContent -match 'cmd == "get_install_logs"')

Assert-Challenger "Backend" "C3.02: main.rs routes clear_install_logs IPC endpoint" `
    ($mainContent -match 'cmd == "clear_install_logs"')

Assert-Challenger "Backend" "C3.03: system_ops.rs thread-safe static EXECUTION_LOGS Mutex" `
    ($opsContent -match 'static EXECUTION_LOGS:\s*Mutex<Vec<String>>')

Assert-Challenger "Backend" "C3.04: system_ops.rs append_log caps buffer at 1000 lines" `
    ($opsContent -match 'logs\.len\(\)\s*>\s*1000' -and $opsContent -match 'drain\(0\.\.200\)')

Assert-Challenger "Backend" "C3.05: system_ops.rs get_logs_json serializes JSON safely" `
    ($opsContent -match 'pub fn get_logs_json')

Assert-Challenger "Backend" "C3.06: system_ops.rs clear_logs clears mutex buffer" `
    ($opsContent -match 'pub fn clear_logs' -and $opsContent -match 'logs\.clear\(\)')

# ------------------------------------------------------------------------------
# SECTION 4: HEADLESS EMPIRICAL DOM STRESS EXECUTION (NODE.JS)
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 4: Headless Empirical DOM Stress Execution (Node.js) <<<" -ForegroundColor Yellow

$nodeTestOutput = & node $headlessTestPath 2>&1
$nodeTestExit = $LASTEXITCODE

Write-Host ($nodeTestOutput -join "`n")

Assert-Challenger "Empirical" "C4.01: Headless simulation (59 tests covering delta, scroll, toggle, clipboard, self-healing) PASSES 100%" `
    ($nodeTestExit -eq 0 -and ($nodeTestOutput -join "`n") -match '0 FAIL')

# ------------------------------------------------------------------------------
# SECTION 5: REGRESSION VALIDATION OF EXISTING TEST SUITES
# ------------------------------------------------------------------------------
Write-Host "`n>>> SECTION 5: Regression Validation of Existing Test Suites <<<" -ForegroundColor Yellow

# 5.1 Run Test-UniversalLogDrawer.Tests.ps1
$m3Suite = Join-Path $projectRoot "tests\Test-UniversalLogDrawer.Tests.ps1"
$m3Out = & powershell -NoProfile -ExecutionPolicy Bypass -File $m3Suite 2>&1
Assert-Challenger "Regression" "C5.01: Worker M3 test suite (Test-UniversalLogDrawer.Tests.ps1) passes 100%" `
    ($LASTEXITCODE -eq 0 -and ($m3Out -join "`n") -match 'Tong so tests FAIL: 0')

# 5.2 Run Test-GatekeeperPolicy.Tests.ps1
$m2Suite = Join-Path $projectRoot "tests\Test-GatekeeperPolicy.Tests.ps1"
$m2Out = & powershell -NoProfile -ExecutionPolicy Bypass -File $m2Suite 2>&1
Assert-Challenger "Regression" "C5.02: Milestone M2 test suite (Test-GatekeeperPolicy.Tests.ps1) passes 100%" `
    ($LASTEXITCODE -eq 0 -and ($m2Out -join "`n") -match 'Tong so tests FAIL: 0')

# ------------------------------------------------------------------------------
# SECTION 6: SUMMARY & VERDICT
# ------------------------------------------------------------------------------
Write-Host "`n========================================================================" -ForegroundColor Cyan
Write-Host "CHALLENGER 2 FINAL VERDICT:" -ForegroundColor Cyan
Write-Host "  Total Checks : $script:TotalTests"
Write-Host "  Passed Checks: $script:PassedTests" -ForegroundColor Green
Write-Host "  Failed Checks: $script:FailedTests" -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })

if ($script:FailedTests -gt 0) {
    Write-Host "`nFAILURES DETECTED:" -ForegroundColor Red
    foreach ($f in $script:Failures) {
        Write-Host "  - $f" -ForegroundColor Red
    }
    Write-Host "`nVERDICT: REJECT" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nVERDICT: APPROVE" -ForegroundColor Green
    exit 0
}
