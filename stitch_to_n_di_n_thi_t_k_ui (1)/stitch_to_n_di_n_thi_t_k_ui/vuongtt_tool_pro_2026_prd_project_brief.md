# VUONGTT Tool Pro 2026 — Product Requirements Document (PRD) & Project Brief

**Tên dự án:** VUONGTT Tool Pro 2026 (Hệ Thống Tiện Ích Kỹ Thuật IT Helpdesk & Quản Trị Hệ Điều Hành Windows Chuẩn Doanh Nghiệp)  
**Phiên bản tài liệu:** v2.0 - Production Specification  
**Ngày phát hành:** 31/03/2026  
**Chủ nhiệm dự án / Thiết kế hệ thống:** VUONGTT System Labs  
**Design System:** Fluent OS Utility (Dark Mode / Mica Accent)  
**Nền tảng mục tiêu:** Windows 10/11 (x64 / ARM64), Hỗ trợ WinPE 2026 & Môi trường cứu hộ IT  

---

## 1. TỔNG QUAN DỰ ÁN (EXECUTIVE SUMMARY)

### 1.1 Bối Cảnh & Vấn Đề
Trong công tác kỹ thuật máy tính, IT Helpdesk doanh nghiệp và dịch vụ cài đặt - bảo dưỡng PC/Laptop:
- Các kỹ thuật viên hiện nay phải dùng hàng chục công cụ rời rạc (Rufus, CrystalDiskInfo, 3DP Chip, Winget, Office C2R Install, MAS, UltraViewer, Dism++, DiskGenius...).
- Giao diện của các tool truyền thống thường lỗi thời, font chữ không đồng nhất, độ tương phản kém và trải nghiệm người dùng phân mảnh.
- Thiếu giải pháp tập trung, 1-Click tự động hóa cho các tác vụ lặp đi lặp lại: cài Windows không cần USB, bypass TPM/SecureBoot/OOBE, sửa lỗi chia sẻ máy in LAN (0x0000011b), kích hoạt bản quyền số HWID và chẩn đoán phần cứng realtime.

### 1.2 Tầm Nhìn & Mục Tiêu (Product Vision)
**VUONGTT Tool Pro 2026** là hệ thống phần mềm all-in-one cao cấp dành riêng cho IT Administrator và kỹ thuật viên phần cứng/phần mềm. Ứng dụng gom toàn bộ 13 phân hệ chức năng (9 tính năng cốt lõi + 4 tab mở rộng) vào một hệ sinh thái đồng nhất với phong cách thiết kế **Fluent OS Utility**, đem lại hiệu suất vượt trội, trực quan và chuyên nghiệp.

---

## 2. NGƯỜI DÙNG MỤC TIÊU & CHÂN DUNG (PERSONAS)

1. **IT Helpdesk & System Administrator Doanh Nghiệp:**
   - Quản trị hàng trăm máy trạm, cần triển khai nhanh Office, phần mềm hàng loạt qua Winget/CDN, sửa lỗi máy in nội bộ trong 1 click và hỗ trợ từ xa nhanh qua UltraViewer/RustDesk.
2. **Kỹ Thuật Viên Cửa Hàng Máy Tính & Cứu Hộ Dạo (PC Technician):**
   - Cần cài Win siêu tốc không cần USB, bypass kiểm tra phần cứng trên các mainboard đời cũ, nạp driver tự động, đóng dấu bản quyền OEM (ASUS ROG, Alienware, Dell, ThinkPad...) và xuất báo cáo bàn giao máy cho khách.
3. **Power User & Vọc Sĩ Công Nghệ:**
   - Theo dõi phần cứng realtime, benchmark nhanh, tinh chỉnh Windows Tweak, tối ưu RAM/Compact OS, quản lý phân vùng và cấu hình VPN/Proxy bảo mật.

---

## 3. KIẾN TRÚC THÔNG TIN & DANH SÁCH 13 MÀN HÌNH (INFORMATION ARCHITECTURE)

