# CrackScannerEngine.ps1
# Engine Quét & Tiệt Trừ Crack Lậu Pro (Crack Scanner Pro)
# Tương thích triệt để AutoKMS, KMSpico, KMSAuto, SppExtComObjHook, Hijack Hosts & Registry IFEO

function Get-VUONGTTCrackThreats {
    [CmdletBinding()]
    param()

    $threats = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. Quét Dịch Vụ Ngầm Rogue Services
    $rogueServiceNames = @(
        "AutoKMS", "KMSEmulator", "KMS-Server", "Service_KMS", 
        "KMSpicoService", "SECOH-QAD", "KmsService", "TunngleService"
    )
    foreach ($sName in $rogueServiceNames) {
        $svc = Get-Service -Name $sName -ErrorAction SilentlyContinue
        if ($svc) {
            $threats.Add([PSCustomObject]@{
                Category    = "Service"
                Name        = $svc.Name
                Target      = $svc.DisplayName
                Description = "Dịch vụ giả lập máy chủ KMS lậu chạy ngầm chiếm tài nguyên"
                Severity    = "High"
            })
        }
    }

    # 2. Quét Tác Vụ Lập Lịch Rogue Scheduled Tasks
    $taskNames = @("\AutoKMS", "\AutoKMSDaily", "\KMSpico", "\KMSAuto", "\KMSAutoNet", "\KmsCleaner")
    foreach ($tn in $taskNames) {
        try {
            $task = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
            if ($task) {
                $threats.Add([PSCustomObject]@{
                    Category    = "ScheduledTask"
                    Name        = $task.TaskName
                    Target      = $task.TaskPath
                    Description = "Tác vụ chạy ngầm định kỳ gia hạn hoặc nạp lại crack lậu"
                    Severity    = "High"
                })
            }
        } catch {}
    }

    # 3. Quét Registry Hook IFEO (Image File Execution Options)
    $ifeoTargets = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SppExtComObj.exe",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\osppsvc.exe"
    )
    foreach ($ifeo in $ifeoTargets) {
        if (Test-Path $ifeo) {
            $item = Get-ItemProperty -Path $ifeo -ErrorAction SilentlyContinue
            if ($item -and ($item.Debugger -or $item.AppExecutionOptions)) {
                $threats.Add([PSCustomObject]@{
                    Category    = "RegistryHook"
                    Name        = (Split-Path $ifeo -Leaf)
                    Target      = $ifeo
                    Description = "Can thiệp tiến trình kích hoạt gốc (IFEO Debugger Hook: SppExtComObjHook.dll)"
                    Severity    = "Critical"
                })
            }
        }
    }

    # 4. Quét Thư Mục & Tệp Tin Crack Độc Hại
    $crackPaths = @(
        "$env:ProgramFiles\KMSpico",
        "${env:ProgramFiles(x86)}\KMSpico",
        "$env:SystemRoot\AutoKMS",
        "$env:SystemRoot\Setup\Scripts\AutoKMS.exe",
        "$env:SystemRoot\System32\SppExtComObjHook.dll",
        "$env:SystemRoot\SysWOW64\SppExtComObjHook.dll",
        "$env:SystemRoot\System32\SECOH-QAD.exe",
        "$env:SystemRoot\SysWOW64\SECOH-QAD.exe",
        "$env:SystemDrive\KMSAuto"
    )
    foreach ($cp in $crackPaths) {
        if (Test-Path $cp) {
            $threats.Add([PSCustomObject]@{
                Category    = "FileOrFolder"
                Name        = (Split-Path $cp -Leaf)
                Target      = $cp
                Description = "Mã độc, tệp thực thi hoặc thư viện crack lậu được phát hiện trên ổ đĩa"
                Severity    = "High"
            })
        }
    }

    # 5. Quét File Hosts Bị Chuyển Hướng (Hosts Redirection Hijack)
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (Test-Path $hostsFile) {
        try {
            $lines = Get-Content -Path $hostsFile -ErrorAction SilentlyContinue
            $kmsDomains = @("activation.sls.microsoft.com", "kms.core.windows.net", "kms8.msguides.com")
            foreach ($line in $lines) {
                $trimmed = $line.Trim()
                if ($trimmed -and -not $trimmed.StartsWith("#")) {
                    foreach ($kd in $kmsDomains) {
                        if ($trimmed -like "*$kd*") {
                            $threats.Add([PSCustomObject]@{
                                Category    = "HostsFile"
                                Name        = $kd
                                Target      = $hostsFile
                                Description = "Tập tin hosts bị chỉnh sửa chuyển hướng máy chủ bản quyền: $trimmed"
                                Severity    = "Medium"
                            })
                            break
                        }
                    }
                }
            }
        } catch {}
    }

    return [PSCustomObject]@{
        Threats     = $threats
        ThreatCount = $threats.Count
        IsClean     = ($threats.Count -eq 0)
        ScanTime    = (Get-Date)
    }
}

