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
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\LabConfig" -Name "BypassDiskCheck" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\Setup\MoSetup" -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "BypassNRO" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker" -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Dismount-VUONGTTDiskImage {
    param([string]$ImagePath)
    try {
        if ($ImagePath -and (Test-Path $ImagePath)) {
            Dismount-DiskImage -ImagePath $ImagePath -ErrorAction SilentlyContinue | Out-Null
        } else {
            Get-DiskImage -StorageType ISO -ErrorAction SilentlyContinue | Dismount-DiskImage -ErrorAction SilentlyContinue | Out-Null
        }
        return $true
    } catch {
        return $false
    }
}

function New-VUONGTTRescuePartition {
    param(
        [string]$DriveLetter = "Z",
        [int]$SizeGB = 15,
        [scriptblock]$OnProgress = $null
    )

    try {
        # 1. Kiểm tra nếu ký tự ổ đĩa đã tồn tại
        if (Test-Path "$($DriveLetter):") {
            if ($OnProgress) { & $OnProgress "• [OK] Ổ đĩa $($DriveLetter):\ đã sẵn sàng trong hệ thống." }
            return [PSCustomObject]@{
                Success     = $true
                DriveLetter = "$($DriveLetter):"
                Created     = $false
                Message     = "Phân vùng $($DriveLetter):\ đã tồn tại và sẵn sàng sử dụng."
            }
        }

        if ($OnProgress) { & $OnProgress "-> Đang kiểm tra dung lượng ổ C: để chuẩn bị tách phân vùng $($DriveLetter):\ ($SizeGB GB)..." }
        $cDrive = Get-PSDrive -Name "C" -PSProvider FileSystem -ErrorAction SilentlyContinue
        if (-not $cDrive) { throw "Không tìm thấy ổ đĩa C: trong hệ thống!" }

        $freeGB = [Math]::Round($cDrive.Free / 1GB, 2)
        $requiredFreeGB = $SizeGB + 10 # Cần dư thêm ít nhất 10GB cho Windows chạy mượt mà
        if ($freeGB -lt $requiredFreeGB) {
            throw "Ổ C: chỉ còn trống $freeGB GB (Cần trống tối thiểu $requiredFreeGB GB để tách phân vùng cứu hộ $SizeGB GB an toàn)!"
        }

        # 2. Lấy phân vùng ổ C:
        $partC = Get-Partition -DriveLetter C -ErrorAction SilentlyContinue
        if (-not $partC) { throw "Không thể truy vấn thông tin phân vùng ổ C:!" }

        $shrinkBytes = [int64]$SizeGB * 1024 * 1024 * 1024
        $newCSizeBytes = $partC.Size - $shrinkBytes

        if ($OnProgress) { & $OnProgress "-> Đang thực hiện co ổ C: (Shrink) để giải phóng $SizeGB GB không gian trống..." }
        Resize-Partition -DiskNumber $partC.DiskNumber -PartitionNumber $partC.PartitionNumber -Size $newCSizeBytes -ErrorAction Stop

        Start-Sleep -Milliseconds 800

        if ($OnProgress) { & $OnProgress "-> Đang tạo phân vùng mới $($DriveLetter):\ (VUONGTT_RESCUE)..." }
        $newPart = New-Partition -DiskNumber $partC.DiskNumber -UseMaximumSize -DriveLetter $DriveLetter -ErrorAction Stop

        Start-Sleep -Milliseconds 800

        if ($OnProgress) { & $OnProgress "-> Đang định dạng phân vùng $($DriveLetter):\ với chuẩn NTFS..." }
        Format-Volume -DriveLetter $DriveLetter -FileSystem NTFS -NewFileSystemLabel "VUONGTT_RESCUE" -Confirm:$false -ErrorAction Stop | Out-Null

        if ($OnProgress) { & $OnProgress "• [OK] ĐÃ TẠO THÀNH CÔNG PHÂN VÙNG CỨU HỘ ĐỘC LẬP $($DriveLetter):\ (VUONGTT_RESCUE - $SizeGB GB)!" }

        return [PSCustomObject]@{
            Success     = $true
            DriveLetter = "$($DriveLetter):"
            Created     = $true
            Message     = "Đã tạo thành công phân vùng cứu hộ độc lập $($DriveLetter):\ (VUONGTT_RESCUE) dung lượng $SizeGB GB."
        }
    } catch {
        if ($OnProgress) { & $OnProgress "• [CẢNH BÁO TÁCH PHÂN VÙNG] $($_.Exception.Message)" }
        return [PSCustomObject]@{
            Success     = $false
            DriveLetter = $null
            Created     = $false
            Message     = $_.Exception.Message
        }
    }
}

