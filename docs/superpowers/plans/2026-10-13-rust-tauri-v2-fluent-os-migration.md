# VUONGTT Tool Pro 2026 — Rust (Tauri v2) & Fluent OS Utility UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi toàn diện công cụ **VUONGTT Tool Pro 2026** sang nền tảng **RUST (Tauri v2)** kết hợp 100% thiết kế giao diện **Fluent OS Utility (Dark Mode / Mica Accent - 13 Màn Hình)** từ bộ thiết kế Google Stitch (`E:\toolwindows\stitch_to_n_di_n_thi_t_k_ui (1)\stitch_to_n_di_n_thi_t_k_ui`).

**Architecture:**
1. **Frontend (`src-ui/`)**: Tích hợp nguyên bản 13 màn hình HTML/Tailwind CSS từ Google Stitch vào một Single-Page App Shell thống nhất:
   - **Top Window Titlebar cố định (`h-14`)**: 3 nút điều khiển cửa sổ (Close, Minimize, Maximize) hỗ trợ kéo thả cửa sổ (`data-tauri-drag-region`), Logo VUONGTT Tool Pro 2026, badge version, Admin Privileges `[Active]`, PRO Lifetime badge, đồng hồ thời gian thực (`#system-clock`), nút Cập nhật và User Profile.
   - **Persistent Left Sidebar (`w-72`)**: Chuyển đổi ngôn ngữ `VN/EN`, chuyển đổi giao diện `Tối / Sáng / Hệ thống`, 9 danh mục phân hệ chính (Core Modules) và 4 nút Thao tác khẩn cấp (`Dọn Dẹp`, `Cứu Hộ IT`, `Explorer`, `Thoát`).
   - **Main Content Router**: Chuyển đổi tức thì (0ms) giữa 9 màn hình chính và 4 màn hình sub-tab chuyên sâu (`Tùy Chỉnh OEM`, `Kích Hoạt HWID`, `Quản Lý Phân Vùng`, `Cứu Hộ IT Helpdesk`), giữ nguyên 100% cấu trúc DOM, class Tailwind và Material Symbols từ 13 file `code.html`.
2. **Backend Nhân Rust (`src-tauri/`)**:
   - **`telemetry.rs`**: Sử dụng crate `sysinfo` đọc trực tiếp từ Windows NT Kernel các thông số: CPU % & xung nhịp, RAM (Total/Used/App/Wired/Compressed), GPU, Disk (Free/Total/Read/Write), Network (Up/Down/Latency), Battery/Power và bảng Top Ứng Dụng Chiếm Tài Nguyên (PID, CPU%, RAM MB) với polling rate 1000ms siêu nhẹ.
   - **`commands.rs` & `ps_bridge.rs`**: Cung cấp hệ thống `#[tauri::command]` xử lý mọi nút bấm trên cả 13 màn hình:
     - Điều khiển cửa sổ (`window_close`, `window_minimize`, `window_toggle_maximize`).
     - Thực thi các tác vụ kỹ thuật Windows (Direct Deploy Win 11/10 & Bypass, Quét & Cài Driver PnP, Dọn rác / Compact OS / SFC / DISM / Tweaks, Cài đặt Office ODT, Sửa lỗi máy in 0x0000011b/709/7c & Share LAN, Đọc S.M.A.R.T ổ cứng & Phân vùng DiskPart, Cài phần mềm Winget/Direct CDN, Fake VPN/SOCKS5 Proxy, Đổi thông tin OEM Registry, Kích hoạt MAS HWID/Ohook, Cứu hộ IT Helpdesk khẩn cấp).
3. **Đóng gói (`Single Executable`)**: Biên dịch ra file thực thi `VUONGTT_Toolkit.exe` chạy độc lập trên máy khách mà không cần máy khách cài Rust hay Node.js.

