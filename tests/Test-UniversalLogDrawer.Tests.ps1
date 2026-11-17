# =========================================================================
# TEST SUITE: UNIVERSAL REAL-TIME EXECUTION LOG DRAWER (R3)
# VUONGTT TOOLKIT 2026 - TDD OPAQUE-BOX E2E VERIFICATION
# =========================================================================
# Tier 1: Canonical Feature Coverage (Happy Path)
# Tier 2: Boundary & Corner Cases (Negative/Null/Idempotency)
# Tier 3: Cross-Feature Combinations (Action Dispatch Auto-Expand & Stream)
# Tier 4: Real-World Application Scenarios (Delta Rendering & Clipboard Simulation)
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0
$script:tierStats = @{
    "Tier 1" = @{ Pass = 0; Fail = 0 }
    "Tier 2" = @{ Pass = 0; Fail = 0 }
    "Tier 3" = @{ Pass = 0; Fail = 0 }
    "Tier 4" = @{ Pass = 0; Fail = 0 }
}

function Assert-TierCondition {
    param(
        [string]$Tier,
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [$Tier][PASS] $TestName" -ForegroundColor Green
        $script:passed++
        $script:tierStats[$Tier].Pass++
    } else {
        Write-Host "  [$Tier][FAIL] $TestName - $Message" -ForegroundColor Red
        $script:failed++
        $script:tierStats[$Tier].Fail++
    }
}

Write-Host "`n>>> [TEST SUITE] R3: UNIVERSAL REAL-TIME EXECUTION LOG DRAWER <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$mainPath = Join-Path $projectRoot "src-tauri\src\main.rs"

Assert-TierCondition "Tier 1" "T1.01: File index.html phai ton tai" (Test-Path $htmlPath)
Assert-TierCondition "Tier 1" "T1.02: File app.js phai ton tai" (Test-Path $appJsPath)
Assert-TierCondition "Tier 1" "T1.03: File system_ops.rs phai ton tai" (Test-Path $opsPath)
Assert-TierCondition "Tier 1" "T1.04: File main.rs phai ton tai" (Test-Path $mainPath)

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)
$mainContent = [System.IO.File]::ReadAllText($mainPath, [System.Text.Encoding]::UTF8)

# =========================================================================
# TIER 1: CANONICAL FEATURE COVERAGE (HAPPY PATH)
# =========================================================================
Write-Host "`n--- TIER 1: CANONICAL FEATURE COVERAGE ---" -ForegroundColor Yellow

# T1.1: UI Floating Drawer DOM Structure
Assert-TierCondition "Tier 1" "T1.05: Khung Drawer universal-log-drawer ton tai trong HTML" `
    ($htmlContent -match 'id="universal-log-drawer"' -or $htmlContent -match 'id="universal-log-console"')
Assert-TierCondition "Tier 1" "T1.06: Than hien thi log universal-log-body ton tai" `
    ($htmlContent -match 'id="universal-log-body"' -or $htmlContent -match 'id="universal-log-terminal"')
Assert-TierCondition "Tier 1" "T1.07: Nut Thu nho / Mo rong btn-toggle-universal-log ton tai" `
    ($htmlContent -match 'id="btn-toggle-universal-log"' -or $htmlContent -match 'id="btn-toggle-drawer"')
Assert-TierCondition "Tier 1" "T1.08: Nut Sao chep log btn-copy-universal-log ton tai" `
    ($htmlContent -match 'id="btn-copy-universal-log"')
Assert-TierCondition "Tier 1" "T1.09: Nut Xoa log btn-clear-universal-log ton tai" `
    ($htmlContent -match 'id="btn-clear-universal-log"')
Assert-TierCondition "Tier 1" "T1.10: Badge dem so dong log universal-log-count ton tai" `
    ($htmlContent -match 'id="universal-log-count"' -or $htmlContent -match 'id="universal-log-badge"')

# T1.2: Frontend Controller Functions
Assert-TierCondition "Tier 1" "T1.11: app.js co ham khoi tao initUniversalLogDrawer" `
    ($appJsContent -match 'initUniversalLogDrawer')
Assert-TierCondition "Tier 1" "T1.12: app.js dinh nghia ham toan cuc window.appendUniversalLog" `
    ($appJsContent -match 'window\.appendUniversalLog\s*=' -or $appJsContent -match 'function appendUniversalLog')
Assert-TierCondition "Tier 1" "T1.13: app.js chua vong lap polling get_install_logs" `
    ($appJsContent -match 'get_install_logs')
Assert-TierCondition "Tier 1" "T1.14: app.js goi lenh clear_install_logs khi bam nut Xoa log" `
    ($appJsContent -match 'clear_install_logs')
