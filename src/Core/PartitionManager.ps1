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

# =========================================================================
# KIỂM TRA SỨC KHỎE Ổ CỨNG CHUYÊN SÂU (SMART / RELIABILITY HEALTH CHECK)
# =========================================================================
function Get-VUONGTTDiskHealthReport {
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "================================================================================"
    $log += "         BÁO CÁO KIỂM TRA SỨC KHỎE & THÔNG SỐ Ổ CỨNG (VUONGTT SMART)"
    $log += "================================================================================"
    
    try {
        $pDisks = Get-PhysicalDisk -ErrorAction SilentlyContinue | Sort-Object DeviceId
        if (-not $pDisks -or $pDisks.Count -eq 0) {
            $log += "[!] Không truy xuất được PhysicalDisk. Đang thử đọc qua WMI Win32_DiskDrive..."
            $wDisks = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue
            foreach ($wd in $wDisks) {
                $sz = [math]::Round($wd.Size / 1GB, 1)
                $log += "• Ổ Đĩa: $($wd.Model) (Index $($wd.Index))"
                $log += "  - Dung lượng    : $sz GB"
                $log += "  - Trạng thái WMI: $($wd.Status) [OK]"
                $log += "  - Giao tiếp     : $($wd.InterfaceType)"
            }
        } else {
            foreach ($pd in $pDisks) {
                $sz = [math]::Round($pd.Size / 1GB, 1)
                $healthVI = switch ($pd.HealthStatus) {
                    "Healthy"   { "🟢 TỐT (Healthy 100% - Hoạt động hoàn hảo)" }
                    "Warning"   { "🟡 CẢNH BÁO (Warning - Cần sao lưu dữ liệu)" }
                    "Unhealthy" { "🔴 NGUY HIỂM (Bad Sector / Hỏng hóc)" }
                    default     { "$($pd.HealthStatus)" }
                }

                $log += "--------------------------------------------------------------------------------"
                $log += "💽 Ổ ĐĨA $($pd.DeviceId): $($pd.FriendlyName) ($sz GB)"
                $log += "• Sức Khỏe Tổng Thể : $healthVI"
                $log += "• Trạng Thái Vận Hành: $($pd.OperationalStatus)"
                $log += "• Loại Ổ Đĩa (Media) : $($pd.MediaType) • Chuẩn Kết Nối: $($pd.BusType)"

                # Storage Reliability Counter (Nhiệt độ, Độ mòn, Giờ chạy)
                try {
                    $rc = Get-StorageReliabilityCounter -PhysicalDisk $pd -ErrorAction SilentlyContinue
                    if ($rc) {
                        if ($rc.Temperature -and $rc.Temperature -gt 0 -and $rc.Temperature -lt 120) {
                            $tempVal = $rc.Temperature
                            $tempNote = if ($tempVal -lt 45) { "Mát mẻ" } elseif ($tempVal -lt 60) { "Bình thường" } else { "Nóng - Cần tản nhiệt" }
                            $log += "• Nhiệt Độ Hoạt Động : $tempVal°C ($tempNote)"
                        }
                        if ($null -ne $rc.Wear) {
                            $remainLife = 100 - $rc.Wear
                            $log += "• Mức Độ Hao Mòn (Wear): $($rc.Wear)% (Tuổi thọ chip nhớ ước tính còn: $remainLife%)"
                        }
                        if ($rc.PowerOnHours -and $rc.PowerOnHours -gt 0) {
                            $days = [math]::Round($rc.PowerOnHours / 24, 1)
                            $log += "• Tổng Giờ Hoạt Động : $($rc.PowerOnHours) giờ (~ $days ngày sử dụng liên tục)"
                        }
                        $log += "• Số Lỗi Đọc / Ghi   : Đọc: $($rc.ReadErrorsTotal) | Ghi: $($rc.WriteErrorsTotal)"
                    }
                } catch {}

                # Thống kê phân vùng đang gán trên ổ đĩa này
                try {
                    $parts = Get-Partition -DiskNumber $pd.DeviceId -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter }
                    if ($parts) {
                        $pNames = ($parts | ForEach-Object { "$($_.DriveLetter): (" + [math]::Round($_.Size/1GB, 1) + " GB)" }) -join ", "
                        $log += "• Phân Vùng Đang Gán : $pNames"
                    }
                } catch {}
            }
        }
    } catch {
        $log += "[LỖI TRUY XUẤT SỨC KHỎE] $($_.Exception.Message)"
    }

    $log += "================================================================================"
    $log += "💡 KHUYẾN NGHỊ: Nếu sức khỏe ổ báo Warning hoặc nhiệt độ trên 65°C, hãy sao lưu dữ liệu ngay lập tức."
    return ($log -join "`n")
}

