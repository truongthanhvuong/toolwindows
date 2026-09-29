# =========================================================================
#   TEST-DRIVEN DEVELOPMENT (TDD) TEST SUITE: APPLE UI STANDARDIZATION
#   Kiem tra cac tieu chuan Apple Human Interface Guidelines (macOS HIG)
# =========================================================================
param()

$ErrorActionPreference = "Stop"

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message
    )
    $script:TotalTests++
    if ($Condition) {
        $script:PassedTests++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
    }
}

Write-Host ">>> BAT DAU CHAY BO TEST APPLE UI STANDARDIZATION (macOS HIG) <<<" -ForegroundColor Cyan

$xamlPath = Join-Path (Split-Path -Parent $PSScriptRoot) "src\UI\MainWindow.xaml"
$mainPs1Path = Join-Path (Split-Path -Parent $PSScriptRoot) "VUONGTT_Toolkit.ps1"

$xamlContent = if (Test-Path $xamlPath) { [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8) } else { "" }
$mainContent = if (Test-Path $mainPs1Path) { [System.IO.File]::ReadAllText($mainPs1Path, [System.Text.Encoding]::UTF8) } else { "" }

# 1. Kiem tra Typography & Font Stack chuan Apple
Write-Host "`n--- Test 1: Apple Typography & Font Family Stack ---"
$hasAppleFontStack = ($xamlContent -match 'FontFamily="[^"]*(SF Pro|-apple-system|Segoe UI Variable)[^"]*"')
Assert-Condition -TestName "1.1: MainWindow.xaml declares Apple SF Pro / Segoe UI Variable font stack" `
    -Condition $hasAppleFontStack `
    -Message "MainWindow.xaml must include SF Pro Display, -apple-system, or Segoe UI Variable in FontFamily"

# 2. Kiem tra Hiệu ứng Chuyển Tab Mượt Mà (Apple Fluid Motion Storyboard)
Write-Host "`n--- Test 2: Apple Fluid Tab Transition Engine ---"
$hasTransitionStoryboard = ($xamlContent -match 'x:Key="AppleTabEntranceAnimation"') -or ($xamlContent -match 'Storyboard[\s\S]*?DoubleAnimation[\s\S]*?CubicEase')
Assert-Condition -TestName "2.1: MainWindow.xaml defines AppleTabEntranceAnimation Storyboard" `
    -Condition $hasTransitionStoryboard `
    -Message "MainWindow.xaml must declare AppleTabEntranceAnimation Storyboard in Resources"

$hasSwitchTabAnimation = ($mainContent -match 'function\s+Switch-Tab[\s\S]*?(AppleTabEntranceAnimation|BeginAnimation|TranslateTransform|DoubleAnimation)')
Assert-Condition -TestName "2.2: Switch-Tab in VUONGTT_Toolkit.ps1 executes fluid motion animation" `
    -Condition $hasSwitchTabAnimation `
    -Message "Switch-Tab function must trigger Apple-style fluid animation on page change"

# 3. Kiem tra Apple Segmented Control (Theme & Language Selectors)
Write-Host "`n--- Test 3: Apple Segmented Control ---"
$hasThemeSegmented = ($xamlContent -match 'x:Name="pnlThemeSegmented"[\s\S]*?CornerRadius="(?:[6-9]|1[0-2])"')
Assert-Condition -TestName "3.1: Theme selector container uses Apple Segmented Capsule (CornerRadius >= 6)" `
    -Condition $hasThemeSegmented `
    -Message "Theme selector must have container pnlThemeSegmented with rounded capsule styling"

$hasLangSegmented = ($xamlContent -match 'x:Name="pnlLangSegmented"[\s\S]*?CornerRadius="(?:[6-9]|1[0-2])"')
Assert-Condition -TestName "3.2: Language selector container uses Apple Segmented Capsule (CornerRadius >= 6)" `
    -Condition $hasLangSegmented `
    -Message "Language selector must have container pnlLangSegmented with rounded capsule styling"

# 4. Kiem tra macOS Sidebar Navigation Pills
Write-Host "`n--- Test 4: macOS Sidebar Navigation Pills ---"
$menuBtnStyleMatch = ($xamlContent -match '<Style\s+x:Key="MenuBtn"[\s\S]*?</Style>')
$menuBtnStyle = if ($matches) { $matches[0] } else { "" }
$hasSidebarPills = ($menuBtnStyle -match 'CornerRadius="[7-9]|1[0-2]"')
Assert-Condition -TestName "4.1: MenuBtn style uses Apple Capsule Pill shape (CornerRadius >= 7)" `
    -Condition $hasSidebarPills `
    -Message "MenuBtn template Border must have Apple pill-shaped rounded corners (CornerRadius >= 7)"

# 5. Kiem tra Squircle Cards & Ambient Shadows
Write-Host "`n--- Test 5: Squircle Cards & Ambient Shadows ---"
$cardBorderStyleMatch = ($xamlContent -match '<Style\s+x:Key="CardBorder"[\s\S]*?</Style>')
$cardBorderStyle = if ($matches) { $matches[0] } else { "" }
$hasSquircleCard = ($cardBorderStyle -match 'Property="CornerRadius"\s+Value="1[0-6]"')
Assert-Condition -TestName "5.1: CardBorder style uses Apple Squircle curvature (CornerRadius 10 to 16)" `
    -Condition $hasSquircleCard `
    -Message "CardBorder must use smooth Apple continuous squircle curvature (CornerRadius between 10 and 16)"

$hasAmbientShadow = ($cardBorderStyle -match 'DropShadowEffect[\s\S]*?BlurRadius="1[2-9]|2[0-9]"[\s\S]*?Opacity="0\.0[3-8]"') -or
                    ($cardBorderStyle -match 'DropShadowEffect[\s\S]*?Opacity="0\.0[3-8]"[\s\S]*?BlurRadius="1[2-9]|2[0-9]"')
Assert-Condition -TestName "5.2: CardBorder uses Apple soft ambient drop shadows (BlurRadius >= 12, Opacity 0.03-0.08)" `
    -Condition $hasAmbientShadow `
    -Message "CardBorder must use soft ambient shadows (BlurRadius >= 12, Opacity between 0.03 and 0.08)"


# 6. Kiem tra cu phap AST
Write-Host "`n--- Test 6: PowerShell AST Syntax Integrity ---"
$parseErrors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($mainPs1Path, [ref]$tokens, [ref]$parseErrors)
Assert-Condition -TestName "6.1: AST check for VUONGTT_Toolkit.ps1" `
    -Condition ($parseErrors.Count -eq 0) `
    -Message "VUONGTT_Toolkit.ps1 must have zero AST parse errors"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $script:PassedTests / $script:TotalTests bai test dat." -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    Exit 1
} else {
    Exit 0
}
