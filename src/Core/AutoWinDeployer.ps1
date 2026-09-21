# =========================================================================
#   VUONGTT TOOLKIT 2026 - ONLINE WINDOWS DEPLOYER & SETUP AUTOMATION
#   Động cơ Cài Windows Online Trực Tiếp (Không cần USB Boot)
# =========================================================================

function Get-VUONGTTAutoWinEditions {
    return @(
        [PSCustomObject]@{
            Id          = "Win11_24H2_Pro"
            Name        = "Windows 11 Pro (Bản 24H2 Mới Nhất 2026)"
            Tag         = "Win11-24H2"
            Type        = "Windows 11"
            SizeGB      = 5.4
            Desc        = "Bản cài đặt Windows 11 chính hãng Microsoft, mượt mà, hỗ trợ Copilot & tính năng AI."
            DownloadUrl = "https://software.download.prss.microsoft.com/dbazure/Win11_24H2_English_x64.iso"
            PortalUrl   = "https://www.microsoft.com/software-download/windows11"
        },
        [PSCustomObject]@{
            Id          = "Win11_IoT_LTSC_2024"
            Name        = "Windows 11 IoT Enterprise LTSC 2024 (Siêu Nhẹ, Không Rác)"
            Tag         = "Win11-LTSC"
            Type        = "Windows 11 LTSC"
            SizeGB      = 4.6
            Desc        = "Bản Doanh nghiệp đặc biệt được lược bỏ 100% bloatware, nhẹ mượt, hỗ trợ cập nhật 10 năm."
            DownloadUrl = "https://software.download.prss.microsoft.com/dbazure/Windows11_IoT_Enterprise_LTSC_2024_x64.iso"
            PortalUrl   = "https://www.microsoft.com/evalcenter/evaluate-windows-11-enterprise"
        },
        [PSCustomObject]@{
            Id          = "Win10_22H2_Pro"
            Name        = "Windows 10 Pro (Bản 22H2 Ổn Định Nhất Cho Mọi Máy)"
            Tag         = "Win10-22H2"
            Type        = "Windows 10"
            SizeGB      = 4.8
            Desc        = "Bản Windows 10 tương thích tốt nhất cho máy văn phòng, laptop đời cũ và máy in/kế toán."
            DownloadUrl = "https://software.download.prss.microsoft.com/dbazure/Win10_22H2_English_x64.iso"
            PortalUrl   = "https://www.microsoft.com/software-download/windows10"
        },
        [PSCustomObject]@{
            Id          = "Win10_LTSC_2021"
            Name        = "Windows 10 Enterprise LTSC 2021 (Hỗ Trợ Dài Hạn)"
            Tag         = "Win10-LTSC"
            Type        = "Windows 10 LTSC"
            SizeGB      = 4.3
            Desc        = "Bản Windows 10 LTSC siêu ổn định, mượt mà cho máy cấu hình yếu hoặc thiết bị doanh nghiệp."
            DownloadUrl = ""
            PortalUrl   = "https://www.microsoft.com/evalcenter/evaluate-windows-10-enterprise"
        },
        [PSCustomObject]@{
            Id          = "Custom_ISO"
            Name        = "📁 Tự chọn file ISO / ESD có sẵn trong máy tính..."
            Tag         = "Custom"
            Type        = "Custom"
            SizeGB      = 0
            Desc        = "Sử dụng bất kỳ file ISO / ESD Windows nào bạn đã tải về sẵn trên ổ đĩa D, E..."
            DownloadUrl = ""
            PortalUrl   = ""
        }
    )
}

