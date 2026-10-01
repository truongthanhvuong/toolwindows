# Plan Nâng Cấp Toàn Bộ Tính Năng Chạy Quyền Administrator Khi Chạy Tool Bằng Quyền Administrator

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đảm bảo 100% tính năng, tác vụ nền, bộ cài đặt phần mềm, công cụ hệ thống và chỉnh sửa Registry trong VUONGTT Toolkit thực thi chuẩn quyền Administrator hệ thống (Full Elevated Token, System-wide Machine Scope, HKLM & Active Domain User Hive Propagation), triệt tiêu hoàn toàn hiện tượng hạ quyền, kẹt token Domain hoặc thay đổi chỉ lưu vào profile ảo của Administrator.

**Architecture:** Xây dựng Động cơ Điều phối Đặc quyền Quản trị Tập trung (`Start-VUONGTTAdminProcess` & `Set-VUONGTTAdminRegistry`), chuẩn hóa phạm vi cài đặt System-wide (`--scope machine`, `ALLUSERS=1`, `/ALLUSERS`), tự động đồng bộ Registry sang cả `HKLM` lẫn toàn bộ User SIDs đang hoạt động (`HKEY_USERS\S-1-5-21-*`), và củng cố toàn bộ 128 lời gọi `Start-Process` / System Tools với `-Verb RunAs` và đường dẫn tuyệt đối `System32`.

**Tech Stack:** Windows PowerShell 5.1, Win32 Shell API (ShellExecuteEx RunAs), Windows Security Principal Token, Registry Provider (HKLM, HKU, HKCU), WinGet Machine Scope, Windows Installer (MSI ALLUSERS=1), WPF / C# Launcher (requireAdministrator).

**Spec:** `docs/superpowers/plans/2026-10-01-full-administrator-execution-enforcement.md`

## Global Constraints
- Tuân thủ quy tắc `AGENTS.md`: Tự động tăng 1 số version sau khi hoàn tất, biên dịch `VUONGTT_Toolkit.exe` tại local, kiểm định `verify_build.ps1` và commit cục bộ.
- Bảo toàn 100% chuẩn mã hóa UTF-8 BOM trên toàn bộ các tệp `.ps1`, `.json`, `.xaml`, `.cs`.
- TDD bắt buộc: Viết test kiểm định thất bại (RED) -> Nâng cấp mã nguồn (GREEN) -> Kiểm thử hồi quy toàn diện trước khi bàn giao.
- Tuyệt đối không để placeholder (TODO/TBD) trong mã nguồn production.

---

### File Structure & Trách Nhiệm Từng Thành Phần

```
e:\toolwindows\
├── src\
│   └── Core\
│       ├── AdminSecurityManager.ps1     [NEW]  Động cơ quản lý đặc quyền Administrator tập trung (Start-VUONGTTAdminProcess, Set-VUONGTTAdminRegistry, Get-VUONGTTActiveUserSIDs)
│       ├── SoftwareInstaller.ps1        [MOD]  Cưỡng chế scope machine cho WinGet, MSI ALLUSERS=1, NSIS /ALLUSERS
│       ├── ConfigManager.ps1            [MOD]  Chuẩn hóa Open-VUONGTTLegacyPanel mở MMC/CPL với RunAs System32
│       ├── SystemTweaks.ps1             [MOD]  Đồng bộ Registry Tweaks sang HKLM và Active User SIDs (HKEY_USERS)
│       └── TroubleshootManager.ps1      [MOD]  Đảm bảo 100% lệnh chẩn đoán & khắc phục chạy dưới Token Admin cao nhất
├── VUONGTT_Toolkit.ps1                  [MOD]  Nạp AdminSecurityManager.ps1 và chuẩn hóa các nút Quick Actions RunAs
└── tests\
    └── Test-AdminExecutionEnforcement.Tests.ps1 [NEW] Bộ kiểm thử TDD xác thực thực thi quyền Administrator trên toàn hệ thống
```

