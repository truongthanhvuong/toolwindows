# HyperLis Fluent UI Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the entire VUONGTT Toolkit UI to match the modern Fluent OS / HyperLis design across 14 views with soft blue/white frosted glass gradients, dual-language explanations, and author/donation customization (Trương Thanh Vương & MoMo).

**Architecture:** A single-page application (SPA) running in Edge WebView2 backed by Rust Tauri/native backend. The UI features a fixed 14-item sidebar, a top navigation bar with a quick action "Restart to apply changes" and settings icon, content areas styled with rounded cards and metric rings, and interactive right-hand explanation panels that show real-time English and Vietnamese descriptions for hovered/selected tweaks.

**Tech Stack:** HTML5, CSS3 / Tailwind CSS (customized for Fluent Mica & Frosted Glass aesthetic), JavaScript (ES6+ modular controller), Rust (Tauri native backend), PowerShell 5.1/7.

**Spec:** Derived directly from the 14 user-provided screenshots and confirmed design requirements.

## Global Constraints
- Target platform: Windows 10 & 11 (64-bit).
- Native executable: `E:\toolwindows\VUONGTT_Toolkit.exe`.
- Version bump: `v20.5.909.151` per AGENTS.md rules.
- Remote bootstrapper: `irm tinyurl.com/vuongwin | iex` downloads from `https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe`.
- Author credit: **Trương Thanh Vương**.
- Donation method: **MoMo** / VietQR with account name **TRƯƠNG THANH VƯƠNG**.
- Test pass rate: 100% (42/42 cargo tests, 71+ comprehensive audit tests).
- Automated git push upon successful local build.

---

### Task 1: Design Tokens & CSS Styling (Frosted Glass / Mica Gradient)
**Files:**
- Modify: `src-ui/index.html` (head style / tailwind configuration)
- Test: Syntax and style rendering verification

- [ ] **Step 1:** Define the CSS custom properties for the HyperLis theme:
  - Background gradient: `linear-gradient(135deg, #E0F2FE 0%, #EDE9FE 50%, #F0FDF4 100%)`
  - Glass cards: `rgba(255, 255, 255, 0.75)` with `backdrop-filter: blur(16px)` and subtle border `rgba(255, 255, 255, 0.6)`
  - Active tab indicator: pill background `rgba(255, 255, 255, 0.9)` with shadow and primary accent text
  - Accent colors: Sky Blue (`#0284C7`), Primary (`#0EA5E9`), Teal (`#14B8A6`)
  - Circular SVG progress rings for CPU, RAM, GPU
- [ ] **Step 2:** Verify CSS styles compile without syntax errors.

---

### Task 2: Reconstruct Main Shell, Topbar & 14-Tab Sidebar Navigation
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Build the App Shell:
  - Header: Logo rocket icon + "VUONGTT Toolkit", "↻ Restart to apply changes" button, Settings gear icon, Minimize, Maximize, Close.
  - Left Sidebar with 14 tabs:
    1. Dashboard (`view-dashboard`)
    2. General (`view-general`)
    3. Windows (`view-windows`)
    4. UWP Apps (`view-uwp-apps`)
    5. Startup Apps (`view-startup-apps`)
    6. Download (`view-download`)
    7. Cleaning (`view-cleaning`)
    8. Network (`view-network`)
    9. USB Boot (`view-usb-boot`)
    10. Hardware Info (`view-hardware-info`)
    11. Manage License (`view-manage-license`)
    12. Convert SKUs (`view-convert-skus`)
    13. Office Setup (`view-office-setup`)
    14. Extend Features (`view-extend-features`)
- [ ] **Step 2:** Wire sidebar click events in `src-ui/app.js` to switch views smoothly with active state highlights.

---

### Task 3: Build View 01 - Dashboard & System Performance
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Dashboard layout matching screenshot 1:
  - 3 Top quick link cards: Facebook, GitHub Repository, Website.
  - Performance Card: Real-time SVG circular gauges for CPU (%), RAM (%), and GPU (%) with model labels.
  - Storage & Drives Card: Visual progress bars for C:, D:, Google Drive G: with Optimize button.
  - Changelog Card: Scrollable list of version notes with "View All" link.
- [ ] **Step 2:** Hook real-time telemetry loop in `app.js` to update gauges and drive capacities.

---

