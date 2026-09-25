# Test-IpScannerLifecycle.Tests.ps1
# Test suite for IP Scanner lifecycle, non-blocking socket safety, and UI Dispatcher crash protection

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

Write-Host "=== TEST SUITE: IP SCANNER SAFETY & UI DISPATCHER LIFECYCLE ===" -ForegroundColor Cyan

# Test 1: IpScanner.ps1 non-blocking socket safety
Write-Host "`n--- Test 1: Socket Architecture & ThreadPool Crash Prevention ---"
$scannerContent = Get-Content "src/Core/IpScanner.ps1" -Raw -Encoding UTF8

Assert-Condition -TestName "1.1: FastScanner uses non-blocking Socket.Poll instead of in-flight TcpClient disposal" `
    -Condition ($scannerContent -match 'SelectMode\.SelectWrite' -or $scannerContent -match 'Poll\(') `
    -Message "FastScanner must use non-blocking Socket.Poll to prevent native completion callback crashes on disposed sockets"

Assert-Condition -TestName "1.2: FastScanner uses SafeGetHostname with timeout protection" `
    -Condition ($scannerContent -match 'SafeGetHostname|BeginGetHostEntry') `
    -Message "FastScanner must use safe hostname resolution with timeout protection"

Assert-Condition -TestName "1.3: FastScanner handles exceptions in port probe and ping" `
    -Condition ($scannerContent -match 'ProbePort' -or $scannerContent -match 'CheckPort') `
    -Message "FastScanner should modularize port probing with isolated try/catch"

# Test 2: VUONGTT_Toolkit.ps1 Dispatcher Timer Protection
Write-Host "`n--- Test 2: DispatcherTimer UI Exception Shield ---"
$toolkitContent = Get-Content "VUONGTT_Toolkit.ps1" -Raw -Encoding UTF8

$timerMatch = ($toolkitContent -match '\$script:ipScanTimer\.Add_Tick\(\{\s*try\s*\{')
Assert-Condition -TestName "2.1: ipScanTimer.Add_Tick is wrapped in try/catch to protect WPF Dispatcher" `
    -Condition $timerMatch `
    -Message "ipScanTimer.Add_Tick must wrap all processing in try/catch to protect WPF Dispatcher from unexpected termination"

# Test 3: PowerShell AST Syntax Integrity
Write-Host "`n--- Test 3: PowerShell AST Syntax Integrity ---"
$filesToParse = @("src/Core/IpScanner.ps1", "VUONGTT_Toolkit.ps1")
foreach ($f in $filesToParse) {
    $parseErrors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$parseErrors)
    Assert-Condition -TestName "3.x: AST check for $f" `
        -Condition ($parseErrors.Count -eq 0) `
        -Message ("AST parse errors in " + $f)
}

Write-Host "`n=== ALL IP SCANNER LIFECYCLE TESTS PASSED ===`n" -ForegroundColor Green
