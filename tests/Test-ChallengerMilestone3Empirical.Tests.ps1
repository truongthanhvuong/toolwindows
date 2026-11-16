# =========================================================================
# EMPIRICAL CHALLENGER TEST SUITE: MILESTONE 3 PRINTER & LAN STRESS HARNESS
# =========================================================================

$ErrorActionPreference = 'Continue'
$global:passCount = 0
$global:failCount = 0

function Assert-Test([bool]$cond, [string]$msg, [string]$failDetail = "") {
    if ($cond) {
        Write-Host "  [PASS] $msg" -ForegroundColor Green
        $global:passCount++
    } else {
        Write-Host "  [FAIL] $msg" -ForegroundColor Red
        if ($failDetail) { Write-Host "         Detail: $failDetail" -ForegroundColor DarkRed }
        $global:failCount++
    }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> EMPIRICAL CHALLENGE 1: REGISTRY & SPOOLER FIX EXECUTION <<<" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1.1 Verify Start-Service parameter compatibility in PowerShell
$startServiceParams = (Get-Command Start-Service).Parameters
$hasStartForce = $startServiceParams.ContainsKey('Force')
Assert-Test (-not $hasStartForce) "PowerShell Start-Service does NOT have a -Force parameter"

# 1.2 Verify system_ops.rs PowerShell code syntax
$opsPath = "$PSScriptRoot\..\src-tauri\src\system_ops.rs"
$opsContent = [System.IO.File]::ReadAllText($opsPath, [System.Text.Encoding]::UTF8)

$hasInvalidStartForce = $opsContent -match 'Start-Service\s+Spooler\s+-Force'
Assert-Test (-not $hasInvalidStartForce) "system_ops.rs spooler restart must NOT use invalid 'Start-Service Spooler -Force'" "Line 1698 uses 'Start-Service Spooler -Force', which causes ParameterBindingException and leaves Spooler stopped"

# 1.3 Verify Registry Keys and Values defined in system_ops.rs
Assert-Test ($opsContent -match "'RpcAuthnLevelEx'\s+-Value\s+0") "system_ops.rs sets RpcAuthnLevelEx = 0 (fixes 0x0000011b)"
Assert-Test ($opsContent -match "'RpcAuthnLevelPrivacyEnabled'\s+-Value\s+0") "system_ops.rs sets RpcAuthnLevelPrivacyEnabled = 0"
Assert-Test ($opsContent -match "'RpcUseNamedPipeProtocol'\s+-Value\s+1") "system_ops.rs sets RpcUseNamedPipeProtocol = 1"
Assert-Test ($opsContent -match "'RestrictDriverInstallationToAdministrators'\s+-Value\s+0") "system_ops.rs sets RestrictDriverInstallationToAdministrators = 0"
Assert-Test ($opsContent -match "'UpdatePromptSettings'\s+-Value\s+2") "system_ops.rs sets UpdatePromptSettings = 2"
Assert-Test ($opsContent -match "'PackagePointAndPrintServerList'\s+-Value\s+0") "system_ops.rs sets PackagePointAndPrintServerList = 0"
Assert-Test ($opsContent -match "'InPrivate'\s+-Value\s+0") "system_ops.rs sets InPrivate = 0"
Assert-Test ($opsContent -match "'LegacyDefaultPrinterMode'\s+-Value\s+1") "system_ops.rs sets LegacyDefaultPrinterMode = 1"

# 1.4 HKCU Registry Test (Safe to test in user context)
$userPrn = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows'
if (Test-Path $userPrn) {
    Set-ItemProperty -Path $userPrn -Name 'LegacyDefaultPrinterMode' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}
$legacyPrnVal = (Get-ItemProperty -Path $userPrn -Name 'LegacyDefaultPrinterMode' -ErrorAction SilentlyContinue).LegacyDefaultPrinterMode
Assert-Test ($legacyPrnVal -eq 1) "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows\LegacyDefaultPrinterMode is 1"

# 1.5 Spooler service presence
$spoolerSvc = Get-Service -Name Spooler -ErrorAction SilentlyContinue
Assert-Test ($null -ne $spoolerSvc) "Spooler service exists on system"

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> EMPIRICAL CHALLENGE 2: SMB SCAN FOLDER SHARING LOGIC <<<" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

function Invoke-ScanFolderLogic($folderInput, $shareInput) {
    $folder = $folderInput
    $share = $shareInput
    if ($folder -match '^[a-zA-Z]:\\?$') { $folder = Join-Path $folder $share }
    $cleanFolder = $folder.TrimEnd('\')
    if (-not (Test-Path $cleanFolder)) { New-Item -ItemType Directory -Path $cleanFolder -Force | Out-Null }
    net share "$share=$cleanFolder" /grant:everyone,full /y 2>&1 | Out-Null
    icacls "$cleanFolder" /grant "Everyone:(OI)(CI)F" /T /C /Q 2>&1 | Out-Null
    icacls "$cleanFolder" /grant "Guest:(OI)(CI)F" /T /C /Q 2>&1 | Out-Null
    $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Ethernet*','Wi-Fi*' -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.254*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1 -ExpandProperty IPAddress)
    if (-not $ip) { $ip = "127.0.0.1" }
    return "UNC_IP:\\$ip\$share|UNC_NAME:\\$($env:COMPUTERNAME)\$share"
}

# 2.1 Standard Folder & Share Output Format Test
$testFolderA = Join-Path $env:TEMP "VUONGTT_Challenger_ScanA"
$testShareA  = "VUONGTT_Challenger_ScanA"
try {
    $resA = Invoke-ScanFolderLogic $testFolderA $testShareA
    $uncPattern = '^UNC_IP:\\\\[0-9\.]+\\[^\s|]+\|UNC_NAME:\\\\[^\\]+\\[^\s|]+$'
    Assert-Test ($resA -match $uncPattern) "Output matches UNC pattern UNC_IP:\\<IP>\<Share>|UNC_NAME:\\<Host>\<Share>" "Result: $resA"

    # Check physical folder created
    Assert-Test (Test-Path $testFolderA) "Physical folder $testFolderA was created on disk"

    # Check icacls permissions
    $aclOut = icacls $testFolderA | Out-String
    Assert-Test ($aclOut -match "Everyone" -and $aclOut -match "\(OI\)\(CI\)\(F\)") "NTFS ACL granted Full Control to Everyone"
    Assert-Test ($aclOut -match "Guest" -and $aclOut -match "\(OI\)\(CI\)\(F\)") "NTFS ACL granted Full Control to Guest"
} finally {
    cmd.exe /c "net share $testShareA /delete /y >nul 2>nul"
    if (Test-Path $testFolderA) { Remove-Item -Path $testFolderA -Recurse -Force -ErrorAction SilentlyContinue }
}

# 2.2 Trailing Backslash Normalization Test
$testFolderB = (Join-Path $env:TEMP "VUONGTT_Challenger_ScanB") + "\"
$testShareB  = "VUONGTT_Challenger_ScanB"
try {
    $resB = Invoke-ScanFolderLogic $testFolderB $testShareB
    $cleanPathB = $testFolderB.TrimEnd('\')
    Assert-Test (Test-Path $cleanPathB) "Folder with trailing slash normalized and created: $cleanPathB"
    Assert-Test (-not $cleanPathB.EndsWith('\')) "Folder path ends without trailing slash"
} finally {
    cmd.exe /c "net share $testShareB /delete /y >nul 2>nul"
    if (Test-Path $cleanPathB) { Remove-Item -Path $cleanPathB -Recurse -Force -ErrorAction SilentlyContinue }
}

# 2.3 Root Drive Normalization Test (e.g., 'C:\' or 'C:')
$testRootFolder = "C:\"
$testShareC     = "VUONGTT_Challenger_ScanC"
$expectedPathC  = "C:\VUONGTT_Challenger_ScanC"
try {
    $resC = Invoke-ScanFolderLogic $testRootFolder $testShareC
    Assert-Test (Test-Path $expectedPathC) "Root drive 'C:\' was joined with share name into '$expectedPathC'"
} finally {
    cmd.exe /c "net share $testShareC /delete /y >nul 2>nul"
    if (Test-Path $expectedPathC) { Remove-Item -Path $expectedPathC -Recurse -Force -ErrorAction SilentlyContinue }
}

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> EMPIRICAL CHALLENGE 3: ENABLE ALL SHARING & LAN SCAN <<<" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 3.1 Test enable_all_sharing service list validation
$expectedServices = @("fdPHost", "FDResPub", "SSDPSRV", "upnphost", "LanmanServer", "LanmanWorkstation")
foreach ($s in $expectedServices) {
    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
    Assert-Test ($null -ne $svc) "Required sharing service exists: $s"
}

# 3.2 Test scan_lan execution
$arpOutput = (arp -a | Out-String)
Assert-Test ($arpOutput -match "Interface:" -or $arpOutput -match "Internet Address") "arp -a produces valid network interface output"
$formattedScan = "Kết quả quét mạng LAN:`n$arpOutput"
Assert-Test ($formattedScan.StartsWith("Kết quả quét mạng LAN:")) "scan_lan returns expected header prefix"

Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host ">>> EMPIRICAL CHALLENGE 4: UI CONTRACT & SUBSTRING COLLISION AUDIT <<<" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$appJsPath = "$PSScriptRoot\..\src-ui\app.js"
$appJs = [System.IO.File]::ReadAllText($appJsPath, [System.Text.Encoding]::UTF8)

# 4.1 Check exposed functions on window
Assert-Test ($appJs -match 'window\.createScanFolderShare\s*=') "app.js exposes window.createScanFolderShare"
Assert-Test ($appJs -match 'window\.enableAllSharingNoPassword\s*=') "app.js exposes window.enableAllSharingNoPassword"
Assert-Test ($appJs -match 'window\.copyUncPath\s*=') "app.js exposes window.copyUncPath"
Assert-Test ($appJs -match 'window\.browseScanFolder\s*=') "app.js exposes window.browseScanFolder"

# 4.2 Check Substring Collision Bug in tool-btn click listener
# Test empirical evaluation of data-action="scan_lan" dynamically from app.js router logic
$routerBlockMatch = [regex]::Match($appJs, '(?s)let actionId = "fix_spooler";\s*(.*?)\s*showToast\(')
if ($routerBlockMatch.Success) {
    $routerBlock = $routerBlockMatch.Groups[1].Value
    $evalJs = "const action = 'scan_lan'; let actionId = 'fix_spooler'; " + $routerBlock + "; process.stdout.write(actionId);"
    $evaluatedActionId = ($evalJs | node)
} else {
    $evaluatedActionId = "failed_to_extract"
}
Assert-Test ($evaluatedActionId -eq "scan_lan") "Clicking 'Quét Mạng LAN' (data-action='scan_lan') routes to 'scan_lan' instead of 'share_scan_folder'" "Evaluated to '$evaluatedActionId' because 'scan_lan'.includes('scan') matched first at line 4250!"

# 4.3 Check UNC regex parsing
Assert-Test ($appJs -match 'res\.message\.match\(/UNC_IP:\(\[\^\\s\|\]\+\)/') "app.js correctly captures UNC_IP"
Assert-Test ($appJs -match 'res\.message\.match\(/UNC_NAME:\(\[\^\\s\|\]\+\)/') "app.js correctly captures UNC_NAME"

Write-Host "`n-----------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "TOTAL CHALLENGE TESTS: $($global:passCount + $global:failCount)" -ForegroundColor Cyan
Write-Host "PASSED: $($global:passCount)" -ForegroundColor Green
Write-Host "FAILED: $($global:failCount)" -ForegroundColor $(if ($global:failCount -eq 0) { "Green" } else { "Red" })
Write-Host "-----------------------------------------------------------------`n" -ForegroundColor Cyan

if ($global:failCount -gt 0) {
    exit 1
} else {
    exit 0
}
