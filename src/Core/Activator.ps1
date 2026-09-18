# VUONGTT Toolkit 2026 - Activation & Crack Cleaner Module

function Invoke-VUONGTTMAS {
    param(
        [string]$Mode = "AIO" # AIO, HWID, Ohook, KMS38
    )
    # Launch MAS official online script in a new elevated PowerShell window
    $cmd = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://get.activated.win | iex"
    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $cmd
}

function Get-DecodedWindowsProductKey {
    try {
        $reg = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'DigitalProductId' -ErrorAction SilentlyContinue
        if (-not $reg -or -not $reg.DigitalProductId) { return $null }
        $bytes = [byte[]]$reg.DigitalProductId
        if ($bytes.Length -lt 67) { return $null }

        $map = 'BCDFGHJKMPQRTVWXY2346789'
        $isWin8 = [math]::Floor($bytes[66] / 6) -band 1
        $bytes[66] = ($bytes[66] -band 0xF7) -bor (($isWin8 -band 2) * 4)

        $chars = New-Object char[] 25
        $last = 0
        for ($i = 24; $i -ge 0; $i--) {
            $k = 0
            for ($j = 14; $j -ge 0; $j--) {
                $k = ($k * 256) -bxor $bytes[52 + $j]
                $bytes[52 + $j] = [math]::Floor($k / 24)
                $k = $k % 24
            }
            $chars[$i] = $map[$k]
            $last = $k
        }

        $keyPart = -join $chars
        if ($isWin8 -eq 1) {
            $keyPart = $keyPart.Substring(1, $last) + 'N' + $keyPart.Substring($last + 1)
        }

        $formatted = ''
        for ($i = 0; $i -lt 25; $i += 5) {
            if ($i -gt 0) { $formatted += '-' }
            $formatted += $keyPart.Substring($i, 5)
        }
        return $formatted
    } catch {
        return $null
    }
}

function Get-WindowsOEMKey {
    try {
        $biosKey = (Get-CimInstance -Query 'SELECT OA3xOriginalProductKey FROM SoftwareLicensingService' -ErrorAction SilentlyContinue).OA3xOriginalProductKey
        if ($biosKey -and $biosKey.Trim().Length -ge 10) {
            return $biosKey.Trim()
        }
    } catch {}
    return $null
}

function Get-VUONGTTOfficeActivationDetails {
    $details = @()
    $paths = @(
        (Join-Path $env:ProgramFiles 'Microsoft Office\Office16\OSPP.VBS'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Office\Office16\OSPP.VBS'),
        (Join-Path $env:ProgramFiles 'Microsoft Office\Office15\OSPP.VBS'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Office\Office15\OSPP.VBS'),
        (Join-Path $env:ProgramFiles 'Microsoft Office\Office14\OSPP.VBS')
    )

    $osppFound = $false
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $osppFound = $true
            try {
                $output = cscript //Nologo "$p" /dstatus
                $prodName = ""
                $licenseStatus = ""
                $partialKey = ""
                $desc = ""
                foreach ($line in ($output -split "`r?`n")) {
                    if ($line -match "LICENSE NAME:\s*(.+)") { $prodName = $matches[1].Trim() }
                    if ($line -match "LICENSE DESCRIPTION:\s*(.+)") { $desc = $matches[1].Trim() }
                    if ($line -match "LICENSE STATUS:\s*(.+)") { $licenseStatus = $matches[1].Trim() }
                    if ($line -match "Last 5 characters of installed product key:\s*([A-Za-z0-9]+)") { $partialKey = $matches[1].Trim() }
                }
                if ($licenseStatus) {
                    $details += [PSCustomObject]@{
                        Product     = if ($prodName) { $prodName } else { "Microsoft Office" }
                        Description = $desc
                        Status      = $licenseStatus
                        PartialKey  = $partialKey
                        Path        = $p
                    }
                }
            } catch {}
        }
    }

    try {
        $cimOffice = Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Office*" }
        foreach ($co in $cimOffice) {
            $stText = switch ($co.LicenseStatus) {
                1 { "---LICENSED--- (Đã kích hoạt bản quyền vĩnh viễn)" }
                2 { "OOB Grace (Đang trong thời gian ân hạn)" }
                default { "Trạng thái mã: $($co.LicenseStatus)" }
            }
            $already = $details | Where-Object { $_.PartialKey -eq $co.PartialProductKey }
            if (-not $already) {
                $details += [PSCustomObject]@{
                    Product     = $co.Name
                    Description = $co.Description
                    Status      = $stText
                    PartialKey  = $co.PartialProductKey
                    Path        = "WMI/CIM SoftwareLicensingProduct"
                }
            }
        }
    } catch {}

    $c2r = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
    $c2rVersion = if ($c2r -and $c2r.VersionToReport) { $c2r.VersionToReport } else { $null }
    $c2rProducts = if ($c2r -and $c2r.ProductReleaseIDs) { $c2r.ProductReleaseIDs } else { $null }

    return [PSCustomObject]@{
        Installed       = ($osppFound -or $details.Count -gt 0 -or ($null -ne $c2rVersion))
        Licenses        = $details
        ClickToRunVer   = $c2rVersion
        ClickToRunProds = $c2rProducts
    }
}

