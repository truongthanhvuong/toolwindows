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

Write-Host "`n=== KIEM THU TDD: MODULE DOI DNS NHANH & DO PING TOI UU MANG ===" -ForegroundColor Cyan

# 1. Kiem tra file engine DnsChangerEngine.ps1
$hasEngine = Test-Path $enginePath
Assert-Condition "Tep src\Core\DnsChangerEngine.ps1 ton tai" $hasEngine "Chua tao tep DnsChangerEngine.ps1"

if ($hasEngine) {
    . $enginePath
    # 2. Kiem tra cac ham cot loi
    $hasGetAdapters = (Get-Command "Get-VUONGTTNetworkAdapters" -ErrorAction SilentlyContinue) -ne $null
    $hasGetPresets = (Get-Command "Get-VUONGTTDnsPresets" -ErrorAction SilentlyContinue) -ne $null
    $hasBenchmark = (Get-Command "Test-VUONGTTDnsBenchmark" -ErrorAction SilentlyContinue) -ne $null
    $hasSetDns = (Get-Command "Set-VUONGTTDns" -ErrorAction SilentlyContinue) -ne $null
    Assert-Condition "Dinh nghia day du 4 ham cot loi (Adapters, Presets, Benchmark, SetDns)" ($hasGetAdapters -and $hasGetPresets -and $hasBenchmark -and $hasSetDns) "Thieu it nhat mot ham trong DnsChangerEngine"

    # 3. Chay thuc te Get-VUONGTTDnsPresets
    if ($hasGetPresets) {
        $presets = Get-VUONGTTDnsPresets
        Assert-Condition "Get-VUONGTTDnsPresets tra ve danh muc DNS da dang (it nhat 5 presets)" ($presets -and $presets.Count -ge 5) "Thieu presets DNS"
    }

    # 4. Chay thuc te Get-VUONGTTNetworkAdapters
    if ($hasGetAdapters) {
        $adapters = Get-VUONGTTNetworkAdapters
        Assert-Condition "Get-VUONGTTNetworkAdapters thuc thi an toan khong nem exception" ($null -ne $adapters) "Khong lay duoc danh sach card mang"
    }
} else {
    Assert-Condition "Dinh nghia day du 4 ham cot loi" $false "Engine chua ton tai"
}

# 5. Kiem tra giao dien trong MainWindow.xaml
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
$hasDnsUi = ($xamlContent -match 'x:Name="cmbDnsAdapters"') -and 
            ($xamlContent -match 'x:Name="cmbDnsPresets"') -and 
            ($xamlContent -match 'x:Name="btnApplyDns"') -and 
            ($xamlContent -match 'x:Name="btnBenchmarkDns"')
Assert-Condition "MainWindow.xaml chua cac dieu khien DNS Pro (cmbDnsAdapters, cmbDnsPresets, btnApplyDns, btnBenchmarkDns)" $hasDnsUi "Thieu dieu khien DNS Changer trong XAML"

Write-Host "`nKET QUA KIEM THU: $testsPassed PASS / $testsFailed FAIL" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
