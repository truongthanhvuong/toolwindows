# =========================================================================
#   SCRIPT TONG HOP 100% GIAO DIEN STITCH (13+1 MAN HINH) VAO TAURI SRC-UI
# =========================================================================
param()

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$stitchRoot  = Join-Path $projectRoot "stitch_to_n_di_n_thi_t_k_ui (1)\stitch_to_n_di_n_thi_t_k_ui"
$outDir      = Join-Path $projectRoot "src-ui"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$screens = @(
    @{ Id = "view-sys-monitor";  Folder = "xem_c_u_h_nh_gi_m_s_t_h_th_ng";                  Path = "check-cau-hinh";      Default = $true  },
    @{ Id = "view-win-deploy";   Folder = "c_i_win_bypass_windows_11_10";                   Path = "cai-win-kho-iso";     Default = $false },
    @{ Id = "view-tech-driver";  Folder = "ti_n_ch_k_thu_t_driver";                         Path = "tien-ich-ky-thuat";   Default = $false },
    @{ Id = "view-win-optimize"; Folder = "t_i_u_s_a_l_i_win";                              Path = "toi-uu-sua-loi-win";  Default = $false },
    @{ Id = "view-office-m365";  Folder = "c_i_t_office_m365";                              Path = "cai-dat-office";      Default = $false },
    @{ Id = "view-printer-lan";  Folder = "m_y_in_scan_lan";                                Path = "may-in-scan-lan";     Default = $false },
    @{ Id = "view-disk-smart";   Folder = "ph_n_v_ng_c_ng_smart";                           Path = "phan-vung-o-cung";    Default = $false },
    @{ Id = "view-soft-winget";  Folder = "kho_ph_n_m_m_winget";                            Path = "kho-phan-mem-go-app"; Default = $false },
    @{ Id = "view-vpn-proxy";    Folder = "fake_vpn_socks5_proxy";                          Path = "fake-vpn-proxy";      Default = $false },
    @{ Id = "view-oem-brand";    Folder = "t_y_ch_nh_oem_th_ng_hi_u_m_y";                   Path = "tuy-chinh-oem";       Default = $false },
    @{ Id = "view-hwid-act";     Folder = "k_ch_ho_t_b_n_quy_n_s_hwid";                     Path = "kich-hoat-hwid";      Default = $false },
    @{ Id = "view-disk-part";    Folder = "qu_n_l_ph_n_v_ng_a";                             Path = "quan-ly-phan-vung";   Default = $false },
    @{ Id = "view-it-helpdesk";  Folder = "c_u_h_it_helpdesk_kh_n_c_p";                     Path = "cuu-ho-it-helpdesk";  Default = $false },
    @{ Id = "view-all-overview"; Folder = "vuongtt_tool_pro_2026_to_n_b_ui_xu_t_file_pdf";  Path = "toan-bo-ui-pdf";      Default = $false }
)

# Lay head, header, aside chuan tu man hinh 01 (xem_c_u_h_nh_gi_m_s_t_h_th_ng)
$baseHtmlPath = Join-Path $stitchRoot "xem_c_u_h_nh_gi_m_s_t_h_th_ng\code.html"
$baseHtml = [System.IO.File]::ReadAllText($baseHtmlPath, [System.Text.Encoding]::UTF8)

if ($baseHtml -notmatch '<head>([\s\S]*?)</head>') {
    throw "Khong tim thay the <head> trong file goc!"
}
$headInner = $Matches[1]

