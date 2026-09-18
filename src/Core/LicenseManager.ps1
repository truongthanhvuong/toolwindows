# =========================================================================
#   VUONGTT TOOLKIT 2026 - LICENSE & ADMIN MANAGEMENT ENGINE
#   Chức năng: Quản lý bản quyền Free/PRO, Mã hóa HWID khóa 1 máy tính,
#              Quản lý phân quyền tính năng, Tạo/Xóa License Key, Đăng nhập Admin
# =========================================================================

$script:CONFIG_DIR = Join-Path $PSScriptRoot "..\Config"
if (-not (Test-Path $script:CONFIG_DIR)) {
    New-Item -Path $script:CONFIG_DIR -ItemType Directory -Force | Out-Null
}

$script:AUTH_FILE       = Join-Path $script:CONFIG_DIR "admin_auth.json"
$script:POLICY_FILE     = Join-Path $script:CONFIG_DIR "feature_policy.json"
$script:VAULT_FILE      = Join-Path $script:CONFIG_DIR "licenses_vault.json"
$script:ACTIVE_LIC_FILE = Join-Path $script:CONFIG_DIR "active_license.lic"

# -------------------------------------------------------------------------
# 1. HARDWARE IDENTIFIER (HWID) ENGINE
# -------------------------------------------------------------------------
function Get-VUONGTTHardwareId {
    [CmdletBinding()]
    param()
    try {
        $biosSerial = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
        if (-not $biosSerial) { $biosSerial = "BIOS-GENERIC-DEFAULT" }

        $mbSerial = (Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue).SerialNumber
        if (-not $mbSerial) { $mbSerial = "MB-GENERIC-DEFAULT" }

        $cpuId = (Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1).ProcessorId
        if (-not $cpuId) { $cpuId = "CPUID-GENERIC-DEFAULT" }

        $rawSeed = "VUONGTT-" + $biosSerial + "-" + $mbSerial + "-" + $cpuId
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($rawSeed)
        $hashBytes = $sha.ComputeHash($bytes)
        $hex = ($hashBytes | ForEach-Object { $_.ToString("X2") }) -join ""
        
        # Format HWID: HWID-XXXX-XXXX-XXXX-XXXX
        $hwid = "HWID-" + $hex.Substring(0, 4) + "-" + $hex.Substring(4, 4) + "-" + $hex.Substring(8, 4) + "-" + $hex.Substring(12, 4)
        return $hwid
    } catch {
        return "HWID-FALLBACK-" + $env:COMPUTERNAME
    }
}

# -------------------------------------------------------------------------
# 2. ADMIN AUTHENTICATION & ENCRYPTED MASTER ACCESS (OFFLINE RESILIENT)
# -------------------------------------------------------------------------
# BẢO MẬT MẬT MÃ ADMIN: Salted SHA-256 Master Hash (Không lưu mật khẩu dạng plain-text)
$script:MASTER_ADMIN_SALT = "VUONGTT_ADMIN_SALT_v2026_MASTER"
$script:MASTER_ADMIN_HASH = "C3D35E18E6BEC6539690B9911694A664CDE362406B5528FA74B18AC4FC9FC374"

function Get-VUONGTTSha256Hash {
    param([string]$Text, [string]$Salt = "VUONGTT_ADMIN_SALT_v2026_MASTER")
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $rawStr = $Text + ":" + $Salt
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($rawStr)
    $hashBytes = $sha.ComputeHash($bytes)
    return ($hashBytes | ForEach-Object { $_.ToString("X2") }) -join ""
}

function Init-VUONGTTAdminAuth {
    if (-not (Test-Path $script:AUTH_FILE)) {
        # Khóa cứng trên tất cả các máy: IsFirstLogin luôn là false (CHẶN TẠO PASS MỚI TRÊN MÁY KHÁC)
        # Mật khẩu Admin Master được bảo vệ bằng salt và mã hóa một chiều
        $authData = [PSCustomObject]@{
            IsFirstLogin  = $false
            PasswordHash  = $script:MASTER_ADMIN_HASH
            LastChanged   = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
            Account       = "admin"
        }
        $authData | ConvertTo-Json -Depth 4 | Set-Content -Path $script:AUTH_FILE -Encoding UTF8
    }
}