**Tech Stack:**
- **Backend:** Rust 2021 Edition, Tauri v2 (`tauri`, `serde`, `serde_json`, `sysinfo`, `tokio`, `windows-sys`).
- **Frontend:** HTML5, Tailwind CSS (cấu hình chuẩn Fluent OS Utility `#0b1326`), Material Symbols Outlined, TypeScript / Vanilla JS Router kết nối `@tauri-apps/api`.

---

## Cấu Trúc Tệp Dự Kiến (File Structure)

```
e:\toolwindows\
├── src-ui/                              # Giao diện Fluent OS Utility (từ 13 màn hình Stitch)
│   ├── index.html                       # App Shell + 13 Views tích hợp + Tailwind Config chuẩn Stitch
│   ├── assets/                          # Font, Icons, Logo nội bộ
│   └── app.js                           # Router 13 màn hình + Realtime Telemetry + Tauri Invoke Bridge
├── src-tauri/                           # Nhân Rust (Tauri v2)
│   ├── Cargo.toml                       # Khai báo dependencies Rust
│   ├── build.rs                         # Tauri build script + Windows UAC Manifest
│   ├── tauri.conf.json                  # Cấu hình cửa sổ 1400x860, Frameless (decorations: false)
│   ├── capabilities/default.json        # Quyền Tauri v2 IPC & Window controls
│   └── src/
│       ├── main.rs                      # Entry point Rust
│       ├── lib.rs                       # Khởi tạo Tauri Builder & đăng ký Commands
│       ├── telemetry.rs                 # Đo lường phần cứng thời gian thực (sysinfo)
│       ├── system_ops.rs                # Các lệnh hệ thống (OEM, Tweaks, Printer, Network, Disk, Office, Winget)
│       └── ps_bridge.rs                 # Cầu nối chạy ngầm các module PowerShell cốt lõi (CREATE_NO_WINDOW)
└── tests/
    └── Test-RustTauriMigration.Tests.ps1 # Bộ kiểm thử tự động xác minh 13 màn hình & Rust Backend
```

---

## Danh Sách 13 Màn Hình Stitch Được Tích Hợp Nguyên Bản

| Mã View | Thư mục nguồn Stitch | Vai trò trong App |
| :--- | :--- | :--- |
| `view-sys-monitor` | `xem_c_u_h_nh_gi_m_s_t_h_th_ng/code.html` | **Màn 01 (Chính)**: Xem Cấu Hình & Giám Sát Hệ Thống (6 thẻ phần cứng + Top Apps + Donut RAM) |
| `view-oem-brand` | `t_y_ch_nh_oem_th_ng_hi_u_m_y/code.html` | **Màn 10 (Sub-tab của 01)**: Tùy Chỉnh OEM & Thương Hiệu Máy (9 Presets hãng + Live Preview) |
| `view-win-deploy` | `c_i_win_bypass_windows_11_10/code.html` | **Màn 02 (Chính)**: Cài Win & Bypass Windows 11/10 (Direct Deploy 3 bước, Bypass TPM/OOBE) |
| `view-tech-driver` | `ti_n_ch_k_thu_t_driver/code.html` | **Màn 03 (Chính)**: Tiện Ích Kỹ Thuật & Driver (Quét PnP, SDIO, 3DP, Sao lưu DISM) |
| `view-hwid-act` | `k_ch_ho_t_b_n_quy_n_s_hwid/code.html` | **Màn 11 (Sub-tab của 03)**: Kích Hoạt Bản Quyền Số HWID / Ohook / KMS38 + Console slmgr |
| `view-win-optimize`| `t_i_u_s_a_l_i_win/code.html` | **Màn 04 (Chính)**: Tối Ưu & Sửa Lỗi Win (1-Click Dọn rác, Compact OS, SFC/DISM, Bảng Tweaks) |
| `view-it-helpdesk` | `c_u_h_it_helpdesk_kh_n_c_p/code.html` | **Màn 13 (Sub-tab của 04 & Quick Action)**: Cứu Hộ IT Helpdesk & Khẩn Cấp (SAM Flush, Winsock, Remote Hub) |
| `view-office-m365` | `c_i_t_office_m365/code.html` | **Màn 05 (Chính)**: Cài Đặt Office M365 (ODT Engine, chọn ứng dụng Word/Excel/PPT, Console ODT) |
| `view-printer-lan` | `m_y_in_scan_lan/code.html` | **Màn 06 (Chính)**: Máy In, Scan & LAN (1-Click Fix 0x0000011b / 709 / 7c, Spooler, SMB Scan) |
| `view-disk-smart`  | `ph_n_v_ng_c_ng_smart/code.html` | **Màn 07 (Chính)**: Phân Vùng & Ổ Cứng SMART (Sức khỏe, Nhiệt độ, Bảng 10+ thuộc tính SMART) |
| `view-disk-part`   | `qu_n_l_ph_n_v_ng_a/code.html` | **Màn 12 (Sub-tab của 07)**: Quản Lý Phân Vùng Ổ Đĩa (Sơ đồ Sector EFI/C/D, Mở rộng C, MBR->GPT) |
| `view-soft-winget` | `kho_ph_n_m_m_winget/code.html` | **Màn 08 (Chính)**: Kho Phần Mềm & Winget (Cài đặt hàng loạt Silent qua Winget CLI / Direct CDN) |
| `view-vpn-proxy`   | `fake_vpn_socks5_proxy/code.html` | **Màn 09 (Chính)**: Fake VPN / SOCKS5 Proxy (Giám sát IP, Bản đồ Global Route Map, Proxy Switcher) |