function Get-VUONGTTActivationStatus {
    $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $osName = if ($osInfo) { $osInfo.Caption } else { (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName }
    $osBuild = if ($osInfo) { "$($osInfo.Version) (Build $($osInfo.BuildNumber))" } else { "N/A" }
    $osArch = if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }

    $winLic = $null
    try {
        $winLic = Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Windows*" } | Select-Object -First 1
    } catch {}

    $winStatusText = "Chưa kích hoạt hoặc không thể xác định"
    $winChannel = "Chưa xác định"
    $winPartialKey = "N/A"
    if ($winLic) {
        $winPartialKey = if ($winLic.PartialProductKey) { $winLic.PartialProductKey } else { "N/A" }
        $winChannel = if ($winLic.Description) { $winLic.Description } else { "N/A" }
        $winStatusText = switch ($winLic.LicenseStatus) {
            1 { "Đã kích hoạt bản quyền vĩnh viễn (Licensed / Genuine)" }
            2 { "OOB Grace (Đang trong thời gian dùng thử / Ân hạn)" }
            3 { "OOT Grace (Quá hạn kích hoạt)" }
            4 { "Non-Genuine Grace (Cảnh báo bản quyền không chính hãng)" }
            5 { "Notification (Chế độ thông báo kích hoạt)" }
            default { "Chưa kích hoạt bản quyền (Mã trạng thái: $($winLic.LicenseStatus))" }
        }
    }

    $decodedKey = Get-DecodedWindowsProductKey
    $oemKey = Get-WindowsOEMKey
    $offDetails = Get-VUONGTTOfficeActivationDetails

    $lines = @()
    $lines += "================================================================================"
    $lines += "             KẾT QUẢ KIỂM TRA SÂU BẢN QUYỀN HỆ THỐNG (VUONGTT TOOLKIT)"
    $lines += "================================================================================"
    $lines += "[ 1. BẢN QUYỀN WINDOWS ]"
    $lines += "• Phiên bản HĐH   : $osName ($osArch)"
    $lines += "• Bản dựng (Build): $osBuild"
    $lines += "• Trạng thái      : $winStatusText"
    $lines += "• Kênh bản quyền  : $winChannel"
    if ($decodedKey) {
        $lines += "• Product Key Cài : $decodedKey (Khóa 25 ký tự đầy đủ)"
    } else {
        $lines += "• Product Key Cài : Không tìm thấy trong Registry hoặc khóa dạng số Digital"
    }
    $lines += "• Partial Key     : $winPartialKey (5 ký tự đuôi xác thực)"
    if ($oemKey) {
        $lines += "• Khóa OEM BIOS   : $oemKey (Khóa gốc nhúng trên Bo mạch chủ / Mainboard)"
    } else {
        $lines += "• Khóa OEM BIOS   : Không nhúng trong BIOS (Máy lắp ráp hoặc dùng Digital License)"
    }

    $lines += ""
    $lines += "[ 2. BẢN QUYỀN MICROSOFT OFFICE ]"
    if (-not $offDetails.Installed) {
        $lines += "• Trạng thái      : Chưa cài đặt Microsoft Office hoặc sử dụng bản Office App Store / Web"
    } else {
        if ($offDetails.ClickToRunVer) {
            $lines += "• Bản Click-To-Run: Office $($offDetails.ClickToRunVer) (Gói: $($offDetails.ClickToRunProds))"
        }
        if ($offDetails.Licenses.Count -gt 0) {
            foreach ($lic in $offDetails.Licenses) {
                $lines += "• Gói phần mềm    : $($lic.Product)"
                $lines += "  - Trạng thái    : $($lic.Status)"
                if ($lic.PartialKey) {
                    $lines += "  - 5 Ký tự đuôi  : $($lic.PartialKey)"
                }
                if ($lic.Description) {
                    $lines += "  - Chi tiết kênh : $($lic.Description)"
                }
            }
        } else {
            $lines += "• Ghi chú         : Đã phát hiện bộ cài Office nhưng chưa có thông tin bản quyền OSPP."
        }
    }
    $lines += "================================================================================"
    $lines += "Mẹo: Bấm nút '📋 Sao Chép Key & Bản Quyền' để lưu thông tin bản quyền vào bộ nhớ tạm."

    $report = $lines -join "`n"

    $summaryOffice = if (-not $offDetails.Installed) {
        "Chưa cài đặt Microsoft Office"
    } elseif ($offDetails.Licenses.Count -gt 0 -and ($offDetails.Licenses | Where-Object { $_.Status -match "LICENSED" })) {
        "Đã kích hoạt bản quyền (Licensed)"
    } else {
        "Chưa kích hoạt hoặc phiên bản dùng thử"
    }

    return [PSCustomObject]@{
        Windows        = $winStatusText
        Office         = $summaryOffice
        DetailedReport = $report
        ProductKey     = $decodedKey
        OEMKey         = $oemKey
    }
}

