# =========================================================================
# EMPIRICAL CHALLENGE SUITE: BYPASS TPM REGISTRY TEST (MoSetup & LabConfig)
# =========================================================================
$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host "`n>>> EMPIRICAL CHALLENGE: BYPASS TPM REGISTRY VERIFICATION <<<`n" -ForegroundColor Cyan

$opsRsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
Assert-True (Test-Path $opsRsPath) "system_ops.rs phai ton tai"
$opsContent = Get-Content -Path $opsRsPath -Raw -Encoding UTF8

Write-Host "--- Nhom 1: Static Code AST / Lexical Verification in system_ops.rs ---" -ForegroundColor Yellow

# 1.1 Kiem tra route bypass_tpm
Assert-True ($opsContent -match 'if\s+act\s*==\s*"bypass_tpm"') "system_ops.rs phai co handler cho action bypass_tpm"

# 1.2 Kiem tra ghi vao ca 2 duong dan HKLM:\SYSTEM\Setup\MoSetup va LabConfig
Assert-True ($opsContent -match 'HKLM:\\SYSTEM\\Setup\\MoSetup' -and $opsContent -match 'HKLM:\\SYSTEM\\Setup\\LabConfig') "bypass_tpm phai ghi vao ca 2 registry hive: MoSetup va LabConfig"

# 1.3 Kiem tra gia tri MoSetup: AllowUpgradesWithUnsupportedTPMOrCPU = 1
Assert-True ($opsContent -match 'AllowUpgradesWithUnsupportedTPMOrCPU.*-Value\s+1') "MoSetup phai set AllowUpgradesWithUnsupportedTPMOrCPU = 1"

# 1.4 Kiem tra cac gia tri LabConfig: BypassTPMCheck, BypassSecureBootCheck, BypassRAMCheck, BypassStorageCheck, BypassCPUCheck
Assert-True ($opsContent -match 'BypassTPMCheck.*-Value\s+1') "LabConfig phai set BypassTPMCheck = 1"
Assert-True ($opsContent -match 'BypassSecureBootCheck.*-Value\s+1') "LabConfig phai set BypassSecureBootCheck = 1"
Assert-True ($opsContent -match 'BypassRAMCheck.*-Value\s+1') "LabConfig phai set BypassRAMCheck = 1"
Assert-True ($opsContent -match 'BypassStorageCheck.*-Value\s+1') "LabConfig phai set BypassStorageCheck = 1"
Assert-True ($opsContent -match 'BypassCPUCheck.*-Value\s+1') "LabConfig phai set BypassCPUCheck = 1"

Write-Host "`n--- Nhom 2: Dynamic Execution Oracle (Mock Hive Execution) ---" -ForegroundColor Yellow

# Extract exact command string from bypass_tpm handler in system_ops.rs
$lines = $opsContent -split "`r?`n"
$cmdLine = $lines | Where-Object { $_ -match 'AllowUpgradesWithUnsupportedTPMOrCPU' -and $_ -match 'BypassTPMCheck' } | Select-Object -First 1
Assert-True ($null -ne $cmdLine) "Tim thay dong lenh PowerShell bypass trong system_ops.rs"

$rawCmd = $cmdLine.Trim().TrimStart('"').TrimEnd('",').TrimEnd('"')
# Unescape Rust double backslashes to single backslashes
$rawCmd = $rawCmd.Replace('\\', '\')
Write-Host "  Extracted Command: $rawCmd" -ForegroundColor Gray

# Transform HKLM:\SYSTEM\Setup to HKCU:\Software\VuongttTestBypass for sandbox verification
$sandboxCmd = $rawCmd -replace 'HKLM:\\SYSTEM\\Setup', 'HKCU:\Software\VuongttTestBypass'

$testBasePath = "HKCU:\Software\VuongttTestBypass"
if (Test-Path $testBasePath) {
    Remove-Item -Path $testBasePath -Recurse -Force
}

# Execute the exact command via PowerShell child process
Write-Host "  >> Dang thuc thi lenh bypass tren test registry sandbox..." -ForegroundColor Cyan
$proc = Start-Process powershell.exe -ArgumentList @("-NoProfile", "-Command", $sandboxCmd) -Wait -PassThru -NoNewWindow
Assert-True ($proc.ExitCode -eq 0) "Lenh PowerShell bypass phai thuc thi khong loi (ExitCode: 0)"

# Verify MoSetup in sandbox
$moSetupPath = "$testBasePath\MoSetup"
Assert-True (Test-Path $moSetupPath) "Khoa MoSetup phai duoc tao thanh cong"
$moProp = Get-ItemProperty -Path $moSetupPath
Assert-True ($moProp.AllowUpgradesWithUnsupportedTPMOrCPU -eq 1) "AllowUpgradesWithUnsupportedTPMOrCPU phai bang 1"

# Verify LabConfig in sandbox
$labConfigPath = "$testBasePath\LabConfig"
Assert-True (Test-Path $labConfigPath) "Khoa LabConfig phai duoc tao thanh cong"
$labProp = Get-ItemProperty -Path $labConfigPath
Assert-True ($labProp.BypassTPMCheck -eq 1) "BypassTPMCheck phai bang 1"
Assert-True ($labProp.BypassSecureBootCheck -eq 1) "BypassSecureBootCheck phai bang 1"
Assert-True ($labProp.BypassRAMCheck -eq 1) "BypassRAMCheck phai bang 1"
Assert-True ($labProp.BypassStorageCheck -eq 1) "BypassStorageCheck phai bang 1"
Assert-True ($labProp.BypassCPUCheck -eq 1) "BypassCPUCheck phai bang 1"

# Cleanup sandbox
Remove-Item -Path $testBasePath -Recurse -Force
Write-Host "  >> Da don dep sandbox test registry." -ForegroundColor Gray

Write-Host "`n--- Nhom 3: Unit Test Integration in Rust Backend ---" -ForegroundColor Yellow
Assert-True ($opsContent -match 'fn\s+test_system_ops_bypass_tpm_execution') "system_ops.rs phai co test_system_ops_bypass_tpm_execution"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "TAT CA TEST EMPIRICAL BYPASS TPM (MoSetup & LabConfig) PASSED!" -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green
