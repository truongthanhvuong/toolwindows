# =========================================================================
#   VUONGTT TOOLKIT 2026 - COMPREHENSIVE TOOL AUDIT & FEATURE VERIFICATION
# =========================================================================

$ErrorActionPreference = "Continue"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $testDir
$srcDir = Join-Path $projectRoot "src"
$coreDir = Join-Path $srcDir "Core"
$dataDir = Join-Path $srcDir "Data"
$configDir = Join-Path $srcDir "Config"
$uiDir = Join-Path $srcDir "UI"
$toolkitPath = Join-Path $projectRoot "VUONGTT_Toolkit.ps1"
$xamlPath = Join-Path $uiDir "MainWindow.xaml"

Write-Host "`n=========================================================================" -ForegroundColor Cyan
Write-Host "   VUONGTT TOOLKIT 2026 - COMPREHENSIVE FEATURE AUDIT MATRIX            " -ForegroundColor Cyan
Write-Host "=========================================================================`n" -ForegroundColor Cyan

$global:auditPassed = 0
$global:auditFailed = 0
$global:auditWarnings = 0
$auditResults = [System.Collections.Generic.List[PSCustomObject]]::new()

function Assert-Audit($hub, $feature, [bool]$condition, $detail = "") {
    $status = if ($condition) { "PASS" } else { "FAIL" }
    $color = if ($condition) { "Green" } else { "Red" }
    if ($condition) {
        $global:auditPassed++
    } else {
        $global:auditFailed++
    }
    Write-Host "  [$status] [$hub] $feature $(if($detail){"-> $detail"})" -ForegroundColor $color
    $global:auditResults.Add([PSCustomObject]@{
        Hub     = $hub
        Feature = $feature
        Status  = $status
        Detail  = $detail
    })
}

# -------------------------------------------------------------------------
# 1. CORE SCRIPTS SYNTAX & LOADABILITY (27 Modules)
# -------------------------------------------------------------------------
Write-Host "[1/9] Kiem tra Cu Phap AST & Kha Nang Nap 27 Core Modules..." -ForegroundColor Yellow
$coreScripts = Get-ChildItem -Path $coreDir -Filter "*.ps1"
foreach ($script in $coreScripts) {
    $tokens = $null; $errs = $null
    [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$errs) | Out-Null
    $hasNoAstErrors = ($errs.Count -eq 0)
    Assert-Audit "Core" "AST Parser: $($script.Name)" $hasNoAstErrors "Errors: $($errs.Count)"
}

# -------------------------------------------------------------------------
# 2. DATABASES & CONFIG INTEGRITY (JSON Schemas)
# -------------------------------------------------------------------------
Write-Host "`n[2/9] Kiem tra Toan Ven Co So Du Lieu & Config JSON..." -ForegroundColor Yellow
$troubleshootDbPath = Join-Path $dataDir "TroubleshootDatabase.json"
$softwareDbPath = Join-Path $dataDir "SoftwareDatabase.json"
$featurePolicyPath = Join-Path $configDir "feature_policy.json"
$vaultPath = Join-Path $configDir "licenses_vault.json"

if (Test-Path $troubleshootDbPath) {
    try {
        $tbJson = Get-Content -Raw -Encoding UTF8 -Path $troubleshootDbPath | ConvertFrom-Json
        $count = if ($tbJson.Problems) { $tbJson.Problems.Count } else { 0 }
        $cats = if ($tbJson.Categories) { $tbJson.Categories.Count } else { 0 }
        $hasRequiredProps = $true
        if ($count -gt 0) {
            $first = $tbJson.Problems[0]
            if (-not ($first.Id -and $first.Category -and $first.Title)) { $hasRequiredProps = $false }
        }
        Assert-Audit "Database" "TroubleshootDatabase.json hop le" ($count -gt 200 -and $cats -ge 7 -and $hasRequiredProps) "So su co: $count, Danh muc: $cats"
    } catch {
        Assert-Audit "Database" "TroubleshootDatabase.json hop le" $false $_.Exception.Message
    }
} else {
    Assert-Audit "Database" "TroubleshootDatabase.json ton tai" $false
}

