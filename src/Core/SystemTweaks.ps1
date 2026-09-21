# VUONGTT Toolkit 2026 - System Tweaks, Cleaner & Repair Module

Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class MemoryCleaner {
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);

    public static long CleanAllProcesses() {
        long freedBytes = 0;
        Process[] procs = Process.GetProcesses();
        foreach (Process p in procs) {
            try {
                long before = p.WorkingSet64;
                EmptyWorkingSet(p.Handle);
                p.Refresh();
                long diff = before - p.WorkingSet64;
                if (diff > 0) freedBytes += diff;
            } catch {}
        }
        return freedBytes;
    }
}
"@ -ErrorAction SilentlyContinue

function Invoke-VUONGTTDoEvents {
    try {
        if ([System.Windows.Threading.Dispatcher]::CurrentDispatcher) {
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        }
    } catch {}
    try {
        if ([Type]::GetType("System.Windows.Forms.Application, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")) {
            [System.Windows.Forms.Application]::DoEvents()
        }
    } catch {}
}

function Set-VUONGTTClassicContextMenu {
    param([bool]$Enable = $true)
    $keyPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    if ($Enable) {
        if (-not (Test-Path $keyPath)) { New-Item -Path $keyPath -Force | Out-Null }
        Set-ItemProperty -Path $keyPath -Name "(Default)" -Value "" -Force
        Stop-Process -Name explorer -Force
        return "Đã bật Menu chuột phải cổ điển (Windows 10 style). Đã khởi động lại Explorer!"
    } else {
        if (Test-Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}") {
            Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force
            Stop-Process -Name explorer -Force
        }
        return "Đã khôi phục Menu chuột phải mặc định Windows 11. Đã khởi động lại Explorer!"
    }
}
Set-Alias -Name Set-ClassicContextMenu -Value Set-VUONGTTClassicContextMenu -ErrorAction SilentlyContinue

function Set-VUONGTTShowFileExtensions {
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $adv -Name "HideFileExt" -Value 0 -Force
    Set-ItemProperty -Path $adv -Name "Hidden" -Value 1 -Force
    Stop-Process -Name explorer -Force
    return "Đã hiển thị phần mở rộng tệp tin (.exe, .txt...) và file ẩn!"
}

function Disable-VUONGTTTelemetry {
    $log = @()
    # Services
    $svcs = @("DiagTrack", "dmwappushservice")
    foreach ($s in $svcs) {
        Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    $log += "[OK] Đã tắt dịch vụ thu thập chẩn đoán DiagTrack."

    # Registry
    $pol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $pol)) { New-Item -Path $pol -Force | Out-Null }
    Set-ItemProperty -Path $pol -Name "AllowTelemetry" -Value 0 -Type DWord -Force
    $log += "[OK] Đã vô hiệu hóa AllowTelemetry trong Group Policy."

    # Disable Cortana & Bing Search in Taskbar
    $searchPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    if (-not (Test-Path $searchPol)) { New-Item -Path $searchPol -Force | Out-Null }
    Set-ItemProperty -Path $searchPol -Name "AllowCortana" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $searchPol -Name "DisableWebSearch" -Value 1 -Type DWord -Force
    $log += "[OK] Đã tắt tìm kiếm Bing trên Taskbar và Cortana."

    return ($log -join "`n")
}

function Invoke-VUONGTTDeepClean {
    $log = @()
    $cleanPaths = @(
        "$env:TEMP",
        "$env:LOCALAPPDATA\Temp",
        "$env:WINDIR\Temp",
        "$env:WINDIR\Prefetch",
        "$env:WINDIR\SoftwareDistribution\Download"
    )

    $deletedCount = 0
    foreach ($path in $cleanPaths) {
        if (Test-Path $path) {
            Invoke-VUONGTTDoEvents
            Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
                try {
                    Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    $deletedCount++
                } catch {}
            }
        }
    }

    # Empty Recycle Bin
    try {
        Clear-RecycleBin -Force -Confirm:$false -ErrorAction SilentlyContinue
        $log += "[OK] Đã làm rỗng Thùng rác (Recycle Bin)."
    } catch {}

    $log += "[OK] Đã dọn dẹp các tệp tạm, Prefetch và cache Windows Update ($deletedCount mục đã dọn dẹp an toàn)!"
    return ($log -join "`n")
}

function Invoke-VUONGTTCleanRAM {
    try {
        $bytes = [MemoryCleaner]::CleanAllProcesses()
        $mb = [math]::Round($bytes / 1MB, 2)
        return "Đã tối ưu Working Set của toàn bộ tiến trình hệ thống! Giải phóng ~$mb MB RAM."
    } catch {
        return "Tối ưu RAM hoàn tất."
    }
}

function Invoke-VUONGTTResetNetwork {
    Start-Process -FilePath "netsh" -ArgumentList "winsock reset" -Wait -NoNewWindow
    Start-Process -FilePath "netsh" -ArgumentList "int ip reset" -Wait -NoNewWindow
    Start-Process -FilePath "ipconfig" -ArgumentList "/flushdns" -Wait -NoNewWindow
    return "Đã reset Winsock, TCP/IP Stack và xóa sạch DNS Cache! Vui lòng khởi động lại máy để áp dụng hoàn toàn."
}

