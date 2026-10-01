# tests/Test-AppSearchAndRegistration.Tests.ps1
# Kiểm thử TDD: Đảm bảo ứng dụng sau khi cài đặt xuất hiện trong Windows Search, Start Menu và Control Panel Programs & Features

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

Write-Host "=== BẮT ĐẦU KIỂM THỬ: APP SEARCH & SYSTEM REGISTRATION TDD ===" -ForegroundColor Cyan

$installerScript = Join-Path $rootDir "src\Core\SoftwareInstaller.ps1"
. $installerScript

# -------------------------------------------------------------
# TEST GROUP 1: Kiểm tra hàm Register-VUONGTTAppSystemIntegration
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 1: Hàm đăng ký Start Menu & Control Panel Programs & Features ---" -ForegroundColor Yellow

$regCmd = Get-Command "Register-VUONGTTAppSystemIntegration" -ErrorAction SilentlyContinue
Assert-True ($null -ne $regCmd) "Hàm Register-VUONGTTAppSystemIntegration phải tồn tại trong SoftwareInstaller.ps1"

# -------------------------------------------------------------
# TEST GROUP 2: Kiểm tra Start Menu All-Users Shortcut
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 2: Lối tắt Start Menu All-Users (Cho Windows Search tìm kiếm) ---" -ForegroundColor Yellow

$testExe = "C:\Tools\unikey\UniKeyNT.exe"
if (-not (Test-Path "C:\Tools\unikey")) { New-Item -ItemType Directory -Path "C:\Tools\unikey" -Force | Out-Null }
if (-not (Test-Path $testExe)) { [System.IO.File]::WriteAllText($testExe, "MZ_MOCK_EXE") }

if ($regCmd) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    [void](Register-VUONGTTAppSystemIntegration -AppId "unikey" -AppName "UniKey (Gõ Tiếng Việt Chuẩn)" -ExePath $testExe -InstallDir "C:\Tools\unikey")
    
    $startMenuAllUsers = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
    $userStartMenu = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs")
    $foundStartMenu = Get-ChildItem -Path @($startMenuAllUsers, $userStartMenu) -Filter "*UniKey*.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1
    Assert-True ($null -ne $foundStartMenu) "Phải tạo lối tắt trong Start Menu (All-Users hoặc User: $($foundStartMenu.FullName)) để Windows Search tìm thấy"

    $publicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
    $userDesktop = [Environment]::GetFolderPath("Desktop")
    $foundDesktop = Get-ChildItem -Path @($publicDesktop, $userDesktop) -Filter "*UniKey*.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1
    Assert-True ($null -ne $foundDesktop) "Phải tạo lối tắt Desktop (Public hoặc User: $($foundDesktop.FullName)) để mọi user đều nhìn thấy trên màn hình"
} else {
    Assert-True $false "Bỏ qua: Chưa có hàm Register-VUONGTTAppSystemIntegration"
    Assert-True $false "Bỏ qua: Chưa tạo lối tắt Desktop"
}

# -------------------------------------------------------------
# TEST GROUP 3: Kiểm tra đăng ký Registry Uninstall (Programs and Features)
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 3: Đăng ký Registry Control Panel Programs and Features ---" -ForegroundColor Yellow

$uninstallKeyHklm = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VUONGTT_unikey"
$uninstallKeyHkcu = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\VUONGTT_unikey"
$regKey = if (Test-Path $uninstallKeyHklm) { $uninstallKeyHklm } elseif (Test-Path $uninstallKeyHkcu) { $uninstallKeyHkcu } else { $null }

Assert-True ($null -ne $regKey) "Phải có entry trong Registry Uninstall ($regKey) để Control Panel Programs and Features hiển thị"

if ($null -ne $regKey) {
    $props = Get-ItemProperty -Path $regKey
    Assert-True ($props.DisplayName -like "*UniKey*") "DisplayName trong Registry phải khớp tên app (Chứa UniKey)"
    Assert-Equal $props.InstallLocation "C:\Tools\unikey" "InstallLocation trong Registry phải là C:\Tools\unikey"
    Assert-True (-not [string]::IsNullOrWhiteSpace($props.UninstallString)) "Phải có lệnh gỡ cài đặt UninstallString hợp lệ"
} else {
    Assert-True $false "Bỏ qua: Không tìm thấy DisplayName"
    Assert-True $false "Bỏ qua: Không tìm thấy InstallLocation"
    Assert-True $false "Bỏ qua: Không tìm thấy UninstallString"
}

# -------------------------------------------------------------
# TEST GROUP 4: Kiểm tra hàm Test-VUONGTTAppActuallyInstalled
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 4: Hàm xác minh cài đặt thực tế (Chống báo thành công giả) ---" -ForegroundColor Yellow

$testInstalledCmd = Get-Command "Test-VUONGTTAppActuallyInstalled" -ErrorAction SilentlyContinue
Assert-True ($null -ne $testInstalledCmd) "Hàm Test-VUONGTTAppActuallyInstalled phải tồn tại"

if ($testInstalledCmd) {
    $uniInstalled = Test-VUONGTTAppActuallyInstalled -AppId "unikey"
    Assert-True $uniInstalled "UniKey phải được xác nhận là ĐÃ cài đặt thực tế"

    $fakeInstalled = Test-VUONGTTAppActuallyInstalled -AppId "non_existent_fake_app_xyz"
    Assert-Equal $fakeInstalled $false "App không tồn tại TUYỆT ĐỐI KHÔNG ĐƯỢC báo là đã cài đặt"
} else {
    Assert-True $false "Bỏ qua: Không có hàm kiểm tra thực tế"
    Assert-True $false "Bỏ qua: Chặn app không tồn tại"
}

# -------------------------------------------------------------
# TEST GROUP 5: Kiểm tra SoftwareInstaller.ps1 gọi hàm đăng ký hệ thống sau khi giải nén
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 5: Tích hợp vào quy trình cài đặt Install-VUONGTTApp ---" -ForegroundColor Yellow

$installerContent = Get-Content $installerScript -Raw -Encoding UTF8
$callsRegIntegration = $installerContent -match "Register-VUONGTTAppSystemIntegration"
Assert-True $callsRegIntegration "SoftwareInstaller.ps1 phải tự động gọi Register-VUONGTTAppSystemIntegration cho các app"

$checksActualInstall = $installerContent -match "Test-VUONGTTAppActuallyInstalled"
Assert-True $checksActualInstall "SoftwareInstaller.ps1 phải kiểm tra Test-VUONGTTAppActuallyInstalled trước khi báo thành công"

# Cleanup test artifacts
try {
    Remove-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\VUONGTT_unikey" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\VUONGTT_unikey" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item ([System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\UniKey*.lnk")) -Force -ErrorAction SilentlyContinue
    Remove-Item ([System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "UniKey*.lnk")) -Force -ErrorAction SilentlyContinue
} catch {}

# -------------------------------------------------------------
# TỔNG KẾT
# -------------------------------------------------------------
Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ: $passed PASSED | $failed FAILED" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "=======================================================" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 } else { exit 0 }
