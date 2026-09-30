# =========================================================================
# UNIT & REGRESSION TEST: Tab Navigation & Layout Integrity
# Tests subpage variable definitions, XAML control existence, default subtab routing, and sidebar quick actions
# =========================================================================

$ErrorActionPreference = "Stop"
$testDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $testDir
$toolkitScript = Join-Path $rootDir "VUONGTT_Toolkit.ps1"
$xamlFile = Join-Path $rootDir "src\UI\MainWindow.xaml"

$testsPassed = 0
$testsFailed = 0

function Assert-Test {
    param([string]$Name, [bool]$Condition, [string]$Details = "")
    if ($Condition) {
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $Name : $Details" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host "`n>>> Running Test-TabNavigationAndLayout.ps1..." -ForegroundColor Cyan

# 1. Test XAML Valid XML & Controls Existence
Assert-Test "MainWindow.xaml exists" (Test-Path $xamlFile)
[xml]$xaml = Get-Content -Path $xamlFile -Raw -Encoding UTF8
Assert-Test "MainWindow.xaml parses as valid XML" ($null -ne $xaml)

$requiredXamlControls = @(
    # SysInfo
    "containerSysInfo", "pageSysInfo", "pageCustomize", "pageCpuMain",
    "subTabSysInfo_View", "subTabSysInfo_Customize", "subTabSysInfo_CpuMain",
    # SystemFix
    "pageSystemFix", "pageCleaner", "pageConfig", "pnlSubSysFix_Troubleshoot",
    "subTabSysFix_Cleaner", "subTabSysFix_Config", "subTabSysFix_Troubleshoot",
    # SoftwareHub
    "pageSoftwareHub", "pageSoftware", "pageCustomApp", "pageUninstaller", "pageFonts",
    "subTabSoft_Store", "subTabSoft_Custom", "subTabSoft_Uninstall", "subTabSoft_Fonts",
    # HardwareDisk
    "pageHardwareDisk", "pageBenchmark", "pagePartition", "pageLaptopCheck",
    "subTabHw_Disk", "subTabHw_Partition", "subTabHw_Laptop",
    # TechUtilities
    "pageTechUtilities", "pageActivation", "pageBitLocker", "pageBackupDriver", "pageAutoWin", "pageUsers",
    "subTabTech_Activation", "subTabTech_BitLocker", "subTabTech_Backup", "subTabTech_AutoWin", "subTabTech_Users",
    # Quick Actions on Sidebar (5 items)
    "btnQuickClean", "btnQuickActivation", "btnQuickFixPrinter", "btnQuickAutoWin", "btnQuickRestartExplorer"
)

$xamlText = [System.IO.File]::ReadAllText($xamlFile)
foreach ($ctrl in $requiredXamlControls) {
    $exists = $xamlText.Contains("x:Name=`"$ctrl`"")
    Assert-Test "XAML contains control x:Name='$ctrl'" $exists "Control $ctrl not found in MainWindow.xaml"
}

# 1.1 Verify duplicate Quick Action 'btnQuickScanIP' is removed from XAML
$hasDuplicateQuickScan = $xamlText.Contains("x:Name=`"btnQuickScanIP`"")
Assert-Test "XAML does not contain duplicate 'btnQuickScanIP'" (-not $hasDuplicateQuickScan) "Duplicate control btnQuickScanIP should be removed from MainWindow.xaml"

# 2. Test VUONGTT_Toolkit.ps1 script content
Assert-Test "VUONGTT_Toolkit.ps1 exists" (Test-Path $toolkitScript)
$scriptText = [System.IO.File]::ReadAllText($toolkitScript)

$requiredScriptVars = @(
    "pageCleaner", "pageConfig", "pnlSubSysFix_Troubleshoot",
    "pageActivation", "pageBitLocker", "pageBackupDriver", "pageAutoWin", "pageUsers",
    "pageBenchmark", "pagePartition", "pageLaptopCheck",
    "pageSoftware", "pageCustomApp", "pageUninstaller", "pageFonts",
    "pageSysInfo", "pageCustomize", "pageCpuMain",
    "btnQuickClean", "btnQuickActivation", "btnQuickFixPrinter", "btnQuickAutoWin", "btnQuickRestartExplorer"
)

foreach ($var in $requiredScriptVars) {
    $pattern = [regex]::Escape('$' + $var) + '\s*=\s*Get-Control'
    $hasVar = [regex]::IsMatch($scriptText, $pattern)
    Assert-Test "VUONGTT_Toolkit.ps1 defines `$$var via Get-Control" $hasVar "Variable `$$var assignment missing in script"
}

# 2.1 Verify duplicate $btnQuickScanIP is removed from VUONGTT_Toolkit.ps1
$hasScriptDuplicateScan = [regex]::IsMatch($scriptText, '\$btnQuickScanIP\s*=\s*Get-Control')
Assert-Test "VUONGTT_Toolkit.ps1 does not define `$btnQuickScanIP" (-not $hasScriptDuplicateScan) "`$btnQuickScanIP should be removed from VUONGTT_Toolkit.ps1"

# 3. Test Default Subtab Handling in Switch-Tab
$hasDefaultSubTabHandling = $scriptText.Contains("Switch-SystemFixSubTab") -and 
                            $scriptText.Contains("Switch-TechUtilitiesSubTab") -and
                            [regex]::IsMatch($scriptText, "defaultSubTabs|Switch-DefaultSubTab")
Assert-Test "Switch-Tab handles default subtab routing automatically" $hasDefaultSubTabHandling "Switch-Tab must automatically select matching sub-tab when entering Hub"

# 4. Test Quick Action Click Handlers
$quickActionsHandlers = @("btnQuickClean", "btnQuickActivation", "btnQuickFixPrinter", "btnQuickAutoWin", "btnQuickRestartExplorer")
foreach ($qa in $quickActionsHandlers) {
    $pattern = [regex]::Escape('$' + $qa) + '\.Add_Click'
    $hasHandler = [regex]::IsMatch($scriptText, $pattern)
    Assert-Test "Quick Action `$$qa has Click handler registered" $hasHandler "Missing Click handler for $qa"
}

Write-Host "`nTest Summary: $testsPassed Passed, $testsFailed Failed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
