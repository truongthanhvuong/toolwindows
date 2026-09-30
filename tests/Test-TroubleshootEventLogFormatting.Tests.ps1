# tests/Test-TroubleshootEventLogFormatting.Tests.ps1
# Kiem thu dinh dang ro rang, khong gay hieu nham cua nhat ky chan doan Troubleshoot

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$PSScriptRoot\..\src\Core\TroubleshootManager.ps1"

$testsRun = 0
$testsPassed = 0
$testsFailed = 0

function Assert-Check {
    param([string]$name, [bool]$cond, [string]$failMsg = "")
    $script:testsRun++
    if ($cond) {
        $script:testsPassed++
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        $script:testsFailed++
        Write-Host "  [FAIL] $name - $failMsg" -ForegroundColor Red
    }
}

Write-Host "=== KIEM THU TDD: CLARITY & CONTEXT CHO CHAN DOAN EVENT LOG ===" -ForegroundColor Cyan

# 1. Khoi tao Engine
$init = Initialize-VUONGTTTroubleshootEngine
Assert-Check "1. Engine khoi tao thanh cong" ($init -eq $true) "Engine khong khoi tao duoc"

# 2. Chay chan doan tong the voi SYS-001
$diag = Invoke-VUONGTTTroubleshootAction -ProblemId "SYS-001" -ActionType "Diagnosis"
Assert-Check "2. Diagnosis co ket qua" ($null -ne $diag -and $diag.ContainsKey("OutputDetails")) "Khong co OutputDetails"

# 3. Phai co ghi chu ro rang ve Event Log he dieu hanh de tranh hieu nham loi tool
Assert-Check "3. OutputDetails phai co ghi chu ro rang ve Event Log Windows (khong gay hieu nham loi tool)" `
    (($diag.OutputDetails -match "Windows Event Log") -and ($diag.OutputDetails -match "KH.NG PH.I")) `
    "Thieu ghi chu phan biet Event Log he dieu hanh de tranh nguoi dung hieu nham tool bi loi"

# 4. Phai co dong ket luan ro rang ve tinh trang tool va he thong
Assert-Check "4. OutputDetails phai co dong ket luan ro rang ve tinh trang tool va he thong" `
    ($diag.OutputDetails -match "VUONGTT Toolkit.*b.nh th..ng|VUONGTT Toolkit.*s.n s.ng") `
    "Thieu dong ket luan chan doan ro rang"

# 5. Khong chua chuoi do dang 'due to the following error:'
Assert-Check "5. OutputDetails khong chua chuoi ket thuc do dang 'due to the following error:'" `
    ($diag.OutputDetails -notmatch "due to the following error:\s*$") `
    "Thong diep bi cat do dang o 'due to the following error:'"

Write-Host "`n=== TONG KET: $testsPassed/$testsRun PASSED ($testsFailed FAILED) ==="
if ($testsFailed -gt 0) { exit 1 } else { exit 0 }
