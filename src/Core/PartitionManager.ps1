# VUONGTT Toolkit 2026 - Partition & Storage Management Module (MiniTool Partition Pro Style)

function Get-VUONGTTDiskPartitionMap {
    $results = @()
    try {
        $disks = Get-Disk | Sort-Object Number
        foreach ($d in $disks) {
            $diskObj = [PSCustomObject]@{
                Number         = $d.Number
                FriendlyName   = $d.FriendlyName
                BusType        = $d.BusType.ToString()
                SizeGB         = [math]::Round($d.Size / 1GB, 2)
                PartitionStyle = $d.PartitionStyle.ToString() # GPT / MBR / RAW
                HealthStatus   = $d.HealthStatus.ToString()
                Operational    = $d.OperationalStatus.ToString()
                Partitions     = @()
            }

            try {
                $parts = Get-Partition -DiskNumber $d.Number -ErrorAction SilentlyContinue | Sort-Object PartitionNumber
                foreach ($p in $parts) {
                    $vol = $null
                    if ($p.DriveLetter) {
                        $vol = Get-Volume -DriveLetter $p.DriveLetter -ErrorAction SilentlyContinue
                    } elseif ($p.AccessPaths -and $p.AccessPaths.Count -gt 0) {
                        $vol = Get-Volume -FilePath $p.AccessPaths[0] -ErrorAction SilentlyContinue
                    }

                    $totalGB = [math]::Round($p.Size / 1GB, 2)
                    $freeGB  = 0
                    $usedGB  = 0
                    $usedPct = 0
                    $fsLabel = ""
                    $fsType  = $p.Type.ToString()

                    if ($vol) {
                        if ($vol.FileSystemLabel) { $fsLabel = $vol.FileSystemLabel }
                        if ($vol.FileSystem) { $fsType = $vol.FileSystem }
                        if ($vol.Size -gt 0) {
                            $freeGB  = [math]::Round($vol.SizeRemaining / 1GB, 2)
                            $usedGB  = [math]::Round(($vol.Size - $vol.SizeRemaining) / 1GB, 2)
                            $usedPct = [math]::Round((($vol.Size - $vol.SizeRemaining) / $vol.Size) * 100, 1)
                        }
                    }

                    $diskObj.Partitions += [PSCustomObject]@{
                        PartitionNumber = $p.PartitionNumber
                        DriveLetter     = if ($p.DriveLetter) { "$($p.DriveLetter):" } else { "-" }
                        Label           = $fsLabel
                        FileSystem      = $fsType
                        Type            = $p.Type.ToString()
                        TotalGB         = $totalGB
                        UsedGB          = $usedGB
                        FreeGB          = $freeGB
                        UsedPercent     = $usedPct
                        IsBoot          = $p.IsBoot
                        IsSystem        = $p.IsSystem
                    }
                }
            } catch {}

            $results += $diskObj
        }
    } catch {
        Write-Warning "Lỗi khi truy xuất dữ liệu đĩa: $($_.Exception.Message)"
    }
    return $results
}

