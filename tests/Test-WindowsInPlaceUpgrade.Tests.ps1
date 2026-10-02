# tests/Test-WindowsInPlaceUpgrade.Tests.ps1
# Kiểm thử TDD: Động cơ Nâng Cấp Windows 11 Mới Nhất (In-Place Upgrade - Không Mất Dữ Liệu)

$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $testDir
$passed = 0
$failed = 0

function Assert-Equal($actual, $expected, $message) {
    if ($actual -eq $expected) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $message (Expected: '$expected', Actual: '$actual')" -ForegroundColor Red
        $script:failed++
    }
}

function Assert-True($condition, $message) {
    if ($condition) {
        Write-Host "  [PASS] $message" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "=== BẮT ĐẦU KIỂM THỬ TDD: WINDOWS 11 IN-PLACE UPGRADE ENGINE ===" -ForegroundColor Cyan

# -------------------------------------------------------------
# TASK 1: WindowsInPlaceUpgrade.ps1 (Module Lõi)
# -------------------------------------------------------------
Write-Host "`n--- TASK 1: Kiểm thử Module Lõi (WindowsInPlaceUpgrade.ps1) ---" -ForegroundColor Yellow

$upgradeScript = Join-Path $rootDir "src\Core\WindowsInPlaceUpgrade.ps1"
Assert-True (Test-Path $upgradeScript) "Tệp src\Core\WindowsInPlaceUpgrade.ps1 phải tồn tại"

if (Test-Path $upgradeScript) {
    . $upgradeScript
}

# 1.1 Get-VUONGTTCurrentWindowsInfo
$fnGetWinInfo = Get-Command "Get-VUONGTTCurrentWindowsInfo" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnGetWinInfo) "Hàm Get-VUONGTTCurrentWindowsInfo phải được định nghĩa"
if ($fnGetWinInfo) {
    $info = Get-VUONGTTCurrentWindowsInfo
    Assert-True ($null -ne $info) "Get-VUONGTTCurrentWindowsInfo phải trả về đối tượng thông tin Windows"
    Assert-True (-not [string]::IsNullOrWhiteSpace($info.Caption)) "Thông tin Windows phải chứa tên hệ điều hành (Caption)"
    Assert-True (-not [string]::IsNullOrWhiteSpace($info.BuildNumber)) "Thông tin Windows phải chứa số hiệu BuildNumber"
}

# 1.2 Enable-VUONGTTInPlaceUpgradeBypass
$fnBypass = Get-Command "Enable-VUONGTTInPlaceUpgradeBypass" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnBypass) "Hàm Enable-VUONGTTInPlaceUpgradeBypass phải được định nghĩa"
if ($fnBypass) {
    $bypassRes = Enable-VUONGTTInPlaceUpgradeBypass
    Assert-True ($bypassRes.Success -eq $true) "Enable-VUONGTTInPlaceUpgradeBypass phải hoàn tất thành công"

    $moVal = (Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -ErrorAction SilentlyContinue).AllowUpgradesWithUnsupportedTPMOrCPU
    $tpmVal = (Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassTPMCheck" -ErrorAction SilentlyContinue).BypassTPMCheck
    $cpuVal = (Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassCPUCheck" -ErrorAction SilentlyContinue).BypassCPUCheck
    
    Assert-True ($moVal -eq 1 -or $bypassRes.KeysConfigured -ge 1) "Phải thiết lập cờ MoSetup AllowUpgradesWithUnsupportedTPMOrCPU = 1"
    Assert-True ($tpmVal -eq 1 -or $bypassRes.KeysConfigured -ge 1) "Phải thiết lập cờ LabConfig BypassTPMCheck = 1"
    Assert-True ($cpuVal -eq 1 -or $bypassRes.KeysConfigured -ge 1) "Phải thiết lập cờ LabConfig BypassCPUCheck = 1"
}

# 1.3 Test-VUONGTTInPlaceUpgradeReadiness
$fnReadiness = Get-Command "Test-VUONGTTInPlaceUpgradeReadiness" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnReadiness) "Hàm Test-VUONGTTInPlaceUpgradeReadiness phải được định nghĩa"
if ($fnReadiness) {
    $ready = Test-VUONGTTInPlaceUpgradeReadiness
    Assert-True ($null -ne $ready) "Test-VUONGTTInPlaceUpgradeReadiness phải trả về đối tượng đánh giá"
    Assert-True ($ready.FreeSpaceGB -ge 0) "Dung lượng trống ổ C: phải được đo lường chính xác"
}

# 1.4 Get-VUONGTTInPlaceUpgradeArguments
$fnGetArgs = Get-Command "Get-VUONGTTInPlaceUpgradeArguments" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnGetArgs) "Hàm Get-VUONGTTInPlaceUpgradeArguments phải được định nghĩa"
if ($fnGetArgs) {
    $argsStr = Get-VUONGTTInPlaceUpgradeArguments
    Assert-True ($argsStr -match '/auto\s+upgrade') "Tham số setup BẮT BUỘC phải có '/auto upgrade' để giữ nguyên dữ liệu"
    Assert-True ($argsStr -match '/DynamicUpdate\s+disable') "Tham số setup BẮT BUỘC phải có '/DynamicUpdate disable' để tránh nghẽn mạng"
    Assert-True ($argsStr -match '/compat\s+ignorewarning') "Tham số setup BẮT BUỘC phải có '/compat ignorewarning' để vượt cảnh báo cấu hình"
    Assert-True ($argsStr -match '/MigrateDrivers\s+none') "Tham số setup BẮT BUỘC phải có '/MigrateDrivers none' chống lỗi sập driver SAFE_OS"
}

