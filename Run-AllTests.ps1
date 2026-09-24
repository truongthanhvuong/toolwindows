# Script chạy toàn bộ test suites trong thư mục tests/
$testFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "tests") -Filter "*.Tests.ps1"
$totalFiles = $testFiles.Count
$passedSuites = 0
$failedSuites = 0

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " BẮT ĐẦU CHẠY TOÀN BỘ REGRESSION TEST SUITES ($totalFiles files)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($file in $testFiles) {
    Write-Host "`n>>> Đang chạy test suite: $($file.Name) ..." -ForegroundColor Yellow
    & powershell -ExecutionPolicy Bypass -File $file.FullName
    if ($LASTEXITCODE -eq 0) {
        Write-Host ">>> [PASS SUITE] $($file.Name)" -ForegroundColor Green
        $passedSuites++
    } else {
        Write-Host ">>> [FAIL SUITE] $($file.Name)" -ForegroundColor Red
        $failedSuites++
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host " KẾT QUẢ TỔNG QUAN TẤT CẢ TEST SUITES:" -ForegroundColor Cyan
Write-Host "  Tổng số test suites: $totalFiles"
Write-Host "  Suites THÀNH CÔNG:   $passedSuites" -ForegroundColor Green
Write-Host "  Suites THẤT BẠI:     $failedSuites" -ForegroundColor $(if ($failedSuites -gt 0) { "Red" } else { "Green" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($failedSuites -gt 0) {
    exit 1
} else {
    exit 0
}
