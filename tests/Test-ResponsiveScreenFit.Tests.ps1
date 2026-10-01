# =========================================================================
#   TEST SUITE: UI RESPONSIVE AUTO-SCALING & SCREEN FIT (TDD)
# =========================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$xamlPath = Join-Path $PSScriptRoot "..\src\UI\MainWindow.xaml"
$ps1Path  = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"

$passCount = 0
$failCount = 0

function Assert-Condition {
    param([string]$Title, [bool]$Condition)
    if ($Condition) {
        Write-Host "  [PASS] $Title" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host "  [FAIL] $Title" -ForegroundColor Red
        $script:failCount++
    }
}

Write-Host "`n>>> BAT DAU KIEM THU TDD: RESPONSIVE SCREEN FIT & AUTO-SCALING <<<" -ForegroundColor Cyan

# 1. Kiem tra MainWindow.xaml
$xamlContent = Get-Content -Raw -Encoding UTF8 $xamlPath
$sr = New-Object System.IO.StringReader($xamlContent)
$xr = [System.Xml.XmlReader]::Create($sr)
$window = [System.Windows.Markup.XamlReader]::Load($xr)

Assert-Condition "1.1: Window MinWidth phai <= 820px de ho tro man hinh nho" ($window.MinWidth -le 820)
Assert-Condition "1.2: Window MinHeight phai <= 500px de ho tro laptop 720p/768p" ($window.MinHeight -le 500)

# Kiem tra khong con trang nao dung HorizontalScrollBarVisibility='Visible' gay tran ngang
$hasVisibleHScroll = ($xamlContent -match 'HorizontalScrollBarVisibility="Visible"')
Assert-Condition "1.3: Khong trang nao dung HorizontalScrollBarVisibility='Visible' gay tran vien man hinh" (-not $hasVisibleHScroll)

# Kiem tra gridSysInfoGauges co name de responsive columns
$gridGauges = $window.FindName("gridSysInfoGauges")
Assert-Condition "1.4: UniformGrid Gauges phai co x:Name='gridSysInfoGauges' de responsive" ($null -ne $gridGauges)

# 2. Kiem tra VUONGTT_Toolkit.ps1
$ps1Content = Get-Content -Raw -Encoding UTF8 $ps1Path
Assert-Condition "2.1: VUONGTT_Toolkit.ps1 phai chua logic kiem tra SystemParameters WorkArea ho tro laptop" ($ps1Content -match 'SystemParameters.*WorkArea')
Assert-Condition "2.2: VUONGTT_Toolkit.ps1 phai co ham Update-VUONGTTResponsiveScaling hoac xu ly co gian" ($ps1Content -match 'Update-VUONGTTResponsiveScaling')
Assert-Condition "2.3: VUONGTT_Toolkit.ps1 phai lang nghe su kien SizeChanged de co gian thoi gian thuc" ($ps1Content -match 'Add_SizeChanged')

Write-Host "`n========================================================"
Write-Host "KET QUA TEST: $passCount PASSED | $failCount FAILED" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================`n"

if ($failCount -gt 0) { exit 1 } else { exit 0 }