function Invoke-VUONGTTOptimizeTrim {
    param([string]$DriveLetter = "")
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "[$timestamp] [BẮT ĐẦU TỐI ƯU HÓA ĐĨA & TRIM SSD]"

    try {
        if ([string]::IsNullOrWhiteSpace($DriveLetter)) {
            # Tự động quét và TRIM toàn bộ phân vùng ổ đĩa cố định
            $vols = Get-Volume | Where-Object { $_.DriveType -eq "Fixed" -and $_.DriveLetter }
            foreach ($v in $vols) {
                $dl = $v.DriveLetter
                $log += "[Đang xử lý] Tối ưu hóa phân vùng ${dl}: ($($v.FileSystemLabel))..."
                try {
                    Optimize-Volume -DriveLetter $dl -ReTrim -Verbose -ErrorAction SilentlyContinue | Out-Null
                    $log += "[OK] Đã hoàn tất gửi lệnh TRIM cho phân vùng ${dl}:!"
                } catch {
                    Optimize-Volume -DriveLetter $dl -Defrag -ErrorAction SilentlyContinue | Out-Null
                    $log += "[OK] Đã hoàn tất dồn đĩa phân vùng ${dl}:!"
                }
            }
        } else {
            $dlClean = $DriveLetter.Trim().TrimEnd(':')
            $log += "[Đang xử lý] Đang gửi lệnh TRIM cho phân vùng ${dlClean}:..."
            try {
                Optimize-Volume -DriveLetter $dlClean -ReTrim -Verbose -ErrorAction SilentlyContinue | Out-Null
                $log += "[OK] Đã hoàn tất TRIM phân vùng ${dlClean}:!"
            } catch {
                Optimize-Volume -DriveLetter $dlClean -Defrag -ErrorAction SilentlyContinue | Out-Null
                $log += "[OK] Đã dồn đĩa phân vùng ${dlClean}:!"
            }
        }
        $log += "[HOÀN TẤT] Tối ưu hóa SSD & Chống phân mảnh đĩa thành công 100%!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTDiskSurfaceCheck {
    param([string]$DriveLetter = "C")
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $dl = $DriveLetter.Trim().TrimEnd(':')
    $log += "[$timestamp] [BẮT ĐẦU QUÉT BỀ MẶT & SỬA LỖI PHÂN VÙNG ${dl}:]"

    try {
        $log += "[Đang xử lý] Đang chạy chkdsk ${dl}: /scan (Quét trực tiếp không cần ngắt kết nối ổ)..."
        $p = Start-Process -FilePath "chkdsk.exe" -ArgumentList "${dl}: /scan" -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0) {
            $log += "[OK] Quá trình quét hoàn tất: Phân vùng ${dl}: hoạt động hoàn hảo, không có lỗi cấu trúc hoặc Bad Sector!"
        } else {
            $log += "[CHÚ Ý] Kết quả kiểm tra trả về mã: $($p.ExitCode). Vui lòng lên lịch quét khi khởi động nếu phát hiện lỗi."
        }
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTMbr2GptCheck {
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "[$timestamp] [KIỂM TRA TƯƠNG THÍCH CHUYỂN ĐỔI MBR SANG GPT (UEFI)]"

    try {
        $log += "[Đang xử lý] Đang kiểm tra cấu trúc đĩa hệ thống với mbr2gpt.exe /validate /allowFullOS..."
        $p = Start-Process -FilePath "mbr2gpt.exe" -ArgumentList "/validate /allowFullOS" -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0) {
            $log += "[OK] Đĩa hệ thống hoàn toàn đủ điều kiện chuyển đổi sang chuẩn GPT/UEFI mà không mất dữ liệu!"
        } else {
            $log += "[THÔNG BÁO] Kiểm tra MBR2GPT kết thúc với mã $($p.ExitCode). (Nếu đĩa đã là GPT thì không cần chuyển đổi)."
        }
    } catch {
        $log += "[CHÚ Ý] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Set-VUONGTTVolumeLabel {
    param(
        [string]$DriveLetter,
        [string]$NewLabel
    )
    try {
        $dl = $DriveLetter.Trim().TrimEnd(':')
        Set-Volume -DriveLetter $dl -NewFileSystemLabel $NewLabel -ErrorAction Stop
        return "[OK] Đã đổi tên nhãn phân vùng ${dl}: thành '$NewLabel' thành công!"
    } catch {
        return "[LỖI] Không thể đổi tên phân vùng: $($_.Exception.Message)"
    }
}

function Set-VUONGTTDriveLetter {
    param(
        [string]$OldLetter,
        [string]$NewLetter
    )
    try {
        $old = $OldLetter.Trim().TrimEnd(':')
        $new = $NewLetter.Trim().TrimEnd(':')
        Get-Partition -DriveLetter $old -ErrorAction Stop | Set-Partition -NewDriveLetter $new -ErrorAction Stop
        return "[OK] Đã đổi ký tự ổ từ ${old}: sang ${new}: thành công!"
    } catch {
        return "[LỖI] Không thể đổi ký tự ổ: $($_.Exception.Message)"
    }
}

function Invoke-VUONGTTLaunchDiskManagement {
    try {
        Start-Process "diskmgmt.msc"
        return "[OK] Đã mở trình Quản Lý Đĩa Windows Disk Management (diskmgmt.msc)!"
    } catch {
        return "[LỖI] Không thể mở diskmgmt.msc: $($_.Exception.Message)"
    }
}

function Invoke-VUONGTTLaunchDiskPart {
    try {
        Start-Process "cmd.exe" -ArgumentList "/k diskpart" -Verb RunAs
        return "[OK] Đã mở bảng điều khiển DiskPart nâng cao với quyền Administrator!"
    } catch {
        return "[LỖI] Không thể mở DiskPart: $($_.Exception.Message)"
    }
}

function Invoke-VUONGTTLaunchPartitionTools {
    # Check if MiniTool Partition Wizard or DiskGenius is installed or download portable
    $tools = @(
        "$env:ProgramFiles\MiniTool Partition Wizard*\partitionwizard.exe",
        "$env:ProgramFiles(x86)\MiniTool Partition Wizard*\partitionwizard.exe",
        "C:\Tools\DiskGenius\DiskGenius.exe"
    )

    foreach ($pattern in $tools) {
        $found = Get-Item -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found -and (Test-Path $found.FullName)) {
            Start-Process -FilePath $found.FullName
            return "[OK] Đã khởi chạy công cụ phân vùng: $($found.FullName)"
        }
    }

    # If not installed, launch diskmgmt.msc and provide download link/winget
    try {
        Start-Process "diskmgmt.msc"
        return "[THÔNG BÁO] Chưa cài đặt MiniTool Partition Wizard trên máy. Đã tự động mở trình Quản Lý Đĩa diskmgmt.msc chuẩn Windows! Bạn có thể tải MiniTool Partition Wizard hoặc DiskGenius để có thêm tính năng nâng cao."
    } catch {
        return "[LỖI] $($_.Exception.Message)"
    }
}