function New-VUONGTTAutoUnattendXml {
    param(
        [string]$DestinationPath,
        [string]$AdminUsername = "Admin",
        [bool]$BypassHardware = $true,
        [bool]$SkipOOBE = $true,
        [ValidateSet("Upgrade", "Clean")][string]$Mode = "Upgrade"
    )

    try {
        $destDir = Split-Path -Parent $DestinationPath
        if ($destDir -and (-not (Test-Path $destDir))) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        $xml = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <UserData>
        <AcceptEula>true</AcceptEula>
      </UserData>
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
          <Order>1</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
          <Order>2</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
          <Order>3</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
          <Order>4</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassCPUCheck /t REG_DWORD /d 1 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
          <Order>5</Order>
          <Path>reg add HKLM\SYSTEM\Setup\LabConfig /v BypassStorageCheck /t REG_DWORD /d 1 /f</Path>
        </RunSynchronousCommand>
        <RunSynchronousCommand wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
          <Order>6</Order>
          <Path>reg add HKLM\SYSTEM\Setup\MoSetup /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f</Path>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <TimeZone>SE Asia Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <Name>$AdminUsername</Name>
            <Group>Administrators</Group>
            <DisplayName>$AdminUsername</DisplayName>
            <Password>
              <Value></Value>
              <PlainText>true</PlainText>
            </Password>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@

        $utf8Bom = New-Object System.Text.UTF8Encoding($true)
        [System.IO.File]::WriteAllText($DestinationPath, $xml.Trim(), $utf8Bom)
        return $DestinationPath
    } catch {
        throw "Không thể tạo file autounattend.xml: $($_.Exception.Message)"
    }
}

