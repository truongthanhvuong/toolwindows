# Rust Migration & 100% Feature Preservation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi file thực thi chính `VUONGTT_Toolkit.exe` sang nền tảng Rust Native (~1.7MB, 0% CPU, khởi động 100ms) thay thế hoàn toàn bản C# WPF bị lag máy, đồng thời bảo đảm 100% tính năng của toàn bộ 31 module nghiệp vụ hoạt động thực tế.

**Architecture:** Sử dụng kiến trúc Rust Native System Host (`src-tauri`) kết hợp Edge WebView2 App Mode hiển thị 15 màn hình Fluent OS Utility Dark Mode. Các tác vụ đo đạc phần cứng dùng Win32 C Native API (`telemetry.rs`). Các tác vụ hệ thống nhẹ chạy trực tiếp trong Rust Win32. Các tác vụ phức hợp nặng (Cài kho 254+ app, Kế toán HTKK/MISA, Office ODT AIO, Cứu hộ IT Helpdesk 547 sự cố, Máy in LAN, Phân vùng, BitLocker) được Rust kích hoạt ngầm qua background Core Bridge (`CREATE_NO_WINDOW`, `-NoProfile`) dẫn vào `src/Core/`.

**Tech Stack:** Rust 1.99, Cargo, Win32 API, PowerShell Core Modules (`src/Core/*.ps1`), Tailwind CSS / Stitch Fluent OS Utility Dark Mode (`src-ui/index.html` + `src-ui/app.js`).

**Spec:** `docs/superpowers/specs/2026-10-15-rust-migration-design.md`

## Global Constraints
- File nhị phân chính xuất ra phải là `E:\toolwindows\VUONGTT_Toolkit.exe`.
- Dung lượng file tối ưu < 2.0 MB.
- Thời gian mở ứng dụng < 0.3 giây, CPU chiếm dụng trung bình 0%.
- Toàn bộ 100% tính năng và nút bấm trên 15 màn hình phải kích hoạt lệnh Windows thật, tuyệt đối không để mockup text.
- Tuyệt đối không tự ý `git push` lên GitHub khi chưa có lệnh rõ ràng từ người dùng (Quy tắc AGENTS.md).
- Tự động tăng version lên `v20.5.909.110` đồng bộ toàn bộ file phiên bản.

---

### Task 1: Mở rộng Động cơ Rust Native System Operations (`system_ops.rs`)

**Files:**
- Modify: `src-tauri/src/system_ops.rs`
- Test: `src-tauri/src/system_ops.rs` (Unit tests `cargo test`)

**Interfaces:**
- Consumes: JSON payloads từ frontend `POST /api/rust-invoke` qua `run_system_action`, `install_apps`, `manage_local_user`.
- Produces: `(bool, String)` kết quả thực thi và thông điệp trạng thái cho UI.

- [ ] **Step 1: Viết test cho các action mới trong `system_ops.rs`**
Thêm unit tests trong `tests` module:
- `test_execute_tweak_actions`: kiểm tra `clean_winsxs`, `compact_os`, `optimize_gpu`, `disable_junk_services`, `toggle_fast_startup`, `sfc_dism`.
- `test_execute_dynamic_app_install`: kiểm tra sinh câu lệnh cài đặt động cho bất kỳ AppId nào từ `src/Core/SoftwareInstaller.ps1`.

- [ ] **Step 2: Chạy cargo test để xác nhận FAIL**
Run: `cargo test --manifest-path src-tauri/Cargo.toml test_execute_tweak_actions`
Expected: FAIL

- [ ] **Step 3: Triển khai mã nguồn trong `system_ops.rs`**
Bổ sung các bộ xử lý hành động thực tế:
1. Xử lý kho 254+ ứng dụng: Nếu app không nằm trong 12 app cơ bản, Rust tự động gọi PowerShell ngầm:
   `powershell -NoProfile -ExecutionPolicy Bypass -Command "& { . E:\toolwindows\src\Core\SoftwareInstaller.ps1; Install-VUONGTTApp -AppId '<id>' -PreferDirect:$true -AutoLaunch:$false }"`
