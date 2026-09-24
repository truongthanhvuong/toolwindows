$path = "e:\toolwindows\VUONGTT_Toolkit.ps1"
$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)

# 1. Đoạn code mới cho btnBackupFullWindowsSystem
$newWinBlock = @'
if ($btnBackupFullWindowsSystem) {
    $btnBackupFullWindowsSystem.Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "CHỌN Ổ ĐĨA ĐÍCH ĐỂ LƯU BẢN SAO LƯU TOÀN BỘ WINDOWS (SYSTEM IMAGE):`n(Chọn ổ đĩa D:, E:, USB hoặc ổ cứng ngoài khác ổ C:)"
        $fbd.ShowNewFolderButton = $false

        # Gợi ý ổ đĩa mặc định: ưu tiên lấy từ ComboBox hoặc ổ đĩa candidate đầu tiên
        $defaultDrive = "D:\"
        if ($cmbBackupTargetDrive -and $script:candidateBackupDrives -and $script:candidateBackupDrives.Count -gt 0) {
            $selIdx = $cmbBackupTargetDrive.SelectedIndex
            if ($selIdx -ge 0 -and $selIdx -lt $script:candidateBackupDrives.Count) {
                $defaultDrive = "$($script:candidateBackupDrives[$selIdx].DeviceID)\"
            }
        }
        if (Test-Path $defaultDrive) { $fbd.SelectedPath = $defaultDrive }

        if ($fbd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            &$logSystemBackupMsg "[HỦY BỎ] Người dùng đã hủy chọn ổ đĩa sao lưu Windows."
            return
        }

        $checkDrive = Test-VUONGTTWindowsBackupTargetDrive -SelectedDriveOrPath $fbd.SelectedPath
        if (-not $checkDrive.Valid) {
            if ($checkDrive.Error -eq "CannotBackupToSystemDrive") {
                [System.Windows.MessageBox]::Show("Không thể chọn ổ $env:SystemDrive làm nơi lưu trữ System Image cho chính nó theo quy định của Windows.`nVui lòng chọn ổ đĩa khác (D:, E:, USB...)!", "Cảnh Báo Ổ Đĩa", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            } elseif ($checkDrive.Error -eq "RequireNTFS") {
                [System.Windows.MessageBox]::Show("Ổ đĩa $($checkDrive.DriveRoot) đang có định dạng $($checkDrive.FileSystem).`n`nCông cụ Windows System Image (WBAdmin) yêu cầu ổ đĩa đích phải được định dạng NTFS.`nVui lòng format ổ $($checkDrive.DriveRoot) sang NTFS hoặc chọn ổ đĩa khác.", "Cần Định Dạng NTFS", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            }
            return
        }

        $targetDrive = $checkDrive.DriveRoot

        # Đồng bộ vào danh sách ComboBox và ứng viên sao lưu
        $foundCandidate = $script:candidateBackupDrives | Where-Object { $_.DeviceID -eq $targetDrive }
        if (-not $foundCandidate) {
            $customObj = [PSCustomObject]@{
                DeviceID    = $targetDrive
                VolumeName  = "Tùy Chọn"
                FileSystem  = "NTFS"
                FreeGB      = 999
                TotalGB     = 999
                IsNTFS      = $true
                IsFit       = $true
                DisplayText = "[$targetDrive] Ổ đĩa tùy chọn do người dùng chỉ định"
            }
            $script:candidateBackupDrives += $customObj
            $cmbBackupTargetDrive.Items.Add($customObj.DisplayText) | Out-Null
        }
        for ($idx = 0; $idx -lt $script:candidateBackupDrives.Count; $idx++) {
            if ($script:candidateBackupDrives[$idx].DeviceID -eq $targetDrive) {
                $cmbBackupTargetDrive.SelectedIndex = $idx
                break
            }
        }

        # Lấy thông số dung lượng thực tế
        $freeGB = 0; $totalGB = 0
        try {
            $dInfo = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.Name.TrimEnd('\') -ieq $targetDrive } | Select-Object -First 1
            if ($dInfo) {
                $freeGB = [math]::Round($dInfo.AvailableFreeSpace / 1GB, 1)
                $totalGB = [math]::Round($dInfo.TotalSize / 1GB, 1)
            }
        } catch {}

        $sysDrive = $env:SystemDrive
        $confirmMsg = "BẠN CÓ MUỐN BẮT ĐẦU SAO LƯU NGUYÊN TRẠNG TOÀN BỘ WINDOWS & TỆP TIN?`n`n" +
                      "• Nơi lưu trữ bản sao lưu: $targetDrive\WindowsImageBackup`n" +
                      "• Trạng thái ổ đích: Trống $freeGB GB / Tổng $totalGB GB (NTFS)`n" +
                      "• Nguồn sao lưu: Ổ $sysDrive (Hệ điều hành Windows, Boot EFI, Toàn bộ file dữ liệu người dùng)`n`n" +
                      "💡 Quá trình sao lưu sẽ chạy trong cửa sổ dòng lệnh trực quan thời gian thực (10 - 25 phút).`n`n" +
                      "Bấm 'Yes' để bắt đầu sao lưu ngay bây giờ!"

        $confirm = [System.Windows.MessageBox]::Show($confirmMsg, "Xác Nhận Sao Lưu Toàn Bộ Windows", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) {
            &$logSystemBackupMsg "[HỦY BỎ] Người dùng đã hủy xác nhận sao lưu."
            return
        }

        &$logSystemBackupMsg "[BẮT ĐẦU] Đang khởi chạy tiến trình sao lưu toàn bộ Windows sang ổ $targetDrive..."
        $res = Start-VUONGTTFullWindowsBackup -TargetDrive $targetDrive -OnProgress {
            param($m)
            &$logSystemBackupMsg "$m"
        }
        &$logSystemBackupMsg "$($res.Message)"
        if ($txtFooterStatus) { $txtFooterStatus.Text = "• [OK] Đã khởi chạy sao lưu Windows & Tệp tin sang $targetDrive" }
    })
}
'@

# 2. Đoạn code mới cho btnBackupAllDrivers
$newDrvBlock = @'
if ($btnBackupAllDrivers) {
    $btnBackupAllDrivers.Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        $fbd.Description = "CHỌN Ổ ĐĨA HOẶC THƯ MỤC ĐỂ LƯU TOÀN BỘ DRIVER (D:, E:, USB...):"
        $defaultPath = if ($script:SelectedDriverBackupDir) { $script:SelectedDriverBackupDir } else { Get-VUONGTTDefaultDriverBackupPath }
        $fbd.SelectedPath = [System.IO.Path]::GetPathRoot($defaultPath)
        $fbd.ShowNewFolderButton = $true

        if ($fbd.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
            if ($txtDriverLog) { $txtDriverLog.Text = "[HỦY BỎ] Người dùng đã hủy chọn vị trí sao lưu Driver.`n$($txtDriverLog.Text)" }
            return
        }

        $resTarget = Resolve-VUONGTTDriverBackupTarget -SelectedPath $fbd.SelectedPath
        if (-not $resTarget.Success) {
            if ($txtDriverLog) { $txtDriverLog.Text = "[HỦY BỎ] Thư mục chọn không hợp lệ.`n$($txtDriverLog.Text)" }
            return
        }

        $destDir = $resTarget.TargetPath
        $driveLetter = $resTarget.DriveRoot

        if ($resTarget.IsSystemDrive) {
            $warnSys = [System.Windows.MessageBox]::Show("⚠️ CẢNH BÁO Ổ ĐĨA HỆ THỐNG:`n`nBạn đang chọn lưu Driver lên ổ $env:SystemDrive (ổ đĩa cài Windows).`nKhi cài lại Windows hoặc format ổ C:, toàn bộ bản sao lưu Driver này sẽ BỊ MẤT!`n`nBạn có chắc chắn muốn tiếp tục lưu trên ổ $env:SystemDrive không?", "Cảnh Báo Vị Trí Lưu", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($warnSys -ne [System.Windows.MessageBoxResult]::Yes) {
                if ($txtDriverLog) { $txtDriverLog.Text = "[HỦY BỎ] Đã hủy sao lưu do chọn ổ hệ thống C:.`n$($txtDriverLog.Text)" }
                return
            }
        }

        $confirmMsg = "XÁC NHẬN BẮT ĐẦU SAO LƯU TOÀN BỘ DRIVER HỆ THỐNG`n`n" +
                      "📁 Thư mục lưu trữ: $destDir`n" +
                      "💾 Ổ đĩa đích: $driveLetter`n`n" +
                      "Bấm 'Yes' để bắt đầu trích xuất toàn bộ Driver phần cứng ngay bây giờ!"

        $choice = [System.Windows.MessageBox]::Show($confirmMsg, "Xác Nhận Nơi Sao Lưu Driver", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($choice -ne [System.Windows.MessageBoxResult]::Yes) {
            if ($txtDriverLog) { $txtDriverLog.Text = "[HỦY BỎ] Người dùng đã hủy xác nhận sao lưu Driver.`n$($txtDriverLog.Text)" }
            return
        }

        $script:SelectedDriverBackupDir = $destDir
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang quét và sao lưu toàn bộ Driver hệ thống ra $destDir..." }
        Invoke-VUONGTTDoEvents

        try {
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Export-WindowsDriver -Online -Destination $destDir -ErrorAction Stop | Out-Null
            $count = (Get-ChildItem -Path $destDir -Directory -ErrorAction SilentlyContinue).Count
            if ($txtDriverLog) {
                $txtDriverLog.Text = "[THÀNH CÔNG] Đã sao lưu $count gói Driver phần cứng vào thư mục:`n$destDir`nThời gian: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')`n`n💡 Driver được bảo toàn an toàn trên ổ đĩa dữ liệu, không bị mất khi cài lại Windows C:."
            }
            $txtFooterStatus.Text = "• [OK] Đã sao lưu xong $count gói Driver vào $destDir"
            [System.Windows.MessageBox]::Show("Đã sao lưu thành công $count gói Driver vào:`n$destDir`n`nBản sao lưu đã an toàn trên ổ dữ liệu, có thể dùng để khôi phục bất cứ lúc nào!", "Sao Lưu Driver Hoàn Tất", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } catch {
            if ($txtDriverLog) { $txtDriverLog.Text = "[LỖI SAO LƯU DRIVER] $($_.Exception.Message)" }
            [System.Windows.MessageBox]::Show("Không thể sao lưu Driver:`n$($_.Exception.Message)", "Lỗi Sao Lưu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        }
    })
}
'@

$newWinLines = $newWinBlock -split "`r?`n"
$newDrvLines = $newDrvBlock -split "`r?`n"

# Tìm vị trí bắt đầu và kết thúc của 2 block trong mảng $lines
$winStart = -1
$winEnd = -1
$drvStart = -1
$drvEnd = -1

for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match '^if \(\$btnBackupFullWindowsSystem\) \{') {
        $winStart = $i
        # Tìm dấu đóng ngoặc tương ứng
        $depth = 0
        for ($j = $i; $j -lt $lines.Length; $j++) {
            if ($lines[$j].Contains("{")) { $depth += ($lines[$j].ToCharArray() | Where-Object { $_ -eq "{" }).Count }
            if ($lines[$j].Contains("}")) { $depth -= ($lines[$j].ToCharArray() | Where-Object { $_ -eq "}" }).Count }
            if ($depth -eq 0) {
                $winEnd = $j
                break
            }
        }
    }
    if ($lines[$i] -match '^if \(\$btnBackupAllDrivers\) \{') {
        $drvStart = $i
        $depth = 0
        for ($j = $i; $j -lt $lines.Length; $j++) {
            if ($lines[$j].Contains("{")) { $depth += ($lines[$j].ToCharArray() | Where-Object { $_ -eq "{" }).Count }
            if ($lines[$j].Contains("}")) { $depth -= ($lines[$j].ToCharArray() | Where-Object { $_ -eq "}" }).Count }
            if ($depth -eq 0) {
                $drvEnd = $j
                break
            }
        }
    }
}

Write-Host "Win block: $winStart to $winEnd"
Write-Host "Drv block: $drvStart to $drvEnd"

if ($winStart -ge 0 -and $winEnd -gt $winStart -and $drvStart -ge 0 -and $drvEnd -gt $drvStart) {
    # Thay block Driver trước (nằm sau để không làm xáo trộn index)
    $part1 = $lines[0..($drvStart - 1)]
    $part2 = $lines[($drvEnd + 1)..($lines.Length - 1)]
    $lines = @($part1) + @($newDrvLines) + @($part2)

    # Thay block Win (nằm trước)
    $part1 = $lines[0..($winStart - 1)]
    $part2 = $lines[($winEnd + 1)..($lines.Length - 1)]
    $lines = @($part1) + @($newWinLines) + @($part2)

    [System.IO.File]::WriteAllLines($path, $lines, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host "Replaced both blocks successfully with UTF-8 BOM!" -ForegroundColor Green
} else {
    Write-Error "Could not find blocks properly."
}
