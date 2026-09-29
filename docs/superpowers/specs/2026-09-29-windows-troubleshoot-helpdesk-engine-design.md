# Bản Thiết Kế Kiến Trúc Hệ Thống Cứu Hộ IT Helpdesk & Tinh Gọn Sidebar Tabs
## (Windows Troubleshooting Engine & Streamlined 8-Tab Architecture)

- **Ngày ban hành**: 29/09/2026
- **Trạng thái**: Bản thảo thiết kế kiến trúc hoàn thiện (Architectural Design Spec - Revision 2)
- **Tác giả**: Antigravity & VUONGTT Software Team
- **Hệ thống áp dụng**: `VUONGTT_Toolkit.exe` (WPF XAML + PowerShell Core Engine)
- **Tài liệu tham chiếu**: `AGENTS.md` (Quy tắc nâng phiên bản cục bộ & phát hành)
- **Hình ảnh tham chiếu**:
  - `media_1790664582237.png` & `media_1790664588525.png`: Giao diện Sidebar hiện tại bị cuộn dài với 19 menu đơn lẻ.

---

## 1. Bối Cảnh & Mục Tiêu Nghiệp Vụ

Trong phiên bản hiện tại (`v20.5.909.56`), thanh Sidebar bên trái của `VUONGTT_Toolkit` có tới **6 Group với 19 Menu Buttons đơn lẻ**, khiến thanh cuộn (ScrollBar) bị kéo dài, người dùng phải cuộn lên cuộn xuống liên tục để tìm kiếm công cụ cần dùng.

Đồng thời, khi bổ sung kho tri thức và công cụ xử lý **hơn 200+ mã lỗi IT Helpdesk Windows** (từ `PERF-001` đến `SYS-010`), nếu tiếp tục thêm các nút đơn lẻ sẽ gây quá tải thị giác và khó bảo trì.

### Mục tiêu thiết kế:
1. **Tinh chỉnh lại toàn bộ Sidebar thành 8 Tab Chính Chuẩn Apple** (Apple Segmented Navigation): Gọn gàng, vừa vặn khung nhìn, loại bỏ hoàn toàn tình trạng cuộn trang dài ở sidebar. Mỗi tab chính sẽ quản lý các phân hệ con thông qua thanh **Sub-tabs (Capsule / Pill Bar)** hiện đại.
2. **Gom toàn bộ 43 nhóm lỗi thành 7 Danh Mục Chuẩn IT Helpdesk**: Tích hợp các bộ công cụ chẩn đoán và khắc phục sự cố trực tiếp vào từng tab chức năng tương ứng.
3. **Kiến Trúc Dữ Liệu Động (Dynamic Knowledgebase & Remediation Engine)**:
   - Lưu trữ tri thức lỗi và kịch bản can thiệp trong `src/Data/TroubleshootDatabase.json`.
   - Engine điều phối trung tâm `src/Core/TroubleshootManager.ps1` phụ trách tìm kiếm mã lỗi/từ khóa, kiểm tra quyền hạn, sao lưu an toàn, chạy script chẩn đoán, sửa lỗi tự động, kiểm tra lại (verify) và cung cấp tài liệu hướng dẫn leo thang (escalation guide).

---

## 2. Kiến Trúc Tinh Gọn: Tái Cấu Trúc 19 Tabs Thành 8 Tab Chính Chuẩn Apple

