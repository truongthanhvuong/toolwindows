# =========================================================================
#   TDD TEST SUITE: RUST (TAURI V2) & FLUENT OS UTILITY 13 SCREENS MIGRATION
# =========================================================================
param()

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Assert-True($condition, $testName) {
    $script:TotalTests++
    if ($condition) {
        $script:PassedTests++
        Write-Host "  [PASS] $testName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  [FAIL] $testName" -ForegroundColor Red
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$cargoToml   = Join-Path $projectRoot "src-tauri\Cargo.toml"
$tauriConf   = Join-Path $projectRoot "src-tauri\tauri.conf.json"
$rustMain    = Join-Path $projectRoot "src-tauri\src\main.rs"
$rustTelem   = Join-Path $projectRoot "src-tauri\src\telemetry.rs"
$rustOps     = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$uiHtml      = Join-Path $projectRoot "src-ui\index.html"
$uiJs        = Join-Path $projectRoot "src-ui\app.js"

Write-Host ">>> BAT DAU CHAY BO TEST CHUYEN DOI RUST (TAURI V2) & 13 MAN HINH STITCH <<<" -ForegroundColor Cyan

# --- NHOM 1: Kiem tra Cau truc Du an Rust & Tauri v2 ---
Write-Host "`n--- NHOM 1: Cau truc Du an Rust & Tauri v2 (src-tauri/) ---" -ForegroundColor Magenta
Assert-True (Test-Path $cargoToml) "Phai ton tai file cau hinh Rust src-tauri/Cargo.toml"
Assert-True (Test-Path $tauriConf) "Phai ton tai file cau hinh Tauri src-tauri/tauri.conf.json"
Assert-True (Test-Path $rustMain)  "Phai ton tai file nhan chinh src-tauri/src/main.rs"
Assert-True (Test-Path $rustTelem) "Phai ton tai module do luong phan cung src-tauri/src/telemetry.rs"
Assert-True (Test-Path $rustOps)   "Phai ton tai module tac vu he thong src-tauri/src/system_ops.rs"

# --- NHOM 2: Kiem tra Tich hop 13 Man hinh Fluent OS Utility tu Google Stitch ---
Write-Host "`n--- NHOM 2: Tich hop 13 Man hinh Google Stitch trong src-ui/index.html ---" -ForegroundColor Magenta
$htmlContent = if (Test-Path $uiHtml) { Get-Content $uiHtml -Raw -Encoding UTF8 } else { "" }

Assert-True ($htmlContent -match 'id="view-sys-monitor"')  "Man 01: Xem Cau Hinh & Giam Sat He Thong (view-sys-monitor)"
Assert-True ($htmlContent -match 'id="view-win-deploy"')   "Man 02: Cai Win & Bypass Windows 11/10 (view-win-deploy)"
Assert-True ($htmlContent -match 'id="view-tech-driver"')  "Man 03: Tien Ich Ky Thuat & Driver (view-tech-driver)"
Assert-True ($htmlContent -match 'id="view-win-optimize"') "Man 04: Toi Uu & Sua Loi Win (view-win-optimize)"
Assert-True ($htmlContent -match 'id="view-office-m365"')  "Man 05: Cai Dat Office M365 (view-office-m365)"
Assert-True ($htmlContent -match 'id="view-printer-lan"')  "Man 06: May In, Scan & LAN (view-printer-lan)"
Assert-True ($htmlContent -match 'id="view-disk-smart"')   "Man 07: Phan Vung & O Cung SMART (view-disk-smart)"
Assert-True ($htmlContent -match 'id="view-soft-winget"')  "Man 08: Kho Phan Mem & Winget (view-soft-winget)"
Assert-True ($htmlContent -match 'id="view-vpn-proxy"')    "Man 09: Fake VPN / SOCKS5 Proxy (view-vpn-proxy)"
Assert-True ($htmlContent -match 'id="view-oem-brand"')    "Man 10: Tuy Chinh OEM & Thuong Hieu May (view-oem-brand)"
Assert-True ($htmlContent -match 'id="view-hwid-act"')     "Man 11: Kich Hoat Ban Quyen So HWID (view-hwid-act)"
Assert-True ($htmlContent -match 'id="view-disk-part"')    "Man 12: Quan Ly Phan Vung O Dia (view-disk-part)"
Assert-True ($htmlContent -match 'id="view-it-helpdesk"')  "Man 13: Cuu Ho IT Helpdesk & Khan Cap (view-it-helpdesk)"

# --- NHOM 3: Kiem tra Router & Cau noi Frontend (src-ui/app.js) ---
Write-Host "`n--- NHOM 3: Bo dinh tuyen SPA & Cau noi Rust IPC trong src-ui/app.js ---" -ForegroundColor Magenta
$jsContent = if (Test-Path $uiJs) { Get-Content $uiJs -Raw -Encoding UTF8 } else { "" }

Assert-True ($jsContent -match 'switchView') "app.js phai co ham chuyen doi man hinh switchView"
Assert-True ($jsContent -match 'get_system_telemetry') "app.js phai goi command get_system_telemetry tu nhan Rust"
Assert-True ($jsContent -match 'run_system_action') "app.js phai goi command run_system_action thuc thi tac vu ky thuat"

# --- NHOM 4: Kiem tra Nhan Backend Rust (telemetry.rs & system_ops.rs) ---
Write-Host "`n--- NHOM 4: Nhan Backend Rust (src-tauri/src/) ---" -ForegroundColor Magenta
$telemContent = if (Test-Path $rustTelem) { Get-Content $rustTelem -Raw -Encoding UTF8 } else { "" }
$opsContent   = if (Test-Path $rustOps)   { Get-Content $rustOps -Raw -Encoding UTF8 }   else { "" }

Assert-True ($telemContent -match 'SystemTelemetry') "telemetry.rs phai dinh nghia cau truc du lieu SystemTelemetry"
Assert-True ($telemContent -match 'collect_telemetry') "telemetry.rs phai co ham thu thap thong so phan cung collect_telemetry"
Assert-True ($opsContent -match 'execute_system_action') "system_ops.rs phai co ham thuc thi tac vu he thong execute_system_action"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "KET QUA: $script:PassedTests / $script:TotalTests PASS" -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
