# Two-Step Execution, Live Terminal Log, Full Admin & Fleet Telemetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hoàn thiện 4 tính năng cốt lõi cho VUONGTT Toolkit v20.5.909.111: (1) Quy trình 2 bước (Select -> Apply) mặc định bỏ chọn toàn bộ (0 app, 0 tweak); (2) Live Log Terminal hiển thị tiến trình tải %, cài đặt và chạy lệnh realtime; (3) Bảo đảm quyền Administrator toàn diện; (4) Admin Portal Fleet Monitor thống kê tổng số máy, Hostname, BIOS Serial, IP, OS, Last Seen.

**Architecture:** 
- Frontend SPA (`src-ui/index.html` & `src-ui/app.js`): Mặc định bỏ chọn toàn bộ checkbox (`checked=false`). Tích hợp giao diện Live Terminal Console trực quan dưới kho phần mềm và tối ưu Win. Bổ sung bảng giám sát máy trạm Fleet Monitor vào màn hình Admin Portal (`#view-admin-portal`).
- Backend Rust Host (`src-tauri/src/system_ops.rs`, `telemetry.rs`, `main.rs`): Cung cấp buffer ghi log tiến trình cài đặt realtime (`get_install_logs`, `clear_install_logs`). Tự động thu thập Hostname, BIOS Serial, Local IP, Windows OS và ghi nhận vào kho `src/Config/client_devices.json`. Xác thực quyền UAC Elevation Win32 và thực thi toàn bộ lệnh ngầm dưới token Administrator.