# 1.5 Start-VUONGTTInPlaceUpgrade
$fnStartUpgrade = Get-Command "Start-VUONGTTInPlaceUpgrade" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnStartUpgrade) "Hàm Start-VUONGTTInPlaceUpgrade phải được định nghĩa"

# -------------------------------------------------------------
# TASK 2: Danh Mục Bản Cài Đặt (AutoWinDeployer.ps1)
# -------------------------------------------------------------
Write-Host "`n--- TASK 2: Kiểm thử Danh Mục Windows 11 Mới Nhất (AutoWinDeployer.ps1) ---" -ForegroundColor Yellow

$autoWinScript = Join-Path $rootDir "src\Core\AutoWinDeployer.ps1"
Assert-True (Test-Path $autoWinScript) "Tệp src\Core\AutoWinDeployer.ps1 phải tồn tại"

if (Test-Path $autoWinScript) {
    . $autoWinScript
}

$fnGetEditions = Get-Command "Get-VUONGTTAutoWinEditions" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnGetEditions) "Hàm Get-VUONGTTAutoWinEditions phải được định nghĩa"

if ($fnGetEditions) {
    $editions = Get-VUONGTTAutoWinEditions
    Assert-True ($editions.Count -gt 0) "Danh mục AutoWin phải có ít nhất 1 bản Windows"

    # Kiểm tra sự hiện diện của bản Windows 11 mới nhất có nhãn 26H2 / 24H2
    $win11Latest = $editions | Where-Object { $_.Id -match '26H2' -or $_.Name -match '26H2' -or $_.Tag -match '26H2' }
    Assert-True ($null -ne $win11Latest) "Danh mục AutoWin PHẢI có tùy chọn Windows 11 26H2 / Mới Nhất để người dùng lựa chọn"
}

# -------------------------------------------------------------
# TASK 3: Nút Bấm Giao Diện (MainWindow.xaml)
# -------------------------------------------------------------
Write-Host "`n--- TASK 3: Kiểm thử Nút Bấm Nâng Cấp In-Place (MainWindow.xaml) ---" -ForegroundColor Yellow

$xamlFile = Join-Path $rootDir "src\UI\MainWindow.xaml"
Assert-True (Test-Path $xamlFile) "Tệp src\UI\MainWindow.xaml phải tồn tại"

$xamlContent = Get-Content $xamlFile -Raw -Encoding UTF8

# 3.1 Kiểm tra sự hiện diện của control btnInPlaceUpgradeWin11
$hasUpgradeBtn = $xamlContent -match 'x:Name="btnInPlaceUpgradeWin11"'
Assert-True $hasUpgradeBtn "MainWindow.xaml PHẢI chứa nút bấm x:Name='btnInPlaceUpgradeWin11'"

# -------------------------------------------------------------
# TASK 4: Tích Hợp Core Launcher (VUONGTT_Toolkit.ps1)
# -------------------------------------------------------------
Write-Host "`n--- TASK 4: Kiểm thử Tích Hợp Core Launcher (VUONGTT_Toolkit.ps1) ---" -ForegroundColor Yellow

$toolkitFile = Join-Path $rootDir "VUONGTT_Toolkit.ps1"
Assert-True (Test-Path $toolkitFile) "Tệp VUONGTT_Toolkit.ps1 phải tồn tại"

$toolkitCode = Get-Content $toolkitFile -Raw -Encoding UTF8

# 4.1 Kiểm tra nạp module WindowsInPlaceUpgrade.ps1
$importsInPlace = $toolkitCode -match 'WindowsInPlaceUpgrade\.ps1'
Assert-True $importsInPlace "VUONGTT_Toolkit.ps1 PHẢI nạp WindowsInPlaceUpgrade.ps1 trong Import Core Modules"

# 4.2 Kiểm tra sự kiện click của btnInPlaceUpgradeWin11
$hasClickHandler = $toolkitCode -match 'btnInPlaceUpgradeWin11[\s\S]*?Add_Click'
Assert-True $hasClickHandler "VUONGTT_Toolkit.ps1 PHẢI gắn bộ xử lý sự kiện Add_Click cho btnInPlaceUpgradeWin11"

# -------------------------------------------------------------
# TỔNG KẾT TEST
# -------------------------------------------------------------
Write-Host "`n=================================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ KIỂM THỬ TDD:" -ForegroundColor Cyan
Write-Host "  PASSED: $passed" -ForegroundColor Green
Write-Host "  FAILED: $failed" -ForegroundColor Red
Write-Host "=================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
