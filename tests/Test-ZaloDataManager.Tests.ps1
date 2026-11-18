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

Write-Host "`nTest Results: $passed Passed, $failed Failed." -ForegroundColor Yellow
if ($failed -gt 0) { exit 1 } else { exit 0 }
