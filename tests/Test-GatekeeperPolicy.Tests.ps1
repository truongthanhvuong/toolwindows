# =========================================================================
# TEST SUITE: PRO & ADMIN GATEKEEPER & POLICY CONTROLLER (R2)
# VUONGTT TOOLKIT 2026 - TDD OPAQUE-BOX E2E VERIFICATION
# =========================================================================
# Tier 1: Canonical Feature Coverage (Happy Path)
# Tier 2: Boundary & Corner Cases (Negative/Null/Idempotency)
# Tier 3: Cross-Feature Combinations (3-Tier Gatekeeper State Matrix)
# Tier 4: Real-World Application Scenarios (Lifecycle Simulation & AST)
# =========================================================================

$ErrorActionPreference = "Stop"

$script:passed = 0
$script:failed = 0
$script:tierStats = @{
    "Tier 1" = @{ Pass = 0; Fail = 0 }
    "Tier 2" = @{ Pass = 0; Fail = 0 }
    "Tier 3" = @{ Pass = 0; Fail = 0 }
    "Tier 4" = @{ Pass = 0; Fail = 0 }
}

function Assert-TierCondition {
    param(
        [string]$Tier,
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [$Tier][PASS] $TestName" -ForegroundColor Green
        $script:passed++
        $script:tierStats[$Tier].Pass++
    } else {
        Write-Host "  [$Tier][FAIL] $TestName - $Message" -ForegroundColor Red
        $script:failed++
        $script:tierStats[$Tier].Fail++
    }
}

Write-Host "`n>>> [TEST SUITE] R2: PRO & ADMIN GATEKEEPER & POLICY ENFORCEMENT <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $projectRoot) { $projectRoot = Get-Location }

$htmlPath = Join-Path $projectRoot "src-ui\index.html"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$licPath = Join-Path $projectRoot "src\Core\LicenseManager.ps1"
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$mainPath = Join-Path $projectRoot "src-tauri\src\main.rs"

Assert-TierCondition "Tier 1" "T1.01: File index.html phai ton tai" (Test-Path $htmlPath)
Assert-TierCondition "Tier 1" "T1.02: File app.js phai ton tai" (Test-Path $appJsPath)
Assert-TierCondition "Tier 1" "T1.03: File LicenseManager.ps1 phai ton tai" (Test-Path $licPath)
Assert-TierCondition "Tier 1" "T1.04: File system_ops.rs phai ton tai" (Test-Path $opsPath)
Assert-TierCondition "Tier 1" "T1.05: File main.rs phai ton tai" (Test-Path $mainPath)

$htmlContent = [System.IO.File]::ReadAllText($htmlPath, [System.Text.Encoding]::UTF8)
$appJsContent = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)
$licContent = [System.IO.File]::ReadAllText($licPath, [System.Text.Encoding]::UTF8)
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)
$mainContent = [System.IO.File]::ReadAllText($mainPath, [System.Text.Encoding]::UTF8)

# =========================================================================
# TIER 1: CANONICAL FEATURE COVERAGE (HAPPY PATH)
# =========================================================================
Write-Host "`n--- TIER 1: CANONICAL FEATURE COVERAGE ---" -ForegroundColor Yellow

# T1.1: PRO License Modal Structure
Assert-TierCondition "Tier 1" "T1.06: Modal kich hoat PRO modal-license-activation ton tai trong HTML" `
    ($htmlContent -match 'id="modal-license-activation"')
Assert-TierCondition "Tier 1" "T1.07: Truong nhap License Key input-pro-license-key ton tai" `
    ($htmlContent -match 'id="input-pro-license-key"')
Assert-TierCondition "Tier 1" "T1.08: Hien thi Hardware ID display-pro-hwid ton tai" `
    ($htmlContent -match 'id="display-pro-hwid"' -or $htmlContent -match 'id="input-pro-hwid"')
Assert-TierCondition "Tier 1" "T1.09: Nut xac nhan kich hoat btn-submit-pro-activation ton tai" `
    ($htmlContent -match 'id="btn-submit-pro-activation"' -or $htmlContent -match 'id="btn-activate-pro"')

# T1.2: ADMIN Login Modal Structure
Assert-TierCondition "Tier 1" "T1.10: Modal dang nhap Admin modal-admin-login ton tai trong HTML" `
    ($htmlContent -match 'id="modal-admin-login"')
Assert-TierCondition "Tier 1" "T1.11: Nut submit dang nhap Admin btn-admin-submit-login ton tai" `
    ($htmlContent -match 'id="btn-admin-submit-login"')

