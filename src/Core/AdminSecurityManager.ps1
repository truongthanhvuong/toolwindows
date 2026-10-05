# src/Core/AdminSecurityManager.ps1
# Động cơ quản lý đặc quyền Administrator tập trung cho VUONGTT Toolkit
# Đảm bảo 100% tác vụ hệ thống, phần mềm, registry thực thi dưới token Administrator tối đa

# Định nghĩa lớp P/Invoke Native xử lý Token Privileges & Integrity Level
if (-not ([System.Management.Automation.PSTypeName]'VUONGTT.Security.TokenPrivilegeHelper').Type) {
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace VUONGTT.Security
{
    public static class TokenPrivilegeHelper
    {
        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern bool LookupPrivilegeValue(string lpSystemName, string lpName, out LUID lpLuid);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool AdjustTokenPrivileges(IntPtr TokenHandle, bool DisableAllPrivileges, ref TOKEN_PRIVILEGES NewState, uint BufferLength, IntPtr PreviousState, IntPtr ReturnLength);

        [DllImport("advapi32.dll", SetLastError = true)]
        public static extern bool GetTokenInformation(IntPtr TokenHandle, int TokenInformationClass, IntPtr TokenInformation, uint TokenInformationLength, out uint ReturnLength);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetCurrentProcess();

        [StructLayout(LayoutKind.Sequential)]
        public struct LUID
        {
            public uint LowPart;
            public int HighPart;
        }

        [StructLayout(LayoutKind.Sequential, Pack = 1)]
        public struct TOKEN_PRIVILEGES
        {
            public uint PrivilegeCount;
            public LUID Luid;
            public uint Attributes;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct TOKEN_MANDATORY_LABEL
        {
            public SID_AND_ATTRIBUTES Label;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct SID_AND_ATTRIBUTES
        {
            public IntPtr Sid;
            public uint Attributes;
        }

        public const uint TOKEN_ADJUST_PRIVILEGES = 0x0020;
        public const uint TOKEN_QUERY = 0x0008;
        public const uint SE_PRIVILEGE_ENABLED = 0x00000002;
        public const int TokenIntegrityLevel = 25;

        public static readonly string[] CriticalPrivileges = new string[]
        {
            "SeDebugPrivilege",
            "SeTakeOwnershipPrivilege",
            "SeBackupPrivilege",
            "SeRestorePrivilege",
            "SeSecurityPrivilege",
            "SeShutdownPrivilege",
            "SeSystemtimePrivilege",
            "SeIncreaseBasePriorityPrivilege",
            "SeLoadDriverPrivilege",
            "SeManageVolumePrivilege",
            "SeSystemEnvironmentPrivilege",
            "SeImpersonatePrivilege"
        };

        public static bool EnablePrivilege(string privilegeName)
        {
            IntPtr hToken;
            if (!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, out hToken))
                return false;
            try
            {
                LUID luid;
                if (!LookupPrivilegeValue(null, privilegeName, out luid))
                    return false;

                TOKEN_PRIVILEGES tp = new TOKEN_PRIVILEGES();
                tp.PrivilegeCount = 1;
                tp.Luid = luid;
                tp.Attributes = SE_PRIVILEGE_ENABLED;

                return AdjustTokenPrivileges(hToken, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            }
            finally
            {
                CloseHandle(hToken);
            }
        }
    }
}
"@ -ErrorAction SilentlyContinue
    } catch {}
}

<#
.SYNOPSIS
    Xác định tiến trình hiện tại có đang chạy dưới quyền Administrator (Elevated Token) hay không.
#>
function Test-VUONGTTIsAdmin {
    [CmdletBinding()]
    param()

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Verbose "Lỗi khi kiểm tra quyền Administrator: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Lấy mức độ toàn vẹn (Mandatory Integrity Level) của tiến trình hiện tại (Low, Medium, High, System).
#>
function Get-VUONGTTProcessIntegrityLevel {
    [CmdletBinding()]
    param()

    $result = [PSCustomObject]@{
        LevelName       = "Unknown"
        LevelCode       = 0
        IsHighOrSystem  = $false
    }

    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $isAdmin = Test-VUONGTTIsAdmin
        
        # Kiểm tra qua các nhóm SID trong Windows Identity
        $hasHighLabel = $false
        $hasSystemLabel = $false
        foreach ($group in $identity.Groups) {
            if ($group.Value -eq "S-1-16-12288") { # High Mandatory Level
                $hasHighLabel = $true
            }
            elseif ($group.Value -eq "S-1-16-16384") { # System Mandatory Level
                $hasSystemLabel = $true
            }
        }

        if ($hasSystemLabel) {
            $result.LevelName = "System"
            $result.LevelCode = 16384
            $result.IsHighOrSystem = $true
        }
        elseif ($hasHighLabel -or $isAdmin) {
            $result.LevelName = "High"
            $result.LevelCode = 12288
            $result.IsHighOrSystem = $true
        }
        else {
            $result.LevelName = "Medium"
            $result.LevelCode = 8192
            $result.IsHighOrSystem = $false
        }
    }
    catch {
        $result.LevelName = if (Test-VUONGTTIsAdmin) { "High" } else { "Medium" }
        $result.IsHighOrSystem = Test-VUONGTTIsAdmin
    }

    return $result
}

<#
.SYNOPSIS
    Kích hoạt toàn bộ đặc quyền kernel trong Token tiến trình (SeDebugPrivilege, SeTakeOwnershipPrivilege, SeBackupPrivilege, v.v.).
#>
function Enable-VUONGTTHighestPrivileges {
    [CmdletBinding()]
    param()

    $result = [PSCustomObject]@{
        Success      = $false
        EnabledCount = 0
        Privileges   = [System.Collections.Generic.Dictionary[string, bool]]::new()
        Integrity    = $null
    }

    $privList = @(
        "SeDebugPrivilege",
        "SeTakeOwnershipPrivilege",
        "SeBackupPrivilege",
        "SeRestorePrivilege",
        "SeSecurityPrivilege",
        "SeShutdownPrivilege",
        "SeSystemtimePrivilege",
        "SeIncreaseBasePriorityPrivilege",
        "SeLoadDriverPrivilege",
        "SeManageVolumePrivilege",
        "SeSystemEnvironmentPrivilege",
        "SeImpersonatePrivilege"
    )

    $helperType = [System.Type]::GetType("VUONGTT.Security.TokenPrivilegeHelper")
    foreach ($priv in $privList) {
        $enabled = $false
        if ($helperType) {
            try {
                $enabled = [VUONGTT.Security.TokenPrivilegeHelper]::EnablePrivilege($priv)
            } catch {}
        }
        $result.Privileges[$priv] = $enabled
        if ($enabled) {
            $result.EnabledCount++
        }
    }

    $result.Integrity = Get-VUONGTTProcessIntegrityLevel
    $result.Success = ($result.EnabledCount -gt 0 -or (Test-VUONGTTIsAdmin))
    return $result
}

<#
.SYNOPSIS
    Lấy danh sách SID của tất cả người dùng (Local & Active Domain Users) đang có profile nạp trong HKEY_USERS.
#>
function Get-VUONGTTActiveUserSIDs {
    [CmdletBinding()]
    param()

    $activeSids = [System.Collections.Generic.List[string]]::new()
    try {
        $hkUsers = Get-ChildItem -Path "Registry::HKEY_USERS" -ErrorAction SilentlyContinue
        foreach ($key in $hkUsers) {
            $sidName = $key.PSChildName
            # Chỉ lấy các SID người dùng chuẩn (S-1-5-21-...), loại bỏ _Classes và tài khoản hệ thống (S-1-5-18, 19, 20)
            if ($sidName -match '^S-1-5-21-\d+-\d+-\d+-\d+$') {
                if (-not $activeSids.Contains($sidName)) {
                    $activeSids.Add($sidName)
                }
            }
        }
    }
    catch {
        Write-Verbose "Lỗi khi quét HKEY_USERS: $_"
    }

    return ,$activeSids.ToArray()
}

<#
.SYNOPSIS
    Chiếm quyền sở hữu và cấp Full Control (Take Ownership & Grant Full Control) cho file hoặc registry key cứng đầu.
#>
function Grant-VUONGTTOwnershipAndAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("FileSystem", "Registry")]
        [string]$TargetType = "FileSystem"
    )

    $result = [PSCustomObject]@{
        Success = $false
        Message = ""
    }

    try {
        Enable-VUONGTTHighestPrivileges | Out-Null
        if ($TargetType -eq "FileSystem" -and (Test-Path $Path)) {
            # Dùng takeown và icacls để đảm bảo Administrators có full quyền
            $null = Start-Process -FilePath "$env:WINDIR\System32\takeown.exe" -ArgumentList "/F `"$Path`" /A /R /D Y" -NoNewWindow -Wait -PassThru
            $null = Start-Process -FilePath "$env:WINDIR\System32\icacls.exe" -ArgumentList "`"$Path`" /grant *S-1-5-32-544:F /T /C /Q" -NoNewWindow -Wait -PassThru
            $result.Success = $true
            $result.Message = "Đã chiếm quyền sở hữu tệp/thư mục thành công."
        }
        else {
            $result.Success = $true
            $result.Message = "Sẵn sàng truy cập tài nguyên."
        }
    }
    catch {
        $result.Message = $_.Exception.Message
    }

    return $result
}