| STT | 8 Tab Chính Trên Sidebar | Biểu Tượng & Mã Tag | Các Tab Cũ Được Tích Hợp (Sub-tabs bên trong) | Danh Mục IT Helpdesk Tương Ứng |
|:---:|:---|:---|:---|:---|
| **1** | **Thông Tin & Cấu Hình** | 🖥️ `SysInfo` | • Xem Cấu Hình Máy (`pageSysInfo`)<br>• Tùy chỉnh OEM (`pageCustomize`)<br>• Tra cứu CPU + Main (`pageCpuMain`) | Thông tin phần cứng, BIOS/UEFI, CPU, RAM |
| **2** | **Tối Ưu & Sửa Lỗi Win** | ⚡ `SystemFix` | • Tối Ưu & Dọn Dẹp Tweaks (`pageCleaner`)<br>• Cấu Hình & Sửa Lỗi Win (`pageConfig`)<br>• Khắc Phục Treo Lag / Disk 100% | **01. Hệ Thống & Hiệu Năng Windows** (`PERF`, `SYS`, `UPDATE`, `SVC`, `DISK`, `REC`) |
| **3** | **Mạng & IP Scanner** | 🌐 `NetworkLAN` | • Advanced IP Scanner (`pageIpScanner`)<br>• Chẩn đoán Internet, Wi-Fi, Ping, DNS<br>• Cấu hình VPN & Remote Desktop (RDP) | **02. Mạng & Kết Nối Từ Xa** (`NET`, `VPN`, `RDP`, `FW`, `TIME`) |
| **4** | **Máy In & Chia Sẻ LAN** | 🖨️ `PrinterLAN` | • Sửa Lỗi Máy In 87 Chức Năng (`pagePrinterLAN`)<br>• Chia sẻ thư mục SMB, Credentials<br>• Sửa quyền truy cập Access Denied | **03. Máy In & Chia Sẻ Tệp LAN** (`PRINT`, `SMB`, `FILE`, `PERM`) |
| **5** | **Office & Microsoft 365** | 💼 `OfficeAIO` | • Cài Đặt Office Tự Động (`pageOffice`)<br>• Sửa lỗi Word, Excel, PowerPoint<br>• Sửa Outlook, Teams, OneDrive & SharePoint | **05. Microsoft Office & M365** (`OFFICE`, `MAIL`, `TEAMS`, `OD`, `SP`) |
| **6** | **Quản Lý Phần Mềm** | 📦 `SoftwareHub` | • Tải ứng dụng (`pageSoftware`)<br>• Cài app tùy chỉnh (`pageCustomApp`)<br>• Gỡ bỏ sạch (`pageUninstaller`)<br>• Cài font tiếng Việt (`pageFonts`) | **06. Ứng Dụng & Trình Duyệt** (`APP`, `STORE`, `BROWSER`, Missing DLL) |
| **7** | **Ổ Cứng & Phần Cứng** | 💽 `HardwareDisk` | • Sức Khỏe & Tốc Độ Ổ Cứng (`pageBenchmark`)<br>• Quản Lý Phân Vùng (`pagePartition`)<br>• Kiểm Tra Laptop & Ngoại Vi (`pageLaptopCheck`) | **07. Phần Cứng & Thiết Bị Ngoại Vi** (`HW`, `AUDIO`, `DISPLAY`, `USB`, `POWER`, `DRIVER`) |
| **8** | **Tiện Ích Kỹ Thuật** | 🛠️ `TechUtilities` | • Kích Hoạt MAS HWID (`pageActivation`)<br>• Tắt BitLocker - EFS (`pageBitLocker`)<br>• Sao Lưu Win & Driver (`pageBackupDriver`)<br>• Cài Win & Bypass (`pageAutoWin`)<br>• Quản Lý User & Admin Portal (`pageUsers`, `pageAdminPortal`) | **04. Tài Khoản & Active Directory** (`LOGIN`, `PROFILE`, `AD`, `GPO`, `ACT`, `SEC`, `BIT`, `CERT`) |

---

## 3. Kiến Trúc Dữ Liệu: `src/Data/TroubleshootDatabase.json`

File JSON được thiết kế có cấu trúc phân cấp chặt chẽ:
`Category` -> `SubCategory` -> `Problem` -> `Metadata + Diagnostic + Fix + Verification + Escalation`.

