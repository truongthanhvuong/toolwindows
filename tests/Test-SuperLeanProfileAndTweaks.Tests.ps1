# =========================================================================
#   KIỂM THỬ TDD: CẤU HÌNH TỐI ƯU SIÊU NHẸ 2026 & BỘ HOÀN TÁC (UNDO ENGINE)
# =========================================================================
$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host "`n>>> KIỂM THỬ TDD: SUPER LEAN PROFILE 2026 & HOÀN TÁC TOÀN DIỆN <<<`n" -ForegroundColor Cyan

$opsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
$psTweaksPath = "E:\toolwindows\src\Core\SystemTweaks.ps1"
$appJsPath = "E:\toolwindows\src-ui\app.js"
$htmlPath = "E:\toolwindows\src-ui\index.html"

Assert-True (Test-Path $opsPath) "Tệp system_ops.rs phải tồn tại"
Assert-True (Test-Path $psTweaksPath) "Tệp SystemTweaks.ps1 phải tồn tại"
Assert-True (Test-Path $appJsPath) "Tệp app.js phải tồn tại"
Assert-True (Test-Path $htmlPath) "Tệp index.html phải tồn tại"

$opsContent = Get-Content -Path $opsPath -Raw -Encoding UTF8
$psContent = Get-Content -Path $psTweaksPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8

Write-Host "--- Nhóm 1: Kiểm Tra Tính An Toàn Bảo Tồn Nguyên Vẹn ---" -ForegroundColor Yellow

# 1.1 Tuyệt đối KHÔNG xóa Edge và WebView2 Runtime
Assert-True (-not ($opsContent -match 'Remove-AppxPackage.*Microsoft\.MicrosoftEdge' -or $psContent -match 'Remove-AppxPackage.*Microsoft\.MicrosoftEdge')) "Tuyệt đối không được gỡ bỏ Microsoft.MicrosoftEdge"
Assert-True (-not ($opsContent -match 'Remove-AppxPackage.*EdgeWebView' -or $psContent -match 'Remove-AppxPackage.*EdgeWebView')) "Tuyệt đối không được gỡ bỏ Microsoft.EdgeWebView"

# 1.2 Tuyệt đối KHÔNG tắt hoặc gỡ bỏ Windows Defender
Assert-True (-not ($opsContent -match 'DisableAntiSpyware.*1' -or $opsContent -match 'Stop-Service\s+WinDefend')) "Tuyệt đối không được tắt Windows Defender Service (WinDefend)"

Write-Host "`n--- Nhóm 2: Kiểm Tra Bộ Action Super Lean & Hoàn Tác (Backend Rust) ---" -ForegroundColor Yellow

# 2.1 Action áp dụng cấu hình siêu nhẹ
Assert-True ($opsContent -match 'apply_super_lean_profile') "system_ops.rs phải hỗ trợ action 'apply_super_lean_profile'"

# 2.2 Action hoàn tác cấu hình siêu nhẹ
Assert-True ($opsContent -match 'revert_super_lean_profile') "system_ops.rs phải hỗ trợ action 'revert_super_lean_profile'"

# 2.3 Action gỡ bỏ 28 bloatware và hoàn tác khôi phục app
Assert-True ($opsContent -match 'purge_bloatware_28_apps' -or $opsContent -match 'purge_bloatware') "system_ops.rs phải có action gỡ bỏ chuyên sâu 28 app rác"
Assert-True ($opsContent -match 'restore_windows_apps') "system_ops.rs phải có action 'restore_windows_apps' để hoàn tác ứng dụng"

# 2.4 Desktop Icons: Apply & Revert
Assert-True ($opsContent -match 'set_desktop_icons_classic') "system_ops.rs phải có action 'set_desktop_icons_classic'"
Assert-True ($opsContent -match 'revert_desktop_icons') "system_ops.rs phải có action 'revert_desktop_icons'"

# 2.5 Control Panel: Icons view & Revert category
Assert-True ($opsContent -match 'set_control_panel_icons') "system_ops.rs phải có action 'set_control_panel_icons'"
Assert-True ($opsContent -match 'revert_control_panel_icons') "system_ops.rs phải có action 'revert_control_panel_icons'"

# 2.6 PrintScreen: Snipping tool & Revert
Assert-True ($opsContent -match 'set_printscreen_snipping_tool') "system_ops.rs phải có action 'set_printscreen_snipping_tool'"
Assert-True ($opsContent -match 'revert_printscreen_snipping_tool') "system_ops.rs phải có action 'revert_printscreen_snipping_tool'"

# 2.7 Copilot & AI: Disable & Re-enable
Assert-True ($opsContent -match 'disable_copilot_ai') "system_ops.rs phải có action 'disable_copilot_ai'"
Assert-True ($opsContent -match 'revert_copilot_ai') "system_ops.rs phải có action 'revert_copilot_ai'"

# 2.8 Fax & Hyper-V: Disable & Re-enable
Assert-True ($opsContent -match 'disable_hyperv_fax') "system_ops.rs phải có action 'disable_hyperv_fax'"
Assert-True ($opsContent -match 'revert_hyperv_fax') "system_ops.rs phải có action 'revert_hyperv_fax'"

# 2.9 Tự động nhận diện bản quyền BIOS (OA3x MSDM)
Assert-True ($opsContent -match 'detect_bios_license' -or $opsContent -match 'OA3xOriginalProductKey') "system_ops.rs phải có action 'detect_bios_license' đọc key từ BIOS"

Write-Host "`n--- Nhóm 3: Kiểm Tra Giao Diện UI & Hoàn Tác (View 04 & View 02) ---" -ForegroundColor Yellow

# 3.1 Card Super Lean Pro trong View 04
Assert-True ($htmlContent -match 'btn-apply-super-lean' -or $htmlContent -match 'btnApplySuperLean') "index.html phải có nút Áp Dụng Cấu Hình Siêu Nhẹ"
Assert-True ($htmlContent -match 'btn-revert-super-lean' -or $htmlContent -match 'btnRevertSuperLean') "index.html phải có nút Hoàn Tác Về Mặc Định"

# 3.2 Banner nhận diện License BIOS trong View 02
Assert-True ($htmlContent -match 'bios-license-card' -or $htmlContent -match 'biosLicenseInfo' -or $htmlContent -match 'banner-bios-license') "View 02 phải có khu vực hiển thị License nhận diện từ BIOS"

# 3.3 Event wiring trong app.js
Assert-True ($appJsContent -match 'apply_super_lean_profile') "app.js phải gọi 'apply_super_lean_profile'"
Assert-True ($appJsContent -match 'revert_super_lean_profile') "app.js phải gọi 'revert_super_lean_profile'"
Assert-True ($appJsContent -match 'detect_bios_license') "app.js phải gọi 'detect_bios_license'"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KẾT QUẢ: TOÀN BỘ TEST TDD CHO TÍNH NĂNG VÀ HOÀN TÁC ĐẠT PASS!" -ForegroundColor Green
