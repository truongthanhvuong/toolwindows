# tests/Test-DomainAppInstallFix.Tests.ps1
# Kiểm thử đơn vị và tích hợp: Khắc phục lỗi cài đặt ứng dụng trên máy Domain-Joined chạy PowerShell Admin

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

Write-Host "=== BẮT ĐẦU KIỂM THỬ: DOMAIN ADMIN APP INSTALLATION FIX ===" -ForegroundColor Cyan

# 1. Nạp module SoftwareInstaller và AccountingApps
$installerScript = Join-Path $rootDir "src\Core\SoftwareInstaller.ps1"
$accountingScript = Join-Path $rootDir "src\Core\AccountingApps.ps1"
$officeScript = Join-Path $rootDir "src\Core\OfficeInstaller.ps1"

. $installerScript
if (Test-Path $accountingScript) { . $accountingScript }
if (Test-Path $officeScript) { . $officeScript }

# -------------------------------------------------------------
# TEST GROUP 1: Kiểm tra hàm Get-VUONGTTSafeDownloadDir
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 1: Thư mục tải về an toàn chống chặn GPO/AppLocker ---" -ForegroundColor Yellow

$safeDirCmd = Get-Command "Get-VUONGTTSafeDownloadDir" -ErrorAction SilentlyContinue
Assert-True ($null -ne $safeDirCmd) "Hàm Get-VUONGTTSafeDownloadDir phải tồn tại"

if ($safeDirCmd) {
    $dir = Get-VUONGTTSafeDownloadDir -SubFolder "Apps"
    Assert-True (Test-Path $dir) "Thư mục tải về an toàn phải được tạo thành công"
    Assert-True ($dir -notmatch "^(?i)[A-Z]:\\Users\\[^\\]+\\AppData\\Local\\Temp") "Thư mục tải về KHÔNG ĐƯỢC nằm trong User Temp (bị GPO chặn trên Domain)"
    Assert-True ($dir -match "(?i)ProgramData|Tools" -or -not ($dir -match "AppData")) "Thư mục tải về phải ưu tiên ProgramData hoặc Tools"
}

# -------------------------------------------------------------
# TEST GROUP 2: Kiểm tra SoftwareInstaller.ps1 không hardcode $env:TEMP cho bộ cài
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 2: Không còn hardcode `$env:TEMP cho tải & giải nén app ---" -ForegroundColor Yellow

$installerContent = Get-Content $installerScript -Raw -Encoding UTF8
$hardcodedTempApps = [regex]::Matches($installerContent, '\$destFolder\s*=\s*"\$env:TEMP\\VUONGTT_Apps"')
Assert-Equal $hardcodedTempApps.Count 0 "SoftwareInstaller.ps1 không được hardcode `$env:TEMP\VUONGTT_Apps"

$hardcodedCustomTemp = [regex]::Matches($installerContent, '\$tempDir\s*=\s*"\$env:TEMP\\VUONGTT_CustomApp"')
Assert-Equal $hardcodedCustomTemp.Count 0 "SoftwareInstaller.ps1 không được hardcode `$env:TEMP\VUONGTT_CustomApp"

$acctContent = Get-Content $accountingScript -Raw -Encoding UTF8
$hardcodedAcctTemp = [regex]::Matches($acctContent, '\$destFolder\s*=\s*"\$env:TEMP\\VUONGTT_AccountingApps"')
Assert-Equal $hardcodedAcctTemp.Count 0 "AccountingApps.ps1 không được hardcode `$env:TEMP\VUONGTT_AccountingApps"

# -------------------------------------------------------------
# TEST GROUP 3: Kiểm tra cơ chế Unblock-File cho installer đã tải
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 3: Kiểm tra loại bỏ cờ Zone.Identifier (Unblock-File) ---" -ForegroundColor Yellow

$hasUnblockInInstaller = $installerContent -match "Unblock-File"
Assert-True $hasUnblockInInstaller "SoftwareInstaller.ps1 phải gọi Unblock-File cho file cài đặt đã tải"

$hasUnblockInAcct = $acctContent -match "Unblock-File"
Assert-True $hasUnblockInAcct "AccountingApps.ps1 phải gọi Unblock-File cho file cài đặt đã tải"

# -------------------------------------------------------------
# TEST GROUP 4: Kiểm tra xử lý mã lỗi WinGet & Không nhận nhầm lỗi thành công
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 4: Xử lý mã lỗi WinGet và Fallback sang Direct ---" -ForegroundColor Yellow

# Mã -1978335189 (0x8A15002B: SOURCE_OPEN_FAILED) và -1978335188 (SOURCE_AGREEMENTS_NOT_ACCEPTED)
$badWingetCodesInInstaller = ($installerContent -match "wingetOkCodes[^\r\n]*-1978335189")
Assert-True (-not $badWingetCodesInInstaller) "wingetOkCodes khong duoc coi ma SOURCE_OPEN_FAILED (-1978335189) la thanh cong mac dinh"

# -------------------------------------------------------------
# TEST GROUP 5: Kiểm tra cơ chế chạy dự phòng (Process Execution Fallback)
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 5: Kiểm tra cơ chế chạy cài đặt an toàn cho Domain Admin ---" -ForegroundColor Yellow

$hasFallbackRunner = $installerContent -match "Start-Process" -and $installerContent -match "ProcessLiveRunner"
Assert-True $hasFallbackRunner "SoftwareInstaller.ps1 phải có cơ chế fallback Start-Process khi ProcessLiveRunner gặp sự cố pipe"

# -------------------------------------------------------------
# TEST GROUP 6: Kiểm tra các ứng dụng thiết yếu có DirectUrl & Silent Arguments
# -------------------------------------------------------------
Write-Host "`n--- TEST GROUP 6: Kiểm tra tính sẵn sàng của gói tải trực tiếp cho Domain ---" -ForegroundColor Yellow

$essentialApps = @("chrome", "7zip", "unikey", "zalo", "foxitpdf", "notepadplus")
$allApps = Get-VUONGTTAppList

foreach ($appId in $essentialApps) {
    $target = $allApps | Where-Object { $_.Id -eq $appId }
    Assert-True ($null -ne $target) "Ứng dụng '$appId' phải có trong cơ sở dữ liệu"
    $hasUrl = (-not [string]::IsNullOrWhiteSpace($target.Url)) -or (-not [string]::IsNullOrWhiteSpace($target.DirectUrl))
    Assert-True $hasUrl "Ứng dụng '$appId' phải có Direct URL hợp lệ để fallback khi WinGet lỗi trên Domain"
}

# -------------------------------------------------------------
# TỔNG KẾT
# -------------------------------------------------------------
Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ: $passed PASSED | $failed FAILED" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "=======================================================" -ForegroundColor Cyan

if ($failed -gt 0) { exit 1 } else { exit 0 }
