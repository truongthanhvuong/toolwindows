# =========================================================================
#   VUONGTT TOOLKIT 2026 - LICENSE & ADMIN MANAGEMENT ENGINE
#   Chức năng: Quản lý bản quyền Free/PRO, Mã hóa HWID khóa 1 máy tính,
#              Quản lý phân quyền tính năng, Tạo/Xóa License Key, Đăng nhập Admin
# =========================================================================

function Get-VUONGTTDataDir {
    # 1. Thư mục vĩnh viễn %ProgramData%\VUONGTT_Toolkit (Bảo toàn khi dọn dẹp Temp và sau mọi lần cập nhật EXE)
    $progData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonApplicationData)
    if (-not $progData) { $progData = "C:\ProgramData" }
    $primary = Join-Path $progData "VUONGTT_Toolkit"
    if (-not (Test-Path $primary)) {
        New-Item -Path $primary -ItemType Directory -Force | Out-Null
    }

    # 2. Đồng bộ dữ liệu cũ từ ..\Config nếu có
    $localConfig = Join-Path $PSScriptRoot "..\Config"
    if (Test-Path $localConfig) {
        foreach ($fn in @("licenses_vault.json", "active_license.lic", "admin_auth.json", "feature_policy.json")) {
            $src = Join-Path $localConfig $fn
            $dst = Join-Path $primary $fn
            if ((Test-Path $src) -and -not (Test-Path $dst)) {
                Copy-Item -Path $src -Destination $dst -Force -ErrorAction SilentlyContinue
            }
        }
    }
    return $primary
}

$script:CONFIG_DIR      = Get-VUONGTTDataDir
$script:AUTH_FILE       = Join-Path $script:CONFIG_DIR "admin_auth.json"
$script:POLICY_FILE     = Join-Path $script:CONFIG_DIR "feature_policy.json"
$script:VAULT_FILE      = Join-Path $script:CONFIG_DIR "licenses_vault.json"
$script:ACTIVE_LIC_FILE = Join-Path $script:CONFIG_DIR "active_license.lic"

# ĐỒNG BỘ HAI CHIỀU: Đảm bảo ..\Config cũng có bản sao nếu tồn tại
try {
    $localCfg = Join-Path $PSScriptRoot "..\Config"
    if (-not (Test-Path $localCfg)) { New-Item -Path $localCfg -ItemType Directory -Force | Out-Null }
} catch {}

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
# 4. UNIVERSAL CRYPTOGRAPHIC KEY ENGINE & HWID LOCK
# -------------------------------------------------------------------------
# BẢO MẬT MẬT MÃ TOÀN CẦU (CROSS-MACHINE): HMAC-SHA256 Secret Engine
$script:LICENSE_MASTER_SECRET = "VUONGTT_SECRET_HMAC_MASTER_KEY_2026_PRO_EDITION"
$script:LICENSE_CHARSET       = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" # 32 ký tự, loại bỏ O, 0, I, 1

# Danh sách Key Master phê duyệt trước (chứa mã key đã tạo của khách hàng trong ảnh)
$script:PREAPPROVED_MASTER_KEYS = @(
    @{ Key = "VUONG-4P34-HE36-5B74-FHCV"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-PRO2026-VIP888-MASTER"; Duration = "Lifetime"; Customer = "VIP Master" },
    @{ Key = "VUONG-L999-PRO8-LIFETIME-VIP"; Duration = "Lifetime"; Customer = "VIP Khách Hàng" }
)

function Get-VUONGTTKeySignature {
    param([string]$Payload)
    $hmac = [System.Security.Cryptography.HMACSHA256]::new([System.Text.Encoding]::UTF8.GetBytes($script:LICENSE_MASTER_SECRET))
    $hashBytes = $hmac.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Payload))
    $sig = ""
    for ($i = 0; $i -lt 8; $i++) {
        $sig += $script:LICENSE_CHARSET[$hashBytes[$i] % $script:LICENSE_CHARSET.Length]
    }
    return $sig
}