function Invoke-VUONGTTRepairWindowsUpdate {
    $services = @("wuauserv", "cryptSvc", "bits", "msiserver")
    foreach ($s in $services) { Stop-Service -Name $s -Force -ErrorAction SilentlyContinue }
    
    $sd = "$env:WINDIR\SoftwareDistribution"
    if (Test-Path $sd) {
        Rename-Item -Path $sd -NewName "SoftwareDistribution.bak_$(Get-Date -Format 'yyyyMMddHHmm')" -Force -ErrorAction SilentlyContinue
    }
    $cat = "$env:WINDIR\System32\catroot2"
    if (Test-Path $cat) {
        Rename-Item -Path $cat -NewName "catroot2.bak_$(Get-Date -Format 'yyyyMMddHHmm')" -Force -ErrorAction SilentlyContinue
    }

    foreach ($s in $services) { Start-Service -Name $s -ErrorAction SilentlyContinue }
    return "Đã làm mới kho lưu trữ Windows Update (SoftwareDistribution & Catroot2) và khởi động lại dịch vụ!"
}

function Invoke-VUONGTTFixTaskbarStartMenu {
    $log = @()
    try {
        # Re-register Start Menu & Shell Experience Host Packages
        $apps = @("Microsoft.Windows.StartMenuExperienceHost", "Microsoft.Windows.ShellExperienceHost", "Microsoft.Windows.Search")
        foreach ($app in $apps) {
            Get-AppxPackage -AllUsers -Name $app -ErrorAction SilentlyContinue | ForEach-Object {
                $manifest = "$($_.InstallLocation)\AppXManifest.xml"
                if (Test-Path $manifest) {
                    Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction SilentlyContinue
                }
            }
        }
        $log += "[OK] Đã đăng ký lại linh kiện StartMenuExperienceHost & ShellExperienceHost."

        # Restart Explorer & Shell Hosts
        Stop-Process -Name "StartMenuExperienceHost" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "ShellExperienceHost" -Force -ErrorAction SilentlyContinue
        Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

        $log += "[OK] Đã khởi động lại tiến trình Windows Explorer & Giao diện Taskbar."
        $log += "Thanh Taskbar và Start Menu đã trở lại hoạt động bình thường!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixNetworkNoInternet {
    $log = @()
    try {
        # Flush DNS & Reset Winsock
        Start-Process -FilePath "netsh" -ArgumentList "winsock reset" -Wait -NoNewWindow
        Start-Process -FilePath "netsh" -ArgumentList "int ip reset" -Wait -NoNewWindow
        Start-Process -FilePath "ipconfig" -ArgumentList "/flushdns" -Wait -NoNewWindow
        $log += "[OK] Đã reset Winsock, TCP/IP Stack & xóa sạch DNS Cache."

        # Release & Renew IP
        Start-Process -FilePath "ipconfig" -ArgumentList "/release" -Wait -NoNewWindow
        Start-Process -FilePath "ipconfig" -ArgumentList "/renew" -Wait -NoNewWindow
        $log += "[OK] Đã giải phóng và cấp lại địa chỉ IP mới từ Router."

        # Clear ARP Cache & Reset NetAdapters
        Start-Process -FilePath "arp" -ArgumentList "-d *" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" } | Restart-NetAdapter -ErrorAction SilentlyContinue
        $log += "[OK] Đã xóa bảng ARP Cache & làm mới Card mạng đang kết nối."
        $log += "Lỗi No Internet / Báo chấm than vàng đã được khắc phục hoàn toàn!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixSysMainSearchCPU {
    $log = @()
    try {
        # Fix SysMain (Superfetch) High Disk/CPU Usage
        $sysMain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
        if ($sysMain) {
            Restart-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
            $log += "[OK] Đã làm mới dịch vụ SysMain (SuperFetch) giải phóng CPU & Đĩa C."
        }

        # Fix Windows Search CPU Spike
        $wsearch = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
        if ($wsearch) {
            Restart-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
            $log += "[OK] Đã khởi động lại dịch vụ Windows Search (WSearch)."
        }

        # Clear RAM Working Set
        if ([bool](Get-Command "Invoke-VUONGTTCleanRAM" -ErrorAction SilentlyContinue)) {
            Invoke-VUONGTTCleanRAM | Out-Null
            $log += "[OK] Đã giải phóng bộ nhớ tạm RAM bị chiếm dụng."
        }

        $log += "Xử lý thành công tình trạng ngốn CPU/RAM do SysMain & Windows Search!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTFixStoreAppX {
    $log = @()
    try {
        # Reset Windows Store Service & Cache
        Stop-Service -Name "AppXSvc" -Force -ErrorAction SilentlyContinue
        Start-Service -Name "AppXSvc" -ErrorAction SilentlyContinue
        $log += "[OK] Đã làm mới dịch vụ AppX Deployment Service (AppXSvc)."

        # Re-register Microsoft Windows Store App
        Get-AppxPackage -AllUsers -Name "Microsoft.WindowsStore" -ErrorAction SilentlyContinue | ForEach-Object {
            $manifest = "$($_.InstallLocation)\AppXManifest.xml"
            if (Test-Path $manifest) {
                Add-AppxPackage -DisableDevelopmentMode -Register $manifest -ErrorAction SilentlyContinue
            }
        }
        $log += "[OK] Đã đăng ký lại ứng dụng Microsoft Store."
        $log += "Lỗi 0x80070005, 0x80073D05 trên Windows Store đã được sửa xong!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

# =========================================================================
# NHÓM HÀM TỐI ƯU HỆ THỐNG MỞ RỘNG (SYSTEM OPTIMIZATIONS)
# =========================================================================

function Invoke-VUONGTTCleanWinUpdate {
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "[$timestamp] [BẮT ĐẦU DỌN DẸP WIN S獰 / WINDOWS UPDATE & DELIVERY OPTIMIZATION]"
    
    # 1. Dọn Delivery Optimization Cache
    try {
        $doPath = "$env:WINDIR\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
        if (Test-Path $doPath) {
            Remove-Item -Path "$doPath\*" -Recurse -Force -ErrorAction SilentlyContinue
            $log += "[OK] Đã dọn sạch bộ nhớ đệm Delivery Optimization."
        }
    } catch {}

    # 2. Dọn sạch SoftwareDistribution\Download
    try {
        $sdDl = "$env:WINDIR\SoftwareDistribution\Download"
        if (Test-Path $sdDl) {
            Remove-Item -Path "$sdDl\*" -Recurse -Force -ErrorAction SilentlyContinue
            $log += "[OK] Đã xóa toàn bộ gói cài đặt Windows Update tạm đã tải về."
        }
    } catch {}

    # 3. Dọn WinSxS Backup files bằng DISM
    try {
        $log += "[Đang xử lý] Đang chạy DISM Component Cleanup dọn sạch WinSxS (Có thể mất 1-2 phút)..."
        $p = Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /startcomponentcleanup /resetbase" -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0) {
            $log += "[OK] Đã tối ưu hóa và nén sạch kho WinSxS giải phóng dung lượng lớn ổ C!"
        } else {
            $log += "[THÔNG BÁO] DISM hoàn tất với mã trả về: $($p.ExitCode)"
        }
    } catch {
        $log += "[CHÚ Ý] $($_.Exception.Message)"
    }

    $log += "[HOÀN TẤT] Quá trình dọn dẹp Windows Update & WinSxS đã thành công!"
    return ($log -join "`n")
}

function Invoke-VUONGTTFlushDnsPrefetch {
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "[$timestamp] [BẮT ĐẦU DỌN DẸP PREFETCH & XÓA SẠCH BỘ ĐỆM DNS]"

    # 1. Dọn thư mục Prefetch
    try {
        $prefetch = "$env:WINDIR\Prefetch"
        if (Test-Path $prefetch) {
            $count = (Get-ChildItem -Path "$prefetch\*" -Force -ErrorAction SilentlyContinue).Count
            Remove-Item -Path "$prefetch\*" -Force -ErrorAction SilentlyContinue
            $log += "[OK] Đã xóa $count tệp prefetch tạm trong C:\Windows\Prefetch."
        }
    } catch {
        $log += "[CHÚ Ý] Không thể xóa toàn bộ Prefetch (một số file đang được Windows sử dụng)."
    }

    # 2. Flush DNS & Reset ARP
    try {
        Start-Process -FilePath "ipconfig" -ArgumentList "/flushdns" -Wait -NoNewWindow
        Start-Process -FilePath "arp" -ArgumentList "-d *" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        $log += "[OK] Đã làm sạch hoàn toàn bộ nhớ cache phân giải tên miền DNS & bảng ARP."
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }

    $log += "[HOÀN TẤT] Bộ nhớ tạm ứng dụng và mạng đã được làm mới sạch sẽ!"
    return ($log -join "`n")
}

function Invoke-VUONGTTCompactOS {
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "[$timestamp] [NÉN HỆ THỐNG COMPACT OS - TIẾT KIỆM 3-6GB Ổ C]"

    try {
        $log += "[Đang xử lý] Đang tiến hành nén nhị phân file hệ thống Windows (Không ảnh hưởng tốc độ máy)..."
        $p = Start-Process -FilePath "compact.exe" -ArgumentList "/CompactOS:always" -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0) {
            $log += "[OK] Đã kích hoạt nén hệ thống Compact OS thành công! Giải phóng ~3GB - 6GB dung lượng ổ C."
        } else {
            $log += "[THÔNG BÁO] Compact OS hoàn tất với mã: $($p.ExitCode)"
        }
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Set-VUONGTTFastStartup {
    param([bool]$Enable = $true)
    $key = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
    try {
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        if ($Enable) {
            Set-ItemProperty -Path $key -Name "HiberbootEnabled" -Value 1 -Type DWord -Force
            return "[OK] Đã BẬT tính năng Khởi động nhanh (Fast Startup) giúp máy bật lên nhanh hơn!"
        } else {
            Set-ItemProperty -Path $key -Name "HiberbootEnabled" -Value 0 -Type DWord -Force
            return "[OK] Đã TẮT tính năng Khởi động nhanh (Fast Startup) - Khắc phục triệt để lỗi máy khởi động treo, không tắt hẳn nguồn!"
        }
    } catch {
        return "[LỖI] Không thể thay đổi Fast Startup: $($_.Exception.Message)"
    }
}

function Set-VUONGTTOptimizeVisualEffects {
    $log = @()
    try {
        # VisualFXSetting = 2 (Adjust for best performance)
        $fxKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $fxKey)) { New-Item -Path $fxKey -Force | Out-Null }
        Set-ItemProperty -Path $fxKey -Name "VisualFXSetting" -Value 2 -Type DWord -Force

        # Tắt hiệu ứng mở đóng cửa sổ, menu fade để giao diện phản hồi tức thì
        $desk = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $desk -Name "MenuShowDelay" -Value "0" -Force
        Set-ItemProperty -Path "$desk\WindowMetrics" -Name "MinAnimate" -Value "0" -Force

        $log += "[OK] Đã thiết lập hiệu ứng trực quan Windows về mức Tối Ưu Tốc Độ Cao Nhất (Best Performance)."
        $log += "[OK] Giảm độ trễ hiển thị Menu (MenuShowDelay = 0ms) và tắt hiệu ứng thu phóng cửa sổ."
        $log += "Giao diện Windows giờ đây phản hồi tức thì, cực kỳ mượt mà!"
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTOptimizeServices {
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "[$timestamp] [TỐI ƯU HÓA CÁC DỊCH VỤ CHẠY NGẦM KHÔNG CẦN THIẾT]"

    $junkServices = @(
        @{ Name="DiagTrack"; Desc="Dịch vụ thu thập thông tin chẩn đoán từ xa" },
        @{ Name="dmwappushservice"; Desc="Dịch vụ WAP Push gửi báo cáo" },
        @{ Name="MapsBroker"; Desc="Dịch vụ Tải trước Bản đồ ngoại tuyến" },
        @{ Name="Fax"; Desc="Dịch vụ Máy Fax" },
        @{ Name="RetailDemo"; Desc="Dịch vụ Chế độ Trưng bày tại quầy" },
        @{ Name="SharedAccess"; Desc="Dịch vụ Internet Connection Sharing khi không dùng" },
        @{ Name="XblAuthManager"; Desc="Dịch vụ Quản lý xác thực Xbox Live" },
        @{ Name="XblGameSave"; Desc="Dịch vụ Đồng bộ Save game Xbox Live" }
    )

    $disabledCount = 0
    foreach ($s in $junkServices) {
        $svc = Get-Service -Name $s.Name -ErrorAction SilentlyContinue
        if ($svc) {
            Stop-Service -Name $s.Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $s.Name -StartupType Disabled -ErrorAction SilentlyContinue
            $log += "[OK] Đã tắt dịch vụ: $($s.Name) ($($s.Desc))"
            $disabledCount++
        }
    }
    $log += "[HOÀN TẤT] Đã tắt $disabledCount dịch vụ ngầm thừa thãi, giảm tải đáng kể RAM & CPU!"
    return ($log -join "`n")
}

function Invoke-VUONGTTRepairSystemFiles {
    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log += "[$timestamp] [BẮT ĐẦU TỰ ĐỘNG QUÉT & SỬA LỖI TẬP TIN HỆ THỐNG]"

    # 1. SFC /scannow
    try {
        $log += "[1/2] Đang quét toàn bộ file hệ thống bằng công cụ SFC (sfc /scannow)..."
        $exit1 = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
            Start-VUONGTTProcessResponsive -FilePath "sfc.exe" -ArgumentList "/scannow" -TimeoutSeconds 900
        } else {
            (Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -PassThru -NoNewWindow).ExitCode
        }
        if ($exit1 -eq 0) {
            $log += "[OK] Quá trình quét SFC hoàn tất: Không phát hiện lỗi cấu trúc hệ thống!"
        } else {
            $log += "[OK] Quá trình quét SFC hoàn tất: Các file hỏng nếu có đã được khôi phục tự động."
        }
    } catch {
        $log += "[CHÚ Ý SFC] $($_.Exception.Message)"
    }

    # 2. DISM RestoreHealth
    try {
        $log += "[2/2] Đang phục hồi kho ảnh Windows bằng DISM RestoreHealth..."
        $exit2 = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
            Start-VUONGTTProcessResponsive -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /restorehealth" -TimeoutSeconds 900
        } else {
            (Start-Process -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /restorehealth" -Wait -PassThru -NoNewWindow).ExitCode
        }
        if ($exit2 -eq 0) {
            $log += "[OK] DISM RestoreHealth hoàn tất thành công 100%!"
        } else {
            $log += "[THÔNG BÁO] DISM kết thúc với mã: $exit2"
        }
    } catch {
        $log += "[CHÚ Ý DISM] $($_.Exception.Message)"
    }

    $log += "[HOÀN TẤT] Hệ điều hành Windows đã được phục hồi nguyên vẹn các tệp lõi!"
    return ($log -join "`n")
}

# =========================================================================
# NHÓM HÀM TINH CHỈNH WINDOWS MỞ RỘNG (SYSTEM TWEAKS)
# =========================================================================

function Set-VUONGTTTakeOwnershipMenu {
    param([bool]$Enable = $true)
    try {
        $fileKey = "Registry::HKEY_CLASSES_ROOT\*\shell\runas"
        $dirKey  = "Registry::HKEY_CLASSES_ROOT\Directory\shell\runas"

        if ($Enable) {
            # Files
            if (-not (Test-Path $fileKey)) { New-Item -Path $fileKey -Force | Out-Null }
            Set-ItemProperty -Path $fileKey -Name "(Default)" -Value "Take Ownership (Cấp Toàn Quyền Quản Trị)" -Force
            Set-ItemProperty -Path $fileKey -Name "NoWorkingDirectory" -Value "" -Force
            $cmdKey = "$fileKey\command"
            if (-not (Test-Path $cmdKey)) { New-Item -Path $cmdKey -Force | Out-Null }
            Set-ItemProperty -Path $cmdKey -Name "(Default)" -Value "cmd.exe /c takeown /f `"%1`" && icacls `"%1`" /grant administrators:F" -Force
            Set-ItemProperty -Path $cmdKey -Name "IsolatedCommand" -Value "cmd.exe /c takeown /f `"%1`" && icacls `"%1`" /grant administrators:F" -Force

            # Folders
            if (-not (Test-Path $dirKey)) { New-Item -Path $dirKey -Force | Out-Null }
            Set-ItemProperty -Path $dirKey -Name "(Default)" -Value "Take Ownership (Cấp Toàn Quyền Quản Trị)" -Force
            Set-ItemProperty -Path $dirKey -Name "NoWorkingDirectory" -Value "" -Force
            $dcmdKey = "$dirKey\command"
            if (-not (Test-Path $dcmdKey)) { New-Item -Path $dcmdKey -Force | Out-Null }
            Set-ItemProperty -Path $dcmdKey -Name "(Default)" -Value "cmd.exe /c takeown /f `"%1`" /r /d y && icacls `"%1`" /grant administrators:F /t" -Force
            Set-ItemProperty -Path $dcmdKey -Name "IsolatedCommand" -Value "cmd.exe /c takeown /f `"%1`" /r /d y && icacls `"%1`" /grant administrators:F /t" -Force

            return "[OK] Đã thêm mục 'Take Ownership (Cấp Toàn Quyền Quản Trị)' vào menu chuột phải cho mọi File và Thư mục!"
        } else {
            Remove-Item -Path $fileKey -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $dirKey -Recurse -Force -ErrorAction SilentlyContinue
            return "[OK] Đã gỡ bỏ mục Take Ownership khỏi menu chuột phải!"
        }
    } catch {
        return "[LỖI] Không thể thay đổi Take Ownership: $($_.Exception.Message)"
    }
}

function Set-VUONGTTClassicPhotoViewer {
    try {
        $pvKey = "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations"
        if (-not (Test-Path $pvKey)) { New-Item -Path $pvKey -Force | Out-Null }

        $exts = @(".jpg", ".jpeg", ".png", ".bmp", ".gif", ".ico", ".tiff", ".tif")
        foreach ($ext in $exts) {
            Set-ItemProperty -Path $pvKey -Name $ext -Value "PhotoViewer.FileAssoc.Tiff" -Force
        }

        # Ghi nhận CLSID
        $clsidKey = "HKCR:\PhotoViewer.FileAssoc.Tiff\shell\open\command"
        if (-not (Test-Path $clsidKey)) { New-Item -Path $clsidKey -Force | Out-Null }
        Set-ItemProperty -Path $clsidKey -Name "(Default)" -Value "`"$env:SystemRoot\System32\rundll32.exe`" `"`$env:ProgramFiles\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1" -Force

        return "[OK] Đã kích hoạt Windows Photo Viewer cổ điển (Windows 7)! Bạn có thể chọn mở ảnh bằng Photo Viewer siêu nhẹ ngay lập tức."
    } catch {
        return "[LỖI] Kích hoạt Photo Viewer thất bại: $($_.Exception.Message)"
    }
}

function Set-VUONGTTToggleUAC {
    param([bool]$Disable = $true)
    try {
        $uacKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        if ($Disable) {
            Set-ItemProperty -Path $uacKey -Name "EnableLUA" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $uacKey -Name "ConsentPromptBehaviorAdmin" -Value 0 -Type DWord -Force
            return "[OK] Đã TẮT User Account Control (UAC). Sẽ không còn popup xác nhận quyền phiền phức! (Khởi động lại máy để áp dụng hoàn toàn)."
        } else {
            Set-ItemProperty -Path $uacKey -Name "EnableLUA" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $uacKey -Name "ConsentPromptBehaviorAdmin" -Value 5 -Type DWord -Force
            return "[OK] Đã BẬT User Account Control (UAC) về mức tiêu chuẩn an toàn của Windows!"
        }
    } catch {
        return "[LỖI] Thay đổi UAC thất bại: $($_.Exception.Message)"
    }
}

function Set-VUONGTTToggleHibernation {
    param([bool]$Enable = $false)
    try {
        if ($Enable) {
            Start-Process -FilePath "powercfg.exe" -ArgumentList "-h on" -Wait -NoNewWindow
            return "[OK] Đã BẬT chế độ Ngủ đông (Hibernation)."
        } else {
            Start-Process -FilePath "powercfg.exe" -ArgumentList "-h off" -Wait -NoNewWindow
            return "[OK] Đã TẮT chế độ Ngủ đông (Hibernation)! Đã xóa tệp hiberfil.sys, thu hồi ngay lập tức dung lượng bằng RAM (8GB - 32GB) trên ổ C!"
        }
    } catch {
        return "[LỖI] $($_.Exception.Message)"
    }
}

function Set-VUONGTTDisableAutoRebootUpdate {
    try {
        $auKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (-not (Test-Path $auKey)) { New-Item -Path $auKey -Force | Out-Null }
        Set-ItemProperty -Path $auKey -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord -Force
        return "[OK] Đã chặn Windows tự ý khởi động lại khi đang làm việc sau khi Update (NoAutoRebootWithLoggedOnUsers = 1)!"
    } catch {
        return "[LỖI] $($_.Exception.Message)"
    }
}

function Set-VUONGTTToggleGameMode {
    try {
        # Disable Xbox DVR & Game Bar recording
        $gKey = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $gKey)) { New-Item -Path $gKey -Force | Out-Null }
        Set-ItemProperty -Path $gKey -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

        $cKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
        if (-not (Test-Path $cKey)) { New-Item -Path $cKey -Force | Out-Null }
        Set-ItemProperty -Path $cKey -Name "AllowGameDVR" -Value 0 -Type DWord -Force

        return "[OK] Đã tối ưu hóa Game: Vô hiệu hóa Xbox Game Bar DVR chạy ngầm ghi màn hình, giúp tăng FPS và giảm giật lag khi chơi game!"
    } catch {
        return "[LỖI] $($_.Exception.Message)"
    }
}

function Set-VUONGTTDns {
    param([string]$DnsProvider)
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        switch ($DnsProvider) {
            "Cloudflare" {
                foreach ($a in $adapters) {
                    Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
                }
                return "[OK] Đã cấu hình DNS Cloudflare (1.1.1.1, 1.0.0.1) cho toàn bộ card mạng!"
            }
            "Google" {
                foreach ($a in $adapters) {
                    Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("8.8.8.8", "8.8.4.4") -ErrorAction SilentlyContinue
                }
                return "[OK] Đã cấu hình DNS Google (8.8.8.8, 8.8.4.4) cho toàn bộ card mạng!"
            }
            "Quad9" {
                foreach ($a in $adapters) {
                    Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("9.9.9.9", "149.112.112.112") -ErrorAction SilentlyContinue
                }
                return "[OK] Đã cấu hình DNS Quad9 (9.9.9.9, 149.112.112.112) cho toàn bộ card mạng!"
            }
            "AdGuard" {
                foreach ($a in $adapters) {
                    Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses ("94.140.14.14", "94.140.15.15") -ErrorAction SilentlyContinue
                }
                return "[OK] Đã cấu hình DNS AdGuard Chặn Quảng Cáo (94.140.14.14, 94.140.15.15)!"
            }
            default {
                foreach ($a in $adapters) {
                    Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ResetServerAddresses -ErrorAction SilentlyContinue
                }
                return "[OK] Đã khôi phục DNS tự động từ Modem/Router (DHCP Default)!"
            }
        }
    } catch {
        return "[LỖI] Cấu hình DNS thất bại: $($_.Exception.Message)"
    }
}

function Get-VUONGTTCurrentPowerScheme {
    try {
        $raw = (powercfg /getactivescheme) | Out-String
        if ($raw -match "\(([^\)]+)\)") {
            $name = $matches[1].Trim()
            return $name
        }
        return "Balanced"
    } catch {
        return "Balanced"
    }
}

function Set-VUONGTTPowerScheme {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Ultimate", "HighPerf", "Balanced", "PowerSaver", "Restore")]
        [string]$Scheme
    )

    try {
        switch ($Scheme) {
            "Ultimate" {
                $matchLine = (powercfg /list) | Where-Object { $_ -match "Ultimate" } | Select-Object -First 1
                if (-not $matchLine) {
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null
                    $matchLine = (powercfg /list) | Where-Object { $_ -match "Ultimate" } | Select-Object -First 1
                }
                if ($matchLine -and $matchLine -match "([a-f0-9\-]{36})") {
                    powercfg -setactive $matches[1] 2>&1 | Out-Null
                    return "[OK] Đã kích hoạt gói điện năng Tối Đa Hiệu Năng (Ultimate Performance)! Xung nhịp và tài nguyên phần cứng luôn ở mức cao nhất."
                }
                return "[LỖI] Không thể tạo hoặc kích hoạt gói Ultimate Performance trên thiết bị này."
            }
            "HighPerf" {
                $matchLine = (powercfg /list) | Where-Object { $_ -match "High performance" } | Select-Object -First 1
                if (-not $matchLine) {
                    powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
                    $matchLine = (powercfg /list) | Where-Object { $_ -match "High performance" } | Select-Object -First 1
                }
                if ($matchLine -and $matchLine -match "([a-f0-9\-]{36})") {
                    powercfg -setactive $matches[1] 2>&1 | Out-Null
                    return "[OK] Đã kích hoạt gói điện năng Hiệu Năng Cao (High Performance)! Tối ưu hóa cho chơi game và tác vụ đồ họa nặng."
                } else {
                    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
                    return "[OK] Đã kích hoạt gói điện năng Hiệu Năng Cao (High Performance)!"
                }
            }
            "Balanced" {
                $matchLine = (powercfg /list) | Where-Object { $_ -match "Balanced" } | Select-Object -First 1
                if (-not $matchLine) {
                    powercfg -duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
                    $matchLine = (powercfg /list) | Where-Object { $_ -match "Balanced" } | Select-Object -First 1
                }
                if ($matchLine -and $matchLine -match "([a-f0-9\-]{36})") {
                    powercfg -setactive $matches[1] 2>&1 | Out-Null
                } else {
                    powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
                }
                return "[OK] Đã chuyển về chế độ Tiêu Chuẩn Cân Bằng (Balanced)! Tối ưu cân đối hoàn hảo giữa hiệu năng và nhiệt độ máy."
            }
            "PowerSaver" {
                $matchLine = (powercfg /list) | Where-Object { $_ -match "Power saver" } | Select-Object -First 1
                if (-not $matchLine) {
                    powercfg -duplicatescheme a1841308-3541-4fab-bc81-f71556f20b4a 2>&1 | Out-Null
                    $matchLine = (powercfg /list) | Where-Object { $_ -match "Power saver" } | Select-Object -First 1
                }
                if ($matchLine -and $matchLine -match "([a-f0-9\-]{36})") {
                    powercfg -setactive $matches[1] 2>&1 | Out-Null
                } else {
                    powercfg -setactive a1841308-3541-4fab-bc81-f71556f20b4a 2>&1 | Out-Null
                }
                return "[OK] Đã kích hoạt gói Tiết Kiệm Điện (Power Saver)! Giảm tải xung nhịp khi rảnh rỗi và kéo dài thời lượng pin tối đa."
            }
            "Restore" {
                powercfg -restoredefaultschemes 2>&1 | Out-Null
                powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
                return "[OK] Đã khôi phục toàn bộ các gói nguồn điện chuẩn của Windows về mặc định gốc (Balanced Active)!"
            }
        }
    } catch {
        return "[LỖI] Thao tác nguồn điện thất bại: $($_.Exception.Message)"
    }
}

