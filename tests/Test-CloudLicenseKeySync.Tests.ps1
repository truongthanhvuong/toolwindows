# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ ĐỒNG BỘ CLOUD LICENSE KEYS GIỮA CÁC MÁY ADMIN
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

Write-Host ">>> BAT DAU CHAY BO TEST CLOUD LICENSE KEY SYNC <<<" -ForegroundColor Cyan

$licManagerPath = Join-Path $PSScriptRoot "..\src\Core\LicenseManager.ps1"
$vaultJsonPath  = Join-Path $PSScriptRoot "..\src\Config\licenses_vault.json"
$mainScriptPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"

$licManagerContent = Get-Content -Path $licManagerPath -Raw -Encoding UTF8
$vaultJsonContent  = Get-Content -Path $vaultJsonPath -Raw -Encoding UTF8
$mainScriptContent = Get-Content -Path $mainScriptPath -Raw -Encoding UTF8

# ------------------------------------------------------------------------------
# 1. LOAI BO HOAN TOAN JSDELIVR KHOI VIEC DOC VAULT VA POLICY
# ------------------------------------------------------------------------------
$hasJsDelivrVault = ($licManagerContent -match 'jsdelivr\.net.+licenses_vault\.json')
$hasJsDelivrPolicy = ($licManagerContent -match 'jsdelivr\.net.+feature_policy\.json')

Assert-Condition -TestName "1.1: Loai bo hoan toan jsDelivr CDN khoi doc licenses_vault.json" `
    -Condition (-not $hasJsDelivrVault) `
    -Message "Van con su dung jsDelivr CDN de doc licenses_vault.json gay loi cache 24h"

Assert-Condition -TestName "1.2: Loai bo hoan toan jsDelivr CDN khoi doc feature_policy.json" `
    -Condition (-not $hasJsDelivrPolicy) `
    -Message "Van con su dung jsDelivr CDN de doc feature_policy.json gay loi cache 24h"

# ------------------------------------------------------------------------------
# 2. UU TIEN GITHUB REST API TANG 1 VOI TOKEN (0S CACHE)
# ------------------------------------------------------------------------------
# Kiem tra xem GitHub Contents REST API co duoc dat truoc trong Sync-VUONGTTCloudAdminData hay khong
$syncFuncMatch = [regex]::Match($licManagerContent, 'function\s+Sync-VUONGTTCloudAdminData\s*\{(?s)(.+?)\nfunction\s+')
$syncFuncBody = if ($syncFuncMatch.Success) { $syncFuncMatch.Groups[1].Value } else { "" }

$posGithubApi = $syncFuncBody.IndexOf("api.github.com/repos")
$posRawGithub = $syncFuncBody.IndexOf("raw.githubusercontent.com")

Assert-Condition -TestName "2.1: GitHub REST API phai duoc goi o Tang 1 truoc Fallback Raw" `
    -Condition ($posGithubApi -ge 0 -and ($posRawGithub -lt 0 -or $posGithubApi -lt $posRawGithub)) `
    -Message "GitHub REST API chua duoc uu tien o vi tri so 1"

# ------------------------------------------------------------------------------
# 3. CO CHE CHONG GHI DE THU HEP (DESTRUCTIVE TRUNCATION PROTECTION)
# ------------------------------------------------------------------------------
$hasTruncationProtection = ($syncFuncBody -match 'Count\s*-lt\s*\$cloud' -or $licManagerContent -match 'Chong ghi de thu hep|Truncation|Count\s*-lt')

Assert-Condition -TestName "3.1: Co co che bao ve chong ghi de thu hep so luong key" `
    -Condition ($hasTruncationProtection) `
    -Message "Chua co co che ngan chan push len Cloud khi so key it hon Cloud"

# ------------------------------------------------------------------------------
# 4. KHO LICENSES_VAULT.JSON PHAI CHUA DU TOAN BO CAC KEY CHUAN (TOI THIEU 8 KEYS)
# ------------------------------------------------------------------------------
$vaultItems = @()
try {
    $parsed = ConvertFrom-Json ($vaultJsonContent.TrimStart([char]0xFEFF).Trim())
    $vaultItems = @($parsed | ForEach-Object { $_ })
} catch {}