function Invoke-VUONGTTCleanCrack {
    [CmdletBinding()]
    param()

    $log = @()
    $log += "Bắt đầu quét và dọn dẹp các tệp/dịch vụ KMS Crack không rõ nguồn gốc..."

    # Common KMS cracks: KMSpico, KMSAuto, AutoKMS, KMS_VL_ALL
    $suspiciousServices = @("KMSAutoSvc", "KMSpicoService", "AutoKMS", "ServiceKMS")
    foreach ($svc in $suspiciousServices) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            sc.exe delete $svc | Out-Null
            $log += "[OK] Đã gỡ bỏ dịch vụ độc hại: $svc"
        }
    }

    # Suspicious Scheduled Tasks
    $tasks = @("AutoKMS", "AutoKMSDaily", "KMSpico", "KMSAuto")
    foreach ($t in $tasks) {
        Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
        $log += "[OK] Đã xóa tác vụ định kỳ: $t"
    }

    # Suspicious folders
    $folders = @(
        "$env:ProgramFiles\KMSpico",
        "${env:ProgramFiles(x86)}\KMSpico",
        "$env:SystemDrive\KMSAuto",
        "$env:ProgramData\KMSAuto"
    )
    foreach ($f in $folders) {
        if (Test-Path $f) {
            Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue
            $log += "[OK] Đã xóa thư mục crack: $f"
        }
    }

    # Clear KMS Server IP cache
    cscript //Nologo "$env:SystemRoot\System32\slmgr.vbs" /ckms | Out-Null
    $log += "[OK] Đã xóa địa chỉ máy chủ KMS lạ trong hệ thống Windows."

    $log += "Hoàn tất quy trình làm sạch. Bạn có thể sử dụng bản quyền số MAS an toàn!"
    return ($log -join "`n")
}
