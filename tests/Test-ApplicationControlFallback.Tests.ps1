# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ CƠ CHẾ BYPASS VÀ FALLBACK KHI BỊ APPLICATION CONTROL CHẶN
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

Write-Host ">>> BAT DAU CHAY BO TEST APPLICATION CONTROL FALLBACK SAFETY <<<" -ForegroundColor Cyan

$vuongttPath = Join-Path $PSScriptRoot "..\vuongtt.ps1"
$winPath     = Join-Path $PSScriptRoot "..\win.ps1"

$vuongttContent = Get-Content -Path $vuongttPath -Raw -Encoding UTF8
$winContent     = Get-Content -Path $winPath -Raw -Encoding UTF8

# ------------------------------------------------------------------------------
# 1. Nhận diện lỗi Application Control / Smart App Control / WDAC
# ------------------------------------------------------------------------------
Assert-Condition -TestName "1.1: vuongtt.ps1 co bat loi Application Control hoac co fallback khi Start-Process that bai" `
    -Condition ($vuongttContent -match 'Application Control' -or $vuongttContent -match 'Assembly.+Load' -or $vuongttContent -match 'Fallback') `
    -Message "vuongtt.ps1 chua co logic fallback khi file EXE bi chan boi Smart App Control / WDAC"

Assert-Condition -TestName "1.2: win.ps1 co bat loi Application Control hoac co fallback khi Start-Process that bai" `
    -Condition ($winContent -match 'Application Control' -or $winContent -match 'Assembly.+Load' -or $winContent -match 'Fallback') `
    -Message "win.ps1 chua co logic fallback khi file EXE bi chan boi Smart App Control / WDAC"

# ------------------------------------------------------------------------------
# 2. Cơ chế giải nén tài nguyên In-Memory từ Assembly khi bị chặn
# ------------------------------------------------------------------------------
Assert-Condition -TestName "2.1: vuongtt.ps1 ho tro load assembly in-memory de lay script goc" `
    -Condition ($vuongttContent -match '\[System\.Reflection\.Assembly\]::Load' -or $vuongttContent -match 'GetManifestResourceNames') `
    -Message "vuongtt.ps1 chua co co che load assembly in-memory giai nen tai nguyen"

Assert-Condition -TestName "2.2: win.ps1 ho tro load assembly in-memory de lay script goc" `
    -Condition ($winContent -match '\[System\.Reflection\.Assembly\]::Load' -or $winContent -match 'GetManifestResourceNames') `
    -Message "win.ps1 chua co co che load assembly in-memory giai nen tai nguyen"

# ------------------------------------------------------------------------------
# 3. Khởi chạy trực tiếp qua powershell.exe -STA khi fallback
# ------------------------------------------------------------------------------
Assert-Condition -TestName "3.1: vuongtt.ps1 khoi chay powershell.exe -STA de bypass 100% Application Control" `
    -Condition ($vuongttContent -match 'powershell\.exe.+-(STA|sta).+(\$mainScript|VUONGTT_Toolkit\.ps1)') `
    -Message "vuongtt.ps1 chua co lenh goi powershell.exe -STA chay VUONGTT_Toolkit.ps1 khi fallback"

Assert-Condition -TestName "3.2: win.ps1 khoi chay powershell.exe -STA de bypass 100% Application Control" `
    -Condition ($winContent -match 'powershell\.exe.+-(STA|sta).+(\$mainScript|VUONGTT_Toolkit\.ps1)') `
    -Message "win.ps1 chua co lenh goi powershell.exe -STA chay VUONGTT_Toolkit.ps1 khi fallback"

# ------------------------------------------------------------------------------
# 4. Kiểm tra AST Syntax của vuongtt.ps1 và win.ps1
# ------------------------------------------------------------------------------
$syntaxPass = $true
foreach ($f in @($vuongttPath, $winPath)) {
    $tokens = $null; $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        $syntaxPass = $false
        Write-Host "  [SYNTAX ERROR] $f : $($errors[0].Message)" -ForegroundColor Red
    }
}
Assert-Condition -TestName "4.1: Cu phap AST cua vuongtt.ps1 va win.ps1 hop le" -Condition $syntaxPass

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $testsPassed / $($testsPassed + $testsFailed) bai test dat." -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
