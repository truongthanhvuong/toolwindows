# Project: VUONGTT Toolkit 2026 Restoration & Enhancement

## Architecture
- **Frontend**: HTML5/Tailwind/Vanilla JS in `src-ui/index.html` and `src-ui/app.js`.
- **Backend**: Rust Native embedded HTTP server in `src-tauri/src/main.rs`, system operations bridge in `src-tauri/src/system_ops.rs`, real-time telemetry engine in `src-tauri/src/telemetry.rs`.
- **Core Principle**: KEEP 100% EXISTING UI AND FEATURES INTACT, NEVER REMOVE ANY EXISTING TABS OR VIEWS, ONLY ADD AND FIX.
  - All 14 existing views (Dashboard, General, Windows, UWP Apps, Startup Apps, Download, Cleaning, Network, USB Boot, Hardware Info, Manage License, Convert SKUs, Office Setup, Extend Features) are 100% preserved.
  - Dedicated views and sidebar navigation items are added for Cài Windows, Backup Windows, Sửa Máy In LAN, IT Helpdesk (547 sự cố), Quản Trị BitLocker, and Bảng Gỡ Cài Đặt Sạch Sẽ.

## Code Layout
- `src-ui/index.html`: UI views, navigation sidebar, cards, and modal dialogs.
- `src-ui/app.js`: Frontend controllers, IPC caller `invokeRust`, event handlers.
- `src-ui/applications.json`: 428 software inventory definitions.
- `src-ui/uwp_presets.json`: UWP application metadata.
- `src/Data/TroubleshootDatabase.json`: 547 IT Helpdesk issue definitions.
- `src-tauri/src/main.rs`: TCP Loopback HTTP Server, static asset routing, JSON API endpoints.
- `src-tauri/src/system_ops.rs`: Win32 FFI & PowerShell bridge for system automation actions.
- `src-tauri/src/telemetry.rs`: Real-time hardware telemetry (CPU, RAM, Network, Disk).
- `tests/`: 76 automated PowerShell regression and feature audit test suites.
- `Build-Exe.ps1`: Version bump and release compilation pipeline.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | UTF-8 BOM Sanitation & Socket Timeout Fix | Strip BOM from `applications.json`, `uwp_presets.json`, and `TroubleshootDatabase.json`. Eliminate 3s socket timeout in `main.rs`, provide static route fallback for `applications.json`. | M1 | Survey 1, 2 |
| 2 | Instant 428 Apps Loading & Categorization | Load 428 apps immediately on Dashboard & Download tabs, render category pills, search real-time, smooth UI. | M1 | Survey 1, 2 |
| 3 | Fast UWP Apps Scanning & Multi-Uninstall | Eliminate 30s recursive directory scan in `collect_uwp_apps` (down to <0.3s), enable multi-select and clean uninstall. | M1 | Survey 1, 2 |
| 4 | Winget Installation & Uninstallation Schema Fix | Support both `"app"` and `"apps"` in `parse_selected_apps`, direct Winget CLI execution for dotted IDs, receive `"target"` in `uninstall_app`. | M1 | Survey 2 |
| 5 | Cài Windows Tab & Environment Detection | Detect virtual/physical environment, boot mode, TPM status (`detect_win_install_env`), ISO file dialog (`browse_iso`), mount and launch `setup.exe` with upgrade/clean mode. | M2 | Survey 1, 2 |
| 6 | Full Windows Bypass MoSetup & LabConfig | Apply TPM 2.0, SecureBoot, RAM, CPU bypass to both `LabConfig` and `MoSetup`. | M2 | Survey 1, 2 |
| 7 | Full Windows C: WIM Backup & Driver Export | Asynchronous DISM `/Capture-Image` backup to WIM file (`backup_full_windows`) and driver export to available storage drive (`export_drivers`). | M2 | Survey 1, 2 |
| 8 | Sửa Lỗi Máy In LAN (0x11b, 0x709) & SMB Scan | Full LAN printer fix with `RpcAuthnLevelEx = 0`, `RpcUseNamedPipeProtocol = 1`, and `RestrictDriverInstallationToAdministrators = 0`, SMB scan folder sharing (`share_scan_folder`), LAN IP scan (`scan_lan`). | M3 | Survey 1, 2 |
| 9 | IT Helpdesk 547 Sự Cố Rescue Tab | Embed `TroubleshootDatabase.json` statically via `include_str!`, search & filter 547 issues, 4 action buttons (Diagnose, Auto-Fix, Verify, Report). | M3 | Survey 1, 2 |
| 10 | Quản Trị BitLocker Tab | Full BitLocker management view: drive encryption table (C:, D:, E:...), Turn On, Turn Off (`manage-bde -off`), Unlock, Recovery Key backup. | M4 | Survey 1, 2 |
| 11 | Tối Ưu Windows & Power Plans | Super Lean Pro Edition 2026 hero card with Undo Engine, 5 power schemes (featuring 24/7 Never Sleep), real-time DNS changer, RAM cleaner. | M4 | Survey 1, 2 |
| 12 | Bảng Gỡ Cài Đặt Hàng Loạt Chuẩn (Registry Win32) | Detailed software table: App Name, Publisher, Version, Install Date, Size, individual checkboxes, Select All header checkbox, red `bg-red-600` uninstall button, safe sequential bulk uninstall. | M5 | Survey 1, 2 |
| 13 | Automated Test Suite 100% Pass | Fix test script syntax gotcha (`Test-DnsChanger.Tests.ps1`), verify all 76 suites in `Run-AllTests.ps1` pass 100%. | M6 | Survey 3 |
| 14 | Version Increment, Binary Build & Git Push | Auto-increment build version across 8 source files, compile `VUONGTT_Toolkit.exe` (1.5MB - 3.5MB), verify `--smoke-test` and `--version`, automated `git push origin main`. | M6 | Survey 3 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Backend IPC Core, 428 Apps & UWP Apps Fix | `src-tauri/src/main.rs`, `src-tauri/src/system_ops.rs`, `src-ui/app.js` | none | DONE |
| M2 | Restore Cài Windows & Backup Windows | `src-ui/index.html`, `src-ui/app.js`, `src-tauri/src/system_ops.rs` | M1 | DONE |
| M3 | Restore Sửa Máy In LAN & IT Helpdesk (547 Sự Cố) | `src-ui/index.html`, `src-ui/app.js`, `src-tauri/src/main.rs`, `src-tauri/src/system_ops.rs` | M1 | DONE |
| M4 | Restore Quản Trị BitLocker & Tối Ưu Windows | `src-ui/index.html`, `src-ui/app.js`, `src-tauri/src/system_ops.rs` | M1 | DONE |
| M5 | Restore Bảng Gỡ Cài Đặt Hàng Loạt | `src-ui/index.html`, `src-ui/app.js`, `src-tauri/src/system_ops.rs` | M1 | PLANNED |
| M6 | Test Suite Pass 100%, Version Bump, Build & Git Push | `tests/`, `version.json`, `Build-Exe.ps1`, `VUONGTT_Toolkit.exe` | M1, M2, M3, M4, M5 | PLANNED |

## Interface Contracts
### Frontend ↔ Backend IPC
- Endpoint: `POST /api/rust-invoke`
- Payload: `{"command": "<cmd_name>", "actionId": "<optional>", ...payload}`
- Response: `{"success": true|false, "data": <any>, "message": "<optional>"}`
- Static Asset Fallback: `GET /applications.json` and `GET /uwp_presets.json` serve embedded JSON strings directly with `200 OK` and `application/json`.
