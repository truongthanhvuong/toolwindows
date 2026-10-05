# Kế Hoạch Triển Khai: Nâng Cấp World Map Trực Quan & Street View 360°

> **Mục tiêu:** Nâng cấp World Map của module Fake VPN / Proxy thành bản đồ tương tác chuyên nghiệp như 1 app thực thụ: bản đồ thế giới vector chi tiết với lưới tọa độ, các điểm trạm bấm tương tác trực tiếp, bộ điều khiển Zoom (+ / - / Reset), Card thông tin chi tiết trạm (Street & Telemetry) và nút mở trực tiếp chế độ Xem Phố Street View 360° trên Google Maps.

## 1. Thông Tin Trạm Toàn Cầu Mở Rộng (`src/Core/VpnProxyManager.ps1`)
Bổ sung trường `StreetAddress`, `Latitude`, `Longitude`, `DataCenter` cho 8 quốc gia:
- **VN:** `Hà Nội - FPT Data Center, Đường Duy Tân, Cầu Giấy (Lat: 21.0307, Lon: 105.7836)`
- **SG:** `Singapore - Equinix SG1, Ayer Rajah Crescent (Lat: 1.2982, Lon: 103.7877)`
- **US:** `Hoa Kỳ - Digital Realty NYC, 60 Hudson St, New York (Lat: 40.7180, Lon: -74.0089)`
- **JP:** `Nhật Bản - Shinjuku Equinix TY2, Tokyo (Lat: 35.6938, Lon: 139.7034)`
- **KR:** `Hàn Quốc - Gangnam Datacenter, Teheran-ro, Seoul (Lat: 37.5008, Lon: 127.0369)`
- **UK:** `Vương Quốc Anh - Telehouse London Docklands (Lat: 51.5113, Lon: -0.0075)`
- **DE:** `Đức - Frankfurt Maincube, Hanauer Landstraße (Lat: 50.1109, Lon: 8.6821)`
- **FR:** `Pháp - Paris PA3 Datacenter, Rue de la Paix (Lat: 48.8698, Lon: 2.3308)`

## 2. Giao Diện World Map (`src/UI/MainWindow.xaml`)
- **Map Controller Bar:**
  - Nút `btnMapZoomIn`: Phóng to (+20%)
  - Nút `btnMapZoomOut`: Thu nhỏ (-20%)
  - Nút `btnMapZoomReset`: Đặt lại tỉ lệ mặc định 100%
- **Interactive Node Pins trên Canvas:**
  - `btnNodeVN`, `btnNodeSG`, `btnNodeUS`, `btnNodeJP`, `btnNodeKR`, `btnNodeUK`, `btnNodeDE`, `btnNodeFR`.
  - Hiệu ứng phát xung (Pulse glow) với màu sắc neon nổi bật.
- **Street View & Node Preview Overlay Card (`cardStreetViewPreview`):**
  - Hiển thị khi người dùng click vào trạm hoặc chọn trên ComboBox:
  - Tên Data Center & Địa chỉ phố thực tế.
  - Tọa độ địa lý GPS (`Lat`, `Lon`).
  - Nút `btnOpenStreetView`: Mở URL Street View trên trình duyệt (`https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=...`).
  - Nút `btnConnectSelectedNode`: Kích hoạt ngay kết nối Proxy tới node này.

## 3. Các Bước Triển Khai:
1. Tạo test TDD: `tests/Test-InteractiveWorldMap.Tests.ps1`.
2. Mở rộng dữ liệu trong `src/Core/VpnProxyManager.ps1`.
3. Bổ sung XAML controls trong `src/UI/MainWindow.xaml`.
4. Ráp xử lý sự kiện trong `VUONGTT_Toolkit.ps1`.
5. Chạy test PASS, kiểm tra AST, tăng version `v20.5.909.90`, compile `VUONGTT_Toolkit.exe` và push GitHub.