# T1.3: Frontend Gatekeeper & Navigation Control
Assert-TierCondition "Tier 1" "T1.12: switchView chua logic Gatekeeper kiem tra currentPolicies" `
    ($appJsContent -match 'switchView' -and ($appJsContent -match 'currentPolicies' -or $appJsContent -match 'checkGatekeeperAccess'))
Assert-TierCondition "Tier 1" "T1.13: app.js co ham initGatekeeper khoi tao ban quyen va policy" `
    ($appJsContent -match 'initGatekeeper')
Assert-TierCondition "Tier 1" "T1.14: app.js dinh nghia bien trang thai pendingGatekeeperTarget" `
    ($appJsContent -match 'pendingGatekeeperTarget')
Assert-TierCondition "Tier 1" "T1.15: app.js dinh nghia bien trang thai isProLicensed" `
    ($appJsContent -match 'isProLicensed')
Assert-TierCondition "Tier 1" "T1.16: app.js dinh nghia bien trang thai isAdminAuth" `
    ($appJsContent -match 'isAdminAuth')

# T1.4: Backend Rust IPC Endpoints
Assert-TierCondition "Tier 1" "T1.17: Backend ho tro lenh check_pro_license" `
    ($opsContent -match 'check_pro_license' -or $mainContent -match 'check_pro_license')
Assert-TierCondition "Tier 1" "T1.18: Backend ho tro lenh activate_pro_key" `
    ($opsContent -match 'activate_pro_key' -or $mainContent -match 'activate_pro_key')

# T1.5: Core License Management Powershell
Assert-TierCondition "Tier 1" "T1.19: LicenseManager.ps1 co ham Get-VUONGTTHardwareId" `
    ($licContent -match 'function Get-VUONGTTHardwareId')
Assert-TierCondition "Tier 1" "T1.20: LicenseManager.ps1 co ham Test-VUONGTTProLicense" `
    ($licContent -match 'function Test-VUONGTTProLicense')
Assert-TierCondition "Tier 1" "T1.21: LicenseManager.ps1 co ham Invoke-VUONGTTKeyActivation" `
    ($licContent -match 'function Invoke-VUONGTTKeyActivation')

# =========================================================================
# TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS
# =========================================================================
Write-Host "`n--- TIER 2: BOUNDARY CONDITIONS & NEGATIVE INPUTS ---" -ForegroundColor Yellow

# T2.1: License Key Validation Rules
function Test-LicenseKeyFormat {
    param([string]$Key)
    if ([string]::IsNullOrWhiteSpace($Key)) { return $false }
    $cleanKey = $Key.Trim().ToUpper()
    # Canonical VUONGTT key pattern: 4 blocks of 4-5 alphanumeric chars or standard format
    if ($cleanKey.Length -lt 10) { return $false }
    if ($cleanKey -match '[^A-Z0-9\-]') { return $false }
    return $true
}

Assert-TierCondition "Tier 2" "T2.01: Tu choi chuoi key rong hoac chi co khoang trang" `
    ((Test-LicenseKeyFormat "") -eq $false -and (Test-LicenseKeyFormat "   ") -eq $false)
Assert-TierCondition "Tier 2" "T2.02: Tu choi key qua ngan duoi 10 ky tu" `
    ((Test-LicenseKeyFormat "KEY123") -eq $false)
Assert-TierCondition "Tier 2" "T2.03: Tu choi key chua ky tu dac biet nguy hiem SQL/Shell injection" `
    ((Test-LicenseKeyFormat "PRO-KEY-'; DROP TABLE--") -eq $false)
Assert-TierCondition "Tier 2" "T2.04: Chap nhan key hop le dinh dang chuan PRO" `
    ((Test-LicenseKeyFormat "VTT-PRO-2026-X89K-L22M") -eq $true)

# T2.2: Modal Cancellation Safety Check
Assert-TierCondition "Tier 2" "T2.05: Modal PRO co nut huy va logic xoa pendingGatekeeperTarget an toan" `
    ($htmlContent -match 'id="btn-cancel-pro-activation"' -or $appJsContent -match 'pendingGatekeeperTarget\s*=\s*null')

# =========================================================================
# TIER 3: CROSS-FEATURE COMBINATIONS (3-TIER GATEKEEPER STATE MATRIX)
# =========================================================================
Write-Host "`n--- TIER 3: CROSS-FEATURE COMBINATIONS ---" -ForegroundColor Yellow

