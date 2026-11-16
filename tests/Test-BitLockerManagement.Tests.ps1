# =========================================================================
#   KIEM THU TDD: QUAN TRI BITLOCKER (GATE 4 / MILESTONE 4 FEATURE 1)
#   tests/Test-BitLockerManagement.Tests.ps1
# =========================================================================
$ErrorActionPreference = "Stop"

$script:testsPassed = 0
$script:testsFailed = 0

function Assert-True([bool]$condition, [string]$message) {
    if ($condition) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:testsFailed++
        throw "Assertion Failed: $message"
    }
}

Write-Host "`n>>> KIEM THU TDD: PHAN HE QUAN TRI MA HOA O DIA BITLOCKER <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$htmlPath = Join-Path $projectRoot "src-ui\index.html"

Assert-True (Test-Path $opsPath) "Tep system_ops.rs phai ton tai"
Assert-True (Test-Path $appJsPath) "Tep app.js phai ton tai"
Assert-True (Test-Path $htmlPath) "Tep index.html phai ton tai"

$opsContent = Get-Content -Path $opsPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8

Write-Host "--- Nhom 1: Kiem Tra Giao Dien UI (index.html) ---" -ForegroundColor Yellow

# 1.1 Sidebar Navigation Item 19
Assert-True ($htmlContent -match 'data-target="view-bitlocker-mgmt"') "Sidebar phai co muc dieu huong data-target='view-bitlocker-mgmt'"

# 1.2 View Container
Assert-True ($htmlContent -match 'id="view-bitlocker-mgmt"') "index.html phai co View container id='view-bitlocker-mgmt'"

# 1.3 Header & Control Panel Buttons
Assert-True ($htmlContent -match 'id="btn-bitlocker-refresh"') "View BitLocker phai co nut lam moi id='btn-bitlocker-refresh'"
Assert-True ($htmlContent -match 'id="btn-bitlocker-open-cpl"') "View BitLocker phai co nut mo Control Panel id='btn-bitlocker-open-cpl'"

# 1.4 Summary Cards
Assert-True ($htmlContent -match 'id="bitlocker-summary-status"') "View BitLocker phai co the tong quan id='bitlocker-summary-status'"
Assert-True ($htmlContent -match 'id="bitlocker-summary-c"') "View BitLocker phai co the o he thong id='bitlocker-summary-c'"
Assert-True ($htmlContent -match 'id="bitlocker-summary-keys"') "View BitLocker phai co the recovery key id='bitlocker-summary-keys'"

# 1.5 Drives Table
Assert-True ($htmlContent -match 'id="table-bitlocker-drives"') "View BitLocker phai co bang phan vung id='table-bitlocker-drives'"
Assert-True ($htmlContent -match 'id="bitlocker-drives-body"') "Bang BitLocker phai co tbody id='bitlocker-drives-body'"
Assert-True ($htmlContent -match 'id="bitlocker-drives-count"') "Bang BitLocker phai co badge dem id='bitlocker-drives-count'"

# 1.6 Interactive Control Form
Assert-True ($htmlContent -match 'id="select-bitlocker-target-drive"') "Khau dieu khien phai co dropdown id='select-bitlocker-target-drive'"
Assert-True ($htmlContent -match 'id="input-bitlocker-password"') "Khau dieu khien phai co o nhap id='input-bitlocker-password'"
Assert-True ($htmlContent -match 'id="input-bitlocker-recovery-key"') "Khau dieu khien phai co o nhap id='input-bitlocker-recovery-key'"

# 1.7 Action Buttons
Assert-True ($htmlContent -match 'id="btn-bitlocker-enable"') "View BitLocker phai co nut Bat id='btn-bitlocker-enable'"
Assert-True ($htmlContent -match 'id="btn-bitlocker-disable"') "View BitLocker phai co nut Tat id='btn-bitlocker-disable'"
Assert-True ($htmlContent -match 'id="btn-bitlocker-unlock"') "View BitLocker phai co nut Mo Khoa id='btn-bitlocker-unlock'"
Assert-True ($htmlContent -match 'id="btn-bitlocker-backup-key"') "View BitLocker phai co nut Sao Luu Khoa id='btn-bitlocker-backup-key'"
Assert-True ($htmlContent -match 'id="btn-bitlocker-suspend"') "View BitLocker phai co nut Tam Dung id='btn-bitlocker-suspend'"
Assert-True ($htmlContent -match 'id="btn-bitlocker-resume"') "View BitLocker phai co nut Tiep Tuc id='btn-bitlocker-resume'"

# 1.8 Real-time Terminal Log Console
Assert-True ($htmlContent -match 'id="bitlocker-action-output"') "View BitLocker phai co man hinh console id='bitlocker-action-output'"
Assert-True ($htmlContent -match 'id="btn-bitlocker-clear-log"') "View BitLocker phai co nut xoa log id='btn-bitlocker-clear-log'"

# 1.9 Bao ton nut Subtab BitLocker tren View Cai Windows
Assert-True ($htmlContent -match 'tab-deploy-bitlocker') "Phai bao ton nut id='tab-deploy-bitlocker' tren View Cai Windows"
Assert-True ($htmlContent -match 'cb-deploy-disable-bitlocker') "Phai bao ton checkbox id='cb-deploy-disable-bitlocker'"