if (Test-Path $softwareDbPath) {
    try {
        $swJson = Get-Content -Raw -Encoding UTF8 -Path $softwareDbPath | ConvertFrom-Json
        $swCount = $swJson.Count
        Assert-Audit "Database" "SoftwareDatabase.json hop le" ($swCount -gt 50) "So phan mem: $swCount"
    } catch {
        Assert-Audit "Database" "SoftwareDatabase.json hop le" $false $_.Exception.Message
    }
} else {
    Assert-Audit "Database" "SoftwareDatabase.json ton tai" $false
}

if (Test-Path $featurePolicyPath) {
    try {
        $fpJson = Get-Content -Raw -Encoding UTF8 -Path $featurePolicyPath | ConvertFrom-Json
        Assert-Audit "Config" "feature_policy.json hop le" ($null -ne $fpJson) "Policies loaded"
    } catch {
        Assert-Audit "Config" "feature_policy.json hop le" $false $_.Exception.Message
    }
}

# -------------------------------------------------------------------------
# 3. HUB 1: THONG TIN & CAU HINH MAY (SysInfo)
# -------------------------------------------------------------------------
Write-Host "`n[3/9] Kiem tra Hub 1: Thong Tin May & Cau Hinh (SysInfo)..." -ForegroundColor Yellow
$hwScript = Join-Path $coreDir "HardwareInfo.ps1"
$diskScript = Join-Path $coreDir "DiskHealthManager.ps1"
$configScript = Join-Path $coreDir "ConfigManager.ps1"
$userScript = Join-Path $coreDir "UserManager.ps1"

if (Test-Path $hwScript) {
    . $hwScript
    $hasHwFunc = Get-Command "Get-VUONGTTHardwareSnapshot" -ErrorAction SilentlyContinue
    $hasMetrics = Get-Command "Get-VUONGTTLiveMetrics" -ErrorAction SilentlyContinue
    Assert-Audit "Hub1-SysInfo" "Hardware Snapshot & Live Metrics co san" ($null -ne $hasHwFunc -and $null -ne $hasMetrics)
}
if (Test-Path $diskScript) {
    . $diskScript
    $hasDiskFunc = Get-Command "Get-VUONGTTDiskHealthList" -ErrorAction SilentlyContinue
    $hasSmartFunc = Get-Command "Get-VUONGTTSmartAttributes" -ErrorAction SilentlyContinue
    Assert-Audit "Hub1-SysInfo" "Disk Health List & S.M.A.R.T telemetry co san" ($null -ne $hasDiskFunc -and $null -ne $hasSmartFunc)
}
if (Test-Path $configScript) {
    . $configScript
    $hasWuStatus = Get-Command "Get-VUONGTTWindowsUpdateStatus" -ErrorAction SilentlyContinue
    $hasWuDisable = Get-Command "Disable-VUONGTTWindowsUpdate" -ErrorAction SilentlyContinue
    $hasWuEnable = Get-Command "Enable-VUONGTTWindowsUpdate" -ErrorAction SilentlyContinue
    Assert-Audit "Hub1-SysInfo" "Windows Update Toggle Functions co san" ($null -ne $hasWuStatus -and $null -ne $hasWuDisable -and $null -ne $hasWuEnable)
}
if (Test-Path $userScript) {
    . $userScript
    $hasUserList = Get-Command "Get-SystemUserAccounts" -ErrorAction SilentlyContinue
    Assert-Audit "Hub1-SysInfo" "Get-SystemUserAccounts co san" ($null -ne $hasUserList)
}

