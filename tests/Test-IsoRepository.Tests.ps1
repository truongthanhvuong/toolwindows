# Test-IsoRepository.Tests.ps1
# TDD Test for Official Windows ISO Repository & SHA-256 Hash Verifier

$ErrorActionPreference = "Stop"
$root = "e:\toolwindows"
$enginePath = Join-Path $root "src\Core\IsoRepositoryEngine.ps1"
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

Write-Host "`n=== KIỂM THỬ TDD: KHO TẢI ISO GỐC & ĐỐI SOÁT CHECKSUM SHA-256 ===" -ForegroundColor Cyan

# 1. Kiểm tra file engine IsoRepositoryEngine.ps1
$hasEngine = Test-Path $enginePath
Assert-Condition "Tệp src\Core\IsoRepositoryEngine.ps1 tồn tại" $hasEngine "Chưa tạo tệp IsoRepositoryEngine.ps1"

if ($hasEngine) {
    . $enginePath
    # 2. Kiểm tra các hàm cốt lõi
    $hasGetCatalog = (Get-Command "Get-VUONGTTIsoCatalog" -ErrorAction SilentlyContinue) -ne $null
    $hasVerifyHash = (Get-Command "Get-VUONGTTFileHashCheck" -ErrorAction SilentlyContinue) -ne $null
    Assert-Condition "Định nghĩa đầy đủ 2 hàm cốt lõi (Get-VUONGTTIsoCatalog, Get-VUONGTTFileHashCheck)" ($hasGetCatalog -and $hasVerifyHash) "Thiếu ít nhất một hàm trong IsoRepositoryEngine"

    # 3. Chạy thực tế Get-VUONGTTIsoCatalog
    if ($hasGetCatalog) {
        $catalog = Get-VUONGTTIsoCatalog
        Assert-Condition "Get-VUONGTTIsoCatalog trả về danh mục ISO (ít nhất 5 bản Win gốc)" ($catalog -and $catalog.Count -ge 5) "Danh mục ISO thiếu hoặc rỗng"
        $first = $catalog | Select-Object -First 1
        Assert-Condition "Mỗi bản ghi ISO có đầy đủ Name, DownloadUrl, OfficialSha256" ($first.Name -and $first.DownloadUrl -and $first.OfficialSha256) "Bản ghi ISO thiếu trường thông tin chuẩn"
    }

    # 4. Chạy thực tế Get-VUONGTTFileHashCheck trên file mẫu
    if ($hasVerifyHash) {
        $tmp = Join-Path $env:TEMP "test_sha256_chk.txt"
        "VUONGTT TOOLKIT OFFICIAL ISO TEST CONTENT" | Set-Content -Path $tmp -Encoding ASCII
        $chk = Get-VUONGTTFileHashCheck -FilePath $tmp -ExpectedSha256 "FAKE_HASH"
        Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
        Assert-Condition "Get-VUONGTTFileHashCheck tính toán hash và trả về kết quả đối soát chính xác" ($chk -and $chk.CalculatedSha256 -and ($chk.IsMatch -eq $false)) "Hàm tính hash lỗi"
    }
} else {
    Assert-Condition "Định nghĩa đầy đủ 2 hàm cốt lõi" $false "Engine chưa tồn tại"
}

# 5. Kiểm tra giao diện trong MainWindow.xaml
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
$hasIsoUi = ($xamlContent -match 'x:Name="cmbIsoCatalog"') -and 
            ($xamlContent -match 'x:Name="btnOpenIsoDownload"') -and 
            ($xamlContent -match 'x:Name="txtOfficialIsoSha256"') -and 
            ($xamlContent -match 'x:Name="btnVerifyIsoSha256"')
Assert-Condition "MainWindow.xaml chứa các điều khiển Kho ISO & Checksum (cmbIsoCatalog, btnOpenIsoDownload, txtOfficialIsoSha256, btnVerifyIsoSha256)" $hasIsoUi "Thiếu điều khiển Kho ISO trong XAML"

Write-Host "`nKẾT QUẢ KIỂM THỬ: $testsPassed PASS / $testsFailed FAIL" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
