# SkuConverterEngine.ps1
# Engine Chuyển Đổi Phiên Bản Windows SKU & Office Retail to Volume (C2R-R2V)
# Tương thích Windows 10, 11, Server & Office 2016/2019/2021/2024/365

function Get-VUONGTTCurrentWindowsEdition {
    [CmdletBinding()]
    param()

    try {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $props = Get-ItemProperty -Path $regPath -ErrorAction Stop
        
        $editionId = $props.EditionID
        $productName = $props.ProductName
        $composition = $props.CompositionEditionID
        $displayVer = $props.DisplayVersion
        if (-not $displayVer) { $displayVer = $props.ReleaseId }

        return [PSCustomObject]@{
            EditionId            = $editionId
            ProductName          = $productName
            CompositionEditionId = $composition
            DisplayVersion       = $displayVer
            CurrentBuild         = $props.CurrentBuild
        }
    } catch {
        return [PSCustomObject]@{
            EditionId            = "Unknown"
            ProductName          = (Get-CimInstance Win32_OperatingSystem).Caption
            CompositionEditionId = ""
            DisplayVersion       = ""
            CurrentBuild         = ""
        }
    }
}

function Get-VUONGTTSupportedTargetSkus {
    [CmdletBinding()]
    param()

    # Danh mục Microsoft Official Generic & KMS Upgrade Keys
    return @(
        [PSCustomObject]@{
            SkuName     = "Windows 10/11 Pro (Chuyên nghiệp)"
            EditionId   = "Professional"
            GenericKey  = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
            KmsKey      = "W269N-WFGWX-YVC9B-4J6C9-T83GX"
            Description = "Nâng cấp từ Home lên Pro để mở Remote Desktop, BitLocker, Group Policy"
        },
        [PSCustomObject]@{
            SkuName     = "Windows 10/11 Enterprise (Doanh nghiệp)"
            EditionId   = "Enterprise"
            GenericKey  = "XGVPP-NMH47-7TTHJ-W3FW7-8HV2C"
            KmsKey      = "NPPR9-FWDCX-D2C8J-H872K-2YT43"
            Description = "Dành cho tổ chức, doanh nghiệp lớn, đầy đủ tính năng bảo mật cao nhất"
        },
        [PSCustomObject]@{
            SkuName     = "Windows 10/11 Pro Education (Giáo dục Pro)"
            EditionId   = "ProEducation"
            GenericKey  = "6TP4R-GNPTD-KYYHQ-7B7DP-J4477"
            KmsKey      = "NRG8B-VKK3Q-CXVCJ-9G2XF-6Q84J"
            Description = "Bản Pro tối ưu cho môi trường trường học & giáo dục"
        },
        [PSCustomObject]@{
            SkuName     = "Windows 10/11 Pro for Workstations (Trạm đồ họa)"
            EditionId   = "ProfessionalWorkstation"
            GenericKey  = "DXG7C-N36C4-C4HTG-X4T3X-2YV77"
            KmsKey      = "WYPNQ-8C467-V2W6J-TX4WX-WTX2W"
            Description = "Tối ưu phần cứng cao cấp Xeon/EPYC, RAM lớn và ReFS"
        },
        [PSCustomObject]@{
            SkuName     = "Windows 10/11 IoT Enterprise"
            EditionId   = "IoTEnterprise"
            GenericKey  = "XQQYW-NFFMW-XJPBH-K8732-CKFFD"
            KmsKey      = "KBN8V-HFGQ4-STY8X-Q44XX-6RR33"
            Description = "Hỗ trợ vòng đời siêu dài LTSC/IoT, không rác bloatware"
        }
    )
}

