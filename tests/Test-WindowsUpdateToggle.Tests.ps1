# =========================================================================
#   VUONGTT TOOLKIT 2026 - UNIT TEST: WINDOWS UPDATE TOGGLE FEATURE
# =========================================================================

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $testDir
$configManagerPath = Join-Path $projectRoot "src\Core\ConfigManager.ps1"
$xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
$toolkitPath = Join-Path $projectRoot "VUONGTT_Toolkit.ps1"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   TEST SUITE: WINDOWS UPDATE TOGGLE (1-CLICK BAT/TAT)   " -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

$passed = 0
$failed = 0

function Assert-Condition($name, [bool]$condition, $message = "") {
    if ($condition) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
        $global:passed++
    } else {
        Write-Host "  [FAIL] $name - $message" -ForegroundColor Red
        $global:failed++
    }
}

# -------------------------------------------------------------------------
# Test 1: Kiem tra ham Backend trong ConfigManager.ps1
# -------------------------------------------------------------------------
Write-Host "[1/3] Kiem tra ham Backend trong ConfigManager.ps1..." -ForegroundColor Yellow
if (Test-Path $configManagerPath) {
    . $configManagerPath
    $hasGetStatus = Get-Command "Get-VUONGTTWindowsUpdateStatus" -ErrorAction SilentlyContinue
    $hasDisable = Get-Command "Disable-VUONGTTWindowsUpdate" -ErrorAction SilentlyContinue
    $hasEnable = Get-Command "Enable-VUONGTTWindowsUpdate" -ErrorAction SilentlyContinue

    Assert-Condition "Ham Get-VUONGTTWindowsUpdateStatus duoc dinh nghia" ($null -ne $hasGetStatus)
    Assert-Condition "Ham Disable-VUONGTTWindowsUpdate duoc dinh nghia" ($null -ne $hasDisable)
    Assert-Condition "Ham Enable-VUONGTTWindowsUpdate duoc dinh nghia" ($null -ne $hasEnable)

    if ($hasGetStatus) {
        $status = Get-VUONGTTWindowsUpdateStatus
        Assert-Condition "Get-VUONGTTWindowsUpdateStatus tra ve Hashtable/PSCustomObject" ($status -is [hashtable] -or $status -is [pscustomobject])
        Assert-Condition "Status chua truong IsEnabled" ($null -ne $status.IsEnabled)
        Assert-Condition "Status chua truong StatusText" ($null -ne $status.StatusText)
    }
} else {
    Assert-Condition "File ConfigManager.ps1 ton tai" $false "Khong tim thay file $configManagerPath"
}

# -------------------------------------------------------------------------
# Test 2: Kiem tra XAML controls trong MainWindow.xaml
# -------------------------------------------------------------------------
Write-Host "`n[2/3] Kiem tra cac dieu khien UI trong MainWindow.xaml..." -ForegroundColor Yellow
if (Test-Path $xamlPath) {
    Add-Type -AssemblyName PresentationFramework
    $xamlContent = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)
    
    $hasStatusTxt = $xamlContent -match 'x:Name="txtWindowsUpdateStatus"'
    $hasDisableBtn = $xamlContent -match 'x:Name="btnDisableWindowsUpdate"'
    $hasEnableBtn = $xamlContent -match 'x:Name="btnEnableWindowsUpdate"'
    $hasSettingsBtn = $xamlContent -match 'x:Name="btnOpenWindowsUpdateSettings"'

    Assert-Condition "MainWindow.xaml co txtWindowsUpdateStatus" $hasStatusTxt
    Assert-Condition "MainWindow.xaml co btnDisableWindowsUpdate" $hasDisableBtn
    Assert-Condition "MainWindow.xaml co btnEnableWindowsUpdate" $hasEnableBtn
    Assert-Condition "MainWindow.xaml co btnOpenWindowsUpdateSettings" $hasSettingsBtn

    try {
        $stringReader = New-Object System.IO.StringReader($xamlContent)
        $xmlReader = [System.Xml.XmlReader]::Create($stringReader)
        $window = [System.Windows.Markup.XamlReader]::Load($xmlReader)
        Assert-Condition "MainWindow.xaml tai thanh cong qua XamlReader::Load (Hop le WPF)" ($null -ne $window)
    } catch {
        Assert-Condition "MainWindow.xaml tai thanh cong qua XamlReader::Load (Hop le WPF)" $false $_.Exception.Message
    }
} else {
    Assert-Condition "File MainWindow.xaml ton tai" $false
}

# -------------------------------------------------------------------------
# Test 3: Kiem tra cu phap va gan su kien trong VUONGTT_Toolkit.ps1
# -------------------------------------------------------------------------
Write-Host "`n[3/3] Kiem tra tich hop trong VUONGTT_Toolkit.ps1..." -ForegroundColor Yellow
if (Test-Path $toolkitPath) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($toolkitPath, [ref]$tokens, [ref]$errors)
    Assert-Condition "VUONGTT_Toolkit.ps1 khong co loi cu phap AST (0 errors)" ($errors.Count -eq 0)

    $toolkitContent = [System.IO.File]::ReadAllText($toolkitPath, [System.Text.Encoding]::UTF8)
    $bindsDisable = $toolkitContent -match '\$btnDisableWindowsUpdate\.Add_Click'
    $bindsEnable = $toolkitContent -match '\$btnEnableWindowsUpdate\.Add_Click'
    $bindsSettings = $toolkitContent -match '\$btnOpenWindowsUpdateSettings\.Add_Click'

    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnDisableWindowsUpdate" $bindsDisable
    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnEnableWindowsUpdate" $bindsEnable
    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnOpenWindowsUpdateSettings" $bindsSettings
} else {
    Assert-Condition "File VUONGTT_Toolkit.ps1 ton tai" $false
}

# -------------------------------------------------------------------------
# Tong ket
# -------------------------------------------------------------------------
$summaryColor = if ($failed -eq 0) { "Green" } else { "Red" }
Write-Host "`n--------------------------------------------------------" -ForegroundColor Cyan
Write-Host "KET QUA KIEM THU: $passed PASS, $failed FAIL" -ForegroundColor $summaryColor
Write-Host "--------------------------------------------------------`n" -ForegroundColor Cyan

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}