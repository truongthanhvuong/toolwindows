# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ ĐÁNH GIÁ SỨC KHỎE Ổ CỨNG CHUYÊN SÂU & ĐỘ CHAI PIN
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

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST DEEP DISK HEALTH & BATTERY DIAGNOSTICS <<<" -ForegroundColor Cyan

$diskHealthPath = Join-Path $PSScriptRoot "..\src\Core\DiskHealthManager.ps1"
$laptopTestPath = Join-Path $PSScriptRoot "..\src\Core\LaptopTester.ps1"
$mainScriptPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"

$diskContent = [System.IO.File]::ReadAllText($diskHealthPath, [System.Text.Encoding]::UTF8)
$laptopContent = [System.IO.File]::ReadAllText($laptopTestPath, [System.Text.Encoding]::UTF8)
$mainContent = [System.IO.File]::ReadAllText($mainScriptPath, [System.Text.Encoding]::UTF8)

# ------------------------------------------------------------------------------
# 1. KIỂM THỬ SỬA LỖI [ulong] VÀ KHÔNG BAO GIỜ ĐỂ BẢNG S.M.A.R.T TRỐNG
# ------------------------------------------------------------------------------
$hasUlongBug = ($diskContent -match '\[ulong\]')
Assert-Condition -TestName "1.1: Loại bỏ hoàn toàn kiểu dữ liệu không hợp lệ [ulong] trong PowerShell" `
    -Condition (-not $hasUlongBug) `
    -Message "Vẫn còn kiểu [ulong] gây lỗi TypeNotFound làm crash hàm Get-VUONGTTSmartAttributes"

# ------------------------------------------------------------------------------
# 2. KIỂM THỬ BẢNG CHỈ SỐ S.M.A.R.T CHUẨN NVME & ATA CHO TẤT CẢ Ổ ĐĨA
# ------------------------------------------------------------------------------
# Kiểm tra hỗ trợ các chỉ số chuẩn NVMe Log Page 0x02
$hasNvmeSmartFields = ($diskContent -match 'Critical Warning' -and $diskContent -match 'Available Spare' -and $diskContent -match 'Percentage Used')
Assert-Condition -TestName "2.1: Phải có bảng chỉ số S.M.A.R.T chuyên sâu cho chuẩn NVMe" `
    -Condition ($hasNvmeSmartFields) `
    -Message "Chưa trang bị danh sách chỉ số S.M.A.R.T chuẩn NVMe (Critical Warning, Available Spare, Percentage Used)"

# Kiểm tra xử lý lọc bỏ Serial rác FFFF_FFFF_FFFF_FFFF
$filtersDummySerial = ($diskContent -match 'FFFF_FFFF' -or $diskContent -match 'FFFFFFFF')
Assert-Condition -TestName "2.2: Phải có cơ chế lọc bỏ số Serial rác FFFF_FFFF của WMI NVMe" `
    -Condition ($filtersDummySerial) `
    -Message "Chưa xử lý lọc bỏ chuỗi Serial dummy FFFF_FFFF"

# ------------------------------------------------------------------------------
# 3. KIỂM THỬ THUẬT TOÁN ĐÁNH GIÁ SỨC KHỎE SÂU (CRYSTALDISKINFO STANDARD)
# ------------------------------------------------------------------------------
# Khi có Reallocated Sectors > 0 hoặc Pending Sectors > 0, HealthLevel phải là CAUTION hoặc BAD
$hasStrictSectorCaution = ($diskContent -match '\$realloc\s*-gt\s*0[\s\S]+?CAUTION')
Assert-Condition -TestName "3.1: Reallocated Sectors > 0 phải đánh giá là CẢNH BÁO (CAUTION) theo chuẩn CrystalDiskInfo" `
    -Condition ($hasStrictSectorCaution) `
    -Message "Chưa tuân thủ chuẩn CrystalDiskInfo: Khi có Reallocated Sector phải cảnh báo Vàng ngay"

# ------------------------------------------------------------------------------
# 4. KIỂM THỬ CHỨC NĂNG ĐO ĐỘ CHAI PIN & CYCLE COUNT
# ------------------------------------------------------------------------------
# Kiểm tra hiển thị đánh giá mức độ chai pin
$hasBatteryRating = ($laptopContent -match 'Pin Rất Tốt' -or $laptopContent -match 'Pin Chai' -or $laptopContent -match 'Chai Nặng' -or $mainContent -match 'Chai Nặng')
Assert-Condition -TestName "4.1: Phải có đánh giá phân loại mức độ chai pin (Tốt / Chai / Cần thay)" `
    -Condition ($hasBatteryRating) `
    -Message "Chưa có phân loại và lời khuyên kỹ thuật theo mức độ chai pin"

# Kiểm tra hỗ trợ đọc Công nghệ pin hoặc Điện áp
$hasBatteryTech = ($laptopContent -match 'Chemistry' -or $laptopContent -match 'Voltage' -or $laptopContent -match 'Công nghệ pin')
Assert-Condition -TestName "4.2: Phải đọc hoặc hỗ trợ công nghệ pin (Chemistry / Li-ion) hoặc điện áp" `
    -Condition ($hasBatteryTech) `
    -Message "Chưa hỗ trợ đọc công nghệ pin (Chemistry)"

# ------------------------------------------------------------------------------
# 5. KIỂM THỬ CÚ PHÁP AST HỢP LỆ
# ------------------------------------------------------------------------------
$tokens = $null
$err1 = $null
$ast1 = [System.Management.Automation.Language.Parser]::ParseFile($diskHealthPath, [ref]$tokens, [ref]$err1)

$err2 = $null
$ast2 = [System.Management.Automation.Language.Parser]::ParseFile($laptopTestPath, [ref]$tokens, [ref]$err2)

$err3 = $null
$ast3 = [System.Management.Automation.Language.Parser]::ParseFile($mainScriptPath, [ref]$tokens, [ref]$err3)

$hasAstErrors = (($err1.Count -ne 0) -or ($err2.Count -ne 0) -or ($err3.Count -ne 0))
if ($hasAstErrors) {
    if ($err1.Count -gt 0) { Write-Host "DiskHealthManager AST Errors: $($err1 | Out-String)" -ForegroundColor Yellow }
    if ($err2.Count -gt 0) { Write-Host "LaptopTester AST Errors: $($err2 | Out-String)" -ForegroundColor Yellow }
    if ($err3.Count -gt 0) { Write-Host "VUONGTT_Toolkit AST Errors: $($err3 | Out-String)" -ForegroundColor Yellow }
}

Assert-Condition -TestName "5.1: Cú pháp AST của DiskHealthManager.ps1, LaptopTester.ps1, VUONGTT_Toolkit.ps1 hợp lệ" `
    -Condition (-not $hasAstErrors) `
    -Message "Có lỗi cú pháp AST"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
Write-Host "--------------------------------------------------------"
Write-Host "KẾT QUẢ KIỂM THỬ DEEP DISK HEALTH & BATTERY:"
Write-Host "  Số test thành công: $testsPassed" -ForegroundColor Green
Write-Host "  Số test thất bại:   $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "--------------------------------------------------------"

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
