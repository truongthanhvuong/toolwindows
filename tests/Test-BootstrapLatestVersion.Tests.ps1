# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ BOOTSTRAPPER LUÔN KHỞI CHẠY BẢN MỚI NHẤT
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

Write-Host ">>> BAT DAU CHAY BO TEST BOOTSTRAPPER LATEST VERSION SAFETY <<<" -ForegroundColor Cyan

$vuongttPath = Join-Path $PSScriptRoot "..\vuongtt.ps1"
$winPath     = Join-Path $PSScriptRoot "..\win.ps1"

$vuongttContent = Get-Content -Path $vuongttPath -Raw -Encoding UTF8
$winContent     = Get-Content -Path $winPath -Raw -Encoding UTF8

# ------------------------------------------------------------------------------
# 1. Cơ chế truy vấn SHA và Version mới nhất từ Cloud chống stale cache
# ------------------------------------------------------------------------------
Assert-Condition -TestName "1.1: vuongtt.ps1 truy van commit SHA hoac version.json tu Cloud" `
    -Condition ($vuongttContent -match 'commits/main' -or $vuongttContent -match 'version\.json') `
    -Message "vuongtt.ps1 chua co logic lay SHA/version.json de chong cache cu"

Assert-Condition -TestName "1.2: win.ps1 truy van commit SHA hoac version.json tu Cloud" `
    -Condition ($winContent -match 'commits/main' -or $winContent -match 'version\.json') `
    -Message "win.ps1 chua co logic lay SHA/version.json de chong cache cu"

# ------------------------------------------------------------------------------
# 2. Xây dựng URL tải bằng Commit SHA hoặc Cache Buster chống Fastly CDN cache
# ------------------------------------------------------------------------------
Assert-Condition -TestName "2.1: vuongtt.ps1 su dung Commit SHA trong duong dan tai de bypass 100% Fastly cache" `
    -Condition ($vuongttContent -match 'raw\.githubusercontent\.com/truongthanhvuong/\$latestSha' -or $vuongttContent -match '\$latestSha/VUONGTT_Toolkit\.exe') `
    -Message "vuongtt.ps1 chua su dung Commit SHA de tai file moi nhat"

Assert-Condition -TestName "2.2: win.ps1 su dung Commit SHA trong duong dan tai de bypass 100% Fastly cache" `
    -Condition ($winContent -match 'raw\.githubusercontent\.com/truongthanhvuong/\$latestSha' -or $winContent -match '\$latestSha/VUONGTT_Toolkit\.exe') `
    -Message "win.ps1 chua su dung Commit SHA de tai file moi nhat"

# ------------------------------------------------------------------------------
# 3. Loại bỏ link jsdelivr tải exe (vì trả về HTTP 403 Forbidden)
# ------------------------------------------------------------------------------
Assert-Condition -TestName "3.1: vuongtt.ps1 khong su dung jsdelivr de tai file exe (tranh loi 403 Forbidden)" `
    -Condition (-not ($vuongttContent -match 'cdn\.jsdelivr\.net/.+/VUONGTT_Toolkit\.exe')) `
    -Message "vuongtt.ps1 van con link jsdelivr tai exe bi chan 403"

Assert-Condition -TestName "3.2: win.ps1 khong su dung jsdelivr de tai file exe (tranh loi 403 Forbidden)" `
    -Condition (-not ($winContent -match 'cdn\.jsdelivr\.net/.+/VUONGTT_Toolkit\.exe')) `
    -Message "win.ps1 van con link jsdelivr tai exe bi chan 403"

# ------------------------------------------------------------------------------
# 4. Kiểm tra phiên bản file cục bộ (ProductVersion) so với Cloud Version
# ------------------------------------------------------------------------------
Assert-Condition -TestName "4.1: vuongtt.ps1 kiem tra ProductVersion cua file cu de quyet dinh cap nhat" `
    -Condition ($vuongttContent -match 'ProductVersion' -or $vuongttContent -match 'VersionInfo') `
    -Message "vuongtt.ps1 chua so sanh ProductVersion voi ban moi tu Cloud"

Assert-Condition -TestName "4.2: win.ps1 kiem tra ProductVersion cua file cu de quyet dinh cap nhat" `
    -Condition ($winContent -match 'ProductVersion' -or $winContent -match 'VersionInfo') `
    -Message "win.ps1 chua so sanh ProductVersion voi ban moi tu Cloud"

# ------------------------------------------------------------------------------
# 5. Vòng lặp giải phóng file lock an toàn trước khi ghi đè
# ------------------------------------------------------------------------------
Assert-Condition -TestName "5.1: vuongtt.ps1 co vong lap cho giai phong process/file lock truoc khi ghi de" `
    -Condition ($vuongttContent -match 'while\s*\(.+Get-Process.+VUONGTT_Toolkit' -or $vuongttContent -match 'Start-Sleep.+Move-Item') `
    -Message "vuongtt.ps1 chua co vong lap cho release file lock khi stop process cu"

# ------------------------------------------------------------------------------
# 6. Kiểm tra AST Syntax của vuongtt.ps1 và win.ps1
# ------------------------------------------------------------------------------
$syntaxPass = $true
foreach ($f in @($vuongttPath, $winPath)) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $syntaxPass = $false
        Write-Host "  [SYNTAX ERROR] $f : $($errors[0].Message)" -ForegroundColor Red
    }
}
Assert-Condition -TestName "6.1: Cu phap AST cua vuongtt.ps1 va win.ps1 hop le" -Condition $syntaxPass

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $testsPassed / $($testsPassed + $testsFailed) bai test dat." -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
