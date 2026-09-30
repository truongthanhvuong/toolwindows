# KẾ HOẠCH TOÀN DIỆN: CHUẨN HÓA GIAO DIỆN, TYPOGRAPHY & CHUYỂN CẢNH PHONG CÁCH APPLE (macOS HIG)

- **Mã kế hoạch**: `PLAN-2026-09-30-APPLE-UI`
- **Phiên bản áp dụng**: `v20.5.909.63+`
- **Mục tiêu**: Chuẩn hóa toàn bộ trải nghiệm người dùng (UX) và giao diện trực quan (UI) của VUONGTT Toolkit theo các nguyên tắc cốt lõi của Apple Human Interface Guidelines (macOS HIG), kết hợp tối ưu hóa hiệu năng render 60 FPS trên nền tảng WPF (Windows Presentation Foundation).

---

## 1. TỔNG QUAN & NGUYÊN TẮC THIẾT KẾ CỐT LÕI (APPLE HIG PHILOSOPHY)

Giao diện phong cách Apple trên hệ thống Windows đạt hiệu quả cao nhất khi kết hợp giữa vẻ đẹp tinh giản, độ sắc nét cao và phản hồi tức thì:

1. **Clarity (Độ rõ ràng & Tinh tế)**: Không gian thoáng đãng, các khối thông tin phân tầng rõ ràng qua khoảng cách (margins/paddings) thay vì các đường kẻ viền dày thô cứng.
2. **Deference (Nội dung là trung tâm)**: Giao diện nền nã làm nổi bật dữ liệu hệ thống, bảng sự cố và các nút hành động thiết yếu.
3. **Depth (Chiều sâu thị giác tự nhiên)**: Sử dụng các lớp nền xếp tầng (layering), đường bo cong liên tục (continuous squircle corners) và bóng đổ môi trường (ambient drop shadow) siêu nhẹ.
4. **Fluid Motion (Chuyển động mượt mà như dòng nước)**: Mọi thao tác chuyển tab, trỏ chuột (hover) và bấm nút (click) đều có phản hồi vi mô tự nhiên qua easing curves (CubicEase Out).

---

## 2. CHUẨN HÓA HỆ THỐNG TYPOGRAPHY (APPLE TYPOGRAPHY STACK)

### 2.1. Đa Tầng Font Chữ Dự Phòng (Multi-Tier Font Stack)
Thay thế font `Segoe UI` đơn lập bằng hệ thống phân tầng ưu tiên cao cấp:

```xml
FontFamily="-apple-system, 'SF Pro Display', 'SF Pro Text', 'Segoe UI Variable Display', 'Segoe UI Variable Text', 'Inter', 'Segoe UI', Arial, sans-serif"
```

- **Môi trường có cài SF Pro**: Tự động hiển thị font gốc của Apple với tỉ lệ chữ hoàn hảo.
- **Windows 11**: Tự động ưu tiên `Segoe UI Variable Display / Text` (font biến thiên thế hệ mới sắc nét của Windows 11).
- **Môi trường cơ bản**: Fallback mượt mà về `Inter` hoặc `Segoe UI` không bao giờ bị lỗi hiển thị.

### 2.2. Bảng Phân Cấp Cỡ Chữ & Trọng Lượng (Type Hierarchy)

| Cấp bậc | Font Size | Font Weight | Line Height | Ứng dụng |
| :--- | :--- | :--- | :--- | :--- |
| **Large Title** | 20.0 pt | Bold (700) | 26 px | Tiêu đề chính của Hub (`txtPageTitle`) |
| **Section Title** | 15.0 - 16.0 pt | SemiBold (600) | 22 px | Tiêu đề Card, nhóm công cụ lớn |
| **Headline** | 13.5 - 14.0 pt | SemiBold (600) | 18 px | Tiêu đề danh sách, tên cột DataGrid |
| **Body Text** | 12.5 - 13.0 pt | Regular (400) | 18 px | Văn bản mô tả, kết quả chẩn đoán |
| **Caption / Subtitle** | 11.0 - 11.5 pt | Medium (500) | 16 px | Thông tin bổ trợ, hướng dẫn, đồng hồ |
| **Micro / Badge** | 10.0 - 10.5 pt | SemiBold (600) | 14 px | Huy hiệu bản quyền, version, nhãn trạng thái |
| **Code / Terminal** | 12.0 pt | Regular (400) | 18 px | Console log (`SF Mono, Cascadia Code, Consolas`) |

---

## 3. HỆ THỐNG MÀU SẮC, CARD & BỌ BO GÓC (APPLE VISUAL SYSTEM)

### 3.1. Bo Góc Squircle Liên Tục (Continuous Rounded Corners)
- **Vỏ ngoài Card & Dialog Container**: `CornerRadius="12"`
- **Thanh Capsule Sub-tabs & Segmented Control**: `CornerRadius="20"` (dạng viên thuốc nổi)
- **Nút bấm Action Buttons & TextBoxes**: `CornerRadius="8"`
- **Huy hiệu (Badges) & Avatar Status**: `CornerRadius="14"` đến `"34"` (tròn hoàn toàn)

