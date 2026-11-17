# VUONGTT Toolkit 2026 - BitLocker Module

function Get-VUONGTTBitLockerStatus {
    $out = manage-bde -status
    return ($out -join "`n")
}

function Suspend-VUONGTTBitLocker {
    param([string]$Drive = "C:")
    $out = manage-bde -protectors -disable $Drive
    return ($out -join "`n")
}

function Disable-VUONGTTBitLocker {
    param([string]$Drive = "C:")
    $out = manage-bde -off $Drive
    return ($out -join "`n")
}

function Get-VUONGTTBitLockerKey {
    param([string]$Drive = "C:")
    $out = manage-bde -protectors -get $Drive
    return ($out -join "`n")
}

function Enable-VUONGTTBitLocker {
    param(
        [string]$Drive = "C:",
        [string]$Password = ""
    )
    if ($Password) {
        $sec = ConvertTo-SecureString $Password -AsPlainText -Force
        if (Get-Command Enable-BitLocker -ErrorAction SilentlyContinue) {
            Enable-BitLocker -MountPoint $Drive -PasswordProtector -Secret $sec -UsedSpaceOnly -SkipHardwareTest -ErrorAction SilentlyContinue | Out-Null
        } else {
            manage-bde -on $Drive -pw $Password -UsedSpaceOnly
        }
        $out = manage-bde -protectors -add $Drive -RecoveryPassword
    } else {
        $out = manage-bde -on $Drive -UsedSpaceOnly -SkipHardwareTest
        manage-bde -protectors -add $Drive -RecoveryPassword
    }
    return ($out -join "`n")
}

function Unlock-VUONGTTBitLocker {
    param(
        [string]$Drive = "D:",
        [string]$Password = "",
        [string]$RecoveryKey = ""
    )
    if ($Password) {
        $out = manage-bde -unlock $Drive -Password $Password
    } elseif ($RecoveryKey) {
        $out = manage-bde -unlock $Drive -RecoveryPassword $RecoveryKey
    } else {
        $out = manage-bde -unlock $Drive
    }
    return ($out -join "`n")
}

function Resume-VUONGTTBitLocker {
    param([string]$Drive = "C:")
    $out = manage-bde -protectors -enable $Drive
    return ($out -join "`n")
}

function Open-VUONGTTBitLockerCpl {
    Start-Process -FilePath "control.exe" -ArgumentList "/name Microsoft.BitLockerDriveEncryption" -ErrorAction SilentlyContinue
    return "Đã mở Control Panel Quản Trị BitLocker."
}