---

### Task 1: Xây Dựng Module Quản Trị Đặc Quyền Tập Trung (`AdminSecurityManager.ps1`)

**Files:**
- Create: `src/Core/AdminSecurityManager.ps1`
- Test: `tests/Test-AdminExecutionEnforcement.Tests.ps1`

**Interfaces:**
- Consumes: Windows Security Identity, ProcessStartInfo, Registry Provider.
- Produces: 
  - `Test-VUONGTTIsAdmin`: Xác thực quyền Administrator thực tế của tiến trình.
  - `Start-VUONGTTAdminProcess`: Khởi chạy tiến trình con với đặc quyền Administrator (`-Verb RunAs`), WorkingDirectory an toàn, và cô lập lỗi.
  - `Get-VUONGTTActiveUserSIDs`: Lấy danh sách SIDs của các tài khoản người dùng đang đăng nhập (kể cả Domain Users) trong `HKEY_USERS`.
  - `Set-VUONGTTAdminRegistry`: Ghi đồng thời Registry vào `HKLM` (chính sách toàn máy) và toàn bộ User Hives đang hoạt động.

- [ ] **Step 1: Viết test TDD kiểm định các hàm của AdminSecurityManager**

```powershell
# tests/Test-AdminExecutionEnforcement.Tests.ps1 (Task 1 snippet)
$adminSecScript = Join-Path $rootDir "src\Core\AdminSecurityManager.ps1"
Assert-True (Test-Path $adminSecScript) "Tệp src\Core\AdminSecurityManager.ps1 phải tồn tại"
. $adminSecScript

$isAdmin = Test-VUONGTTIsAdmin
Assert-True ($null -ne $isAdmin) "Test-VUONGTTIsAdmin phải trả về giá trị boolean"

$sids = Get-VUONGTTActiveUserSIDs
Assert-True ($sids -is [array] -or $sids -is [System.Collections.IEnumerable]) "Get-VUONGTTActiveUserSIDs phải trả về danh sách SIDs"
```

- [ ] **Step 2: Chạy test để xác nhận trạng thái RED (Thất bại vì chưa tạo tệp)**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: FAIL

- [ ] **Step 3: Triển khai mã nguồn `src/Core/AdminSecurityManager.ps1`**
Định nghĩa các hàm:
- `Test-VUONGTTIsAdmin`: `([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)`
- `Start-VUONGTTAdminProcess`: Chuẩn hóa gọi `Start-Process` với `-Verb RunAs`, WorkingDirectory là `$env:WINDIR\System32`, và bắt ngoại lệ an toàn.
- `Get-VUONGTTActiveUserSIDs`: Duyệt `Get-ChildItem Registry::HKEY_USERS` lấy các SIDs bắt đầu bằng `S-1-5-21-` (loại trừ `_Classes`).
- `Set-VUONGTTAdminRegistry`: Ghi key vào `HKLM:\SOFTWARE\...` và duyệt từng SID trong `Registry::HKEY_USERS\$sid\Software\...` để người dùng Domain đang ngồi trước máy nhận ngay thiết lập.

- [ ] **Step 4: Chạy test để xác nhận trạng thái GREEN**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: PASS

- [ ] **Step 5: Áp dụng UTF-8 BOM và Commit Task 1**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Fix-AllUtf8Bom.ps1"`
Git commit: `feat(security): tich hop module AdminSecurityManager quan tri dac quyen administrator tap trung`

---

### Task 2: Chuẩn Hóa Cưỡng Chế Quyền Admin & Scope Machine Trong Cài Đặt Phần Mềm (`SoftwareInstaller.ps1`)

**Files:**
- Modify: `src/Core/SoftwareInstaller.ps1`
- Test: `tests/Test-AdminExecutionEnforcement.Tests.ps1`