# Bo sung title, style hieu ung chuyen trang muot ma & Light Mode support
$extraHead = @"
<title>VUONGTT Tool Pro 2026 — Rust (Tauri v2) Fluent OS Utility</title>
<style>
  .stitch-view {
    display: none;
    animation: stitchFadeIn 0.18s cubic-bezier(0.16, 1, 0.3, 1);
  }
  .stitch-view.active {
    display: block;
  }
  @keyframes stitchFadeIn {
    from { opacity: 0; transform: translateY(6px); }
    to   { opacity: 1; transform: translateY(0); }
  }
  html.light-theme body {
    filter: invert(0.92) hue-rotate(180deg);
  }
  html.light-theme img, html.light-theme svg {
    filter: invert(1) hue-rotate(180deg);
  }
  button, a { cursor: pointer; }
  /* Toast notification */
  #rust-toast-container {
    position: fixed;
    bottom: 20px;
    right: 20px;
    z-index: 9999;
    display: flex;
    flex-direction: column;
    gap: 8px;
    pointer-events: none;
  }
  .rust-toast {
    pointer-events: auto;
    background: rgba(23, 31, 51, 0.95);
    backdrop-filter: blur(16px);
    border: 1px solid rgba(180, 197, 255, 0.25);
    color: #dae2fd;
    padding: 12px 16px;
    border-radius: 10px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.45);
    font-family: Inter, sans-serif;
    font-size: 13px;
    display: flex;
    align-items: center;
    gap: 10px;
    max-width: 420px;
    animation: stitchFadeIn 0.2s ease-out;
  }
</style>
"@

# Trich xuat sections tu 14 man hinh
$sectionsSb = New-Object System.Text.StringBuilder
foreach ($s in $screens) {
    $filePath = Join-Path (Join-Path $stitchRoot $s.Folder) "code.html"
    if (-not (Test-Path $filePath)) {
        throw "Khong tim thay file: $filePath"
    }
    $raw = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
    if ($raw -match '<main[^>]*>([\s\S]*?)</main>') {
        $mainInner = $Matches[1].Trim()
        $activeClass = if ($s.Default) { "stitch-view active" } else { "stitch-view" }
        [void]$sectionsSb.AppendLine("<!-- ==================== SCREEN: $($s.Id) ($($s.Folder)) ==================== -->")
        [void]$sectionsSb.AppendLine("<section id=`"$($s.Id)`" data-view-path=`"$($s.Path)`" class=`"$activeClass`">")
        [void]$sectionsSb.AppendLine($mainInner)
        [void]$sectionsSb.AppendLine("</section>")
    } else {
        throw "Khong trich xuat duoc <main> tu: $filePath"
    }
}

