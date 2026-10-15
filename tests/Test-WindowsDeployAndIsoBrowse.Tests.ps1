# =========================================================================
#   KIEM THU TDD: CHUC NANG CAI WIN & BYPASS WINDOWS (ONLINE / IN-PLACE DEPLOY)
# =========================================================================
$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host "`n>>> KIEM THU TOAN DIEN CHUC NANG CAI WIN & DUYET ISO (TDD) <<<`n" -ForegroundColor Cyan

$opsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
$htmlPath = "E:\toolwindows\src-ui\index.html"
$appJsPath = "E:\toolwindows\src-ui\app.js"

$opsContent = Get-Content -Path $opsPath -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8

Write-Host "--- Nhom 1: Backend Rust Xu Ly Cai Win & Mount ISO (system_ops.rs) ---" -ForegroundColor Yellow

# 1.1 system_ops.rs phai co xu ly action start_win_deploy hoac deploy_windows
Assert-True ($opsContent -match 'start_win_deploy' -or $opsContent -match 'deploy_windows' -or $opsContent -match 'cai_win_deploy') "system_ops.rs phai co action thuc thi Cai Win thuc te"

# 1.2 system_ops.rs phai co logic Mount ISO thuc te (Mount-DiskImage)
Assert-True ($opsContent -match 'Mount-DiskImage' -and $opsContent -match 'setup\.exe') "system_ops.rs phai chua logic Mount-DiskImage va tim file setup.exe"

# 1.3 system_ops.rs phai co co che Bypass TPM / SecureBoot / CPU / MoSetup khi cai Win
Assert-True ($opsContent -match 'AllowUpgradesWithUnsupportedTPMOrCPU' -or $opsContent -match 'BypassTPMCheck') "system_ops.rs phai chua co che Registry Bypass truoc khi chay setup.exe"

# 1.4 system_ops.rs phai co action browse_iso mo hop thoai chon file ISO
Assert-True ($opsContent -match 'browse_iso' -or ($opsContent -match 'OpenFileDialog' -and $opsContent -match '\.iso')) "system_ops.rs phai co action browse_iso de mo OpenFileDialog chon tep ISO"

# 1.5 system_ops.rs phai co action check_disk_partitions
Assert-True ($opsContent -match 'check_disk_partitions' -or $opsContent -match 'pre_check_disk') "system_ops.rs phai co action kiem tra phan vung o dia"

Write-Host "`n--- Nhom 2: Frontend UI & Tuong Tac Thuc Te (index.html & app.js) ---" -ForegroundColor Yellow

# 2.1 index.html khong duoc chua doan alert gia lap timeout
Assert-True (-not ($htmlContent -match 'alert\(''Đã chuẩn bị hoàn tất phân vùng DirectEFI!')) "index.html KHONG duoc chua alert gia lap khoi tao WinPE"

# 2.2 Nhan nut btn-start-deploy phai kich hoat goi IPC backend invokeRust
Assert-True ($htmlContent -match 'startWinDeploy' -or $appJsContent -match 'startWinDeploy' -or $htmlContent -match 'run_system_action.*start_win_deploy') "btn-start-deploy phai goi lenh backend cai win thuc te"

# 2.3 Nhan nut btn-browse-iso phai goi backend browse_iso de chon file ISO that
Assert-True ($htmlContent -match 'browseIsoFile' -or $appJsContent -match 'browseIsoFile' -or $htmlContent -match 'browse_iso') "btn-browse-iso phai cho phep mo FileDialog that de chon ISO"

# 2.4 app.js phai loai tru btn-start-deploy, btn-browse-iso, btn-pre-check khoi catch-all listener
Assert-True ($appJsContent -match 'btn-start-deploy' -and $appJsContent -match 'btn-browse-iso') "app.js phai loai tru cac nut cua view-win-deploy khoi generic listener"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KET QUA: KIEM THU TDD CAI WIN PASSED" -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green
