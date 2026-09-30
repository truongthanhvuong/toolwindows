$xamlPath = "E:\toolwindows\src\UI\MainWindow.xaml"
$scriptPath = "E:\toolwindows\VUONGTT_Toolkit.ps1"
$testsRun = 0
$testsPassed = 0
$testsFailed = 0

function Assert-Condition {
    param([string]$TestName, [bool]$Condition, [string]$FailureMessage = "")
    $script:testsRun++
    if ($Condition) {
        $script:testsPassed++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        $script:testsFailed++
        Write-Host "  [FAIL] $TestName - $FailureMessage" -ForegroundColor Red
    }
}

Write-Host "--- TDD Kiem thu dieu huong AutoWin ra Sidebar & Quick Actions ---" -ForegroundColor Cyan

$xamlContent = [System.IO.File]::ReadAllText($xamlPath)
Assert-Condition "XAML chua btnMenuAutoWin voi Tag='AutoWin'" ($xamlContent -match 'x:Name="btnMenuAutoWin"[^>]*Tag="AutoWin"' -or $xamlContent -match 'Tag="AutoWin"[^>]*x:Name="btnMenuAutoWin"') "Thieu btnMenuAutoWin trong XAML"
Assert-Condition "XAML chua btnQuickAutoWin trong Quick Actions" ($xamlContent -match 'x:Name="btnQuickAutoWin"') "Thieu btnQuickAutoWin trong XAML"

$scriptContent = [System.IO.File]::ReadAllText($scriptPath)
Assert-Condition "VUONGTT_Toolkit.ps1 khai bao btnMenuAutoWin trong `$menuButtons" ($scriptContent -match '\$menuButtons\s*=\s*@\([^)]*"btnMenuAutoWin"') "Thieu btnMenuAutoWin trong `$menuButtons"
Assert-Condition "VUONGTT_Toolkit.ps1 gan Get-Control cho `$btnMenuAutoWin va `$btnQuickAutoWin" (($scriptContent -match '\$btnMenuAutoWin\s*=\s*Get-Control') -and ($scriptContent -match '\$btnQuickAutoWin\s*=\s*Get-Control')) "Thieu Get-Control"
Assert-Condition "VUONGTT_Toolkit.ps1 gan Add_Click cho `$btnQuickAutoWin" ($scriptContent -match '\$btnQuickAutoWin\.Add_Click') "Thieu Add_Click"
Assert-Condition "VUONGTT_Toolkit.ps1 ho tro dinh tuyen mo tab AutoWin" (($scriptContent -match 'TargetTag\s+-eq\s+"AutoWin"') -or ($scriptContent -match '"AutoWin"\s*=\s*Get-Control') -or ($scriptContent -match '"AutoWin"\s*\{')) "Thieu dinh tuyen AutoWin"

$color = "Green"
if ($testsFailed -gt 0) { $color = "Yellow" }
Write-Host "`n--- TONG KET: $testsPassed/$testsRun PASSED ($testsFailed FAILED) ---" -ForegroundColor $color
if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
