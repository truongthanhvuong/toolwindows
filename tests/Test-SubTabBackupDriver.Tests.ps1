# =========================================================================
# TEST SUITE: KIEM THU SUB-TAB SAO LUU WIN / DRIVER & SUB-NAVIGATION VIEW 02
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

Write-Host "`n>>> KIỂM THỬ TDD: SUB-TAB SAO LƯU WIN / DRIVER & ĐIỀU HƯỚNG VIEW 02 <<<`n" -ForegroundColor Cyan

$htmlPath = "src-ui\index.html"
$appJsPath = "src-ui\app.js"

Assert-True (Test-Path $htmlPath) "Tệp index.html phải tồn tại"
Assert-True (Test-Path $appJsPath) "Tệp app.js phải tồn tại"

$htmlContent = Get-Content -Raw -Encoding UTF8 $htmlPath
$appJsContent = Get-Content -Raw -Encoding UTF8 $appJsPath

Write-Host "--- Nhóm 1: Kiểm Tra Cấu Trúc Sub-tab Trong View 02 (Cài Win Bypass) ---" -ForegroundColor Yellow

# 1.1 Nút Sao Lưu Win / Driver phải có ID hoặc handler kết nối đến driver backup
Assert-True ($htmlContent -match 'tab-deploy-backup-driver' -or $htmlContent -match 'driver-backup-vault') "Nút Sao Lưu Win / Driver phải có id tab-deploy-backup-driver hoặc gắn kết nối rõ ràng"

# 1.2 Khối Sao Lưu & Xuất Driver Tĩnh trong view-tech-driver phải có id driver-backup-vault để cuộn tới
Assert-True ($htmlContent -match 'id="driver-backup-vault"' -or $htmlContent -match "id='driver-backup-vault'") "Khối Driver Backup Vault trong view-tech-driver phải có id 'driver-backup-vault'"

# 1.3 Nút Kích Hoạt HWID và Tắt BitLocker phải có ID rõ ràng
Assert-True ($htmlContent -match 'tab-deploy-hwid') "Nút Kích Hoạt HWID phải có id tab-deploy-hwid"
Assert-True ($htmlContent -match 'tab-deploy-bitlocker') "Nút Tắt BitLocker phải có id tab-deploy-bitlocker"

Write-Host "`n--- Nhóm 2: Kiểm Tra Cơ Chế SPA Router & Alias An Toàn Trong app.js ---" -ForegroundColor Yellow

# 2.1 switchView phải có cơ chế Alias an toàn cho view-win-activate -> view-hwid-act
Assert-True ($appJsContent -match 'view-win-activate' -and $appJsContent -match 'view-hwid-act') "switchView phải có alias hỗ trợ view-win-activate chuyển sang view-hwid-act"

# 2.2 switchView phải hỗ trợ focus/cuộn mượt đến phần tử mục tiêu (focusElementId)
Assert-True ($appJsContent -match 'focusElementId' -or $appJsContent -match 'scrollIntoView') "switchView phải hỗ trợ tham số focusElementId để cuộn trực tiếp đến khối tác vụ"

# 2.3 subTabRouteMap phải chứa ánh xạ cho 'Sao Lưu Win / Driver' và 'Tắt BitLocker'
Assert-True ($appJsContent -match 'driver-backup-vault' -and $appJsContent -match 'subTabRouteMap') "subTabRouteMap phải chứa định tuyến cho Sao Lưu Win / Driver"

# 2.4 app.js phải có controller khởi tạo các sub-tab trong View 02
Assert-True ($appJsContent -match 'initDeploySubTabs') "app.js phải có hàm initDeploySubTabs điều khiển các sub-tab"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KẾT QUẢ: TOÀN BỘ TEST TDD CHO SUB-TAB SAO LƯU WIN / DRIVER ĐẠT PASS!" -ForegroundColor Green