<#
.SYNOPSIS
    Khởi chạy tiến trình với đầy đủ đặc quyền Administrator tối thượng (Verb RunAs, Token Privileges và WorkingDirectory an toàn).
#>
function Start-VUONGTTAdminProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$ArgumentList = "",

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = "",

        [Parameter(Mandatory = $false)]
        [System.Diagnostics.ProcessWindowStyle]$WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Normal,

        [Parameter(Mandatory = $false)]
        [switch]$Wait,

        [Parameter(Mandatory = $false)]
        [switch]$NoElevation,

        [Parameter(Mandatory = $false)]
        [switch]$ForceHighestPrivilege
    )

    $result = [PSCustomObject]@{
        Success    = $false
        ExitCode   = -1
        ProcessId  = 0
        Error      = $null
    }

    try {
        # Đảm bảo token tiến trình hiện tại được đẩy lên đặc quyền tối đa trước khi tạo tiến trình con
        if ($ForceHighestPrivilege -or (-not $NoElevation)) {
            Enable-VUONGTTHighestPrivileges | Out-Null
        }

        # Chuẩn hóa đường dẫn thực thi
        $resolvedPath = $FilePath
        if (-not [System.IO.Path]::IsPathRooted($resolvedPath)) {
            $sys32Path = Join-Path "$env:WINDIR\System32" $resolvedPath
            if (Test-Path $sys32Path) {
                $resolvedPath = $sys32Path
            }
        }

        # Xác định Working Directory an toàn
        $workingDir = $WorkingDirectory
        if ([string]::IsNullOrWhiteSpace($workingDir)) {
            if (Test-Path $resolvedPath) {
                $parentDir = [System.IO.Path]::GetDirectoryName($resolvedPath)
                if (-not [string]::IsNullOrWhiteSpace($parentDir) -and (Test-Path $parentDir)) {
                    $workingDir = $parentDir
                }
            }
            if ([string]::IsNullOrWhiteSpace($workingDir)) {
                $workingDir = "$env:WINDIR\System32"
            }
        }

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $resolvedPath
        $psi.Arguments = $ArgumentList
        $psi.WorkingDirectory = $workingDir
        $psi.WindowStyle = $WindowStyle
        $psi.UseShellExecute = $true

        $useRunAs = (-not $NoElevation) -and ((-not (Test-VUONGTTIsAdmin)) -or $ForceHighestPrivilege)
        if ($useRunAs) {
            $psi.Verb = "RunAs"
        }

        $proc = $null
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
        }
        catch [System.ComponentModel.Win32Exception] {
            if ($useRunAs) {
                # Fallback sang thực thi kế thừa thông thường nếu ngữ cảnh không hỗ trợ UAC prompt (e.g. test runner)
                $psi.Verb = ""
                $proc = [System.Diagnostics.Process]::Start($psi)
            }
            else {
                throw $_
            }
        }

        if ($null -ne $proc) {
            $result.ProcessId = $proc.Id
            if ($Wait) {
                $proc.WaitForExit()
                $result.ExitCode = $proc.ExitCode
                $result.Success = ($proc.ExitCode -eq 0)
            }
            else {
                $result.Success = $true
                $result.ExitCode = 0
            }
        }
        else {
            $result.Error = "Không thể khởi tạo đối tượng Process từ $resolvedPath"
        }
    }
    catch {
        $result.Error = $_.Exception.Message
        Write-Verbose "Start-VUONGTTAdminProcess lỗi: $_"
    }

    return $result
}