Hệ thống được chia thành 2 khối màn hình chính:

### PHẦN I: 9 MÀN HÌNH CHỨC NĂNG CỐT LÕI (CORE MODULES)

| STT | Tên Phân Hệ | Mục Tiêu & Chức Năng Chính | Thông Số & Engine Tích Hợp |
|---|---|---|---|
| **01** | **Xem Cấu Hình & Giám Sát Hệ Thống** | Giám sát realtime 6 cụm phần cứng: CPU, RAM, GPU, NVMe SSD, Mạng Wi-Fi/LAN, Nguồn điện & Pin. Hiển thị đồ thị xung nhịp, donut chart phân bổ bộ nhớ và bảng xếp hạng tiến trình ngốn tài nguyên. | Polling rate 1000ms, WMI / NT Kernel API, Hardware Monitor Engine |
| **02** | **Cài Win & Bypass Windows 11/10** | Triển khai cài Win trực tiếp từ ổ cứng (Direct Deploy không cần USB Boot). Quy trình 3 bước trực quan: Chọn ISO & Check SHA256 -> Chế độ Cài Đè/Cài Mới -> Tùy chọn Bypass TPM 2.0, SecureBoot, RAM, Microsoft Account OOBE, sao lưu driver. | WinPE Injection Hook, DirectEFI v4.8, Unattend XML Generator |
| **03** | **Tiện Ích Kỹ Thuật & Driver** | Quét chẩn đoán 218 thiết bị PnP. Tự động tìm & cài Driver thiếu qua Microsoft Update Catalog; tích hợp bộ cài Driver SDIO, 3DP Chip, 3DP Net. Trích xuất sao lưu Driver tĩnh dạng DISM. | WHQL Signature Enforced, Dism /Export-Driver Engine, ACPI Monitor |
| **04** | **Tối Ưu & Sửa Lỗi Win** | Thanh thao tác 1-Click: Dọn rác tạm, dọn WinSxS, nén Compact OS (tiết kiệm 3-6GB), sửa file hệ thống SFC / DISM. Bảng Tweak phân loại Cơ Bản An Toàn & Nâng Cao. Switch cá nhân hóa giao diện và kích hoạt profile Ultimate Performance. | AI Engine v20.5 Tweak, Registry Batch Injector, Power Scheme API |
| **05** | **Cài Đặt Office M365** | Trình cài đặt Office tự động (ODT Engine). Hỗ trợ Office 2016 - 2024 & Microsoft 365 Enterprise. Chọn kiến trúc 64/32-bit, ngôn ngữ chính/phụ, chọn lọc ứng dụng (Word, Excel, PowerPoint, Outlook...) và Console Log ODT realtime. | Click-to-Run (C2R) Client, Office Deployment Tool v16.0, MS CDN Mirror |
| **06** | **Máy In, Scan & LAN** | Khắc phục triệt để lỗi chia sẻ máy in nội bộ Windows 10/11 (0x0000011b, 0x00000709, 0x0000007c). 1-Click Fix toàn bộ LAN, cấu hình RPC Auth Level, nạp port in TCP/IP và khởi động lại Print Spooler. | Print Spooler Service Hook, LanmanWorkstation Registry Patch, RPC Host Monitor |
| **07** | **Phân Vùng & Ổ Cứng SMART** | Chuẩn đoán chuyên sâu CrystalDiskInfo: Sức khỏe 99% Good, nhiệt độ 36°C, giờ chạy, số lần bật/tắt, tuổi thọ ô nhớ NAND. Bảng chi tiết 10+ thuộc tính S.M.A.R.T (Read Error Rate, Reallocated Sectors...) và đo tốc độ SSD. | CrystalDiskInfo Core v9.4, NVMe Passthrough API, Chkdsk Engine |
| **08** | **Kho Phần Mềm & Winget** | Trung tâm tải & cài đặt ứng dụng phân nhóm: Trình duyệt, Chat/Liên lạc, Lập trình/Dev, Văn phòng đồ họa. Hỗ trợ tích chọn hàng loạt để cài đặt im lặng (Silent Unattended) qua Winget CLI hoặc Direct CDN. | Winget CLI v1.8 Engine, Multi-thread CDN Direct Download, App Uninstaller |
| **09** | **Fake VPN / SOCKS5 Proxy** | Giám sát IP công cộng, vị trí ISP, ping ICMP. Bản đồ định tuyến cáp mạng toàn cầu (Global Route Map) và module thiết lập Proxy nội bộ (SOCKS5/HTTP Host & Port). | WinINet API & WFP Engine, DNS-over-HTTPS (DoH), Proxy Switcher |

