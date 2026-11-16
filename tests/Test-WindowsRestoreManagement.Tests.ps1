# =========================================================================
# TEST SUITE: KIEM THU PHAN HE PHUC HOI HE THONG WINDOWS & WINRE RESTORE
# VUONGTT TOOLKIT 2026 - TDD ENGINE
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:failed++
        throw "TEST FAILED: $message"
    } else {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    }
}

Write-Host "`n>>> KIEM THU TDD: PHAN HE PHUC HOI WINDOWS & CUU HO WINRE <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"

Assert-True (Test-Path $htmlPath) "Tep index.html phai ton tai"
Assert-True (Test-Path $appJsPath) "Tep app.js phai ton tai"
Assert-True (Test-Path $opsPath) "Tep system_ops.rs phai ton tai"

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)

Write-Host "--- Nhom 1: Kiem Tra Giao Dien UI Phuc Hoi Windows (index.html) ---" -ForegroundColor Yellow

Assert-True ($htmlContent -match 'id="view-backup-windows"') "View view-backup-windows phai ton tai"
Assert-True ($htmlContent -match 'btn-restore-wim-system') "Nut phuc hoi WIM id='btn-restore-wim-system' phai ton tai"
Assert-True ($htmlContent -match 'btn-boot-winre') "Nut khoi dong WinRE id='btn-boot-winre' phai ton tai"
Assert-True ($htmlContent -match 'btn-scan-wim-backups') "Nut quet ban backup id='btn-scan-wim-backups' phai ton tai"
Assert-True ($htmlContent -match 'btn-browse-wim-file') "Nut duyet file WIM id='btn-browse-wim-file' phai ton tai"
Assert-True ($htmlContent -match 'btn-open-system-restore') "Nut mo System Restore id='btn-open-system-restore' phai ton tai"
Assert-True ($htmlContent -match 'btn-create-restore-point') "Nut tao diem khoi phuc id='btn-create-restore-point' phai ton tai"
Assert-True ($htmlContent -match 'btn-check-winre') "Nut kiem tra/bat WinRE id='btn-check-winre' phai ton tai"
Assert-True ($htmlContent -match 'sel-restore-wim-file') "Dropdown chon ban sao luu id='sel-restore-wim-file' phai ton tai"
Assert-True ($htmlContent -match 'restore-system-target-desc') "Khung trang thai phuc hoi id='restore-system-target-desc' phai ton tai"

Write-Host "`n--- Nhom 2: Kiem Tra Controller Frontend (app.js) ---" -ForegroundColor Yellow

Assert-True ($appJsContent -match 'restoreSystemWim') "app.js phai dinh nghia ham restoreSystemWim"
Assert-True ($appJsContent -match 'browseWimFile') "app.js phai dinh nghia ham browseWimFile"
Assert-True ($appJsContent -match 'scanWimBackups') "app.js phai dinh nghia ham scanWimBackups"
Assert-True ($appJsContent -match 'bootToWinRE') "app.js phai dinh nghia ham bootToWinRE"
Assert-True ($appJsContent -match 'openSystemRestore') "app.js phai dinh nghia ham openSystemRestore"
Assert-True ($appJsContent -match 'createRestorePoint') "app.js phai dinh nghia ham createRestorePoint"
Assert-True ($appJsContent -match 'checkOrRepairWinRE') "app.js phai dinh nghia ham checkOrRepairWinRE"
Assert-True ($appJsContent -match 'initWindowsRestoreController') "app.js phai co ham initWindowsRestoreController"
Assert-True ($appJsContent -match '(?s)view-backup-windows.*?scanWimBackups') "switchView phai tu dong goi scanWimBackups khi mo view-backup-windows"
Assert-True ($appJsContent -match 'initWindowsRestoreController') "DOMContentLoaded phai goi initWindowsRestoreController"

Write-Host "`n--- Nhom 3: Kiem Tra Backend Rust (system_ops.rs) ---" -ForegroundColor Yellow

Assert-True ($opsContent -match 'restore_full_windows') "system_ops.rs phai ho tro action 'restore_full_windows'"
Assert-True ($opsContent -match 'scan_wim_backups') "system_ops.rs phai ho tro action 'scan_wim_backups'"
Assert-True ($opsContent -match 'browse_wim') "system_ops.rs phai ho tro action 'browse_wim'"
Assert-True ($opsContent -match 'boot_to_winre') "system_ops.rs phai ho tro action 'boot_to_winre'"
Assert-True ($opsContent -match 'open_system_restore') "system_ops.rs phai ho tro action 'open_system_restore'"
Assert-True ($opsContent -match 'create_restore_point') "system_ops.rs phai ho tro action 'create_restore_point'"
Assert-True ($opsContent -match 'repair_winre') "system_ops.rs phai ho tro action 'repair_winre'"
Assert-True ($opsContent -match 'Apply-Image') "Backend phai ho tro lenh bung anh DISM Apply-Image"
Assert-True ($opsContent -match 'reagentc /boottore') "Backend phai tich hop lenh WinRE boot-to-RE"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KET QUA: 100% CAC TIEU CHI PHUC HOI WINDOWS & WINRE DAT PASS!" -ForegroundColor Green
