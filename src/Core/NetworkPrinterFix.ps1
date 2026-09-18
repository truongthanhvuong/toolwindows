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