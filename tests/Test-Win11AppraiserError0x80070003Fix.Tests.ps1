# =========================================================================
# TDD TEST SUITE: WIN 11 DEPLOY APPRAISER ERROR 0x80070003 - 0x40008 FIX
# tests/Test-Win11AppraiserError0x80070003Fix.Tests.ps1
# =========================================================================

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$opsRs = Join-Path $repoRoot "src-tauri\src\system_ops.rs"

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN 11 APPRAISER ERROR 0x80070003 - 0x40008 FIX     " -ForegroundColor Yellow -BackgroundColor Black
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

# 1. system_ops.rs ton tai
Assert-Test "1. File system_ops.rs ton tai va doc duoc" {
    Test-Path $opsRs
}

# 2. Phai chu dong unmount o EFI S: (mountvol S: /D) trong ps_clean_and_prep va ngay sau bcdboot
Assert-Test "2. Phai chu dong go mount point S: (mountvol S: /D) de tranh xung dot phan vung EFI 0x80070003" {
    $opsContent -match 'mountvol S: /D'
}

# 3. Phai tao tep appraiserres.dll 0-byte vao $WINDOWS.~BT\Sources de triet tieu hardware appraisal engine
Assert-Test "3. Phai tao tep appraiserres.dll 0-byte vao $stagingDir\Sources de triet tieu hardware appraisal" {
    $opsContent -match 'appraiserres\.dll'
}

# 4. Thu muc lam viec $workDir phai la root $drv cua ISO
Assert-Test "4. Thu muc lam viec $workDir phai la root $drv thay vi Split-Path $setupExe -Parent" {
    $opsContent -match '\$workDir\s*=\s*\$drv'
}

# 5. Che do clean va custom phai chua co /compat ignorewarning
Assert-Test "5. Che do clean va custom phai chua co /compat ignorewarning" {
    $opsContent -match '/compat ignorewarning /DynamicUpdate disable /tempdrive'
}

# 6. Runtime setup_args khong duoc chua /product server
Assert-Test "6. Runtime setup_args khong chua /product server (tranh loi Invalid Command Line Argument tren Win 11)" {
    (-not ($opsContent -match 'format!\("[^"]*\/product server[^"]*"'))
}

# 7. Registry LabConfig va MoSetup phai duoc cau hinh day du
Assert-Test "7. Registry LabConfig va MoSetup phai cau hinh du cac khoa bypass TPM, CPU, SecureBoot, RAM, Storage" {
    ($opsContent -match 'BypassTPMCheck') -and 
    ($opsContent -match 'BypassSecureBootCheck') -and 
    ($opsContent -match 'BypassCPUCheck') -and 
    ($opsContent -match 'BypassRAMCheck') -and 
    ($opsContent -match 'BypassStorageCheck') -and 
    ($opsContent -match 'AllowUpgradesWithUnsupportedTPMOrCPU')
}

Write-Host "----------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host " KET QUA: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================`n" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    exit 1
} else {
    exit 0
}