### 3.2. Bảng Màu Thích Ứng (Apple Palette - Light / Dark Theme)
- **Background chính (Canvas)**: Light `#F8FAFC`, Dark `#0F172A`
- **Thẻ Card Surface**: Light `#FFFFFF`, Dark `#1E293B`
- **Lòng Card / Inner Container**: Light `#F1F5F9`, Dark `#0F172A`
- **Đường viền tối giản (Subtle Border)**: Light `#E2E8F0` (Thickness 1px), Dark `#334155`
- **Bóng đổ Ambient Shadow**:
  ```xml
  <DropShadowEffect Color="#000000" BlurRadius="16" ShadowDepth="2" Direction="270" Opacity="0.04"/>
  ```

---

## 4. ĐỘNG CƠ CHUYỂN CẢNH MƯỢT MÀ (APPLE FLUID TAB TRANSITION ENGINE)

### 4.1. Kiến Trúc Hiệu Ứng Kép (Simultaneous Fade & Micro-Slide)
Khi người dùng chuyển đổi giữa các Hub chính hoặc giữa các Capsule Sub-tabs:
1. **Opacity Animation**: Chuyển biến độ mờ từ `0.20` lên `1.00` trong `220ms`.
2. **TranslateTransform Y Animation**: Trượt nhẹ vi mô theo trục dọc từ `Y = +8px` lên `Y = 0px` trong `220ms`.
3. **Easing Function**: Sử dụng `CubicEase` với `EasingMode="EaseOut"`, tạo cảm giác chuyển động hãm phanh mềm mại đặc trưng của macOS/iOS.

### 4.2. Mẫu Mã Cài Đặt WPF XAML / C#

```xml
<!-- Resources trong App/Window -->
<Storyboard x:Key="AppleFluidFadeIn">
    <DoubleAnimation Storyboard.TargetProperty="Opacity"
                     From="0.2" To="1.0" Duration="0:0:0.22">
        <DoubleAnimation.EasingFunction>
            <CubicEase EasingMode="EaseOut"/>
        </DoubleAnimation.EasingFunction>
    </DoubleAnimation>
    <DoubleAnimation Storyboard.TargetProperty="(UIElement.RenderTransform).(TranslateTransform.Y)"
                     From="8" To="0" Duration="0:0:0.22">
        <DoubleAnimation.EasingFunction>
            <CubicEase EasingMode="EaseOut"/>
        </DoubleAnimation.EasingFunction>
    </DoubleAnimation>
</Storyboard>
```

```powershell
# Kích hoạt chuyển cảnh mượt mà trong Switch-Tab
function Animate-PageTransition {
    param([System.Windows.FrameworkElement]$targetPage)
    if (-not $targetPage) { return }
    $transform = New-Object System.Windows.Media.TranslateTransform(0, 8)
    $targetPage.RenderTransform = $transform
    
    $animFade = New-Object System.Windows.Media.Animation.DoubleAnimation(0.2, 1.0, [TimeSpan]::FromMilliseconds(220))
    $animSlide = New-Object System.Windows.Media.Animation.DoubleAnimation(8, 0, [TimeSpan]::FromMilliseconds(220))
    $ease = New-Object System.Windows.Media.Animation.CubicEase
    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
    $animFade.EasingFunction = $ease
    $animSlide.EasingFunction = $ease
    
    $targetPage.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $animFade)
    $transform.BeginAnimation([System.Windows.Media.TranslateTransform]::YProperty, $animSlide)
}
```

---

## 5. LỘ TRÌNH TRIỂN KHAI THEO TỪNG GIAI ĐOẠN (ROADMAP)

### Giai đoạn 1: Chuẩn hóa Typography & Styles trong `MainWindow.xaml`
- Thay thế toàn bộ `FontFamily` cứng bằng Apple Typography Stack.
- Đồng bộ `CornerRadius` cho toàn bộ 48 thẻ Card trên 8 Hubs.
- Cập nhật DataGrid headers và DataGrid rows theo kiểu macOS striped list (hàng xen kẽ tinh tế).

### Giai đoạn 2: Tích hợp Động cơ Chuyển Cảnh (Fluid Transition Engine)
- Bổ sung `RenderTransform` sẵn trên các container Hub (`containerSysInfo`, `pageSystemFix`, `pageNetworkLAN`...).
- Gắn hàm `Animate-PageTransition` vào cuối hàm `Switch-Tab` và các hàm `Switch-*SubTab`.
- Đảm bảo cơ chế Lazy Session Cache vẫn duy trì phản hồi 0ms, không gây sụt giảm FPS.

### Giai đoạn 3: Tinh chỉnh Chi Tiết Nút Bấm, Terminal Console & Feedback Vi Mô
- Chuẩn hóa các nút bấm Primary (`#B45309`, `#0284C7`) có hiệu ứng bo góc 8px và bóng đổ nhẹ.
- Tinh chỉnh `txtTroubleshootConsoleLog` và `txtDriverLog` sang phong cách macOS Terminal với font `SF Mono` / `Cascadia Code`, padding 12px, nền `#0B0F19`.

### Giai đoạn 4: Kiểm Thử Toàn Diện (Verification & Quality Gates)
- Kiểm tra toàn bộ 37 bộ test suite bảo đảm 100% PASS.
- Kiểm tra tính hợp lệ của XamlReader::Load (0 lỗi parse).
- Xác thực thị giác thực tế trên cả Windows 10 và Windows 11.
