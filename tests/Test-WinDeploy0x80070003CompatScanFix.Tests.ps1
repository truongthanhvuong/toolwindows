# =========================================================================
#   TDD TEST SUITE: WIN DEPLOY 0x80070003 - 0x40008 COMPAT SCAN ROOT FIX
# =========================================================================
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
if (-not $RootDir) { $RootDir = "E:\toolwindows" }
$systemOpsPath = Join-Path $RootDir "src-tauri\src\system_ops.rs"

$passedCount = 0
$failedCount = 0

function Assert-Test {
    param(
        [string]$Description,
        [scriptblock]$TestBlock
    )
    try {
        $result = & $TestBlock
        if ($result) {
            Write-Host " [PASS] $Description" -ForegroundColor Green
            $script:passedCount++
        } else {
            Write-Host " [FAIL] $Description" -ForegroundColor Red
            $script:failedCount++
        }
    } catch {
        Write-Host " [FAIL] $Description (Exception: $_)" -ForegroundColor Red
        $script:failedCount++
    }
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   TDD TEST SUITE: WIN DEPLOY 0x80070003 - 0x40008 COMPAT SCAN FIX   " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$opsContent = Get-Content -Path $systemOpsPath -Raw -Encoding UTF8

# 1. TUYET DOI KHONG truyen /product server trong setup_args de tranh loi Setup has encountered a critical error (Windows Server Setup 0x80070003 - 0x40008)
Assert-Test "1. setup_args khong duoc chua /product server gay xung dot goi Windows Server tren ISO Client" {
    -not ($opsContent -match 'format!\("/auto clean /eula accept /compat ignorewarning /product server') -and
    -not ($opsContent -match 'format!\("/product server /DynamicUpdate')
}

# 2. Tiem truc tiep cac khoa Registry MoSetup va LabConfig vao he dieu hanh hien tai de bypass TPM/CPU hop le
Assert-Test "2. He thong phai tiem AllowUpgradesWithUnsupportedTPMOrCPU va LabConfig truc tiep vao Registry truoc khi Setup chay" {
    $opsContent -match 'AllowUpgradesWithUnsupportedTPMOrCPU' -and
    $opsContent -match 'BypassTPMCheck' -and
    $opsContent -match 'BypassSecureBootCheck'
}

# 3. TUYET DOI KHONG tao truoc thu muc staging Sources ($stg\Sources) vi khien Setup ngo nhan staging da xong va gay 0x80070003
Assert-Test "3. Khong duoc tu y tao truoc thu muc staging Sources gay thieu DLL cho provider wsc:setup" {
    -not ($opsContent -match 'New-Item -Path \$srcDir -ItemType Directory') -and
    -not ($opsContent -match 'Copy-Item -Path "\$drv\\sources\\appraiserres\.dll"')
}

# 4. TUYET DOI KHONG chay bcdboot ... /s C: vi lam o C: mang cau truc boot EFI gay xung dot voi ESP va lam GetSystemPartitionNtPath bao 0x80070003
Assert-Test "4. Khong duoc ghi de boot files vao C:\ gay xung dot voi phan vung EFI System Partition" {
    -not ($opsContent -match 'bcdboot.*\$env:SystemRoot.*/s.*\$env:SystemDrive')
}

# 5. Phai tao SetupConfig.ini chuan Microsoft co Unattend va Compat=IgnoreWarning
Assert-Test "5. SetupConfig.ini phai duoc cau hinh day du Unattend va Compat=IgnoreWarning" {
    $opsContent -match 'SetupConfig\.ini' -and
    $opsContent -match 'Compat=IgnoreWarning'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
