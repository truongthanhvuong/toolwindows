# =========================================================================
#   TEST-DRIVEN DEVELOPMENT (TDD) TEST SUITE: CONSOLE AUTO EXIT
#   Kiem tra logic phat hien tool dong va tu dong thoat cua so console
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

Write-Host ">>> BAT DAU CHAY BO TEST TU DONG DONG CUA SO CONSOLE KHI TAT TOOL <<<" -ForegroundColor Cyan

# Kiem tra file vuongtt.ps1 va win.ps1
$vPs1 = Join-Path (Split-Path -Parent $PSScriptRoot) "vuongtt.ps1"
$wPs1 = Join-Path (Split-Path -Parent $PSScriptRoot) "win.ps1"
$mainPs1 = Join-Path (Split-Path -Parent $PSScriptRoot) "VUONGTT_Toolkit.ps1"

$vContent = if (Test-Path $vPs1) { [System.IO.File]::ReadAllText($vPs1) } else { "" }
$wContent = if (Test-Path $wPs1) { [System.IO.File]::ReadAllText($wPs1) } else { "" }
$mContent = if (Test-Path $mainPs1) { [System.IO.File]::ReadAllText($mainPs1) } else { "" }

# 1. Kiem tra co lenh tu dong dong cua so console trong vuongtt.ps1
$hasVConsoleExit = ($vContent -match 'Stop-Process\s+-Id\s+\$PID' -or $vContent -match '\[System\.Environment\]::Exit\(0\)')
Assert-Equal $hasVConsoleExit $true "1.1: vuongtt.ps1 co lenh tu dong dong cua so console sau khi tool tat"

# 2. Kiem tra co co che vo hieu hoa QuickEdit Mode tranh freeze trong vuongtt.ps1
$hasVDisableQuickEdit = ($vContent -match 'SetConsoleMode' -or $vContent -match '0x0040' -or $vContent -match 'QuickEdit')
Assert-Equal $hasVDisableQuickEdit $true "1.2: vuongtt.ps1 co co che chong freeze click chuot QuickEdit"

# 3. Kiem tra co lenh tu dong dong cua so console trong win.ps1
$hasWConsoleExit = ($wContent -match 'Stop-Process\s+-Id\s+\$PID' -or $wContent -match '\[System\.Environment\]::Exit\(0\)')
Assert-Equal $hasWConsoleExit $true "1.3: win.ps1 co lenh tu dong dong cua so console sau khi tool tat"

# 4. Kiem tra co co che vo hieu hoa QuickEdit Mode trong win.ps1
$hasWDisableQuickEdit = ($wContent -match 'SetConsoleMode' -or $wContent -match '0x0040' -or $wContent -match 'QuickEdit')
Assert-Equal $hasWDisableQuickEdit $true "1.4: win.ps1 co co che chong freeze click chuot QuickEdit"

# 5. Kiem tra VUONGTT_Toolkit.ps1 co lenh thoat dut khoat sau khi dong cua so
$hasShowDialogExit = ($mContent -match '(\$window\.ShowDialog\(\)|\$window\.Show\(\)[\s\S]*?Dispatcher\]::Run\(\))[\s\S]*?\[System\.Environment\]::Exit\(0\)')
Assert-Equal $hasShowDialogExit $true "1.5: VUONGTT_Toolkit.ps1 co lenh Exit(0) dut khoat sau khi dong cua so giao dien"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $script:PassedTests / $script:TotalTests bai test dat." -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    Exit 1
} else {
    Exit 0
}
