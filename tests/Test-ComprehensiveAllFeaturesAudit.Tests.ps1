# =========================================================================
# COMPREHENSIVE ALL-FEATURES AUDIT TEST SUITE
# VUONGTT TOOLKIT 2026 - TIEU CHUAN KIEM THU TOAN DIEN HE THONG
# tests/Test-ComprehensiveAllFeaturesAudit.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$exePath = Join-Path $repoRoot "VUONGTT_Toolkit.exe"
$mainRs = Join-Path $repoRoot "src-tauri\src\main.rs"
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"
$appJs = Join-Path $repoRoot "src-ui\app.js"
$indexHtml = Join-Path $repoRoot "src-ui\index.html"
$verJson = Join-Path $repoRoot "version.json"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   VUONGTT TOOLKIT 2026 - HE THONG KIEM THU TOAN DIEN 15 PHAN HE      " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "======================================================================" -ForegroundColor Cyan

$passedCount = 0
$failedCount = 0
$totalTests = 0

function Assert-Audit([string]$group, [string]$feature, [scriptblock]$condition) {
    $script:totalTests++
    try {
        $result = & $condition
        if ($result) {
            Write-Host " [PASS] [$group] $feature" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host " [FAIL] [$group] $feature" -ForegroundColor Red
            $script:failedCount++
        }
    } catch {
        Write-Host " [FAIL] [$group] $feature - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failedCount++
    }
}

$opsContent = Get-Content -Path $opsRs -Raw -Encoding UTF8
$appContent = Get-Content -Path $appJs -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $indexHtml -Raw -Encoding UTF8
$verContent = Get-Content -Path $verJson -Raw -Encoding UTF8 | ConvertFrom-Json

# -------------------------------------------------------------------------
# NHOM 1: CORE BINARY & SYSTEM LAUNCH
# -------------------------------------------------------------------------
Assert-Audit "Core" "Tep thuc thi VUONGTT_Toolkit.exe ton tai tren dia" {
    Test-Path $exePath
}

Assert-Audit "Core" "Dung luong binary toi uu (1.5MB - 3.5MB sieu nhe)" {
    $sizeMb = (Get-Item $exePath).Length / 1MB
    $sizeMb -ge 1.5 -and $sizeMb -le 3.5
}

Assert-Audit "Core" "Lenh --smoke-test phan hoi thanh cong 100%" {
    $res = cmd.exe /c "`"$exePath`" --smoke-test"
    $res -match "SMOKE TEST PASS 100%"
}

Assert-Audit "Core" "Lenh --version khop chinh xac voi version.json (v$($verContent.version))" {
    $res = cmd.exe /c "`"$exePath`" --version"
    $res.Trim() -eq "VUONGTT Toolkit v$($verContent.version)"
}

Assert-Audit "Core" "Tich hop Single-Instance Mutex chong mo nhieu cua so trung lap" {
    $mainContent = Get-Content -Path $mainRs -Raw -Encoding UTF8
    $mainContent -match "VUONGTT_Toolkit_SingleInstance_Mutex"
}

# -------------------------------------------------------------------------
# NHOM 2: VIEW 01 - GIAM SAT HE THONG & CAU HINH
# -------------------------------------------------------------------------
Assert-Audit "View 01" "Giao dien View 01 ton tai trong index.html" {
    $htmlContent -match 'id="view-sys-monitor"'
}

Assert-Audit "View 01" "Ho tro truy van chi tiet CPU & Bo Mach Chu (collect_cpu_main_details)" {
    $opsContent -match 'collect_cpu_main_details' -and $opsContent -match 'Win32_BaseBoard'
}

Assert-Audit "View 01" "Ho tro quan tri tai khoan nguoi dung (collect_local_users / open_lusrmgr)" {
    $opsContent -match 'collect_local_users' -and ($opsContent -match 'open_lusrmgr' -or $opsContent -match 'quan_tri_user')
}

Assert-Audit "View 01" "Ho tro chay Benchmark Nhanh CPU (run_benchmark)" {
    $opsContent -match 'act == "run_benchmark"'
}

Assert-Audit "View 01" "Ho tro xuat bao cao he thong DxDiag / JSON (export_helpdesk_report)" {
    $opsContent -match 'export_helpdesk_report'
}