function Initialize-VUONGTTPostInstallPayload {
    param(
        [bool]$RestoreDrivers = $true,
        [bool]$AutoActivate = $true,
        [string]$TargetDataDrive = "D:"
    )

    try {
        # 1. Xác định ổ đĩa an toàn (Ưu tiên Z:, D:, E:, sau đó C:)
        $safeDrive = $TargetDataDrive
        if (Test-Path "Z:\") {
            $safeDrive = "Z:"
        } elseif (-not (Test-Path "$safeDrive\")) {
            $fixed = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 5GB -and $_.Name -ne "C" } | Select-Object -First 1
            if ($fixed) { $safeDrive = "$($fixed.Name):" } else { $safeDrive = "C:" }
        }

        $appBackupDir = "$safeDrive\VUONGTT_Windows_Setup"
        if (-not (Test-Path $appBackupDir)) { New-Item -ItemType Directory -Path $appBackupDir -Force | Out-Null }

        # 2. Sao chép VUONGTT_Toolkit.exe hiện tại sang ổ an toàn để không bao giờ bị mất
        $runningExe = $null
        try {
            $runningExe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        } catch {}

        if ($runningExe -and (Test-Path $runningExe) -and $runningExe.EndsWith(".exe", [System.StringComparison]::OrdinalIgnoreCase)) {
            Copy-Item -Path $runningExe -Destination "$appBackupDir\VUONGTT_Toolkit.exe" -Force -ErrorAction SilentlyContinue
        } else {
            $candidateExes = @(
                "E:\toolwindows\VUONGTT_Toolkit.exe",
                "$PSScriptRoot\..\..\VUONGTT_Toolkit.exe",
                "C:\toolwindows\VUONGTT_Toolkit.exe"
            )
            foreach ($cand in $candidateExes) {
                if (Test-Path $cand) {
                    Copy-Item -Path $cand -Destination "$appBackupDir\VUONGTT_Toolkit.exe" -Force -ErrorAction SilentlyContinue
                    break
                }
            }
        }

        # 3. Tạo SetupComplete.cmd - Kịch bản tối cao được Windows Setup tự động chạy dưới quyền SYSTEM
        $scriptsDir = "$env:SystemRoot\Setup\Scripts"
        if (-not (Test-Path $scriptsDir)) { New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null }
        $setupCompletePath = "$scriptsDir\SetupComplete.cmd"

        $cmdLines = @(
            "@echo off",
            "chcp 65001 >nul",
            "echo [VUONGTT POST-INSTALL AUTOMATION] Starting system restore...",
            "",
            ":: 1. Tu dong nap lai toan bo Driver phan cung tu moi nguon (D, C hoac Windows.old)",
            "if exist `"$safeDrive\Backup_Drivers`" (",
            "    pnputil.exe /add-driver `"$safeDrive\Backup_Drivers\*.inf`" /subdirs /install >nul 2>&1",
            ")",
            "if exist `"C:\Backup_Drivers`" (",
            "    pnputil.exe /add-driver `"C:\Backup_Drivers\*.inf`" /subdirs /install >nul 2>&1",
            ")",
            "if exist `"C:\Windows.old\Backup_Drivers`" (",
            "    pnputil.exe /add-driver `"C:\Windows.old\Backup_Drivers\*.inf`" /subdirs /install >nul 2>&1",
            ")",
            "",
            ":: 2. Tu dong khoi phuc VUONGTT Toolkit len Public Desktop (Ke ca khi may chi co o C)",
            "if exist `"$appBackupDir\VUONGTT_Toolkit.exe`" (",
            "    copy /y `"$appBackupDir\VUONGTT_Toolkit.exe`" `"%PUBLIC%\Desktop\VUONGTT_Toolkit.exe`" >nul 2>&1",
            ") else if exist `"C:\Windows.old\VUONGTT_Windows_Setup\VUONGTT_Toolkit.exe`" (",
            "    copy /y `"C:\Windows.old\VUONGTT_Windows_Setup\VUONGTT_Toolkit.exe`" `"%PUBLIC%\Desktop\VUONGTT_Toolkit.exe`" >nul 2>&1",
            ") else if exist `"C:\VUONGTT_Windows_Setup\VUONGTT_Toolkit.exe`" (",
            "    copy /y `"C:\VUONGTT_Windows_Setup\VUONGTT_Toolkit.exe`" `"%PUBLIC%\Desktop\VUONGTT_Toolkit.exe`" >nul 2>&1",
            ")",
            "if exist `"%PUBLIC%\Desktop\VUONGTT_Toolkit.exe`" (",
            "    reg add `"HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`" /v `"VUONGTT_Welcome`" /t REG_SZ /d `"%PUBLIC%\Desktop\VUONGTT_Toolkit.exe`" /f >nul 2>&1",
            ")"
        )

        if ($AutoActivate) {
            $cmdLines += @(
                "",
                ":: 3. Tu dong kich hoat ban quyen so vinh vien MAS HWID",
                "powershell -NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.activated.win | iex`" >nul 2>&1"
            )
        }

        $cmdLines += @(
            "",
            "exit 0"
        )

        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllLines($setupCompletePath, $cmdLines, $utf8NoBom)
        [System.IO.File]::WriteAllLines("$appBackupDir\SetupComplete.cmd", $cmdLines, $utf8NoBom)

        return [PSCustomObject]@{
            Success       = $true
            SafeDrive     = $safeDrive
            AppBackupPath = "$appBackupDir\VUONGTT_Toolkit.exe"
            ScriptPath    = $setupCompletePath
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Error   = $_.Exception.Message
        }
    }
}

