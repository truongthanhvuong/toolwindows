# =========================================================================
#   TEST-DRIVEN DEVELOPMENT (TDD) TEST SUITE: UAC ELEVATION SAFETY
#   Kiem tra tinh an toan va co che nang quyen Administrator
# =========================================================================
param()

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Assert-Equal($actual, $expected, $testName) {
    $script:TotalTests++
    if ($actual -eq $expected) {
        $script:PassedTests++
        Write-Host "  [PASS] $testName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  [FAIL] $testName" -ForegroundColor Red
        Write-Host "         Mong doi: '$expected' | Thuc te: '$actual'" -ForegroundColor Yellow
    }
}

Write-Host ">>> BAT DAU CHAY BO TEST UAC ELEVATION SAFETY <<<" -ForegroundColor Cyan

$vPs1 = Join-Path (Split-Path -Parent $PSScriptRoot) "vuongtt.ps1"
$wPs1 = Join-Path (Split-Path -Parent $PSScriptRoot) "win.ps1"

$vContent = if (Test-Path $vPs1) { [System.IO.File]::ReadAllText($vPs1) } else { "" }
$wContent = if (Test-Path $wPs1) { [System.IO.File]::ReadAllText($wPs1) } else { "" }

# 1. Kiem tra vuongtt.ps1 su dung -EncodedCommand cho UAC Elevation
$hasVEncodedCommand = ($vContent -match '-EncodedCommand')
Assert-Equal $hasVEncodedCommand $true "1.1: vuongtt.ps1 su dung -EncodedCommand (Base64) de chong loi cu phap command line"

# 2. Kiem tra win.ps1 su dung -EncodedCommand cho UAC Elevation
$hasWEncodedCommand = ($wContent -match '-EncodedCommand')
Assert-Equal $hasWEncodedCommand $true "1.2: win.ps1 su dung -EncodedCommand (Base64) de chong loi cu phap command line"

# 3. Kiem tra vuongtt.ps1 dong ngay cua so cu bang Stop-Process sau khi Start-Process elevated thanh cong
$hasVCloseParent = ($vContent -match 'Start-Process[\s\S]{1,300}?-Verb\s+RunAs[\s\S]{1,300}?Stop-Process\s+-Id\s+\$PID')
Assert-Equal $hasVCloseParent $true "1.3: vuongtt.ps1 dong ngay cua so cu bang Stop-Process khi elevate thanh cong"

# 4. Kiem tra win.ps1 dong ngay cua so cu bang Stop-Process sau khi Start-Process elevated thanh cong
$hasWCloseParent = ($wContent -match 'Start-Process[\s\S]{1,300}?-Verb\s+RunAs[\s\S]{1,300}?Stop-Process\s+-Id\s+\$PID')
Assert-Equal $hasWCloseParent $true "1.4: win.ps1 dong ngay cua so cu bang Stop-Process khi elevate thanh cong"

# 5. Kiem tra khoi catch phan biet ro loi thuc te ($_ .Exception.Message) thay vi chi bao tu choi quyen
$hasVDetailedError = ($vContent -match '\$_\.Exception\.Message' -and ($vContent -match 'NativeErrorCode' -or $vContent -match '1223' -or $vContent -match 'canceled'))
Assert-Equal $hasVDetailedError $true "1.5: vuongtt.ps1 in chi tiet loi exception thuc te khi khong elevate duoc"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $script:PassedTests / $script:TotalTests bai test dat." -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    Exit 1
} else {
    Exit 0
}