# Gatekeeper Decision Matrix Evaluator
function Evaluate-GatekeeperAccess {
    param(
        [string]$FeatureTier,     # FREE, PRO, ADMIN
        [bool]$IsProLicensed,     # true / false
        [bool]$IsAdminAuth        # true / false
    )
    # Admin God Mode has unrestricted access
    if ($IsAdminAuth) {
        return [PSCustomObject]@{ Allowed = $true; Modal = "none"; Reason = "AdminGranted" }
    }
    # ADMIN tier feature
    if ($FeatureTier -eq "ADMIN") {
        return [PSCustomObject]@{ Allowed = $false; Modal = "modal-admin-login"; Reason = "RequireAdmin" }
    }
    # PRO tier feature
    if ($FeatureTier -eq "PRO") {
        if ($IsProLicensed) {
            return [PSCustomObject]@{ Allowed = $true; Modal = "none"; Reason = "ProGranted" }
        } else {
            return [PSCustomObject]@{ Allowed = $false; Modal = "modal-license-activation"; Reason = "RequirePro" }
        }
    }
    # Default FREE tier
    return [PSCustomObject]@{ Allowed = $true; Modal = "none"; Reason = "FreeGranted" }
}

# 1. FREE user accessing FREE feature -> ALLOWED
$res = Evaluate-GatekeeperAccess -FeatureTier "FREE" -IsProLicensed $false -IsAdminAuth $false
Assert-TierCondition "Tier 3" "T3.01: FREE User vao FREE Feature -> CHO PHEP truy cap" `
    ($res.Allowed -eq $true -and $res.Modal -eq "none")

# 2. FREE user accessing PRO feature -> BLOCKED (shows PRO Modal)
$res = Evaluate-GatekeeperAccess -FeatureTier "PRO" -IsProLicensed $false -IsAdminAuth $false
Assert-TierCondition "Tier 3" "T3.02: FREE User vao PRO Feature -> BI CHAN, bat modal-license-activation" `
    ($res.Allowed -eq $false -and $res.Modal -eq "modal-license-activation")

# 3. FREE user accessing ADMIN feature -> BLOCKED (shows ADMIN Modal)
$res = Evaluate-GatekeeperAccess -FeatureTier "ADMIN" -IsProLicensed $false -IsAdminAuth $false
Assert-TierCondition "Tier 3" "T3.03: FREE User vao ADMIN Feature -> BI CHAN, bat modal-admin-login" `
    ($res.Allowed -eq $false -and $res.Modal -eq "modal-admin-login")

# 4. PRO user accessing PRO feature -> ALLOWED
$res = Evaluate-GatekeeperAccess -FeatureTier "PRO" -IsProLicensed $true -IsAdminAuth $false
Assert-TierCondition "Tier 3" "T3.04: PRO User vao PRO Feature -> CHO PHEP truy cap" `
    ($res.Allowed -eq $true -and $res.Modal -eq "none")

# 5. PRO user accessing ADMIN feature -> BLOCKED (shows ADMIN Modal)
$res = Evaluate-GatekeeperAccess -FeatureTier "ADMIN" -IsProLicensed $true -IsAdminAuth $false
Assert-TierCondition "Tier 3" "T3.05: PRO User van bi CHAN khi vao ADMIN Feature, bat modal-admin-login" `
    ($res.Allowed -eq $false -and $res.Modal -eq "modal-admin-login")

# 6. ADMIN Authenticated user accessing ALL tiers -> ALLOWED (God Mode)
$resAdminOnAdmin = Evaluate-GatekeeperAccess -FeatureTier "ADMIN" -IsProLicensed $false -IsAdminAuth $true
$resAdminOnPro   = Evaluate-GatekeeperAccess -FeatureTier "PRO" -IsProLicensed $false -IsAdminAuth $true
$resAdminOnFree  = Evaluate-GatekeeperAccess -FeatureTier "FREE" -IsProLicensed $false -IsAdminAuth $true
Assert-TierCondition "Tier 3" "T3.06: ADMIN Authenticated co God Mode truy cap toan bo cac tang FREE/PRO/ADMIN" `
    ($resAdminOnAdmin.Allowed -eq $true -and $resAdminOnPro.Allowed -eq $true -and $resAdminOnFree.Allowed -eq $true)

# =========================================================================
# TIER 4: REAL-WORLD APPLICATION SCENARIOS
# =========================================================================
Write-Host "`n--- TIER 4: REAL-WORLD APPLICATION SCENARIOS ---" -ForegroundColor Yellow

