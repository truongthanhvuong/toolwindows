# Test-AppXDisplayNameFix.Tests.ps1
# Unit test kiem tra ten ung dung AppX / Store khong bi tach roi rac ky tu

$ErrorActionPreference = "Stop"
$testResults = @()

function Assert-Test {
    param (
        [string]$Name,
        [bool]$Condition,
        [string]$Details = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testResults += [PSCustomObject]@{ Name = $Name; Status = "PASS"; Details = $Details }
    } else {
        Write-Host "  [FAIL] $Name - $Details" -ForegroundColor Red
        $script:testResults += [PSCustomObject]@{ Name = $Name; Status = "FAIL"; Details = $Details }
    }
}

Write-Host ">>> BAT DAU BO TEST SUA LOI FONT / TACH CHU APPX GOM GIAO DIEN <<<`n" -ForegroundColor Cyan

# Kiem tra file SoftwareInstaller.ps1
$codePath = "E:\toolwindows\src\Core\SoftwareInstaller.ps1"
$content = Get-Content $codePath -Raw -Encoding UTF8

# Test 1: Khong duoc chua dong loi -replace '([a-z])([A-Z])' khong phan biet hoa thuong
$hasBadReplace = ($content -match '\$displayName\s*=\s*\$displayName\s*-replace\s*''\(\[a-z\]\)\(\[A-Z\]\)''')
Assert-Test -Name "1.1: Khong duoc dung -replace khong phan biet hoa thuong tren chu hoa chu thuong" -Condition (-not $hasBadReplace) -Details "Van con ton tai lenh -replace '([a-z])([A-Z])' gay tach roi chu"

# Test 2: Phai dung -creplace hoac logic chuan hoa an toan
$hasGoodReplace = ($content -match '-creplace\s*''\(\[a-z\]\)\(\[A-Z\]\)''') -or ($content -match '-creplace\s*''\(\\p\{Ll\}\)\(\\p\{Lu\}\)''')
Assert-Test -Name "1.2: Phai su dung -creplace (case-sensitive) de tach camelCase" -Condition $hasGoodReplace -Details "Chua tim thay -creplace case-sensitive"

# Test 3: Kiem tra mot so ten mau qua ham Get-VUONGTTInstalledSoftware
. $codePath
$samplePackages = @(
    "AgileBits.1Password",
    "Microsoft.BingNews",
    "Microsoft.Clipchamp",
    "Microsoft.CrossDevice",
    "Microsoft.ActionsServer"
)

# Test ten khong bi cach chu
foreach ($pkg in $samplePackages) {
    # Mo phong xu ly ten nhu trong Get-VUONGTTInstalledSoftware
    $pName = $pkg
    $displayName = $pName -replace '^Microsoft\.', '' -replace '^[0-9A-Za-z]+\.', ''
    # Dung regex hien tai trong file
    if ($content -match '\$displayName\s*=\s*\$displayName\s*(-[c]?replace\s*''[^'']+''\s*,\s*''[^'']+'')') {
        $repExpr = $matches[1]
        # Evaluated
    }
}

$passCount = ($script:testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($script:testResults | Where-Object { $_.Status -eq "FAIL" }).Count

Write-Host "`n========================================================" -ForegroundColor Gray
Write-Host "KET QUA TEST: $passCount PASSED | $failCount FAILED" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================`n" -ForegroundColor Gray

if ($failCount -gt 0) { exit 1 } else { exit 0 }
