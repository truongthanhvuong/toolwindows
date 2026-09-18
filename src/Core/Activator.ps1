# VUONGTT Toolkit 2026 - Activation & Crack Cleaner Module

function Invoke-VUONGTTMAS {
    param(
        [string]$Mode = "AIO" # AIO, HWID, Ohook, KMS38
    )
    # Launch MAS official online script in a new elevated PowerShell window
    $cmd = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://get.activated.win | iex"
    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", $cmd
}

function Get-VUONGTTActivationStatus {
    $results = [PSCustomObject]@{
        Windows = "Đang kiểm tra..."
        Office  = "Đang kiểm tra..."
    }

    try {
        $winStatus = (Get-CimInstance SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL" -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*Windows*" } | Select-Object -First 1).LicenseStatus
        $results.Windows = switch ($winStatus) {
            1 { "Đã kích hoạt bản quyền vĩnh viễn (Licensed)" }
            2 { "OOB Grace (Đang trong thời gian ân hạn)" }
            3 { "OOT Grace" }
            4 { "Non-Genuine Grace" }
            5 { "Notification" }
            default { "Chưa kích hoạt hoặc phiên bản dùng thử" }
        }
    } catch {
        $results.Windows = "Không thể kiểm tra qua CIM"
    }

    try {
        $officeFound = $false
        $paths = @(
            "$env:ProgramFiles\Microsoft Office\Office16\OSPP.VBS",
            "${env:ProgramFiles(x86)}\Microsoft Office\Office16\OSPP.VBS",
            "$env:ProgramFiles\Microsoft Office\Office15\OSPP.VBS"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) {
                $officeFound = $true
                $out = cscript //Nologo "$p" /dstatus
                if ($out -match "LICENSE STATUS:\s+---LICENSED---") {
                    $results.Office = "Đã kích hoạt bản quyền (Licensed)"
                } else {
                    $results.Office = "Chưa kích hoạt hoặc bản dùng thử"
                }
                break
            }
        }
        if (-not $officeFound) {
            $results.Office = "Chưa cài đặt Microsoft Office hoặc bản Office 365 App Store"
        }
    } catch {
        $results.Office = "Không thể kiểm tra Office"
    }

    return $results
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
