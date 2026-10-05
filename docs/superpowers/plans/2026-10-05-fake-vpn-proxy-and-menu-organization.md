# Fake VPN / Proxy & Professional Menu Organization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm module "Fake VPN / Proxy" hoàn chỉnh với bản đồ thế giới đồ họa tương tác, kiểm tra thông tin mạng (IP public, ISP, DNS, ping/speed test), quản lý System Proxy & DNS theo quốc gia, đồng thời tái cấu trúc toàn bộ hệ thống Sidebar Menu thành 18 mục phân loại chi tiết, dễ nhìn chuẩn Toolkit 2026 như trong ảnh.

**Architecture:** Tạo module backend `src/Core/VpnProxyManager.ps1` xử lý truy vấn mạng an toàn (WebClient / HttpClient với timeout chặt chẽ), thiết lập/gỡ bỏ System Proxy qua Win32 Registry `Software\Microsoft\Windows\CurrentVersion\Internet Settings`, và DNS switcher; thiết kế giao diện WPF XAML `pageFakeVpnProxy` với Canvas bản đồ thế giới đêm trực quan và các widget thẻ thông tin mạng; sắp xếp lại Sidebar Menu trong `src/UI/MainWindow.xaml` và bộ điều hướng `Switch-Tab` trong `VUONGTT_Toolkit.ps1` đảm bảo 100% tương thích ngược.

**Tech Stack:** C#, PowerShell 5.1 / 7+, WPF XAML (Canvas, Polyline, Path, Ellipse), Windows Networking API (WinINet, Registry, NetTCPIP).

**Spec:** Yêu cầu người dùng kèm 2 ảnh `media_1791180916319.png` (Fake VPN / Proxy) và `media_1791180968975.png` (Sidebar menu phân loại trực quan & AutoWin).

## Global Constraints

- Tuân thủ quy tắc Superpowers: TDD (RED -> GREEN), cập nhật `task.md`, phân tích tác động, xác thực thực tế.
- Tuân thủ `AGENTS.md`: Tự động tăng build version (`v20.5.909.87` -> `v20.5.909.88`), biên dịch `VUONGTT_Toolkit.exe`, chỉ push git khi hoàn tất và xác thực thành công.
- Giữ nguyên UTF-8 BOM trên toàn bộ tệp mã nguồn.

---

### Task 1: Bộ Test TDD Ban Đầu (RED Phase)

**Files:**
- Create: `tests/Test-FakeVpnProxyAndMenu.Tests.ps1`

**Interfaces:**
- Consumes: `src/Core/VpnProxyManager.ps1`, `src/UI/MainWindow.xaml`, `VUONGTT_Toolkit.ps1`
- Produces: Test suite kiểm tra hàm `Get-VUONGTTNetworkCheckup`, `Set-VUONGTTSystemProxy`, `Reset-VUONGTTNetworkToDefault`, `Get-VUONGTTProxyCountries`, sự tồn tại của `pageFakeVpnProxy` và nút `btnMenuFakeVpnProxy`.

- [ ] **Step 1: Viết test failing `tests/Test-FakeVpnProxyAndMenu.Tests.ps1`**
- [ ] **Step 2: Chạy test để xác nhận FAIL (RED)**

---

### Task 2: Hiện Thực Module Lõi VpnProxyManager.ps1

**Files:**
- Create: `src/Core/VpnProxyManager.ps1`

**Interfaces:**
- Consumes: Network Web APIs (`ip-api.com`, `icanhazip.com`), Registry `Internet Settings`
- Produces:
  - `Get-VUONGTTNetworkCheckup`: Lấy IPv4 Public, Country, City, ISP, DNS, Local IP, MAC
  - `Get-VUONGTTProxyCountries`: Danh sách quốc gia có sẵn proxy/VPN (Việt Nam, Singapore, Mỹ, Nhật, v.v.)
  - `Set-VUONGTTSystemProxy`: Bật Proxy HTTP/SOCKS5 cho Windows
  - `Reset-VUONGTTNetworkToDefault`: Tắt Proxy, reset DNS về DHCP Router, flush DNS cache

- [ ] **Step 1: Viết mã nguồn cho `src/Core/VpnProxyManager.ps1`**
- [ ] **Step 2: Đảm bảo UTF-8 BOM cho `src/Core/VpnProxyManager.ps1`**

---

### Task 3: Thiết Kế Trang XAML & Tái Cấu Trúc Sidebar Menu

**Files:**
- Modify: `src/UI/MainWindow.xaml`

**Interfaces:**
- Consumes: Static resources, Canvas, Menu styles
- Produces:
  - Tái cấu trúc Menu Sidebar thành 18 mục chi tiết, dễ nhìn có icon đẹp mắt
  - Thiết kế `pageFakeVpnProxy`: Cột trái (Thông tin Checkup, Trạng thái Proxy, Lưu lượng, Nút Bật/Tắt VPN tròn, Nút Phục hồi mặc định mạng gốc) + Cột phải (Combobox Quốc gia, Bản đồ thế giới đồ họa với các điểm node phát sáng và đường bay kết nối)

- [ ] **Step 1: Cập nhật Sidebar Menu trong `src/UI/MainWindow.xaml`**
- [ ] **Step 2: Thêm Grid `pageFakeVpnProxy` vào Pages Container trong `src/UI/MainWindow.xaml`**

---

### Task 4: Kết Nối Bộ Điều Khiển Trong VUONGTT_Toolkit.ps1 & Build Script

**Files:**
- Modify: `VUONGTT_Toolkit.ps1`
- Modify: `Build-Exe.ps1`
- Modify: `src/Program.cs`

**Interfaces:**
- Consumes: `VpnProxyManager.ps1`, `pageFakeVpnProxy`, `btnMenuFakeVpnProxy`
- Produces: Gắn sự kiện chuyển tab, cập nhật dữ liệu mạng định kỳ/realtime, tương tác vẽ tuyến đường trên bản đồ thế giới đồ họa.

- [ ] **Step 1: Thêm nạp module `VpnProxyManager.ps1` và nhúng vào `Build-Exe.ps1` & `Program.cs`**
- [ ] **Step 2: Gắn sự kiện `Switch-Tab` và điều khiển kết nối VPN/Proxy trong `VUONGTT_Toolkit.ps1`**
- [ ] **Step 3: Chạy test `Test-FakeVpnProxyAndMenu.Tests.ps1` xác nhận PASS (GREEN)**

---

### Task 5: Kiểm Thử Toàn Diện, Nâng Version, Biên Dịch & Git Push

**Files:**
- Modify: `version.json`
- Modify: `src/Program.cs`
- Modify: `src/UI/MainWindow.xaml`
- Modify: `src/Core/AppUpdater.ps1`
- Modify: `VUONGTT_Toolkit.ps1`
- Output: `VUONGTT_Toolkit.exe`

- [ ] **Step 1: Áp dụng UTF-8 BOM và kiểm tra cú pháp AST**
- [ ] **Step 2: Chạy toàn bộ các test suites của dự án**
- [ ] **Step 3: Nâng version lên `v20.5.909.88` và chạy `Build-Exe.ps1`**
- [ ] **Step 4: Chạy `tests/verify_build.ps1` xác thực file exe**
- [ ] **Step 5: Commit Git cục bộ và đẩy lên GitHub (`git push origin main`)**
