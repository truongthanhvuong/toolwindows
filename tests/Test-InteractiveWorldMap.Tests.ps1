# =========================================================================
#   TDD TEST SUITE: INTERACTIVE WORLD MAP & STREET VIEW EXPLORER
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
$vpnModule = Join-Path $projectRoot "src\Core\VpnProxyManager.ps1"
$xamlFile = Join-Path $projectRoot "src\UI\MainWindow.xaml"
$toolkitFile = Join-Path $projectRoot "VUONGTT_Toolkit.ps1"

Write-Host ">>> BAT DAU CHAY BO TEST INTERACTIVE WORLD MAP & STREET VIEW <<<" -ForegroundColor Cyan

# --- NHOM 1: Backend Data Model Mở Rộng Địa Chỉ Phố & Tọa Độ GPS ---
Write-Host "`n--- NHOM 1: Backend Country Model co day du StreetAddress & GPS ---" -ForegroundColor Magenta
if (Test-Path $vpnModule) {
    . $vpnModule
    $countries = Get-VUONGTTProxyCountries
    $sample = $countries | Where-Object { $_.Code -eq "SG" }
    
    Assert-True ($sample -ne $null) "Phai tim thay node Singapore (SG)"
    Assert-True ($sample.PSObject.Properties['StreetAddress'] -ne $null) "Country node phai chua thuoc tinh StreetAddress"
    Assert-True ($sample.PSObject.Properties['Latitude'] -ne $null) "Country node phai chua thuoc tinh Latitude"
    Assert-True ($sample.PSObject.Properties['Longitude'] -ne $null) "Country node phai chua thuoc tinh Longitude"
    Assert-True ($sample.PSObject.Properties['StreetViewUrl'] -ne $null) "Country node phai chua URL Street View 360 do"
} else {
    Assert-True $false "src/Core/VpnProxyManager.ps1 khong ton tai"
}

# --- NHOM 2: UI Controls trong MainWindow.xaml ---
Write-Host "`n--- NHOM 2: Giao dien UI Zoom & Street View Overlay Card ---" -ForegroundColor Magenta
$xamlContent = Get-Content $xamlFile -Raw -Encoding UTF8

Assert-True ($xamlContent -match 'x:Name="btnMapZoomIn"') "Ban do phai co nut Phong To btnMapZoomIn"
Assert-True ($xamlContent -match 'x:Name="btnMapZoomOut"') "Ban do phai co nut Thu Nho btnMapZoomOut"
Assert-True ($xamlContent -match 'x:Name="btnMapZoomReset"') "Ban do phai co nut Reset Ty Le btnMapZoomReset"
Assert-True ($xamlContent -match 'x:Name="cardStreetViewPreview"') "Ban do phai co Card xem truoc Street View cardStreetViewPreview"
Assert-True ($xamlContent -match 'x:Name="btnOpenStreetView"') "Card phai co nut Mo Xem Pho 360 do btnOpenStreetView"
Assert-True ($xamlContent -match 'x:Name="btnNodeVN"') "Canvas phai co interactive pin btnNodeVN"
Assert-True ($xamlContent -match 'x:Name="btnNodeSG"') "Canvas phai co interactive pin btnNodeSG"
Assert-True ($xamlContent -match 'x:Name="btnNodeUS"') "Canvas phai co interactive pin btnNodeUS"

# --- NHOM 3: Controller Event Handlers trong VUONGTT_Toolkit.ps1 ---
Write-Host "`n--- NHOM 3: Controller Event Handlers trong VUONGTT_Toolkit.ps1 ---" -ForegroundColor Magenta
$toolkitContent = Get-Content $toolkitFile -Raw -Encoding UTF8

Assert-True ($toolkitContent -match 'btnOpenStreetView') "VUONGTT_Toolkit.ps1 phai gan su kien cho btnOpenStreetView"
Assert-True ($toolkitContent -match 'btnMapZoomIn') "VUONGTT_Toolkit.ps1 phai gan su kien cho btnMapZoomIn"

# --- TONG KET ---
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA KIEM THU:" -ForegroundColor Cyan
Write-Host "  Tong so test : $script:TotalTests"
Write-Host "  Thanh cong   : $script:PassedTests" -ForegroundColor Green
Write-Host "  That bai     : $script:FailedTests" -ForegroundColor $(if ($script:FailedTests -gt 0) { "Red" } else { "Green" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) { exit 1 } else { exit 0 }
