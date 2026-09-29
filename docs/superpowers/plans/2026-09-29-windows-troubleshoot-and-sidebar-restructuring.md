# Kế Hoạch Triển Khai: Hệ Thống Cứu Hộ IT Helpdesk & Tinh Gọn Sidebar 8 Tabs
## (Windows Troubleshooting Helpdesk Engine & Streamlined 8-Tab Sidebar)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tinh gọn thanh Sidebar của `VUONGTT_Toolkit` từ 19 menu cuộn dài thành 8 Tab chính chuẩn Apple (tích hợp Sub-tabs bên trong), đồng thời xây dựng Hệ Thống Cứu Hộ & Chẩn Đoán Lỗi IT Helpdesk Windows (Giai đoạn 1) với cơ sở dữ liệu hơn 200+ mã sự cố phân cấp thành 7 danh mục chuẩn, Core Engine PowerShell chẩn đoán/sửa lỗi tự động và giao diện widget chuyên nghiệp.

**Architecture:** Kiến trúc Dữ liệu Động (Dynamic Knowledgebase) lưu trữ trong `src/Data/TroubleshootDatabase.json`, được điều phối bởi `src/Core/TroubleshootManager.ps1` (chịu trách nhiệm tìm kiếm, sao lưu an toàn, thực thi pipeline: Diagnosis -> Fix -> Verify -> Escalation). Giao diện Sidebar trong `MainWindow.xaml` được tinh gọn thành 8 Apple Cards không cuộn trang, nhúng Widget Troubleshoot chuẩn hóa có tìm kiếm theo mã lỗi và real-time console log.

**Tech Stack:** C# WPF (.NET Framework 4.8), PowerShell Core / Windows PowerShell 5.1+, XAML, JSON, Windows Diagnostics & Management APIs (WMI, CIM, Registry, Services, NetTCPIP, DISM/SFC).

