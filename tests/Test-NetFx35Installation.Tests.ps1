# ==============================================================================
# BỘ TEST TDD: TÍNH NĂNG CÀI ĐẶT .NET FRAMEWORK 3.5 (.NET 2.0 & 3.0)
# ==============================================================================

$passed = 0
$failed = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $global:passed++
    } else {
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
        $global:failed++
    }
}

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST CÀI ĐẶT .NET FRAMEWORK 3.5 <<<" -ForegroundColor Cyan

$softInstPath = Join-Path $PSScriptRoot "..\src\Core\SoftwareInstaller.ps1"
. $softInstPath

# ------------------------------------------------------------------------------
# CA 1: HÀM CÀI ĐẶT Install-VUONGTTNetFx35 VÀ Get-VUONGTTNetFx35Status TỒN TẠI
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 1: Định nghĩa các hàm quản lý .NET Framework 3.5 ---" -ForegroundColor Yellow
$hasInstallFunc = (Get-Command "Install-VUONGTTNetFx35" -ErrorAction SilentlyContinue) -ne $null
Assert-Condition -TestName "1.1: Hàm Install-VUONGTTNetFx35 phải tồn tại" `
    -Condition ($hasInstallFunc) `
    -Message "Chưa định nghĩa hàm Install-VUONGTTNetFx35 trong SoftwareInstaller.ps1"

$hasStatusFunc = (Get-Command "Get-VUONGTTNetFx35Status" -ErrorAction SilentlyContinue) -ne $null
Assert-Condition -TestName "1.2: Hàm Get-VUONGTTNetFx35Status phải tồn tại" `
    -Condition ($hasStatusFunc) `
    -Message "Chưa định nghĩa hàm Get-VUONGTTNetFx35Status trong SoftwareInstaller.ps1"

# ------------------------------------------------------------------------------
# CA 2: KIỂM TRA TRẠNG THÁI HIỆN TẠI CỦA .NET FRAMEWORK 3.5
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 2: Kiểm tra trạng thái .NET Framework 3.5 trên Windows ---" -ForegroundColor Yellow
if ($hasStatusFunc) {
    $stt = Get-VUONGTTNetFx35Status
    $validStt = ($stt -ne $null -and $stt.PSObject.Properties["IsInstalled"] -ne $null -and $stt.PSObject.Properties["State"] -ne $null)
    Assert-Condition -TestName "2.1: Get-VUONGTTNetFx35Status trả về đối tượng hợp lệ (IsInstalled, State)" `
        -Condition ($validStt) `
        -Message "Get-VUONGTTNetFx35Status không trả về thuộc tính IsInstalled hoặc State"
} else {
    Assert-Condition -TestName "2.1: Get-VUONGTTNetFx35Status trả về đối tượng hợp lệ" `
        -Condition ($false) `
        -Message "Bỏ qua do hàm chưa tồn tại"
}

# ------------------------------------------------------------------------------
# CA 3: PHẦN MỀM netfx35 TRONG DANH SÁCH VUONGTT_APPS
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 3: Tích hợp netfx35 vào kho phần mềm VUONGTT_APPS ---" -ForegroundColor Yellow
$netfxApp = $script:VUONGTT_APPS | Where-Object { $_.Id -eq "netfx35" }
Assert-Condition -TestName "3.1: netfx35 phải có mặt trong danh sách phần mềm" `
    -Condition ($netfxApp -ne $null) `
    -Message "Chưa thêm app netfx35 vào danh sách VUONGTT_APPS"

if ($netfxApp) {
    $hasGoodName = $netfxApp.Name -like "*.NET Framework 3.5*"
    Assert-Condition -TestName "3.2: Tên phần mềm chứa .NET Framework 3.5 (hiện tại: $($netfxApp.Name))" `
        -Condition ($hasGoodName) `
        -Message "Tên phần mềm netfx35 không đúng định dạng"
}

# ------------------------------------------------------------------------------
# CA 4: CHECKBOX app_netfx35 TỒN TẠI TRONG MAINWINDOW.XAML
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 4: Giao diện CheckBox app_netfx35 trong MainWindow.xaml ---" -ForegroundColor Yellow
$xamlPath = Join-Path $PSScriptRoot "..\src\UI\MainWindow.xaml"
$xamlContent = Get-Content -Path $xamlPath -Raw -Encoding UTF8
$hasCheckbox = $xamlContent -match 'x:Name="app_netfx35"'
Assert-Condition -TestName "4.1: CheckBox app_netfx35 phải có mặt trong MainWindow.xaml" `
    -Condition ($hasCheckbox) `
    -Message "Chưa thêm CheckBox app_netfx35 vào MainWindow.xaml"

# ------------------------------------------------------------------------------
# CA 5: ĐIỀU HƯỚNG CÀI ĐẶT QUA Install-VUONGTTApp
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 5: Install-VUONGTTApp nhận diện và điều hướng netfx35 ---" -ForegroundColor Yellow
$scriptContent = Get-Content -Path $softInstPath -Raw -Encoding UTF8
$handlesNetFx35 = $scriptContent -match 'netfx35' -and $scriptContent -match 'Install-VUONGTTNetFx35'
Assert-Condition -TestName "5.1: Install-VUONGTTApp phải điều hướng netfx35 sang Install-VUONGTTNetFx35" `
    -Condition ($handlesNetFx35) `
    -Message "Install-VUONGTTApp chưa có nhánh gọi Install-VUONGTTNetFx35"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ TEST: $passed PASSED | $failed FAILED" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    Exit 1
} else {
    Exit 0
}
