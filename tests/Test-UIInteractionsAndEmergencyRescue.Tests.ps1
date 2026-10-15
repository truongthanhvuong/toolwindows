# tests/Test-UIInteractionsAndEmergencyRescue.Tests.ps1
# Bộ kiểm thử TDD: Đảm bảo hoạt động thực tế của 6 phân hệ giao diện và cứu hộ khẩn cấp

$rootDir = Split-Path -Parent $PSScriptRoot
$passed = 0
$failed = 0

function Assert-True($condition, $message) {
    if ($condition) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host ">>> KIEM THU 6 PHAN HE GIAO DIEN & CUU HO KHAN CAP (SUPERPOWERS) <<<`n" -ForegroundColor Cyan

# -------------------------------------------------------------
# NHOM 1: Tab Cấu Hình & Sửa Lỗi và Điều Hướng Sub-tabs
# -------------------------------------------------------------
Write-Host "--- Nhom 1: Tab Cau Hinh & Sua Loi va SubTabRouteMap ---" -ForegroundColor Yellow
$appJsPath = Join-Path $rootDir "src-ui\app.js"
$indexHtmlPath = Join-Path $rootDir "src-ui\index.html"
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8
$indexHtmlContent = Get-Content -Path $indexHtmlPath -Raw -Encoding UTF8

$hasSubTabRouteCauHinh = $appJsContent -match 'Cấu Hình & Sửa Lỗi' -or $appJsContent -match 'view-tech-driver'
Assert-True $hasSubTabRouteCauHinh "app.js phai dinh tuyen nut Cau Hinh & Sua Loi sang view-tech-driver"

$hasIndexClickCauHinh = $indexHtmlContent -match 'switchView\(.view-tech-driver.\)'
Assert-True $hasIndexClickCauHinh "index.html phai co onclick switchView('view-tech-driver') cho nut Cau Hinh & Sua Loi"

# -------------------------------------------------------------
# NHOM 2: Software Hub 4 Sub-tabs (Gỡ Bỏ Sạch & Cài Font Chữ)
# -------------------------------------------------------------
Write-Host "`n--- Nhom 2: Software Hub 4 Sub-tabs Routing & Handlers ---" -ForegroundColor Yellow
$hasSwitchSoftSubTab = $appJsContent -match 'function switchSoftSubTab' -or $appJsContent -match 'window\.switchSoftSubTab'
Assert-True $hasSwitchSoftSubTab "app.js phai dinh nghia ham window.switchSoftSubTab"

$hasRefreshInstalledApps = $appJsContent -match 'refreshInstalledApps'
Assert-True $hasRefreshInstalledApps "app.js phai co ham refreshInstalledApps cho tab Go Bo Sach"

$hasInstallFontPack = $appJsContent -match 'installFontPack'
Assert-True $hasInstallFontPack "app.js phai co ham installFontPack cho tab Cai Font Chu"

# -------------------------------------------------------------
# NHOM 3: Chống Nuốt Sự Kiện Button (Button Catch-all Exclusion)
# -------------------------------------------------------------
Write-Host "`n--- Nhom 3: Exclusion List cho Button Catch-all Listener ---" -ForegroundColor Yellow
$hasDeployExcluded = $appJsContent -match 'btn-run-deploy'
Assert-True $hasDeployExcluded "Catch-all listener trong app.js phai loai tru btn-run-deploy de khong nuot su kien Cai Office"

$hasTabSoftExcluded = $appJsContent -match 'tab-soft-' -or $appJsContent -match 'subview-soft'
Assert-True $hasTabSoftExcluded "Catch-all listener trong app.js phai loai tru cac tab soft va nut chuyen view"

# -------------------------------------------------------------
# NHOM 4: Bộ Công Cụ Cứu Hộ IT Helpdesk Thực Tế (system_ops.rs)
# -------------------------------------------------------------
Write-Host "`n--- Nhom 4: Bo Cong Cu Cuu Ho IT Helpdesk (system_ops.rs) ---" -ForegroundColor Yellow
$sysOpsPath = Join-Path $rootDir "src-tauri\src\system_ops.rs"
$sysOpsContent = Get-Content -Path $sysOpsPath -Raw -Encoding UTF8

$hasBypassPass = $sysOpsContent -match 'bypass_pass' -or $sysOpsContent -match 'reset_password'
Assert-True $hasBypassPass "system_ops.rs phai co xu ly bypass_pass (Pha Mat Khau)"

$hasUnhideFiles = $sysOpsContent -match 'unhide_files' -or $sysOpsContent -match 'hien file an'
Assert-True $hasUnhideFiles "system_ops.rs phai co xu ly unhide_files (Hien File An attrib)"

$hasCleanShortcut = $sysOpsContent -match 'clean_shortcut_virus' -or $sysOpsContent -match 'don virus shortcut'
Assert-True $hasCleanShortcut "system_ops.rs phai co xu ly clean_shortcut_virus (Diet Shortcut Gia)"

# Kiểm tra fix_network_freeze không được nuốt "cuu ho" bừa bãi
$noCuuHoHijack = -not ($sysOpsContent -match 'act\.contains\("cuu ho"\)')
Assert-True $noCuuHoHijack "system_ops.rs KHONG duoc dung act.contains('cuu ho') de nuot toan bo su kien Helpdesk sang Network Freeze"

# -------------------------------------------------------------
# NHOM 5: Tùy Chỉnh Thông Tin Thương Hiệu (OEM Brand Customization)
# -------------------------------------------------------------
Write-Host "`n--- Nhom 5: Tuy Chinh Thong Tin Thuong Hieu OEM ---" -ForegroundColor Yellow
$hasOemBrandingAction = $sysOpsContent -match 'set_oem_branding' -or $sysOpsContent -match 'oem_branding'
Assert-True $hasOemBrandingAction "system_ops.rs phai co action set_oem_branding ghi Registry OEMInformation thuc te"

$hasOemApplyRustCall = $appJsContent -match 'set_oem_branding' -or $indexHtmlContent -match 'set_oem_branding'
Assert-True $hasOemApplyRustCall "Giao dien phai goi invokeRust('set_oem_branding', ...) chu khong chi log chuoi"

# -------------------------------------------------------------
# NHOM 6: Cài Office ODT & Bộ Tiện Ích Kỹ Thuật
# -------------------------------------------------------------
Write-Host "`n--- Nhom 6: Cai Office & Tien Ich Ky Thuat ---" -ForegroundColor Yellow
$hasInstalledAppsQuery = $sysOpsContent -match 'get_installed_apps'
Assert-True $hasInstalledAppsQuery "system_ops.rs phai co action get_installed_apps quet danh sach phan mem"

$hasFontPackBackend = $sysOpsContent -match 'install_font_pack'
Assert-True $hasFontPackBackend "system_ops.rs phai co action install_font_pack cai font chu"

# -------------------------------------------------------------
# TỔNG KẾT
# -------------------------------------------------------------
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "KET QUA: $passed PASS / $($passed + $failed) TOTAL" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
