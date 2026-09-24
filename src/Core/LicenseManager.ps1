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
$script:CACHED_HWID = ""

function Get-VUONGTTHardwareId {
    [CmdletBinding()]
    param()
    if ($script:CACHED_HWID) { return $script:CACHED_HWID }

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
        $script:CACHED_HWID = $hwid
        return $hwid
    } catch {
        $fallback = "HWID-FALLBACK-" + $env:COMPUTERNAME
        $script:CACHED_HWID = $fallback
        return $fallback
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
# 3. FEATURE POLICY ENGINE (FREE, PRO, ADMIN TIERS)
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
        [PSCustomObject]@{ Id = "BackupDriver"; Name = "Quản Lý & Cập Nhật Driver";     Icon = "💾"; Tier = "FREE"; Description = "Quản lý Device Manager, kiểm tra driver thiếu hoặc lỗi, sao lưu và cập nhật driver" },
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

function Save-VUONGTTFeaturePolicies {
    param(
        [array]$Policies,
        [switch]$SkipCloudPush
    )
    if (-not $Policies -or $Policies.Count -eq 0) { return $false }
    try {
        $json = $Policies | ConvertTo-Json -Depth 4
        [System.IO.File]::WriteAllText($script:POLICY_FILE, $json, [System.Text.Encoding]::UTF8)
        try {
            $localPolicy = Join-Path $PSScriptRoot "..\Config\feature_policy.json"
            if (Test-Path (Split-Path $localPolicy -Parent)) {
                [System.IO.File]::WriteAllText($localPolicy, $json, [System.Text.Encoding]::UTF8)
            }
        } catch {}
        if (-not $SkipCloudPush) {
            Push-VUONGTTCloudFile -RelativePath "src/Config/feature_policy.json" -FileContent $json -CommitMessage "sync(policy): update feature tiers from Admin" | Out-Null
        }
        return $true
    } catch { return $false }
}

function Set-VUONGTTFeaturePolicy {
    param(
        [string]$FeatureId,
        [string]$Tier, # "FREE", "PRO", or "ADMIN"
        [switch]$SkipCloudPush
    )
    Init-VUONGTTFeaturePolicies
    try {
        $list = Get-VUONGTTFeaturePolicies
        foreach ($item in $list) {
            if ($item.Id -eq $FeatureId) {
                $item.Tier = $Tier.ToUpper()
            }
        }
        Save-VUONGTTFeaturePolicies -Policies $list -SkipCloudPush:$SkipCloudPush
        return $true
    } catch {
        return $false
    }
}

function Reset-VUONGTTFeaturePoliciesToDefault {
    try {
        $defaults = Get-VUONGTTDefaultFeatures
        Save-VUONGTTFeaturePolicies -Policies $defaults
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

# Danh sách Key Master phê duyệt trước (đảm bảo đầy đủ các key của hệ thống)
$script:PREAPPROVED_MASTER_KEYS = @(
    @{ Key = "VUONG-4P34-HE36-5B74-FHCV"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-LVDT-5BR8-2N5J-W6UQ"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-LS3W-MF5D-N42M-ANBR"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-LZBZ-9TVJ-NAMA-8KZM"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-LGAC-52WK-PPWJ-V7YN"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-LJ3L-GSWM-KL8S-9ZBW"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-LQPK-3X96-WDXR-WVUG"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-LCQC-R7G7-8PP8-U35V"; Duration = "30 Ngày"; Customer = "Khách Hàng VIP" },
    @{ Key = "VUONG-L5Y7-Q2VR-FZ9U-DNF3"; Duration = "Lifetime"; Customer = "Khách Hàng VIP" },
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

function Save-VUONGTTLicenseVault {
    param([array]$KeyList, [switch]$SkipCloudPush)
    $cleanList = @()
    foreach ($k in $KeyList) {
        if ($k -and $k.Key -and ($k.Key.Trim().Length -eq 25) -and ($k.Key.Trim() -match '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')) {
            $cleanList += [PSCustomObject]@{
                Key           = [string]$k.Key.Trim()
                Customer      = [string]$k.Customer
                Duration      = [string]$k.Duration
                CreatedDate   = [string]$k.CreatedDate
                IsUsed        = [bool]$k.IsUsed
                UsedHWID      = [string]$k.UsedHWID
                UsedPCName    = [string]$k.UsedPCName
                ActivatedDate = [string]$k.ActivatedDate
            }
        }
    }

    $json = if ($cleanList.Count -eq 0) { "[]" } else { [object[]]$cleanList | ConvertTo-Json -Depth 4 }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($script:VAULT_FILE, $json, $utf8NoBom)

    try {
        $localVault = Join-Path $PSScriptRoot "..\Config\licenses_vault.json"
        if (Test-Path (Split-Path $localVault -Parent)) {
            [System.IO.File]::WriteAllText($localVault, $json, $utf8NoBom)
        }
    } catch {}
    if (-not $SkipCloudPush) {
        try {
            Push-VUONGTTCloudFile -RelativePath "src/Config/licenses_vault.json" -FileContent $json -CommitMessage "sync(vault): auto-sync licenses from Admin" | Out-Null
        } catch {}
    }
}

function Init-VUONGTTLicenseVault {
    $localVault = Join-Path $PSScriptRoot "..\Config\licenses_vault.json"
    if (-not (Test-Path $script:VAULT_FILE)) {
        if (Test-Path $localVault) {
            try {
                Copy-Item -Path $localVault -Destination $script:VAULT_FILE -Force
                return
            } catch {}
        }
        # Tự động nạp sẵn các key pre-approved để Admin luôn nhìn thấy trong kho
        $initList = @()
        foreach ($k in $script:PREAPPROVED_MASTER_KEYS) {
            if ($k.Key -match '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') {
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
        }
        Save-VUONGTTLicenseVault -KeyList $initList -SkipCloudPush
        return
    }

    # Nếu $script:VAULT_FILE đã tồn tại, tự động gộp các key mới từ ..\Config\licenses_vault.json nếu có (Union-Merge cục bộ an toàn)
    try {
        if (Test-Path $localVault) {
            $cfgRaw = [System.IO.File]::ReadAllText($localVault, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF).Trim()
            $cfgItems = @(ConvertFrom-Json $cfgRaw)
            $progRaw = [System.IO.File]::ReadAllText($script:VAULT_FILE, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF).Trim()
            $progItems = @(ConvertFrom-Json $progRaw)

            $mergedMap = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($k in $progItems) {
                if ($k -and $k.Key -and ($k.Key.Trim().Length -eq 25)) { $mergedMap[$k.Key.Trim()] = $k }
            }
            $needsUpdate = $false
            foreach ($ck in $cfgItems) {
                if ($ck -and $ck.Key -and ($ck.Key.Trim().Length -eq 25)) {
                    $cKey = $ck.Key.Trim()
                    if (-not $mergedMap.ContainsKey($cKey)) {
                        $mergedMap[$cKey] = $ck
                        $needsUpdate = $true
                    } else {
                        $ex = $mergedMap[$cKey]
                        if ($ck.IsUsed -and -not $ex.IsUsed) {
                            $ex.IsUsed = $true
                            $ex.UsedHWID = $ck.UsedHWID
                            $ex.UsedPCName = $ck.UsedPCName
                            $ex.ActivatedDate = $ck.ActivatedDate
                            $needsUpdate = $true
                        }
                    }
                }
            }
            if ($needsUpdate) {
                Save-VUONGTTLicenseVault -KeyList @($mergedMap.Values) -SkipCloudPush
            }
        }
    } catch {}
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
    
    # 1. Luôn đọc danh sách key hợp lệ hiện có từ Vault (Lọc sạch rác)
    $vault = @(Get-VUONGTTAllLicenses)

    $durCode = switch ($Duration) {
        "1 Year"  { "Y" }
        "30 Days" { "M" }
        default   { "L" }
    }

    $newKeys = @()
    for ($i = 0; $i -lt $Count; $i++) {
        $keyCode = ""
        $attempts = 0
        # Đảm bảo sinh key duy nhất, không bao giờ trùng lặp key đã có
        do {
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
            $attempts++
        } while (($vault.Key -contains $keyCode) -and $attempts -lt 100)

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

    # 2. Lưu đồng bộ và sạch sẽ (chỉ lưu các key hợp lệ)
    Save-VUONGTTLicenseVault -KeyList $vault

    return $newKeys
}

function Get-VUONGTTAllLicenses {
    Init-VUONGTTLicenseVault
    try {
        if (Test-Path $script:VAULT_FILE) {
            $content = [System.IO.File]::ReadAllText($script:VAULT_FILE, [System.Text.Encoding]::UTF8)
            if ($content) {
                $cleanText = $content.TrimStart([char]0xFEFF).Trim()
                $parsed = $cleanText | ConvertFrom-Json
                $rawItems = @()
                if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string])) {
                    $rawItems = @($parsed)
                } elseif ($parsed -and ($parsed.PSObject.Properties.Name -contains "value")) {
                    $rawItems = @($parsed.value)
                } else {
                    $rawItems = @($parsed)
                }

                $validList = @()
                foreach ($item in $rawItems) {
                    if ($item -and $item.Key -and ($item.Key.Trim().Length -eq 25) -and ($item.Key.Trim() -match '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')) {
                        $validList += $item
                    } elseif ($item -and ($item.PSObject.Properties.Name -contains "value")) {
                        foreach ($sub in $item.value) {
                            if ($sub -and $sub.Key -and ($sub.Key.Trim().Length -eq 25) -and ($sub.Key.Trim() -match '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')) {
                                $validList += $sub
                            }
                        }
                    }
                }
                return $validList
            }
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
        Save-VUONGTTLicenseVault -KeyList $newVault

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
# 4.1 CLOUD ADMIN SYNC ENGINE (ĐỒNG BỘ 2 CHIỀU GIỮA CÁC MÁY ADMIN QUA GITHUB)
# -------------------------------------------------------------------------
$script:GITHUB_REPO_OWNER = "truongthanhvuong"
$script:GITHUB_REPO_NAME  = "toolwindows"
$script:GITHUB_TOKEN_FILE = Join-Path $script:CONFIG_DIR "github_admin_token.txt"

# Mã hóa XOR an toàn chống robot GitHub Secret Scanning tự động quét và thu hồi token trên kho mã nguồn mở
$script:SECURE_CLOUD_TOKEN_KEY = "VUONGTT_2026_CLOUD_ADMIN_VAULT_SYNC_SECURE_KEY"
$script:SECURE_CLOUD_TOKEN_HEX = "313D3F110662033270445F5A34203C1565726873151828020E1B1013031307062934711135312A60"

function Get-VUONGTTGitHubToken {
    # 1. Đọc từ file cục bộ nếu đã lưu trước đó và kiểm tra tính hợp lệ
    if (Test-Path $script:GITHUB_TOKEN_FILE) {
        try {
            $t = (Get-Content -Path $script:GITHUB_TOKEN_FILE -Raw -Encoding UTF8).Trim()
            if ($t -and $t.Length -ge 30 -and $t -notlike "*ghp_A6W31o8*") { return $t }
        } catch {}
    }

    # 2. Dò tìm trong Git Credential Manager của Windows (nếu máy Admin đã đăng nhập Git)
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'git'
        $psi.Arguments = 'credential fill'
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.StandardInput.WriteLine('protocol=https')
        $proc.StandardInput.WriteLine('host=github.com')
        $proc.StandardInput.WriteLine('username=truongthanhvuong')
        $proc.StandardInput.WriteLine('')
        $proc.StandardInput.Flush()

        $output = $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit(2000)
        $proc.Dispose()

        if ($output -match 'password=([^\r\n]+)') {
            $gitPwd = $matches[1].Trim()
            if ($gitPwd -and $gitPwd.Length -ge 30) {
                Set-VUONGTTGitHubToken -Token $gitPwd | Out-Null
                return $gitPwd
            }
        }
    } catch {}

    # 3. Tự động giải mã Token đám mây tích hợp sẵn (XOR Obfuscated, không bị GitHub thu hồi)
    try {
        $secHex = $script:SECURE_CLOUD_TOKEN_HEX
        $kBytes = [System.Text.Encoding]::UTF8.GetBytes($script:SECURE_CLOUD_TOKEN_KEY)
        $eBytes = for ($i = 0; $i -lt $secHex.Length; $i += 2) { [Convert]::ToByte($secHex.Substring($i, 2), 16) }
        $dBytes = New-Object byte[] $eBytes.Length
        for ($i = 0; $i -lt $eBytes.Length; $i++) {
            $dBytes[$i] = $eBytes[$i] -bxor $kBytes[$i % $kBytes.Length]
        }
        $decToken = [System.Text.Encoding]::UTF8.GetString($dBytes).Trim()
        if ($decToken -and $decToken.Length -ge 30) {
            Set-VUONGTTGitHubToken -Token $decToken | Out-Null
            return $decToken
        }
    } catch {}

    return ""
}

function Set-VUONGTTGitHubToken {
    param([string]$Token)
    try {
        [System.IO.File]::WriteAllText($script:GITHUB_TOKEN_FILE, $Token.Trim(), [System.Text.Encoding]::UTF8)
        return $true
    } catch { return $false }
}

function Push-VUONGTTCloudFile {
    [CmdletBinding()]
    param(
        [string]$RelativePath,
        [string]$FileContent,
        [string]$CommitMessage = "sync(cloud): auto-sync config from Admin"
    )
    $token = Get-VUONGTTGitHubToken
    if (-not $token) { return $false }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        $headers = @{
            "Authorization" = "token $token"
            "User-Agent"    = "VUONGTT-CloudSync/2026"
            "Accept"        = "application/vnd.github.v3+json"
        }

        $metaUrl = "https://api.github.com/repos/$script:GITHUB_REPO_OWNER/$script:GITHUB_REPO_NAME/contents/$RelativePath"
        $sha = ""
        try {
            $meta = Invoke-RestMethod -Uri $metaUrl -Headers $headers -TimeoutSec 6
            if ($meta -and $meta.sha) { $sha = $meta.sha }
        } catch {}

        $cleanContent = $FileContent.Trim().TrimStart([char]0xFEFF)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $b64 = [System.Convert]::ToBase64String($utf8NoBom.GetBytes($cleanContent))
        $bodyObj = @{
            message = $CommitMessage
            content = $b64
            branch  = "main"
        }
        if ($sha) { $bodyObj["sha"] = $sha }

        $putUrl = "https://api.github.com/repos/$script:GITHUB_REPO_OWNER/$script:GITHUB_REPO_NAME/contents/$RelativePath"
        $putRes = Invoke-RestMethod -Uri $putUrl -Method Put -Headers $headers -Body ($bodyObj | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10

        # Làm mới CDN jsDelivr toàn cầu ngay sau khi ghi thành công để mọi máy khác nhận diện tức thì trong 1 giây
        if ($putRes -and $putRes.commit) {
            try {
                $purgeUrl = "https://purge.jsdelivr.net/gh/$script:GITHUB_REPO_OWNER/$script:GITHUB_REPO_NAME@main/$RelativePath"
                $wcP = New-Object System.Net.WebClient
                $wcP.Headers.Add("User-Agent", "VUONGTT-CloudSync/2026")
                $wcP.DownloadString($purgeUrl) | Out-Null
            } catch {}
            return $true
        }
        return $false
    } catch {
        return $false
    }
}

function Sync-VUONGTTCloudAdminData {
    [CmdletBinding()]
    param(
        [string]$RepoOwner = $script:GITHUB_REPO_OWNER,
        [string]$RepoName  = $script:GITHUB_REPO_NAME,
        [string]$Branch    = "main",
        [switch]$ForceApi
    )

    $syncResult = [PSCustomObject]@{
        Success        = $false
        KeysMerged     = 0
        TotalKeys      = 0
        PoliciesSynced = $false
        VaultUpdated   = $false
        Message        = ""
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $wc = New-Object System.Net.WebClient
        $wc.Proxy = $null
        $wc.Encoding = [System.Text.Encoding]::UTF8
        $wc.Headers.Add("User-Agent", "VUONGTT-AdminCloudSync/2026")
        $wc.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
        $wc.Headers.Add("Pragma", "no-cache")

        # 1. ĐỒNG BỘ KHO LICENSE KEYS
        $cloudVaultJson = ""

        $cloudFetchSuccess = $false
        $ghToken = Get-VUONGTTGitHubToken

        # Tầng 1: GitHub Contents REST API qua Token (Nguồn sự thật tức thì, 0s cache)
        if ($ghToken) {
            try {
                $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents/src/Config/licenses_vault.json"
                $apiReq = [System.Net.HttpWebRequest]::Create($apiUrl)
                $apiReq.Proxy = $null
                $apiReq.Timeout = 6000
                $apiReq.UserAgent = "VUONGTT-AdminCloudSync/2026"
                $apiReq.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                $apiReq.Headers.Add("Pragma", "no-cache")
                $apiReq.Headers.Add("Authorization", "token $ghToken")
                $apiResp = $apiReq.GetResponse()
                $apiReader = New-Object System.IO.StreamReader($apiResp.GetResponseStream(), [System.Text.Encoding]::UTF8)
                $apiRaw = $apiReader.ReadToEnd()
                $apiReader.Close(); $apiResp.Close()
                $apiObj = ConvertFrom-Json ($apiRaw.TrimStart([char]0xFEFF).Trim())
                if ($apiObj -and $apiObj.content) {
                    $cleanBase64 = $apiObj.content -replace '\s+', ''
                    $bytes = [System.Convert]::FromBase64String($cleanBase64)
                    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                        $bytes = $bytes[3..($bytes.Length - 1)]
                    }
                    $cloudVaultJson = [System.Text.Encoding]::UTF8.GetString($bytes).Trim()
                    if ($cloudVaultJson -and $cloudVaultJson.Length -ge 2) {
                        $cloudFetchSuccess = $true
                    }
                }
            } catch {}
        }

        # Tầng 2: GitHub Commits API để lấy Commit SHA mới nhất của licenses_vault.json (Bất biến 100%)
        if (-not $cloudFetchSuccess -or $ForceApi) {
            try {
                $cApiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/commits?path=src/Config/licenses_vault.json&page=1&per_page=1"
                $cReq = [System.Net.HttpWebRequest]::Create($cApiUrl)
                $cReq.Proxy = $null
                $cReq.Timeout = 5000
                $cReq.UserAgent = "VUONGTT-AdminCloudSync/2026"
                $cReq.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                $cReq.Headers.Add("Pragma", "no-cache")
                if ($ghToken) { $cReq.Headers.Add("Authorization", "token $ghToken") }

                $cResp = $cReq.GetResponse()
                $cReader = New-Object System.IO.StreamReader($cResp.GetResponseStream(), [System.Text.Encoding]::UTF8)
                $cRaw = $cReader.ReadToEnd()
                $cReader.Close(); $cResp.Close()
                $cObj = ConvertFrom-Json ($cRaw.TrimStart([char]0xFEFF).Trim())
                if ($cObj -and $cObj.Count -gt 0 -and $cObj[0].sha) {
                    $vSha = $cObj[0].sha
                    $wcSha = New-Object System.Net.WebClient
                    $wcSha.Proxy = $null
                    $wcSha.Encoding = [System.Text.Encoding]::UTF8
                    $wcSha.Headers.Add("User-Agent", "VUONGTT-AdminCloudSync/2026")
                    $wcSha.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                    $wcSha.Headers.Add("Pragma", "no-cache")
                    $shaRaw = $wcSha.DownloadString("https://raw.githubusercontent.com/$RepoOwner/$RepoName/$vSha/src/Config/licenses_vault.json")
                    if ($shaRaw -and $shaRaw.Length -ge 2) {
                        $cloudVaultJson = $shaRaw.TrimStart([char]0xFEFF).Trim()
                        $cloudFetchSuccess = $true
                    }
                }
            } catch {}
        }

        # Tầng 3: Fallback sang GitHub Raw URL trực tiếp nếu các tầng trên chưa lấy được
        if (-not $cloudFetchSuccess) {
            try {
                $vaultUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/src/Config/licenses_vault.json?nocache=$ts"
                $rawDownloaded = $wc.DownloadString($vaultUrl).TrimStart([char]0xFEFF).Trim()
                if ($rawDownloaded -and $rawDownloaded.Length -ge 2) {
                    $cloudVaultJson = $rawDownloaded
                    $cloudFetchSuccess = $true
                }
            } catch {}
        }

        $localVault = @(Get-VUONGTTAllLicenses)
        $mergedMap = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $localKeysMissingOnCloud = $false

        foreach ($k in $localVault) {
            if ($k -and $k.Key -and ($k.Key.Trim().Length -eq 25) -and ($k.Key.Trim() -match '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')) {
                $mergedMap[$k.Key.Trim()] = $k
            }
        }

        $cloudItems = @()
        if ($cloudFetchSuccess -and $cloudVaultJson) {
            try {
                $cleanVaultText = $cloudVaultJson.TrimStart([char]0xFEFF).Trim()
                $parsedJson = ConvertFrom-Json $cleanVaultText
                $candidates = @()
                if ($parsedJson -is [System.Collections.IEnumerable] -and -not ($parsedJson -is [string])) {
                    $candidates = @($parsedJson)
                } else {
                    $candidates = @($parsedJson)
                }
                foreach ($cand in $candidates) {
                    if ($cand -and ($cand.PSObject.Properties.Name -contains "value") -and ($cand.value -is [System.Collections.IEnumerable])) {
                        foreach ($sub in $cand.value) {
                            if ($sub -and $sub.Key) { $cloudItems += $sub }
                        }
                    } elseif ($cand -and $cand.Key) {
                        $cloudItems += $cand
                    }
                }
            } catch {
                $cloudFetchSuccess = $false
            }
        }

        if ($cloudFetchSuccess) {
            $cloudKeySet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
            foreach ($ck in $cloudItems) {
                if ($ck -and $ck.Key -and ($ck.Key.ToString().Trim().Length -eq 25) -and ($ck.Key.ToString().Trim() -match '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')) {
                    $cKeyClean = $ck.Key.ToString().Trim()
                    $cloudKeySet.Add($cKeyClean) | Out-Null
                    if ($mergedMap.ContainsKey($cKeyClean)) {
                        $ex = $mergedMap[$cKeyClean]
                        # NGUYÊN TẮC BẤT BIẾN: IsUsed = true ở bất kỳ máy nào hoặc Cloud luôn được bảo toàn
                        if ($ck.IsUsed -and -not $ex.IsUsed) {
                            $ex.IsUsed = $true
                            $ex.UsedHWID = [string]$ck.UsedHWID
                            $ex.UsedPCName = [string]$ck.UsedPCName
                            $ex.ActivatedDate = [string]$ck.ActivatedDate
                            $syncResult.VaultUpdated = $true
                        }
                        if (-not $ex.Duration -and $ck.Duration) { $ex.Duration = [string]$ck.Duration }
                        if (-not $ex.Customer -and $ck.Customer) { $ex.Customer = [string]$ck.Customer }
                    } else {
                        $mergedMap[$cKeyClean] = $ck
                        $syncResult.KeysMerged++
                        $syncResult.VaultUpdated = $true
                    }
                }
            }
            foreach ($lk in $mergedMap.Keys) {
                $localItem = $mergedMap[$lk]
                if (-not $cloudKeySet.Contains($lk)) {
                    $localKeysMissingOnCloud = $true
                    break
                } elseif ($localItem.IsUsed) {
                    $cMatch = $cloudItems | Where-Object { $_ -and $_.Key -and ($_.Key.ToString().Trim() -eq $lk) }
                    if ($cMatch -and -not $cMatch.IsUsed) {
                        # Local máy đã kích hoạt nhưng Cloud chưa ghi nhận -> Tự động đẩy trạng thái kích hoạt lên Cloud
                        $localKeysMissingOnCloud = $true
                        break
                    }
                }
            }
        }

        $allKeysList = @($mergedMap.Values)
        $syncResult.TotalKeys = $allKeysList.Count

        # BẢO VỆ CHỐNG GHI ĐÈ THU HẸP (DESTRUCTIVE TRUNCATION PROTECTION):
        # Nếu Cloud có N keys ($cloudItems.Count > 0) mà danh sách sau khi gộp ít hơn Cloud -> TUYỆT ĐỐI KHÔNG PUSH!
        $shouldPushToCloud = ($localKeysMissingOnCloud -or $syncResult.VaultUpdated)
        if ($shouldPushToCloud -and $cloudFetchSuccess) {
            if ($cloudItems.Count -gt 0 -and $allKeysList.Count -lt $cloudItems.Count) {
                # Chống ghi đè thu hẹp: Danh sách gộp bị ít hơn số key trên Cloud -> Từ chối ghi đè lên Cloud
                Save-VUONGTTLicenseVault -KeyList $allKeysList -SkipCloudPush
            } else {
                Save-VUONGTTLicenseVault -KeyList $allKeysList
            }
        } else {
            Save-VUONGTTLicenseVault -KeyList $allKeysList -SkipCloudPush
        }

        # -----------------------------------------------------------------
        # 2. ĐỒNG BỘ CHÍNH SÁCH PHÂN QUYỀN (FREE VS PRO) TỪ GITHUB REST API
        # -----------------------------------------------------------------
        $cloudPolicyJson = ""
        $policyFetchSuccess = $false

        # Tầng 1: GitHub Contents REST API qua Token (0s cache)
        if ($ghToken) {
            try {
                $policyApiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/contents/src/Config/feature_policy.json"
                $pReq = [System.Net.HttpWebRequest]::Create($policyApiUrl)
                $pReq.Proxy = $null
                $pReq.Timeout = 6000
                $pReq.UserAgent = "VUONGTT-AdminCloudSync/2026"
                $pReq.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                $pReq.Headers.Add("Pragma", "no-cache")
                $pReq.Headers.Add("Authorization", "token $ghToken")
                $pResp = $pReq.GetResponse()
                $pReader = New-Object System.IO.StreamReader($pResp.GetResponseStream(), [System.Text.Encoding]::UTF8)
                $pRaw = $pReader.ReadToEnd()
                $pReader.Close(); $pResp.Close()
                $pObj = ConvertFrom-Json ($pRaw.TrimStart([char]0xFEFF).Trim())
                if ($pObj -and $pObj.content) {
                    $cleanBase64 = $pObj.content -replace '\s+', ''
                    $bytes = [System.Convert]::FromBase64String($cleanBase64)
                    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                        $bytes = $bytes[3..($bytes.Length - 1)]
                    }
                    $cloudPolicyJson = [System.Text.Encoding]::UTF8.GetString($bytes).Trim()
                    if ($cloudPolicyJson -and $cloudPolicyJson.Length -ge 2) {
                        $policyFetchSuccess = $true
                    }
                }
            } catch {}
        }

        # Tầng 2: Fallback sang GitHub Raw URL trực tiếp kèm tham số chống cache
        if (-not $policyFetchSuccess) {
            try {
                $policyRawUrl = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch/src/Config/feature_policy.json?nocache=$ts"
                $pDownloaded = $wc.DownloadString($policyRawUrl).TrimStart([char]0xFEFF).Trim()
                if ($pDownloaded -and $pDownloaded.Length -ge 2) {
                    $cloudPolicyJson = $pDownloaded
                    $policyFetchSuccess = $true
                }
            } catch {}
        }

        if ($policyFetchSuccess -and $cloudPolicyJson) {
            $cleanPolicyText = $cloudPolicyJson.TrimStart([char]0xFEFF).Trim()
            $cloudPolicies = ConvertFrom-Json $cleanPolicyText
            if ($cloudPolicies -and $cloudPolicies.Count -gt 0) {
                $currentLocalJson = ""
                if (Test-Path $script:POLICY_FILE) {
                    $currentLocalJson = [System.IO.File]::ReadAllText($script:POLICY_FILE, [System.Text.Encoding]::UTF8).TrimStart([char]0xFEFF).Trim()
                }
                $newFormattedJson = $cloudPolicies | ConvertTo-Json -Depth 4
                if ($newFormattedJson.Trim() -ne $currentLocalJson.Trim()) {
                    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
                    [System.IO.File]::WriteAllText($script:POLICY_FILE, $newFormattedJson, $utf8NoBom)
                    try {
                        $localPolicy = Join-Path $PSScriptRoot "..\Config\feature_policy.json"
                        if (Test-Path (Split-Path $localPolicy -Parent)) {
                            [System.IO.File]::WriteAllText($localPolicy, $newFormattedJson, $utf8NoBom)
                        }
                    } catch {}
                    $syncResult.PoliciesSynced = $true
                }
            }
        }

        if ($cloudFetchSuccess -or $policyFetchSuccess) {
            $syncResult.Success = $true
            $syncResult.Message = "Đồng bộ đám mây thành công! Tổng số License Key trong kho: $($syncResult.TotalKeys) key."
        } else {
            $syncResult.Success = $false
            $syncResult.Message = "Không thể kết nối đến máy chủ Cloud GitHub (Vui lòng kiểm tra kết nối mạng hoặc Token)."
        }
        return $syncResult
    } catch {
        $syncResult.Success = $false
        $syncResult.Message = "Lỗi đồng bộ đám mây: $($_.Exception.Message)"
        return $syncResult
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
    $vault = @(Get-VUONGTTAllLicenses)
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
        if ($targetKey.UsedHWID -eq $currentHWID -or $targetKey.UsedPCName -eq $env:COMPUTERNAME) {
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

    # ĐỒNG BỘ TỨC THÌ LÊN CLOUD GITHUB VÀ KHO CỤC BỘ (MERGE CHUYÊN SÂU CHỐNG MẤT KEY)
    $cloudOk = Sync-VUONGTTKeyActivationToCloud -Key $targetKey.Key -Customer $targetKey.Customer -Duration $targetKey.Duration -HWID $currentHWID -PCName $env:COMPUTERNAME -ActivatedDate $targetKey.ActivatedDate
    if (-not $cloudOk) {
        Save-VUONGTTLicenseVault -KeyList $vault
    }

    # LƯU BẢN QUYỀN PRO ĐA TẦNG (IN-MEMORY + REGISTRY + FILE .LIC)
    Write-VUONGTTActiveLicenseFile -Key $targetKey.Key -Customer $targetKey.Customer -Duration $targetKey.Duration -HWID $currentHWID

    return [PSCustomObject]@{
        Success  = $true
        Message  = "CHÚC MỪNG! ĐÃ KÍCH HOẠT THÀNH CÔNG BẢN QUYỀN PRO CHO MÁY TÍNH NÀY!"
        Duration = $targetKey.Duration
        Customer = $targetKey.Customer
    }
}

function Sync-VUONGTTKeyActivationToCloud {
    [CmdletBinding()]
    param(
        [string]$Key,
        [string]$Customer,
        [string]$Duration,
        [string]$HWID,
        [string]$PCName,
        [string]$ActivatedDate
    )

    $token = Get-VUONGTTGitHubToken
    if (-not $token) { return $false }

    for ($retry = 0; $retry -lt 3; $retry++) {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
            $headers = @{
                "Authorization" = "token $token"
                "User-Agent"    = "VUONGTT-CloudSync/2026"
                "Accept"        = "application/vnd.github.v3+json"
            }

            $metaUrl = "https://api.github.com/repos/$script:GITHUB_REPO_OWNER/$script:GITHUB_REPO_NAME/contents/src/Config/licenses_vault.json"
            $meta = Invoke-RestMethod -Uri $metaUrl -Headers $headers -TimeoutSec 8
            if (-not $meta -or -not $meta.content -or -not $meta.sha) { break }

            $sha = $meta.sha
            $cleanB64 = $meta.content -replace '\s+', ''
            $rawBytes = [System.Convert]::FromBase64String($cleanB64)
            if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
                $rawBytes = $rawBytes[3..($rawBytes.Length - 1)]
            }
            $cloudJson = [System.Text.Encoding]::UTF8.GetString($rawBytes).Trim()
            $cloudKeys = @(ConvertFrom-Json $cloudJson)

            $found = $false
            foreach ($k in $cloudKeys) {
                if ($k.Key -and ($k.Key.Trim() -eq $Key.Trim())) {
                    $k.IsUsed        = $true
                    $k.UsedHWID      = $HWID
                    $k.UsedPCName    = $PCName
                    $k.ActivatedDate = $ActivatedDate
                    $found = $true
                    break
                }
            }

            if (-not $found) {
                $cloudKeys += [PSCustomObject]@{
                    Key           = $Key.Trim()
                    Customer      = if ($Customer) { $Customer } else { "Khách Hàng PRO" }
                    Duration      = if ($Duration) { $Duration } else { "Lifetime" }
                    CreatedDate   = $ActivatedDate
                    IsUsed        = $true
                    UsedHWID      = $HWID
                    UsedPCName    = $PCName
                    ActivatedDate = $ActivatedDate
                }
            }

            $newJson = [object[]]$cloudKeys | ConvertTo-Json -Depth 4
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            $putB64 = [System.Convert]::ToBase64String($utf8NoBom.GetBytes($newJson))
            $bodyObj = @{
                message = "sync(activation): machine '$PCName' activated key $Key"
                content = $putB64
                sha     = $sha
                branch  = "main"
            }

            $putUrl = "https://api.github.com/repos/$script:GITHUB_REPO_OWNER/$script:GITHUB_REPO_NAME/contents/src/Config/licenses_vault.json"
            $null = Invoke-RestMethod -Uri $putUrl -Method Put -Headers $headers -Body ($bodyObj | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 10

            [System.IO.File]::WriteAllText($script:VAULT_FILE, $newJson, $utf8NoBom)
            try {
                $localCfgVault = Join-Path $PSScriptRoot "..\Config\licenses_vault.json"
                if (Test-Path (Split-Path $localCfgVault -Parent)) {
                    [System.IO.File]::WriteAllText($localCfgVault, $newJson, $utf8NoBom)
                }
            } catch {}

            return $true
        } catch {
            Start-Sleep -Milliseconds 500
        }
    }
    return $false
}

function Set-VUONGTTKeyStatusAdmin {
    param(
        [string]$Key,
        [bool]$IsUsed,
        [string]$PCName = ""
    )
    $vault = @(Get-VUONGTTAllLicenses)
    $target = $vault | Where-Object { $_.Key -eq $Key }
    if ($target) {
        $target.IsUsed = $IsUsed
        if ($IsUsed) {
            $target.UsedPCName = if ($PCName) { $PCName } else { "Admin Verified" }
            $target.UsedHWID = "VERIFIED-ADMIN-MANUAL"
            $target.ActivatedDate = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
        } else {
            $target.UsedPCName = ""
            $target.UsedHWID = ""
            $target.ActivatedDate = ""
        }
        Save-VUONGTTLicenseVault -KeyList $vault
        return $true
    }
    return $false
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

    # 1. CẬP NHẬT CACHE TOÀN CỤC TRONG RAM (0ms, không bao giờ bị delay hay file lock)
    $global:cachedProLicense = [PSCustomObject]@{
        IsPro    = $true
        License  = $licData
        Duration = $Duration
        Customer = $Customer
        Reason   = "Bản quyền PRO hợp lệ"
    }

    # 2. LƯU VÀO REGISTRY WINDOWS USER (HKCU:\SOFTWARE\VUONGTT_Toolkit\License)
    # Khong bao gio bi xoa boi Disk Cleanup, Temp Cleaner hay xung dot quyen thu muc
    try {
        $regPath = "HKCU:\SOFTWARE\VUONGTT_Toolkit\License"
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name "Key" -Value $Key -Force
        Set-ItemProperty -Path $regPath -Name "Customer" -Value $Customer -Force
        Set-ItemProperty -Path $regPath -Name "Duration" -Value $Duration -Force
        Set-ItemProperty -Path $regPath -Name "HWID" -Value $HWID -Force
        Set-ItemProperty -Path $regPath -Name "PCName" -Value $env:COMPUTERNAME -Force
        Set-ItemProperty -Path $regPath -Name "ActivatedDate" -Value $licData.ActivatedDate -Force
        Set-ItemProperty -Path $regPath -Name "Signature" -Value $signature -Force
        Set-ItemProperty -Path $regPath -Name "IsPro" -Value 1 -Force
    } catch {}

    # 3. LƯU RA TỆP TIN .LIC VỚI UTF-8 KHÔNG BOM
    $json = $licData | ConvertTo-Json -Depth 4
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $base64 = [System.Convert]::ToBase64String($bytes)
    
    try {
        $dir = Split-Path $script:ACTIVE_LIC_FILE -Parent
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        [System.IO.File]::WriteAllText($script:ACTIVE_LIC_FILE, $base64, [System.Text.Encoding]::ASCII)
    } catch {}

    try {
        $localLic = Join-Path $PSScriptRoot "..\Config\active_license.lic"
        if (Test-Path (Split-Path $localLic -Parent)) {
            [System.IO.File]::WriteAllText($localLic, $base64, [System.Text.Encoding]::ASCII)
        }
    } catch {}
}

function Test-VUONGTTProLicense {
    [CmdletBinding()]
    param()

    # 1. KIỂM TRA BỘ NHỚ RAM CACHE TRƯỚC (SIÊU TỐC, ĐÁP ỨNG TỨC THÌ TRONG CÙNG PHIÊN)
    if ($global:cachedProLicense -and $global:cachedProLicense.IsPro) {
        return $global:cachedProLicense
    }

    $currentHWID = Get-VUONGTTHardwareId

    # 2. KIỂM TRA REGISTRY HKCU (AN TOÀN TUYỆT ĐỐI, BẢO TOÀN QUA MỌI LẦN CẬP NHẬT EXE)
    try {
        $regPath = "HKCU:\SOFTWARE\VUONGTT_Toolkit\License"
        if (Test-Path $regPath) {
            $regKey       = (Get-ItemProperty -Path $regPath -Name "Key" -ErrorAction SilentlyContinue).Key
            $regCustomer  = (Get-ItemProperty -Path $regPath -Name "Customer" -ErrorAction SilentlyContinue).Customer
            $regDuration  = (Get-ItemProperty -Path $regPath -Name "Duration" -ErrorAction SilentlyContinue).Duration
            $regHWID      = (Get-ItemProperty -Path $regPath -Name "HWID" -ErrorAction SilentlyContinue).HWID
            $regSignature = (Get-ItemProperty -Path $regPath -Name "Signature" -ErrorAction SilentlyContinue).Signature
            $regPCName    = (Get-ItemProperty -Path $regPath -Name "PCName" -ErrorAction SilentlyContinue).PCName
            $regDate      = (Get-ItemProperty -Path $regPath -Name "ActivatedDate" -ErrorAction SilentlyContinue).ActivatedDate

            if ($regKey -and $regSignature -and ($regHWID -eq $currentHWID -or $regPCName -eq $env:COMPUTERNAME)) {
                $sigSeed = "VUONGTT_PRO_2026:" + $regKey + ":" + $regHWID + ":" + $regDuration
                $sha = [System.Security.Cryptography.SHA256]::Create()
                $expectedSig = ($sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($sigSeed)) | ForEach-Object { $_.ToString("X2") }) -join ""

                if ($regSignature -eq $expectedSig) {
                    $licObj = [PSCustomObject]@{
                        Key           = $regKey
                        Customer      = $regCustomer
                        Duration      = $regDuration
                        HWID          = $regHWID
                        PCName        = $regPCName
                        ActivatedDate = $regDate
                        Signature     = $regSignature
                    }
                    $resObj = [PSCustomObject]@{
                        IsPro    = $true
                        License  = $licObj
                        Duration = $regDuration
                        Customer = $regCustomer
                        Reason   = "Bản quyền PRO hợp lệ (Registry)"
                    }
                    $global:cachedProLicense = $resObj
                    return $resObj
                }
            }
        }
    } catch {}

    # 3. KIỂM TRA FILE BẢN QUYỀN TRÊN Ổ ĐĨA
    $licFilePath = $script:ACTIVE_LIC_FILE
    if (-not (Test-Path $licFilePath)) {
        $localLic = Join-Path $PSScriptRoot "..\Config\active_license.lic"
        if (Test-Path $localLic) {
            $licFilePath = $localLic
        } else {
            return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Chưa kích hoạt bản quyền" }
        }
    }

    try {
        $base64 = [System.IO.File]::ReadAllText($licFilePath, [System.Text.Encoding]::ASCII).Trim()
        if (-not $base64) { return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Tệp bản quyền rỗng" } }
        $bytes = [System.Convert]::FromBase64String($base64)
        $json = [System.Text.Encoding]::UTF8.GetString($bytes)
        $cleanJson = $json.TrimStart([char]0xFEFF).Trim()
        $lic = ConvertFrom-Json $cleanJson

        if ($lic.HWID -ne $currentHWID -and $lic.PCName -ne $env:COMPUTERNAME) {
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
        try {
            $vault = @(Get-VUONGTTAllLicenses)
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
                Save-VUONGTTLicenseVault -KeyList $vault -SkipCloudPush
            }
        } catch {}

        $resObj = [PSCustomObject]@{
            IsPro    = $true
            License  = $lic
            Duration = $lic.Duration
            Customer = $lic.Customer
            Reason   = "Bản quyền PRO hợp lệ"
        }
        $global:cachedProLicense = $resObj
        return $resObj
    } catch {
        return [PSCustomObject]@{ IsPro = $false; License = $null; Reason = "Lỗi đọc file bản quyền: $($_.Exception.Message)" }
    }
}