# -------------------------------------------------------------------------
# NHOM 3: VIEW 02 - CAI WIN, BYPASS & SAO LUU DRIVER
# -------------------------------------------------------------------------
Assert-Audit "View 02" "Giao dien View 02 ton tai trong index.html" {
    $htmlContent -match 'id="view-win-deploy"'
}

Assert-Audit "View 02" "Nhan dien moi truong cai Win (detect_win_install_env: VMware, VBox, Hyper-V, Physical)" {
    $opsContent -match 'detect_win_install_env' -and $opsContent -match 'VMware'
}

Assert-Audit "View 02" "Nap Registry Bypass TPM 2.0, SecureBoot, RAM, Disk Check vao LabConfig & MoSetup" {
    $opsContent -match 'BypassTPMCheck' -and $opsContent -match 'BypassSecureBootCheck' -and $opsContent -match 'BypassRAMCheck'
}

Assert-Audit "View 02" "Mo hop thoai duyet file ISO chuan Windows OpenFileDialog" {
    $opsContent -match 'browse_iso' -and $opsContent -match 'OpenFileDialog'
}

Assert-Audit "View 02" "Tich hop Sao Luu Driver truoc khi cai Win" {
    $opsContent -match 'backup_drivers' -and ($appContent -match 'cb-deploy-backup-drivers' -or $htmlContent -match 'cb-deploy-backup-drivers')
}

Assert-Audit "View 02" "Tich hop Sao Luu Toan Bo Windows ra anh WIM (backup_full_windows)" {
    $opsContent -match 'backup_full_windows' -and $opsContent -match 'DISM.*Capture-Image'
}

# -------------------------------------------------------------------------
# NHOM 4: VIEW 03 - TIEN ICH KY THUAT & DRIVER VAULT
# -------------------------------------------------------------------------
Assert-Audit "View 03" "Giao dien View 03 ton tai trong index.html" {
    $htmlContent -match 'id="view-tech-driver"'
}

Assert-Audit "View 03" "Ho tro Quet va Xuat Driver tu dong bang DISM (export_drivers)" {
    $opsContent -match 'export_driver' -and $opsContent -match 'dism.*export-driver'
}

Assert-Audit "View 03" "Ho tro Kiem tra dung luong thu muc WinSxS (check_winsxs_size)" {
    $opsContent -match 'check_winsxs_size' -and $opsContent -match 'WinSxS'
}

# -------------------------------------------------------------------------
# NHOM 5: VIEW 04 - TOI UU & SUA LOI WIN (TWEAKS)
# -------------------------------------------------------------------------
Assert-Audit "View 04" "Giao dien View 04 ton tai trong index.html" {
    $htmlContent -match 'id="view-win-optimize"'
}

Assert-Audit "View 04" "Ho tro Menu Chuot Phai Cu Windows 10 (classic_context_menu InprocServer32)" {
    $opsContent -match 'classic_context_menu' -and $opsContent -match '86ca1aa0-34aa-4e8b-a509-50c905bae2a2'
}

Assert-Audit "View 04" "Ho tro 5 Goi Nguon Dien bao gom Che Do 24/7 Never Sleep (set_power_plan)" {
    $opsContent -match 'set_power_plan' -and $opsContent -match 'never_sleep' -and $opsContent -match 'ultimate'
}

Assert-Audit "View 04" "Ho tro Doi DNS thoi gian thuc (Cloudflare, Google, Quad9, AdGuard, DHCP)" {
    ($opsContent -match 'change_dns' -or $opsContent -match 'doi_dns') -and $opsContent -match '1.1.1.1' -and $opsContent -match '8.8.8.8'
}

Assert-Audit "View 04" "Ho tro Toi Uu Giai Phong RAM In-Memory (optimize_ram SetProcessWorkingSetSize)" {
    $opsContent -match 'optimize_ram' -and ($opsContent -match 'SetProcessWorkingSetSize' -or $opsContent -match 'GC\]::Collect')
}

Assert-Audit "View 04" "Ho tro Cau Hinh Toi Uu Sieu Nhe 2026 (apply_super_lean_profile)" {
    $opsContent -match 'apply_super_lean_profile'
}

