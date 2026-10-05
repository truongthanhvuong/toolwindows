# Kế Hoạch Triển Khai: Gộp Tính Năng Trùng Lặp & Tinh Gọn 10 Menu Sidebar

> **Mục tiêu:** Loại bỏ hoàn toàn sự trùng lặp giữa các tính năng (Scan vs Máy In, Cài Win vs Kho ISO Win), gộp các tính năng trùng thành các tab con bên trong trang tương ứng, giữ lại đúng 10 danh mục menu Sidebar trực quan, chuyên nghiệp.

## 1. Cấu trúc 10 Danh Mục Menu Chuẩn Hóa
1. `btnMenuSysInfo` -> Check Cấu Hình (Tag: `SysInfo`)
2. `btnMenuAutoWin` -> Cài Win & Kho ISO (Tag: `AutoWin`)
3. `btnMenuBackupRestore` -> Sao Lưu & Phục Hồi (Tag: `BackupRestore` -> Hub `TechUtilities`)
4. `btnMenuOffice` -> Cài Đặt Office (Tag: `OfficeAIO`)
5. `btnMenuActivator` -> Kích Hoạt & Bản Quyền (Tag: `Activation` -> Hub `TechUtilities`)
6. `btnMenuSystemFix` -> Tiện Ích - Sửa Lỗi Win (Tag: `SystemFix`)
7. `btnMenuPrinterLAN` -> Máy In, Scan & Share LAN (Tag: `PrinterLAN`)
8. `btnMenuHardwareDisk` -> Phân Vùng & Ổ Cứng (Tag: `HardwareDisk`)
9. `btnMenuSoftwareStore` -> Kho Phần Mềm & Gỡ App (Tag: `SoftwareHub`)
10. `btnMenuFakeVpnProxy` -> Fake VPN / Proxy (Tag: `FakeVpnProxy`)

## 2. Chi Tiết Gộp Tính Năng Trùng:
- **Scan vs Máy In:** Gộp toàn bộ vào `btnMenuPrinterLAN`. Đổi tên tab con số 4 thành `📁 Fix Chia Sẻ & Scan Folder`.
- **Cài Win vs Kho ISO:** Gộp toàn bộ vào `btnMenuAutoWin`. Kho ISO đã có sẵn trong trang, liên kết trực tiếp.
- **Sao Lưu vs Phục Hồi:** Gộp `Sao Lưu Windows` và `Sao Lưu - Phục Hồi` thành `💾 Sao Lưu & Phục Hồi`.
- **Kho Phần Mềm vs Gỡ Cài Đặt:** Gom vào `📦 Kho Phần Mềm & Gỡ App` (chuyển sang hub `SoftwareHub`).
- **Dọn dẹp vs Tiện ích:** Gom vào `⚡ Tiện Ích - Sửa Lỗi Win`.

## 3. Các File Cần Chỉnh Sửa:
- `src/UI/MainWindow.xaml`: Cập nhật lại `MenuPanel` chỉ gồm 10 nút chuẩn, cập nhật text header và sub-tab.
- `VUONGTT_Toolkit.ps1`: Cập nhật `$menuButtons`, `$pages`, `$legacyRouting`, `$pageTitlesVI`, `$pageTitlesEN`.
- `tests/Test-MenuStreamlining.Tests.ps1`: Kiểm tra sự tồn tại của 10 menu mới và routing an toàn 100%.
- `Build-Exe.ps1`: Tăng version lên `v20.5.909.89` và build EXE.