**Spec:** [docs/superpowers/specs/2026-09-29-windows-troubleshoot-helpdesk-engine-design.md](file:///e:/toolwindows/docs/superpowers/specs/2026-09-29-windows-troubleshoot-helpdesk-engine-design.md)

## Global Constraints

- **Local Version Bump (AGENTS.md)**: Tự động tăng 1 số Build Increment (ví dụ `v20.5.909.56` -> `v20.5.909.57`) đồng bộ trên 5 files: `version.json`, `MainWindow.xaml`, `src/Program.cs`, `AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`.
- **Biên dịch cục bộ**: Chạy `Build-Exe.ps1` tạo file thực thi `E:\toolwindows\VUONGTT_Toolkit.exe` và kiểm tra giao diện local.
- **Quy tắc phát hành**: TUYỆT ĐỐI KHÔNG `git push`. Chỉ commit tại git local.
- **Bảo toàn chức năng**: Không xóa hay làm gián đoạn bất kỳ tính năng nào trong 19 trang cũ; tất cả được chuyển đổi hợp lý vào Sub-tabs bên trong 8 tab chính.

---

### Task 1: Thiết Kế & Xây Dựng Cơ Sở Dữ Liệu JSON (Troubleshoot Database)

**Files:**
- Create: `src/Data/TroubleshootDatabase.json`
- Test: `tests/Test-TroubleshootDatabase.ps1`

**Interfaces:**
- Produces: `TroubleshootDatabase.json` chứa 7 Categories, các SubCategories và hơn 200 mã Problem (`PERF-001` -> `SYS-010`), mỗi Problem có cấu trúc chuẩn: `Id`, `Category`, `SubCategory`, `TargetPage`, `Title`, `ErrorCode`, `Symptoms`, `Cause`, `Diagnosis`, `Fix`, `Verification`, `Escalation`.

- [ ] **Step 1: Viết bài kiểm tra tính hợp lệ của cơ sở dữ liệu JSON (`tests/Test-TroubleshootDatabase.ps1`)**
```powershell
$jsonPath = "$PSScriptRoot\..\src\Data\TroubleshootDatabase.json"
if (-not (Test-Path $jsonPath)) {
    Write-Error "TroubleshootDatabase.json không tồn tại!"
    exit 1
}
$content = Get-Content -Raw -Encoding UTF8 -Path $jsonPath | ConvertFrom-Json
if (-not $content.Categories -or $content.Categories.Count -ne 7) {
    Write-Error "Số lượng Categories phải đúng bằng 7!"
    exit 1
}
if (-not $content.Problems -or $content.Problems.Count -lt 150) {
    Write-Error "Danh sách sự cố Problems chưa đủ số lượng quy định (tối thiểu 150+ sự cố)!"
    exit 1
}
Write-Host "[PASS] TroubleshootDatabase.json hợp lệ với $($content.Problems.Count) sự cố thuộc 7 Danh mục!"
exit 0
```

- [ ] **Step 2: Chạy kiểm tra để xác nhận thất bại trước khi tạo file**
Run: `powershell -ExecutionPolicy Bypass -File tests/Test-TroubleshootDatabase.ps1`
Expected: FAIL với thông báo "TroubleshootDatabase.json không tồn tại!"

- [ ] **Step 3: Xây dựng file `src/Data/TroubleshootDatabase.json` hoàn chỉnh**
Tạo file `src/Data/TroubleshootDatabase.json` nạp đủ 7 Danh Mục Chuẩn IT Helpdesk:
1. `01. Windows / Operating System` (`PERF-001` -> `020`, `SYS-001` -> `010`, `UPDATE-001` -> `020`, `SVC-001` -> `014`, `DISK-001` -> `016`, `REC-001` -> `010`, `UI-001` -> `010`, `SETTINGS-001` -> `008`)
2. `02. Network & Remote Access` (`NET-001` -> `025`, `VPN-001` -> `010`, `RDP-001` -> `012`, `FW-001` -> `008`, `TIME-001` -> `007`)
3. `03. Printer & LAN Share` (`PRINT-001` -> `020`, `SMB-001` -> `015`, `FILE-001` -> `020`, `PERM-001` -> `012`)
4. `04. Account & Active Directory` (`LOGIN-001` -> `020`, `PROFILE-001` -> `010`, `AD-001` -> `020`, `GPO-001` -> `015`, `ACT-001` -> `010`, `SEC-001` -> `012`, `BIT-001` -> `008`, `CERT-001` -> `008`)
5. `05. Microsoft Office & M365` (`OFFICE-001` -> `020`, `MAIL-001` -> `025`, `TEAMS-001` -> `012`, `OD-001` -> `015`, `SP-001` -> `014`)
6. `06. Application & Browser` (`APP-001` -> `020`, `STORE-001` -> `006`, `BROWSER-001` -> `017`)
7. `07. Hardware & Peripherals` (`HW-001` -> `015`, `AUDIO-001` -> `011`, `DISPLAY-001` -> `015`, `USB-001` -> `012`, `POWER-001` -> `010`, `DRIVER-001` -> `015`)

- [ ] **Step 4: Chạy lại test để xác nhận đạt (PASS)**
Run: `powershell -ExecutionPolicy Bypass -File tests/Test-TroubleshootDatabase.ps1`
Expected: PASS

- [ ] **Step 5: Commit Git cục bộ**
```bash
git add src/Data/TroubleshootDatabase.json tests/Test-TroubleshootDatabase.ps1
git commit -m "feat(data): add 7-category TroubleshootDatabase with 200+ IT helpdesk problems"
```

---

### Task 2: Xây Dựng Core Troubleshoot Engine (`src/Core/TroubleshootManager.ps1`)

**Files:**
- Create: `src/Core/TroubleshootManager.ps1`
- Test: `tests/Test-TroubleshootManager.ps1`

**Interfaces:**
- Consumes: `src/Data/TroubleshootDatabase.json`
- Produces:
  - `Initialize-VUONGTTTroubleshootEngine`
  - `Get-VUONGTTTroubleshootProblems -Category <string> -TargetPage <string>`
  - `Search-VUONGTTTroubleshootProblem -Query <string>`
  - `Invoke-VUONGTTTroubleshootAction -ProblemId <string> -ActionType <string>`
  - Built-in remediation routines for Top Priority issues (Disk 100%, Print Spooler, Network Winsock/DNS, Windows Update Cache reset, Access Denied).

- [ ] **Step 1: Viết test kiểm tra các hàm cốt lõi của Engine (`tests/Test-TroubleshootManager.ps1`)**
```powershell
. "$PSScriptRoot\..\src\Core\TroubleshootManager.ps1"
$init = Initialize-VUONGTTTroubleshootEngine
if (-not $init) { Write-Error "Khởi tạo Engine thất bại!"; exit 1 }

$searchRes = Search-VUONGTTTroubleshootProblem -Query "0x80070002"
if ($searchRes.Count -eq 0) { Write-Error "Không tìm thấy mã lỗi 0x80070002!"; exit 1 }

$diagRes = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-011" -ActionType "Diagnosis"
if (-not $diagRes -or -not $diagRes.StatusText) { Write-Error "Chẩn đoán PERF-011 thất bại!"; exit 1 }

Write-Host "[PASS] TroubleshootManager.ps1 hoạt động chính xác!"
exit 0
```

- [ ] **Step 2: Chạy kiểm tra để xác nhận thất bại trước khi viết code**
Run: `powershell -ExecutionPolicy Bypass -File tests/Test-TroubleshootManager.ps1`
Expected: FAIL

- [ ] **Step 3: Viết mã nguồn cho `src/Core/TroubleshootManager.ps1`**
Triển khai:
- Quản lý nạp bộ nhớ đệm `$global:VUONGTT_TroubleshootDB`.
- Tìm kiếm từ khóa và mã lỗi bằng Regex.
- Logging chuẩn hóa ra file `C:\ProgramData\VUONGTT_Toolkit\Logs\Troubleshoot.log`.
- Cơ chế sao lưu khóa Registry trước khi chỉnh sửa (`reg export`).
- Tích hợp các hàm tự động sửa cho Đợt 1:
  - `Fix-VUONGTTDisk100`: Tắt SysMain, tối ưu StorAHCI, dọn dẹp bộ đệm I/O.
  - `Fix-VUONGTTWindowsUpdate`: Dừng wuauserv, bits; xóa `C:\Windows\SoftwareDistribution` và `Catroot2`; kích hoạt lại services.
  - `Fix-VUONGTTNetworkStack`: Reset TCP/IP, Winsock, flush DNS, cấu hình DNS Google/Cloudflare tự động.
  - `Fix-VUONGTTPrintSpooler`: Dọn dẹp `C:\Windows\System32\spool\PRINTERS`, khởi động lại dịch vụ Spooler.

- [ ] **Step 4: Chạy lại test để xác nhận đạt (PASS)**
Run: `powershell -ExecutionPolicy Bypass -File tests/Test-TroubleshootManager.ps1`
Expected: PASS

- [ ] **Step 5: Commit Git cục bộ**
```bash
git add src/Core/TroubleshootManager.ps1 tests/Test-TroubleshootManager.ps1
git commit -m "feat(core): implement TroubleshootManager engine with diagnosis and auto-fix pipeline"
```

---

### Task 3: Tái Cấu Trúc Giao Diện Sidebar Thành 8 Tab Chuẩn Apple Trong `MainWindow.xaml`

**Files:**
- Modify: `src/UI/MainWindow.xaml` (khu vực Sidebar `MenuPanel`, lines 428-660)

**Interfaces:**
- Thay thế 19 Menu Button cũ bằng 8 Apple Menu Cards có chiều cao chuẩn 40px, góc bo `CornerRadius="8"`, biểu tượng Canvas/Emoji vector sắc nét:
  1. `btnMenuSysInfo` (Tag="SysInfo") - 🖥️ Thông Tin & Cấu Hình
  2. `btnMenuSystemFix` (Tag="SystemFix") - ⚡ Tối Ưu & Sửa Lỗi Win
  3. `btnMenuNetworkLAN` (Tag="NetworkLAN") - 🌐 Mạng & IP Scanner
  4. `btnMenuPrinterLAN` (Tag="PrinterLAN") - 🖨️ Máy In & Chia Sẻ LAN
  5. `btnMenuOffice` (Tag="OfficeAIO") - 💼 Office & Microsoft 365
  6. `btnMenuSoftware` (Tag="SoftwareHub") - 📦 Quản Lý Phần Mềm
  7. `btnMenuHardwareDisk` (Tag="HardwareDisk") - 💽 Ổ Cứng & Phần Cứng
  8. `btnMenuTechUtilities` (Tag="TechUtilities") - 🛠️ Tiện Ích Kỹ Thuật

- [ ] **Step 1: Rà soát các vùng XAML của 19 trang hiện có để đảm bảo không bị mất mã nguồn**
Xác nhận vị trí các container trang: `pageSysInfo`, `pageCustomize`, `pageUsers`, `pageBenchmark`, `pageLaptopCheck`, `pageCpuMain`, `pageOffice`, `pageSoftware`, `pageCustomApp`, `pageUninstaller`, `pageFonts`, `pageCleaner`, `pageConfig`, `pagePrinterLAN`, `pageBackupDriver`, `pageActivation`, `pageBitLocker`, `pageAutoWin`, `pagePartition`, `pageIpScanner`, `pageAdminPortal`.

- [ ] **Step 2: Cập nhật `MenuPanel` trong `MainWindow.xaml` thành 8 Apple Cards tinh gọn**
Xóa bỏ các Group Headers chiếm diện tích lớn, thiết kế 8 Card Buttons đồng nhất, padding gọn gàng, hiệu ứng hover chuẩn Apple.

- [ ] **Step 3: Thiết lập thanh Sub-tabs chuyển đổi nội bộ cho các trang chứa nhiều phân hệ**
- Trang `Thông Tin & Cấu Hình` có Sub-tabs: `[🖥️ Cấu Hình Máy]` | `[✨ Tùy Chỉnh OEM]` | `[🔍 Tra Cứu CPU/Main]`.
- Trang `Tối Ưu & Sửa Lỗi Win` có Sub-tabs: `[⚡ Tối Ưu & Tweaks]` | `[🛠️ Cấu Hình & Sửa Lỗi]` | `[🩺 Cứu Hộ IT Helpdesk]`.
- Trang `Ổ Cứng & Phần Cứng` có Sub-tabs: `[💽 Sức Khỏe/Tốc Độ]` | `[✂️ Quản Lý Phân Vùng]` | `[💻 Test Laptop/Ngoại Vi]`.
- Trang `Quản Lý Phần Mềm` có Sub-tabs: `[📥 Tải App]` | `[📦 Cài App Tùy Chỉnh]` | `[🗑️ Gỡ Bỏ Sạch]` | `[🔤 Cài Font]`.
- Trang `Tiện Ích Kỹ Thuật` có Sub-tabs: `[🔑 Kích Hoạt HWID]` | `[🔒 Tắt BitLocker]` | `[💾 Sao Lưu Win/Driver]` | `[🚀 Cài Win Bypass]` | `[👑 Quản Trị User/PC]`.

- [ ] **Step 4: Kiểm tra cấu trúc XAML không bị lỗi cú pháp**
Chạy test kiểm tra cú pháp XML:
```powershell
[xml]$xaml = Get-Content -Raw -Encoding UTF8 -Path "src/UI/MainWindow.xaml"
Write-Host "[PASS] MainWindow.xaml XML hợp lệ!"
```

- [ ] **Step 5: Commit Git cục bộ**
```bash
git add src/UI/MainWindow.xaml
git commit -m "feat(ui): streamline sidebar into 8 modern Apple tabs with internal sub-tabs"
```

---

### Task 4: Nhúng Troubleshoot Widget Chuẩn Hóa Vào Các Trang Trọng Tâm

**Files:**
- Modify: `src/UI/MainWindow.xaml` (nhúng widget vào `pageConfig`, `pageCleaner`, `pagePrinterLAN`, `pageIpScanner`)

**Interfaces:**
- Thêm Widget điều khiển 4 bước:
  - Search Box: `txtTroubleshootSearch`
  - List Box / DataGrid: `dgTroubleshootList`
  - Info Card: `txtTroubleshootTitle`, `txtTroubleshootSymptoms`, `txtTroubleshootCause`
  - 4 Action Buttons: `btnActionDiagnosis`, `btnActionAutoFix`, `btnActionVerify`, `btnActionEscalation`
  - Console Box: `txtTroubleshootConsoleLog`

- [ ] **Step 1: Viết ControlTemplate XAML cho Reusable Troubleshoot Card Widget**
Tạo Resource Style hoặc Component Grid chuẩn hóa hiển thị trong `pageConfig`, `pageCleaner`, `pagePrinterLAN`.

- [ ] **Step 2: Nhúng Widget vào Sub-tab "Cứu Hộ IT Helpdesk" của Tab `Tối Ưu & Sửa Lỗi Win`**
Gắn mã lỗi nhóm 1 (`PERF`, `SYS`, `UPDATE`, `DISK`, `SVC`).

- [ ] **Step 3: Nhúng Widget vào Tab `Mạng & IP Scanner` và Tab `Máy In & Chia Sẻ LAN`**
Gắn mã lỗi nhóm 2 (`NET`, `VPN`, `RDP`) và nhóm 3 (`PRINT`, `SMB`, `FILE`, `PERM`).

- [ ] **Step 4: Kiểm tra cú pháp XAML**
Run: `[xml]$xaml = Get-Content -Raw -Encoding UTF8 -Path "src/UI/MainWindow.xaml"`
Expected: Không có lỗi XML parser.

- [ ] **Step 5: Commit Git cục bộ**
```bash
git add src/UI/MainWindow.xaml
git commit -m "feat(ui): embed reusable IT helpdesk troubleshooting widget into core pages"
```

---

### Task 5: Đồng Bộ Điều Hướng & Sự Kiện Xử Lý Trong `VUONGTT_Toolkit.ps1`

**Files:**
- Modify: `VUONGTT_Toolkit.ps1`

**Interfaces:**
- Cập nhật Dictionary `$pages` và hàm `Show-AppPage` cho 8 menu mới.
- Khởi tạo `Initialize-VUONGTTTroubleshootEngine`.
- Kết nối các sự kiện Click của 8 Sidebar Buttons và các Sub-tabs Capsule Buttons.
- Kết nối sự kiện tìm kiếm và các nút `Chẩn đoán`, `Tự động sửa`, `Kiểm tra lại`, `Hướng dẫn kỹ thuật`.

- [ ] **Step 1: Cập nhật mảng điều hướng trang `$pages` trong `VUONGTT_Toolkit.ps1`**
Ánh xạ các Tag mới: `SysInfo`, `SystemFix`, `NetworkLAN`, `PrinterLAN`, `OfficeAIO`, `SoftwareHub`, `HardwareDisk`, `TechUtilities`.

- [ ] **Step 2: Viết logic điều hướng Sub-tabs trong `VUONGTT_Toolkit.ps1`**
Chuyển đổi ẩn/hiện các panel con bên trong từng trang chính một cách mượt mà và cập nhật trạng thái màu active của nút Capsule.

- [ ] **Step 3: Viết logic kết nối Troubleshoot Widget với Engine**
- Sự kiện `TextChanged` trên `txtTroubleshootSearch`: gọi `Search-VUONGTTTroubleshootProblem` và cập nhật ItemSource của bảng.
- Sự kiện `SelectionChanged` trên bảng sự cố: hiển thị chi tiết tiêu đề, mã lỗi, triệu chứng, nguyên nhân.
- Sự kiện Click 4 nút: gọi `Invoke-VUONGTTTroubleshootAction` và xuất log ra màn hình Console.

- [ ] **Step 4: Kiểm tra cú pháp PowerShell của `VUONGTT_Toolkit.ps1`**
```powershell
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile("e:\toolwindows\VUONGTT_Toolkit.ps1", [ref]$null, [ref]$errors)
if ($errors.Count -gt 0) {
    Write-Error "Cú pháp VUONGTT_Toolkit.ps1 bị lỗi: $($errors | Out-String)"
    exit 1
}
Write-Host "[PASS] VUONGTT_Toolkit.ps1 không có lỗi cú pháp!"
```

- [ ] **Step 5: Commit Git cục bộ**
```bash
git add VUONGTT_Toolkit.ps1
git commit -m "feat(script): wire up 8-tab navigation, sub-tab switches and troubleshooting events"
```

---

### Task 6: Nâng Version Cục Bộ, Biên Dịch `VUONGTT_Toolkit.exe` & Kiểm Thử Toàn Diện (AGENTS.md)

**Files:**
- Modify: `version.json`
- Modify: `src/UI/MainWindow.xaml` (Title & Version Texts)
- Modify: `src/Program.cs`
- Modify: `src/Core/AppUpdater.ps1`
- Modify: `VUONGTT_Toolkit.ps1`
- Target Binary: `VUONGTT_Toolkit.exe`

- [ ] **Step 1: Nâng số hiệu Version (Local Version Bump)**
Tăng phiên bản từ `v20.5.909.56` lên `v20.5.909.57` đồng bộ tại cả 5 file:
- `version.json` -> `"version": "v20.5.909.57"`
- `MainWindow.xaml` -> Window Title & `txtLogoVersionDisplay`
- `src/Program.cs` -> Assembly Version / Header
- `src/Core/AppUpdater.ps1` -> `$CurrentVersion = "v20.5.909.57"`
- `VUONGTT_Toolkit.ps1` -> Biến `$Script:AppVersion = "v20.5.909.57"`

- [ ] **Step 2: Chạy kiểm tra toàn bộ Unit Tests**
Run: `powershell -ExecutionPolicy Bypass -File tests/Test-TroubleshootDatabase.ps1`
Run: `powershell -ExecutionPolicy Bypass -File tests/Test-TroubleshootManager.ps1`
Run: `powershell -ExecutionPolicy Bypass -File Run-AllTests.ps1`
Expected: ALL PASS.

- [ ] **Step 3: Biên dịch file thực thi `VUONGTT_Toolkit.exe`**
Run: `powershell -ExecutionPolicy Bypass -File Build-Exe.ps1`
Expected: Biên dịch thành công mã thoát 0, sinh ra file `E:\toolwindows\VUONGTT_Toolkit.exe`.

- [ ] **Step 4: Kiểm thử trực tiếp file thực thi tại máy cục bộ (Local Verification)**
- Khởi chạy `VUONGTT_Toolkit.exe`.
- Xác nhận số hiệu `v20.5.909.57` hiển thị trên Window Title và Logo Header.
- Xác nhận thanh Sidebar hiển thị đủ 8 Tab Apple gọn gàng, không bị thanh cuộn dài che khuất.
- Bấm thử chuyển đổi giữa 8 Tab và các Sub-tabs nội bộ.
- Bấm vào tab `Tối Ưu & Sửa Lỗi Win`, tìm kiếm mã lỗi `0x80070002` hoặc `PERF-011`, chạy thử nghiệm tính năng Chẩn đoán.

- [ ] **Step 5: Lưu Commit Git Cục Bộ (TUYỆT ĐỐI KHÔNG GIT PUSH)**
```bash
git add version.json src/UI/MainWindow.xaml src/Program.cs src/Core/AppUpdater.ps1 VUONGTT_Toolkit.ps1 VUONGTT_Toolkit.exe
git commit -m "build(release): bump version to v20.5.909.57 with 8-tab sidebar and IT helpdesk engine"
```