function Test-VUONGTTAdminAuth {
    param([string]$Password)
    if ([string]::IsNullOrEmpty($Password)) {
        return [PSCustomObject]@{ IsValid = $false; IsFirstLogin = $false; Account = "admin" }
    }

    # 1. KIỂM TRA TRỰC TIẾP MẬT KHẨU GỐC GÁN CHẾT (MÃ HÓA MẬT MÃ - HOẠT ĐỘNG 100% OFFLINE TRÊN MỌI MÁY)
    $masterCheck = Get-VUONGTTSha256Hash -Text $Password -Salt $script:MASTER_ADMIN_SALT
    if ($masterCheck -eq $script:MASTER_ADMIN_HASH) {
        return [PSCustomObject]@{
            IsValid      = $true
            IsFirstLogin = $false
            Account      = "admin"
        }
    }

    # 2. KIỂM TRA MẬT KHẨU TÙY BIẾN ĐÃ ĐỔI TRONG FILE AUTH (NẾU CÓ)
    try {
        Init-VUONGTTAdminAuth
        if (Test-Path $script:AUTH_FILE) {
            $data = Get-Content -Path $script:AUTH_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($data -and $data.PasswordHash) {
                $customCheck = Get-VUONGTTSha256Hash -Text $Password -Salt $script:MASTER_ADMIN_SALT
                if ($customCheck -eq $data.PasswordHash) {
                    return [PSCustomObject]@{
                        IsValid      = $true
                        IsFirstLogin = $false
                        Account      = $data.Account
                    }
                }
                # Tương thích ngược với salt cũ nếu file cũ tồn tại
                $legacyCheck = Get-VUONGTTSha256Hash -Text $Password -Salt "VUONGTT_SALT_2026"
                if ($legacyCheck -eq $data.PasswordHash) {
                    return [PSCustomObject]@{
                        IsValid      = $true
                        IsFirstLogin = $false
                        Account      = $data.Account
                    }
                }
            }
        }
    } catch {}

    return [PSCustomObject]@{ IsValid = $false; IsFirstLogin = $false; Account = "admin" }
}

