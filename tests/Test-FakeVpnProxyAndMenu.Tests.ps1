# =========================================================================
#   TDD TEST SUITE: FAKE VPN / PROXY & MENU REORGANIZATION
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
$vpnModule = Join-Path $projectRoot "src\Core\VpnProxyManager.ps1"
$xamlFile = Join-Path $projectRoot "src\UI\MainWindow.xaml"
$toolkitFile = Join-Path $projectRoot "VUONGTT_Toolkit.ps1"

Write-Host ">>> BAT DAU CHAY BO TEST FAKE VPN / PROXY & MENU REORGANIZATION <<<" -ForegroundColor Cyan

# --- NHOM 1: Module Backend VpnProxyManager.ps1 ---
Write-Host "`n--- NHOM 1: Backend Module VpnProxyManager.ps1 ---" -ForegroundColor Magenta
$hasFile = Test-Path $vpnModule
Assert-True $hasFile "File src/Core/VpnProxyManager.ps1 phai ton tai"

if ($hasFile) {
    . $vpnModule
    $hasCheckup = (Get-Command -Name "Get-VUONGTTNetworkCheckup" -ErrorAction SilentlyContinue) -ne $null
    $hasSetProxy = (Get-Command -Name "Set-VUONGTTSystemProxy" -ErrorAction SilentlyContinue) -ne $null
    $hasReset = (Get-Command -Name "Reset-VUONGTTNetworkToDefault" -ErrorAction SilentlyContinue) -ne $null
    $hasCountries = (Get-Command -Name "Get-VUONGTTProxyCountries" -ErrorAction SilentlyContinue) -ne $null
    
    Assert-True $hasCheckup "Ham Get-VUONGTTNetworkCheckup phai duoc dinh nghia"
    Assert-True $hasSetProxy "Ham Set-VUONGTTSystemProxy phai duoc dinh nghia"
    Assert-True $hasReset "Ham Reset-VUONGTTNetworkToDefault phai duoc dinh nghia"
    Assert-True $hasCountries "Ham Get-VUONGTTProxyCountries phai duoc dinh nghia"

    if ($hasCountries) {
        $countries = Get-VUONGTTProxyCountries
        Assert-True ($countries.Count -ge 5) "Danh sach quoc gia Proxy phai co it nhat 5 nuoc"
        $codes = @($countries | ForEach-Object { $_.Code })
        Assert-True ($codes -contains "VN") "Danh sach phai chua Viet Nam (VN)"
        Assert-True ($codes -contains "SG") "Danh sach phai chua Singapore (SG)"
        Assert-True ($codes -contains "US") "Danh sach phai chua Hoa Ky (US)"
    } else {
        Assert-True $false "Khong the kiem tra Get-VUONGTTProxyCountries do ham chua ton tai"
    }
} else {
    Assert-True $false "Ham Get-VUONGTTNetworkCheckup chua ton tai do file chua tao"
    Assert-True $false "Ham Set-VUONGTTSystemProxy chua ton tai do file chua tao"
    Assert-True $false "Ham Reset-VUONGTTNetworkToDefault chua ton tai do file chua tao"
    Assert-True $false "Ham Get-VUONGTTProxyCountries chua ton tai do file chua tao"
}

# --- NHOM 2: UI XAML MainWindow.xaml ---
Write-Host "`n--- NHOM 2: Giao dien UI XAML MainWindow.xaml ---" -ForegroundColor Magenta
$xamlContent = Get-Content $xamlFile -Raw -Encoding UTF8

Assert-True ($xamlContent -match 'x:Name="btnMenuFakeVpnProxy"') "Sidebar menu phai co nut btnMenuFakeVpnProxy"
Assert-True ($xamlContent -match 'x:Name="pageFakeVpnProxy"') "XAML phai co Grid pageFakeVpnProxy"
Assert-True ($xamlContent -match 'x:Name="btnVpnToggle"') "pageFakeVpnProxy phai co nut btnVpnToggle"
Assert-True ($xamlContent -match 'x:Name="cmbVpnCountry"') "pageFakeVpnProxy phai co combobox cmbVpnCountry"
Assert-True ($xamlContent -match 'x:Name="txtVpnPublicIp"') "pageFakeVpnProxy phai co txtVpnPublicIp"

$expectedButtons = @(
    "btnMenuSysInfo", "btnMenuAutoWin", "btnMenuUserManager", "btnMenuBackupWin",
    "btnMenuOffice", "btnMenuActivator", "btnMenuSystemFix", "btnMenuBitLocker",
    "btnMenuPrinterLAN", "btnMenuScanFolder", "btnMenuIsoRepo", "btnMenuDiskPartition",
    "btnMenuBackupRestore", "btnMenuSoftwareStore", "btnMenuCustomizer", "btnSpeedupCleaner",
    "btnMenuUninstaller", "btnMenuFakeVpnProxy"
)

$hasAll18 = $true
foreach ($btn in $expectedButtons) {
    if ($xamlContent -notmatch "x:Name=""$btn""") {
        $hasAll18 = $false
        Write-Host "       Thieu nut menu: $btn" -ForegroundColor Yellow
    }
}
Assert-True $hasAll18 "Sidebar phai chua day du 18 nut menu theo phan loai moi"

# --- NHOM 3: Controller & Integration VUONGTT_Toolkit.ps1 ---
Write-Host "`n--- NHOM 3: Tich hop Controller VUONGTT_Toolkit.ps1 ---" -ForegroundColor Magenta
$toolkitContent = Get-Content $toolkitFile -Raw -Encoding UTF8
Assert-True ($toolkitContent -match 'FakeVpnProxy') "VUONGTT_Toolkit.ps1 phai khai bao routing FakeVpnProxy"

# --- TONG KET ---
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA KIEM THU:" -ForegroundColor Cyan
Write-Host "  Tong so test : $script:TotalTests"
Write-Host "  Thanh cong   : $script:PassedTests" -ForegroundColor Green
Write-Host "  That bai     : $script:FailedTests" -ForegroundColor $(if ($script:FailedTests -gt 0) { "Red" } else { "Green" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
