# tests/Test-RestoreDefaultWindows.Tests.ps1
# Bộ kiểm thử TDD: Đảm bảo chức năng khôi phục mặc định như lúc mới cài Windows hoạt động chính xác 100%

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

Write-Host "=== BẮT ĐẦU KIỂM THỬ TDD: RESTORE FRESH DEFAULT WINDOWS ===" -ForegroundColor Cyan

# -------------------------------------------------------------
# TASK 1: Kiểm thử hàm Restore-VUONGTTDefaultWindows trong SystemTweaks.ps1
# -------------------------------------------------------------
$tweaksFile = Join-Path $rootDir "src\Core\SystemTweaks.ps1"
Assert-True (Test-Path $tweaksFile) "Tệp src\Core\SystemTweaks.ps1 phải tồn tại"

if (Test-Path $tweaksFile) {
    . $tweaksFile
}

$fnRestore = Get-Command "Restore-VUONGTTDefaultWindows" -ErrorAction SilentlyContinue
Assert-True ($null -ne $fnRestore) "Hàm Restore-VUONGTTDefaultWindows PHẢI tồn tại"

if ($fnRestore) {
    # Kiểm tra gọi thử nghiệm hàm khôi phục với tham số mô phỏng (WhatIf / DryRun hoặc không restart explorer)
    $res = Restore-VUONGTTDefaultWindows -SkipExplorerRestart -SkipRestorePoint
    Assert-True ($null -ne $res) "Restore-VUONGTTDefaultWindows phải trả về kết quả đối tượng"
    Assert-True ($res.Success -eq $true) "Restore-VUONGTTDefaultWindows phải hoàn tất thành công (Success = true)"
    Assert-True ($res.RestoredCount -gt 10) "Số mục khôi phục (RestoredCount) phải lớn hơn 10 mục"
    Assert-True ($res.Log -is [System.Collections.IEnumerable]) "Nhật ký Log phải là danh sách chi tiết"
}

# -------------------------------------------------------------
# TASK 2: Kiểm thử các nút điều khiển trong MainWindow.xaml
# -------------------------------------------------------------
$xamlFile = Join-Path $rootDir "src\UI\MainWindow.xaml"
$xamlContent = Get-Content -Path $xamlFile -Raw -Encoding UTF8

$hasBtnPresetDefault = $xamlContent -match 'x:Name="btnPresetDefaultWin"'
Assert-True $hasBtnPresetDefault "MainWindow.xaml PHẢI chứa nút x:Name='btnPresetDefaultWin' trên thanh Khuyến Nghị Chọn Sẵn"

$hasBtnRestoreDefault = $xamlContent -match 'x:Name="btnRestoreDefaultWin"'
Assert-True $hasBtnRestoreDefault "MainWindow.xaml PHẢI chứa nút x:Name='btnRestoreDefaultWin' trên thanh Thao Tác Dưới Cùng"

# -------------------------------------------------------------
# TASK 3: Kiểm thử kết nối sự kiện trong VUONGTT_Toolkit.ps1
# -------------------------------------------------------------
$toolkitFile = Join-Path $rootDir "VUONGTT_Toolkit.ps1"
$toolkitContent = Get-Content -Path $toolkitFile -Raw -Encoding UTF8

$hasWirePresetDefault = $toolkitContent -match 'btnPresetDefaultWin'
Assert-True $hasWirePresetDefault "VUONGTT_Toolkit.ps1 PHẢI kết nối biến và sự kiện cho btnPresetDefaultWin"

$hasWireRestoreDefault = $toolkitContent -match 'btnRestoreDefaultWin'
Assert-True $hasWireRestoreDefault "VUONGTT_Toolkit.ps1 PHẢI kết nối biến và sự kiện cho btnRestoreDefaultWin"

$hasCallRestoreFunction = $toolkitContent -match 'Restore-VUONGTTDefaultWindows'
Assert-True $hasCallRestoreFunction "VUONGTT_Toolkit.ps1 PHẢI gọi hàm Restore-VUONGTTDefaultWindows"

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
