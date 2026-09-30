# ==============================================================================
# TDD Test Suite: Real Execution & Live Diagnostics for IT Helpdesk Engine
# File: tests/Test-TroubleshootRealExecution.Tests.ps1
# ==============================================================================

$ErrorActionPreference = "Stop"
$managerPath = "$PSScriptRoot\..\src\Core\TroubleshootManager.ps1"
if (-not (Test-Path $managerPath)) {
    Write-Error "Khong tim thay ma nguon TroubleshootManager.ps1 tai $managerPath"
    exit 1
}

. $managerPath

$testPassed = 0
$testFailed = 0

function Assert-Check {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$FailureMessage
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $script:testPassed++
    } else {
        Write-Host "  [FAIL] $($TestName): $FailureMessage" -ForegroundColor Red
        $script:testFailed++
    }
}

Write-Host "`n=== BAT DAU KIEM THU TDD: THUC THI CHAN DOAN & SUA LOI THUC TE ===" -ForegroundColor Cyan

# 1. Khoi tao Engine
$init = Initialize-VUONGTTTroubleshootEngine
Assert-Check "Engine khoi tao thanh cong" ($init -eq $true) "Engine khong the khoi tao"

# 2. Test PERF-012 (CPU Spike / TiWorker)
Write-Host "`n--- Test PERF-012 (CPU Tang bat thuong / TiWorker) ---" -ForegroundColor Yellow
$cpuDiag = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-012" -ActionType "Diagnosis"
Assert-Check "PERF-012 Diagnosis co ket qua" ($null -ne $cpuDiag -and $cpuDiag.ContainsKey("OutputDetails")) "Khong co OutputDetails"
Assert-Check "PERF-012 Diagnosis KHONG chua chuoi placeholder 'Test-VUONGTTPERF_012'" `
    ($cpuDiag.OutputDetails -notmatch "Test-VUONGTTPERF_012") `
    "OutputDetails van con chuoi placeholder 'Test-VUONGTTPERF_012'"

Assert-Check "PERF-012 Diagnosis chua thong so CPU Load (%) hoac danh sach tien trinh thuc te" `
    ($cpuDiag.OutputDetails -match "Load|CPU.*%|%|TiWorker|TrustedInstaller|Process") `
    "OutputDetails khong chua thong tin CPU/Tien trinh thuc te"

$cpuFix = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-012" -ActionType "Fix"
Assert-Check "PERF-012 Fix KHONG chua chuoi placeholder 'Invoke-VUONGTTRestartTiWorker'" `
    ($cpuFix.OutputDetails -notmatch "Invoke-VUONGTTRestartTiWorker") `
    "OutputDetails van con chuoi placeholder 'Invoke-VUONGTTRestartTiWorker'"
Assert-Check "PERF-012 Fix thuc thi thanh cong" ($cpuFix.Success -eq $true) "PERF-012 Fix bao that bai"

$cpuVerify = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-012" -ActionType "Verify"
Assert-Check "PERF-012 Verify KHONG chua chuoi placeholder 'Test-VUONGTTVerifyPERF_012'" `
    ($cpuVerify.OutputDetails -notmatch "Test-VUONGTTVerifyPERF_012") `
    "OutputDetails van con chuoi placeholder 'Test-VUONGTTVerifyPERF_012'"

# 3. Test PERF-010 / PERF-013 (RAM 100% / Memory Leak)
Write-Host "`n--- Test PERF-010 (RAM 100% / Memory Leak) ---" -ForegroundColor Yellow
$ramDiag = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-010" -ActionType "Diagnosis"
Assert-Check "PERF-010 Diagnosis KHONG chua chuoi placeholder 'Test-VUONGTTPERF_010'" `
    ($ramDiag.OutputDetails -notmatch "Test-VUONGTTPERF_010") `
    "OutputDetails van con chuoi placeholder 'Test-VUONGTTPERF_010'"

$ramFix = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-010" -ActionType "Fix"
Assert-Check "PERF-010 Fix KHONG chua chuoi placeholder 'Invoke-VUONGTTClearMemoryCache'" `
    ($ramFix.OutputDetails -notmatch "Invoke-VUONGTTClearMemoryCache") `
    "OutputDetails van con chuoi placeholder 'Invoke-VUONGTTClearMemoryCache'"

# 4. Test AUDIO-001 (Audio Service)
Write-Host "`n--- Test AUDIO-001 (Mat tieng / Audio Service) ---" -ForegroundColor Yellow
$audioDiag = Invoke-VUONGTTTroubleshootAction -ProblemId "AUDIO-001" -ActionType "Diagnosis"
Assert-Check "AUDIO-001 Diagnosis kiem tra trang thai Audiosrv thuc te" `
    ($audioDiag.OutputDetails -match "Audiosrv|AudioEndpointBuilder|Audio|Service|Dich vu") `
    "AUDIO-001 Diagnosis khong kiem tra dich vu am thanh thuc te"
Assert-Check "AUDIO-001 Diagnosis KHONG chua chuoi placeholder 'Test-VUONGTTAUDIO_001'" `
    ($audioDiag.OutputDetails -notmatch "Test-VUONGTTAUDIO_001") `
    "OutputDetails van con chuoi placeholder 'Test-VUONGTTAUDIO_001'"

# 5. Test Generic Problem Fallback (PERF-001) phai co telemetries thuc te
Write-Host "`n--- Test Generic Fallback: PERF-001 (May cham) ---" -ForegroundColor Yellow
$genDiag = Invoke-VUONGTTTroubleshootAction -ProblemId "PERF-001" -ActionType "Diagnosis"
Assert-Check "PERF-001 Diagnosis KHONG chua text mau gia lap 'Test-VUONGTTPERF_001'" `
    ($genDiag.OutputDetails -notmatch "Test-VUONGTTPERF_001") `
    "PERF-001 van chua text mau gia lap"

Assert-Check "PERF-001 Diagnosis chua thong so Telemetry thuc te cua he thong" `
    ($genDiag.OutputDetails -match "CPU|RAM|Disk|Uptime|Event") `
    "PERF-001 Diagnosis khong chua thong so Telemetry thuc te"

Write-Host "`n=== KET QUA KIEM THU TDD ===" -ForegroundColor Cyan
Write-Host "Passed: $testPassed, Failed: $testFailed"

if ($testFailed -gt 0) {
    Write-Host "[XAC NHAN THAT BAI TRUOC KHI IMPLEMENT (TDD REQUIREMENT SATISFIED)]" -ForegroundColor Magenta
    exit 1
} else {
    Write-Host "[TAT CA TEST DEU PASS]" -ForegroundColor Green
    exit 0
}
