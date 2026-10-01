$projectRoot = Split-Path -Path $PSScriptRoot -Parent
$installerScript = Join-Path $projectRoot "src\Core\SoftwareInstaller.ps1"
. $installerScript

Write-Host "=== Testing WinGet/Default Workflow ==="

Write-Host "1. Testing UniKey with PreferDirect: `$false..."
$resUni = Install-VUONGTTApp -AppId "unikey" -PreferDirect:$false -AutoLaunch:$false
Write-Host "UniKey Result: $resUni"
if ($resUni -match '\[LỖI\]|Lỗi tải|thất bại|không hợp lệ') {
    throw "WinGet/Default workflow for UniKey failed: $resUni"
}
Write-Host "[PASS] UniKey default install success" -ForegroundColor Green

Write-Host "`n2. Testing Zalo with PreferDirect: `$false..."
$resZalo = Install-VUONGTTApp -AppId "zalo" -PreferDirect:$false -AutoLaunch:$false
Write-Host "Zalo Result: $resZalo"
if ($resZalo -match '\[LỖI\]|Lỗi tải|thất bại|không hợp lệ') {
    throw "WinGet/Default workflow for Zalo failed: $resZalo"
}
Write-Host "[PASS] Zalo default install success" -ForegroundColor Green

Write-Host "`n=== ALL UI WORKFLOW TESTS PASSED ===" -ForegroundColor Green
