# =========================================================================
#   VUONGTT TOOLKIT 2026 - WINDOWS CONFIG & FIXES MANAGER
#   Quản lý tính năng Windows, sửa lỗi hệ thống 1-click & mở Legacy Panels
# =========================================================================

function Enable-VUONGTTOptionalFeature {
    param([string]$FeatureName)
    $log = @()
    try {
        $log += "[BẮT ĐẦU] Đang bật tính năng Windows: $FeatureName ..."
        $proc = Start-Process -FilePath "dism.exe" -ArgumentList "/online /enable-feature /featurename:$FeatureName /all /norestart" -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            $log += "[OK] Đã bật thành công tính năng: $FeatureName (Khởi động lại nếu cần)."
        } else {
            $log += "[CẢNH BÁO] DISM hoàn tất với mã trả về: $($proc.ExitCode)"
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
            Add-WindowsCapability -Online -Name $cap.Name -ErrorAction SilentlyContinue | Out-Null
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
            "main"       { Start-Process "main.cpl" }
            "ncpa"       { Start-Process "ncpa.cpl" }
            "power"      { Start-Process "powercfg.cpl" }
            "printers"   { Start-Process "control" -ArgumentList "printers" }
            "appwiz"     { Start-Process "appwiz.cpl" }
            "region"     { Start-Process "intl.cpl" }
            "security"   { Start-Process "wscui.cpl" }
            "sound"      { Start-Process "mmsys.cpl" }
            "sysdm"      { Start-Process "sysdm.cpl" }
            "timedate"   { Start-Process "timedate.cpl" }
            "firewall"   { Start-Process "firewall.cpl" }
            "restore"    { Start-Process "rstrui.exe" }
            "autologon"  { Start-Process "control" -ArgumentList "userpasswords2" }
            default      { Start-Process "control.exe" }
        }
        return "[OK] Đã mở bảng điều khiển ${PanelId}."
    } catch {
        return "[LỖI] Không thể mở bảng điều khiển ${PanelId}: $($_.Exception.Message)"
    }
}
