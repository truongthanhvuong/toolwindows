# Test-DnsChanger.Tests.ps1
# TDD Test for DNS Changer Pro Module & Benchmark Latency

$ErrorActionPreference = "Stop"
$root = "e:\toolwindows"
$enginePath = Join-Path $root "src\Core\DnsChangerEngine.ps1"
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

Write-Host "`n=== KIỂM THỬ TDD: MODULE ĐỔI DNS NHANH & ĐO PING TỐI ƯU MẠNG ===" -ForegroundColor Cyan

# 1. Kiểm tra file engine DnsChangerEngine.ps1
$hasEngine = Test-Path $enginePath
Assert-Condition "Tệp src\Core\DnsChangerEngine.ps1 tồn tại" $hasEngine "Chưa tạo tệp DnsChangerEngine.ps1"

if ($hasEngine) {
    . $enginePath
    # 2. Kiểm tra các hàm cốt lõi
    $hasGetAdapters = (Get-Command "Get-VUONGTTNetworkAdapters" -ErrorAction SilentlyContinue) -ne $null
    $hasGetPresets = (Get-Command "Get-VUONGTTDnsPresets" -ErrorAction SilentlyContinue) -ne $null
    $hasBenchmark = (Get-Command "Test-VUONGTTDnsBenchmark" -ErrorAction SilentlyContinue) -ne $null
    $hasSetDns = (Get-Command "Set-VUONGTTDns" -ErrorAction SilentlyContinue) -ne $null
    Assert-Condition "Định nghĩa đầy đủ 4 hàm cốt lõi (Adapters, Presets, Benchmark, SetDns)" ($hasGetAdapters -and $hasGetPresets -and $hasBenchmark -and $hasSetDns) "Thiếu ít nhất một hàm trong DnsChangerEngine"

    # 3. Chạy thực tế Get-VUONGTTDnsPresets
    if ($hasGetPresets) {
        $presets = Get-VUONGTTDnsPresets
        Assert-Condition "Get-VUONGTTDnsPresets trả về danh mục DNS đa dạng (ít nhất 5 presets)" ($presets -and $presets.Count -ge 5) "Thiếu presets DNS"
    }

    # 4. Chạy thực tế Get-VUONGTTNetworkAdapters
    if ($hasGetAdapters) {
        $adapters = Get-VUONGTTNetworkAdapters
        Assert-Condition "Get-VUONGTTNetworkAdapters thực thi an toàn không ném exception" ($adapters -ne $null) "Không lấy được danh sách card mạng"
    }
} else {
    Assert-Condition "Định nghĩa đầy đủ 4 hàm cốt lõi" $false "Engine chưa tồn tại"
}

# 5. Kiểm tra giao diện trong MainWindow.xaml
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
$hasDnsUi = ($xamlContent -match 'x:Name="cmbDnsAdapters"') -and 
            ($xamlContent -match 'x:Name="cmbDnsPresets"') -and 
            ($xamlContent -match 'x:Name="btnApplyDns"') -and 
            ($xamlContent -match 'x:Name="btnBenchmarkDns"')
Assert-Condition "MainWindow.xaml chứa các điều khiển DNS Pro (cmbDnsAdapters, cmbDnsPresets, btnApplyDns, btnBenchmarkDns)" $hasDnsUi "Thiếu điều khiển DNS Changer trong XAML"

Write-Host "`nKẾT QUẢ KIỂM THỬ: $testsPassed PASS / $testsFailed FAIL" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
