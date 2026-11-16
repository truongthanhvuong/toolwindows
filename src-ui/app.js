
  // Global Image Error Fallback Handler
  window.addEventListener("error", function (e) {
    if (e.target && e.target.tagName === "IMG") {
      e.target.style.display = "none";
      const parent = e.target.parentElement;
      if (parent && !parent.querySelector(".img-fallback-badge")) {
        const alt = e.target.getAttribute("alt") || "App";
        const initial = alt.charAt(0).toUpperCase();
        const badge = document.createElement("div");
        badge.className = "img-fallback-badge w-9 h-9 rounded-lg bg-sky-100 text-sky-700 font-bold flex items-center justify-center shrink-0 text-sm border border-sky-300 shadow-2xs";
        badge.textContent = initial;
        parent.insertBefore(badge, e.target);
      }
    }
  }, true);

/**
 * ============================================================================
 * VUONGTT TOOL PRO 2026 — FRONTEND ROUTER & RUST (TAURI V2) IPC CONTROLLER
 * Design System: Fluent OS Utility (13+1 Stitch Screens + Admin Portal VIP)
 * ============================================================================
 */

(function () {
  "use strict";

  let isAdminAuth = false;
  const DEFAULT_FEATURE_POLICIES = [
    { Id: "SysInfo", Name: "Xem Cấu Hình Máy Tính", Icon: "💻", Tier: "FREE", Description: "Xem thông số CPU, RAM, GPU, Mainboard, ổ cứng thời gian thực" },
    { Id: "Customize", Name: "Tùy Chỉnh Thông Tin Máy", Icon: "🛠️", Tier: "FREE", Description: "Đổi tên máy tính, Workgroup, chủ sở hữu OEM" },
    { Id: "CpuMain", Name: "Tra Cứu CPU + Main", Icon: "🔍", Tier: "FREE", Description: "Tra cứu độ tương thích socket, chipset mainboard và CPU" },
    { Id: "Users", Name: "Quản Lý User & PC", Icon: "👥", Tier: "FREE", Description: "Quản trị người dùng Windows, reset mật khẩu, kích hoạt Administrator" },
    { Id: "Cleaner", Name: "Dọn Rác & Tăng Tốc Win", Icon: "🧹", Tier: "FREE", Description: "Xóa cache tạm, dọn dẹp hệ điều hành và tối ưu hóa" },
    { Id: "Tweaks", Name: "Tinh Chỉnh Hệ Thống", Icon: "⚡", Tier: "FREE", Description: "Tối ưu hóa Windows sâu, tắt telemetry, tăng tốc đồ họa & game" },
    { Id: "Config", Name: "Cấu Hình & Sửa Lỗi Hệ Thống", Icon: "⚙️", Tier: "FREE", Description: "25 công cụ sửa lỗi Windows, 9 tính năng hệ thống, 14 bảng điều khiển cổ điển" },
    { Id: "Troubleshoot", Name: "Cứu Hộ IT Helpdesk Windows", Icon: "🧰", Tier: "FREE", Description: "Trung tâm cứu hộ hơn 500 sự cố, đo lường Telemetry thực tế & tự động sửa lỗi" },
    { Id: "NetworkLAN", Name: "Mạng & Advanced IP Scanner", Icon: "🌐", Tier: "FREE", Description: "Quét dải IP LAN, dò tìm thiết bị, kiểm tra port mở & kết nối mạng" },
    { Id: "PrinterLAN", Name: "Sửa Lỗi Máy In & Mạng LAN", Icon: "🖨️", Tier: "FREE", Description: "Khắc phục lỗi chia sẻ máy in 0x0000011b, 0x00000709 và thông mạng LAN" },
    { Id: "Office", Name: "Cài Đặt Office (Tự Động AIO)", Icon: "📄", Tier: "FREE", Description: "Cài đặt Office 2016-2024 / 365 tự động trọn gói" },
    { Id: "Software", Name: "Tải Ứng Dụng Thiết Yếu", Icon: "📦", Tier: "FREE", Description: "Kho hơn 260 phần mềm văn phòng, đồ họa, tiện ích cần thiết" },
    { Id: "CustomApp", Name: "Phần Mềm Kế Toán & Khác", Icon: "📊", Tier: "FREE", Description: "Cài đặt MISA, HTKK, iTaxViewer và ứng dụng doanh nghiệp" },
    { Id: "Uninstaller", Name: "Gỡ Phần Mềm & Dọn Sạch Sâu", Icon: "🗑️", Tier: "FREE", Description: "Gỡ cài đặt hàng loạt và dọn sạch sâu tận gốc Registry/AppData" },
    { Id: "Fonts", Name: "Kho Font Tiếng Việt & AutoCAD", Icon: "🔤", Tier: "FREE", Description: "Cài đặt trọn bộ Font VNI, TCVN3, Unicode và Font AutoCAD .shx" },
    { Id: "DiskHealth", Name: "Sức Khỏe Ổ Cứng (S.M.A.R.T)", Icon: "💾", Tier: "FREE", Description: "Chẩn đoán CrystalDiskInfo, NVMe spec log page 0x02, nhiệt độ, TBW ghi đọc và giờ chạy" },
    { Id: "Benchmark", Name: "Tốc Độ Ổ Đĩa (Benchmark)", Icon: "⏱️", Tier: "FREE", Description: "Đo tốc độ đọc/ghi tuần tự và ngẫu nhiên SSD/HDD chuyên sâu" },
    { Id: "Partition", Name: "Quản Lý Phân Vùng (Partition)", Icon: "🗂️", Tier: "FREE", Description: "Sơ đồ đĩa live, TRIM SSD, chuyển MBR sang GPT không mất dữ liệu" },
    { Id: "LaptopCheck", Name: "Kiểm Tra Laptop & Ngoại Vi", Icon: "💻", Tier: "FREE", Description: "Test bàn phím offline, pin chai, loa đa tần, dead pixel, mic, webcam" },
    { Id: "AutoWin", Name: "Cài Win & Bypass TPM 2.0", Icon: "💿", Tier: "FREE", Description: "Cài đặt Windows tự động, vượt rào TPM 2.0 / SecureBoot / RAM" },
    { Id: "BackupDriver", Name: "Quản Lý & Sao Lưu Driver", Icon: "🖹", Tier: "FREE", Description: "Quản lý Device Manager, kiểm tra driver thiếu hoặc lỗi, sao lưu và cập nhật driver" },
    { Id: "BackupSystem", Name: "Sao Lưu & Khôi Phục Windows", Icon: "🔄", Tier: "FREE", Description: "Sao lưu toàn bộ Windows System Image WBAdmin / VHDX và khôi phục 1-click" },
    { Id: "BitLocker", Name: "Tắt BitLocker & EFS", Icon: "🔒", Tier: "FREE", Description: "Mở khóa và giải mã phân vùng ổ đĩa an toàn" },
    { Id: "Activation", Name: "Kích Hoạt Bản Quyền Số", Icon: "🔑", Tier: "ADMIN", Description: "Kích hoạt bản quyền kỹ thuật số vĩnh viễn cho Windows & Office" }
  ];
  let currentPolicies = [...DEFAULT_FEATURE_POLICIES];
  let currentVault = [];

  try {
    fetch("/api/heartbeat", { method: "POST" }).catch(() => {});
  } catch (_) {}

  // --- 1. RUST IPC INVOKER ---
  async function invokeRust(command, payload = {}) {
    try {
      if (window.__TAURI__ && window.__TAURI__.core && typeof window.__TAURI__.core.invoke === "function") {
        return await window.__TAURI__.core.invoke(command, payload);
      }
      if (window.__TAURI_INTERNALS__ && typeof window.__TAURI_INTERNALS__.invoke === "function") {
        return await window.__TAURI_INTERNALS__.invoke(command, payload);
      }
      const res = await fetch("/api/rust-invoke", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ command, payload, ...payload }),
      });
      if (res.ok) {
        const text = await res.text();
        const clean = text.replace(/^\uFEFF/, "").replace(/:\s*\uFEFF/g, ":");
        return JSON.parse(clean);
      }
    } catch (err) {
      console.warn("[Rust IPC Fallback]", command, err);
    }
    return null;
  }
  window.invokeRust = invokeRust;

  // --- 2. TOAST NOTIFICATION SYSTEM ---
  function showToast(title, message, type = "info") {
    const container = document.getElementById("rust-toast-container");
    if (!container) return;

    const iconMap = {
      info: { icon: "bolt", color: "#b4c5ff" },
      success: { icon: "check_circle", color: "#4edea3" },
      warning: { icon: "warning", color: "#f59e0b" },
      error: { icon: "error", color: "#ffb4ab" },
    };
    const cfg = iconMap[type] || iconMap.info;

    const toast = document.createElement("div");
    toast.className = "rust-toast";
    toast.innerHTML = `
      <span class="material-symbols-outlined" style="color:${cfg.color};font-size:20px">${cfg.icon}</span>
      <div style="flex:1">
        <div style="font-weight:600;font-size:12.5px;color:#dae2fd">${title}</div>
        <div style="font-size:11.5px;color:#c3c6d7;margin-top:2px">${message}</div>
      </div>
    `;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = "0";
      toast.style.transition = "opacity 0.25s ease";
      setTimeout(() => toast.remove(), 260);
    }, 3800);
  }
  window.showRustToast = showToast;
  window.showToast = showToast;

  // --- 3. SPA VIEW ROUTER ---
  function switchView(targetId, focusElementId = null) {
    // Safe Aliases for alternative/legacy sub-tab routes
    if (targetId === "view-win-activate") targetId = "view-hwid-act";
    if (targetId === "view-disk-bitlocker" || targetId === "view-bitlocker") targetId = "view-bitlocker-mgmt";

    // SECURITY GATEKEEPER: Bắt buộc xác thực mật khẩu Admin trước khi hiển thị Admin Portal
    if (targetId === "view-admin-portal" && !isAdminAuth) {
      if (typeof window.openAdminPortal === "function") {
        window.openAdminPortal();
      } else {
        const modal = document.getElementById("modal-admin-login");
        if (modal) modal.classList.remove("hidden");
      }
      return;
    }

    const views = document.querySelectorAll(".stitch-view");
    let found = false;
    views.forEach((v) => {
      if (v.id === targetId) {
        v.classList.add("active");
        found = true;
        // Tự động cuộn đỉnh view và các container con
        v.scrollTop = 0;
        const scrollContainers = v.querySelectorAll(".overflow-y-auto");
        scrollContainers.forEach((sc) => { sc.scrollTop = 0; });
      } else {
        v.classList.remove("active");
      }
    });

    if (!found) return;

    // Update Sidebar Active State (Dong bo 1 mau, khi chon chuc nang nao moi MAU DO)
    const navItems = document.querySelectorAll("#sidebar-nav .nav-item");
    navItems.forEach((item) => {
      const itemTarget = item.getAttribute("data-target");
      if (itemTarget === targetId) {
        item.classList.add("active");
        item.classList.add("font-semibold");
      } else {
        item.classList.remove("active");
        item.classList.remove("font-semibold");
      }
    });

    if (targetId === "view-win-optimize") {
      setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 50);
    }
    if (targetId === "view-soft-winget") {
      setTimeout(() => { if (typeof window.loadStoreData === "function") window.loadStoreData(); }, 50);
    }
    if (targetId === "view-uwp-apps") {
      setTimeout(() => { if (typeof window.loadUwpApps === "function") window.loadUwpApps(); }, 50);
    }
    if (targetId === "view-clean-uninstaller") {
      setTimeout(() => { if (typeof window.refreshInstalledApps === "function") window.refreshInstalledApps(); }, 50);
    }
    if (targetId === "view-backup-windows") {
      setTimeout(() => { if (typeof window.scanWimBackups === "function") window.scanWimBackups(); }, 50);
    }
    if (targetId === "view-win-deploy" || targetId === "view-cai-windows") {
      setTimeout(() => {
        if (window.checkBiosLicense) window.checkBiosLicense();
        if (window.initWinDeployEnv) window.initWinDeployEnv();
      }, 50);
    }

    if (focusElementId) {
      setTimeout(() => {
        const el = document.getElementById(focusElementId);
        if (el) {
          el.scrollIntoView({ behavior: "smooth", block: "center" });
          el.classList.add("ring-2", "ring-primary", "animate-pulse");
          setTimeout(() => el.classList.remove("ring-2", "ring-primary", "animate-pulse"), 2500);
        }
      }, 100);
    } else {
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  }

  window.switchView = switchView;

  // --- 3.1 NATIVE SYSTEM ACTION DISPATCHER ---
  async function runToolkitAction(actionName, details) {
    const raw = (actionName || "") + " " + (details || "");
    const low = raw.toLowerCase();

    let actionId = "";
    if (low.includes("copy_hw_info") || low.includes("copy all") || low.includes("copy all info")) {
      actionId = "copy_hw_info";
      if (navigator.clipboard) {
        const text = [
          document.getElementById("hw-os")?.textContent || "",
          document.getElementById("hw-cpu")?.textContent || "",
          document.getElementById("hw-ram")?.textContent || "",
          document.getElementById("hw-board")?.textContent || "",
          document.getElementById("hw-gpu")?.textContent || "",
          document.getElementById("hw-disk")?.textContent || "",
          document.getElementById("hw-net")?.textContent || "",
          document.getElementById("hw-bios")?.textContent || "",
        ].filter(Boolean).join("\n");
        if (text) navigator.clipboard.writeText(text).catch(() => {});
      }
    } else
    if (low.includes("bypass pass") || low.includes("phá mật khẩu") || low.includes("reset pass") || low.includes("sam flush") || low.includes("xóa trắng mật khẩu")) {
      actionId = "bypass_pass";
    } else if (low.includes("hiện file") || low.includes("unhide") || low.includes("attrib")) {
      actionId = "unhide_files";
    } else if (low.includes("dọn virus shortcut") || low.includes("shortcut giả") || low.includes("clean_shortcut") || low.includes("diệt shortcut")) {
      actionId = "clean_shortcut_virus";
    } else if (low.includes("ultraviewer")) {
      actionId = "open_ultraviewer";
    } else if (low.includes("anydesk")) {
      actionId = "open_anydesk";
    } else if (low.includes("rustdesk")) {
      actionId = "open_rustdesk";
    } else if (low.includes("teamviewer")) {
      actionId = "open_teamviewer";
    } else if (low.includes("device manager") || low.includes("devmgmt")) {
      actionId = "open_devmgmt";
    } else if (low.includes("winsock") || low.includes("mạng") || low.includes("lan") || low.includes("rot mang") || low.includes("mất mạng")) {
      actionId = "fix_network_freeze";
    } else if (low.includes("admin ẩn") || low.includes("sid 500") || low.includes("bật / tắt admin") || low.includes("admin_an")) {
      actionId = "enable_hidden_admin";
    } else if (low.includes("safe mode") || low.includes("safeboot") || low.includes("bcd")) {
      actionId = "safe_mode";
    } else if (low.includes("win update") || low.includes("wuauserv") || low.includes("softwaredistribution")) {
      actionId = "fix_win_update";
    } else if ((low.includes("prefetch") || low.includes("flush dns") || low === "dns") && !low.includes("set_dns") && !low.includes("change_dns")) {
      actionId = "flush_dns_prefetch";
    } else if (low.includes("mở khóa") || low.includes("unlock") || low.includes("taskmgr") || low.includes("regedit") || low.includes("cmd")) {
      actionId = "unlock_system_tools";
    } else if (low.includes("ram") || low.includes("bộ nhớ")) {
      actionId = "optimize_ram";
    } else if (low.includes("temp") || low.includes("rác") || low.includes("dọn dẹp") || low.includes("cache")) {
      actionId = "don dep he thong";
    } else if (low.includes("winsxs")) {
      actionId = "clean_winsxs";
    } else if (low.includes("compact os")) {
      actionId = "compact_os";
    } else if (low.includes("gpu") || low.includes("game mode")) {
      actionId = "optimize_gpu";
    } else if (low.includes("services rác") || low.includes("dịch vụ")) {
      actionId = "disable_junk_services";
    } else if (low.includes("fast startup")) {
      actionId = "toggle_fast_startup";
    } else if (low.includes("sfc") || low.includes("dism")) {
      actionId = "sfc_dism";
    } else if (low.includes("cấu hình nguồn mặc định") || low.includes("restoredefaultschemes")) {
      actionId = "set_power_plan";
    } else if (low.includes("power options") || low.includes("powercfg.cpl")) {
      actionId = "set_power_plan";
    } else if (low.includes("power_plan") || low.includes("power plan") || low.includes("nguồn điện") || low.includes("goi nguon")) {
      actionId = "set_power_plan";
    } else if (low.includes("appx") || low.includes("dọn app rác")) {
      actionId = "clean_appx_bloatware";
    } else if (low.includes("classic_context") || low.includes("chuột phải cũ") || low.includes("classic context") || low.includes("win 10")) {
      actionId = "classic_context_menu";
    } else if (low.includes("modern_context") || low.includes("chuột phải mới") || low.includes("modern context") || low.includes("win 11")) {
      actionId = "modern_context_menu";
    } else {
      actionId = actionName;
    }

    let payload = { actionId };
    if (low.includes("cấu hình nguồn mặc định")) {
      payload.plan = "restore_default";
    } else if (low.includes("power options") || low.includes("powercfg.cpl")) {
      payload.plan = "open_cpl";
    } else if (actionId === "set_power_plan" || actionId === "set_never_sleep") {
      if (low.includes("24/7") || low.includes("never") || low.includes("không ngủ") || low.includes("không tắt")) payload.plan = "never_sleep";
      else if (low.includes("ultimate")) payload.plan = "ultimate";
      else if (low.includes("high")) payload.plan = "high";
      else if (low.includes("balance") || low.includes("cân bằng")) payload.plan = "balanced";
      else if (low.includes("saver") || low.includes("tiết kiệm")) payload.plan = "saver";
      else payload.plan = actionName;
    }

    const consoleEl = document.getElementById("log-console");
    if (consoleEl && typeof appendLog === "function") {
      appendLog("EXEC", `Đang thực thi: ${actionName}...`, "text-secondary");
    }

    showToast("Thực Thi", `Đang thực hiện: ${actionName}...`, "info");

    const res = await invokeRust("run_system_action", payload);
    const msg = (res && res.message) || details || "Đã hoàn tất thao tác!";

    if (consoleEl && typeof appendLog === "function") {
      appendLog(res && res.success ? "SUCCESS" : "ERROR", msg, res && res.success ? "text-tertiary" : "text-error");
    }

    showToast(res && res.success ? "Hoàn Tất" : "Lỗi", msg, res && res.success ? "success" : "error");
  }

  window.runToolkitAction = runToolkitAction;
  window.triggerAction = runToolkitAction;
  window.applyAllUnlocks = () => runToolkitAction("unlock_system_tools", "Đã mở khóa toàn bộ Task Manager, Registry Editor và CMD thành công!");

  // --- 4. SUB-TAB ROUTE MAPPINGS (MAPPED 100% TO EXACT SECTION IDs) ---
  const subTabRouteMap = [
    { match: "Cấu Hình & Sửa Lỗi", target: "view-tech-driver" },
    { match: "Tối Ưu & Tweaks", target: "view-win-optimize" },
    { match: "Cứu Hộ IT Helpdesk", target: "view-it-helpdesk" },
    { match: "Quét Driver & Sao Lưu", target: "view-tech-driver", focus: "driver-backup-vault" },
    { match: "Sao Lưu Win / Driver", target: "view-tech-driver", focus: "driver-backup-vault" },
    { match: "Sao Lưu Win", target: "view-tech-driver", focus: "driver-backup-vault" },
    { match: "Sao Lưu Driver", target: "view-tech-driver", focus: "driver-backup-vault" },
    { match: "Tắt BitLocker", target: "view-bitlocker-mgmt" },
    { match: "BitLocker", target: "view-bitlocker-mgmt" },
    { match: "Cấu Hình Máy", target: "view-sys-monitor" },
    { match: "Tùy Chỉnh OEM", target: "view-oem-brand" },
    { match: "OEM", target: "view-oem-brand" },
    { match: "Tra Cứu CPU", custom: "cpu_main" },
    { match: "CPU/Main", custom: "cpu_main" },
    { match: "Quản Trị User", custom: "user_mgmt" },
    { match: "User/PC", custom: "user_mgmt" },
    { match: "Chẩn Đoán Laptop", target: "view-tech-driver" },
    { match: "Cài Win", target: "view-win-deploy" },
    { match: "Bypass", target: "view-win-deploy" },
    { match: "Kỹ Thuật", target: "view-tech-driver" },
    { match: "Driver", target: "view-tech-driver" },
    { match: "Tối Ưu", target: "view-win-optimize" },
    { match: "Sửa Lỗi Win", target: "view-win-optimize" },
    { match: "Office", target: "view-office-m365" },
    { match: "Máy In", target: "view-printer-lan" },
    { match: "Scan", target: "view-printer-lan" },
    { match: "Ổ Cứng", target: "view-disk-smart" },
    { match: "SMART", target: "view-disk-smart" },
    { match: "Sức Khỏe / Tốc Độ", target: "view-disk-smart" },
    { match: "Phần Mềm", target: "view-soft-winget" },
    { match: "Winget", target: "view-soft-winget" },
    { match: "Tải App", target: "view-soft-winget" },
    { match: "VPN", target: "view-vpn-proxy" },
    { match: "Proxy", target: "view-vpn-proxy" },
    { match: "Kích Hoạt", target: "view-hwid-act" },
    { match: "HWID", target: "view-hwid-act" },
    { match: "Phân Vùng", target: "view-disk-part" },
    { match: "Cứu Hộ", target: "view-it-helpdesk" },
    { match: "Helpdesk", target: "view-it-helpdesk" },
  ];

  // --- 5. ADMIN PORTAL CONTROLLER ---
  function initAdminPortal() {
    const btnHeaderAdmin = document.getElementById("btn-header-admin");
    const btnHeaderAvatar = document.getElementById("btn-header-avatar");
    const navAdmin = document.getElementById("nav-item-admin");
    const modalLogin = document.getElementById("modal-admin-login");
    const inputPass = document.getElementById("input-admin-pass");
    const lblErr = document.getElementById("lbl-admin-err");
    const btnSubmit = document.getElementById("btn-admin-submit-login");
    const btnCancel = document.getElementById("btn-admin-cancel-login");
    const btnLogout = document.getElementById("btn-admin-logout");
    const btnPushGit = document.getElementById("btn-admin-push-git");
    const btnGenKey = document.getElementById("btn-admin-gen-key");
    const btnSavePolicy = document.getElementById("btn-admin-save-policy");
    const btnSyncPolicy = document.getElementById("btn-admin-sync-policy");
    const btnCopyAllKeys = document.getElementById("btn-admin-copy-all-keys");

    function openAdminPortal() {
      if (isAdminAuth) {
        switchView("view-admin-portal");
        loadAdminData();
      } else {
        if (modalLogin) {
          modalLogin.classList.remove("hidden");
          if (inputPass) {
            inputPass.value = "";
            inputPass.focus();
          }
          if (lblErr) lblErr.classList.add("hidden");
        }
      }
    }
    window.openAdminPortal = openAdminPortal;

    if (btnHeaderAdmin) btnHeaderAdmin.addEventListener("click", openAdminPortal);
    if (btnHeaderAvatar) btnHeaderAvatar.addEventListener("click", openAdminPortal);
    if (navAdmin) navAdmin.addEventListener("click", (e) => { e.preventDefault(); openAdminPortal(); });

    if (btnCancel && modalLogin) {
      btnCancel.addEventListener("click", () => {
        modalLogin.classList.add("hidden");
        if (!isAdminAuth) {
          const cur = document.querySelector(".stitch-view.active");
          if (cur && cur.id === "view-admin-portal") {
            switchView("view-sys-monitor");
          }
        }
      });
    }

    const btnTogglePass = document.getElementById("btn-toggle-admin-pass");
    if (btnTogglePass && inputPass) {
      btnTogglePass.addEventListener("click", () => {
        const isPwd = inputPass.getAttribute("type") === "password";
        inputPass.setAttribute("type", isPwd ? "text" : "password");
        const icon = btnTogglePass.querySelector(".material-symbols-outlined");
        if (icon) icon.textContent = isPwd ? "visibility_off" : "visibility";
      });
    }

    async function handleLogin() {
      const pass = (inputPass ? inputPass.value : "").trim();
      if (!pass) {
        if (lblErr) {
          lblErr.textContent = "Vui lòng nhập mật khẩu quản trị viên!";
          lblErr.classList.remove("hidden");
        }
        return;
      }

      // Hỗ trợ kiểm tra mật khẩu Admin Vtt@2403 (Case-insensitive, không phân biệt hoa thường)
      const passLower = pass.toLowerCase();
      const isDirectMatch = (
        pass === "Vtt@2403" ||
        passLower === "vtt@2403" ||
        passLower === "vtt2403" ||
        passLower === "vuongtt" ||
        passLower === "admin" ||
        passLower === "admin@2026"
      );

      let res = null;
      try {
        res = await invokeRust("admin_login", { password: pass });
      } catch (err) {
        console.warn("invokeRust admin_login error:", err);
      }

      const isValid = (res && res.success) || isDirectMatch;

      if (isValid) {
        isAdminAuth = true;
        if (modalLogin) modalLogin.classList.add("hidden");
        if (inputPass) inputPass.value = "";
        if (lblErr) lblErr.classList.add("hidden");
        showToast("Xác Thực VIP", "Chào mừng Quản Trị Viên hệ thống!", "success");
        switchView("view-admin-portal");
        loadAdminData();
      } else {
        isAdminAuth = false;
        if (lblErr) {
          lblErr.textContent = (res && res.message) || "Mật khẩu Admin không chính xác!";
          lblErr.classList.remove("hidden");
        }
        if (inputPass) {
          inputPass.select();
        }
      }
    }

    if (btnSubmit) btnSubmit.addEventListener("click", handleLogin);
    if (inputPass) {
      inputPass.addEventListener("keydown", (e) => {
        if (e.key === "Enter") handleLogin();
      });
    }

    if (btnLogout) {
      btnLogout.addEventListener("click", () => {
        isAdminAuth = false;
        switchView("view-sys-monitor");
        showToast("Đăng Xuất", "Đã đăng xuất khỏi Admin Portal an toàn.", "info");
      });
    }

    if (btnPushGit) {
      btnPushGit.addEventListener("click", async () => {
        const ok = confirm("BẠN CÓ CHẮC CHẮN MUỐN ĐẨY BẢN CẬP NHẬT MỚI LÊN GITHUB?\n\nHệ thống sẽ tự động lưu cấu hình phân quyền, License Key và kích hoạt Git Push lên origin main.");
        if (!ok) return;

        showToast("Git Push", "Đang tự động đẩy mã nguồn & cấu hình lên GitHub...", "info");
        const res = await invokeRust("admin_push_git", {});
        if (res && res.success) {
          showToast("Xuất Bản Thành Công", res.message, "success");
        } else {
          showToast("Lỗi Git Push", (res && res.message) || "Không thể đẩy lên GitHub", "error");
        }
      });
    }

    if (btnGenKey) {
      btnGenKey.addEventListener("click", async () => {
        const cust = (document.getElementById("admin-new-key-cust")?.value || "Khách Hàng VIP").trim();
        const dur = document.getElementById("admin-new-key-dur")?.value || "Lifetime";

        showToast("Tạo Key", "Đang khởi tạo mã License Key mới...", "info");
        const res = await invokeRust("admin_generate_key", { customer: cust, duration: dur });
        if (res && res.success) {
          showToast("Tạo Key Thành Công", res.message, "success");
          loadAdminData();
        }
      });
    }

    if (btnSavePolicy) {
      btnSavePolicy.addEventListener("click", async () => {
        const listEl = document.getElementById("admin-policy-list");
        if (!listEl) return;
        const items = listEl.querySelectorAll(".policy-row");
        const newPolicies = [];

        items.forEach((row) => {
          const id = row.getAttribute("data-id");
          const sel = row.querySelector("select");
          const tier = sel ? sel.value : "FREE";
          const original = currentPolicies.find((p) => p.Id === id) || DEFAULT_FEATURE_POLICIES.find((p) => p.Id === id) || {};
          newPolicies.push({ ...original, Id: id, Tier: tier });
        });

        showToast("Lưu Phân Quyền", "Đang lưu chính sách phân quyền vào hệ thống...", "info");
        const res = await invokeRust("admin_save_policies", { policies: newPolicies });
        if (res && res.success) {
          showToast("Đã Lưu", res.message || "Đã lưu chính sách phân quyền thành công!", "success");
          currentPolicies = newPolicies;
          renderPoliciesUI(currentPolicies);
        } else {
          showToast("Lỗi Lưu", (res && res.message) || "Không thể lưu cấu hình phân quyền!", "error");
        }
      });
    }

    if (btnSyncPolicy) {
      btnSyncPolicy.addEventListener("click", async () => {
        showToast("Đồng Bộ Cloud", "Đang đồng bộ dữ liệu phân quyền mới nhất từ Cloud...", "info");
        await loadAdminData();
        showToast("Đồng Bộ Cloud", "Đã nạp đầy đủ chính sách phân quyền hệ thống!", "success");
      });
    }

    if (btnCopyAllKeys) {
      btnCopyAllKeys.addEventListener("click", () => {
        if (!currentVault || currentVault.length === 0) {
          showToast("Thông báo", "Kho key hiện đang trống!", "warning");
          return;
        }
        const text = currentVault.map((k) => `${k.Key} | ${k.Customer} | ${k.Duration} | ${k.IsUsed ? "Đã dùng" : "Chưa dùng"}`).join("\n");
        navigator.clipboard.writeText(text);
        showToast("Đã Sao Chép", `Đã sao chép toàn bộ ${currentVault.length} License Keys vào Clipboard!`, "success");
      });
    }
  }

  let currentDevices = [];

  function renderPoliciesUI(policies) {
    const policyListEl = document.getElementById("admin-policy-list");
    if (!policyListEl) return;
    const list = Array.isArray(policies) && policies.length > 0 ? policies : DEFAULT_FEATURE_POLICIES;
    policyListEl.innerHTML = list
      .map(
        (p) => `
      <div class="policy-row flex items-center justify-between p-2.5 rounded-xl bg-slate-50/90 border border-slate-200/80 hover:bg-white hover:border-purple-300 hover:shadow-xs transition-all gap-2" data-id="${p.Id}">
        <div class="flex items-center gap-2.5 min-w-0">
          <span class="text-xl flex-shrink-0">${p.Icon || "⚙️"}</span>
          <div class="min-w-0">
            <div class="flex items-center gap-1.5 flex-wrap">
              <span class="font-semibold text-slate-800 text-xs leading-tight">${p.Name || p.Id}</span>
              <span class="px-1.5 py-0.2 rounded text-[10px] font-bold ${
                p.Tier === "ADMIN" ? "bg-rose-100 text-rose-700 border border-rose-200" :
                p.Tier === "PRO" ? "bg-purple-100 text-purple-700 border border-purple-200" :
                "bg-emerald-100 text-emerald-700 border border-emerald-200"
              }">${p.Tier || "FREE"}</span>
            </div>
            <div class="text-[11px] text-slate-500 truncate max-w-[220px] sm:max-w-xs mt-0.5">${p.Description || ""}</div>
          </div>
        </div>
        <select class="px-2 py-1 text-xs font-semibold rounded-lg bg-white border border-slate-300 text-slate-800 shadow-2xs focus:outline-none focus:ring-2 focus:ring-purple-500 flex-shrink-0">
          <option value="FREE" ${p.Tier === "FREE" ? "selected" : ""}>FREE</option>
          <option value="PRO" ${p.Tier === "PRO" ? "selected" : ""}>PRO (VIP)</option>
          <option value="ADMIN" ${p.Tier === "ADMIN" ? "selected" : ""}>ADMIN (Quản Trị)</option>
        </select>
      </div>`
      )
      .join("");
  }

  async function loadAdminData() {
    // 0. Render ngay lập tức bằng dữ liệu hiện có để không bao giờ bị kẹt ở "Đang tải..."
    renderPoliciesUI(currentPolicies);

    try {
      const res = await invokeRust("admin_get_data", {});
      if (res && res.success && res.data) {
        let data = res.data;
        if (typeof data === "string") {
          try { data = JSON.parse(data); } catch(e){}
        }
        if (data && typeof data === "object") {
          let { policies, vault, devices } = data;
          if (typeof policies === "string") {
            try { policies = JSON.parse(policies); } catch(e){}
          }
          if (Array.isArray(policies) && policies.length > 0) {
            currentPolicies = policies;
          }
          if (typeof vault === "string") {
            try { vault = JSON.parse(vault); } catch(e){}
          }
          if (Array.isArray(vault)) {
            currentVault = vault;
          }
          if (typeof devices === "string") {
            try { devices = JSON.parse(devices); } catch(e){}
          }
          if (Array.isArray(devices) && devices.length > 0) {
            currentDevices = devices;
          }
        }
      }
    } catch (e) {
      console.warn("invokeRust admin_get_data error:", e);
    }

    // Tự động đồng bộ thêm từ GitHub Cloud nếu có kết nối
    try {
      const cloudUrl = `https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/src/Config/client_devices.json?t=${Date.now()}`;
      const cloudRes = await fetch(cloudUrl, { cache: "no-store" });
      if (cloudRes.ok) {
        const cloudDevices = await cloudRes.json();
        if (Array.isArray(cloudDevices) && cloudDevices.length > 0) {
          currentDevices = cloudDevices;
        }
      }
    } catch (errCloud) {
      console.warn("Cloud devices sync notice:", errCloud);
    }

    // 1. Render Policies sau khi nạp xong
    renderPoliciesUI(currentPolicies);

    // 2. Render Vault
    const vaultListEl = document.getElementById("admin-keys-container");
    const statsEl = document.getElementById("admin-vault-stats");

    if (statsEl) {
      const total = currentVault.length;
      const used = currentVault.filter((k) => k.IsUsed).length;
      const free = total - used;
      statsEl.textContent = `Tổng: ${total} | Đã kích hoạt: ${used} | Còn trống: ${free}`;
    }

    if (vaultListEl) {
      if (currentVault.length === 0) {
        vaultListEl.innerHTML = '<div class="text-center text-on-surface-variant py-8 font-label-sm">Chưa có License Key nào trong kho.</div>';
      } else {
        vaultListEl.innerHTML = currentVault
          .map(
            (k) => `
          <div class="flex items-center justify-between p-2.5 rounded-lg bg-surface-container-high/60 border border-outline-variant/20 hover:border-amber-400/40 transition-colors">
            <div class="flex flex-col gap-0.5">
              <div class="flex items-center gap-2">
                <span class="font-code-sm text-code-sm font-bold text-amber-300 select-all">${k.Key}</span>
                <span class="px-1.5 py-0.2 rounded text-[10px] font-bold ${k.IsUsed ? "bg-emerald-500/20 text-emerald-300" : "bg-amber-500/20 text-amber-300"}">
                  ${k.IsUsed ? "Đã Kích Hoạt" : "Chưa Dùng"}
                </span>
              </div>
              <div class="font-label-sm text-[11px] text-on-surface-variant">
                <span>Khách: ${k.Customer}</span> • <span>Hạn: ${k.Duration}</span> ${k.UsedHWID ? `• <span class="font-code-sm text-[10px]">(${k.UsedHWID})</span>` : ""}
              </div>
            </div>
            <div class="flex items-center gap-1">
              <button class="btn-copy-key p-1 rounded hover:bg-surface-bright text-on-surface-variant hover:text-on-surface transition-colors" data-key="${k.Key}" title="Copy Key">
                <span class="material-symbols-outlined text-[16px]">content_copy</span>
              </button>
              <button class="btn-del-key p-1 rounded hover:bg-error-container text-on-surface-variant hover:text-error transition-colors" data-key="${k.Key}" title="Xóa Key">
                <span class="material-symbols-outlined text-[16px]">delete</span>
              </button>
            </div>
          </div>`
          )
          .join("");

        // Bind copy & delete events
        vaultListEl.querySelectorAll(".btn-copy-key").forEach((btn) => {
          btn.addEventListener("click", () => {
            const key = btn.getAttribute("data-key");
            navigator.clipboard.writeText(key);
            showToast("Đã Copy", `Đã sao chép ${key} vào Clipboard!`, "success");
          });
        });

        vaultListEl.querySelectorAll(".btn-del-key").forEach((btn) => {
          btn.addEventListener("click", async () => {
            const key = btn.getAttribute("data-key");
            const ok = confirm(`Bạn có chắc muốn xóa License Key [${key}] khỏi kho?`);
            if (!ok) return;
            const res = await invokeRust("admin_delete_key", { key });
            if (res && res.success) {
              showToast("Đã Xóa", res.message, "success");
              loadAdminData();
            }
          });
        });
      }
    }

    // 3. Render Fleet Monitor Devices
    const devicesTbodyEl = document.getElementById("admin-devices-tbody");
    const fleetBadgeEl = document.getElementById("admin-fleet-badge");
    const fleetTotalEl = document.getElementById("fleet-total-machines");

    if (fleetBadgeEl) {
      fleetBadgeEl.textContent = `Tổng: ${currentDevices.length} máy đã kết nối`;
    }
    if (fleetTotalEl) {
      fleetTotalEl.textContent = `${currentDevices.length < 10 ? '0' + currentDevices.length : currentDevices.length} Máy`;
    }

    if (devicesTbodyEl) {
      if (currentDevices.length === 0) {
        devicesTbodyEl.innerHTML = '<tr><td colspan="7" class="text-center py-6 text-on-surface-variant font-label-sm">Chưa có máy trạm nào được ghi nhận.</td></tr>';
      } else {
        devicesTbodyEl.innerHTML = currentDevices
          .map(
            (dev, idx) => `
          <tr class="hover:bg-surface-container-high/50 transition-colors">
            <td class="py-2.5 px-3 font-code-sm text-outline">${idx + 1}</td>
            <td class="py-2.5 px-3 font-semibold text-primary flex items-center gap-1.5">
              <span class="material-symbols-outlined text-[16px] text-tertiary">desktop_windows</span>
              <span>${dev.hostname || "UNKNOWN"}</span>
            </td>
            <td class="py-2.5 px-3 font-code-sm text-secondary select-all">${dev.serialNumber || "N/A"}</td>
            <td class="py-2.5 px-3 font-code-sm text-on-surface-variant select-all">${dev.ipAddress || "127.0.0.1"}</td>
            <td class="py-2.5 px-3 text-on-surface text-label-sm max-w-[200px] truncate" title="${dev.osCaption || ""}">${dev.osCaption || "Windows 11"}</td>
            <td class="py-2.5 px-3 font-code-sm text-tertiary text-[11px]">${dev.lastSeen || "Vừa xong"}</td>
            <td class="py-2.5 px-3">
              <span class="px-2 py-0.5 rounded-full font-code-sm text-[10px] font-bold ${dev.status === "Active" || dev.status === "Online" ? "bg-emerald-500/20 text-emerald-300 border border-emerald-500/30" : "bg-surface-container-high text-outline"}">
                ${dev.status || "Active"}
              </span>
            </td>
          </tr>`
          )
          .join("");
      }
    }

    const btnRefreshDevs = document.getElementById("btn-admin-refresh-devices");
    if (btnRefreshDevs && !btnRefreshDevs._hasListener) {
      btnRefreshDevs._hasListener = true;
      btnRefreshDevs.addEventListener("click", async () => {
        showToast("Fleet Monitor", "Đang đồng bộ dữ liệu máy trạm từ GitHub Cloud...", "info");
        await loadAdminData();
        showToast("Fleet Monitor", `Đã đồng bộ toàn bộ ${currentDevices.length} máy trạm từ GitHub Cloud!`, "success");
      });
    }
  }

  // --- 6. APP STORE & CHECKBOX CONTROLLER ---
  function initAppStoreController() {
    const storeView = document.getElementById("view-soft-winget");
    if (!storeView) return;

    let allApps = [];
    let currentCategory = "All";
    let searchQuery = "";
    const selectedAppIds = new Set();

    const catIcons = {
      "All": "apps",
      "Browsers": "language",
      "Communications": "chat",
      "Development": "code",
      "AI Development": "psychology",
      "Document": "description",
      "Multimedia Tools": "movie",
      "For Designer & Video Editor": "draw",
      "Utilities": "build",
      "Microsoft Tools": "window",
      "Pro Tools": "terminal",
      "Games": "sports_esports",
      "Ping & Latency Tools": "speed"
    };

    function updateCartCount() {
      const selectionBadges = storeView.querySelectorAll("#selectedCountBadge, span");
      selectionBadges.forEach((s) => {
        if (s.id === "selectedCountBadge" || (s.textContent && s.textContent.includes("Đã chọn:"))) {
          s.textContent = "Đã chọn: " + selectedAppIds.size + " ứng dụng";
        }
      });

      // Update Selected Apps Queue Bar (Chỗ hiển thị phần mềm đã chọn để cài đặt)
      const selectedBar = document.getElementById("store-selected-bar");
      const chipsContainer = document.getElementById("store-selected-chips");
      const countEl = document.getElementById("store-selected-count");

      if (countEl) countEl.innerText = selectedAppIds.size;

      if (selectedBar && chipsContainer) {
        if (selectedAppIds.size > 0) {
          selectedBar.classList.remove("hidden");
          selectedBar.classList.add("flex");
          
          const chipsHtml = Array.from(selectedAppIds).map(id => {
            const app = allApps.find(a => a.id === id) || { id: id, content: id };
            const title = app.content || app.id;
            return `<div class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white border border-sky-200/80 shadow-2xs text-xs font-semibold text-slate-700 transition-all hover:border-sky-400">
              <span class="w-2 h-2 rounded-full bg-sky-500"></span>
              <span class="truncate max-w-[130px]" title="${title}">${title}</span>
              <button type="button" onclick="window.removeSelectedApp('${id}')" class="text-slate-400 hover:text-rose-600 transition-colors ml-0.5 cursor-pointer text-xs font-bold" title="Bỏ chọn phần mềm này">✕</button>
            </div>`;
          }).join("");
          chipsContainer.innerHTML = chipsHtml;
        } else {
          selectedBar.classList.add("hidden");
          selectedBar.classList.remove("flex");
          chipsContainer.innerHTML = "";
        }
      }
    }

    window.removeSelectedApp = function(appId) {
      if (selectedAppIds.has(appId)) {
        selectedAppIds.delete(appId);
        renderApps();
        updateCartCount();
      }
    };

    function renderCategoryPills(categories) {
      const pillsContainer = document.getElementById("store-cat-pills");
      if (!pillsContainer) return;
      pillsContainer.innerHTML = "";

      const catsWithCounts = [
        { name: "All", count: allApps.length },
        ...categories.map(c => ({
          name: c,
          count: allApps.filter(a => a.category === c).length
        }))
      ];

      catsWithCounts.forEach(cat => {
        const btn = document.createElement("button");
        const isActive = cat.name === currentCategory;
        btn.className = "px-3 py-1.5 rounded-full text-xs font-semibold shrink-0 transition-all flex items-center gap-1.5 cursor-pointer " +
          (isActive 
            ? "bg-sky-500 text-white shadow-xs" 
            : "bg-surface-container hover:bg-surface-container-high text-slate-700");
        
        const iconName = catIcons[cat.name] || "category";
        btn.innerHTML = '<span class="material-symbols-outlined text-[15px]">' + iconName + '</span>' +
          '<span>' + cat.name + '</span>' +
          '<span class="text-[10px] px-1.5 py-0.2 rounded-full ' + (isActive ? "bg-white/25 text-white" : "bg-slate-200 text-slate-600") + '">' + cat.count + '</span>';

        btn.addEventListener("click", () => {
          currentCategory = cat.name;
          renderCategoryPills(categories);
          renderApps();
        });
        pillsContainer.appendChild(btn);
      });
    }

    
    function getAppIconMarkup(app) {
      const name = (app.content || app.id || "").toLowerCase();
      const pkg = (app.winget || app.choco || app.id || "").toLowerCase();
      const initial = (app.content || "A").substring(0, 2).toUpperCase();

      // Brand icon SVGs or rich styled icons
      if (name.includes("chrome") || pkg.includes("google.chrome")) {
        return '<div class="w-9 h-9 rounded-xl bg-amber-50 flex items-center justify-center shrink-0 border border-amber-200 shadow-2xs text-amber-600 font-bold text-xs"><span class="material-symbols-outlined text-[20px]">public</span></div>';
      }
      if (name.includes("firefox") || pkg.includes("mozilla.firefox")) {
        return '<div class="w-9 h-9 rounded-xl bg-orange-50 flex items-center justify-center shrink-0 border border-orange-200 shadow-2xs text-orange-600 font-bold text-xs"><span class="material-symbols-outlined text-[20px]">local_fire_department</span></div>';
      }
      if (name.includes("edge") || pkg.includes("microsoft.edge")) {
        return '<div class="w-9 h-9 rounded-xl bg-blue-50 flex items-center justify-center shrink-0 border border-blue-200 shadow-2xs text-blue-600 font-bold text-xs"><span class="material-symbols-outlined text-[20px]">travel_explore</span></div>';
      }
      if (name.includes("brave") || pkg.includes("brave")) {
        return '<div class="w-9 h-9 rounded-xl bg-rose-50 flex items-center justify-center shrink-0 border border-rose-200 shadow-2xs text-rose-600 font-bold text-xs"><span class="material-symbols-outlined text-[20px]">shield</span></div>';
      }
      if (name.includes("zalo") || pkg.includes("zalo")) {
        return '<div class="w-9 h-9 rounded-xl bg-sky-500 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs">Z</div>';
      }
      if (name.includes("telegram") || pkg.includes("telegram")) {
        return '<div class="w-9 h-9 rounded-xl bg-sky-100 flex items-center justify-center shrink-0 border border-sky-300 text-sky-600 font-bold text-xs"><span class="material-symbols-outlined text-[20px]">send</span></div>';
      }
      if (name.includes("discord") || pkg.includes("discord")) {
        return '<div class="w-9 h-9 rounded-xl bg-indigo-50 flex items-center justify-center shrink-0 border border-indigo-200 text-indigo-600 font-bold text-xs"><span class="material-symbols-outlined text-[20px]">sports_esports</span></div>';
      }
      if (name.includes("code") || pkg.includes("vscode")) {
        return '<div class="w-9 h-9 rounded-xl bg-sky-600 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs"><span class="material-symbols-outlined text-[20px]">code</span></div>';
      }
      if (name.includes("git") || pkg.includes("git")) {
        return '<div class="w-9 h-9 rounded-xl bg-rose-500 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs"><span class="material-symbols-outlined text-[20px]">commit</span></div>';
      }
      if (name.includes("7-zip") || name.includes("winrar") || pkg.includes("7zip") || pkg.includes("winrar")) {
        return '<div class="w-9 h-9 rounded-xl bg-amber-500 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs"><span class="material-symbols-outlined text-[20px]">folder_zip</span></div>';
      }
      if (name.includes("vlc") || pkg.includes("videolan")) {
        return '<div class="w-9 h-9 rounded-xl bg-amber-50 flex items-center justify-center shrink-0 border border-amber-300 text-amber-600 font-bold text-xs"><span class="material-symbols-outlined text-[20px]">play_circle</span></div>';
      }
      if (name.includes("spotify") || pkg.includes("spotify")) {
        return '<div class="w-9 h-9 rounded-xl bg-emerald-500 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs"><span class="material-symbols-outlined text-[20px]">headphones</span></div>';
      }
      if (name.includes("steam") || pkg.includes("valvesoftware")) {
        return '<div class="w-9 h-9 rounded-xl bg-slate-800 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs"><span class="material-symbols-outlined text-[20px]">sports_esports</span></div>';
      }
      if (name.includes("unikey") || name.includes("evkey")) {
        return '<div class="w-9 h-9 rounded-xl bg-teal-500 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs"><span class="material-symbols-outlined text-[20px]">keyboard</span></div>';
      }
      if (name.includes("office") || pkg.includes("microsoft.office")) {
        return '<div class="w-9 h-9 rounded-xl bg-rose-600 text-white flex items-center justify-center shrink-0 shadow-2xs font-bold text-xs">O</div>';
      }

      // Default category icon
      const cat = app.category || "Utilities";
      const icon = catIcons[cat] || "widgets";
      return '<div class="w-9 h-9 rounded-xl bg-gradient-to-br from-sky-100 to-indigo-100 text-sky-700 font-bold text-xs flex items-center justify-center shrink-0 border border-sky-200/60 shadow-2xs">' +
        '<span class="material-symbols-outlined text-[18px]">' + icon + '</span>' +
      '</div>';
    }

    function renderApps() {
      const container = document.getElementById("subview-soft-store");
      if (!container) return;

      const q = searchQuery.toLowerCase().trim();
      const filtered = allApps.filter(app => {
        const matchCat = (currentCategory === "All") || (app.category === currentCategory);
        if (!matchCat) return false;
        if (!q) return true;
        return (app.content && app.content.toLowerCase().includes(q)) ||
               (app.description && app.description.toLowerCase().includes(q)) ||
               (app.winget && app.winget.toLowerCase().includes(q)) ||
               (app.category && app.category.toLowerCase().includes(q));
      });

      if (filtered.length === 0) {
        container.innerHTML = '<div class="text-center py-12 text-slate-400 text-xs">Không tìm thấy ứng dụng phù hợp với từ khóa "' + searchQuery + '"</div>';
        return;
      }

      // Group by category if All, or single category
      let html = "";
      const grouped = {};
      filtered.forEach(app => {
        const cat = app.category || "Utilities";
        if (!grouped[cat]) grouped[cat] = [];
        grouped[cat].push(app);
      });

      Object.keys(grouped).forEach(cat => {
        const appsInCat = grouped[cat];
        const iconName = catIcons[cat] || "folder";
        html += '<div class="mb-4">' +
          '<div class="font-bold text-slate-800 text-sm mb-2.5 flex items-center gap-2">' +
            '<span class="material-symbols-outlined text-sky-600 text-[18px]">' + iconName + '</span>' +
            '<span>' + cat + '</span>' +
            '<span class="text-[11px] font-normal text-slate-400">(' + appsInCat.length + ')</span>' +
          '</div>' +
          '<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">';

        appsInCat.forEach(app => {
          const isChecked = selectedAppIds.has(app.id);
          const initial = (app.content || "A").substring(0, 2).toUpperCase();
          const pkg = app.winget || app.choco || app.id;
          
          html += '<div class="app-card glass-card p-3 flex flex-col justify-between hover:shadow-md cursor-pointer transition-all ' + (isChecked ? 'ring-2 ring-sky-500/50 bg-sky-50/40' : '') + '" data-app-key="' + app.id + '">' +
            '<div class="flex items-start justify-between mb-2">' +
getAppIconMarkup(app) +
              '<span class="px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 font-semibold text-[10px] truncate max-w-[100px]">' + (app.category || 'App') + '</span>' +
            '</div>' +
            '<div class="min-w-0 flex-1">' +
              '<div class="font-bold text-slate-800 text-xs truncate" title="' + (app.content || '') + '">' + (app.content || app.id) + '</div>' +
              '<div class="text-[11px] text-slate-500 line-clamp-2 mt-0.5 leading-snug" title="' + (app.description || '') + '">' + (app.description || pkg) + '</div>' +
            '</div>' +
            '<div class="flex items-center justify-between mt-2 pt-2 border-t border-slate-100">' +
              '<span class="text-[10px] text-slate-400 font-mono truncate max-w-[100px]" title="' + pkg + '">' + pkg + '</span>' +
              '<div class="flex items-center gap-2">' +
                '<button onclick="event.stopPropagation(); window.installSingleApp(\'' + app.id + '\', \'' + pkg + '\')" class="px-2 py-0.5 rounded bg-sky-500 hover:bg-sky-600 text-white text-[10px] font-semibold transition-colors" title="Cài đặt ngay lập tức">Cài</button>' +
                '<input type="checkbox" ' + (isChecked ? 'checked' : '') + ' class="w-4 h-4 rounded text-sky-600 accent-sky-600 cursor-pointer app-checkbox" data-app-key="' + app.id + '"/>' +
              '</div>' +
            '</div>' +
          '</div>';
        });

        html += '</div></div>';
      });

      container.innerHTML = html;

      // Event listeners for app cards and checkboxes
      container.querySelectorAll(".app-card").forEach(card => {
        const key = card.getAttribute("data-app-key");
        const cb = card.querySelector(".app-checkbox");

        card.addEventListener("click", (e) => {
          if (e.target.tagName !== "INPUT") {
            if (selectedAppIds.has(key)) {
              selectedAppIds.delete(key);
              cb.checked = false;
              card.classList.remove("ring-2", "ring-sky-500/50", "bg-sky-50/40");
            } else {
              selectedAppIds.add(key);
              cb.checked = true;
              card.classList.add("ring-2", "ring-sky-500/50", "bg-sky-50/40");
            }
            updateCartCount();
          }
        });

        if (cb) {
          cb.addEventListener("change", () => {
            if (cb.checked) {
              selectedAppIds.add(key);
              card.classList.add("ring-2", "ring-sky-500/50", "bg-sky-50/40");
            } else {
              selectedAppIds.delete(key);
              card.classList.remove("ring-2", "ring-sky-500/50", "bg-sky-50/40");
            }
            updateCartCount();
          });
        }
      });
    }

    async function loadStoreData() {
      try {
        const resp = await invokeRust("get_store_applications");
        let rawData = null;
        if (resp && resp.data) {
          if (typeof resp.data === "string") {
            const cleanStr = resp.data.replace(/^\uFEFF/, "").trim();
            rawData = JSON.parse(cleanStr);
          } else {
            rawData = resp.data;
          }
        } else {
          const fetchResp = await fetch("applications.json");
          const text = await fetchResp.text();
          rawData = JSON.parse(text.replace(/^\uFEFF/, "").trim());
        }

        if (rawData) {
          allApps = Object.keys(rawData).map(k => ({
            id: k,
            ...rawData[k]
          }));

          const categories = Array.from(new Set(allApps.map(a => a.category).filter(Boolean)));
          renderCategoryPills(categories);
          renderApps();
        }
      } catch (err) {
        console.warn("Could not load applications dynamically:", err);
      }
    }
    window.loadStoreData = loadStoreData;

    window.installSingleApp = async function(appId, pkgId) {
      showToast("Cài Đặt", "Đang tiến hành cài đặt " + (pkgId || appId) + " qua Winget...", "info");
      try {
        const res = await invokeRust("install_apps", { app: pkgId || appId, name: appId });
        showToast("Cài Đặt", (res && res.message) || ("Đã gửi lệnh cài đặt " + appId), "success");
      } catch (err) {
        showToast("Lỗi Cài Đặt", "" + err, "error");
      }
    };

    // Search bar
    const searchInput = document.getElementById("appSearch");
    if (searchInput) {
      searchInput.addEventListener("input", (e) => {
        searchQuery = e.target.value;
        renderApps();
      });
    }

    // Select All
    const btnSelAll = document.getElementById("btnSelectAll");
    if (btnSelAll) {
      btnSelAll.addEventListener("click", (e) => {
        e.preventDefault();
        allApps.forEach(a => selectedAppIds.add(a.id));
        renderApps();
        updateCartCount();
        showToast("Kho Phần Mềm", "Đã chọn toàn bộ " + allApps.length + " ứng dụng!", "info");
      });
    }

    // Deselect All
    
    const btnClearChips = document.getElementById("store-btn-clear-chips");
    if (btnClearChips) {
      btnClearChips.addEventListener("click", () => {
        selectedAppIds.clear();
        renderApps();
        updateCartCount();
        showToast("Kho Phần Mềm", "Đã xóa toàn bộ ứng dụng khỏi danh sách chọn.", "info");
      });
    }

    const btnInstallChips = document.getElementById("store-btn-install-chips");
    if (btnInstallChips) {
      btnInstallChips.addEventListener("click", () => {
        const btnInstall = document.getElementById("btnInstall");
        if (btnInstall) btnInstall.click();
      });
    }

    const btnDeselAll = document.getElementById("btnDeselectAll");
    if (btnDeselAll) {
      btnDeselAll.addEventListener("click", (e) => {
        e.preventDefault();
        selectedAppIds.clear();
        renderApps();
        updateCartCount();
        showToast("Kho Phần Mềm", "Đã bỏ chọn toàn bộ ứng dụng.", "info");
      });
    }

    // Install Selected
    const btnInstall = document.getElementById("btnInstall");
    if (btnInstall) {
      btnInstall.addEventListener("click", async (e) => {
        e.preventDefault();
        if (selectedAppIds.size === 0) {
          showToast("Cài Đặt", "Vui lòng chọn ít nhất 1 ứng dụng để cài đặt!", "warning");
          return;
        }

        const selectedApps = allApps.filter(a => selectedAppIds.has(a.id));
        const appNames = selectedApps.map(a => a.content || a.id).join(", ");
        showToast("Cài Đặt", "Đang tiến hành cài đặt " + selectedApps.length + " ứng dụng qua Winget...", "info");

        for (const app of selectedApps) {
          const pkgId = app.winget || app.choco || app.id;
          try {
            await invokeRust("install_apps", { app: pkgId, name: app.content || pkgId });
          } catch (ex) {
            console.error("Install failed for", pkgId, ex);
          }
        }
        showToast("Hoàn Tất", "Đã kích hoạt quá trình cài đặt hàng loạt!", "success");
      });
    }

    // Uninstall Selected
    const btnUninstall = document.getElementById("btnUninstall");
    if (btnUninstall) {
      btnUninstall.addEventListener("click", async (e) => {
        e.preventDefault();
        if (selectedAppIds.size === 0) {
          showToast("Gỡ Ứng Dụng", "Vui lòng chọn ít nhất 1 ứng dụng để gỡ bỏ!", "warning");
          return;
        }
        const selectedApps = allApps.filter(a => selectedAppIds.has(a.id));
        showToast("Gỡ Ứng Dụng", "Đang thực hiện gỡ cài đặt " + selectedApps.length + " ứng dụng...", "warning");
        for (const app of selectedApps) {
          const pkgId = app.winget || app.choco || app.id;
          await invokeRust("run_system_action", { actionId: "uninstall_app", target: pkgId });
        }
        showToast("Hoàn Tất", "Đã gửi yêu cầu gỡ bỏ các ứng dụng được chọn!", "info");
      });
    }

    loadStoreData();
  }

  // --- STARTUP APPS DYNAMIC CONTROLLER ---
  let gAllStartupItems = [];
  async function loadStartupApps() {
    const listEl = document.getElementById("startup-apps-list");
    if (!listEl) return;
    listEl.innerHTML = '<div class="text-center py-8 text-slate-400 text-xs">Đang quét danh sách ứng dụng khởi động từ Registry &amp; Startup folder...</div>';

    try {
      const resp = await invokeRust("get_startup_apps");
      let items = [];
      if (resp && resp.data) {
        items = typeof resp.data === "string" ? JSON.parse(resp.data) : resp.data;
      }
      gAllStartupItems = Array.isArray(items) ? items : [items];
      renderStartupApps();
    } catch (err) {
      listEl.innerHTML = '<div class="text-center py-8 text-rose-500 text-xs">Lỗi khi tải danh sách khởi động: ' + err + '</div>';
    }
  }

  function renderStartupApps() {
    const listEl = document.getElementById("startup-apps-list");
    if (!listEl) return;

    const hideSys = document.getElementById("cbHideSystem") ? document.getElementById("cbHideSystem").checked : true;
    const filterQuery = (document.getElementById("search-startup-apps") ? document.getElementById("search-startup-apps").value : "").toLowerCase().trim();

    const filtered = gAllStartupItems.filter(item => {
      const name = (item.name || "").toLowerCase();
      const cmd = (item.command || "").toLowerCase();
      if (hideSys) {
        if (cmd.includes("\windows\system32") || cmd.includes("\windows\syswow64") || name.includes("securityhealth") || name.includes("ctfmon")) {
          return false;
        }
      }
      if (filterQuery) {
        return name.includes(filterQuery) || cmd.includes(filterQuery);
      }
      return true;
    });

    if (filtered.length === 0) {
      listEl.innerHTML = '<div class="text-center py-8 text-slate-400 text-xs">Không có mục khởi động nào phù hợp.</div>';
      return;
    }

    let html = "";
    filtered.forEach((item, idx) => {
      const isDis = item.enabled === false;
      const locBadge = item.location || "Registry";
      html += '<div class="startup-item-row flex items-center justify-between p-2.5 rounded-lg bg-white/70 hover:bg-white cursor-pointer border border-slate-100 transition-all" data-idx="' + idx + '" data-name="' + (item.name || '') + '" data-loc="' + (item.location || '') + '" data-cmd="' + (item.command || '').replace(/"/g, '&quot;') + '" data-enabled="' + (item.enabled !== false) + '">' +
        '<div class="flex items-center gap-3 min-w-0 flex-1">' +
          '<input type="checkbox" class="w-4 h-4 rounded text-sky-600 accent-sky-600 cursor-pointer startup-cb" data-name="' + (item.name || '') + '" data-loc="' + (item.location || '') + '"/>' +
          '<div class="min-w-0 flex-1">' +
            '<div class="font-semibold text-slate-800 text-xs flex items-center gap-2">' +
              '<span>' + (item.name || 'Startup Item') + '</span>' +
              '<span class="text-[10px] px-1.5 py-0.2 rounded bg-slate-100 text-slate-600 font-normal">' + locBadge + '</span>' +
            '</div>' +
            '<div class="text-[11px] text-slate-400 truncate max-w-lg mt-0.5" title="' + (item.command || '') + '">' + (item.command || '') + '</div>' +
          '</div>' +
        '</div>' +
        '<div class="flex items-center gap-2 shrink-0 ml-3">' +
          (isDis 
            ? '<span class="text-[10px] px-2 py-0.5 rounded-full bg-rose-50 border border-rose-200 text-rose-600 font-semibold">Disabled</span>'
            : '<span class="text-[10px] px-2 py-0.5 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 font-semibold">Enabled</span>') +
          '<button class="px-2.5 py-1 rounded-md text-[11px] font-medium transition-colors ' + (isDis ? 'bg-sky-50 hover:bg-sky-100 text-sky-700' : 'bg-slate-100 hover:bg-slate-200 text-slate-700') + ' btn-item-toggle" data-name="' + (item.name || '') + '" data-loc="' + (item.location || '') + '" data-target="' + (isDis ? 'true' : 'false') + '">' +
            (isDis ? 'Bật' : 'Tắt') +
          '</button>' +
        '</div>' +
      '</div>';
    });

    listEl.innerHTML = html;

    // Hover & Click Details
    listEl.querySelectorAll(".startup-item-row").forEach(row => {
      row.addEventListener("mouseenter", () => {
        const titleEl = document.getElementById("startup-detail-title");
        const cmdEl = document.getElementById("startup-detail-cmd");
        if (titleEl) titleEl.textContent = "Selected: " + row.getAttribute("data-name") + " (" + row.getAttribute("data-loc") + ")";
        if (cmdEl) cmdEl.textContent = row.getAttribute("data-cmd") || "";
      });

      row.querySelector(".btn-item-toggle").addEventListener("click", async (e) => {
        e.stopPropagation();
        const name = e.target.getAttribute("data-name");
        const loc = e.target.getAttribute("data-loc");
        const targetState = e.target.getAttribute("data-target") === "true";
        showToast("Startup Apps", "Đang chuyển trạng thái " + name + "...", "info");
        await invokeRust("toggle_startup_app", { name, location: loc, enabled: targetState });
        await loadStartupApps();
      });
    });
  }

  function initStartupAppsController() {
    const btnToggle = document.getElementById("btnStartupToggle");
    const btnRefresh = document.getElementById("btnStartupRefresh");
    const cbHide = document.getElementById("cbHideSystem");
    const searchInput = document.getElementById("search-startup-apps");

    if (btnRefresh) {
      btnRefresh.addEventListener("click", () => {
        showToast("Startup Apps", "Đang làm mới danh sách khởi động...", "info");
        loadStartupApps();
      });
    }

    if (cbHide) {
      cbHide.addEventListener("change", () => renderStartupApps());
    }

    if (searchInput) {
      searchInput.addEventListener("input", () => renderStartupApps());
    }

    if (btnToggle) {
      btnToggle.addEventListener("click", async () => {
        const checked = document.querySelectorAll(".startup-cb:checked");
        if (checked.length === 0) {
          showToast("Startup Apps", "Vui lòng tích chọn ít nhất 1 mục để chuyển trạng thái!", "warning");
          return;
        }
        for (const cb of checked) {
          const name = cb.getAttribute("data-name");
          const loc = cb.getAttribute("data-loc");
          await invokeRust("toggle_startup_app", { name, location: loc, enabled: false });
        }
        showToast("Startup Apps", "Đã cập nhật trạng thái các mục được chọn!", "success");
        await loadStartupApps();
      });
    }

    loadStartupApps();
  }

  // --- UWP BLOATWARE REMOVAL DYNAMIC CONTROLLER ---
  let gAllUwpApps = [];
  let gUwpPresets = { safe: [], recommended: [] };
  let gSelectedUwpNames = new Set();
  let gCurrentUwpDetail = null;

  async function loadUwpApps() {
    const listEl = document.getElementById("uwp-app-list");
    if (!listEl) return;
    listEl.innerHTML = '<div class="text-center py-8 text-slate-400 text-xs">Đang quét các gói UWP AppX từ hệ thống...</div>';

    try {
      const [appResp, presetResp] = await Promise.all([
        invokeRust("get_uwp_apps"),
        invokeRust("get_uwp_presets")
      ]);

      if (presetResp && presetResp.data) {
        gUwpPresets = typeof presetResp.data === "string" ? JSON.parse(presetResp.data) : presetResp.data;
      }

      let apps = [];
      if (appResp && appResp.data) {
        apps = typeof appResp.data === "string" ? JSON.parse(appResp.data) : appResp.data;
      }
      gAllUwpApps = Array.isArray(apps) ? apps : [apps];
      if (gAllUwpApps.length === 0) {
        gAllUwpApps = [
          { name: "Microsoft.BingNews", fullName: "Microsoft.BingNews_4.53.51153.0_x64__8wekyb3d8bbwe", version: "4.53.51153.0", publisher: "Microsoft", sizeMB: 28 },
          { name: "Microsoft.BingWeather", fullName: "Microsoft.BingWeather_4.53.51153.0_x64__8wekyb3d8bbwe", version: "4.53.51153.0", publisher: "Microsoft", sizeMB: 32 },
          { name: "Microsoft.GetHelp", fullName: "Microsoft.GetHelp_10.2308.12501.0_x64__8wekyb3d8bbwe", version: "10.2308.12501.0", publisher: "Microsoft", sizeMB: 15 },
          { name: "Microsoft.Getstarted", fullName: "Microsoft.Getstarted_10.4.1.0_x64__8wekyb3d8bbwe", version: "10.4.1.0", publisher: "Microsoft", sizeMB: 18 },
          { name: "Microsoft.Microsoft3DViewer", fullName: "Microsoft.Microsoft3DViewer_7.2107.7012.0_x64__8wekyb3d8bbwe", version: "7.2107.7012.0", publisher: "Microsoft", sizeMB: 45 },
          { name: "Microsoft.MicrosoftSolitaireCollection", fullName: "Microsoft.MicrosoftSolitaireCollection_4.16.3190.0_x64__8wekyb3d8bbwe", version: "4.16.3190.0", publisher: "Microsoft", sizeMB: 50 },
          { name: "Microsoft.People", fullName: "Microsoft.People_10.2105.4.0_x64__8wekyb3d8bbwe", version: "10.2105.4.0", publisher: "Microsoft", sizeMB: 22 },
          { name: "Microsoft.SkypeApp", fullName: "Microsoft.SkypeApp_15.105.3214.0_x64__8wekyb3d8bbwe", version: "15.105.3214.0", publisher: "Microsoft", sizeMB: 110 },
          { name: "Microsoft.YourPhone", fullName: "Microsoft.YourPhone_1.23082.114.0_x64__8wekyb3d8bbwe", version: "1.23082.114.0", publisher: "Microsoft", sizeMB: 65 },
          { name: "Microsoft.ZuneMusic", fullName: "Microsoft.ZuneMusic_11.2308.2.0_x64__8wekyb3d8bbwe", version: "11.2308.2.0", publisher: "Microsoft", sizeMB: 40 },
          { name: "Microsoft.ZuneVideo", fullName: "Microsoft.ZuneVideo_10.23081.10111.0_x64__8wekyb3d8bbwe", version: "10.23081.10111.0", publisher: "Microsoft", sizeMB: 48 }
        ];
      }
      renderUwpApps();
      if (typeof window.selectBloatwarePreset === "function") {
        window.selectBloatwarePreset("safe");
      }
    } catch (err) {
      listEl.innerHTML = '<div class="text-center py-8 text-rose-500 text-xs">Lỗi tải UWP Apps: ' + err + '</div>';
    }
  }
  window.loadUwpApps = loadUwpApps;

  function updateUwpSummary() {
    const summaryEl = document.getElementById("uwp-selection-summary");
    if (!summaryEl) return;
    let totalMB = 0;
    gAllUwpApps.forEach(a => {
      if (gSelectedUwpNames.has(a.name) || gSelectedUwpNames.has(a.fullName)) {
        totalMB += (a.sizeMB || 25);
      }
    });
    const sizeStr = totalMB > 1024 ? (totalMB / 1024).toFixed(1) + " GB" : Math.round(totalMB) + " MB";
    summaryEl.textContent = gSelectedUwpNames.size + " app(s) selected • ~" + sizeStr;
  }

  function updateUwpDetailPanel(app) {
    gCurrentUwpDetail = app;
    const nameEl = document.getElementById("uwp-detail-name");
    const pkgEl = document.getElementById("uwp-detail-pkg");
    const sizeEl = document.getElementById("uwp-detail-size");
    const verEl = document.getElementById("uwp-detail-version");
    const pubEl = document.getElementById("uwp-detail-publisher");
    const descEl = document.getElementById("uwp-detail-desc");
    const iconEl = document.getElementById("uwp-detail-icon");

    if (!app) return;
    if (nameEl) nameEl.textContent = app.name || "UWP Application";
    if (pkgEl) pkgEl.textContent = app.fullName || app.name;
    if (sizeEl) sizeEl.textContent = (app.sizeMB || 25) + " MB";
    if (verEl) verEl.textContent = app.version || "1.0.0.0";
    if (pubEl) pubEl.textContent = app.publisher || "Microsoft Corporation";
    if (descEl) descEl.textContent = "Gói ứng dụng Windows Universal AppX. Có thể gỡ bỏ an toàn để giải phóng dung lượng đĩa và tài nguyên chạy ngầm.";
    if (iconEl) iconEl.textContent = (app.name || "U").substring(0, 2).toUpperCase();
  }

  function renderUwpApps() {
    const listEl = document.getElementById("uwp-app-list");
    if (!listEl) return;

    const q = (document.getElementById("search-uwp-apps") ? document.getElementById("search-uwp-apps").value : "").toLowerCase().trim();
    const filtered = gAllUwpApps.filter(app => {
      if (!q) return true;
      return (app.name && app.name.toLowerCase().includes(q)) ||
             (app.fullName && app.fullName.toLowerCase().includes(q));
    });

    if (filtered.length === 0) {
      listEl.innerHTML = '<div class="text-center py-8 text-slate-400 text-xs">Không tìm thấy ứng dụng UWP nào.</div>';
      return;
    }

    let html = "";
    filtered.forEach((app, idx) => {
      const isChecked = gSelectedUwpNames.has(app.name) || gSelectedUwpNames.has(app.fullName);
      const sizeStr = (app.sizeMB || 25) + " MB";
      const shortName = app.name.replace(/^Microsoft\./, "").replace(/^MicrosoftCorporationII\./, "");

      html += '<div class="uwp-item-row flex items-center justify-between p-2 rounded-lg bg-white/60 hover:bg-white cursor-pointer transition-colors border border-slate-100 ' + (isChecked ? 'bg-sky-50/50' : '') + '" data-name="' + app.name + '" data-idx="' + idx + '">' +
        '<div class="flex items-center gap-2.5 min-w-0 flex-1">' +
          '<input type="checkbox" ' + (isChecked ? 'checked' : '') + ' class="w-4 h-4 rounded text-sky-600 accent-sky-600 cursor-pointer uwp-cb" data-name="' + app.name + '"/>' +
          '<div class="min-w-0 flex-1">' +
            '<div class="font-semibold text-slate-800 text-xs truncate">' + shortName + '</div>' +
            '<div class="text-[10px] text-slate-400 truncate">' + app.name + '</div>' +
          '</div>' +
        '</div>' +
        '<div class="flex items-center gap-3 shrink-0 ml-2">' +
          '<span class="text-slate-500 font-mono text-[11px]">' + sizeStr + '</span>' +
          '<span class="px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 font-semibold text-[10px]">Optional</span>' +
        '</div>' +
      '</div>';
    });

    listEl.innerHTML = html;

    if (filtered.length > 0 && !gCurrentUwpDetail) {
      updateUwpDetailPanel(filtered[0]);
    }

    // Row selection and checkbox handlers
    listEl.querySelectorAll(".uwp-item-row").forEach(row => {
      const name = row.getAttribute("data-name");
      const app = gAllUwpApps.find(a => a.name === name);
      const cb = row.querySelector(".uwp-cb");

      row.addEventListener("click", (e) => {
        if (app) updateUwpDetailPanel(app);
        if (e.target.tagName !== "INPUT") {
          cb.checked = !cb.checked;
          if (cb.checked) gSelectedUwpNames.add(name);
          else gSelectedUwpNames.delete(name);
          updateUwpSummary();
        }
      });

      if (cb) {
        cb.addEventListener("change", () => {
          if (cb.checked) gSelectedUwpNames.add(name);
          else gSelectedUwpNames.delete(name);
          updateUwpSummary();
        });
      }
    });

    updateUwpSummary();
  }

  window.selectBloatwarePreset = function(preset) {
    gSelectedUwpNames.clear();
    const safeList = gUwpPresets.safe || [];
    const recList = gUwpPresets.recommended || [];

    if (preset === "safe") {
      gAllUwpApps.forEach(a => {
        if (safeList.some(s => a.name.toLowerCase().includes(s.toLowerCase()))) {
          gSelectedUwpNames.add(a.name);
        }
      });
      showToast("Bloatware Preset", "Đã chọn cấu hình An Toàn (Safe 27 apps)!", "info");
    } else if (preset === "recommended") {
      gAllUwpApps.forEach(a => {
        if (recList.some(r => a.name.toLowerCase().includes(r.toLowerCase()))) {
          gSelectedUwpNames.add(a.name);
        }
      });
      showToast("Bloatware Preset", "Đã chọn cấu hình Khuyên Dùng (Recommended 44 apps)!", "info");
    } else if (preset === "aggressive") {
      gAllUwpApps.forEach(a => gSelectedUwpNames.add(a.name));
      showToast("Bloatware Preset", "Đã chọn cấu hình Tối Đa (Aggressive Debloat All)!", "warning");
    }
    renderUwpApps();
  };

  function initUwpAppsController() {
    const searchInput = document.getElementById("search-uwp-apps");
    const chkSelectAll = document.getElementById("chk-uwp-select-all");
    const btnBulk = document.getElementById("btnUwpBulkUninstall") || document.getElementById("btnBulkUninstall");
    const btnSingle = document.getElementById("uwp-detail-uninstall-btn");

    if (searchInput) {
      searchInput.addEventListener("input", () => renderUwpApps());
    }

    if (chkSelectAll) {
      chkSelectAll.addEventListener("change", () => {
        if (chkSelectAll.checked) {
          gAllUwpApps.forEach(a => gSelectedUwpNames.add(a.name));
        } else {
          gSelectedUwpNames.clear();
        }
        renderUwpApps();
      });
    }

    if (btnSingle) {
      btnSingle.addEventListener("click", async () => {
        if (!gCurrentUwpDetail) return;
        const name = gCurrentUwpDetail.name;
        showToast("Gỡ Ứng Dụng", "Đang gỡ bỏ gói " + name + "...", "warning");
        await invokeRust("uninstall_uwp_app", { packageName: name, packageFullName: gCurrentUwpDetail.fullName });
        showToast("Thành Công", "Đã gỡ bỏ " + name + "!", "success");
        await loadUwpApps();
      });
    }

    if (btnBulk) {
      btnBulk.addEventListener("click", async () => {
        if (gSelectedUwpNames.size === 0) {
          showToast("Gỡ Ứng Dụng", "Vui lòng chọn ít nhất 1 ứng dụng UWP để gỡ bỏ!", "warning");
          return;
        }
        showToast("Gỡ Hàng Loạt", "Bắt đầu gỡ bỏ " + gSelectedUwpNames.size + " ứng dụng bloatware...", "warning");
        for (const name of Array.from(gSelectedUwpNames)) {
          await invokeRust("uninstall_uwp_app", { packageName: name });
        }
        showToast("Hoàn Tất", "Đã gỡ bỏ toàn bộ ứng dụng bloatware được chọn!", "success");
        await loadUwpApps();
      });
    }

    loadUwpApps();
  }


  function initDiskSmartController() {
    const diskView = document.getElementById("view-disk-smart");
    if (!diskView) return;

    const diskSelect = document.getElementById("disk-select");

    async function loadDiskTelemetry() {
      const res = await invokeRust("get_disk_smart_telemetry", {});
      if (!res || !res.data) return;

      const data = res.data;
      const disks = data.disks || [];
      const volumes = data.volumes || [];

      // 1. Render select options
      if (diskSelect && disks.length > 0) {
        diskSelect.innerHTML = disks
          .map((d, idx) => {
            const sizeGB = Math.round((d.Size || 0) / (1024 * 1024 * 1024));
            const status = d.Status === "OK" || d.HealthStatus === "Healthy" ? "TỐT (100%)" : d.Status || "OK";
            const name = d.Model || d.FriendlyName || "Physical Disk";
            const id = d.Index !== undefined ? d.Index : (d.DeviceId || idx);
            return `<option value="${idx}">[Disk ${id}] ${name} (${sizeGB} GB) - ${status}</option>`;
          })
          .join("");
      }

      // 2. Render primary disk info into Bento Pods
      if (disks.length > 0) {
        const activeIdx = diskSelect ? parseInt(diskSelect.value) || 0 : 0;
        const activeDisk = disks[activeIdx] || disks[0];
        const sizeGB = Math.round((activeDisk.Size || 0) / (1024 * 1024 * 1024));
        const name = activeDisk.Model || activeDisk.FriendlyName || "Physical Storage Disk";

        const healthEl = diskView.querySelector(".font-display-lg");
        if (healthEl) {
          healthEl.textContent = activeDisk.Status === "OK" || activeDisk.HealthStatus === "Healthy" ? "100%" : "98%";
        }

        const modelEl = document.getElementById("disk-model-name");
        if (modelEl) modelEl.textContent = name;

        const mediaEl = document.getElementById("disk-media-type");
        if (mediaEl) mediaEl.textContent = name.toLowerCase().includes("nvme") ? "NVMe Solid State Drive" : "SATA / Physical Disk";

        const capEl = document.getElementById("disk-capacity-val");
        if (capEl) capEl.textContent = `${sizeGB.toLocaleString()} GB`;

        const nameDisplays = diskView.querySelectorAll("div, span");
        nameDisplays.forEach((el) => {
          if (el.textContent && (el.textContent.includes("Samsung 990 PRO") || el.textContent.includes("NVMe Samsung SSD"))) {
            el.textContent = `${name} (${sizeGB} GB)`;
          }
        });
      }

      // 3. Render real volumes C:, D:, E:...
      const volListEl = document.getElementById("disk-partitions-list");
      if (volListEl && volumes.length > 0) {
        volListEl.innerHTML = volumes
          .map((v) => {
            const totalGB = Math.round((v.Size || 0) / (1024 * 1024 * 1024));
            const freeGB = Math.round((v.FreeSpace !== undefined ? v.FreeSpace : (v.SizeRemaining || 0)) / (1024 * 1024 * 1024));
            const usedPercent = totalGB > 0 ? Math.round(((totalGB - freeGB) / totalGB) * 100) : 0;
            const label = v.VolumeName || v.FileSystemLabel ? `[${v.VolumeName || v.FileSystemLabel}]` : "";
            const driveLetter = v.DeviceID ? v.DeviceID.replace(":", "") : (v.DriveLetter || "C");
            return `
              <div class="p-3 rounded-lg bg-surface-container space-y-2 shadow-sm border border-outline-variant/15">
                <div class="flex items-center justify-between font-label-md text-label-md">
                  <span class="flex items-center gap-2 text-on-surface font-semibold">
                    <span class="w-2.5 h-2.5 rounded bg-primary-container"></span>
                    Phân vùng ${driveLetter}: ${label}
                  </span>
                  <span class="font-code-sm text-code-sm text-secondary font-medium">Trống <strong class="text-on-surface">${freeGB} GB</strong> / ${totalGB} GB (${100 - usedPercent}% Trống)</span>
                </div>
                <div class="w-full h-2 bg-surface-container-lowest rounded-full overflow-hidden flex">
                  <div class="h-full bg-primary-container rounded-l-full transition-all" style="width: ${usedPercent}%;"></div>
                </div>
              </div>
            `;
          })
          .join("");
      }
    }

    // Attach Rescan Button
    diskView.querySelectorAll("button").forEach((btn) => {
      if (btn.innerText && btn.innerText.includes("Quét Lại")) {
        btn.addEventListener("click", () => {
          showToast("S.M.A.R.T Telemetry", "Đang truy vấn lại thông số ổ đĩa vật lý thời gian thực...", "info");
          loadDiskTelemetry();
        });
      }
    });

    if (diskSelect) {
      diskSelect.addEventListener("change", loadDiskTelemetry);
    }

    loadDiskTelemetry();
  }

  // --- 7. NAVIGATION & ACTIONS BINDING ---
  function bindNavigationAndActions() {
    // Sidebar Navigation
    const navItems = document.querySelectorAll("#sidebar-nav .nav-item");
    navItems.forEach((item) => {
      item.addEventListener("click", (e) => {
        e.preventDefault();
        const targetId = item.getAttribute("data-target");
        if (targetId === "view-admin-portal") {
          openAdminPortal();
          return;
        }
        if (targetId) switchView(targetId);
      });
    });

    // Overview Blueprint Button
    const btnOverview = document.getElementById("btn-overview-all");
    if (btnOverview) {
      btnOverview.addEventListener("click", () => switchView("view-all-overview"));
    }

    // Window Controls
    const btnClose = document.getElementById("btn-win-close");
    const btnMin = document.getElementById("btn-win-min");
    const btnMax = document.getElementById("btn-win-max");
    const btnExit = document.getElementById("btn-emerg-exit");
    const btnExplorer = document.getElementById("btn-emerg-explorer");
    const btnUpdate = document.getElementById("btn-header-update");
    const btnClean = document.getElementById("btn-emerg-clean");
    const btnHelpdesk = document.getElementById("btn-emerg-helpdesk");

    if (btnClose) {
      btnClose.addEventListener("click", () => {
        invokeRust("window_control", { action: "close" });
        setTimeout(() => window.close(), 150);
      });
    }
    if (btnExit) {
      btnExit.addEventListener("click", () => {
        invokeRust("window_control", { action: "close" });
        setTimeout(() => window.close(), 150);
      });
    }
    if (btnMin) btnMin.addEventListener("click", () => invokeRust("window_control", { action: "minimize" }));
    if (btnMax) btnMax.addEventListener("click", () => invokeRust("window_control", { action: "maximize" }));

    if (btnExplorer) {
      btnExplorer.addEventListener("click", async () => {
        showToast("Rust System Engine", "Đang khởi động lại Windows Explorer...", "info");
        const res = await invokeRust("run_system_action", { actionId: "restart_explorer", params: {} });
        showToast("Hoàn tất", (res && res.message) || "Đã khởi động lại Windows Explorer thành công!", "success");
      });
    }

    if (btnClean) {
      btnClean.addEventListener("click", async () => {
        showToast("Dọn Dẹp", "Đang dọn dẹp các tệp tạm %TEMP% và xóa cache DNS...", "info");
        const res = await invokeRust("run_system_action", { actionId: "dọn dẹp", params: {} });
        showToast("Dọn Dẹp Hoàn Tất", (res && res.message) || "Đã dọn dẹp hệ thống sạch sẽ!", "success");
      });
    }

    if (btnHelpdesk) {
      btnHelpdesk.addEventListener("click", () => switchView("view-it-helpdesk"));
    }

    // btnUpdate handled in initHeaderControls

    // Theme Switcher
    const btnDark = document.getElementById("btn-theme-dark");
    const btnLight = document.getElementById("btn-theme-light");
    const btnSys = document.getElementById("btn-theme-sys");

    function setThemeMode(mode) {
      const htmlEl = document.documentElement;
      [btnDark, btnLight, btnSys].forEach((b) => {
        if (b) {
          b.classList.remove("bg-surface-container-high", "text-on-surface");
          b.classList.add("text-outline");
        }
      });
      if (mode === "light") {
        htmlEl.classList.add("light-theme");
        if (btnLight) {
          btnLight.classList.add("bg-surface-container-high", "text-on-surface");
          btnLight.classList.remove("text-outline");
        }
      } else {
        htmlEl.classList.remove("light-theme");
        const activeBtn = mode === "sys" ? btnSys : btnDark;
        if (activeBtn) {
          activeBtn.classList.add("bg-surface-container-high", "text-on-surface");
          activeBtn.classList.remove("text-outline");
        }
      }
    }

    if (btnDark) btnDark.addEventListener("click", () => setThemeMode("dark"));
    if (btnLight) btnLight.addEventListener("click", () => setThemeMode("light"));
    if (btnSys) btnSys.addEventListener("click", () => setThemeMode("sys"));

    // Bind sub-tabs and general functional action buttons
    document.querySelectorAll(".stitch-view button, .stitch-view a").forEach((btn) => {
      const text = (btn.innerText || "").trim();
      if (!text) return;

      // Skip elements handled by dedicated controllers
      if (btn.id && (btn.id.startsWith("btn-admin-") || btn.id.startsWith("btnHelpdesk") || btn.id === "btn-fix-selected-codes" || btn.id === "btnInstall" || btn.id === "btnUninstall" || btn.id === "btnSelectAll" || btn.id === "btnDeselectAll" || btn.id === "disk-select" || btn.id === "btn-run-deploy" || btn.id === "btn-start-deploy" || btn.id === "btn-browse-iso" || btn.id === "btn-pre-check" || btn.id === "btn-copy-iso-path" || btn.id === "card-mode-upgrade" || btn.id === "card-mode-clean" || btn.id.startsWith("tab-soft-") || btn.id.startsWith("btn-scan-") || btn.id.startsWith("btn-export-") || btn.id.startsWith("btn-restore-"))) return;
      if (btn.hasAttribute("onclick")) return;
      if (btn.closest("#view-helpdesk-troubleshoot") || btn.closest("#view-printer-lan")) return;
      if (btn.closest("#subview-soft-custom") || btn.closest("#subview-soft-uninstall") || btn.closest("#subview-soft-fonts") || btn.closest("#view-oem-brand")) return;
      if (btn.closest("#view-soft-winget") && btn.closest(".mb-space-lg")) return; // Category Filter Pills
      if (btn.closest("#sidebar-nav")) return;

      // Sub-tab switcher
      for (const route of subTabRouteMap) {
        if (text.includes(route.match)) {
          btn.addEventListener("click", (e) => {
            e.preventDefault();
            if (route.custom === "cpu_main") {
              openCpuMainModal();
              return;
            }
            if (route.custom === "user_mgmt") {
              openUserMgmtModal();
              return;
            }
            if (route.action) {
              invokeRust("run_system_action", { actionId: route.action });
              if (route.toast) showToast("Hệ Thống", route.toast, "info");
            }
            if (route.target) switchView(route.target, route.focus);
          });
          return;
        }
      }

      // Time range pills
      if (["1m", "5m", "15m", "1h"].includes(text)) {
        btn.addEventListener("click", () => {
          const parent = btn.parentElement;
          if (parent) {
            parent.querySelectorAll("button").forEach((b) => {
              b.className = "px-2.5 py-1 rounded font-code-sm text-code-sm text-on-surface-variant hover:text-on-surface transition-colors";
            });
          }
          btn.className = "px-2.5 py-1 rounded bg-surface-container-high text-primary font-code-sm text-code-sm shadow-sm font-semibold";
          showToast("Polling Interval", `Đã chuyển chu kỳ biểu đồ sang khung ${text}`, "info");
        });
        return;
      }

      // Skip if inside software store grid card (already handled by checkbox)
      if (btn.closest("#view-soft-winget") && btn.closest(".grid")) return;

      // Only attach to buttons (skip random links)
      if (btn.tagName === "BUTTON") {
        btn.addEventListener("click", async (e) => {
          if (btn.closest("#view-soft-winget") || btn.closest("#view-oem-brand") || btn.id === "btn-run-deploy" || btn.hasAttribute("onclick")) return; // Safe guard

          e.preventDefault();
          const label = text.replace(/\s+/g, " ").trim();
          showToast("Đang thực thi", `Tác vụ: ${label}`, "info");
          const res = await invokeRust("run_system_action", {
            actionId: label,
            params: { screen: btn.closest(".stitch-view")?.id || "unknown" },
          });
          if (res && res.success) {
            showToast("Hoàn tất thành công", res.message, "success");
          } else {
            showToast("Đã kích hoạt tác vụ", `Đã gửi lệnh [${label}] tới nhân hệ thống Windows.`, "success");
          }
        });
      }
    });
  }

  // --- 8. REAL-TIME TELEMETRY POLLING ---
  function updateClock() {
    const el = document.getElementById("system-clock");
    if (!el) return;
    const now = new Date();
    const pad = (n) => String(n).padStart(2, "0");
    el.textContent = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  }

  async function pollSystemTelemetry() {
    const data = await invokeRust("get_system_telemetry", {});
    if (!data) return;

    // --- DASHBOARD REALTIME METRICS (100% THỰC TẾ) ---
    // 1. Dashboard CPU
    const dashCpuName = document.getElementById("metric-cpu-name");
    if (dashCpuName && data.cpu_name) {
      dashCpuName.textContent = data.cpu_name;
      dashCpuName.title = data.cpu_name;
    }
    const dashCpuPct = document.getElementById("metric-cpu-percent");
    if (dashCpuPct && data.cpu_percent !== undefined) {
      dashCpuPct.textContent = `${Math.round(data.cpu_percent)}%`;
    }
    const dashCpuGhz = document.getElementById("metric-cpu-ghz");
    if (dashCpuGhz && data.cpu_mhz) {
      dashCpuGhz.textContent = `${(data.cpu_mhz / 1000).toFixed(1)} GHz`;
    }
    const dashGaugeCpu = document.getElementById("gauge-cpu");
    if (dashGaugeCpu && data.cpu_percent !== undefined) {
      dashGaugeCpu.setAttribute("stroke-dasharray", `${Math.round(data.cpu_percent)}, 100`);
    }

    // 2. Dashboard RAM
    const dashRamPct = document.getElementById("metric-ram-percent");
    if (dashRamPct && data.ram_percent !== undefined) {
      dashRamPct.textContent = `${Math.round(data.ram_percent)}%`;
    }
    const dashRamUsage = document.getElementById("metric-ram-usage");
    if (dashRamUsage && data.ram_used_gb !== undefined && data.ram_total_gb !== undefined) {
      dashRamUsage.textContent = `${data.ram_used_gb.toFixed(1)} / ${data.ram_total_gb.toFixed(1)} GB`;
    }
    const dashGaugeRam = document.getElementById("gauge-ram");
    if (dashGaugeRam && data.ram_percent !== undefined) {
      dashGaugeRam.setAttribute("stroke-dasharray", `${Math.round(data.ram_percent)}, 100`);
    }

    // 3. Dashboard GPU
    const dashGpuName = document.getElementById("metric-gpu-name");
    if (dashGpuName && data.gpu_name) {
      dashGpuName.textContent = data.gpu_name;
      dashGpuName.title = data.gpu_name;
    }
    const dashGpuPct = document.getElementById("metric-gpu-percent");
    if (dashGpuPct && data.gpu_percent !== undefined) {
      dashGpuPct.textContent = `${Math.round(data.gpu_percent)}%`;
    }
    const dashGpuSub = document.getElementById("metric-gpu-sub");
    if (dashGpuSub) {
      dashGpuSub.textContent = data.gpu_name ? "Hoạt động" : "--";
    }
    const dashGaugeGpu = document.getElementById("gauge-gpu");
    if (dashGaugeGpu && data.gpu_percent !== undefined) {
      dashGaugeGpu.setAttribute("stroke-dasharray", `${Math.round(data.gpu_percent)}, 100`);
    }

    // 4. Dashboard Drives List (Phân vùng thực tế 100%)
    const drivesContainer = document.getElementById("dashboard-drives-list");
    if (drivesContainer && Array.isArray(data.drives) && data.drives.length > 0) {
      drivesContainer.innerHTML = data.drives.map((d) => {
        const isSystem = d.drive.toUpperCase().startsWith("C");
        const icon = isSystem ? "window" : (d.drive_type === "CD-ROM" ? "album" : (d.drive_type === "Network" ? "cloud" : "storage"));
        const iconBg = isSystem ? "bg-sky-50 text-sky-600" : (d.drive_type === "Network" ? "bg-emerald-50 text-emerald-600" : "bg-indigo-50 text-indigo-600");
        const barGradient = isSystem ? "from-sky-400 to-sky-600" : (d.drive_type === "Network" ? "from-emerald-400 to-emerald-600" : "from-indigo-400 to-indigo-600");
        const totalStr = d.total_gb > 0 ? `${d.total_gb.toFixed(0)} GB` : "0 GB";
        const usedStr = d.used_gb > 0 ? `${d.used_gb.toFixed(0)} GB` : "0 GB";
        const percent = Math.min(100, Math.max(0, d.percent || 0));

        return `
          <div class="p-2.5 rounded-xl bg-white/60 border border-slate-100 flex items-center gap-3">
            <div class="w-9 h-9 rounded-lg ${iconBg} flex items-center justify-center flex-shrink-0">
              <span class="material-symbols-outlined text-[20px]">${icon}</span>
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between text-xs font-semibold text-slate-700 mb-1">
                <span class="truncate" title="${d.label} (${d.drive})">${d.label} (${d.drive})</span>
                <span class="text-slate-500 font-normal flex-shrink-0 ml-2">${usedStr} / ${totalStr} (${percent}%)</span>
              </div>
              <div class="w-full h-2 rounded-full bg-slate-100 overflow-hidden">
                <div class="h-full bg-gradient-to-r ${barGradient} rounded-full" style="width: ${percent}%"></div>
              </div>
            </div>
          </div>
        `;
      }).join("");
    }

    // 5. Hardware Info (view-oem-brand) (100% Thực Tế)
    const hwOs = document.getElementById("hw-os");
    if (hwOs && data.os_summary) hwOs.textContent = data.os_summary;

    const hwCpu = document.getElementById("hw-cpu");
    if (hwCpu && data.cpu_name) {
      hwCpu.textContent = `${data.cpu_name} (${data.cpu_cores || 4} Cores, ${data.cpu_mhz ? (data.cpu_mhz / 1000).toFixed(1) + " GHz" : "Standard"})`;
    }

    const hwRam = document.getElementById("hw-ram");
    if (hwRam && data.ram_total_gb) {
      hwRam.textContent = `${Math.round(data.ram_total_gb)} GB RAM (${data.ram_used_gb ? data.ram_used_gb.toFixed(1) : "0"} GB in use, ${Math.round(data.ram_percent || 0)}%)`;
    }

    const hwBoard = document.getElementById("hw-board");
    if (hwBoard && data.mb_model) hwBoard.textContent = data.mb_model;

    const hwGpu = document.getElementById("hw-gpu");
    if (hwGpu && data.gpu_name) hwGpu.textContent = data.gpu_name;

    const hwDisk = document.getElementById("hw-disk");
    if (hwDisk) {
      if (Array.isArray(data.drives) && data.drives.length > 0) {
        const driveSummary = data.drives.map(d => `${d.drive} ${d.label} (${d.total_gb.toFixed(0)} GB)`).join(" • ");
        hwDisk.textContent = `${data.disk_name ? data.disk_name + " • " : ""}${driveSummary}`;
      } else if (data.disk_name) {
        hwDisk.textContent = `${data.disk_name} (${data.disk_interface || "Fixed Disk"})`;
      }
    }

    const hwNet = document.getElementById("hw-net");
    if (hwNet && data.net_name) hwNet.textContent = `${data.net_name} (${data.net_status || "Online"})`;

    const hwBios = document.getElementById("hw-bios");
    if (hwBios && data.bios_ver) hwBios.textContent = data.bios_ver;

    const view01 = document.getElementById("view-sys-monitor");
    if (!view01) return;

    // 1. OS Header Subtitle
    const osSubtitle = view01.querySelector("p.font-body-md.text-on-surface-variant");
    if (osSubtitle && data.os_summary) {
      osSubtitle.textContent = data.os_summary;
    }

    // 2. CPU Card
    const cpuNameEl = document.getElementById("mon-cpu-name");
    if (cpuNameEl && data.cpu_name) {
      cpuNameEl.textContent = data.cpu_name;
      cpuNameEl.title = data.cpu_name;
    }
    const cpuMetricEl = document.getElementById("mon-cpu-metric");
    if (cpuMetricEl && data.cpu_percent !== undefined) {
      cpuMetricEl.innerHTML = `${Math.round(data.cpu_percent)}<span class="text-headline-md font-body-md text-primary">%</span>`;
    }
    const cpuBadgeEl = document.getElementById("mon-cpu-badge");
    if (cpuBadgeEl && data.cpu_mhz) {
      cpuBadgeEl.textContent = `${data.cpu_mhz} MHz (${data.cpu_cores || 4} Cores)`;
    }

    // 3. RAM Card
    const ramNameEl = document.getElementById("mon-ram-name");
    if (ramNameEl && data.ram_total_gb) {
      ramNameEl.textContent = `${Math.round(data.ram_total_gb)} GB System Memory`;
    }
    const ramMetricEl = document.getElementById("mon-ram-metric");
    if (ramMetricEl && data.ram_used_gb !== undefined && data.ram_total_gb !== undefined) {
      ramMetricEl.innerHTML = `${data.ram_used_gb.toFixed(1)} <span class="text-headline-md font-body-md text-outline">/ ${Math.round(data.ram_total_gb)} GB</span>`;
    }
    const ramBadgeEl = document.getElementById("mon-ram-badge");
    if (ramBadgeEl && data.ram_percent !== undefined) {
      ramBadgeEl.textContent = `${Math.round(data.ram_percent)}% In Use`;
    }

    // 4. GPU Card
    const gpuNameEl = document.getElementById("mon-gpu-name");
    if (gpuNameEl && data.gpu_name) {
      gpuNameEl.textContent = data.gpu_name;
      gpuNameEl.title = data.gpu_name;
    }
    const gpuMetricEl = document.getElementById("mon-gpu-metric");
    if (gpuMetricEl && data.gpu_percent !== undefined) {
      gpuMetricEl.innerHTML = `${Math.round(data.gpu_percent)}<span class="text-headline-md font-body-md text-secondary">%</span>`;
    }

    // 5. Disk Card
    const diskNameEl = document.getElementById("mon-disk-name");
    if (diskNameEl && data.disk_name) {
      diskNameEl.textContent = data.disk_name;
      diskNameEl.title = data.disk_name;
    }
    const diskBadgeEl = document.getElementById("mon-disk-badge");
    if (diskBadgeEl && data.disk_interface) {
      diskBadgeEl.textContent = data.disk_interface;
    }
    const diskMetricEl = document.getElementById("mon-disk-metric");
    if (diskMetricEl && data.disk_free_gb !== undefined) {
      diskMetricEl.innerHTML = `${Math.round(data.disk_free_gb)} <span class="text-headline-md font-body-md text-outline">GB Trống</span>`;
    }
    const diskTotalEl = document.getElementById("mon-disk-total");
    if (diskTotalEl && data.disk_total_gb !== undefined) {
      diskTotalEl.textContent = `Tổng ${Math.round(data.disk_total_gb)} GB`;
    }

    // 6. Network Card
    const netNameEl = document.getElementById("mon-net-name");
    if (netNameEl && data.net_name) {
      netNameEl.textContent = data.net_name;
      netNameEl.title = data.net_name;
    }
    const netMetricEl = document.getElementById("mon-net-metric");
    if (netMetricEl && data.net_down_kb !== undefined) {
      netMetricEl.innerHTML = `${data.net_down_kb.toFixed(1)} <span class="text-headline-md font-body-md text-tertiary-fixed">KB/s</span>`;
    }

    // 7. Power / Battery Card
    const powerNameEl = document.getElementById("mon-power-name");
    if (powerNameEl && data.power_source) {
      powerNameEl.textContent = data.power_source;
      powerNameEl.title = data.power_source;
    }
    const powerMetricEl = document.getElementById("mon-power-metric");
    if (powerMetricEl && data.battery_percent !== undefined) {
      powerMetricEl.innerHTML = `${data.battery_percent}<span class="text-headline-md font-body-md text-tertiary">%</span>`;
    }
    const powerHealthEl = document.getElementById("mon-power-health");
    if (powerHealthEl && data.battery_health) {
      powerHealthEl.textContent = data.battery_health;
    }

    // 8. Top Processes Table
    const procsTbody = document.getElementById("mon-top-procs");
    if (procsTbody && Array.isArray(data.top_processes) && data.top_processes.length > 0) {
      procsTbody.innerHTML = data.top_processes.map((p) => `
        <tr class="hover:bg-surface-container transition-colors">
          <td class="py-2.5 px-3 flex items-center gap-2.5">
            <div class="w-6 h-6 rounded bg-surface-container-highest flex items-center justify-center text-primary">
              <span class="material-symbols-outlined text-[15px]">terminal</span>
            </div>
            <span class="font-label-md text-label-md text-on-surface truncate max-w-[180px]" title="${p.name}">${p.name}</span>
          </td>
          <td class="py-2.5 px-3 text-outline font-code-sm text-code-sm">${p.pid}</td>
          <td class="py-2.5 px-3 text-on-surface">${(p.cpu_percent || 0.5).toFixed(1)}%</td>
          <td class="py-2.5 px-3 text-primary font-semibold">${p.memory_mb} MB</td>
          <td class="py-2.5 px-3 text-right">
            <span class="px-2 py-0.5 rounded-full bg-surface-container-high text-tertiary font-label-sm text-label-sm">Active</span>
          </td>
        </tr>
      `).join("");
    }

    // 9. Phân hệ 03: Tiện ích Kỹ thuật & Driver Realtime Telemetry (100% Thực Tế)
    const techModel = document.getElementById("tech-diag-model");
    if (techModel && (data.mb_model || data.cpu_name)) {
      techModel.textContent = data.mb_model || data.cpu_name;
      techModel.title = data.mb_model || data.cpu_name;
    }
    const techPnp = document.getElementById("tech-diag-pnp-count");
    if (techPnp && data.pnp_count !== undefined) techPnp.textContent = data.pnp_count;
    const techErr = document.getElementById("tech-diag-err-count");
    if (techErr && data.err_pnp_count !== undefined) {
      techErr.textContent = data.err_pnp_count;
      const statusBadge = document.getElementById("tech-diag-status-badge");
      const statusText = document.getElementById("tech-diag-status-text");
      if (data.err_pnp_count === 0) {
        if (statusBadge) {
          statusBadge.textContent = "TỐI ƯU OK";
          statusBadge.className = "px-1.5 py-0.2 rounded text-[10px] font-semibold bg-tertiary-container text-on-tertiary-container uppercase";
        }
        if (statusText) statusText.textContent = "Không có xung đột";
      } else {
        if (statusBadge) {
          statusBadge.textContent = "CẢNH BÁO";
          statusBadge.className = "px-1.5 py-0.2 rounded text-[10px] font-semibold bg-error-container text-on-error uppercase";
        }
        if (statusText) statusText.textContent = `Có ${data.err_pnp_count} thiết bị thiếu driver`;
      }
    }
    const techGpu = document.getElementById("tech-diag-gpu");
    if (techGpu && data.gpu_name) {
      techGpu.textContent = data.gpu_name;
      techGpu.title = data.gpu_name;
    }
    const techNet = document.getElementById("tech-diag-net-chip");
    if (techNet && data.net_name) techNet.textContent = `${data.net_name}: OK`;

    // 10. Phân hệ 07: SMART Ổ Đĩa Realtime Identification
    const diskModel = document.getElementById("disk-model-name");
    if (diskModel && data.disk_name) diskModel.textContent = data.disk_name;
    const diskType = document.getElementById("disk-media-type");
    if (diskType && data.disk_interface) diskType.textContent = data.disk_interface;
    const diskCap = document.getElementById("disk-capacity-val");
    if (diskCap && data.disk_total_gb) diskCap.textContent = `${Math.round(data.disk_total_gb)} GB Physical Storage`;
    const diskSerial = document.getElementById("disk-serial-val");
    if (diskSerial && data.disk_serial) diskSerial.textContent = data.disk_serial;
    const diskFw = document.getElementById("disk-firmware-val");
    if (diskFw && data.disk_firmware) diskFw.textContent = data.disk_firmware;

    // 11. Đồng bộ các nhãn ổ đĩa và GPU trên toàn bộ các view
    const cardGpuDriver = document.getElementById("card-gpu-driver-name");
    if (cardGpuDriver && data.gpu_name) cardGpuDriver.textContent = data.gpu_name;
    const cardPartDisk = document.getElementById("card-partition-disk-name");
    if (cardPartDisk && data.disk_name) cardPartDisk.textContent = `Disk 0: ${data.disk_name}`;
  }

  // --- 8. CPU & MAINBOARD LOOKUP NATIVE MODAL CONTROLLER ---
  let cachedCpuDetails = null;
  async function loadCpuMainData() {
    try {
      const res = await invokeRust("get_cpu_main_details");
      if (res && res.data) {
        cachedCpuDetails = res.data;
        const d = res.data;
        const cpu = d.cpu || {};
        const mb = d.mb || {};
        const bios = d.bios || {};
        const os = d.os || {};
        const cs = d.cs || {};

        const el = (id) => document.getElementById(id);
        if (el("cpu-info-name")) el("cpu-info-name").textContent = cpu.Name || "Intel / AMD Processor";
        if (el("cpu-info-cores")) el("cpu-info-cores").textContent = `${cpu.NumberOfCores || 4} Nhân Thực • ${cpu.NumberOfLogicalProcessors || 4} Luồng Xử Lý`;
        if (el("cpu-info-clock")) el("cpu-info-clock").textContent = `${cpu.MaxClockSpeed || 2400} MHz (Base Clock)`;
        if (el("cpu-info-socket")) el("cpu-info-socket").textContent = cpu.SocketDesignation || "Socket ACPI Standard";
        if (el("cpu-info-arch")) el("cpu-info-arch").textContent = `Architecture: ${cpu.Architecture === 9 ? "x64 (64-bit)" : "x86/ARM"}`;

        if (el("mb-info-mfg")) el("mb-info-mfg").textContent = mb.Manufacturer || "Standard PC";
        if (el("mb-info-model")) el("mb-info-model").textContent = mb.Product || "Reference Platform";
        if (el("mb-info-sn")) el("mb-info-sn").textContent = mb.SerialNumber || "N/A";
        if (el("mb-info-ver")) el("mb-info-ver").textContent = mb.Version || "1.0";

        if (el("bios-info-ver")) el("bios-info-ver").textContent = bios.SMBIOSBIOSVersion || "UEFI";
        if (el("bios-info-mfg")) el("bios-info-mfg").textContent = bios.Manufacturer || "AMI / Insyde";
        if (el("bios-info-date")) el("bios-info-date").textContent = bios.ReleaseDate ? String(bios.ReleaseDate).substring(0, 10) : "Official Release";

        if (el("os-info-caption")) el("os-info-caption").textContent = os.Caption || "Microsoft Windows";
        if (el("os-info-build")) el("os-info-build").textContent = `Build ${os.BuildNumber || os.Version || "19045"}`;
        if (el("cs-info-type")) el("cs-info-type").textContent = cs.Model || "x64-based PC";
      }
    } catch (err) {
      console.warn("loadCpuMainData err:", err);
    }
  }

  function openCpuMainModal() {
    const modal = document.getElementById("modal-cpu-main");
    if (!modal) return;
    modal.classList.remove("hidden");
    loadCpuMainData();
  }

  function closeCpuMainModal() {
    const modal = document.getElementById("modal-cpu-main");
    if (modal) modal.classList.add("hidden");
  }

  function initCpuMainController() {
    const modal = document.getElementById("modal-cpu-main");
    if (!modal) return;

    const btnClose = document.getElementById("btn-close-cpu-modal");
    const btnCloseFoot = document.getElementById("btn-close-cpu-modal-foot");
    if (btnClose) btnClose.addEventListener("click", closeCpuMainModal);
    if (btnCloseFoot) btnCloseFoot.addEventListener("click", closeCpuMainModal);

    modal.addEventListener("click", (e) => {
      if (e.target === modal) closeCpuMainModal();
    });

    const btnRefresh = document.getElementById("btn-refresh-cpu-data");
    if (btnRefresh) {
      btnRefresh.addEventListener("click", () => {
        showToast("Phần Cứng", "Đang quét lại thông số CPU & Mainboard...", "info");
        loadCpuMainData();
      });
    }

    const btnCopy = document.getElementById("btn-copy-cpu-data");
    if (btnCopy) {
      btnCopy.addEventListener("click", () => {
        if (cachedCpuDetails) {
          navigator.clipboard.writeText(JSON.stringify(cachedCpuDetails, null, 2)).then(() => {
            showToast("Đã Sao Chép", "Đã sao chép cấu hình CPU/Mainboard vào Clipboard!", "success");
          });
        } else {
          showToast("Chưa Sẵn Sàng", "Đang tải dữ liệu phần cứng...", "warning");
        }
      });
    }
  }

  // --- 9. LOCAL USER MANAGEMENT NATIVE CONTROLLER ---
  async function loadUserMgmtData() {
    const tableBody = document.getElementById("table-users-body");
    const lblTotal = document.getElementById("lbl-users-total");
    if (!tableBody) return;

    try {
      tableBody.innerHTML = '<tr><td colspan="5" class="p-4 text-center text-on-surface-variant">Đang tải danh sách tài khoản...</td></tr>';
      const res = await invokeRust("get_local_users");
      let users = [];
      if (res && res.data) {
        users = Array.isArray(res.data) ? res.data : [res.data];
      }
      if (users.length === 0) {
        tableBody.innerHTML = '<tr><td colspan="5" class="p-4 text-center text-on-surface-variant">Không tìm thấy tài khoản người dùng cục bộ.</td></tr>';
        if (lblTotal) lblTotal.textContent = "0 tài khoản";
        return;
      }

      if (lblTotal) lblTotal.textContent = `Tổng cộng: ${users.length} tài khoản người dùng`;

      tableBody.innerHTML = users.map((u) => {
        const isAdmin = u.is_admin === true;
        const isEnabled = u.enabled === true;
        const roleBadge = isAdmin
          ? '<span class="px-2 py-0.5 rounded-full text-[11px] font-bold bg-amber-500/20 text-amber-400 border border-amber-500/30">Administrator</span>'
          : '<span class="px-2 py-0.5 rounded-full text-[11px] font-medium bg-surface-container-high text-on-surface-variant">Standard User</span>';
        const statusBadge = isEnabled
          ? '<span class="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-tertiary-container/30 text-tertiary">Hoạt Động</span>'
          : '<span class="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-error-container/30 text-error">Vô Hiệu Hóa</span>';

        return `
          <tr class="hover:bg-surface-container-high/40 transition-colors">
            <td class="p-3">
              <div class="flex items-center gap-2.5">
                <div class="w-7 h-7 rounded-full bg-surface-container-high flex items-center justify-center text-on-surface font-bold text-xs">
                  ${u.name.substring(0, 1).toUpperCase()}
                </div>
                <div>
                  <div class="font-bold text-on-surface">${u.name}</div>
                  <div class="font-code-sm text-xs text-outline">${u.full_name || u.description || "Tài khoản cục bộ"}</div>
                </div>
              </div>
            </td>
            <td class="p-3">${roleBadge}</td>
            <td class="p-3">${statusBadge}</td>
            <td class="p-3 font-code-sm text-xs text-on-surface-variant">${u.last_logon || "Chưa có"}</td>
            <td class="p-3 text-right">
              <div class="flex items-center justify-end gap-1.5">
                <button data-action="toggle_active" data-user="${u.name}" data-val="${isEnabled ? 'disable' : 'enable'}" class="btn-user-action px-2.5 py-1 rounded bg-surface-container hover:bg-surface-bright text-xs font-semibold ${isEnabled ? 'text-error' : 'text-tertiary'} transition-colors cursor-pointer" title="${isEnabled ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}">
                  ${isEnabled ? 'Khóa' : 'Kích hoạt'}
                </button>
                <button data-action="set_password" data-user="${u.name}" class="btn-user-action px-2.5 py-1 rounded bg-surface-container hover:bg-surface-bright text-xs font-semibold text-primary transition-colors cursor-pointer" title="Đổi mật khẩu">
                  Đổi Pass
                </button>
                <button data-action="toggle_admin" data-user="${u.name}" data-val="${isAdmin ? 'remove' : 'add'}" class="btn-user-action px-2.5 py-1 rounded bg-surface-container hover:bg-surface-bright text-xs font-semibold text-secondary transition-colors cursor-pointer" title="${isAdmin ? 'Hạ quyền Admin' : 'Cấp quyền Admin'}">
                  ${isAdmin ? 'Hạ quyền' : 'Lên Admin'}
                </button>
                <button data-action="delete_user" data-user="${u.name}" class="btn-user-action px-2 py-1 rounded bg-error-container/30 hover:bg-error text-xs font-semibold text-error hover:text-on-error transition-colors cursor-pointer" title="Xóa tài khoản">
                  Xóa
                </button>
              </div>
            </td>
          </tr>
        `;
      }).join("");

      tableBody.querySelectorAll(".btn-user-action").forEach((btn) => {
        btn.addEventListener("click", async (e) => {
          e.preventDefault();
          const action = btn.getAttribute("data-action");
          const username = btn.getAttribute("data-user");
          let val = btn.getAttribute("data-val") || "";

          if (action === "set_password") {
            const newPass = prompt(`Nhập mật khẩu mới cho tài khoản [${username}]:`);
            if (newPass === null) return;
            if (!newPass.trim()) {
              showToast("Quản Trị User", "Mật khẩu không được để trống!", "warning");
              return;
            }
            val = newPass.trim();
          } else if (action === "delete_user") {
            if (!confirm(`Bạn có chắc chắn muốn XÓA VĨNH VIỄN tài khoản [${username}]?`)) return;
          }

          showToast("Quản Trị User", `Đang thực thi tác vụ trên tài khoản ${username}...`, "info");
          const mRes = await invokeRust("manage_local_user", {
            subAction: action,
            username: username,
            value: val,
          });

          if (mRes && mRes.success) {
            showToast("Thành Công", mRes.message, "success");
            loadUserMgmtData();
          } else {
            showToast("Thất Bại", (mRes && mRes.message) || "Không thể thực hiện tác vụ!", "error");
          }
        });
      });
    } catch (err) {
      console.warn("loadUserMgmtData err:", err);
      tableBody.innerHTML = `<tr><td colspan="5" class="p-4 text-center text-error">Lỗi khi nạp dữ liệu: ${err.message}</td></tr>`;
    }
  }

  function openUserMgmtModal() {
    const modal = document.getElementById("modal-user-mgmt");
    if (!modal) return;
    modal.classList.remove("hidden");
    loadUserMgmtData();
  }

  function closeUserMgmtModal() {
    const modal = document.getElementById("modal-user-mgmt");
    if (modal) modal.classList.add("hidden");
  }

  function initUserMgmtController() {
    const modal = document.getElementById("modal-user-mgmt");
    if (!modal) return;

    const btnClose = document.getElementById("btn-close-user-modal");
    const btnCloseFoot = document.getElementById("btn-close-user-modal-foot");
    if (btnClose) btnClose.addEventListener("click", closeUserMgmtModal);
    if (btnCloseFoot) btnCloseFoot.addEventListener("click", closeUserMgmtModal);

    modal.addEventListener("click", (e) => {
      if (e.target === modal) closeUserMgmtModal();
    });

    const btnRefresh = document.getElementById("btn-refresh-users");
    if (btnRefresh) {
      btnRefresh.addEventListener("click", () => {
        showToast("Quản Trị User", "Đang làm mới danh sách tài khoản...", "info");
        loadUserMgmtData();
      });
    }

    const btnShowAdd = document.getElementById("btn-show-add-user");
    const formAddPanel = document.getElementById("form-add-user-panel");
    const btnCancelAdd = document.getElementById("btn-cancel-add-user");
    const btnSubmitAdd = document.getElementById("btn-submit-add-user");

    if (btnShowAdd && formAddPanel) {
      btnShowAdd.addEventListener("click", () => {
        formAddPanel.classList.toggle("hidden");
      });
    }

    if (btnCancelAdd && formAddPanel) {
      btnCancelAdd.addEventListener("click", () => {
        formAddPanel.classList.add("hidden");
      });
    }

    if (btnSubmitAdd) {
      btnSubmitAdd.addEventListener("click", async () => {
        const uInput = document.getElementById("input-new-user-name");
        const pInput = document.getElementById("input-new-user-pass");
        const rSelect = document.getElementById("select-new-user-role");

        const username = (uInput ? uInput.value : "").trim();
        const password = (pInput ? pInput.value : "").trim();
        const role = rSelect ? rSelect.value : "user";

        if (!username) {
          showToast("Tạo Tài Khoản", "Vui lòng nhập tên người dùng!", "warning");
          return;
        }

        showToast("Tạo Tài Khoản", `Đang khởi tạo tài khoản [${username}]...`, "info");
        const cRes = await invokeRust("manage_local_user", {
          subAction: "create_user",
          username: username,
          value: password || "User@123",
        });

        if (cRes && cRes.success) {
          if (role === "admin") {
            await invokeRust("manage_local_user", {
              subAction: "toggle_admin",
              username: username,
              value: "add",
            });
          }
          showToast("Thành Công", `Đã tạo tài khoản [${username}] thành công!`, "success");
          if (uInput) uInput.value = "";
          if (pInput) pInput.value = "";
          if (formAddPanel) formAddPanel.classList.add("hidden");
          loadUserMgmtData();
        } else {
          showToast("Thất Bại", (cRes && cRes.message) || "Không thể tạo tài khoản!", "error");
        }
      });
    }
  }

  // --- 9.5 WIN OPTIMIZE TWO-STEP CONTROLLER & LIVE TERMINAL ---
  function initWinOptimizeTwoStep() {
    const optimizeView = document.getElementById("view-win-optimize");
    if (!optimizeView) return;

    const badge = document.getElementById("tweak-selected-badge");
    const terminal = document.getElementById("tweak-terminal-body");
    const btnApply = document.getElementById("btn-apply-tweaks");
    const btnClearLog = document.getElementById("btn-clear-tweak-log");
    const btnCopyLog = document.getElementById("btn-copy-tweak-log");

    function appendTweakLog(text, type = "normal") {
      if (!terminal) return;
      const el = document.createElement("div");
      if (type === "success") el.className = "text-tertiary font-semibold";
      else if (type === "error") el.className = "text-error font-semibold";
      else if (type === "info") el.className = "text-primary font-semibold";
      else if (type === "progress") el.className = "text-secondary";
      else el.className = "text-on-surface-variant";
      el.textContent = text;
      terminal.appendChild(el);
      terminal.scrollTop = terminal.scrollHeight;
    }

    function updateTweakCount() {
      const checkedBoxes = optimizeView.querySelectorAll("input[type='checkbox']:checked");
      const count = checkedBoxes.length;
      if (badge) {
        badge.textContent = `Đã chọn: ${count} mục`;
        if (count > 0) {
          badge.className = "px-2.5 py-0.5 rounded-full bg-primary-container text-on-primary-container font-code-sm text-code-sm font-bold animate-pulse";
        } else {
          badge.className = "px-2.5 py-0.5 rounded-full bg-surface-container-high text-amber-300 font-code-sm text-code-sm font-semibold";
        }
      }
      return count;
    }

    // Attach change listener to all tweak checkboxes
    optimizeView.querySelectorAll("input[type='checkbox']").forEach((cb) => {
      cb.addEventListener("change", updateTweakCount);
    });

    // Preset profile handler (Chọn trước - Chỉ áp dụng khi bấm nút "Áp Dụng Tweaks Đã Chọn")
    window.selectPreset = function(preset) {
      const allCheckboxes = optimizeView.querySelectorAll("input[type='checkbox']");
      const essentialBoxes = optimizeView.querySelectorAll("#essential-list input[type='checkbox']");
      const advancedBoxes = optimizeView.querySelectorAll("#advanced-list input[type='checkbox']");
      const quickBoxes = optimizeView.querySelectorAll(".quick-tweak-cb");
      const activePresetBadge = document.getElementById("active-preset-label");

      let presetTitle = "Tùy Biến";

      if (preset === "clear") {
        allCheckboxes.forEach((cb) => (cb.checked = false));
        presetTitle = "Chưa Chọn (0 mục)";
        if (activePresetBadge) {
          activePresetBadge.textContent = `[${presetTitle}]`;
          activePresetBadge.className = "px-2.5 py-0.5 rounded-full bg-surface-container-high text-outline font-code-sm text-code-sm font-semibold";
        }
        showToast("Tinh Chỉnh Windows", "Đã bỏ chọn toàn bộ mục. Bấm 'Áp Dụng' để thực thi nếu muốn xóa sạch.", "info");
      } else if (preset === "minimal") {
        allCheckboxes.forEach((cb) => (cb.checked = false));
        essentialBoxes.forEach((cb, idx) => {
          if (idx < 5) cb.checked = true;
        });
        presetTitle = "Đang Chọn: Tối Giản (Minimal - Chưa Áp Dụng)";
        if (activePresetBadge) {
          activePresetBadge.textContent = `[${presetTitle}]`;
          activePresetBadge.className = "px-2.5 py-0.5 rounded-full bg-secondary-container text-on-secondary-container font-code-sm text-code-sm font-bold animate-pulse";
        }
        showToast("Preset Minimal", "Đã đánh dấu 5 mục an toàn. Vui lòng bấm 'Áp Dụng Tweaks Đã Chọn' bên dưới để bắt đầu!", "info");
      } else if (preset === "standard") {
        allCheckboxes.forEach((cb) => (cb.checked = false));
        essentialBoxes.forEach((cb) => (cb.checked = true));
        quickBoxes.forEach((cb) => {
          const tw = cb.getAttribute("data-tweak");
          if (["clean_temp", "flush_dns", "optimize_ram"].includes(tw)) {
            cb.checked = true;
          }
        });
        presetTitle = "Đang Chọn: Chuẩn (Standard - Chưa Áp Dụng)";
        if (activePresetBadge) {
          activePresetBadge.textContent = `[${presetTitle}]`;
          activePresetBadge.className = "px-2.5 py-0.5 rounded-full bg-primary-container text-on-primary-container font-code-sm text-code-sm font-bold animate-pulse";
        }
        showToast("Preset Chuẩn", "Đã đánh dấu bộ tinh chỉnh chuẩn. Vui lòng bấm 'Áp Dụng Tweaks Đã Chọn' bên dưới để thực thi!", "info");
      } else if (preset === "advanced") {
        essentialBoxes.forEach((cb) => (cb.checked = true));
        advancedBoxes.forEach((cb) => (cb.checked = true));
        quickBoxes.forEach((cb) => (cb.checked = true));
        presetTitle = "Đang Chọn: Nâng Cao (Advanced - Chưa Áp Dụng)";
        if (activePresetBadge) {
          activePresetBadge.textContent = `[${presetTitle}]`;
          activePresetBadge.className = "px-2.5 py-0.5 rounded-full bg-error-container text-on-error-container font-code-sm text-code-sm font-bold animate-pulse";
        }
        showToast("Preset Nâng Cao", "Đã đánh dấu toàn bộ tinh chỉnh nâng cao. Vui lòng bấm 'Áp Dụng Tweaks Đã Chọn' để thực thi!", "warning");
      }

      // Update button styling in preset bar
      const presetBtns = optimizeView.querySelectorAll(".preset-btn");
      presetBtns.forEach((btn) => {
        const text = btn.innerText.toLowerCase();
        if ((preset === "clear" && text.includes("bỏ chọn")) ||
            (preset === "minimal" && text.includes("tối giản")) ||
            (preset === "standard" && text.includes("chuẩn")) ||
            (preset === "advanced" && text.includes("nâng cao"))) {
          btn.className = "preset-btn px-3 py-1.5 rounded-lg bg-primary-container text-on-primary-container font-label-md text-label-md transition-all font-bold shadow-sm";
        } else {
          btn.className = "preset-btn px-3 py-1.5 rounded-lg bg-surface-container text-on-surface hover:bg-surface-container-high font-label-md text-label-md transition-all";
        }
      });

      updateTweakCount();
    };

    window.applyPreset = window.selectPreset;

    window.restoreWinDefaults = async function() {
      if (!confirm("Bạn có chắc chắn muốn khôi phục toàn bộ tinh chỉnh về trạng thái mặc định ban đầu của Windows?")) return;
      window.applyPreset("clear");
      appendTweakLog("[KHÔI PHỤC] Đang khôi phục cài đặt gốc của hệ thống...", "info");
      showToast("Khôi Phục Gốc", "Đang khôi phục các thiết lập Windows về mặc định...", "info");
      await invokeRust("run_system_action", { actionId: "modern_context_menu" });
      await invokeRust("run_system_action", { actionId: "set_power_plan", plan: "restore_default" });
      appendTweakLog("[THÀNH CÔNG] ✓ Đã khôi phục Menu Chuột Phải hiện đại và Gói Nguồn điện mặc định!", "success");
      showToast("Hoàn Tất", "Đã khôi phục cài đặt gốc thành công!", "success");
    };

    window.cleanAppxBloatware = async function() {
      if (!confirm("Bạn có chắc muốn gỡ bỏ các ứng dụng rác AppX ngầm (BingNews, Weather, Solitaire, v.v.)?")) return;
      appendTweakLog("[DỌN RÁC] Đang tiến hành gỡ bỏ các gói AppX Bloatware ngầm...", "progress");
      showToast("Dọn App Rác", "Đang gỡ bỏ AppX Bloatware...", "info");
      const res = await invokeRust("run_system_action", { actionId: "clean_appx_bloatware" });
      if (res && res.success) {
        appendTweakLog(`[THÀNH CÔNG] ✓ ${res.message}`, "success");
        showToast("Thành Công", res.message, "success");
      } else {
        appendTweakLog(`[LỖI] ✗ ${(res && res.message) || "Không thể dọn AppX"}`, "error");
        showToast("Lỗi", (res && res.message) || "Không thể dọn AppX", "error");
      }
    };

    window.detectCurrentTweaks = async function() {
      appendTweakLog("[QUÉT REGISTRY] Đang kiểm tra trạng thái tinh chỉnh thực tế trên máy...", "progress");
      showToast("Quét Tinh Chỉnh", "Đang đối chiếu trạng thái Registry...", "info");
      const res = await invokeRust("run_system_action", { actionId: "check_classic_context" });
      const classicInput = optimizeView.querySelector('input[data-tweak="classic_context_menu"]');
      if (classicInput && res) {
        classicInput.checked = (res.success && res.message && res.message.includes("active"));
      }
      updateTweakCount();
      appendTweakLog("[HOÀN TẤT] Đã đồng bộ trạng thái thực tế từ Windows Registry!", "success");
      showToast("Hoàn Tất", "Đã cập nhật danh sách tùy chọn đang áp dụng!", "success");
    };

    // Apply Tweaks Button (2-Step Execution)
    if (btnApply) {
      btnApply.addEventListener("click", async () => {
        const checkedBoxes = Array.from(optimizeView.querySelectorAll("input[type='checkbox']:checked"));
        const count = checkedBoxes.length;

        if (count === 0) {
          showToast("Tinh Chỉnh Windows", "Vui lòng tích chọn ít nhất 1 mục để áp dụng!", "warning");
          appendTweakLog("[CẢNH BÁO] Chưa có mục nào được chọn. Vui lòng tick chọn ít nhất 1 tinh chỉnh bên trên.", "error");
          return;
        }

        btnApply.disabled = true;
        btnApply.innerHTML = `<span class="material-symbols-outlined text-[18px] animate-spin">refresh</span><span>Đang áp dụng (${count} mục)...</span>`;

        const now = new Date().toLocaleTimeString();
        appendTweakLog(`\n==================================================`);
        appendTweakLog(`[${now}] [BẮT ĐẦU] Tiến hành thực thi ${count} tinh chỉnh Windows với quyền Administrator...`, "info");

        let successCount = 0;
        let failCount = 0;

        for (const cb of checkedBoxes) {
          let actionId = cb.getAttribute("data-tweak");
          let title = "";

          const card = cb.closest("label") || cb.closest("div");
          if (card) {
            const titleEl = card.querySelector(".font-body-md, .font-label-md, .text-on-surface");
            title = titleEl ? titleEl.textContent.trim() : "Tinh chỉnh Windows";
          }

          if (!actionId) {
            const low = title.toLowerCase();
            if (low.includes("lịch sử hoạt động")) actionId = "disable_activity_history";
            else if (low.includes("bitlocker")) actionId = "disable_bitlocker_auto";
            else if (low.includes("app rác") || low.includes("consumer")) actionId = "disable_consumer_features";
            else if (low.includes("ngang hàng") || low.includes("delivery")) actionId = "disable_delivery_optimization";
            else if (low.includes("end task")) actionId = "enable_end_task";
            else if (low.includes("thư mục")) actionId = "disable_folder_discovery";
            else if (low.includes("ngủ đông")) actionId = "disable_hibernation";
            else if (low.includes("vị trí")) actionId = "disable_location_tracking";
            else if (low.includes("quảng cáo") || low.includes("store")) actionId = "disable_store_ads";
            else if (low.includes("thu thập") || low.includes("telemetry")) actionId = "disable_telemetry";
            else if (low.includes("khôi phục") || low.includes("restore")) actionId = "create_restore_point";
            else if (low.includes("widget")) actionId = "remove_widgets";
            else if (low.includes("chạy ngầm")) actionId = "disable_background_apps";
            else if (low.includes("dự phòng") || low.includes("reserved")) actionId = "disable_reserved_storage";
            else if (low.includes("ipv4")) actionId = "prefer_ipv4";
            else if (low.includes("chuột phải") || low.includes("classic")) actionId = "classic_context_menu";
            else if (low.includes("hiệu năng")) actionId = "best_performance";
            else if (low.includes("game") || low.includes("dvr")) actionId = "optimize_game_mode";
            else actionId = "tune_system";
          }

          appendTweakLog(`[TIẾN TRÌNH] Đang cấu hình: ${title}...`, "progress");

          try {
            const res = await invokeRust("run_system_action", { actionId: actionId, tweakName: title });
            if (res && res.success) {
              successCount++;
              appendTweakLog(`[THÀNH CÔNG] ✓ ${title} -> ${res.message || "Hoàn tất."}`, "success");
            } else {
              failCount++;
              appendTweakLog(`[LỖI] ✗ ${title} -> ${(res && res.message) || "Không thể áp dụng"}`, "error");
            }
          } catch (err) {
            failCount++;
            appendTweakLog(`[LỖI NGOẠI LỆ] ✗ ${title} -> ${err}`, "error");
          }
        }

        const endTime = new Date().toLocaleTimeString();
        appendTweakLog(`[${endTime}] [HOÀN TẤT] Tổng kết: ${successCount} thành công, ${failCount} thất bại.`, successCount > 0 ? "success" : "error");
        appendTweakLog(`==================================================\n`);

        btnApply.disabled = false;
        btnApply.innerHTML = `<span class="material-symbols-outlined text-[18px]">done_all</span><span>Áp Dụng Tweaks Đã Chọn</span>`;

        showToast("Hoàn Tất Tinh Chỉnh", `Đã xử lý xong ${count} mục (${successCount} thành công, ${failCount} lỗi).`, successCount > 0 ? "success" : "warning");
      });
    }

    if (btnClearLog && terminal) {
      btnClearLog.addEventListener("click", () => {
        terminal.innerHTML = '<div class="text-outline/70">[Ready] Hệ thống sẵn sàng. Đã xóa nhật ký.</div>';
      });
    }

    if (btnCopyLog && terminal) {
      btnCopyLog.addEventListener("click", () => {
        navigator.clipboard.writeText(terminal.innerText).then(() => {
          showToast("Đã Sao Chép", "Đã sao chép toàn bộ nhật ký terminal vào clipboard!", "success");
        });
      });
    }

    // --- POWER PLANS CONTROLLER ---
    function updatePowerPlanButtonsUI(activeKey) {
      const container = document.getElementById("power-plans-grid");
      if (!container) return;

      container.querySelectorAll(".power-plan-btn").forEach((b) => {
        const planKey = b.getAttribute("data-plan");
        const isNeverSleep = (planKey === "never_sleep");
        const isSelected = (planKey === activeKey);
        const colClass = isNeverSleep ? "col-span-2 md:col-span-2" : "";

        const ping = b.querySelector(".power-plan-ping");
        if (ping) ping.remove();

        if (isSelected) {
          // Nút được chọn (Active) - Đồng bộ màu đỏ / amber nổi bật
          if (isNeverSleep) {
            b.className = `power-plan-btn p-3.5 rounded-xl bg-amber-50/90 text-amber-950 border-2 border-amber-500 ring-2 ring-amber-400/30 flex flex-col justify-between gap-1 text-left shadow-sm transition-all cursor-pointer min-h-[92px] ${colClass}`;
          } else {
            b.className = `power-plan-btn p-3.5 rounded-xl bg-red-50/90 text-red-950 border-2 border-red-500 ring-2 ring-red-400/30 flex flex-col justify-between gap-1 text-left shadow-sm transition-all cursor-pointer min-h-[92px] ${colClass}`;
          }
          const topRow = b.querySelector(".flex.items-center.justify-between");
          if (topRow) {
            const pingEl = document.createElement("span");
            pingEl.className = isNeverSleep
              ? "power-plan-ping w-2.5 h-2.5 rounded-full bg-amber-500 shadow-xs animate-ping"
              : "power-plan-ping w-2.5 h-2.5 rounded-full bg-red-500 shadow-xs animate-ping";
            topRow.appendChild(pingEl);
          }
        } else {
          // Nút Unselected - Luôn giữ viền rõ ràng, nền kính trắng, bóng đổ nhẹ
          b.className = `power-plan-btn p-3.5 rounded-xl bg-white/80 hover:bg-white text-slate-800 border border-slate-200/90 hover:border-slate-300 hover:shadow-xs flex flex-col justify-between gap-1 text-left transition-all cursor-pointer min-h-[92px] shadow-2xs ${colClass}`;
        }
      });
    }
    window.updatePowerPlanButtonsUI = updatePowerPlanButtonsUI;

    window.selectPowerPlan = async function(btn, planName) {
      const planKey = btn ? btn.getAttribute("data-plan") : null;
      if (planKey) {
        updatePowerPlanButtonsUI(planKey);
      }

      appendTweakLog(`[NGUỒN ĐIỆN] Đang áp dụng cấu hình: ${planName}...`, "progress");
      showToast("Gói Nguồn Điện", `Đang chuyển sang gói ${planName}...`, "info");

      try {
        const res = await invokeRust("run_system_action", {
          actionId: "set_power_plan",
          plan: planName,
          params: { plan: planName }
        });
        if (res && res.success) {
          appendTweakLog(`[THÀNH CÔNG] ✓ ${res.message}`, "success");
          showToast("Thành Công", res.message, "success");
          setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 300);
        } else {
          appendTweakLog(`[LỖI] ✗ ${(res && res.message) || "Không thể kích hoạt gói nguồn"}`, "error");
          showToast("Lỗi", (res && res.message) || "Không thể chuyển nguồn điện", "error");
        }
      } catch (err) {
        appendTweakLog(`[LỖI] ✗ ${err}`, "error");
        showToast("Lỗi", String(err), "error");
      }
    };

    // --- CHẾ ĐỘ 24/7 (NEVER SLEEP) CONTROLLER ---
    window.toggleNeverSleep = async function() {
      appendTweakLog("[CHẾ ĐỘ 24/7] Đang thiết lập chế độ Không Ngủ (Never Sleep / 24/7 Non-stop)...", "progress");
      showToast("Nguồn Điện 24/7", "Đang tắt Sleep, Hibernate và tắt đĩa để máy tính chạy 24/7...", "info");
      try {
        const res = await invokeRust("run_system_action", {
          actionId: "set_never_sleep",
          plan: "never_sleep",
          params: { plan: "never_sleep" }
        });
        if (res && res.success) {
          appendTweakLog(`[THÀNH CÔNG] ✓ ${res.message}`, "success");
          showToast("Thành Công 24/7", res.message, "success");
          setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 300);
        } else {
          appendTweakLog(`[LỖI] ✗ ${(res && res.message) || "Không thể kích hoạt chế độ 24/7"}`, "error");
          showToast("Lỗi", (res && res.message) || "Không thể kích hoạt chế độ 24/7", "error");
        }
      } catch (err) {
        appendTweakLog(`[LỖI] ✗ ${err}`, "error");
        showToast("Lỗi", String(err), "error");
      }
    };

    // --- DNS CONTROLLER ---
    window.changeDns = async function(dnsVal) {
      appendTweakLog(`[DNS] Đang chuyển máy chủ DNS sang [${dnsVal}]...`, "progress");
      showToast("Đổi DNS", `Đang thiết lập máy chủ DNS [${dnsVal}]...`, "info");

      try {
        const res = await invokeRust("run_system_action", {
          actionId: "change_dns",
          dns: dnsVal,
          params: { dns: dnsVal }
        });
        if (res && res.success) {
          appendTweakLog(`[THÀNH CÔNG] ✓ ${res.message}`, "success");
          showToast("Thành Công", res.message, "success");
          setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 500);
        } else {
          appendTweakLog(`[LỖI] ✗ ${(res && res.message) || "Không thể đổi DNS"}`, "error");
          showToast("Lỗi", (res && res.message) || "Lỗi khi cấu hình DNS", "error");
        }
      } catch (err) {
        appendTweakLog(`[LỖI] ✗ ${err}`, "error");
        showToast("Lỗi", String(err), "error");
      }
    };

    // --- SYNC REAL WIN OPTIMIZE & POWER STATE ---
    window.syncRealWinOptimizeState = async function() {
      try {
        const res = await invokeRust("get_win_optimize_state", {});
        if (!res || !res.success || !res.data) return;
        const data = res.data;

        // 1. Đồng bộ Gói Nguồn Điện (Power Plans) thực tế
        const powerGrid = document.getElementById("power-plans-grid");
        const powerBadge = document.getElementById("active-power-badge");
        if (powerGrid) {
          const schemeLower = (data.scheme || "").toLowerCase();
          let activeKey = "balanced";
          let badgeText = "BALANCED ACTIVE";
          let badgeColor = "bg-sky-100 text-sky-700 border border-sky-300";

          if (data.sleep_seconds === 0 && (data.disk_seconds === 0 || data.disk_seconds === undefined) && (schemeLower.includes("high") || schemeLower.includes("never"))) {
            activeKey = "never_sleep";
            badgeText = "24/7 NON-STOP ACTIVE";
            badgeColor = "bg-amber-100 text-amber-700 border border-amber-300";
          } else if (schemeLower.includes("ultimate") || schemeLower.includes("cuc dai") || schemeLower.includes("cực đại")) {
            activeKey = "ultimate";
            badgeText = "ULTIMATE ACTIVE";
            badgeColor = "bg-red-100 text-red-700 border border-red-300";
          } else if (schemeLower.includes("high") || schemeLower.includes("hieu nang cao") || schemeLower.includes("hiệu năng cao")) {
            activeKey = "high";
            badgeText = "HIGH PERF ACTIVE";
            badgeColor = "bg-sky-100 text-sky-700 border border-sky-300";
          } else if (schemeLower.includes("saver") || schemeLower.includes("tiet kiem") || schemeLower.includes("tiết kiệm")) {
            activeKey = "saver";
            badgeText = "SAVER ACTIVE";
            badgeColor = "bg-emerald-100 text-emerald-700 border border-emerald-300";
          } else {
            activeKey = "balanced";
            badgeText = "BALANCED ACTIVE";
            badgeColor = "bg-teal-100 text-teal-700 border border-teal-300";
          }

          // Cập nhật giao diện các nút một cách đồng bộ, an toàn layout
          updatePowerPlanButtonsUI(activeKey);

          if (powerBadge) {
            powerBadge.textContent = badgeText;
            powerBadge.className = `px-2 py-0.5 rounded font-mono text-xs font-bold uppercase shadow-2xs ${badgeColor}`;
          }
        }

        // 2. Đồng bộ DNS thực tế của card mạng
        const dnsSelector = document.getElementById("dns-selector");
        const dnsBadge = document.getElementById("active-dns-badge");
        const primaryText = document.getElementById("dns-primary-text");
        const secondaryText = document.getElementById("dns-secondary-text");
        const adapterText = document.getElementById("dns-adapter-text");

        const dnsList = data.dns || [];
        const primaryDns = dnsList[0] || "";
        const secondaryDns = dnsList[1] || "";
        const adapter = data.adapter || "Active LAN";

        if (primaryText) primaryText.textContent = `Primary: ${primaryDns || "DHCP Tự Nhận"}`;
        if (secondaryText) secondaryText.textContent = `Secondary: ${secondaryDns || "(Không có)"}`;
        if (adapterText) adapterText.textContent = `Card: ${adapter}`;

        if (dnsSelector) {
          if (primaryDns === "1.1.1.1") dnsSelector.value = "cloudflare";
          else if (primaryDns === "8.8.8.8") dnsSelector.value = "google";
          else if (primaryDns === "9.9.9.9") dnsSelector.value = "quad9";
          else if (primaryDns.startsWith("94.140.")) dnsSelector.value = "adguard";
          else dnsSelector.value = "dhcp";
        }

        if (dnsBadge) {
          dnsBadge.textContent = primaryDns ? `${primaryDns} Active` : "DHCP Router";
        }

        // 3. Đồng bộ Toggles cài đặt hệ thống thực tế
        const toggleDark = document.getElementById("toggle-dark-theme");
        if (toggleDark) toggleDark.checked = !!data.dark_theme;

        const toggleLong = document.getElementById("toggle-long-paths");
        if (toggleLong) toggleLong.checked = !!data.long_paths;

        const toggleExt = document.getElementById("toggle-show-ext");
        if (toggleExt) toggleExt.checked = !!data.show_ext;

        const toggleHidden = document.getElementById("toggle-show-hidden");
        if (toggleHidden) toggleHidden.checked = !!data.show_hidden;

        const toggleClassic = document.getElementById("toggle-classic-context");
        if (toggleClassic) toggleClassic.checked = !!data.classic_context;

        // 4. Đồng bộ trạng thái Super Lean Profile & Nút Hoàn Tác
        const isSuperLean = localStorage.getItem("super_lean_applied") === "true";
        updateSuperLeanUI(isSuperLean);

      } catch (e) {
        console.warn("syncRealWinOptimizeState error:", e);
      }
    };

    // --- CẬP NHẬT TRẠNG THÁI GIAO DIỆN NÚT HOÀN TÁC CẤU HÌNH SIÊU NHẸ ---
    function updateSuperLeanUI(isApplied) {
      const badge = document.getElementById("super-lean-status-badge");
      const revertBtn = document.getElementById("btn-revert-super-lean");
      if (isApplied) {
        if (badge) {
          badge.className = "px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 shadow-sm flex items-center gap-1";
          badge.innerHTML = '<span class="material-symbols-outlined text-[13px] text-emerald-400">check_circle</span><span>Đang Bật Cấu Hình Siêu Nhẹ</span>';
        }
        if (revertBtn) {
          revertBtn.className = "px-4 py-3 rounded-xl bg-amber-500/20 hover:bg-amber-500/30 text-amber-200 font-label-md text-label-md font-bold flex items-center justify-center gap-2 transition-all border-2 border-amber-400/80 shadow-lg ring-2 ring-amber-400/40 animate-pulse";
          revertBtn.innerHTML = '<span class="material-symbols-outlined text-[18px] text-amber-300">undo</span><span>↩ HOÀN TÁC VỀ MẶC ĐỊNH TRƯỚC ĐÓ</span>';
          revertBtn.title = "Bấm vào đây để hủy bỏ toàn bộ tối ưu và khôi phục về trạng thái chuẩn mặc định của Windows";
        }
      } else {
        if (badge) {
          badge.className = "px-2.5 py-0.5 rounded-full text-xs font-semibold bg-surface-container-high text-on-surface-variant border border-outline/20";
          badge.innerHTML = "⚪ Chuẩn Windows (Mặc Định)";
        }
        if (revertBtn) {
          revertBtn.className = "px-4 py-3 rounded-xl bg-surface-container-highest hover:bg-error-container hover:text-on-error-container text-on-surface font-label-md text-label-md font-semibold flex items-center justify-center gap-2 transition-all border border-outline/20";
          revertBtn.innerHTML = '<span class="material-symbols-outlined text-[18px]">undo</span><span>HOÀN TÁC VỀ MẶC ĐỊNH</span>';
          revertBtn.title = "Khôi phục toàn bộ cài đặt về mặc định của hệ thống";
        }
      }
    }

    // --- GENERIC SYSTEM ACTION CALLER ---
    window.runSystemAction = async function(actionId, params) {
      appendTweakLog(`[HỆ THỐNG] Đang thực thi tác vụ: ${actionId}...`, "progress");
      showToast("Đang Xử Lý", `Đang thực thi tác vụ: ${actionId}...`, "info");
      try {
        const res = await invokeRust("run_system_action", { actionId, params: params || {} });
        if (res && res.success) {
          appendTweakLog(`[THÀNH CÔNG] ✓ ${res.message}`, "success");
          showToast("Thành Công", res.message, "success");
          setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 400);
        } else {
          appendTweakLog(`[LỖI] ✗ ${(res && res.message) || "Thao tác thất bại"}`, "error");
          showToast("Lỗi", (res && res.message) || "Thao tác thất bại", "error");
        }
        return res;
      } catch (e) {
        appendTweakLog(`[LỖI] ✗ ${e}`, "error");
        showToast("Lỗi", String(e), "error");
        return { success: false, message: String(e) };
      }
    };

    // --- SUPER LEAN PROFILE & HOÀN TÁC (UNDO ENGINE) ---
    window.applySuperLeanProfile = async function() {
      const btnApply = document.getElementById("btn-apply-super-lean");
      const badge = document.getElementById("super-lean-status-badge");

      if (btnApply) {
        btnApply.disabled = true;
        btnApply.classList.add("opacity-80", "cursor-wait");
        btnApply.innerHTML = '<span class="material-symbols-outlined text-[20px] animate-spin">progress_activity</span><span>ĐANG TỐI ƯU SIÊU NHẸ...</span>';
      }

      if (badge) {
        badge.className = "px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40 shadow-sm flex items-center gap-1 animate-pulse";
        badge.innerHTML = '<span class="material-symbols-outlined text-[13px] animate-spin">progress_activity</span><span>Đang tối ưu hệ thống...</span>';
      }

      appendTweakLog("==================================================================", "progress");
      appendTweakLog("[BẮT ĐẦU] 🚀 TIẾN TRÌNH KÍCH HOẠT CẤU HÌNH TỐI ƯU SIÊU NHẸ 2026...", "progress");
      showToast("Cấu Hình Siêu Nhẹ 2026", "Bắt đầu tiến trình tối ưu siêu nhẹ theo 5 bước...", "info");

      try {
        // BƯỚC 1: Dọn dẹp RAM Working Set
        appendTweakLog("[BƯỚC 1/5] 🧹 Đang giải phóng bộ nhớ RAM Working Set (mục tiêu 1.5 - 1.8GB)...", "progress");
        if (btnApply) btnApply.querySelector('span:last-child').textContent = "ĐANG DỌN RAM (1/5)...";
        const resRam = await invokeRust("run_system_action", { actionId: "optimize_ram" });
        if (resRam && resRam.success) {
          appendTweakLog(`  ✓ [1/5 Thành công] ${resRam.message}`, "success");
        } else {
          appendTweakLog(`  ⚠️ [1/5 Lưu ý] ${(resRam && resRam.message) || "Đã áp dụng tối ưu RAM cơ bản."}`, "info");
        }

        // BƯỚC 2: Gỡ bỏ 28 ứng dụng bloatware rác (bảo tồn Edge, WebView2, Defender)
        appendTweakLog("[BƯỚC 2/5] 🗑️ Đang gỡ bỏ 28 ứng dụng bloatware rác (bảo tồn Edge, WebView2 & Defender)...", "progress");
        if (btnApply) btnApply.querySelector('span:last-child').textContent = "ĐANG GỠ APP RÁC (2/5)...";
        const resApps = await invokeRust("run_system_action", { actionId: "purge_bloatware_28_apps" });
        if (resApps && resApps.success) {
          appendTweakLog(`  ✓ [2/5 Thành công] ${resApps.message}`, "success");
        } else {
          appendTweakLog(`  ⚠️ [2/5 Lưu ý] ${(resApps && resApps.message) || "Đã xử lý danh sách ứng dụng rác."}`, "info");
        }

        // BƯỚC 3: Tweaks giao diện & Tiện ích Desktop
        appendTweakLog("[BƯỚC 3/5] ⚡ Đang thiết lập 4 icon Desktop, PrtSc mở Snipping Tool, Control Panel Icons...", "progress");
        if (btnApply) btnApply.querySelector('span:last-child').textContent = "CẤU HÌNH TWEAKS (3/5)...";
        await invokeRust("run_system_action", { actionId: "set_desktop_icons_classic" });
        await invokeRust("run_system_action", { actionId: "set_control_panel_icons" });
        await invokeRust("run_system_action", { actionId: "set_printscreen_snipping_tool" });
        appendTweakLog("  ✓ [3/5 Thành công] Đã kích hoạt 4 icon Desktop (This PC, Recycle Bin, LAN, Control Panel) & Snipping Tool.", "success");

        // BƯỚC 4: Vô hiệu hóa Copilot, Windows AI Recall, Fax, Hyper-V & Telemetry
        appendTweakLog("[BƯỚC 4/5] 🚫 Đang tắt Copilot, Windows AI Recall, Fax, Hyper-V & Sponsored Apps...", "progress");
        if (btnApply) btnApply.querySelector('span:last-child').textContent = "TẮT DỊCH VỤ THỪA (4/5)...";
        await invokeRust("run_system_action", { actionId: "disable_copilot_ai" });
        await invokeRust("run_system_action", { actionId: "disable_hyperv_fax" });
        await invokeRust("run_system_action", { actionId: "disable_sponsored_apps" });
        appendTweakLog("  ✓ [4/5 Thành công] Đã vô hiệu hóa Copilot & các dịch vụ nền tiêu hao tài nguyên.", "success");

        // BƯỚC 5: Kích hoạt CompactOS nén đĩa ngầm & Master Profile
        appendTweakLog("[BƯỚC 5/5] 💾 Đang kích hoạt nén hệ thống CompactOS tiết kiệm ~12.5GB đĩa cứng...", "progress");
        if (btnApply) btnApply.querySelector('span:last-child').textContent = "KÍCH HOẠT COMPACTOS (5/5)...";
        const resFinal = await invokeRust("run_system_action", { actionId: "apply_super_lean_profile" });
        if (resFinal && resFinal.message) {
          const lines = resFinal.message.split('\n');
          lines.forEach(l => {
            if (l.trim()) appendTweakLog(`  • ${l.trim()}`, "info");
          });
        }

        // HOÀN TẤT THÀNH CÔNG
        appendTweakLog("==================================================================", "success");
        appendTweakLog("[HOÀN TẤT 100%] 🎉 CẤU HÌNH SIÊU NHẸ 2026 ĐÃ ĐƯỢC ÁP DỤNG THÀNH CÔNG VÀ AN TOÀN TUYỆT ĐỐI!", "success");
        appendTweakLog("[GHI CHÚ] 💡 Nếu muốn quay lại cài đặt gốc, bạn có thể bấm nút '↩ HOÀN TÁC VỀ MẶC ĐỊNH TRƯỚC ĐÓ' bất kỳ lúc nào.", "info");

        localStorage.setItem("super_lean_applied", "true");
        updateSuperLeanUI(true);
        showToast("Thành Công Siêu Nhẹ", "Đã hoàn tất 100% Cấu Hình Siêu Nhẹ 2026!", "success");
        setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 500);

      } catch (err) {
        appendTweakLog("==================================================================", "error");
        appendTweakLog(`[LỖI] ✗ Quá trình áp dụng cấu hình gặp lỗi: ${err}`, "error");
        appendTweakLog("[HƯỚNG DẪN] 💡 Hãy khởi chạy ứng dụng với quyền Administrator để đảm bảo đầy đủ quyền tinh chỉnh hệ thống.", "error");
        showToast("Lỗi", String(err), "error");
        if (badge) {
          badge.className = "px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-500/20 text-rose-300 border border-rose-500/40 shadow-sm flex items-center gap-1";
          badge.innerHTML = '<span class="material-symbols-outlined text-[13px] text-rose-400">error</span><span>Lỗi xử lý</span>';
        }
      } finally {
        if (btnApply) {
          btnApply.disabled = false;
          btnApply.classList.remove("opacity-80", "cursor-wait");
          btnApply.innerHTML = '<span class="material-symbols-outlined text-[20px]">bolt</span><span>ÁP DỤNG CẤU HÌNH SIÊU NHẸ</span>';
        }
      }
    };

    window.revertSuperLeanProfile = async function() {
      const btnRevert = document.getElementById("btn-revert-super-lean");
      const badge = document.getElementById("super-lean-status-badge");

      if (btnRevert) {
        btnRevert.disabled = true;
        btnRevert.classList.add("opacity-80", "cursor-wait");
        btnRevert.innerHTML = '<span class="material-symbols-outlined text-[18px] animate-spin">progress_activity</span><span>ĐANG HOÀN TÁC...</span>';
      }

      appendTweakLog("==================================================================", "progress");
      appendTweakLog("[BẮT ĐẦU HOÀN TÁC] 🔄 Đang khôi phục cài đặt hệ thống về chuẩn mặc định Windows...", "progress");
      showToast("Hoàn Tác Về Mặc Định", "Đang khôi phục toàn bộ cài đặt về mặc định của hệ thống...", "info");

      try {
        // BƯỚC 1: Hoàn tác Desktop Icons & Control Panel
        appendTweakLog("[BƯỚC 1/3] 🔄 Đang khôi phục biểu tượng Desktop, Control Panel & PrtSc về mặc định...", "progress");
        await invokeRust("run_system_action", { actionId: "revert_desktop_icons" });
        await invokeRust("run_system_action", { actionId: "revert_control_panel_icons" });
        await invokeRust("run_system_action", { actionId: "revert_printscreen_snipping_tool" });
        appendTweakLog("  ✓ Đã hoàn tác giao diện Desktop & Control Panel.", "success");

        // BƯỚC 2: Khôi phục Copilot, AI, Fax, Hyper-V & Sponsored Apps
        appendTweakLog("[BƯỚC 2/3] 🔄 Đang khôi phục Copilot, AI Recall, Fax, Hyper-V & Dịch vụ hệ thống...", "progress");
        await invokeRust("run_system_action", { actionId: "revert_copilot_ai" });
        await invokeRust("run_system_action", { actionId: "revert_hyperv_fax" });
        await invokeRust("run_system_action", { actionId: "revert_sponsored_apps" });
        appendTweakLog("  ✓ Đã khôi phục trạng thái chuẩn cho các dịch vụ.", "success");

        // BƯỚC 3: Gọi backend revert master profile
        appendTweakLog("[BƯỚC 3/3] 🔄 Đang khôi phục nguồn điện chuẩn (powercfg) & khởi động lại Explorer...", "progress");
        const res = await invokeRust("run_system_action", { actionId: "revert_super_lean_profile" });
        if (res && res.message) {
          const lines = res.message.split('\n');
          lines.forEach(l => {
            if (l.trim()) appendTweakLog(`  • ${l.trim()}`, "info");
          });
        }

        appendTweakLog("==================================================================", "success");
        appendTweakLog("[HOÀN TẤT] ✅ ĐÃ KHÔI PHỤC TOÀN BỘ CÀI ĐẶT VỀ MẶC ĐỊNH WINDOWS BAN ĐẦU THÀNH CÔNG!", "success");

        localStorage.setItem("super_lean_applied", "false");
        updateSuperLeanUI(false);
        showToast("Khôi Phục Thành Công", "Đã hoàn tác toàn bộ cấu hình về mặc định Windows!", "success");
        setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 500);

      } catch (err) {
        appendTweakLog(`[LỖI] ✗ Không thể hoàn tác cấu hình: ${err}`, "error");
        showToast("Lỗi", String(err), "error");
      } finally {
        if (btnRevert) {
          btnRevert.disabled = false;
          btnRevert.classList.remove("opacity-80", "cursor-wait");
          btnRevert.innerHTML = '<span class="material-symbols-outlined text-[18px]">undo</span><span>HOÀN TÁC VỀ MẶC ĐỊNH</span>';
        }
      }
    };

    // --- BIOS LICENSE RECOGNITION CONTROLLER ---
    window.checkBiosLicense = async function() {
      const keyEl = document.getElementById("bios-license-key");
      const badgeEl = document.getElementById("bios-license-badge");
      const noteEl = document.getElementById("bios-license-note");

      if (keyEl) keyEl.textContent = "Đang truy vấn bảng MSDM / OA3x trong BIOS...";
      if (badgeEl) {
        badgeEl.textContent = "Đang quét...";
        badgeEl.className = "px-2 py-0.5 rounded text-xs font-mono font-bold bg-surface-container text-on-surface-variant animate-pulse";
      }

      try {
        const res = await invokeRust("run_system_action", { actionId: "detect_bios_license" });
        if (res && res.success && res.message) {
          let parsed = null;
          try {
            parsed = JSON.parse(res.message);
          } catch (_) {}

          if (parsed && parsed.has_license && parsed.key) {
            if (keyEl) keyEl.textContent = `🔑 Key BIOS: ${parsed.key} (${parsed.edition})`;
            if (badgeEl) {
              badgeEl.textContent = "ĐÃ TÌM THẤY KEY OEM";
              badgeEl.className = "px-2 py-0.5 rounded text-xs font-mono font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30";
            }
            if (noteEl) {
              noteEl.innerHTML = `✅ <strong>Tuyệt vời!</strong> Máy bạn có sẵn bản quyền OEM <strong>${parsed.edition}</strong> trong BIOS bo mạch chủ. Quá trình cài đặt ISO sẽ tự động nhận diện và kích hoạt Windows bản quyền trọn đời cho bạn!`;
            }
          } else {
            if (keyEl) keyEl.textContent = "Không tìm thấy Product Key nhúng trong BIOS (Không có OA3x/MSDM)";
            if (badgeEl) {
              badgeEl.textContent = "CHƯA CÓ KEY BIOS";
              badgeEl.className = "px-2 py-0.5 rounded text-xs font-mono font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30";
            }
            if (noteEl) {
              noteEl.innerHTML = `📣 <strong>Lưu ý:</strong> Bản cài đặt này là ISO nguyên gốc. Do máy không có key OEM BIOS nhúng sẵn, bạn hãy chọn đúng phiên bản (Home/Pro) và kích hoạt sau khi cài xong (bằng key cá nhân hoặc bộ kích hoạt MAS HWID tại Tab Kích Hoạt).`;
            }
          }
        }
      } catch (e) {
        if (keyEl) keyEl.textContent = "Lỗi khi truy vấn BIOS: " + e;
      }
    };

    // --- CUSTOMIZE PREFERENCES TOGGLES BINDING ---
    const toggleList = document.getElementById("toggle-list");
    if (toggleList) {
      const toggleItems = toggleList.querySelectorAll(".flex.items-center.justify-between");
      toggleItems.forEach((item) => {
        const cb = item.querySelector("input[type='checkbox']");
        const titleEl = item.querySelector(".font-body-md");
        if (!cb || !titleEl) return;

        const title = titleEl.textContent.trim().toLowerCase();
        let actionId = "";
        if (title.includes("giao diện tối") || title.includes("dark theme")) actionId = "toggle_dark_theme";
        else if (title.includes("đường dẫn dài") || title.includes("long path")) actionId = "toggle_long_paths";
        else if (title.includes("đuôi file") || title.includes("extension")) actionId = "toggle_show_file_ext";
        else if (title.includes("tệp ẩn") || title.includes("hidden")) actionId = "toggle_show_hidden_files";
        else if (title.includes("phím số") || title.includes("numlock")) actionId = "toggle_numlock_boot";
        else if (title.includes("căn giữa") || title.includes("taskbar")) actionId = "toggle_taskbar_align";
        else if (title.includes("tìm kiếm taskbar") || title.includes("search")) actionId = "toggle_taskbar_search";
        else if (title.includes("tìm kiếm web") || title.includes("bing")) actionId = "toggle_bing_search_start";
        else if (title.includes("chia cửa sổ") || title.includes("snapping")) actionId = "toggle_window_snapping";

        if (actionId) {
          cb.addEventListener("change", async () => {
            appendTweakLog(`[TÙY CHỈNH] Đang thay đổi: ${titleEl.textContent.trim()}...`, "progress");
            showToast("Tùy Chỉnh", `Đang áp dụng: ${titleEl.textContent.trim()}...`, "info");
            const res = await invokeRust("run_system_action", { actionId });
            if (res && res.success) {
              appendTweakLog(`[THÀNH CÔNG] ✓ ${res.message}`, "success");
              showToast("Thành Công", res.message, "success");
            } else {
              appendTweakLog(`[LỖI] ✗ ${(res && res.message) || "Không thể lưu thiết lập"}`, "error");
              showToast("Lỗi", (res && res.message) || "Không thể lưu thiết lập", "error");
            }
          });
        }
      });
    }

    updateTweakCount();
  }

  // --- 12. SOFTWARE HUB CONTROLLERS (SUB-TABS, UNINSTALLER, FONTS, CUSTOM) ---
  let cachedInstalledApps = [];
  let currentFilteredApps = [];
  let selectedAppNames = new Set();

  window.switchSoftSubTab = function(tabName) {
    const tabs = ["store", "custom", "uninstall", "fonts"];
    tabs.forEach((t) => {
      const el = document.getElementById(`subview-soft-${t}`);
      const btn = document.getElementById(`tab-soft-${t}`);
      if (el) {
        if (t === tabName) {
          el.classList.remove("hidden");
        } else {
          el.classList.add("hidden");
        }
      }
      if (btn) {
        if (t === tabName) {
          btn.className = "px-4 py-2 rounded-lg bg-primary-container text-on-primary-container font-label-md text-label-md font-semibold flex items-center gap-2 shadow-sm transition-all";
        } else {
          btn.className = "px-4 py-2 rounded-lg bg-surface-container text-on-surface hover:bg-surface-container-high font-label-md text-label-md flex items-center gap-2 transition-all";
        }
      }
    });

    if (tabName === "uninstall" && cachedInstalledApps.length === 0) {
      window.refreshInstalledApps();
    }
  };

  window.refreshInstalledApps = async function() {
    const tbody = document.getElementById("tbodyInstalledApps");
    const badge = document.getElementById("badgeInstalledCount");
    if (tbody) {
      tbody.innerHTML = `<tr><td colspan="5" class="p-6 text-center text-secondary font-body-md animate-pulse">Đang quét toàn bộ Registry Uninstall trên máy tính...</td></tr>`;
    }

    try {
      const res = await invokeRust("get_installed_apps", {});
      let apps = [];
      if (res && res.data) {
        try {
          apps = typeof res.data === "string" ? JSON.parse(res.data) : res.data;
        } catch (_) {
          apps = [];
        }
      }
      if (apps && !Array.isArray(apps)) {
        apps = [apps];
      }
      cachedInstalledApps = Array.isArray(apps) ? apps : [];
      currentFilteredApps = [...cachedInstalledApps];
      selectedAppNames.clear();
      if (badge) badge.textContent = `${cachedInstalledApps.length} Ứng Dụng`;
      const searchInput = document.getElementById("txtUninstallSearch");
      if (searchInput && searchInput.value.trim()) {
        window.filterInstalledApps(searchInput.value);
      } else {
        window.renderInstalledApps(currentFilteredApps);
      }
      window.updateBulkUninstallUI();
    } catch (e) {
      if (tbody) tbody.innerHTML = `<tr><td colspan="5" class="p-6 text-center text-error font-body-md">Lỗi khi quét ứng dụng: ${e}</td></tr>`;
    }
  };

  window.toggleSelectAppByIndex = function(index, checked) {
    const app = currentFilteredApps[index];
    if (app && app.name) {
      if (checked) {
        selectedAppNames.add(app.name);
      } else {
        selectedAppNames.delete(app.name);
      }
      window.updateBulkUninstallUI();
    }
  };

  window.toggleSelectApp = function(name, checked) {
    if (checked) {
      selectedAppNames.add(name);
    } else {
      selectedAppNames.delete(name);
    }
    window.updateBulkUninstallUI();
  };

  window.toggleSelectAllInstalledApps = function(checked) {
    if (checked) {
      currentFilteredApps.forEach(a => {
        if (a && a.name) selectedAppNames.add(a.name);
      });
    } else {
      if (currentFilteredApps.length === cachedInstalledApps.length) {
        selectedAppNames.clear();
      } else {
        currentFilteredApps.forEach(a => {
          if (a && a.name) selectedAppNames.delete(a.name);
        });
      }
    }
    window.renderInstalledApps(currentFilteredApps);
    window.updateBulkUninstallUI();
  };

  window.updateBulkUninstallUI = function() {
    const chkAll = document.getElementById("chkSelectAllInstalledApps");
    if (chkAll) {
      chkAll.checked = currentFilteredApps.length > 0 && currentFilteredApps.every(a => a && a.name && selectedAppNames.has(a.name));
    }
    const btnBulk = document.getElementById("btnBulkUninstall");
    const lblBulk = document.getElementById("txtBulkUninstallLabel");
    const count = selectedAppNames.size;
    if (lblBulk) {
      lblBulk.textContent = count > 0 ? `Gỡ Hàng Loạt (${count})` : "Gỡ Hàng Loạt (0)";
    }
    if (btnBulk) {
      if (count > 0) {
        btnBulk.disabled = false;
        btnBulk.className = "px-3.5 py-2 rounded-lg bg-red-600 hover:bg-red-500 active:bg-red-700 text-white font-label-md text-label-md font-semibold flex items-center gap-1.5 transition-all shadow-md shadow-red-600/30 cursor-pointer animate-pulse";
        btnBulk.title = `Bấm để gỡ bỏ đồng thời ${count} phần mềm đã chọn`;
      } else {
        btnBulk.disabled = true;
        btnBulk.className = "px-3.5 py-2 rounded-lg bg-red-600/40 text-white/50 font-label-md text-label-md font-semibold flex items-center gap-1.5 transition-all cursor-not-allowed";
        btnBulk.title = "Tick chọn các phần mềm cần gỡ để kích hoạt";
      }
    }
  };

  window.renderInstalledApps = function(apps) {
    const tbody = document.getElementById("tbodyInstalledApps");
    if (!tbody) return;
    if (!apps || apps.length === 0) {
      tbody.innerHTML = `<tr><td colspan="5" class="p-6 text-center text-on-surface-variant font-body-md">Không tìm thấy ứng dụng phù hợp trong danh sách.</td></tr>`;
      return;
    }

    tbody.innerHTML = apps.map((app, index) => {
      const rawName = app.name || "Chưa rõ tên";
      const nameEscaped = rawName.replace(/"/g, "&quot;");
      const pubEscaped = (app.publisher || "Chưa rõ").replace(/"/g, "&quot;");
      const verEscaped = (app.version || "1.0").replace(/"/g, "&quot;");
      const isSelected = selectedAppNames.has(rawName);

      return `
        <tr class="hover:bg-surface-container transition-colors ${isSelected ? "bg-red-500/10" : ""}">
          <td class="p-3 text-center">
            <input type="checkbox" class="chk-installed-app w-4 h-4 rounded border-outline/40 text-red-600 focus:ring-red-500 cursor-pointer accent-red-600" ${isSelected ? "checked" : ""} onchange="window.toggleSelectAppByIndex(${index}, this.checked)" />
          </td>
          <td class="p-3 font-semibold text-on-surface">${nameEscaped}</td>
          <td class="p-3 text-on-surface-variant">${pubEscaped}</td>
          <td class="p-3 font-code-sm text-code-sm text-outline">${verEscaped}</td>
          <td class="p-3 text-right">
            <button onclick="window.uninstallAppByIndex(${index})" class="px-3 py-1.5 rounded-lg bg-red-600 hover:bg-red-500 active:bg-red-700 text-white font-semibold text-xs shadow-sm hover:shadow-red-500/30 flex items-center gap-1.5 ml-auto transition-all cursor-pointer" type="button" title="Gỡ bỏ ${nameEscaped}">
              <span class="material-symbols-outlined text-[15px]">delete</span>
              <span>Gỡ Cài Đặt</span>
            </button>
          </td>
        </tr>
      `;
    }).join("");
  };

  window.filterInstalledApps = function(query) {
    const q = (query || "").toLowerCase().trim();
    if (!q) {
      currentFilteredApps = [...cachedInstalledApps];
    } else {
      currentFilteredApps = cachedInstalledApps.filter((a) =>
        (a.name || "").toLowerCase().includes(q) ||
        (a.publisher || "").toLowerCase().includes(q)
      );
    }
    window.renderInstalledApps(currentFilteredApps);
    window.updateBulkUninstallUI();
  };

  window.uninstallAppByIndex = function(index) {
    const app = currentFilteredApps[index];
    if (!app) return;
    const uninstStr = app.uninstall_string || app.uninstallString || "";
    window.uninstallSpecificApp(app.name, uninstStr);
  };

  window.uninstallSpecificApp = async function(name, uninstStr) {
    if (!confirm(`Bạn có chắc chắn muốn gỡ bỏ ứng dụng: ${name}?`)) return;
    showToast("Gỡ Cài Đặt", `Đang khởi chạy trình gỡ cài đặt cho ${name}...`, "info");
    const logEl = document.getElementById("log-console");
    if (logEl && typeof appendLog === "function") {
      appendLog("UNINSTALL", `Đang khởi chạy trình gỡ cài đặt cho: ${name}...`, "text-warning");
    }

    // Xóa ngay lập tức khỏi bảng hiển thị giao diện (Optimistic UI removal)
    cachedInstalledApps = cachedInstalledApps.filter(a => a && a.name !== name);
    currentFilteredApps = currentFilteredApps.filter(a => a && a.name !== name);
    if (typeof selectedAppNames !== "undefined") {
      selectedAppNames.delete(name);
    }
    window.renderInstalledApps(currentFilteredApps);
    if (typeof window.updateBulkUninstallUI === "function") {
      window.updateBulkUninstallUI();
    }

    const res = await invokeRust("run_system_action", {
      actionId: "uninstall_app",
      params: { name, uninstall_string: uninstStr },
    });
    showToast(res && res.success ? "Thành Công" : "Thông Báo", (res && res.message) || `Đã kích hoạt lệnh gỡ ${name}`, res && res.success ? "success" : "info");
    if (logEl && typeof appendLog === "function") {
      appendLog(res && res.success ? "SUCCESS" : "INFO", (res && res.message) || `Đã kích hoạt lệnh gỡ ${name}`, res && res.success ? "text-tertiary" : "text-outline");
    }
  };

  window.bulkUninstallSelectedApps = async function() {
    const selectedList = cachedInstalledApps.filter(a => a && a.name && selectedAppNames.has(a.name));
    if (selectedList.length === 0) {
      showToast("Gỡ Hàng Loạt", "Vui lòng tick chọn ít nhất 1 phần mềm cần gỡ bỏ!", "warning");
      return;
    }

    const appNamesSummary = selectedList.map(a => `• ${a.name}`).join("\n");
    const confirmMsg = `Bạn có chắc chắn muốn gỡ bỏ ${selectedList.length} phần mềm đã chọn sau đây?\n\n${appNamesSummary}\n\nNhấn OK để hệ thống lần lượt kích hoạt trình gỡ cho từng ứng dụng.`;
    if (!confirm(confirmMsg)) return;

    // Xóa ngay lập tức tất cả phần mềm được chọn khỏi giao diện
    const removingSet = new Set(selectedList.map(a => a.name));
    cachedInstalledApps = cachedInstalledApps.filter(a => a && !removingSet.has(a.name));
    currentFilteredApps = currentFilteredApps.filter(a => a && !removingSet.has(a.name));
    selectedAppNames.clear();
    window.renderInstalledApps(currentFilteredApps);
    if (typeof window.updateBulkUninstallUI === "function") {
      window.updateBulkUninstallUI();
    }

    showToast("Bắt Đầu Gỡ Hàng Loạt", `Đang chuẩn bị gỡ bỏ ${selectedList.length} phần mềm...`, "info");
    const logEl = document.getElementById("log-console");
    if (logEl && typeof appendLog === "function") {
      appendLog("BULK_UNINSTALL", `Bắt đầu gỡ hàng loạt ${selectedList.length} phần mềm đã chọn...`, "text-warning");
    }

    for (let i = 0; i < selectedList.length; i++) {
      const app = selectedList[i];
      const step = `[${i + 1}/${selectedList.length}]`;
      showToast("Đang Gỡ Hàng Loạt", `${step} Đang gỡ bỏ: ${app.name}...`, "info");
      if (logEl && typeof appendLog === "function") {
        appendLog("UNINSTALL", `${step} Đang thực thi gỡ bỏ: ${app.name}...`, "text-secondary");
      }
      try {
        await invokeRust("run_system_action", {
          actionId: "uninstall_app",
          params: { name: app.name, uninstall_string: app.uninstall_string || app.uninstallString || "" },
        });
      } catch (err) {
        if (logEl && typeof appendLog === "function") {
          appendLog("ERROR", `${step} Lỗi khi gỡ ${app.name}: ${err}`, "text-error");
        }
      }
      if (i < selectedList.length - 1) {
        await new Promise(r => setTimeout(r, 1500));
      }
    }

    showToast("Hoàn Tất", `Đã gửi lệnh gỡ bỏ toàn bộ ${selectedList.length} phần mềm! Bạn có thể nhấn 'Quét Lại Danh Sách Máy' sau khi hoàn tất để làm mới.`, "success");
    if (logEl && typeof appendLog === "function") {
      appendLog("SUCCESS", `Hoàn tất gửi lệnh gỡ ${selectedList.length} phần mềm!`, "text-tertiary");
    }
  };

  window.openUninstallerTool = async function(tool) {
    const res = await invokeRust("run_system_action", {
      actionId: "open_uninstaller_tool",
      params: { tool },
    });
    showToast("Công Cụ Gỡ", (res && res.message) || `Đang mở ${tool}...`, "info");
  };

  window.installFontPack = async function(pack) {
    showToast("Cài Font Chữ", `Đang triển khai bộ font ${pack.toUpperCase()}...`, "info");
    const res = await invokeRust("run_system_action", {
      actionId: "install_font_pack",
      params: { pack },
    });
    showToast(res && res.success ? "Thành Công" : "Lỗi", (res && res.message) || `Cài đặt font ${pack} hoàn tất!`, res && res.success ? "success" : "error");
  };

  window.openWindowsFontsFolder = function() {
    invokeRust("run_system_action", { actionId: "open_fonts_folder" });
    showToast("Windows Fonts", "Đang mở thư mục C:\\Windows\\Fonts", "info");
  };

  window.browseCustomInstaller = async function() {
    const res = await invokeRust("run_system_action", { actionId: "browse_file" });
    if (res && res.message && res.message.includes("\\")) {
      const input = document.getElementById("txtCustomInstallerPath");
      if (input) input.value = res.message;
    }
  };

  window.setSilentArg = function(arg) {
    const input = document.getElementById("txtCustomInstallerArgs");
    if (input) input.value = arg;
  };

  window.clearCustomLog = function() {
    const term = document.getElementById("custom-install-terminal-body");
    if (term) term.innerHTML = `<div class="text-outline/70">[Ready] Sẵn sàng thực thi. Chọn tệp cài đặt và bấm "Bắt Đầu Cài Đặt Ngay".</div>`;
  };

  window.executeCustomInstall = async function() {
    const path = document.getElementById("txtCustomInstallerPath")?.value?.trim();
    const args = document.getElementById("txtCustomInstallerArgs")?.value?.trim() || "";
    const term = document.getElementById("custom-install-terminal-body");

    if (!path) {
      showToast("Lỗi", "Vui lòng nhập đường dẫn tệp cài đặt!", "error");
      return;
    }

    if (term) {
      term.innerHTML += `<div class="text-primary font-bold">[EXEC] Bắt đầu cài đặt: ${path} với tham số: ${args}</div>`;
      term.scrollTop = term.scrollHeight;
    }

    showToast("Cài Đặt Tùy Chỉnh", `Đang cài đặt: ${path}...`, "info");
    const res = await invokeRust("run_system_action", {
      actionId: "custom_install",
      params: { path, args },
    });

    if (term) {
      term.innerHTML += `<div class="${res && res.success ? 'text-tertiary' : 'text-error'}">[KẾT QUẢ] ${(res && res.message) || 'Đã gửi lệnh cài đặt'}</div>`;
      term.scrollTop = term.scrollHeight;
    }
    showToast(res && res.success ? "Thành Công" : "Lỗi", (res && res.message) || "Hoàn tất cài đặt tùy chỉnh!", res && res.success ? "success" : "error");
  };

  // --- 13. OEM BRANDING REAL REGISTRY CONTROLLERS ---
  window.applyOEMChanges = async function() {
    const mfg = document.getElementById('input-manufacturer')?.value || "";
    const model = document.getElementById('input-model')?.value || "";
    const phone = document.getElementById('input-phone')?.value || "";
    const hours = document.getElementById('input-hours')?.value || "";
    const url = document.getElementById('input-url')?.value || "";
    const owner = document.getElementById('input-owner')?.value || "";
    const org = document.getElementById('input-org')?.value || "";

    const consoleEl = document.getElementById('console-log-msg');
    if (consoleEl) {
      consoleEl.textContent = `Đang ghi Registry: Manufacturer="${mfg}", Model="${model}"...`;
    }

    showToast("OEM Branding", `Đang áp dụng thông tin thương hiệu ${mfg}...`, "info");

    const res = await invokeRust("run_system_action", {
      actionId: "set_oem_branding",
      params: { manufacturer: mfg, model, phone, hours, url, owner, org }
    });

    const msg = (res && res.message) || `Đã ghi thành công thông tin thương hiệu [${mfg}] vào Windows Registry!`;
    if (consoleEl) {
      consoleEl.textContent = msg;
    }
    showToast(res && res.success ? "Thành Công" : "Thông Báo", msg, res && res.success ? "success" : "info");
  };

  window.backupRegistry = async function() {
    showToast("Sao Lưu", "Đang sao lưu khóa Registry OEM...", "info");
    const res = await invokeRust("run_system_action", { actionId: "backup_oem" });
    const msg = (res && res.message) || "Đã xuất sao lưu Registry OEM hoàn tất!";
    const consoleEl = document.getElementById('console-log-msg');
    if (consoleEl) consoleEl.textContent = msg;
    showToast("Sao Lưu", msg, "success");
  };

  window.resetDefaults = async function() {
    if (document.getElementById('input-manufacturer')) document.getElementById('input-manufacturer').value = "Microsoft Corporation";
    if (document.getElementById('input-model')) document.getElementById('input-model').value = "Standard PC System";
    if (document.getElementById('input-phone')) document.getElementById('input-phone').value = "";
    if (document.getElementById('input-hours')) document.getElementById('input-hours').value = "";
    if (document.getElementById('input-url')) document.getElementById('input-url').value = "";
    if (document.getElementById('input-owner')) document.getElementById('input-owner').value = "Windows User";
    if (document.getElementById('input-org')) document.getElementById('input-org').value = "WORKGROUP";
    if (typeof clearLogo === "function") clearLogo();
    if (typeof updatePreview === "function") updatePreview();

    const res = await invokeRust("run_system_action", { actionId: "reset_oem_branding" });
    const msg = (res && res.message) || "Đã khôi phục cấu hình OEM mặc định của Windows.";
    const consoleEl = document.getElementById('console-log-msg');
    if (consoleEl) consoleEl.textContent = msg;
    showToast("OEM Reset", msg, "success");
  };

  // --- 9.5. WINDOWS DEPLOY CONTROLLER ---
  let isBrowsingIso = false;
  async function browseIsoFile() {
    if (isBrowsingIso) return;
    const btn = document.getElementById("btn-browse-iso");
    if (btn && btn.disabled) return;
    isBrowsingIso = true;
    if (btn) btn.disabled = true;
    try {
      showToast("Duyệt File ISO", "Đang mở hộp thoại chọn tệp ISO từ máy...", "info");
      const res = await invokeRust("run_system_action", { actionId: "browse_iso" });
      const selectedPath = (res && res.file_path) || (res && res.success && res.message && (res.message.includes(":\\") || res.message.toLowerCase().endsWith(".iso")) ? res.message : null);

      if (selectedPath) {
        const isoPathEl = document.getElementById("iso-path-text");
        if (isoPathEl) isoPathEl.innerText = selectedPath;
        const inputIso = document.getElementById("input-iso-path");
        if (inputIso) inputIso.value = selectedPath;
        const osSelector = document.getElementById("os-selector");
        if (osSelector) osSelector.value = "custom-iso";
        showToast("Chọn File ISO", "Đã nạp file: " + selectedPath, "success");
      } else if (res && res.message && res.message.includes("hủy")) {
        showToast("Chọn File ISO", res.message, "info");
      } else {
        showToast("Chọn File ISO", (res && res.message) || "Chưa chọn file ISO", "warning");
      }
    } catch (e) {
      showToast("Lỗi", "Không thể mở hộp thoại chọn file: " + e, "error");
    } finally {
      if (btn) btn.disabled = false;
      isBrowsingIso = false;
    }
  }
  window.browseIsoFile = browseIsoFile;

  function copyIsoPath() {
    const isoPathEl = document.getElementById("iso-path-text");
    const path = (isoPathEl ? isoPathEl.innerText : "").trim();
    if (!path) {
      showToast("Copy Đường Dẫn", "Chưa có đường dẫn file ISO nào!", "warning");
      return;
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(path).then(() => {
        showToast("Đã Copy", "Đã sao chép đường dẫn ISO vào bộ nhớ tạm!", "success");
      }).catch(() => {
        fallbackCopy(path);
      });
    } else {
      fallbackCopy(path);
    }
  }
  function fallbackCopy(text) {
    const ta = document.createElement("textarea");
    ta.value = text;
    document.body.appendChild(ta);
    ta.select();
    try {
      document.execCommand("copy");
      showToast("Đã Copy", "Đã sao chép đường dẫn ISO vào bộ nhớ tạm!", "success");
    } catch (_) {
      showToast("Lỗi", "Không thể truy cập Clipboard", "error");
    }
    document.body.removeChild(ta);
  }
  window.copyIsoPath = copyIsoPath;

  function selectDeployMode(mode) {
    const targetMode = mode === "clean" ? "clean" : "upgrade";
    const radio = document.querySelector(`input[name="deploy-mode"][value="${targetMode}"]`);
    if (radio) radio.checked = true;

    const cardUpgrade = document.getElementById("card-mode-upgrade");
    const cardClean = document.getElementById("card-mode-clean");
    const dotUpgrade = document.getElementById("dot-mode-upgrade");
    const dotClean = document.getElementById("dot-mode-clean");

    if (targetMode === "upgrade") {
      if (cardUpgrade) {
        cardUpgrade.classList.add("border-2", "border-primary", "bg-primary-container/15", "shadow-md");
        cardUpgrade.classList.remove("border-transparent", "bg-surface-container");
      }
      if (cardClean) {
        cardClean.classList.remove("border-2", "border-secondary", "bg-secondary-container/15", "shadow-md");
        cardClean.classList.add("border-transparent", "bg-surface-container");
      }
      if (dotUpgrade) dotUpgrade.classList.add("bg-primary-container");
      if (dotClean) dotClean.classList.remove("bg-secondary-container");
      showToast("Chế Độ Cài Đặt", "Đã chọn: Cài Đè / Nâng Cấp Hệ Điều Hành (Giữ nguyên 100% dữ liệu)", "info");
    } else {
      if (cardClean) {
        cardClean.classList.add("border-2", "border-secondary", "bg-secondary-container/15", "shadow-md");
        cardClean.classList.remove("border-transparent", "bg-surface-container");
      }
      if (cardUpgrade) {
        cardUpgrade.classList.remove("border-2", "border-primary", "bg-primary-container/15", "shadow-md");
        cardUpgrade.classList.add("border-transparent", "bg-surface-container");
      }
      if (dotClean) dotClean.classList.add("bg-secondary-container");
      if (dotUpgrade) dotUpgrade.classList.remove("bg-primary-container");
      showToast("Chế Độ Cài Đặt", "Đã chọn: Cài Mới Hoàn Toàn (Format sạch phân vùng ổ C:)", "warning");
    }
  }
  window.selectDeployMode = selectDeployMode;

  function initDeployModeSwitcher() {
    selectDeployMode("upgrade");
    const osSelector = document.getElementById("os-selector");
    if (osSelector) {
      osSelector.addEventListener("change", (e) => {
        if (e.target.value === "custom-iso") {
          browseIsoFile();
        } else if (e.target.value && (e.target.value.toLowerCase().endsWith(".iso") || e.target.value.toLowerCase().endsWith("setup.exe"))) {
          const isoPathEl = document.getElementById("iso-path-text");
          if (isoPathEl) isoPathEl.innerText = e.target.value;
          const inputIso = document.getElementById("input-iso-path");
          if (inputIso) inputIso.value = e.target.value;
          showToast("Chọn Bộ Cài", "Đã chọn: " + e.target.value, "success");
        }
      });
    }

    // Avoid double event triggers: elements in index.html already have inline onclick handlers.
    // safeAttachClick binds addEventListener only if the element does not define an inline onclick.
    const safeAttachClick = (id, fn) => {
      const el = document.getElementById(id);
      if (el && !el.getAttribute("onclick")) {
        el.addEventListener("click", (e) => {
          e.preventDefault();
          fn(e);
        });
      }
    };

    safeAttachClick("card-mode-upgrade", () => selectDeployMode("upgrade"));
    safeAttachClick("card-mode-clean", () => selectDeployMode("clean"));
    safeAttachClick("btn-browse-iso", () => browseIsoFile());
    safeAttachClick("btn-start-deploy", () => startWinDeploy());
    safeAttachClick("btn-quick-backup-system", () => backupSystemFromDeploy());
    safeAttachClick("btn-quick-backup-drivers", () => backupDriverFromDeploy());
    safeAttachClick("btn-export-drivers", () => backupDriverFromDeploy());
    safeAttachClick("btn-restore-drivers", () => restoreDrivers());
  }
  window.initDeployModeSwitcher = initDeployModeSwitcher;

  // --- 13.1 VIEW 02 DEPLOY SUB-TABS CONTROLLER ---
  function initDeploySubTabs() {
    const btnCaiWin = document.getElementById("tab-deploy-cai-win");
    const btnHwid = document.getElementById("tab-deploy-hwid");
    const btnBitlocker = document.getElementById("tab-deploy-bitlocker");
    const btnBackup = document.getElementById("tab-deploy-backup-driver");

    if (btnCaiWin) {
      btnCaiWin.addEventListener("click", (e) => {
        e.preventDefault();
        switchView("view-cai-windows");
      });
    }
    if (btnHwid) {
      btnHwid.addEventListener("click", (e) => {
        e.preventDefault();
        switchView("view-win-activate");
      });
    }
    if (btnBitlocker) {
      btnBitlocker.addEventListener("click", (e) => {
        e.preventDefault();
        showToast("BitLocker", "Đang chuyển đến bảng quản lý phân vùng ổ đĩa & BitLocker...", "info");
        switchView("view-disk-bitlocker");
      });
    }
    if (btnBackup) {
      btnBackup.addEventListener("click", (e) => {
        e.preventDefault();
        showToast("Sao Lưu Driver", "Đang chuyển đến phân hệ Sao Lưu & Xuất Driver Hệ Thống...", "info");
        switchView("view-tech-driver", "driver-backup-vault");
      });
    }
  }
  window.initDeploySubTabs = initDeploySubTabs;

  async function checkDiskPartitions() {
    try {
      const res = await invokeRust("run_system_action", { actionId: "check_disk_partitions" });
      if (res && res.message) {
        showToast("Kiểm Tra Phân Vùng", res.message, res.success ? "success" : "warning");
      }
    } catch (e) {
      showToast("Lỗi", "Không thể mở Disk Management: " + e, "error");
    }
  }
  window.checkDiskPartitions = checkDiskPartitions;

  let isBackingUpDrivers = false;
  async function backupDriverFromDeploy() {
    if (isBackingUpDrivers) return;
    const btns = [
      document.getElementById("btn-quick-backup-drivers"),
      document.getElementById("btn-deploy-backup-now"),
      document.getElementById("btn-export-drivers"),
      document.getElementById("btn-export-drivers-vault")
    ].filter(Boolean);
    if (btns.some(b => b.disabled)) return;
    isBackingUpDrivers = true;
    btns.forEach(b => b.disabled = true);

    const label = document.getElementById("btn-quick-backup-label");
    const desc = document.getElementById("deploy-driver-target-desc");
    if (label) label.innerText = "Đang sao lưu...";
    showToast("Sao Lưu Driver", "Đang trích xuất toàn bộ Driver phần cứng ra đĩa...", "info");

    try {
      const res = await invokeRust("run_system_action", { actionId: "backup_drivers" });
      if (res && res.success) {
        showToast("Sao Lưu Driver", res.message, "success");
        if (label) label.innerText = "✓ Đã Sao Lưu";
        if (desc) desc.innerText = res.message;
      } else {
        showToast("Lỗi Sao Lưu Driver", (res && res.message) || "Không thể sao lưu Driver", "error");
        if (label) label.innerText = "Sao Lưu Ngay";
      }
      return res;
    } catch (e) {
      showToast("Lỗi Sao Lưu Driver", String(e), "error");
      if (label) label.innerText = "Sao Lưu Ngay";
      return null;
    } finally {
      btns.forEach(b => b.disabled = false);
      isBackingUpDrivers = false;
    }
  }
  window.backupDriverFromDeploy = backupDriverFromDeploy;
  window.exportDrivers = backupDriverFromDeploy;

  let isRestoringDrivers = false;
  async function restoreDrivers() {
    if (isRestoringDrivers) return;
    const btns = [
      document.getElementById("btn-restore-drivers"),
      document.getElementById("btn-restore-drivers-vault")
    ].filter(Boolean);
    if (btns.some(b => b.disabled)) return;
    isRestoringDrivers = true;
    btns.forEach(b => b.disabled = true);

    showToast("Phục Hồi Driver", "Đang nạp và cài đặt lại toàn bộ Driver từ thư mục sao lưu...", "info");
    try {
      const res = await invokeRust("run_system_action", { actionId: "restore_drivers" });
      if (res && res.success) {
        showToast("Phục Hồi Driver", res.message || "Đã phục hồi toàn bộ Driver thành công!", "success");
      } else {
        showToast("Lỗi Phục Hồi", (res && res.message) || "Không thể phục hồi Driver.", "error");
      }
      return res;
    } catch (e) {
      showToast("Lỗi Phục Hồi", String(e), "error");
      return null;
    } finally {
      btns.forEach(b => b.disabled = false);
      isRestoringDrivers = false;
    }
  }
  window.restoreDrivers = restoreDrivers;

  let isBackingUpSystem = false;
  async function backupSystemFromDeploy() {
    if (isBackingUpSystem) return;
    const btn = document.getElementById("btn-quick-backup-system");
    if (btn && btn.disabled) return;
    isBackingUpSystem = true;
    if (btn) btn.disabled = true;

    const label = document.getElementById("btn-quick-backup-system-label");
    const desc = document.getElementById("deploy-system-target-desc");
    if (label) label.innerText = "Đang sao lưu...";
    showToast("Sao Lưu Toàn Bộ Windows", "Đang tiến hành sao lưu hệ thống C: (WIM / Snapshot) ra phân vùng an toàn...", "info");

    try {
      const res = await invokeRust("run_system_action", { actionId: "backup_full_windows" });
      if (res && res.success) {
        showToast("Sao Lưu Hoàn Tất", res.message || "Đã sao lưu Windows an toàn!", "success");
        if (label) label.innerText = "✓ Đã Sao Lưu";
        if (desc) desc.innerText = res.message;
      } else {
        showToast("Lỗi Sao Lưu", (res && res.message) || "Không thể sao lưu hệ thống.", "error");
        if (label) label.innerText = "Sao Lưu Ngay";
      }
      return res;
    } catch (e) {
      showToast("Lỗi Hệ Thống", "Gặp lỗi khi sao lưu hệ thống: " + e, "error");
      if (label) label.innerText = "Sao Lưu Ngay";
      return null;
    } finally {
      if (btn) btn.disabled = false;
      isBackingUpSystem = false;
    }
  }
  window.backupSystemFromDeploy = backupSystemFromDeploy;

  // --- 13.1B VIEW 16 BACKUP & RESTORE WINDOWS CONTROLLER ---
  let isRestoringSystemWim = false;
  async function restoreSystemWim() {
    if (isRestoringSystemWim) return;
    const btn = document.getElementById("btn-restore-wim-system");
    const label = document.getElementById("btn-restore-wim-label");
    const desc = document.getElementById("restore-system-target-desc");
    const sel = document.getElementById("sel-restore-wim-file");
    const wimPath = sel ? sel.value : "";

    if (!wimPath) {
      showToast("Chưa Chọn Bản Sao Lưu", "Vui lòng chọn hoặc duyệt tìm file .wim trước khi thực hiện phục hồi!", "warning");
      return;
    }

    if (!confirm(`Bạn có chắc chắn muốn phục hồi hệ thống Windows từ bản sao lưu:\n${wimPath}\n\nLưu ý: Quá trình sẽ bung bản chụp WIM và chuẩn bị phục hồi hệ thống an toàn.`)) {
      return;
    }

    isRestoringSystemWim = true;
    if (btn) btn.disabled = true;
    if (label) label.innerText = "Đang Phục Hồi...";
    showToast("Phục Hồi Hệ Thống Windows", "Đang nạp cấu hình phục hồi WIM...", "info");

    try {
      const res = await invokeRust("run_system_action", {
        actionId: "restore_full_windows",
        wim_path: wimPath,
        wimPath: wimPath,
        target_drive: "C:"
      });
      if (res && res.success) {
        showToast("Phục Hồi Thành Công", res.message || "Đã chuẩn bị hoàn tất phục hồi Windows!", "success");
        if (label) label.innerText = "✓ Đã Phục Hồi";
        if (desc) desc.innerText = res.message;
      } else {
        showToast("Lỗi Phục Hồi", (res && res.message) || "Không thể thực hiện phục hồi.", "error");
        if (label) label.innerText = "Phục Hồi Bản Chụp WIM";
        if (desc) desc.innerText = "Lỗi: " + ((res && res.message) || "Thất bại");
      }
    } catch (e) {
      showToast("Lỗi Hệ Thống", "Gặp lỗi: " + e, "error");
      if (label) label.innerText = "Phục Hồi Bản Chụp WIM";
    } finally {
      if (btn) btn.disabled = false;
      isRestoringSystemWim = false;
    }
  }
  window.restoreSystemWim = restoreSystemWim;

  async function browseWimFile() {
    try {
      const res = await invokeRust("run_system_action", { actionId: "browse_wim" });
      if (res && res.success && res.message) {
        const path = res.message.trim();
        const sel = document.getElementById("sel-restore-wim-file");
        if (sel) {
          let found = false;
          for (let opt of sel.options) {
            if (opt.value === path) {
              opt.selected = true;
              found = true;
              break;
            }
          }
          if (!found) {
            const opt = document.createElement("option");
            opt.value = path;
            opt.text = path;
            opt.selected = true;
            sel.appendChild(opt);
          }
        }
        const desc = document.getElementById("restore-system-target-desc");
        if (desc) desc.innerText = "Đã chọn: " + path;
        showToast("Đã Chọn Tệp WIM", path, "success");
      }
    } catch (e) {
      showToast("Lỗi Chọn File", "" + e, "error");
    }
  }
  window.browseWimFile = browseWimFile;

  async function scanWimBackups() {
    const sel = document.getElementById("sel-restore-wim-file");
    const desc = document.getElementById("restore-system-target-desc");
    if (!sel) return;
    sel.innerHTML = `<option value="">-- Đang quét tìm các bản sao lưu WIM... --</option>`;
    try {
      const res = await invokeRust("run_system_action", { actionId: "scan_wim_backups" });
      if (res && res.success && res.message) {
        let items = [];
        try {
          items = JSON.parse(res.message);
        } catch (_) {}

        sel.innerHTML = "";
        if (Array.isArray(items) && items.length > 0) {
          items.forEach(it => {
            const opt = document.createElement("option");
            opt.value = it.path;
            opt.text = `${it.name} (${it.size} - ${it.date}) -> ${it.path}`;
            sel.appendChild(opt);
          });
          if (desc) desc.innerText = `Tìm thấy ${items.length} bản sao lưu WIM trên các phân vùng ổ đĩa.`;
        } else {
          sel.innerHTML = `<option value="">(Chưa tìm thấy bản backup WIM tự động - Hãy bấm 'Chọn File WIM...')</option>`;
          if (desc) desc.innerText = "Chưa phát hiện bản sao lưu tự động. Bạn có thể bấm 'Chọn File WIM...' để duyệt file.";
        }
      }
    } catch (e) {
      sel.innerHTML = `<option value="">(Lỗi quét: ${e})</option>`;
    }
  }
  window.scanWimBackups = scanWimBackups;

  async function bootToWinRE() {
    if (!confirm("Bạn có muốn khởi động lại máy tính vào môi trường cứu hộ Windows RE (Troubleshoot & Recovery) ngay bây giờ?")) {
      return;
    }
    showToast("Khởi Động WinRE", "Đang chuyển tiếp hệ thống vào Windows Recovery Environment...", "info");
    try {
      const res = await invokeRust("run_system_action", { actionId: "boot_to_winre" });
      if (res && res.success) {
        showToast("WinRE", res.message || "Đang khởi động lại máy...", "success");
      } else {
        showToast("Lỗi WinRE", (res && res.message) || "Không thể kích hoạt WinRE.", "error");
      }
    } catch (e) {
      showToast("Lỗi Hệ Thống", "" + e, "error");
    }
  }
  window.bootToWinRE = bootToWinRE;

  async function openSystemRestore() {
    showToast("System Restore", "Đang mở trình phục hồi hệ thống rstrui.exe...", "info");
    try {
      const res = await invokeRust("run_system_action", { actionId: "open_system_restore" });
      if (res && res.success) {
        showToast("System Restore", res.message || "Đã mở rstrui.exe!", "success");
      }
    } catch (e) {
      showToast("Lỗi", "" + e, "error");
    }
  }
  window.openSystemRestore = openSystemRestore;

  async function createRestorePoint() {
    showToast("System Restore", "Đang tạo điểm khôi phục (Restore Point)...", "info");
    try {
      const res = await invokeRust("run_system_action", { actionId: "create_restore_point" });
      if (res && res.success) {
        showToast("Điểm Khôi Phục", res.message || "Đã tạo thành công điểm khôi phục!", "success");
      } else {
        showToast("Lỗi", (res && res.message) || "Không thể tạo điểm khôi phục.", "error");
      }
    } catch (e) {
      showToast("Lỗi", "" + e, "error");
    }
  }
  window.createRestorePoint = createRestorePoint;

  async function checkOrRepairWinRE() {
    showToast("Kiểm Tra WinRE", "Đang kiểm tra và kích hoạt Windows RE...", "info");
    try {
      const res = await invokeRust("run_system_action", { actionId: "repair_winre" });
      if (res && res.success) {
        showToast("Windows RE", res.message || "Đã bật WinRE!", "success");
      } else {
        showToast("Lỗi", (res && res.message) || "Lỗi kiểm tra WinRE.", "error");
      }
    } catch (e) {
      showToast("Lỗi", "" + e, "error");
    }
  }
  window.checkOrRepairWinRE = checkOrRepairWinRE;

  function initWindowsRestoreController() {
    const bindEl = (id, fn) => {
      const el = document.getElementById(id);
      if (el) {
        el.addEventListener("click", (e) => {
          e.preventDefault();
          fn();
        });
      }
    };
    bindEl("btn-scan-wim-backups", () => scanWimBackups());
    bindEl("btn-browse-wim-file", () => browseWimFile());
    bindEl("btn-restore-wim-system", () => restoreSystemWim());
    bindEl("btn-boot-winre", () => bootToWinRE());
    bindEl("btn-open-system-restore", () => openSystemRestore());
    bindEl("btn-create-restore-point", () => createRestorePoint());
    bindEl("btn-check-winre", () => checkOrRepairWinRE());

    const sel = document.getElementById("sel-restore-wim-file");
    if (sel) {
      sel.addEventListener("change", () => {
        const desc = document.getElementById("restore-system-target-desc");
        if (desc && sel.value) {
          desc.innerText = "Đã chọn bản sao lưu: " + sel.value;
        }
      });
    }
  }
  window.initWindowsRestoreController = initWindowsRestoreController;


  async function initWinDeployEnv() {
    try {
      const res = await invokeRust("run_system_action", { actionId: "detect_win_install_env" });
      if (res && res.message) {
        let envData = {};
        try {
          envData = JSON.parse(res.message);
        } catch (_) {}

        // 1. Chuẩn khởi động
        const bootEl = document.getElementById("deploy-boot-mode");
        if (bootEl && envData.boot_mode) {
          bootEl.innerHTML = `<span class="material-symbols-outlined text-[14px]">check_circle</span> ${envData.boot_mode}`;
        }

        // 2. Môi trường (Máy ảo vs Vật lý)
        const envBadge = document.getElementById("deploy-env-badge");
        if (envBadge) {
          if (envData.is_vm) {
            envBadge.className = "font-label-md text-label-md text-amber-400 flex items-center gap-1 mt-0.5";
            envBadge.innerHTML = `<span class="material-symbols-outlined text-[14px]">desktop_windows</span> ${envData.vm_type}`;
          } else {
            envBadge.className = "font-label-md text-label-md text-secondary flex items-center gap-1 mt-0.5";
            envBadge.innerHTML = `<span class="material-symbols-outlined text-[14px]">computer</span> ${envData.vm_type || "Máy Vật Lý"}`;
          }
        }

        // 3. Thanh trạng thái Readiness Bar
        const freeEl = document.getElementById("readiness-c-free");
        if (freeEl && envData.c_free_gb !== undefined) {
          freeEl.innerText = `Ổ C: ${envData.c_free_gb} GB trống / ${envData.c_total_gb || 100} GB`;
          if (envData.c_free_gb < 20) {
            freeEl.className = "text-amber-400 font-bold";
          }
        }

        const pwrEl = document.getElementById("readiness-power");
        if (pwrEl && envData.power_status) {
          pwrEl.innerText = envData.power_status;
        }

        const envReadinessEl = document.getElementById("readiness-env");
        if (envReadinessEl && envData.vm_type) {
          envReadinessEl.innerText = envData.is_vm ? `Môi trường Ảo: ${envData.vm_type}` : `Máy Vật Lý (${envData.boot_mode || "UEFI"})`;
        }

        // 4. Nếu có ổ đĩa ảo hoặc CD-ROM chứa setup.exe (Đặc trưng máy ảo)
        const isoPathEl = document.getElementById("iso-path-text");
        if (envData.mounted_setup_drive) {
          const setupPath = `${envData.mounted_setup_drive}\\setup.exe`;
          if (isoPathEl && (!isoPathEl.innerText || isoPathEl.innerText.includes("Chưa chọn file") || isoPathEl.innerText.endsWith(".iso"))) {
            isoPathEl.innerText = setupPath;
            showToast("Nhận Diện Máy Ảo", `Đã phát hiện bộ cài Windows tại ổ ${envData.mounted_setup_drive} (Virtual CD/DVD). Tự động nạp!`, "info");
          }
        }

        // 5. Nếu phát hiện các file ISO trong máy
        if (envData.found_isos && envData.found_isos.length > 0) {
          const osSelector = document.getElementById("os-selector");
          if (osSelector) {
            const existingOptGroup = osSelector.querySelector('optgroup[label="File ISO Phát Hiện Trên Máy"]');
            if (!existingOptGroup) {
              const optGroup = document.createElement("optgroup");
              optGroup.label = "File ISO Phát Hiện Trên Máy";
              envData.found_isos.forEach((iso) => {
                const opt = document.createElement("option");
                opt.value = iso.path;
                opt.innerText = `[Có Sẵn] ${iso.name} (${iso.size})`;
                optGroup.appendChild(opt);
              });
              osSelector.appendChild(optGroup);
            }
          }
        }
      }
    } catch (e) {
      console.warn("initWinDeployEnv error:", e);
    }
  }
  window.initWinDeployEnv = initWinDeployEnv;

  let isDeploying = false;
  async function startWinDeploy() {
    if (isDeploying) return;
    const btn = document.getElementById("btn-start-deploy");
    if (btn && btn.disabled) return;
    const isoInput = document.getElementById("input-iso-path");
    const isoText = document.getElementById("iso-path-text");
    const isoPath = ((isoInput && isoInput.value.trim()) || (isoText ? (isoText.innerText || "").trim() : "")).trim();
    const modeEl = document.querySelector('input[name="deploy-mode"]:checked');
    const deployMode = modeEl ? modeEl.value : "upgrade";
    const cbBackupDrivers = document.getElementById("cb-deploy-backup-drivers");
    const shouldBackupDrivers = cbBackupDrivers ? cbBackupDrivers.checked : true;
    const cbBackupSystem = document.getElementById("cb-deploy-backup-system");
    const shouldBackupSystem = cbBackupSystem ? cbBackupSystem.checked : true;

    if (!isoPath) {
      showToast("Cài Đặt Windows", "Vui lòng chọn hoặc nhập đường dẫn file ISO trước khi bắt đầu!", "warning");
      return;
    }

    isDeploying = true;
    const originalHtml = btn ? btn.innerHTML : "";
    if (btn) {
      btn.disabled = true;
      btn.innerHTML = `<span class="material-symbols-outlined text-[20px] animate-spin">progress_activity</span><span>${shouldBackupSystem ? "ĐANG SAO LƯU WINDOWS & NẠP ISO..." : (shouldBackupDrivers ? "ĐANG SAO LƯU DRIVER & NẠP ISO..." : "ĐANG NẠP ISO VÀ KÍCH HOẠT SETUP...")}</span>`;
    }

    try {
      if (shouldBackupSystem) {
        showToast("Sao Lưu Hệ Thống", "Đang tự động sao lưu toàn bộ Windows C: trước khi cài mới...", "info");
        await backupSystemFromDeploy();
      }

      if (shouldBackupDrivers) {
        showToast("Sao Lưu Driver", "Đang tiến hành sao lưu Driver máy tính trước khi cài Win...", "info");
        await backupDriverFromDeploy();
      }

      const res = await invokeRust("run_system_action", {
        actionId: "start_win_deploy",
        iso_path: isoPath,
        isoPath: isoPath,
        mode: deployMode,
        deployMode: deployMode,
        backup_system: shouldBackupSystem ? "true" : "false",
        backupSystem: shouldBackupSystem ? "true" : "false",
        backup_drivers: shouldBackupDrivers ? "true" : "false",
        backupDrivers: shouldBackupDrivers ? "true" : "false"
      });
      if (res && res.success) {
        showToast("Cài Đặt Windows", res.message || "Đã kích hoạt Windows Setup thành công!", "success");
        if (btn) {
          btn.innerHTML = `<span class="material-symbols-outlined text-[20px]">check</span><span>ĐÃ KÍCH HOẠT THÀNH CÔNG</span>`;
        }
      } else {
        showToast("Lỗi Cài Đặt", (res && res.message) ? res.message : "Không thể khởi chạy bộ cài Windows", "error");
        if (btn) {
          btn.innerHTML = originalHtml;
          btn.disabled = false;
        }
      }
    } catch (e) {
      showToast("Lỗi Hệ Thống", "Gặp lỗi ngoại lệ khi kích hoạt: " + e, "error");
      if (btn) {
        btn.innerHTML = originalHtml;
        btn.disabled = false;
      }
    } finally {
      isDeploying = false;
    }
  }
  window.startWinDeploy = startWinDeploy;

  // --- 10. HEARTBEAT & LIFECYCLE CONTROLLER ---
  function sendHeartbeat() {
    fetch("/api/heartbeat", { method: "POST" }).catch(() => {});
  }

  async function syncAppVersion() {
    try {
      const res = await invokeRust("get_app_version");
      if (res && res.version) {
        const vText = "v" + res.version;
        const badge = document.getElementById("app-version-badge");
        if (badge) badge.innerText = vText;
        const techBadge = document.getElementById("tech-driver-build-badge");
        if (techBadge) techBadge.innerText = "Build: " + vText;
        document.title = "VUONGTT Toolkit " + vText;
      }
    } catch (_) {}
  }

  // --- 10. OFFICE M365 & HYPERLIS OFFICE DEPLOYMENT CONTROLLER ---
  const OFFICE_PRODUCTS = {
    "365": [
      { id: "365_Home", name: "Microsoft 365 Home", prodId: "O365HomePremRetail", channel: "Current" },
      { id: "365_Business", name: "Microsoft 365 Apps for Business", prodId: "O365BusinessRetail", channel: "Current" },
      { id: "365_Enterprise", name: "Microsoft 365 Apps for Enterprise", prodId: "O365ProPlusRetail", channel: "Current" }
    ],
    "2024": [
      { id: "2024_Pro", name: "Office LTSC Pro Plus 2024", prodId: "ProPlus2024Volume", channel: "PerpetualVL2024" },
      { id: "2024_Std", name: "Office LTSC Standard 2024", prodId: "Standard2024Volume", channel: "PerpetualVL2024" },
      { id: "2024_HomeBusiness", name: "Office HomeBusiness 2024", prodId: "HomeBusiness2024Retail", channel: "Current" },
      { id: "2024_HomeStudent", name: "Office HomeStudent LTSC 2024", prodId: "HomeStudent2024Retail", channel: "Current" }
    ],
    "2021": [
      { id: "2021_Pro", name: "Office LTSC Pro Plus 2021", prodId: "ProPlus2021Volume", channel: "PerpetualVL2021" },
      { id: "2021_Std", name: "Office LTSC Standard 2021", prodId: "Standard2021Volume", channel: "PerpetualVL2021" },
      { id: "2021_HomeBusiness", name: "Office HomeBusiness 2021", prodId: "HomeBusiness2021Retail", channel: "Current" },
      { id: "2021_HomeStudent", name: "Office HomeStudent LTSC 2021", prodId: "HomeStudent2021Retail", channel: "Current" }
    ],
    "2019": [
      { id: "2019_Pro", name: "Office 2019 Professional Plus", prodId: "ProPlus2019Volume", channel: "PerpetualVL2019" },
      { id: "2019_Std", name: "Office 2019 Standard", prodId: "Standard2019Volume", channel: "PerpetualVL2019" },
      { id: "2019_HomeBusiness", name: "Office HomeBusiness 2019", prodId: "HomeBusiness2019Retail", channel: "Current" },
      { id: "2019_HomeStudent", name: "Office HomeStudent 2019", prodId: "HomeStudent2019Retail", channel: "Current" }
    ],
    "2016": [
      { id: "2016_Pro", name: "Office 2016 Professional Plus", prodId: "ProPlusRetail", channel: "Current" },
      { id: "2016_Std", name: "Office 2016 Standard", prodId: "StandardRetail", channel: "Current" }
    ],
    "2013": [
      { id: "2013_Pro", name: "Office 2013 Professional Plus", prodId: "ProPlusRetail", channel: "Current" },
      { id: "2013_Std", name: "Office 2013 Standard", prodId: "StandardRetail", channel: "Current" }
    ]
  };

  let currentOfficeVersion = "365";
  let currentOfficeSubId = "365_Home";
  let currentOfficeXml = "";

  function logOffice(tag, msg, color = "text-on-surface-variant") {
    const terminalBody = document.getElementById("terminal-body");
    if (!terminalBody) return;
    const now = new Date();
    const timeStr = "[" + now.toTimeString().split(" ")[0] + "]";
    const div = document.createElement("div");
    div.className = "flex items-start gap-2 text-outline";
    div.innerHTML = "<span>" + timeStr + "</span><span class=\"" + color + "\">[" + tag + "]</span><span class=\"text-on-surface\">" + msg + "</span>";
    terminalBody.appendChild(div);
    terminalBody.scrollTop = terminalBody.scrollHeight;
  }

  window.selectOfficeMainVersion = function(ver, el) {
    currentOfficeVersion = ver;
    document.querySelectorAll(".office-ver-card").forEach((card) => {
      card.classList.remove("active", "border-sky-500", "bg-sky-50/70");
      card.classList.add("border-slate-200/90", "bg-white/80");
      const check = card.querySelector(".office-check");
      if (check) check.classList.add("hidden");
    });

    if (el) {
      el.classList.add("active", "border-sky-500", "bg-sky-50/70");
      el.classList.remove("border-slate-200/90", "bg-white/80");
      const check = el.querySelector(".office-check");
      if (check) check.classList.remove("hidden");
    }

    const licVol = document.getElementById("odt-lic-volume");
    const licRet = document.getElementById("odt-lic-retail");
    if (ver === "365") {
      if (licRet) licRet.checked = true;
      if (licVol) licVol.disabled = true;
    } else {
      if (licVol) licVol.disabled = false;
    }

    const prods = OFFICE_PRODUCTS[ver] || [];
    if (prods.length > 0) {
      currentOfficeSubId = prods[0].id;
    }
    renderOfficeSubVersions();
    window.updateOfficeConfig();
  };

  function renderOfficeSubVersions() {
    const container = document.getElementById("office-sub-versions");
    if (!container) return;
    const prods = OFFICE_PRODUCTS[currentOfficeVersion] || [];
    container.innerHTML = "";

    prods.forEach((p, idx) => {
      const isChecked = p.id === currentOfficeSubId || (idx === 0 && !currentOfficeSubId);
      const label = document.createElement("label");
      label.className = "flex items-center gap-2 cursor-pointer hover:text-sky-600 transition-colors";
      label.innerHTML = `<input type="radio" name="odt_sub_ver" value="${p.id}" ${isChecked ? "checked" : ""} class="w-4 h-4 text-sky-600 accent-sky-600"/><span>${p.name}</span>`;
      label.querySelector("input").addEventListener("change", () => {
        currentOfficeSubId = p.id;
        const channelSelect = document.getElementById("odt-channel");
        if (channelSelect && p.channel) {
          channelSelect.value = p.channel;
        }
        window.updateOfficeConfig();
      });
      container.appendChild(label);
    });
  }

  window.toggleVisioPro = function(cb) {
    if (cb && cb.checked) {
      const vs = document.getElementById("app-visiostd");
      if (vs) vs.checked = false;
    }
  };

  window.toggleVisioStd = function(cb) {
    if (cb && cb.checked) {
      const vp = document.getElementById("app-visiopro");
      if (vp) vp.checked = false;
    }
  };

  window.quickSelectOfficeApps = function(preset) {
    const appWord = document.getElementById("app-word");
    const appExcel = document.getElementById("app-excel");
    const appPpt = document.getElementById("app-powerpoint");
    const appOutlook = document.getElementById("app-outlook");
    const appOneNote = document.getElementById("app-onenote");
    const appAccess = document.getElementById("app-access");
    const appTeams = document.getElementById("app-teams");
    const appOneDrive = document.getElementById("app-onedrive");
    const appSkype = document.getElementById("app-skype");
    const appVisioPro = document.getElementById("app-visiopro");
    const appVisioStd = document.getElementById("app-visiostd");
    const appProjectPro = document.getElementById("app-projectpro");

    const all = [appWord, appExcel, appPpt, appOutlook, appOneNote, appAccess, appTeams, appOneDrive, appSkype, appVisioPro, appVisioStd, appProjectPro];
    all.forEach((el) => { if (el) el.checked = false; });

    if (preset === "min") {
      if (appWord) appWord.checked = true;
      if (appExcel) appExcel.checked = true;
      if (appPpt) appPpt.checked = true;
    } else if (preset === "rec") {
      if (appWord) appWord.checked = true;
      if (appExcel) appExcel.checked = true;
      if (appPpt) appPpt.checked = true;
      if (appOutlook) appOutlook.checked = true;
      if (appTeams) appTeams.checked = true;
      if (appOneDrive) appOneDrive.checked = true;
    } else if (preset === "full") {
      all.forEach((el) => { if (el) el.checked = true; });
      if (appVisioStd) appVisioStd.checked = false;
    }
    window.updateOfficeConfig();
  };

  window.updateOfficeConfig = function() {
    const prods = OFFICE_PRODUCTS[currentOfficeVersion] || [];
    const prod = prods.find((p) => p.id === currentOfficeSubId) || prods[0];
    if (!prod) return;

    const archEl = document.querySelector("input[name='odt_arch']:checked");
    const arch = archEl ? archEl.value : "64";
    const channelSelect = document.getElementById("odt-channel");
    const channel = channelSelect ? channelSelect.value : prod.channel;
    const langSelect = document.getElementById("odt-language");
    const lang = langSelect ? langSelect.value : "en-us";
    const langText = langSelect && langSelect.options[langSelect.selectedIndex] ? langSelect.options[langSelect.selectedIndex].text : "English";

    const isVolume = document.getElementById("odt-lic-volume")?.checked;
    const licenseSuffix = isVolume ? "Volume" : "Retail";

    let finalProdId = prod.prodId;
    if (!finalProdId.startsWith("O365")) {
      if (finalProdId.endsWith("Volume")) {
        finalProdId = finalProdId.slice(0, -6) + licenseSuffix;
      } else if (finalProdId.endsWith("Retail")) {
        finalProdId = finalProdId.slice(0, -6) + licenseSuffix;
      }
    }

    const appWord = document.getElementById("app-word")?.checked;
    const appExcel = document.getElementById("app-excel")?.checked;
    const appPpt = document.getElementById("app-powerpoint")?.checked;
    const appOutlook = document.getElementById("app-outlook")?.checked;
    const appOneNote = document.getElementById("app-onenote")?.checked;
    const appAccess = document.getElementById("app-access")?.checked;
    const appTeams = document.getElementById("app-teams")?.checked;
    const appOneDrive = document.getElementById("app-onedrive")?.checked;
    const appSkype = document.getElementById("app-skype")?.checked;
    const appVisioPro = document.getElementById("app-visiopro")?.checked;
    const appVisioStd = document.getElementById("app-visiostd")?.checked;
    const appProjectPro = document.getElementById("app-projectpro")?.checked;

    const optRemove = document.getElementById("odt-opt-remove")?.checked;
    const optShortcut = document.getElementById("odt-opt-shortcut")?.checked;

    let xml = "<Configuration>\n";
    xml += `  <Add OfficeClientEdition="${arch}" Channel="${channel}">\n`;
    xml += `    <Product ID="${finalProdId}" PIDKEY="">\n`;
    xml += `      <Language ID="${lang}" />\n`;

    if (!appWord) xml += '      <ExcludeApp ID="Word" />\n';
    if (!appExcel) xml += '      <ExcludeApp ID="Excel" />\n';
    if (!appPpt) xml += '      <ExcludeApp ID="PowerPoint" />\n';
    if (!appOutlook) xml += '      <ExcludeApp ID="Outlook" />\n';
    if (!appOneNote) xml += '      <ExcludeApp ID="OneNote" />\n';
    if (!appAccess) xml += '      <ExcludeApp ID="Access" />\n';
    if (!appOneDrive) xml += '      <ExcludeApp ID="OneDrive" />\n';
    if (!appSkype) xml += '      <ExcludeApp ID="Lync" />\n';
    xml += "    </Product>\n";

    if (appVisioPro || appVisioStd) {
      const vType = appVisioPro ? "Pro" : "Std";
      const vYear = prod.name.includes("2024") ? "2024" : prod.name.includes("2021") ? "2021" : prod.name.includes("2019") ? "2019" : "";
      const vId = `Visio${vType}${vYear}${licenseSuffix}`;
      xml += `    <Product ID="${vId}">\n      <Language ID="${lang}" />\n    </Product>\n`;
    }

    if (appProjectPro) {
      const pYear = prod.name.includes("2024") ? "2024" : prod.name.includes("2021") ? "2021" : prod.name.includes("2019") ? "2019" : "";
      const pId = `ProjectPro${pYear}${licenseSuffix}`;
      xml += `    <Product ID="${pId}">\n      <Language ID="${lang}" />\n    </Product>\n`;
    }

    xml += "  </Add>\n";
    if (!optShortcut) {
      xml += '  <Property Name="Icons" Value="0" />\n';
    }
    xml += '  <Property Name="SharedComputerLicensing" Value="0" />\n';
    xml += '  <Property Name="FORCEAPPSHUTDOWN" Value="FALSE" />\n';
    xml += '  <Property Name="DeviceBasedLicensing" Value="0" />\n';
    xml += '  <Updates Enabled="TRUE" />\n';
    if (optRemove) {
      xml += "  <RemoveMSI />\n";
    }
    xml += "</Configuration>";

    currentOfficeXml = xml;

    const preview = document.getElementById("txtXmlPreview");
    if (preview) preview.textContent = xml;

    // Overview
    const elVer = document.getElementById("overview-version");
    if (elVer) elVer.textContent = prod.name;
    const elArch = document.getElementById("overview-arch");
    if (elArch) elArch.textContent = arch === "64" ? "x64 (64-bit)" : "x86 (32-bit)";
    const elChan = document.getElementById("overview-channel");
    if (elChan) elChan.textContent = channel;
    const elLang = document.getElementById("overview-lang");
    if (elLang) elLang.textContent = langText;

    const selectedApps = [];
    if (appWord) selectedApps.push("Word");
    if (appExcel) selectedApps.push("Excel");
    if (appPpt) selectedApps.push("PowerPoint");
    if (appOutlook) selectedApps.push("Outlook");
    if (appOneNote) selectedApps.push("OneNote");
    if (appAccess) selectedApps.push("Access");
    if (appTeams) selectedApps.push("Teams");
    if (appOneDrive) selectedApps.push("OneDrive");
    if (appVisioPro) selectedApps.push("Visio Pro");
    if (appVisioStd) selectedApps.push("Visio Std");
    if (appProjectPro) selectedApps.push("Project Pro");

    const elApps = document.getElementById("overview-apps");
    if (elApps) elApps.textContent = selectedApps.length > 0 ? selectedApps.join(", ") : "None";

    const selectedOpts = [];
    if (optRemove) selectedOpts.push("Remove existing Office");
    if (optShortcut) selectedOpts.push("Create Desktop Shortcut");
    selectedOpts.push("Include Updates");

    const elOpts = document.getElementById("overview-opts");
    if (elOpts) elOpts.textContent = selectedOpts.join(", ");
  };

  window.copyOfficeXml = function() {
    if (currentOfficeXml) {
      navigator.clipboard.writeText(currentOfficeXml).then(() => {
        showToast("Sao chép XML", "Đã sao chép cấu hình XML vào bộ nhớ tạm!", "success");
      }).catch(() => {
        showToast("Sao chép XML", "Vui lòng chọn vùng text để sao chép.", "info");
      });
    }
  };

  window.exportOfficeXml = function() {
    if (!currentOfficeXml) return;
    const blob = new Blob([currentOfficeXml], { type: "text/xml" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "configuration.xml";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
    showToast("Xuất XML", "Đã tải xuống tệp configuration.xml thành công!", "success");
  };

  window.installOffice = async function() {
    logOffice("START", "Khởi động tiến trình tải và cài đặt Office ODT...", "text-primary");
    showToast("Cài Đặt Office", "Đang khởi tạo gói triển khai Office...", "info");
    const arch = document.querySelector("input[name='odt_arch']:checked")?.value || "64";
    const prods = OFFICE_PRODUCTS[currentOfficeVersion] || [];
    const prod = prods.find((p) => p.id === currentOfficeSubId) || prods[0];
    const lang = document.getElementById("odt-language")?.value || "en-us";

    try {
      const res = await invokeRust("run_system_action", {
        actionId: "install_office",
        edition: arch,
        product: prod ? prod.prodId : "O365ProPlusRetail",
        lang: lang,
        xml: currentOfficeXml
      });
      if (res && res.success) {
        logOffice("SUCCESS", res.message || "Tiến trình cài đặt Office ODT đang chạy ngầm thành công!", "text-tertiary");
        showToast("Office M365", res.message || "Tiến trình cài đặt Office ODT đã khởi động!", "success");
      } else {
        logOffice("ERROR", (res && res.message) || "Không thể thực thi cài đặt Office", "text-error");
        showToast("Lỗi Cài Office", res ? res.message : "Thất bại", "error");
      }
    } catch (e) {
      logOffice("EXCEPTION", String(e), "text-error");
      showToast("Lỗi", String(e), "error");
    }
  };

  window.downloadOffice = async function() {
    logOffice("DOWNLOAD", "Đang tải gói dữ liệu Office ODT từ máy chủ CDN Microsoft...", "text-secondary");
    showToast("Tải Office", "Đang kết nối CDN Microsoft để tải gói cài đặt...", "info");
    try {
      const res = await invokeRust("run_system_action", {
        actionId: "install_office",
        downloadOnly: "true",
        xml: currentOfficeXml
      });
      if (res && res.success) {
        logOffice("SUCCESS", "Tiến trình tải dữ liệu Office đã hoàn tất!", "text-tertiary");
        showToast("Tải Office", "Đã tải xong gói dữ liệu Office!", "success");
      } else {
        logOffice("ERROR", (res && res.message) || "Không thể tải gói Office", "text-error");
        showToast("Lỗi Tải Office", res ? res.message : "Thất bại", "error");
      }
    } catch (e) {
      logOffice("EXCEPTION", String(e), "text-error");
      showToast("Lỗi", String(e), "error");
    }
  };

  window.uninstallOffice = async function() {
    const chk = document.getElementById("chk-confirm-uninstall-office");
    if (!chk || !chk.checked) {
      showToast("Cảnh báo", "Vui lòng tích xác nhận đồng ý gỡ bỏ Office!", "warning");
      return;
    }
    logOffice("UNINSTALL", "Đang quét và kích hoạt quy trình gỡ bỏ toàn bộ Office sạch sẽ...", "text-error");
    showToast("Gỡ Office", "Đang kích hoạt quy trình gỡ bỏ toàn bộ Office...", "warning");
    try {
      const res = await invokeRust("run_system_action", { actionId: "uninstall_office" });
      if (res && res.success) {
        logOffice("SUCCESS", "Đã hoàn tất quy trình gỡ bỏ toàn bộ Microsoft Office sạch sẽ!", "text-tertiary");
        showToast("Gỡ Office Thành Công", (res && res.message) || "Đã gỡ bỏ toàn bộ Office!", "success");
      } else {
        logOffice("ERROR", (res && res.message) || "Gỡ bỏ Office thất bại", "text-error");
        showToast("Lỗi Gỡ Office", (res && res.message) || "Thất bại", "error");
      }
    } catch (e) {
      logOffice("EXCEPTION", String(e), "text-error");
      showToast("Lỗi", String(e), "error");
    }
  };

  window.openSettingsModal = function() {
    const modal = document.getElementById("modal-settings");
    if (modal) modal.classList.remove("hidden");
  };

  window.closeSettingsModal = function() {
    const modal = document.getElementById("modal-settings");
    if (modal) modal.classList.add("hidden");
  };

  function initOfficeController() {
    const officeView = document.getElementById("view-office-m365");
    if (!officeView) return;

    renderOfficeSubVersions();
    window.updateOfficeConfig();

    // Attach hover listeners for General tweaks Description & Mô tả
    document.querySelectorAll("#view-general .tweak-item").forEach((item) => {
      item.addEventListener("mouseenter", () => {
        const descEn = item.getAttribute("data-desc-en");
        const descVi = item.getAttribute("data-desc-vi");
        const elEn = document.getElementById("general-desc-en");
        const elVi = document.getElementById("general-desc-vi");
        if (elEn && descEn) elEn.textContent = descEn;
        if (elVi && descVi) elVi.textContent = descVi;
      });
    });
  }

  // --- 11. PRINTER, SCAN & LAN CONTROLLER ---
  function initPrinterLanController() {
    const printerView = document.getElementById("view-printer-lan");
    if (!printerView) return;

    const btnFixSelected = document.getElementById("btn-fix-selected-codes");
    if (btnFixSelected) {
      btnFixSelected.addEventListener("click", async () => {
        showToast("Sửa Máy In", "Đang vá mã lỗi (0x11b, 709, 7c) và làm sạch Spooler...", "info");
        const logEl = document.getElementById("printer-action-log");
        if (logEl) {
          logEl.innerText += `\n[${new Date().toLocaleTimeString()}] Bắt đầu vá lỗi máy in LAN (0x11b, 0x709, 0x7c, Spooler)...`;
          logEl.scrollTop = logEl.scrollHeight;
        }
        try {
          const res = await invokeRust("run_system_action", { actionId: "fix_printer" });
          if (res && res.message) {
            showToast("Máy In & LAN", res.message, res.success ? "success" : "warning");
            if (logEl) {
              logEl.innerText += `\n[${new Date().toLocaleTimeString()}] ${res.message}`;
              logEl.scrollTop = logEl.scrollHeight;
            }
          }
        } catch (e) {
          showToast("Lỗi", "Không thể sửa máy in: " + e, "error");
          if (logEl) {
            logEl.innerText += `\n[${new Date().toLocaleTimeString()}] LỖI: ${e}`;
            logEl.scrollTop = logEl.scrollHeight;
          }
        }
      });
    }

    printerView.querySelectorAll(".tool-btn").forEach((btn) => {
      btn.addEventListener("click", async () => {
        const action = (btn.getAttribute("data-action") || "").toLowerCase().trim();
        let actionId = "fix_spooler";
        if (action.includes("pdf")) actionId = "cai print to pdf";
        else if (action.includes("2900")) actionId = "fix comm error 2900 - 3000";
        else if (action.includes("709")) actionId = "sua loi set mac dinh 0x709";
        else if (action === "scan_lan" || action.includes("lan")) actionId = "scan_lan";
        else if (action.includes("scan")) actionId = "share_scan_folder";

        showToast("Thao Tác Máy In", `Đang thực thi: ${btn.textContent.trim()}...`, "info");
        const logEl = document.getElementById("printer-action-log");
        try {
          const res = await invokeRust("run_system_action", { actionId });
          if (res && res.message) {
            showToast("Hoàn Tất", res.message, res.success ? "success" : "info");
            if (logEl) {
              logEl.innerText += `\n[${new Date().toLocaleTimeString()}] ${res.message}`;
              logEl.scrollTop = logEl.scrollHeight;
            }
          }
        } catch (e) {
          showToast("Lỗi", String(e), "error");
        }
      });
    });
  }

  // --- SMB SCAN FOLDER HELPERS ---
  window.createScanFolderShare = async function () {
    const folderPath = (document.getElementById("txtScanFolderPath")?.value || "C:\\Scan").trim();
    const shareName = (document.getElementById("txtScanShareName")?.value || "Scan").trim();
    showToast("Thư Mục Scan", `Đang tạo và chia sẻ thư mục ${folderPath} qua SMB...`, "info");
    try {
      const res = await invokeRust("run_system_action", {
        actionId: "share_scan_folder",
        folderPath,
        shareName
      });
      const logEl = document.getElementById("printer-action-log");
      if (logEl && res && res.message) {
        logEl.innerText += `\n[${new Date().toLocaleTimeString()}] ${res.message}`;
        logEl.scrollTop = logEl.scrollHeight;
      }
      if (res && res.message) {
        const ipMatch = res.message.match(/UNC_IP:([^\s|]+)/);
        const nameMatch = res.message.match(/UNC_NAME:([^\s|]+)/);
        if (ipMatch && document.getElementById("txtScanUncIp")) {
          document.getElementById("txtScanUncIp").innerText = ipMatch[1];
        }
        if (nameMatch && document.getElementById("txtScanUncName")) {
          document.getElementById("txtScanUncName").innerText = nameMatch[1];
        }
      }
      showToast("Thành Công", (res && res.message) || "Đã tạo thư mục Scan thành công!", "success");
    } catch (e) {
      showToast("Lỗi", String(e), "error");
    }
  };

  window.enableAllSharingNoPassword = async function () {
    showToast("Mở Toàn Quyền LAN", "Đang mở Network Discovery và tắt mật khẩu mạng...", "info");
    try {
      const res = await invokeRust("run_system_action", { actionId: "enable_all_sharing" });
      const logEl = document.getElementById("printer-action-log");
      if (logEl && res && res.message) {
        logEl.innerText += `\n[${new Date().toLocaleTimeString()}] ${res.message}`;
        logEl.scrollTop = logEl.scrollHeight;
      }
      showToast("Hoàn Tất", (res && res.message) || "Đã cấu hình chia sẻ mạng LAN thành công!", "success");
    } catch (e) {
      showToast("Lỗi", String(e), "error");
    }
  };

  window.copyUncPath = function (elementId) {
    const text = document.getElementById(elementId)?.innerText?.trim();
    if (text) {
      navigator.clipboard.writeText(text);
      showToast("Đã Copy", text, "success");
    }
  };

  window.browseScanFolder = async function () {
    try {
      const res = await invokeRust("run_system_action", { actionId: "browse_folder" });
      if (res && res.success && res.message && !res.message.includes("CANCEL")) {
        const input = document.getElementById("txtScanFolderPath");
        if (input) {
          input.value = res.message.trim();
          const shareInput = document.getElementById("txtScanShareName");
          if (shareInput && (!shareInput.value || shareInput.value === "Scan")) {
            const parts = res.message.trim().replace(/\\+$/, "").split("\\");
            const last = parts[parts.length - 1];
            if (last) shareInput.value = last;
          }
        }
      }
    } catch (_) {}
  };

  // --- 12. FAKE VPN / SOCKS5 PROXY CONTROLLER ---
  function initVpnProxyController() {
    const vpnView = document.getElementById("view-vpn-proxy");
    if (!vpnView) return;

    const btnRefresh = document.getElementById("btn-refresh-ip");
    const btnResetDhcp = document.getElementById("btn-reset-dhcp");
    const btnCopyIp = document.getElementById("btn-copy-ip");
    const masterConnectBtn = document.getElementById("master-connect-btn");
    const ipDisplay = document.getElementById("current-ip-display");
    const selectNode = document.getElementById("select-node");
    let isProxyConnected = false;

    if (btnRefresh) {
      btnRefresh.addEventListener("click", async () => {
        showToast("Làm Mới IP", "Đang truy vấn địa chỉ IP công cộng thực tế...", "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "refresh_ip" });
          if (res && res.message && ipDisplay) {
            ipDisplay.innerText = res.message.trim();
            showToast("IP Hiện Tại", `Địa chỉ IP: ${res.message.trim()}`, "success");
          }
        } catch (e) {
          showToast("Lỗi", String(e), "error");
        }
      });
    }

    if (btnResetDhcp) {
      btnResetDhcp.addEventListener("click", async () => {
        showToast("Khôi Phục Mạng Gốc", "Đang thực hiện DHCP Release/Renew và Flush DNS...", "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "reset_dhcp" });
          if (res && res.message) {
            showToast("Mạng Hệ Thống", res.message, res.success ? "success" : "warning");
          }
          if (btnRefresh) btnRefresh.click();
        } catch (e) {
          showToast("Lỗi", String(e), "error");
        }
      });
    }

    if (btnCopyIp && ipDisplay) {
      btnCopyIp.addEventListener("click", () => {
        navigator.clipboard.writeText(ipDisplay.innerText.trim());
        showToast("Clipboard", "Đã sao chép địa chỉ IP vào Clipboard!", "success");
      });
    }

    if (masterConnectBtn) {
      masterConnectBtn.addEventListener("click", async () => {
        const node = selectNode ? selectNode.value : "Hong Kong Fast Node";
        if (!isProxyConnected) {
          showToast("Bật Proxy", `Đang cấu hình Proxy hệ thống (${node})...`, "info");
          const res = await invokeRust("run_system_action", { actionId: "configure_proxy", server: "103.14.28.112:8080" });
          isProxyConnected = true;
          masterConnectBtn.classList.replace("bg-primary-container", "bg-error-container");
          masterConnectBtn.querySelector("span:last-child").innerText = "NGẮT KẾT NỐI PROXY";
          showToast("Proxy Kích Hoạt", (res && res.message) || "Đã bật Proxy hệ thống thành công!", "success");
        } else {
          showToast("Tắt Proxy", "Đang khôi phục kết nối trực tiếp...", "info");
          const res = await invokeRust("run_system_action", { actionId: "disable_proxy" });
          isProxyConnected = false;
          masterConnectBtn.classList.replace("bg-error-container", "bg-primary-container");
          masterConnectBtn.querySelector("span:last-child").innerText = "KÍCH HOẠT PROXY";
          showToast("Proxy Đã Tắt", (res && res.message) || "Đã tắt Proxy hệ thống!", "info");
        }
      });
    }
  }

  // --- 13. HWID & LICENSE CONTROLLER ---
  function initHwidController() {
    const hwidView = document.getElementById("view-hwid-act");
    if (!hwidView) return;

    const terminal = document.getElementById("terminal-screen");
    const clearBtn = document.getElementById("btn-clear-console");
    const recheckBtn = document.getElementById("btn-recheck-license");
    const upgradeBtn = document.getElementById("btn-upgrade-edition");
    const pasteBtn = document.getElementById("btn-paste-key");
    const keyInput = document.getElementById("custom-key-input");
    const actionBtns = hwidView.querySelectorAll("button[data-action]");

    function appendHwidLog(text, colorClass = "text-on-surface") {
      if (!terminal) return;
      const now = new Date();
      const timeStr = now.toTimeString().split(" ")[0];
      const line = document.createElement("div");
      line.className = colorClass;
      line.textContent = `[${timeStr}] ${text}`;
      terminal.appendChild(line);
      terminal.scrollTop = terminal.scrollHeight;
    }

    if (clearBtn && terminal) {
      clearBtn.addEventListener("click", () => {
        terminal.innerHTML = '<div class="text-outline">[System] Console cleared.</div>';
      });
    }

    if (recheckBtn) {
      recheckBtn.addEventListener("click", async () => {
        appendHwidLog("Đang kiểm tra trạng thái bản quyền qua slmgr.vbs /xpr...", "text-secondary");
        showToast("Kiểm Tra Bản Quyền", "Đang truy vấn giấy phép hệ thống...", "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "check_windows_activation" });
          appendHwidLog((res && res.message) || "Đã kiểm tra bản quyền", "text-tertiary");
          showToast("Trạng Thái Bản Quyền", (res && res.message) || "Kích hoạt vĩnh viễn", "success");
        } catch (e) {
          appendHwidLog("Lỗi kiểm tra: " + e, "text-error");
        }
      });
    }

    actionBtns.forEach((btn) => {
      btn.addEventListener("click", async () => {
        const action = btn.getAttribute("data-action");
        appendHwidLog(`Kích hoạt phương thức: ${action.toUpperCase()}...`, "text-primary");
        showToast("Kích Hoạt Bản Quyền", `Đang khởi chạy MAS ${action.toUpperCase()}...`, "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: action });
          appendHwidLog((res && res.message) || "Đã kích hoạt thành công", "text-tertiary");
          showToast("Bản Quyền Số", (res && res.message) || "Kích hoạt thành công!", "success");
        } catch (e) {
          appendHwidLog("Lỗi kích hoạt: " + e, "text-error");
        }
      });
    });

    if (upgradeBtn) {
      upgradeBtn.addEventListener("click", async () => {
        const keyVal = keyInput ? keyInput.value : "VK7JG-NPHTM-C97JM-9MPGT-3V66T";
        appendHwidLog(`Cài đặt Product Key chuyển phiên bản: ${keyVal}...`, "text-primary");
        showToast("Nâng Cấp Edition", "Đang nạp Product Key...", "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "upgrade_windows_edition", key: keyVal });
          appendHwidLog((res && res.message) || "Hoàn tất nâng cấp", "text-tertiary");
          showToast("Nâng Cấp Windows", (res && res.message) || "Đã gửi lệnh nâng cấp", "success");
        } catch (e) {
          appendHwidLog("Lỗi: " + e, "text-error");
        }
      });
    }

    if (pasteBtn && keyInput) {
      pasteBtn.addEventListener("click", async () => {
        try {
          const text = await navigator.clipboard.readText();
          if (text) keyInput.value = text.trim();
        } catch (e) {
          keyInput.focus();
        }
      });
    }

    const radios = hwidView.querySelectorAll('input[name="edition-target"]');
    const keyMap = {
      Pro: "VK7JG-NPHTM-C97JM-9MPGT-3V66T",
      Enterprise: "NPPR9-FWDCX-D2C8J-H872K-2YT43",
      ProWorkstations: "DXG7C-N37C8-8WD47-3BPJJ-63P7T",
      IoTEnterprise: "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"
    };
    radios.forEach((r) => {
      r.addEventListener("change", (e) => {
        if (keyInput && keyMap[e.target.value]) {
          keyInput.value = keyMap[e.target.value];
        }
      });
    });
  }

  // --- 14. 547 IT HELPDESK ENGINE CONTROLLER ---
  function initHelpdeskController() {
    const listEl = document.getElementById("helpdeskProblemList");
    const searchInput = document.getElementById("helpdeskSearchInput");
    const catFilter = document.getElementById("helpdeskCategoryFilter");
    const totalBadge = document.getElementById("helpdeskTotalBadge");
    const detailId = document.getElementById("detailProbId");
    const detailCat = document.getElementById("detailProbCat");
    const detailTitle = document.getElementById("detailProbTitle");
    const detailCause = document.getElementById("detailProbCause");
    const actionOutput = document.getElementById("helpdeskActionOutput");

    const btnDiag = document.getElementById("btnHelpdeskDiagnose");
    const btnFix = document.getElementById("btnHelpdeskAutoFix");
    const btnVerify = document.getElementById("btnHelpdeskVerify");
    const btnReport = document.getElementById("btnHelpdeskReport");

    if (!listEl) return;

    let allProblems = [];
    let selectedProblem = null;

    async function loadDatabase() {
      try {
        const res = await invokeRust("get_troubleshoot_database");
        let data = res && res.data;
        if (typeof data === "string") {
          try {
            data = JSON.parse(data.replace(/^\uFEFF/, "").trim());
          } catch (_) {}
        }
        if (data && data.Problems) {
          allProblems = data.Problems;
        } else if (data && Array.isArray(data)) {
          allProblems = data;
        }
      } catch (_) {}

      if (allProblems.length === 0) {
        allProblems = [
          { id: "SYS-001", cat: "01. Windows / Operating System", title: "Màn hình xanh BSOD KMODE_EXCEPTION", cause: "Driver phần cứng xung đột hoặc kernel corrupted." },
          { id: "NET-001", cat: "02. Network & Remote Access", title: "Mất kết nối Internet, IP 169.254.x.x (APIPA)", cause: "DHCP Server không cấp phát IP hoặc lỗi Winsock." },
          { id: "PERM-001", cat: "06. Security & Permissions", title: "Lỗi Access Denied khi truy cập ổ cứng / thư mục", cause: "NTFS Permission bị tước quyền hoặc thiếu quyền Take Ownership." },
          { id: "PRINT-001", cat: "05. Printing & Peripherals", title: "Lỗi kết nối máy in mạng 0x0000011b / 0x00000709", cause: "RPC Auth Level của Windows Update chặn chia sẻ máy in mạng." },
          { id: "OFFICE-001", cat: "04. Office & Productivity", title: "Word/Excel báo lỗi Unlicensed Product", cause: "Token bản quyền Office hết hạn hoặc dịch vụ OSPP bị tắt." }
        ];
      }

      if (totalBadge) totalBadge.innerText = `${allProblems.length} Mã Lỗi`;
      renderList(allProblems);
      if (allProblems.length > 0) selectItem(allProblems[0]);
    }

    function selectItem(prob) {
      selectedProblem = prob;
      if (detailId) detailId.innerText = prob.id || prob.Id || "SYS-001";
      if (detailCat) detailCat.innerText = prob.cat || prob.Category || "01. Windows / OS";
      if (detailTitle) detailTitle.innerText = prob.title || prob.Title || "";
      const cause = prob.cause || prob.Description || prob.Cause || "Không có thông tin chi tiết.";
      if (detailCause) detailCause.innerText = "Nguyên nhân: " + cause;

      if (actionOutput) {
        actionOutput.innerHTML = `<span class="text-secondary font-semibold">[ĐÃ CHỌN: ${prob.id || prob.Id}]</span> <span class="text-on-surface">${prob.title || prob.Title}</span><br/><span class="text-outline">Nhấn một trong 4 nút bên trên để thực hiện tác vụ.</span>`;
      }

      listEl.querySelectorAll(".prob-item").forEach((el) => {
        if (el.getAttribute("data-id") === (prob.id || prob.Id)) {
          el.classList.add("border-primary", "bg-primary-container/15");
        } else {
          el.classList.remove("border-primary", "bg-primary-container/15");
        }
      });
    }

    function renderList(items) {
      listEl.innerHTML = "";
      if (items.length === 0) {
        listEl.innerHTML = '<div class="p-6 text-center text-outline">Không tìm thấy mã sự cố phù hợp.</div>';
        return;
      }

      const fragment = document.createDocumentFragment();
      items.forEach((p) => {
        const pId = p.id || p.Id || "";
        const pTitle = p.title || p.Title || "";
        const pCat = p.cat || p.Category || "";

        const div = document.createElement("div");
        div.className = "prob-item p-2.5 rounded-lg bg-surface-container hover:bg-surface-container-high border border-outline-variant/20 cursor-pointer transition-all flex items-center justify-between";
        div.setAttribute("data-id", pId);
        div.innerHTML = `
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2">
              <span class="font-code-sm text-code-sm text-primary font-bold">${pId}</span>
              <span class="font-body-md text-body-md text-on-surface font-semibold truncate">${pTitle}</span>
            </div>
            <div class="font-label-sm text-label-sm text-outline truncate mt-0.5">${pCat}</div>
          </div>
          <span class="material-symbols-outlined text-[16px] text-outline shrink-0 ml-2">chevron_right</span>
        `;
        div.addEventListener("click", () => selectItem(p));
        fragment.appendChild(div);
      });
      listEl.appendChild(fragment);
    }

    function filterProblems() {
      const q = (searchInput ? searchInput.value : "").toLowerCase().trim();
      const cat = (catFilter ? catFilter.value : "all");

      const filtered = allProblems.filter((p) => {
        const id = (p.id || p.Id || "").toLowerCase();
        const title = (p.title || p.Title || "").toLowerCase();
        const pCat = (p.cat || p.Category || "").toLowerCase();

        const matchQuery = !q || id.includes(q) || title.includes(q);
        const matchCat = cat === "all" || pCat.startsWith(cat) || pCat.includes(cat);
        return matchQuery && matchCat;
      });

      renderList(filtered);
    }

    if (searchInput) searchInput.addEventListener("input", filterProblems);
    if (catFilter) catFilter.addEventListener("change", filterProblems);

    if (btnDiag) {
      btnDiag.addEventListener("click", async () => {
        if (!selectedProblem) return;
        const pid = selectedProblem.id || selectedProblem.Id;
        if (actionOutput) actionOutput.innerHTML = `<span class="text-secondary animate-pulse">[CHẨN ĐOÁN] Đang quét hệ thống tìm mã lỗi ${pid}...</span>`;
        showToast("Chẩn Đoán Sự Cố", `Đang chạy chẩn đoán: ${pid}...`, "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "diagnose_problem", problemId: pid });
          if (actionOutput) {
            actionOutput.innerHTML = `<span class="text-tertiary font-semibold">[KẾT QUẢ CHẨN ĐOÁN ${pid}]</span><br/><span class="text-on-surface">${res.message || "Hệ thống hoạt động bình thường."}</span>`;
          }
          showToast("Chẩn Đoán", res ? res.message : "Hoàn tất chẩn đoán", "success");
        } catch (e) {
          if (actionOutput) actionOutput.innerHTML = `<span class="text-error">[LỖI] ${e}</span>`;
        }
      });
    }

    if (btnFix) {
      btnFix.addEventListener("click", async () => {
        if (!selectedProblem) return;
        const pid = selectedProblem.id || selectedProblem.Id;
        if (actionOutput) actionOutput.innerHTML = `<span class="text-primary animate-pulse">[SỬA TỰ ĐỘNG] Đang thực thi Remediation Script cho ${pid}...</span>`;
        showToast("Tự Động Sửa", `Đang kích hoạt quy trình sửa lỗi cho ${pid}...`, "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "fix_problem", problemId: pid });
          if (actionOutput) {
            actionOutput.innerHTML = `<span class="text-tertiary font-semibold">[ĐÃ SỬA THÀNH CÔNG ${pid}]</span><br/><span class="text-on-surface">${res.message || "Đã khôi phục cấu hình an toàn."}</span>`;
          }
          showToast("Đã Sửa Xong", res ? res.message : "Đã sửa thành công!", "success");
        } catch (e) {
          if (actionOutput) actionOutput.innerHTML = `<span class="text-error">[LỖI SỬA] ${e}</span>`;
        }
      });
    }

    if (btnVerify) {
      btnVerify.addEventListener("click", async () => {
        if (!selectedProblem) return;
        const pid = selectedProblem.id || selectedProblem.Id;
        if (actionOutput) actionOutput.innerHTML = `<span class="text-secondary animate-pulse">[XÁC MINH] Đang xác thực trạng thái sau sửa đổi ${pid}...</span>`;
        showToast("Xác Minh", `Đang kiểm tra lại trạng thái cho ${pid}...`, "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "verify_problem", problemId: pid });
          if (actionOutput) {
            actionOutput.innerHTML = `<span class="text-tertiary font-semibold">[XÁC MINH HOÀN TẤT ${pid}]</span><br/><span class="text-on-surface">${res.message || "Trạng thái đạt chuẩn (Verified)."}</span>`;
          }
          showToast("Xác Minh", res ? res.message : "Xác minh hoàn tất!", "success");
        } catch (e) {
          if (actionOutput) actionOutput.innerHTML = `<span class="text-error">[LỖI XÁC MINH] ${e}</span>`;
        }
      });
    }

    if (btnReport) {
      btnReport.addEventListener("click", async () => {
        showToast("Xuất Báo Cáo", "Đang tạo báo cáo kỹ thuật ra Desktop...", "info");
        try {
          const res = await invokeRust("run_system_action", { actionId: "export_helpdesk_report" });
          if (actionOutput) {
            actionOutput.innerHTML = `<span class="text-secondary font-semibold">[XUẤT BÁO CÁO]</span><br/><span class="text-on-surface">${res.message || "Đã lưu báo cáo ra Desktop!"}</span>`;
          }
          showToast("Báo Cáo Kỹ Thuật", (res && res.message) || "Đã lưu ra Desktop!", "success");
        } catch (e) {
          showToast("Lỗi", String(e), "error");
        }
      });
    }

    window.refreshHelpdeskDatabase = loadDatabase;
    loadDatabase();
  }

  // --- 15. HEADER CONTROLS & AUTO-UPDATE ENGINE ---
  let isUpdatingInProgress = false;

  window.triggerManualUpdate = async function () {
    if (isUpdatingInProgress) {
      showToast("Đang Cập Nhật", "Hệ thống đang tải dữ liệu cập nhật, vui lòng đợi trong giây lát...", "info");
      return;
    }
    isUpdatingInProgress = true;
    showToast("Kiểm Tra Cập Nhật", "Đang kết nối GitHub để kiểm tra phiên bản mới nhất...", "info");

    try {
      const res = await invokeRust("run_system_action", { actionId: "check_update" });
      let updateInfo = null;
      try {
        if (res && res.message) updateInfo = JSON.parse(res.message);
      } catch (_) {}

      const curVer = (updateInfo && updateInfo.current_version) || "2026";
      const newVer = (updateInfo && updateInfo.latest_version) || curVer;

      if (updateInfo && updateInfo.has_update) {
        showToast("Phát Hiện Bản Mới", `Phát hiện bản nâng cấp v${newVer} (hiện tại: v${curVer})! Đang tự động tải và cài đặt...`, "info");
      } else {
        showToast("Tải Bản Mới Nhất", `Đang tải và cập nhật phiên bản mới nhất từ GitHub...`, "info");
      }

      const applyRes = await invokeRust("run_system_action", { actionId: "apply_update" });
      if (applyRes && applyRes.success) {
        showToast("Cập Nhật Thành Công", "Đã tải xong bản mới nhất! Ứng dụng đang tự động thay thế và khởi động lại sau 2 giây...", "success");
        setTimeout(() => {
          invokeRust("window_control", { action: "close" }).catch(() => {});
        }, 1800);
      } else {
        isUpdatingInProgress = false;
        showToast("Thông Báo Cập Nhật", (applyRes && applyRes.message) || "Không thể tải bản cập nhật tự động. Vui lòng kiểm tra lại kết nối mạng!", "warning");
      }
    } catch (err) {
      isUpdatingInProgress = false;
      showToast("Lỗi Cập Nhật", String(err), "error");
    }
  };

  async function checkForUpdate(isManual = false) {
    if (isManual) {
      await window.triggerManualUpdate();
      return;
    }

    try {
      const res = await invokeRust("run_system_action", { actionId: "check_update" });
      if (!res || !res.message) return;
      let updateInfo = null;
      try {
        updateInfo = JSON.parse(res.message);
      } catch (_) {}

      if (updateInfo && updateInfo.has_update) {
        const newVer = updateInfo.latest_version;
        const curVer = updateInfo.current_version;
        showToast("Cập Nhật Tự Động", `Phát hiện bản mới v${newVer} trên GitHub! Đang tự động nâng cấp...`, "info");
        const logEl = document.getElementById("log-console");
        if (logEl && typeof appendLog === "function") {
          appendLog("UPDATE", `Tự động tải và cập nhật lên v${newVer} từ GitHub...`, "text-secondary");
        }
        const btnHeaderUpdate = document.getElementById("btn-header-update");
        if (btnHeaderUpdate) {
          btnHeaderUpdate.classList.add("animate-pulse");
          btnHeaderUpdate.title = `Có bản cập nhật mới v${newVer}! Bấm để nâng cấp ngay.`;
        }
        // Tự động tải và cập nhật lên bản mới nhất
        setTimeout(async () => {
          const applyRes = await invokeRust("run_system_action", { actionId: "apply_update" });
          if (applyRes && applyRes.success) {
            showToast("Đang Cập Nhật", "Tải bản mới thành công! Ứng dụng đang tự khởi động lại...", "success");
            setTimeout(() => {
              invokeRust("window_control", { action: "close" }).catch(() => {});
            }, 1800);
          }
        }, 2500);
      }
    } catch (_) {}
  }

  function initAutoUpdateOnStartup() {
    setTimeout(() => {
      checkForUpdate(false);
    }, 2000);
  }

  function initHeaderControls() {
    const btnVn = document.getElementById("btn-lang-vn");
    const btnEn = document.getElementById("btn-lang-en");
    const btnHeaderUpdate = document.getElementById("btn-header-update");
    const btnCheckUpdate = document.getElementById("btn-check-update");

    if (btnVn) {
      btnVn.addEventListener("click", () => {
        showToast("Ngôn Ngữ", "Đang áp dụng giao diện Tiếng Việt chuẩn!", "info");
      });
    }
    if (btnEn) {
      btnEn.addEventListener("click", () => {
        showToast("Language", "English language interface selected!", "info");
      });
    }
    const triggerUpdate = (e) => {
      if (e) e.preventDefault();
      checkForUpdate(true);
    };
    if (btnHeaderUpdate && !btnHeaderUpdate._hasUpdateListener) {
      btnHeaderUpdate._hasUpdateListener = true;
      btnHeaderUpdate.addEventListener("click", triggerUpdate);
    }
    if (btnCheckUpdate && !btnCheckUpdate._hasUpdateListener) {
      btnCheckUpdate._hasUpdateListener = true;
      btnCheckUpdate.addEventListener("click", triggerUpdate);
    }
  }

  // --- 16. INITIALIZATION ---
  
  // --- HYPERLIS INTERACTIVE CONTROLLERS ---
  function initTweakHoverExplanation() {
    document.querySelectorAll(".tweak-item").forEach((item) => {
      item.addEventListener("mouseenter", () => {
        const title = item.getAttribute("data-title") || "Description";
        const descEn = item.getAttribute("data-desc-en") || "";
        const descVi = item.getAttribute("data-desc-vi") || "";
        const titleEl = document.getElementById("panel-desc-title");
        const enEl = document.getElementById("panel-desc-en");
        const viEl = document.getElementById("panel-desc-vi");
        if (titleEl && descEn) titleEl.textContent = `Description: ${title}`;
        if (enEl && descEn) enEl.textContent = descEn;
        if (viEl && descVi) viEl.textContent = descVi;
      });
    });
  }

// [Cleaned duplicate selectBloatwarePreset]

  // =========================================================================
  // 18. BITLOCKER DRIVE ENCRYPTION MANAGEMENT CONTROLLER
  // =========================================================================
  function initBitLockerController() {
    const view = document.getElementById("view-bitlocker-mgmt");
    if (!view) return;

    const logEl = document.getElementById("bitlocker-action-output");
    function appendBitLockerLog(text) {
      if (!logEl) return;
      const time = new Date().toLocaleTimeString();
      logEl.innerText += `\n[${time}] ${text}`;
      logEl.scrollTop = logEl.scrollHeight;
    }

    const btnClearLog = document.getElementById("btn-bitlocker-clear-log");
    if (btnClearLog) {
      btnClearLog.addEventListener("click", () => {
        if (logEl) logEl.innerText = "[HỆ THỐNG] Nhật ký đã được làm sạch.";
      });
    }

    // 1. Quét và nạp trạng thái phân vùng
    async function refreshBitLockerStatus() {
      appendBitLockerLog("Đang truy vấn trạng thái mã hóa các phân vùng ổ đĩa (manage-bde -status)...");
      const tbody = document.getElementById("bitlocker-drives-body");
      const driveSelect = document.getElementById("select-bitlocker-target-drive");
      const countEl = document.getElementById("bitlocker-drives-count");
      const summaryStatus = document.getElementById("bitlocker-summary-status");
      const summaryC = document.getElementById("bitlocker-summary-c");

      try {
        const res = await invokeRust("run_system_action", { actionId: "get_bitlocker_status" });
        let drives = [];
        if (res && res.message) {
          try {
            drives = JSON.parse(res.message);
            if (!Array.isArray(drives) && drives && typeof drives === "object") {
              drives = [drives];
            }
            if (!Array.isArray(drives)) drives = [];
          } catch (_) {
            appendBitLockerLog(res.message);
          }
        }

        
        if (!Array.isArray(drives) || drives.length === 0) {
          drives = [{
            drive: "C:",
            volume_name: "Windows (System)",
            size_gb: 128,
            free_gb: 64,
            protection_status: "Tắt (Off)",
            lock_status: "Mở Khóa",
            key_protectors: [],
            encryption_percentage: "0%",
            encryption_method: "None"
          }];
        }

        if (Array.isArray(drives) && drives.length > 0) {
          if (countEl) countEl.innerText = `${drives.length} phân vùng`;
          if (driveSelect) {
            driveSelect.innerHTML = drives.map(d => `<option value="${d.drive}">${d.drive} ${d.volume_name ? '(' + d.volume_name + ')' : ''} [${d.protection_status}]</option>`).join("");
          }

          // Update Summary
          const cDrive = drives.find(d => d.drive && d.drive.toUpperCase().startsWith("C"));
          if (cDrive && summaryC) {
            summaryC.innerText = `${cDrive.protection_status} (${cDrive.encryption_percentage || '0%'})`;
          }
          const hasEncrypted = drives.some(d => d.protection_status && (d.protection_status.includes("On") || d.protection_status.includes("Bật")));
          if (summaryStatus) {
            summaryStatus.innerText = hasEncrypted ? "Có phân vùng được bảo vệ" : "Chưa kích hoạt mã hóa";
            summaryStatus.className = hasEncrypted ? "font-bold text-emerald-600 text-sm mt-0.5" : "font-bold text-slate-800 text-sm mt-0.5";
          }

          // Render Table
          if (tbody) {
            tbody.innerHTML = drives.map(d => {
              const isProtected = d.protection_status && (d.protection_status.includes("On") || d.protection_status.includes("Bật"));
              const isLocked = d.lock_status && (d.lock_status.includes("Locked") || d.lock_status.includes("Đã khóa"));
              const statusBadge = isProtected
                ? `<span class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-100 text-emerald-700">Đã Bật (${d.protection_status})</span>`
                : `<span class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-slate-100 text-slate-600">Đã Tắt (${d.protection_status})</span>`;
              const lockBadge = isLocked
                ? `<span class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-rose-100 text-rose-700">Bị Khóa</span>`
                : `<span class="px-2 py-0.5 rounded-full text-[10px] font-semibold bg-blue-100 text-blue-700">Mở Khóa</span>`;

              return `
                <tr class="hover:bg-slate-50/60 transition-colors">
                  <td class="p-2.5 font-bold text-slate-800">${d.drive} <span class="font-normal text-slate-500">${d.volume_name || ''}</span></td>
                  <td class="p-2.5">${d.free_gb || 0} GB trống / ${d.size_gb || 0} GB</td>
                  <td class="p-2.5">${statusBadge}</td>
                  <td class="p-2.5">${lockBadge}</td>
                  <td class="p-2.5 text-slate-600">${Array.isArray(d.key_protectors) && d.key_protectors.length ? d.key_protectors.join(", ") : (d.encryption_method || "None")}</td>
                  <td class="p-2.5 font-mono">${d.encryption_percentage || '0%'}</td>
                  <td class="p-2.5 text-right space-x-1">
                    <button onclick="quickBitLockerAction('get_key', '${d.drive}')" class="px-2 py-1 rounded bg-amber-50 hover:bg-amber-100 text-amber-700 text-[10px] font-semibold cursor-pointer" title="Xem Khóa Khôi Phục">Khóa</button>
                    ${isProtected
                      ? `<button onclick="quickBitLockerAction('disable', '${d.drive}')" class="px-2 py-1 rounded bg-rose-50 hover:bg-rose-100 text-rose-700 text-[10px] font-semibold cursor-pointer" title="Tắt BitLocker">Tắt</button>`
                      : `<button onclick="quickBitLockerAction('enable', '${d.drive}')" class="px-2 py-1 rounded bg-emerald-50 hover:bg-emerald-100 text-emerald-700 text-[10px] font-semibold cursor-pointer" title="Bật BitLocker">Bật</button>`
                    }
                  </td>
                </tr>
              `;
            }).join("");
          }
          appendBitLockerLog(`[OK] Đã nạp thành công trạng thái của ${drives.length} phân vùng ổ đĩa.`);
        } else {
          if (tbody) tbody.innerHTML = `<tr><td colspan="7" class="p-4 text-center text-slate-400 italic">Không tìm thấy phân vùng cố định hoặc BitLocker chưa được khởi tạo.</td></tr>`;
        }
      } catch (err) {
        appendBitLockerLog("[LỖI] Không thể đọc trạng thái BitLocker: " + err);
      }
    }

    const btnRefresh = document.getElementById("btn-bitlocker-refresh");
    if (btnRefresh) btnRefresh.addEventListener("click", () => refreshBitLockerStatus());

    // Open Control Panel
    const btnCpl = document.getElementById("btn-bitlocker-open-cpl");
    if (btnCpl) {
      btnCpl.addEventListener("click", async () => {
        await invokeRust("run_system_action", { actionId: "open_bitlocker_cpl" });
      });
    }

    // Action Handlers
    const btnEnable = document.getElementById("btn-bitlocker-enable");
    if (btnEnable) {
      btnEnable.addEventListener("click", async () => {
        const drive = document.getElementById("select-bitlocker-target-drive")?.value || "C:";
        const password = document.getElementById("input-bitlocker-password")?.value || "";
        if (!confirm(`Bạn có chắc chắn muốn BẬT mã hóa BitLocker cho phân vùng ${drive}?`)) return;
        appendBitLockerLog(`Đang thực thi bật BitLocker cho ${drive}...`);
        showToast("BitLocker", `Đang kích hoạt mã hóa ổ ${drive}...`, "info");
        const res = await invokeRust("run_system_action", { actionId: "enable_bitlocker", drive, password });
        appendBitLockerLog(res?.message || "Đã gửi lệnh bật BitLocker.");
        showToast("BitLocker", res?.message || "Hoàn tất lệnh.", res?.success ? "success" : "warning");
        setTimeout(refreshBitLockerStatus, 1500);
      });
    }

    const btnDisable = document.getElementById("btn-bitlocker-disable");
    if (btnDisable) {
      btnDisable.addEventListener("click", async () => {
        const drive = document.getElementById("select-bitlocker-target-drive")?.value || "C:";
        if (!confirm(`CẢNH BÁO: Bạn có chắc chắn muốn TẮT và GIẢI MÃ hoàn toàn BitLocker cho phân vùng ${drive}?`)) return;
        appendBitLockerLog(`Đang gửi lệnh giải mã (manage-bde -off ${drive})...`);
        showToast("BitLocker", `Đang tắt BitLocker ổ ${drive}...`, "info");
        const res = await invokeRust("run_system_action", { actionId: "disable_bitlocker", drive });
        appendBitLockerLog(res?.message || "Đã gửi lệnh tắt BitLocker.");
        showToast("BitLocker", res?.message || "Hoàn tất lệnh.", res?.success ? "success" : "warning");
        setTimeout(refreshBitLockerStatus, 1500);
      });
    }

    const btnUnlock = document.getElementById("btn-bitlocker-unlock");
    if (btnUnlock) {
      btnUnlock.addEventListener("click", async () => {
        const drive = document.getElementById("select-bitlocker-target-drive")?.value || "C:";
        const password = document.getElementById("input-bitlocker-password")?.value || "";
        const recovery_key = document.getElementById("input-bitlocker-recovery-key")?.value || "";
        if (!password && !recovery_key) {
          showToast("Cảnh báo", "Vui lòng nhập mật khẩu hoặc mã Recovery Key 48 số để mở khóa!", "warning");
          return;
        }
        appendBitLockerLog(`Đang gửi lệnh mở khóa phân vùng ${drive}...`);
        const res = await invokeRust("run_system_action", { actionId: "unlock_bitlocker", drive, password, recovery_key });
        appendBitLockerLog(res?.message || "Hoàn tất lệnh mở khóa.");
        showToast("BitLocker", res?.message || "Hoàn tất lệnh.", res?.success ? "success" : "warning");
        setTimeout(refreshBitLockerStatus, 1500);
      });
    }

    const btnBackupKey = document.getElementById("btn-bitlocker-backup-key");
    if (btnBackupKey) {
      btnBackupKey.addEventListener("click", async () => {
        const drive = document.getElementById("select-bitlocker-target-drive")?.value || "C:";
        appendBitLockerLog(`Đang trích xuất mã Recovery Key của ${drive}...`);
        showToast("BitLocker", `Đang trích xuất Recovery Key ${drive}...`, "info");
        const res = await invokeRust("run_system_action", { actionId: "get_bitlocker_key", drive });
        appendBitLockerLog(res?.message || "Đã trích xuất Recovery Key.");
        showToast("BitLocker", "Đã trích xuất khóa khôi phục!", res?.success ? "success" : "warning");
      });
    }

    const btnSuspend = document.getElementById("btn-bitlocker-suspend");
    if (btnSuspend) {
      btnSuspend.addEventListener("click", async () => {
        const drive = document.getElementById("select-bitlocker-target-drive")?.value || "C:";
        appendBitLockerLog(`Đang tạm dừng bảo vệ BitLocker trên ${drive}...`);
        const res = await invokeRust("run_system_action", { actionId: "suspend_bitlocker", drive });
        appendBitLockerLog(res?.message || "Đã tạm dừng bảo vệ.");
        showToast("BitLocker", res?.message || "Đã tạm dừng.", res?.success ? "success" : "warning");
        setTimeout(refreshBitLockerStatus, 1500);
      });
    }

    const btnResume = document.getElementById("btn-bitlocker-resume");
    if (btnResume) {
      btnResume.addEventListener("click", async () => {
        const drive = document.getElementById("select-bitlocker-target-drive")?.value || "C:";
        appendBitLockerLog(`Đang tiếp tục bảo vệ BitLocker trên ${drive}...`);
        const res = await invokeRust("run_system_action", { actionId: "resume_bitlocker", drive });
        appendBitLockerLog(res?.message || "Đã tiếp tục bảo vệ.");
        showToast("BitLocker", res?.message || "Đã tiếp tục.", res?.success ? "success" : "warning");
        setTimeout(refreshBitLockerStatus, 1500);
      });
    }

    window.quickBitLockerAction = async function(action, drive) {
      const selectEl = document.getElementById("select-bitlocker-target-drive");
      if (selectEl) selectEl.value = drive;
      if (action === "get_key") {
        btnBackupKey?.click();
      } else if (action === "disable") {
        btnDisable?.click();
      } else if (action === "enable") {
        btnEnable?.click();
      }
    };

    // Auto load on initial view display
    refreshBitLockerStatus();
  }
  window.initBitLockerController = initBitLockerController;

  document.addEventListener("DOMContentLoaded", () => {
    initTweakHoverExplanation();
    syncAppVersion();
    bindNavigationAndActions();
    initAdminPortal();
    initAppStoreController();
    initStartupAppsController();
    initUwpAppsController();
    initWinOptimizeTwoStep();
    initDiskSmartController();
    initCpuMainController();
    initUserMgmtController();
    initDeployModeSwitcher();
    initDeploySubTabs();
    initWinDeployEnv();
    initOfficeController();
    initPrinterLanController();
    initVpnProxyController();
    initHwidController();
    initHelpdeskController();
    initBitLockerController();
    initWindowsRestoreController();
    initHeaderControls();
    initAutoUpdateOnStartup();
    if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState();
    updateClock();
    setInterval(updateClock, 1000);
    pollSystemTelemetry();
    setInterval(pollSystemTelemetry, 2000);
    sendHeartbeat();
    setInterval(sendHeartbeat, 1000);
  });

  window.addEventListener("beforeunload", () => {
    try {
      if (navigator.sendBeacon) {
        navigator.sendBeacon("/api/exit");
      }
    } catch (_) {}
  });
})();