**Interfaces:**
- Consumes: `AdminSecurityManager.ps1`
- Produces:
  - WinGet install/upgrade có thêm cờ `--scope machine` để cài đặt vào `C:\Program Files` thay vì `%LOCALAPPDATA%` của Admin.
  - MSI execution thêm thuộc tính `ALLUSERS=1` và `MSIINSTALLPERUSER=0`.
  - Inno Setup / NSIS installers thêm tham số `/ALLUSERS` khi chạy ngầm.
  - Bộ cài Zalo, Discord, Chrome... tự động tạo lối tắt Start Menu All-Users và Public Desktop.

- [ ] **Step 1: Viết test TDD kiểm định các tham số cài đặt của SoftwareInstaller**

```powershell
# tests/Test-AdminExecutionEnforcement.Tests.ps1 (Task 2 snippet)
$installerContent = Get-Content (Join-Path $rootDir "src\Core\SoftwareInstaller.ps1") -Raw -Encoding UTF8
$hasScopeMachine = $installerContent -match '--scope machine'
Assert-True $hasScopeMachine "Lệnh cài đặt WinGet phải sử dụng --scope machine để cài đặt cho toàn máy"

$hasMsiAllUsers = $installerContent -match 'ALLUSERS=1'
Assert-True $hasMsiAllUsers "Trình cài đặt MSI phải truyền cờ ALLUSERS=1"
```

- [ ] **Step 2: Chạy test xác nhận trạng thái**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: FAIL ở các mục chưa có cờ

- [ ] **Step 3: Triển khai cập nhật `src/Core/SoftwareInstaller.ps1`**
- Trong `$runWingetInstall`:
  `$arg = "install --id `"$($app.WingetId)`" -e --silent --scope machine --accept-package-agreements --accept-source-agreements --disable-interactivity --force"`
- Trong `$runDirectInstall`:
  Nếu là tệp `.msi`: gọi `msiexec.exe /i "$destFile" ALLUSERS=1 MSIINSTALLPERUSER=0 /qn /norestart`.
  Nếu là Inno Setup / NSIS: bổ sung tham số `/ALLUSERS` vào chuỗi silent arguments.
- Tự động gọi `Register-VUONGTTAppSystemIntegration` cho tất cả các gói cài đặt thành công.

- [ ] **Step 4: Chạy test xác nhận trạng thái GREEN**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: PASS

- [ ] **Step 5: Áp dụng UTF-8 BOM và Commit Task 2**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Fix-AllUtf8Bom.ps1"`
Git commit: `feat(installer): cuong che scope machine va allusers cho toan bo trinh cai dat phan mem`

---

### Task 3: Chuẩn Hóa Mở Bảng Điều Khiển & Công Cụ Hệ Thống Với Quyền Administrator (`ConfigManager.ps1`)

**Files:**
- Modify: `src/Core/ConfigManager.ps1:123-148`
- Test: `tests/Test-AdminExecutionEnforcement.Tests.ps1`

**Interfaces:**
- Consumes: `Start-VUONGTTAdminProcess`
- Produces: `Open-VUONGTTLegacyPanel` mở 100% bảng điều khiển (`compmgmt.msc`, `control.exe`, `ncpa.cpl`, `sysdm.cpl`, `rstrui.exe`, `userpasswords2`, `firewall.cpl`) với `-Verb RunAs` và đường dẫn chuẩn `System32`.

- [ ] **Step 1: Viết test TDD kiểm định hàm Open-VUONGTTLegacyPanel**

```powershell
# tests/Test-AdminExecutionEnforcement.Tests.ps1 (Task 3 snippet)
$configContent = Get-Content (Join-Path $rootDir "src\Core\ConfigManager.ps1") -Raw -Encoding UTF8
$callsAdminProcess = $configContent -match 'Start-VUONGTTAdminProcess|Verb RunAs'
Assert-True $callsAdminProcess "Open-VUONGTTLegacyPanel phải mở công cụ với quyền Administrator (RunAs)"
```

