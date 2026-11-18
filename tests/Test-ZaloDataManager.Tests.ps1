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

# Test 1: Verify command definitions and functional structure
# These functions are called via IPC, so we verify their definition existance in the module.

Assert-True (Get-Command "zalo_scan_data" -ErrorAction SilentlyContinue) "Zalo Scan Command Function Exists"
Assert-True (Get-Command "zalo_delete_data" -ErrorAction SilentlyContinue) "Zalo Delete Command Function Exists"

# Test 2: Verify Log synchronization mechanism existence
Assert-True (Get-Command "append_log" -ErrorAction SilentlyContinue) "Append Log Function Exists"
Assert-True (Get-Command "get_logs_json" -ErrorAction SilentlyContinue) "Get Logs Function Exists"

Write-Host "`nTest Results: $passed Passed, $failed Failed." -ForegroundColor Yellow
if ($failed -gt 0) { exit 1 } else { exit 0 }