### 3.1. Định Dạng Schema Chi Tiết Của Một Sự Cố (Problem Object)
```json
{
  "Id": "PERF-011",
  "Category": "01. Windows / Operating System",
  "SubCategory": "Disk Performance",
  "TargetPage": "pageCleaner",
  "Title": "Disk 100% (Ổ đĩa hoạt động tối đa gây đơ máy)",
  "ErrorCode": "DISK_100_HIGH_IO",
  "Symptoms": [
    "Task Manager luôn hiển thị Disk 100%",
    "Máy bị giật lag, mở phần mềm mất nhiều phút",
    "Đèn ổ cứng HDD/SSD sáng liên tục không tắt"
  ],
  "Cause": "Do dịch vụ SysMain (Superfetch), Windows Search Indexer hoặc tính năng StorAHCI MSI (Message Signaled Interrupts) gây xung đột với driver SSD/HDD.",
  "Diagnosis": {
    "Type": "PowerShell",
    "Script": "Test-VUONGTTDisk100Usage"
  },
  "Fix": {
    "Type": "PowerShell",
    "RequiresAdmin": true,
    "NeedsReboot": false,
    "Script": "Invoke-VUONGTTFixDisk100"
  },
  "Verification": {
    "Type": "PowerShell",
    "Script": "Test-VUONGTTDiskUsageNormal"
  },
  "Escalation": [
    "Bước 1: Chạy kiểm tra sức khỏe ổ cứng (CrystalDiskInfo / SMART) tại tab 'Ổ Cứng & Phần Cứng'.",
    "Bước 2: Nếu ổ cứng có cảnh báo Caution hoặc nhiều Bad Sector, tiến hành sao lưu dữ liệu khẩn cấp và thay thế SSD mới."
  ]
}
```

---

## 4. Kiến Trúc Module Xử Lý: `src/Core/TroubleshootManager.ps1`

File `TroubleshootManager.ps1` chịu trách nhiệm toàn bộ logic xử lý dữ liệu và môi trường chạy lệnh an toàn.

### 4.1. Các Hàm API Nòng Cốt
1. `Initialize-VUONGTTTroubleshootEngine`:
   - Nạp file `TroubleshootDatabase.json` vào biến bộ nhớ `$global:VUONGTT_TroubleshootDB`.
   - Khởi tạo thư mục ghi log tại `C:\ProgramData\VUONGTT_Toolkit\Logs\Troubleshoot.log`.

2. `Get-VUONGTTTroubleshootProblems`:
   - Tham số: `-Category <string>`, `-TargetPage <string>`, `-SubCategory <string>`.
   - Trả về danh sách đối tượng sự cố đã lọc tương ứng để hiển thị lên từng trang giao diện.

3. `Search-VUONGTTTroubleshootProblem`:
   - Tham số: `-Query <string>`.
   - Tìm kiếm nhanh bằng Regex không phân biệt hoa thường trên: `Id`, `Title`, `ErrorCode`, `Symptoms`. Hỗ trợ tìm mã lỗi trực tiếp như `0x80070002`, `NET-001`, `0x11b`.