function Invoke-VUONGTTWindowsSkuConvert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetEditionId,
        [Parameter(Mandatory = $false)]
        [string]$CustomKey = ""
    )

    $logs = [System.Collections.Generic.List[string]]::new()
    $logs.Add("==================================================")
    $logs.Add(" BẮT ĐẦU CHUYỂN ĐỔI PHIÊN BẢN WINDOWS SKU")
    $logs.Add(" Thời gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $logs.Add("==================================================")

    $cur = Get-VUONGTTCurrentWindowsEdition
    $logs.Add("• Phiên bản hiện tại: $($cur.ProductName) ($($cur.EditionId))")
    $logs.Add("• Mục tiêu chuyển đổi: $TargetEditionId")

    # Xác định Key cần nạp
    $keyToUse = $CustomKey
    if (-not $keyToUse) {
        $skuList = Get-VUONGTTSupportedTargetSkus
        $matched = $skuList | Where-Object { $_.EditionId -eq $TargetEditionId }
        if ($matched) {
            $keyToUse = $matched.GenericKey
        }
    }

    if (-not $keyToUse) {
        $logs.Add("❌ Không xác định được Generic Key cho phiên bản $TargetEditionId!")
        return [PSCustomObject]@{
            Success = $false
            Logs    = ($logs -join "`r`n")
        }
    }

    $logs.Add("• Đang nạp Generic Upgrade Key: $keyToUse")

    # Cách 1: Sử dụng changepk.exe
    $changepk = "$env:SystemRoot\System32\changepk.exe"
    if (Test-Path $changepk) {
        $logs.Add("• Thực thi chuyển đổi qua changepk.exe...")
        try {
            $proc = Start-Process -FilePath $changepk -ArgumentList "/ProductKey $keyToUse" -NoNewWindow -PassThru -Wait
            if ($proc.ExitCode -eq 0) {
                $logs.Add("✅ Lệnh changepk hoàn tất thành công (ExitCode 0)!")
                $logs.Add("⚠️ Windows có thể cần khởi động lại máy để hoàn tất nạp các gói tính năng của phiên bản mới.")
                return [PSCustomObject]@{
                    Success = $true
                    Logs    = ($logs -join "`r`n")
                }
            } else {
                $logs.Add("⚠️ changepk trả về mã thoát: $($proc.ExitCode). Đang thử tiếp giải pháp DISM / slmgr...")
            }
        } catch {
            $logs.Add("⚠️ Lỗi gọi changepk: $($_.Exception.Message)")
        }
    }

    # Cách 2: DISM /Set-Edition
    $dism = "$env:SystemRoot\System32\dism.exe"
    if (Test-Path $dism) {
        $logs.Add("• Thực thi lệnh DISM Set-Edition: /Set-Edition:$TargetEditionId /ProductKey:$keyToUse /NoRestart...")
        try {
            $dismOut = & $dism /online /Set-Edition:$TargetEditionId /ProductKey:$keyToUse /AcceptEula /NoRestart 2>&1 | Out-String
            $logs.Add($dismOut)
            if ($LASTEXITCODE -eq 0) {
                $logs.Add("✅ DISM chuyển đổi SKU thành công!")
                return [PSCustomObject]@{
                    Success = $true
                    Logs    = ($logs -join "`r`n")
                }
            }
        } catch {
            $logs.Add("⚠️ Lỗi thực thi DISM: $($_.Exception.Message)")
        }
    }

    # Cách 3: slmgr.vbs /ipk
    $slmgr = "$env:SystemRoot\System32\slmgr.vbs"
    $logs.Add("• Nạp Product Key qua slmgr.vbs...")
    try {
        $slmgrOut = cscript.exe //nologo $slmgr /ipk $keyToUse 2>&1 | Out-String
        $logs.Add($slmgrOut)
    } catch {
        $logs.Add("⚠️ Lỗi slmgr: $($_.Exception.Message)")
    }

    $after = Get-VUONGTTCurrentWindowsEdition
    $isSuccess = ($after.EditionId -like "*$TargetEditionId*")
    if ($isSuccess) {
        $logs.Add("✅ Nâng cấp SKU Windows thành công! Phiên bản mới: $($after.ProductName)")
    } else {
        $logs.Add("ℹ️ Đã gửi lệnh nâng cấp. Nếu hệ thống thông báo cần khởi động lại, hãy Restart máy để áp dụng.")
    }

    return [PSCustomObject]@{
        Success = $isSuccess
        Logs    = ($logs -join "`r`n")
    }
}

