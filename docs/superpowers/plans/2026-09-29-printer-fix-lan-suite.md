# Bộ Công Cụ "Fix Máy In - Share LAN" Toàn Diện Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hiện đại hóa và mở rộng toàn diện phân hệ "Fix Máy In - Share LAN" thành 4 sub-tabs chuyên nghiệp (Fix Máy In Mạng LAN, Add Windows Credentials, Tạo User Chia Sẻ Máy In - LAN, Fix Chia Sẻ Dữ Liệu) kèm Modal Dialog sửa lỗi 0x0000007c theo đúng chuẩn hình ảnh tham chiếu và phong cách Apple HIG.

**Architecture:** Tái cấu trúc `pagePrinterLAN` trong `src/UI/MainWindow.xaml` bằng thanh điều hướng Apple Segmented Control 4 sub-tabs; xây dựng các động cơ PowerShell quản lý máy in, quản lý Windows Local User, quản lý Windows Credentials và sửa lỗi hệ thống trong `src/Core/NetworkPrinterFix.ps1`; kết nối luồng sự kiện và hoạt họa mượt mà trong `VUONGTT_Toolkit.ps1`.

**Tech Stack:** WPF (XAML), PowerShell 5.1, .NET Framework 4.8, Windows Spooler API, CIM/WMI, `cmdkey.exe`, `net.exe`, `lusrmgr.msc`.

