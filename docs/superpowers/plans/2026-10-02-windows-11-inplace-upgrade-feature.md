# Plan Thêm Tính Năng Nâng Cấp Windows 11 Mới Nhất (In-Place Upgrade - Không Mất Dữ Liệu)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bổ sung tính năng 1-click nâng cấp lên phiên bản Windows 11 mới nhất (24H2 / 25H2 / 26H2) theo phương pháp In-Place Upgrade, bảo toàn 100% dữ liệu, phần mềm, file cá nhân và bản quyền số, tự động Bypass triệt để kiểm tra TPM 2.0 / CPU / Secure Boot cho mọi cấu hình máy tính.

**Architecture:** 
- Xây dựng module lõi `src/Core/WindowsInPlaceUpgrade.ps1` phụ trách:
  1. Phát hiện thông tin hệ điều hành (`Get-VUONGTTCurrentWindowsInfo`).
  2. Kích hoạt chính sách Bypass phần cứng toàn diện vào Registry (`Enable-VUONGTTInPlaceUpgradeBypass`).
  3. Kiểm tra điều kiện tiên quyết (`Test-VUONGTTInPlaceUpgradeReadiness` - dung lượng ổ C: >= 20GB, kiến trúc x64, AC power).
  4. Khởi chạy tiến trình nâng cấp đè chuẩn Microsoft (`Start-VUONGTTInPlaceUpgrade`) với tham số `/auto upgrade /DynamicUpdate disable /compat ignorewarning /MigrateDrivers none`.
- Cập nhật danh mục bản cài đặt trong `src/Core/AutoWinDeployer.ps1` bổ sung Windows 11 26H2 / 24H2.
- Tích hợp nút điều khiển 1-click `btnInPlaceUpgradeWin11` trong `src/UI/MainWindow.xaml` và bộ xử lý sự kiện trong `VUONGTT_Toolkit.ps1`.
- Đảm bảo 100% lệnh thực thi qua `Start-VUONGTTAdminProcess` và đồng bộ Registry qua `Set-VUONGTTAdminRegistry`.

**Tech Stack:** Windows PowerShell 5.1, Windows Setup Host (`setupprep.exe` / `setup.exe`), In-Place Upgrade Engine, Win32 Registry Provider, WPF / XAML.

**Spec:** `docs/superpowers/plans/2026-10-02-windows-11-inplace-upgrade-feature.md`

## Global Constraints
- Tuân thủ quy tắc `AGENTS.md`: Tự động tăng 1 số version sau khi hoàn tất (`v20.5.909.84` -> `v20.5.909.85`), biên dịch `VUONGTT_Toolkit.exe` tại local, kiểm định `verify_build.ps1` và commit cục bộ (KHÔNG push git).
- Bảo toàn 100% chuẩn mã hóa UTF-8 BOM trên toàn bộ các tệp `.ps1`, `.json`, `.xaml`, `.cs`.
- TDD bắt buộc: Viết test kiểm định thất bại (RED) -> Nâng cấp mã nguồn (GREEN) -> Kiểm thử hồi quy toàn diện trước khi bàn giao.
- Tuyệt đối không để placeholder (TODO/TBD) trong mã nguồn production.

---

### File Structure & Trách Nhiệm Từng Thành Phần

```
e:\toolwindows\
├── src\
│   ├── Core\
│   │   ├── WindowsInPlaceUpgrade.ps1    [NEW] Module điều phối nâng cấp Windows In-Place (Bypass TPM, check dung lượng, mount ISO & build lệnh setup)
│   │   └── AutoWinDeployer.ps1          [MOD] Bổ sung danh mục Windows 11 26H2 / 24H2 mới nhất
│   └── UI\
│       └── MainWindow.xaml              [MOD] Thêm nút bấm 1-Click Nâng Cấp Windows 11 In-Place Upgrade
├── VUONGTT_Toolkit.ps1                  [MOD] Nạp module WindowsInPlaceUpgrade.ps1 và xử lý sự kiện btnInPlaceUpgradeWin11
└── tests\
    └── Test-WindowsInPlaceUpgrade.Tests.ps1 [NEW] Bộ kiểm thử TDD xác thực In-Place Upgrade & Bypass
```

---

### Task 1: Xây Dựng Module Lõi In-Place Upgrade (`WindowsInPlaceUpgrade.ps1`)

**Files:**
- Create: `src/Core/WindowsInPlaceUpgrade.ps1`
- Test: `tests/Test-WindowsInPlaceUpgrade.Tests.ps1`

