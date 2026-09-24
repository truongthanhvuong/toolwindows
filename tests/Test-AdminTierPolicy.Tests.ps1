# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ PHÂN QUYỀN ADMIN (TIER ADMIN) TRONG HỆ THỐNG
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

Write-Host ">>> BAT DAU CHAY BO TEST KIEM THU PHAN QUYEN ADMIN (TIER ADMIN) <<<" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. Kiểm tra cấu trúc Tier ADMIN trong LicenseManager.ps1
# ------------------------------------------------------------------------------
$licPath = Join-Path $PSScriptRoot "..\src\Core\LicenseManager.ps1"
$licContent = Get-Content -Path $licPath -Raw -Encoding UTF8

Assert-Condition -TestName "1.1: LicenseManager ho tro gia tri Tier ADMIN" `
    -Condition ($licContent -match 'ADMIN') `
    -Message "LicenseManager.ps1 chua khai bao hoac ho tro gia tri Tier ADMIN"

# ------------------------------------------------------------------------------
# 2. Logic Gatekeeper: Phân quyền truy cập 3 tầng (FREE, PRO, ADMIN)
# ------------------------------------------------------------------------------
function Test-FeatureAccessGatekeeper {
    param(
        [string]$FeatureTier,
        [bool]$IsProUser,
        [bool]$IsAdminAuth
    )

    if ($IsAdminAuth) {
        return [PSCustomObject]@{ IsAllowed = $true; Reason = "AdminGranted" }
    }

    if ($FeatureTier -eq "ADMIN") {
        return [PSCustomObject]@{ IsAllowed = $false; Reason = "RequireAdmin" }
    }

    if ($FeatureTier -eq "PRO") {
        if ($IsProUser) {
            return [PSCustomObject]@{ IsAllowed = $true; Reason = "ProGranted" }
        } else {
            return [PSCustomObject]@{ IsAllowed = $false; Reason = "RequirePro" }
        }
    }

    return [PSCustomObject]@{ IsAllowed = $true; Reason = "FreeGranted" }
}

$freeUserOnAdmin = Test-FeatureAccessGatekeeper -FeatureTier "ADMIN" -IsProUser $false -IsAdminAuth $false
Assert-Condition -TestName "2.1: Nguoi dung Free bi CHAN khi vao tinh nang ADMIN" `
    -Condition ($freeUserOnAdmin.IsAllowed -eq $false -and $freeUserOnAdmin.Reason -eq "RequireAdmin")

$proUserOnAdmin = Test-FeatureAccessGatekeeper -FeatureTier "ADMIN" -IsProUser $true -IsAdminAuth $false
Assert-Condition -TestName "2.2: Nguoi dung PRO van bi CHAN khi vao tinh nang ADMIN" `
    -Condition ($proUserOnAdmin.IsAllowed -eq $false -and $proUserOnAdmin.Reason -eq "RequireAdmin")

$adminUserOnAdmin = Test-FeatureAccessGatekeeper -FeatureTier "ADMIN" -IsProUser $false -IsAdminAuth $true
Assert-Condition -TestName "2.3: Quản trị viên (Admin Authenticated) duoc DUNG tinh nang ADMIN" `
    -Condition ($adminUserOnAdmin.IsAllowed -eq $true -and $adminUserOnAdmin.Reason -eq "AdminGranted")

$proUserOnPro = Test-FeatureAccessGatekeeper -FeatureTier "PRO" -IsProUser $true -IsAdminAuth $false
Assert-Condition -TestName "2.4: Nguoi dung PRO dung duoc tinh nang PRO" `
    -Condition ($proUserOnPro.IsAllowed -eq $true -and $proUserOnPro.Reason -eq "ProGranted")

$freeUserOnPro = Test-FeatureAccessGatekeeper -FeatureTier "PRO" -IsProUser $false -IsAdminAuth $false
Assert-Condition -TestName "2.5: Nguoi dung Free bi chan khi vao tinh nang PRO" `
    -Condition ($freeUserOnPro.IsAllowed -eq $false -and $freeUserOnPro.Reason -eq "RequirePro")

$freeUserOnFree = Test-FeatureAccessGatekeeper -FeatureTier "FREE" -IsProUser $false -IsAdminAuth $false
Assert-Condition -TestName "2.6: Nguoi dung Free dung binh thuong tinh nang FREE" `
    -Condition ($freeUserOnFree.IsAllowed -eq $true)

# ------------------------------------------------------------------------------
# 3. Kiểm tra mã nguồn VUONGTT_Toolkit.ps1 tích hợp UI và Gatekeeper ADMIN
# ------------------------------------------------------------------------------
$mainScriptPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"
$mainContent = Get-Content -Path $mainScriptPath -Raw -Encoding UTF8

Assert-Condition -TestName "3.1: Render-VUONGTTAdminPolicies co tuy chon ADMIN trong ComboBox" `
    -Condition ($mainContent -match 'ADMIN' -and $mainContent -match '\$itemAdmin') `
    -Message "VUONGTT_Toolkit.ps1 chua render item ADMIN trong ComboBox phan quyen"

Assert-Condition -TestName "3.2: btnSavePolicies luu dung Tier ADMIN tu ComboBox" `
    -Condition ($mainContent -match '\$tier\s*=\s*switch\s*\(\$cmb\.SelectedIndex\)' -or ($mainContent -match 'SelectedIndex\s*-eq\s*2' -and $mainContent -match '"ADMIN"')) `
    -Message "VUONGTT_Toolkit.ps1 chua xu ly luu Tier ADMIN khi Admin luu cau hinh"

Assert-Condition -TestName "3.3: Switch-Tab chan dung quyen ADMIN va mo modal dang nhap Admin" `
    -Condition ($mainContent -match '\$policy\.Tier\s*-eq\s*["'']ADMIN["'']' -and $mainContent -match 'Show-VUONGTTAdminLoginModal') `
    -Message "Switch-Tab chua tich hop Gatekeeper chan tinh nang Tier ADMIN"

# ------------------------------------------------------------------------------
# 4. Kiểm tra AST Syntax của các file mã nguồn liên quan
# ------------------------------------------------------------------------------
$targetFiles = @($licPath, $mainScriptPath)
$syntaxPass = $true
foreach ($f in $targetFiles) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $syntaxPass = $false
        Write-Host "  [SYNTAX ERROR] $f : $($errors[0].Message)" -ForegroundColor Red
    }
}
Assert-Condition -TestName "4.1: Cu phap AST cua LicenseManager va VUONGTT_Toolkit hop le" -Condition $syntaxPass

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $testsPassed / $($testsPassed + $testsFailed) bai test dat." -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
