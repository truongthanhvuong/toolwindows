# =========================================================================
# TDD TEST SUITE: SELF-ELEVATION & ADMIN AUTO-RUN VERIFICATION
# tests/Test-SelfElevationAndAdminAutoRun.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$winPs1 = Join-Path $repoRoot "win.ps1"
$vuongttPs1 = Join-Path $repoRoot "vuongtt.ps1"
$toolkitPs1 = Join-Path $repoRoot "VUONGTT_Toolkit.ps1"
$mainRs = Join-Path $repoRoot "src-tauri\src\main.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: SELF-ELEVATION & ADMIN AUTO-RUN VERIFICATION        " -ForegroundColor Yellow -BackgroundColor Black
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

$winContent = if (Test-Path $winPs1) { Get-Content -Path $winPs1 -Raw -Encoding UTF8 } else { "" }
$vuongttContent = if (Test-Path $vuongttPs1) { Get-Content -Path $vuongttPs1 -Raw -Encoding UTF8 } else { "" }
$toolkitContent = if (Test-Path $toolkitPs1) { Get-Content -Path $toolkitPs1 -Raw -Encoding UTF8 } else { "" }
$mainContent = if (Test-Path $mainRs) { Get-Content -Path $mainRs -Raw -Encoding UTF8 } else { "" }

# 1. win.ps1 phai dung duong dan tuyet doi cua powershell.exe va thu muc WorkingDirectory an toan
Assert-Test "win.ps1 phai su dung duong dan powershell tuyet doi va WorkingDirectory de chong Access Denied" {
    ($winContent -match '\$PSHOME\\powershell\.exe' -or $winContent -match 'WindowsPowerShell\\v1\.0\\powershell\.exe') -and
    $winContent -match 'WorkingDirectory'
}

# 2. win.ps1 phai ma hoa EncodedCommand de tranh hong quote arguments khi nang quyen UAC
Assert-Test "win.ps1 phai su dung EncodedCommand khi trigger Start-Process RunAs" {
    $winContent -match 'EncodedCommand'
}

# 3. win.ps1 phai tich hop co che Du Phong (Fallback) sang Shell.Application hoac ProcessStartInfo neu Start-Process loi
Assert-Test "win.ps1 phai co co che du phong Shell.Application / ProcessStartInfo khi nang quyen" {
    $winContent -match 'Shell\.Application' -or $winContent -match 'ProcessStartInfo'
}

# 4. vuongtt.ps1 phai dong bo co che tu dong nang quyen da tang voi win.ps1
Assert-Test "vuongtt.ps1 phai dong bo co che tu dong nang quyen da tang voi win.ps1" {
    $vuongttContent -match 'EncodedCommand' -and
    $vuongttContent -match 'WorkingDirectory'
}

# 5. VUONGTT_Toolkit.ps1 phai co WorkingDirectory an toan va duong dan powershell tuyet doi
Assert-Test "VUONGTT_Toolkit.ps1 phai su dung WorkingDirectory an toan khi tu dong RunAs" {
    $toolkitContent -match 'WorkingDirectory' -and
    ($toolkitContent -match '\$PSHOME\\powershell\.exe' -or $toolkitContent -match 'WindowsPowerShell\\v1\.0\\powershell\.exe')
}

# 6. src-tauri/src/main.rs phai tich hop tu dong kiem tra quyen Admin va goi ShellExecute RunAs khi khoi chay
Assert-Test "src-tauri/src/main.rs phai co co che tu dong RunAs UAC (ensure_admin_elevation) khi khoi chay" {
    $mainContent -match 'ensure_admin_elevation' -and
    $mainContent -match 'runas'
}

# 7. src-tauri/src/main.rs phai bo qua yeu cau Admin khi chay --smoke-test va --version
Assert-Test "src-tauri/src/main.rs phai bo qua yeu cau Admin cho --smoke-test va --version" {
    $mainContent -match '--smoke-test' -and
    $mainContent -match '--version'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
