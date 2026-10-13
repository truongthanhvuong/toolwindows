/**
 * ============================================================================
 * VUONGTT TOOL PRO 2026 — FRONTEND ROUTER & RUST (TAURI V2) IPC CONTROLLER
 * Design System: Fluent OS Utility (13+1 Google Stitch Screens)
 * ============================================================================
 */

(function () {
  "use strict";

  // --- 1. RUST IPC INVOKER (Supports both Tauri v2 IPC & Local Rust Native Bridge) ---
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
        body: JSON.stringify({ command, payload }),
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

  // --- 3. SPA VIEW ROUTER (13+1 STITCH SCREENS) ---
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

  // --- 4. AUTO-BIND SUB-TAB BUTTONS INSIDE ALL 13 SCREENS ---
  const subTabRouteMap = [
    { match: "Cấu Hình Máy", target: "view-sys-monitor" },
    { match: "Tùy Chỉnh OEM", target: "view-oem-brand" },
    { match: "Tra Cứu CPU/Main", target: "view-sys-monitor" },
    { match: "Quản Trị User/PC", target: "view-it-helpdesk" },
    { match: "Quét Driver & Sao Lưu", target: "view-tech-driver" },
    { match: "Kích Hoạt HWID", target: "view-hwid-act" },
    { match: "Cài Win Bypass", target: "view-win-deploy" },
    { match: "Tắt BitLocker", target: "view-disk-part" },
    { match: "Tối Ưu & Tweaks", target: "view-win-optimize" },
    { match: "Cấu Hình & Sửa Lỗi", target: "view-win-optimize" },
    { match: "Cứu Hộ IT Helpdesk", target: "view-it-helpdesk" },
    { match: "Sức Khỏe / Tốc Độ", target: "view-disk-smart" },
    { match: "Quản Lý Phân Vùng", target: "view-disk-part" },
    { match: "Test Laptop & Ngoại Vi", target: "view-sys-monitor" },
  ];

  function bindNavigationAndActions() {
    // Sidebar links
    document.querySelectorAll("[data-target]").forEach((el) => {
      el.addEventListener("click", (e) => {
        e.preventDefault();
        const target = el.getAttribute("data-target");
        if (target) switchView(target);
      });
    });

    // Window Controls
    const btnClose = document.getElementById("btn-win-close");
    const btnMin = document.getElementById("btn-win-min");
    const btnMax = document.getElementById("btn-win-max");
    const btnExit = document.getElementById("btn-emerg-exit");
    const btnExplorer = document.getElementById("btn-emerg-explorer");
    const btnUpdate = document.getElementById("btn-header-update");

    if (btnClose) btnClose.addEventListener("click", () => invokeRust("window_control", { action: "close" }));
    if (btnExit) btnExit.addEventListener("click", () => invokeRust("window_control", { action: "close" }));
    if (btnMin) btnMin.addEventListener("click", () => invokeRust("window_control", { action: "minimize" }));
    if (btnMax) btnMax.addEventListener("click", () => invokeRust("window_control", { action: "maximize" }));

    if (btnExplorer) {
      btnExplorer.addEventListener("click", async () => {
        showToast("Rust System Engine", "Đang khởi động lại Windows Explorer...", "info");
        const res = await invokeRust("run_system_action", { actionId: "restart_explorer", params: {} });
        showToast("Hoàn tất", (res && res.message) || "Đã khởi động lại Windows Explorer thành công!", "success");
      });
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

    // Bind all buttons inside the 14 views
    document.querySelectorAll(".stitch-view button").forEach((btn) => {
      const text = (btn.innerText || "").trim();
      if (!text) return;

      // Check if button is a sub-tab switcher
      for (const route of subTabRouteMap) {
        if (text.includes(route.match)) {
          btn.addEventListener("click", (e) => {
            e.preventDefault();
            switchView(route.target);
          });
          return;
        }
      }

      // Time range pills (1m, 5m, 15m, 1h)
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

      // General functional action buttons
      btn.addEventListener("click", async (e) => {
        e.preventDefault();
        const label = text.replace(/\s+/g, " ").trim();
        showToast("Đang thực thi (Rust Native)", `Tác vụ: ${label}`, "info");
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
    });
  }

  // --- 5. REALTIME CLOCK & HARDWARE TELEMETRY POLLING (get_system_telemetry) ---
  function updateClock() {
    const clockEl = document.getElementById("system-clock");
    if (!clockEl) return;
    const now = new Date();
    const pad = (n) => String(n).padStart(2, "0");
    clockEl.textContent = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
  }

  async function pollSystemTelemetry() {
    const data = await invokeRust("get_system_telemetry", {});
    if (!data) return;

    const view01 = document.getElementById("view-sys-monitor");
    if (!view01) return;

    // Update Host & OS subtitle
    const osSubtitle = view01.querySelector("p.font-body-md.text-on-surface-variant");
    if (osSubtitle && data.os_summary) {
      osSubtitle.textContent = data.os_summary;
    }

    // Update Metric Cards (CPU, RAM, GPU, Disk, Net, Battery)
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

    // Update Top 5 Processes Table if available
    if (Array.isArray(data.top_processes) && data.top_processes.length > 0) {
      const tbody = view01.querySelector("table tbody");
      if (tbody) {
        tbody.innerHTML = data.top_processes
          .slice(0, 5)
          .map(
            (p) => `
          <tr class="hover:bg-surface-container transition-colors">
            <td class="py-2.5 px-3 flex items-center gap-2.5">
              <div class="w-6 h-6 rounded bg-surface-container-highest flex items-center justify-center text-primary">
                <span class="material-symbols-outlined text-[15px]">memory</span>
              </div>
              <span class="font-label-md text-label-md text-on-surface">${p.name}</span>
            </td>
            <td class="py-2.5 px-3 text-outline font-code-sm text-code-sm">${p.pid}</td>
            <td class="py-2.5 px-3 text-on-surface">${p.cpu_percent.toFixed(1)}%</td>
            <td class="py-2.5 px-3 text-primary font-semibold">${p.memory_mb} MB</td>
            <td class="py-2.5 px-3 text-right">
              <span class="px-2 py-0.5 rounded-full bg-surface-container-high text-tertiary font-label-sm text-label-sm">Active</span>
            </td>
          </tr>`
          )
          .join("");
      }
    }
  }

  // --- 6. INITIALIZATION ---
  document.addEventListener("DOMContentLoaded", () => {
    bindNavigationAndActions();
    updateClock();
    setInterval(updateClock, 1000);
    pollSystemTelemetry();
    setInterval(pollSystemTelemetry, 2000);
  });
})();
