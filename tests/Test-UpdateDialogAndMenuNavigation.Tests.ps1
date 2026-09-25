# =========================================================================
#   TEST SUITE: UPDATE DIALOG 'X' CLOSE BUTTON & REALISTIC ICONS & SOFTWARE TAB
# =========================================================================
$ErrorActionPreference = "Continue"

Write-Host ">>> BAT DAU KIEM THU UPDATE DIALOG & MENU NAVIGATION & REALISTIC ICONS <<<`n" -ForegroundColor Cyan

$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = "E:\toolwindows" }

$scriptFile = Join-Path $root "VUONGTT_Toolkit.ps1"
$xamlFile   = Join-Path $root "src\UI\MainWindow.xaml"

$testsPassed = 0
$testsFailed = 0

function Assert-Condition($name, $condition, $failDetail) {
    if ($condition) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $name - $failDetail" -ForegroundColor Red
        $script:testsFailed++
    }
}

# --- TEST 1: Kiem tra khong dung MessageBox::Show YesNo lam khoa nut X khi cap nhat ---
$scriptContent = [System.IO.File]::ReadAllText($scriptFile, [System.Text.Encoding]::UTF8)

$hasMessageBoxYesNoChangelog = $scriptContent -match 'btnCheckAppUpdate[\s\S]{1,2500}\[System\.Windows\.MessageBox\]::Show\([^)]*YesNo'
Assert-Condition "1.1: Khong dung MessageBox YesNo khien nut X bi disable tren hop thoai cap nhat" (-not $hasMessageBoxYesNoChangelog) "Van con su dung MessageBox::Show voi YesNo trong btnCheckAppUpdate"

$hasCustomUpdateModal = $scriptContent -match 'Show-VUONGTTUpdateChangelogWindow'
Assert-Condition "1.2: Phai co ham Show-VUONGTTUpdateChangelogWindow chuyen dung co nut X va cuon duoc" $hasCustomUpdateModal "Chua co ham Show-VUONGTTUpdateChangelogWindow de mo cua so cap nhat scrollable"

# --- TEST 2: Kiem tra su kien click cho btnMenuSoftware co explicit click handler ---
$hasSoftwareExplicitWiring = $scriptContent -match '\$btnMenuSoftware\.Add_Click'
Assert-Condition "2.1: btnMenuSoftware phai co explicit click handler chuyen tab an toan" $hasSoftwareExplicitWiring "Chua co explicit click handler cho btnMenuSoftware"

# --- TEST 3: Kiem tra Icon nhom THONG TIN HE THONG phai giong that (realistic) ---
$xamlContent = [System.IO.File]::ReadAllText($xamlFile, [System.Text.Encoding]::UTF8)

$bulbChar = [char]0xD83D + [char]0xDCA1
$hasLightbulbForCpu = $xamlContent -match [regex]::Escape("btnMenuCpuMain") -and ($xamlContent.Substring($xamlContent.IndexOf("btnMenuCpuMain"), 300).Contains($bulbChar))
Assert-Condition "3.1: Tra Cuu CPU + Main khong duoc dung icon bong den" (-not $hasLightbulbForCpu) "Van dung icon bong den cho CPU + Mainboard"

$lightningChar = [char]0x26A1
$hasLightningForDisk = $xamlContent -match [regex]::Escape("btnMenuBenchmark") -and ($xamlContent.Substring($xamlContent.IndexOf("btnMenuBenchmark"), 300).Contains($lightningChar))
Assert-Condition "3.2: Suc Khoe O Cung khong dung icon tia set don thuan" (-not $hasLightningForDisk) "Van dung icon tia set cho O Cung"

# Kiem tra co icon vector thuc te cho CPU va O Cung
$hasRealisticIcons = $xamlContent -match 'btnMenuCpuMain[\s\S]{1,600}<Canvas' -and $xamlContent -match 'btnMenuBenchmark[\s\S]{1,600}<Canvas'
Assert-Condition "3.3: Icon CPU va O Cung duoc thiet ke vector thuc te (Canvas / Path)" $hasRealisticIcons "Chua thay Canvas vector icon trong btnMenuCpuMain va btnMenuBenchmark"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $testsPassed PASSED | $testsFailed FAILED" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================================`n" -ForegroundColor Cyan
if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
