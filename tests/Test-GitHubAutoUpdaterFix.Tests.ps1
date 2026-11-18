$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host ""
Write-Host ">>> KIEM THU TDD: FIX NHO VA TRIET DE NUT CAP NHAT TU GITHUB <<<" -ForegroundColor Cyan
Write-Host ""

$mainRsPath = "E:\toolwindows\src-tauri\src\main.rs"
$opsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
$appJsPath = "E:\toolwindows\src-ui\app.js"
$htmlPath = "E:\toolwindows\src-ui\index.html"

$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)

Write-Host "--- Nhom 1: Frontend UI & Event Binding (index.html & app.js) ---" -ForegroundColor Yellow

# 1.1 btn-header-update phai co onclick triggerManualUpdate
Assert-True ($htmlContent.Contains('id="btn-header-update"') -and $htmlContent.Contains('onclick="triggerManualUpdate()"')) "Nut btn-header-update phai co onclick triggerManualUpdate() truc tiep"

# 1.2 triggerManualUpdate phai tu dong mo Universal Console Log Drawer
Assert-True ($appJsContent.Contains('window.openUniversalLog') -and $appJsContent.Contains('[CÀI ĐẶT GITHUB]') -or $appJsContent.Contains('[CẬP NHẬT GITHUB]')) "triggerManualUpdate phai tu dong bat Console Log Drawer de stream log cap nhat"

# 1.3 triggerManualUpdate phai dong bo/tai lai ke ca khi version trung nhau
Assert-True ($appJsContent.Contains('Đồng Bộ GitHub') -and $appJsContent.Contains('Đang đồng bộ và tải lại bản phát hành mới nhất')) "triggerManualUpdate phai cho phep tai va dong bo lai binary tu GitHub khi nguoi dung bam thu cong"

Write-Host ""
Write-Host "--- Nhom 2: Backend Zero-CDN-Cache & GitHub Commit SHA (system_ops.rs) ---" -ForegroundColor Yellow

# 2.1 check_update phai truy van GitHub Commits API de bypass Fastly Edge Cache
Assert-True ($opsContent.Contains('commits?path=version.json') -and $opsContent.Contains('$latestSha')) "check_update phai truy van GitHub API lay SHA moi nhat de chong CDN stale cache"

# 2.2 apply_update phai truy van GitHub Commits API lay SHA cho file VUONGTT_Toolkit.exe
Assert-True ($opsContent.Contains('commits?path=VUONGTT_Toolkit.exe') -and $opsContent.Contains('$latestSha')) "apply_update phai truy van GitHub API lay SHA file exe truc tiep"

Write-Host ""
Write-Host "--- Nhom 3: Backend Detached Runner Khong Bi Crash (system_ops.rs) ---" -ForegroundColor Yellow

# 3.1 apply_update khong duoc chua ProcessStartInfo Verb=RunAs bi loi Win32Exception
Assert-True (-not ($opsContent.Contains('$psi.Verb = "RunAs"'))) "apply_update khong duoc dung ProcessStartInfo Verb=RunAs vi bi Windows tu choi voi CreateNoWindow"

# 3.2 apply_update khong duoc dung timeout /t 1 /nobreak >nul bi loi Input redirection
Assert-True (-not ($opsContent.Contains('timeout /t 1 /nobreak >nul'))) "apply_update khong duoc dung timeout.exe gay crash Input redirection"

# 3.3 apply_update phai dung Start-Process khoi chay powershell runner ngam doc lap
Assert-True ($opsContent.Contains('vuongtt_update_runner.ps1') -and $opsContent.Contains('Start-Process -FilePath "powershell.exe"')) "apply_update phai dung PowerShell runner doc lap chay ngam"

# 3.4 runner phai co vong lap thu lai 25 lan cho nhả file lock
Assert-True ($opsContent.Contains('$i -lt 25') -and $opsContent.Contains('Start-Sleep -Milliseconds 400')) "runner phai co vong lap thu lai 25 lan de sao chep binary an toan"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "KET QUA: TAT CA CAC MUC KIEM THU CAP NHAT GITHUB PASSED" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host ""
