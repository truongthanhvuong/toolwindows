# Bản Thiết Kế Kiến Trúc Hệ Thống Cứu Hộ & Chẩn Đoán Lỗi IT Helpdesk Windows
## (Windows Troubleshooting & IT Helpdesk Engine Architecture)

- **Ngày ban hành**: 29/09/2026
- **Trạng thái**: Bản thảo thiết kế kiến trúc hoàn thiện (Architectural Design Spec)
- **Tác giả**: Antigravity & VUONGTT Software Team
- **Hệ thống áp dụng**: `VUONGTT_Toolkit.exe` (WPF XAML + PowerShell Core Engine)
- **Tài liệu tham chiếu**: `AGENTS.md` (Quy tắc nâng phiên bản cục bộ & phát hành)

---

## 1. Bối Cảnh & Mục Tiêu Nghiệp Vụ

Trong môi trường quản trị kỹ thuật máy tính (IT Support / Helpdesk / Quản trị hệ thống doanh nghiệp), kỹ thuật viên thường xuyên phải đối mặt với hơn 200 loại sự cố khác nhau từ hệ điều hành, mạng, máy in, tài khoản domain, phần cứng cho đến các bộ phần mềm như Office 365, Teams, OneDrive.

Mục tiêu của dự án là:
1. **Tinh gọn hóa nghiệp vụ**: Gom toàn bộ 43 nhóm lỗi ban đầu (~200+ mã sự cố từ `PERF-001` đến `SYS-010`) thành **7 Danh Mục Chuẩn IT Helpdesk** trực quan, khoa học.
2. **Tích hợp phân tán tự nhiên**: Nhúng trực tiếp các công cụ chẩn đoán và khắc phục sự cố vào các trang tính năng hiện có trong `VUONGTT_Toolkit` (`pageConfig`, `pageCleaner`, `pagePrinterLAN`, `pageUsers`, `pageOffice`, `pageSoftware`, `pageLaptopCheck`, `pageIpScanner`), giúp người dùng thao tác đúng ngữ cảnh mà không làm rối mắt hay tách rời quy trình.
3. **Kiến trúc Dữ liệu Động (Dynamic Knowledgebase & Remediation Engine)**:
   - Lưu trữ toàn bộ tri thức kỹ thuật và kịch bản can thiệp trong `src/Data/TroubleshootDatabase.json`.
   - Engine điều phối tập trung `src/Core/TroubleshootManager.ps1` phụ trách tìm kiếm nhanh, kiểm tra quyền hạn, tạo bản sao lưu an toàn (Registry/Restore Point), chạy script chẩn đoán, sửa lỗi tự động, kiểm tra lại (verify) và cung cấp tài liệu hướng dẫn leo thang (escalation guide).
4. **Lộ trình chia giai đoạn (3-Phase Roadmap)** đảm bảo tính ổn định, dễ kiểm thử và an toàn tuyệt đối cho hệ thống máy trạm của khách hàng.

---

## 2. Phân Loại 7 Danh Mục Chuẩn IT Helpdesk & Bản Đồ Phân Bổ Trang

Hệ thống gom 43 nhóm lỗi ban đầu thành 7 danh mục lớn, ánh xạ vào các trang làm việc tương ứng của `VUONGTT_Toolkit`:

| STT | 7 Danh Mục Chuẩn IT Helpdesk | Mã Nhóm Lỗi Bao Gồm | Trang Tích Hợp Hiện Có Trong App | Mô Tả Trọng Tâm Nghiệp Vụ |
|:---:|:---|:---|:---|:---|
| **01** | **⚡ Hệ Thống & Hiệu Năng Windows** | `PERF`, `SYS`, `UPDATE`, `SVC`, `DISK`, `REC`, `SETTINGS`, `UI` | `pageCleaner` (Dọn dẹp/Tối ưu) & `pageConfig` (Cấu hình & Sửa lỗi) | Treo máy, lag, CPU/RAM/Disk 100%, quạt hú, lỗi Windows Update, dịch vụ bị dừng, hỏng file hệ thống SFC/DISM, ổ đĩa đầy, recovery loop. |
| **02** | **🌐 Mạng & Kết Nối Từ Xa** | `NET`, `VPN`, `RDP`, `FW`, `TIME` | `pageIpScanner` & `pageConfig` | Mất Internet, Wi-Fi chập chờn, APIPA 169.254, lỗi DNS/DHCP, VPN disconnect, Remote Desktop (RDP) lỗi màn hình đen/CredSSP, lệch ngày giờ Kerberos. |
| **03** | **🖨️ Máy In & Chia Sẻ Tệp LAN** | `PRINT`, `SMB`, `FILE`, `PERM` | `pagePrinterLAN` (Sửa Lỗi Máy In - Share LAN) | Kẹt hàng đợi in, Print Spooler stopped, lỗi in mạng LAN 0x0000011b/0x7c/0x709, không truy cập `\\server\share`, Access Denied, NTFS permission. |
| **04** | **👤 Tài Khoản & Active Directory** | `LOGIN`, `PROFILE`, `AD`, `GPO`, `ACT`, `SEC`, `BIT`, `CERT` | `pageUsers`, `pageActivation`, `pageBitLocker` | Quên mật khẩu, Temporary profile, User profile service failed, không join Domain, GPO không apply, Windows chưa activate, BitLocker khóa, TPM lỗi. |
| **05** | **💼 Microsoft Office & M365** | `OFFICE`, `MAIL`, `TEAMS`, `OD`, `SP` | `pageOffice` (Cài đặt & Sửa Office AIO) | Word/Excel/PowerPoint crash/Not Responding, Outlook kẹt Outbox/lỗi OST/PST/hỏi pass, Teams trắng màn hình/mất mic/cam, OneDrive/SharePoint sync conflict/đầy. |
| **06** | **📦 Ứng Dụng & Trình Duyệt** | `APP`, `STORE`, `BROWSER` | `pageSoftware` (Tải ứng dụng) & `pageUninstaller` (Gỡ sạch) | Thiếu DLL (`VCRUNTIME140.dll`, `MSVCP140.dll`), lỗi .NET/Visual C++, app bị chặn bởi Defender/SmartScreen, Microsoft Store không tải, trình duyệt web lỗi SSL/DNS. |
| **07** | **🖥️ Phần Cứng & Thiết Bị Ngoại Vi** | `HW`, `AUDIO`, `DISPLAY`, `USB`, `POWER`, `DRIVER` | `pageLaptopCheck`, `pageBenchmark`, `pageBackupDriver` | Mất âm thanh, mic rè, màn hình chớp nháy/sai scale/không nhận monitor 2, USB unknown device, chuột/phím liệt, laptop không sleep/không sạc, driver lỗi mã Code 10/28/43. |

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
    "Bước 1: Chạy kiểm tra sức khỏe ổ cứng (CrystalDiskInfo / SMART) tại tab 'Sức Khỏe & Tốc Độ Ổ Cứng'.",
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

## 5. Kiến Trúc Giao Diện Người Dùng (UI Component Trong MainWindow.xaml)

Để tích hợp phân tán mượt mà vào từng trang mà không làm xáo trộn bố cục có sẵn, một **Widget Chuẩn Hóa IT Helpdesk** (`TroubleshootDrawer / TroubleshootCard`) được thiết kế theo phong cách Apple Modern UI.

### 5.1. Bố Cục UI Widget Chuẩn
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

Do tổng số lượng hơn 200 mã sự cố rất lớn, dự án được triển khai thành 3 giai đoạn rõ ràng:

### Giai Đoạn 1: Nền Tảng Cốt Lõi & Nhóm Sự Cố Ưu Tiên Cao (Core Engine & Top Priority Pages)
1. **Dữ liệu**: Tạo file `src/Data/TroubleshootDatabase.json` định nghĩa cấu trúc đầy đủ của toàn bộ 7 Danh Mục và nạp toàn bộ danh sách 200+ mã sự cố (mã, tên, triệu chứng, nguyên nhân, hướng dẫn leo thang).
2. **Engine**: Xây dựng `src/Core/TroubleshootManager.ps1` với đầy đủ các hàm nạp dữ liệu, tìm kiếm, kiểm tra quyền, ghi log an toàn.
3. **Kịch bản tự động hóa Đợt 1**: Hoàn thiện 100% logic tự động (Diagnosis, Fix, Verify) cho 3 trang cốt lõi nhất:
   - `pageCleaner` & `pageConfig`: Danh mục 1 (⚡ Hệ Thống & Hiệu Năng Windows, Windows Update).
   - `pageIpScanner`: Danh mục 2 (🌐 Mạng & Kết Nối Từ Xa).
   - `pagePrinterLAN`: Danh mục 3 (🖨️ Máy In & Chia Sẻ Tệp LAN).
4. **Giao diện**: Nhúng Widget Troubleshoot vào `pageConfig`, `pageCleaner`, `pagePrinterLAN` và liên kết sự kiện trong `VUONGTT_Toolkit.ps1`.

### Giai Đoạn 2: Bộ Ứng Dụng Văn Phòng & Phần Mềm (Office, M365 & Applications)
1. Hoàn thiện kịch bản tự động hóa cho Danh mục 5 (💼 Microsoft Office & M365) trên `pageOffice`:
   - Reset Profile Outlook, sửa lỗi kẹt Outbox, khôi phục index tìm kiếm mail, xóa cache Teams, giải phóng xung đột OneDrive sync.
2. Hoàn thiện kịch bản tự động hóa cho Danh mục 6 (📦 Ứng Dụng & Trình Duyệt) trên `pageSoftware` và `pageUninstaller`:
   - Tự động phát hiện và cài đặt trọn bộ Visual C++ Runtimes (2005-2022) và .NET Framework để sửa lỗi Missing DLL (`VCRUNTIME140.dll`, `MSVCP140.dll`), reset Microsoft Store cache (`wsreset.exe`).

### Giai Đoạn 3: Tài Khoản, Domain, Bảo Mật & Phần Cứng (Account, AD, Security & Hardware)
1. Hoàn thiện kịch bản tự động hóa cho Danh mục 4 (👤 Tài Khoản & Active Directory) trên `pageUsers` và `pageBitLocker`:
   - Khắc phục lỗi Temporary Profile, reset secure channel domain, cập nhật GPO (`gpupdate /force`), quản lý trạng thái BitLocker.
2. Hoàn thiện kịch bản tự động hóa cho Danh mục 7 (🖥️ Phần Cứng & Thiết Bị Ngoại Vi) trên `pageLaptopCheck` và `pageBackupDriver`:
   - Khởi động lại Windows Audio service, reset TCP/IP và Network driver, reset GPU driver (`Win + Ctrl + Shift + B`), kiểm tra pin và quản lý chế độ Sleep/Hibernate.

---

## 7. Quy Tắc Kiểm Thử & Quản Trị Phiên Bản (Tuân Thủ AGENTS.md)

1. **Local Version Bump**:
   - Khi hoàn thành từng giai đoạn hoặc sửa lỗi: Tăng 1 số Build Increment (ví dụ: `v20.5.909.56` -> `v20.5.909.57`).
   - Cập nhật đồng bộ tại 5 vị trí: `version.json`, `MainWindow.xaml`, `src/Program.cs`, `AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`.
   - Biên dịch ra file thực thi `E:\toolwindows\VUONGTT_Toolkit.exe` bằng `Build-Exe.ps1`.
2. **Kiểm thử cục bộ**:
   - Chạy thử trực tiếp `VUONGTT_Toolkit.exe` trên máy tính để kiểm tra Window Title, Logo Header, nạp danh sách sự cố, tìm kiếm mã lỗi và chạy thử nghiệm các hàm Fix.
3. **Tuyệt đối không chạy `git push`**:
   - Chỉ tạo commit lưu trữ lịch sử tại git local.
   - Để người dùng tự quyết định thời điểm phát hành qua `Publish-Update.ps1`.