function Set-VUONGTTAdminPassword {
    param([string]$NewPassword)
    Init-VUONGTTAdminAuth
    try {
        $newHash = Get-VUONGTTSha256Hash -Text $NewPassword -Salt $script:MASTER_ADMIN_SALT
        $authData = [PSCustomObject]@{
            IsFirstLogin  = $false
            PasswordHash  = $newHash
            LastChanged   = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
            Account       = "admin"
        }
        $authData | ConvertTo-Json -Depth 4 | Set-Content -Path $script:AUTH_FILE -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}

# -------------------------------------------------------------------------
# 3. FEATURE POLICY ENGINE (FREE VS PRO TIERS)
# -------------------------------------------------------------------------
function Get-VUONGTTDefaultFeatures {
    return @(
        [PSCustomObject]@{ Id = "SysInfo";      Name = "Xem Cấu Hình Máy Tính";          Icon = "💻"; Tier = "FREE"; Description = "Xem thông số CPU, RAM, GPU, Mainboard, ổ cứng thời gian thực" },
        [PSCustomObject]@{ Id = "Customize";    Name = "Tùy Chỉnh Thông Tin Máy";        Icon = "🖥️"; Tier = "FREE"; Description = "Đổi tên máy tính, Workgroup, chủ sở hữu OEM" },
        [PSCustomObject]@{ Id = "Users";        Name = "Quản Lý User & PC";              Icon = "👤"; Tier = "FREE"; Description = "Quản trị người dùng Windows, reset mật khẩu, kích hoạt Administrator" },
        [PSCustomObject]@{ Id = "Benchmark";    Name = "Tốc Độ Ổ Đĩa (Benchmark)";       Icon = "⚡"; Tier = "PRO";  Description = "Đo tốc độ đọc/ghi tuần tự và ngẫu nhiên SSD/HDD chuyên sâu" },
        [PSCustomObject]@{ Id = "LaptopCheck";  Name = "Kiểm Tra Laptop & Ngoại Vi";     Icon = "🔬"; Tier = "FREE"; Description = "Test bàn phím offline, pin chai, loa đa tần, dead pixel, mic, webcam" },
        [PSCustomObject]@{ Id = "CpuMain";      Name = "Tra Cứu CPU + Main";             Icon = "💡"; Tier = "FREE"; Description = "Tra cứu độ tương thích socket, chipset mainboard và CPU" },
        [PSCustomObject]@{ Id = "Office";       Name = "Cài Đặt Office (Tự Động)";       Icon = "📑"; Tier = "FREE"; Description = "Cài đặt Office 2016-2024 / 365 tự động trọn gói" },
        [PSCustomObject]@{ Id = "Software";     Name = "Tải Ứng Dụng Thiết Yếu";         Icon = "📥"; Tier = "FREE"; Description = "Kho phần mềm văn phòng, đồ họa, tiện ích cần thiết" },
        [PSCustomObject]@{ Id = "CustomApp";    Name = "Phần Mềm Kế Toán & Khác";        Icon = "📊"; Tier = "FREE"; Description = "Cài đặt MISA, HTKK, iTaxViewer và ứng dụng doanh nghiệp" },
        [PSCustomObject]@{ Id = "Uninstaller";  Name = "Gỡ Phần Mềm & Dọn Sạch Sâu";    Icon = "🗑️"; Tier = "PRO";  Description = "Gỡ cài đặt hàng loạt và dọn sạch sâu tận gốc Registry/AppData" },
        [PSCustomObject]@{ Id = "Fonts";        Name = "Kho Font Tiếng Việt & AutoCAD";  Icon = "🔤"; Tier = "FREE"; Description = "Cài đặt trọn bộ Font VNI, TCVN3, Unicode và Font AutoCAD .shx" },
        [PSCustomObject]@{ Id = "Cleaner";      Name = "Dọn Rác & Tăng Tốc Win";         Icon = "🧹"; Tier = "FREE"; Description = "Xóa cache tạm, dọn dẹp hệ điều hành và tối ưu hóa" },
        [PSCustomObject]@{ Id = "Tweaks";       Name = "Tinh Chỉnh Hệ Thống";            Icon = "⚙️"; Tier = "PRO";  Description = "Tối ưu hóa Windows sâu, tắt telemetry, tăng tốc đồ họa & game" },
        [PSCustomObject]@{ Id = "PrinterLAN";   Name = "Sửa Lỗi Máy In & Mạng LAN";      Icon = "🖨️"; Tier = "PRO";  Description = "Khắc phục lỗi chia sẻ máy in 0x0000011b, 0x00000709 và thông mạng LAN" },
        [PSCustomObject]@{ Id = "BackupDriver"; Name = "Sao Lưu / Phục Hồi Driver";      Icon = "💾"; Tier = "PRO";  Description = "Backup toàn bộ driver thiết bị và phục hồi tự động khi cài lại máy" },
        [PSCustomObject]@{ Id = "DevMgmt";      Name = "Quản Lý Thiết Bị Phần Cứng";     Icon = "🔌"; Tier = "FREE"; Description = "Quản lý Device Manager, kiểm tra driver thiếu hoặc lỗi" },
        [PSCustomObject]@{ Id = "Activation";   Name = "Kích Hoạt Bản Quyền Số";         Icon = "🔑"; Tier = "PRO";  Description = "Kích hoạt bản quyền kỹ thuật số vĩnh viễn cho Windows & Office" },
        [PSCustomObject]@{ Id = "BitLocker";    Name = "Tắt BitLocker & EFS";            Icon = "🔒"; Tier = "PRO";  Description = "Mở khóa và giải mã phân vùng ổ đĩa an toàn" },
        [PSCustomObject]@{ Id = "AutoWin";      Name = "Cài Win & Bypass TPM 2.0";       Icon = "🚀"; Tier = "PRO";  Description = "Cài đặt Windows tự động, vượt rào TPM 2.0 / SecureBoot / RAM" },
        [PSCustomObject]@{ Id = "Partition";    Name = "Quản Lý Phân Vùng (Partition)";  Icon = "💽"; Tier = "PRO";  Description = "Sơ đồ đĩa live, TRIM SSD, chuyển MBR sang GPT không mất dữ liệu" }
    )
}

function Init-VUONGTTFeaturePolicies {
    if (-not (Test-Path $script:POLICY_FILE)) {
        $defaults = Get-VUONGTTDefaultFeatures
        $defaults | ConvertTo-Json -Depth 4 | Set-Content -Path $script:POLICY_FILE -Encoding UTF8
    }
}

function Get-VUONGTTFeaturePolicies {
    Init-VUONGTTFeaturePolicies
    try {
        $policies = Get-Content -Path $script:POLICY_FILE -Raw -Encoding UTF8 | ConvertFrom-Json
        return $policies
    } catch {
        return (Get-VUONGTTDefaultFeatures)
    }
}

function Set-VUONGTTFeaturePolicy {
    param(
        [string]$FeatureId,
        [string]$Tier # "FREE" or "PRO"
    )
    Init-VUONGTTFeaturePolicies
    try {
        $list = Get-VUONGTTFeaturePolicies
        foreach ($item in $list) {
            if ($item.Id -eq $FeatureId) {
                $item.Tier = $Tier.ToUpper()
            }
        }
        $list | ConvertTo-Json -Depth 4 | Set-Content -Path $script:POLICY_FILE -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}

function Reset-VUONGTTFeaturePoliciesToDefault {
    try {
        $defaults = Get-VUONGTTDefaultFeatures
        $defaults | ConvertTo-Json -Depth 4 | Set-Content -Path $script:POLICY_FILE -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}

# -------------------------------------------------------------------------
# 4. LICENSE KEY VAULT & HWID LOCK ENGINE (SINGLE-USE ON 1 PC)
# -------------------------------------------------------------------------
function Init-VUONGTTLicenseVault {
    if (-not (Test-Path $script:VAULT_FILE)) {
        @() | ConvertTo-Json | Set-Content -Path $script:VAULT_FILE -Encoding UTF8
    }
}

function New-VUONGTTLicenseKey {
    [CmdletBinding()]
    param(
        [string]$Customer = "Khách Hàng",
        [string]$Duration = "Lifetime", # "Lifetime", "1 Year", "30 Days"
        [int]$Count = 1
    )
    Init-VUONGTTLicenseVault
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" # Exclude confusing characters 0, O, 1, I
    $vault = @()
    try {
        $content = Get-Content -Path $script:VAULT_FILE -Raw -Encoding UTF8
        if ($content) { $vault = @($content | ConvertFrom-Json) }
    } catch {}

    $newKeys = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $part1 = ""
        $part2 = ""
        $part3 = ""
        $part4 = ""
        $bytes = New-Object byte[] 16
        $rng.GetBytes($bytes)
        for ($j = 0; $j -lt 4; $j++) { $part1 += $chars[$bytes[$j] % $chars.Length] }
        for ($j = 4; $j -lt 8; $j++) { $part2 += $chars[$bytes[$j] % $chars.Length] }
        for ($j = 8; $j -lt 12; $j++) { $part3 += $chars[$bytes[$j] % $chars.Length] }
        for ($j = 12; $j -lt 16; $j++) { $part4 += $chars[$bytes[$j] % $chars.Length] }

        $keyCode = "VUONG-" + $part1 + "-" + $part2 + "-" + $part3 + "-" + $part4
        $keyObj = [PSCustomObject]@{
            Key           = $keyCode
            Customer      = $Customer
            Duration      = $Duration
            CreatedDate   = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
            IsUsed        = $false
            UsedHWID      = ""
            UsedPCName    = ""
            ActivatedDate = ""
        }
        $vault += $keyObj
        $newKeys += $keyObj
    }

    $vault | ConvertTo-Json -Depth 4 | Set-Content -Path $script:VAULT_FILE -Encoding UTF8
    return $newKeys
}

function Get-VUONGTTAllLicenses {
    Init-VUONGTTLicenseVault
    try {
        $content = Get-Content -Path $script:VAULT_FILE -Raw -Encoding UTF8
        if ($content) {
            $list = @($content | ConvertFrom-Json)
            return $list
        }
    } catch {}
    return @()
}

function Remove-VUONGTTLicenseKey {
    param([string]$Key)
    Init-VUONGTTLicenseVault
    try {
        $vault = Get-VUONGTTAllLicenses
        $targetKey = $vault | Where-Object { $_.Key -eq $Key }
        $newVault = @($vault | Where-Object { $_.Key -ne $Key })
        if ($newVault.Count -eq 0) {
            "[]" | Set-Content -Path $script:VAULT_FILE -Encoding UTF8
        } else {
            $newVault | ConvertTo-Json -Depth 4 | Set-Content -Path $script:VAULT_FILE -Encoding UTF8
        }

        # NẾU KEY BỊ XÓA LÀ KEY ĐANG DÙNG TRÊN MÁY NÀY HOẶC TRÙNG HWID -> THU HỒI BẢN QUYỀN MÁY TỨC THÌ
        if (Test-Path $script:ACTIVE_LIC_FILE) {
            try {
                $base64 = Get-Content -Path $script:ACTIVE_LIC_FILE -Raw -ErrorAction SilentlyContinue
                if ($base64) {
                    $json = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64.Trim()))
                    $lic = ConvertFrom-Json $json
                    if ($lic.Key -eq $Key) {
                        Remove-Item -Path $script:ACTIVE_LIC_FILE -Force -ErrorAction SilentlyContinue
                    }
                }
            } catch {}
        }
        if ($targetKey -and $targetKey.UsedHWID -eq (Get-VUONGTTHardwareId)) {
            Remove-Item -Path $script:ACTIVE_LIC_FILE -Force -ErrorAction SilentlyContinue
        }

        return $true
    } catch {
        return $false
    }
}

