# tests/Test-ZaloDomainInstallFix.Tests.ps1
# Kiểm thử TDD: Khắc phục triệt để lỗi JavaScript main process (ENOENT package.json) khi cài đặt Zalo trên máy Domain

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $testDir
$passed = 0
$failed = 0

function Assert-Equal($actual, $expected, $message) {
    if ($actual -eq $expected) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $message (Expected: '$expected', Actual: '$actual')" -ForegroundColor Red
        $script:failed++
    }
}

function Assert-True($condition, $message) {
    if ($condition) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "=== BẮT ĐẦU KIỂM THỬ: ZALO DOMAIN INSTALL JAVASCRIPT ERROR FIX ===" -ForegroundColor Cyan

$installerScript = Join-Path $rootDir "src\Core\SoftwareInstaller.ps1"
. $installerScript

# -------------------------------------------------------------
# TEST GROUP 1: Kiểm định tính toàn vẹn của Zalo (app.asar validation)
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 1: Kiểm định tính toàn vẹn gói Zalo (Chống lỗi thiếu app.asar / package.json) ---" -ForegroundColor Yellow

# Tạo mock folder Zalo bị hỏng (chỉ có Zalo.exe nhưng thiếu app.asar)
$mockBrokenDir = "$env:TEMP\MockZaloBroken\Programs\Zalo"
$mockBrokenVer = Join-Path $mockBrokenDir "Zalo-26.9.10"
if (-not (Test-Path $mockBrokenVer)) { New-Item -ItemType Directory -Path $mockBrokenVer -Force | Out-Null }
[System.IO.File]::WriteAllText((Join-Path $mockBrokenDir "Zalo.exe"), "MZ_MOCK_STUB")

# Hàm kiểm tra Zalo phải từ chối nếu app.asar chưa tồn tại hoặc bị hỏng
$checkZaloIntegrityCmd = Get-Command "Test-VUONGTTZaloIntegrity" -ErrorAction SilentlyContinue
Assert-True ($null -ne $checkZaloIntegrityCmd) "Hàm Test-VUONGTTZaloIntegrity phải tồn tại để xác thực app.asar"

if ($checkZaloIntegrityCmd) {
    $isBrokenValid = Test-VUONGTTZaloIntegrity -ZaloRootPath $mockBrokenDir
    Assert-Equal $isBrokenValid $false "Zalo bị thiếu app.asar BẮT BUỘC phải bị đánh giá là INVALID (chống văng ENOENT package.json)"

    # Giả lập tạo app.asar đầy đủ (> 100MB)
    $mockResDir = Join-Path $mockBrokenVer "resources"
    if (-not (Test-Path $mockResDir)) { New-Item -ItemType Directory -Path $mockResDir -Force | Out-Null }
    $mockAsar = Join-Path $mockResDir "app.asar"
    # Tạo file mock lớn hơn 50MB
    $fs = [System.IO.File]::Create($mockAsar)
    $fs.SetLength(150 * 1024 * 1024)
    $fs.Close()

    $isNowValid = Test-VUONGTTZaloIntegrity -ZaloRootPath $mockBrokenDir
    Assert-True $isNowValid "Zalo có đầy đủ app.asar hợp lệ phải được xác nhận VALID"

    # Cleanup mock
    Remove-Item (Split-Path -Parent $mockBrokenDir) -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Assert-True $false "Bỏ qua: Thiếu hàm Test-VUONGTTZaloIntegrity"
    Assert-True $false "Bỏ qua: Kiểm tra app.asar"
}

# -------------------------------------------------------------
# TEST GROUP 2: Tự động dọn dẹp thư mục Zalo bị hỏng trước khi cài đặt
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 2: Tự động dọn dẹp thư mục Zalo hỏng trước khi cài ---" -ForegroundColor Yellow

$cleanZaloCmd = Get-Command "Clear-VUONGTTCorruptedZaloInstall" -ErrorAction SilentlyContinue
Assert-True ($null -ne $cleanZaloCmd) "Hàm Clear-VUONGTTCorruptedZaloInstall phải tồn tại"

# -------------------------------------------------------------
# TEST GROUP 3: Phương thức thực thi ZaloSetup an toàn chống kẹt pipe
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 3: Cơ chế thực thi ZaloSetup an toàn chống kẹt pipe 10 phút ---" -ForegroundColor Yellow

$installerContent = Get-Content $installerScript -Raw -Encoding UTF8
$hasZaloSafeExec = $installerContent -match 'zalo.*Start-Process|Start-Process.*zalo'
Assert-True $hasZaloSafeExec "SoftwareInstaller.ps1 phải có cơ chế thực thi an toàn chuyên biệt cho Zalo tránh pipe hang"

# -------------------------------------------------------------
# TEST GROUP 4: Chống khởi chạy trùng lặp khi NSIS đã tự mở Zalo
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 4: Chống mở trùng lặp tiến trình Zalo ---" -ForegroundColor Yellow

$hasZaloDuplicateGuard = $installerContent -match 'Get-Process.*Zalo'
Assert-True $hasZaloDuplicateGuard "SoftwareInstaller.ps1 phải kiểm tra tiến trình Zalo trước khi gọi Start-VUONGTTInstalledApp"

# -------------------------------------------------------------
# TỔNG KẾT
# -------------------------------------------------------------
Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ: $passed PASSED | $failed FAILED" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "=======================================================" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 } else { exit 0 }