---

### PHẦN II: 4 TAB CHỨC NĂNG PHỤ CHUYÊN SÂU (ADVANCED SUB-TABS)

| STT | Tên Phân Hệ Phụ | Mục Tiêu & Trải Nghiệm Giao Diện | Công Nghệ Áp Dụng |
|---|---|---|---|
| **10** | **Tùy Chỉnh OEM & Thương Hiệu Máy** | Đổi trực tiếp thông tin hãng sản xuất hiển thị trong Windows Settings > About. Cung cấp 9 preset hãng (ASUS ROG, Alienware, Lenovo Legion, HP Omen, MSI, ThinkPad...), nạp Logo OEM 120x120px và đóng dấu bản quyền winver. | HKLM OEMInformation Registry Injection, Live Preview Framework |
| **11** | **Kích Hoạt Bản Quyền Số HWID** | Cấp phép kỹ thuật số vĩnh viễn theo bo mạch chủ: HWID vĩnh viễn, Ohook Office vĩnh viễn, KMS38 cho Enterprise LTSC. Đổi nhanh phiên bản Windows Home lên Pro/Enterprise trong 30 giây kèm Console output slmgr. | MAS Core v2.6, slmgr/vbs Automation, Digital License Ticket Generator |
| **12** | **Quản Lý Phân Vùng Ổ Đĩa** | Thanh hiển thị trực quan tỷ lệ block sector phân vùng vật lý (EFI FAT32, C: Windows NTFS, Recovery, D: Data, Unallocated). Mở rộng phân vùng C không mất dữ liệu, chuyển đổi MBR sang GPT và sửa Bootloader EFI / BCD. | DiskPart & Virtual Disk Service (VDS) API v2.4, 4K Alignment Checker |
| **13** | **Cứu Hộ IT Helpdesk & Khẩn Cấp** | Bộ 5 tác vụ 1-Click: Phá mật khẩu Windows trong 3 giây (SAM Flush), kích hoạt Admin ẩn (SID 500), Reset Winsock & IP, vào Safe Mode khẩn cấp. Trung tâm kết nối nhanh UltraViewer/AnyDesk/TeamViewer/RustDesk, mở khóa Task Manager & Regedit. | NT AUTHORITY\SYSTEM Privilege Hook, Registry Policy Unlocker, Remote Support Hub |

---

## 4. QUY CHUẨN THIẾT KẾ & HỆ THỐNG DESIGN SYSTEM (UI/UX SPECIFICATIONS)

### 4.1 Triết Lý Thiết Kế: Fluent OS Utility (Dark Mode)
- **Cảm hứng:** Sự kết hợp giữa tính hiện đại của **Windows 11 Mica / Fluent 2** và sự tinh giản, trực quan của **macOS Dark Mode**.
- **Màu nền chủ đạo:**
  - `surface`: `#0b1326` (Nền chính tối sâu, chống mỏi mắt cho thợ kỹ thuật).
  - `surface-container-low`: `#131b2e` / `surface-container-lowest`: `#060e20` (Nền phân vùng thẻ card).
  - `surface-bright`: `#31394d` (Nền hover, highlight và viền vi tế 1px).
