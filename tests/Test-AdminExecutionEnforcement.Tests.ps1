# tests/Test-AdminExecutionEnforcement.Tests.ps1
# Kiểm thử TDD: Đảm bảo 100% tính năng chạy quyền Administrator hệ thống (Full Elevation, Machine Scope, Domain Registry Propagation)

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

Write-Host "=== BẮT ĐẦU KIỂM THỬ: ENFORCE FULL ADMINISTRATOR EXECUTION ===" -ForegroundColor Cyan

# -------------------------------------------------------------
# TASK 1: AdminSecurityManager.ps1 (Module Quản Trị Đặc Quyền Tập Trung)
# -------------------------------------------------------------
Write-Host "`n--- TASK 1: Kiểm thử Module Quản Trị Đặc Quyền Tập Trung (AdminSecurityManager.ps1) ---" -ForegroundColor Yellow

$adminSecFile = Join-Path $rootDir "src\Core\AdminSecurityManager.ps1"
Assert-True (Test-Path $adminSecFile) "Tệp src\Core\AdminSecurityManager.ps1 phải tồn tại"

if (Test-Path $adminSecFile) {
    . $adminSecFile
}

# 1.1 Test-VUONGTTIsAdmin
$fnIsAdmin = Get-Command "Test-VUONGTTIsAdmin" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnIsAdmin) "Hàm Test-VUONGTTIsAdmin phải được định nghĩa"
if ($fnIsAdmin) {
    $currentElevation = Test-VUONGTTIsAdmin
    # Phải trả về kiểu boolean
    Assert-True ($currentElevation -is [bool]) "Test-VUONGTTIsAdmin phải trả về kiểu boolean"
}

# 1.2 Start-VUONGTTAdminProcess
$fnStartAdmin = Get-Command "Start-VUONGTTAdminProcess" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnStartAdmin) "Hàm Start-VUONGTTAdminProcess phải được định nghĩa"
if ($fnStartAdmin) {
    # Kiểm tra thực thi an toàn với lệnh cmd /c exit 0
    $res = Start-VUONGTTAdminProcess -FilePath "cmd.exe" -ArgumentList "/c exit 0" -Wait
    Assert-True ($res.Success -eq $true) "Start-VUONGTTAdminProcess phải thực thi thành công lệnh cơ bản"
    Assert-Equal $res.ExitCode 0 "Start-VUONGTTAdminProcess phải bắt đúng ExitCode 0"
}

# 1.3 Get-VUONGTTActiveUserSIDs
$fnGetSIDs = Get-Command "Get-VUONGTTActiveUserSIDs" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnGetSIDs) "Hàm Get-VUONGTTActiveUserSIDs phải được định nghĩa"
if ($fnGetSIDs) {
    $sids = Get-VUONGTTActiveUserSIDs
    Assert-True ($sids -is [System.Array]) "Get-VUONGTTActiveUserSIDs phải trả về mảng SIDs"
    # Không được chứa SID kết thúc bằng _Classes
    $hasClasses = $sids | Where-Object { $_ -like "*_Classes" }
    Assert-True ($null -eq $hasClasses) "Danh sách SIDs không được chứa các key _Classes"
}

# 1.4 Set-VUONGTTAdminRegistry
$fnSetAdminReg = Get-Command "Set-VUONGTTAdminRegistry" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnSetAdminReg) "Hàm Set-VUONGTTAdminRegistry phải được định nghĩa"
if ($fnSetAdminReg) {
    $testSubKey = "Software\VUONGTT_Toolkit\TestElevation"
    $testValName = "IsAdminSync"
    $testValData = 1

    $regRes = Set-VUONGTTAdminRegistry -SubKey $testSubKey -Name $testValName -Value $testValData -Type "DWord"
    Assert-True ($regRes.Success -eq $true) "Set-VUONGTTAdminRegistry phải thực thi thành công"

    # Kiểm tra xem HKLM hoặc HKCU/HKU có ghi nhận không
    $hklmVal = (Get-ItemProperty -Path "HKLM:\$testSubKey" -Name $testValName -ErrorAction SilentlyContinue).$testValName
    $hkcuVal = (Get-ItemProperty -Path "HKCU:\$testSubKey" -Name $testValName -ErrorAction SilentlyContinue).$testValName
    $propagated = ($hklmVal -eq 1 -or $hkcuVal -eq 1)
    Assert-True $propagated "Set-VUONGTTAdminRegistry phải đồng bộ thành công vào HKLM hoặc User Hive"

    # Dọn dẹp test registry
    Remove-Item -Path "HKLM:\$testSubKey" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKCU:\$testSubKey" -Recurse -Force -ErrorAction SilentlyContinue
}

