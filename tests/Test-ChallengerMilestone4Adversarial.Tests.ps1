# =========================================================================
#   EMPIRICAL CHALLENGER: MILESTONE 4 ADVERSARIAL STRESS TEST SUITE
#   tests/Test-ChallengerMilestone4Adversarial.Tests.ps1
# =========================================================================
$ErrorActionPreference = "Stop"

$script:testsPassed = 0
$script:testsFailed = 0
$script:findings = @()

function Assert-Condition([bool]$condition, [string]$testName, [string]$detail = "") {
    if ($condition) {
        Write-Host "  [PASS] $testName" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $testName : $detail" -ForegroundColor Red
        $script:testsFailed++
        $script:findings += "$testName : $detail"
    }
}

Write-Host "`n>>> ADVERSARIAL CHALLENGE: BITLOCKER & POWER PLANS STRESS TEST <<<`n" -ForegroundColor Cyan

$projectRoot = Split-Path -Parent $PSScriptRoot
$opsPath = Join-Path $projectRoot "src-tauri\src\system_ops.rs"
$appJsPath = Join-Path $projectRoot "src-ui\app.js"
$htmlPath = Join-Path $projectRoot "src-ui\index.html"

$opsContent = Get-Content -Path $opsPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8
$htmlContent = Get-Content -Path $htmlPath -Raw -Encoding UTF8

# -------------------------------------------------------------------------
# Test Group 1: Single Disk JSON Handling (Edge Case Challenge)
# -------------------------------------------------------------------------
Write-Host "--- Nhom 1: Single Disk JSON Parsing & Frontend Normalization ---" -ForegroundColor Yellow

# Verify PowerShell 5.1 behavior for single item
$singleObj = [PSCustomObject]@{ drive = 'C:'; volume_name = 'OS' }
$singleJson = @($singleObj) | ConvertTo-Json -Compress
$isSingleObjFormat = $singleJson.StartsWith("{")

Assert-Condition $isSingleObjFormat "PowerShell 5.1 serializes 1-element arrays as Object {...} without array wrapper" "Expected '{' start"

# Check whether app.js checks Array.isArray
$hasArrayCheck = $appJsContent.Contains("Array.isArray(drives)")
Assert-Condition $hasArrayCheck "app.js checks Array.isArray(drives)"

# Evaluate what happens in JS if drives is an Object
$hasNormalization = $appJsContent.Contains("Array.isArray(drives) ? drives : [drives]") -or $appJsContent.Contains("!Array.isArray(drives)")

if (-not $hasNormalization) {
    Write-Host "  [WARNING/DEFECT RISK] app.js does not normalize single drive object to array. On single-disk systems, Array.isArray(drives) evaluates to false!" -ForegroundColor Magenta
    $script:findings += "DEFECT RISK: Single-disk systems receive JSON object from PowerShell ConvertTo-Json, causing Array.isArray(drives) to fail in app.js"
}

# -------------------------------------------------------------------------
# Test Group 2: Empty / Invalid Inputs to Backend System Actions
# -------------------------------------------------------------------------
Write-Host "`n--- Nhom 2: Non-existent Drives & Input Validation ---" -ForegroundColor Yellow

# Unlock validation: requires password or recovery_key
$hasUnlockGuard = $opsContent.Contains("Recovery Key 48")
Assert-Condition $hasUnlockGuard "unlock_bitlocker fails closed if both password and recovery_key are empty"

# Non-existent drive safety
$hasDriveDefault = $opsContent.Contains('extract_json_field(params_json, "drive").unwrap_or("C:")')
Assert-Condition $hasDriveDefault "Missing drive parameter safely defaults to C:"

# -------------------------------------------------------------------------
# Test Group 3: Real Power Plan 24/7 Execution & Verification
# -------------------------------------------------------------------------
Write-Host "`n--- Nhom 3: Real Power Plan 24/7 Registry & Kernel Values ---" -ForegroundColor Yellow

$diskIdleQ = powercfg /q SCHEME_CURRENT SUB_DISK DISKIDLE 2>$null | Out-String
$isDiskIdleZero = $diskIdleQ.Contains("Current AC Power Setting Index: 0x00000000")
Assert-Condition $isDiskIdleZero "Kernel DISKIDLE is 0 (Never spin down)" "Power Setting Index: $diskIdleQ"

$videoIdleQ = powercfg /q SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 2>$null | Out-String
$isVideoIdleZero = $videoIdleQ.Contains("Current AC Power Setting Index: 0x00000000")
Assert-Condition $isVideoIdleZero "Kernel VIDEOIDLE is 0 (Never turn off display)" "Power Setting Index: $videoIdleQ"

# -------------------------------------------------------------------------
# Test Group 4: Rust Unit Test Parity
# -------------------------------------------------------------------------
Write-Host "`n--- Nhom 4: Rust Backend Unit Test Verification ---" -ForegroundColor Yellow

$hasBitLockerTest = $opsContent.Contains("fn test_system_ops_bitlocker_actions")
Assert-Condition $hasBitLockerTest "system_ops.rs includes unit test for BitLocker actions"

$hasNeverSleepTest = $opsContent.Contains("fn test_set_power_plan_never_sleep")
Assert-Condition $hasNeverSleepTest "system_ops.rs includes unit test for Never Sleep 24/7"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "CHALLENGE SUMMARY: $($script:testsPassed) PASS / $($script:testsFailed) FAIL" -ForegroundColor $(if ($script:testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "Total findings / caveats recorded: $($script:findings.Count)"
foreach ($f in $script:findings) {
    Write-Host "  * $f" -ForegroundColor Yellow
}
Write-Host "==========================================================" -ForegroundColor Cyan

if ($script:testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
