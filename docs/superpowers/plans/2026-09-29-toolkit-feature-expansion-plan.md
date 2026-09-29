# Kế Hoạch Triển Khai Nâng Cấp Tính Năng Toàn Diện (Toolkit Feature Expansion Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nâng cấp và mở rộng toàn diện bộ công cụ `VUONGTT Tool Pro 2026` từ 12 tính năng hoàn thiện hiện tại lên đầy đủ 28 tính năng thuộc 6 nhóm chuyên nghiệp theo chuẩn Apple HIG, bổ sung các năng lực vượt trội: Tra cứu BIOS OEM Key, Chuyển đổi SKU Windows/Office, Quét sạch Crack lậu, Đổi DNS đo ping thời gian thực, Tự động cài đặt Windows (WSAP), Cài Windows To Go (WEDI), Máy ảo Hyper-V, và Khóa ứng dụng (AppBlock).

**Architecture:** Mở rộng kiến trúc Module hóa (Modular Architecture) với các file Core Engine độc lập trong `src/Core/` (ví dụ `LicenseKeyReader.ps1`, `SkuConverter.ps1`, `CrackScanner.ps1`, `DnsOptimizer.ps1`, `WsapInstaller.ps1`), liên kết chặt chẽ với XAML trong `src/UI/MainWindow.xaml` thông qua cơ chế Apple Segmented Controls và Storyboards hoạt ảnh mượt mà, điều khiển tập trung tại `VUONGTT_Toolkit.ps1`.

**Tech Stack:** WPF (XAML), PowerShell 5.1, .NET Framework 4.8, WMI/CIM, DISM, BCD, WScript, Win32 API.

