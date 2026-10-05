# tests/Test-HighestAdminPrivilege.Tests.ps1
# Bộ kiểm thử TDD: Đảm bảo đặc quyền Quản trị viên tối thượng hệ thống (Highest System Administrator Privileges)

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

Write-Host "=== BẮT ĐẦU KIỂM THỬ TDD: HIGHEST SYSTEM ADMINISTRATOR PRIVILEGES ===" -ForegroundColor Cyan

# -------------------------------------------------------------
# TASK 1: Kiểm thử các hàm cốt lõi trong AdminSecurityManager.ps1
# -------------------------------------------------------------
$adminSecFile = Join-Path $rootDir "src\Core\AdminSecurityManager.ps1"
Assert-True (Test-Path $adminSecFile) "Tệp src\Core\AdminSecurityManager.ps1 phải tồn tại"

if (Test-Path $adminSecFile) {
    . $adminSecFile
}

# 1.1 Hàm Enable-VUONGTTHighestPrivileges phải tồn tại và khả dụng
$fnEnablePrivs = Get-Command "Enable-VUONGTTHighestPrivileges" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnEnablePrivs) "Hàm Enable-VUONGTTHighestPrivileges PHẢI tồn tại"

if ($fnEnablePrivs) {
    $privResult = Enable-VUONGTTHighestPrivileges
    Assert-True ($null -ne $privResult) "Enable-VUONGTTHighestPrivileges phải trả về kết quả"
    Assert-True ($privResult.PSObject.Properties['Success'] -ne $null) "Kết quả phải có thuộc tính Success"
    Assert-True ($privResult.PSObject.Properties['EnabledCount'] -ne $null) "Kết quả phải có thuộc tính EnabledCount"
    Assert-True ($privResult.PSObject.Properties['Privileges'] -ne $null) "Kết quả phải có danh sách Privileges"
}

# 1.2 Hàm Get-VUONGTTProcessIntegrityLevel phải tồn tại
$fnGetIntegrity = Get-Command "Get-VUONGTTProcessIntegrityLevel" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnGetIntegrity) "Hàm Get-VUONGTTProcessIntegrityLevel PHẢI tồn tại"

if ($fnGetIntegrity) {
    $integrity = Get-VUONGTTProcessIntegrityLevel
    Assert-True ($null -ne $integrity) "Get-VUONGTTProcessIntegrityLevel phải trả về kết quả"
    Assert-True ($integrity.PSObject.Properties['LevelName'] -ne $null) "Kết quả phải có thuộc tính LevelName"
    Assert-True ($integrity.PSObject.Properties['IsHighOrSystem'] -ne $null) "Kết quả phải có thuộc tính IsHighOrSystem"
}

# 1.3 Cải tiến Start-VUONGTTAdminProcess với cờ ForceHighestPrivilege
$fnStartAdmin = Get-Command "Start-VUONGTTAdminProcess" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnStartAdmin) "Hàm Start-VUONGTTAdminProcess PHẢI tồn tại"

if ($fnStartAdmin) {
    # Kiểm tra gọi tiến trình với ForceHighestPrivilege
    $procRes = Start-VUONGTTAdminProcess -FilePath "cmd.exe" -ArgumentList "/c exit 0" -Wait -ForceHighestPrivilege
    Assert-True ($procRes.Success -eq $true) "Start-VUONGTTAdminProcess với ForceHighestPrivilege phải chạy thành công"
}

# 1.4 Hàm Grant-VUONGTTOwnershipAndAccess (Chiếm quyền sở hữu file/registry cứng đầu)
$fnGrantAccess = Get-Command "Grant-VUONGTTOwnershipAndAccess" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnGrantAccess) "Hàm Grant-VUONGTTOwnershipAndAccess PHẢI tồn tại"

# -------------------------------------------------------------
# TASK 2: Kiểm tra tích hợp vào Program.cs và VUONGTT_Toolkit.ps1
# -------------------------------------------------------------
$programCsPath = Join-Path $rootDir "src\Program.cs"
$programCsText = Get-Content -Path $programCsPath -Raw -Encoding UTF8
$hasNativePrivAdjust = $programCsText -match 'AdjustTokenPrivileges' -or $programCsText -match 'EnablePrivilege'
Assert-True $hasNativePrivAdjust "Program.cs PHẢI chứa logic nâng đặc quyền Windows Token (AdjustTokenPrivileges)"

$toolkitPath = Join-Path $rootDir "VUONGTT_Toolkit.ps1"
$toolkitText = Get-Content -Path $toolkitPath -Raw -Encoding UTF8
$hasCallEnablePrivs = $toolkitText -match 'Enable-VUONGTTHighestPrivileges'
Assert-True $hasCallEnablePrivs "VUONGTT_Toolkit.ps1 PHẢI gọi Enable-VUONGTTHighestPrivileges khi khởi động"

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
