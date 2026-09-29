# Tài Liệu Thiết Kế (Design Spec): Chuẩn Hóa Giao Diện, Font Chữ & Hiệu Ứng Theo Chuẩn Apple (macOS HIG)

- **Ngày ban hành**: 29/09/2026
- **Trạng thái**: Bản thảo thiết kế kiến trúc (Draft Specification)
- **Tác giả**: Antigravity & VUONGTT Software Team
- **Hệ thống áp dụng**: `VUONGTT_Toolkit.exe` (WPF XAML + PowerShell Core Engine)

---

## 1. Mục Tiêu & Tầm Nhìn Thiết Kế (Design Vision)

Ứng dụng **VUONGTT Tool Pro 2026** hiện có đầy đủ 16 phân hệ tính năng đồ sộ và thông số phần cứng thời gian thực. Tuy nhiên, giao diện hiện tại mang phong cách Windows cổ điển với font chữ mặc định Segoe UI đậm đặc, hiệu ứng chuyển tab bị giật (hard cut) và các nút điều khiển có viền thô.

Mục tiêu của bản thiết kế này là nâng tầm trải nghiệm thị giác lên đẳng cấp **Apple Human Interface Guidelines (macOS HIG)**:
1. **Fluid Motion (Chuyển động mượt mà)**: Triệt tiêu hoàn toàn hiệu ứng chuyển tab thô cứng, thay thế bằng hoạt ảnh chuyển tiếp mềm mại (Smooth Cross-fade & Micro-slide: Opacity 0 -> 1 và Y-translation 8px -> 0px trong 220ms với `CubicEase Out`).
2. **Apple Typography (Hệ thống chữ thanh lịch)**: Áp dụng font stack chuẩn Apple (`SF Pro Display`, `SF Pro Text`, `Segoe UI Variable Display`, `Segoe UI`, `Inter`), tối ưu hóa phân cấp thị giác (Visual Hierarchy), tỷ lệ kích thước chữ và khoảng cách dòng thông thoáng.
3. **Apple Segmented Controls**: Tái cấu trúc khối chọn Giao diện (Mặc Định / Tối / Sáng) và Ngôn ngữ (VN / EN) thành thanh viên thuốc trượt trứ danh của macOS (Apple Segmented Capsule).
4. **macOS Sidebar Navigation**: Chuyển đổi các nút menu bên trái sang dạng **Apple Pill Selection** (viên thuốc bo tròn `CornerRadius="8"`, hiệu ứng nổi khối tinh tế, màu nền hoạt tính dịu mắt, hover phản hồi tức thì).
5. **Continuous Curvature & Ambient Lighting (Thẻ bo góc mềm & Bóng đổ tự nhiên)**: Thay thế các góc bo gắt bằng độ cong squircle mềm mại (`CornerRadius="12"` đến `"14"` cho các Card lớn, `"8"` cho Card con), bóng đổ môi trường đa lớp siêu mịn (`BlurRadius="20" Opacity="0.04"`).

---

## 2. Chi Tiết Kiến Trúc 5 Trụ Cột Apple HIG

### Trụ Cột 1: Apple Typography & Font Hierarchy

#### Font Stack Đa Tầng (Cross-Platform Fallback):
WPF trên Windows sẽ ưu tiên font Apple nếu máy đã cài (hoặc được nhúng), và tự động fallback về font hiện đại nhất của Windows 11/10 mà vẫn giữ nguyên tỷ lệ thẩm mỹ của Apple:
```xaml
FontFamily="-apple-system, 'SF Pro Display', 'SF Pro Text', 'Segoe UI Variable Display', 'Segoe UI Variable Text', 'Segoe UI', 'Helvetica Neue', Inter, sans-serif"
```

