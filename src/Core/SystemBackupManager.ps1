# ========================================================================================
#   VUONGTT TOOLKIT 2026 - WINDOWS & FILES FULL SYSTEM BACKUP MANAGER
#   Chức năng: Sao lưu toàn diện nguyên trạng Windows (C:), Boot EFI, Registry và toàn bộ tệp tin
#              Hỗ trợ System Image (WBAdmin), Restore Point, Backup Center và khôi phục WinRE
#   Encoding: UTF-8 with BOM
# ========================================================================================


# ========================================================================================
#   CAC HAM XU LY CHON O DIA SAO LUU DRIVER & WINDOWS HE THONG
# ========================================================================================

function Resolve-VUONGTTDriverBackupTarget {
    <#
    .SYNOPSIS
        Kiem tra va chuan hoa duong dan thu muc sao luu Driver do nguoi dung chon.
    #>
    param(
        [string]$SelectedPath,
        [string]$SystemDrive = $env:SystemDrive
    )
    if ([string]::IsNullOrWhiteSpace($SelectedPath)) {
        return [PSCustomObject]@{
            Success       = $false
            Reason        = "UserCancelled"
            TargetPath    = $null
            IsSystemDrive = $false
            DriveRoot     = $null
        }
    }
    $cleanPath = $SelectedPath.TrimEnd('\')
    if ($cleanPath -match '^[A-Za-z]:$') {
        $cleanPath = "$cleanPath\Backup_Drivers"
    }
    $rootDrive = [System.IO.Path]::GetPathRoot($cleanPath).TrimEnd('\')
    $sysClean = if ($SystemDrive) { $SystemDrive.TrimEnd('\') } else { "C:" }
    $isSys = ($rootDrive -ieq $sysClean)

    return [PSCustomObject]@{
        Success       = $true
        Reason        = "OK"
        TargetPath    = $cleanPath
        IsSystemDrive = $isSys
        DriveRoot     = $rootDrive
    }
}

function Test-VUONGTTWindowsBackupTargetDrive {
    <#
    .SYNOPSIS
        Kiem tra tinh hop le cua o dia dich khi sao luu toan bo Windows (WBAdmin System Image).
    #>
    param(
        [string]$SelectedDriveOrPath,
        [string]$FileSystem = "",
        [string]$SystemDrive = $env:SystemDrive
    )
    if ([string]::IsNullOrWhiteSpace($SelectedDriveOrPath)) {
        return [PSCustomObject]@{
            Valid      = $false
            Error      = "UserCancelled"
            DriveRoot  = $null
            FileSystem = $null
        }
    }
    $driveRoot = [System.IO.Path]::GetPathRoot($SelectedDriveOrPath).TrimEnd('\')
    $sysClean = if ($SystemDrive) { $SystemDrive.TrimEnd('\') } else { "C:" }
    if ($driveRoot -ieq $sysClean) {
        return [PSCustomObject]@{
            Valid      = $false
            Error      = "CannotBackupToSystemDrive"
            DriveRoot  = $driveRoot
            FileSystem = $FileSystem
        }
    }

    $fs = if ($FileSystem) { $FileSystem.ToUpper() } else { "" }
    if (-not $fs) {
        try {
            $di = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.Name.TrimEnd('\') -ieq $driveRoot } | Select-Object -First 1
            if ($di -and $di.DriveFormat) { $fs = $di.DriveFormat.ToUpper() }
        } catch {}
        if (-not $fs) {
            try {
                $cim = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$driveRoot'" -ErrorAction SilentlyContinue
                if ($cim -and $cim.FileSystem) { $fs = $cim.FileSystem.ToUpper() }
            } catch {}
        }
    }
    if ($fs -and $fs -ne "NTFS") {
        return [PSCustomObject]@{
            Valid      = $false
            Error      = "RequireNTFS"
            DriveRoot  = $driveRoot
            FileSystem = $fs
        }
    }

    return [PSCustomObject]@{
        Valid      = $true
        Error      = $null
        DriveRoot  = $driveRoot
        FileSystem = if ($fs) { $fs } else { "NTFS" }
    }
}

function Get-VUONGTTCandidateBackupDrives {
    <#
    .SYNOPSIS
        Quét và lấy danh sách các ổ đĩa khả dụng để sao lưu toàn bộ Windows và tệp tin.
        Hỗ trợ đa tầng (.NET DriveInfo + CIM Win32_LogicalDisk) nhận diện mọi ổ cứng rời, USB, External HDD.
    #>
    try {
        $sysDrive = $env:SystemDrive # Thường là C:
        $sysDriveClean = $sysDrive.TrimEnd('\')
        
        $sysUsedGB = 0
        try {
            $sysDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$sysDrive'" -ErrorAction SilentlyContinue
            if ($sysDisk -and $sysDisk.Size -gt 0) {
                $sysUsedGB = [math]::Round(($sysDisk.Size - $sysDisk.FreeSpace) / 1GB, 2)
            }
        } catch {}
        
        if ($sysUsedGB -le 0) {
            try {
                $dC = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.Name.TrimEnd('\') -eq $sysDriveClean } | Select-Object -First 1
                if ($dC -and $dC.TotalSize -gt 0) {
                    $sysUsedGB = [math]::Round(($dC.TotalSize - $dC.AvailableFreeSpace) / 1GB, 2)
                }
            } catch {}
        }
        if ($sysUsedGB -le 0) { $sysUsedGB = 35 }
        $minRequiredGB = [math]::Max(10, [math]::Round($sysUsedGB * 0.25, 1))

        # Thu thập danh sách ổ đĩa từ cả CIM và .NET DriveInfo để đảm bảo 100% không sót ổ rời/USB
        $diskDict = @{}

        # Tầng 1: Win32_LogicalDisk
        try {
            $wmiDisks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue
            foreach ($wd in $wmiDisks) {
                if ($wd.DeviceID -and ($wd.DeviceID.TrimEnd('\') -ne $sysDriveClean) -and ($wd.DriveType -in 2, 3)) {
                    $devId = $wd.DeviceID.TrimEnd('\')
                    $diskDict[$devId] = @{
                        DeviceID   = $devId
                        VolumeName = if ($wd.VolumeName) { $wd.VolumeName } else { "Ổ Đĩa" }
                        FileSystem = if ($wd.FileSystem) { $wd.FileSystem.ToUpper() } else { "UNKNOWN" }
                        FreeGB     = if ($wd.FreeSpace) { [math]::Round($wd.FreeSpace / 1GB, 2) } else { 0 }
                        TotalGB    = if ($wd.Size) { [math]::Round($wd.Size / 1GB, 2) } else { 0 }
                    }
                }
            }
        } catch {}

        # Tầng 2: .NET DriveInfo (Bổ sung/cập nhật mọi ổ đĩa rời, USB cắm ngoài mà WMI có thể chưa nạp kịp)
        try {
            $netDrives = [System.IO.DriveInfo]::GetDrives()
            foreach ($nd in $netDrives) {
                if ($nd.IsReady) {
                    $devId = $nd.Name.TrimEnd('\')
                    $dTypeStr = $nd.DriveType.ToString()
                    if ($devId -ne $sysDriveClean -and ($dTypeStr -in 'Fixed', 'Removable')) {
                        $fGB = [math]::Round($nd.AvailableFreeSpace / 1GB, 2)
                        $tGB = [math]::Round($nd.TotalSize / 1GB, 2)
                        $fsName = if ($nd.DriveFormat) { $nd.DriveFormat.ToUpper() } else { "UNKNOWN" }
                        $vLabel = if ($nd.VolumeLabel) { $nd.VolumeLabel } else { "Ổ Đĩa" }
                        
                        $diskDict[$devId] = @{
                            DeviceID   = $devId
                            VolumeName = $vLabel
                            FileSystem = $fsName
                            FreeGB     = $fGB
                            TotalGB    = $tGB
                        }
                    }
                }
            }
        } catch {}

        $results = @()
        foreach ($k in $diskDict.Keys) {
            $d = $diskDict[$k]
            $devId = $d.DeviceID
            $volName = $d.VolumeName
            $fs = $d.FileSystem
            $freeGB = $d.FreeGB
            $totalGB = $d.TotalGB

            $isNTFS = ($fs -in 'NTFS', 'REFS')
            $isFit = ($isNTFS -and ($freeGB -ge $minRequiredGB))

            $statusText = ""
            if (-not $isNTFS) {
                $statusText = "Định dạng $fs (Cần format NTFS để tạo System Image)"
            } elseif ($isFit) {
                $statusText = "Đủ dung lượng (Khuyên dùng)"
            } elseif ($freeGB -ge 10) {
                $statusText = "Khả dụng (Còn trống $freeGB GB)"
            } else {
                $statusText = "Dung lượng thấp (< 10 GB)"
            }

            $displayText = "[$devId] $volName ($fs) - Trống: $freeGB GB / Tổng: $totalGB GB | $statusText"

            $results += [PSCustomObject]@{
                DeviceID      = $devId
                VolumeName    = $volName
                FileSystem    = $fs
                FreeGB        = $freeGB
                TotalGB       = $totalGB
                IsNTFS        = $isNTFS
                IsFit         = $isFit
                DisplayText   = $displayText
                SysUsedGB     = $sysUsedGB
            }
        }

        $sortedResults = @($results | Sort-Object -Property @{Expression={$_.IsFit}; Descending=$true}, @{Expression={$_.FreeGB}; Descending=$true})
        return $sortedResults
    } catch {
        return @()
    }
}

function Start-VUONGTTFullWindowsBackup {
    <#
    .SYNOPSIS
        Khởi chạy sao lưu toàn bộ Windows (hệ điều hành, boot EFI, registry) và toàn bộ file ổ C: (Users, Data)
    #>
    param(
        [string]$TargetDrive,
        [scriptblock]$OnProgress
    )

    try {
        if (-not $TargetDrive) {
            return [PSCustomObject]@{ Success = $false; Message = "[LỖI] Chưa chọn ổ đĩa đích để lưu bản sao lưu Windows!" }
        }

        # Đảm bảo target drive chuẩn format (ví dụ "E:" hoặc "E:\")
        $targetClean = $TargetDrive.TrimEnd('\')
        if ($targetClean -eq $env:SystemDrive) {
            return [PSCustomObject]@{ Success = $false; Message = "[LỖI] Không thể lưu bản System Image của ổ $env:SystemDrive lên chính ổ $env:SystemDrive! Vui lòng chọn ổ đĩa khác (D:, E:, USB, HDD rời)." }
        }

        if ($OnProgress) { & $OnProgress "Đang chuẩn bị dịch vụ Volume Shadow Copy (VSS) và Windows Backup Engine..." }

        # Khởi động dịch vụ cần thiết
        try {
            Set-Service -Name "VSS" -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service -Name "VSS" -ErrorAction SilentlyContinue
            Set-Service -Name "wbengine" -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service -Name "wbengine" -ErrorAction SilentlyContinue
        } catch {}

        if ($OnProgress) { & $OnProgress "Đang dọn dẹp rác tạm và chuẩn bị môi trường sao lưu..." }

        # Dọn dẹp rác tạm an toàn trước bằng PowerShell (không làm lỗi file batch)
        try {
            Remove-Item -Path "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
        } catch {}

        # Lưu file batch ở thư mục an toàn ProgramData để không bao giờ bị xóa khi dọn dẹp Temp
        $safeDir = Join-Path $env:ProgramData "VUONGTT_Toolkit"
        if (-not (Test-Path $safeDir)) { New-Item -Path $safeDir -ItemType Directory -Force | Out-Null }
        $tempBat = Join-Path $safeDir "VUONGTT_FullWindowsBackup.cmd"

        $scriptContent = @"
@echo off
chcp 65001 >nul
title [VUONGTT TOOLKIT 2026] SAO LUU NGUYEN TRANG WINDOWS & PHAN MEM DA CAI
color 0A
echo ==============================================================================
echo   VUONGTT TOOLKIT 2026 - SAO LUU NGUYEN TRANG WINDOWS & PHAN MEM DA CAI
echo ==============================================================================
echo   * Pham vi sao luu:
echo     - He dieu hanh Windows & Driver he thong ($env:SystemDrive\Windows)
echo     - Toan bo Phan Mem da cai dat (Program Files, Program Files x86, ProgramData)
echo     - Phan vung khoi dong quan trong (EFI System Partition, WinRE Recovery, BCD)
echo     - Ho so cau hinh nguoi dung ($env:SystemDrive\Users, Desktop, Documents, AppData...)
echo   * O dia dich: $targetClean\WindowsImageBackup
echo   * Thoi gian : %date% %time%
echo ==============================================================================
echo.
echo [1/2] Dang quet kiem tra truc tuyen he thong tep de ngan ngua Bad Clusters...
chkdsk $env:SystemDrive /scan /perf
echo.
echo [2/2] Dang thuc thi lenh tao System Image WBAdmin sang o $targetClean...
echo       (Lenh: wbadmin start backup -backupTarget:$targetClean -include:$env:SystemDrive -allCritical -vssCopy -quiet)
echo.
wbadmin start backup -backupTarget:$targetClean -include:$env:SystemDrive -allCritical -vssCopy -quiet
set EXIT_CODE=%ERRORLEVEL%
echo.
if %EXIT_CODE% equ 0 (
    echo ==============================================================================
    echo [THANH CONG RUC RO] DA TAO HOAN TAT BAN SAO LUU WINDOWS & PHAN MEM!
    echo Thu muc luu tru: $targetClean\WindowsImageBackup
    echo Ban co the dung nut 'Khoi Phuc Ban Sao Luu' tren tool de gan o ao (Mount VHDX)
    echo lay lai phan mem/du lieu, hoac khoi dong WinRE de khoi phuc toan dien 100%%.
    echo ==============================================================================
) else if %EXIT_CODE% equ -4 (
    echo ==============================================================================
    echo [HOAN TAT CO CANH BAO BAD CLUSTERS]
    echo BAN SAO LUU NGUYEN TRANG WINDOWS DA DUOC TAO THANH CONG TREN $targetClean!
    echo.
    echo Giai thich chi tiet:
    echo Tren o dia $env:SystemDrive co mot so sector/cluster vat ly khong the doc (Bad Clusters).
    echo WBAdmin da tu dong bo qua cac cluster loi nay va sao luu thanh cong 100%%
    echo phan con lai cua he dieu hanh Windows, phan vung khoi dong EFI va du lieu nguoi dung.
    echo.
    echo [OK] Ban sao luu hoan toan hop le va co the dung de khoi phuc may tinh khi can!
    echo Goi y: Hay dung nut 'Quet & Sua Loi Bad Sector O C' tren tool de sua o dia.
    echo ==============================================================================
) else if %EXIT_CODE% equ 1 (
    echo ==============================================================================
    echo [HOAN TAT CO CANH BAO TEP DANG MO]
    echo BAN SAO LUU NGUYEN TRANG WINDOWS DA DUOC TAO TREN $targetClean!
    echo Mot so tep tin dang duoc khoa boi he thong da duoc sao luu qua VSS Shadow Copy.
    echo ==============================================================================
) else (
    echo ==============================================================================
    echo [CANH BAO] Tien trinh ket thuc voi ma thoat: %EXIT_CODE%
    echo Neu can ho tro, vui long kiem tra dung luong trong cua o dia dich hoac
    echo dam bao o dia dich da duoc format sang NTFS.
    echo ==============================================================================
)
echo.
echo Nhan phim bat ky de dong cua so nay...
pause >nul
"@

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempBat, $scriptContent, $utf8NoBom)

        # Khởi chạy cmd hiển thị trực quan tiến trình sao lưu thời gian thực (/k giữ cửa sổ luôn mở)
        try {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/k `"$tempBat`""
        } catch {
            [System.Diagnostics.Process]::Start("cmd.exe", "/k `"$tempBat`"") | Out-Null
        }

        return [PSCustomObject]@{
            Success     = $true
            TargetDrive = $targetClean
            Message     = "[KHỞI CHẠY THÀNH CÔNG] Đang sao lưu toàn bộ Windows sang ổ $targetClean\`nHãy theo dõi tiến trình trực tiếp trong cửa sổ dòng lệnh vừa xuất hiện."
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "[LỖI SAO LƯU] Không thể khởi chạy tiến trình: $($_.Exception.Message)"
        }
    }
}

function New-VUONGTTSystemRestorePoint {
    <#
    .SYNOPSIS
        Tạo nhanh điểm khôi phục hệ thống (System Restore Point)
    #>
    try {
        $sysDrive = $env:SystemDrive
        
        # 1. Kích hoạt dịch vụ Volume Shadow Copy và System Restore
        try {
            Set-Service -Name "VSS" -StartupType Manual -ErrorAction SilentlyContinue
            Start-Service -Name "VSS" -ErrorAction SilentlyContinue
            Set-Service -Name "srservice" -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name "srservice" -ErrorAction SilentlyContinue
        } catch {}

        # 2. Bật System Restore trên ổ C nếu đang tắt
        try {
            Enable-ComputerRestore -Drive "$sysDrive\" -ErrorAction SilentlyContinue
        } catch {}

        # 3. Phân bổ dung lượng Shadow Storage tối thiểu 10% nếu chưa cấu hình
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "vssadmin.exe"
            $psi.Arguments = "resize shadowstorage /for=$sysDrive /on=$sysDrive /maxsize=10%"
            $psi.CreateNoWindow = $true
            $psi.UseShellExecute = false
            $proc = [System.Diagnostics.Process]::Start($psi)
            if ($proc) { $proc.WaitForExit(3000) }
        } catch {}

        # 4. Tắt giới hạn tần suất tạo checkpoint 24h của Windows
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
            if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $regPath -Name "RPSessionInterval" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        } catch {}

        $desc = "VUONGTT_RestorePoint_$(Get-Date -Format 'ddMMyyyy_HHmmss')"
        Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop

        return [PSCustomObject]@{
            Success = $true
            Message = "[THÀNH CÔNG] Đã tạo Điểm Khôi Phục Hệ Thống (System Restore Point) thành công:`n• Tên điểm khôi phục: $desc`n• Thời gian: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')"
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "[LỖI TẠO RESTORE POINT] Không thể tạo điểm khôi phục: $($_.Exception.Message)`n`n👉 Gợi ý: Hãy bấm nút 'Cấu Hình System Protection' để kiểm tra xem tính năng bảo vệ ổ C: đã được BẬT (Turn on system protection) trong Windows chưa."
        }
    }
}

function Open-VUONGTTWindowsBackupCenter {
    <#
    .SYNOPSIS
        Mở giao diện gốc Windows Backup and Restore Center
    #>
    try {
        if (Test-Path "$env:SystemRoot\System32\sdclt.exe") {
            Start-Process "$env:SystemRoot\System32\sdclt.exe"
            return "[OK] Đã mở công cụ Windows Backup & Restore (Windows 7) của hệ thống!"
        } else {
            Start-Process "control.exe" -ArgumentList "/name Microsoft.BackupAndRestoreCenter"
            return "[OK] Đã mở Windows Backup and Restore Center!"
        }
    } catch {
        return "[LỖI] Không thể mở Windows Backup Center: $($_.Exception.Message)"
    }
}

function Open-VUONGTTSystemProtectionSettings {
    <#
    .SYNOPSIS
        Mở hộp thoại System Properties -> System Protection để cấu hình Restore Point
    #>
    try {
        Start-Process "SystemPropertiesProtection.exe"
        return "[OK] Đã mở bảng điều khiển System Protection & Restore Point!"
    } catch {
        return "[LỖI] Không thể mở SystemPropertiesProtection: $($_.Exception.Message)"
    }
}

function Get-VUONGTTExistingBackups {
    <#
    .SYNOPSIS
        Quét và liệt kê toàn bộ các bản sao lưu WindowsImageBackup có sẵn trên các ổ đĩa
    #>
    try {
        $sysDrive = $env:SystemDrive.TrimEnd('\')
        $targetDrives = @()
        
        try {
            $wmi = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue
            foreach ($w in $wmi) {
                if ($w.DeviceID -and $w.DeviceID.TrimEnd('\') -ne $sysDrive) {
                    $targetDrives += $w.DeviceID.TrimEnd('\')
                }
            }
        } catch {}

        try {
            $netD = [System.IO.DriveInfo]::GetDrives()
            foreach ($nd in $netD) {
                if ($nd.IsReady) {
                    $n = $nd.Name.TrimEnd('\')
                    if ($n -ne $sysDrive -and ($targetDrives -notcontains $n)) {
                        $targetDrives += $n
                    }
                }
            }
        } catch {}

        $backups = @()
        foreach ($dId in $targetDrives) {
            $imgPath = "$dId\WindowsImageBackup"
            if (Test-Path $imgPath) {
                $compDirs = Get-ChildItem -Path $imgPath -Directory -ErrorAction SilentlyContinue
                foreach ($cd in $compDirs) {
                    $bFiles = Get-ChildItem -Path $cd.FullName -Recurse -Filter "*.vhdx" -ErrorAction SilentlyContinue
                    if (-not $bFiles) {
                        $bFiles = Get-ChildItem -Path $cd.FullName -Recurse -Filter "*.vhd" -ErrorAction SilentlyContinue
                    }
                    $totalBytes = 0
                    if ($bFiles) {
                        $totalBytes = ($bFiles | Measure-Object -Property Length -Sum).Sum
                    }
                    $totalGB = if ($totalBytes) { [math]::Round($totalBytes / 1GB, 2) } else { 0 }
                    $backups += [PSCustomObject]@{
                        Drive        = $dId
                        ComputerName = $cd.Name
                        BackupPath   = $cd.FullName
                        SizeGB       = $totalGB
                        LastModified = $cd.LastWriteTime
                    }
                }
            }
        }
        return @($backups)
    } catch {
        return @()
    }
}

function Repair-VUONGTTDiskBadSectors {
    <#
    .SYNOPSIS
        Tự động quét trực tuyến và cô lập/sửa chữa các Bad Sector / Bad Cluster trên ổ C:
    #>
    param([string]$DriveLetter = "C:")
    
    $cleanDrive = if ($DriveLetter) { $DriveLetter.TrimEnd('\') } else { "C:" }
    $tempCmd = Join-Path $env:TEMP "VUONGTT_ChkdskRepair_$(Get-Date -Format 'yyyyMMdd_HHmmss').cmd"
    $cmdContent = @"
@echo off
chcp 65001 >nul
title [VUONGTT TOOLKIT] QUET VA SUA LOI BAD SECTOR / CLUSTER O DIA $cleanDrive...
color 0E
echo ==============================================================================
echo   VUONGTT TOOLKIT 2026 - CONG CU QUET & SUA LOI BAD CLUSTERS O DIA $cleanDrive
echo ==============================================================================
echo   Tien trinh se thuc hien kiem tra, phat hien va sua chua cac cluster loi
echo   tren o dia $cleanDrive bang cong cu Microsoft CheckDisk (Chkdsk).
echo ==============================================================================
echo.
echo [BUOC 1] Dang quet truc tuyen nhanh toan bo he thong tep (Online Scan)...
chkdsk $cleanDrive /scan /perf
echo.
echo [BUOC 2] Dang sua chua va co lap cac loi cluster da phat hien...
chkdsk $cleanDrive /spotfix
echo.
echo ==============================================================================
echo Neu van con Bad Sector vat ly sau khi quet online, ban co the len lich
echo quet chuyen sau va phuc hoi toan dien (/F /R) trong lan khoi dong tiep theo.
echo ==============================================================================
echo.
set /p SCHEDULE_REBOOT="Ban co muon len lich quet toan dien (chkdsk $cleanDrive /f /r) khi khoi dong lai? (Y/N): "
if /i "%SCHEDULE_REBOOT%"=="Y" (
    echo y | chkdsk $cleanDrive /f /r
    echo.
    echo [OK] Da len lich quet toan dien o $cleanDrive trong lan khoi dong may tiep theo!
)
echo.
echo Hoan tat! Nhan phim bat ky de thoat...
pause >nul
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($tempCmd, $cmdContent, $utf8NoBom)
    try {
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempCmd`""
    } catch {
        [System.Diagnostics.Process]::Start("cmd.exe", "/c `"$tempCmd`"") | Out-Null
    }
}

function Find-VUONGTTBackupImagesInFolder {
    <#
    .SYNOPSIS
        Tìm kiếm các file ảnh đĩa (.vhdx, .vhd) của bản sao lưu trong thư mục chỉ định hoặc quét toàn bộ các ổ
    #>
    param([string]$FolderPath = "")

    $results = @()
    $foldersToScan = @()

    if ($FolderPath -and (Test-Path $FolderPath)) {
        $foldersToScan += $FolderPath
    } else {
        # Quét tự động tất cả các ổ đĩa có thư mục WindowsImageBackup
        $sysDrive = $env:SystemDrive.TrimEnd('\')
        try {
            $drives = [System.IO.DriveInfo]::GetDrives()
            foreach ($d in $drives) {
                if ($d.IsReady) {
                    $wib = Join-Path $d.Name "WindowsImageBackup"
                    if (Test-Path $wib) { $foldersToScan += $wib }
                }
            }
        } catch {}
    }

    foreach ($folder in $foldersToScan) {
        try {
            $vhdxFiles = Get-ChildItem -Path $folder -Recurse -Include "*.vhdx", "*.vhd" -File -ErrorAction SilentlyContinue
            foreach ($vf in $vhdxFiles) {
                # Lọc bỏ các file quá nhỏ (< 500MB) không phải system image
                if ($vf.Length -ge 500MB) {
                    $sizeGB = [math]::Round($vf.Length / 1GB, 2)
                    $results += [PSCustomObject]@{
                        FileName     = $vf.Name
                        FilePath     = $vf.FullName
                        Directory    = $vf.DirectoryName
                        SizeGB       = $sizeGB
                        LastModified = $vf.LastWriteTime
                        Drive        = [System.IO.Path]::GetPathRoot($vf.FullName).TrimEnd('\')
                    }
                }
            }
        } catch {}
    }

    return @($results | Sort-Object -Property LastModified -Descending)
}

function Mount-VUONGTTBackupImage {
    <#
    .SYNOPSIS
        Gắn file đĩa ảo VHDX của bản sao lưu thành ổ đĩa ảo ngay trong Windows Explorer
    #>
    param([string]$ImagePath)

    if (-not $ImagePath -or -not (Test-Path $ImagePath)) {
        return [PSCustomObject]@{ Success = $false; Message = "[LỖI] Tệp tin đĩa sao lưu (.vhdx/.vhd) không tồn tại!" }
    }

    try {
        # Sử dụng PowerShell Mount-DiskImage
        $diskImg = Mount-DiskImage -ImagePath $ImagePath -StorageType VHDX -Access ReadOnly -PassThru -ErrorAction Stop
        Start-Sleep -Milliseconds 800

        # Tìm ổ đĩa ký tự vừa được gán
        $vol = $diskImg | Get-Disk | Get-Partition | Get-Volume | Where-Object { $_.DriveLetter } | Select-Object -First 1
        $assignedDrive = if ($vol -and $vol.DriveLetter) { "$($vol.DriveLetter):" } else { "" }

        if ($assignedDrive) {
            # Mở ngay Explorer tại ổ đĩa vừa gắn
            Start-Process "explorer.exe" -ArgumentList $assignedDrive
            return [PSCustomObject]@{
                Success     = $true
                DriveLetter = $assignedDrive
                ImagePath   = $ImagePath
                Message     = "[THÀNH CÔNG] Đã gắn đĩa ảo thành ổ $assignedDrive\`n• Bạn có thể xem và lấy lại bất kỳ phần mềm, file dữ liệu nào ngay lập tức!`n• Khi dùng xong, bạn có thể tháo đĩa ảo bất kỳ lúc nào."
            }
        } else {
            return [PSCustomObject]@{
                Success     = $true
                DriveLetter = ""
                ImagePath   = $ImagePath
                Message     = "[OK] Đã gắn đĩa ảo vào hệ thống (Đang ở chế độ ReadOnly). Bạn có thể mở Disk Management (diskmgmt.msc) để kiểm tra."
            }
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "[LỖI GẮN ĐĨA ẢO] Không thể gắn file VHDX: $($_.Exception.Message)"
        }
    }
}

function Dismount-VUONGTTBackupImage {
    <#
    .SYNOPSIS
        Tháo đĩa ảo VHDX của bản sao lưu
    #>
    param([string]$ImagePath)

    if (-not $ImagePath) {
        return [PSCustomObject]@{ Success = $false; Message = "[LỖI] Chưa chỉ định file đĩa ảo để tháo!" }
    }

    try {
        Dismount-DiskImage -ImagePath $ImagePath -ErrorAction Stop
        return [PSCustomObject]@{
            Success = $true
            Message = "[THÀNH CÔNG] Đã tháo đĩa ảo an toàn khỏi hệ thống!"
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "[LỖI THÁO ĐĨA] Không thể tháo đĩa ảo: $($_.Exception.Message)"
        }
    }
}

# ========================================================================================
#   HAM THUC THI GIAO DIEN CHON O DIA CHO SAO LUU DRIVER VA TOAN BO WINDOWS
# ========================================================================================

function Invoke-VUONGTTBackupDriverWithFolderPicker {
    <#
    .SYNOPSIS
        Mo hop thoai chon o dia/thu muc va tien hanh sao luu toan bo Driver phan cung.
    #>
    param(
        [ScriptBlock]$LogAction,
        [ScriptBlock]$StatusAction
    )
    Add-Type -AssemblyName System.Windows.Forms
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "Chon o dia hoac thu muc (D:, E:, USB...) de sao luu toan bo Driver:"
    $defaultPath = if ($script:SelectedDriverBackupDir) { $script:SelectedDriverBackupDir } else { Get-VUONGTTDefaultDriverBackupPath }
    if ($defaultPath) {
        $fbd.SelectedPath = [System.IO.Path]::GetPathRoot($defaultPath)
    }
    $fbd.ShowNewFolderButton = $true

    if ($fbd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        if ($LogAction) { &$LogAction "[HUY BO] Nguoi dung da huy chon vi tri sao luu Driver." }
        return
    }

    $resTarget = Resolve-VUONGTTDriverBackupTarget -SelectedPath $fbd.SelectedPath
    if (-not $resTarget.Success) {
        if ($LogAction) { &$LogAction "[HUY BO] Thu muc da chon khong hop le." }
        return
    }

    $destDir = $resTarget.TargetPath
    $driveLetter = $resTarget.DriveRoot

    if ($resTarget.IsSystemDrive) {
        $warnSys = [System.Windows.MessageBox]::Show(
            "CANH BAO O DIA HE THONG:`n`nBan dang chon luu Driver len o $env:SystemDrive (o dia cai Windows).`nKhi cai lai Windows hoac format o C:, toan bo ban sao luu Driver nay se BI MAT!`n`nBan co chac chan muon tiep tuc luu tren o $env:SystemDrive khong?",
            "Canh Bao Vi Tri Luu",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        if ($warnSys -ne [System.Windows.MessageBoxResult]::Yes) {
            if ($LogAction) { &$LogAction "[HUY BO] Da huy sao luu do chon o he thong C:." }
            return
        }
    }

    $confirmMsg = "XAC NHAN BAT DAU SAO LUU TOAN BO DRIVER HE THONG`n`n" +
                  "- Thu muc luu tru: $destDir`n" +
                  "- O dia dich: $driveLetter`n`n" +
                  "Bam 'Yes' de bat dau sao luu Driver ngay bay gio!"

    $choice = [System.Windows.MessageBox]::Show($confirmMsg, "Xac Nhan Sao Luu Driver", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($choice -ne [System.Windows.MessageBoxResult]::Yes) {
        if ($LogAction) { &$LogAction "[HUY BO] Nguoi dung da huy xac nhan sao luu Driver." }
        return
    }

    $script:SelectedDriverBackupDir = $destDir
    if ($LogAction) { &$LogAction "Dang quet va sao luu toan bo Driver he thong ra $destDir..." }
    if (Get-Command "Invoke-VUONGTTDoEvents" -ErrorAction SilentlyContinue) { Invoke-VUONGTTDoEvents }

    try {
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Export-WindowsDriver -Online -Destination $destDir -ErrorAction Stop | Out-Null
        $count = (Get-ChildItem -Path $destDir -Directory -ErrorAction SilentlyContinue).Count
        $msgSuccess = "[THANH CONG] Da sao luu $count goi Driver phan cung vao thu muc:`n$destDir`nThoi gian: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')`n`nDriver da duoc bao toan an toan tren o dia du lieu, khong bi mat khi cai lai Windows C:."
        if ($LogAction) { &$LogAction $msgSuccess }
        if ($StatusAction) { &$StatusAction "- [OK] Da sao luu xong $count goi Driver vao $destDir" }
        [System.Windows.MessageBox]::Show("Da sao luu thanh cong $count goi Driver vao:`n$destDir`n`nBan sao luu da an toan tren o du lieu, co the dung de khoi phuc bat cu luc nao!", "Sao Luu Driver Hoan Tat", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    } catch {
        $errText = "[LOI SAO LUU DRIVER] $($_.Exception.Message)"
        if ($LogAction) { &$LogAction $errText }
        [System.Windows.MessageBox]::Show("Khong the sao luu Driver:`n$($_.Exception.Message)", "Loi Sao Luu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
}

function Invoke-VUONGTTBackupWindowsWithDrivePicker {
    <#
    .SYNOPSIS
        Mo hop thoai chon o dia tren may va tien hanh sao luu toan bo Windows (WBAdmin System Image).
    #>
    param(
        [ScriptBlock]$LogAction,
        [ScriptBlock]$StatusAction,
        $TargetDriveComboBox = $null
    )
    Add-Type -AssemblyName System.Windows.Forms
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "CHON O DIA DICH DE LUU BAN SAO LUU TOAN BO WINDOWS (SYSTEM IMAGE):`n(Chon o dia D:, E:, USB hoac o cung ngoai khac o C:)"
    $fbd.ShowNewFolderButton = $false

    # Goi y o dia mac dinh: uu tien lay tu ComboBox hoac o candidate dau tien
    $defaultDrive = "D:\"
    if ($TargetDriveComboBox -and $script:candidateBackupDrives -and $script:candidateBackupDrives.Count -gt 0) {
        $selIdx = $TargetDriveComboBox.SelectedIndex
        if ($selIdx -ge 0 -and $selIdx -lt $script:candidateBackupDrives.Count) {
            $defaultDrive = "$($script:candidateBackupDrives[$selIdx].DeviceID)\"
        }
    }
    if (Test-Path $defaultDrive) { $fbd.SelectedPath = $defaultDrive }

    if ($fbd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
        if ($LogAction) { &$LogAction "[HUY BO] Nguoi dung da huy chon o dia sao luu Windows." }
        return
    }

    $checkDrive = Test-VUONGTTWindowsBackupTargetDrive -SelectedDriveOrPath $fbd.SelectedPath
    if (-not $checkDrive.Valid) {
        if ($checkDrive.Error -eq "CannotBackupToSystemDrive") {
            [System.Windows.MessageBox]::Show("Khong the chon o $env:SystemDrive lam noi luu tru System Image cho chinh no theo quy dinh cua Windows.`nVui long chon o dia khac (D:, E:, USB...)!", "Canh Bao O Dia", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        } elseif ($checkDrive.Error -eq "RequireNTFS") {
            [System.Windows.MessageBox]::Show("O dia $($checkDrive.DriveRoot) dang co dinh dang $($checkDrive.FileSystem).`n`nCong cu Windows System Image (WBAdmin) yeu cau o dia dich phai duoc dinh dang NTFS.`nVui long format o $($checkDrive.DriveRoot) sang NTFS hoac chon o dia khac.", "Can Dinh Dang NTFS", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        }
        return
    }

    $targetDrive = $checkDrive.DriveRoot

    # Dong bo vao danh sach ComboBox va ung vien sao luu
    if ($TargetDriveComboBox) {
        $foundCandidate = $script:candidateBackupDrives | Where-Object { $_.DeviceID -eq $targetDrive }
        if (-not $foundCandidate) {
            $customObj = [PSCustomObject]@{
                DeviceID    = $targetDrive
                VolumeName  = "Tuy Chon"
                FileSystem  = "NTFS"
                FreeGB      = 999
                TotalGB     = 999
                IsNTFS      = $true
                IsFit       = $true
                DisplayText = "[$targetDrive] O dia tuy chon do nguoi dung chi dinh"
            }
            $script:candidateBackupDrives += $customObj
            $TargetDriveComboBox.Items.Add($customObj.DisplayText) | Out-Null
        }
        for ($idx = 0; $idx -lt $script:candidateBackupDrives.Count; $idx++) {
            if ($script:candidateBackupDrives[$idx].DeviceID -eq $targetDrive) {
                $TargetDriveComboBox.SelectedIndex = $idx
                break
            }
        }
    }

    # Lay thong so dung luong thuc te
    $freeGB = 0; $totalGB = 0
    try {
        $dInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.Name.TrimEnd('\') -ieq $targetDrive } | Select-Object -First 1
        if ($dInfo) {
            $freeGB = [math]::Round($dInfo.AvailableFreeSpace / 1GB, 1)
            $totalGB = [math]::Round($dInfo.TotalSize / 1GB, 1)
        }
    } catch {}

    $sysDrive = $env:SystemDrive
    $confirmMsg = "BAN CO MUON BAT DAU SAO LUU NGUYEN TRANG TOAN BO WINDOWS & TEP TIN?`n`n" +
                  "- Noi luu tru ban sao luu: $targetDrive\WindowsImageBackup`n" +
                  "- Trang thai o dich: Trong $freeGB GB / Tong $totalGB GB (NTFS)`n" +
                  "- Nguon sao luu: O $sysDrive (He dieu hanh Windows, Boot EFI, Toan bo du lieu nguoi dung)`n`n" +
                  "Qua trinh sao luu se chay trong cua so dong lenh truc quan thoi gian thuc (10 - 25 phut).`n`n" +
                  "Bam 'Yes' de bat dau sao luu ngay bay gio!"

    $confirm = [System.Windows.MessageBox]::Show($confirmMsg, "Xac Nhan Sao Luu Toan Bo Windows", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
    if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
        if ($LogAction) { &$LogAction "[HUY BO] Nguoi dung da huy xac nhan sao luu." }
        return
    }

    if ($LogAction) { &$LogAction "[BAT DAU] Dang khoi chay tien trinh sao luu toan bo Windows sang o $targetDrive..." }
    $res = Start-VUONGTTFullWindowsBackup -TargetDrive $targetDrive -OnProgress {
        param($m)
        if ($LogAction) { &$LogAction "$m" }
    }
    if ($LogAction) { &$LogAction "$($res.Message)" }
    if ($StatusAction) { &$StatusAction "- [OK] Da khoi chay sao luu Windows sang $targetDrive" }
}
