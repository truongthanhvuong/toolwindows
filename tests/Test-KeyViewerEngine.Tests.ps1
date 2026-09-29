# Test-KeyViewerEngine.Tests.ps1
# TDD Test for Product Key & OEM BIOS Key Viewer Module

$ErrorActionPreference = "Stop"
$root = "e:\toolwindows"
$enginePath = Join-Path $root "src\Core\KeyViewerEngine.ps1"
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

Write-Host "`n=== KIỂM THỬ TDD: MODULE TRA CỨU PRODUCT KEY & OEM BIOS KEY ===" -ForegroundColor Cyan

# 1. Kiểm tra file engine KeyViewerEngine.ps1
$hasEngine = Test-Path $enginePath
Assert-Condition "Tệp src\Core\KeyViewerEngine.ps1 tồn tại" $hasEngine "Chưa tạo tệp KeyViewerEngine.ps1"

if ($hasEngine) {
    . $enginePath
    # 2. Kiểm tra các hàm cốt lõi
    $hasGetOem = (Get-Command "Get-VUONGTTOemBiosKey" -ErrorAction SilentlyContinue) -ne $null
    $hasGetInstalled = (Get-Command "Get-VUONGTTInstalledWindowsKey" -ErrorAction SilentlyContinue) -ne $null
    $hasGetOffice = (Get-Command "Get-VUONGTTOfficeLicenseStatus" -ErrorAction SilentlyContinue) -ne $null
    Assert-Condition "Định nghĩa đầy đủ 3 hàm cốt lõi (OEM BIOS, Windows Installed, Office License)" ($hasGetOem -and $hasGetInstalled -and $hasGetOffice) "Thiếu ít nhất một hàm trong engine"

    # 3. Chạy thực tế Get-VUONGTTInstalledWindowsKey
    if ($hasGetInstalled) {
        $winKey = Get-VUONGTTInstalledWindowsKey
        Assert-Condition "Get-VUONGTTInstalledWindowsKey trả về đối tượng có ProductName và Key" ($winKey -ne $null -and $winKey.ProductName) "Không lấy được thông tin Windows"
    }

    # 4. Chạy thực tế Get-VUONGTTOemBiosKey
    if ($hasGetOem) {
        $oemKey = Get-VUONGTTOemBiosKey
        Assert-Condition "Get-VUONGTTOemBiosKey thực thi an toàn không ném exception" ($oemKey -ne $null) "Hàm trả về null hoặc lỗi"
    }
} else {
    Assert-Condition "Định nghĩa đầy đủ 3 hàm cốt lõi (OEM BIOS, Windows Installed, Office License)" $false "Engine chưa tồn tại"
}

# 5. Kiểm tra giao diện trong MainWindow.xaml
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
$hasKeyUi = ($xamlContent -match 'x:Name="txtBiosOemKey"') -and 
            ($xamlContent -match 'x:Name="txtWindowsInstalledKey"') -and 
            ($xamlContent -match 'x:Name="btnRefreshProductKeys"')
Assert-Condition "MainWindow.xaml chứa các điều khiển tra cứu Product Key (txtBiosOemKey, txtWindowsInstalledKey, btnRefreshProductKeys)" $hasKeyUi "Thiếu điều khiển tra cứu Key trong XAML"

Write-Host "`nKẾT QUẢ KIỂM THỬ: $testsPassed PASS / $testsFailed FAIL" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
