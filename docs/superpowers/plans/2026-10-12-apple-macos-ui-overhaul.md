# Nâng Cấp Toàn Bộ Giao Diện Theo Chuẩn Apple macOS (Activity Monitor / HIG) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chuyển đổi toàn diện giao diện VUONGTT Toolkit sang phong cách Apple macOS Human Interface Guidelines (Activity Monitor) theo hình ảnh mẫu tham chiếu: Window Chrome Traffic Lights (🔴 🟡 🟢), Sidebar Apple Capsule, Trang Tổng Quan Overview 6 Thẻ Phần Cứng Big Metrics + Chấm LED Matrix, và 3 Thẻ Phân Tích Chuyên Sâu (Donut RAM, Top Apps Memory & Energy).

**Architecture:** Sử dụng WPF XAML thuần kết hợp phong cách Apple HIG (Squircle CornerRadius 14-16px, bảng màu macOS Sonoma/Sequoia `#F5F5F7` & `#FFFFFF`, hiệu ứng bóng mờ siêu mịn). Tái sử dụng và nâng cấp các cơ chế thu thập Telemetry thời gian thực trong `VUONGTT_Toolkit.ps1` để đổ dữ liệu vào các thẻ chỉ số lớn (Big Bold Metrics), chỉ số phụ (Sub-metrics), thanh LED chấm và danh sách tiến trình tiêu thụ tài nguyên.

**Tech Stack:** WPF (XAML), PowerShell 5.1+, C# P/Invoke, WMI / CIM / PerformanceCounter.

**Spec:** Dựa trên ảnh tham chiếu `media_1791788615306_0e1e79c6.png` và thỏa thuận Brainstorming với người dùng.

## Global Constraints

- Bảo toàn mã hóa UTF-8 BOM trên toàn bộ các tệp `.ps1`, `.xaml`, `.json`.
- Tuyệt đối giữ nguyên toàn bộ 10 chuyên mục và các tính năng nghiệp vụ cốt lõi hiện có.
- Tự động tăng 1 số version cục bộ (`v20.5.909.91`) trên toàn bộ các tệp định danh (`version.json`, `MainWindow.xaml`, `src/Program.cs`, `VUONGTT_Toolkit.ps1`, `AppUpdater.ps1`).
- Biên dịch ra file `E:\toolwindows\VUONGTT_Toolkit.exe` và kiểm thử `--smoke-test` thành công.
- TUYỆT ĐỐI KHÔNG chạy lệnh `git push` lên GitHub (theo RULE trong AGENTS.md).

---

### Task 1: TDD RED Phase - Viết Bộ Test Cấu Trúc Giao Diện Apple macOS

**Files:**
- Create: `tests/Test-AppleMacOSDesign.Tests.ps1`

- [ ] **Step 1: Viết test suite kiểm tra sự hiện diện của các thành phần giao diện Apple macOS**
  - Kiểm tra 3 nút Traffic Lights macOS: `btnMacClose`, `btnMacMinimize`, `btnMacMaximize`.
  - Kiểm tra các thẻ Apple Metric: `cardAppleCpu`, `cardAppleMemory`, `cardAppleGpu`, `cardAppleDisk`, `cardAppleNetwork`, `cardAppleBattery`.
  - Kiểm tra các thành phần đồ thị và phân tích sâu: `cardAppleMemoryByType`, `cardAppleMemoryByApp`, `cardAppleEnergyByApp`.
  - Kiểm tra sự kiện click của các nút traffic lights trong `VUONGTT_Toolkit.ps1`.

- [ ] **Step 2: Chạy test và xác nhận kết quả FAIL (RED)**
  - Chạy: `powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-AppleMacOSDesign.Tests.ps1`
  - Kết quả mong đợi: FAIL do các controls chưa được định nghĩa trong XAML.

---

### Task 2: TDD GREEN Phase (UI XAML) - Thiết Kế Window Chrome & Trang Overview Chuẩn Apple

**Files:**
- Modify: `src/UI/MainWindow.xaml`

- [ ] **Step 1: Tích hợp cụm nút macOS Window Controls (Traffic Lights)**
  - Bổ sung 3 nút tròn: `btnMacClose` (`#FF5F56`), `btnMacMinimize` (`#FFBD2E`), `btnMacMaximize` (`#27C93F`) ở góc trên bên trái Sidebar.
  - Cập nhật Sidebar: Section headers mờ (`HARDWARE`, `SYSTEM`), Active pill capsule màu xanh Apple (`#007AFF`) với bo góc tròn 8-10px.
  - Thêm Sidebar footer hiển thị thông tin máy và thời gian hoạt động (Uptime).

