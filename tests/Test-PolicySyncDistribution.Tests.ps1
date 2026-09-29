# =========================================================================
#   TDD TEST SUITE: POLICY SYNC DISTRIBUTION ACROSS MACHINES
#   Kiem tra co che dong bo phan quyen tu Admin Portal sang cac may khac
# =========================================================================
param()

$ErrorActionPreference = "Stop"

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message
    )
    $script:TotalTests++
    if ($Condition) {
        $script:PassedTests++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
    }
}

Write-Host ">>> BAT DAU CHAY BO TEST POLICY SYNC DISTRIBUTION <<<" -ForegroundColor Cyan

$licManagerPath = Join-Path (Split-Path -Parent $PSScriptRoot) "src\Core\LicenseManager.ps1"
$mainPs1Path    = Join-Path (Split-Path -Parent $PSScriptRoot) "VUONGTT_Toolkit.ps1"
$publishPs1Path = Join-Path (Split-Path -Parent $PSScriptRoot) "Publish-Update.ps1"

$licContent = if (Test-Path $licManagerPath) { [System.IO.File]::ReadAllText($licManagerPath, [System.Text.Encoding]::UTF8) } else { "" }
$mainContent = if (Test-Path $mainPs1Path) { [System.IO.File]::ReadAllText($mainPs1Path, [System.Text.Encoding]::UTF8) } else { "" }
$publishContent = if (Test-Path $publishPs1Path) { [System.IO.File]::ReadAllText($publishPs1Path, [System.Text.Encoding]::UTF8) } else { "" }

# 1. Kiem tra loai bo Downgrade Blocker trong Sync-VUONGTTCloudAdminData
Write-Host "`n--- Test 1: Loai bo Downgrade Blocker trong Sync-VUONGTTCloudAdminData ---"
$hasDowngradeBlocker = ($licContent -match '\$lpRank\s*-gt\s*\$cpRank' -or $licContent -match '\$cp\.Tier\s*=\s*\$lp\.Tier')
Assert-Condition -TestName "1.1: Sync-VUONGTTCloudAdminData khong chan ha cap tu PRO/ADMIN xuong FREE" `
    -Condition (-not $hasDowngradeBlocker) `
    -Message "Sync-VUONGTTCloudAdminData van con doan code lpRank -gt cpRank chan Cloud dong bo ve may khach"

$hasAutoPreservePush = ($licContent -match 'auto-preserve admin tier conflict from Local')
Assert-Condition -TestName "1.2: Khong tu y day nguoc cau hinh cu len Cloud khi co su khac biet" `
    -Condition (-not $hasAutoPreservePush) `
    -Message "Van con lenh tu y day cau hinh cu len Cloud ghi de phan quyen moi cua Admin"

# 2. Kiem tra lam moi du lieu cau hinh dong goi trong EXE vao ProgramData
Write-Host "`n--- Test 2: Lam moi cau hinh dong goi trong EXE vao ProgramData ---"
$hasPolicyAutoRefresh = ($licContent -match 'Update-VUONGTTRuntimeBundledConfig') -and ($licContent -match 'feature_policy\.json')
Assert-Condition -TestName "2.1: Get-VUONGTTDataDir hoac ham khoi tao phai cap nhat feature_policy.json khi file dong goi trong EXE moi hon" `
    -Condition $hasPolicyAutoRefresh `
    -Message "Get-VUONGTTDataDir chi copy khi file chua ton tai (-not (Test-Path dst)), khien file cu khong bao gio duoc cap nhat sau khi nang cap EXE"

# 3. Kiem tra Purge CDN cho feature_policy.json trong Publish-Update.ps1
Write-Host "`n--- Test 3: Purge CDN cho feature_policy.json trong Publish-Update.ps1 ---"
$hasPublishPolicyPurge = ($publishContent -match 'purge.*feature_policy\.json')
Assert-Condition -TestName "3.1: Publish-Update.ps1 phai tu dong purge cache CDN cho feature_policy.json" `
    -Condition $hasPublishPolicyPurge `
    -Message "Publish-Update.ps1 chi purge version.json ma quen purge feature_policy.json tren CDN"

# 4. Kiem tra nut Push Git trong Admin Portal day truc tiep git push va Cloud API
Write-Host "`n--- Test 4: Day Git Push va Cloud API truc tiep trong btnAdminPushGit ---"
$hasDirectGitPushInAdmin = ($mainContent -match 'btnAdminPushGit' -and $mainContent -match 'git\s+(-C\s+\S+\s+)?push\s+origin\s+main' -and $mainContent -match 'feature_policy\.json')
Assert-Condition -TestName "4.1: btnAdminPushGit phai dam bao git push origin main truc tiep cac commit cau hinh chua day" `
    -Condition $hasDirectGitPushInAdmin `
    -Message "btnAdminPushGit chi goi Publish-Update.ps1 ma khong bao dam git push truc tiep cho cac commit chinh sach dang treo"

# 5. Kiem tra tinh toan ven cu phap AST
Write-Host "`n--- Test 5: AST Syntax Integrity ---"
$tokens = $null; $errors = $null
[System.Management.Automation.Language.Parser]::ParseInput($licContent, [ref]$tokens, [ref]$errors) | Out-Null
$licAstOk = ($errors.Count -eq 0)

$tokens = $null; $errors = $null
[System.Management.Automation.Language.Parser]::ParseInput($mainContent, [ref]$tokens, [ref]$errors) | Out-Null
$mainAstOk = ($errors.Count -eq 0)

Assert-Condition -TestName "5.1: Cu phap AST cua LicenseManager.ps1 va VUONGTT_Toolkit.ps1 hop le" `
    -Condition ($licAstOk -and $mainAstOk) `
    -Message "Co loi cu phap AST"

Write-Host "`n========================================================"
Write-Host "KET QUA TEST: $script:PassedTests / $script:TotalTests bai test dat."
Write-Host "========================================================"

if ($script:FailedTests -gt 0) {
    exit 1
}