**Spec:** [`docs/superpowers/specs/2026-09-29-printer-fix-lan-suite-design.md`](file:///e:/toolwindows/docs/superpowers/specs/2026-09-29-printer-fix-lan-suite-design.md)

## Global Constraints

- Bảo tồn 100% các `x:Name` hiện có hoặc bổ sung tương thích ngược để không gây lỗi runtime.
- Giao diện tuân thủ tuyệt đối phong cách Apple HIG đã định hình (CornerRadius bo mềm, font chữ Apple SF Pro fallback, màu sắc dịu mắt, hover mượt).
- Hỗ trợ đầy đủ cả 3 chế độ Theme (Mặc Định / Tối / Sáng).
- Bảo toàn UTF-8 BOM trên toàn bộ các file mã nguồn.
- Tuân thủ nghiêm ngặt quy tắc `AGENTS.md`: Tự động nâng số hiệu version lên 1 build (`v20.5.909.56` -> `v20.5.909.57`) đồng bộ trên 5 files (`version.json`, `MainWindow.xaml`, `src/Program.cs`, `AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`), biên dịch `VUONGTT_Toolkit.exe`, chạy Smoke Test pass và chỉ lưu Git commit tại máy cục bộ (TUYỆT ĐỐI KHÔNG tự ý `git push`).

---

### Task 1: Bộ Kiểm Thử TDD Toàn Diện (Red Phase)

**Files:**
- Create: `tests/Test-PrinterFixLANSuite.Tests.ps1`
- Test: `tests/Test-PrinterFixLANSuite.Tests.ps1`

**Interfaces:**
- Consumes: `src/UI/MainWindow.xaml`, `src/Core/NetworkPrinterFix.ps1`, `VUONGTT_Toolkit.ps1`
- Produces: Test runner kiểm tra tự động 6 khía cạnh của bộ công cụ máy in & chia sẻ LAN

- [ ] **Step 1: Viết bộ test TDD kiểm tra các thành phần của bộ công cụ mới**

Tạo tệp `tests/Test-PrinterFixLANSuite.Tests.ps1` chứa các test case:
1. `Test 1`: Kiểm tra sự tồn tại của 4 sub-tabs (`tabPrinterLAN_Fix`, `tabPrinterLAN_Credentials`, `tabPrinterLAN_ShareUser`, `tabPrinterLAN_ShareData`) trong XAML.
2. `Test 2`: Kiểm tra DataGrid máy in `dgPrinterList` và DataGrid User `dgUsersList` có đầy đủ cột hiển thị.
3. `Test 3`: Kiểm tra Modal 0x0000007c (`modal0x7c`) và các tùy chọn phiên bản Windows.
4. `Test 4`: Kiểm tra các hàm backend trong `src/Core/NetworkPrinterFix.ps1` (`Get-VUONGTTPrinterList`, `Get-VUONGTTLocalUsers`, `New-VUONGTTShareUser`, `Invoke-VUONGTTBatchErrorFix`, `Get-VUONGTTCredentials`).
5. `Test 5`: Kiểm tra các mã lỗi mới được khai báo trong backend (`0x7c`, `0xbc4`, `0x4005`, `0x11b`, `0xbcb`, `0x6d9`, `0x709`, `0x012`, `policy`).
6. `Test 6`: Kiểm tra cú pháp AST của toàn bộ các file PowerShell liên quan.

- [ ] **Step 2: Chạy test xác nhận FAIL thực tế (Red Phase)**

Chạy: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tests\Test-PrinterFixLANSuite.Tests.ps1"`
Kỳ vọng: FAIL (vì các sub-tabs và hàm backend mới chưa được tích hợp).

---

### Task 2: Triển Khai Backend Động Cơ Quản Lý Máy In, User & Credentials (`src/Core/NetworkPrinterFix.ps1`)

**Files:**
- Modify: `src/Core/NetworkPrinterFix.ps1`

**Interfaces:**
- Consumes: Windows CIM/WMI (`Win32_Printer`, `Win32_UserAccount`), Windows Credential Manager (`cmdkey.exe`), Spooler Service, Registry
- Produces:
  - `Get-VUONGTTPrinterList`
  - `Invoke-VUONGTTPrinterAction` (test_print, set_default, share_printer, remove_printer, add_local_port)
  - `Invoke-VUONGTTBatchErrorFix` (nhận danh sách mã lỗi và sửa hàng loạt)
  - `Invoke-VUONGTTFix0x7c` (thay thế file win32spl.dll và registry)
  - `Get-VUONGTTLocalUsers`
  - `New-VUONGTTShareUser`
  - `Set-VUONGTTUserProperty` (khóa, mở khóa, đổi pass, gán admin, hạn mật khẩu)
  - `Remove-VUONGTTUser`
  - `Get-VUONGTTCredentials`, `Add-VUONGTTCredential`, `Remove-VUONGTTCredential`
  - `Invoke-VUONGTTDataShareFix`

- [ ] **Step 1: Viết các hàm quét và thao tác Máy In (`Get-VUONGTTPrinterList`, `Invoke-VUONGTTPrinterAction`)**

```powershell
function Get-VUONGTTPrinterList {
    try {
        $printers = Get-CimInstance -ClassName Win32_Printer -ErrorAction Stop
        $list = @()
        foreach ($p in $printers) {
            $statusText = if ($p.PrinterStatus -eq 3) { "Sẵn sàng (Ready)" } elseif ($p.WorkOffline) { "Offline" } else { "Sẵn sàng (Ready)" }
            $list += [PSCustomObject]@{
                IsDefault = [bool]$p.Default
                Name      = $p.Name
                PortName  = if ($p.PortName) { $p.PortName } else { "Unknown" }
                Status    = $statusText
                IsShared  = [bool]$p.Shared
                ShareName = $p.ShareName
            }
        }
        return $list
    } catch {
        return @()
    }
}
```

- [ ] **Step 2: Viết các hàm quản lý Local User (`Get-VUONGTTLocalUsers`, `New-VUONGTTShareUser`, `Set-VUONGTTUserProperty`, `Remove-VUONGTTUser`)**

```powershell
function Get-VUONGTTLocalUsers {
    try {
        $users = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = True" -ErrorAction Stop
        $list = @()
        foreach ($u in $users) {
            $isAdmin = $false
            try {
                $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
                $members = @($group.psbase.Invoke("Members"))
                foreach ($m in $members) {
                    $mName = $m.GetType().InvokeMember("Name", 'GetProperty', $null, $m, $null)
                    if ($mName -eq $u.Name) { $isAdmin = $true; break }
                }
            } catch {}
            
            $status = if ($u.Disabled) { "Đã khóa" } else { "Hoạt động" }
            $pwdExpires = if ($u.PasswordExpires) { "Có thời hạn" } else { "Không bao giờ hết hạn" }
            $groupName = if ($isAdmin) { "Admin" } elseif ($u.Name -eq "Guest") { "Guests" } else { "Users" }

            $list += [PSCustomObject]@{
                Name            = $u.Name
                FullName        = $u.FullName
                Group           = $groupName
                Status          = $status
                IsDisabled      = [bool]$u.Disabled
                PasswordExpires = $pwdExpires
                IsAdmin         = $isAdmin
            }
        }
        return $list
    } catch {
        return @()
    }
}
```

- [ ] **Step 3: Viết các hàm quản lý Windows Credentials qua `cmdkey.exe`**

```powershell
function Get-VUONGTTCredentials {
    $creds = @()
    try {
        $output = cmdkey.exe /list
        $currentTarget = ""
        $currentType = ""
        $currentUser = ""
        foreach ($line in ($output -split "`r?`n")) {
            $t = $line.Trim()
            if ($t -match "^Target:\s*(.*)$") {
                if ($currentTarget) {
                    $creds += [PSCustomObject]@{ Target=$currentTarget; Type=$currentType; User=$currentUser }
                }
                $currentTarget = $Matches[1].Trim()
                $currentType = ""
                $currentUser = ""
            } elseif ($t -match "^Type:\s*(.*)$") {
                $currentType = $Matches[1].Trim()
            } elseif ($t -match "^User:\s*(.*)$") {
                $currentUser = $Matches[1].Trim()
            }
        }
        if ($currentTarget) {
            $creds += [PSCustomObject]@{ Target=$currentTarget; Type=$currentType; User=$currentUser }
        }
    } catch {}
    return $creds
}
```

- [ ] **Step 4: Mở rộng `Invoke-VUONGTTBatchErrorFix` và `Invoke-VUONGTTFix0x7c`**

Tích hợp xử lý các mã lỗi:
- `0x7c`: Thay thế `win32spl.dll` chuẩn kèm chỉnh Registry `RpcAuthnLevelPrivacyEnabled = 0`.
- `0xbc4`: Thiết lập `RpcOverNamedPipes` và `RpcProtocols` trong Registry Spooler.
- `0x4005`: Sửa quyền phân quyền thư mục Spooler và nạp lại DCOM endpoint.
- `0x11b`: `RpcAuthnLevelPrivacyEnabled = 0`.
- `0xbcb`: Hủy hạn chế PointAndPrint (`Restricted = 0`, `TrustedServers = 0`).
- `0x6d9`: Sửa lỗi tường lửa chặn Windows Firewall Service khi chia sẻ máy in.
- `0x709`: Mở quyền Admin cho Point and Print (`RestrictDriverInstallationToAdministrators = 0`) & `LegacyDefaultPrinterMode = 1`.
- `0x012`: Khắc phục lỗi Network BIOS session limit / Memory pool.
- `Policy In Effect`: Gỡ bỏ ép buộc Group Policy Point and Print hạn chế người dùng.

---

### Task 3: Tái Cấu Trúc XAML Giao Diện `pagePrinterLAN` (`src/UI/MainWindow.xaml`)

**Files:**
- Modify: `src/UI/MainWindow.xaml:1634-1710`

**Interfaces:**
- Consumes: XAML WPF Theme Brushes & Apple Styles
- Produces:
  - Apple Segmented Control Bar: `btnSubTab_PrinterFix`, `btnSubTab_Credentials`, `btnSubTab_ShareUser`, `btnSubTab_ShareData`
  - Sub-tab 1 Panel (`pnlSubPrinterLAN_Fix`):
    - Left Card: DataGrid `dgPrinterList` và 5 nút tác vụ
    - Right Card: 9 Checkboxes mã lỗi 3 cột, nút `btnFixSelectedErrors`, Warning Banner, Lưới 9 nút tiện ích
    - Modal Overlay Dialog: `modal0x7c` căn giữa với radio options và nút sửa nhanh
  - Sub-tab 2 Panel (`pnlSubPrinterLAN_Credentials`): Form thêm credential, DataGrid hiển thị và các nút quản lý
  - Sub-tab 3 Panel (`pnlSubPrinterLAN_ShareUser`): Form tạo User, DataGrid tài khoản hiện có, 6 nút quản lý user và thẻ hướng dẫn chi tiết
  - Sub-tab 4 Panel (`pnlSubPrinterLAN_ShareData`): 6 thẻ chức năng 1-Click fix chia sẻ file/folder mạng LAN

- [ ] **Step 1: Tạo Segmented Pill Subtab Header Bar**
- [ ] **Step 2: Tạo Sub-tab 1 Layout (DataGrid Máy in & Khối Sửa Mã Lỗi)**
- [ ] **Step 3: Tạo Modal Overlay Khắc Phục Lỗi 0x0000007c**
- [ ] **Step 4: Tạo Sub-tab 2 Layout (Windows Credentials Manager)**
- [ ] **Step 5: Tạo Sub-tab 3 Layout (Tạo User Chia Sẻ & Quản Lý User Local & Hướng Dẫn)**
- [ ] **Step 6: Tạo Sub-tab 4 Layout (Fix Chia Sẻ Dữ Liệu)**

---

### Task 4: Kết Nối Sự Kiện & Tự Động Hóa UI (`VUONGTT_Toolkit.ps1`)

**Files:**
- Modify: `VUONGTT_Toolkit.ps1`

**Interfaces:**
- Consumes: XAML Controls từ `MainWindow.xaml` và Functions từ `NetworkPrinterFix.ps1`
- Produces: Điều khiển hoàn chỉnh 4 Sub-tabs, load DataGrid tự động, xử lý Click các nút chức năng

- [ ] **Step 1: Logic chuyển đổi 4 Sub-tabs (Active Tab Highlight & Panel Switch)**
- [ ] **Step 2: Logic Sub-tab 1 - Quét máy in, In test, Set mặc định, Share LAN, Sửa lỗi đã chọn, Mở modal 0x7c**
- [ ] **Step 3: Logic Sub-tab 2 - Thêm Credentials, Quét danh sách, Xóa Credentials, Mở Credential Manager**
- [ ] **Step 4: Logic Sub-tab 3 - Tạo User Share mới, Quét danh sách User, Khóa/Mở khóa, Đổi pass, Đặt MK không hết hạn, Gán/Gỡ Admin, Xóa User**
- [ ] **Step 5: Logic Sub-tab 4 - Chạy các tiện ích chia sẻ dữ liệu LAN**

---

### Task 5: Kiểm Thử Toàn Diện & Verification (Green Phase)

**Files:**
- Test: `tests/Test-PrinterFixLANSuite.Tests.ps1`
- Check: `tests/check_ast.ps1`

- [ ] **Step 1: Chạy `Test-PrinterFixLANSuite.Tests.ps1` xác nhận 100% PASS**
- [ ] **Step 2: Chạy kiểm tra toàn bộ AST (`check_ast.ps1`) đảm bảo 0 lỗi cú pháp**

---

### Task 6: Nâng Phiên Bản, Biên Dịch & Smoke Test (AGENTS.md Compliance)

**Files:**
- Modify: `version.json`
- Modify: `src/UI/MainWindow.xaml`
- Modify: `src/Program.cs`
- Modify: `AppUpdater.ps1`
- Modify: `VUONGTT_Toolkit.ps1`

- [ ] **Step 1: Nâng version đồng bộ lên `v20.5.909.57`**
- [ ] **Step 2: Áp dụng UTF-8 BOM qua `Fix-AllUtf8Bom.ps1`**
- [ ] **Step 3: Biên dịch `VUONGTT_Toolkit.exe` tại local qua `build.bat` hoặc PowerShell**
- [ ] **Step 4: Chạy Smoke Test kiểm tra file EXE khởi chạy thành công**
- [ ] **Step 5: Lưu Git commit tại máy cục bộ (KHÔNG push lên GitHub)**