- [ ] **Step 2: Chạy test xác nhận trạng thái**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: FAIL

- [ ] **Step 3: Triển khai cập nhật `Open-VUONGTTLegacyPanel` trong `ConfigManager.ps1`**
Thay thế `Start-Process "xxx"` đơn thuần bằng `Start-VUONGTTAdminProcess` hoặc `Start-Process -FilePath ... -Verb RunAs`:
```powershell
switch ($PanelId) {
    "compmgmt"   { Start-VUONGTTAdminProcess -FilePath "$env:WINDIR\System32\mmc.exe" -ArgumentList "$env:WINDIR\System32\compmgmt.msc" }
    "control"    { Start-VUONGTTAdminProcess -FilePath "$env:WINDIR\System32\control.exe" }
    "ncpa"       { Start-VUONGTTAdminProcess -FilePath "$env:WINDIR\System32\control.exe" -ArgumentList "ncpa.cpl" }
    "restore"    { Start-VUONGTTAdminProcess -FilePath "$env:WINDIR\System32\rstrui.exe" }
    "autologon"  { Start-VUONGTTAdminProcess -FilePath "$env:WINDIR\System32\control.exe" -ArgumentList "userpasswords2" }
    ...
}
```

- [ ] **Step 4: Chạy test xác nhận trạng thái GREEN**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: PASS

- [ ] **Step 5: Áp dụng UTF-8 BOM và Commit Task 3**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Fix-AllUtf8Bom.ps1"`
Git commit: `feat(config): mo bang dieu khien va cong cu he thong voi dac quyen administrator RunAs`

---

### Task 4: Đồng Bộ Tinh Chỉnh Hệ Thống (Tweaks) Sang HKLM & Active Domain User Hives (`SystemTweaks.ps1`)

**Files:**
- Modify: `src/Core/SystemTweaks.ps1`
- Test: `tests/Test-AdminExecutionEnforcement.Tests.ps1`

**Interfaces:**
- Consumes: `Set-VUONGTTAdminRegistry` từ `AdminSecurityManager.ps1`
- Produces: Các hàm tinh chỉnh chuột phải Classic Context Menu, ẩn Search Box, tắt Telemetry, tắt Bing Search, tối ưu hiệu năng... không chỉ ghi vào `HKCU` của Admin mà ghi trực tiếp vào `HKLM:\SOFTWARE\Policies` và toàn bộ Active User SIDs trong `HKEY_USERS`.

- [ ] **Step 1: Viết test TDD kiểm định tinh chỉnh đa tầng (Multi-Hive Tweaks)**

```powershell
# tests/Test-AdminExecutionEnforcement.Tests.ps1 (Task 4 snippet)
$tweaksContent = Get-Content (Join-Path $rootDir "src\Core\SystemTweaks.ps1") -Raw -Encoding UTF8
$hasMultiHive = $tweaksContent -match 'Set-VUONGTTAdminRegistry|HKEY_USERS'
Assert-True $hasMultiHive "SystemTweaks.ps1 phải áp dụng tinh chỉnh cho cả HKLM và các tài khoản người dùng hoạt động"
```

- [ ] **Step 2: Chạy test xác nhận trạng thái**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: FAIL

- [ ] **Step 3: Cập nhật các hàm Registry Tweaks trong `src/Core/SystemTweaks.ps1`**
Sử dụng `Set-VUONGTTAdminRegistry` để thiết lập các giá trị Registry đồng thời cho:
1. `HKLM:\SOFTWARE\Policies\Microsoft\Windows\...`
2. `HKCU:\Software\...`
3. Mọi SID hợp lệ của người dùng đang đăng nhập trong `HKEY_USERS\$sid\Software\...`.

- [ ] **Step 4: Chạy test xác nhận trạng thái GREEN**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: PASS