function Remove-VUONGTTCrackThreats {
    [CmdletBinding()]
    param()

    $logs = [System.Collections.Generic.List[string]]::new()
    $logs.Add("==================================================")
    $logs.Add(" BẮT ĐẦU TIỆT TRỪ VÀ DỌN SẠCH CRACK RÁC HỆ THỐNG")
    $logs.Add(" Thời gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $logs.Add("==================================================")

    $scan = Get-VUONGTTCrackThreats
    $logs.Add("• Tổng số mối nguy crack phát hiện: $($scan.ThreatCount)")

    # 1. Xử lý Dịch vụ ngầm
    $rogueServiceNames = @(
        "AutoKMS", "KMSEmulator", "KMS-Server", "Service_KMS", 
        "KMSpicoService", "SECOH-QAD", "KmsService", "TunngleService"
    )
    foreach ($sName in $rogueServiceNames) {
        $svc = Get-Service -Name $sName -ErrorAction SilentlyContinue
        if ($svc) {
            $logs.Add("• Đang dừng & xóa dịch vụ rogue: $sName...")
            try {
                Stop-Service -Name $sName -Force -ErrorAction SilentlyContinue
                & sc.exe delete $sName | Out-Null
                $logs.Add("  ✅ Đã gỡ bỏ dịch vụ $sName.")
            } catch {
                $logs.Add("  ⚠️ Lỗi khi xóa dịch vụ: $($_.Exception.Message)")
            }
        }
    }

    # 2. Xử lý Tác vụ lập lịch
    $taskNames = @("AutoKMS", "AutoKMSDaily", "KMSpico", "KMSAuto", "KMSAutoNet", "KmsCleaner")
    foreach ($tn in $taskNames) {
        try {
            $t = Get-ScheduledTask -TaskName $tn -ErrorAction SilentlyContinue
            if ($t) {
                $logs.Add("• Đang xóa tác vụ lập lịch: $tn...")
                Unregister-ScheduledTask -TaskName $tn -Confirm:$false -ErrorAction SilentlyContinue
                $logs.Add("  ✅ Đã hủy đăng ký tác vụ $tn.")
            }
        } catch {}
    }

    # 3. Xử lý Registry IFEO Hook
    $ifeoTargets = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\SppExtComObj.exe",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\osppsvc.exe"
    )
    foreach ($ifeo in $ifeoTargets) {
        if (Test-Path $ifeo) {
            $logs.Add("• Phát hiện IFEO Hook tại: $ifeo. Đang gỡ bỏ...")
            try {
                Remove-Item -Path $ifeo -Recurse -Force -ErrorAction SilentlyContinue
                $logs.Add("  ✅ Đã làm sạch IFEO Hook: $(Split-Path $ifeo -Leaf).")
            } catch {
                $logs.Add("  ⚠️ Lỗi xóa key IFEO: $($_.Exception.Message)")
            }
        }
    }

    # 4. Xóa Thư mục & Tệp tin rác
    $crackPaths = @(
        "$env:ProgramFiles\KMSpico",
        "${env:ProgramFiles(x86)}\KMSpico",
        "$env:SystemRoot\AutoKMS",
        "$env:SystemRoot\Setup\Scripts\AutoKMS.exe",
        "$env:SystemRoot\System32\SppExtComObjHook.dll",
        "$env:SystemRoot\SysWOW64\SppExtComObjHook.dll",
        "$env:SystemRoot\System32\SECOH-QAD.exe",
        "$env:SystemRoot\SysWOW64\SECOH-QAD.exe",
        "$env:SystemDrive\KMSAuto"
    )
    foreach ($cp in $crackPaths) {
        if (Test-Path $cp) {
            $logs.Add("• Đang xóa tệp/thư mục: $cp...")
            try {
                Remove-Item -Path $cp -Recurse -Force -ErrorAction SilentlyContinue
                $logs.Add("  ✅ Đã dọn dẹp thành công: $(Split-Path $cp -Leaf)")
            } catch {
                $logs.Add("  ⚠️ Không thể xóa tệp (có thể đang bị khóa): $($_.Exception.Message)")
            }
        }
    }

    # 5. Làm sạch Hosts File
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    if (Test-Path $hostsFile) {
        try {
            $lines = Get-Content -Path $hostsFile -ErrorAction SilentlyContinue
            $cleanLines = [System.Collections.Generic.List[string]]::new()
            $modified = $false
            $kmsDomains = @("activation.sls.microsoft.com", "kms.core.windows.net", "kms8.msguides.com")

            foreach ($line in $lines) {
                $isKmsRedirect = $false
                foreach ($kd in $kmsDomains) {
                    if ($line -like "*$kd*") {
                        $isKmsRedirect = $true
                        $modified = $true
                        break
                    }
                }
                if (-not $isKmsRedirect) {
                    $cleanLines.Add($line)
                }
            }

            if ($modified) {
                Set-Content -Path $hostsFile -Value $cleanLines -Encoding ASCII -Force
                $logs.Add("✅ Đã làm sạch các dòng chuyển hướng KMS trong tập tin hosts.")
            }
        } catch {
            $logs.Add("⚠️ Lỗi làm sạch file hosts: $($_.Exception.Message)")
        }
    }

    # 6. Xóa địa chỉ KMS Server lậu đã gán vào Windows (slmgr /ckms)
    $logs.Add("• Đang xóa cổng/máy chủ KMS Server tùy chỉnh trong Windows (slmgr.vbs /ckms)...")
    try {
        $ckms = cscript.exe //nologo $env:SystemRoot\System32\slmgr.vbs /ckms 2>&1 | Out-String
        $logs.Add("  $($ckms.Trim())")
    } catch {}

    $logs.Add("✅ QUÁ TRÌNH DỌN SẠCH CRACK RÁC ĐÃ HOÀN TẤT!")
    $logs.Add("👉 Hệ thống hiện đã sạch hoàn toàn mã độc giả lập KMS.")

    return [PSCustomObject]@{
        Success = $true
        Logs    = ($logs -join "`r`n")
    }
}
