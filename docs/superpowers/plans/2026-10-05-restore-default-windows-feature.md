# Windows Fresh Install State Restoration Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm chức năng khôi phục toàn bộ các chức năng, giao diện, dịch vụ và cấu hình hệ thống Windows trở về trạng thái nguyên bản như lúc mới cài Windows (Fresh Clean Install State), có nút chọn sẵn trên thanh Presets và nút thực thi 1-click dưới thanh công cụ.

**Architecture:** Bổ sung hàm lõi `Restore-VUONGTTDefaultWindows` trong `src/Core/SystemTweaks.ps1` có khả năng hoàn tác toàn diện 32+ tinh chỉnh, phục hồi Menu chuột phải Windows 11 gốc, ẩn đuôi file, ẩn file ẩn, khôi phục dịch vụ Windows, trả lại Power Plan Balanced mặc định, reset DNS về DHCP router; cập nhật `MainWindow.xaml` bổ sung nút `btnPresetDefaultWin` và `btnRestoreDefaultWin`; kết nối sự kiện trong `VUONGTT_Toolkit.ps1` kèm System Restore Point an toàn.

**Tech Stack:** C#, PowerShell 5.1 / 7+, Windows API (P/Invoke Registry, Service Control Manager, powercfg, Explorer shell), WPF XAML.

**Spec:** Yêu cầu người dùng: "thêm chức năng khôi phục các chức năng như lúc mới cài win và git push".

## Global Constraints

- Tuân thủ quy tắc Superpowers: TDD (RED -> GREEN), cập nhật `task.md`, phân tích tác động, xác thực thực tế.
- Tuân thủ `AGENTS.md`: Tự động nâng 1 build version (`v20.5.909.86` -> `v20.5.909.87`), biên dịch `VUONGTT_Toolkit.exe`.
- Thực hiện `git push origin main` sau khi người dùng yêu cầu trực tiếp.
- Giữ nguyên UTF-8 BOM trên toàn bộ tệp mã nguồn.

---

### Task 1: Thiết Kế Bộ Test TDD (RED Phase)

**Files:**
- Create: `tests/Test-RestoreDefaultWindows.Tests.ps1`

**Interfaces:**
- Consumes: `src/Core/SystemTweaks.ps1`, `src/UI/MainWindow.xaml`, `VUONGTT_Toolkit.ps1`
- Produces: Test suite kiểm tra hàm `Restore-VUONGTTDefaultWindows`, sự tồn tại của controls `btnPresetDefaultWin` và `btnRestoreDefaultWin`, và logic hoàn tác registry chuẩn.

- [ ] **Step 1: Viết test failing `tests/Test-RestoreDefaultWindows.Tests.ps1`**
- [ ] **Step 2: Chạy test để xác nhận FAIL (RED)**

---

### Task 2: Hiện Thực Hàm Lõi Khôi Phục Trong SystemTweaks.ps1

**Files:**
- Modify: `src/Core/SystemTweaks.ps1`

**Interfaces:**
- Consumes: `Set-VUONGTTAdminRegistry`, Win32 Registry paths
- Produces: `Restore-VUONGTTDefaultWindows -CreateRestorePoint -RestartExplorer`

- [ ] **Step 1: Thêm hàm `Restore-VUONGTTDefaultWindows` vào `SystemTweaks.ps1`**
- [ ] **Step 2: Đảm bảo hoàn tác đủ Explorer (Menu phải, ẩn đuôi file, ẩn file ẩn, Taskbar center, Bing search), Services (Windows Update, Telemetry, SysMain), Power Plans (Balanced), DNS (DHCP)**

---

### Task 3: Cập Nhật Giao Diện XAML & Kết Nối Sự Kiện

**Files:**
- Modify: `src/UI/MainWindow.xaml`
- Modify: `VUONGTT_Toolkit.ps1`

**Interfaces:**
- Consumes: `btnPresetDefaultWin`, `btnRestoreDefaultWin`, `Restore-VUONGTTDefaultWindows`
- Produces: Nút `🔄 Khôi Phục Gốc (Default)` tại UniformGrid Presets và nút `⏮️ Khôi Phục Như Lúc Mới Cài Win` tại thanh công cụ dưới cùng.

- [ ] **Step 1: Thêm `btnPresetDefaultWin` vào UniformGrid Presets (chuyển sang Columns=7) và `btnRestoreDefaultWin` vào thanh công cụ dưới cùng trong `MainWindow.xaml`**
- [ ] **Step 2: Gắn logic xử lý sự kiện trong `VUONGTT_Toolkit.ps1`**
- [ ] **Step 3: Chạy test `Test-RestoreDefaultWindows.Tests.ps1` xác nhận PASS (GREEN)**

---

### Task 4: Kiểm Thử Toàn Diện, Nâng Version, Biên Dịch & Git Push

**Files:**
- Modify: `version.json`
- Modify: `src/Program.cs`
- Modify: `src/UI/MainWindow.xaml`
- Modify: `src/Core/AppUpdater.ps1`
- Modify: `VUONGTT_Toolkit.ps1`
- Output: `VUONGTT_Toolkit.exe`

- [ ] **Step 1: Áp dụng UTF-8 BOM bằng `tests/Fix-AllUtf8Bom.ps1`**
- [ ] **Step 2: Chạy `tests/check_ast.ps1` và toàn bộ test suites**
- [ ] **Step 3: Nâng version lên `v20.5.909.87` và chạy `Build-Exe.ps1`**
- [ ] **Step 4: Chạy `tests/verify_build.ps1` xác thực binary mới**
- [ ] **Step 5: Commit Git cục bộ và chạy `git push origin main`**