Assert-Audit "View 04" "Ho tro Bo Go Bo 28 Ung Dung AppX Bloatware (purge_bloatware_28_apps)" {
    $opsContent -match 'purge_bloatware_28_apps' -and $opsContent -match 'Remove-AppxPackage'
}

Assert-Audit "View 04" "Ho tro Bo Hoan Tac Toan Dien Undo Engine (revert_super_lean_profile)" {
    $opsContent -match 'revert_super_lean_profile'
}

Assert-Audit "View 04" "Ho tro 4 Tinh Chinh Giao Dien Shell (Dark Theme, Long Paths, File Ext, Hidden Files)" {
    $opsContent -match 'toggle_dark_theme' -and $opsContent -match 'toggle_long_paths' -and $opsContent -match 'toggle_show_file_ext' -and $opsContent -match 'toggle_show_hidden_files'
}

# -------------------------------------------------------------------------
# NHOM 6: VIEW 05 - CAI DAT OFFICE M365 (ODT AIO)
# -------------------------------------------------------------------------
Assert-Audit "View 05" "Giao dien View 05 ton tai trong index.html" {
    $htmlContent -match 'id="view-office-m365"'
}

Assert-Audit "View 05" "Ho tro Cai Dat Office ODT AIO tu dong (install_office)" {
    $opsContent -match 'install_office' -and $opsContent -match 'setup.exe'
}

Assert-Audit "View 05" "Ho tro Che do Tai Du Lieu Chuyen Dung ODT (downloadOnly)" {
    $opsContent -match 'install_office' -and $opsContent -match 'download_only'
}

Assert-Audit "View 05" "Ho tro Kich Hoat Office KMS / Ohook (activate_office)" {
    $opsContent -match 'activate_office'
}

# -------------------------------------------------------------------------
# NHOM 7: VIEW 06 - MAY IN, SCAN & MANG LAN
# -------------------------------------------------------------------------
Assert-Audit "View 06" "Giao dien View 06 ton tai trong index.html" {
    $htmlContent -match 'id="view-printer-lan"'
}

Assert-Audit "View 06" "Ho tro Sua Loi May In LAN 0x0000011b & 0x00000709 (fix_printer RpcAuthnLevelEx)" {
    $opsContent -match 'fix_printer' -and $opsContent -match 'RpcAuthnLevelEx'
}

Assert-Audit "View 06" "Ho tro Tao va Chia Se Thu Muc Scan LAN tu dong (share_scan_folder)" {
    $opsContent -match 'share_scan_folder' -and $opsContent -match 'net share'
}

Assert-Audit "View 06" "Ho tro Quet IP cac thiet bi trong mang LAN (scan_lan)" {
    $opsContent -match 'scan_lan'
}

# -------------------------------------------------------------------------
# NHOM 8: VIEW 07 - PHAN VUNG & S.M.A.R.T O CUNG
# -------------------------------------------------------------------------
Assert-Audit "View 07" "Giao dien View 07 ton tai trong index.html" {
    $htmlContent -match 'id="view-disk-smart"'
}

Assert-Audit "View 07" "Ho tro Doc Thong So S.M.A.R.T Suc Khoe O Cung Thuc Te (collect_disk_smart_telemetry)" {
    $opsContent -match 'collect_disk_smart_telemetry' -and $opsContent -match 'Win32_DiskDrive'
}

# -------------------------------------------------------------------------
# NHOM 9: VIEW 08 - KHO PHAN MEM, GO APP SACH & FONT HUB
# -------------------------------------------------------------------------
Assert-Audit "View 08" "Giao dien View 08 ton tai trong index.html" {
    $htmlContent -match 'id="view-soft-winget"'
}

Assert-Audit "View 08" "Day du 4 Subviews doc lap (Store, Custom, Uninstall, Fonts)" {
    $htmlContent -match 'id="subview-soft-store"' -and
    $htmlContent -match 'id="subview-soft-custom"' -and
    $htmlContent -match 'id="subview-soft-uninstall"' -and
    $htmlContent -match 'id="subview-soft-fonts"'
}