2. Xử lý ứng dụng Kế toán: Gọi `Install-VUONGTTAccountingApp -AppId '<id>'` từ `src/Core/AccountingApps.ps1`.
3. Xử lý Tinh chỉnh chuyên sâu:
   - `clean_winsxs`: gọi `dism.exe /online /cleanup-image /startcomponentcleanup /resetbase`.
   - `compact_os`: gọi `compact.exe /CompactOS:always`.
   - `optimize_gpu`: kích hoạt Hardware Accelerated GPU Scheduling (`HwSchMode = 2`) & Game Bar.
   - `disable_junk_services`: vô hiệu hóa DiagTrack, dmwappushservice, SysMain (Superfetch).
   - `toggle_fast_startup`: bật/tắt `HiberbootEnabled`.
   - `sfc_dism`: chạy `dism.exe /online /cleanup-image /restorehealth` & `sfc.exe /scannow`.
4. Xử lý Cứu hộ IT Helpdesk 547 sự cố: Gọi `Invoke-VUONGTTTroubleshootFix -IssueId '<id>'` từ `src/Core/TroubleshootManager.ps1`.

- [ ] **Step 4: Chạy cargo test xác nhận PASS**
Run: `cargo test --manifest-path src-tauri/Cargo.toml`
Expected: 100% tests PASS.

- [ ] **Step 5: Commit task 1**
Run: `git commit -m "feat(rust-engine): wire 100% real system operations and core bridge in system_ops.rs"`

---

### Task 2: Hoàn thiện Bộ điều khiển Frontend IPC (`src-ui/app.js` & `src-ui/index.html`)

**Files:**
- Modify: `src-ui/app.js`
- Modify: `src-ui/index.html`

- [ ] **Step 1: Rà soát và nối dây 100% nút bấm vào `runToolkitAction`**
- Đảm bảo tất cả các button trong các section `view-win-optimize`, `view-soft-winget`, `view-office-m365`, `view-printer-lan`, `view-disk-smart`, `view-it-helpdesk` đều gọi `runToolkitAction(actionId, description)`.
- Cập nhật Terminal Console `log-console` in ra đúng tiến trình thực thi thời gian thực.

- [ ] **Step 2: Commit task 2**
Run: `git commit -m "feat(ui): connect all action triggers and terminal logging to rust backend"`

---

### Task 3: Cập nhật Kịch bản Biên dịch & Nâng Version `v20.5.909.110` (`Build-Rust-Exe.ps1`)

**Files:**
- Modify: `Build-Rust-Exe.ps1`
- Modify: `version.json`
- Modify: `src-tauri/Cargo.toml`
- Modify: `src-ui/index.html`
- Modify: `src/Program.cs`
- Modify: `VUONGTT_Toolkit.ps1`

- [ ] **Step 1: Cập nhật `Build-Rust-Exe.ps1`**
Tự động tăng version lên `v20.5.909.110` đồng bộ toàn bộ file.
Biên dịch Cargo release và xuất thẳng ra `E:\toolwindows\VUONGTT_Toolkit.exe`.

- [ ] **Step 2: Biên dịch và chạy smoke test**
Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Build-Rust-Exe.ps1`
Expected: Tạo thành công `VUONGTT_Toolkit.exe` dung lượng ~1.7 MB, smoke test PASS.

- [ ] **Step 3: Commit task 3**
Run: `git commit -m "chore(release): bump version to v20.5.909.110 and build primary rust executable"`

---

### Task 4: Kiểm thử Toàn diện & Xác thực (Verification)

**Files:**
- Test: `tests/Test-RustTauriMigration.Tests.ps1`
- Test: `tests/Test-RealHardwareTelemetry.Tests.ps1`

- [ ] **Step 1: Chạy kiểm thử tự động**
Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-RustTauriMigration.Tests.ps1`
Expected: 100% PASS.

- [ ] **Step 2: Đo kiểm hiệu năng thực tế**
Khởi chạy thử `VUONGTT_Toolkit.exe`, kiểm tra thời gian mở, CPU% (=0%), RAM (<40MB).

- [ ] **Step 3: Cập nhật task.md và báo cáo kết quả**