#### Bảng Phân Cấp Typography Chuẩn Apple:
| Cấp bậc | Kích thước (pt) | Độ dày (FontWeight) | Màu sắc (Light Mode) | Ứng dụng |
| :--- | :--- | :--- | :--- | :--- |
| **Large Title / Header** | 18 - 20 | SemiBold (600) | `#1D1D1F` (Apple Dark) | Tiêu đề phân hệ chính, Window Header |
| **Section Title** | 13.5 - 14 | SemiBold (600) | `#1D1D1F` | Tiêu đề nhóm card, card phần cứng |
| **Headline / Metric Value**| 14 - 16 | Bold (700) | `#0071E3` / `#1D1D1F` | Giá trị Gauge (2.5 GHz, 32 GB, 53%) |
| **Subheadline / Label** | 11.5 - 12 | Medium (500) | `#6E6E73` (Apple Gray) | Nhãn thuộc tính (Socket, Bus, VRAM) |
| **Body Regular** | 12 - 12.5 | Normal (400) | `#1D1D1F` | Nội dung văn bản, bảng chi tiết |
| **Caption / Footnote** | 10.5 - 11 | Normal (400) | `#86868B` | Mô tả phụ, footer, trạng thái |
| **Category Header** | 10.5 | SemiBold (600) | `#86868B` | Tiêu đề danh mục Sidebar (viết hoa nhẹ) |

---

### Trụ Cột 2: Hiệu Ứng Chuyển Tab Mượt Mà (Apple Fluid Motion)

#### Nguyên lý Hoạt Họa (Motion Physics):
Thay vì ẩn/hiện thô thiển (`Visibility = Collapsed` / `Visible`), Apple sử dụng chuyển động nhẹ nhàng không gây mất tập trung:
- **Thời gian (Duration)**: `220ms` (0.22 giây) — Điểm ngọt hoàn hảo (Sweet spot) giữa sự tức thì (responsive) và mượt mà (fluid).
- **Đường cong chuyển động (Easing Function)**: `CubicEase` với `EasingMode="EaseOut"`, tạo cảm giác chuyển động vật lý tự nhiên như trên iPadOS/macOS.
- **Thuộc tính biến đổi**:
  - `Opacity`: từ `0.1` lên `1.0`.
  - `RenderTransform.Y` (hoặc `RenderTransform.X`): từ `8px` về `0px`.

#### Kiến trúc Storyboard WPF:
```xaml
<Storyboard x:Key="AppleTabEntranceAnimation">
    <DoubleAnimation Storyboard.TargetProperty="Opacity"
                     From="0.15" To="1.0"
                     Duration="0:0:0.22">
        <DoubleAnimation.EasingFunction>
            <CubicEase EasingMode="EaseOut"/>
        </DoubleAnimation.EasingFunction>
    </DoubleAnimation>
    <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)"
                     From="8" To="0"
                     Duration="0:0:0.22">
        <DoubleAnimation.EasingFunction>
            <CubicEase EasingMode="EaseOut"/>
        </DoubleAnimation.EasingFunction>
    </DoubleAnimation>
</Storyboard>
```

#### Tích hợp vào Hàm `Switch-Tab` trong PowerShell:
Khi người dùng click đổi tab:
1. Trang cũ được ẩn nhanh hoặc hạ opacity.
2. Trang mới được đặt `Visibility = Visible`, gán `TranslateTransform` và kích hoạt hoạt ảnh `AppleTabEntranceAnimation.Begin()`.
3. Giao diện người dùng phản hồi mượt mà 60 FPS mà không tiêu tốn thêm tài nguyên CPU.

---

### Trụ Cột 3: Apple Segmented Controls (Theme & Ngôn Ngữ)

#### Thiết kế Hiện Tại:
- Các nút riêng lẻ hình chữ nhật vuông vức, viền khung dày (`btnThemeDefault`, `btnThemeDark`, `btnThemeLight`, `btnLangVI`, `btnLangEN`).

#### Thiết kế Apple Segmented Capsule:
- Toàn bộ khối điều khiển được bao bọc trong một container duy nhất có nền xám nhẹ bo tròn (`Background="#E5E5EA"` hoặc `#E8E0D5`, `CornerRadius="8"`, `Padding="2"`).
- Nút đang được chọn (Selected Segment) biến thành một viên thuốc trắng nổi (`Background="#FFFFFF"`, `CornerRadius="6"`, bóng đổ nhẹ `BlurRadius="3" Opacity="0.12"`).
- Nút chưa chọn có nền trong suốt, chữ màu xám ghi thanh thoát, hover nhẹ nhàng (`Opacity="0.8"`).