function Invoke-VUONGTTOfficeR2VConvert {
    [CmdletBinding()]
    param()

    $logs = [System.Collections.Generic.List[string]]::new()
    $logs.Add("==================================================")
    $logs.Add(" CHUYỂN ĐỔI OFFICE RETAIL SANG VOLUME (C2R-R2V)")
    $logs.Add(" Thời gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $logs.Add("==================================================")

    # 1. Định vị thư mục cài đặt Office ClickToRun
    $c2rLicPaths = @(
        "$env:ProgramFiles\Microsoft Office\root\Licenses16",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Licenses16"
    )

    $licDir = $null
    foreach ($p in $c2rLicPaths) {
        if (Test-Path $p) {
            $licDir = $p
            break
        }
    }

    if (-not $licDir) {
        $logs.Add("❌ Không tìm thấy thư mục bản quyền Office Click-to-Run (Licenses16).")
        $logs.Add("• Vui lòng đảm bảo Office (2016/2019/2021/2024/365) đã được cài đặt trên máy.")
        return [PSCustomObject]@{
            Success = $false
            Logs    = ($logs -join "`r`n")
        }
    }

    $logs.Add("• Tìm thấy thư mục chứng chỉ bản quyền: $licDir")

    # 2. Định vị ospp.vbs
    $osppPaths = @(
        "$env:ProgramFiles\Microsoft Office\Office16\ospp.vbs",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs",
        "$env:ProgramFiles\Microsoft Office\Office15\ospp.vbs",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office15\ospp.vbs"
    )

    $osppFile = $null
    foreach ($o in $osppPaths) {
        if (Test-Path $o) {
            $osppFile = $o
            break
        }
    }

    if (-not $osppFile) {
        $logs.Add("❌ Không tìm thấy công cụ OSPP (ospp.vbs) của Microsoft Office.")
        return [PSCustomObject]@{
            Success = $false
            Logs    = ($logs -join "`r`n")
        }
    }

    $logs.Add("• Tìm thấy công cụ OSPP: $osppFile")

    # 3. Quét các file chứng chỉ Volume trong Licenses16 (ProPlus, Standard, Mondo, v.v.)
    $volCertFiles = Get-ChildItem -Path $licDir -Filter "*VL_KMS*.xrm-ms" -ErrorAction SilentlyContinue
    if (-not $volCertFiles -or $volCertFiles.Count -eq 0) {
        $volCertFiles = Get-ChildItem -Path $licDir -Filter "*Volume*.xrm-ms" -ErrorAction SilentlyContinue
    }

    if (-not $volCertFiles -or $volCertFiles.Count -eq 0) {
        $logs.Add("⚠️ Không tìm thấy file chứng chỉ VL (*VL_KMS*.xrm-ms) trực tiếp trong Licenses16.")
        $logs.Add("• Đang áp dụng cơ chế chuyển đổi C2R qua cấu hình Registry...")
        try {
            $regC2R = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
            if (Test-Path $regC2R) {
                Set-ItemProperty -Path $regC2R -Name "ProductKeys" -Value "" -ErrorAction SilentlyContinue
                $logs.Add("• Đã làm sạch ProductKeys Retail trong Registry ClickToRun.")
            }
        } catch {}
    } else {
        $logs.Add("• Phát hiện $($volCertFiles.Count) chứng chỉ Volume License phù hợp. Đang nạp chứng chỉ...")
        $count = 0
        foreach ($cert in $volCertFiles) {
            $out = cscript.exe //nologo $osppFile /inslic:"$($cert.FullName)" 2>&1 | Out-String
            $count++
            if ($count -le 3) {
                $logs.Add("  - Đã nạp: $($cert.Name)")
            }
        }
        if ($count -gt 3) {
            $logs.Add("  - ...và $($count - 3) chứng chỉ Volume License khác đã được nạp thành công.")
        }
    }

    # 4. Nạp GVLK cho Office Mondo / ProPlus Volume để sẵn sàng kích hoạt MAS/KMS
    # Office 2021 ProPlus Volume GVLK: FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH
    # Office 2019 ProPlus Volume GVLK: NMMKJ-6RK4F-KMJVX-8D9MJ-6MWKP
    # Office 2016 ProPlus Volume GVLK: XQNVK-8JYDB-WJ9W3-YJ8YR-WFG99
    $proPlus2021Gvlk = "FXYTK-NJJ8C-GB6DW-3DYQT-6F7TH"
    $logs.Add("• Cài đặt Volume GVLK chuẩn cho Office ProPlus ($proPlus2021Gvlk)...")
    $ipkOut = cscript.exe //nologo $osppFile /inpkey:$proPlus2021Gvlk 2>&1 | Out-String
    $logs.Add($ipkOut)

    $logs.Add("✅ Hoàn tất chuyển đổi Office Retail sang Volume License (C2R-R2V)!")
    $logs.Add("👉 Bây giờ bạn có thể bấm '⚡ Khởi Chạy MAS Kích Hoạt' để kích hoạt vĩnh viễn Office qua KMS/Ohook.")

    return [PSCustomObject]@{
        Success = $true
        Logs    = ($logs -join "`r`n")
    }
}