Write-Host "`n--- Nhom 2: Kiem Tra Controller Frontend (app.js) ---" -ForegroundColor Yellow

# 2.1 Router Alias & Navigation Mapping
Assert-True ($appJsContent -match 'view-disk-bitlocker.*view-bitlocker-mgmt') "switchView phai co alias chuyen view-disk-bitlocker sang view-bitlocker-mgmt"
Assert-True ($appJsContent -match 'target:\s*[\x22\x27]view-bitlocker-mgmt[\x22\x27]') "subTabRouteMap phai co target view-bitlocker-mgmt"
Assert-True ($appJsContent -match 'match:\s*[\x22\x27]BitLocker[\x22\x27],\s*target:\s*[\x22\x27]view-bitlocker-mgmt[\x22\x27]') "subTabRouteMap phai anh xa 'BitLocker' sang view-bitlocker-mgmt"

# 2.2 Controller Function Definition & Export
Assert-True ($appJsContent -match 'function\s+initBitLockerController\s*\(') "app.js phai dinh nghia ham initBitLockerController"
Assert-True ($appJsContent -match 'window\.initBitLockerController\s*=') "app.js phai export window.initBitLockerController"

# 2.3 DOMContentLoaded Wiring
Assert-True ($appJsContent -match 'initBitLockerController\s*\(\s*\);') "DOMContentLoaded phai goi initBitLockerController()"

# 2.4 Quick Actions & IPC Action Calls
Assert-True ($appJsContent -match 'quickBitLockerAction') "app.js phai ho tro ham thao tac nhanh quickBitLockerAction"
Assert-True ($appJsContent -match 'get_bitlocker_status') "app.js phai goi action 'get_bitlocker_status'"
Assert-True ($appJsContent -match 'enable_bitlocker') "app.js phai goi action 'enable_bitlocker'"
Assert-True ($appJsContent -match 'disable_bitlocker') "app.js phai goi action 'disable_bitlocker'"
Assert-True ($appJsContent -match 'unlock_bitlocker') "app.js phai goi action 'unlock_bitlocker'"
Assert-True ($appJsContent -match 'get_bitlocker_key') "app.js phai goi action 'get_bitlocker_key'"
Assert-True ($appJsContent -match 'suspend_bitlocker') "app.js phai goi action 'suspend_bitlocker'"
Assert-True ($appJsContent -match 'resume_bitlocker') "app.js phai goi action 'resume_bitlocker'"

Write-Host "`n--- Nhom 3: Kiem Tra Backend Rust (system_ops.rs) ---" -ForegroundColor Yellow

# 3.1 Backend Actions Handling
Assert-True ($opsContent -match 'act == "get_bitlocker_status"') "system_ops.rs phai ho tro action 'get_bitlocker_status'"
Assert-True ($opsContent -match 'act == "enable_bitlocker"') "system_ops.rs phai ho tro action 'enable_bitlocker'"
Assert-True ($opsContent -match 'act == "disable_bitlocker"') "system_ops.rs phai ho tro action 'disable_bitlocker'"
Assert-True ($opsContent -match 'act == "unlock_bitlocker"') "system_ops.rs phai ho tro action 'unlock_bitlocker'"
Assert-True ($opsContent -match 'act == "get_bitlocker_key"') "system_ops.rs phai ho tro action 'get_bitlocker_key'"
Assert-True ($opsContent -match 'act == "suspend_bitlocker"') "system_ops.rs phai ho tro action 'suspend_bitlocker'"
Assert-True ($opsContent -match 'act == "resume_bitlocker"') "system_ops.rs phai ho tro action 'resume_bitlocker'"
Assert-True ($opsContent -match 'act == "open_bitlocker_cpl"') "system_ops.rs phai ho tro action 'open_bitlocker_cpl'"

# 3.2 Win32 / PowerShell Underlying Tooling
Assert-True ($opsContent -match 'manage-bde\s+-status') "Backend phai su dung manage-bde -status hoac Get-BitLockerVolume"
Assert-True ($opsContent -match 'manage-bde\s+-off') "Backend phai su dung manage-bde -off de tat ma hoa"
Assert-True ($opsContent -match 'manage-bde\s+-unlock') "Backend phai su dung manage-bde -unlock de mo khoa phan vung"
Assert-True ($opsContent -match 'manage-bde\s+-protectors') "Backend phai su dung manage-bde -protectors quan ly key & pause"

Write-Host "`n--- Nhom 4: Kiem Tra Tinh Toan Ven Khong Hoi Quy ---" -ForegroundColor Yellow

# 4.1 So luong Views khong bi mat mat
$viewMatches = ([regex]::Matches($htmlContent, '<div\s+id=[\x22\x27]view-[a-z0-9_-]+[\x22\x27]')).Count
Assert-True ($viewMatches -ge 20) "He thong phai bao ton day du tat ca cac View cu (Hien tai co $viewMatches views >= 20)"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KET QUA: $script:testsPassed PASS / $script:testsFailed FAIL - TAT CA TEST BITLOCKER PASSED 100%!" -ForegroundColor Green