---

## Các Bước Thực Thi Chi Tiết (Tasks)

### Task 1: Cài Đặt Rust Toolchain & Kiểm Tra Môi Trường Biên Dịch
- [ ] **Step 1**: Cài đặt `Rustup` (MSVC toolchain) tự động qua Winget hoặc trình cài đặt chính thức `rustup-init.exe -y`.
- [ ] **Step 2**: Xác minh `rustc --version` và `cargo --version` hoạt động 100%.

### Task 2: Viết Bộ Kiểm Thử TDD (`tests/Test-RustTauriMigration.Tests.ps1`) — RED Phase
- [ ] **Step 1**: Viết bộ kiểm thử tự động kiểm tra:
  - Sự tồn tại và cấu hình chuẩn của `src-tauri/Cargo.toml`, `src-tauri/tauri.conf.json`.
  - Sự tồn tại của toàn bộ 13 màn hình chức năng từ Stitch trong `src-ui/`.
  - Sự tồn tại của các Tauri Commands trong Rust (`get_system_telemetry`, `run_system_action`, `apply_oem_info`, `fix_printer_lan`, `install_winget_apps`, `set_proxy_config`, `window_control`...).
- [ ] **Step 2**: Chạy test xác nhận trạng thái **RED (FAIL)** trước khi viết code.

### Task 3: Xây Dựng Giao Diện `src-ui/` Từ 13 Màn Hình Google Stitch — GREEN Phase (UI)
- [ ] **Step 1**: Trích xuất tự động phần nội dung `<main>` của cả 13 file `code.html` trong thư mục `stitch_to_n_di_n_thi_t_k_ui` để giữ nguyên 100% thiết kế gốc, không sai lệch dù chỉ 1 class CSS.
- [ ] **Step 2**: Xây dựng App Shell (`src-ui/index.html`) với Top Header (nút Đóng/Thu nhỏ/Phóng to, đồng hồ thời gian thực, nút Cập nhật) và Left Sidebar (9 tab chính + 4 nút khẩn cấp + nút chuyển đổi Sáng/Tối & VN/EN).
- [ ] **Step 3**: Viết bộ định tuyến `src-ui/app.js` kết nối:
  - Chuyển đổi mượt mà giữa 9 tab Sidebar chính, 4 nút Thao tác khẩn cấp và các thanh Sub-tab bên trong (`Cấu Hình Máy <-> Tùy Chỉnh OEM`, `Tiện Ích Driver <-> Kích Hoạt HWID`, `Tối Ưu Win <-> Cứu Hộ IT`, `Ổ Cứng SMART <-> Quản Lý Phân Vùng`).
  - Cập nhật số liệu phần cứng thời gian thực (CPU%, RAM, Disk, Network, Battery, Top Processes) mỗi 1000ms từ nhân Rust.
  - Gắn sự kiện click cho toàn bộ các nút tác vụ trên cả 13 màn hình gọi xuống nhân Rust kèm thông báo trạng thái trực quan.

