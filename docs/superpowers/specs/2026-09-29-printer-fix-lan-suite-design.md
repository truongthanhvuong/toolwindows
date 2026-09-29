# Bản Thiết Kế Chi Tiết (Design Spec): Bộ Công Cụ "Fix Máy In - Share LAN" Toàn Diện

- **Ngày ban hành**: 29/09/2026
- **Trạng thái**: Bản thảo thiết kế kiến trúc hoàn thiện (Architectural Design Spec)
- **Tác giả**: Antigravity & VUONGTT Software Team
- **Hệ thống áp dụng**: `VUONGTT_Toolkit.exe` (WPF XAML + PowerShell Core Engine)
- **Tham chiếu hình ảnh**:
  - `media_1790663366271.png` (Sub-tab 1: Fix Máy In Mạng LAN & Modal 0x0000007c)
  - `media_1790663351835.png` / `media_1790663351866.png` (Sub-tab 3: Tạo User Chia Sẻ Máy In - LAN)

---

## 1. Tổng Quan & Mục Tiêu Nghiệp Vụ

Giao diện mục `Fix Máy In - Share LAN` (`pagePrinterLAN`) hiện tại chỉ gồm một danh sách nút bấm đơn giản và ô tìm kiếm. Trong thực tế bảo trì phòng máy và văn phòng, các kỹ thuật viên máy tính thường xuyên phải xử lý chuỗi vấn đề liên hoàn:
1. **Lỗi kết nối in ấn mạng LAN**: Lỗi mã `0x0000011b`, `0x00000709`, `0x0000007c` (cần thay `win32spl.dll`), `0x00000bc4`, `0x00004005`, `0x00000bcb`, `0x000006d9`, `0x00000012`.
2. **Quản lý danh sách máy in & cổng in cục bộ**: In trang test, đổi máy in mặc định, thêm Local Port, chia sẻ máy in LAN, xóa máy in lỗi.
3. **Lưu trữ tài khoản xác thực (Credentials)**: Máy trạm không thể kết nối tới máy chủ chia sẻ do thiếu Windows Credentials hợp lệ (lỗi xác thực đăng nhập `Logon Failure / Access Denied`).
4. **Tạo tài khoản User Share chuyên dụng**: Máy chủ Windows 10/11 chặn khách vãng lai, yêu cầu tạo riêng một tài khoản Local User (`shareuser`) với mật khẩu không hết hạn để máy trạm truy cập chia sẻ ổn định mà không để lộ mật khẩu Admin.
5. **Khắc phục lỗi chia sẻ dữ liệu (Folder / File Sharing)**: Lỗi chặn SMB1/SMB2, tường lửa chia sẻ file, sai Network Profile (Public thay vì Private), lỗi xác thực Guest Insecure.

Bản thiết kế này cấu trúc lại hoàn toàn phân hệ `pagePrinterLAN` thành **4 Sub-tabs chuyên nghiệp** theo chuẩn Apple Human Interface Guidelines (Segmented Pill Bar), đồng thời bổ sung **Modal Dialog chuyên biệt sửa lỗi 0x0000007c** theo đúng 100% hình mẫu tham chiếu.

---

## 2. Kiến Trúc Giao Diện (UI Architecture & Layout)

### 2.1. Thanh Điều Hướng Sub-tabs (Apple Segmented Bar)
Nằm ngay phía trên cùng của `pagePrinterLAN`, gồm 4 viên thuốc (Capsule Tabs):
- **Sub-tab 1**: `🖨️ Fix Máy In Mạng LAN` (`tabPrinterLAN_Fix`)
- **Sub-tab 2**: `🔐 Add Windows Credentials` (`tabPrinterLAN_Credentials`)
- **Sub-tab 3**: `👤 Tạo User Chia Sẻ Máy In - LAN` (`tabPrinterLAN_ShareUser`)
- **Sub-tab 4**: `📁 Fix Chia Sẻ Dữ Liệu` (`tabPrinterLAN_ShareData`)

