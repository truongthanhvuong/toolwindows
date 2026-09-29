# Test-CrackScanner.Tests.ps1
# TDD Test for Crack Scanner Pro Module (AutoKMS, KMSpico, Registry Hooks)

$ErrorActionPreference = "Stop"
$root = "e:\toolwindows"
$enginePath = Join-Path $root "src\Core\CrackScannerEngine.ps1"
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

Write-Host "`n=== KIỂM THỬ TDD: MODULE QUÉT & TIỆT TRỪ CRACK LẬU (CRACK SCANNER PRO) ===" -ForegroundColor Cyan

# 1. Kiểm tra file engine CrackScannerEngine.ps1
$hasEngine = Test-Path $enginePath
Assert-Condition "Tệp src\Core\CrackScannerEngine.ps1 tồn tại" $hasEngine "Chưa tạo tệp CrackScannerEngine.ps1"

if ($hasEngine) {
    . $enginePath
    # 2. Kiểm tra các hàm cốt lõi
    $hasScan = (Get-Command "Get-VUONGTTCrackThreats" -ErrorAction SilentlyContinue) -ne $null
    $hasClean = (Get-Command "Remove-VUONGTTCrackThreats" -ErrorAction SilentlyContinue) -ne $null
    Assert-Condition "Định nghĩa đầy đủ 2 hàm cốt lõi (Get-VUONGTTCrackThreats, Remove-VUONGTTCrackThreats)" ($hasScan -and $hasClean) "Thiếu ít nhất một hàm trong CrackScannerEngine"

    # 3. Chạy thực tế Get-VUONGTTCrackThreats
    if ($hasScan) {
        $scanRes = Get-VUONGTTCrackThreats
        Assert-Condition "Get-VUONGTTCrackThreats thực thi an toàn không ném exception" ($scanRes -ne $null) "Hàm trả về null hoặc ném lỗi"
        Assert-Condition "Get-VUONGTTCrackThreats trả về thuộc tính IsClean và Threats" ($scanRes.PSObject.Properties['IsClean'] -ne $null) "Đối tượng thiếu thuộc tính IsClean"
    }
} else {
    Assert-Condition "Định nghĩa đầy đủ 2 hàm cốt lõi" $false "Engine chưa tồn tại"
}

# 4. Kiểm tra giao diện trong MainWindow.xaml
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
$hasCrackUi = ($xamlContent -match 'x:Name="btnScanCrackThreats"') -and 
              ($xamlContent -match 'x:Name="btnCleanCrack"')
Assert-Condition "MainWindow.xaml chứa các điều khiển Quét & Dọn Crack (btnScanCrackThreats, btnCleanCrack)" $hasCrackUi "Thiếu điều khiển Quét Crack trong XAML"

Write-Host "`nKẾT QUẢ KIỂM THỬ: $testsPassed PASS / $testsFailed FAIL" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