# Tao App Shell chuan Stitch voi day du data-view-target cho 13+1 man hinh
$finalHtml = @"
<!DOCTYPE html>
<html class="dark" lang="vi">
<head>
$headInner
$extraHead
</head>
<body class="bg-background font-body-md text-on-surface select-none antialiased">
  <!-- TOP WINDOW TITLEBAR (TAURI DRAG REGION) -->
  <header data-tauri-drag-region class="fixed top-0 left-0 right-0 h-14 z-50 bg-surface-container-lowest/85 backdrop-blur-xl shadow-[0_1px_8px_rgba(0,0,0,0.25)] border-b border-outline-variant/20">
    <div data-tauri-drag-region class="h-14 w-full px-space-md flex items-center justify-between">
      <div data-tauri-drag-region class="flex items-center gap-space-md">
        <div class="flex items-center gap-1.5 pr-space-xs">
          <button id="btn-win-close" aria-label="Close" title="Đóng cửa sổ" class="w-3.5 h-3.5 rounded-full bg-error-container hover:bg-error transition-colors flex items-center justify-center" type="button">
            <span class="material-symbols-outlined text-on-error text-[9px] opacity-0 hover:opacity-100">close</span>
          </button>
          <button id="btn-win-min" aria-label="Minimize" title="Thu nhỏ" class="w-3.5 h-3.5 rounded-full bg-surface-bright hover:bg-outline transition-colors flex items-center justify-center" type="button">
            <span class="material-symbols-outlined text-on-surface text-[9px] opacity-0 hover:opacity-100">remove</span>
          </button>
          <button id="btn-win-max" aria-label="Maximize" title="Phóng to / Khôi phục" class="w-3.5 h-3.5 rounded-full bg-tertiary-container hover:bg-tertiary transition-colors flex items-center justify-center" type="button">
            <span class="material-symbols-outlined text-on-tertiary text-[9px] opacity-0 hover:opacity-100">crop_square</span>
          </button>
        </div>
        <div data-tauri-drag-region class="flex items-center gap-space-xs">
          <div class="w-8 h-8 rounded-lg bg-primary-container flex items-center justify-center font-headline-md text-on-primary-container shadow-sm">V</div>
          <span data-tauri-drag-region class="font-headline-md text-headline-md text-on-surface tracking-tight">VUONGTT Tool Pro 2026</span>
          <span id="app-version-badge" class="px-2 py-0.5 rounded bg-surface-container-high font-code-sm text-code-sm text-secondary">v20.5.909.93 • Rust Tauri v2</span>
        </div>
        <div class="hidden xl:flex items-center gap-2">
          <span class="px-2 py-0.5 rounded bg-surface-container-high font-label-sm text-label-sm text-tertiary flex items-center gap-1">
            <span class="material-symbols-outlined text-[13px]">verified_user</span>Admin Privileges [Active]
          </span>
          <span class="px-2 py-0.5 rounded bg-tertiary-container font-label-sm text-label-sm text-on-tertiary-container font-semibold">PRO • Lifetime</span>
        </div>
      </div>

      <div class="flex items-center gap-space-md">
        <div class="hidden md:flex items-center gap-space-xs px-2.5 py-1 rounded bg-surface-container font-code-sm text-code-sm text-on-surface-variant">
          <span class="material-symbols-outlined text-[14px] text-primary">schedule</span>
          <span id="system-clock">2026-10-13 09:45:00</span>
        </div>
        <button id="btn-overview-all" data-target="view-all-overview" class="px-2.5 py-1 rounded bg-surface-container-high hover:bg-primary-container hover:text-on-primary-container text-on-surface-variant font-label-sm text-label-sm flex items-center gap-1.5 transition-colors" type="button" title="Xem Bản Tổng Hợp Đặc Tả 13 Màn Hình">
          <span class="material-symbols-outlined text-[14px]">grid_view</span>
          <span>Blueprint 13 UI</span>
        </button>
        <button id="btn-header-update" class="px-2.5 py-1 rounded bg-surface-container-high hover:bg-primary-container hover:text-on-primary-container text-on-surface-variant font-label-sm text-label-sm flex items-center gap-1.5 transition-colors" type="button">
          <span class="material-symbols-outlined text-[14px]">sync</span>
          <span>Cập nhật</span>
        </button>
        <div class="w-8 h-8 rounded-full bg-primary flex items-center justify-center" title="IT Administrator • Superuser">
          <span class="material-symbols-outlined text-on-primary text-[18px]">person</span>
        </div>
      </div>
    </div>
  </header>

  <!-- PERSISTENT LEFT SIDEBAR (288px / w-72) -->
  <aside class="fixed left-0 top-14 bottom-0 w-72 bg-surface-container-low/95 backdrop-blur-xl z-40 flex flex-col justify-between shadow-[0_1px_8px_rgba(0,0,0,0.2)] border-r border-outline-variant/20">
    <div class="flex flex-col flex-1 min-h-0">
      <div class="px-space-md pt-space-md pb-space-sm flex items-center justify-between">
        <div class="flex items-center gap-2">
          <div class="w-7 h-7 rounded-lg bg-surface-container flex items-center justify-center">
            <span class="material-symbols-outlined text-secondary text-[16px]">admin_panel_settings</span>
          </div>
          <div>
            <div class="font-label-md text-label-md text-on-surface leading-tight">IT Administrator</div>
            <div class="font-label-sm text-label-sm text-tertiary">Rust Native Engine</div>
          </div>
        </div>
        <div class="flex items-center gap-1">
          <button id="btn-lang-vn" class="px-1.5 py-0.5 rounded bg-primary-container font-code-sm text-code-sm text-on-primary-container" type="button">VN</button>
          <button id="btn-lang-en" class="px-1.5 py-0.5 rounded bg-surface-container-high font-code-sm text-code-sm text-outline hover:text-on-surface" type="button">EN</button>
        </div>
      </div>

      <!-- Theme Switcher -->
      <div class="px-space-md pb-space-xs">
        <div class="flex items-center justify-between p-1 rounded-lg bg-surface-container-lowest">
          <button id="btn-theme-dark" class="flex-1 py-1 rounded font-label-sm text-label-sm text-center text-on-surface bg-surface-container-high transition-colors" type="button">Tối</button>
          <button id="btn-theme-light" class="flex-1 py-1 rounded font-label-sm text-label-sm text-center text-outline hover:text-on-surface transition-colors" type="button">Sáng</button>
          <button id="btn-theme-sys" class="flex-1 py-1 rounded font-label-sm text-label-sm text-center text-outline hover:text-on-surface transition-colors" type="button">Hệ thống</button>
        </div>
      </div>

      <!-- 9 CORE MODULES + 4 SUB-MODULES NAVIGATION -->
      <nav id="sidebar-nav" class="flex-1 px-space-sm py-space-xs overflow-y-auto space-y-0.5">
        <div class="px-3 pt-1 pb-1 font-code-sm text-[10px] text-outline uppercase tracking-wider">9 Phân Hệ Cốt Lõi</div>
        <a data-target="view-sys-monitor" data-path="check-cau-hinh" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md bg-primary-container text-on-primary-container font-semibold shadow-sm transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5">monitor_heart</span>
          <span>01. Xem Cấu Hình &amp; Giám Sát</span>
        </a>
        <a data-target="view-win-deploy" data-path="cai-win-kho-iso" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-secondary">install_desktop</span>
          <span>02. Cài Win &amp; Bypass 11/10</span>
        </a>
        <a data-target="view-tech-driver" data-path="tien-ich-ky-thuat" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-tertiary">build_circle</span>
          <span>03. Tiện Ích Kỹ Thuật &amp; Driver</span>
        </a>
        <a data-target="view-win-optimize" data-path="toi-uu-sua-loi-win" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-primary-fixed">tune</span>
          <span>04. Tối Ưu &amp; Sửa Lỗi Win</span>
        </a>
        <a data-target="view-office-m365" data-path="cai-dat-office" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-secondary-fixed">description</span>
          <span>05. Cài Đặt Office M365</span>
        </a>
        <a data-target="view-printer-lan" data-path="may-in-scan-lan" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-tertiary-fixed">print</span>
          <span>06. Máy In, Scan &amp; LAN</span>
        </a>
        <a data-target="view-disk-smart" data-path="phan-vung-o-cung" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-primary">hard_drive</span>
          <span>07. Phân Vùng &amp; Ổ Cứng SMART</span>
        </a>
        <a data-target="view-soft-winget" data-path="kho-phan-mem-go-app" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-secondary">apps</span>
          <span>08. Kho Phần Mềm &amp; Winget</span>
        </a>
        <a data-target="view-vpn-proxy" data-path="fake-vpn-proxy" class="nav-item flex items-center px-3 py-2 rounded-lg font-body-md text-body-md text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[18px] mr-2.5 text-tertiary">vpn_lock</span>
          <span>09. Fake VPN / SOCKS5 Proxy</span>
        </a>

        <div class="px-3 pt-2.5 pb-1 font-code-sm text-[10px] text-outline uppercase tracking-wider">4 Phân Hệ Chuyên Sâu</div>
        <a data-target="view-oem-brand" data-path="tuy-chinh-oem" class="nav-item flex items-center px-3 py-1.5 rounded-lg font-body-md text-[12.5px] text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[17px] mr-2.5 text-primary">branding_watermark</span>
          <span>10. Tùy Chỉnh OEM &amp; Thương Hiệu</span>
        </a>
        <a data-target="view-hwid-act" data-path="kich-hoat-hwid" class="nav-item flex items-center px-3 py-1.5 rounded-lg font-body-md text-[12.5px] text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[17px] mr-2.5 text-tertiary">vpn_key</span>
          <span>11. Kích Hoạt Bản Quyền HWID</span>
        </a>
        <a data-target="view-disk-part" data-path="quan-ly-phan-vung" class="nav-item flex items-center px-3 py-1.5 rounded-lg font-body-md text-[12.5px] text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[17px] mr-2.5 text-secondary">pie_chart</span>
          <span>12. Quản Lý Phân Vùng Ổ Đĩa</span>
        </a>
        <a data-target="view-it-helpdesk" data-path="cuu-ho-it-helpdesk" class="nav-item flex items-center px-3 py-1.5 rounded-lg font-body-md text-[12.5px] text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface transition-colors" href="#">
          <span class="material-symbols-outlined text-[17px] mr-2.5 text-error">emergency</span>
          <span>13. Cứu Hộ IT Helpdesk Khẩn Cấp</span>
        </a>
      </nav>
    </div>

    <!-- EMERGENCY QUICK ACTIONS -->
    <div class="p-space-md bg-surface-container-lowest/60 border-t border-outline-variant/15">
      <div class="font-label-sm text-label-sm text-outline mb-space-xs uppercase tracking-wider">Thao tác khẩn cấp</div>
      <div class="grid grid-cols-2 gap-1.5">
        <button id="btn-emerg-clean" data-target="view-win-optimize" class="px-2 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high hover:text-on-surface text-on-surface-variant font-label-sm text-label-sm flex items-center justify-center gap-1 transition-colors" type="button">
          <span class="material-symbols-outlined text-[14px] text-tertiary">cleaning_services</span>
          <span>Dọn Dẹp</span>
        </button>
        <button id="btn-emerg-helpdesk" data-target="view-it-helpdesk" class="px-2 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high hover:text-on-surface text-on-surface-variant font-label-sm text-label-sm flex items-center justify-center gap-1 transition-colors" type="button">
          <span class="material-symbols-outlined text-[14px] text-primary">medical_services</span>
          <span>Cứu Hộ IT</span>
        </button>
        <button id="btn-emerg-explorer" class="px-2 py-1.5 rounded-lg bg-surface-container hover:bg-surface-container-high hover:text-on-surface text-on-surface-variant font-label-sm text-label-sm flex items-center justify-center gap-1 transition-colors" type="button">
          <span class="material-symbols-outlined text-[14px] text-secondary">restart_alt</span>
          <span>Explorer</span>
        </button>
        <button id="btn-emerg-exit" class="px-2 py-1.5 rounded-lg bg-error-container hover:bg-error hover:text-on-error text-on-error-container font-label-sm text-label-sm flex items-center justify-center gap-1 transition-colors" type="button">
          <span class="material-symbols-outlined text-[14px]">power_settings_new</span>
          <span>Thoát</span>
        </button>
      </div>
    </div>
  </aside>

  <!-- MAIN CONTENT AREA (13+1 STITCH VIEWS) -->
  <div class="pl-72">
    <main id="app-main-container" class="w-full pt-14 px-margin-window pb-space-xl bg-background min-h-screen">
$($sectionsSb.ToString())
    </main>
  </div>

  <!-- TOAST NOTIFICATION CONTAINER -->
  <div id="rust-toast-container"></div>

  <!-- FRONTEND ROUTER & TAURI IPC CONTROLLER -->
  <script src="app.js"></script>
</body>
</html>
"@

$outFile = Join-Path $outDir "index.html"
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($outFile, $finalHtml, $utf8Bom)
Write-Host "[OK] Da tao thanh cong src-ui/index.html ($(([System.IO.FileInfo]$outFile).Length) bytes) voi 14 man hinh Stitch!" -ForegroundColor Green