**Interfaces:**
- `Get-VUONGTTCurrentWindowsInfo`: Trả về thông tin Windows hiện tại (Caption, BuildNumber, DisplayVersion, Architecture).
- `Enable-VUONGTTInPlaceUpgradeBypass`: Kích hoạt các cờ Bypass TPM/CPU/RAM trong `MoSetup` và `LabConfig`.
- `Test-VUONGTTInPlaceUpgradeReadiness`: Kiểm tra dung lượng ổ C (>= 20GB) và tính sẵn sàng của hệ điều hành.
- `Get-VUONGTTInPlaceUpgradeArguments`: Tạo chuỗi tham số chuẩn `/auto upgrade /DynamicUpdate disable /compat ignorewarning /MigrateDrivers none`.
- `Start-VUONGTTInPlaceUpgrade`: Mount ISO, tìm `setupprep.exe` hoặc `setup.exe`, và khởi chạy tiến trình nâng cấp bảo toàn dữ liệu.

- [ ] **Step 1: Viết test TDD kiểm định module In-Place Upgrade (RED phase)**
- [ ] **Step 2: Hiện thực module `src/Core/WindowsInPlaceUpgrade.ps1`**
- [ ] **Step 3: Chạy test Task 1 và xác nhận chuyển sang GREEN phase**

---

### Task 2: Cập Nhật Danh Mục Bản Cài Đặt Trong `AutoWinDeployer.ps1`

**Files:**
- Modify: `src/Core/AutoWinDeployer.ps1`
- Test: `tests/Test-WindowsInPlaceUpgrade.Tests.ps1`

- [ ] **Step 1: Bổ sung test kiểm định bản Windows 11 26H2 / 24H2 trong danh mục**
- [ ] **Step 2: Thêm entry `Win11_26H2_Latest` vào `Get-VUONGTTAutoWinEditions`**
- [ ] **Step 3: Chạy test Task 2 và xác nhận GREEN phase**

---

### Task 3: Bổ Sung Nút Bấm 1-Click Vào Giao Diện XAML (`MainWindow.xaml`)

**Files:**
- Modify: `src/UI/MainWindow.xaml`
- Test: `tests/Test-WindowsInPlaceUpgrade.Tests.ps1`

- [ ] **Step 1: Bổ sung test kiểm tra sự hiện diện của control `btnInPlaceUpgradeWin11` trong XAML**
- [ ] **Step 2: Thêm nút bấm `btnInPlaceUpgradeWin11` tại khu vực công cụ AutoWin trong `MainWindow.xaml`**
- [ ] **Step 3: Chạy test Task 3 và xác nhận GREEN phase**

---

### Task 4: Tích Hợp Xử Lý Sự Kiện Trong Core Launcher (`VUONGTT_Toolkit.ps1`)

**Files:**
- Modify: `VUONGTT_Toolkit.ps1`
- Test: `tests/Test-WindowsInPlaceUpgrade.Tests.ps1`

- [ ] **Step 1: Bổ sung test kiểm tra nạp module và bắt sự kiện `btnInPlaceUpgradeWin11`**
- [ ] **Step 2: Dot-source `src/Core/WindowsInPlaceUpgrade.ps1` và gắn logic click cho `btnInPlaceUpgradeWin11`**
- [ ] **Step 3: Chạy test Task 4 và xác nhận GREEN phase**

---

### Task 5: Kiểm Thử Hồi Quy Toàn Diện, Nâng Version, Biên Dịch Exe & Bàn Giao

**Files:**
- Modify: `version.json`, `src/Core/AppUpdater.ps1`, `src/Program.cs`, `src/UI/MainWindow.xaml`, `VUONGTT_Toolkit.ps1`
- Build: `VUONGTT_Toolkit.exe`

- [ ] **Step 1: Chạy `tests/Fix-AllUtf8Bom.ps1` đảm bảo UTF-8 BOM 100% file**
- [ ] **Step 2: Chạy `tests/check_ast.ps1` xác thực cú pháp PowerShell**
- [ ] **Step 3: Chạy toàn bộ 6 bộ test suites (bao gồm cả suite mới)**
- [ ] **Step 4: Nâng version lên `v20.5.909.85` và biên dịch bằng `Build-Exe.ps1`**
- [ ] **Step 5: Chạy `tests/verify_build.ps1` xác thực binary**
- [ ] **Step 6: Commit Git cục bộ (KHÔNG push remote per AGENTS.md)**
