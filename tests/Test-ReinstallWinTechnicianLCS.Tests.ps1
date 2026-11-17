# =========================================================================
#   KIEM THU TDD: REINSTALL WINDOWS TECHNICIAN (CHUAN WINTOHDD / LCS-AUTO WIN)
# =========================================================================
$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host "`n>>> KIEM THU TDD: REINSTALL WINDOWS TECHNICIAN CHUAN WINTOHDD <<<`n" -ForegroundColor Cyan

$opsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
$htmlPath = "E:\toolwindows\src-ui\index.html"
$appJsPath = "E:\toolwindows\src-ui\app.js"

$opsContent = Get-Content -Path $opsPath -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8

Write-Host "--- Nhom 1: Giao Dien Chinh (3 Bento Hero Cards & Footer Bar) ---" -ForegroundColor Yellow

# 1.1 Tieu de chuan Reinstall Windows Technician
Assert-True ($htmlContent -match "VUONGTT Reinstall Windows Technician") "index.html phai co tieu de VUONGTT Reinstall Windows Technician"

# 1.2 Bento Card 1: Reinstall Windows
Assert-True ($htmlContent -match "Reinstall Windows" -and $htmlContent -match "openReinstallWinModal") "Card 1 phai co nhan Reinstall Windows va goi openReinstallWinModal"

# 1.3 Bento Card 2: Tai ISO / Dan Link
Assert-True ($htmlContent -match "Tải ISO / Dán Link" -and $htmlContent -match "openIsoDownloadModal") "Card 2 phai co nhan Tai ISO / Dan Link va goi openIsoDownloadModal"

# 1.4 Bento Card 3: Tuy Chon & Phan Mem
Assert-True ($htmlContent -match "Tùy Chọn &amp; Phần Mềm" -and $htmlContent -match "openPostInstallModal") "Card 3 phai co nhan Tuy Chon & Phan Mem va goi openPostInstallModal"

# 1.5 Footer Info Bar (Firmware, RAM/TPM, CPU/OS, Disk/Buffer)
Assert-True ($htmlContent -match 'id="deploy-boot-mode"' -and $htmlContent -match 'id="deploy-ram-tpm"') "Footer phai co boot-mode va ram-tpm"
Assert-True ($htmlContent -match 'id="deploy-cpu-os"' -and $htmlContent -match 'id="deploy-disk-target"') "Footer phai co cpu-os va disk-target"

Write-Host "`n--- Nhom 2: Modal Tuy Chon Toi Uu & Phan Mem (2 Tabs) ---" -ForegroundColor Yellow

# 2.1 Modal container
Assert-True ($htmlContent -match 'id="modal-post-install-options"') "Phai co modal-post-install-options"

# 2.2 2 Tabs Optimizer & Softwares
Assert-True ($htmlContent -match 'id="tab-btn-win-opt"' -and $htmlContent -match 'id="tab-btn-softwares"') "Modal phai co 2 tab win-opt va softwares"
Assert-True ($appJsContent -match 'switchPostInstallTab') "app.js phai co controller switchPostInstallTab"

# 2.3 Checbox Optimizer tieu bieu
Assert-True ($htmlContent -match 'id="opt-net35"' -and $htmlContent -match 'id="opt-legacy"') "Tab Optimizer phai co .NET 3.5 va Legacy"
Assert-True ($htmlContent -match 'id="opt-smb"' -and $htmlContent -match 'id="opt-show-thispc"') "Tab Optimizer phai co SMB va This PC Desktop"
Assert-True ($htmlContent -match 'id="opt-disable-cortana"' -and $htmlContent -match 'id="opt-disable-copilot"') "Tab Optimizer phai co tat Cortana va Copilot"
Assert-True ($htmlContent -match 'id="opt-disable-uac"' -and $htmlContent -match 'id="opt-disable-bitlocker"') "Tab Optimizer phai co tat UAC va BitLocker"

# 2.4 Checkbox Softwares tieu bieu
Assert-True ($htmlContent -match 'id="soft-rustdesk"' -and $htmlContent -match 'id="soft-chrome"') "Tab Softwares phai co RustDesk va Chrome"
Assert-True ($htmlContent -match 'id="soft-evkey"' -and $htmlContent -match 'id="soft-winrar"') "Tab Softwares phai co EVKey va WinRAR"
Assert-True ($htmlContent -match 'id="soft-vcredist"' -and $htmlContent -match 'id="soft-office"') "Tab Softwares phai co VCRedist va Office"

# 2.5 Khung Thong Tin May & Remote
Assert-True ($htmlContent -match 'id="cfg-pc-name"' -and $htmlContent -match 'id="cfg-user-name"') "Phai co truong cau hinh pc-name va user-name"
Assert-True ($htmlContent -match 'id="cfg-remote-pass"' -and $htmlContent -match 'id="cfg-auto-reboot"') "Phai co truong cau hinh remote-pass va auto-reboot"
Assert-True ($appJsContent -match 'savePostInstallOptions') "app.js phai co ham savePostInstallOptions"

Write-Host "`n--- Nhom 3: Modal Tai ISO & Backend Rust Handlers ---" -ForegroundColor Yellow

# 3.1 Modal Tai ISO
Assert-True ($htmlContent -match 'id="modal-iso-download"' -and $htmlContent -match 'id="input-direct-iso-url"') "Phai co modal-iso-download va input-direct-iso-url"
Assert-True ($appJsContent -match 'startDirectIsoDownload') "app.js phai co startDirectIsoDownload"

# 3.2 Backend Rust Handlers
Assert-True ($opsContent -match 'save_deploy_post_config') "system_ops.rs phai co handler save_deploy_post_config"
Assert-True ($opsContent -match 'autounattend\.xml') "system_ops.rs phai sinh autounattend.xml tu dong"
Assert-True ($opsContent -match 'download_iso_file') "system_ops.rs phai co handler download_iso_file"
Assert-True ($opsContent -match 'cpu_name' -and $opsContent -match 'ram_total_gb') "detect_win_install_env phai tra ve cpu_name va ram_total_gb"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "TAT CA 18/18 CHECK TDD REINSTALL WINDOWS TECHNICIAN PASSED!" -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green
