# Test-MainWindowXaml.ps1
# Kiem tra tinh hop le va cu phap runtime cua MainWindow.xaml

$ErrorActionPreference = "Stop"

Write-Host "1. Kiem tra XML Parser..."
[xml]$xaml = Get-Content -Raw -Encoding UTF8 -Path "$PSScriptRoot\..\src\UI\MainWindow.xaml"
Write-Host "[PASS] MainWindow.xaml XML hop le hoan toan!" -ForegroundColor Green

Write-Host "2. Kiem tra PresentationFramework XamlReader::Load..."
Add-Type -AssemblyName PresentationFramework
$xamlContent = Get-Content -Raw -Encoding UTF8 -Path "$PSScriptRoot\..\src\UI\MainWindow.xaml"
$stringReader = New-Object System.IO.StringReader($xamlContent)
$xmlReader = [System.Xml.XmlReader]::Create($stringReader)
$window = [System.Windows.Markup.XamlReader]::Load($xmlReader)

if ($window) {
    Write-Host "[PASS] XamlReader::Load thanh cong tuyet doi! Window loai: $($window.GetType().FullName)" -ForegroundColor Green
} else {
    Write-Error "XamlReader::Load tra ve null!"
}

# 3. Kiem tra su ton tai cua tat ca cac control Troubleshoot moi
$requiredControls = @(
    "txtTroubleshootSearch",
    "btnTroubleshootClearSearch",
    "cboTroubleshootCategoryFilter",
    "dgTroubleshootList",
    "txtTroubleshootDetailTitle",
    "txtTroubleshootDetailCategory",
    "txtTroubleshootDetailSymptoms",
    "txtTroubleshootDetailCause",
    "btnActionDiagnosis",
    "btnActionAutoFix",
    "btnActionVerify",
    "btnActionEscalation",
    "txtTroubleshootConsoleLog",
    "btnClearTroubleshootLog"
)

Write-Host "3. Kiem tra su ton tai cua 14 controls Troubleshoot..."
$missing = @()
foreach ($ctrlName in $requiredControls) {
    $found = $window.FindName($ctrlName)
    if ($found) {
        Write-Host "  - Control '$ctrlName' ($($found.GetType().Name)): OK" -ForegroundColor Cyan
    } else {
        $missing += $ctrlName
        Write-Host "  - Control '$ctrlName': MISSING!" -ForegroundColor Red
    }
}

if ($missing.Count -gt 0) {
    Write-Error "Thieu cac controls sau: $($missing -join ', ')"
    exit 1
}

Write-Host "[PASS] Tat ca 14/14 controls Troubleshoot da duoc nhung chinh xac va tim thay thanh cong!" -ForegroundColor Green