**Spec:** [`docs/superpowers/specs/2026-09-29-toolkit-feature-gap-analysis.md`](file:///e:/toolwindows/docs/superpowers/specs/2026-09-29-toolkit-feature-gap-analysis.md)

## Global Constraints

- Bảo tồn 100% các tính năng hiện có, không làm hỏng các event handler và cơ chế đồng bộ Cloud License.
- Giao diện mới 100% tuân thủ phong cách Apple HIG (Font chữ Apple SF Pro fallback, CornerRadius bo mềm, hiệu ứng mờ chuyển tab 220ms).
- Tuân thủ quy chuẩn `AGENTS.md`: Tự động nâng số hiệu version (+1 build), duy trì UTF-8 BOM, biên dịch `VUONGTT_Toolkit.exe`, chạy Smoke Test và chỉ commit cục bộ (tuyệt đối không tự ý `git push`).

---

## 🗺️ LỘ TRÌNH TRIỂN KHAI PHÂN KỲ (3 GIAI ĐOẠN)

---

### GIAI ĐOẠN 1: NÂNG CẤP NHANH CÁC TÍNH NĂNG CỐT LÕI (HIGH-IMPACT QUICK WINS)

Mục tiêu: Hoàn thiện ngay 5 tính năng đang có một phần để người dùng và kỹ thuật viên có thể sử dụng ngay trong các công việc thường nhật.

#### Task 1.1: Module Tra Cứu Product Key Windows, Office & BIOS OEM Key
- **Files**:
  - Tạo mới: `src/Core/KeyViewerEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Thêm Card tra cứu Key trong `pageActivation`)
  - Cập nhật: `VUONGTT_Toolkit.ps1` (Kết nối sự kiện quét Key)
  - Test: `tests/Test-KeyViewerEngine.Tests.ps1`
- **Mô tả**:
  - Trích xuất OEM BIOS Product Key từ firmware ACPI MSDM qua `(Get-CimInstance -ClassName SoftwareLicensingService).OA3xOriginalProductKey`.
  - Giải mã khóa số bản quyền Windows hiện tại từ Registry `DigitalProductId` (`HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion`).
  - Kiểm tra trạng thái kích hoạt Office và hiển thị 5 ký tự cuối của Office Key qua `ospp.vbs`.
  - Nút `[Sao Chép Key]` và nút `[Kích Hoạt Ngay Bằng Key Này]`.

#### Task 1.2: Module Chuyển Đổi SKU Windows & Office Retail ➔ Volume
- **Files**:
  - Tạo mới: `src/Core/SkuConverterEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Thêm Sub-tab / Card trong `pageActivation` & `pageConfig`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-SkuConverter.Tests.ps1`
- **Mô tả**:
  - **Convert Windows SKU**: 1-Click chuyển đổi giữa các phiên bản không cần cài lại Win (Home ➔ Pro, Pro ➔ Enterprise, Pro ➔ Education, Pro ➔ Workstation) bằng generic GVLK keys và `changepk.exe` / `dism /online /set-edition`.
  - **Convert Office C2R-R2V**: Tự động chuyển đổi giấy phép Office Retail (Click-to-Run) sang Volume License (nạp chứng chỉ và KMS client key) để sẵn sàng kích hoạt bản quyền doanh nghiệp.

#### Task 1.3: Module Quét & Tiệt Trừ Crack Lậu (Crack Scanner Pro)
- **Files**:
  - Tạo mới: `src/Core/CrackScannerEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Thêm giao diện quét crack trong `pageActivation`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-CrackScanner.Tests.ps1`
- **Mô tả**:
  - Quét phát hiện và hiển thị danh sách các dấu vết crack: Service giả mạo (AutoKMS, KMSpico), Scheduled Tasks ngầm, File hook DLL trong System32/SysWOW64 (`SppExtComObjHook.dll`, `SECOH-QAD.exe`), cổng KMS giả lập 127.0.0.1.
  - Nút `[🧹 1-Click Dọn Sạch Toàn Bộ Crack]`: Dừng service, xóa tasks, gỡ DLL hook, khôi phục registry Windows Licensing sạch 100% để máy sẵn sàng nhập key bản quyền chính hãng.

#### Task 1.4: Module Đổi DNS Nhanh & Tối Ưu Tốc Độ Mạng (DNS Changer Pro)
- **Files**:
  - Tạo mới: `src/Core/DnsChangerEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Giao diện thẻ DNS trong `pageConfig`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-DnsChanger.Tests.ps1`
- **Mô tả**:
  - Tự động nhận diện danh sách Card mạng đang kết nối (Wi-Fi, Ethernet) kèm DNS hiện tại.
  - Các Preset DNS hàng đầu: Google (8.8.8.8 / 8.8.4.4), Cloudflare (1.1.1.1 / 1.0.0.1), AdGuard Chặn Quảng Cáo (94.140.14.14 / 94.140.15.15), Quad9 Bảo Mật (9.9.9.9), OpenDNS, DNS Tự Động (DHCP).
  - Nút `[⚡ Đo Ping Nhanh Các DNS]`: Đo độ trễ (latency ms) thực tế tới từng máy chủ DNS và gợi ý DNS có tốc độ nhanh nhất cho người dùng bấm chọn.

#### Task 1.5: Kho Tải ISO Windows Gốc & Công Cụ Đối Soát Hash SHA-256
- **Files**:
  - Tạo mới: `src/Core/IsoRepositoryEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Thêm Sub-tab trong `pageAutoWin`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-IsoRepository.Tests.ps1`
- **Mô tả**:
  - Danh mục các bộ cài Windows chính thức: Windows 11 24H2, Windows 10 22H2, Windows 10 Enterprise LTSC 2021, Windows 11 IoT Enterprise LTSC, Windows Server 2022/2025.
  - Hiển thị trực tiếp bảng mã băm SHA-256 gốc từ Microsoft.
  - Công cụ tích hợp `[🧪 Kiểm Tra Checksum File ISO]`: Cho phép chọn file ISO đã tải về để tự động tính hash SHA-256 và so khớp xem có đúng bản chuẩn sạch không bị chèn mã độc.

---

### GIAI ĐOẠN 2: TỰ ĐỘNG HÓA CÀI ĐẶT WINDOWS & MÁY ẢO (DEPLOYMENT & VIRTUALIZATION)

Mục tiêu: Xây dựng các năng lực cài đặt Windows chuyên sâu không cần USB boot, cài Windows lên ổ cứng di động, và quản lý máy ảo Hyper-V.

#### Task 2.1: Quy Trình Cài Win Tự Động Không Cần USB (WSAP)
- **Files**:
  - Tạo mới: `src/Core/WsapEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Thiết kế lại phân hệ `pageAutoWin` theo wizard WSAP)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-WsapEngine.Tests.ps1`
- **Mô tả**:
  - Chuẩn hóa quy trình 4 bước trực quan:
    1. Bước 1: Chọn tệp ISO hoặc file `install.wim` / `install.esd` (tự động đọc danh sách phiên bản Home/Pro/Enterprise bên trong).
    2. Bước 2: Chọn phân vùng ổ đĩa cài đặt (tự động phát hiện chuẩn BIOS Legacy MBR hay UEFI GPT).
    3. Bước 3: Tùy chọn cài đặt (Bypass TPM/Secure Boot/RAM, tích hợp sẵn Driver từ máy hiện tại qua `Export-WindowsDriver`, nạp file unattend).
    4. Bước 4: Bung ảnh WIM qua DISM và tự động nạp Bootloader BCD qua `bcdboot.exe`.

#### Task 2.2: Trình Tạo Cấu Hình Cài Win Tự Động (Auto Unattend Generator)
- **Files**:
  - Tạo mới: `src/Core/UnattendGenerator.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml`
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-UnattendGenerator.Tests.ps1`
- **Mô tả**:
  - Form trực quan tạo file `autounattend.xml`:
    - Đặt tên máy tính (Computer Name), múi giờ (Timezone: SE Asia Standard Time GMT+7).
    - Tạo tài khoản người dùng cục bộ (Username, Password, Password Never Expires).
    - Tùy chọn tự động: Bỏ qua kiểm tra TPM 2.0 & Secure Boot & RAM 4GB (Windows 11).
    - Bỏ qua bước ép đăng nhập tài khoản Microsoft (OOBE BypassNRO).
    - Tự động kích hoạt tài khoản Administrator mặc định.
  - Nút xuất file `autounattend.xml` lưu trực tiếp vào thư mục gốc của USB cài Win hoặc phân vùng cài đặt.

