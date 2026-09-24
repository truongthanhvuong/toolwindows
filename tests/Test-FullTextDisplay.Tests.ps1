# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ HIỂN THỊ ĐẦY ĐỦ TÊN ỨNG DỤNG, VERSION VÀ CÁC THÔNG TIN DÀI
# ==============================================================================

$testsPassed = 0
$testsFailed = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST FULL TEXT & VERSION DISPLAY <<<" -ForegroundColor Cyan

$xamlPath = Join-Path $PSScriptRoot "..\src\UI\MainWindow.xaml"
$xamlContent = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)

# ------------------------------------------------------------------------------
# 1. KIỂM THỬ STYLE AppStoreCard CHO KHO ỨNG DỤNG
# ------------------------------------------------------------------------------
# Trích xuất Style AppStoreCard
$appStoreCardRegex = [regex]::Match($xamlContent, '<Style x:Key="AppStoreCard" TargetType="CheckBox">(?s)(.+?)</Style>')
$appStoreCardXml = if ($appStoreCardRegex.Success) { $appStoreCardRegex.Groups[1].Value } else { "" }

Assert-Condition -TestName "1.1: Style AppStoreCard phải tồn tại trong MainWindow.xaml" `
    -Condition ($appStoreCardXml -ne "") `
    -Message "Không tìm thấy Style AppStoreCard"

# Chiều rộng Card phải >= 236px để đủ không gian hiển thị tên ứng dụng dài
$widthMatch = [regex]::Match($appStoreCardXml, '<Setter Property="Width" Value="(\d+)"')
$cardWidth = if ($widthMatch.Success) { [int]$widthMatch.Groups[1].Value } else { 0 }

Assert-Condition -TestName "1.2: AppStoreCard Width phải >= 236px (hiện tại: $cardWidth px)" `
    -Condition ($cardWidth -ge 236) `
    -Message "Card Width quá hẹp ($cardWidth px), tên ứng dụng dài sẽ bị cắt cụt"

# Card phải có TextWrapping="Wrap" trên TextBlock
$hasTextWrapping = ($appStoreCardXml -match 'TextWrapping="Wrap"')

Assert-Condition -TestName "1.3: TextBlock trong AppStoreCard phải bật TextWrapping='Wrap'" `
    -Condition ($hasTextWrapping) `
    -Message "Chưa bật TextWrapping='Wrap', tên dài hơn 1 dòng sẽ bị cắt dấu 3 chấm"

# Card phải có ToolTip hiển thị đầy đủ tên ứng dụng khi hover chuột
$hasCardToolTip = ($appStoreCardXml -match 'ToolTip="\{TemplateBinding Content\}"')

Assert-Condition -TestName "1.4: AppStoreCard phải có ToolTip hiển thị trọn vẹn Content" `
    -Condition ($hasCardToolTip) `
    -Message "Chưa có ToolTip cho AppStoreCard"

# Chiều cao Card phải >= 48px để chứa được 2 dòng chữ
$heightMatch = [regex]::Match($appStoreCardXml, '<Setter Property="(?:MinHeight|Height)" Value="(\d+)"')
$cardHeight = if ($heightMatch.Success) { [int]$heightMatch.Groups[1].Value } else { 0 }

Assert-Condition -TestName "1.5: AppStoreCard Height/MinHeight phải >= 48px (hiện tại: $cardHeight px)" `
    -Condition ($cardHeight -ge 48) `
    -Message "Card Height quá thấp ($cardHeight px), không đủ hiển thị 2 dòng chữ"

# ------------------------------------------------------------------------------
# 2. KIỂM THỬ DANH SÁCH GỠ CÀI ĐẶT (lvInstalledApps)
# ------------------------------------------------------------------------------
# Cột Phiên Bản phải >= 130px
$colVerMatch = [regex]::Match($xamlContent, 'Header="Phiên Bản"\s+Width="(\d+)"')
$colVerWidth = if ($colVerMatch.Success) { [int]$colVerMatch.Groups[1].Value } else { 0 }

Assert-Condition -TestName "2.1: Cột Phiên Bản trong lvInstalledApps phải >= 130px (hiện tại: $colVerWidth px)" `
    -Condition ($colVerWidth -ge 130) `
    -Message "Cột Phiên Bản quá hẹp ($colVerWidth px), phiên bản dài sẽ bị che khuất"

# Cột Phiên Bản phải có ToolTip Binding
$hasVersionToolTip = ($xamlContent -match 'ToolTip="\{Binding DisplayVersion\}"')

Assert-Condition -TestName "2.2: Cột Phiên Bản phải có ToolTip={Binding DisplayVersion}" `
    -Condition ($hasVersionToolTip) `
    -Message "Thiếu ToolTip cho cột Phiên Bản"

# Cột Tên Phần Mềm phải có ToolTip Binding
$hasDisplayNameToolTip = ($xamlContent -match 'ToolTip="\{Binding DisplayName\}"')

Assert-Condition -TestName "2.3: Cột Tên Phần Mềm phải có ToolTip={Binding DisplayName}" `
    -Condition ($hasDisplayNameToolTip) `
    -Message "Thiếu ToolTip cho cột Tên Phần Mềm"

# ------------------------------------------------------------------------------
# 3. KIỂM THỬ THÔNG TIN PHẦN CỨNG & HỆ THỐNG
# ------------------------------------------------------------------------------
$hasMachineModelToolTip = ($xamlContent -match 'x:Name="lblMachineModel"[^>]*ToolTip=')
Assert-Condition -TestName "3.1: lblMachineModel phải có ToolTip" `
    -Condition ($hasMachineModelToolTip) `
    -Message "lblMachineModel thiếu ToolTip khi tên model máy dài bị cắt"

$hasMachineBoardToolTip = ($xamlContent -match 'x:Name="lblMachineBoard"[^>]*ToolTip=')
Assert-Condition -TestName "3.2: lblMachineBoard phải có ToolTip" `
    -Condition ($hasMachineBoardToolTip) `
    -Message "lblMachineBoard thiếu ToolTip khi tên mainboard dài bị cắt"

$hasSystemUUIDToolTip = ($xamlContent -match 'x:Name="lblSystemUUID"[^>]*ToolTip=')
Assert-Condition -TestName "3.3: lblSystemUUID phải có ToolTip" `
    -Condition ($hasSystemUUIDToolTip) `
    -Message "lblSystemUUID thiếu ToolTip khi UUID dài bị cắt"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
Write-Host "--------------------------------------------------------"
Write-Host "KẾT QUẢ KIỂM THỬ FULL TEXT & VERSION DISPLAY:"
Write-Host "  Số test thành công: $testsPassed" -ForegroundColor Green
Write-Host "  Số test thất bại:   $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "--------------------------------------------------------"

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