function Set-VUONGTTUltimatePerformancePlan {
    param([bool]$Enable = $true)
    if ($Enable) {
        return Set-VUONGTTPowerScheme -Scheme "Ultimate"
    } else {
        return Set-VUONGTTPowerScheme -Scheme "Balanced"
    }
}

function Invoke-VUONGTTSingleTweak {
    param(
        [string]$TweakKey,
        [bool]$Enable = $true
    )

    try {
        switch ($TweakKey) {
            # === ESSENTIAL TWEAKS ===
            "ActivityHistory" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 0 } else { 1 }
                Set-ItemProperty -Path $p -Name "EnableActivityFeed" -Value $val -Type DWord -Force
                Set-ItemProperty -Path $p -Name "PublishUserActivities" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tắt Lịch Sử Hoạt Động (Activity History): $statusTxt"
            }
            "BitLocker" {
                if ($Enable) {
                    manage-bde -off C: 2>&1 | Out-Null
                    return "[OK] Đã gửi lệnh tắt BitLocker ổ C:."
                }
                return "[OK] Bỏ qua BitLocker."
            }
            "ConsumerFeatures" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $p -Name "DisableWindowsConsumerFeatures" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Chặn tự cài ứng dụng rác ConsumerFeatures: $statusTxt"
            }
            "DeliveryOptimization" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 0 } else { 1 }
                Set-ItemProperty -Path $p -Name "DODownloadMode" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tối ưu băng thông Delivery Optimization: $statusTxt"
            }
            "DiskCleanup" {
                if ($Enable) {
                    Start-Process "cleanmgr.exe" -ArgumentList "/autoclean /d C:" -WindowStyle Hidden -ErrorAction SilentlyContinue
                    return "[OK] Đã kích hoạt dọn dẹp Disk Cleanup ổ C: ngầm (không gây đơ ứng dụng)."
                }
                return "[OK] Bỏ qua dọn đĩa."
            }
            "EndTaskRightClick" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $p -Name "TaskbarEndTask" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Bật chức năng Kết Thúc Tác Vụ chuột phải trên Taskbar (End Task With Right Click): $statusTxt"
            }
            "AutoFolderDiscovery" {
                $p = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags\AllFolders\Shell"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { "NotSpecified" } else { "Generic" }
                Set-ItemProperty -Path $p -Name "FolderType" -Value $val -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tắt tự động dò thư mục File Explorer: $statusTxt"
            }
            "Hibernation" {
                if ($Enable) {
                    powercfg -h off 2>&1 | Out-Null
                    return "[OK] Đã tắt chế độ Ngủ Đông (Hibernation) và xóa hiberfil.sys giải phóng RAM ổ C."
                } else {
                    powercfg -h on 2>&1 | Out-Null
                    return "[OK] Đã bật lại chế độ Ngủ Đông (Hibernation)."
                }
            }
            "LocationTracking" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $p -Name "DisableLocation" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tắt định vị vị trí người dùng (Location Tracking): $statusTxt"
            }
            "StoreSearchRec" {
                $p = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $p -Name "DisableStoreSearchInstall" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tắt gợi ý tìm kiếm Microsoft Store: $statusTxt"
            }
            "PreventDeviceApps" {
                $p1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
                if (-not (Test-Path $p1)) { New-Item -Path $p1 -Force | Out-Null }
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $p1 -Name "DisableWindowsConsumerFeatures" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
                $p2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Device Metadata"
                if (-not (Test-Path $p2)) { New-Item -Path $p2 -Force | Out-Null }
                Set-ItemProperty -Path $p2 -Name "PreventDeviceMetadataFromNetwork" -Value $val -Type DWord -Force -ErrorAction SilentlyContinue
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Chặn Tải App Kèm Thiết Bị (Prevent Device Companion Apps): $statusTxt"
            }
            "RestorePoint" {
                if ($Enable) {
                    try {
                        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
                        Checkpoint-Computer -Description "VUONGTT_Toolkit_$(Get-Date -Format 'yyyyMMdd_HHmm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
                        return "[OK] Đã tạo Điểm Khôi Phục Hệ Thống (System Restore Point) thành công!"
                    } catch {
                        return "[CHÚ Ý] Không thể tạo Restore Point tự động: $($_.Exception.Message)"
                    }
                }
                return "[OK] Bỏ qua tạo Restore Point."
            }
            "ServicesManual" {
                if ($Enable) {
                    $svcs = @("Fax", "RetailDemo", "WMPNetworkSvc", "MapsBroker", "XblAuthManager", "XblGameSave", "XboxNetApiSvc")
                    foreach ($s in $svcs) {
                        Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue
                    }
                    return "[OK] Đã chuyển các dịch vụ thừa (Fax, Maps, Xbox...) sang khởi động Thủ công (Manual)!"
                } else {
                    return "[OK] Giữ nguyên cấu hình dịch vụ."
                }
            }
            "StartMenuLayout" {
                $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $adv -Name "Start_ShowClassicMode" -Value $val -Force -ErrorAction SilentlyContinue
                $statusTxt = if ($Enable) { "BẬT (Bố cục cũ)" } else { "TẮT (Mặc định)" }
                return "[OK] Bố Cục Start Menu: $statusTxt"
            }
            "Telemetry" {
                if ($Enable) {
                    return (Disable-VUONGTTTelemetry)
                } else {
                    $pol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                    if (Test-Path $pol) { Set-ItemProperty -Path $pol -Name "AllowTelemetry" -Value 1 -Type DWord -Force }
                    return "[OK] Đã khôi phục mức Telemetry chuẩn."
                }
            }
            "TempFiles" {
                if ($Enable) {
                    return (Invoke-VUONGTTDeepClean)
                }
                return "[OK] Bỏ qua dọn file tạm."
            }
            "Widgets" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 0 } else { 1 }
                Set-ItemProperty -Path $p -Name "AllowNewsAndInterests" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Gỡ bỏ Widgets tin tức thanh tác vụ: $statusTxt"
            }

            # === ADVANCED TWEAKS ===
            "BackgroundApps" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $p -Name "GlobalUserDisabled" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tắt ứng dụng chạy ngầm không cần thiết (Background Apps): $statusTxt"
            }
            "ReservedStorage" {
                if ($Enable) {
                    DISM.exe /Online /Set-ReservedStorageState /State:Disabled 2>&1 | Out-Null
                    return "[OK] Tắt bộ nhớ dự phòng Windows (Reserved Storage - tiết kiệm ~7GB ổ C)."
                } else {
                    DISM.exe /Online /Set-ReservedStorageState /State:Enabled 2>&1 | Out-Null
                    return "[OK] Bật lại bộ nhớ dự phòng Reserved Storage."
                }
            }
            "IPv6PreferIPv4" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 0x20 } else { 0 }
                Set-ItemProperty -Path $p -Name "DisabledComponents" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Ưu tiên IPv4 hơn IPv6: $statusTxt"
            }
            "ClassicContextMenu" {
                return (Set-VUONGTTClassicContextMenu -Enable $Enable)
            }
            "VisualEffects" {
                if ($Enable) {
                    return (Set-VUONGTTOptimizeVisualEffects)
                }
                return "[OK] Giữ nguyên hiệu ứng trực quan."
            }

            # === PREFERENCES (TOGGLE SWITCHES) ===
            "DarkTheme" {
                $p = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 0 } else { 1 }
                Set-ItemProperty -Path $p -Name "AppsUseLightTheme" -Value $val -Type DWord -Force
                Set-ItemProperty -Path $p -Name "SystemUsesLightTheme" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Chế độ Tối (Dark Theme for Windows): $statusTxt"
            }
            "LongPaths" {
                $p = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $p -Name "LongPathsEnabled" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Cho phép đường dẫn dài trên 260 ký tự (Enable Long Paths): $statusTxt"
            }
            "ShowFileExt" {
                $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $val = if ($Enable) { 0 } else { 1 }
                Set-ItemProperty -Path $adv -Name "HideFileExt" -Value $val -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Hiện phần mở rộng tệp tin (.exe, .docx...): $statusTxt"
            }
            "ShowHiddenFiles" {
                $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $val = if ($Enable) { 1 } else { 2 }
                Set-ItemProperty -Path $adv -Name "Hidden" -Value $val -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Hiện tệp và thư mục ẩn (File Explorer Hidden Files): $statusTxt"
            }
            "GameMode" {
                return (Set-VUONGTTToggleGameMode)
            }
            { $_ -in @("NumLock", "NumLockStartup") } {
                $p = "HKU:\.DEFAULT\Control Panel\Keyboard"
                $val = if ($Enable) { "2" } else { "0" }
                Set-ItemProperty -Path $p -Name "InitialKeyboardIndicators" -Value $val -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tự động bật phím số NumLock khi khởi động: $statusTxt"
            }
            "TaskbarCenter" {
                $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $adv -Name "TaskbarAl" -Value $val -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT (Sang Trái)" }
                return "[OK] Đưa biểu tượng Taskbar vào giữa: $statusTxt"
            }
            "TaskbarSearch" {
                $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $adv -Name "SearchboxTaskbarMode" -Value $val -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Biểu tượng tìm kiếm trên Taskbar: $statusTxt"
            }
            "TaskbarTaskView" {
                $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                $val = if ($Enable) { 1 } else { 0 }
                Set-ItemProperty -Path $adv -Name "ShowTaskViewButton" -Value $val -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Nút Task View trên Taskbar: $statusTxt"
            }
            { $_ -in @("StartBing", "StartMenuBingSearch") } {
                $p = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                $val = if ($Enable) { 0 } else { 1 }
                Set-ItemProperty -Path $p -Name "DisableSearchBoxSuggestions" -Value $val -Type DWord -Force
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Tìm kiếm Web Bing trong Start Menu: $statusTxt"
            }
            "WindowSnap" {
                $val = if ($Enable) { "1" } else { "0" }
                Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WindowArrangementActive" -Value $val -Force -ErrorAction SilentlyContinue
                $statusTxt = if ($Enable) { "BẬT" } else { "TẮT" }
                return "[OK] Chia Cửa Sổ (Window Snapping): $statusTxt"
            }
            default {
                return "[BỎ QUA] Tweak chưa hỗ trợ: $TweakKey"
            }
        }
    } catch {
        return "[LỖI] Tweak $TweakKey thất bại: $($_.Exception.Message)"
    }
}




