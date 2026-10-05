# System-Wide Highest Administrator & Token Privileges Enforcement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Đảm bảo 100% tính năng của VUONGTT Toolkit chạy với đặc quyền Quản trị viên Tối thượng (Highest System Administrator / Superuser) mà không gặp bất kỳ lỗi từ chối truy cập (Access Denied / UAC / Token Elevation Error) nào.

**Architecture:** Bổ sung C# Native P/Invoke Windows Token Privilege Adjuster (`Enable-VUONGTTHighestPrivileges`) vào `AdminSecurityManager.ps1` để kích hoạt toàn bộ token privileges (`SeDebugPrivilege`, `SeTakeOwnershipPrivilege`, `SeBackupPrivilege`, `SeRestorePrivilege`, `SeSecurityPrivilege`, `SeShutdownPrivilege`, v.v.), kiểm tra Integrity Level (High/System Mandatory Level), tích hợp TrustedInstaller/SYSTEM delegation helper cho các registry/service bảo vệ nghiêm ngặt, tự động cưỡng chế token cao nhất cho mọi lệnh thực thi tiến trình con, và cập nhật giao diện hiển thị trạng thái đặc quyền tối thượng trên Header UI.

**Tech Stack:** C#, PowerShell 5.1 / 7+, Windows API (P/Invoke `advapi32.dll`, `kernel32.dll`), Win32 UAC Token Architecture, WPF XAML.

**Spec:** Yêu cầu người dùng: "tôi thấy tool chưa có hoàn toàn đi vào admin của hệ thống, hãy làm cho toàn bộ chức năng đều chạy admin với quyền cao nhất để không còn bị lỗi bất kì chức năng nào".

## Global Constraints

- Tuân thủ quy tắc Superpowers: TDD (RED -> GREEN), cập nhật `task.md`, phân tích tác động, xác thực thực tế.
- Tuân thủ `AGENTS.md`: Tự động nâng 1 build version (`v20.5.909.85` -> `v20.5.909.86`), biên dịch `VUONGTT_Toolkit.exe`, KHÔNG `git push`.
- Giữ nguyên UTF-8 BOM trên toàn bộ tệp mã nguồn.

---

### Task 1: Thiết Kế Bộ Test TDD (RED Phase)

**Files:**
- Create: `tests/Test-HighestAdminPrivilege.Tests.ps1`

**Interfaces:**
- Consumes: `src/Core/AdminSecurityManager.ps1`
- Produces: Test suite kiểm tra hàm `Enable-VUONGTTHighestPrivileges`, `Get-VUONGTTProcessIntegrityLevel`, `Start-VUONGTTAdminProcess` nâng cao, `Set-VUONGTTAdminRegistry` bảo vệ, và xác thực Header badge.

- [ ] **Step 1: Viết test failing `tests/Test-HighestAdminPrivilege.Tests.ps1`**
- [ ] **Step 2: Chạy test để xác nhận FAIL (RED)**
- [ ] **Step 3: Ghi nhận kết quả test thất bại đúng như kỳ vọng**

---

### Task 2: Hiện Thực Token Privilege Adjuster & Integrity Level Engine trong AdminSecurityManager.ps1

**Files:**
- Modify: `src/Core/AdminSecurityManager.ps1`

**Interfaces:**
- Consumes: Win32 APIs (`OpenProcessToken`, `LookupPrivilegeValue`, `AdjustTokenPrivileges`, `GetTokenInformation`)
- Produces: `Enable-VUONGTTHighestPrivileges`, `Get-VUONGTTProcessIntegrityLevel`, `Invoke-VUONGTTTrustedInstallerTask`, cải tiến `Start-VUONGTTAdminProcess` và `Set-VUONGTTAdminRegistry`

- [ ] **Step 1: Thêm C# Native Token Privileges & Integrity Level helper vào `AdminSecurityManager.ps1`**
- [ ] **Step 2: Hiện thực `Enable-VUONGTTHighestPrivileges` tự động bật toàn bộ đặc quyền kernel**
- [ ] **Step 3: Hiện thực `Get-VUONGTTProcessIntegrityLevel` xác định High / System level**
- [ ] **Step 4: Củng cố `Start-VUONGTTAdminProcess` tự động kế thừa và cưỡng chế token cao nhất**
- [ ] **Step 5: Chạy test `Test-HighestAdminPrivilege.Tests.ps1` xác nhận PASS (GREEN)**

---

### Task 3: Tích Hợp Khởi Động Tối Thượng Vào Entry Point C# (Program.cs) & Main Script (VUONGTT_Toolkit.ps1)

**Files:**
- Modify: `src/Program.cs`
- Modify: `VUONGTT_Toolkit.ps1`

**Interfaces:**
- Consumes: `Enable-VUONGTTHighestPrivileges`, `Get-VUONGTTProcessIntegrityLevel`
- Produces: C# launcher kích hoạt đặc quyền ngay từ lúc nạp và Main Script gọi `Enable-VUONGTTHighestPrivileges` ngay tại dòng khởi động.

- [ ] **Step 1: Cập nhật `src/Program.cs` kích hoạt token privileges trước khi spawn PowerShell**
- [ ] **Step 2: Cập nhật `VUONGTT_Toolkit.ps1` khởi động `Enable-VUONGTTHighestPrivileges` và cập nhật ToolTip / hiển thị Header UI badge**
- [ ] **Step 3: Kiểm tra cú pháp qua `tests/check_ast.ps1`**

---

### Task 4: Kiểm Thử Toàn Diện, Nâng Version, Biên Dịch & Xác Thực Hoàn Tất

**Files:**
- Modify: `version.json`
- Modify: `src/Program.cs`
- Modify: `src/UI/MainWindow.xaml`
- Modify: `src/Core/AppUpdater.ps1`
- Modify: `VUONGTT_Toolkit.ps1`
- Output: `VUONGTT_Toolkit.exe`

- [ ] **Step 1: Áp dụng UTF-8 BOM bằng `tests/Fix-AllUtf8Bom.ps1`**
- [ ] **Step 2: Chạy toàn bộ các bộ test suites hiện có**
- [ ] **Step 3: Nâng version lên `v20.5.909.86` và chạy `Build-Exe.ps1`**
- [ ] **Step 4: Chạy `tests/verify_build.ps1` xác thực binary mới**
- [ ] **Step 5: Commit Git cục bộ (Không push)**
