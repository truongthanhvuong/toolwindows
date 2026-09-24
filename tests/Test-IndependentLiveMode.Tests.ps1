# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ CHẾ ĐỘ CHẠY ĐỘC LẬP LIVE MODE (KHÔNG BẮT CẬP NHẬT)
# ==============================================================================

$testsPassed = 0
$testsFailed = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host ">>> BAT DAU CHAY BO TEST INDEPENDENT LIVE MODE <<<" -ForegroundColor Cyan

$mainScriptPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"
$programCsPath  = Join-Path $PSScriptRoot "..\src\Program.cs"
$vuongttPath    = Join-Path $PSScriptRoot "..\vuongtt.ps1"
$winPath        = Join-Path $PSScriptRoot "..\win.ps1"

$mainScriptContent = Get-Content -Path $mainScriptPath -Raw -Encoding UTF8
$programCsContent  = Get-Content -Path $programCsPath -Raw -Encoding UTF8
$vuongttContent    = Get-Content -Path $vuongttPath -Raw -Encoding UTF8
$winContent        = Get-Content -Path $winPath -Raw -Encoding UTF8

# ------------------------------------------------------------------------------
# 1. vuongtt.ps1 & win.ps1: Thiet lap Live Mode va truyen tham so o ca 2 nhanh
# ------------------------------------------------------------------------------
Assert-Condition -TestName "1.1: vuongtt.ps1 thiet lap bien moi truong VUONGTT_LIVE_MODE" `
    -Condition ($vuongttContent -match 'VUONGTT_LIVE_MODE') `
    -Message "vuongtt.ps1 chua thiet lap bien VUONGTT_LIVE_MODE"

Assert-Condition -TestName "1.2: vuongtt.ps1 truyen co Live vao nhanh In-Memory Fallback PowerShell" `
    -Condition ($vuongttContent -match 'powershell\.exe.+mainScript.+-Live') `
    -Message "vuongtt.ps1 chua truyen -Live vao nhanh Fallback powershell.exe"

Assert-Condition -TestName "1.3: win.ps1 thiet lap bien moi truong VUONGTT_LIVE_MODE" `
    -Condition ($winContent -match 'VUONGTT_LIVE_MODE') `
    -Message "win.ps1 chua thiet lap bien VUONGTT_LIVE_MODE"

Assert-Condition -TestName "1.4: win.ps1 truyen co Live vao nhanh In-Memory Fallback PowerShell" `
    -Condition ($winContent -match 'powershell\.exe.+mainScript.+-Live') `
    -Message "win.ps1 chua truyen -Live vao nhanh Fallback powershell.exe"

# ------------------------------------------------------------------------------
# 2. Program.cs: Chuyen tiep co --live cho tien trinh PowerShell va chan hot-swap khi Live
# ------------------------------------------------------------------------------
Assert-Condition -TestName "2.1: Program.cs chuyen tiep co --live hoac bien VUONGTT_LIVE_MODE cho PowerShell con" `
    -Condition ($programCsContent -match 'VUONGTT_LIVE_MODE' -or $programCsContent -match 'isLiveMode.+\-\-live') `
    -Message "Program.cs chua chuyen tiep trang thai Live cho tien trinh PowerShell"

Assert-Condition -TestName "2.2: Program.cs bo qua HotSwap update staged khi isLiveMode = true" `
    -Condition ($programCsContent -match '(?s)if\s*\(!isLiveMode\).+?readyFiles') `
    -Message "Program.cs van kiem tra readyFiles khi o che do LiveMode gay can thiep khong can thiet"

# ------------------------------------------------------------------------------
# 3. VUONGTT_Toolkit.ps1: Nhan dien Live Mode va vo hieu hoa popup cap nhat
# ------------------------------------------------------------------------------
Assert-Condition -TestName "3.1: VUONGTT_Toolkit.ps1 nhan dien bien `$script:isLiveMode" `
    -Condition ($mainScriptContent -match '\$script:isLiveMode\s*=\s*.+VUONGTT_LIVE_MODE') `
    -Message "VUONGTT_Toolkit.ps1 chua dinh nghia va nhan dien `$script:isLiveMode tu args/env"

Assert-Condition -TestName "3.2: VUONGTT_Toolkit.ps1 bo qua hoan toan startup auto-update prompt khi `$script:isLiveMode" `
    -Condition ($mainScriptContent -match '(?s)if\s*\(\$script:isLiveMode\).+?txtFooterStatus\.Text.+?return') `
    -Message "VUONGTT_Toolkit.ps1 chua co logic bo qua popup tu dong cap nhat khi chay Live Mode"

# ------------------------------------------------------------------------------
# 4. AST Validation
# ------------------------------------------------------------------------------
$filesToCheck = @($mainScriptPath, $vuongttPath, $winPath)
$astSuccess = $true
foreach ($file in $filesToCheck) {
    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        $astSuccess = $false
        Write-Host "  [FAIL AST] $($file): $($errors[0].Message)" -ForegroundColor Red
    }
}
Assert-Condition -TestName "4.1: Cu phap AST cua cac file PowerShell hoan toan hop le" `
    -Condition $astSuccess `
    -Message "Phat hien loi cu phap AST trong ma nguon"

$resColor = if ($script:testsFailed -eq 0) { "Green" } else { "Red" }
Write-Host "`n>>> KET QUA: $script:testsPassed PASSED, $script:testsFailed FAILED <<<" -ForegroundColor $resColor
if ($script:testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
