# Project: VUONGTT Toolkit 2026 Core Upgrades & Defect Remediation

## Architecture
- **Frontend UI**: Vanilla JavaScript (ES6+), HTML5, Tailwind CSS in `src-ui/index.html` and `src-ui/app.js`.
- **Backend IPC & Native Bridge**: Rust embedded HTTP Loopback server in `src-tauri/src/main.rs`, system execution engine in `src-tauri/src/system_ops.rs`, real-time telemetry in `src-tauri/src/telemetry.rs`.
- **Scripting Core**: PowerShell 5.1/7+ scripts in `src/Core/*.ps1` and `VUONGTT_Toolkit.ps1`.
- **Testing Track**: Opaque-box regression suites in `tests/*.Tests.ps1`, `Run-AllTests.ps1`, and native Rust tests via `cargo test`.
- **Core Principle**: PRESERVE 100% EXISTING UI AND FEATURES. Never remove or alter existing tabs, buttons, or functions. Only add new capabilities and repair defects.

## Code Layout
- `src-ui/index.html`: Views, navigation sidebar, modals (`#modal-admin-login`, `#modal-license-activation`), and global floating drawer (`#universal-log-drawer`).
- `src-ui/app.js`: Frontend controllers, `switchView` gatekeeper, `initGatekeeper`, `initUniversalLogDrawer`, `syncRealWinOptimizeState`.
- `src-tauri/src/main.rs`: TCP Loopback server, IPC routing for `check_pro_license`, `activate_pro_key`, `get_install_logs`, `clear_install_logs`.
- `src-tauri/src/system_ops.rs`: Anti-bypass blocking engine, registry/policy management, Windows Update toggle, file extension toggles, Bing search toggle, execution log buffer.
- `src/Core/LicenseManager.ps1`: Hardware ID generation, PRO license verification, key activation vault.
- `tests/`: 84+ automated PowerShell test suites.
- `Build-Exe.ps1`: Release compilation pipeline and synchronized 8-file version increment.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Anti-Bypass Registry Policies | Configure `HKLM\SOFTWARE\Policies\Google\Chrome\DnsOverHttpsMode = "off"` and `HKLM\SOFTWARE\Policies\Microsoft\Edge\DnsOverHttpsMode = "off"` with parent key auto-creation. | M1 | R1 (Survey 1) |
| 2 | Expanded Facebook/Messenger Domains | Expand `$domainMap['facebook']` to include 17 domains including `web.facebook.com`, `edge-chat.facebook.com`, `graph.facebook.com`, `messenger.com`, `www.messenger.com`, and CDN endpoints. | M1 | R1 (Survey 1) |
| 3 | Windows Firewall Outbound Rule | Add `VUONGTT_Block_Facebook` firewall rule blocking Meta CIDRs `31.13.0.0/16,157.240.0.0/16,129.134.0.0/16,185.60.216.0/22,57.144.0.0/14` at kernel WFP level. | M1 | R1 (Survey 1) |
| 4 | Socket Termination & DNS Flush | Terminate browser processes (`chrome, msedge, brave, opera`) to sever persistent HTTP/2 & QUIC sockets, flush DNS via `ipconfig /flushdns` & `Clear-DnsClientCache`. | M1 | R1 (Survey 1) |
| 5 | Clean Unblock & Restoration | Revert hosts file, remove registry policies, delete firewall rules, flush DNS caches, and restart browser processes. | M1 | R1 (Survey 1) |
| 6 | Navigation & Action Gatekeeper | Integrate access control in `switchView` matching canonical Policy IDs; intercept unauthorized calls based on PRO and ADMIN tiers. | M2 | R2 (Survey 2) |
| 7 | PRO License Verification & Modal | Add `#modal-license-activation` in UI; backend endpoints `check_pro_license` and `activate_pro_key` hooking `LicenseManager.ps1`; immediate unlock via `pendingGatekeeperTarget`. | M2 | R2 (Survey 2) |
| 8 | ADMIN Authentication Gatekeeper | Enforce Admin Login modal when navigating to ADMIN-tier views or actions; grant full access once authenticated (`isAdminAuth = true`). | M2 | R2 (Survey 2) |
| 9 | Startup Policy & License Sync | Initialize `currentPolicies` and `isProLicensed` on `DOMContentLoaded` via `initGatekeeper` so policies apply immediately to regular users. | M2 | R2 (Survey 2) |
| 10 | Universal Floating Log Drawer UI | Fixed collapsible/expandable drawer (`#universal-log-drawer`) at bottom right of screen, dark terminal theme, line badge, Auto-scroll, Copy, Clear buttons. | M3 | R3 (Survey 2) |
| 11 | Real-time Log Streaming Bridge | 800ms polling loop fetching `get_install_logs` via `invokeRust`, delta rendering, auto-expanding on action trigger, global `window.appendUniversalLog`. | M3 | R3 (Survey 2) |
| 12 | Classic Context Menu on Win 11 | Registry CLSID `{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32` toggle with safe explorer restart (`classic_context_menu` & `modern_context_menu`). | M4 | R4 (Survey 3) |
| 13 | 1-Click Windows Update Toggle | Stop & disable `wuauserv`, `UsoSvc`, `WaaSMedicSvc`, set Group Policy `NoAutoUpdate = 1`; complete restore sequence in `enable_windows_update`. | M4 | R4 (Survey 3) |
| 14 | Show / Hide File Extensions | Fix toggle event logic in `index.html`, add backend `hide_file_extensions` action, refresh Explorer shell. | M4 | R4 (Survey 3) |
| 15 | Disable Bing Search in Start Menu | Set `DisableSearchBoxSuggestions = 1` and `BingSearchEnabled = 0`; add `enable_bing_search`; add UI toggle in `view-win-optimize`. | M4 | R4 (Survey 3) |
| 16 | Opaque-Box E2E Test Suite | Comprehensive tests covering Tiers 1-4 for Anti-Bypass, Gatekeeper, Universal Log, and Win Tối Ưu Extensions. | M5 | Acceptance Criteria |
| 17 | Version Bump to v20.5.909.180 | Synchronized version bump across 8 files (`version.json`, `AppUpdater.ps1`, `Program.cs`, `MainWindow.xaml`, `VUONGTT_Toolkit.ps1`, `Cargo.toml`, `main.rs`, `index.html`). | M6 | AGENTS.md |
| 18 | Compilation & Automated Git Push | Compile `VUONGTT_Toolkit.exe`, verify smoke test, automated commit and `git push origin main`. | M6 | AGENTS.md |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Anti-Bypass Website/Game Blocker Engine | `src-tauri/src/system_ops.rs` | none | DONE |
| M2 | PRO & ADMIN Gatekeeper Implementation | `src-ui/index.html`, `src-ui/app.js`, `src-tauri/src/main.rs`, `src-tauri/src/system_ops.rs` | none | DONE |
| M3 | Universal Real-time Execution Log Drawer | `src-ui/index.html`, `src-ui/app.js`, `src-tauri/src/main.rs`, `src-tauri/src/system_ops.rs` | none | DONE |
| M4 | Windows Tối Ưu Extensions | `src-ui/index.html`, `src-ui/app.js`, `src-tauri/src/system_ops.rs` | none | DONE |
| M5 | E2E Testing Suite (Tiers 1-4) & Coverage Hardening | `tests/`, `TEST_READY.md` | M1, M2, M3, M4 | PLANNED |
| M6 | Release: Version Bump v20.5.909.180, Compile & Git Push | 8 version files, `Build-Exe.ps1`, `VUONGTT_Toolkit.exe` | M1, M2, M3, M4, M5 | PLANNED |