### Task 4: Xây Dựng Nhân Backend Rust (`src-tauri/`) — GREEN Phase (Rust Core)
- [ ] **Step 1**: Khởi tạo `src-tauri/Cargo.toml` và `src-tauri/tauri.conf.json` (cửa sổ `decorations: false`, kích thước `1440x900`, tiêu đề `VUONGTT Tool Pro 2026`).
- [ ] **Step 2**: Viết `src-tauri/src/telemetry.rs` dùng crate `sysinfo` thu thập CPU, RAM, Disk, Network, Hostname, OS Version, Uptime và Top 5 tiến trình ăn RAM/CPU nhiều nhất.
- [ ] **Step 3**: Viết `src-tauri/src/system_ops.rs` và `src-tauri/src/ps_bridge.rs` cung cấp các `#[tauri::command]` thực thi trực tiếp các chức năng kỹ thuật Windows (gọi ngầm với cờ `CREATE_NO_WINDOW = 0x08000000` không bao giờ hiện cửa sổ đen):
  - **Nhóm 01 & 10**: Benchmark nhanh, Xuất báo cáo DXDiag/JSON, Ghi thông tin OEM vào Registry `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation`.
  - **Nhóm 02**: Mount ISO, kiểm tra mã băm SHA256, tạo cấu hình Bypass TPM 2.0 / SecureBoot / RAM / OOBE.
  - **Nhóm 03 & 11**: Quét thiết bị PnP lỗi, trích xuất sao lưu Driver DISM, kích hoạt bản quyền số HWID / Ohook / KMS38, kiểm tra `slmgr /xpr`.
  - **Nhóm 04 & 13**: Dọn rác tạm, nén Compact OS, chạy SFC / DISM, áp dụng các Tweak tối ưu, Phá mật khẩu / Bật Admin ẩn / Reset Winsock / Mở khóa TaskMgr & Regedit / Mở công cụ Remote.
  - **Nhóm 05**: Tạo cấu hình XML và khởi chạy cài đặt Office M365 / 2024 qua ODT Engine.
  - **Nhóm 06**: Fix lỗi máy in `0x0000011b`, `0x00000709`, `0x0000007c`, khởi động lại Print Spooler, tạo thư mục Scan SMB.
  - **Nhóm 07 & 12**: Đọc thông số S.M.A.R.T vật lý, liệt kê phân vùng đĩa, kiểm tra 4K Alignment, sửa lỗi Bootloader EFI.
  - **Nhóm 08**: Cài đặt phần mềm hàng loạt qua `winget install --silent` hoặc tải trực tiếp CDN.
  - **Nhóm 09**: Kiểm tra IP Public & Ping, bật/tắt SOCKS5 / HTTP System Proxy trong Registry `Internet Settings`.

### Task 5: Kiểm Thử, Biên Dịch File EXE Độc Lập & Xác Thực
- [ ] **Step 1**: Chạy `cargo check` và `cargo test` trong `src-tauri` xác nhận code Rust biên dịch sạch 100% không lỗi.
- [ ] **Step 2**: Chạy bộ kiểm thử `tests/Test-RustTauriMigration.Tests.ps1` xác nhận **100% PASS (GREEN)**.
- [ ] **Step 3**: Biên dịch bản Release tạo file thực thi `VUONGTT_Toolkit.exe` (và cập nhật version lên `v20.5.909.93`), kiểm tra chạy thực tế trên máy.