### Task 4: Build View 02 - General (Settings, Author: Trương Thanh Vương & MoMo Donation)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement General Settings layout matching screenshot 14:
  - Language selection dropdown (English / Tiếng Việt).
  - Check for updates card with "Check Update" button and version details.
  - About VUONGTT Toolkit section.
  - **About us**: "Developed by Trương Thanh Vương".
  - **Donation Section**: VietQR & MoMo payment card for **TRƯƠNG THANH VƯƠNG**.
- [ ] **Step 2:** Wire update check and language switch logic in `app.js`.

---

### Task 5: Build View 03 - Windows Tweaks & Dual-Language Explanation Panel
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Windows Tweaks layout matching screenshot 2:
  - Category groupings: System, Privacy, Gaming, Power Plan, Windows Update.
  - Switch toggles for each tweak.
  - Right-hand side panel showing live "Description:" (English) and "Mô tả:" (Vietnamese) when hovering or selecting toggles.
- [ ] **Step 2:** Connect toggle events in `app.js` to invoke existing Rust system tweak actions.

---

### Task 6: Build View 04 - UWP Apps (Bloatware Removal)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Bloatware Removal layout matching screenshot 3:
  - 3 Quick preset cards: Safe (27 apps), Recommended (44 apps), Aggressive (65 apps).
  - Expert Mode toggle (Unlock System Apps).
  - Search bar + Grid/List view toggle.
  - App list table with checkboxes, icons, size, and category badge.
  - Right detail panel with selected app information and red "Uninstall" button.
  - Bottom action bar: selected count, estimated freed space, Export, Import, and "Uninstall Selected" button.
- [ ] **Step 2:** Wire selection presets and bulk uninstall IPC calls in `app.js`.

---

### Task 7: Build View 05 - Startup Apps
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Startup Manager layout matching screenshot 4:
  - Table of startup apps (Name, Location, Checkbox).
  - Action buttons: "Toggle Status", "Refresh", and "Hide system apps" checkbox.
  - Right-hand explanation panel.
- [ ] **Step 2:** Connect `get_startup_apps` and `toggle_startup_app` actions.

---

### Task 8: Build View 06 - Download (Categorized Software Store)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Download store layout matching screenshot 5:
  - Top action bar: Search input, "Install Selected", "Uninstall Selected", "Clear Selection", "Update All".
  - Categorized grids: AI Development (Antigravity, Claude Code, Cursor, Codex...), Browsers, Communications, Dev, Office, etc.
  - App cards with logo, name, description, "Installed" badge, and checkbox with `data-app-id`.
- [ ] **Step 2:** Verify click/install handlers trigger `install_apps` in backend.

---

### Task 9: Build View 07 - Cleaning (Windows, RAM & Browsers)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Cleaning layout matching screenshot 6:
  - Windows & RAM checkboxes: Temporary Files, Update Cache, BSOD Minidumps, System Restore, Error Reports, RAM Cache, Empty Recycle Bin, RAM Usage.
  - Browser cleaning: Browser selector (Chrome, Edge, Brave, Firefox) + Cache, Session, Cookies, Passwords, History checkboxes.
  - Action buttons: "Clean by VUONGTT", "Clean by Disk Cleanup", "Use both methods", "Optimize Drives".
  - Right-hand explanation panel.
- [ ] **Step 2:** Connect cleanup IPC commands.

---

### Task 10: Build View 08 - Network & Latency Diagnostics
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Network layout matching screenshot 7:
  - Network Adapter dropdown & DNS preset dropdown (Cloudflare, Google, Quad9, AdGuard, DHCP).
  - Action buttons: "Set DNS", "Flush DNS Cache", "Open Network Settings".
  - Optimization toggles: "Optimize Network", "Disable Wifi Sense", "Fix Wi-Fi automatically hidden".
  - Ping latency tester: Input, Ping button, log output area, Export button.
  - Network Information card: Status, SSID, Signal Strength, Link Speed, Session Data Usage, IP addresses.
  - Right-hand explanation panel.
- [ ] **Step 2:** Connect DNS switching and ping diagnostics in `app.js`.

---