# -------------------------------------------------------------------------
# 4. HUB 2: TOI UU & SUA LOI WIN (SystemFix & Troubleshoot Helpdesk)
# -------------------------------------------------------------------------
Write-Host "`n[4/9] Kiem tra Hub 2: Toi Uu & Trung Tam Cuu Ho IT Helpdesk..." -ForegroundColor Yellow
$tweaksScript = Join-Path $coreDir "SystemTweaks.ps1"
$tbScript = Join-Path $coreDir "TroubleshootManager.ps1"

if (Test-Path $tweaksScript) {
    . $tweaksScript
    $hasClean = Get-Command "Invoke-VUONGTTDeepClean" -ErrorAction SilentlyContinue
    $hasRam = Get-Command "Invoke-VUONGTTCleanRAM" -ErrorAction SilentlyContinue
    Assert-Audit "Hub2-SystemFix" "Invoke-VUONGTTDeepClean & CleanRAM co san" ($null -ne $hasClean -and $null -ne $hasRam)
}
if (Test-Path $tbScript) {
    . $tbScript
    $hasTbInit = Get-Command "Initialize-VUONGTTTroubleshootEngine" -ErrorAction SilentlyContinue
    $hasTbAction = Get-Command "Invoke-VUONGTTTroubleshootAction" -ErrorAction SilentlyContinue
    Assert-Audit "Hub2-SystemFix" "Troubleshoot Engine (Init & Action) co san" ($null -ne $hasTbInit -and $null -ne $hasTbAction)

    if ($hasTbInit) {
        $initRes = Initialize-VUONGTTTroubleshootEngine -DatabasePath $troubleshootDbPath
        Assert-Audit "Hub2-SystemFix" "Initialize-VUONGTTTroubleshootEngine thanh cong" ($initRes -eq $true)
    }
}

# -------------------------------------------------------------------------
# 5. HUB 3: MANG LAN & IP SCANNER (NetworkLAN)
# -------------------------------------------------------------------------
Write-Host "`n[5/9] Kiem tra Hub 3: Mang LAN & IP Scanner (NetworkLAN)..." -ForegroundColor Yellow
$ipScript = Join-Path $coreDir "IpScanner.ps1"
if (Test-Path $ipScript) {
    . $ipScript
    $hasGetSubnet = Get-Command "Get-VUONGTTLocalSubnetInfo" -ErrorAction SilentlyContinue
    $hasMacVendor = Get-Command "Get-VUONGTTMacVendor" -ErrorAction SilentlyContinue
    Assert-Audit "Hub3-NetworkLAN" "Get-VUONGTTLocalSubnetInfo co san" ($null -ne $hasGetSubnet)
    Assert-Audit "Hub3-NetworkLAN" "Get-VUONGTTMacVendor co san" ($null -ne $hasMacVendor)
}

# -------------------------------------------------------------------------
# 6. HUB 4: SUA LOI MAY IN & CHIA SE LAN (PrinterLAN & Scan Folder)
# -------------------------------------------------------------------------
Write-Host "`n[6/9] Kiem tra Hub 4: Sua Loi May In & Scan to Folder Everyone..." -ForegroundColor Yellow
$printerScript = Join-Path $coreDir "NetworkPrinterFix.ps1"
if (Test-Path $printerScript) {
    . $printerScript
    $hasPrinters = Get-Command "Get-VUONGTTPrinterList" -ErrorAction SilentlyContinue
    $hasNewScan = Get-Command "New-VUONGTTScanFolderShare" -ErrorAction SilentlyContinue
    $hasEnableSharing = Get-Command "Enable-VUONGTTAllSharingNoPassword" -ErrorAction SilentlyContinue
    $hasFixLogonRights = Get-Command "Invoke-VUONGTTFixNetworkLogonRights" -ErrorAction SilentlyContinue
    $hasBatchFix = Get-Command "Invoke-VUONGTTBatchErrorFix" -ErrorAction SilentlyContinue

    Assert-Audit "Hub4-PrinterLAN" "Get-VUONGTTPrinterList co san" ($null -ne $hasPrinters)
    Assert-Audit "Hub4-PrinterLAN" "New-VUONGTTScanFolderShare co san" ($null -ne $hasNewScan)
    Assert-Audit "Hub4-PrinterLAN" "Enable-VUONGTTAllSharingNoPassword co san" ($null -ne $hasEnableSharing)
    Assert-Audit "Hub4-PrinterLAN" "Invoke-VUONGTTFixNetworkLogonRights co san" ($null -ne $hasFixLogonRights)
    Assert-Audit "Hub4-PrinterLAN" "Invoke-VUONGTTBatchErrorFix co san" ($null -ne $hasBatchFix)
}

