# =========================================================================
#   TEST SUITE: SOFTWARE DOWNLOAD RESILIENCE & DEADLOCK PREVENTION (TDD)
# =========================================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$accountingPath = Join-Path $PSScriptRoot "..\src\Core\AccountingApps.ps1"
$installerPath  = Join-Path $PSScriptRoot "..\src\Core\SoftwareInstaller.ps1"
$toolkitPath    = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"

$passCount = 0
$failCount = 0

function Assert-Condition {
    param([string]$Title, [bool]$Condition)
    if ($Condition) {
        Write-Host "  [PASS] $Title" -ForegroundColor Green
        $script:passCount++
    } else {
        Write-Host "  [FAIL] $Title" -ForegroundColor Red
        $script:failCount++
    }
}

Write-Host "`n>>> BAT DAU KIEM THU TDD: SOFTWARE DOWNLOAD RESILIENCE <<<" -ForegroundColor Cyan

# 1. Kiem tra source code khong con dung Register-ObjectEvent gay deadlock
$acctCode = Get-Content -Raw -Encoding UTF8 $accountingPath
$hasRegisterObjectEvent = ($acctCode -match 'Register-ObjectEvent.*Download')
Assert-Condition "1.1: AccountingApps.ps1 KHONG duoc dung Register-ObjectEvent de tranh deadlock PowerShell" (-not $hasRegisterObjectEvent)

$hasInfiniteWhile = ($acctCode -match 'while\s*\(-not\s*\$script:VUONGTT_DlCompleted\)')
Assert-Condition "1.2: AccountingApps.ps1 KHONG duoc chua while loop vo tan thieu timeout" (-not $hasInfiniteWhile)

# 2. Kiem tra SoftwareInstaller khong con cho 10 phut
$installerCode = Get-Content -Raw -Encoding UTF8 $installerPath
$has10MinWait = ($installerCode -match 'AddMinutes\(10\)')
Assert-Condition "2.1: SoftwareInstaller.ps1 timeout phai toi uu (<= 3 phut thay vi 10 phut)" (-not $has10MinWait)

# 3. Kiem tra ham Invoke-VUONGTTDownloadWithLog xu ly URL chet khong bi treo (Timeout < 10s)
. $accountingPath
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$logMessages = @()
$dlResult = Invoke-VUONGTTDownloadWithLog -Url "https://download.gdt.gov.vn/htkk/HTKK_v5.2.6.zip" -DestPath "$env:TEMP\vuongtt_dead_test.zip" -OnProgress {
    param($m)
    $logMessages += $m
}
$elapsedMs = $sw.ElapsedMilliseconds

Assert-Condition "3.1: Invoke-VUONGTTDownloadWithLog phai thoat trong < 12 giay khi gap link chet (Thuc te: ${elapsedMs}ms)" ($elapsedMs -lt 12000)
Assert-Condition "3.2: Ket qua tra ve phai la `$false khi link loi" ($dlResult -eq $false)

# 4. Kiem tra Install-VUONGTTAccountingApp cho HTKK khong bi treo va chuyen huong trang chu
$sw.Restart()
$htkkResult = Install-VUONGTTAccountingApp -AppId "htkk" -AutoLaunch:$false -OnProgress {
    param($m)
}
$htkkElapsed = $sw.ElapsedMilliseconds

Assert-Condition "4.1: Install-VUONGTTAccountingApp htkk phai ket thuc an toan trong < 15 giay (Thuc te: ${htkkElapsed}ms)" ($htkkElapsed -lt 15000)
Assert-Condition "4.2: htkk phai thong bao chuyen huong trang chu khi may chu cong yeu cau" ($htkkResult -match "trang chủ")

# 5. Kiem tra tong ket bao cao ro rang trong VUONGTT_Toolkit.ps1
$toolkitCode = Get-Content -Raw -Encoding UTF8 $toolkitPath
Assert-Condition "5.1: VUONGTT_Toolkit.ps1 phai thong bao chi tiet so luong cai dat / chuyen huong" ($toolkitCode -match 'Thành công|thành công|Hoàn tất')

Write-Host "`n========================================================"
Write-Host "KET QUA TEST: $passCount PASSED | $failCount FAILED" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================`n"

if ($failCount -gt 0) { exit 1 } else { exit 0 }