#### Task 2.3: Cài Windows Lên Ổ Cứng Di Động (WEDI — Windows To Go)
- **Files**:
  - Tạo mới: `src/Core/WediEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Thêm Sub-tab trong `pageAutoWin`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-WediEngine.Tests.ps1`
- **Mô tả**:
  - Nhận diện ổ cứng ngoài cắm qua cổng USB / Type-C (External SSD / USB HDD).
  - Tự động chia phân vùng EFI Boot (FAT32) và phân vùng Windows OS (NTFS).
  - Bung file `install.wim` lên ổ cứng ngoài, nạp BCD Boot UEFI cho ổ ngoài độc lập không ảnh hưởng ổ cứng trong máy.
  - Cấu hình cờ Windows To Go để hệ điều hành nhận diện chạy ổn định từ cổng USB.

#### Task 2.4: Trình Tạo Nhanh Máy Ảo Hyper-V (Hyper-V Creator Pro)
- **Files**:
  - Tạo mới: `src/Core/HyperVCreatorEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml`
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-HyperVCreator.Tests.ps1`
- **Mô tả**:
  - Tự động kiểm tra CPU hỗ trợ ảo hóa (VT-x / AMD-V) và trạng thái dịch vụ Hyper-V.
  - Form tạo máy ảo nhanh: Tên máy ảo, Thế hệ (Generation 1/2), Số nhân CPU, Dung lượng RAM, Dung lượng ổ ảo VHDX động, Chọn Virtual Switch mạng, Gắn đường dẫn file ISO cài đặt.
  - Thực thi tạo máy ảo tức thì qua cmdlet `New-VM`, `Set-VMMemory`, `New-VHD` và mở ngay công cụ điều khiển `vmconnect.exe`.

---

### GIAI ĐOẠN 3: NHÂN BẢN HỆ THỐNG & QUẢN TRỊ NÂNG CAO (ADVANCED SYSTEM SUITE)

Mục tiêu: Trang bị các công cụ đỉnh cao dành cho kỹ thuật viên IT chuyên nghiệp quản lý hàng chục đến hàng trăm máy tính.

#### Task 3.1: Sao Chép & Di Chuyển Hệ Điều Hành (OS Migrator / Disk Clone)
- **Files**:
  - Tạo mới: `src/Core/OsMigratorEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Tích hợp vào phân hệ `pagePartition`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-OsMigrator.Tests.ps1`
- **Mô tả**:
  - Clone trực tiếp từ ổ cứng chứa hệ điều hành đang chạy sang ổ cứng mới (SSD SATA/NVMe).
  - Tự động đồng bộ phân vùng EFI, MSR, Windows và nạp lại BCD Boot trên ổ cứng mới để rút ổ cũ ra là khởi động được ngay.

#### Task 3.2: Bộ Khóa & Chặn Ứng Dụng Bằng Mật Khẩu (AppBlock Pro)
- **Files**:
  - Tạo mới: `src/Core/AppBlockEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Tích hợp vào phân hệ `pageConfig` hoặc `pageUsers`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-AppBlock.Tests.ps1`
- **Mô tả**:
  - Quản lý danh sách ứng dụng bị hạn chế (Trình duyệt Chrome/Edge/Cốc Cốc, Game, Phần mềm kế toán...).
  - Chặn chạy ứng dụng thông qua Image File Execution Options (IFEO) hoặc Software Restriction Policies.
  - Bảo vệ danh sách chặn bằng Mật khẩu quản trị viên (Admin PIN/Password).

#### Task 3.3: Sysprep & Chụp Ảnh Golden Image WIM (Ghost Windows)
- **Files**:
  - Tạo mới: `src/Core/WimCaptureEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml` (Tích hợp vào `pageAutoWin`)
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-WimCapture.Tests.ps1`
- **Mô tả**:
  - Tự động chạy Sysprep Generalize OOBE chuẩn bị máy mẫu.
  - Thực thi chụp ảnh phân vùng Windows thành file `install.wim` nén cao (`dism /Capture-Image /Compress:max`) phục vụ việc bung hàng loạt cho các máy cùng cấu hình.