Phong cách hiển thị:
- Tab kích hoạt (Active): Màu xanh Apple Accent (`#0284C7` hoặc `#0071E3`), chữ trắng, bo góc `CornerRadius="8"`.
- Tab không kích hoạt (Inactive): Nền thẻ trong suốt/nhạt (`DynamicResource CardInnerBgBrush`), chữ trung tính, viền mảnh.
- Chuyển tab mượt mà với Storyboard hoạt ảnh Cross-fade 180ms.

---

### 2.2. Chi Tiết Sub-tab 1: `Fix Máy In Mạng LAN` (Khắc Phục Mã Lỗi & Quản Lý Máy In)

#### Cột Trái (Left Card): Danh Sách Máy In & Cổng Đang Chạy (Port)
- **Tiêu đề nhóm**: `📋 Danh Sách Máy In & Cổng Đang Chạy (Port)`
- **Nút tác vụ góc phải**: `[🔄 Quét Lại Máy In]` (`btnPrinterRefreshList`)
- **Bảng dữ liệu DataGrid** (`dgPrinterList`):
  - Cột 1: `Check/Chọn` (Checkbox & icon máy in / `⭐`)
  - Cột 2: `Tên Máy In` (`Name`) - hiển thị tên máy in kèm sao đánh dấu máy in mặc định
  - Cột 3: `Cổng (Port)` (`PortName`) - e.g. `PORTPROMPT:`, `USB001`, `192.168.1.150`
  - Cột 4: `Trạng Thái` (`Status`) - e.g. `Sẵn sàng (Ready)`, `Offline`, `Error`
- **Khối nút tác vụ máy in (Dưới DataGrid)**:
  - Hàng 1:
    - `[🖨️ In Trang Test]` (`btnPrinterTestPrint`) -> Gửi lệnh in trang thử nghiệm Windows
    - `[⭐ Set Mặc Định]` (`btnPrinterSetDefault`) -> Đặt máy in đã chọn thành mặc định
  - Hàng 2:
    - `[➕ Add Local Port]` (`btnPrinterAddLocalPort`) -> Mở hộp thoại thêm cổng Local Port hoặc TCP/IP Port
    - `[🔗 Share Máy In LAN]` (`btnPrinterShareLan`) -> Mở thuộc tính chia sẻ hoặc kích hoạt chia sẻ máy in qua LAN
  - Hàng 3:
    - `[🗑️ Xóa Sạch Máy In (Chọn máy in trong bảng)]` (`btnPrinterRemoveSelected`) -> Gỡ bỏ máy in đã chọn khỏi Windows Spooler

#### Cột Phải (Right Card): Khắc Phục Mã Lỗi & Tiện Ích Sửa Máy In LAN
- **Tiêu đề nhóm**: `🛠️ Khắc Phục Mã Lỗi & Tiện Ích Sửa Máy In LAN`
- **Khối Checkbox Mã Lỗi Chia 3 Phân Nhóm (3-Column Layout)**:
  1. **Máy Trạm (Client)**:
     - `☐ 0x0000007c` (`chkErr0x7c`)
     - `☐ 0x00000bc4` (`chkErr0xbc4`)
     - `☐ 0x00004005` (`chkErr0x4005`)
  2. **Máy Chủ (Host/Server)**:
     - `☐ 0x0000011b` (`chkErr0x11b`)
     - `☐ 0x00000bcb` (`chkErr0xbcb`)
     - `☐ 0x000006d9` (`chkErr0x6d9`)
  3. **Cả 2 Máy (Both)**:
     - `☐ 0x00000709` (`chkErr0x709`)
     - `☐ 0x00000012` (`chkErr0x012`)
     - `☐ Policy In Effect` (`chkErrPolicyInEffect`)
