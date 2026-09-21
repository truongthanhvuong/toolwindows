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

function Get-FriendlyOfficeProductName {
    param([string]$ReleaseIds)
    if (-not $ReleaseIds) { return "Microsoft Office" }
    $names = @()
    foreach ($id in ($ReleaseIds -split "[,; ]+")) {
        $clean = $id.Trim()
        if (-not $clean) { continue }
        $n = switch -Regex ($clean) {
            "^O365HomePremRetail$"    { "Microsoft 365 Family / Personal (Home Premium)" }
            "^O365ProPlusRetail$"     { "Microsoft 365 Apps for enterprise" }
            "^O365BusinessRetail$"    { "Microsoft 365 Business Standard / Premium" }
            "^ProPlus2024Retail$"     { "Office Professional Plus 2024 (Retail)" }
            "^ProPlus2024Volume$"     { "Office LTSC Professional Plus 2024 (Volume)" }
            "^ProPlus2021Retail$"     { "Office Professional Plus 2021 (Retail)" }
            "^ProPlus2021Volume$"     { "Office LTSC Professional Plus 2021 (Volume)" }
            "^ProPlus2019Retail$"     { "Office Professional Plus 2019 (Retail)" }
            "^ProPlus2019Volume$"     { "Office Professional Plus 2019 (Volume)" }
            "^ProPlusRetail$"         { "Office Professional Plus 2016 (Retail)" }
            "^ProPlusVolume$"         { "Office Professional Plus 2016 (Volume)" }
            "^Standard2021Volume$"    { "Office Standard 2021 (Volume)" }
            "^HomeStudent2021Retail$" { "Office Home & Student 2021" }
            "^HomeBusiness2021Retail$"{ "Office Home & Business 2021" }
            "^VisioPro2024Retail$"    { "Microsoft Visio Professional 2024" }
            "^VisioPro2021Retail$"    { "Microsoft Visio Professional 2021" }
            "^ProjectPro2024Retail$"  { "Microsoft Project Professional 2024" }
            "^ProjectPro2021Retail$"  { "Microsoft Project Professional 2021" }
            "^MondoVolume$"           { "Office Mondo 2016 / 365 (Volume)" }
            default                   { $clean }
        }
        $names += $n
    }
    if ($names.Count -gt 0) { return ($names -join " + ") }
    return $ReleaseIds
}

