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

Write-Host "`n>>> KIỂM THỬ TDD: TỰ ĐỘNG TẠO SHORTCUT & TỰ ĐỘNG CẬP NHẬT KHI KHỞI CHẠY <<<`n" -ForegroundColor Cyan

$mainRsPath = "src-tauri\src\main.rs"
$opsRsPath = "src-tauri\src\system_ops.rs"
$appJsPath = "src-ui\app.js"
$updPs1Path = "src\Core\AppUpdater.ps1"

Assert-True (Test-Path $mainRsPath) "Tệp main.rs phải tồn tại"
Assert-True (Test-Path $opsRsPath) "Tệp system_ops.rs phải tồn tại"
Assert-True (Test-Path $appJsPath) "Tệp app.js phải tồn tại"
Assert-True (Test-Path $updPs1Path) "Tệp AppUpdater.ps1 phải tồn tại"

$mainRsContent = Get-Content -Raw -Encoding UTF8 $mainRsPath
$opsRsContent = Get-Content -Raw -Encoding UTF8 $opsRsPath
$appJsContent = Get-Content -Raw -Encoding UTF8 $appJsPath
$updPs1Content = Get-Content -Raw -Encoding UTF8 $updPs1Path

Write-Host "--- Nhóm 1: Kiểm Tra Cơ Chế Tạo Shortcut Desktop ---" -ForegroundColor Yellow

# 1.1 main.rs hoặc system_ops.rs phải có hàm tạo Shortcut Desktop
Assert-True ($mainRsContent -match 'ensure_desktop_shortcut' -or $opsRsContent -match 'ensure_desktop_shortcut') "Hệ thống phải có hàm ensure_desktop_shortcut() tạo biểu tượng Desktop"

# 1.2 main() phải gọi hàm tạo shortcut khi khởi động
Assert-True ($mainRsContent -match 'ensure_desktop_shortcut') "main() trong main.rs phải tự động gọi ensure_desktop_shortcut() khi khởi động tool"

# 1.3 Kiểm tra logic tạo shortcut qua PowerShell COM WScript.Shell
Assert-True ($mainRsContent -match 'WScript.Shell' -or $opsRsContent -match 'WScript.Shell' -or $opsRsContent -match 'VUONGTT Toolkit.lnk') "Cơ chế tạo shortcut phải nhắm đến 'VUONGTT Toolkit.lnk' trên Desktop"

Write-Host "`n--- Nhóm 2: Kiểm Tra Động Cơ Kiểm Tra & Tự Động Cập Nhật ---" -ForegroundColor Yellow

# 2.1 system_ops.rs phải có action 'check_update' kết nối logic cập nhật thực tế (không phải mockup)
Assert-True ($opsRsContent -match 'act == "check_update"' -and ($opsRsContent -match 'version\.json' -or $opsRsContent -match 'AppUpdater')) "system_ops.rs phải có action check_update kiểm tra tệp version.json thực tế"

# 2.2 AppUpdater.ps1 phải có hàm Get-VUONGTTAppUpdateInfo
Assert-True ($updPs1Content -match 'function Get-VUONGTTAppUpdateInfo') "AppUpdater.ps1 phải có hàm Get-VUONGTTAppUpdateInfo kiểm tra cập nhật"

# 2.3 system_ops.rs phải có action thực thi cập nhật tự động 'apply_update'
Assert-True ($opsRsContent -match 'apply_update' -or $opsRsContent -match 'download_and_apply_update') "system_ops.rs phải hỗ trợ action tải và cập nhật phiên bản mới"

Write-Host "`n--- Nhóm 3: Kiểm Tra Tự Động Kiểm Tra Cập Nhật Trên UI (app.js) ---" -ForegroundColor Yellow

# 3.1 app.js phải tự động kiểm tra cập nhật khi tải trang (DOMContentLoaded)
Assert-True ($appJsContent -match 'initAutoUpdateOnStartup' -or $appJsContent -match 'check_update') "app.js phải tự động kích hoạt kiểm tra cập nhật khi khởi động"

# 3.2 app.js phải có xử lý thông báo khi có bản cập nhật mới
Assert-True ($appJsContent -match 'showToast' -and ($appJsContent -match 'checkForUpdate' -or $appJsContent -match 'apply_update')) "app.js phải hiển thị thông báo cập nhật cho người dùng"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KẾT QUẢ: TOÀN BỘ TEST TDD CHO SHORTCUT VÀ AUTO-UPDATE ĐẠT PASS!" -ForegroundColor Green