- **Nút hành động sửa lỗi đã chọn**:
  - `[🔧 Sửa Các Mã Lỗi Đã Chọn (Tích ở trên)]` (`btnFixSelectedErrors`) -> Thực thi đồng thời các mã lỗi được tích chọn, xuất nhật ký chi tiết.
- **Hộp cảnh báo phiên bản (Warning Box)**:
  - Nền vàng hổ phách nhạt (`#FEF3C7` / Viền `#F59E0B`):
  - `⚠️ Lưu ý quan trọng: Kiểm tra kỹ Version Win trước khi chạy. Nếu 1909 trở xuống thì đừng chạy One Click và Fix Services Print Spooler (chạy sẽ lỗi Print Spooler). Nếu 1909 trở lên thì bạn chạy bình thường.`
- **Lưới nút Tiện Ích Máy In (Utilities Grid 2 cột)**:
  - `[⚡ Fix Spooler Services]` (`btnFixSpoolerServices`)
  - `[📄 Cài Print to PDF]` (`btnInstallPrintToPdf`)
  - `[⚠️ Fix Communication Error 2900 - 3000]` (`btnFixCommError2900`)
  - `[⭐ Sửa Lỗi Set Mặc Định 0x709]` (`btnFixDefault709`)
  - `[💾 Backup / Restore Driver]` (`btnBackupRestorePrinterDriver`)
  - `[🔥 One Click Fix Tất Cả Lỗi LAN]` (`btnOneClickFixAllLAN`)
  - `[🌐 Download Spooler Fix Theo Window]` (`btnDownloadSpoolerFix`)
  - `[🖨️ Reset Canon Màu]` (`btnResetCanonColor`)
  - `[🛠️ Fix không cài được driver]` (`btnFixCannotInstallDriver`) (Full width)

---

### 2.3. Chi Tiết Modal Dialog: Tiến Trình Khắc Phục Lỗi 0x0000007c (Máy Trạm)

- **Cơ chế**: In-place modal overlay trong WPF (`modal0x7c`), hiển thị lớp phủ mờ tinh tế phủ lên màn hình làm việc, căn giữa card thông báo.
- **Thanh tiêu đề Modal**:
  - Tiêu đề: `🖨️ TIẾN TRÌNH KHẮC PHỤC LỖI 0x0000007c`
  - Nút đóng: `[✕]` (`btnCloseModal0x7c`)
- **Phần thân (Body)**:
  - Huy hiệu (Badge) hình vuông bo góc xanh dương đậm: chữ số `7C` nổi bật
  - Tiêu đề chính: `SỬA LỖI MÁY IN: 0x0000007c (MÁY TRẠM)`
  - Mô tả phụ: `Tự động thay thế tệp win32spl.dll chuẩn và nạp cấu hình Registry RpcAuthnLevelPrivacyEnabled`
  - **Khung chọn phiên bản Windows (Group Options)**:
    - `🔘 Windows 10 (2004, 20H2, 21H1, 21H2, 22H2) & Windows 11` (`rbWin10_2004_Plus`) -> Tự động tích chọn nếu hệ điều hành hiện tại tương ứng.
    - `🔘 Windows 10 (Version 1909)` (`rbWin10_1909`)
    - `🔘 Windows 10 (Version 1809) & Windows Server 2019` (`rbWin10_1809`)
  - **Nút thực thi chính**:
    - `[⚡ 1-Click Fix Lỗi 0x0000007c (Thay Thế win32spl.dll)]` (`btnExecuteFix0x7c`)
- **Chân trang (Footer)**:
  - Text thông báo trạng thái: `Sẵn sàng thực thi...` (`txtModal0x7cStatus`)
  - Nút: `[Đóng]` (`btnDismissModal0x7c`)

---

### 2.4. Chi Tiết Sub-tab 3: `Tạo User Chia Sẻ Máy In - LAN`

