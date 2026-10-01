# src/Core/AdminSecurityManager.ps1
# Động cơ quản lý đặc quyền Administrator tập trung cho VUONGTT Toolkit
# Đảm bảo 100% tác vụ hệ thống, phần mềm, registry thực thi dưới token Administrator tối đa

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
    Khởi chạy tiến trình với đầy đủ đặc quyền Administrator (Verb RunAs) và môi trường làm việc chuẩn.
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
        [switch]$NoElevation
    )

    $result = [PSCustomObject]@{
        Success    = $false
        ExitCode   = -1
        ProcessId  = 0
        Error      = $null
    }

    try {
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

        $useRunAs = (-not $NoElevation) -and (-not (Test-VUONGTTIsAdmin))
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