# -------------------------------------------------------------------------
# 5. ACTIVATION & PRO LICENSE VERIFICATION (HARDWARE LOCKED)
# -------------------------------------------------------------------------
function Invoke-VUONGTTKeyActivation {
    param([string]$InputKey)
    $cleanKey = $InputKey.Trim().ToUpper()
    Init-VUONGTTLicenseVault
    $currentHWID = Get-VUONGTTHardwareId

    $vault = Get-VUONGTTAllLicenses
    $targetKey = $vault | Where-Object { $_.Key -eq $cleanKey }

    if (-not $targetKey) {
        return [PSCustomObject]@{
            Success = $false
            Message = "Mã License Key không tồn tại trên hệ thống! Vui lòng kiểm tra lại."
        }
    }

    # KIỂM TRA QUY TẮC KHÓA 1 MÁY DUY NHẤT (SINGLE-USE HARDWARE LOCK)
    if ($targetKey.IsUsed) {
        if ($targetKey.UsedHWID -eq $currentHWID) {
            # Máy này đã kích hoạt trước đó bằng key này -> Cho phép khôi phục
            Write-VUONGTTActiveLicenseFile -Key $targetKey.Key -Customer $targetKey.Customer -Duration $targetKey.Duration -HWID $currentHWID
            return [PSCustomObject]@{
                Success = $true
                Message = "Bản quyền PRO trên máy tính này đã được xác nhận và kích hoạt lại thành công!"
            }
        } else {
            # Key đã được dùng trên máy khác -> TỪ CHỐI
            return [PSCustomObject]@{
                Success = $false
                Message = "Key này đã được kích hoạt trên một máy tính khác (HWID không trùng khớp)! Mỗi key chỉ sử dụng được trên 1 máy tính duy nhất."
            }
        }
    }

    # Key hợp lệ và chưa sử dụng -> KÍCH HOẠT CHO MÁY NÀY
    $targetKey.IsUsed        = $true
    $targetKey.UsedHWID      = $currentHWID
    $targetKey.UsedPCName    = $env:COMPUTERNAME
    $targetKey.ActivatedDate = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")

    $vault | ConvertTo-Json -Depth 4 | Set-Content -Path $script:VAULT_FILE -Encoding UTF8

    Write-VUONGTTActiveLicenseFile -Key $targetKey.Key -Customer $targetKey.Customer -Duration $targetKey.Duration -HWID $currentHWID

    return [PSCustomObject]@{
        Success  = $true
        Message  = "CHÚC MỪNG! ĐÃ KÍCH HOẠT THÀNH CÔNG BẢN QUYỀN PRO CHO MÁY TÍNH NÀY!"
        Duration = $targetKey.Duration
        Customer = $targetKey.Customer
    }
}