#### Khối Trái (Left Card): Form Tạo Tài Khoản Chia Sẻ
- **Tiêu đề nhóm**: `👤 Tạo Tài Khoản Windows Chia Sẻ Mạng LAN / Máy In (Share User)`
- **Các trường nhập liệu**:
  - `Tên tài khoản (Username):` TextBox (`txtShareUser_Name`) — Watermark: `VD: shareuser, mayin...`
  - `Tên đầy đủ / Ghi chú:` TextBox (`txtShareUser_FullName`) — Watermark: `Tùy chọn: User Chia Sẻ LAN...`
  - `Mật khẩu (Password):` PasswordBox (`txtShareUser_Pass`) — Watermark: `Nhập mật khẩu (VD: 123456)...`
  - `Xác nhận mật khẩu:` PasswordBox (`txtShareUser_ConfirmPass`) — Watermark: `Nhập lại mật khẩu...`
  - Checkbox: `♾️ Mật khẩu không bao giờ hết hạn (Password Never Expires)` (`chkShareUser_NeverExpires`) — Mặc định: `IsChecked="True"`
- **Nút tác vụ**:
  - `[➕ Tạo Tài Khoản Mới Ngay]` (`btnCreateShareUser`) — Màu xanh lá hiện đại (`#059669` / `#10B981`)

#### Khối Phải (Right Card): Danh Sách Tài Khoản Windows Hiện Có
- **Tiêu đề nhóm**: `📑 Danh Sách Tài Khoản Windows Hiện Có`
- **Nút góc phải**: `[🔄 Quét Lại]` (`btnRefreshUsersList`)
- **Bảng dữ liệu DataGrid** (`dgUsersList`):
  - Cột 1: `Tài Khoản` (Tên username + Icon đại diện: Admin 👑, User 👥, Khóa 🔴)
  - Cột 2: `Nhóm` (Admin / Users / Guests)
  - Cột 3: `Trạng Thái` (🟢 Hoạt động / 🔴 Đã khóa)
  - Cột 4: `Hạn Mật Khẩu` (⏳ Có thời hạn / ♾️ Không bao giờ hết hạn)
- **Dãy nút điều khiển User (Dưới DataGrid)**:
  - Hàng 1:
    - `[🔒 Khóa / Mở Khóa User]` (`btnToggleUserActive`)
    - `[🔑 Đổi Mật Khẩu Nhanh]` (`btnChangeUserPasswordQuick`)
  - Hàng 2:
    - `[♾️ Đặt MK Không Hết Hạn]` (`btnSetUserNeverExpires`)
    - `[👤 Gán / Gỡ Quyền Admin]` (`btnToggleUserAdminRole`)
  - Hàng 3:
    - `[⚙️ Mở lusrmgr.msc]` (`btnOpenLusrmgr`)
    - `[🗑️ Xóa User Đang Chọn]` (`btnDeleteSelectedUser`)

#### Khối Dưới (Bottom Card): Hướng Dẫn Chi Tiết Cho Người Mới
- **Tiêu đề**: `📖 Hướng Dẫn Chi Tiết: Tạo User Chia Sẻ Máy In - Mạng LAN (Dành Cho Người Mới)`
- **Nội dung hướng dẫn thực chiến**:
  - **Tại Sao Cần Tạo User Share & Để Fix Lỗi Gì**:
    - Khi chia sẻ máy in hoặc folder qua mạng LAN, Windows 10/11 yêu cầu máy trạm phải xác thực tài khoản hợp lệ. Việc tạo một User Share riêng biệt (VD: `shareuser` / Mật khẩu: `123456`) giúp các máy khác kết nối máy in và dữ liệu mượt mà, **không bị lỗi chặn quyền truy cập (Access Denied / Logon Failure)** và **không cần chia sẻ mật khẩu tài khoản chính**.
  - **Máy Nào Cần Tạo & Máy Nào Cần Sử Dụng**:
    - **Tạo trên MÁY CHỦ** (Máy cắm máy in / Máy chứa dữ liệu): Sử dụng form bên trên để tạo tài khoản User Share.
    - **Dùng trên MÁY TRẠM** (Máy cần in / Máy cần lấy file): Khi máy trạm kết nối tới máy chủ (qua tab Add Windows Credentials hoặc mở `\\IP-MAY-CHU`), hãy nhập đúng User name và Password vừa tạo để lưu lại vĩnh viễn.
    - **Mẹo nhỏ**: Nên giữ tùy chọn Mật khẩu không bao giờ hết hạn để việc in ấn trong mạng nội bộ luôn thông suốt lâu dài.