function Get-VUONGTTOfficeActivationDetails {
    $details = @()

    # 1. Kiểm tra công nghệ kích hoạt MAS Ohook vNext (Phương pháp kích hoạt Office 365 / C2R phổ biến nhất)
    $ohookFound = $false
    $ohookPath = ""
    $candidateOhooks = @(
        "$env:ProgramFiles\Microsoft Office\root\vfs\System\sppc.dll",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\vfs\System\sppc.dll",
        "$env:ProgramFiles\Microsoft Office\root\Office16\sppc.dll",
        "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\sppc.dll",
        "$env:ProgramFiles\Microsoft Office\Office16\sppc.dll",
        "${env:ProgramFiles(x86)}\Microsoft Office\Office16\sppc.dll"
    )
    foreach ($oh in $candidateOhooks) {
        if (Test-Path $oh) {
            $ohookFound = $true
            $ohookPath = $oh
            break
        }
    }

    if ($ohookFound) {
        $details += [PSCustomObject]@{
            Product     = "Microsoft Office (Word, Excel, PowerPoint, Outlook, Access...)"
            Description = "Bản quyền số vĩnh viễn (Kích hoạt qua MAS Ohook vNext Genuine)"
            Status      = "---LICENSED--- (Đã kích hoạt bản quyền vĩnh viễn theo máy)"
            PartialKey  = "OHOOK-PERMANENT"
            Path        = $ohookPath
        }
    }

    # 2. Kiểm tra tài khoản Microsoft 365 Subscription (Account Identity)
    $m365Accounts = @()
    $identityRoot = "HKCU:\Software\Microsoft\Office\16.0\Common\Identity\Identities"
    if (Test-Path $identityRoot) {
        try {
            $subKeys = Get-ChildItem -Path $identityRoot -ErrorAction SilentlyContinue
            foreach ($sk in $subKeys) {
                $prop = Get-ItemProperty -Path $sk.PSPath -ErrorAction SilentlyContinue
                $email = if ($prop.EmailAddress) { $prop.EmailAddress } elseif ($prop.UPN) { $prop.UPN } elseif ($prop.SigninName) { $prop.SigninName } else { "" }
                if ($email -and $email -match "@") {
                    $friendly = if ($prop.FriendlyName) { $prop.FriendlyName } else { "" }
                    $m365Accounts += [PSCustomObject]@{
                        Email    = $email
                        Friendly = $friendly
                    }
                }
            }
        } catch {}
    }

    if ($m365Accounts.Count -gt 0 -and (-not $ohookFound)) {
        $act = $m365Accounts[0]
        $actDesc = if ($act.Friendly) { "$($act.Email) ($($act.Friendly))" } else { $act.Email }
        $details += [PSCustomObject]@{
            Product     = "Microsoft 365 Subscription"
            Description = "Bản quyền thuê bao chính thức của Microsoft"
            Status      = "---LICENSED--- (Đã kích hoạt bản quyền thuê bao Microsoft 365)"
            PartialKey  = "M365-ACTIVE"
            Path        = "Tài khoản: $actDesc"
        }
    }

    # 3. Kiểm tra kịch bản OSPP.VBS cổ điển (Dành cho bản Volume VL, KMS, MAK)
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
                    $already = $details | Where-Object { $_.PartialKey -eq $partialKey }
                    if (-not $already) {
                        $details += [PSCustomObject]@{
                            Product     = if ($prodName) { $prodName } else { "Microsoft Office" }
                            Description = $desc
                            Status      = $licenseStatus
                            PartialKey  = $partialKey
                            Path        = $p
                        }
                    }
                }
            } catch {}
        }
    }

    # 4. Kiểm tra WMI SoftwareLicensingProduct & OfficeSoftwareProtectionProduct
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
                    Path        = "WMI SoftwareLicensingProduct"
                }
            }
        }
    } catch {}

    try {
        $cimOspp = Get-CimInstance -ClassName OfficeSoftwareProtectionProduct -ErrorAction SilentlyContinue | Where-Object { $_.LicenseStatus -eq 1 -or ($_.PartialProductKey -and $_.PartialProductKey.Trim().Length -gt 0) }
        foreach ($co in $cimOspp) {
            $stText = switch ($co.LicenseStatus) {
                1 { "---LICENSED--- (Đã kích hoạt bản quyền vĩnh viễn)" }
                2 { "OOB Grace (Đang trong thời gian ân hạn)" }
                default { "Trạng thái mã: $($co.LicenseStatus)" }
            }
            $partKey = if ($co.PartialProductKey) { $co.PartialProductKey } else { "C2R-LIC" }
            $already = $details | Where-Object { $_.PartialKey -eq $partKey }
            if (-not $already) {
                $details += [PSCustomObject]@{
                    Product     = if ($co.Name) { $co.Name } else { "Microsoft Office" }
                    Description = if ($co.Description) { $co.Description } else { "Office Software Protection" }
                    Status      = $stText
                    PartialKey  = $partKey
                    Path        = "WMI OfficeSoftwareProtectionProduct"
                }
            }
        }
    } catch {}

    # 5. Kiểm tra thông tin gói Click-To-Run
    $c2r = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
    $c2rVersion = if ($c2r -and $c2r.VersionToReport) { $c2r.VersionToReport } else { $null }
    $c2rProducts = if ($c2r -and $c2r.ProductReleaseIDs) { $c2r.ProductReleaseIDs } else { $null }
    $friendlyProds = if ($c2rProducts) { Get-FriendlyOfficeProductName -ReleaseIds $c2rProducts } else { "" }

    # 6. Kiểm tra token vNext / Heartbeat / LicensingCache nếu chưa có license nào
    $hasVNextToken = $false
    if ($details.Count -eq 0 -and $c2rVersion) {
        $licDirs = @(
            "$env:LOCALAPPDATA\Microsoft\Office\Licenses",
            "$env:ProgramData\Microsoft\Office\Licenses",
            "$env:ProgramData\Microsoft\Office\Heartbeat"
        )
        foreach ($ld in $licDirs) {
            if (Test-Path $ld) {
                $fCount = (Get-ChildItem -Path $ld -Recurse -File -ErrorAction SilentlyContinue).Count
                if ($fCount -gt 0) { $hasVNextToken = $true; break }
            }
        }
        if (-not $hasVNextToken) {
            $licCache = Get-ChildItem -Path "HKCU:\Software\Microsoft\Office\16.0\Common\Licensing\LicensingCache" -ErrorAction SilentlyContinue
            if ($licCache -and $licCache.Count -gt 0) { $hasVNextToken = $true }
        }

        if ($hasVNextToken) {
            $details += [PSCustomObject]@{
                Product     = if ($friendlyProds) { $friendlyProds } else { "Microsoft Office Click-to-Run" }
                Description = "Giấy phép số kỹ thuật số (vNext Digital License Token)"
                Status      = "---LICENSED--- (Đang hoạt động đầy đủ tính năng bản quyền)"
                PartialKey  = "VNEXT-TOKEN"
                Path        = "Office Click-to-Run Licensing Service"
            }
        }
    }

    return [PSCustomObject]@{
        Installed         = ($osppFound -or $details.Count -gt 0 -or ($null -ne $c2rVersion))
        Licenses          = $details
        ClickToRunVer     = $c2rVersion
        ClickToRunProds   = $c2rProducts
        FriendlyProds     = $friendlyProds
        OhookActive       = $ohookFound
        M365Accounts      = $m365Accounts
        HasVNextToken     = $hasVNextToken
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
        $keyNote = if ($decodedKey -eq "VK7JG-NPHTM-C97JM-9MPGT-3V66T") {
            " (Khóa số mặc định chính hãng Microsoft cho Windows 11/10 Pro)"
        } elseif ($decodedKey -eq "YTMG3-N6DKC-DKB77-7M9GH-8HVX7") {
            " (Khóa số mặc định chính hãng Microsoft cho Windows 11/10 Home)"
        } else {
            " (Khóa 25 ký tự đầy đủ)"
        }
        $lines += "• Product Key Cài : $decodedKey$keyNote"
        $lines += "• Loại bản quyền  : Bản quyền số vĩnh viễn (Digital License / HWID liên kết Mainboard)"
    } else {
        $lines += "• Product Key Cài : Bản quyền số kỹ thuật số liên kết phần cứng máy tính"
    }

    $lines += "• Partial Key     : $winPartialKey (5 ký tự đuôi xác thực)"
    if ($oemKey) {
        $lines += "• Khóa OEM BIOS   : $oemKey (Khóa gốc từ nhà sản xuất gắn liền Bo mạch chủ)"
    } else {
        $lines += "• Khóa OEM BIOS   : Không nhúng trong BIOS (Máy tính lắp ráp hoặc kích hoạt bản quyền số)"
    }

    $lines += ""
    $lines += "[ 2. BẢN QUYỀN MICROSOFT OFFICE ]"
    if (-not $offDetails.Installed) {
        $lines += "• Trạng thái      : Chưa cài đặt Microsoft Office trên hệ thống"
    } else {
        if ($offDetails.ClickToRunVer) {
            $displayPkg = if ($offDetails.FriendlyProds) { $offDetails.FriendlyProds } else { $offDetails.ClickToRunProds }
            $lines += "• Phiên bản cài   : Office $($offDetails.ClickToRunVer) (Gói: $displayPkg)"
        }

        if ($offDetails.Licenses.Count -gt 0) {
            foreach ($lic in $offDetails.Licenses) {
                $lines += "• Gói phần mềm    : $($lic.Product)"
                $lines += "  - Trạng thái    : $($lic.Status)"
                if ($lic.PartialKey -and $lic.PartialKey -ne "N/A") {
                    $lines += "  - Nhận diện key : $($lic.PartialKey)"
                }
                if ($lic.Description) {
                    $lines += "  - Chi tiết kênh : $($lic.Description)"
                }
            }
        } else {
            # Trường hợp đã cài Click-To-Run nhưng không tìm thấy license chi tiết
            $lines += "• Trạng thái      : Đang hoạt động theo giấy phép bản quyền số Click-to-Run (Retail)"
            $lines += "• Khuyến nghị     : Nếu bạn muốn kích hoạt bản quyền vĩnh viễn cho tất cả ứng dụng Office,"
            $lines += "                    vui lòng bấm nút '⚡ Khởi Chạy MAS Kích Hoạt' ở trên (chọn mục Ohook)."
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
        "Đang hoạt động (Click-to-Run)"
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