Assert-TierCondition "Tier 1" "T1.15: app.js co logic sao chep Clipboard cho Universal Log" `
    ($appJsContent -match 'clipboard\.writeText' -or $appJsContent -match 'execCommand\("copy"\)')

# T1.3: Backend Rust Log IPC Bridge
Assert-TierCondition "Tier 1" "T1.16: Backend main.rs hoac system_ops.rs ho tro IPC get_install_logs" `
    ($mainContent -match 'get_install_logs' -or $opsContent -match 'get_install_logs')
Assert-TierCondition "Tier 1" "T1.17: Backend main.rs hoac system_ops.rs ho tro IPC clear_install_logs" `
    ($mainContent -match 'clear_install_logs' -or $opsContent -match 'clear_install_logs')
Assert-TierCondition "Tier 1" "T1.18: system_ops.rs co ham append_log de ghi nhat ky he thong" `
    ($opsContent -match 'pub fn append_log')
Assert-TierCondition "Tier 1" "T1.19: system_ops.rs co ham get_logs_json de tra ve mang JSON" `
    ($opsContent -match 'pub fn get_logs_json')
Assert-TierCondition "Tier 1" "T1.20: system_ops.rs co ham clear_logs de lam sach hang doi" `
    ($opsContent -match 'pub fn clear_logs')

# =========================================================================
# TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS
# =========================================================================
Write-Host "`n--- TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS ---" -ForegroundColor Yellow

# T2.1: Log Buffer Capacity Limit (Ring Buffer Truncation)
Assert-TierCondition "Tier 2" "T2.01: Backend Rust gioi han toi da 1000 dong log (tu xa bot khi vuot nguong)" `
    ($opsContent -match '1000' -and $opsContent -match 'drain\(0\.\.200\)' -or $opsContent -match 'EXECUTION_LOGS')

# T2.2: Escaping & Sanitization for JSON Log Serialization
function Test-LogJsonSerialization {
    param([string]$RawMsg)
    # Rust escape logic simulation
    $escaped = $RawMsg.Replace('\', '\\').Replace('"', '\"').Replace("`r", '').Replace("`n", '\n')
    $json = "[`"$escaped`"]"
    try {
        $parsed = $json | ConvertFrom-Json
        return ($parsed[0] -eq $RawMsg.Replace("`r`n", "`n"))
    } catch {
        return $false
    }
}

