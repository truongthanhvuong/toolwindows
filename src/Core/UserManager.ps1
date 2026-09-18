# VUONGTT Toolkit 2026 - Windows User Account Manager Module

function Get-SystemUserAccounts {
    [CmdletBinding()]
    param()

    $results = @()

    try {
        # Check Administrators group members
        $adminMembers = @()
        try {
            $admGroup = [ADSI]"WinNT://$env:COMPUTERNAME/Administrators,group"
            $members = @($admGroup.Invoke("Members"))
            foreach ($m in $members) {
                $name = $m.GetType().InvokeMember("Name", 'GetProperty', $null, $m, $null)
                if ($name) { $adminMembers += $name.ToString().ToLower() }
            }
        } catch {
            # Fallback with net localgroup
            $lines = net localgroup administrators 2>$null
            $start = $false
            foreach ($l in $lines) {
                if ($l -like "---*") { $start = $true; continue }
                if ($l -like "*The command completed*" -or $l -like "*Lệnh hoàn thành*") { break }
                if ($start -and -not [string]::IsNullOrWhiteSpace($l)) {
                    $adminMembers += $l.Trim().ToLower()
                }
            }
        }

        # Get local users via ADSI or Get-LocalUser
        $computer = [ADSI]"WinNT://$env:COMPUTERNAME"
        foreach ($child in $computer.Children) {
            if ($child.SchemaClassName -eq "User") {
                $uName = $child.Name.ToString()
                $fullName = try { $child.FullName.ToString() } catch { "" }
                $desc = try { $child.Description.ToString() } catch { "" }
                
                # Check disabled flag: ADS_UF_ACCOUNTDISABLE = 0x0002
                $userFlags = try { $child.UserFlags.Value } catch { 0 }
                $isDisabled = ($userFlags -band 0x0002) -eq 0x0002
                $status = if ($isDisabled) { "Vô hiệu hóa" } else { "Đang hoạt động" }

                $isAdmin = $adminMembers -contains $uName.ToLower()
                $role = if ($isAdmin) { "Quản trị viên (Admin)" } else { "Người dùng thường" }

                $lastLogin = try {
                    $ll = $child.LastLogin.ToString()
                    if ($ll) { $ll } else { "Chưa từng đăng nhập" }
                } catch { "Chưa từng đăng nhập" }

                $results += [PSCustomObject]@{
                    Username    = $uName
                    FullName    = $fullName
                    Role        = $role
                    IsAdmin     = $isAdmin
                    Status      = $status
                    IsEnabled   = (-not $isDisabled)
                    LastLogon   = $lastLogin
                    Description = $desc
                }
            }
        }
    } catch {
        # Fallback if ADSI encounters issue
        $raw = net user 2>$null
        foreach ($r in $raw) {
            if ($r -like "*---*" -or $r -like "*User accounts*" -or $r -like "*The command completed*") { continue }
            $tokens = $r -split '\s+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            foreach ($t in $tokens) {
                $results += [PSCustomObject]@{
                    Username    = $t
                    FullName    = ""
                    Role        = "Local User"
                    IsAdmin     = $false
                    Status      = "Đang hoạt động"
                    IsEnabled   = $true
                    LastLogon   = "N/A"
                    Description = ""
                }
            }
        }
    }

    return $results
}

function New-SystemUserAccount {
    param(
        [string]$Username,
        [string]$Password,
        [bool]$IsAdmin = $false,
        [string]$FullName = "",
        [string]$Description = ""
    )

    if ([string]::IsNullOrWhiteSpace($Username)) {
        return "Lỗi: Tên tài khoản không được để trống!"
    }

    try {
        $pArg = if ($Password) { "`"$Password`"" } else { '""' }
        $out = net user "$Username" $pArg /add 2>&1
        if ($LASTEXITCODE -ne 0) {
            return "Lỗi khi tạo user: $out"
        }

        if ($IsAdmin) {
            net localgroup administrators "$Username" /add 2>&1 | Out-Null
        }

        if ($FullName -or $Description) {
            $user = [ADSI]"WinNT://$env:COMPUTERNAME/$Username,user"
            if ($FullName) { $user.FullName = $FullName }
            if ($Description) { $user.Description = $Description }
            $user.SetInfo()
        }

        return "[OK] Đã tạo thành công tài khoản '$Username' $(if ($IsAdmin) { '(Quyền Administrator)' } else { '' })!"
    } catch {
        return "Lỗi: $($_.Exception.Message)"
    }
}

function Set-SystemUserPassword {
    param(
        [string]$Username,
        [string]$NewPassword
    )

    if ([string]::IsNullOrWhiteSpace($Username)) {
        return "Lỗi: Tên tài khoản không được để trống!"
    }

    try {
        $pArg = if ($NewPassword) { "`"$NewPassword`"" } else { '""' }
        $out = net user "$Username" $pArg 2>&1
        if ($LASTEXITCODE -eq 0) {
            return "[OK] Đã đổi mật khẩu cho tài khoản '$Username' thành công!"
        } else {
            return "Lỗi đổi mật khẩu: $out"
        }
    } catch {
        return "Lỗi: $($_.Exception.Message)"
    }
}

function Set-SystemUserStatus {
    param(
        [string]$Username,
        [bool]$Enable
    )

    try {
        $act = if ($Enable) { "yes" } else { "no" }
        $out = net user "$Username" /active:$act 2>&1
        if ($LASTEXITCODE -eq 0) {
            return "[OK] Đã $(if ($Enable) { 'kích hoạt' } else { 'vô hiệu hóa' }) tài khoản '$Username'!"
        } else {
            return "Lỗi cập nhật trạng thái: $out"
        }
    } catch {
        return "Lỗi: $($_.Exception.Message)"
    }
}

function Set-SystemUserAdmin {
    param(
        [string]$Username,
        [bool]$MakeAdmin
    )

    try {
        if ($MakeAdmin) {
            $out = net localgroup administrators "$Username" /add 2>&1
            return "[OK] Đã cấp quyền Administrator cho '$Username'!"
        } else {
            $out = net localgroup administrators "$Username" /delete 2>&1
            return "[OK] Đã gỡ quyền Administrator của '$Username'!"
        }
    } catch {
        return "Lỗi: $($_.Exception.Message)"
    }
}

function Remove-SystemUserAccount {
    param([string]$Username)

    if ([string]::IsNullOrWhiteSpace($Username)) {
        return "Lỗi: Tên tài khoản không được để trống!"
    }

    try {
        $out = net user "$Username" /delete 2>&1
        if ($LASTEXITCODE -eq 0) {
            return "[OK] Đã xóa tài khoản '$Username' khỏi máy tính!"
        } else {
            return "Lỗi khi xóa tài khoản: $out"
        }
    } catch {
        return "Lỗi: $($_.Exception.Message)"
    }
}

function Set-BuiltinAdminStatus {
    param([bool]$Enable)
    try {
        $act = if ($Enable) { "yes" } else { "no" }
        net user Administrator /active:$act 2>&1 | Out-Null
        return "[OK] Đã $(if ($Enable) { 'bật' } else { 'tắt' }) tài khoản Built-in Administrator!"
    } catch {
        return "Lỗi: $($_.Exception.Message)"
    }
}
