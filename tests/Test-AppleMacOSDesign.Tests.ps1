# =========================================================================
#   TDD TEST SUITE: APPLE MACOS UI DESIGN (ACTIVITY MONITOR HIG)
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

Write-Host ">>> BAT DAU CHAY BO TEST GIAO DIEN APPLE MACOS ACTIVITY MONITOR <<<" -ForegroundColor Cyan

# --- NHOM 1: Window Controls Traffic Lights (🔴 🟡 🟢) trong MainWindow.xaml ---
Write-Host "`n--- NHOM 1: macOS Window Controls Traffic Lights ---" -ForegroundColor Magenta
$xamlContent = Get-Content $xamlFile -Raw -Encoding UTF8

Assert-True ($xamlContent -match 'x:Name="btnMacClose"') "Phai co nut Traffic Light Dong cua so btnMacClose (Do)"
Assert-True ($xamlContent -match 'x:Name="btnMacMinimize"') "Phai co nut Traffic Light Thu nho btnMacMinimize (Vang)"
Assert-True ($xamlContent -match 'x:Name="btnMacMaximize"') "Phai co nut Traffic Light Phong to btnMacMaximize (Xanh)"

# --- NHOM 2: 6 Thẻ Phần Cứng Lớn (Big Metric Cards + Dot Matrix) ---
Write-Host "`n--- NHOM 2: 6 The Phan Cung Lon Chuan Apple Activity Monitor ---" -ForegroundColor Magenta
Assert-True ($xamlContent -match 'x:Name="cardAppleCpu"') "Phai co the CPU cardAppleCpu"
Assert-True ($xamlContent -match 'x:Name="txtAppleCpuPercent"') "Phai co nhan chi so lon CPU txtAppleCpuPercent"
Assert-True ($xamlContent -match 'x:Name="cardAppleMemory"') "Phai co the Memory cardAppleMemory"
Assert-True ($xamlContent -match 'x:Name="txtAppleMemUsedGb"') "Phai co nhan chi so lon RAM txtAppleMemUsedGb"
Assert-True ($xamlContent -match 'x:Name="cardAppleGpu"') "Phai co the GPU cardAppleGpu"
Assert-True ($xamlContent -match 'x:Name="txtAppleGpuPercent"') "Phai co nhan chi so lon GPU txtAppleGpuPercent"
Assert-True ($xamlContent -match 'x:Name="cardAppleDisk"') "Phai co the Disk cardAppleDisk"
Assert-True ($xamlContent -match 'x:Name="txtAppleDiskFreeGb"') "Phai co nhan chi so lon Disk txtAppleDiskFreeGb"
Assert-True ($xamlContent -match 'x:Name="cardAppleNetwork"') "Phai co the Network cardAppleNetwork"
Assert-True ($xamlContent -match 'x:Name="txtAppleNetDownSpeed"') "Phai co nhan chi so lon Network txtAppleNetDownSpeed"
Assert-True ($xamlContent -match 'x:Name="cardAppleBattery"') "Phai co the Battery / Power cardAppleBattery"
Assert-True ($xamlContent -match 'x:Name="txtAppleBatteryPercent"') "Phai co nhan chi so lon Battery txtAppleBatteryPercent"

# --- NHOM 3: 3 Thẻ Phân Tích Chuyên Sâu (Donut RAM & Top Apps) ---
Write-Host "`n--- NHOM 3: 3 The Phan Tich Chuyen Sau ---" -ForegroundColor Magenta
Assert-True ($xamlContent -match 'x:Name="cardAppleMemoryByType"') "Phai co the phan tich RAM theo loai cardAppleMemoryByType"
Assert-True ($xamlContent -match 'x:Name="cardAppleMemoryByApp"') "Phai co the top ung dung an RAM cardAppleMemoryByApp"
Assert-True ($xamlContent -match 'x:Name="cardAppleEnergyByApp"') "Phai co the top ung dung tieu thu CPU cardAppleEnergyByApp"

# --- NHOM 4: Controller Event Handlers & Data Binding trong VUONGTT_Toolkit.ps1 ---
Write-Host "`n--- NHOM 4: Controller Event Handlers trong VUONGTT_Toolkit.ps1 ---" -ForegroundColor Magenta
$toolkitContent = Get-Content $toolkitFile -Raw -Encoding UTF8

Assert-True ($toolkitContent -match 'btnMacClose') "VUONGTT_Toolkit.ps1 phai gan su kien cho btnMacClose"
Assert-True ($toolkitContent -match 'btnMacMinimize') "VUONGTT_Toolkit.ps1 phai gan su kien cho btnMacMinimize"
Assert-True ($toolkitContent -match 'btnMacMaximize') "VUONGTT_Toolkit.ps1 phai gan su kien cho btnMacMaximize"
Assert-True ($toolkitContent -match 'txtAppleCpuPercent') "VUONGTT_Toolkit.ps1 phai dong bo du lieu cho txtAppleCpuPercent"

# --- TONG KET ---
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA KIEM THU:" -ForegroundColor Cyan
Write-Host "  Tong so test : $script:TotalTests"
Write-Host "  Thanh cong   : $script:PassedTests" -ForegroundColor Green
Write-Host "  That bai     : $script:FailedTests" -ForegroundColor $(if ($script:FailedTests -gt 0) { "Red" } else { "Green" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) { exit 1 } else { exit 0 }