### Task 11: Build View 09 - USB Boot & ISO Management
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement USB Boot layout matching screenshot 8:
  - USB drive selector + "Scan USB/Drive Again" button.
  - Windows version selector + custom ISO picker with Browse button.
  - "Start" action button.
  - "Get other ISO" dropdown & "Let's go" button.
  - Auxiliary management buttons: Download ISO only, Create Menu Boot only, Add ISO to existing USB, Restart to BIOS/UEFI, Fix WMIC.
  - Right-hand explanation panel.
- [ ] **Step 2:** Connect disk drive enumeration and ISO deployment routines.

---

### Task 12: Build View 10 - Hardware Info (Full Specs)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Hardware Info layout matching screenshot 9:
  - Top bar: "Detailed view" toggle, "Save .txt file", "Copy All".
  - Specs list: OS, CPU, RAM, Motherboard, Graphics, Disk Drives, Network Adapters, BIOS.
  - Right-hand explanation panel.
- [ ] **Step 2:** Connect hardware telemetry query (`collect_cpu_main_details`).

---

### Task 13: Build View 11 - Manage License (Windows & Office)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement License Manager layout matching screenshot 10:
  - Top status banner: Windows activation state, Retail/OEM status, Recheck Status.
  - License Information card: Channel, CID, Product Key, OEM Key, OS Edition, Version, Copy all info.
  - Activate Windows card: Product key input, Activate button, Check Status.
  - Backup & Restore Activation card: Backup License, Restore License.
  - Remove MAS card: Windows (Remove HWID, KMS, TSforce), Office (Remove Ohook, KMS, TSforce).
- [ ] **Step 2:** Wire license activation and cleanup scripts.

---

### Task 14: Build View 12 - Convert SKUs (Windows Edition Switcher)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement SKU Conversion layout matching screenshot 11:
  - Step 1: Current Windows Info card.
  - Step 2: Choose Windows Version (Windows 11, Windows 11 LTSC).
  - Step 3: Choose Target Edition (Home, Pro, Enterprise).
  - Step 4: Conversion Preview & Compatibility Check.
  - Step 5: Overview (Target, Arch, Method, Risk).
  - Step 6: Real-time Logs area with Clear Log & Convert Now buttons.
- [ ] **Step 2:** Connect edition conversion logic.

---

### Task 15: Build View 13 - Office Setup (ODT Configurator)
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Office Setup layout matching screenshot 12:
  - Architecture (64-bit / 32-bit), Update Channel dropdown.
  - Applications checkboxes with Quick Select buttons (Minimum, Recommended, Full, Unselect All).
  - Language dropdown, License Type (Volume / Retail).
  - Advanced options: Remove existing Office, Create Desktop Shortcut.
  - Configuration XML Live Preview with Copy button.
  - Configuration Overview & Install / Download Action buttons.
- [ ] **Step 2:** Connect `install_office` action in backend.

---

### Task 16: Build View 14 - Extend Features
**Files:**
- Modify: `src-ui/index.html`
- Modify: `src-ui/app.js`

- [ ] **Step 1:** Implement Extend Features layout matching screenshot 13:
  - System: End task in Taskbar, "Take Ownership" in Right click, "God Mode" in Right click, Vietnamese Time Format, Disable UAC, Disable BitLocker.
  - Add program to Right click: Program selector + Browse, Add, Remove, List added.
  - Reduce Latency: Open MSI Util v3, Open Timer Resolution.
  - Export / Import Driver from specific directory: Browse, Export, Import.
  - Right-hand explanation panel.
- [ ] **Step 2:** Connect extend features IPC actions.

---

### Task 17: End-to-End Testing, Audit Verification & Version Bump
**Files:**
- Modify: `tests/Test-ComprehensiveAllFeaturesAudit.Tests.ps1`
- Modify: `version.json`, `MainWindow.xaml`, `src/Program.cs`, `AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`
- Target: `v20.5.909.151`

- [ ] **Step 1:** Run `node -c src-ui/app.js` to ensure 0 syntax errors.
- [ ] **Step 2:** Run `cargo test --manifest-path src-tauri/Cargo.toml` to ensure 42/42 tests pass.
- [ ] **Step 3:** Run `tests/Test-ComprehensiveAllFeaturesAudit.Tests.ps1` and ensure 100% PASS.
- [ ] **Step 4:** Compile `VUONGTT_Toolkit.exe` via `Build-Exe.ps1 -TargetVersion "20.5.909.151"`.
- [ ] **Step 5:** Commit and `git push origin main`.