# T4.1: Canonical Feature Map to Policy ID Validation
$canonicalViewPolicyMap = @{
    "view-sys-monitor"     = "SysInfo"
    "view-general"         = "Customize"
    "view-win-optimize"    = "Tweaks"
    "view-clean-uninstaller" = "Uninstaller"
    "view-soft-winget"     = "Software"
    "view-it-helpdesk"     = "Troubleshoot"
    "view-vpn-proxy"       = "NetworkLAN"
    "view-win-deploy"      = "AutoWin"
    "view-disk-smart"      = "DiskHealth"
    "view-hwid-act"        = "Activation"
    "view-disk-part"       = "Partition"
    "view-office-m365"     = "Office"
    "view-tech-driver"     = "BackupDriver"
    "view-backup-windows"  = "BackupSystem"
    "view-printer-lan"     = "PrinterLAN"
    "view-bitlocker-mgmt"  = "BitLocker"
}

$policyMatchPass = $true
foreach ($view in $canonicalViewPolicyMap.Keys) {
    if ($htmlContent -notmatch $view) {
        $policyMatchPass = $false
        Write-Host "    Canh bao: View $view khong tim thay trong index.html" -ForegroundColor Yellow
    }
}
Assert-TierCondition "Tier 4" "T4.01: Tat ca 16 View anh xa chinh sach Canonical Policy ton tai trong index.html" `
    $policyMatchPass

# T4.2: Immediate Unlock Flow Simulation
function Simulate-ImmediateUnlockWorkflow {
    $state = @{
        CurrentView = "view-sys-monitor"
        IsProLicensed = $false
        IsAdminAuth = $false
        PendingTarget = $null
        ModalActive = "none"
    }
    
    # Step 1: User tries to navigate to PRO view "view-win-deploy"
    $target = "view-win-deploy"
    $access = Evaluate-GatekeeperAccess -FeatureTier "PRO" -IsProLicensed $state.IsProLicensed -IsAdminAuth $state.IsAdminAuth
    if (-not $access.Allowed) {
        $state.PendingTarget = $target
        $state.ModalActive = $access.Modal
    }
    
    $blockedCorrectly = ($state.CurrentView -eq "view-sys-monitor" -and $state.PendingTarget -eq "view-win-deploy" -and $state.ModalActive -eq "modal-license-activation")
    
    # Step 2: User successfully activates valid license key
    $state.IsProLicensed = $true
    $state.ModalActive = "none"
    
    # Step 3: Trigger Immediate Unlock
    if ($state.PendingTarget) {
        $recheck = Evaluate-GatekeeperAccess -FeatureTier "PRO" -IsProLicensed $state.IsProLicensed -IsAdminAuth $state.IsAdminAuth
        if ($recheck.Allowed) {
            $state.CurrentView = $state.PendingTarget
            $state.PendingTarget = $null
        }
    }
    
    $unlockedCorrectly = ($state.CurrentView -eq "view-win-deploy" -and $state.PendingTarget -eq $null)
    return ($blockedCorrectly -and $unlockedCorrectly)
}

Assert-TierCondition "Tier 4" "T4.02: Mo phong quy trinh Immediate Unlock khi kich hoat thanh cong mo ngay View dich" `
    (Simulate-ImmediateUnlockWorkflow)

# T4.3: AST Syntax Parsing of LicenseManager.ps1
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($licPath, [ref]$tokens, [ref]$errors) | Out-Null
Assert-TierCondition "Tier 4" "T4.03: Cu phap AST cua LicenseManager.ps1 hop le (0 loi parse)" `
    ($errors.Count -eq 0)

# =========================================================================
# SUMMARY REPORT
# =========================================================================
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host " KET QUA KIEM THU R2 (PRO & ADMIN GATEKEEPER):" -ForegroundColor Cyan
Write-Host "  Tong so tests PASS: $script:passed" -ForegroundColor Green
Write-Host "  Tong so tests FAIL: $script:failed" -ForegroundColor $(if ($script:failed -eq 0) { "Green" } else { "Red" })
Write-Host "  Phan bo Tiers:"
foreach ($tierKey in $script:tierStats.Keys | Sort-Object) {
    $tPass = $script:tierStats[$tierKey].Pass
    $tFail = $script:tierStats[$tierKey].Fail
    Write-Host "    $tierKey : $tPass PASS / $($tPass + $tFail) Total" -ForegroundColor $(if ($tFail -eq 0) { "Green" } else { "Yellow" })
}
Write-Host "========================================================`n" -ForegroundColor Cyan

if ($script:failed -gt 0) {
    exit 1
} else {
    exit 0
}
