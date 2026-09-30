# =========================================================================
#   VUONGTT TOOLKIT 2026 - UNIT TEST: SCAN FOLDER SHARING & PASSWORDLESS FIX
# =========================================================================

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $testDir
$netPrinterFixPath = Join-Path $projectRoot "src\Core\NetworkPrinterFix.ps1"
$xamlPath = Join-Path $projectRoot "src\UI\MainWindow.xaml"
$toolkitPath = Join-Path $projectRoot "VUONGTT_Toolkit.ps1"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   TEST SUITE: SCAN FOLDER SHARING & PASSWORDLESS FIX   " -ForegroundColor Cyan
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
# Test 1: Kiem tra ham Backend trong NetworkPrinterFix.ps1
# -------------------------------------------------------------------------
Write-Host "[1/3] Kiem tra ham Backend trong NetworkPrinterFix.ps1..." -ForegroundColor Yellow
if (Test-Path $netPrinterFixPath) {
    . $netPrinterFixPath
    $hasEnableAllSharing = Get-Command "Enable-VUONGTTAllSharingNoPassword" -ErrorAction SilentlyContinue
    $hasNewScanShare = Get-Command "New-VUONGTTScanFolderShare" -ErrorAction SilentlyContinue

    Assert-Condition "Ham Enable-VUONGTTAllSharingNoPassword duoc dinh nghia" ($null -ne $hasEnableAllSharing)
    Assert-Condition "Ham New-VUONGTTScanFolderShare duoc dinh nghia" ($null -ne $hasNewScanShare)

    if ($hasNewScanShare) {
        $tempTestPath = Join-Path $env:TEMP "VUONGTT_Scan_Test_Dir"
        try {
            $shareResult = New-VUONGTTScanFolderShare -FolderPath $tempTestPath -ShareName "VUONGTT_Test_Scan" -SkipNetworkEnforce $true
            Assert-Condition "New-VUONGTTScanFolderShare tra ve doi tuong hop le" ($null -ne $shareResult)
            Assert-Condition "Ket qua chua FolderPath" ($null -ne $shareResult.FolderPath)
            Assert-Condition "Ket qua chua UncIp" ($null -ne $shareResult.UncIp)
            Assert-Condition "Ket qua chua UncName" ($null -ne $shareResult.UncName)
        } finally {
            if (Test-Path $tempTestPath) {
                Remove-Item -Path $tempTestPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            cmd.exe /c "net share VUONGTT_Test_Scan /delete /y >nul 2>nul"
        }

        # Test TDD: Xu ly o dia goc (vd D:\ hoac D: phai tu dong chuyen thanh D:\<ShareName> chu khong duoc de nguyen D:\)
        $testDriveRootInput = "D:\"
        $expectedSubFolder = "D:\VUONGTT_TDD_Scan"
        $driveTestRes = New-VUONGTTScanFolderShare -FolderPath $testDriveRootInput -ShareName "VUONGTT_TDD_Scan" -SkipNetworkEnforce $true
        try {
            Assert-Condition "FolderPath khong duoc giu nguyen la goc o dia D:\" ($driveTestRes.FolderPath -ne "D:\" -and $driveTestRes.FolderPath -ne "D:")
            Assert-Condition "FolderPath duoc tu dong noi thanh D:\VUONGTT_TDD_Scan" ($driveTestRes.FolderPath -eq $expectedSubFolder)
            Assert-Condition "FolderPath khong ket thuc bang dau gach cheo nguoc (tranh loi escape Win32)" (-not $driveTestRes.FolderPath.EndsWith("\"))
        } finally {
            cmd.exe /c "net share VUONGTT_TDD_Scan /delete /y >nul 2>nul"
            if (Test-Path $expectedSubFolder) {
                Remove-Item -Path $expectedSubFolder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        # Test TDD: Kiem tra co ham sua loi SeDenyNetworkLogonRight (Error 1385)
        $hasFixLogonRights = Get-Command "Invoke-VUONGTTFixNetworkLogonRights" -ErrorAction SilentlyContinue
        Assert-Condition "Ham Invoke-VUONGTTFixNetworkLogonRights duoc dinh nghia de sua loi 1385" ($null -ne $hasFixLogonRights)

        $backendContent = [System.IO.File]::ReadAllText($netPrinterFixPath, [System.Text.Encoding]::UTF8)
        $hasSeDenyFix = $backendContent -match 'SeDenyNetworkLogonRight'
        $hasSeNetworkFix = $backendContent -match 'SeNetworkLogonRight'
        $hasLoopbackFix = $backendContent -match 'DisableLoopbackCheck'
        $hasStrictNameFix = $backendContent -match 'DisableStrictNameChecking'
        $hasNullSessFix = $backendContent -match 'RestrictNullSessAccess'

        Assert-Condition "Backend co logic xu ly loai bo Guest khoi SeDenyNetworkLogonRight" $hasSeDenyFix
        Assert-Condition "Backend co logic cap quyen SeNetworkLogonRight cho Everyone va Guest" $hasSeNetworkFix
        Assert-Condition "Backend co cau hinh DisableLoopbackCheck tren LanmanServer" $hasLoopbackFix
        Assert-Condition "Backend co cau hinh DisableStrictNameChecking tren LanmanServer" $hasStrictNameFix
        Assert-Condition "Backend co cau hinh RestrictNullSessAccess tren LanmanServer" $hasNullSessFix
    }
} else {
    Assert-Condition "File NetworkPrinterFix.ps1 ton tai" $false "Khong tim thay $netPrinterFixPath"
}

# -------------------------------------------------------------------------
# Test 2: Kiem tra cac control UI trong MainWindow.xaml
# -------------------------------------------------------------------------
Write-Host "`n[2/3] Kiem tra cac dieu khien UI trong MainWindow.xaml..." -ForegroundColor Yellow
if (Test-Path $xamlPath) {
    Add-Type -AssemblyName PresentationFramework
    $xamlContent = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)

    $hasTxtScanFolder   = $xamlContent -match 'x:Name="txtScanFolderPath"'
    $hasTxtScanShare    = $xamlContent -match 'x:Name="txtScanShareName"'
    $hasBtnBrowseFolder = $xamlContent -match 'x:Name="btnBrowseScanFolder"'
    $hasBtnCreateShare  = $xamlContent -match 'x:Name="btnCreateScanFolder"'
    $hasBtnEnableShare  = $xamlContent -match 'x:Name="btnEnableAllFileSharing"'
    $hasBtnOpenFolder   = $xamlContent -match 'x:Name="btnOpenScanFolder"'
    $hasTxtUncIp        = $xamlContent -match 'x:Name="txtScanUncIp"'
    $hasTxtUncName      = $xamlContent -match 'x:Name="txtScanUncName"'
    $hasBtnCopyIp       = $xamlContent -match 'x:Name="btnCopyScanUncIp"'
    $hasBtnCopyName     = $xamlContent -match 'x:Name="btnCopyScanUncName"'

    Assert-Condition "MainWindow.xaml co txtScanFolderPath" $hasTxtScanFolder
    Assert-Condition "MainWindow.xaml co txtScanShareName" $hasTxtScanShare
    Assert-Condition "MainWindow.xaml co btnBrowseScanFolder" $hasBtnBrowseFolder
    Assert-Condition "MainWindow.xaml co btnCreateScanFolder" $hasBtnCreateShare
    Assert-Condition "MainWindow.xaml co btnEnableAllFileSharing" $hasBtnEnableShare
    Assert-Condition "MainWindow.xaml co btnOpenScanFolder" $hasBtnOpenFolder
    Assert-Condition "MainWindow.xaml co txtScanUncIp" $hasTxtUncIp
    Assert-Condition "MainWindow.xaml co txtScanUncName" $hasTxtUncName
    Assert-Condition "MainWindow.xaml co btnCopyScanUncIp" $hasBtnCopyIp
    Assert-Condition "MainWindow.xaml co btnCopyScanUncName" $hasBtnCopyName

    $uncCopyColNot80 = -not ($xamlContent -match '<ColumnDefinition Width="80"/>\s*</Grid.ColumnDefinitions>\s*<TextBlock Grid.Column="0" Text="1\. Theo IP')
    Assert-Condition "Cot nut Copy Scan UNC khong bi hep (Width >= 90 de khong bi cat chu Copy thanh Cop)" $uncCopyColNot80

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
    $bindsCreate = $toolkitContent -match '\$btnCreateScanFolder\.Add_Click'
    $bindsEnable = $toolkitContent -match '\$btnEnableAllFileSharing\.Add_Click'
    $bindsBrowse = $toolkitContent -match '\$btnBrowseScanFolder\.Add_Click'
    $bindsOpen   = $toolkitContent -match '\$btnOpenScanFolder\.Add_Click'
    $bindsCopyIp = $toolkitContent -match '\$btnCopyScanUncIp\.Add_Click'
    $bindsCopyName = $toolkitContent -match '\$btnCopyScanUncName\.Add_Click'

    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnCreateScanFolder" $bindsCreate
    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnEnableAllFileSharing" $bindsEnable
    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnBrowseScanFolder" $bindsBrowse
    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnOpenScanFolder" $bindsOpen
    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnCopyScanUncIp" $bindsCopyIp
    Assert-Condition "VUONGTT_Toolkit.ps1 gan su kien cho btnCopyScanUncName" $bindsCopyName
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