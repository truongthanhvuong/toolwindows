# VUONGTT Toolkit 2026 - Windows & Files Full System Backup Manager
# Encoding: UTF-8 with BOM

function Get-VUONGTTCandidateBackupDrives {
    <#
    .SYNOPSIS
        Quét và lấy danh sách các ổ đĩa NTFS/ReFS khả dụng để sao lưu toàn bộ Windows và tệp tin.
    #>
    try {
        $sysDrive = $env:SystemDrive # Thường là C:
        $sysDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$sysDrive'" -ErrorAction SilentlyContinue
        $sysUsedGB = 0
        if ($sysDisk -and $sysDisk.Size -gt 0) {
            $sysUsedGB = [math]::Round(($sysDisk.Size - $sysDisk.FreeSpace) / 1GB, 2)
        }

        $disks = Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue | Where-Object {
            $_.DeviceID -ne $sysDrive -and 
            $_.DriveType -in 3, 2, 4 -and 
            $_.FileSystem -in 'NTFS', 'ReFS'
        }

        $results = @()
        foreach ($d in $disks) {
            $freeGB = [math]::Round($d.FreeSpace / 1GB, 2)
            $totalGB = [math]::Round($d.Size / 1GB, 2)
            $volName = if ($d.VolumeName) { $d.VolumeName } else { "Local Disk" }
            $isFit = ($freeGB -ge ($sysUsedGB * 0.7)) # Dự trù nén của VSS/wbadmin

            $statusText = if ($isFit) { "Đủ dung lượng (Khuyên dùng)" } else { "Cảnh báo: Có thể thiếu dung lượng" }
            $displayText = "[$($d.DeviceID)] $volName - Trống: $freeGB GB / Tổng: $totalGB GB ($statusText)"

            $results += [PSCustomObject]@{
                DeviceID      = $d.DeviceID
                VolumeName    = $volName
                FileSystem    = $d.FileSystem
                FreeGB        = $freeGB
                TotalGB       = $totalGB
                IsFit         = $isFit
                DisplayText   = $displayText
                SysUsedGB     = $sysUsedGB
            }
        }
        return $results
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
            return [PSCustomObject]@{ Success = $false; Message = "Chưa chọn ổ đĩa đích để lưu bản sao lưu Windows!" }
        }

        # Đảm bảo target drive chuẩn format (ví dụ "E:" hoặc "E:\")
        $targetClean = $TargetDrive.TrimEnd('\')
        if ($targetClean -eq $env:SystemDrive) {
            return [PSCustomObject]@{ Success = $false; Message = "Không thể lưu bản System Image của ổ $env:SystemDrive lên chính ổ $env:SystemDrive! Vui lòng chọn ổ đĩa khác (D:, E:, USB, HDD rời)." }
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
echo Dang goi wbadmin thuc thi Volume Shadow Copy tao System Image...
echo.
wbadmin start backup -backupTarget:$targetClean -include:$env:SystemDrive -allCritical -vssCopy
set EXIT_CODE=%ERRORLEVEL%
echo.
if %EXIT_CODE% equ 0 (
    echo ==============================================================================
    echo [THANH CONG] DA TAO HOAN TAT BAN SAO LUU TOAN BO WINDOWS VA TEP TIN!
    echo Thu muc luu tru: $targetClean\WindowsImageBackup
    echo Khi can khoi phuc lai toan bo may tinh, ban chi can khoi dong vao WinRE va
    echo chon System Image Recovery.
    echo ==============================================================================
) else (
    echo ==============================================================================
    echo [CANH BAO] Tien trinh ket thuc voi ma thoat: %EXIT_CODE%
    echo Neu can ho tro, vui long kiem tra dung luong trong cua o dia dich hoac
    echo dam bao khong co ung dung khac dang khoa Volume.
    echo ==============================================================================
)
echo.
echo Nhan phim bat ky de dong cua so nay...
pause >nul
"@

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempBat, $scriptContent, $utf8NoBom)

        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempBat`""

        return [PSCustomObject]@{
            Success     = $true
            TargetDrive = $targetClean
            Message     = "Đã khởi chạy tiến trình sao lưu toàn bộ Windows & Tệp tin sang ổ $targetClean\`nTheo dõi tiến trình chi tiết trong cửa sổ nổi đang hiển thị."
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "Lỗi khởi chạy sao lưu: $($_.Exception.Message)"
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
        # Bật System Restore trên ổ C nếu đang tắt
        try {
            Enable-ComputerRestore -Drive "$sysDrive\" -ErrorAction SilentlyContinue
        } catch {}

        # Cho phép tạo checkpoint liên tục mà không bị Windows chặn giới hạn tần suất 24h
        try {
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            }
        } catch {}

        $desc = "VUONGTT_QuickRestorePoint_$(Get-Date -Format 'ddMMyyyy_HHmmss')"
        Checkpoint-Computer -Description $desc -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop

        return [PSCustomObject]@{
            Success = $true
            Message = "[THÀNH CÔNG] Đã tạo Điểm Khôi Phục Hệ Thống (System Restore Point) thành công:`n• Tên điểm khôi phục: $desc`n• Thời gian: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')"
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "[LỖI TẠO RESTORE POINT] Không thể tạo điểm khôi phục: $($_.Exception.Message)`n(Có thể tính năng System Protection đang bị tắt hoặc bị hạn chế bởi Group Policy)."
        }
    }
}

function Open-VUONGTTWindowsBackupCenter {
    <#
    .SYNOPSIS
        Mở giao diện gốc Windows Backup and Restore Center
    #>
    try {
        if (Test-Path "C:\Windows\System32\sdclt.exe") {
            Start-Process "C:\Windows\System32\sdclt.exe"
            return "Đã mở công cụ Windows Backup & Restore (Windows 7) của hệ thống!"
        } else {
            Start-Process "control.exe" -ArgumentList "/name Microsoft.BackupAndRestoreCenter"
            return "Đã mở Windows Backup and Restore Center!"
        }
    } catch {
        return "Không thể mở Windows Backup Center: $($_.Exception.Message)"
    }
}