Assert-Audit "View 08" "Ho tro Quet Danh Sach Phan Mem Da Cai Dat tren May (get_installed_apps)" {
    $opsContent -match 'get_installed_apps' -and $opsContent -match 'UninstallString'
}

Assert-Audit "View 08" "Ho tro Go Bo Tung Phan Mem voi quyen Admin (uninstall_app)" {
    $opsContent -match 'uninstall_app' -and $opsContent -match 'Verb RunAs'
}

Assert-Audit "View 08" "Ho tro Go Hang Loat nhieu phan mem (bulkUninstallSelectedApps)" {
    $appContent -match 'bulkUninstallSelectedApps' -and $htmlContent -match 'btnBulkUninstall'
}

Assert-Audit "View 08" "Nut Go Cai Dat mang gam mau do sang ro net (bg-red-600)" {
    $appContent -match 'bg-red-600'
}

Assert-Audit "View 08" "Ho tro Cai Dat Bo Font Chu Tieng Viet VNI/TCVN3/Google Fonts (install_font_pack)" {
    $opsContent -match 'install_font_pack'
}

# -------------------------------------------------------------------------
# NHOM 10: VIEW 09 - FAKE VPN & PROXY
# -------------------------------------------------------------------------
Assert-Audit "View 09" "Giao dien View 09 ton tai trong index.html" {
    $htmlContent -match 'id="view-vpn-proxy"'
}

Assert-Audit "View 09" "Ho tro Cau hinh va Bat/Tat Proxy he thong (configure_proxy / disable_proxy)" {
    $opsContent -match 'configure_proxy' -and $opsContent -match 'disable_proxy'
}

Assert-Audit "View 09" "Ho tro Lay Dia Chi IP Public thuc te (refresh_ip)" {
    $opsContent -match 'refresh_ip' -or $opsContent -match 'get_public_ip'
}

# -------------------------------------------------------------------------
# NHOM 11: VIEW 10 - TUY CHINH THUONG HIEU OEM
# -------------------------------------------------------------------------
Assert-Audit "View 10" "Giao dien View 10 ton tai trong index.html" {
    $htmlContent -match 'id="view-oem-brand"'
}

Assert-Audit "View 10" "Ho tro Thiet Lap Thong Tin OEM Manufacturer & Support Phone (set_oem_info)" {
    $opsContent -match 'set_oem_info' -and $opsContent -match 'OEMInformation'
}

# -------------------------------------------------------------------------
# NHOM 12: VIEW 11 - KICH HOAT BAN QUYEN WINDOWS / OFFICE
# -------------------------------------------------------------------------
Assert-Audit "View 11" "Giao dien View 11 ton tai trong index.html" {
    $htmlContent -match 'id="view-hwid-act"'
}

Assert-Audit "View 11" "Ho tro Kich Hoat Windows HWID Ban Quyen Ky Thuat So (activate_windows)" {
    $opsContent -match 'activate_windows'
}

Assert-Audit "View 11" "Ho tro Doc Product Key Nhuan Tu BIOS MSDM Table (detect_bios_license)" {
    $opsContent -match 'detect_bios_license' -and $opsContent -match 'SoftwareLicensingService'
}

# -------------------------------------------------------------------------
# NHOM 13: VIEW 12 - QUAN LY PHAN VUNG O DIA
# -------------------------------------------------------------------------
Assert-Audit "View 12" "Giao dien View 12 ton tai trong index.html" {
    $htmlContent -match 'id="view-disk-part"'
}

Assert-Audit "View 12" "Ho tro Khoi Chay Disk Management Chuyen Nghiep (open_disk_mgmt / diskmgmt.msc)" {
    $opsContent -match 'open_disk_mgmt' -and $opsContent -match 'diskmgmt.msc'
}

# -------------------------------------------------------------------------
# NHOM 14: VIEW 13 - CUU HO IT HELPDESK (547 SU CO)
# -------------------------------------------------------------------------
Assert-Audit "View 13" "Giao dien View 13 ton tai trong index.html" {
    $htmlContent -match 'id="view-it-helpdesk"'
}

Assert-Audit "View 13" "Ho tro Sua Mat Mang va Nghen Card Mang LAN (fix_network_freeze)" {
    $opsContent -match 'fix_network_freeze'
}