# -------------------------------------------------------------------------
# 7. HUB 5 & 6: OFFICE AIO & QUAN LY PHAN MEM (SoftwareHub)
# -------------------------------------------------------------------------
Write-Host "`n[7/9] Kiem tra Hub 5 & 6: Office AIO & Quan Ly Phan Mem..." -ForegroundColor Yellow
$officeScript = Join-Path $coreDir "OfficeInstaller.ps1"
$softwareScript = Join-Path $coreDir "SoftwareInstaller.ps1"

if (Test-Path $officeScript) {
    . $officeScript
    $hasOfficeInstall = Get-Command "Start-VUONGTTOfficeInstall" -ErrorAction SilentlyContinue
    Assert-Audit "Hub5-OfficeAIO" "Start-VUONGTTOfficeInstall co san" ($null -ne $hasOfficeInstall)
}
if (Test-Path $softwareScript) {
    . $softwareScript
    $hasGetInstalled = Get-Command "Get-VUONGTTInstalledSoftware" -ErrorAction SilentlyContinue
    $hasUninstall = Get-Command "Invoke-VUONGTTUninstallSoftware" -ErrorAction SilentlyContinue
    $hasInstallApp = Get-Command "Install-VUONGTTApp" -ErrorAction SilentlyContinue
    Assert-Audit "Hub6-Software" "Get-VUONGTTInstalledSoftware co san" ($null -ne $hasGetInstalled)
    Assert-Audit "Hub6-Software" "Invoke-VUONGTTUninstallSoftware co san" ($null -ne $hasUninstall)
    Assert-Audit "Hub6-Software" "Install-VUONGTTApp co san" ($null -ne $hasInstallApp)
}

# -------------------------------------------------------------------------
# 8. HUB 7 & 8: PHAN CUNG, O DIA, TIEN ICH & ADMIN PORTAL
# -------------------------------------------------------------------------
Write-Host "`n[8/9] Kiem tra Hub 7 & 8: Backup, Activator, AutoWin & Admin..." -ForegroundColor Yellow
$backupScript = Join-Path $coreDir "SystemBackupManager.ps1"
$activatorScript = Join-Path $coreDir "Activator.ps1"
$autowinScript = Join-Path $coreDir "AutoWinDeployer.ps1"
$licenseScript = Join-Path $coreDir "LicenseManager.ps1"

if (Test-Path $backupScript) {
    . $backupScript
    $hasBackup = Get-Command "Start-VUONGTTFullWindowsBackup" -ErrorAction SilentlyContinue
    Assert-Audit "Hub8-TechUtilities" "Start-VUONGTTFullWindowsBackup co san" ($null -ne $hasBackup)
}
if (Test-Path $activatorScript) {
    . $activatorScript
    $hasActivate = Get-Command "Invoke-VUONGTTMAS" -ErrorAction SilentlyContinue
    Assert-Audit "Hub8-TechUtilities" "Invoke-VUONGTTMAS (KMS38/HWID) co san" ($null -ne $hasActivate)
}
if (Test-Path $autowinScript) {
    . $autowinScript
    $hasAutoWin = Get-Command "Get-VUONGTTAutoWinEditions" -ErrorAction SilentlyContinue
    Assert-Audit "Hub8-TechUtilities" "Get-VUONGTTAutoWinEditions co san" ($null -ne $hasAutoWin)
}
if (Test-Path $licenseScript) {
    . $licenseScript
    $hasHwid = Get-Command "Get-VUONGTTHardwareId" -ErrorAction SilentlyContinue
    Assert-Audit "AdminPortal" "Get-VUONGTTHardwareId co san" ($null -ne $hasHwid)
}

