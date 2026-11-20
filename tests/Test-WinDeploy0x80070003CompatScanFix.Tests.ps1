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

# 6. Kich hoat va cuong che wscsvc va SecurityHealthService de provider wsc:setup khong bao loi
Assert-Test "6. Kich hoat wscsvc va SecurityHealthService de provider wsc:setup khong bi loi" {
    $opsContent -match 'wscsvc' -and
    $opsContent -match 'SecurityHealthService'
}

# 7. Khoi tao cac thu muc Windows Defender Platform & Health de tranh ERROR_PATH_NOT_FOUND (0x80070003)
Assert-Test "7. Khoi tao thu muc Windows Defender Platform va Security Health" {
    $opsContent -match 'Windows Defender\\Platform' -and
    $opsContent -match 'Windows Security Health'
}

# 8. Refresh va lam sach BCD he thong qua bcdboot /p /bcdclean full ma khong gan ky tu o dia /s S:
Assert-Test "8. Refresh va lam sach BCD he thong qua bcdboot /p /bcdclean full ma khong gan ky tu o dia /s S:" {
    $opsContent -match 'bcdboot.*\$env:SystemRoot.*/p' -and
    $opsContent -match 'mountvol.*\$gl.*\/D' -and
    -not ($opsContent -match 'bcdboot.*\$env:SystemRoot.*/s.*\$mountLetter')
}

# 9. Chuan hoa GPT Attributes 0x8000000000000000 va partition id cua ESP qua diskpart / Set-Partition
Assert-Test "9. Chuan hoa GPT Attributes 0x8000000000000000 va partition id cua ESP qua diskpart / Set-Partition" {
    $opsContent -match '0x8000000000000000' -and
    $opsContent -match 'c12a7328-f81f-11d2-ba4b-00a0c93ec93b' -and
    $opsContent -match 'diskpart'
}

# 10. Go bo cac anh ISO ao stale de tranh xung dot catalog voi provider wsc:setup
Assert-Test "10. Go bo cac anh ISO ao stale de tranh xung dot catalog voi provider wsc:setup" {
    $opsContent -match 'MSFT_DiskImage' -and
    $opsContent -match 'Dismount-DiskImage'
}

# 11. Khong duoc tao autounattend.xml tai goc o dia (C:\autounattend.xml) trong In-OS deploy vi gay loi GetDriveLetterFromUnattend 0xC1800108 va mo man hinh phan vung
Assert-Test "11. Khong duoc tao autounattend.xml tren C:\ de tranh loi GetDriveLetterFromUnattend 0xC1800108" {
    -not ($opsContent -match 'Set-Content -Path "C:\\autounattend\.xml"') -and
    $opsContent -match 'Remove-Item -Path "C:\\autounattend\.xml"'
}

# 12. unattend.xml cho In-OS deploy tuyet doi khong chua pass="windowsPE" de chong loi GetDriveLetterFromUnattend 0xC1800108
Assert-Test "12. unattend.xml cho In-OS deploy khong duoc chua pass='windowsPE' gay ket man hinh chon phan vung" {
    -not ($opsContent -match '(?s)\$unattendXml = @''.*?<settings pass="windowsPE">') -and
    ($opsContent -match '(?s)\$unattendXml = @''.*?<settings pass="specialize">')
}

# 13. save_deploy_post_config khong duoc ghi file autounattend.xml len goc o dia he thong hoac target
Assert-Test "13. save_deploy_post_config khong duoc ghi autounattend.xml len goc o dia he thong" {
    -not ($opsContent -match 'Out-File -FilePath "\$env:SystemDrive\\autounattend\.xml"') -and
    -not ($opsContent -match 'Out-File -FilePath "\$targetDrive\\autounattend\.xml"')
}