# -------------------------------------------------------------
# TASK 2: Cưỡng Chế Phạm Vi Cài Đặt Toàn Máy (Machine-Scope) Cho Trình Cài Đặt
# -------------------------------------------------------------
Write-Host "`n--- TASK 2: Kiểm thử Cưỡng Chế Machine-Scope và ALLUSERS=1 (SoftwareInstaller.ps1) ---" -ForegroundColor Yellow

$installerCode = Get-Content (Join-Path $rootDir "src\Core\SoftwareInstaller.ps1") -Raw -Encoding UTF8

# 2.1 Kiểm tra winget install có --scope machine trong Install-VUONGTTApp
$wingetInstallScope = $installerCode -match 'install\s+--id\s+.*--scope\s+machine'
Assert-True $wingetInstallScope "Lệnh winget install trong Install-VUONGTTApp PHẢI chứa cờ '--scope machine' để cài toàn máy"

# 2.2 Kiểm tra winget upgrade có --scope machine
$wingetUpgradeScope = $installerCode -match 'upgrade\s+--id\s+.*--scope\s+machine'
Assert-True $wingetUpgradeScope "Lệnh winget upgrade trong Install-VUONGTTApp PHẢI chứa cờ '--scope machine'"

# 2.3 Kiểm tra winget install có --scope machine trong Install-VUONGTTCustomApp
$wingetCustomScope = $installerCode -match 'Install-VUONGTTCustomApp[\s\S]*?install\s+--id\s+.*--scope\s+machine'
Assert-True $wingetCustomScope "Lệnh winget install trong Install-VUONGTTCustomApp PHẢI chứa cờ '--scope machine'"

# 2.4 Kiểm tra xử lý tệp .msi với ALLUSERS=1
$msiAllUsersCheck = $installerCode -match 'ALLUSERS=1'
Assert-True $msiAllUsersCheck "Bộ cài .msi BẮT BUỘC phải truyền tham số ALLUSERS=1 để phổ biến toàn bộ Domain Users"

# -------------------------------------------------------------
# TASK 3: Chuẩn Hóa Khởi Chạy Công Cụ Hệ Thống Với RunAs & Đường Dẫn Tuyệt Đối
# -------------------------------------------------------------
Write-Host "`n--- TASK 3: Kiểm thử Khởi Chạy Hệ Thống với RunAs & System32 (ConfigManager.ps1) ---" -ForegroundColor Yellow

$configManagerFile = Join-Path $rootDir "src\Core\ConfigManager.ps1"
Assert-True (Test-Path $configManagerFile) "Tệp src\Core\ConfigManager.ps1 phải tồn tại"

$configCode = Get-Content $configManagerFile -Raw -Encoding UTF8

# 3.1 Kiểm tra Open-VUONGTTLegacyPanel có sử dụng Start-VUONGTTAdminProcess hoặc RunAs
$usesAdminLaunch = ($configCode -match 'Open-VUONGTTLegacyPanel[\s\S]*?Start-VUONGTTAdminProcess') -or ($configCode -match 'Open-VUONGTTLegacyPanel[\s\S]*?-Verb\s+RunAs')
Assert-True $usesAdminLaunch "Open-VUONGTTLegacyPanel BẮT BUỘC phải khởi chạy qua Start-VUONGTTAdminProcess hoặc cờ RunAs"