# -------------------------------------------------------------------------
# 9. UI XAML INTEGRITY & EVENT BINDINGS AUDIT
# -------------------------------------------------------------------------
Write-Host "`n[9/9] Kiem tra Toan Dien Giao Dien WPF XAML & Event Handlers..." -ForegroundColor Yellow
if (Test-Path $xamlPath) {
    Add-Type -AssemblyName PresentationFramework
    $xamlContent = [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8)
    try {
        $stringReader = New-Object System.IO.StringReader($xamlContent)
        $xmlReader = [System.Xml.XmlReader]::Create($stringReader)
        $window = [System.Windows.Markup.XamlReader]::Load($xmlReader)
        Assert-Audit "UI-WPF" "MainWindow.xaml XamlReader::Load thanh cong" ($null -ne $window)
    } catch {
        Assert-Audit "UI-WPF" "MainWindow.xaml XamlReader::Load thanh cong" $false $_.Exception.Message
    }

    # Kiem tra cac nut Sidebar Navigation Chuan Apple HIG
    $hasMenuSysInfo       = $xamlContent -match 'x:Name="btnMenuSysInfo"'
    $hasMenuSystemFix     = $xamlContent -match 'x:Name="btnMenuSystemFix"'
    $hasMenuNetworkLAN    = $xamlContent -match 'x:Name="btnMenuNetworkLAN"'
    $hasMenuPrinterLAN    = $xamlContent -match 'x:Name="btnMenuPrinterLAN"'
    $hasMenuOffice        = $xamlContent -match 'x:Name="btnMenuOffice"'
    $hasMenuSoftware      = $xamlContent -match 'x:Name="btnMenuSoftware"'
    $hasMenuHardwareDisk  = $xamlContent -match 'x:Name="btnMenuHardwareDisk"'
    $hasMenuAutoWin       = $xamlContent -match 'x:Name="btnMenuAutoWin"'
    $hasMenuTechUtilities = $xamlContent -match 'x:Name="btnMenuTechUtilities"'

    $allMenus = ($hasMenuSysInfo -and $hasMenuSystemFix -and $hasMenuNetworkLAN -and $hasMenuPrinterLAN -and
                 $hasMenuOffice -and $hasMenuSoftware -and $hasMenuHardwareDisk -and $hasMenuAutoWin -and $hasMenuTechUtilities)
    Assert-Audit "UI-WPF" "Day du cac nut Sidebar Chuan Apple HIG (8 Hubs + AutoWin)" $allMenus
}

if (Test-Path $toolkitPath) {
    $tokens = $null; $errs = $null
    [System.Management.Automation.Language.Parser]::ParseFile($toolkitPath, [ref]$tokens, [ref]$errs) | Out-Null
    Assert-Audit "Integration" "VUONGTT_Toolkit.ps1 AST 0 errors" ($errs.Count -eq 0) "Errors: $($errs.Count)"
}

# -------------------------------------------------------------------------
# TONG KET AUDIT
# -------------------------------------------------------------------------
$summaryColor = if ($global:auditFailed -eq 0) { "Green" } else { "Red" }
Write-Host "`n=========================================================================" -ForegroundColor Cyan
Write-Host "TONG KET AUDIT HE THONG: $($global:auditPassed) PASS, $($global:auditFailed) FAIL" -ForegroundColor $summaryColor
Write-Host "=========================================================================`n" -ForegroundColor Cyan

if ($global:auditFailed -gt 0) {
    exit 1
} else {
    exit 0
}