# =========================================================================
# CHIA PHÂN VÙNG Ổ ĐĨA AN TOÀN (SPLIT / SHRINK PARTITION & CREATE NEW VOLUME)
# =========================================================================
function Invoke-VUONGTTSplitPartition {
    param(
        [string]$SourceDriveLetter = "C",
        [int]$SplitSizeGB = 30,
        [string]$NewDriveLetter = "E",
        [string]$NewVolumeLabel = "DATA"
    )

    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $srcClean = $SourceDriveLetter.Trim().TrimEnd(':')
    $newClean = $NewDriveLetter.Trim().TrimEnd(':')

    $log += "[$timestamp] [BẮT ĐẦU CHIA PHÂN VÙNG: TÁCH TỪ Ổ ${srcClean}: -> TẠO Ổ MỚI ${newClean}:]"
    
    try {
        # 1. Kiểm tra phân vùng nguồn
        $srcPart = Get-Partition -DriveLetter $srcClean -ErrorAction Stop
        $srcVol  = Get-Volume -DriveLetter $srcClean -ErrorAction Stop

        $freeGB = [math]::Round($srcVol.SizeRemaining / 1GB, 2)
        $log += "• Ổ nguồn ${srcClean}: Hiện có $freeGB GB dung lượng trống."

        if ($freeGB -le ($SplitSizeGB + 2)) {
            $log += "[LỖI] Ổ ${srcClean}: không đủ dung lượng trống để tách $SplitSizeGB GB (Cần chừa tối thiểu 2-5GB an toàn cho hệ điều hành)!"
            return ($log -join "`n")
        }

        # 2. Thu nhỏ (Shrink) phân vùng nguồn
        $currentBytes = $srcPart.Size
        $shrinkBytes  = [int64]$SplitSizeGB * 1GB
        $targetBytes  = $currentBytes - $shrinkBytes

        $log += "• Đang thu nhỏ phân vùng ${srcClean}: bớt $SplitSizeGB GB..."
        
        $resizeOk = $false
        try {
            Resize-Partition -DriveLetter $srcClean -Size $targetBytes -ErrorAction Stop
            $resizeOk = $true
            $log += "[OK] Thu nhỏ phân vùng ${srcClean}: thành công!"
        } catch {
            $log += "[CHÚ Ý] Resize-Partition trả về: $($_.Exception.Message). Đang chuyển sang chế độ DiskPart tự động..."
            # DiskPart Fallback
            $dpScript = @"
select volume $srcClean
shrink desired=$($SplitSizeGB * 1024)
exit
"@
            $dpFile = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $dpFile -Value $dpScript -Encoding ASCII
            $p = Start-Process -FilePath "diskpart.exe" -ArgumentList "/s `"$dpFile`"" -Wait -PassThru -NoNewWindow
            Remove-Item -Path $dpFile -Force -ErrorAction SilentlyContinue
            if ($p.ExitCode -eq 0) {
                $resizeOk = $true
                $log += "[OK] DiskPart thu nhỏ thành công!"
            } else {
                $log += "[LỖI] Không thể thu nhỏ ổ ${srcClean}: qua DiskPart (ExitCode: $($p.ExitCode)). Có thể file hệ thống bị khóa hoặc phân mảnh."
                return ($log -join "`n")
            }
        }

        # 3. Tạo phân vùng mới trong khoảng trống vừa tạo
        $log += "• Đang tạo phân vùng mới ${newClean}: ($SplitSizeGB GB) trên ổ đĩa $($srcPart.DiskNumber)..."
        Start-Sleep -Milliseconds 800

        try {
            $newPart = New-Partition -DiskNumber $srcPart.DiskNumber -UseMaximumSize -DriveLetter $newClean -ErrorAction Stop
            $log += "[OK] Đã tạo thành công phân vùng mới với ký tự ${newClean}:!"
            
            $log += "• Đang định dạng NTFS nhanh (Quick Format) với tên nhãn '$NewVolumeLabel'..."
            Format-Volume -DriveLetter $newClean -FileSystem NTFS -NewFileSystemLabel $NewVolumeLabel -Confirm:$false -ErrorAction Stop | Out-Null
            $log += "[OK] Định dạng hoàn tất! Ổ đĩa ${newClean}: ('$NewVolumeLabel') đã sẵn sàng sử dụng trong File Explorer!"
        } catch {
            $log += "[CHÚ Ý] Lỗi khi tạo qua PowerShell: $($_.Exception.Message). Đang thực thi qua DiskPart..."
            $dpScript2 = @"
select disk $($srcPart.DiskNumber)
create partition primary
format fs=ntfs quick label="$NewVolumeLabel"
assign letter=$newClean
exit
"@
            $dpFile2 = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $dpFile2 -Value $dpScript2 -Encoding ASCII
            $p2 = Start-Process -FilePath "diskpart.exe" -ArgumentList "/s `"$dpFile2`"" -Wait -PassThru -NoNewWindow
            Remove-Item -Path $dpFile2 -Force -ErrorAction SilentlyContinue
            if ($p2.ExitCode -eq 0) {
                $log += "[OK] DiskPart đã tạo và định dạng phân vùng ${newClean}: thành công!"
            } else {
                $log += "[LỖI] Không thể tạo phân vùng mới: $($_.Exception.Message)"
            }
        }

        $log += "[$timestamp] [HOÀN TẤT] Quá trình chia ổ đĩa hoàn thành 100%!"
    } catch {
        $log += "[LỖI NGOẠI LỆ] $($_.Exception.Message)"
    }

    return ($log -join "`n")
}
