# =========================================================================
#   TDD TEST SUITE: APPLE MACOS FULL POLISH & REMOVE HIG LABEL
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

Write-Host ">>> BAT DAU CHAY BO TEST MACOS FULL POLISH & REMOVE HIG LABEL <<<" -ForegroundColor Cyan

# --- NHOM 1: Kiem tra loai bo nhan 'macOS HIG' ---
Write-Host "`n--- NHOM 1: Loai bo nhan 'macOS HIG' khoi giao dien ---" -ForegroundColor Magenta
$xamlContent = Get-Content $xamlFile -Raw -Encoding UTF8

Assert-True ($xamlContent -notmatch 'macOS HIG') "MainWindow.xaml KHONG duoc chua chuoi 'macOS HIG'"

# --- NHOM 2: Dong bo Phong chu Apple SF Typography ---
Write-Host "`n--- NHOM 2: Dong bo Phong chu Apple SF Typography tren cac Style ---" -ForegroundColor Magenta
Assert-True ($xamlContent -match 'TargetType="Button"\s+x:Key="FilterTabBtn"[\s\S]*?-apple-system') "FilterTabBtn phai su dung chuoi font chu Apple SF Pro"
Assert-True ($xamlContent -match 'x:Key="AppStoreCard"[\s\S]*?-apple-system') "AppStoreCard phai su dung chuoi font chu Apple SF Pro"
Assert-True ($xamlContent -match 'x:Key="ToggleSwitch"[\s\S]*?-apple-system') "ToggleSwitch phai su dung chuoi font chu Apple SF Pro"

# --- NHOM 3: Hieu ung tuong tac Apple (Triggers: IsMouseOver, IsPressed) ---
Write-Host "`n--- NHOM 3: Hieu ung tuong tac Apple Triggers ---" -ForegroundColor Magenta
Assert-True ($xamlContent -match 'TargetType="Button"\s+x:Key="ActionBtn"[\s\S]*?Property="IsMouseOver"\s+Value="True"') "ActionBtn phai co Trigger IsMouseOver de tao hieu ung hover"
Assert-True ($xamlContent -match 'TargetType="Button"\s+x:Key="ActionBtn"[\s\S]*?Property="IsPressed"\s+Value="True"') "ActionBtn phai co Trigger IsPressed de tao hieu ung nhan lún"
Assert-True ($xamlContent -match 'TargetType="Button"\s+x:Key="MenuBtn"[\s\S]*?Property="IsMouseOver"\s+Value="True"') "MenuBtn phai co Trigger IsMouseOver cho Sidebar Apple"
Assert-True ($xamlContent -match 'TargetType="Button"\s+x:Key="SubTabCapsuleBtn"[\s\S]*?Property="IsMouseOver"\s+Value="True"') "SubTabCapsuleBtn phai co Trigger IsMouseOver"
Assert-True ($xamlContent -match 'x:Key="ToggleSwitch"[\s\S]*?#34C759') "ToggleSwitch phai co mau xanh la Apple (#34C759) khi bat"

# --- NHOM 4: Controller Subtab Apple Blue Capsule Color ---
Write-Host "`n--- NHOM 4: Mau sac Sub-tabs trong VUONGTT_Toolkit.ps1 ---" -ForegroundColor Magenta
$toolkitContent = Get-Content $toolkitFile -Raw -Encoding UTF8
Assert-True ($toolkitContent -notmatch '#B45309') "VUONGTT_Toolkit.ps1 khong con chua ma mau cu #B45309 cho subtab active"
Assert-True ($toolkitContent -match '007AFF') "VUONGTT_Toolkit.ps1 phai su dung ma mau Apple Blue #007AFF cho subtab active"

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "KET QUA: $script:PassedTests / $script:TotalTests PASS" -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