Assert-Condition -TestName "4.1: licenses_vault.json chua toi thieu 8 keys hop le" `
    -Condition ($vaultItems.Count -ge 8) `
    -Message "Kho vault hien chi co $($vaultItems.Count) keys, can it nhat 8 keys hop nhat"

$requiredKeys = @(
    "VUONG-4P34-HE36-5B74-FHCV",
    "VUONG-LVDT-5BR8-2N5J-W6UQ",
    "VUONG-LS3W-MF5D-N42M-ANBR",
    "VUONG-LZBZ-9TVJ-NAMA-8KZM",
    "VUONG-LGAC-52WK-PPWJ-V7YN",
    "VUONG-LJ3L-GSWM-KL8S-9ZBW",
    "VUONG-LQPK-3X96-WDXR-WVUG",
    "VUONG-LCQC-R7G7-8PP8-U35V"
)

$vaultKeyList = @($vaultItems | ForEach-Object { $_.Key })
$allKeysFound = $true
foreach ($rk in $requiredKeys) {
    if ($vaultKeyList -notcontains $rk) {
        $allKeysFound = $false
        Write-Host "    -> Thieu key: $rk" -ForegroundColor Yellow
    }
}

Assert-Condition -TestName "4.2: licenses_vault.json chua day du 8 required master keys" `
    -Condition ($allKeysFound) `
    -Message "licenses_vault.json bi thieu mot so master keys"

# Kiem tra trang thai IsUsed cua key DESKTOP-8P5CKNF va VUONGTT phai luon la True
$keyDesktop = $vaultItems | Where-Object { $_.Key -eq "VUONG-LVDT-5BR8-2N5J-W6UQ" }
Assert-Condition -TestName "4.3: Key VUONG-LVDT-5BR8-2N5J-W6UQ phai bao toan IsUsed = True" `
    -Condition ($keyDesktop -and $keyDesktop.IsUsed -eq $true) `
    -Message "Key VUONG-LVDT-5BR8-2N5J-W6UQ bi mat trang thai IsUsed"

# ------------------------------------------------------------------------------
# 5. UI XU LY STATUS DONG BO CLOUD CHINH XAC (KHONG BAO THANH CONG KHI THAT BAI)
# ------------------------------------------------------------------------------
$hasSuccessCheckInUi = ($mainScriptContent -match 'if\s*\(\$res\.Success\)' -or $mainScriptContent -match '\$res\s*-and\s*\$res\.Success')

Assert-Condition -TestName "5.1: UI kiem tra `$res.Success truoc khi hien popup thong bao thanh cong" `
    -Condition ($hasSuccessCheckInUi) `
    -Message "UI van luon hien popup thanh cong du Sync-VUONGTTCloudAdminData that bai"

# ------------------------------------------------------------------------------
# 6. REALTIME BACKGROUND AUTO-SYNC TREN MOI MAY CLIENT KHI KET NOI TOOL
# ------------------------------------------------------------------------------
$hasStartupAutoSync = [bool]($mainScriptContent -match 'AddSeconds\(-900\)' -or $mainScriptContent -match 'MinValue')
Assert-Condition -TestName "6.1: VUONGTT_Toolkit.ps1 phai kich hoat dong bo ngam ngay khi khoi dong tool" `
    -Condition ($hasStartupAutoSync) `
    -Message "Tool chua khoi tao dong bo ngam ngay luc khoi dong"

$hasShortSyncInterval = [bool]($mainScriptContent -match '\$elapsed\s*-ge\s*180')
Assert-Condition -TestName "6.2: Chu ky dong bo Cloud ngam duoc toi uu xuong 180 giay (3 phut)" `
    -Condition ($hasShortSyncInterval) `
    -Message "Chu ky dong bo Cloud chua duoc toi uu xuong 180s"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "KET QUA: PASS = $testsPassed | FAIL = $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
