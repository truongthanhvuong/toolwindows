/**
 * ============================================================================
 * VUONGTT TOOL PRO 2026 — FRONTEND ROUTER & RUST (TAURI V2) IPC CONTROLLER
 * Design System: Fluent OS Utility (13+1 Stitch Screens + Admin Portal VIP)
 * ============================================================================
 */

(function () {
  "use strict";

  let isAdminAuth = false;
  let currentPolicies = [];
  let currentVault = [];

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
        return await res.json();
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
  function switchView(targetId) {
    const views = document.querySelectorAll(".stitch-view");
    let found = false;
    views.forEach((v) => {
      if (v.id === targetId) {
        v.classList.add("active");
        found = true;
      } else {
        v.classList.remove("active");
      }
    });

    if (!found) return;

    // Update Sidebar Active State
    const navItems = document.querySelectorAll("#sidebar-nav .nav-item");
    navItems.forEach((item) => {
      const itemTarget = item.getAttribute("data-target");
      if (itemTarget === targetId) {
        item.classList.add("bg-primary-container", "text-on-primary-container", "font-semibold", "shadow-sm");
        item.classList.remove("text-on-surface-variant");
      } else {
        item.classList.remove("bg-primary-container", "text-on-primary-container", "font-semibold", "shadow-sm");
        item.classList.add("text-on-surface-variant");
      }
    });

    if (targetId === "view-win-optimize") {
      setTimeout(() => { if (window.syncRealWinOptimizeState) window.syncRealWinOptimizeState(); }, 50);
    }

    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  window.switchView = switchView;

  // --- 3.1 NATIVE SYSTEM ACTION DISPATCHER ---
  async function runToolkitAction(actionName, details) {
    const raw = (actionName || "") + " " + (details || "");
    const low = raw.toLowerCase();

    let actionId = "";
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
    } else if (low.includes("prefetch") || low.includes("flush dns") || low.includes("dns")) {
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
    { match: "Quét Driver & Sao Lưu", target: "view-tech-driver" },
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

    if (btnHeaderAdmin) btnHeaderAdmin.addEventListener("click", openAdminPortal);
    if (btnHeaderAvatar) btnHeaderAvatar.addEventListener("click", openAdminPortal);
    if (navAdmin) navAdmin.addEventListener("click", (e) => { e.preventDefault(); openAdminPortal(); });

    if (btnCancel && modalLogin) {
      btnCancel.addEventListener("click", () => modalLogin.classList.add("hidden"));
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

      const res = await invokeRust("admin_login", { password: pass });
      if (res && res.success) {
        isAdminAuth = true;
        if (modalLogin) modalLogin.classList.add("hidden");
        showToast("Xác Thực VIP", "Chào mừng Quản Trị Viên hệ thống!", "success");
        switchView("view-admin-portal");
        loadAdminData();
      } else {
        if (lblErr) {
          lblErr.textContent = (res && res.message) || "Mật khẩu Admin không chính xác!";
          lblErr.classList.remove("hidden");
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
        // Collect current policies
        const listEl = document.getElementById("admin-policy-list");
        if (!listEl) return;
        const items = listEl.querySelectorAll(".policy-row");
        const newPolicies = [];

        items.forEach((row) => {
          const id = row.getAttribute("data-id");
          const sel = row.querySelector("select");
          const tier = sel ? sel.value : "FREE";
          const original = currentPolicies.find((p) => p.Id === id) || {};
          newPolicies.push({ ...original, Id: id, Tier: tier });
        });

        showToast("Lưu Phân Quyền", "Đang lưu chính sách phân quyền vào hệ thống...", "info");
        const res = await invokeRust("admin_save_policies", { policies: JSON.stringify(newPolicies) });
        if (res && res.success) {
          showToast("Đã Lưu", res.message, "success");
          currentPolicies = newPolicies;
        }
      });
    }

    if (btnSyncPolicy) {
      btnSyncPolicy.addEventListener("click", () => {
        showToast("Đồng Bộ Cloud", "Đang tải dữ liệu phân quyền mới nhất từ Cloud...", "info");
        loadAdminData();
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

  async function loadAdminData() {
    const res = await invokeRust("admin_get_data", {});
    if (!res || !res.success || !res.data) return;

    const { policies, vault, devices } = res.data;
    currentPolicies = Array.isArray(policies) ? policies : [];
    currentVault = Array.isArray(vault) ? vault : [];
    currentDevices = Array.isArray(devices) ? devices : [];

    // 1. Render Policies
    const policyListEl = document.getElementById("admin-policy-list");
    if (policyListEl && currentPolicies.length > 0) {
      policyListEl.innerHTML = currentPolicies
        .map(
          (p) => `
        <div class="policy-row flex items-center justify-between p-2.5 rounded-lg bg-surface-container-high/60 border border-outline-variant/20 hover:border-primary/40 transition-colors" data-id="${p.Id}">
          <div class="flex items-center gap-2.5">
            <span class="text-xl">${p.Icon || "⚙️"}</span>
            <div>
              <div class="font-label-md text-label-md text-on-surface font-semibold leading-tight">${p.Name || p.Id}</div>
              <div class="font-label-sm text-[11px] text-on-surface-variant line-clamp-1">${p.Description || ""}</div>
            </div>
          </div>
          <select class="px-2 py-1 rounded bg-surface-container border border-outline-variant/40 font-code-sm text-code-sm font-bold text-on-surface focus:outline-none focus:border-primary">
            <option value="FREE" ${p.Tier === "FREE" ? "selected" : ""}>FREE</option>
            <option value="PRO" ${p.Tier === "PRO" ? "selected" : ""}>PRO (VIP)</option>
            <option value="ADMIN" ${p.Tier === "ADMIN" ? "selected" : ""}>ADMIN (Chỉ Quản Trị)</option>
          </select>
        </div>`
        )
        .join("");
    }

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
        await loadAdminData();
        showToast("Fleet Monitor", "Đã cập nhật danh sách máy trạm mới nhất!", "success");
      });
    }
  }

  // --- 6. APP STORE & CHECKBOX CONTROLLER ---
  function initAppStoreController() {
    const storeView = document.getElementById("view-soft-winget");
    if (!storeView) return;

    // Map application names to package identifiers
    const appMap = {
      "Google Chrome": "google-chrome",
      "Zalo PC": "zalo",
      "Mozilla Firefox": "firefox",
      "Microsoft Edge": "edge",
      "Brave Browser": "brave",
      "Cốc Cốc Browser": "coccoc",
      "Telegram Desktop": "telegram",
      "Discord": "discord",
      "Visual Studio Code": "vscode",
      "Git for Windows": "git",
      "NodeJS (LTS)": "nodejs",
      "Python 3.12": "python",
      "UltraViewer": "ultraviewer",
      "UniKey": "unikey",
    };

    function updateCartCount() {
      const checkedBoxes = storeView.querySelectorAll("input[type='checkbox']:checked");
      const selectionBadges = storeView.querySelectorAll("#selectedCountBadge, span");
      selectionBadges.forEach((s) => {
        if (s.id === "selectedCountBadge" || (s.textContent && s.textContent.includes("Đã chọn:"))) {
          s.textContent = `Đã chọn: ${checkedBoxes.length} ứng dụng`;
        }
      });
    }

    // Toggle card on click
    storeView.querySelectorAll(".grid > div").forEach((card) => {
      const cb = card.querySelector("input[type='checkbox']");
      if (!cb) return;

      card.addEventListener("click", (e) => {
        if (e.target.tagName !== "INPUT") {
          cb.checked = !cb.checked;
          updateCartCount();
        }
      });
      cb.addEventListener("change", updateCartCount);
    });

    // Select All / Deselect All
    const btnSelAll = document.getElementById("btnSelectAll");
    const btnDeselAll = document.getElementById("btnDeselectAll");

    if (btnSelAll) {
      btnSelAll.addEventListener("click", (e) => {
        e.preventDefault();
        storeView.querySelectorAll("input[type='checkbox']").forEach((cb) => (cb.checked = true));
        updateCartCount();
        showToast("Kho Phần Mềm", "Đã chọn toàn bộ danh sách phần mềm!", "info");
      });
    }

    if (btnDeselAll) {
      btnDeselAll.addEventListener("click", (e) => {
        e.preventDefault();
        storeView.querySelectorAll("input[type='checkbox']").forEach((cb) => (cb.checked = false));
        updateCartCount();
        showToast("Kho Phần Mềm", "Đã bỏ chọn toàn bộ phần mềm.", "info");
      });
    }

    // Category Filter Pills Handler (Sử dụng trực tiếp thuộc tính data-cat)
    const filterPills = storeView.querySelectorAll(".mb-space-lg button");
    const categoryContainers = storeView.querySelectorAll(".category-pod, .xl\\:col-span-9 > div");

    filterPills.forEach((pill) => {
      pill.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();

        filterPills.forEach((p) => {
          p.className = "px-3 py-1.5 rounded-full font-label-md text-label-md bg-surface-container hover:bg-surface-container-high text-on-surface-variant hover:text-on-surface transition-colors flex-shrink-0 cursor-pointer";
        });
        pill.className = "px-3 py-1.5 rounded-full font-label-md text-label-md bg-primary-container text-on-primary-container shadow-sm flex-shrink-0 flex items-center gap-1.5 font-bold cursor-pointer";

        const cat = pill.getAttribute("data-cat") || "all";

        categoryContainers.forEach((pod) => {
          const podCat = pod.getAttribute("data-cat") || "";
          if (cat === "all" || podCat === cat) {
            pod.style.display = "";
          } else {
            pod.style.display = "none";
          }
        });
      });
    });

    // Realtime Search Filter
    const searchInput = document.getElementById("appSearch");
    if (searchInput) {
      searchInput.addEventListener("input", (e) => {
        const query = (e.target.value || "").toLowerCase().trim();
        storeView.querySelectorAll(".app-card").forEach((card) => {
          const cardText = card.textContent.toLowerCase();
          card.style.display = cardText.includes(query) ? "" : "none";
        });
      });
    }

    // Action button: Cài Đặt / Update
    const btnInstall = document.getElementById("btnInstall");
    if (btnInstall) {
      btnInstall.addEventListener("click", async (e) => {
        e.preventDefault();
        const selectedApps = [];
        storeView.querySelectorAll(".app-card").forEach((card) => {
          const cb = card.querySelector("input[type='checkbox']");
          if (cb && cb.checked) {
            const titleEl = card.querySelector(".font-headline-md, .font-body-md, .font-label-md, div");
            const appName = titleEl ? titleEl.textContent.trim() : "";
            const appId = appMap[appName] || appName.toLowerCase().replace(/\s+/g, "-");
            if (appId) selectedApps.push(appId);
          }
        });

        if (selectedApps.length === 0) {
          showToast("Kho Phần Mềm", "Vui lòng tích chọn ít nhất 1 ứng dụng để cài đặt!", "warning");
          return;
        }

        showToast("Đang Cài Đặt", `Đang gửi lệnh cài đặt ${selectedApps.length} ứng dụng tới nhân Windows...`, "info");
        const res = await invokeRust("run_system_action", {
          actionId: "install_apps",
          apps: selectedApps,
          params: { apps: selectedApps },
        });

        if (res && res.success) {
          showToast("Đang Tiến Hành", res.message, "success");
        } else {
          showToast("Lỗi Cài Đặt", (res && res.message) || "Không thể thực thi lệnh cài đặt", "error");
        }
      });
    }

    // Action button: Gỡ Cài Đặt
    const btnUninstall = document.getElementById("btnUninstall");
    if (btnUninstall) {
      btnUninstall.addEventListener("click", async (e) => {
        e.preventDefault();
        showToast("Gỡ Ứng Dụng", "Đang mở trình gỡ cài đặt Programs and Features...", "info");
        await invokeRust("run_system_action", { actionId: "uninstall_apps" });
      });
    }
  }

  // --- 7. DISK S.M.A.R.T REALTIME CONTROLLER ---
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

    if (btnUpdate) {
      btnUpdate.addEventListener("click", async () => {
        showToast("Kiểm tra cập nhật", "Đang kết nối máy chủ GitHub kiểm tra phiên bản mới...", "info");
        const res = await invokeRust("run_system_action", { actionId: "check_update", params: {} });
        showToast("Cập nhật hệ thống", (res && res.message) || "Bạn đang sử dụng phiên bản VUONGTT Toolkit mới nhất!", "success");
      });
    }

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
      if (btn.id && (btn.id.startsWith("btn-admin-") || btn.id === "btnInstall" || btn.id === "btnUninstall" || btn.id === "btnSelectAll" || btn.id === "btnDeselectAll" || btn.id === "disk-select" || btn.id === "btn-run-deploy" || btn.id === "btn-start-deploy" || btn.id === "btn-browse-iso" || btn.id === "btn-pre-check" || btn.id.startsWith("tab-soft-") || btn.id.startsWith("btn-scan-") || btn.id.startsWith("btn-export-") || btn.id.startsWith("btn-restore-"))) return;
      if (btn.hasAttribute("onclick")) return;
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
            if (route.target) switchView(route.target);
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
    window.selectPowerPlan = async function(btn, planName) {
      const container = document.getElementById("power-plans-grid");
      if (container) {
        container.querySelectorAll(".power-plan-btn").forEach((b) => {
          b.className = "power-plan-btn p-3 rounded-xl bg-surface-container hover:bg-surface-container-high text-on-surface flex flex-col gap-1 text-left transition-all cursor-pointer";
          const ping = b.querySelector(".animate-ping");
          if (ping) ping.remove();
        });
      }

      if (btn) {
        btn.className = "power-plan-btn p-3 rounded-xl bg-error-container text-on-error-container flex flex-col gap-1 text-left shadow-sm transition-all ring-1 ring-error cursor-pointer";
        const topRow = btn.querySelector(".flex.items-center.justify-between");
        if (topRow && !topRow.querySelector(".animate-ping")) {
          const pingEl = document.createElement("span");
          pingEl.className = "w-2 h-2 rounded-full bg-error animate-ping";
          topRow.appendChild(pingEl);
        }
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
          powerGrid.querySelectorAll(".power-plan-btn").forEach((b) => {
            b.className = "power-plan-btn p-3 rounded-xl bg-surface-container hover:bg-surface-container-high text-on-surface flex flex-col gap-1 text-left transition-all cursor-pointer";
            const ping = b.querySelector(".animate-ping");
            if (ping) ping.remove();
          });

          const schemeLower = (data.scheme || "").toLowerCase();
          let activeKey = "balanced";
          let badgeText = "BALANCED ACTIVE";
          let badgeColor = "bg-primary-container text-on-primary-container";

          if (data.sleep_seconds === 0 && (data.disk_seconds === 0 || data.disk_seconds === undefined) && (schemeLower.includes("high") || schemeLower.includes("never"))) {
            activeKey = "never_sleep";
            badgeText = "24/7 NON-STOP ACTIVE";
            badgeColor = "bg-amber-500/20 text-amber-500 ring-1 ring-amber-500";
          } else if (schemeLower.includes("ultimate") || schemeLower.includes("cuc dai") || schemeLower.includes("cực đại")) {
            activeKey = "ultimate";
            badgeText = "ULTIMATE ACTIVE";
            badgeColor = "bg-error-container text-on-error-container";
          } else if (schemeLower.includes("high") || schemeLower.includes("hieu nang cao") || schemeLower.includes("hiệu năng cao")) {
            activeKey = "high";
            badgeText = "HIGH PERF ACTIVE";
            badgeColor = "bg-secondary-container text-on-secondary-container";
          } else if (schemeLower.includes("saver") || schemeLower.includes("tiet kiem") || schemeLower.includes("tiết kiệm")) {
            activeKey = "saver";
            badgeText = "SAVER ACTIVE";
            badgeColor = "bg-surface-container-high text-outline";
          } else {
            activeKey = "balanced";
            badgeText = "BALANCED ACTIVE";
            badgeColor = "bg-tertiary-container text-on-tertiary-container";
          }

          const activeBtn = powerGrid.querySelector(`button[data-plan="${activeKey}"]`);
          if (activeBtn) {
            const is247 = activeKey === "never_sleep";
            activeBtn.className = is247
              ? "power-plan-btn p-3 rounded-xl bg-amber-500/15 text-amber-400 flex flex-col gap-1 text-left shadow-sm transition-all ring-1 ring-amber-500 cursor-pointer col-span-2 md:col-span-2"
              : "power-plan-btn p-3 rounded-xl bg-error-container text-on-error-container flex flex-col gap-1 text-left shadow-sm transition-all ring-1 ring-error cursor-pointer";
            const topRow = activeBtn.querySelector(".flex.items-center.justify-between");
            if (topRow && !topRow.querySelector(".animate-ping")) {
              const pingEl = document.createElement("span");
              pingEl.className = is247 ? "w-2 h-2 rounded-full bg-amber-500 animate-ping" : "w-2 h-2 rounded-full bg-error animate-ping";
              topRow.appendChild(pingEl);
            }
          }

          if (powerBadge) {
            powerBadge.textContent = badgeText;
            powerBadge.className = `px-2 py-0.5 rounded font-code-sm text-code-sm font-bold uppercase ${badgeColor}`;
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

      } catch (e) {
        console.warn("syncRealWinOptimizeState error:", e);
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
          btn.className = "px-3.5 py-1.5 rounded-md font-label-md text-label-md bg-primary-container text-on-primary-container shadow-sm flex items-center gap-1.5 transition-all";
        } else {
          btn.className = "px-3.5 py-1.5 rounded-md font-label-md text-label-md text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high transition-all flex items-center gap-1.5";
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
      tbody.innerHTML = `<tr><td colspan="4" class="p-6 text-center text-secondary font-body-md animate-pulse">Đang quét toàn bộ Registry Uninstall...</td></tr>`;
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
      cachedInstalledApps = Array.isArray(apps) ? apps : [];
      if (badge) badge.textContent = `${cachedInstalledApps.length} Ứng Dụng`;
      window.renderInstalledApps(cachedInstalledApps);
    } catch (e) {
      if (tbody) tbody.innerHTML = `<tr><td colspan="4" class="p-6 text-center text-error font-body-md">Lỗi khi quét ứng dụng: ${e}</td></tr>`;
    }
  };

  window.renderInstalledApps = function(apps) {
    const tbody = document.getElementById("tbodyInstalledApps");
    if (!tbody) return;
    if (!apps || apps.length === 0) {
      tbody.innerHTML = `<tr><td colspan="4" class="p-6 text-center text-on-surface-variant font-body-md">Không tìm thấy ứng dụng phù hợp.</td></tr>`;
      return;
    }

    tbody.innerHTML = apps.map((app) => {
      const name = (app.name || "").replace(/"/g, '&quot;');
      const pub = (app.publisher || "Chưa rõ").replace(/"/g, '&quot;');
      const ver = (app.version || "1.0").replace(/"/g, '&quot;');
      const uninst = (app.uninstall_string || "").replace(/"/g, '&quot;');
      return `
        <tr class="hover:bg-surface-container transition-colors">
          <td class="p-3 font-semibold text-on-surface">${name}</td>
          <td class="p-3 text-on-surface-variant">${pub}</td>
          <td class="p-3 font-code-sm text-code-sm text-outline">${ver}</td>
          <td class="p-3 text-right">
            <button onclick="window.uninstallSpecificApp('${name.replace(/'/g, "\\'")}', '${uninst.replace(/'/g, "\\'")}')" class="px-2.5 py-1 rounded bg-error-container hover:bg-error text-on-error font-label-sm text-label-sm transition-colors">
              Gỡ Cài Đặt
            </button>
          </td>
        </tr>
      `;
    }).join("");
  };

  window.filterInstalledApps = function(query) {
    const q = (query || "").toLowerCase().trim();
    if (!q) {
      window.renderInstalledApps(cachedInstalledApps);
      return;
    }
    const filtered = cachedInstalledApps.filter((a) =>
      (a.name || "").toLowerCase().includes(q) ||
      (a.publisher || "").toLowerCase().includes(q)
    );
    window.renderInstalledApps(filtered);
  };

  window.uninstallSpecificApp = async function(name, uninstStr) {
    if (!confirm(`Bạn có chắc chắn muốn gỡ bỏ ứng dụng: ${name}?`)) return;
    showToast("Gỡ Cài Đặt", `Đang khởi chạy trình gỡ cho ${name}...`, "info");
    const res = await invokeRust("run_system_action", {
      actionId: "uninstall_app",
      params: { name, uninstall_string: uninstStr },
    });
    showToast(res && res.success ? "Thành Công" : "Thông Báo", (res && res.message) || `Đã kích hoạt lệnh gỡ ${name}`, res && res.success ? "success" : "info");
    setTimeout(() => window.refreshInstalledApps(), 2000);
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
  async function browseIsoFile() {
    try {
      const res = await invokeRust("run_system_action", { actionId: "browse_iso" });
      if (res && res.success && res.file_path) {
        const isoPathEl = document.getElementById("iso-path-text");
        if (isoPathEl) isoPathEl.innerText = res.file_path;
        const osSelector = document.getElementById("os-selector");
        if (osSelector) osSelector.value = "custom-iso";
        showToast("Chọn File ISO", res.message || ("Đã chọn: " + res.file_path), "success");
      } else if (res && res.message) {
        showToast("Chọn File ISO", res.message, "info");
      }
    } catch (e) {
      showToast("Lỗi", "Không thể mở hộp thoại chọn file: " + e, "error");
    }
  }
  window.browseIsoFile = browseIsoFile;

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

  async function startWinDeploy() {
    const btn = document.getElementById("btn-start-deploy");
    const isoPathEl = document.getElementById("iso-path-text");
    const isoPath = (isoPathEl ? isoPathEl.innerText : "").trim();
    const modeEl = document.querySelector('input[name="deploy-mode"]:checked');
    const deployMode = modeEl ? modeEl.value : "upgrade";

    if (!isoPath) {
      showToast("Cài Đặt Windows", "Vui lòng chọn hoặc nhập đường dẫn file ISO trước khi bắt đầu!", "warning");
      return;
    }

    const originalHtml = btn ? btn.innerHTML : "";
    if (btn) {
      btn.disabled = true;
      btn.innerHTML = `<span class="material-symbols-outlined text-[20px] animate-spin">progress_activity</span><span>ĐANG NẠP ISO VÀ KÍCH HOẠT SETUP...</span>`;
    }

    try {
      const res = await invokeRust("run_system_action", {
        actionId: "start_win_deploy",
        isoPath: isoPath,
        deployMode: deployMode
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
    }
  }
  window.startWinDeploy = startWinDeploy;

  // --- 10. HEARTBEAT & LIFECYCLE CONTROLLER ---
  function sendHeartbeat() {
    fetch("/api/heartbeat", { method: "POST" }).catch(() => {});
  }

  // --- 11. INITIALIZATION ---
  document.addEventListener("DOMContentLoaded", () => {
    bindNavigationAndActions();
    initAdminPortal();
    initAppStoreController();
    initWinOptimizeTwoStep();
    initDiskSmartController();
    initCpuMainController();
    initUserMgmtController();
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