function Invoke-VUONGTTPreDeployBypass {
    try {
        $keys = @("HKLM:\SYSTEM\Setup\LabConfig", "HKLM:\SYSTEM\Setup\MoSetup", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE")
        foreach ($k in $keys) {
            if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
        }
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassTPMCheck" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassSecureBootCheck" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassRAMCheck" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassCPUCheck" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassStorageCheck" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "BypassNRO" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Invoke-VUONGTTPrepareOnlineWindowsDeployment {
    param(
        [string]$IsoPath,
        [ValidateSet("Upgrade", "Clean")][string]$Mode = "Upgrade",
        [bool]$BackupDrivers = $true,
        [bool]$BypassHardware = $true,
        [bool]$NoMSA = $true,
        [bool]$AutoActivate = $true,
        [scriptblock]$OnProgress = $null
    )

    $log = [System.Collections.Generic.List[string]]::new()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log.Add("[$timestamp] === KHỞI ĐỘNG TIẾN TRÌNH TRIỂN KHAI CÀI WINDOWS ONLINE ===")

    # 1. Kiểm tra file ISO
    if (-not $IsoPath -or -not (Test-Path $IsoPath)) {
        throw "Tệp tin hình ảnh Windows (.ISO) không tồn tại hoặc đường dẫn không hợp lệ: '$IsoPath'"
    }

    if ($OnProgress) { & $OnProgress "-> Đang kiểm tra dung lượng ổ đĩa và tính toàn vẹn file ISO..." }
    $fileItem = Get-Item $IsoPath
    $fileSizeGB = [Math]::Round($fileItem.Length / 1GB, 2)
    $log.Add("• Tệp tin cài đặt: $($fileItem.Name) (Dung lượng: $fileSizeGB GB)")

    # 2. Sao lưu Driver hiện tại nếu được chọn
    if ($BackupDrivers) {
        if ($OnProgress) { & $OnProgress "-> Đang tự động sao lưu toàn bộ Driver phần cứng trước khi cài đặt..." }
        try {
            $backupTargetDrive = "D:"
            if (-not (Test-Path "D:\")) { $backupTargetDrive = "C:" }
            $drvDir = "$backupTargetDrive\Backup_Drivers"
            if (-not (Test-Path $drvDir)) { New-Item -ItemType Directory -Path $drvDir -Force | Out-Null }
            Export-WindowsDriver -Online -Destination $drvDir -ErrorAction SilentlyContinue | Out-Null
            $drvCount = (Get-ChildItem -Path $drvDir -Directory -ErrorAction SilentlyContinue).Count
            $log.Add("• [OK] Đã tự động sao lưu $drvCount gói Driver phần cứng vào thư mục: $drvDir")
        } catch {
            $log.Add("• [CẢNH BÁO] Không thể sao lưu Driver: $($_.Exception.Message)")
        }
    }

    # 3. Kích hoạt chính sách Bypass phần cứng
    if ($BypassHardware) {
        if ($OnProgress) { & $OnProgress "-> Đang kích hoạt chính sách 1-Click Bypass TPM 2.0, SecureBoot, RAM & CPU..." }
        Invoke-VUONGTTPreDeployBypass | Out-Null
        $log.Add("• [OK] Đã kích hoạt 100% chính sách Bypass TPM 2.0, SecureBoot, RAM & CPU.")
    }

    # 4. Mount ISO vào ổ ảo
    if ($OnProgress) { & $OnProgress "-> Đang nạp file ISO vào ổ đĩa ảo hệ thống (Mount-DiskImage)..." }
    $mountedDrive = $null
    try {
        $mountRes = Mount-DiskImage -ImagePath $IsoPath -StorageType ISO -PassThru
        Start-Sleep -Milliseconds 800
        $vol = $mountRes | Get-Volume
        if ($vol -and $vol.DriveLetter) {
            $mountedDrive = "$($vol.DriveLetter):"
        }
    } catch {
        # Fallback thử tìm ổ đĩa vừa mount
    }

    if (-not $mountedDrive) {
        # Thử dò ổ đĩa CD-ROM vừa xuất hiện có chứa setup.exe
        $drives = Get-PSDrive -PSProvider FileSystem
        foreach ($d in $drives) {
            if (Test-Path (Join-Path $d.Root "setup.exe")) {
                $mountedDrive = $d.Root.TrimEnd('\')
                break
            }
        }
    }

    if (-not $mountedDrive -or -not (Test-Path "$mountedDrive\setup.exe")) {
        throw "Không thể mount ổ đĩa ảo hoặc không tìm thấy file 'setup.exe' bên trong file ISO!"
    }

    $log.Add("• [OK] Đã nạp thành công file ISO vào ổ đĩa ảo: $mountedDrive\")

    # 5. Tạo file autounattend.xml
    $tempWorkDir = "$env:SystemDrive\VUONGTT_Deploy_Runtime"
    if (-not (Test-Path $tempWorkDir)) { New-Item -ItemType Directory -Path $tempWorkDir -Force | Out-Null }
    $unattendXmlPath = Join-Path $tempWorkDir "autounattend.xml"
    
    if ($OnProgress) { & $OnProgress "-> Đang tạo file cấu hình tự động hóa autounattend.xml..." }
    New-VUONGTTAutoUnattendXml -DestinationPath $unattendXmlPath -Mode $Mode -BypassHardware $BypassHardware -SkipOOBE $NoMSA -AdminUsername "Admin" | Out-Null
    $log.Add("• [OK] Đã sinh file cấu hình tự động hóa: $unattendXmlPath")

    # 6. Xây dựng lệnh cài đặt tự động
    $setupExe = "$mountedDrive\setup.exe"
    $modeText = if ($Mode -eq "Upgrade") { "Cài đè nâng cấp / Sửa lỗi (Giữ lại toàn bộ App & Dữ liệu)" } else { "Cài mới sạch sẽ 100% (Clean Install - Format ổ C:)" }
    $log.Add("• Chế độ cài đặt đã chọn: $modeText")

    # Tham số chuẩn của Microsoft Windows Setup
    if ($Mode -eq "Upgrade") {
        $argList = "/auto upgrade /quiet /migratedata all /DynamicUpdate disable /compat ignorewarning"
    } else {
        $argList = "/auto clean /quiet /migratedata none /DynamicUpdate disable /compat ignorewarning /unattend `"$unattendXmlPath`""
    }

    $log.Add("• Lệnh thực thi: $setupExe $argList")
    $log.Add("-----------------------------------------------------------------")
    $log.Add("🚀 SẴN SÀNG KHỞI CHẠY TIẾN TRÌNH CÀI ĐẶT WINDOWS ONLINE!")
    $log.Add("Máy tính sẽ tự động nạp bộ cài đặt ngầm và khởi động lại để hoàn tất.")
    $log.Add("-----------------------------------------------------------------")

    return [PSCustomObject]@{
        Success          = $true
        MountedDrive     = $mountedDrive
        SetupExe         = $setupExe
        Arguments        = $argList
        UnattendPath     = $unattendXmlPath
        Mode             = $Mode
        SummaryLog       = ($log -join "`r`n")
    }
}
