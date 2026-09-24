# =========================================================================
#   TEST-DRIVEN DEVELOPMENT (TDD) TEST SUITE: BACKUP DRIVE SELECTION
#   Kiem thu logic chon o dia truoc khi sao luu Driver va Windows Image
# =========================================================================
param()

$script:TotalTests = 0
$script:PassedTests = 0
$script:FailedTests = 0

function Assert-Equal($actual, $expected, $testName) {
    $script:TotalTests++
    if ($actual -eq $expected) {
        $script:PassedTests++
        Write-Host "  [PASS] $testName" -ForegroundColor Green
    } else {
        $script:FailedTests++
        Write-Host "  [FAIL] $testName" -ForegroundColor Red
        Write-Host "         Mong doi: '$expected' | Thuc te: '$actual'" -ForegroundColor Yellow
    }
}

Write-Host ">>> BAT DAU CHAY BO TEST CHON O DIA SAO LUU DRIVER VA WINDOWS <<<" -ForegroundColor Cyan

# Nap file module nguon
$sourceCore = Join-Path (Split-Path -Parent $PSScriptRoot) "src\Core\SystemBackupManager.ps1"
if (Test-Path $sourceCore) {
    . $sourceCore
}

# Kiem tra xem ham da duoc implement chua
$hasResolveDriverTarget = (Get-Command "Resolve-VUONGTTDriverBackupTarget" -ErrorAction SilentlyContinue) -ne $null
$hasTestWindowsBackupTarget = (Get-Command "Test-VUONGTTWindowsBackupTargetDrive" -ErrorAction SilentlyContinue) -ne $null

Write-Host "`n--- NHOM 1: Kiem thu logic chon o dia sao luu Driver ---" -ForegroundColor Magenta
if (-not $hasResolveDriverTarget) {
    Write-Host "  [FAIL RED-PHASE] Ham Resolve-VUONGTTDriverBackupTarget CHUA DUOC DINH NGHIA" -ForegroundColor Red
    $script:TotalTests += 4
    $script:FailedTests += 4
} else {
    # Case 1: Nguoi dung huy chon (bam Cancel)
    $resCancel = Resolve-VUONGTTDriverBackupTarget -SelectedPath "" -SystemDrive "C:"
    Assert-Equal $resCancel.Success $false "1.1: Huy chon (rong) tra ve Success = `$false"
    Assert-Equal $resCancel.Reason "UserCancelled" "1.2: Ly do tra ve dung la 'UserCancelled'"

    # Case 2: Nguoi dung chon goc o D:\ -> tu dong them thu muc \Backup_Drivers
    $resDriveD = Resolve-VUONGTTDriverBackupTarget -SelectedPath "D:\" -SystemDrive "C:"
    Assert-Equal $resDriveD.Success $true "1.3: Chon o D:\ tra ve Success = `$true"
    Assert-Equal $resDriveD.TargetPath "D:\Backup_Drivers" "1.4: Tu dong chuan hoa o D:\ thanh D:\Backup_Drivers"
    Assert-Equal $resDriveD.IsSystemDrive $false "1.5: O D:\ khong phai o he thong C:"

    # Case 3: Nguoi dung chon thu muc tuy y -> giu nguyen
    $resCustom = Resolve-VUONGTTDriverBackupTarget -SelectedPath "D:\Drivers_Backup_2026" -SystemDrive "C:"
    Assert-Equal $resCustom.TargetPath "D:\Drivers_Backup_2026" "1.6: Giu nguyen thu muc nguoi dung da chi dinh"

    # Case 4: Nguoi dung chon o C:\ -> Canh bao IsSystemDrive = $true
    $resDriveC = Resolve-VUONGTTDriverBackupTarget -SelectedPath "C:\" -SystemDrive "C:"
    Assert-Equal $resDriveC.IsSystemDrive $true "1.7: Phat hien nguoi dung chon o C: va danh dau IsSystemDrive = `$true"
    Assert-Equal $resDriveC.TargetPath "C:\Backup_Drivers" "1.8: Chuan hoa C:\ thanh C:\Backup_Drivers"
}

Write-Host "`n--- NHOM 2: Kiem thu logic tuy chon o dia sao luu Windows (System Image) ---" -ForegroundColor Magenta
if (-not $hasTestWindowsBackupTarget) {
    Write-Host "  [FAIL RED-PHASE] Ham Test-VUONGTTWindowsBackupTargetDrive CHUA DUOC DINH NGHIA" -ForegroundColor Red
    $script:TotalTests += 4
    $script:FailedTests += 4
} else {
    # Case 5: Nguoi dung huy chon o dia Windows System Backup
    $resWinCancel = Test-VUONGTTWindowsBackupTargetDrive -SelectedDriveOrPath "" -FileSystem "NTFS" -SystemDrive "C:"
    Assert-Equal $resWinCancel.Valid $false "2.1: Huy chon o Windows Backup tra ve Valid = `$false"
    Assert-Equal $resWinCancel.Error "UserCancelled" "2.2: Loi tra ve la 'UserCancelled'"

    # Case 6: Chon chinh o C:\ de sao luu Windows -> Chan lai vi vi pham quy dinh WBAdmin
    $resWinDriveC = Test-VUONGTTWindowsBackupTargetDrive -SelectedDriveOrPath "C:\" -FileSystem "NTFS" -SystemDrive "C:"
    Assert-Equal $resWinDriveC.Valid $false "2.3: Khong cho phep chon o C: lam noi luu System Image"
    Assert-Equal $resWinDriveC.Error "CannotBackupToSystemDrive" "2.4: Loi tra ve la 'CannotBackupToSystemDrive'"

    # Case 7: Chon o D: nhung dinh dang FAT32 -> Chan lai vi WBAdmin yeu cau NTFS
    $resWinFAT32 = Test-VUONGTTWindowsBackupTargetDrive -SelectedDriveOrPath "D:\" -FileSystem "FAT32" -SystemDrive "C:"
    Assert-Equal $resWinFAT32.Valid $false "2.5: Khong cho phep o FAT32 lam noi luu System Image"
    Assert-Equal $resWinFAT32.Error "RequireNTFS" "2.6: Loi tra ve la 'RequireNTFS'"

    # Case 8: Chon o D:\ dinh dang NTFS -> Hop le hoan toan
    $resWinValid = Test-VUONGTTWindowsBackupTargetDrive -SelectedDriveOrPath "D:\" -FileSystem "NTFS" -SystemDrive "C:"
    Assert-Equal $resWinValid.Valid $true "2.7: O D:\ (NTFS) hop le cho System Image"
    Assert-Equal $resWinValid.DriveRoot "D:" "2.8: Tra ve DriveRoot dung la 'D:'"
}

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KET QUA TEST: $script:PassedTests / $script:TotalTests bai test dat." -ForegroundColor $(if ($script:FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($script:FailedTests -gt 0) {
    Exit 1
} else {
    Exit 0
}
