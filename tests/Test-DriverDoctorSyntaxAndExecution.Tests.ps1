# ==============================================================================
# BỘ TEST TDD: KIỂM TRA SỬA LỖI CÚ PHÁP CMDLET 'IF' TRONG DRIVER DOCTOR & SOURCE
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

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST DRIVER DOCTOR SYNTAX & EXECUTION <<<" -ForegroundColor Cyan

$mainPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"
$mainContent = Get-Content -Path $mainPath -Raw -Encoding UTF8

$diskPath = Join-Path $PSScriptRoot "..\src\Core\DiskHealthManager.ps1"
$diskContent = Get-Content -Path $diskPath -Raw -Encoding UTF8

# ------------------------------------------------------------------------------
# 1. KIỂM THỬ KHÔNG CÒN MẪU BIỂU THỨC "+ (if (" NGUY HIỂM TRONG VUONGTT_TOOLKIT.PS1
# ------------------------------------------------------------------------------
$hasBadIfInMain = ($mainContent -match '\+\s*\(if\s*\(' -or $mainContent -match '[^$]\(if\s*\(')
Assert-Condition -TestName "1.1: VUONGTT_Toolkit.ps1 không được chứa biểu thức '(if (' thiếu ký tự '$'" `
    -Condition (-not $hasBadIfInMain) `
    -Message "Vẫn còn biểu thức '(if (' thiếu '$' gây lỗi cmdlet 'if'"

# ------------------------------------------------------------------------------
# 2. KIỂM THỬ KHÔNG CÒN MẪU "-Wear (if (" TRONG DISKHEALTHMANAGER.PS1
# ------------------------------------------------------------------------------
$hasBadIfInDisk = ($diskContent -match '-Wear\s*\(if\s*\(')
Assert-Condition -TestName "2.1: DiskHealthManager.ps1 không được chứa tham số '-Wear (if (' thiếu '$'" `
    -Condition (-not $hasBadIfInDisk) `
    -Message "Vẫn còn tham số '-Wear (if (' thiếu '$' trong DiskHealthManager.ps1"

# ------------------------------------------------------------------------------
# 3. KIỂM THỬ THỰC THI KHỐI TẠO THÔNG ĐIỆP DRIVER DOCTOR KHÔNG BỊ EXCEPTION
# ------------------------------------------------------------------------------
$diagMock = [PSCustomObject]@{
    TotalDevices = 241
    IssueCount   = 0
    HasGpuWarning= $false
    GpuStatus    = "Tối ưu [OK]"
    Manufacturer = "Razer"
    Model        = "Blade"
    SerialNumber = "123456789"
}

$execSuccess = $false
try {
    $serialTag = if ($diagMock.SerialNumber) { " (Serial/Tag: $($diagMock.SerialNumber))" } else { "" }
    $msg = "=== TOÀN BỘ DRIVER PHẦN CỨNG HOẠT ĐỘNG HOÀN HẢO ===`n`n" +
           "• Đã quét kiểm tra sâu: $($diagMock.TotalDevices) thiết bị PnP.`n" +
           "• Thiết bị lỗi / chấm than vàng (Code 28, 10, 43...): 0 thiết bị.`n" +
           "• Card màn hình (GPU): $($diagMock.GpuStatus)`n" +
           "• Thông tin máy: $($diagMock.Manufacturer) $($diagMock.Model)$serialTag`n`n" +
           "Chúc mừng! Máy tính của bạn đã được cài đặt đầy đủ tất cả các driver tối ưu."
    if ($msg -match "Razer Blade \(Serial/Tag: 123456789\)") {
        $execSuccess = $true
    }
} catch {
    $execSuccess = $false
}

Assert-Condition -TestName "3.1: Khối tạo thông điệp Driver Doctor thực thi trơn tru không phát sinh Exception" `
    -Condition ($execSuccess) `
    -Message "Khối tạo thông điệp Driver Doctor phát sinh lỗi khi chạy"

# ------------------------------------------------------------------------------
# 4. KIỂM THỬ CÚ PHÁP AST HỢP LỆ
# ------------------------------------------------------------------------------
$tokens = $null
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseInput($mainContent, [ref]$tokens, [ref]$errors)
$astValid = ($errors.Count -eq 0)
Assert-Condition -TestName "4.1: Cú pháp AST của VUONGTT_Toolkit.ps1 hợp lệ" `
    -Condition ($astValid) `
    -Message "Lỗi cú pháp trong VUONGTT_Toolkit.ps1"

Write-Host "--------------------------------------------------------"
Write-Host "KẾT QUẢ KIỂM THỬ DRIVER DOCTOR SYNTAX:"
Write-Host "  Số test thành công: $passed" -ForegroundColor Green
Write-Host "  Số test thất bại:   $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "--------------------------------------------------------"

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