- [ ] **Step 2: Xây dựng Dashboard Overview 6 Thẻ Phần Cứng Lớn**
  - **CPU Card**: Big metric `txtAppleCpuPercent` (ví dụ `58%`), sub-metrics: `txtAppleCpuUser`, `txtAppleCpuSystem`, `txtAppleCpuTemp`, thanh LED ma trận `barAppleCpuLed`.
  - **Memory Card**: Sub-title `txtAppleMemInUseOf`, Big metric `txtAppleMemUsedGb` (ví dụ `13.5 GB`), badge `! Elevated`, sub-metrics: `txtAppleMemApp`, `txtAppleMemWired`, `txtAppleMemCompressed`, thanh LED ma trận `barAppleMemLed`.
  - **GPU Card**: Sub-title `txtAppleGpuModel`, Big metric `txtAppleGpuPercent` (ví dụ `42%`), sub-metrics: `txtAppleGpuVram`, `txtAppleGpuAvg`, `txtAppleGpuPeak`, thanh LED ma trận `barAppleGpuLed`.
  - **Disk Card**: Sub-title `txtAppleDiskFreeOf`, Big metric `txtAppleDiskFreeGb` (ví dụ `26.8 GB`), sub-metrics: `txtAppleDiskReadSpeed`, `txtAppleDiskWriteSpeed`, `txtAppleDiskWrittenTotal`, thanh LED ma trận `barAppleDiskLed`.
  - **Network Card**: Sub-title `Downloading`, Big metric `txtAppleNetDownSpeed` (ví dụ `1.02 KB/s`), sub-metrics: `txtAppleNetUpSpeed`, `txtAppleNetReceived`, `txtAppleNetSent`, thanh LED ma trận `barAppleNetLed`.
  - **Battery/Power Card**: Sub-title `txtApplePowerState` (On Battery / AC Power), Big metric `txtAppleBatteryPercent` (ví dụ `83%`), sub-metrics: `txtAppleBatteryRemaining`, `txtApplePowerDraw`, `txtAppleBatteryHealth`, thanh LED ma trận `barAppleBatteryLed`.

- [ ] **Step 3: Xây dựng 3 Thẻ Phân Tích Chuyên Sâu**
  - **Memory by Type**: Donut chart % RAM đã sử dụng + legend (App, Wired, Compressed, Cached, Free).
  - **Memory by App**: Danh sách các tiến trình tiêu thụ RAM hàng đầu kèm icon và dung lượng GB/MB.
  - **Energy by App**: Danh sách tiến trình tiêu thụ CPU kèm thanh tiến trình mượt mà.

---

### Task 3: TDD GREEN Phase (Controller Backend) - Kết Nối Logic & Sự Kiện

**Files:**
- Modify: `VUONGTT_Toolkit.ps1`

- [ ] **Step 1: Xử lý sự kiện 3 nút Traffic Lights**
  - Gắn sự kiện `btnMacClose.Add_Click({ $window.Close() })`.
  - Gắn sự kiện `btnMacMinimize.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })`.
  - Gắn sự kiện `btnMacMaximize.Add_Click({ $window.WindowState = if ($window.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' } })`.

- [ ] **Step 2: Đổ dữ liệu giám sát thời gian thực vào các thẻ Apple**
  - Cập nhật hàm refresh telemetry để cập nhật các nhãn số lớn Big Metrics, các sub-metrics và thanh LED ma trận cho cả 6 thẻ phần cứng.
  - Cập nhật danh sách Top 5 ứng dụng ngốn RAM và Top 5 ứng dụng ngốn CPU vào 2 thẻ `Memory by App` và `Energy by App`.

- [ ] **Step 3: Chạy lại bộ test kiểm tra kết quả PASS (GREEN)**
  - Chạy `tests/Test-AppleMacOSDesign.Tests.ps1`.
  - Xác nhận 100% tests PASS.

---

### Task 4: Kiểm Tra Toàn Diện, Tăng Version & Biên Dịch Exe Local

**Files:**
- Modify: `version.json`, `src/Program.cs`, `src/Core/AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`, `src/UI/MainWindow.xaml`
- Produce: `E:\toolwindows\VUONGTT_Toolkit.exe`

- [ ] **Step 1: Kiểm tra cú pháp AST & UTF-8 BOM**
  - Chạy `tests/Fix-AllUtf8Bom.ps1`.
  - Chạy `tests/check_ast.ps1`.

- [ ] **Step 2: Nâng version v20.5.909.91 & Biên dịch file thực thi**
  - Chạy `Build-Exe.ps1` để tăng số phiên bản và biên dịch `VUONGTT_Toolkit.exe`.
  - Chạy `tests/verify_build.ps1` kiểm tra kích thước và số phiên bản file exe.
  - Chạy smoke test: `.\VUONGTT_Toolkit.exe --smoke-test`.

- [ ] **Step 3: Commit Git Cục Bộ (TUYỆT ĐỐI KHÔNG GIT PUSH)**
  - Git commit: `feat(ui): dai tu toan bo giao dien theo chuan apple macos activity monitor (v20.5.909.91)`.