function Write-VUONGTTActiveLicenseFile {
    param(
        [string]$Key,
        [string]$Customer,
        [string]$Duration,
        [string]$HWID
    )
    $sigSeed = "VUONGTT_PRO_2026:" + $Key + ":" + $HWID + ":" + $Duration
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $sigBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sigSeed))
    $signature = ($sigBytes | ForEach-Object { $_.ToString("X2") }) -join ""

    $licData = [PSCustomObject]@{
        Key           = $Key
        Customer      = $Customer
        Duration      = $Duration
        HWID          = $HWID
        PCName        = $env:COMPUTERNAME
        ActivatedDate = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
        Signature     = $signature
    }

    $json = $licData | ConvertTo-Json -Depth 4
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $base64 = [System.Convert]::ToBase64String($bytes)
    Set-Content -Path $script:ACTIVE_LIC_FILE -Value $base64 -Encoding ASCII
}

function Test-VUONGTTProLicense {
    [CmdletBinding()]
    param()
    if (-not (Test-Path $script:ACTIVE_LIC_FILE)) {
        return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Chưa kích hoạt bản quyền" }
    }

    try {
        $base64 = Get-Content -Path $script:ACTIVE_LIC_FILE -Raw -ErrorAction Stop
        $bytes = [System.Convert]::FromBase64String($base64.Trim())
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        $lic = ConvertFrom-Json $json

        $currentHWID = Get-VUONGTTHardwareId
        if ($lic.HWID -ne $currentHWID) {
            return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "HWID không khớp (File bản quyền sao chép từ máy khác)" }
        }

        # ĐỐI SOÁT VỚI KHO VAULT: NẾU KEY ĐÃ BỊ ADMIN XÓA KHỎI KHO -> TỰ ĐỘNG THU HỒI BẢN QUYỀN MÁY
        $vault = Get-VUONGTTAllLicenses
        $vaultKey = $vault | Where-Object { $_.Key -eq $lic.Key }
        if (-not $vaultKey) {
            # Key đã bị Admin xóa khỏi Vault -> Xóa sạch active license trên máy và trả về Free
            Remove-Item -Path $script:ACTIVE_LIC_FILE -Force -ErrorAction SilentlyContinue
            return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "License Key đã bị xóa khỏi hệ thống (Bản quyền bị thu hồi)" }
        }

        # Check cryptographic signature
        $sigSeed = "VUONGTT_PRO_2026:" + $lic.Key + ":" + $lic.HWID + ":" + $lic.Duration
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $expectedSig = ($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sigSeed)) | ForEach-Object { $_.ToString("X2") }) -join ""

        if ($lic.Signature -ne $expectedSig) {
            return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Chữ ký số bản quyền không hợp lệ" }
        }

        return [PSCustomObject]@{
            IsPro    = $true
            License  = $lic
            Duration = $lic.Duration
            Customer = $lic.Customer
            Reason   = "Bản quyền PRO hợp lệ"
        }
    } catch {
        return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Lỗi đọc file bản quyền" }
    }
}