- [ ] **Step 5: Áp dụng UTF-8 BOM và Commit Task 4**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Fix-AllUtf8Bom.ps1"`
Git commit: `feat(tweaks): dong bo tinh chinh registry he thong sang HKLM va toan bo active user SIDs`

---

### Task 5: Tích Hợp Toàn Diện Vào Giao Diện Chính & Quick Actions (`VUONGTT_Toolkit.ps1`)

**Files:**
- Modify: `VUONGTT_Toolkit.ps1`
- Test: `tests/Test-AdminExecutionEnforcement.Tests.ps1`

**Interfaces:**
- Consumes: `AdminSecurityManager.ps1`
- Produces: 
  - Dot-source `AdminSecurityManager.ps1` khi khởi động.
  - Chuẩn hóa các nút Quick Actions: Khởi động lại Explorer, Dọn Dẹp Nhanh, Sửa Máy In LAN, Quản trị người dùng chạy với đầy đủ đặc quyền Admin.

- [ ] **Step 1: Viết test TDD kiểm định tích hợp vào VUONGTT_Toolkit.ps1**

```powershell
# tests/Test-AdminExecutionEnforcement.Tests.ps1 (Task 5 snippet)
$toolkitContent = Get-Content (Join-Path $rootDir "VUONGTT_Toolkit.ps1") -Raw -Encoding UTF8
$sourcesAdminSec = $toolkitContent -match 'AdminSecurityManager\.ps1'
Assert-True $sourcesAdminSec "VUONGTT_Toolkit.ps1 phải tự động nạp AdminSecurityManager.ps1"
```

- [ ] **Step 2: Chạy test xác nhận trạng thái**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: FAIL

- [ ] **Step 3: Triển khai dot-source và tích hợp vào `VUONGTT_Toolkit.ps1`**
- Thêm `. "$CoreDir\AdminSecurityManager.ps1"` vào danh sách nạp module khởi động.
- Cập nhật các sự kiện Click trong Sidebar Quick Actions và điều hướng quản trị.

- [ ] **Step 4: Chạy test xác nhận trạng thái GREEN**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"`
Expected: PASS

- [ ] **Step 5: Áp dụng UTF-8 BOM và Commit Task 5**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Fix-AllUtf8Bom.ps1"`
Git commit: `feat(toolkit): tich hop module dac quyen administrator vao giao dien chinh`

---

### Task 6: Kiểm Thử Toàn Diện, Nâng Version & Biên Dịch Binary Local

**Files:**
- Modify: `version.json`, `src/UI/MainWindow.xaml`, `src/Program.cs`, `src/Core/AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`
- Build: `VUONGTT_Toolkit.exe`
- Test: `tests/Test-AdminExecutionEnforcement.Tests.ps1`, `tests/check_ast.ps1`, `tests/verify_build.ps1`

- [ ] **Step 1: Chạy toàn bộ bộ kiểm thử tự động**
Run:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AdminExecutionEnforcement.Tests.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-ZaloDomainInstallFix.Tests.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AppSearchAndRegistration.Tests.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-DomainAppInstallFix.Tests.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "tests\Test-FeaturePolicySync.Tests.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "tests\check_ast.ps1"
```
Expected: 100% PASSED (0 FAILED)

- [ ] **Step 2: Cập nhật version và changelog trong version.json**
- [ ] **Step 3: Biên dịch file thực thi `Build-Exe.ps1`**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "Build-Exe.ps1"`
Expected: Tạo thành công `VUONGTT_Toolkit.exe` mới với số hiệu phiên bản tăng đồng bộ.

- [ ] **Step 4: Kiểm định file thực thi**
Run: `powershell -NoProfile -ExecutionPolicy Bypass -File "tests\verify_build.ps1"`
Expected: Dung lượng hợp lệ, FileVersion khớp với version mới.

- [ ] **Step 5: Commit Git cục bộ**
Git commit: `chore(release): hoan tat nang cap cuong che toan bo tinh nang chay quyen administrator`
