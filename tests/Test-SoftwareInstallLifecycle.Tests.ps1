# Test-SoftwareInstallLifecycle.Tests.ps1
# Test suite for software installation lifecycle, safe AppX launch, and anti-premature termination

$ErrorActionPreference = "Stop"

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
    } else {
        Write-Host ("  [FAIL] " + $TestName + " - " + $Message) -ForegroundColor Red
        throw ("Assertion failed: " + $TestName + " - " + $Message)
    }
}

Write-Host "=== TEST SUITE: SOFTWARE INSTALLATION & WINDOW LIFECYCLE ===" -ForegroundColor Cyan

# Test 1: SoftwareInstaller contains AppExecutionMap for files
Write-Host "`n--- Test 1: SoftwareInstaller App Execution Map & AppX Support ---"
$installerContent = Get-Content "src/Core/SoftwareInstaller.ps1" -Raw -Encoding UTF8
Assert-Condition -TestName "1.1: APP_EXEC_MAP includes 'files'" `
    -Condition ($installerContent -match '["'']files["'']\s*=') `
    -Message "APP_EXEC_MAP should contain an entry for 'files'"

Assert-Condition -TestName "1.2: Start-VUONGTTInstalledApp has AppX/UWP shell launcher" `
    -Condition ($installerContent -match 'shell:AppsFolder' -or $installerContent -match 'files-uwp:') `
    -Message "Start-VUONGTTInstalledApp should have logic to launch AppX/UWP apps safely via shell:AppsFolder or protocol"

Assert-Condition -TestName "1.3: Start-VUONGTTInstalledApp routes WindowsApps alias via explorer.exe" `
    -Condition ($installerContent -match 'WindowsApps') `
    -Message "Start-VUONGTTInstalledApp should route WindowsApps execution aliases through explorer.exe to prevent elevation crash"

# Test 2: Winget silent install includes disable-interactivity
Write-Host "`n--- Test 2: Winget Install Parameters ---"
Assert-Condition -TestName "2.1: Winget argument includes --disable-interactivity" `
    -Condition ($installerContent -match '--disable-interactivity') `
    -Message "Winget install command should include --disable-interactivity"

# Test 3: VUONGTT_Toolkit.ps1 Window Lifecycle Protection
Write-Host "`n--- Test 3: VUONGTT_Toolkit Window Lifecycle Protection ---"
$toolkitContent = Get-Content "VUONGTT_Toolkit.ps1" -Raw -Encoding UTF8

Assert-Condition -TestName "3.1: Root window uses Dispatcher::Run or protected event loop" `
    -Condition ($toolkitContent -match '\[System\.Windows\.Threading\.Dispatcher\]::Run\(\)' -or $toolkitContent -match '\$window\.Add_Closed') `
    -Message "Root window should use robust Dispatcher::Run and Add_Closed instead of naked ShowDialog"

Assert-Condition -TestName "3.2: Software install completion MessageBox uses $window owner or safe try-catch" `
    -Condition ($toolkitContent -match 'MessageBox\]::Show\(\s*\$window' -or $toolkitContent -match '\$window\.Activate\(\)') `
    -Message "Software install completion MessageBox should be properly owned by `$window or followed by `$window.Activate()"

# Test 4: AST syntax verification of modified files
Write-Host "`n--- Test 4: PowerShell AST Syntax Integrity ---"
$filesToParse = @("src/Core/SoftwareInstaller.ps1", "VUONGTT_Toolkit.ps1")
foreach ($f in $filesToParse) {
    $parseErrors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$parseErrors)
    Assert-Condition -TestName "4.x AST check for $f" `
        -Condition ($parseErrors.Count -eq 0) `
        -Message ("AST parse errors in " + $f)
}

Write-Host "`n=== ALL SOFTWARE INSTALL LIFECYCLE TESTS PASSED ===`n" -ForegroundColor Green
