# Test-SplashScreenText.Tests.ps1
# Unit Test kiem tra noi dung chu hien thi tren man hinh Splash Screen

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

Write-Host ">>> BAT DAU CHAY BO TEST NOI DUNG SPLASH SCREEN <<<`n" -ForegroundColor Cyan

# Kiem tra 1: File src/Program.cs ton tai
$programCsPath = "E:\toolwindows\src\Program.cs"
Assert-Test -Name "1.1: File src/Program.cs phai ton tai" -Condition (Test-Path $programCsPath)

$programCsContent = Get-Content $programCsPath -Raw -Encoding UTF8

# Kiem tra 2: Noi dung text tren splash screen khong duoc chua chu 'sieu toc'
$hasSieuTocInSplash = ($programCsContent -match 'lblSub\.Text\s*=\s*"[^"]*si.*?t.*?c[^"]*"')
Assert-Test -Name "2.1: Splash screen khong chua chu 'sieu toc'" -Condition (-not $hasSieuTocInSplash) -Details "Phat hien van con chu sieu toc trong lblSub.Text"

# Kiem tra 3: Noi dung text tren splash phai la 'Dang khoi dong VUONGTT TOOL... Vui long cho!'
$targetText = "VUONGTT TOOL"
$hasNewText = ($programCsContent -match 'lblSub\.Text\s*=\s*"[^"]*VUONGTT TOOL[^"]*"')
Assert-Test -Name "3.1: Splash screen phai chua 'VUONGTT TOOL'" -Condition $hasNewText -Details "Chua tim thay dong chu VUONGTT TOOL trong lblSub.Text"

$passCount = ($script:testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($script:testResults | Where-Object { $_.Status -eq "FAIL" }).Count

Write-Host "`n========================================================" -ForegroundColor Gray
Write-Host "KET QUA TEST: $passCount PASSED | $failCount FAILED" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================`n" -ForegroundColor Gray

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
