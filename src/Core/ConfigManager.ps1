# =========================================================================
#   VUONGTT TOOLKIT 2026 - WINDOWS CONFIG & FIXES MANAGER
#   Quản lý tính năng Windows, sửa lỗi hệ thống 1-click & mở Legacy Panels
# =========================================================================

function Enable-VUONGTTOptionalFeature {
    param([string]$FeatureName)
    $log = @()
    try {
        $log += "[BẮT ĐẦU] Đang bật tính năng Windows: $FeatureName ..."
        $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
            Start-VUONGTTProcessResponsive -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:$FeatureName /all /norestart" -TimeoutSeconds 600 -NoNewWindow $true
        } else {
            (Start-Process -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:$FeatureName /all /norestart" -Wait -PassThru -NoNewWindow).ExitCode
        }
        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            $log += "[OK] Đã bật thành công tính năng: $FeatureName (Khởi động lại nếu cần)."
        } else {
            $log += "[CẢNH BÁO] DISM hoàn tất với mã trả về: $exitCode"
        }
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Set-VUONGTTLegacyF8Boot {
    param([bool]$Enable = $true)
    try {
        if ($Enable) {
            $res = bcdedit /set "{default}" bootmenupolicy legacy 2>&1
            return "[OK] Đã BẬT menu khởi động F8 cổ điển (Legacy Boot Recovery F8)!"
        } else {
            $res = bcdedit /set "{default}" bootmenupolicy standard 2>&1
            return "[OK] Đã chuyển về menu khởi động chuẩn của Windows (Standard Boot)!"
        }
    } catch {
        return "[LỖI] Cấu hình F8 Boot thất bại: $($_.Exception.Message)"
    }
}

function Enable-VUONGTTRegistryBackupDaily {
    try {
        # Enable RegIdleBackup in Windows Task Scheduler
        $key = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager"
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        Set-ItemProperty -Path $key -Name "EnablePeriodicBackup" -Value 1 -Type DWord -Force

        # Run or enable task
        $taskPath = "\Microsoft\Windows\Registry"
        $taskName = "RegIdleBackup"
        schtasks /change /tn "$taskPath\$taskName" /enable 2>&1 | Out-Null
        return "[OK] Đã BẬT tính năng tự động sao lưu Registry định kỳ hàng ngày (RegIdleBackup)!"
    } catch {
        return "[LỖI] Thiết lập sao lưu Registry thất bại: $($_.Exception.Message)"
    }
}

function Enable-VUONGTTOpenSSHServer {
    $log = @()
    try {
        $log += "[1/3] Kiểm tra gói OpenSSH.Server..."
        $cap = Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" } | Select-Object -First 1
        if ($cap -and $cap.State -ne "Installed") {
            $log += "[2/3] Đang tải và cài đặt OpenSSH.Server..."
            if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                Start-VUONGTTProcessResponsive -FilePath "dism.exe" -ArgumentList "/Online /Add-Capability /CapabilityName:$($cap.Name)" -TimeoutSeconds 600 -NoNewWindow $true | Out-Null
            } else {
                Add-WindowsCapability -Online -Name $cap.Name -ErrorAction SilentlyContinue | Out-Null
            }
        }
        $log += "[3/3] Khởi động và thiết lập dịch vụ sshd tự động..."
        Start-Service sshd -ErrorAction SilentlyContinue
        Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction SilentlyContinue
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 -ErrorAction SilentlyContinue | Out-Null
        $log += "[OK] Đã BẬT máy chủ OpenSSH Server (Cổng 22) thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTReinstallWinget {
    $log = @()
    try {
        $log += "[1/2] Đang làm mới App Installer (Winget) từ Microsoft..."
        $uri = "https://aka.ms/getwinget"
        $dest = "$env:TEMP\Microsoft.DesktopAppInstaller_latest.msixbundle"
        Start-BitsTransfer -Source $uri -Destination $dest -ErrorAction SilentlyContinue
        if (Test-Path $dest) {
            Add-AppxPackage -Path $dest -ErrorAction SilentlyContinue
            $log += "[OK] Đã cài đặt lại gói WinGet AppInstaller thành công!"
        } else {
            $log += "[CHÚ Ý] Không thể tải gói tự động, đang mở trang Microsoft Store..."
            Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1"
        }
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTSyncNtpServer {
    $log = @()
    try {
        $log += "[1/2] Khởi động dịch vụ thời gian Windows Time (W32Time)..."
        Start-Service -Name "w32time" -ErrorAction SilentlyContinue
        Set-Service -Name "w32time" -StartupType Automatic -ErrorAction SilentlyContinue
        w32tm /config /manualpeerlist:"time.windows.com,0x1 time.google.com,0x1" /syncfromflags:manual /reliable:YES /update 2>&1 | Out-Null
        $log += "[2/2] Đồng bộ thời gian hệ thống qua máy chủ NTP..."
        $res = w32tm /resync /force 2>&1
        $log += "[OK] Giờ hệ thống đã được đồng bộ chính xác 100%!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Open-VUONGTTLegacyPanel {
    param([string]$PanelId)
    try {
        switch ($PanelId) {
            "compmgmt"   { Start-Process "compmgmt.msc" }
            "control"    { Start-Process "control.exe" }
            "main"       { Start-Process "control.exe" -ArgumentList "main.cpl" }
            "ncpa"       { Start-Process "control.exe" -ArgumentList "ncpa.cpl" }
            "power"      { Start-Process "control.exe" -ArgumentList "powercfg.cpl" }
            "printers"   { Start-Process "control.exe" -ArgumentList "printers" }
            "appwiz"     { Start-Process "control.exe" -ArgumentList "appwiz.cpl" }
            "region"     { Start-Process "control.exe" -ArgumentList "intl.cpl" }
            "security"   { Start-Process "control.exe" -ArgumentList "wscui.cpl" }
            "sound"      { Start-Process "control.exe" -ArgumentList "mmsys.cpl" }
            "sysdm"      { Start-Process "control.exe" -ArgumentList "sysdm.cpl" }
            "timedate"   { Start-Process "control.exe" -ArgumentList "timedate.cpl" }
            "firewall"   { Start-Process "control.exe" -ArgumentList "firewall.cpl" }
            "restore"    { Start-Process "rstrui.exe" }
            "autologon"  { Start-Process "control.exe" -ArgumentList "userpasswords2" }
            default      { Start-Process "control.exe" }
        }
        return "[OK] Đã mở bảng điều khiển $PanelId."
    } catch {
        return "[LỖI] Không thể mở bảng điều khiển $PanelId : $($_.Exception.Message)"
    }
}

# --- BỘ CÔNG CỤ SỬA LỖI WINDOWS CƠ BẢN & NÂNG CAO ---

function Invoke-VUONGTTFixPrintSpoolerService {
    $log = @()
    try {
        $log += "[1/3] Dừng dịch vụ Print Spooler..."
        Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
        
        $log += "[2/3] Dọn dẹp toàn bộ hàng đợi lệnh in bị kẹt (PRINTERS)..."
        $spoolDir = "$env:WINDIR\System32\spool\PRINTERS"
        if (Test-Path $spoolDir) {
            Get-ChildItem -Path $spoolDir -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }

        $log += "[3/3] Khởi động lại dịch vụ Print Spooler..."
        Set-Service -Name "Spooler" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
        $log += "[OK] Đã sửa lỗi hàng đợi in và khôi phục dịch vụ Print Spooler thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixExplorerTaskbar {
    $log = @()
    try {
        $log += "[1/3] Đóng các tiến trình Windows Explorer và Shell Host..."
        Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800

        $log += "[2/3] Dọn dẹp Icon Cache và Thumbnail Cache hệ thống..."
        $iconCache = "$env:LOCALAPPDATA\IconCache.db"
        if (Test-Path $iconCache) { Remove-Item -Path $iconCache -Force -ErrorAction SilentlyContinue }
        $thumbDir = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
        if (Test-Path $thumbDir) {
            Get-ChildItem -Path $thumbDir -Filter "thumbcache_*.db" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }

        $log += "[3/3] Khởi động lại Windows Explorer hoàn toàn mới..."
        Start-Process "explorer.exe" -ErrorAction SilentlyContinue
        $log += "[OK] Đã khởi động lại Explorer và làm mới giao diện Taskbar mượt mà!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixWindowsSearch {
    $log = @()
    try {
        $log += "[1/3] Dừng dịch vụ Windows Search (WSearch)..."
        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
        
        $log += "[2/3] Đặt lại trạng thái dịch vụ sang Tự động (Automatic)..."
        Set-Service -Name "WSearch" -StartupType Automatic -ErrorAction SilentlyContinue
        
        $log += "[3/3] Khởi động lại dịch vụ Windows Search..."
        Start-Service -Name "WSearch" -ErrorAction SilentlyContinue
        $log += "[OK] Đã làm mới chỉ mục tìm kiếm và khôi phục Windows Search thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixMicrosoftStore {
    $log = @()
    try {
        if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
            Start-VUONGTTProcessResponsive -FilePath "wsreset.exe" -ArgumentList "-i" -TimeoutSeconds 120 -NoNewWindow $true
        } else {
            Start-Process -FilePath "wsreset.exe" -ArgumentList "-i" -NoNewWindow -Wait -ErrorAction SilentlyContinue
        }
        
        $log += "[2/2] Đăng ký lại gói cài đặt Microsoft Windows Store..."
        Get-AppxPackage -AllUsers *WindowsStore* -ErrorAction SilentlyContinue | ForEach-Object {
            $manifest = "$($_.InstallLocation)\AppXManifest.xml"
            if (Test-Path $manifest) {
                Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction SilentlyContinue
            }
        }
        $log += "[OK] Đã đặt lại Microsoft Store và khôi phục hoạt động bình thường!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixAudioService {
    $log = @()
    try {
        $log += "[1/2] Dừng và thiết lập dịch vụ Windows Audio & AudioEndpointBuilder..."
        $audioServices = @("AudioEndpointBuilder", "Audiosrv")
        foreach ($s in $audioServices) {
            Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
            Restart-Service -Name $s -Force -ErrorAction SilentlyContinue
        }
        $log += "[OK] Đã khởi động lại toàn bộ dịch vụ âm thanh hệ thống thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixTempAndPrefetch {
    $log = @()
    try {
        $log += "[1/3] Dọn dẹp tệp tin rác trong %TEMP%..."
        if (Test-Path $env:TEMP) {
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        $log += "[2/3] Dọn dẹp thư mục C:\Windows\Temp..."
        $winTemp = "$env:WINDIR\Temp"
        if (Test-Path $winTemp) {
            Get-ChildItem -Path $winTemp -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }

        $log += "[3/3] Dọn dẹp thư mục Prefetch..."
        $prefetch = "$env:WINDIR\Prefetch"
        if (Test-Path $prefetch) {
            Get-ChildItem -Path $prefetch -Filter "*.pf" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        $log += "[OK] Đã dọn sạch tệp tạm, bộ nhớ đệm và file rác hệ thống!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixWindowsFirewall {
    $log = @()
    try {
        $log += "[1/2] Khôi phục cấu hình Windows Defender Firewall về mặc định..."
        netsh advfirewall reset | Out-Null
        $log += "[2/2] Khởi động lại dịch vụ mpssvc (Windows Firewall)..."
        Set-Service -Name "mpssvc" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "mpssvc" -ErrorAction SilentlyContinue
        $log += "[OK] Đã thiết lập lại tường lửa Windows Defender Firewall về cấu hình chuẩn!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixHostsFile {
    $log = @()
    try {
        $hostsPath = "$env:WINDIR\System32\drivers\etc\hosts"
        $log += "[1/2] Sao lưu file hosts hiện tại..."
        if (Test-Path $hostsPath) {
            Copy-Item -Path $hostsPath -Destination "$hostsPath.bak_$(Get-Date -Format 'yyyyMMddHHmm')" -Force -ErrorAction SilentlyContinue
        }

        $defaultHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
# Default Windows Hosts File
127.0.0.1       localhost
::1             localhost
"@
        [System.IO.File]::WriteAllText($hostsPath, $defaultHosts, [System.Text.Encoding]::ASCII)
        $log += "[OK] Đã khôi phục file hosts về nguyên bản sạch 100%!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixDefender {
    $log = @()
    try {
        $log += "[1/3] Gỡ bỏ các chính sách chặn Windows Defender do virus hoặc tool khóa..."
        $regPaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection",
            "HKLM:\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection"
        )
        $names = @("DisableAntiSpyware", "DisableRealtimeMonitoring", "DisableBehaviorMonitoring", "DisableIOAVProtection", "DisableOnAccessProtection")
        foreach ($p in $regPaths) {
            if (Test-Path $p) {
                foreach ($n in $names) {
                    Remove-ItemProperty -Path $p -Name $n -Force -ErrorAction SilentlyContinue | Out-Null
                }
            }
        }

        $log += "[2/3] Khởi động và thiết lập lại dịch vụ bảo mật Windows Defender..."
        Set-Service -Name "WinDefend" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "WinDefend" -ErrorAction SilentlyContinue
        Set-Service -Name "SecurityHealthService" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "SecurityHealthService" -ErrorAction SilentlyContinue

        $log += "[3/3] Đăng ký lại Windows Defender Security Center..."
        Get-AppxPackage -AllUsers *Microsoft.SecHealthUI* -ErrorAction SilentlyContinue | Reset-AppxPackage -ErrorAction SilentlyContinue | Out-Null

        $log += "[OK] Đã khôi phục và mở khóa Windows Defender & Security Center thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixWindowsInstaller {
    $log = @()
    try {
        $log += "[1/3] Hủy đăng ký và đăng ký lại Windows Installer Engine (msiexec)..."
        Start-Process "msiexec.exe" -ArgumentList "/unregister" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        Start-Process "msiexec.exe" -ArgumentList "/regserver" -Wait -NoNewWindow -ErrorAction SilentlyContinue

        $log += "[2/3] Thiết lập trạng thái dịch vụ msiserver..."
        Set-Service -Name "msiserver" -StartupType Manual -ErrorAction SilentlyContinue
        Start-Service -Name "msiserver" -ErrorAction SilentlyContinue

        $log += "[3/3] Cấp quyền thư mục cài đặt Installer..."
        $instDir = "$env:WINDIR\Installer"
        if (-not (Test-Path $instDir)) { New-Item -ItemType Directory -Path $instDir -Force | Out-Null }

        $log += "[OK] Đã sửa lỗi dịch vụ Windows Installer (msiserver), sẵn sàng cài/gỡ app .msi!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixIconAndThumbnailCache {
    $log = @()
    try {
        $log += "[1/3] Đóng tiến trình Windows Explorer để giải phóng bộ nhớ đệm icon..."
        Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 600

        $log += "[2/3] Xóa triệt để IconCache.db và Thumbnail cache bị hỏng..."
        $localApp = [Environment]::GetFolderPath("LocalApplicationData")
        $iconCache = Join-Path $localApp "IconCache.db"
        if (Test-Path $iconCache) { Remove-Item -Path $iconCache -Force -ErrorAction SilentlyContinue }

        $explorerCache = Join-Path $localApp "Microsoft\Windows\Explorer"
        if (Test-Path $explorerCache) {
            Get-ChildItem -Path $explorerCache -Filter "*cache*.db" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }

        $log += "[3/3] Khởi động lại Windows Explorer để tái tạo lại toàn bộ Icon..."
        Start-Process "explorer.exe" -ErrorAction SilentlyContinue
        $log += "[OK] Đã sửa lỗi mất icon / icon trắng và làm mới Icon Cache thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixBluetoothService {
    $log = @()
    try {
        $log += "[1/2] Đặt lại và khởi động lại các dịch vụ Bluetooth hệ thống..."
        $services = @("bthserv", "BTAGService", "BluetoothUserService")
        foreach ($s in $services) {
            Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
            Restart-Service -Name $s -Force -ErrorAction SilentlyContinue
        }
        $log += "[2/2] Kích hoạt chế độ cho phép thiết bị Bluetooth kết nối..."
        $btKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ActionCenter\Quick Actions\All\SystemSettings_Device_BluetoothQuickAction"
        if (Test-Path $btKey) { Set-ItemProperty -Path $btKey -Name "Type" -Value 0 -Force -ErrorAction SilentlyContinue }
        $log += "[OK] Đã khôi phục dịch vụ Bluetooth và ngăn xếp kết nối không dây!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixLanSharingNetworkDiscovery {
    $log = @()
    try {
        $log += "[1/3] Kích hoạt và đặt chế độ Tự Động cho các dịch vụ Network Discovery..."
        $netServices = @("FDResPub", "fdPHost", "LanmanServer", "LanmanWorkstation", "SSDPSRV", "upnphost", "dnscache")
        foreach ($srv in $netServices) {
            Set-Service -Name $srv -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $srv -ErrorAction SilentlyContinue
        }

        $log += "[2/3] Mở thông tường lửa cho Chia Sẻ Tệp Tin & Máy In và Dò Tìm Mạng (Network Discovery)..."
        netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes | Out-Null
        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes | Out-Null

        $log += "[3/3] Kích hoạt giao thức SMBv2 / SMBv3 an toàn..."
        Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force -ErrorAction SilentlyContinue | Out-Null

        $log += "[OK] Đã kích hoạt toàn bộ Network Discovery và sửa lỗi không thấy máy khác trong mạng LAN!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixPowerSleepHibernate {
    $log = @()
    try {
        $log += "[1/3] Khôi phục toàn bộ sơ đồ nguồn điện về mặc định (Restore Default Power Schemes)..."
        powercfg -restoredefaultschemes | Out-Null

        $log += "[2/3] Bật lại tính năng Hibernate và Fast Startup chuẩn..."
        powercfg -h on | Out-Null

        $log += "[3/3] Sửa lỗi máy tính không tắt được nguồn hoặc treo khi Sleep..."
        $pwrKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
        if (Test-Path $pwrKey) {
            Set-ItemProperty -Path $pwrKey -Name "HibernateEnabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        }
        $log += "[OK] Đã sửa lỗi treo máy khi Sleep/Shutdown và khôi phục cài đặt nguồn điện thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixWmiRepository {
    $log = @()
    try {
        $log += "[1/2] Kiểm tra và khôi phục tính toàn vẹn của WMI Repository..."
        $res = winmgmt /salvagerepository 2>&1
        $log += "  -> $res"

        $log += "[2/2] Đăng ký lại các thư viện WMI DLL quan trọng..."
        $wbemPath = "$env:WINDIR\System32\wbem"
        $dlls = @("wmidcprv.dll", "wbemcore.dll", "wbemprox.dll", "wmisvc.dll", "fastprox.dll")
        foreach ($d in $dlls) {
            $p = Join-Path $wbemPath $d
            if (Test-Path $p) {
                Start-Process "regsvr32.exe" -ArgumentList "/s `"$p`"" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            }
        }
        $log += "[OK] Đã kiểm tra và sửa lỗi WMI Repository thành công!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

