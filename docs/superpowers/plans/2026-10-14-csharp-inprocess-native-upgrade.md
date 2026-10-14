# VUONGTT Tool Pro 2026 — Nâng Cấp Kiến Trúc C# Native In-Process & In-Memory Execution Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng cấp tầng C# Launcher (`src/Program.cs`) của VUONGTT Toolkit thành **C# Native Host In-Process** nhúng trực tiếp `System.Management.Automation` và nạp WPF XAML trong bộ nhớ, loại bỏ hoàn toàn việc giải nén file `.ps1` ra đĩa và triệt tiêu việc gọi tiến trình `powershell.exe` ngoài.

**Architecture:**
1. **Compilation Pipeline (`Build-Exe.ps1`)**: Bổ sung reference WPF (`PresentationFramework.dll`, `PresentationCore.dll`, `WindowsBase.dll`, `System.Xaml.dll`) và `System.Management.Automation.dll` vào `csc.exe`.
2. **In-Memory Embedded Resources (`src/Program.cs`)**: Đọc tài nguyên nhúng `VUONGTT.VUONGTT_Toolkit.ps1` và các module trực tiếp từ Manifest Resource Stream vào RAM, không ghi bất kỳ file `.ps1` nào ra `%TEMP%` hay `%ProgramData%`.
3. **In-Process Runspace Engine**: Khởi tạo `RunspacePool` / `PowerShell` API chạy trực tiếp trong cùng AppDomain của C#, truyền đối tượng trực tiếp sang giao diện WPF.
4. **Fallback & Single Executable**: Giữ nguyên 100% giao diện XAML `MainWindow.xaml`, đóng gói thành `VUONGTT_Toolkit.exe` chạy độc lập trên mọi máy Windows.

**Tech Stack:**
- C# 5 / .NET Framework 4.5+ (`csc.exe` Native Windows Toolchain)
- WPF XAML (`PresentationFramework`, `PresentationCore`, `WindowsBase`)
- PowerShell In-Process Runspace (`System.Management.Automation.dll`)

## Global Constraints
- Giữ nguyên 100% giao diện XAML hiện có trong `src/UI/MainWindow.xaml` và toàn bộ 31 module nghiệp vụ trong `src/Core/`.
- Không phụ thuộc WebView2, không mở bất kỳ cổng mạng TCP `127.0.0.1` nào.
- Tự động nâng số phiên bản cục bộ theo đúng quy tắc dự án (Build Increment `v20.5.909.105` -> `v20.5.909.106`).
- Sau khi kiểm thử cục bộ hoàn tất thì thực hiện `git push` theo lệnh người dùng.

---

### Task 1: Nâng Cấp Pipeline Biên Dịch csc.exe trong Build-Exe.ps1
**Files:**
- Modify: `Build-Exe.ps1:160-175`
- Test: Chạy biên dịch thử nghiệm kiểm tra csc.exe nhận đủ các assembly WPF và System.Management.Automation.

- [ ] **Step 1:** Tìm đường dẫn chính xác của `System.Management.Automation.dll` và các DLL WPF trong script `Build-Exe.ps1`.
- [ ] **Step 2:** Thêm các cờ `/r:` cho `PresentationFramework.dll`, `PresentationCore.dll`, `WindowsBase.dll`, `System.Xaml.dll` và `System.Management.Automation.dll`.
- [ ] **Step 3:** Chạy thử `Build-Exe.ps1 -NoBump` xác nhận biên dịch không lỗi.

---

### Task 2: Hiện Thực Cơ Chế In-Memory Execution trong src/Program.cs
**Files:**
- Modify: `src/Program.cs:270-360`
- Test: Khởi chạy `--smoke-test` xác nhận nạp kịch bản từ bộ nhớ không cần tạo file ngoài đĩa.

- [ ] **Step 1:** Viết phương thức đọc nội dung script nhúng trực tiếp từ `Assembly.GetExecutingAssembly().GetManifestResourceStream()` thành chuỗi String hoặc Memory Stream.
- [ ] **Step 2:** Tích hợp phương thức thực thi In-Process bằng `System.Management.Automation.PowerShell` Runspace, truyền trực tiếp biến môi trường và tham số.
- [ ] **Step 3:** Giữ cơ chế Fallback an toàn (nếu môi trường thiếu Runspace thì tự động fallback sang cơ chế chạy an toàn).

---

### Task 3: Kiểm Thử Cục Bộ & Nâng Version v20.5.909.106
**Files:**
- Modify: `version.json`, `src/Core/AppUpdater.ps1`, `src/Program.cs`, `src/UI/MainWindow.xaml`, `VUONGTT_Toolkit.ps1`
- Test: Smoke test, kiểm tra kích thước file, thời gian khởi động.

- [ ] **Step 1:** Đồng bộ tăng version lên `v20.5.909.106`.
- [ ] **Step 2:** Biên dịch file `VUONGTT_Toolkit.exe` mới.
- [ ] **Step 3:** Chạy `VUONGTT_Toolkit.exe --smoke-test` và đo tốc độ khởi động.

---

### Task 4: Git Commit & Git Push Theo Lệnh Người Dùng
- [ ] **Step 1:** `git add -A` và `git commit -m "feat(core): nang cap kien truc C# Native In-Process & In-Memory Execution v20.5.909.106"`
- [ ] **Step 2:** `git push origin main`
- [ ] **Step 3:** Báo cáo chi tiết cho người dùng.