**Tech Stack:** Rust 1.99 Native, Win32 API, PowerShell Core Bridge, Tailwind CSS / Stitch Dark Mode (#0b1326), Inter & Fira Code Fonts.

**Spec:** Yêu cầu người dùng & Tiêu chuẩn Superpowers dự án VUONGTT Toolkit 2026.

## Global Constraints
- File nhị phân chính xuất ra phải là `E:\toolwindows\VUONGTT_Toolkit.exe`.
- Dung lượng file tối ưu < 2.0 MB.
- Thời gian mở ứng dụng < 0.3 giây, CPU chiếm dụng trung bình 0%.
- Toàn bộ checkbox mặc định BỎ CHỌN TOÀN BỘ (0 apps, 0 tweaks). Người dùng chủ động tick chọn rồi mới bấm "Áp Dụng / Cài Đặt".
- Mọi chức năng chạy lệnh Windows phải bảo đảm quyền Administrator (UAC token / `-ExecutionPolicy Bypass`).
- Tuyệt đối không tự ý `git push` lên GitHub khi chưa có lệnh rõ ràng từ người dùng (Quy tắc AGENTS.md).
- Tự động tăng version lên `v20.5.909.111` đồng bộ toàn bộ file phiên bản.

---

### Task 1: Mặc Định Bỏ Chọn & Quy Trình 2 Bước (Select -> Apply)

**Files:**
- Modify: `src-ui/index.html:1500-1930` (Màn hình Tối Ưu Win `view-win-optimize`)
- Modify: `src-ui/index.html:4500-4950` (Màn hình Kho Phần Mềm `view-soft-winget`)
- Modify: `src-ui/app.js`

**Interfaces:**
- Consumes: Thao tác click checkbox từ người dùng.
- Produces: Danh sách các AppId hoặc TweakId đã tick chọn gửi sang backend khi bấm nút "Áp Dụng / Cài Đặt".

- [ ] **Step 1: Xóa toàn bộ thuộc tính `checked=""` mặc định trong HTML**
  - Xóa toàn bộ `checked=""` tại tất cả các `<input class="app-checkbox" ...>` trong `view-soft-winget`.
  - Xóa toàn bộ `checked=""` tại tất cả các `<input data-preset="..." type="checkbox" ...>` trong `view-win-optimize`.
  - Cập nhật số badge mặc định hiển thị "Đã chọn: 0 ứng dụng" và "Đã chọn: 0 tinh chỉnh".

- [ ] **Step 2: Nâng cấp 9 Thao tác nhanh tại `view-win-optimize` sang cơ chế Chọn -> Áp dụng**
  - Mỗi thẻ thao tác nhanh có checkbox / toggle trạng thái chọn.
  - Nút bấm chính "Áp Dụng Các Tinh Chỉnh Đã Chọn" hiển thị số lượng mục đang chọn. Khi bấm, chỉ thực thi các mục đã tích chọn.

- [ ] **Step 3: Cập nhật JavaScript xử lý đếm và xác thực**
  - Nếu người dùng bấm "Cài Đặt" hoặc "Áp Dụng" mà số lượng chọn = 0: Hiển thị thông báo Toast cảnh báo "Vui lòng tick chọn ít nhất 1 mục để thực thi".
  - Cập nhật hàm `updateBadge()` đồng bộ trạng thái khi click chọn/bỏ chọn.

- [ ] **Step 4: Kiểm thử giao diện**
  - Mở trang xác nhận: 0 app được chọn sẵn, 0 tweak được chọn sẵn.
  - Chọn 2 app -> badge tăng lên 2 -> bấm cài đặt gửi đúng danh sách 2 app.

---

### Task 2: Live Log Terminal Cho Kho Phần Mềm & Tinh Chỉnh Hệ Thống

**Files:**
- Modify: `src-ui/index.html` (Thêm khối Terminal Console vào `view-soft-winget` và `view-win-optimize`)
- Modify: `src-ui/app.js` (Hàm ghi log realtime `appendLiveLog`, tự động autoscroll, nút Xóa/Copy log)
- Modify: `src-tauri/src/system_ops.rs` & `src-tauri/src/main.rs` (Đệm log in-memory và endpoint `get_install_log`)

**Interfaces:**
- Consumes: Output stdout/stderr và progress status từ quá trình cài đặt / tối ưu.
- Produces: Dòng log có màu (Xanh lá = Thành công, Xanh dương = Đang tải, Vàng = Đang cài, Đỏ = Lỗi) cuộn mượt mà.

- [ ] **Step 1: Thêm khung Live Terminal Console chuẩn Fluent OS Dark**
  - Đặt dưới bảng danh sách ứng dụng trong `view-soft-winget`:
    - Header: 3 chấm tròn macOS (Đỏ, Vàng, Xanh), tiêu đề "TERMINAL NHẬT KÝ CÀI ĐẶT THỜI GIAN THỰC", trạng thái "Auto-Scroll: ON".
    - Body: Khung nền `#060e20`, font monospace Fira Code / Consolas, chiều cao 180px, thanh cuộn tự động.
    - Cụm phím: "Xóa Log (Clear)", "Sao Chép (Copy)", "Dừng (Cancel)".
  - Đặt khung tương tự tại `view-win-optimize` để hiển thị tiến trình SFC, DISM, dọn rác, tinh chỉnh Registry.

- [ ] **Step 2: Xây dựng cơ chế Log Buffer trong Rust Backend**
  - Tạo `static LOG_BUFFER: Mutex<Vec<String>>` trong `system_ops.rs`.
  - Khi `install_apps` hoặc các lệnh tweak chạy, hàm `push_log(msg)` ghi dòng nhật ký kèm timestamp `[HH:mm:ss]`.
  - Thêm action `get_execution_logs` và `clear_execution_logs` trong `POST /api/rust-invoke`.

- [ ] **Step 3: Kết nối Frontend Polling & Stream Logs**
  - Trong `src-ui/app.js`: Khi bắt đầu cài đặt, khởi chạy vòng lặp polling 250ms lấy log mới nhất từ backend và append vào terminal body.
  - Tự động cuộn `terminalEl.scrollTop = terminalEl.scrollHeight`.

- [ ] **Step 4: Kiểm thử chức năng Live Log**
  - Chạy `cargo test` kiểm tra log buffer.
  - Thử nghiệm trên UI xác nhận dòng log xuất hiện mượt mà từng bước.

---

### Task 3: Bảo Đảm Quyền Administrator Toàn Diện Cho Mọi Tác Vụ

**Files:**
- Modify: `src-tauri/src/system_ops.rs`
- Modify: `src-tauri/src/main.rs`
- Modify: `src-ui/app.js`

**Interfaces:**
- Consumes: Win32 Token API / `OpenProcessToken` / `GetTokenInformation`.
- Produces: Xác nhận trạng thái UAC Elevation, bảo đảm 100% lệnh hệ thống được thực thi với quyền tối cao.

- [ ] **Step 1: Viết hàm kiểm tra quyền Administrator Win32 trong Rust**
  - Viết `pub fn is_admin_elevated() -> bool` sử dụng Windows API kiểm tra token elevation.
  - Bổ sung cờ `-ExecutionPolicy Bypass -NoProfile` và `CREATE_NO_WINDOW` cho toàn bộ các lệnh PowerShell con.

- [ ] **Step 2: Tự động Elevate hoặc Fallback nếu thiếu quyền**
  - Nếu phát hiện tiến trình chưa có quyền Admin, cung cấp action `request_admin_elevation` gọi `ShellExecuteW` với verb `runas`.
  - Hiển thị trên thanh Header của giao diện: Badge "Admin Privileges [Active]" màu xanh lá nếu đã elevated.

- [ ] **Step 3: Kiểm thử quyền hạn**
  - Viết test trong `system_ops.rs` xác thực việc khởi tạo tiến trình với cờ bypass quyền.

---

### Task 4: Admin Portal Fleet Monitor (Giám Sát Máy Trạm Đã Dùng Tool)

**Files:**
- Create: `src/Config/client_devices.json`
- Modify: `src-tauri/src/telemetry.rs` (Thu thập thông tin máy: Hostname, BIOS Serial, IP, OS, HWID)
- Modify: `src-tauri/src/system_ops.rs` (Ghi nhận heartbeat vào `client_devices.json`, bổ sung dữ liệu vào `admin_get_data`)
- Modify: `src-ui/index.html:7860-7970` (Giao diện Fleet Monitor trong `view-admin-portal`)
- Modify: `src-ui/app.js` (Render bảng máy trạm và thẻ tổng số máy)

**Interfaces:**
- Consumes: Thông tin phần cứng máy thực tế từ `telemetry.rs`.
- Produces: Dữ liệu JSON `devices: [{ hostname, serial, ip, os, last_seen, hwid }]` hiển thị lên Admin Portal.

- [ ] **Step 1: Viết test cho Động cơ Fleet Monitor trong Rust**
  - Test ghi nhận thiết bị mới vào `client_devices.json`.
  - Test cập nhật `last_seen` nếu thiết bị đã tồn tại (trùng BIOS Serial hoặc Hostname).

- [ ] **Step 2: Triển khai thu thập dữ liệu máy trạm trong `telemetry.rs` & `system_ops.rs`**
  - Lấy Hostname qua `COMPUTERNAME`.
  - Lấy BIOS Serial qua Registry `HKLM\HARDWARE\DESCRIPTION\System\BIOS\SystemSerialNumber` (0ms siêu tốc, không cần WMI).
  - Lấy Local IP qua UDP socket lookup nội bộ.
  - Lấy OS Caption qua Registry `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProductName`.
  - Ghi/cập nhật vào `src/Config/client_devices.json` và `%ProgramData%\VUONGTT_Toolkit\client_devices.json`.

- [ ] **Step 3: Bổ sung giao diện Fleet Monitor trong `view-admin-portal`**
  - Thẻ thống kê nổi bật:
    - `Tổng Số Máy Trạm`: Hiển thị số lượng máy lớn (e.g., `01 MÁY`, `08 MÁY`).
    - `Máy Đang Hoạt Động (Online)`: Trạng thái kết nối.
  - Bảng DataGrid danh sách máy trạm:
    - Cột 1: STT
    - Cột 2: Tên Máy (Hostname)
    - Cột 3: Số Serial (BIOS Serial)
    - Cột 4: Địa Chỉ IP
    - Cột 5: Hệ Điều Hành
    - Cột 6: Thời Gian Chạy Gần Nhất (Last Seen)
    - Cột 7: Trạng Thái / Thao Tác (Chi tiết HWID)

- [ ] **Step 4: Cập nhật `src-ui/app.js` nạp danh sách devices**
  - Trong `loadAdminData()`: Đọc `res.data.devices` và render trực quan vào DataGrid.

---

### Task 5: Nâng Version Lên `v20.5.909.111`, Biên Dịch & Kiểm Thử Toàn Diện

**Files:**
- Modify: `version.json`
- Modify: `MainWindow.xaml`
- Modify: `src/Program.cs`
- Modify: `AppUpdater.ps1`
- Modify: `VUONGTT_Toolkit.ps1`
- Modify: `src-tauri/Cargo.toml`
- Modify: `src-tauri/src/main.rs`
- Modify: `src-ui/index.html`

- [ ] **Step 1: Tăng số hiệu phiên bản lên `v20.5.909.111`**
  - Cập nhật đồng bộ trên toàn bộ 8 tệp tin của hệ thống.
  - Ghi nhận changelog chi tiết 4 tính năng mới vào `version.json`.

- [ ] **Step 2: Chạy kiểm thử tự động `cargo test`**
  - Xác nhận 100% unit tests trong `src-tauri` PASS.

- [ ] **Step 3: Biên dịch `VUONGTT_Toolkit.exe`**
  - Chạy `powershell -ExecutionPolicy Bypass -File .\Build-Rust-Exe.ps1`.
  - Xác nhận tạo thành công file thực thi `E:\toolwindows\VUONGTT_Toolkit.exe` dung lượng < 2.0 MB.
  - Kiểm tra smoke test `--smoke-test` và `--version`.

- [ ] **Step 4: Lưu commit cục bộ và KHÔNG `git push`**
  - Commit message: `feat(core): implement two-step execution, live terminal log, admin rights & fleet telemetry v20.5.909.111`.
  - Tuân thủ nghiêm ngặt quy tắc `AGENTS.md`.
