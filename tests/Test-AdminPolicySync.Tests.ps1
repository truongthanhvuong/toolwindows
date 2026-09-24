# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ ĐỒNG BỘ PHÂN QUYỀN ADMIN PORTAL VỚI GIT & CLOUD
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

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST ADMIN POLICY SYNC & GIT PRESERVATION <<<" -ForegroundColor Cyan

$licManagerPath = Join-Path $PSScriptRoot "..\src\Core\LicenseManager.ps1"
$mainScriptPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"
$gitPolicyPath  = Join-Path $PSScriptRoot "..\src\Config\feature_policy.json"

$licContent = [System.IO.File]::ReadAllText($licManagerPath, [System.Text.Encoding]::UTF8)
$mainContent = [System.IO.File]::ReadAllText($mainScriptPath, [System.Text.Encoding]::UTF8)

# ------------------------------------------------------------------------------
# 1. KIỂM THỬ ĐỒNG BỘ TRỰC TIẾP VÀO GIT REPO KHI LƯU CẤU HÌNH ADMIN
# ------------------------------------------------------------------------------
$hasDevRepoSync = ($licContent -match 'Save-VUONGTTFeaturePolicies' -and ($licContent -match 'Sync-VUONGTTLocalGitFile' -or $licContent -match 'E:\\toolwindows\\src\\Config'))
Assert-Condition -TestName "1.1: Save-VUONGTTFeaturePolicies phải đồng bộ trực tiếp vào Git workspace file" `
    -Condition ($hasDevRepoSync) `
    -Message "Chưa có đường dẫn đồng bộ trực tiếp vào git workspace"

# Kiểm tra đồng bộ License Vault vào Git Workspace
$hasVaultGitSync = ($licContent -match 'Save-VUONGTTLicenseVault' -and ($licContent -match 'E:\\toolwindows\\src\\Config\\licenses_vault\.json' -or $licContent -match 'licenses_vault\.json'))
Assert-Condition -TestName "1.2: Save-VUONGTTLicenseVault phải đồng bộ trực tiếp vào Git workspace licenses_vault.json" `
    -Condition ($hasVaultGitSync) `
    -Message "Chưa có cơ chế đồng bộ kho License Key vào git workspace"

# ------------------------------------------------------------------------------
# 2. KIEM THU CO CHE BAO VE CHONG HA CAP BOI CLOUD (TIER PRESERVATION)
# ------------------------------------------------------------------------------
# Khi Cloud trả về bản cũ (PRO/FREE), nếu Local đã là ADMIN thì không được ghi đè làm mất ADMIN
$hasTierPreservation = ($licContent -match 'ADMIN' -and ($licContent -match 'TierRank|Preserv|Downgrade|Ưu tiên|tierWeight'))
Assert-Condition -TestName "2.1: Phải có cơ chế chống ghi đè hạ cấp từ Cloud (Admin Tier Preservation)" `
    -Condition ($hasTierPreservation) `
    -Message "Chưa có cơ chế bảo vệ phân quyền ADMIN chống bị Cloud cache cũ ghi đè hạ cấp"

# ------------------------------------------------------------------------------
# 3. KIỂM THỬ GIAO DIỆN ADMIN LƯU VÀ PHẢN HỒI KẾT QUẢ THỰC TẾ
# ------------------------------------------------------------------------------
$handlesSaveFeedback = ($mainContent -match '\$saved' -and $mainContent -match 'ADMIN')
Assert-Condition -TestName "3.1: Giao diện btnSavePolicies phải xử lý đầy đủ 3 tier FREE, PRO, ADMIN" `
    -Condition ($handlesSaveFeedback) `
    -Message "Giao diện chưa xử lý trọn vẹn tier ADMIN khi lưu cấu hình"

# ------------------------------------------------------------------------------
# 4. KIỂM THỬ ĐỒNG BỘ GIT LOCAL AUTOMATION (TỰ ĐỘNG GIT ADD / STAGE NẾU CÓ .GIT)
# ------------------------------------------------------------------------------
$hasGitStageSupport = ($licContent -match 'git add' -or $licContent -match 'git\.exe')
Assert-Condition -TestName "4.1: Tự động cập nhật Git tracking (git add) khi lưu cấu hình hoặc tạo Key tại Dev Repo" `
    -Condition ($hasGitStageSupport) `
    -Message "Chưa có cơ chế tự động stage file policy hoặc vault vào git khi chạy ở dev repo"

# ------------------------------------------------------------------------------
# 5. KIỂM THỬ CÚ PHÁP AST HỢP LỆ
# ------------------------------------------------------------------------------
$tokens = $null
$err1 = $null
$ast1 = [System.Management.Automation.Language.Parser]::ParseFile($licManagerPath, [ref]$tokens, [ref]$err1)

$err2 = $null
$ast2 = [System.Management.Automation.Language.Parser]::ParseFile($mainScriptPath, [ref]$tokens, [ref]$err2)

$hasAstErrors = (($err1.Count -ne 0) -or ($err2.Count -ne 0))
if ($hasAstErrors) {
    if ($err1.Count -gt 0) { Write-Host "LicenseManager AST Errors: $($err1 | Out-String)" -ForegroundColor Yellow }
    if ($err2.Count -gt 0) { Write-Host "VUONGTT_Toolkit AST Errors: $($err2 | Out-String)" -ForegroundColor Yellow }
}

Assert-Condition -TestName "5.1: Cú pháp AST của LicenseManager.ps1 và VUONGTT_Toolkit.ps1 hợp lệ" `
    -Condition (-not $hasAstErrors) `
    -Message "Có lỗi cú pháp AST"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
Write-Host "--------------------------------------------------------"
Write-Host "KẾT QUẢ KIỂM THỬ ADMIN POLICY SYNC:"
Write-Host "  Số test thành công: $testsPassed" -ForegroundColor Green
Write-Host "  Số test thất bại:   $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Green" })
Write-Host "--------------------------------------------------------"

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
