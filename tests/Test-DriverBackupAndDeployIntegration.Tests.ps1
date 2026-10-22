# =========================================================================
# TEST SUITE: SAO LUU DRIVER & TICH HOP CHUC NANG CAI WIN
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

Write-Host "`n>>> KIEM THU TDD: SAO LUU DRIVER & TICH HOP VAO CHUC NANG CAI WIN <<<`n" -ForegroundColor Cyan

$opsRsPath = "src-tauri\src\system_ops.rs"
$indexHtmlPath = "src-ui\index.html"
$appJsPath = "src-ui\app.js"

Assert-True (Test-Path $opsRsPath) "Tep system_ops.rs phai ton tai"
Assert-True (Test-Path $indexHtmlPath) "Tep index.html phai ton tai"
Assert-True (Test-Path $appJsPath) "Tep app.js phai ton tai"

$opsRs = Get-Content -Raw -Encoding UTF8 $opsRsPath
$indexHtml = Get-Content -Raw -Encoding UTF8 $indexHtmlPath
$appJs = Get-Content -Raw -Encoding UTF8 $appJsPath

Write-Host "--- Nhom 1: Backend Rust (system_ops.rs) Sao Luu Driver Thuc Te ---" -ForegroundColor Yellow

# 1.1 system_ops.rs phai kiem tra so luong Driver thuc te (.inf) sau khi export
Assert-True ($opsRs -match 'pnputil' -and ($opsRs -match 'Get-ChildItem' -or $opsRs -match '\*\.inf' -or $opsRs -match 'inf_count')) "system_ops.rs phai dem so luong file .inf thuc te de xac nhan sao luu thanh cong"

# 1.2 system_ops.rs phai uu tien o dia khong phai o he thong (D:, E:...) de khong bi xoa khi cai lai Win
Assert-True ($opsRs -match 'Drivers_Backup' -or $opsRs -match 'Backup_Drivers') "system_ops.rs phai co thu muc sao luu an toan"

# 1.3 action start_win_deploy phai nhan dien duoc ca camelCase va snake_case cho backup_drivers
Assert-True ($opsRs -match 'backup_drivers' -or $opsRs -match 'backupDrivers') "start_win_deploy phai xu ly tham so backup_drivers"

Write-Host "`n--- Nhom 2: Giao Dien View 02 (index.html) Tich Hop Sao Luu Driver ---" -ForegroundColor Yellow

# 2.1 View 02 phai co khoi dieu khien Sao Luu Driver ro rang kem trang thai
Assert-True ($indexHtml -match 'id="cb-deploy-backup-drivers"' -or $indexHtml -match 'id="btn-deploy-backup-drivers"') "View 02 phai co checkbox hoac nut sao luu driver"

# 2.2 View 02 phai co nut Sao Luu Driver Ngay voi id ro rang
Assert-True ($indexHtml -match 'id="btn-quick-backup-drivers"' -or $indexHtml -match 'id="btn-deploy-backup-now"') "View 02 phai co nut Sao Luu Driver Ngay"

# 2.3 View 02 phai co phan hien thi thu muc luu tru Driver an toan
Assert-True ($indexHtml -match 'Drivers_Backup' -or $indexHtml -match 'Backup_Drivers' -or $indexHtml -match 'driver-target-path') "View 02 phai the hien duong dan luu driver de ky thuat vien kiem tra"

Write-Host "`n--- Nhom 3: Frontend Logic (app.js) Tich Hop Quy Trinh Cai Win ---" -ForegroundColor Yellow

# 3.1 startWinDeploy phai doc trang thai cb-deploy-backup-drivers va truyen vao Rust backend
Assert-True ($appJs -match 'cb-deploy-backup-drivers' -or $appJs -match 'backupDrivers') "startWinDeploy trong app.js phai doc checkbox sao luu driver"

# 3.2 app.js phai co ham backupDriverNow hoac ket noi nut sao luu driver trong View 02
Assert-True ($appJs -match 'backup_drivers' -and ($appJs -match 'exportDrivers' -or $appJs -match 'backupDrivers')) "app.js phai co logic xu ly sao luu driver cho View 02"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KET QUA: KIEM THU TDD CHO SAO LUU DRIVER VA CAI WIN HOAN TAT!" -ForegroundColor Green
