# ==============================================================================
# TEST SUITE: KIỂM THỬ XÁC THỰC MẬT KHẨU ADMIN PORTAL
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

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST XÁC THỰC MẬT KHẨU ADMIN PORTAL <<<" -ForegroundColor Cyan

. "$PSScriptRoot\..\src\Core\LicenseManager.ps1"

$validVariants = @(
    "vuongtt",
    "Vuongtt",
    "VUONGTT",
    "vươngtt",
    "admin",
    "Admin",
    "ADMIN",
    "Admin@2026",
    "admin@2026",
    "Vuongtt@2026",
    "vuongtt@2026",
    "123456",
    "12345678",
    "admin123",
    "vuongtt123"
)

foreach ($pwd in $validVariants) {
    $res = Test-VUONGTTAdminAuth -Password $pwd
    Assert-Condition -TestName "Mật khẩu '$pwd' phải đăng nhập thành công" -Condition ($res.IsValid -eq $true) -Message "Mật khẩu hợp lệ nhưng bị từ chối"
}

# Test mật khẩu sai
$invalidVariants = @(
    "sai_mat_khau_123",
    "random_pass_xyz",
    "wrong_admin"
)

foreach ($wrong in $invalidVariants) {
    $res = Test-VUONGTTAdminAuth -Password $wrong
    Assert-Condition -TestName "Mật khẩu sai '$wrong' phải bị chặn" -Condition ($res.IsValid -eq $false) -Message "Mật khẩu sai nhưng lại cho phép"
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "KET QUA: $testsPassed PASS / $($testsPassed + $testsFailed) TESTS" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
