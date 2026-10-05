# =========================================================================
#   TDD TEST SUITE: MENU DEDUPLICATION & STREAMLINING
# =========================================================================
param()

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Assert-True($condition, $testName) {
    $script:TotalTests++
    if ($condition) {
        $script:PassedTests++
        Write-Host "  [PASS] $testName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  [FAIL] $testName" -ForegroundColor Red
    }
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$xamlFile = Join-Path $projectRoot "src\UI\MainWindow.xaml"
$toolkitFile = Join-Path $projectRoot "VUONGTT_Toolkit.ps1"

Write-Host ">>> BAT DAU CHAY BO TEST DEDUPLICATE & STREAMLINE MENU <<<" -ForegroundColor Cyan

# --- NHOM 1: Kiem tra khong con trung lap o Sidebar Menu ---
Write-Host "`n--- NHOM 1: Sidebar chi gom 10 Menu chuan, khong con nut trung lap ---" -ForegroundColor Magenta
$xamlContent = Get-Content $xamlFile -Raw -Encoding UTF8

# Cac nut trung lap PHAI BI XOA khoi Sidebar Menu
Assert-True ($xamlContent -notmatch 'x:Name="btnMenuScanFolder"') "Nut trung lap btnMenuScanFolder phai duoc xoa khoi Sidebar"
Assert-True ($xamlContent -notmatch 'x:Name="btnMenuIsoRepo"') "Nut trung lap btnMenuIsoRepo phai duoc xoa khoi Sidebar"
Assert-True ($xamlContent -notmatch 'x:Name="btnMenuBackupWin"') "Nut trung lap btnMenuBackupWin phai duoc xoa (gop vao BackupRestore)"
Assert-True ($xamlContent -notmatch 'x:Name="btnSpeedupCleaner"') "Nut trung lap btnSpeedupCleaner phai duoc xoa (gop vao SystemFix)"

# 10 Nut Menu chuan phai ton tai
$expected10Buttons = @(
    "btnMenuSysInfo", "btnMenuAutoWin", "btnMenuBackupRestore", "btnMenuOffice",
    "btnMenuActivator", "btnMenuSystemFix", "btnMenuPrinterLAN", "btnMenuHardwareDisk",
    "btnMenuSoftwareStore", "btnMenuFakeVpnProxy"
)

foreach ($btn in $expected10Buttons) {
    Assert-True ($xamlContent -match "x:Name=""$btn""") "Sidebar phai co nut: $btn"
}

# --- NHOM 2: Tab con Scan Folder trong PrinterLAN phai duoc lam ro ---
Write-Host "`n--- NHOM 2: Tab con Scan Folder va Shared Data trong PrinterLAN ---" -ForegroundColor Magenta
Assert-True ($xamlContent -match 'Scan Folder') "Tab con so 4 trong pagePrinterLAN phai chua ten Scan Folder ro rang"

# --- NHOM 3: Routing trong VUONGTT_Toolkit.ps1 ---
Write-Host "`n--- NHOM 3: Kiem tra Routing trong VUONGTT_Toolkit.ps1 ---" -ForegroundColor Magenta
$toolkitContent = Get-Content $toolkitFile -Raw -Encoding UTF8
Assert-True ($toolkitContent -match 'BackupRestore') "VUONGTT_Toolkit.ps1 phai routing hop le cho BackupRestore"
Assert-True ($toolkitContent -match 'SoftwareStore') "VUONGTT_Toolkit.ps1 phai routing hop le cho SoftwareStore"

# --- TONG KET ---
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA KIEM THU:" -ForegroundColor Cyan
Write-Host "  Tong so test : $script:TotalTests"
Write-Host "  Thanh cong   : $script:PassedTests" -ForegroundColor Green
Write-Host "  That bai     : $script:FailedTests" -ForegroundColor $(if ($script:FailedTests -gt 0) { "Red" } else { "Green" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) { exit 1 } else { exit 0 }