## Interface Contracts
### Gatekeeper & Policies Contract
- Endpoint: `POST /api/rust-invoke` with `{"command": "check_pro_license"}` -> `{"success": true, "data": {"is_pro": bool, "customer": string, "duration": string}}`
- Endpoint: `POST /api/rust-invoke` with `{"command": "activate_pro_key", "key": string}` -> `{"success": true|false, "message": string}`
- Frontend State: `window.currentPolicies = [...]`, `window.isProLicensed = bool`, `window.isAdminAuth = bool`.

### Universal Log Stream Contract
- Endpoint: `POST /api/rust-invoke` with `{"command": "get_install_logs"}` -> `{"success": true, "logs": [string, ...]}`
- Endpoint: `POST /api/rust-invoke` with `{"command": "clear_install_logs"}` -> `{"success": true, "message": "Logs cleared"}`
- Frontend Global: `window.appendUniversalLog(msg, level)` writes to drawer buffer immediately.

### Windows Tối Ưu Extensions Contract
- Actions: `classic_context_menu`, `modern_context_menu`, `disable_windows_update`, `enable_windows_update`, `show_file_extensions`, `hide_file_extensions`, `disable_bing_search`, `enable_bing_search`.
- State Query: `get_win_optimize_state` returns JSON with `windows_update_disabled: bool`, `show_ext: bool`, `classic_context: bool`, `bing_disabled: bool`.