# 3.2 Kiểm tra Open-VUONGTTLegacyPanel sử dụng đường dẫn System32 cho các công cụ hệ thống
$usesSystem32 = $configCode -match 'Open-VUONGTTLegacyPanel[\s\S]*?System32'
Assert-True $usesSystem32 "Open-VUONGTTLegacyPanel BẮT BUỘC phải trỏ đường dẫn tuyệt đối System32 cho các binary hệ thống"

# 3.3 Kiểm tra hàm thực tế với panel giả lập
. $configManagerFile
$fnPanel = Get-Command "Open-VUONGTTLegacyPanel" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnPanel) "Hàm Open-VUONGTTLegacyPanel phải tồn tại"

# -------------------------------------------------------------
# TASK 4: Đồng Bộ Registry Tweaks Cho Cả HKLM và Toàn Bộ Active Domain User SIDs
# -------------------------------------------------------------
Write-Host "`n--- TASK 4: Kiểm thử Đồng Bộ Registry Tweaks (SystemTweaks.ps1) ---" -ForegroundColor Yellow

$tweaksFile = Join-Path $rootDir "src\Core\SystemTweaks.ps1"
Assert-True (Test-Path $tweaksFile) "Tệp src\Core\SystemTweaks.ps1 phải tồn tại"

$tweaksCode = Get-Content $tweaksFile -Raw -Encoding UTF8

# 4.1 Kiểm tra SystemTweaks.ps1 có tích hợp Set-VUONGTTAdminRegistry để đồng bộ Domain Users
$usesAdminRegistry = $tweaksCode -match 'Set-VUONGTTAdminRegistry'
Assert-True $usesAdminRegistry "SystemTweaks.ps1 PHẢI gọi Set-VUONGTTAdminRegistry để đồng bộ cấu hình sang Domain User Hives"

# 4.2 Kiểm tra hàm Set-VUONGTTShowFileExtensions dùng Set-VUONGTTAdminRegistry
$fileExtUsesAdminReg = $tweaksCode -match 'Set-VUONGTTShowFileExtensions[\s\S]*?Set-VUONGTTAdminRegistry'
Assert-True $fileExtUsesAdminReg "Set-VUONGTTShowFileExtensions PHẢI dùng Set-VUONGTTAdminRegistry để hiện đuôi file cho mọi user"

# -------------------------------------------------------------
# TASK 5: Tích Hợp Module Vào Core Launcher & Quick Actions
# -------------------------------------------------------------
Write-Host "`n--- TASK 5: Kiểm thử Tích Hợp Core Launcher & Quick Actions (VUONGTT_Toolkit.ps1) ---" -ForegroundColor Yellow

$toolkitFile = Join-Path $rootDir "VUONGTT_Toolkit.ps1"
Assert-True (Test-Path $toolkitFile) "Tệp VUONGTT_Toolkit.ps1 phải tồn tại"

$toolkitCode = Get-Content $toolkitFile -Raw -Encoding UTF8

# 5.1 Kiểm tra nạp AdminSecurityManager.ps1 trong danh sách Import Core Modules
$importsAdminSec = $toolkitCode -match 'AdminSecurityManager\.ps1'
Assert-True $importsAdminSec "VUONGTT_Toolkit.ps1 PHẢI nạp AdminSecurityManager.ps1 trong khối Import Core Modules"

# 5.2 Kiểm tra Quick Actions devmgmt dùng Start-VUONGTTAdminProcess
$devmgmtAdmin = $toolkitCode -match 'btnDriverOpenDevMgmt[\s\S]*?Start-VUONGTTAdminProcess'
Assert-True $devmgmtAdmin "Nút Device Manager PHẢI gọi Start-VUONGTTAdminProcess để đảm bảo quyền quản trị"

# 5.3 Kiểm tra Quick Actions lusrmgr dùng Start-VUONGTTAdminProcess
$lusrmgrAdmin = $toolkitCode -match 'btnOpenLusrmgr[\s\S]*?Start-VUONGTTAdminProcess'
Assert-True $lusrmgrAdmin "Nút Local Users (lusrmgr) PHẢI gọi Start-VUONGTTAdminProcess"

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
