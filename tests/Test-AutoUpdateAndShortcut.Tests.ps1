# =========================================================================
# TEST SUITE: TU DONG TAO SHORTCUT DESKTOP & TU DONG CAP NHAT PHIEN BAN
# VUONGTT TOOLKIT 2026 - TDD ENGINE
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

Write-Host "`n>>> KIEM THU TDD: TU DONG TAO SHORTCUT & TU DONG CAP NHAT KHI KHOI CHAY <<<`n" -ForegroundColor Cyan

$mainRsPath = "src-tauri\src\main.rs"
$opsRsPath = "src-tauri\src\system_ops.rs"
$appJsPath = "src-ui\app.js"
$updPs1Path = "src\Core\AppUpdater.ps1"

Assert-True (Test-Path $mainRsPath) "Tep main.rs phai ton tai"
Assert-True (Test-Path $opsRsPath) "Tep system_ops.rs phai ton tai"
Assert-True (Test-Path $appJsPath) "Tep app.js phai ton tai"
Assert-True (Test-Path $updPs1Path) "Tep AppUpdater.ps1 phai ton tai"

$mainRsContent = Get-Content -Raw -Encoding UTF8 $mainRsPath
$opsRsContent = Get-Content -Raw -Encoding UTF8 $opsRsPath
$appJsContent = Get-Content -Raw -Encoding UTF8 $appJsPath
$updPs1Content = Get-Content -Raw -Encoding UTF8 $updPs1Path

Write-Host "--- Nhom 1: Kiem Tra Co Che Tao Shortcut Desktop ---" -ForegroundColor Yellow

# 1.1 main.rs hoac system_ops.rs phai co ham tao Shortcut Desktop
Assert-True ($mainRsContent -match 'ensure_desktop_shortcut' -or $opsRsContent -match 'ensure_desktop_shortcut') "He thong phai co ham ensure_desktop_shortcut() tao bieu tuong Desktop"

# 1.2 main() phai goi ham tao shortcut khi khoi dong
Assert-True ($mainRsContent -match 'ensure_desktop_shortcut') "main() trong main.rs phai tu dong goi ensure_desktop_shortcut() khi khoi dong tool"

# 1.3 Kiem tra logic tao shortcut qua PowerShell COM WScript.Shell
Assert-True ($mainRsContent -match 'WScript.Shell' -or $opsRsContent -match 'WScript.Shell' -or $opsRsContent -match 'VUONGTT Toolkit.lnk') "Co che tao shortcut phai nham den 'VUONGTT Toolkit.lnk' tren Desktop"

Write-Host "`n--- Nhom 2: Kiem Tra Dong Co Kiem Tra & Tu Dong Cap Nhat ---" -ForegroundColor Yellow

# 2.1 system_ops.rs phai co action 'check_update' ket noi logic cap nhat thuc te
Assert-True ($opsRsContent -match 'act == "check_update"' -and ($opsRsContent -match 'version\.json' -or $opsRsContent -match 'AppUpdater')) "system_ops.rs phai co action check_update kiem tra tep version.json thuc te"

# 2.2 AppUpdater.ps1 phai co ham Get-VUONGTTAppUpdateInfo
Assert-True ($updPs1Content -match 'function Get-VUONGTTAppUpdateInfo') "AppUpdater.ps1 phai co ham Get-VUONGTTAppUpdateInfo kiem tra cap nhat"

# 2.3 system_ops.rs phai co action thuc thi cap nhat tu dong 'apply_update'
Assert-True ($opsRsContent -match 'apply_update' -or $opsRsContent -match 'download_and_apply_update') "system_ops.rs phai ho tro action tai va cap nhat phien ban moi"

# 2.4 system_ops.rs phai ho tro restart_app / exit_app de giai phong file lock
Assert-True ($opsRsContent -match 'restart_app' -or $opsRsContent -match 'exit_app') "system_ops.rs phai ho tro action restart_app giai phong file lock khi cap nhat"

Write-Host "`n--- Nhom 3: Kiem Tra Tu Dong Kiem Tra Cap Nhat Tren UI (app.js) ---" -ForegroundColor Yellow

# 3.1 app.js phai tu dong kiem tra cap nhat khi tai trang (DOMContentLoaded)
Assert-True ($appJsContent -match 'initAutoUpdateOnStartup' -or $appJsContent -match 'check_update') "app.js phai tu dong kich hoat kiem tra cap nhat khi khoi dong"

# 3.2 app.js phai co xu ly thong bao khi co ban cap nhat moi
Assert-True ($appJsContent -match 'showToast' -and ($appJsContent -match 'checkForUpdate' -or $appJsContent -match 'apply_update')) "app.js phai hien thi thong bao cap nhat cho nguoi dung"

# 3.3 Nut btn-header-update phai goi checkForUpdate (khong hien thi raw JSON)
Assert-True ($appJsContent -match 'btn-header-update' -and $appJsContent -match 'checkForUpdate\(true\)') "Nut btn-header-update tren Header phai kich hoat checkForUpdate(true)"
Assert-True (-not ($appJsContent -match 'actionId:\s*"check_update"[^}]+showToast\([^)]*res\.message')) "app.js khong duoc hien thi raw JSON res.message cua check_update vao showToast"

Write-Host "`n--- Nhom 4: Kiem Tra Dong Co Hot-Swap Bulletproof Updater & Don Dep Shortcut Cu ---" -ForegroundColor Yellow

# 4.1 Updater script phai ghi nhat ky chan doan ra vuongtt_updater.log
Assert-True ($opsRsContent -match 'vuongtt_updater\.log') "Updater script phai ghi nhat ky chan doan ra vuongtt_updater.log"

# 4.2 Updater script phai tieu diet cay tien trinh (process tree) de giai phong file lock WebView2
Assert-True ($opsRsContent -match 'taskkill.*\/T' -or $opsRsContent -match 'taskkill.*\/F.*\/PID') "Updater script phai tieu diet cay tien trinh de giai phong file lock"

# 4.3 Updater script phai khoi chay lai TargetExe voi WorkingDirectory
Assert-True ($opsRsContent -match 'Start-Process.*-WorkingDirectory' -or $opsRsContent -match 'WorkingDirectory.*targetDir') "Updater script phai khoi chay lai TargetExe voi WorkingDirectory chuan xac"

# 4.4 Co che tao/cap nhat shortcut phai tu dong don dep shortcut cu 'VUONGTT Tool Pro 2026.lnk'
Assert-True ($opsRsContent -match 'VUONGTT Tool Pro 2026\.lnk') "He thong phai tu dong don dep shortcut cu 'VUONGTT Tool Pro 2026.lnk' tren Desktop"

# 4.5 Updater script phai dong bo sang ProgramData\VUONGTT_Toolkit de chong lech version
Assert-True ($opsRsContent -match 'ProgramData.*VUONGTT_Toolkit.*VUONGTT_Toolkit\.exe') "Updater script phai ho tro dong bo cap nhat vao ProgramData de ngan lech phien ban"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KET QUA: TOAN BO TEST TDD CHO SHORTCUT VA AUTO-UPDATE DAT PASS!" -ForegroundColor Green
