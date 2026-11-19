# =========================================================================
# TDD TEST SUITE: WIN DEPLOY UI VISIBILITY & EULA ACCEPT FIX
# tests/Test-WinDeployUiVisibilityAndEulaFix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN DEPLOY UI VISIBILITY & /eula accept FIX        " -ForegroundColor Yellow -BackgroundColor Black
Write-Host "======================================================================" -ForegroundColor Cyan

$passedCount = 0
$failedCount = 0

function Assert-Test([string]$desc, [scriptblock]$condition) {
    try {
        $result = & $condition
        if ($result) {
            Write-Host " [PASS] $desc" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host " [FAIL] $desc" -ForegroundColor Red
            $script:failedCount++
        }
    } catch {
        Write-Host " [FAIL] $desc - Exception: $($_.Exception.Message)" -ForegroundColor Red
        $script:failedCount++
    }
}

$opsContent = if (Test-Path $opsRs) { Get-Content -Path $opsRs -Raw -Encoding UTF8 } else { "" }

# 1. /auto phai di kem /eula accept de tranh loi MOSETUP_E_EULA_ACCEPT_REQUIRED khien setup tu thoat
Assert-Test "1. Lenh /auto phai co tham so /eula accept de tranh loi MOSETUP_E_EULA_ACCEPT_REQUIRED" {
    $opsContent -match '/auto clean.*\/eula accept' -and $opsContent -match '/auto upgrade.*\/eula accept'
}

# 2. Lenh setup phai kem /product server de bypass TPM 2.0 / CPU check goc tu Microsoft
Assert-Test "2. Lenh setup phai kem /product server de bypass TPM/CPU tren tat ca cac che do" {
    $opsContent -match '\/product server'
}

# 3. Start-Process khong duoc dung -WindowStyle Hidden (phai hien thi cua so Windows Setup cho nguoi dung)
Assert-Test "3. Start-Process khong duoc dung -WindowStyle Hidden gay an cua so setup tren man hinh" {
    $opsContent -notmatch 'Start-Process.*cmd\.exe.*-WindowStyle Hidden'
}

# 4. Phai gan mount point cho EFI partition qua mountvol S: /S de chong triet de 0x80070490
Assert-Test "4. Phai gan mount point EFI partition qua mountvol S: /S" {
    $opsContent -match 'mountvol S: \/S'
}

# 5. Phai escape `$WINDOWS.~BT trong PowerShell double quote string de tranh bien $WINDOWS rong
Assert-Test "5. Phai escape literal dollar cho `$WINDOWS.~BT trong PowerShell string" {
    $opsContent -match '`\$WINDOWS\.~BT'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
