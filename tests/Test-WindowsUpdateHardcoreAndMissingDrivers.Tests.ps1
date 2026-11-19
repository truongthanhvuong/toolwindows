# =========================================================================
# TDD TEST SUITE: HARDCORE WINDOWS UPDATE BLOCK & MISSING DRIVERS SCAN
# tests/Test-WindowsUpdateHardcoreAndMissingDrivers.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$mainRs = Join-Path $repoRoot "src-tauri\src\main.rs"
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"
$appJs = Join-Path $repoRoot "src-ui\app.js"
$indexHtml = Join-Path $repoRoot "src-ui\index.html"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: HARDCORE WINDOWS UPDATE & MISSING DRIVERS SCAN      " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "======================================================================" -ForegroundColor Cyan

$passedCount = 0
$failedCount = 0

function Assert-Test([string]$desc, [scriptblock]$condition) {
    try {
        $result = & $condition
        if ($result) {
            Write-Host " [PASS] $desc" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host " [FAIL] $desc" -ForegroundColor Red
            $script:failedCount++
        }
    } catch {
        Write-Host " [FAIL] $desc - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failedCount++
    }
}

$opsContent = Get-Content -Path $opsRs -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $indexHtml -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJs -Raw -Encoding UTF8
$mainContent = Get-Content -Path $mainRs -Raw -Encoding UTF8

# 1. Kiem tra disable_windows_update ap dung cac chinh sach GPO va WSUS dummy triet de
Assert-Test "disable_windows_update phai thiet lap DisableWindowsUpdateAccess, DoNotConnectToWindowsUpdateInternetLocations va SetDisableUXWUAccess" {
    $opsContent -match 'DisableWindowsUpdateAccess' -and
    $opsContent -match 'DoNotConnectToWindowsUpdateInternetLocations' -and
    $opsContent -match 'SetDisableUXWUAccess'
}

# 2. Kiem tra disable_windows_update chuyen huong WSUS ve 127.0.0.1 va set AUOptions = 1
Assert-Test "disable_windows_update phai chuyen huong WUServer ve loopback 127.0.0.1 de chan 100% ket noi toi may chu update" {
    $opsContent -match 'WUServer.*127\.0\.0\.1' -and
    $opsContent -match 'UseWUServer' -and
    $opsContent -match 'AUOptions'
}

# 3. Kiem tra disable_windows_update vo hieu hoa cac Scheduled Tasks cua UpdateOrchestrator va WaaSMedic
Assert-Test "disable_windows_update phai vo hieu hoa cac Task ngam UpdateOrchestrator va WaaSMedic" {
    $opsContent -match 'UpdateOrchestrator' -and
    $opsContent -match 'Disable-ScheduledTask'
}

# 4. Kiem tra disable_windows_update tich hop Outbound Firewall Rule chan wuauserv
Assert-Test "disable_windows_update phai thiet lap Firewall Rule chan ket noi ra ngoai cua Windows Update" {
    $opsContent -match 'VUONGTT_Block_Windows_Update' -or $opsContent -match 'New-NetFirewallRule'
}

# 5. Kiem tra enable_windows_update phuc hoi sach se toan bo chinh sach va dich vu
Assert-Test "enable_windows_update phai xoa bo WSUS dummy, xoa Firewall rule va phuc hoi UpdateOrchestrator" {
    $opsContent -match 'Remove-ItemProperty.*WUServer' -and
    $opsContent -match 'Remove-NetFirewallRule' -and
    $opsContent -match 'Enable-ScheduledTask'
}

# 6. Kiem tra action scan_missing_drivers duoc khai bao trong backend Rust
Assert-Test "system_ops.rs phai ho tro action scan_missing_drivers quet cac thiet bi thieu driver qua Win32_PnPEntity" {
    $opsContent -match 'act == "scan_missing_drivers"' -and
    $opsContent -match 'ConfigManagerErrorCode'
}

# 7. Kiem tra giao dien view-tech-driver co card Quet Driver Thieu va Khuyen nghi tai phan mem
Assert-Test "view-tech-driver trong index.html phai co card Kiem Tra Driver Thieu va Khuyen Nghi Cap Nhat" {
    $htmlContent -match 'scanMissingDrivers' -and
    $htmlContent -match 'id="driver-scan-results"' -and
    $htmlContent -match '3DP Chip' -and
    $htmlContent -match 'Snappy Driver Installer'
}

# 8. Kiem tra app.js co ham scanMissingDrivers va xu ly hien thi ket qua quet driver
Assert-Test "app.js phai dinh nghia window.scanMissingDrivers va cac ham tai phan mem driver" {
    $appJsContent -match 'window\.scanMissingDrivers' -and
    $appJsContent -match 'download3DPChip'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