# 14. Uu tien tuyet doi root setup.exe tren mounted ISO lam primary launcher de chong 0x80070003 cua setupprep
Assert-Test "14. Uu tien tuyet doi root setup.exe tren mounted ISO lam primary launcher" {
    $opsContent -match '\$setupExe = if \(Test-Path "\$drv\\setup\.exe"\)'
}

# 15. SetupConfig.ini tai WSUS phai co EULA=Accept va TempDrive, dong thoi khong truyen /ConfigFile tren dong lenh de tranh xung dot voi /auto clean
Assert-Test "15. SetupConfig.ini co EULA=Accept, TempDrive va dong lenh khong truyen /ConfigFile tranh xung dot /auto clean" {
    $opsContent -match 'EULA=Accept' -and
    $opsContent -match 'TempDrive=\$targetDrive' -and
    -not ($opsContent -match '@\("\/ConfigFile"')
}

# 16. Go bo triet de moi IFEO hook cho SetupHost.exe de tranh popup cmd va crash SetupAppraiser, dong thoi chuan hoa SystemPartition
Assert-Test "16. Go bo triet de moi IFEO hook cho SetupHost.exe va chuan hoa HKLM:\SYSTEM\Setup\SystemPartition" {
    $opsContent -match 'Remove-Item.*Image File Execution Options\\SetupHost\.exe' -and
    $opsContent -match 'Remove-Item.*get11\.cmd' -and
    $opsContent -match 'SystemPartition'
}

# 17. Xoa bo triet de moi cache cu va log loi trong C:\Windows\Panther (compatscancache.dat, queues, setupinfo) de chong 0x80070003
Assert-Test "17. Xoa sach bo nho dem compatscancache.dat va queue loi cu trong C:\Windows\Panther" {
    $opsContent -match 'compatscancache\.dat' -and
    $opsContent -match 'setupinfo' -and
    $opsContent -match 'Remove-Item -Path \$pf'
}

# 18. Chuan hoa chinh xac tuyet doi HKLM:\SYSTEM\Setup\SystemPartition qua QueryDosDevice va Win32 API
Assert-Test "18. Chuan hoa chinh xac NT Device Path cua SystemPartition qua QueryDosDevice va Win32VolHelper" {
    $opsContent -match 'QueryDosDevice' -and
    $opsContent -match 'Win32VolHelper' -and
    $opsContent -match 'SystemPartition'
}

# 19. WinToHDD Dual-Engine: Trich xuat WinPE RAMDisk (boot.wim, boot.sdi) va kich hoat BCD bootsequence du phong
Assert-Test "19. WinToHDD Dual-Engine trich xuat WinPE RAMDisk va thiet lap BCD bootsequence" {
    $opsContent -match 'ramdiskoptions' -and
    $opsContent -match 'boot\.sdi' -and
    $opsContent -match 'boot\.wim' -and
    $opsContent -match 'bcdedit /bootsequence'
}

# 20. Tiem khoa HwReqChkVars va xoa stale markers de bypass hoan toan hwreqchk.dll tren Windows 11 24H2/25H2
Assert-Test "20. Tiem khoa HwReqChkVars va xoa stale markers de bypass hoan toan hwreqchk.dll" {
    $opsContent -match 'HwReqChk' -and
    $opsContent -match 'HwReqChkVars' -and
    $opsContent -match 'SQ_SecureBootCapable=TRUE' -and
    $opsContent -match 'TargetVersionUpgradeExperienceIndicators'
}

# 21. Tu dong su dung o dem an toan D: khi cai sach se len C: de chong xung dot xoa phan vung boot
Assert-Test "21. Tu dong lua chon o dem D: khi cai dat moi sach se len C:" {
    $opsContent -match 'clean_target\.eq_ignore_ascii_case\("C"\)' -and
    $opsContent -match 'temp_drive_letter = "D"'
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   KET QUA KIEM THU: $passedCount PASS, $failedCount FAIL" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedCount -gt 0) {
    throw "$failedCount tests failed!"
}