function Test-VUONGTTCryptographicKey {
    param([string]$Key)
    $clean = $Key.Trim().ToUpper()

    # 1. Đối soát danh sách Pre-Approved Master Keys
    foreach ($item in $script:PREAPPROVED_MASTER_KEYS) {
        if ($item.Key -eq $clean) {
            return [PSCustomObject]@{
                IsValid  = $true
                Duration = $item.Duration
                Customer = $item.Customer
            }
        }
    }

    # 2. Kiểm tra cấu trúc chuẩn VUONG-XXXX-XXXX-XXXX-XXXX
    if ($clean -notmatch '^VUONG-([A-Z2-9]{4})-([A-Z2-9]{4})-([A-Z2-9]{4})-([A-Z2-9]{4})$') {
        return [PSCustomObject]@{ IsValid = $false; Duration = ""; Customer = "" }
    }

    $p1 = $matches[1]
    $p2 = $matches[2]
    $p3 = $matches[3]
    $p4 = $matches[4]

    $payload = $p1 + $p2
    $receivedSig = $p3 + $p4

    $expectedSig = Get-VUONGTTKeySignature -Payload ("VUONGTT_KEY_PAYLOAD:" + $payload)
    if ($receivedSig -eq $expectedSig) {
        $durCode = $payload.Substring(0, 1)
        $dur = switch ($durCode) {
            "L" { "Lifetime" }
            "Y" { "1 Year" }
            "M" { "30 Days" }
            default { "Lifetime" }
        }
        return [PSCustomObject]@{
            IsValid  = $true
            Duration = $dur
            Customer = "Khách Hàng PRO"
        }
    }

    return [PSCustomObject]@{ IsValid = $false; Duration = ""; Customer = "" }
}

