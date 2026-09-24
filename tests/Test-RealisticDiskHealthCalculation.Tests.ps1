# ==============================================================================
# BỘ TEST TDD: MÔ HÌNH TÍNH TOÁN SỨC KHỎE Ổ CỨNG TOÀN DIỆN THỰC TẾ
# ==============================================================================

$passed = 0
$failed = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $global:passed++
    } else {
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
        $global:failed++
    }
}

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST REALISTIC DISK HEALTH CALCULATION <<<" -ForegroundColor Cyan

$diskMgrPath = Join-Path $PSScriptRoot "..\src\Core\DiskHealthManager.ps1"
. $diskMgrPath

# ------------------------------------------------------------------------------
# 1. KIỂM THỬ MÔ PHỎNG Ổ CỦA USER: 11,902 GIỜ (~496 NGÀY), 1,341 LẦN BẬT
# ------------------------------------------------------------------------------
# Ổ chạy 496 ngày, 1,341 lần bật KHÔNG THỂ BẰNG 100% MÀ PHẢI TỪ 92% ĐẾN 96%
$hasCalcFunc = (Get-Command "Get-VUONGTTRealisticHealthScore" -ErrorAction SilentlyContinue) -ne $null
Assert-Condition -TestName "1.1: Hàm Get-VUONGTTRealisticHealthScore phải tồn tại" `
    -Condition ($hasCalcFunc) `
    -Message "Chưa định nghĩa hàm tính điểm sức khỏe thực tế Get-VUONGTTRealisticHealthScore"

if ($hasCalcFunc) {
    $resUser = Get-VUONGTTRealisticHealthScore -PowerOnHours 11902 -PowerOnCount 1341 -Wear 0 -SizeGB 476.9
    $isRealisticUser = ($resUser.HealthPct -lt 100 -and $resUser.HealthPct -ge 90 -and $resUser.HealthPct -le 96)
    Assert-Condition -TestName "1.2: Ổ chạy 11,902 giờ (~496 ngày) và 1,341 lần bật phải có sức khỏe thực tế 90-96% (hiện tại: $($resUser.HealthPct)%)" `
        -Condition ($isRealisticUser) `
        -Message "Sức khỏe không được phép bằng 100% khi ổ đã chạy 11,902 giờ"

    # ------------------------------------------------------------------------------
    # 2. KIỂM THỬ Ổ MỚI TINH (< 500 GIỜ, < 50 LẦN BẬT)
    # ------------------------------------------------------------------------------
    $resNew = Get-VUONGTTRealisticHealthScore -PowerOnHours 120 -PowerOnCount 25 -Wear 0 -SizeGB 512
    Assert-Condition -TestName "2.1: Ổ mới tinh (120 giờ, 25 lần bật) phải giữ vững 100% (hiện tại: $($resNew.HealthPct)%)" `
        -Condition ($resNew.HealthPct -eq 100) `
        -Message "Ổ mới tinh phải đạt 100%"

    # ------------------------------------------------------------------------------
    # 3. KIỂM THỬ SUY GIẢM DO TẮT ĐỘT NGỘT (UNSAFE SHUTDOWNS)
    # ------------------------------------------------------------------------------
    $resUnsafe = Get-VUONGTTRealisticHealthScore -PowerOnHours 2000 -PowerOnCount 300 -UnsafeShutdowns 150 -Wear 0 -SizeGB 512
    Assert-Condition -TestName "3.1: Ổ có 150 lần tắt nguồn đột ngột (Unsafe Shutdowns) phải bị giảm trừ điểm (hiện tại: $($resUnsafe.HealthPct)%)" `
        -Condition ($resUnsafe.HealthPct -lt 99) `
        -Message "Chưa trừ điểm khi có số lần tắt đột ngột lớn"

    # ------------------------------------------------------------------------------
    # 4. KIỂM THỬ MÔ TẢ GIẢI THÍCH NGUYÊN NHÂN SUY GIẢM RÕ RÀNG
    # ------------------------------------------------------------------------------
    $hasExplanation = ($resUser.Description -match '11.*902' -or $resUser.Description -match 'giờ vận hành' -or $resUser.Description -match 'tuổi thọ')
    Assert-Condition -TestName "4.1: Mô tả sức khỏe phải giải thích rõ ràng mức tiêu hao theo giờ vận hành" `
        -Condition ($hasExplanation) `
        -Message "Mô tả sức khỏe chưa giải thích chi tiết mức tiêu hao theo thời gian hoạt động"
}

# ------------------------------------------------------------------------------
# 5. KIỂM THỬ CÚ PHÁP AST HỢP LỆ
# ------------------------------------------------------------------------------
$diskContent = Get-Content -Path $diskMgrPath -Raw -Encoding UTF8
$tokens = $null
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseInput($diskContent, [ref]$tokens, [ref]$errors)
$astValid = ($errors.Count -eq 0)
Assert-Condition -TestName "5.1: Cú pháp AST của DiskHealthManager.ps1 hợp lệ" `
    -Condition ($astValid) `
    -Message "Lỗi cú pháp trong DiskHealthManager.ps1"

Write-Host "--------------------------------------------------------"
Write-Host "KẾT QUẢ KIỂM THỬ REALISTIC DISK HEALTH:"
Write-Host "  Số test thành công: $passed" -ForegroundColor Green
Write-Host "  Số test thất bại:   $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "--------------------------------------------------------"

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
