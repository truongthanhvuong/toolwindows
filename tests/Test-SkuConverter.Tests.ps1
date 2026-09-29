# Test-SkuConverter.Tests.ps1
# TDD Test for Windows SKU Converter & Office Retail to Volume (C2R-R2V) Module

$ErrorActionPreference = "Stop"
$root = "e:\toolwindows"
$enginePath = Join-Path $root "src\Core\SkuConverterEngine.ps1"
$xamlPath = Join-Path $root "src\UI\MainWindow.xaml"

$testsPassed = 0
$testsFailed = 0

function Assert-Condition {
    param([string]$Name, [bool]$Condition, [string]$Details = "")
    if ($Condition) {
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $Name - $Details" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host "`n=== KIỂM THỬ TDD: MODULE SKU CONVERTER & OFFICE RETAIL TO VOLUME ===" -ForegroundColor Cyan

# 1. Kiểm tra file engine SkuConverterEngine.ps1
$hasEngine = Test-Path $enginePath
Assert-Condition "Tệp src\Core\SkuConverterEngine.ps1 tồn tại" $hasEngine "Chưa tạo tệp SkuConverterEngine.ps1"

if ($hasEngine) {
    . $enginePath
    # 2. Kiểm tra các hàm cốt lõi
    $hasGetCur = (Get-Command "Get-VUONGTTCurrentWindowsEdition" -ErrorAction SilentlyContinue) -ne $null
    $hasGetTarget = (Get-Command "Get-VUONGTTSupportedTargetSkus" -ErrorAction SilentlyContinue) -ne $null
    $hasWinConvert = (Get-Command "Invoke-VUONGTTWindowsSkuConvert" -ErrorAction SilentlyContinue) -ne $null
    $hasOffConvert = (Get-Command "Invoke-VUONGTTOfficeR2VConvert" -ErrorAction SilentlyContinue) -ne $null
    Assert-Condition "Định nghĩa đầy đủ 4 hàm chuyển đổi (GetCurEdition, SupportedSkus, WinConvert, OfficeR2V)" ($hasGetCur -and $hasGetTarget -and $hasWinConvert -and $hasOffConvert) "Thiếu ít nhất một hàm trong SkuConverterEngine"

    # 3. Chạy thực tế Get-VUONGTTCurrentWindowsEdition
    if ($hasGetCur) {
        $curEd = Get-VUONGTTCurrentWindowsEdition
        Assert-Condition "Get-VUONGTTCurrentWindowsEdition trả về EditionId hợp lệ" ($curEd -and $curEd.EditionId) "Không đọc được EditionId"
    }

    # 4. Chạy thực tế Get-VUONGTTSupportedTargetSkus
    if ($hasGetTarget) {
        $targets = Get-VUONGTTSupportedTargetSkus
        Assert-Condition "Get-VUONGTTSupportedTargetSkus trả về danh sách SKU đích (ít nhất 2 SKU)" ($targets -and $targets.Count -ge 2) "Danh sách SKU đích trống hoặc thiếu"
    }
} else {
    Assert-Condition "Định nghĩa đầy đủ 4 hàm chuyển đổi" $false "Engine chưa tồn tại"
}

# 5. Kiểm tra giao diện trong MainWindow.xaml
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
$hasSkuUi = ($xamlContent -match 'x:Name="cmbWindowsTargetSku"') -and 
            ($xamlContent -match 'x:Name="btnConvertWindowsSku"') -and 
            ($xamlContent -match 'x:Name="btnConvertOfficeR2V"')
Assert-Condition "MainWindow.xaml chứa các điều khiển Sku Converter (cmbWindowsTargetSku, btnConvertWindowsSku, btnConvertOfficeR2V)" $hasSkuUi "Thiếu điều khiển Sku Converter trong XAML"

Write-Host "`nKẾT QUẢ KIỂM THỬ: $testsPassed PASS / $testsFailed FAIL" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