#### Task 3.4: Tùy Biến Ảnh Cài Đặt Windows (ISO Customizer)
- **Files**:
  - Tạo mới: `src/Core/IsoCustomizerEngine.ps1`
  - Cập nhật: `src/UI/MainWindow.xaml`
  - Cập nhật: `VUONGTT_Toolkit.ps1`
  - Test: `tests/Test-IsoCustomizer.Tests.ps1`
- **Mô tả**:
  - Mount file `install.wim` bằng DISM.
  - Tích hợp thêm gói Driver phần cứng (`.inf`), bật tính năng .NET 3.5 offline, gỡ bỏ các ứng dụng rác không cần thiết.
  - Unmount và lưu WIM, hỗ trợ xuất thành file ISO bootable hoàn chỉnh.

---

## 4. QUY CHUẨN TDD & KIỂM THỬ MỖI GIAI ĐOẠN

Mỗi Task trong lộ trình đều tuân thủ nghiêm ngặt chu trình:
1. **Red Phase**: Viết file test `.Tests.ps1` kiểm tra tính năng trước khi viết code, chạy test xác nhận FAIL.
2. **Green Phase**: Viết mã nguồn Core Engine và giao diện XAML tối thiểu để vượt qua test, chạy test xác nhận 100% PASS.
3. **Refactor & AST Integrity**: Chạy `tests/check_ast.ps1` xác thực 0 lỗi cú pháp.
4. **AGENTS.md Compliance**: Tăng 1 số Version (Build Increment), gắn UTF-8 BOM, biên dịch `VUONGTT_Toolkit.exe`, chạy Smoke Test nạp Assembly, lưu commit Git cục bộ.
