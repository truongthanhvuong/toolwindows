# src/Core/WindowsInPlaceUpgrade.ps1
# VUONGTT Toolkit 2026 - Windows 11 In-Place Upgrade Engine
# Nâng cấp lên Windows 11 mới nhất không mất dữ liệu (Giữ nguyên toàn bộ App & Tệp cá nhân)

$coreDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$adminSecPath = Join-Path $coreDir "AdminSecurityManager.ps1"
if (-not (Get-Command "Start-VUONGTTAdminProcess" -ErrorAction SilentlyContinue) -and (Test-Path $adminSecPath)) {
    . $adminSecPath
}

<#
.SYNOPSIS
    Lấy thông tin chi tiết về phiên bản Windows hiện tại đang chạy trên máy.
#>
function Get-VUONGTTCurrentWindowsInfo {
    [CmdletBinding()]
    param()

    $caption = "Windows"
    $buildNumber = "0"
    $arch = if ([Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" }
    $displayVer = ""

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $caption = $os.Caption
            $buildNumber = $os.BuildNumber
        }
    } catch {
        try {
            $caption = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName" -ErrorAction SilentlyContinue).ProductName
            $buildNumber = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "CurrentBuild" -ErrorAction SilentlyContinue).CurrentBuild
        } catch {}
    }

    try {
        $regCur = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
        if ($regCur) {
            if ($regCur.DisplayVersion) { $displayVer = $regCur.DisplayVersion }
            elseif ($regCur.ReleaseId) { $displayVer = $regCur.ReleaseId }
        }
    } catch {}

    $buildInt = 0
    [int]::TryParse($buildNumber, [ref]$buildInt) | Out-Null
    $isWin11 = ($buildInt -ge 22000)

    return [PSCustomObject]@{
        Caption        = $caption
        BuildNumber    = $buildNumber
        DisplayVersion = $displayVer
        Architecture   = $arch
        IsWindows11    = $isWin11
    }
}

<#
.SYNOPSIS
    Kích hoạt 100% chính sách Registry Bypass TPM 2.0, SecureBoot, RAM & CPU để nâng cấp đè Windows 11 mọi cấu hình.