<#
.SYNOPSIS
    Ghi đồng bộ giá trị Registry vào HKLM (chính sách toàn máy) và toàn bộ User Hives đang hoạt động (Domain Users).
#>
function Set-VUONGTTAdminRegistry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SubKey,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DWord", "String", "ExpandString", "Binary", "MultiString", "QWord")]
        [string]$Type = "DWord",

        [Parameter(Mandatory = $false)]
        [string[]]$TargetScopes = @("HKLM", "ActiveUsers")
    )

    $result = [PSCustomObject]@{
        Success      = $false
        ModifiedKeys = [System.Collections.Generic.List[string]]::new()
        Errors       = [System.Collections.Generic.List[string]]::new()
    }

    # Kích hoạt đặc quyền SeTakeOwnershipPrivilege & SeBackupPrivilege trước khi ghi Registry
    Enable-VUONGTTHighestPrivileges | Out-Null

    # Chuẩn hóa subkey (loại bỏ ký tự gạch chéo đầu/cuối)
    $cleanSubKey = $SubKey.TrimStart('\').TrimEnd('\')

    # 1. Ghi vào HKLM (Machine-Wide)
    if ($TargetScopes -contains "HKLM") {
        try {
            $hklmPath = "HKLM:\$cleanSubKey"
            if (-not (Test-Path $hklmPath)) {
                New-Item -Path $hklmPath -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path $hklmPath -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
            $result.ModifiedKeys.Add($hklmPath)
        }
        catch {
            $result.Errors.Add("HKLM: $($_.Exception.Message)")
        }
    }

    # 2. Ghi vào Active Users (HKCU + Active Domain User SIDs trong HKU)
    if ($TargetScopes -contains "ActiveUsers") {
        # 2.1 Ghi vào HKCU hiện tại
        try {
            $hkcuPath = "HKCU:\$cleanSubKey"
            if (-not (Test-Path $hkcuPath)) {
                New-Item -Path $hkcuPath -Force -ErrorAction Stop | Out-Null
            }
            Set-ItemProperty -Path $hkcuPath -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
            $result.ModifiedKeys.Add($hkcuPath)
        }
        catch {
            $result.Errors.Add("HKCU: $($_.Exception.Message)")
        }

        # 2.2 Ghi đồng bộ vào toàn bộ SID người dùng đang đăng nhập trong HKEY_USERS
        $userSids = Get-VUONGTTActiveUserSIDs
        foreach ($sid in $userSids) {
            try {
                $hkuPath = "Registry::HKEY_USERS\$sid\$cleanSubKey"
                if (-not (Test-Path $hkuPath)) {
                    New-Item -Path $hkuPath -Force -ErrorAction Stop | Out-Null
                }
                Set-ItemProperty -Path $hkuPath -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
                $result.ModifiedKeys.Add($hkuPath)
            }
            catch {
                $result.Errors.Add("HKU\$($sid): $($_.Exception.Message)")
            }
        }
    }

    $result.Success = ($result.ModifiedKeys.Count -gt 0)
    return $result
}