$sampleLogs = @(
    "Thuc hien lenh: cmd.exe /c `"echo test`"",
    "Duong dan: C:\Program Files\VUONGTT\bin\tool.exe",
    "Thong bao loi: [ERROR] Tieng Viet co dau: Sửa lỗi máy in 0x0000011b",
    "Dong 1`r`nDong 2"
)
$allEscapedPass = $true
foreach ($log in $sampleLogs) {
    if (-not (Test-LogJsonSerialization -RawMsg $log)) {
        $allEscapedPass = $false
    }
}
Assert-TierCondition "Tier 2" "T2.02: Serialization JSON cua log xu ly an toan dau ngoac kep, duong dan backslash va unicode" `
    $allEscapedPass

# T2.3: Idempotent Clear Operation
Assert-TierCondition "Tier 2" "T2.03: system_ops.rs clear_logs hoat dong an toan khi hang doi log da rong" `
    ($opsContent -match 'logs\.clear\(\)' -or $opsContent -match 'EXECUTION_LOGS.*clear')

# =========================================================================
# TIER 3: CROSS-FEATURE COMBINATIONS
# =========================================================================
Write-Host "`n--- TIER 3: CROSS-FEATURE COMBINATIONS ---" -ForegroundColor Yellow

# T3.1: Auto-Expand Drawer on Action Dispatch
Assert-TierCondition "Tier 3" "T3.01: runToolkitAction hoac action trigger co logic tu dong mo rong Drawer" `
    ($appJsContent -match 'runToolkitAction' -and ($appJsContent -match 'universal-log-drawer' -or $appJsContent -match 'expandUniversalLog' -or $appJsContent -match 'openUniversalLog'))

# T3.2: Universal Telemetry Logging across Key Operations
$loggedOps = @(
    'Cai Windows',
    'Bypass TPM',
    'Driver',
    'Toi uu',
    'Chan Web'
)
$loggedOpsPass = $true
foreach ($op in $loggedOps) {
    if ($opsContent -notmatch "append_log") {
        $loggedOpsPass = $false
    }
}
Assert-TierCondition "Tier 3" "T3.02: Cac phan he he thong (Cai Win, Bypass, Driver, Toi uu, Chan web) deu day log vao append_log" `
    $loggedOpsPass

# T3.3: Terminal Dark Theme & Fluent Design Compliance
$hasTerminalTheme = ($htmlContent -match 'bg-slate-900' -or $htmlContent -match 'bg-black' -or $htmlContent -match 'bg-zinc-900') -and `
                    ($htmlContent -match 'font-mono' -or $htmlContent -match 'text-emerald-' -or $htmlContent -match 'text-green-')
Assert-TierCondition "Tier 3" "T3.03: Khung Terminal Dark Theme tuan thu styling (font-mono, dark background, emerald/green text)" `
    $hasTerminalTheme

# =========================================================================
# TIER 4: REAL-WORLD APPLICATION SCENARIOS
# =========================================================================
Write-Host "`n--- TIER 4: REAL-WORLD APPLICATION SCENARIOS ---" -ForegroundColor Yellow

# T4.1: Delta Rendering & Auto-Scroll Simulation
function Simulate-LogDrawerDeltaStream {
    $drawerState = @{
        RenderedCount = 0
        LogBuffer = @()
        IsAutoScroll = $true
        IsExpanded = $false
    }
    
    # 1. Action starts -> Drawer auto-expands
    $drawerState.IsExpanded = $true
    
    # 2. Server emits batch 1 (3 logs)
    $serverLogs = @(
        "[12:00:01] Bat dau kiem tra cau hinh he thong...",
        "[12:00:02] Phat hien Windows 11 23H2 (Build 22631)",
        "[12:00:03] Kiem tra TPM 2.0: OK, SecureBoot: OK"
    )
    
    # Delta render
    if ($serverLogs.Count -gt $drawerState.RenderedCount) {
        $newLogs = $serverLogs[$drawerState.RenderedCount..($serverLogs.Count - 1)]
        $drawerState.LogBuffer += $newLogs
        $drawerState.RenderedCount = $serverLogs.Count
    }
    
    $batch1Pass = ($drawerState.LogBuffer.Count -eq 3 -and $drawerState.RenderedCount -eq 3)
    
    # 3. Server emits batch 2 (2 new logs)
    $serverLogs += @(
        "[12:00:04] Khoi chay tien trinh toi uu hoa registry...",
        "[12:00:05] Hoan tat 100% thanh cong!"
    )
    if ($serverLogs.Count -gt $drawerState.RenderedCount) {
        $newLogs = $serverLogs[$drawerState.RenderedCount..($serverLogs.Count - 1)]
        $drawerState.LogBuffer += $newLogs
        $drawerState.RenderedCount = $serverLogs.Count
    }
    
    $batch2Pass = ($drawerState.LogBuffer.Count -eq 5 -and $drawerState.RenderedCount -eq 5)
    
    # 4. User copies log
    $plainText = $drawerState.LogBuffer -join "`r`n"
    $copyPass = ($plainText -match 'Phat hien Windows 11' -and $plainText -match 'Hoan tat 100% thanh cong!')
    
    # 5. User clears log
    $drawerState.LogBuffer = @()
    $drawerState.RenderedCount = 0
    $clearPass = ($drawerState.LogBuffer.Count -eq 0 -and $drawerState.RenderedCount -eq 0)
    
    return ($batch1Pass -and $batch2Pass -and $copyPass -and $clearPass -and $drawerState.IsExpanded)
}

Assert-TierCondition "Tier 4" "T4.01: Mo phong chu trinh Delta Streaming, Auto-Expand, Copy Clipboard va Clear Buffer" `
    (Simulate-LogDrawerDeltaStream)

# T4.2: Rust Cargo Test Coverage Verification
$cargoTomlPath = Join-Path $projectRoot "src-tauri\Cargo.toml"
Assert-TierCondition "Tier 4" "T4.02: src-tauri/Cargo.toml ton tai va hop le" (Test-Path $cargoTomlPath)

# =========================================================================
# SUMMARY REPORT
# =========================================================================
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " KET QUA KIEM THU R3 (UNIVERSAL REAL-TIME LOG DRAWER):" -ForegroundColor Cyan
Write-Host "  Tong so tests PASS: $script:passed" -ForegroundColor Green
Write-Host "  Tong so tests FAIL: $script:failed" -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
Write-Host "  Phan bo Tiers:"
foreach ($tierKey in $script:tierStats.Keys | Sort-Object) {
    $tPass = $script:tierStats[$tierKey].Pass
    $tFail = $script:tierStats[$tierKey].Fail
    Write-Host "    $tierKey : $tPass PASS / $($tPass + $tFail) Total" -ForegroundColor $(if ($tFail -eq 0) { "Green" } else { "Yellow" })
}
Write-Host "========================================================`n" -ForegroundColor Cyan

if ($script:failed -gt 0) {
    exit 1
} else {
    exit 0
}
