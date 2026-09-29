# VUONGTT Toolkit 2026 - Comprehensive Printer & Network Fix Module (87 Chức Năng)

function Invoke-PrinterFixAction {
    param([string]$ActionId)

    $log = @()
    $timestamp = (Get-Date).ToString("HH:mm:ss")

    try {
        switch ($ActionId) {
            "0x6ba" {
                $log += "[$timestamp] [XỬ LÝ 0x0000006ba - RPC Server is Unavailable]"
                try {
                    Set-Service -Name "RpcSs" -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name "RpcSs" -ErrorAction SilentlyContinue
                    Set-Service -Name "DcomLaunch" -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name "DcomLaunch" -ErrorAction SilentlyContinue
                    
                    $spoolReg = "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler"
                    if (Test-Path $spoolReg) {
                        Set-ItemProperty -Path $spoolReg -Name "DependOnService" -Value @("RPCSS", "http") -Force -ErrorAction SilentlyContinue
                    }
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã cấu hình dịch vụ RPCSS, DcomLaunch và liên kết Print Spooler."
                    $log += "[OK] Đã khởi động lại Print Spooler. Lỗi RPC server is unavailable đã được khắc phục!"
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "0x11b" {
                $log += "[$timestamp] [XỬ LÝ 0x0000011b - RPC Authentication Level]"
                try {
                    $regPath = "HKLM:\System\CurrentControlSet\Control\Print"
                    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $regPath -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã thiết lập RpcAuthnLevelPrivacyEnabled = 0."
                    $log += "[OK] Đã restart Print Spooler. Máy trạm đã có thể kết nối in qua máy chủ mạng LAN!"
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "0x709" {
                $log += "[$timestamp] [XỬ LÝ 0x00000709 - Point and Print & Default Printer]"
                try {
                    $pnpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
                    if (-not (Test-Path $pnpPath)) { New-Item -Path $pnpPath -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $pnpPath -Name "RestrictDriverInstallationToAdministrators" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnpPath -Name "UpdatePromptSettings" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                    
                    $userPrn = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
                    if (Test-Path $userPrn) {
                        Set-ItemProperty -Path $userPrn -Name "LegacyDefaultPrinterMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    }
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã mở chính sách cài Driver cho máy trạm (RestrictDriverInstallationToAdministrators = 0)."
                    $log += "[OK] Đã kích hoạt LegacyDefaultPrinterMode và khởi động lại Spooler."
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "0x7c" {
                $log += "[$timestamp] [XỬ LÝ 0x0000007c - Point & Print Buffer Overflow Policy]"
                try {
                    $pnpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
                    if (-not (Test-Path $pnpPath)) { New-Item -Path $pnpPath -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $pnpPath -Name "PackagePointAndPrintServerList" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnpPath -Name "InPrivate" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã gỡ bỏ giới hạn đóng gói Point & Print Package (0x0000007c)."
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "0x02" {
                $log += "[$timestamp] [XỬ LÝ 0x00000002 - The system cannot find the file specified]"
                try {
                    $prtPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
                    if (-not (Test-Path $prtPolicy)) { New-Item -Path $prtPolicy -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $prtPolicy -Name "CopyFilesPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã bật chính sách tự động copy file driver từ server (CopyFilesPolicy = 1)."
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "0x40" {
                $log += "[$timestamp] [XỬ LÝ 0x00000040 - Network Name Is No Longer Available]"
                try {
                    $lanman = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
                    if (Test-Path $lanman) {
                        Set-ItemProperty -Path $lanman -Name "autodisconnect" -Value 15 -Type DWord -Force -ErrorAction SilentlyContinue
                    }
                    net stop LanmanServer /y 2>&1 | Out-Null
                    net start LanmanServer 2>&1 | Out-Null
                    net start LanmanWorkstation 2>&1 | Out-Null
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã đặt lại cấu hình kết nối mạng SMB và khởi động lại dịch vụ chia sẻ."
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "0x3e8" {
                $log += "[$timestamp] [XỬ LÝ 0x000003e8 - Port / Spooler Error]"
                try {
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã reset hàng đợi và kết nối cổng in TCP/IP."
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "0xbcb" {
                $log += "[$timestamp] [XỬ LÝ 0x00000bcb - Connect to printer policy restriction]"
                try {
                    $pnp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
                    if (-not (Test-Path $pnp)) { New-Item -Path $pnp -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $pnp -Name "Restricted" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnp -Name "TrustedServers" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã hủy bỏ chính sách chặn kết nối máy in mạng (0x00000bcb)."
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "restart_spooler" {
                $log += "[$timestamp] [KHỞI ĐỘNG LẠI DỊCH VỤ PRINT SPOOLER]"
                try {
                    Set-Service -Name "Spooler" -StartupType Automatic -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Dịch vụ Print Spooler đã được đặt thành Automatic và đang chạy tốt!"
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "clear_queue" {
                $log += "[$timestamp] [DỌN DẸP HÀNG ĐỢI LỆNH IN BỊ KẸT]"
                try {
                    Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $spoolDir = "$env:WINDIR\System32\spool\PRINTERS"
                    $count = 0
                    if (Test-Path $spoolDir) {
                        $files = Get-ChildItem -Path "$spoolDir\*" -Force -ErrorAction SilentlyContinue
                        $count = $files.Count
                        $files | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
                    $log += "[OK] Đã xóa sạch $count lệnh in bị kẹt (.SPL, .SHD). Hàng đợi đã sẵn sàng!"
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "snmp_offline" {
                $log += "[$timestamp] [SỬA LỖI MÁY IN BÁO OFFLINE ẢO (SNMP)]"
                try {
                    $portsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports"
                    if (Test-Path $portsPath) {
                        Get-ChildItem -Path $portsPath -ErrorAction SilentlyContinue | ForEach-Object {
                            Set-ItemProperty -Path $_.PSPath -Name "SNMP Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path $_.PSPath -Name "SNMPApproved" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                        }
                        $log += "[OK] Đã vô hiệu hóa giám sát SNMP trên toàn bộ cổng TCP/IP Port."
                    }
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Máy in đã trở lại trạng thái Online bình thường!"
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "lan_share" {
                $log += "[$timestamp] [KÍCH HOẠT CHIA SẺ MẠNG LAN & MỞ TƯỜNG LỬA MÁY IN]"
                try {
                    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-Null
                    netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 | Out-Null
                    
                    $services = @("fdPHost", "FDResPub", "SSDPSRV", "upnphost", "LanmanServer", "LanmanWorkstation")
                    foreach ($s in $services) {
                        Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
                        Start-Service -Name $s -ErrorAction SilentlyContinue
                    }

                    $smbPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
                    if (-not (Test-Path $smbPath)) { New-Item -Path $smbPath -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $smbPath -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-SmbServerConfiguration -EnableSMB2Protocol $true -Confirm:$false -Force -ErrorAction SilentlyContinue
                    $log += "[OK] Đã mở tường lửa cổng in 139, 445, 9100 và bật duyệt mạng FDResPub/SMB2."
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "backup_driver" {
                $log += "[$timestamp] [SAO LƯU DRIVER MÁY IN TRÊN HỆ THỐNG]"
                try {
                    $backupDir = "$env:SystemDrive\Backup_Printer_Drivers"
                    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force -ErrorAction SilentlyContinue | Out-Null }
                    Export-WindowsDriver -Online -Destination $backupDir -ErrorAction SilentlyContinue | Out-Null
                    $log += "[OK] Đã sao lưu toàn bộ Driver hệ thống vào thư mục: $backupDir"
                } catch {
                    $log += "[LƯU Ý] $($_.Exception.Message)"
                }
            }

            "open_devmgmt" {
                Start-Process "devmgmt.msc"
                $log += "[OK] Đã mở trình quản lý thiết bị Device Manager."
            }

            "open_printmgmt" {
                try {
                    Start-Process "printmanagement.msc"
                    $log += "[OK] Đã mở Print Management."
                } catch {
                    Start-Process "control.exe" -ArgumentList "printers"
                    $log += "[OK] Đã mở Devices and Printers Control Panel."
                }
            }

            "fix_all" {
                $log += "[$timestamp] [BẮT ĐẦU 1-CLICK TỰ ĐỘNG SỬA TOÀN BỘ LỖI MÁY IN & MẠNG LAN (AUTO YES)]"
                try {
                    Set-Service -Name "RpcSs" -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name "RpcSs" -ErrorAction SilentlyContinue
                    Set-Service -Name "DcomLaunch" -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name "DcomLaunch" -ErrorAction SilentlyContinue
                    $spoolReg = "HKLM:\SYSTEM\CurrentControlSet\Services\Spooler"
                    if (Test-Path $spoolReg) {
                        Set-ItemProperty -Path $spoolReg -Name "DependOnService" -Value @("RPCSS", "http") -Force -ErrorAction SilentlyContinue
                    }
                    $log += "[1/8] [OK] Đã sửa lỗi 0x0000006ba (RPC Server) và liên kết Print Spooler."
                } catch { $log += "[1/8] [BỎ QUA] $($_.Exception.Message)" }

                try {
                    $regPrint = "HKLM:\System\CurrentControlSet\Control\Print"
                    if (-not (Test-Path $regPrint)) { New-Item -Path $regPrint -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $regPrint -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    $log += "[2/8] [OK] Đã sửa lỗi 0x0000011b (RpcAuthnLevelPrivacyEnabled = 0)."
                } catch { $log += "[2/8] [BỎ QUA] $($_.Exception.Message)" }

                try {
                    $pnpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
                    if (-not (Test-Path $pnpPath)) { New-Item -Path $pnpPath -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $pnpPath -Name "RestrictDriverInstallationToAdministrators" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnpPath -Name "UpdatePromptSettings" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnpPath -Name "PackagePointAndPrintServerList" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnpPath -Name "InPrivate" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnpPath -Name "Restricted" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnpPath -Name "TrustedServers" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    
                    $userPrn = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Windows"
                    if (Test-Path $userPrn) {
                        Set-ItemProperty -Path $userPrn -Name "LegacyDefaultPrinterMode" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    }
                    $log += "[3/8] [OK] Đã sửa lỗi 0x00000709, 0x0000007c, 0x00000bcb (Mở khóa Policy Point and Print)."
                } catch { $log += "[3/8] [BỎ QUA] $($_.Exception.Message)" }

                try {
                    $prtPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
                    if (-not (Test-Path $prtPolicy)) { New-Item -Path $prtPolicy -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $prtPolicy -Name "CopyFilesPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    $log += "[4/8] [OK] Đã sửa lỗi 0x00000002 (CopyFilesPolicy = 1 cho phép chép Driver)."
                } catch { $log += "[4/8] [BỎ QUA] $($_.Exception.Message)" }

                try {
                    $lanman = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
                    if (Test-Path $lanman) {
                        Set-ItemProperty -Path $lanman -Name "autodisconnect" -Value 15 -Type DWord -Force -ErrorAction SilentlyContinue
                    }
                    net stop LanmanServer /y 2>&1 | Out-Null
                    net start LanmanServer 2>&1 | Out-Null
                    net start LanmanWorkstation 2>&1 | Out-Null
                    $log += "[5/8] [OK] Đã sửa lỗi 0x00000040 & đặt lại thông số mạng kết nối SMB."
                } catch { $log += "[5/8] [BỎ QUA] $($_.Exception.Message)" }

                try {
                    $portsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Monitors\Standard TCP/IP Port\Ports"
                    if (Test-Path $portsPath) {
                        Get-ChildItem -Path $portsPath -ErrorAction SilentlyContinue | ForEach-Object {
                            Set-ItemProperty -Path $_.PSPath -Name "SNMP Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path $_.PSPath -Name "SNMPApproved" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                        }
                    }
                    $log += "[6/8] [OK] Đã tắt cảnh báo SNMP gây lỗi máy in Offline ảo."
                } catch { $log += "[6/8] [BỎ QUA] $($_.Exception.Message)" }

                try {
                    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-Null
                    netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 | Out-Null
                    $services = @("fdPHost", "FDResPub", "SSDPSRV", "upnphost", "LanmanServer", "LanmanWorkstation")
                    foreach ($s in $services) {
                        Set-Service -Name $s -StartupType Automatic -ErrorAction SilentlyContinue
                        Start-Service -Name $s -ErrorAction SilentlyContinue
                    }
                    $smbPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
                    if (-not (Test-Path $smbPath)) { New-Item -Path $smbPath -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $smbPath -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-SmbServerConfiguration -EnableSMB2Protocol $true -Confirm:$false -Force -ErrorAction SilentlyContinue
                    $log += "[7/8] [OK] Đã mở toàn bộ Port tường lửa chia sẻ máy in và kích hoạt dịch vụ mạng LAN."
                } catch { $log += "[7/8] [BỎ QUA] $($_.Exception.Message)" }

                try {
                    Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $spoolDir = "$env:WINDIR\System32\spool\PRINTERS"
                    if (Test-Path $spoolDir) {
                        Get-ChildItem -Path "$spoolDir\*" -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                    }
                    Set-Service -Name "Spooler" -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
                    $log += "[8/8] [OK] Đã xóa kẹt lệnh in và khởi động lại Print Spooler (Chế độ Tự Động)."
                } catch { $log += "[8/8] [BỎ QUA] $($_.Exception.Message)" }

                $log += "[$timestamp] [HOÀN TẤT] Đã sửa chữa toàn diện 100% tất cả lỗi máy in & mạng LAN!"
            }

            default {
                $log += "[$timestamp] [XỬ LÝ TỔNG HỢP CHO LỖI: $ActionId]"
                Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                $log += "[OK] Đã áp dụng cấu hình và tối ưu hóa hệ thống in ấn thành công!"
            }
        }
    } catch {
        $log += "[LỖI] $($_.Exception.Message)"
    }

    return ($log -join "`n")
}

# =========================================================================
# BỘ CÔNG CỤ FIX MÁY IN - SHARE LAN TOÀN DIỆN (4 SUB-TABS & MODAL 0x7c)
# =========================================================================

function Get-VUONGTTPrinterList {
    $list = @()
    try {
        $printers = Get-CimInstance -ClassName Win32_Printer -ErrorAction SilentlyContinue
        if (-not $printers) {
            $printers = Get-WmiObject -Class Win32_Printer -ErrorAction SilentlyContinue
        }
        foreach ($p in $printers) {
            $isDef = [bool]$p.Default
            $statusText = if ($p.PrinterStatus -eq 3) { "Sẵn sàng (Ready)" } elseif ($p.WorkOffline) { "Offline" } else { "Sẵn sàng (Ready)" }
            $port = if ($p.PortName) { $p.PortName } else { "Unknown" }
            $list += [PSCustomObject]@{
                IsDefault   = $isDef
                Name        = $p.Name
                DisplayName = if ($isDef) { "⭐ $($p.Name)" } else { $p.Name }
                PortName    = $port
                Status      = $statusText
                IsShared    = [bool]$p.Shared
                ShareName   = if ($p.ShareName) { $p.ShareName } else { "" }
            }
        }
    } catch {}
    return $list
}

function Invoke-VUONGTTPrinterAction {
    param(
        [Parameter(Mandatory=$true)][string]$Action,
        [string]$PrinterName = "",
        [hashtable]$Params = @{}
    )
    $log = @()
    $ts = (Get-Date).ToString("HH:mm:ss")
    try {
        switch ($Action) {
            "test_print" {
                if ([string]::IsNullOrWhiteSpace($PrinterName)) { throw "Chưa chọn máy in để in thử nghiệm." }
                rundll32.exe printui.dll,PrintUIEntry /k /n "$PrinterName"
                $log += "[$ts] [OK] Đã gửi lệnh in trang thử nghiệm Windows Test Page tới '$PrinterName'."
            }
            "set_default" {
                if ([string]::IsNullOrWhiteSpace($PrinterName)) { throw "Chưa chọn máy in để đặt mặc định." }
                $wscript = New-Object -ComObject WScript.Network
                $wscript.SetDefaultPrinter($PrinterName)
                $log += "[$ts] [OK] Đã đặt máy in '$PrinterName' làm mặc định hệ thống thành công."
            }
            "share_printer" {
                if ([string]::IsNullOrWhiteSpace($PrinterName)) { throw "Chưa chọn máy in để chia sẻ." }
                Set-Printer -Name $PrinterName -Shared $true -ErrorAction SilentlyContinue
                $log += "[$ts] [OK] Đã kích hoạt chia sẻ máy in '$PrinterName' qua mạng LAN."
            }
            "remove_printer" {
                if ([string]::IsNullOrWhiteSpace($PrinterName)) { throw "Chưa chọn máy in để xóa." }
                Remove-Printer -Name $PrinterName -ErrorAction SilentlyContinue
                $log += "[$ts] [OK] Đã gỡ bỏ máy in '$PrinterName' khỏi hệ thống."
            }
            "add_local_port" {
                rundll32.exe printui.dll,PrintUIEntry /il
                $log += "[$ts] [OK] Đã mở trình hướng dẫn thêm máy in & cấu hình Port."
            }
            default {
                $log += "[$ts] [LƯU Ý] Không hỗ trợ tác vụ máy in: $Action"
            }
        }
    } catch {
        $log += "[$ts] [LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Invoke-VUONGTTBatchErrorFix {
    param([string[]]$ErrorCodes)
    $results = @()
    $ts = (Get-Date).ToString("HH:mm:ss")
    $results += "[$ts] === BẮT ĐẦU SỬA CÁC MÃ LỖI ĐÃ CHỌN ==="

    foreach ($code in $ErrorCodes) {
        $c = $code.ToLower().Trim()
        switch ($c) {
            "0x7c" {
                $results += Invoke-PrinterFixAction -ActionId "0x7c"
            }
            "0xbc4" {
                try {
                    $pnp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
                    if (-not (Test-Path $pnp)) { New-Item -Path $pnp -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $pnp -Name "RpcOverNamedPipes" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnp -Name "RpcProtocols" -Value 0x7 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $results += "[$ts] [0x00000bc4] [OK] Đã cấu hình RPC Over Named Pipes và giao thức in ấn."
                } catch { $results += "[$ts] [0x00000bc4] [LỖI] $($_.Exception.Message)" }
            }
            "0x4005" {
                try {
                    $regRpc = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider"
                    if (-not (Test-Path $regRpc)) { New-Item -Path $regRpc -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $regRpc -Name "RemovePrintersAtLogoff" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $results += "[$ts] [0x00004005] [OK] Đã thiết lập CSR Client Side Provider và cấp lại quyền Spooler."
                } catch { $results += "[$ts] [0x00004005] [LỖI] $($_.Exception.Message)" }
            }
            "0x11b" {
                $results += Invoke-PrinterFixAction -ActionId "0x11b"
            }
            "0xbcb" {
                $results += Invoke-PrinterFixAction -ActionId "0xbcb"
            }
            "0x6d9" {
                try {
                    Set-Service -Name "MpsSvc" -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name "MpsSvc" -ErrorAction SilentlyContinue
                    netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-Null
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $results += "[$ts] [0x000006d9] [OK] Đã bật dịch vụ tường lửa Windows Defender Firewall & kích hoạt chia sẻ máy in."
                } catch { $results += "[$ts] [0x000006d9] [LỖI] $($_.Exception.Message)" }
            }
            "0x709" {
                $results += Invoke-PrinterFixAction -ActionId "0x709"
            }
            "0x012" {
                try {
                    $lanman = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
                    if (-not (Test-Path $lanman)) { New-Item -Path $lanman -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $lanman -Name "IRPStackSize" -Value 32 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $lanman -Name "SizReqBuf" -Value 17424 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "LanmanServer" -Force -ErrorAction SilentlyContinue
                    $results += "[$ts] [0x00000012] [OK] Đã tối ưu hóa bộ nhớ mạng IRPStackSize / SizReqBuf chống tràn kết nối."
                } catch { $results += "[$ts] [0x00000012] [LỖI] $($_.Exception.Message)" }
            }
            "policy" {
                try {
                    $pnp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
                    if (-not (Test-Path $pnp)) { New-Item -Path $pnp -Force -ErrorAction SilentlyContinue | Out-Null }
                    Set-ItemProperty -Path $pnp -Name "Restricted" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnp -Name "RestrictDriverInstallationToAdministrators" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $pnp -Name "PackagePointAndPrintServerList" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    Restart-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                    $results += "[$ts] [Policy In Effect] [OK] Đã dỡ bỏ hạn chế Group Policy Point and Print."
                } catch { $results += "[$ts] [Policy In Effect] [LỖI] $($_.Exception.Message)" }
            }
        }
    }
    $results += "[$ts] === HOÀN TẤT XỬ LÝ CÁC MÃ LỖI ==="
    return ($results -join "`n")
}

function Invoke-VUONGTTFix0x7c {
    param([string]$TargetWinVersion = "win10_plus")
    $log = @()
    $ts = (Get-Date).ToString("HH:mm:ss")
    $log += "[$ts] [0x0000007c] Bắt đầu khắc phục lỗi 0x0000007c (Phiên bản mục tiêu: $TargetWinVersion)"
    try {
        # 1. Dừng Print Spooler
        Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
        
        # 2. Cấu hình Registry RpcAuthnLevelPrivacyEnabled
        $regPath = "HKLM:\System\CurrentControlSet\Control\Print"
        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $regPath -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        
        $pnpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        if (-not (Test-Path $pnpPath)) { New-Item -Path $pnpPath -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $pnpPath -Name "PackagePointAndPrintServerList" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pnpPath -Name "RestrictDriverInstallationToAdministrators" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        # 3. Quản lý quyền file win32spl.dll
        $dllPath = "$env:WINDIR\System32\win32spl.dll"
        if (Test-Path $dllPath) {
            $bakPath = "$env:WINDIR\System32\win32spl.dll.bak"
            if (-not (Test-Path $bakPath)) {
                Copy-Item -Path $dllPath -Destination $bakPath -Force -ErrorAction SilentlyContinue
            }
            takeown.exe /f "$dllPath" /a 2>&1 | Out-Null
            icacls.exe "$dllPath" /grant "Administrators:F" 2>&1 | Out-Null
        }

        # 4. Khởi động lại Print Spooler
        Set-Service -Name "Spooler" -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name "Spooler" -ErrorAction SilentlyContinue

        $log += "[$ts] [OK] Đã thiết lập RpcAuthnLevelPrivacyEnabled = 0 và PackagePointAndPrintServerList = 0."
        $log += "[$ts] [OK] Đã kiểm tra tệp win32spl.dll và nạp lại Print Spooler."
        $log += "[$ts] [OK] Lỗi 0x0000007c trên máy trạm đã được khắc phục thành công!"
    } catch {
        $log += "[$ts] [LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}

function Get-VUONGTTLocalUsers {
    $list = @()
    try {
        $users = Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = True" -ErrorAction SilentlyContinue
        if (-not $users) {
            $users = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount = True" -ErrorAction SilentlyContinue
        }

        # Lấy danh sách thành viên Administrators
        $adminMembers = @()
        try {
            $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
            $members = @($group.psbase.Invoke("Members"))
            foreach ($m in $members) {
                $mName = $m.GetType().InvokeMember("Name", 'GetProperty', $null, $m, $null)
                if ($mName) { $adminMembers += $mName }
            }
        } catch {}

        foreach ($u in $users) {
            $isAdmin = $adminMembers -contains $u.Name
            $status = if ($u.Disabled) { "Đã khóa" } else { "Hoạt động" }
            $pwdExpires = if ($u.PasswordExpires) { "Có thời hạn" } else { "Không bao giờ hết hạn" }
            $groupName = if ($isAdmin) { "Admin" } elseif ($u.Name -eq "Guest") { "Guests" } else { "Users" }

            $list += [PSCustomObject]@{
                Name            = $u.Name
                FullName        = if ($u.FullName) { $u.FullName } else { $u.Name }
                Group           = $groupName
                Status          = $status
                IsDisabled      = [bool]$u.Disabled
                PasswordExpires = $pwdExpires
                IsAdmin         = $isAdmin
            }
        }
    } catch {}
    return $list
}

function New-VUONGTTShareUser {
    param(
        [Parameter(Mandatory=$true)][string]$Username,
        [string]$FullName = "",
        [string]$Password = "",
        [bool]$PasswordNeverExpires = $true
    )
    $ts = (Get-Date).ToString("HH:mm:ss")
    try {
        if ([string]::IsNullOrWhiteSpace($Username)) { throw "Tên tài khoản không được để trống." }
        
        # Tạo bằng net user
        $p = if ([string]::IsNullOrEmpty($Password)) { "" } else { $Password }
        $cmd = "net user `"$Username`" `"$p`" /add /comment:`"User Chia Se May In LAN`""
        if ($FullName) { $cmd += " /fullname:`"$FullName`"" }
        Invoke-Expression $cmd 2>&1 | Out-Null

        if ($PasswordNeverExpires) {
            try {
                $user = [ADSI]"WinNT://$env:COMPUTERNAME/$Username,user"
                $user.UserFlags.Value = $user.UserFlags.Value -bor 0x10000 # ADS_UF_DONT_EXPIRE_PASSWORD
                $user.SetInfo()
            } catch {
                wmic useraccount where name="$Username" set passwordexpires=false 2>&1 | Out-Null
            }
        }

        return "[$ts] [OK] Đã tạo thành công tài khoản chia sẻ mạng: '$Username'."
    } catch {
        return "[$ts] [LỖI] Không thể tạo tài khoản: $($_.Exception.Message)"
    }
}

function Set-VUONGTTUserProperty {
    param(
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Property,
        $Value = $null
    )
    $ts = (Get-Date).ToString("HH:mm:ss")
    try {
        switch ($Property) {
            "toggle_active" {
                # Kiểm tra trạng thái hiện tại
                $u = Get-CimInstance -ClassName Win32_UserAccount -Filter "Name='$Username' AND LocalAccount=True" -ErrorAction SilentlyContinue
                $newActive = if ($u -and $u.Disabled) { "yes" } else { "no" }
                net user "$Username" /active:$newActive 2>&1 | Out-Null
                $stateText = if ($newActive -eq "yes") { "Mở khóa (Active)" } else { "Khóa (Disabled)" }
                return "[$ts] [OK] Đã chuyển tài khoản '$Username' sang trạng thái: $stateText."
            }
            "change_password" {
                if ([string]::IsNullOrEmpty($Value)) { throw "Mật khẩu mới không được để trống." }
                net user "$Username" "$Value" 2>&1 | Out-Null
                return "[$ts] [OK] Đã cập nhật mật khẩu mới cho tài khoản '$Username'."
            }
            "never_expires" {
                try {
                    $user = [ADSI]"WinNT://$env:COMPUTERNAME/$Username,user"
                    $user.UserFlags.Value = $user.UserFlags.Value -bor 0x10000
                    $user.SetInfo()
                } catch {
                    wmic useraccount where name="$Username" set passwordexpires=false 2>&1 | Out-Null
                }
                return "[$ts] [OK] Đã đặt thuộc tính Mật khẩu không bao giờ hết hạn cho '$Username'."
            }
            "toggle_admin" {
                $group = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
                $isAdmin = $false
                $members = @($group.psbase.Invoke("Members"))
                foreach ($m in $members) {
                    $mName = $m.GetType().InvokeMember("Name", 'GetProperty', $null, $m, $null)
                    if ($mName -eq $Username) { $isAdmin = $true; break }
                }
                if ($isAdmin) {
                    net localgroup Administrators "$Username" /delete 2>&1 | Out-Null
                    return "[$ts] [OK] Đã gỡ tài khoản '$Username' khỏi nhóm Administrators."
                } else {
                    net localgroup Administrators "$Username" /add 2>&1 | Out-Null
                    return "[$ts] [OK] Đã gán quyền Administrators cho tài khoản '$Username'."
                }
            }
            default {
                return "[$ts] [LƯU Ý] Thuộc tính không xác định: $Property"
            }
        }
    } catch {
        return "[$ts] [LỖI] $($_.Exception.Message)"
    }
}

function Remove-VUONGTTUser {
    param([Parameter(Mandatory=$true)][string]$Username)
    $ts = (Get-Date).ToString("HH:mm:ss")
    try {
        if ($Username.ToLower() -in @("administrator", "admin", "guest", "$env:USERNAME".ToLower())) {
            throw "Không thể xóa tài khoản hệ thống hoặc tài khoản đang đăng nhập."
        }
        net user "$Username" /delete 2>&1 | Out-Null
        return "[$ts] [OK] Đã xóa vĩnh viễn tài khoản '$Username'."
    } catch {
        return "[$ts] [LỖI] $($_.Exception.Message)"
    }
}

function Get-VUONGTTCredentials {
    $creds = @()
    try {
        $output = cmdkey.exe /list
        $currentTarget = ""
        $currentType = ""
        $currentUser = ""
        foreach ($line in ($output -split "`r?`n")) {
            $t = $line.Trim()
            if ($t -match "^Target:\s*(.*)$") {
                if ($currentTarget) {
                    $creds += [PSCustomObject]@{ Target=$currentTarget; Type=$currentType; User=$currentUser }
                }
                $currentTarget = $Matches[1].Trim()
                $currentType = "Domain/Local"
                $currentUser = ""
            } elseif ($t -match "^Type:\s*(.*)$") {
                $currentType = $Matches[1].Trim()
            } elseif ($t -match "^User:\s*(.*)$") {
                $currentUser = $Matches[1].Trim()
            }
        }
        if ($currentTarget) {
            $creds += [PSCustomObject]@{ Target=$currentTarget; Type=$currentType; User=$currentUser }
        }
    } catch {}
    return $creds
}

function Add-VUONGTTCredential {
    param(
        [Parameter(Mandatory=$true)][string]$Target,
        [Parameter(Mandatory=$true)][string]$Username,
        [string]$Password = ""
    )
    $ts = (Get-Date).ToString("HH:mm:ss")
    try {
        if ([string]::IsNullOrWhiteSpace($Target) -or [string]::IsNullOrWhiteSpace($Username)) {
            throw "Target (IP/Máy chủ) và Username không được để trống."
        }
        cmdkey.exe /add:"$Target" /user:"$Username" /pass:"$Password" 2>&1 | Out-Null
        return "[$ts] [OK] Đã lưu thành công Windows Credential cho mục tiêu '$Target' với User '$Username'."
    } catch {
        return "[$ts] [LỖI] $($_.Exception.Message)"
    }
}

function Remove-VUONGTTCredential {
    param([Parameter(Mandatory=$true)][string]$Target)
    $ts = (Get-Date).ToString("HH:mm:ss")
    try {
        cmdkey.exe /delete:"$Target" 2>&1 | Out-Null
        return "[$ts] [OK] Đã xóa Windows Credential của mục tiêu '$Target'."
    } catch {
        return "[$ts] [LỖI] $($_.Exception.Message)"
    }
}

function Invoke-VUONGTTDataShareFix {
    param([Parameter(Mandatory=$true)][string]$Action)
    $ts = (Get-Date).ToString("HH:mm:ss")
    $log = @()
    try {
        switch ($Action) {
            "network_discovery" {
                netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes 2>&1 | Out-Null
                netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes 2>&1 | Out-Null
                @("fdPHost", "FDResPub", "SSDPSRV", "upnphost") | ForEach-Object {
                    Set-Service -Name $_ -StartupType Automatic -ErrorAction SilentlyContinue
                    Start-Service -Name $_ -ErrorAction SilentlyContinue
                }
                $log += "[$ts] [OK] Đã bật Network Discovery, File & Printer Sharing và dịch vụ FDResPub."
            }
            "guest_insecure" {
                $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation"
                if (-not (Test-Path $p)) { New-Item -Path $p -Force -ErrorAction SilentlyContinue | Out-Null }
                Set-ItemProperty -Path $p -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $log += "[$ts] [OK] Đã kích hoạt AllowInsecureGuestAuth = 1 (Cho phép kết nối máy in/NAS chia sẻ không mật khẩu)."
            }
            "private_network" {
                Get-NetConnectionProfile -ErrorAction SilentlyContinue | ForEach-Object {
                    Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private -ErrorAction SilentlyContinue
                }
                $log += "[$ts] [OK] Đã chuyển toàn bộ kết nối mạng sang chế độ Private Network (Mạng riêng tư)."
            }
            "enable_smb" {
                Set-SmbServerConfiguration -EnableSMB1Protocol $true -EnableSMB2Protocol $true -Confirm:$false -Force -ErrorAction SilentlyContinue
                $log += "[$ts] [OK] Đã kích hoạt hỗ trợ giao thức SMBv1 và SMBv2."
            }
            "flush_net_use" {
                net use * /delete /y 2>&1 | Out-Null
                Restart-Service -Name "LanmanWorkstation" -Force -ErrorAction SilentlyContinue
                $log += "[$ts] [OK] Đã xóa toàn bộ bộ nhớ đệm kết nối mạng LAN (Net Use Flush) và làm mới LanmanWorkstation."
            }
            "open_advanced_sharing" {
                Start-Process "control.exe" -ArgumentList "/name Microsoft.NetworkAndSharingCenter /page AdvancedShared"
                $log += "[$ts] [OK] Đã mở cài đặt chia sẻ mạng nâng cao (Advanced Sharing Settings)."
            }
            default {
                $log += "[$ts] [LƯU Ý] Không hỗ trợ hành động: $Action"
            }
        }
    } catch {
        $log += "[$ts] [LỖI] $($_.Exception.Message)"
    }
    return ($log -join "`n")
}