---

### Trụ Cột 4: macOS Sidebar Navigation (Apple Pill Selection)

#### Thiết kế Menu Nút Bấm:
- Mỗi nút menu trong Sidebar có cấu trúc:
  - `CornerRadius="8"` (viên thuốc bo cong nhẹ nhàng).
  - Chiều cao: `32px` - `34px`.
  - Icon kích thước `15px` - `16px`, căn lề trái đều đặn `Margin="8,0,10,0"`.
  - Khi Active:
    - Nền: Viên thuốc nhấn nổi bật màu Apple Amber/Blue (`#0071E3` hoặc `#EADBCA` cho theme hiện tại).
    - Chữ: Đậm nhẹ, màu sắc tương phản cao.
    - Thanh chỉ báo vị trí (Active Indicator Bar): 1 thanh dọc nhỏ `Width="3" CornerRadius="1.5"` ở mép trái.
  - Khi Hover: Nền chuyển màu bán trong suốt siêu êm `0.1s`.

---

### Trụ Cột 5: Squircle Cards & Ambient Shadows

#### Hình Học Thẻ (Card Geometry):
- Các card chính (Hardware Cards, Meter Gauges, Action Bars):
  - `CornerRadius="12"` đến `"14"` (Squircle Apple-like).
  - `BorderThickness="1"` với màu viền đồng nhất mềm mại `BorderBrush="{DynamicResource CardBorderBrush}"`.
  - Đổ bóng môi trường:
    ```xaml
    <Border.Effect>
        <DropShadowEffect BlurRadius="16" Direction="270" ShadowDepth="2" Opacity="0.04" Color="#000000"/>
    </Border.Effect>
    ```
  - Loại bỏ hoàn toàn cảm giác bóng đen nặng nề, giữ cho giao diện luôn sáng sủa, thanh thoát và hiện đại.

---

## 3. Phân Tích Tác Động & Tính Tương Thích (Impact Analysis)

| Vùng Thay Đổi | Mức Độ Tác Động | Rủi Ro | Biện Pháp Phòng Ngừa |
| :--- | :--- | :--- | :--- |
| **`MainWindow.xaml` (Styles & Resources)** | Trung bình | THẤP | Giữ nguyên 100% `x:Name` của tất cả các Button, TextBox, CheckBox, TextBlock, ScrollViewer |
| **`MainWindow.xaml` (Storyboards)** | Nhỏ | THẤP | Chỉ bổ sung Storyboard vào `<Window.Resources>`, không xóa template gốc |
| **`VUONGTT_Toolkit.ps1` (`Switch-Tab`)** | Nhỏ | THẤP | Nâng cấp hàm chuyển tab kết hợp animation, giữ nguyên toàn bộ logic phân quyền Gatekeeper Free/Pro/Admin |
| **Hiệu năng hệ thống (FPS / RAM)** | Tích cực | RẤT THẤP | `DoubleAnimation` của WPF sử dụng phần cứng đồ họa (DirectX Hardware Acceleration), CPU tiêu hao < 0.5% |

---

## 4. Kế Hoạch Kiểm Thử TDD (Test Strategy)

Xây dựng bộ test tự động [`tests/Test-AppleUiDesign.Tests.ps1`](file:///e:/toolwindows/tests/Test-AppleUiDesign.Tests.ps1) kiểm tra:
1. **Font Family**: Khai báo font stack Apple (`SF Pro Display` / `Segoe UI Variable` / `-apple-system`) trong MainWindow.xaml.
2. **Tab Transition Storyboard**: Khai báo đầy đủ Storyboard hoạt họa với `CubicEase` trong Resources.
3. **Squircle & Pill Geometry**: Kiểm tra các Style Card và Menu Button có CornerRadius $\ge 8$.
4. **Segmented Control Structure**: Kiểm tra container bo tròn cho Theme & Language.
5. **Switch-Tab Logic**: Kiểm tra hàm `Switch-Tab` trong `VUONGTT_Toolkit.ps1` gọi animation mượt mà.
6. **AST Syntax Integrity**: 100% không có lỗi cú pháp AST.