---

### 2.5. Chi Tiết Sub-tab 2: `Add Windows Credentials`

- **Mục tiêu**: Xóa bỏ rào cản gõ mật khẩu nhiều lần hoặc lưu sai mật khẩu khi kết nối mạng LAN.
- **Form nhập thông tin xác thực**:
  - `Địa chỉ IP hoặc Tên Máy Chủ (Target IP / Hostname):` TextBox (`txtCredTarget`) — Watermark: `VD: 192.168.1.100 hoặc MAY-CHU`
  - `Tên tài khoản (Username):` TextBox (`txtCredUser`) — Watermark: `VD: shareuser hoặc Administrator`
  - `Mật khẩu (Password):` PasswordBox (`txtCredPass`)
  - Nút: `[➕ Lưu Windows Credentials]` (`btnSaveCredential`) -> `cmdkey.exe /add:$target /user:$user /pass:$pass`
- **Danh sách Credentials trong hệ thống**:
  - DataGrid liệt kê các thông tin lưu trữ từ `cmdkey /list`.
  - Cột: `Mục Tiêu (Target)`, `Loại (Type)`, `Tài Khoản (User)`
  - Nút: `[🔄 Quét Lại Credentials]` (`btnRefreshCredentials`)
  - Nút: `[🗑️ Xóa Credential Đang Chọn]` (`btnDeleteCredential`) -> `cmdkey /delete:$target`
  - Nút: `[⚙️ Mở Credential Manager]` (`btnOpenCredMgr`) -> `control.exe keymgr.dll`
  - Nút: `[🧪 Kiểm Tra Kết Nối (Ping & SMB Port 445)]` (`btnTestTargetConnection`)

---

### 2.6. Chi Tiết Sub-tab 4: `Fix Chia Sẻ Dữ Liệu`

- **Mục tiêu**: Khắc phục các vấn đề chia sẻ file/thư mục qua mạng LAN giữa Windows 10 và 11.
- **Các chức năng 1-Click**:
  - `[🌐 Bật Network Discovery & File Sharing]` -> Mở toàn bộ firewall rule và cấu hình dịch vụ `fdPHost`, `FDResPub`, `upnphost`, `SSDPSRV`.
  - `[🔒 Bật Cho Phép Guest Insecure (LanmanWorkstation)]` -> Gán `AllowInsecureGuestAuth = 1` trong Registry để Windows 11 truy cập được NAS/Windows cũ.
  - `[📶 Đặt Cấu Hình Mạng Thành Private Network]` -> Chuyển card mạng từ Public sang Private bằng `Set-NetConnectionProfile`.
  - `[⚡ Kích Hoạt SMBv1 & SMBv2]` -> Cấu hình SMB protocol.
  - `[🧹 Xóa Sạch Bộ Nhớ Đệm Kết Nối Mạng (Net Use Flush)]` -> Chạy `net use * /delete /y` và restart LanmanWorkstation.
  - `[⚙️ Mở Thiết Lập Chia Sẻ Nâng Cao (Advanced Sharing)]` -> Mở `control.exe /name Microsoft.NetworkAndSharingCenter /page AdvancedShared`.

---

## 3. Kiến Trúc Backend PowerShell (`src/Core/NetworkPrinterFix.ps1`)

Cung cấp các hàm automation độc lập, trả về chuỗi log nhật ký chi tiết và dữ liệu cấu trúc:

1. **`Get-VUONGTTPrinterList`**: Lấy danh sách máy in từ `Get-CimInstance Win32_Printer` (Tên, Cổng, Trạng thái, Default).
2. **`Invoke-VUONGTTPrinterAction`**:
   - `test_print`: Gửi lệnh in test page.
   - `set_default`: Đặt máy in mặc định.
   - `share_printer`: Bật cờ chia sẻ máy in LAN.
   - `remove_printer`: Gỡ bỏ driver và máy in.
   - `add_local_port`: Thêm cổng TCP/IP / Local Port.
3. **`Invoke-VUONGTTBatchErrorFix`**: Nhận danh sách mã lỗi (`0x7c`, `0xbc4`, `0x4005`, `0x11b`, `0xbcb`, `0x6d9`, `0x709`, `0x012`, `policy`) và sửa chữa tuần tự.
4. **`Invoke-VUONGTTFix0x7c`**:
   - Tự động kiểm tra quyền Admin.
   - Dừng Print Spooler.
   - Sao lưu `win32spl.dll` hiện tại sang `win32spl.dll.bak`.
   - Take ownership và cấp quyền ghi file cho Administrators (`takeown`, `icacls`).
   - Ghi đè file `win32spl.dll` phiên bản sạch tương thích (trích xuất hoặc từ kho lưu trữ).
   - Thiết lập cấu hình Registry `RpcAuthnLevelPrivacyEnabled = 0`.
   - Khởi động lại Print Spooler.
5. **`Get-VUONGTTLocalUsers`**: Quét danh sách tài khoản Windows, nhóm phân quyền, trạng thái hoạt động và kỳ hạn mật khẩu.
6. **`New-VUONGTTShareUser`**: Tạo người dùng chia sẻ mạng mới với tùy chọn mật khẩu không bao giờ hết hạn.
7. **`Set-VUONGTTUserProperty`**: Khóa/Mở khóa, đổi mật khẩu, gán/gỡ quyền Admin, cấu hình PasswordNeverExpires.
8. **`Remove-VUONGTTUser`**: Xóa user an toàn.
9. **`Get-VUONGTTCredentials` & `Add-VUONGTTCredential` & `Remove-VUONGTTCredential`**: Quản lý Windows Vault / Credential Manager thông qua `cmdkey.exe`.
10. **`Invoke-VUONGTTDataShareFix`**: Bật chia sẻ mạng, chuyển Private Network, sửa lỗi Guest Insecure, cấu hình SMB.

---

## 4. Kiểm Thử TDD & Tiêu Chuẩn Nghiệm Thu

1. **Bộ Test Suite TDD**: `tests/Test-PrinterFixLANSuite.Tests.ps1`
   - Test 1: Kiểm tra cấu trúc XAML chứa đầy đủ 4 sub-tabs, DataGrid máy in, DataGrid User, Modal 0x7c.
   - Test 2: Kiểm tra backend `Get-VUONGTTPrinterList` trả về danh sách máy in hợp lệ.
   - Test 3: Kiểm tra backend `Get-VUONGTTLocalUsers` quét được user hiện tại của hệ điều hành.
   - Test 4: Kiểm tra backend `Invoke-VUONGTTBatchErrorFix` xử lý được các mã lỗi máy trạm, máy chủ và cả hai máy.
   - Test 5: Kiểm tra backend `Get-VUONGTTCredentials` parse đúng kết quả từ `cmdkey.exe`.
   - Test 6: Kiểm tra cú pháp AST 100% các file XAML và PowerShell không có lỗi syntax.
2. **Quy Chuẩn AGENTS.md**:
   - Nâng phiên bản đồng bộ 5 files: `v20.5.909.56` -> `v20.5.909.57`.
   - Biên dịch `VUONGTT_Toolkit.exe` tại local.
   - Khởi chạy Smoke Test xác nhận Exit Code 0.
   - KHÔNG thực hiện `git push` khi chưa có lệnh từ người dùng.