#>
function Enable-VUONGTTInPlaceUpgradeBypass {
    [CmdletBinding()]
    param()

    $result = [PSCustomObject]@{
        Success        = $false
        KeysConfigured = 0
        Log            = [System.Collections.Generic.List[string]]::new()
    }

    $bypassSettings = @(
        @{ Key = "SYSTEM\Setup\MoSetup";   Name = "AllowUpgradesWithUnsupportedTPMOrCPU"; Value = 1 },
        @{ Key = "SYSTEM\Setup\LabConfig"; Name = "BypassTPMCheck";                       Value = 1 },
        @{ Key = "SYSTEM\Setup\LabConfig"; Name = "BypassSecureBootCheck";                Value = 1 },
        @{ Key = "SYSTEM\Setup\LabConfig"; Name = "BypassCPUCheck";                       Value = 1 },
        @{ Key = "SYSTEM\Setup\LabConfig"; Name = "BypassRAMCheck";                       Value = 1 },
        @{ Key = "SYSTEM\Setup\LabConfig"; Name = "BypassStorageCheck";                   Value = 1 }
    )

    foreach ($item in $bypassSettings) {
        try {
            if (Get-Command "Set-VUONGTTAdminRegistry" -ErrorAction SilentlyContinue) {
                Set-VUONGTTAdminRegistry -SubKey $item.Key -Name $item.Name -Value $item.Value -Type "DWord" -TargetScopes @("HKLM") | Out-Null
            } else {
                $fullPath = "HKLM:\$($item.Key)"
                if (-not (Test-Path $fullPath)) {
                    New-Item -Path $fullPath -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Set-ItemProperty -Path $fullPath -Name $item.Name -Value $item.Value -Type DWord -Force -ErrorAction SilentlyContinue
            }
            $result.KeysConfigured++
            $result.Log.Add("  [OK] Đã thiết lập: $($item.Key)\$($item.Name) = $($item.Value)")
        } catch {
            $result.Log.Add("  [CẢNH BÁO] Không thể ghi $($item.Key)\$($item.Name): $($_.Exception.Message)")
        }
    }

    $result.Success = ($result.KeysConfigured -ge 3)
    return $result
}

<#
.SYNOPSIS
    Kiểm tra điều kiện tiên quyết trước khi nâng cấp Windows 11 In-Place (Dung lượng ổ C, kiến trúc x64).
#>
function Test-VUONGTTInPlaceUpgradeReadiness {
    [CmdletBinding()]
    param()

    $info = Get-VUONGTTCurrentWindowsInfo
    $freeGB = 0
    $isReady = $true
    $warnings = [System.Collections.Generic.List[string]]::new()

    try {
        $cDrive = Get-PSDrive -Name C -PSProvider FileSystem -ErrorAction SilentlyContinue
        if ($cDrive) {
            $freeGB = [Math]::Round($cDrive.Free / 1GB, 2)
        }
    } catch {}

    # Yêu cầu tối thiểu dung lượng trống ổ C: khuyến nghị 20GB
    if ($freeGB -lt 20) {
        $isReady = $false
        $warnings.Add("Ổ đĩa C: chỉ còn $freeGB GB dung lượng trống. Windows Setup khuyến nghị tối thiểu 20 GB để lưu bản sao lưu Windows.old.")
    }

    # Windows 11 chỉ hỗ trợ 64-bit
    if ($info.Architecture -ne "64-bit") {
        $isReady = $false
        $warnings.Add("Hệ thống hiện tại là $($info.Architecture). Windows 11 chỉ hỗ trợ kiến trúc 64-bit.")
    }

    return [PSCustomObject]@{
        IsReady     = $isReady
        FreeSpaceGB = $freeGB
        CurrentOS   = $info
        Warnings    = $warnings.ToArray()
    }
}

<#
.SYNOPSIS
    Trả về chuỗi tham số thực thi chuẩn cho Windows Setup In-Place Upgrade bảo toàn dữ liệu.
#>
function Get-VUONGTTInPlaceUpgradeArguments {
    [CmdletBinding()]
    param()

    # /auto upgrade: Cài đè trực tiếp, giữ nguyên 100% ứng dụng và tệp cá nhân
    # /DynamicUpdate disable: Bỏ qua bước tải cập nhật mạng kéo dài thời gian cài
    # /compat ignorewarning: Tự động bỏ qua các cảnh báo phần cứng chưa đạt chuẩn
    # /MigrateDrivers none: Ngăn Windows Setup mang driver cũ sang nhân mới gây lỗi sập boot SAFE_OS 0xC1900101
    return "/auto upgrade /DynamicUpdate disable /compat ignorewarning /MigrateDrivers none"
}

<#
.SYNOPSIS
    Khởi chạy tiến trình nâng cấp Windows 11 In-Place Upgrade từ tệp ISO hoặc thư mục setup.
#>
function Start-VUONGTTInPlaceUpgrade {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$IsoOrSetupPath,

        [Parameter(Mandatory = $false)]
        [switch]$BypassHardware = $true,

        [Parameter(Mandatory = $false)]
        [scriptblock]$OnProgress = $null
    )

    $log = [System.Collections.Generic.List[string]]::new()
    $log.Add("=== KHỞI CHẠY NÂNG CẤP WINDOWS 11 IN-PLACE UPGRADE (GIỮ NGUYÊN DỮ LIỆU) ===")

    # 1. Kích hoạt Bypass phần cứng
    if ($BypassHardware) {
        if ($OnProgress) { & $OnProgress "-> Đang kích hoạt chính sách 1-Click Bypass TPM 2.0, SecureBoot, RAM & CPU..." }
        $bp = Enable-VUONGTTInPlaceUpgradeBypass
        $log.Add("• Đã nạp thành công $($bp.KeysConfigured) cờ Bypass phần cứng Windows 11.")
    }

    # 2. Xử lý đường dẫn ISO hoặc Setup
    $mountedDrive = $null
    $setupExe = $null

    if ($IsoOrSetupPath -like "*.iso") {
        if (-not (Test-Path $IsoOrSetupPath)) {
            throw "Không tìm thấy tệp tin ISO: '$IsoOrSetupPath'"
        }
        if ($OnProgress) { & $OnProgress "-> Đang nạp tệp tin ISO vào ổ đĩa ảo hệ thống (Mount-DiskImage)..." }
        try {
            $m = Mount-DiskImage -ImagePath $IsoOrSetupPath -StorageType ISO -PassThru
            Start-Sleep -Milliseconds 800
            $vol = $m | Get-Volume
            if ($vol -and $vol.DriveLetter) {
                $mountedDrive = "$($vol.DriveLetter):"
            }
        } catch {}

        if (-not $mountedDrive) {
            $drives = Get-PSDrive -PSProvider FileSystem
            foreach ($d in $drives) {
                if (Test-Path (Join-Path $d.Root "setup.exe")) {
                    $mountedDrive = $d.Root.TrimEnd('\')
                    break
                }
            }
        }

        if (-not $mountedDrive) {
            throw "Không thể mount ổ đĩa ảo từ tệp ISO!"
        }
        $log.Add("• Đã mount tệp ISO vào ổ đĩa ảo: $mountedDrive\")
        $setupExe = "$mountedDrive\setup.exe"
        if (Test-Path "$mountedDrive\sources\setupprep.exe") {
            $setupExe = "$mountedDrive\sources\setupprep.exe"
        }
    } else {
        # Đã là thư mục giải nén hoặc đường dẫn setup.exe trực tiếp
        if (Test-Path (Join-Path $IsoOrSetupPath "setup.exe")) {
            $setupExe = Join-Path $IsoOrSetupPath "setup.exe"
            if (Test-Path (Join-Path $IsoOrSetupPath "sources\setupprep.exe")) {
                $setupExe = Join-Path $IsoOrSetupPath "sources\setupprep.exe"
            }
        } elseif (Test-Path $IsoOrSetupPath) {
            $setupExe = $IsoOrSetupPath
        }
    }

    if (-not $setupExe -or -not (Test-Path $setupExe)) {
        throw "Không tìm thấy file trình cài đặt Windows Setup (setup.exe)!"
    }

    # 3. Chuẩn bị tham số In-Place Upgrade
    $argList = Get-VUONGTTInPlaceUpgradeArguments
    $log.Add("• Trình thực thi: $setupExe")
    $log.Add("• Tham số nâng cấp: $argList")
    $log.Add("• Trạng thái dữ liệu: BẢO TOÀN 100% ỨNG DỤNG, TỆP CÁ NHÂN & THIẾT LẬP")

    # 4. Khởi chạy tiến trình với quyền Administrator cao nhất
    if ($OnProgress) { & $OnProgress "-> Đang khởi chạy Windows Setup với đặc quyền Administrator..." }
    $procRes = $null
    if (Get-Command "Start-VUONGTTAdminProcess" -ErrorAction SilentlyContinue) {
        $procRes = Start-VUONGTTAdminProcess -FilePath $setupExe -ArgumentList $argList -WorkingDirectory ([System.IO.Path]::GetDirectoryName($setupExe))
    } else {
        $p = Start-Process -FilePath $setupExe -ArgumentList $argList -Verb RunAs -PassThru
        $procRes = [PSCustomObject]@{ Success = ($null -ne $p); ProcessId = if ($p) { $p.Id } else { 0 }; Error = $null }
    }

    if ($procRes -and $procRes.Success) {
        $log.Add("• [THÀNH CÔNG] Trình nâng cấp Windows 11 đã được khởi động sẵn sàng!")
        $log.Add("  Windows sẽ tự động chuẩn bị và khởi động lại để hoàn tất tiến trình nâng cấp.")
    } else {
        throw "Không thể khởi động trình cài đặt: $($procRes.Error)"
    }

    return [PSCustomObject]@{
        Success      = $true
        MountedDrive = $mountedDrive
        SetupExe     = $setupExe
        Arguments    = $argList
        SummaryLog   = ($log -join "`r`n")
    }
}
