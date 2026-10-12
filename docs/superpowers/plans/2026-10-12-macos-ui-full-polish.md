# Kế Hoạch Nâng Cấp Toàn Bộ Giao Diện Theo Chuẩn Apple macOS (Hiệu Ứng, Phông Chữ & Bỏ macOS HIG)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Loại bỏ nhãn "macOS HIG" theo yêu cầu người dùng, đại tu toàn diện phông chữ SF Pro / Apple Typography, nâng cấp hệ thống hiệu ứng tương tác Apple (hover animation, card shadow lift, active capsule pill, toggle switch iOS) trên toàn bộ 10 trang chức năng, kiểm thử tự động, build EXE và git push.

**Architecture:** Chuẩn hóa toàn bộ Resource Dictionary XAML (`src/UI/MainWindow.xaml`) theo hệ thống thiết kế macOS Sequoia/Sonoma:
- Bảng màu Apple System Colors (`#007AFF`, `#34C759`, `#FF9500`, `#FF3B30`, `#5856D6`, `#AF52DE`).
- Hiệu ứng Triggers chuột (MouseOver, IsPressed) trên các thẻ Card, Nút bấm ActionBtn, Menu Sidebar và Sub-tabs.
- Chuẩn hóa phân cấp phông chữ Apple Typography Hierarchy trên toàn bộ ứng dụng.
- Cập nhật logic điều hướng màu sắc Sub-tabs trong `VUONGTT_Toolkit.ps1`.

**Tech Stack:** WPF (XAML), Triggers & Storyboards, PowerShell 5.1+, C# Compiler (csc.exe).

## Global Constraints

- Loại bỏ hoàn toàn chuỗi văn bản `macOS HIG`.
- Bảo toàn mã hóa UTF-8 BOM trên toàn bộ các tệp `.ps1`, `.xaml`, `.json`.
- Tự động tăng 1 số version cục bộ (`v20.5.909.92`) trên toàn bộ các tệp định danh.
- Biên dịch thành công `VUONGTT_Toolkit.exe` và chạy smoke test `--smoke-test`.
- Thực hiện `git push origin main` sau khi người dùng phê duyệt tiến trình theo đúng câu lệnh yêu cầu.

---

### Task 1: TDD RED Phase - Viết Bộ Test Kiểm Tra Chuẩn macOS Full Polish

**Files:**
- Create: `tests/Test-AppleMacOSFullPolish.Tests.ps1`

- [ ] **Step 1: Viết test suite kiểm tra các tiêu chí macOS Polish**
  - Kiểm tra `MainWindow.xaml` KHÔNG còn chứa chuỗi "macOS HIG".
  - Kiểm tra các Style controls đều dùng chuẩn phông chữ Apple.
  - Kiểm tra hiệu ứng hover Triggers trên ActionBtn, MenuBtn, SubTabCapsuleBtn.
  - Kiểm tra màu sắc kích hoạt chuẩn Apple trong `VUONGTT_Toolkit.ps1`.
- [ ] **Step 2: Chạy test và xác nhận kết quả RED**

---

### Task 2: TDD GREEN Phase (UI XAML) - Nâng Cấp Giao Diện, Phông Chữ & Hiệu Ứng Apple

**Files:**
- Modify: `src/UI/MainWindow.xaml`

- [ ] **Step 1: Xóa bỏ nhãn "macOS HIG" trong Sidebar Header**
  - Loại bỏ Border chứa `TextBlock Text="macOS HIG"`.
- [ ] **Step 2: Nâng cấp Styles & Hiệu Ứng Tương Tác Apple macOS**
  - Nâng cấp `ActionBtn` với Trigger `IsMouseOver` (nhẹ nhàng sáng màu, thêm viền mờ), `IsPressed` (hiệu ứng nhấn lún nhẹ).
  - Nâng cấp `MenuBtn` với Trigger `IsMouseOver` (nền capsule `#E5E7EB` bo góc 8px).
  - Nâng cấp `SubTabCapsuleBtn` thành chuẩn Apple Segmented Capsule: Bo góc 8px, khi Active dùng nền trắng tinh khiết `#FFFFFF` hoặc `#007AFF` kèm đổ bóng mờ.
  - Nâng cấp `ToggleSwitch` sang màu chuẩn iOS/macOS Switch (`#34C759` khi bật).
  - Nâng cấp `CardBorder` với bóng đổ mờ Ambient Shadow siêu mịn và hiệu ứng viền mờ.
  - Đồng bộ phông chữ Apple SF Typography cho toàn bộ CheckBox, RadioButton, FilterTabBtn, AppStoreCard, v.v.

---

### Task 3: TDD GREEN Phase (Controller Backend) - Đồng Bộ Màu Sắc Sub-Tabs Apple

**Files:**
- Modify: `VUONGTT_Toolkit.ps1`

- [ ] **Step 1: Cập nhật hàm chuyển đổi Sub-tab sang bảng màu Apple**
  - Thay thế các mã màu cũ cứng nhắc (`#B45309`, `#2563EB`) trong các sự kiện click sub-tab bằng màu xanh Apple (`#007AFF` hoặc Apple Active Capsule) và chữ trắng chuẩn mực.
- [ ] **Step 2: Chạy kiểm thử tự động xác nhận 100% tests PASS (GREEN)**

---

### Task 4: Tăng Version, Biên Dịch Exe, Kiểm Thử & Git Push

**Files:**
- Modify: `version.json`, `src/Program.cs`, `src/Core/AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`, `src/UI/MainWindow.xaml`
- Produce: `E:\toolwindows\VUONGTT_Toolkit.exe`

- [ ] **Step 1: Kiểm tra cú pháp AST & UTF-8 BOM**
- [ ] **Step 2: Nâng version v20.5.909.92 & Biên dịch `VUONGTT_Toolkit.exe`**
- [ ] **Step 3: Chạy smoke test và kiểm tra FileVersion**
- [ ] **Step 4: Commit Git & Git Push lên GitHub `origin main` theo yêu cầu**