function Init-VUONGTTLicenseVault {
    if (-not (Test-Path $script:VAULT_FILE)) {
        # Tự động nạp sẵn các key pre-approved để Admin luôn nhìn thấy trong kho
        $initList = @()
        foreach ($k in $script:PREAPPROVED_MASTER_KEYS) {
            $initList += [PSCustomObject]@{
                Key           = $k.Key
                Customer      = $k.Customer
                Duration      = $k.Duration
                CreatedDate   = "19/09/2026 08:56:12"
                IsUsed        = $false
                UsedHWID      = ""
                UsedPCName    = ""
                ActivatedDate = ""
            }
        }
        $initList | ConvertTo-Json -Depth 4 | Set-Content -Path $script:VAULT_FILE -Encoding UTF8
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
    $vault = @()
    try {
        $content = Get-Content -Path $script:VAULT_FILE -Raw -Encoding UTF8
        if ($content) { $vault = @($content | ConvertFrom-Json) }
    } catch {}

    $durCode = switch ($Duration) {
        "1 Year"  { "Y" }
        "30 Days" { "M" }
        default   { "L" }
    }

    $newKeys = @()
    for ($i = 0; $i -lt $Count; $i++) {
        # Tạo 7 ký tự ngẫu nhiên sau mã thời hạn
        $randBytes = New-Object byte[] 7
        $rng.GetBytes($randBytes)
        $rand7 = ""
        for ($j = 0; $j -lt 7; $j++) {
            $rand7 += $script:LICENSE_CHARSET[$randBytes[$j] % $script:LICENSE_CHARSET.Length]
        }

        $payload = "$durCode$rand7" # Đúng 8 ký tự (Block 1 & Block 2)
        $sig = Get-VUONGTTKeySignature -Payload ("VUONGTT_KEY_PAYLOAD:" + $payload) # Đúng 8 ký tự (Block 3 & Block 4)

        $part1 = $payload.Substring(0, 4)
        $part2 = $payload.Substring(4, 4)
        $part3 = $sig.Substring(0, 4)
        $part4 = $sig.Substring(4, 4)

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

    # Đồng bộ sang local config nếu tồn tại
    try {
        $localVault = Join-Path $PSScriptRoot "..\Config\licenses_vault.json"
        if (Test-Path (Split-Path $localVault -Parent)) {
            $vault | ConvertTo-Json -Depth 4 | Set-Content -Path $localVault -Encoding UTF8
        }
    } catch {}

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
# 5. ACTIVATION & PRO LICENSE VERIFICATION (CROSS-MACHINE & HWID LOCKED)
# -------------------------------------------------------------------------
function Invoke-VUONGTTKeyActivation {
    param([string]$InputKey)
    $cleanKey = $InputKey.Trim().ToUpper()
    Init-VUONGTTLicenseVault
    $currentHWID = Get-VUONGTTHardwareId

    # 1. Tìm kiếm trong Vault cục bộ trước
    $vault = Get-VUONGTTAllLicenses
    $targetKey = $vault | Where-Object { $_.Key -eq $cleanKey }

    # 2. Nếu không có trong Vault cục bộ -> Thẩm định chữ ký số Universal Cryptographic (Cross-Machine)
    if (-not $targetKey) {
        $cryptoCheck = Test-VUONGTTCryptographicKey -Key $cleanKey
        if ($cryptoCheck.IsValid) {
            # Tự động tiếp nhận key chính thống vào Vault của máy này
            $targetKey = [PSCustomObject]@{
                Key           = $cleanKey
                Customer      = $cryptoCheck.Customer
                Duration      = $cryptoCheck.Duration
                CreatedDate   = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
                IsUsed        = $false
                UsedHWID      = ""
                UsedPCName    = ""
                ActivatedDate = ""
            }
            $vault += $targetKey
            $vault | ConvertTo-Json -Depth 4 | Set-Content -Path $script:VAULT_FILE -Encoding UTF8
        }
    }

    if (-not $targetKey) {
        return [PSCustomObject]@{
            Success = $false
            Message = "Mã License Key không tồn tại trên hệ thống! Vui lòng kiểm tra lại."
        }
    }

    # 3. KIỂM TRA QUY TẮC KHÓA 1 MÁY DUY NHẤT (SINGLE-USE HARDWARE LOCK)
    if ($targetKey.IsUsed) {
        if ($targetKey.UsedHWID -eq $currentHWID) {
            # Máy này đã kích hoạt trước đó bằng key này -> Cho phép khôi phục
            Write-VUONGTTActiveLicenseFile -Key $targetKey.Key -Customer $targetKey.Customer -Duration $targetKey.Duration -HWID $currentHWID
            return [PSCustomObject]@{
                Success  = $true
                Message  = "Bản quyền PRO trên máy tính này đã được xác nhận và kích hoạt lại thành công!"
                Duration = $targetKey.Duration
                Customer = $targetKey.Customer
            }
        } else {
            # Key đã được dùng trên máy khác -> TỪ CHỐI
            return [PSCustomObject]@{
                Success = $false
                Message = "Key này đã được kích hoạt trên một máy tính khác (HWID: $($targetKey.UsedHWID))! Mỗi key chỉ sử dụng được trên 1 máy tính duy nhất."
            }
        }
    }

    # 4. Key hợp lệ và chưa sử dụng -> KÍCH HOẠT CHO MÁY NÀY VÀ KHÓA CHẶT VỚI HWID
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

    # Sao lưu thêm 1 bản dự phòng vào thư mục local ..\Config nếu có
    try {
        $localLic = Join-Path $PSScriptRoot "..\Config\active_license.lic"
        Set-Content -Path $localLic -Value $base64 -Encoding ASCII -ErrorAction SilentlyContinue
    } catch {}
}

function Test-VUONGTTProLicense {
    [CmdletBinding()]
    param()
    if (-not (Test-Path $script:ACTIVE_LIC_FILE)) {
        # Fallback thử kiểm tra thư mục local
        $localLic = Join-Path $PSScriptRoot "..\Config\active_license.lic"
        if (Test-Path $localLic) {
            Copy-Item -Path $localLic -Destination $script:ACTIVE_LIC_FILE -Force -ErrorAction SilentlyContinue
        } else {
            return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Chưa kích hoạt bản quyền" }
        }
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

        # Check cryptographic signature
        $sigSeed = "VUONGTT_PRO_2026:" + $lic.Key + ":" + $lic.HWID + ":" + $lic.Duration
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $expectedSig = ($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sigSeed)) | ForEach-Object { $_.ToString("X2") }) -join ""

        if ($lic.Signature -ne $expectedSig) {
            return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Chữ ký số bản quyền không hợp lệ" }
        }

        # ĐỐI SOÁT VỚI KHO VAULT: NẾU THIẾU TRONG VAULT -> TỰ ĐỘNG PHỤC HỒI LẠI VÀO VAULT
        $vault = Get-VUONGTTAllLicenses
        $vaultKey = $vault | Where-Object { $_.Key -eq $lic.Key }
        if (-not $vaultKey) {
            $newEntry = [PSCustomObject]@{
                Key           = $lic.Key
                Customer      = $lic.Customer
                Duration      = $lic.Duration
                CreatedDate   = $lic.ActivatedDate
                IsUsed        = $true
                UsedHWID      = $lic.HWID
                UsedPCName    = $lic.PCName
                ActivatedDate = $lic.ActivatedDate
            }
            $vault += $newEntry
            $vault | ConvertTo-Json -Depth 4 | Set-Content -Path $script:VAULT_FILE -Encoding UTF8
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
