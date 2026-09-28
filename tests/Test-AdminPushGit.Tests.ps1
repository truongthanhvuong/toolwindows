# =========================================================================
#   TEST-DRIVEN DEVELOPMENT (TDD) TEST SUITE: ADMIN PUSH GIT FEATURE
#   Kiem tra nut Push Git & Phat Hanh tren giao dien Admin Portal
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

Write-Host ">>> BAT DAU CHAY BO TEST ADMIN PORTAL PUSH GIT & RELEASE <<<" -ForegroundColor Cyan

$xamlPath = Join-Path (Split-Path -Parent $PSScriptRoot) "src\UI\MainWindow.xaml"
$mainPs1Path = Join-Path (Split-Path -Parent $PSScriptRoot) "VUONGTT_Toolkit.ps1"

$xamlContent = if (Test-Path $xamlPath) { [System.IO.File]::ReadAllText($xamlPath, [System.Text.Encoding]::UTF8) } else { "" }
$mainContent = if (Test-Path $mainPs1Path) { [System.IO.File]::ReadAllText($mainPs1Path, [System.Text.Encoding]::UTF8) } else { "" }

# 1. Kiem tra nut btnAdminPushGit ton tai trong MainWindow.xaml
Write-Host "`n--- Test 1: UI Element Declaration in MainWindow.xaml ---"
$hasBtnInXaml = ($xamlContent -match 'x:Name="btnAdminPushGit"')
Assert-Condition -TestName "1.1: btnAdminPushGit must be declared in MainWindow.xaml" `
    -Condition $hasBtnInXaml `
    -Message "MainWindow.xaml must define a button named btnAdminPushGit in the Admin Portal page"

$hasToolTip = ($xamlContent -match 'x:Name="btnAdminPushGit"[\s\S]*?ToolTip="[^"]*"')
Assert-Condition -TestName "1.2: btnAdminPushGit must have a descriptive ToolTip" `
    -Condition $hasToolTip `
    -Message "btnAdminPushGit must have a helpful ToolTip explaining the Git push & release action"

# 2. Kiem tra Get-Control va su kien Click trong VUONGTT_Toolkit.ps1
Write-Host "`n--- Test 2: Event Binding & Logic in VUONGTT_Toolkit.ps1 ---"
$hasGetControl = ($mainContent -match '\$btnAdminPushGit\s*=\s*Get-Control\s+"btnAdminPushGit"')
Assert-Condition -TestName "2.1: btnAdminPushGit is retrieved via Get-Control" `
    -Condition $hasGetControl `
    -Message "VUONGTT_Toolkit.ps1 must retrieve btnAdminPushGit via Get-Control"

$hasClickHandler = ($mainContent -match '\$btnAdminPushGit\.Add_Click\(')
Assert-Condition -TestName "2.2: btnAdminPushGit has Add_Click event handler registered" `
    -Condition $hasClickHandler `
    -Message "VUONGTT_Toolkit.ps1 must register an Add_Click handler for btnAdminPushGit"

# 3. Kiem tra chong loi hardcode o dia E: va co co che tim kiem dong
Write-Host "`n--- Test 3: Dynamic Repo Discovery & No Hardcoded Drive Crash ---"
# Check that the click handler does NOT unconditionally assign $repoRoot = "E:\toolwindows"
$hasUnconditionalHardcodedE = ($mainContent -match '\$btnAdminPushGit\.Add_Click\([\s\S]*?\$repoRoot\s*=\s*"E:\\toolwindows"')
Assert-Condition -TestName "3.1: btnAdminPushGit does NOT unconditionally fallback to hardcoded E:\toolwindows" `
    -Condition (-not $hasUnconditionalHardcodedE) `
    -Message "VUONGTT_Toolkit.ps1 must not unconditionally use 'E:\toolwindows' without verifying drive existence"

# 4. Kiem tra co che Cloud REST API Fallback khi chay tren may khong co repo Git
Write-Host "`n--- Test 4: Cloud REST API Fallback on Standalone / Remote Machines ---"
$hasCloudFallback = ($mainContent -match '\$btnAdminPushGit\.Add_Click\([\s\S]*?(Push-VUONGTTCloudFile|purge\.jsdelivr\.net|api\.github\.com)')
Assert-Condition -TestName "4.1: btnAdminPushGit supports Cloud REST API push when running standalone" `
    -Condition $hasCloudFallback `
    -Message "Click handler must support direct GitHub Cloud REST API push when local git repo is not present"

# 5. Kiem tra cu phap AST cua cac file lien quan
Write-Host "`n--- Test 5: PowerShell AST Syntax Integrity ---"
$parseErrors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($mainPs1Path, [ref]$tokens, [ref]$parseErrors)
Assert-Condition -TestName "5.1: AST check for VUONGTT_Toolkit.ps1" `
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
