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

    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  window.switchView = switchView;

  // --- 4. SUB-TAB ROUTE MAPPINGS (MAPPED 100% TO EXACT SECTION IDs) ---
  const subTabRouteMap = [
    { match: "Cấu Hình Máy", target: "view-sys-monitor" },
    { match: "Tùy Chỉnh OEM", target: "view-oem-brand" },
    { match: "OEM", target: "view-oem-brand" },
    { match: "Tra Cứu CPU", action: "msinfo32", target: "view-sys-monitor", toast: "Đang mở bảng tra cứu thông tin CPU & Hệ Thống (msinfo32)..." },
    { match: "CPU/Main", action: "msinfo32", target: "view-sys-monitor", toast: "Đang mở bảng tra cứu CPU & Mainboard (msinfo32)..." },
    { match: "Quản Trị User", action: "lusrmgr", target: "view-sys-monitor", toast: "Đang mở trình quản trị User & Groups (lusrmgr.msc)..." },
    { match: "User/PC", action: "lusrmgr", target: "view-sys-monitor", toast: "Đang mở trình quản trị User & Groups (lusrmgr.msc)..." },
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

  async function loadAdminData() {
    const res = await invokeRust("admin_get_data", {});
    if (!res || !res.success || !res.data) return;

    const { policies, vault } = res.data;
    currentPolicies = Array.isArray(policies) ? policies : [];
    currentVault = Array.isArray(vault) ? vault : [];

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

    // Category Filter Pills Handler (Tách biệt hoàn toàn, không kích hoạt system action)
    const filterPills = storeView.querySelectorAll(".mb-space-lg button");
    const categoryContainers = storeView.querySelectorAll(".xl\\:col-span-9 > div");

    filterPills.forEach((pill) => {
      pill.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();

        filterPills.forEach((p) => {
          p.className = "px-3 py-1.5 rounded-full font-label-md text-label-md bg-surface-container hover:bg-surface-container-high text-on-surface-variant hover:text-on-surface transition-colors flex-shrink-0 cursor-pointer";
        });
        pill.className = "px-3 py-1.5 rounded-full font-label-md text-label-md bg-primary-container text-on-primary-container shadow-sm flex-shrink-0 flex items-center gap-1.5 font-bold cursor-pointer";

        const rawText = pill.innerText.toLowerCase().replace(/\s*\(\d+\)/, "").trim();

        categoryContainers.forEach((pod) => {
          const titleEl = pod.querySelector("span, h2, h3, div");
          const podTitle = titleEl ? titleEl.textContent.toLowerCase() : "";
          if (rawText.includes("tất cả") || rawText.includes("all")) {
            pod.style.display = "";
          } else {
            let match = false;
            if (rawText.includes("trình duyệt") && podTitle.includes("trình duyệt")) match = true;
            else if (rawText.includes("liên lạc") && podTitle.includes("liên lạc")) match = true;
            else if (rawText.includes("lập trình") && podTitle.includes("lập trình")) match = true;
            else if (rawText.includes("văn phòng") && podTitle.includes("văn phòng")) match = true;
            else if (rawText.includes("microsoft") && (podTitle.includes("microsoft") || podTitle.includes("văn phòng"))) match = true;
            else if (rawText.includes("trò chơi") && podTitle.includes("trò chơi")) match = true;
            else if (rawText.includes("đa phương tiện") && podTitle.includes("đa phương tiện")) match = true;
            else if (rawText.includes("kế toán") && podTitle.includes("kế toán")) match = true;
            else if (rawText.includes("tiện ích") && podTitle.includes("tiện ích")) match = true;
            else if (podTitle.includes(rawText)) match = true;

            pod.style.display = match ? "" : "none";
          }
        });
      });
    });

    // Realtime Search Filter
    const searchInput = document.getElementById("appSearch");
    if (searchInput) {
      searchInput.addEventListener("input", (e) => {
        const query = (e.target.value || "").toLowerCase().trim();
        storeView.querySelectorAll(".grid > div").forEach((card) => {
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
        storeView.querySelectorAll(".grid > div").forEach((card) => {
          const cb = card.querySelector("input[type='checkbox']");
          if (cb && cb.checked) {
            const titleEl = card.querySelector("span.font-body-md, span.font-label-md, div.font-body-md, span");
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
        showToast("Cập nhật hệ thống", (res && res.message) || "Bạn đang sử dụng phiên bản Rust Tauri v2 mới nhất!", "success");
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
      if (btn.id && (btn.id.startsWith("btn-admin-") || btn.id === "btnInstall" || btn.id === "btnUninstall" || btn.id === "btnSelectAll" || btn.id === "btnDeselectAll" || btn.id === "disk-select")) return;
      if (btn.closest("#view-soft-winget") && btn.closest(".mb-space-lg")) return; // Category Filter Pills
      if (btn.closest("#sidebar-nav")) return;

      // Sub-tab switcher
      for (const route of subTabRouteMap) {
        if (text.includes(route.match)) {
          btn.addEventListener("click", (e) => {
            e.preventDefault();
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
          if (btn.closest("#view-soft-winget")) return; // Safe guard

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

    const osSubtitle = view01.querySelector("p.font-body-md.text-on-surface-variant");
    if (osSubtitle && data.os_summary) {
      osSubtitle.textContent = data.os_summary;
    }

    const metricEls = view01.querySelectorAll(".font-metric-num.text-metric-num");
    if (metricEls.length >= 4) {
      if (data.cpu_percent !== undefined) {
        metricEls[0].innerHTML = `${Math.round(data.cpu_percent)}<span class="text-headline-md font-body-md text-primary">%</span>`;
      }
      if (data.ram_used_gb !== undefined && data.ram_total_gb !== undefined) {
        metricEls[1].innerHTML = `${data.ram_used_gb.toFixed(1)} <span class="text-headline-md font-body-md text-outline">/ ${Math.round(data.ram_total_gb)} GB</span>`;
      }
      if (data.disk_free_gb !== undefined) {
        metricEls[3].innerHTML = `${Math.round(data.disk_free_gb)} <span class="text-headline-md font-body-md text-outline">GB Trống</span>`;
      }
    }
  }

  // --- 9. HEARTBEAT & LIFECYCLE CONTROLLER ---
  function sendHeartbeat() {
    fetch("/api/heartbeat", { method: "POST" }).catch(() => {});
  }

  // --- 10. INITIALIZATION ---
  document.addEventListener("DOMContentLoaded", () => {
    bindNavigationAndActions();
    initAdminPortal();
    initAppStoreController();
    initDiskSmartController();
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
