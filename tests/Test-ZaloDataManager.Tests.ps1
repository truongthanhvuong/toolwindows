# tests/Test-ZaloDataManager.Tests.ps1
# Kiểm thử: Zalo Data Management (zalo_scan_data, zalo_delete_data)

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$passed = 0
$failed = 0

function Assert-True($condition, $message) {
    if ($condition) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "Running Zalo Data Manager Tests..." -ForegroundColor Cyan

# Test 1: Verify command definitions in main.rs
$mainRs = Get-Content (Join-Path $testDir "../src-tauri/src/main.rs") -Raw
Assert-True ($mainRs -match 'cmd == "zalo_scan"') "Zalo Scan IPC Command Defined in main.rs"
Assert-True ($mainRs -match 'cmd == "zalo_delete"') "Zalo Delete IPC Command Defined in main.rs"

# Test 2: Verify Log synchronization mechanism definition in system_ops.rs
$systemOpsRs = Get-Content (Join-Path $testDir "../src-tauri/src/system_ops.rs") -Raw
Assert-True ($systemOpsRs -match 'pub fn append_log') "Append Log Function Defined in system_ops.rs"
Assert-True ($systemOpsRs -match 'pub fn get_logs_json') "Get Logs Function Defined in system_ops.rs"
Assert-True ($systemOpsRs -match 'zalo_scan_all') "zalo_scan_all action Defined in system_ops.rs"
Assert-True ($systemOpsRs -match 'zalo_clear_cache') "zalo_clear_cache action Defined in system_ops.rs"

# Test 3: Verify Frontend UI & Controller in app.js and index.html
$appJs = Get-Content (Join-Path $testDir "../src-ui/app.js") -Raw
Assert-True ($appJs -match 'window\.zaloScanAll') "window.zaloScanAll defined in app.js"
Assert-True ($appJs -match 'window\.zaloDetectPath') "window.zaloDetectPath defined in app.js"
Assert-True ($appJs -match 'window\.zaloDeleteData') "window.zaloDeleteData defined in app.js"
Assert-True ($appJs -match 'window\.zaloClearCache') "window.zaloClearCache defined in app.js"

$indexHtml = Get-Content (Join-Path $testDir "../src-ui/index.html") -Raw
Assert-True ($indexHtml -match 'zalo-breakdown-panel') "Zalo breakdown panel in index.html"
Assert-True ($indexHtml -match 'zalo-size-total') "Zalo size total element in index.html"
Assert-True ($indexHtml -match 'zalo-size-media') "Zalo size media element in index.html"
Assert-True ($indexHtml -match 'zalo-size-cache') "Zalo size cache element in index.html"
Assert-True ($indexHtml -match 'zalo-size-system') "Zalo size system element in index.html"

Write-Host "`nTest Results: $passed Passed, $failed Failed." -ForegroundColor Yellow
if ($failed -gt 0) { exit 1 } else { exit 0 }