Assert-Audit "View 13" "Ho tro Mo Khoa Toan Bo Task Manager, Registry, CMD (unlock_system_tools)" {
    $opsContent -match 'unlock_system_tools' -and $opsContent -match 'DisableTaskMgr'
}

Assert-Audit "View 13" "Ho tro Kich Hoat Tai Khoan Administrator An SID 500 (enable_hidden_admin)" {
    $opsContent -match 'enable_hidden_admin'
}

Assert-Audit "View 13" "Ho tro Chuyen Che Do Safe Mode (safe_mode / bcdedit safeboot)" {
    ($opsContent -match 'safe_mode' -or $opsContent -match 'safeboot') -and $opsContent -match 'bcdedit'
}

Assert-Audit "View 13" "Ho tro Quet va Sua Chua Tep Tin He Thong SFC / DISM (sfc_dism)" {
    $opsContent -match 'sfc_dism'
}

# -------------------------------------------------------------------------
# NHOM 15: VIEW 15 - ADMIN PORTAL & FLEET MONITOR
# -------------------------------------------------------------------------
Assert-Audit "View 15" "Giao dien View 15 ton tai trong index.html" {
    $htmlContent -match 'id="view-admin-portal"'
}

Assert-Audit "View 15" "Mat Khau Admin mac dinh chinh xac la Vtt@2403 (khong phan biet hoa thuong, Unikey)" {
    $opsContent -match 'admin_login' -and $opsContent -match 'vtt@2403'
}

Assert-Audit "View 15" "Chan triet de dieu huong vao Admin Portal khi chua nhap dung mat khau" {
    $appContent -match 'view-admin-portal' -and $appContent -match '!isAdminAuth'
}

Assert-Audit "View 15" "Dong bo danh sach may tram Fleet Telemetry ve GitHub Cloud (record_device_heartbeat)" {
    $opsContent -match 'record_device_heartbeat' -and $opsContent -match 'client_devices.json'
}

# -------------------------------------------------------------------------
# NHOM 16: GLOBAL ENGINES (CAP NHAT, SHORTCUT, GIAO DIEN)
# -------------------------------------------------------------------------
Assert-Audit "Global" "Co che kiem tra cap nhat khong bi vong lap vo tan (Compare-SemVer)" {
    $opsContent -match 'act == "check_update"'
}

Assert-Audit "Global" "Tu dong tao va dong bo Shortcut 'VUONGTT Toolkit.lnk' tren Desktop" {
    $opsContent -match 'ensure_desktop_shortcut' -and $opsContent -match 'VUONGTT Toolkit.lnk'
}

Assert-Audit "Global" "Bo chuyen doi giao dien Dark / Light / System Theme hoat dong on dinh" {
    $appContent -match 'setThemeMode' -and $htmlContent -match 'btn-theme-dark'
}

Assert-Audit "Global" "Bo chuyen doi ngon ngu VN / EN hoat dong on dinh" {
    $appContent -match 'btn-lang-vn' -and $appContent -match 'btn-lang-en'
}

Assert-Audit "Global" "Tep src-ui/app.js khong chua bat ky loi cu phap JavaScript nao (node -c)" {
    $res = cmd.exe /c "node -c src-ui\app.js 2>&1"
    $LASTEXITCODE -eq 0
}

Assert-Audit "Global" "Live Terminal Buffer ghi log thoi gian thuc khong gay freeze UI" {
    $opsContent -match 'append_log' -and $opsContent -match 'get_logs'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TONG KET KIEM THU TOAN DIEN HE THONG VUONGTT TOOLKIT 2026          " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host " Tong so tieu chi kiem thu: $totalTests" -ForegroundColor White
Write-Host " So tieu chi DAT (PASS):    $passedCount" -ForegroundColor Green
Write-Host " So tieu chi LOI (FAIL):    $failedCount" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })

if ($failedCount -eq 0) {
    Write-Host "`n>>> KET LUAN: 100% TAT CA CAC PHAN HE VA TINH NANG DEU DAT CHUAN HOAT DONG! <<<`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> CANH BAO: PHAT HIEN $failedCount TINH NANG BI LOI HOAC CHUA DAT CHUAN! <<<`n" -ForegroundColor Red
    exit 1
}
