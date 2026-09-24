# ==============================================================================
# BỘ TEST TDD: PHÁT HIỆN & GỠ CÀI ĐẶT MICROSOFT TEAMS (WIN32 & MODERN APPX/MSIX)
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

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST TEAMS DETECTION & CLEAN UNINSTALL <<<" -ForegroundColor Cyan

$softInstPath = Join-Path $PSScriptRoot "..\src\Core\SoftwareInstaller.ps1"
$mainPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"

$softContent = Get-Content -Path $softInstPath -Raw -Encoding UTF8
$mainContent = Get-Content -Path $mainPath -Raw -Encoding UTF8

# ------------------------------------------------------------------------------
# 1. KIỂM THỬ KHẢ NĂNG QUÉT APPX / MSIX PACKAGES (NEW MICROSOFT TEAMS)
# ------------------------------------------------------------------------------
$hasAppxScan = ($softContent -match 'Get-AppxPackage' -and $softContent -match 'MSTeams|MicrosoftTeams|Teams')
Assert-Condition -TestName "1.1: Get-VUONGTTInstalledSoftware phải quét AppX / MSIX Packages để tìm New Microsoft Teams" `
    -Condition ($hasAppxScan) `
    -Message "Chưa tích hợp quét AppX package trong Get-VUONGTTInstalledSoftware"

# ------------------------------------------------------------------------------
# 2. KIỂM THỬ XỬ LÝ NGOẠI LỆ SYSTEMCOMPONENT CHO TEAMS MACHINE-WIDE / EMBEDDED
# ------------------------------------------------------------------------------
$hasSystemCompException = ($softContent -match 'SystemComponent' -and $softContent -match 'Teams')
Assert-Condition -TestName "2.1: Quét Registry Win32 không được bỏ sót Teams khi có cờ SystemComponent" `
    -Condition ($hasSystemCompException) `
    -Message "Chưa có ngoại lệ cho Teams khi bị Microsoft gắn cờ SystemComponent trong Registry"

# ------------------------------------------------------------------------------
# 3. KIỂM THỬ HỖ TRỢ GỠ BỎ GÓI APPX / MODERN APPS TRONG INVOKE-VUONGTTUNINSTALLSOFTWARE
# ------------------------------------------------------------------------------
$hasAppxUninstall = ($softContent -match 'Remove-AppxPackage' -and $softContent -match 'Invoke-VUONGTTUninstallSoftware')
Assert-Condition -TestName "3.1: Invoke-VUONGTTUninstallSoftware phải hỗ trợ lệnh Remove-AppxPackage cho ứng dụng Store/AppX" `
    -Condition ($hasAppxUninstall) `
    -Message "Chưa có logic thực thi Remove-AppxPackage trong trình gỡ cài đặt"

# ------------------------------------------------------------------------------
# 4. KIỂM THỬ CƠ CHẾ DỌN SẠCH CHUYÊN SÂU TẬN GỐC CHO MICROSOFT TEAMS
# ------------------------------------------------------------------------------
$hasTeamsDeepClean = ($softContent -match 'ms-teams' -or $softContent -match 'msteams' -or ($softContent -match 'Teams' -and $softContent -match 'Remove-AppxProvisionedPackage'))
Assert-Condition -TestName "4.1: Phải có cơ chế dọn dẹp chuyên sâu cho Microsoft Teams (tiến trình, provisioned, cache)" `
    -Condition ($hasTeamsDeepClean) `
    -Message "Chưa có cơ chế dọn rác chuyên sâu (ms-teams.exe, provisioned package, Teams cache) cho Microsoft Teams"

# ------------------------------------------------------------------------------
# 5. KIỂM THỬ CÚ PHÁP AST HỢP LỆ
# ------------------------------------------------------------------------------
$tokens = $null
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseInput($softContent, [ref]$tokens, [ref]$errors)
$astValid = ($errors.Count -eq 0)
Assert-Condition -TestName "5.1: Cú pháp AST của SoftwareInstaller.ps1 hợp lệ" `
    -Condition ($astValid) `
    -Message "Lỗi cú pháp trong SoftwareInstaller.ps1"

Write-Host "--------------------------------------------------------"
Write-Host "KẾT QUẢ KIỂM THỬ TEAMS DETECTION & UNINSTALL:"
Write-Host "  Số test thành công: $passed" -ForegroundColor Green
Write-Host "  Số test thất bại:   $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "--------------------------------------------------------"

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