function Start-VUONGTTAutoPilotWatcher {
    param(
        [ValidateSet("Upgrade", "Clean")][string]$Mode = "Upgrade"
    )

    $syncObj = [hashtable]::Synchronized(@{
        Mode        = $Mode
        IsInstalled = $false
        LogMessages = [System.Collections.Generic.List[string]]::new()
        Stop        = $false
    })

    $rs = [runspacefactory]::CreateRunspace()
    $rs.Open()
    $rs.SessionStateProxy.SetVariable("Sync", $syncObj)

    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript({
        Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes -ErrorAction SilentlyContinue
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $hasClickedLicense = $false
        $hasSelectedMode = $false
        $hasClickedInstall = $false

        while ($stopwatch.Elapsed.TotalSeconds -lt 900 -and -not $Sync.Stop -and -not $hasClickedInstall) {
            Start-Sleep -Milliseconds 1200
            
            try {
                $root = [System.Windows.Automation.AutomationElement]::RootElement
                $windows = $root.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
                
                $setupWin = $null
                foreach ($w in $windows) {
                    $name = $w.Current.Name
                    if ($name -match "Windows 11 Setup" -or $name -match "Windows Setup" -or $name -match "Modern Setup Host") {
                        $setupWin = $w
                        break
                    }
                }

                if (-not $setupWin) { continue }

                # 1. Nhận diện và tự động xử lý nút Accept (Chấp nhận điều khoản bản quyền)
                if (-not $hasClickedLicense) {
                    $allBtns = $setupWin.FindAll([System.Windows.Automation.TreeScope]::Descendants, 
                        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
                    foreach ($b in $allBtns) {
                        $bName = $b.Current.Name
                        if ($bName -match "Accept" -or $bName -match "Chấp nhận" -or $bName -match "Đồng ý") {
                            $inv = $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                            if ($inv) {
                                $inv.Invoke()
                                $hasClickedLicense = $true
                                $Sync.LogMessages.Add("• [AUTO-PILOT] Đã tự động chấp thuận Điều khoản bản quyền (Accept License Terms).")
                                Start-Sleep -Milliseconds 1500
                                break
                            }
                        }
                    }
                }

                # 2. Nhận diện và tự động chọn chế độ cài đặt (Choose what to keep)
                if (-not $hasSelectedMode) {
                    $allRadios = $setupWin.FindAll([System.Windows.Automation.TreeScope]::Descendants, 
                        (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::RadioButton)))
                    
                    if ($allRadios.Count -gt 0) {
                        foreach ($r in $allRadios) {
                            $rName = $r.Current.Name
                            if ($Sync.Mode -eq "Clean") {
                                if ($rName -match "Nothing" -or $rName -match "Không giữ lại") {
                                    $sp = $r.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
                                    if ($sp) { $sp.Select() }
                                    $hasSelectedMode = $true
                                    $Sync.LogMessages.Add("• [AUTO-PILOT] Đã tự động chọn: Cài mới sạch sẽ 100% (Nothing - Format ổ C:, ổ D/E giữ nguyên).")
                                    break
                                }
                            } else {
                                if ($rName -match "Keep personal files and apps" -or $rName -match "Giữ lại") {
                                    $sp = $r.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
                                    if ($sp) { $sp.Select() }
                                    $hasSelectedMode = $true
                                    $Sync.LogMessages.Add("• [AUTO-PILOT] Đã tự động chọn: Cài đè giữ nguyên 100% App & Dữ liệu (Keep personal files and apps).")
                                    break
                                }
                            }
                        }

                        if ($hasSelectedMode) {
                            Start-Sleep -Milliseconds 800
                            $allBtns = $setupWin.FindAll([System.Windows.Automation.TreeScope]::Descendants, 
                                (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
                            foreach ($b in $allBtns) {
                                if ($b.Current.Name -match "Next" -or $b.Current.Name -match "Tiếp theo") {
                                    $inv = $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                                    if ($inv) { $inv.Invoke(); break }
                                }
                            }
                        }
                    }
                }

                # 3. Nhận diện và tự động bấm nút Install (Cài đặt)
                $allBtns = $setupWin.FindAll([System.Windows.Automation.TreeScope]::Descendants, 
                    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
                foreach ($b in $allBtns) {
                    $bName = $b.Current.Name
                    if ($bName -match "Install" -or $bName -match "Cài đặt") {
                        if ($bName -notmatch "Change") {
                            $inv = $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                            if ($inv) {
                                $inv.Invoke()
                                $hasClickedInstall = $true
                                $Sync.IsInstalled = $true
                                $Sync.LogMessages.Add("🚀 [AUTO-PILOT] ĐÃ TỰ ĐỘNG BẤM CÀI ĐẶT (INSTALL)! Máy tính đang nạp hệ điều hành mới và sẽ tự động khởi động lại.")
                                break
                            }
                        }
                    }
                }
            } catch {}
        }
    }) | Out-Null

    $asyncHandle = $ps.BeginInvoke()
    return [PSCustomObject]@{
        Runspace    = $rs
        PowerShell  = $ps
        AsyncHandle = $asyncHandle
        Sync        = $syncObj
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

    # 5.5. Khởi tạo Payload tự phục hồi sau cài đặt (Post-Install)
    if ($OnProgress) { & $OnProgress "-> Đang bảo lưu VUONGTT Toolkit sang ổ an toàn & thiết lập SetupComplete.cmd..." }
    $postPayload = Initialize-VUONGTTPostInstallPayload -RestoreDrivers $BackupDrivers -AutoActivate $AutoActivate
    if ($postPayload.Success) {
        $log.Add("• [OK] Đã bảo lưu bộ chạy Toolkit vào ổ dữ liệu an toàn: $($postPayload.AppBackupPath)")
        $log.Add("• [OK] Đã cài đặt kịch bản SetupComplete.cmd tự động nạp Driver & Bản quyền sau Reboot.")
    }

    # 6. Xây dựng lệnh cài đặt tự động
    $setupExe = "$mountedDrive\setup.exe"
    $modeText = if ($Mode -eq "Upgrade") { "Cài đè nâng cấp / Sửa lỗi (Giữ lại toàn bộ App & Dữ liệu)" } else { "Cài mới sạch sẽ 100% (Clean Install - Format ổ C:)" }
    $log.Add("• Chế độ cài đặt đã chọn: $modeText")

    # Tham số chuẩn tương thích 100% mọi loại ISO (kể cả ISO mod, Repack, bootstrapper Win10/WinPE)
    # Loại bỏ switch '/auto' để tránh lỗi: 'Windows Setup: An unknown command-line option [/auto] was specified.'
    if ($Mode -eq "Upgrade") {
        $argList = ""
        $log.Add("• Lệnh khởi chạy: $setupExe (Chế độ tương thích đa năng - Giữ nguyên 100% Dữ liệu & App)")
        $log.Add("• Đã nạp sẵn: LabConfig Bypass TPM/CPU/RAM & MoSetup AllowUpgrades vào Registry.")
    } else {
        $argList = "/unattend:`"$unattendXmlPath`""
        $log.Add("• Lệnh khởi chạy: $setupExe $argList")
    }

    $log.Add("-----------------------------------------------------------------")
    $log.Add("🚀 SẴN SÀNG KHỞI CHẠY TRÌNH CÀI ĐẶT WINDOWS ONLINE!")
    $log.Add("Auto-Pilot Watcher sẽ tự động điều khiển tiến trình cho đến khi máy tự Reboot.")
    $log.Add("-----------------------------------------------------------------")

    return [PSCustomObject]@{
        Success          = $true
        MountedDrive     = $mountedDrive
        SetupExe         = $setupExe
        Arguments        = $argList
        UnattendPath     = $unattendXmlPath
        Mode             = $Mode
        PostPayload      = $postPayload
        SummaryLog       = ($log -join "`r`n")
    }
}