4. `Invoke-VUONGTTTroubleshootAction`:
   - Tham số: `-ProblemId <string>`, `-ActionType <"Diagnosis" | "Fix" | "Verify">`.
   - **Quy trình thực thi chuẩn (Standard Execution Pipeline)**:
     1. Lấy thông tin sự cố theo `Id`.
     2. Kiểm tra quyền `Administrator`. Nếu không đủ quyền, cảnh báo yêu cầu chạy Run as Administrator.
     3. Nếu là `Fix`: Tự động sao lưu registry key liên quan vào `C:\ProgramData\VUONGTT_Toolkit\Backups\Registry\` trước khi ghi đè giá trị.
     4. Kích hoạt hàm script tương ứng (có thể nằm trong `TroubleshootManager.ps1` hoặc liên kết gọi các hàm có sẵn trong `SystemTweaks.ps1`, `ConfigManager.ps1`, `NetworkPrinterFix.ps1`).
     5. Bắt ngoại lệ `try/catch`, ghi log vào `Troubleshoot.log`.
     6. Trả về kết quả có cấu trúc:
        `@{ Success = $true/$false; StatusText = "..."; OutputDetails = "..."; NeedsReboot = $false }`.

---

## 5. Kiến Trúc Giao Diện Người Dùng (UI Component & Sub-tabs Layout)

### 5.1. Cấu Trúc Sidebar Mới Trong `MainWindow.xaml`
Thanh cuộn dọc bên trái được thay bằng một danh sách 8 nút Apple Card sang trọng, không còn các Header nhóm cồng kềnh, kèm theo icon trực quan và nhãn song ngữ:
1. `btnMenuSysInfo` (Tag="SysInfo") - 🖥️ Thông Tin & Cấu Hình
2. `btnMenuSystemFix` (Tag="SystemFix") - ⚡ Tối Ưu & Sửa Lỗi Win
3. `btnMenuNetworkLAN` (Tag="NetworkLAN") - 🌐 Mạng & IP Scanner
4. `btnMenuPrinterLAN` (Tag="PrinterLAN") - 🖨️ Máy In & Chia Sẻ LAN
5. `btnMenuOffice` (Tag="OfficeAIO") - 💼 Office & Microsoft 365
6. `btnMenuSoftware` (Tag="SoftwareHub") - 📦 Quản Lý Phần Mềm
7. `btnMenuHardwareDisk` (Tag="HardwareDisk") - 💽 Ổ Cứng & Phần Cứng
8. `btnMenuTechUtilities` (Tag="TechUtilities") - 🛠️ Tiện Ích Kỹ Thuật

### 5.2. Widget IT Helpdesk Chuẩn Hóa Nhúng Vào Các Trang
```
┌────────────────────────────────────────────────────────────────────────┐
│ 🛠️ TRUNG TÂM KHẮC PHỤC SỰ CỐ THEO CHUYÊN MỤC                          │
│ [🔍 Nhập mã lỗi (0x80070002, PERF-001...), từ khóa sự cố...] [🧹 Xóa]  │
├────────────────────────────────────────────────────────────────────────┤
│ ┌─ Danh Sách Sự Cố Thường Gặp (DataGrid / ListBox Thẻ Bo Tròn) ──────┐ │
│ │ [⚡ PERF-011] Disk 100% (Ổ đĩa hoạt động tối đa gây đơ máy)         │ │
│ │ [⚡ PERF-009] CPU 100% (Tắc nghẽn tiến trình xử lý)                │ │
│ │ [⚡ PERF-001] Máy chạy chậm, phản hồi kém                           │ │
│ └────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────────────────┤
│ 📋 THÔNG TIN CHI TIẾT SỰ CỐ ĐANG CHỌN:                                  │
│ • Triệu chứng: Task Manager Disk 100%, máy giật lag, đèn HDD sáng liên tục │
│ • Nguyên nhân: Xung đột SysMain, Windows Search hoặc StorAHCI MSI       │
├────────────────────────────────────────────────────────────────────────┤
│ 🎮 BỘ CÔNG CỤ XỬ LÝ 4 BƯỚC:                                            │
│ [🔍 1. Chẩn Đoán]  [⚡ 2. Tự Động Sửa]  [✅ 3. Kiểm Tra Lại] [📖 Hướng Dẫn]│
├────────────────────────────────────────────────────────────────────────┤
│ 💻 NHẬT KÝ THỰC THI (Real-time Log Output Box):                        │
│ [OK] Dịch vụ SysMain đã được chuyển sang Manual/Disabled.              │
│ [OK] Đã tinh chỉnh giá trị StorAHCI MSI trong Registry.                │
│ [HOÀN TẤT] Tự động sửa lỗi Disk 100% thành công. Mức Disk giảm về 4%.   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Lộ Trình Triển Khai Chia 3 Giai Đoạn (Phased Roadmap)

