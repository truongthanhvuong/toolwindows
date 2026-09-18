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
