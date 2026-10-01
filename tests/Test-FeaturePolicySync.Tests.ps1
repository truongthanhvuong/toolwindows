# ==============================================================================
#   TEST-DRIVEN DEVELOPMENT (TDD) TEST SUITE
#   Kiem thu dong bo 100% Bang Phan Quyen Chuc Nang (Tiers) voi cac chuc nang hien co
# ==============================================================================
param()

$ErrorActionPreference = "Continue"
$rootDir = Split-Path -Path $PSScriptRoot -Parent
if (-not $rootDir) { $rootDir = "E:\toolwindows" }

$script:testsRun = 0
$script:testsPassed = 0
$script:testsFailed = 0

function Assert-Test {
    param([string]$Name, [bool]$Condition, [string]$Details = "")
    $script:testsRun++
    if ($Condition) {
        $script:testsPassed++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
    } else {
        $script:testsFailed++
        Write-Host "  [FAIL] $Name : $Details" -ForegroundColor Red
    }
}

Write-Host "`n==============================================================================" -ForegroundColor Cyan
Write-Host ">>> KIEM THU TDD: DONG BO 100% BANG PHAN QUYEN CHUC NANG (TIERS) <<<" -ForegroundColor Yellow
Write-Host "==============================================================================" -ForegroundColor Cyan

# Danh sach 24 chuc nang chuan hoa bao phu toan bo he thong
$expectedFeatureIds = @(
    # SysInfo (4)
    "SysInfo", "Customize", "CpuMain", "Users",
    # SystemFix (4)
    "Cleaner", "Tweaks", "Config", "Troubleshoot",
    # NetworkLAN (1)
    "NetworkLAN",
    # PrinterLAN (1)
    "PrinterLAN",
    # Office (1)
    "Office",
    # SoftwareHub (4)
    "Software", "CustomApp", "Uninstaller", "Fonts",
    # HardwareDisk (4)
    "DiskHealth", "Benchmark", "Partition", "LaptopCheck",
    # AutoWin (1)
    "AutoWin",
    # TechUtilities (4)
    "BackupDriver", "BackupSystem", "BitLocker", "Activation"
)

# --- PHAN 1: Kiem tra feature_policy.json ---
Write-Host "`n--- PHAN 1: Kiem tra file cau hinh feature_policy.json ---" -ForegroundColor Cyan
$policyPath = Join-Path $rootDir "src\Config\feature_policy.json"
Assert-Test "feature_policy.json ton tai" (Test-Path $policyPath)

$policyJson = Get-Content -Path $policyPath -Raw -Encoding UTF8 | ConvertFrom-Json
Assert-Test "feature_policy.json chua du 24 chuc nang (Hien tai: $($policyJson.Count))" ($policyJson.Count -ge 24)

foreach ($fid in $expectedFeatureIds) {
    $found = $policyJson | Where-Object { $_.Id -eq $fid }
    Assert-Test "feature_policy.json chua chuc nang '$fid'" ($null -ne $found) "Thieu feature Id='$fid'"
}

# --- PHAN 2: Kiem tra Get-VUONGTTDefaultFeatures trong LicenseManager.ps1 ---
Write-Host "`n--- PHAN 2: Kiem tra LicenseManager.ps1 ---" -ForegroundColor Cyan
. (Join-Path $rootDir "src\Core\LicenseManager.ps1")

$defaultFeatures = Get-VUONGTTDefaultFeatures
Assert-Test "Get-VUONGTTDefaultFeatures tra ve du 24 chuc nang (Thuc te: $($defaultFeatures.Count))" ($defaultFeatures.Count -ge 24)

foreach ($fid in $expectedFeatureIds) {
    $found = $defaultFeatures | Where-Object { $_.Id -eq $fid }
    Assert-Test "Get-VUONGTTDefaultFeatures chua '$fid'" ($null -ne $found) "Thieu '$fid' trong default features"
}

# Test Smart Merge: Get-VUONGTTFeaturePolicies phai tu dong bo sung chuc nang moi vao policy file
$loadedPolicies = Get-VUONGTTFeaturePolicies
Assert-Test "Get-VUONGTTFeaturePolicies tra ve du >= 24 chuc nang sau khi nap" ($loadedPolicies.Count -ge 24)

# --- PHAN 3: Kiem tra Gatekeeper Access Control trong VUONGTT_Toolkit.ps1 ---
Write-Host "`n--- PHAN 3: Kiem tra Gatekeeper Access Control trong VUONGTT_Toolkit.ps1 ---" -ForegroundColor Cyan
$toolkitPath = Join-Path $rootDir "VUONGTT_Toolkit.ps1"
$toolkitCode = [System.IO.File]::ReadAllText($toolkitPath, [System.Text.Encoding]::UTF8)

Assert-Test "VUONGTT_Toolkit.ps1 dinh nghia ham Test-VUONGTTGatekeeperAccess" ($toolkitCode -match 'function\s+Test-VUONGTTGatekeeperAccess')
Assert-Test "Switch-Tab goi kiem tra Gatekeeper" ($toolkitCode -match 'Test-VUONGTTGatekeeperAccess\s+-FeatureId\s+\$TargetTag')
Assert-Test "Switch-SystemFixSubTab goi kiem tra Gatekeeper" ($toolkitCode -match 'Switch-SystemFixSubTab[\s\S]*?Test-VUONGTTGatekeeperAccess')
Assert-Test "Switch-SoftwareHubSubTab goi kiem tra Gatekeeper" ($toolkitCode -match 'Switch-SoftwareHubSubTab[\s\S]*?Test-VUONGTTGatekeeperAccess')
Assert-Test "Switch-HardwareDiskSubTab goi kiem tra Gatekeeper" ($toolkitCode -match 'Switch-HardwareDiskSubTab[\s\S]*?Test-VUONGTTGatekeeperAccess')
Assert-Test "Switch-SysInfoSubTab goi kiem tra Gatekeeper" ($toolkitCode -match 'Switch-SysInfoSubTab[\s\S]*?Test-VUONGTTGatekeeperAccess')
Assert-Test "Switch-TechUtilitiesSubTab goi kiem tra Gatekeeper" ($toolkitCode -match 'Switch-TechUtilitiesSubTab[\s\S]*?Test-VUONGTTGatekeeperAccess')

# --- TONG KET ---
Write-Host "`n==============================================================================" -ForegroundColor Cyan
Write-Host ">>> KET QUA KIEM THU: $script:testsPassed/$script:testsRun PASSED ($script:testsFailed FAILED) <<<" -ForegroundColor $(if ($script:testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "==============================================================================" -ForegroundColor Cyan

if ($script:testsFailed -gt 0) { exit 1 } else { exit 0 }