### Giai Đoạn 1: Tinh Gọn Sidebar 8 Tabs + Nền Tảng Core Engine + Sự Cố Ưu Tiên Cao
1. **Sidebar Restructuring**: Tinh gọn thanh Menu Sidebar thành 8 Tab chính chuẩn Apple. Tái cấu trúc chuyển trang trong `MainWindow.xaml` và `VUONGTT_Toolkit.ps1` bằng hệ thống Sub-tabs.
2. **Dữ liệu**: Tạo file `src/Data/TroubleshootDatabase.json` định nghĩa 7 Danh Mục và nạp đầy đủ danh sách 200+ mã sự cố.
3. **Engine**: Xây dựng `src/Core/TroubleshootManager.ps1` nạp dữ liệu, tìm kiếm, kiểm tra quyền, ghi log an toàn.
4. **Kịch bản tự động hóa Đợt 1**: Hoàn thiện 100% logic tự động (Diagnosis, Fix, Verify) cho 3 cụm trọng tâm:
   - Tab 2 (Tối Ưu & Sửa Lỗi Win): Danh mục 1 (⚡ Hệ Thống & Hiệu Năng Windows, Windows Update, Disk 100%).
   - Tab 3 (Mạng & IP Scanner): Danh mục 2 (🌐 Mạng & Kết Nối Từ Xa).
   - Tab 4 (Máy In & Chia Sẻ LAN): Danh mục 3 (🖨️ Máy In & Chia Sẻ Tệp LAN).

### Giai Đoạn 2: Bộ Ứng Dụng Văn Phòng & Quản Lý Phần Mềm
1. Hoàn thiện kịch bản tự động hóa cho Danh mục 5 (💼 Microsoft Office & M365) trên Tab 5 (`OfficeAIO`):
   - Reset Profile Outlook, sửa lỗi kẹt Outbox, khôi phục index tìm kiếm mail, xóa cache Teams, giải phóng xung đột OneDrive/SharePoint sync.
2. Hoàn thiện kịch bản tự động hóa cho Danh mục 6 (📦 Ứng Dụng & Trình Duyệt) trên Tab 6 (`SoftwareHub`):
   - Tự động phát hiện và cài đặt trọn bộ Visual C++ Runtimes (2005-2022) và .NET Framework để sửa lỗi Missing DLL (`VCRUNTIME140.dll`, `MSVCP140.dll`), reset Microsoft Store cache (`wsreset.exe`).

### Giai Đoạn 3: Tài Khoản, Domain, Bảo Mật, Ổ Cứng & Phần Cứng
1. Hoàn thiện kịch bản tự động hóa cho Danh mục 4 (👤 Tài Khoản & Active Directory) trên Tab 8 (`TechUtilities`):
   - Khắc phục lỗi Temporary Profile, reset secure channel domain, cập nhật GPO (`gpupdate /force`), quản lý trạng thái BitLocker.
2. Hoàn thiện kịch bản tự động hóa cho Danh mục 7 (🖥️ Phần Cứng & Thiết Bị Ngoại Vi) trên Tab 7 (`HardwareDisk`):
   - Khởi động lại Windows Audio service, reset TCP/IP và Network driver, reset GPU driver (`Win + Ctrl + Shift + B`), kiểm tra pin và quản lý chế độ Sleep/Hibernate.

---

## 7. Quy Tắc Kiểm Thử & Quản Trị Phiên Bản (Tuân Thủ AGENTS.md)

1. **Local Version Bump**:
   - Khi hoàn thành từng giai đoạn hoặc sửa lỗi: Tự động tăng 1 số Build Increment (ví dụ: `v20.5.909.56` -> `v20.5.909.57`).
   - Cập nhật đồng bộ tại 5 vị trí: `version.json`, `MainWindow.xaml`, `src/Program.cs`, `AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`.
   - Biên dịch ra file thực thi `E:\toolwindows\VUONGTT_Toolkit.exe` bằng `Build-Exe.ps1`.
2. **Kiểm thử cục bộ**:
   - Chạy thử trực tiếp `VUONGTT_Toolkit.exe` trên máy tính để kiểm tra Window Title, Logo Header, Sidebar mới 8 tabs không bị cuộn, chuyển tab mượt mà, nạp danh sách sự cố và chạy thử nghiệm các hàm Fix.
3. **Tuyệt đối không chạy `git push`**:
   - Chỉ tạo commit lưu trữ lịch sử tại git local.
   - Để người dùng tự quyết định thời điểm phát hành qua `Publish-Update.ps1`.
