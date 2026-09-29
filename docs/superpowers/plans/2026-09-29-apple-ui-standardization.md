# Chuẩn Hóa Giao Diện, Font Chữ & Hiệu Ứng Theo Chuẩn Apple (macOS HIG) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hiện đại hóa toàn diện giao diện VUONGTT Tool Pro 2026 theo phong cách Apple Human Interface Guidelines (macOS HIG): font chữ thanh lịch Apple SF Pro fallback, hiệu ứng chuyển tab mượt mà (fluid cross-fade & micro-slide), thanh chọn Segmented Control và các thẻ Card bo góc mềm Squircle.

**Architecture:** Mở rộng hệ thống XAML Styles, Resources và Storyboard trong `MainWindow.xaml` kết hợp nâng cấp logic chuyển tab trong `VUONGTT_Toolkit.ps1`. Tận dụng WPF DirectX hardware-accelerated animations (DoubleAnimation kết hợp CubicEase) để đạt 60 FPS mượt mà không gây tốn CPU.

**Tech Stack:** WPF (Windows Presentation Foundation), XAML, C#/.NET 4.8, PowerShell 5.1, Apple Human Interface Guidelines (HIG).

**Spec:** [`docs/superpowers/specs/2026-09-29-apple-ui-standardization-design.md`](file:///e:/toolwindows/docs/superpowers/specs/2026-09-29-apple-ui-standardization-design.md)

## Global Constraints

- 100% giữ nguyên tên điều khiển `x:Name` và các event handler liên kết để không gây ảnh hưởng tới chức năng nghiệp vụ.
- Bảo toàn hỗ trợ 3 chế độ Theme (Mặc Định / Tối / Sáng) và 2 Ngôn ngữ (VI / EN).
- Duy trì định dạng tệp có UTF-8 BOM qua `Fix-AllUtf8Bom.ps1`.
- Tuân thủ nghiêm ngặt quy tắc AGENTS.md: Tự động nâng version cục bộ lên `v20.5.909.54`, biên dịch file thực thi `VUONGTT_Toolkit.exe`, chạy Smoke Test và chỉ lưu commit Git cục bộ (tuyệt đối không tự ý `git push`).

---

### Task 1: Bộ Kiểm Thử TDD Toàn Diện (Red Phase)

**Files:**
- Create: `tests/Test-AppleUiDesign.Tests.ps1`
- Test: `tests/Test-AppleUiDesign.Tests.ps1`

**Interfaces:**
- Consumes: `src/UI/MainWindow.xaml`, `VUONGTT_Toolkit.ps1`
- Produces: Báo cáo kết quả kiểm thử tự động 6 tiêu chuẩn Apple HIG

- [ ] **Step 1: Viết bộ test TDD kiểm tra các tiêu chuẩn giao diện Apple**

Tạo tệp `tests/Test-AppleUiDesign.Tests.ps1` kiểm tra:
1. Font family ưu tiên Apple SF Pro / Segoe UI Variable fallback.
2. Storyboard hoạt họa chuyển tab `AppleTabEntranceAnimation` hoặc logic chuyển tab mượt.
3. Card styles có CornerRadius $\ge 10$ và hiệu ứng bóng đổ mềm.
4. Nút bấm Sidebar có CornerRadius $\ge 7$.
5. Segmented control container cho Theme và Ngôn ngữ.
6. Cú pháp AST không có lỗi.

- [ ] **Step 2: Chạy test xác nhận FAIL thực tế (Red Phase)**

Chạy: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AppleUiDesign.Tests.ps1"`
Kỳ vọng: FAIL (vì các thành phần Apple mới chưa được tích hợp vào mã nguồn).

---

### Task 2: Chuẩn Hóa Apple Typography & Font Family Stack

**Files:**
- Modify: `src/UI/MainWindow.xaml:1-120`

**Interfaces:**
- Consumes: System Fonts
- Produces: Toàn bộ Window, TextBlock, Button, TextBox, ListView thừa hưởng font chữ Apple SF Pro chuẩn mực

- [ ] **Step 1: Cập nhật FontFamily gốc của Window và Styles trong MainWindow.xaml**

Cập nhật `FontFamily` của `<Window>`:
```xaml
FontFamily="-apple-system, 'SF Pro Display', 'SF Pro Text', 'Segoe UI Variable Display', 'Segoe UI Variable Text', 'Segoe UI', 'Helvetica Neue', Inter, sans-serif"
```
Cập nhật các Style mặc định của `TextBlock`, `TextBox`, `Button`, `Label` để dùng chung font stack thanh lịch này.

- [ ] **Step 2: Kiểm tra AST và chạy lại test để ghi nhận tiến độ**

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AppleUiDesign.Tests.ps1"`

---

### Task 3: Hiệu Ứng Chuyển Tab Mượt Mà (Apple Fluid Motion)

**Files:**
- Modify: `src/UI/MainWindow.xaml` (Thêm Storyboard hoạt họa vào `<Window.Resources>`)
- Modify: `VUONGTT_Toolkit.ps1` (Nâng cấp hàm `Switch-Tab` kích hoạt hoạt họa khi chuyển trang)

**Interfaces:**
- Consumes: `$pages` dictionary, `AppleTabEntranceAnimation`
- Produces: Trải nghiệm chuyển tab mượt mà 60 FPS với Opacity fade-in & Micro-slide

- [ ] **Step 1: Thêm Storyboard hoạt họa trong Window.Resources của MainWindow.xaml**

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

- [ ] **Step 2: Cập nhật hàm `Switch-Tab` trong `VUONGTT_Toolkit.ps1`**

Áp dụng `TranslateTransform` và kích hoạt hoạt họa Storyboard cho `$pages[$TargetTag]` ngay khi hiển thị.

- [ ] **Step 3: Chạy test xác nhận phần hoạt họa đã đạt (Pass Task 3)**

---

### Task 4: Apple Segmented Controls & macOS Sidebar Navigation Pills

**Files:**
- Modify: `src/UI/MainWindow.xaml` (Theme selector, Language selector, Menu Button Styles)
- Modify: `VUONGTT_Toolkit.ps1` (Màu sắc trạng thái Active/Hover của Sidebar Pills)

**Interfaces:**
- Consumes: `btnThemeDefault`, `btnThemeDark`, `btnThemeLight`, `btnLangVI`, `btnLangEN`, `$menuButtons`
- Produces: Thanh điều khiển dạng viên thuốc Apple Segmented Control và danh sách menu macOS Sidebar

- [ ] **Step 1: Tái cấu trúc khối Theme & Language thành Apple Segmented Capsule**

Đặt các nút chọn Theme và Language trong container bo tròn `CornerRadius="8"` với nền xám tinh tế, nút được chọn nổi khối với nền trắng.

- [ ] **Step 2: Nâng cấp Sidebar Menu Button Style thành Apple Capsule Pills**

Thiết lập `CornerRadius="8"`, đệm trong `Padding="10,6,10,6"`, icon cách chữ hợp lý, trạng thái Active có viên thuốc nổi bật.

- [ ] **Step 3: Chạy test TDD xác nhận toàn bộ bài test chuyển sang PASS (Green Phase)**

Run: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tests\Test-AppleUiDesign.Tests.ps1"`
Kỳ vọng: 100% PASSED.

---

### Task 5: Kiểm Tra Toàn Diện, Nâng Version & Biên Dịch (AGENTS.md)

**Files:**
- Modify: `version.json`, `src/UI/MainWindow.xaml`, `src/Program.cs`, `src/Core/AppUpdater.ps1`, `VUONGTT_Toolkit.ps1`
- Output: `E:\toolwindows\VUONGTT_Toolkit.exe`

- [ ] **Step 1: Chạy kiểm tra cú pháp AST 100% các file mã nguồn**
- [ ] **Step 2: Chạy toàn bộ 27 bộ test suite trong `tests/`**
- [ ] **Step 3: Tự động nâng số hiệu phiên bản lên `v20.5.909.54` trên 5 tệp tin cốt lõi**
- [ ] **Step 4: Chạy `Fix-AllUtf8Bom.ps1` bảo toàn UTF-8 BOM**
- [ ] **Step 5: Biên dịch `VUONGTT_Toolkit.exe` qua `Build-Exe.ps1 -NoBump`**
- [ ] **Step 6: Chạy Smoke Test `.\VUONGTT_Toolkit.exe --smoke-test` (Exit code 0)**
- [ ] **Step 7: Lưu commit Git cục bộ (tuyệt đối không push lên GitHub khi chưa có lệnh)**
- [ ] **Step 8: Báo cáo kết quả chi tiết bằng số liệu thực tế**