- **Hệ thống màu biểu thị trạng thái (Status Accent Tokens):**
  - **Primary Action (Thao tác chính):** `#2563eb` / `#3b82f6` (Electric Blue).
  - **Success / Good Health (Tốt / An toàn):** `#10b981` / `#059669` (Emerald Green).
  - **Warning / Alert (Cảnh báo):** `#f59e0b` (Amber).
  - **Critical / Danger (Nguy hiểm / Khẩn cấp):** `#ef4444` / `#dc2626` (Crimson Red).
  - **Accent Pro:** Neon Cyan (`#06b6d4`) & Purple Badge (`#8b5cf6`).

### 4.2 Typography & Iconography
- **Font chữ chính:** `Inter` (sans-serif) — Chuẩn hóa độ đọc trên màn hình máy tính từ độ phân giải 1366x768 đến 4K.
- **Font số liệu kỹ thuật / Terminal:** `JetBrains Mono` / monospace — Hiển thị địa chỉ IP, mã SHA256, log kích hoạt, bảng thuộc tính SMART.
- **Iconography:** Lucide Icons / Fluent System Icons đồng bộ độ dày stroke 1.5px.

### 4.3 Khung App Shell Điều Hướng
- **Top Window Titlebar:** Hiển thị 3 nút điều khiển cửa sổ MacOS/Windows style, logo nhận diện VUONGTT Tool Pro 2026, version badge, trạng thái Admin Privileges [Active], PRO Lifetime badge, đồng hồ thời gian thực và nút Cập nhật / User Profile.
- **Persistent Left Sidebar:** Chiếm 260px cố định, gom gọn 9 danh mục phân hệ chính + cụm thao tác khẩn cấp (Dọn dẹp, Cứu hộ IT, Explorer, Thoát) và thông tin bản quyền/ủng hộ tác giả ở chân sidebar.

---

## 5. YÊU CẦU PHI CHỨC NĂNG & HIỆU NĂNG (NON-FUNCTIONAL REQUIREMENTS)

1. **Hiệu năng & Khởi động:**
   - Ứng dụng khởi động trong dưới 1.5 giây trên ổ SSD SATA/NVMe.
   - Bộ nhớ RAM tiêu thụ dưới 85MB ở chế độ nền.
2. **Khả năng tương thích (Compatibility):**
   - Chạy độc lập dạng Portable hoặc Single Executable, không phụ thuộc .NET Framework ngoài bản dựng native AOT.
   - Hoạt động trơn tru trên cả môi trường Windows thực và môi trường WinPE (Windows Preinstallation Environment) cứu hộ.
3. **An toàn dữ liệu (Safety & Fail-safe):**
   - Mọi thao tác chỉnh sửa Registry nhạy cảm đều tự động tạo điểm khôi phục (Restore Point) hoặc file `.reg` sao lưu gốc trước khi áp dụng.
   - Thao tác chuyển đổi phân vùng đĩa (MBR sang GPT) áp dụng cơ chế Non-destructive, bảo toàn dữ liệu phân vùng Data.
4. **Xuất Bản & Tài Liệu Hóa:**
   - Hỗ trợ xuất toàn bộ giao diện thành tài liệu PDF đặc tả kỹ thuật tiêu chuẩn khổ A4/Landscape (Screen ID: `{{DATA:SCREEN:SCREEN_2}}`).

---

## 6. KẾ HOẠCH TRIỂN KHAI & PHÁT TRIỂN TIẾP THEO (ROADMAP)

- **Giai đoạn 1 (Hiện tại - v20.5):** Hoàn thiện 100% bản vẽ giao diện, prototype tương tác, thiết kế 13 màn hình và tài liệu PRD.
- **Giai đoạn 2 (v20.6):** Tích hợp Backend API (C# .NET 8 / Rust Native Windows API), kết nối hook WMI và WinINet.
- **Giai đoạn 3 (v21.0):** Phát hành bản Beta cho cộng đồng kỹ thuật viên IT Helpdesk và đóng gói file ISO WinPE tích hợp sẵn tool.
