# =========================================================================
# TEST SUITE: GO PHAN MEM, GO HANG LOAT & GIAO DIEN NUT GO CAI DAT
# VUONGTT TOOLKIT 2026 - TDD ENGINE
# tests/Test-SoftwareUninstallerAndBulkActions.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Error "TEST FAILED: $message"
        exit 1
    } else {
        Write-Host "  [PASS] $message" -ForegroundColor Green
    }
}

Write-Host "`n>>> KIEM THU TDD: GO CAI DAT, GO HANG LOAT & GIAO DIEN NUT GO <<<`n" -ForegroundColor Cyan

$opsRsPath = "src-tauri\src\system_ops.rs"
$appJsPath = "src-ui\app.js"
$indexHtmlPath = "src-ui\index.html"

Assert-True (Test-Path $opsRsPath) "Tep system_ops.rs phai ton tai"
Assert-True (Test-Path $appJsPath) "Tep app.js phai ton tai"
Assert-True (Test-Path $indexHtmlPath) "Tep index.html phai ton tai"

$opsRsContent = Get-Content -Raw -Encoding UTF8 $opsRsPath
$appJsContent = Get-Content -Raw -Encoding UTF8 $appJsPath
$indexHtmlContent = Get-Content -Raw -Encoding UTF8 $indexHtmlPath

Write-Host "--- Nhom 1: Backend Rust (system_ops.rs) Xu Ly Lenh Go & Unescape JSON ---" -ForegroundColor Yellow

# 1.1 system_ops.rs phai co bo giai ma chuoi JSON ho tro ky tu escape (extract_json_string hoac xu ly quote)
Assert-True ($opsRsContent -match 'extract_json_string' -or $opsRsContent -match 'extract_json_field.*char_indices') "system_ops.rs phai ho tro extract_json_string / unescaping chuoi JSON co dau ngoac kep"

# 1.2 system_ops.rs phai ho tro action uninstall_app va bulk_uninstall_apps / uninstall_multiple_apps
Assert-True ($opsRsContent -match 'act == "uninstall_app"' -and ($opsRsContent -match 'bulk_uninstall_apps' -or $opsRsContent -match 'uninstall_multiple_apps' -or $opsRsContent -match 'uninstall_apps')) "system_ops.rs phai ho tro action uninstall_app va gỡ hàng loạt"

# 1.3 Lenh PowerShell phai chuyen doi MsiExec /I thanh /X
Assert-True ($opsRsContent -match '(?i)msiexec' -and ($opsRsContent -match '\/X' -or $opsRsContent -match '\/x')) "PowerShell executor phai chuyen doi MsiExec sang che do go /X"

# 1.4 Lenh PowerShell phai chay voi Verb RunAs tranh loi thieu quyen Admin (Error 740)
Assert-True ($opsRsContent -match 'Verb RunAs' -or $opsRsContent -match '-Verb\s+RunAs') "PowerShell executor phai chay voi Verb RunAs"

Write-Host "`n--- Nhom 2: Giao Dien Frontend (src-ui/index.html) ---" -ForegroundColor Yellow

# 2.1 index.html phai co nut/thanh thao tac Go Hang Loat
Assert-True ($indexHtmlContent -match 'btnBulkUninstall' -or $indexHtmlContent -match 'bulkUninstallSelectedApps') "index.html phai co nut Go Hang Loat"

# 2.2 index.html phai co checkbox Chon Tat Ca trong the thead
Assert-True ($indexHtmlContent -match 'chkSelectAllInstalledApps' -or $indexHtmlContent -match 'toggleSelectAllInstalledApps') "index.html phai co checkbox Chon Tat Ca tren thead"

Write-Host "`n--- Nhom 3: Logic JavaScript (src-ui/app.js) ---" -ForegroundColor Yellow

# 3.1 app.js phai co ham chon tat ca toggleSelectAllInstalledApps
Assert-True ($appJsContent -match 'toggleSelectAllInstalledApps') "app.js phai co ham toggleSelectAllInstalledApps"

# 3.2 app.js phai co ham go hang loat bulkUninstallSelectedApps
Assert-True ($appJsContent -match 'bulkUninstallSelectedApps') "app.js phai co ham bulkUninstallSelectedApps"

# 3.3 app.js phai dung ham uninstallAppByIndex tranh loi attribute quote HTML
Assert-True ($appJsContent -match 'uninstallAppByIndex') "app.js phai su dung uninstallAppByIndex de tranh xung dot dau ngoac kep HTML"

# 3.4 Nut Go Cai Dat phai duoc doi mau sang mau do sang ro net (bg-red-600 hoac tuong duong)
Assert-True ($appJsContent -match 'bg-red-600' -or $appJsContent -match 'bg-rose-600' -or $appJsContent -match 'bg-red-500') "Nut Go Cai Dat phai duoc doi sang mau do sang ro net (bg-red-600/bg-rose-600)"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KET QUA: TOAN BO TEST TDD CHO UNINSTALLER VA BULK ACTIONS PASS!" -ForegroundColor Green
