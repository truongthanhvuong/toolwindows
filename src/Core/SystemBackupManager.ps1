# ========================================================================================
#   VUONGTT TOOLKIT 2026 - WINDOWS & FILES FULL SYSTEM BACKUP MANAGER
#   Chức năng: Sao lưu toàn diện nguyên trạng Windows (C:), Boot EFI, Registry và toàn bộ tệp tin
#              Hỗ trợ System Image (WBAdmin), Restore Point, Backup Center và khôi phục WinRE
#   Encoding: UTF-8 with BOM
# ========================================================================================

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

        if ($OnProgress) { & $OnProgress "Đang khởi chạy tiến trình tạo System Image qua WBAdmin sang ổ $targetClean..." }

        $tempBat = Join-Path $env:TEMP "VUONGTT_FullWindowsBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').cmd"
        $scriptContent = @"
@echo off
chcp 65001 >nul
title [VUONGTT TOOLKIT] DANG SAO LUU TOAN BO WINDOWS VA TEP TIN (SYSTEM IMAGE)...
color 0A
echo ==============================================================================
echo   VUONGTT TOOLKIT 2026 - SAO LUU TOAN BO WINDOWS & TEP TIN (FULL SYSTEM IMAGE)
echo ==============================================================================
echo   * O dia nguon : $env:SystemDrive (Bao gom Windows, Boot EFI, Toan bo du lieu tep tin)
echo   * O dia dich  : $targetClean\WindowsImageBackup
echo   * Thoi gian   : %date% %time%
echo ==============================================================================
echo   Luu y:
echo   - Qua trinh sao luu co the mat tu 10 den 30 phut tuy thuoc toc do o dia va du lieu.
echo   - Vui long KHONG tat may tinh hoac rut o dia trong qua trinh sao luu!
echo ==============================================================================
echo.
echo Dang thuc thi lenh: wbadmin start backup -backupTarget:$targetClean -include:$env:SystemDrive -allCritical -vssCopy -quiet
echo.
wbadmin start backup -backupTarget:$targetClean -include:$env:SystemDrive -allCritical -vssCopy -quiet
set EXIT_CODE=%ERRORLEVEL%
echo.
if %EXIT_CODE% equ 0 (
    echo ==============================================================================
    echo [THANH CONG RUC RO] DA TAO HOAN TAT BAN SAO LUU TOAN BO WINDOWS VA TEP TIN!
    echo Thu muc luu tru: $targetClean\WindowsImageBackup
    echo Khi can khoi phuc lai toan bo may tinh, ban chi can khoi dong vao WinRE va
    echo chon System Image Recovery.
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

        # Khởi chạy cmd hiển thị trực quan tiến trình sao lưu thời gian thực
        try {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempBat`""
        } catch {
            [System.Diagnostics.Process]::Start("cmd.exe", "/c `"$tempBat`"") | Out-Null
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
        $sysDrive = $env:SystemDrive
        $disks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -ne $sysDrive }
        $backups = @()
        foreach ($d in $disks) {
            $imgPath = Join-Path $d.DeviceID "WindowsImageBackup"
            if (Test-Path $imgPath) {
                $compDirs = Get-ChildItem -Path $imgPath -Directory -ErrorAction SilentlyContinue
                foreach ($cd in $compDirs) {
                    $bFiles = Get-ChildItem -Path $cd.FullName -Recurse -Filter "*.vhdx" -ErrorAction SilentlyContinue
                    $totalBytes = 0
                    if ($bFiles) {
                        $totalBytes = ($bFiles | Measure-Object -Property Length -Sum).Sum
                    }
                    $totalGB = if ($totalBytes) { [math]::Round($totalBytes / 1GB, 2) } else { 0 }
                    $backups += [PSCustomObject]@{
                        Drive        = $d.DeviceID
                        ComputerName = $cd.Name
                        BackupPath   = $cd.FullName
                        SizeGB       = $totalGB
                        LastModified = $cd.LastWriteTime
                    }
                }
            }
        }
        return $backups
    } catch {
        return @()
    }
}
