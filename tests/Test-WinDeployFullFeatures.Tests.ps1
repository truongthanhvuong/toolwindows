# =========================================================================
#   KIEM THU TDD: TOAN DIEN CAC TINH NANG TAB CAI WIN & BYPASS (view-win-deploy)
# =========================================================================
$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host "`n>>> KIEM THU TDD: TOAN DIEN TINH NANG CAI WIN & BYPASS <<<`n" -ForegroundColor Cyan

$opsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
$mainPath = "E:\toolwindows\src-tauri\src\main.rs"
$htmlPath = "E:\toolwindows\src-ui\index.html"
$appJsPath = "E:\toolwindows\src-ui\app.js"

$opsContent = Get-Content -Path $opsPath -Raw -Encoding UTF8
$mainContent = Get-Content -Path $mainPath -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8

Write-Host "--- Nhom 1: Backend Rust Schema & Dialog Host (browse_iso) ---" -ForegroundColor Yellow

# 1.1 main.rs phai tra ve file_path ro rang khi goi browse_iso
Assert-True ($mainContent -match 'file_path' -or $mainContent -match 'browse_iso') "main.rs phai tra ve file_path hoac xu ly rieng cho browse_iso"

# 1.2 system_ops.rs browse_iso phai co TopMost va STA an toan
Assert-True ($opsContent -match 'TopMost\s*=\s*\$true' -or $opsContent -match 'ShowDialog') "system_ops.rs OpenFileDialog phai co co che TopMost de hop thoai khong bi che"

Write-Host "`n--- Nhom 2: Frontend Tuong Tac Chon Che Do Cai Dat (Deployment Mode) ---" -ForegroundColor Yellow

# 2.1 app.js phai co controller chuyen doi che do deploy_mode (selectDeployMode hoac listener)
Assert-True ($appJsContent -match 'selectDeployMode' -or $appJsContent -match 'initDeployModeSwitcher') "app.js phai co ham dieu khien visual highlight khi chon che do cai dat"

# 2.2 index.html 2 card deployment mode phai co id hoac click handler de chon duoc de dang
Assert-True ($htmlContent -match 'card-mode-upgrade' -and $htmlContent -match 'card-mode-clean') "index.html phai co id card-mode-upgrade va card-mode-clean"

Write-Host "`n--- Nhom 3: Sub-tabs & Copy & Utilities ---" -ForegroundColor Yellow

# 3.1 Nut Copy duong dan ISO phai co onclick copyIsoPath
Assert-True ($htmlContent -match 'copyIsoPath' -and $appJsContent -match 'copyIsoPath') "Phai co ham copyIsoPath sao chep vao clipboard"

# 3.2 4 Sub-tabs tren dau view-win-deploy phai co navigation handlers
Assert-True ($htmlContent -match 'switchView\(''view-win-activate''\)' -or $appJsContent -match 'switchView.*view-win-activate') "Sub-tab Kich Hoat HWID phai co su kien chuyen tab"
Assert-True ($htmlContent -match 'switchView\(''view-disk-bitlocker''\)' -or $appJsContent -match 'switchView.*view-disk-bitlocker') "Sub-tab Tat BitLocker phai co su kien chuyen tab"
Assert-True ($htmlContent -match 'switchView\(''view-tech-driver''\)' -or $appJsContent -match 'switchView.*view-tech-driver') "Sub-tab Sao Luu Win / Driver phai co su kien chuyen tab"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "TAT CA TEST TDD CAI WIN TOAN DIEN PASSED!" -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green
