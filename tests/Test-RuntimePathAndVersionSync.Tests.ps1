# ==============================================================================
# BỘ TEST TỰ ĐỘNG: KIỂM THỬ ĐỒNG BỘ ĐƯỜNG DẪN RUNTIME VÀ CHỐNG CACHE PHIÊN BẢN CŨ
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

Write-Host ">>> BAT DAU CHAY BO TEST RUNTIME PATH AND VERSION SYNC <<<" -ForegroundColor Cyan

$mainScriptPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"
$appUpdaterPath = Join-Path $PSScriptRoot "..\src\Core\AppUpdater.ps1"
$programCsPath  = Join-Path $PSScriptRoot "..\src\Program.cs"
$vuongttPath    = Join-Path $PSScriptRoot "..\vuongtt.ps1"
$winPath        = Join-Path $PSScriptRoot "..\win.ps1"

$mainScriptContent = Get-Content -Path $mainScriptPath -Raw -Encoding UTF8
$appUpdaterContent = Get-Content -Path $appUpdaterPath -Raw -Encoding UTF8
$programCsContent  = Get-Content -Path $programCsPath -Raw -Encoding UTF8
$vuongttContent    = Get-Content -Path $vuongttPath -Raw -Encoding UTF8
$winContent        = Get-Content -Path $winPath -Raw -Encoding UTF8

# ------------------------------------------------------------------------------
# 1. VUONGTT_Toolkit.ps1: Ưu tiên ProgramData\VUONGTT_Toolkit\runtime trước TEMP
# ------------------------------------------------------------------------------
Assert-Condition -TestName "1.1: VUONGTT_Toolkit.ps1 kiem tra duong dan ProgramData\VUONGTT_Toolkit\runtime cho ScriptDir" `
    -Condition ($mainScriptContent -match 'ProgramData.*VUONGTT_Toolkit.*runtime' -or $mainScriptContent -match 'pdRuntime.*VUONGTT_Toolkit.*runtime') `
    -Message "VUONGTT_Toolkit.ps1 chua co duong dan ProgramData runtime de tim src\UI\MainWindow.xaml"

# ------------------------------------------------------------------------------
# 2. AppUpdater.ps1: Không còn chứa duong dan rac $env:TEMP\VUONGTT_Toolkit_Runtime
# ------------------------------------------------------------------------------
Assert-Condition -TestName "2.1: AppUpdater.ps1 loai bo tuyet doi duong dan rac TEMP\\VUONGTT_Toolkit_Runtime\\version.json" `
    -Condition (-not ($appUpdaterContent -match '\$env:TEMP\\VUONGTT_Toolkit_Runtime\\version\.json')) `
    -Message "AppUpdater.ps1 van con tham chieu toi file version.json trong TEMP gay nhan dien sai phien ban cu"

Assert-Condition -TestName "2.2: AppUpdater.ps1 uu tien doc version.json tu ScriptDir va ProgramData runtime" `
    -Condition ($appUpdaterContent -match 'ProgramData.*VUONGTT_Toolkit.*runtime.*version\.json' -or $appUpdaterContent -match '\$global:ScriptDir.*version\.json') `
    -Message "AppUpdater.ps1 chua uu tien doc version.json tu ScriptDir / ProgramData"

# ------------------------------------------------------------------------------
# 3. vuongtt.ps1 & win.ps1: Don dep sach se cache rac ngay khi khoi dong
# ------------------------------------------------------------------------------
Assert-Condition -TestName "3.1: vuongtt.ps1 co khoi don dep cache rac TEMP runtime va READY.exe" `
    -Condition ($vuongttContent -match 'VUONGTT_Toolkit_v\*_READY\.exe' -and $vuongttContent -match 'VUONGTT_Toolkit_Runtime') `
    -Message "vuongtt.ps1 chua co logic don dep cache rac TEMP truoc khi kiem tra tai file"

Assert-Condition -TestName "3.2: win.ps1 co khoi don dep cache rac TEMP runtime va READY.exe" `
    -Condition ($winContent -match 'VUONGTT_Toolkit_v\*_READY\.exe' -and $winContent -match 'VUONGTT_Toolkit_Runtime') `
    -Message "win.ps1 chua co logic don dep cache rac TEMP truoc khi kiem tra tai file"

# ------------------------------------------------------------------------------
# 4. Program.cs: Kiem tra isDevRepo de tranh chay nham script cu tren may client
# ------------------------------------------------------------------------------
Assert-Condition -TestName "4.1: Program.cs kiem tra isDevRepo truoc khi quyet dinh trich xuat tai nguyen" `
    -Condition ($programCsContent -match '(?s)bool isDevRepo\s*=.+?if\s*\(!isDevRepo\)') `
    -Message "Program.cs chi kiem tra File.Exists(scriptPath) ma khong kiem tra dev repo, de bi loi tren client"

# ------------------------------------------------------------------------------
# 5. Kiem tra AST Syntax khong co loi cu phap
# ------------------------------------------------------------------------------
$filesToCheck = @($mainScriptPath, $appUpdaterPath, $vuongttPath, $winPath)
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
Assert-Condition -TestName "5.1: Cu phap AST cua cac file PowerShell hoan toan hop le" `
    -Condition $astSuccess `
    -Message "Phat hien loi cu phap AST trong ma nguon"

$resColor = if ($script:testsFailed -eq 0) { "Green" } else { "Red" }
Write-Host "`n>>> KET QUA: $script:testsPassed PASSED, $script:testsFailed FAILED <<<" -ForegroundColor $resColor
if ($script:testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
