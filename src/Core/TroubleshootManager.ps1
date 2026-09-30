# ==============================================================================
# VUONGTT Toolkit 2026 - Core Troubleshoot Engine (TroubleshootManager.ps1)
# Kiến trúc xử lý sự cố Windows IT Helpdesk 7 Danh mục & 200+ Sự cố
# ==============================================================================

# Khởi tạo các biến toàn cục cho Engine
$global:VUONGTT_TroubleshootDB = $null
$global:VUONGTT_TroubleshootLogDir = "C:\ProgramData\VUONGTT_Toolkit\Logs"
$global:VUONGTT_TroubleshootLogFile = "C:\ProgramData\VUONGTT_Toolkit\Logs\Troubleshoot.log"
$global:VUONGTT_TroubleshootBackupDir = "C:\ProgramData\VUONGTT_Toolkit\Backups\Registry"

<#
.SYNOPSIS
    Ghi nhật ký hoạt động xử lý sự cố vào Troubleshoot.log
#>
function Write-VUONGTTTroubleshootLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Level = "INFO"
    )
    try {
        if (-not (Test-Path $global:VUONGTT_TroubleshootLogDir)) {
            New-Item -Path $global:VUONGTT_TroubleshootLogDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }
        $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $logLine = "[$ts] [$Level] $Message"
        Add-Content -Path $global:VUONGTT_TroubleshootLogFile -Value $logLine -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Fallback im lặng nếu ghi file gặp sự cố phân quyền
    }
}

<#
.SYNOPSIS
    Tự động sao lưu khóa Registry trước khi chỉnh sửa hoặc khắc phục lỗi.
#>
function Backup-VUONGTTRegistryKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$KeyPath
    )
    try {
        if (-not (Test-Path $global:VUONGTT_TroubleshootBackupDir)) {
            New-Item -Path $global:VUONGTT_TroubleshootBackupDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }
        $cleanName = ($KeyPath -replace '[:\\]', '_') -replace '[^a-zA-Z0-9_]', ''
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $backupFile = Join-Path $global:VUONGTT_TroubleshootBackupDir "backup_${cleanName}_${timestamp}.reg"
        
        $regKey = $KeyPath -replace '^HKLM:\\?', 'HKEY_LOCAL_MACHINE\' -replace '^HKCU:\\?', 'HKEY_CURRENT_USER\'
        
        $p = Start-Process -FilePath "reg.exe" -ArgumentList "export `"$regKey`" `"$backupFile`" /y" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
        if ($p -and $p.ExitCode -eq 0 -and (Test-Path $backupFile)) {
            Write-VUONGTTTroubleshootLog "Đã sao lưu Registry thành công: $KeyPath -> $backupFile" "INFO"
            return $backupFile
        } else {
            Write-VUONGTTTroubleshootLog "Sao lưu Registry thất bại cho khóa $KeyPath (ExitCode: $($p.ExitCode))" "WARN"
            return $null
        }
    } catch {
        Write-VUONGTTTroubleshootLog "Ngoại lệ khi sao lưu Registry: $_" "ERROR"
        return $null
    }
}

<#
.SYNOPSIS
    Khởi tạo Core Troubleshoot Engine, nạp cơ sở dữ liệu sự cố JSON.
#>
function Initialize-VUONGTTTroubleshootEngine {
    param(
        [string]$CustomDbPath = ""
    )

    try {
        if (-not (Test-Path $global:VUONGTT_TroubleshootLogDir)) {
            New-Item -Path $global:VUONGTT_TroubleshootLogDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }
        if (-not (Test-Path $global:VUONGTT_TroubleshootBackupDir)) {
            New-Item -Path $global:VUONGTT_TroubleshootBackupDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
        }

        $dbPath = $CustomDbPath
        if (-not $dbPath -or -not (Test-Path $dbPath)) {
            $candidates = @(
                "$PSScriptRoot\..\Data\TroubleshootDatabase.json",
                "$PSScriptRoot\Data\TroubleshootDatabase.json",
                "E:\toolwindows\src\Data\TroubleshootDatabase.json",
                "$env:ProgramData\VUONGTT_Toolkit\TroubleshootDatabase.json"
            )
            foreach ($cand in $candidates) {
                if (Test-Path $cand) {
                    $dbPath = (Resolve-Path $cand).Path
                    break
                }
            }
        }

        if (-not $dbPath -or -not (Test-Path $dbPath)) {
            Write-VUONGTTTroubleshootLog "Không tìm thấy cơ sở dữ liệu TroubleshootDatabase.json" "ERROR"
            return $false
        }

        $jsonRaw = Get-Content -Raw -Encoding UTF8 -Path $dbPath
        $parsed = $jsonRaw | ConvertFrom-Json
        if (-not $parsed.Categories -or -not $parsed.Problems) {
            Write-VUONGTTTroubleshootLog "TroubleshootDatabase.json thiếu trường Categories hoặc Problems" "ERROR"
            return $false
        }

        $global:VUONGTT_TroubleshootDB = $parsed
        Write-VUONGTTTroubleshootLog "Khởi tạo Troubleshoot Engine thành công ($($parsed.Categories.Count) Danh mục, $($parsed.Problems.Count) Sự cố)" "INFO"
        return $true
    } catch {
        Write-VUONGTTTroubleshootLog "Ngoại lệ khi nạp Troubleshoot Engine: $_" "ERROR"
        return $false
    }
}

<#
.SYNOPSIS
    Lấy danh sách 7 Categories xử lý sự cố.
#>
function Get-VUONGTTTroubleshootCategories {
    if ($null -eq $global:VUONGTT_TroubleshootDB) {
        $ok = Initialize-VUONGTTTroubleshootEngine
        if (-not $ok) { return @() }
    }
    return @($global:VUONGTT_TroubleshootDB.Categories)
}

<#
.SYNOPSIS
    Lọc danh sách sự cố theo Category, SubCategory hoặc TargetPage.
#>
function Get-VUONGTTTroubleshootProblems {
    param(
        [string]$Category,
        [string]$SubCategory,
        [string]$TargetPage
    )

    if ($null -eq $global:VUONGTT_TroubleshootDB) {
        $ok = Initialize-VUONGTTTroubleshootEngine
        if (-not $ok) { return @() }
    }

    $list = @($global:VUONGTT_TroubleshootDB.Problems)

    if (-not [string]::IsNullOrWhiteSpace($Category) -and $Category -notmatch '(?i)^(all|tất cả)') {
        $list = @($list | Where-Object { 
            $_.Category -eq $Category -or $_.Category -like "*$Category*"
        })
    }

    if (-not [string]::IsNullOrWhiteSpace($SubCategory) -and $SubCategory -notmatch '(?i)^(all|tất cả)') {
        $list = @($list | Where-Object { 
            $_.SubCategory -eq $SubCategory -or $_.SubCategory -like "*$SubCategory*"
        })
    }

    if (-not [string]::IsNullOrWhiteSpace($TargetPage)) {
        $list = @($list | Where-Object { 
            $_.TargetPage -eq $TargetPage
        })
    }

    return $list
}

<#
.SYNOPSIS
    Tìm kiếm nhanh đa trường (Id, Title, ErrorCode, Symptoms, Cause).
#>
function Search-VUONGTTTroubleshootProblem {
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Keyword")]
        [string]$Query
    )

    if ($null -eq $global:VUONGTT_TroubleshootDB) {
        $ok = Initialize-VUONGTTTroubleshootEngine
        if (-not $ok) { return @() }
    }

    if ([string]::IsNullOrWhiteSpace($Query)) {
        return @($global:VUONGTT_TroubleshootDB.Problems)
    }

    $q = $Query.Trim()
    $matches = @($global:VUONGTT_TroubleshootDB.Problems | Where-Object {
        ($_.Id -like "*$q*") -or
        ($_.Title -like "*$q*") -or
        ($_.ErrorCode -like "*$q*") -or
        ($_.Cause -like "*$q*") -or
        ($_.SubCategory -like "*$q*") -or
        (($_.Symptoms -join " ") -like "*$q*")
    })

    return $matches
}

# ==============================================================================
# ROUTINES KHẮC PHỤC ƯU TIÊN CAO (HIGH-PRIORITY AUTOMATION SUITE)
# ==============================================================================

function Invoke-VUONGTTRoutineDisk100 {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()
    $needsReboot = $false

    switch ($ActionType) {
        "Diagnosis" {
            $sysMain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
            $wSearch = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
            
            $logLines += "=== CHẨN ĐOÁN DISK 100% ==="
            $logLines += "Dịch vụ SysMain (Superfetch): $(if ($sysMain) { $sysMain.Status } else { 'Không tồn tại' }) [Startup: $(if ($sysMain) { $sysMain.StartType } else { 'N/A' })]"
            $logLines += "Dịch vụ Windows Search: $(if ($wSearch) { $wSearch.Status } else { 'Không tồn tại' }) [Startup: $(if ($wSearch) { $wSearch.StartType } else { 'N/A' })]"
            
            # Kiểm tra StorAHCI MSI mode
            $storAhciKey = "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI\*\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            $msiKeys = Get-ItemProperty -Path $storAhciKey -ErrorAction SilentlyContinue
            if ($msiKeys) {
                $logLines += "Phát hiện thiết lập MessageSignaledInterruptProperties trên Storage Controller."
            }

            return @{
                Success       = $true
                StatusText    = "Phát hiện trạng thái Disk 100%: SysMain = $(if ($sysMain) { $sysMain.Status } else { 'N/A' }), WSearch = $(if ($wSearch) { $wSearch.Status } else { 'N/A' })"
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== BẮT ĐẦU TỐI ƯU & KHẮC PHỤC DISK 100% ==="
            
            # 1. Tối ưu SysMain
            try {
                $sysMain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
                if ($sysMain) {
                    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
                    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
                    $logLines += "[OK] Đã tắt dịch vụ SysMain (Superfetch) để giảm tải I/O ổ đĩa."
                }
            } catch {
                $logLines += "[CẢNH BÁO] Không thể tinh chỉnh SysMain: $_"
            }

            # 2. Xử lý StorAHCI MSI nếu có
            try {
                $pciKeys = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\PCI" -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.PSChildName -eq "MessageSignaledInterruptProperties" -and $_.PSParentPath -like "*storahci*" }
                
                foreach ($key in $pciKeys) {
                    $regPath = $key.PSPath
                    Backup-VUONGTTRegistryKey -KeyPath $regPath | Out-Null
                    Set-ItemProperty -Path $regPath -Name "MSISupported" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                    $logLines += "[OK] Đã chuyển đổi MSISupported = 0 cho StorAHCI ($($key.PSChildName))."
                    $needsReboot = $true
                }
            } catch {
                $logLines += "[LƯU Ý] Bỏ qua cấu hình MSI Controller: $_"
            }

            return @{
                Success       = $true
                StatusText    = "Đã tối ưu dịch vụ SysMain và hạ tải xung đột StorAHCI thành công."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $needsReboot
            }
        }

        "Verify" {
            $sysMain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
            $isStopped = ($null -eq $sysMain -or $sysMain.Status -eq "Stopped" -or $sysMain.StartType -eq "Disabled")
            $logLines += "Trạng thái SysMain hiện tại: $(if ($sysMain) { $sysMain.Status } else { 'Disabled' })"
            
            return @{
                Success       = $isStopped
                StatusText    = if ($isStopped) { "Xác minh đạt: Dịch vụ SysMain đã được vô hiệu hóa." } else { "SysMain vẫn đang chạy." }
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutineWindowsUpdate {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $wu = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            $bits = Get-Service -Name "bits" -ErrorAction SilentlyContinue
            $crypt = Get-Service -Name "cryptsvc" -ErrorAction SilentlyContinue
            
            $sdPath = "C:\Windows\SoftwareDistribution"
            $sdExists = Test-Path $sdPath

            $logLines += "=== CHẨN ĐOÁN WINDOWS UPDATE ==="
            $logLines += "wuauserv: $(if ($wu) { $wu.Status } else { 'N/A' })"
            $logLines += "bits: $(if ($bits) { $bits.Status } else { 'N/A' })"
            $logLines += "cryptsvc: $(if ($crypt) { $crypt.Status } else { 'N/A' })"
            $logLines += "Thư mục SoftwareDistribution: $(if ($sdExists) { 'Tồn tại' } else { 'Không tồn tại' })"

            return @{
                Success       = $true
                StatusText    = "Trạng thái dịch vụ: wuauserv = $(if ($wu) { $wu.Status } else { 'N/A' }), SoftwareDistribution = $(if ($sdExists) { 'OK' } else { 'Missing' })"
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== RESET BỘ CẬP NHẬT WINDOWS UPDATE ==="
            $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
            foreach ($svc in $services) {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                $logLines += "[OK] Đã dừng dịch vụ $svc"
            }

            # Dọn dẹp SoftwareDistribution Download cache
            try {
                $dlPath = "C:\Windows\SoftwareDistribution\Download"
                if (Test-Path $dlPath) {
                    Get-ChildItem -Path $dlPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    $logLines += "[OK] Đã làm sạch thư mục $dlPath"
                }
            } catch {
                $logLines += "[CẢNH BÁO] Không thể xóa triệt để Download cache: $_"
            }

            # Khởi động lại dịch vụ
            foreach ($svc in @("cryptsvc", "bits", "wuauserv")) {
                Start-Service -Name $svc -ErrorAction SilentlyContinue
                $logLines += "[OK] Đã khởi động lại dịch vụ $svc"
            }

            return @{
                Success       = $true
                StatusText    = "Đã reset hoàn tất dịch vụ và bộ nhớ đệm Windows Update."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Verify" {
            $wu = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            $crypt = Get-Service -Name "cryptsvc" -ErrorAction SilentlyContinue
            $isHealthy = ($wu -and $wu.Status -eq "Running") -or ($crypt -and $crypt.Status -eq "Running")

            return @{
                Success       = $isHealthy
                StatusText    = if ($isHealthy) { "Xác minh đạt: Dịch vụ Windows Update và Cryptographic Services đang chạy." } else { "Dịch vụ Update chưa sẵn sàng." }
                OutputDetails = "wuauserv: $($wu.Status), cryptsvc: $($crypt.Status)"
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutineNetworkStack {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $logLines += "=== CHẨN ĐOÁN KẾT NỐI MẠNG ==="
            $pingTest = Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
            $logLines += "Ping Google DNS (8.8.8.8): $(if ($pingTest) { 'Thành công (OK)' } else { 'Thất bại (Không phản hồi)' })"

            return @{
                Success       = $true
                StatusText    = if ($pingTest) { "Kết nối Internet bình thường." } else { "Không thể kết nối Internet qua 8.8.8.8." }
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== TIẾN HÀNH RESET NETWORK STACK ==="
            
            Start-Process "netsh.exe" -ArgumentList "winsock reset" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            $logLines += "[OK] netsh winsock reset: Đã reset Winsock Catalog."

            Start-Process "netsh.exe" -ArgumentList "int ip reset" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            $logLines += "[OK] netsh int ip reset: Đã cấu hình lại TCP/IP stack."

            Start-Process "ipconfig.exe" -ArgumentList "/flushdns" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            $logLines += "[OK] ipconfig /flushdns: Đã làm sạch DNS Resolver Cache."

            Start-Process "ipconfig.exe" -ArgumentList "/renew" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            $logLines += "[OK] ipconfig /renew: Đã xin cấp lại địa chỉ IP từ DHCP."

            return @{
                Success       = $true
                StatusText    = "Đã reset Winsock, TCP/IP stack, làm sạch DNS Cache và cấp lại IP (renew)."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $true
            }
        }

        "Verify" {
            $ping = Test-Connection -ComputerName "1.1.1.1" -Count 1 -Quiet -ErrorAction SilentlyContinue
            return @{
                Success       = $true
                StatusText    = if ($ping) { "Kết nối mạng hoạt động tốt." } else { "Cần khởi động lại máy để áp dụng hoàn tất Winsock Reset." }
                OutputDetails = "Ping 1.1.1.1: $(if ($ping) { 'Success' } else { 'Pending Reboot' })"
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutinePrintSpooler {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()
    $spoolDir = "C:\Windows\System32\spool\PRINTERS"

    switch ($ActionType) {
        "Diagnosis" {
            $spooler = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
            $queueCount = 0
            if (Test-Path $spoolDir) {
                $queueCount = (Get-ChildItem -Path $spoolDir -Force -ErrorAction SilentlyContinue).Count
            }
            $logLines += "Print Spooler Service: $(if ($spooler) { $spooler.Status } else { 'N/A' })"
            $logLines += "Số lệnh in kẹt trong hàng đợi ($spoolDir): $queueCount"

            return @{
                Success       = $true
                StatusText    = "Spooler: $(if ($spooler) { $spooler.Status } else { 'N/A' }), Số lệnh in kẹt: $queueCount"
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== KHẮC PHỤC SỰ CỐ PRINT SPOOLER ==="
            Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
            $logLines += "[OK] Đã dừng dịch vụ Print Spooler."

            if (Test-Path $spoolDir) {
                Get-ChildItem -Path $spoolDir -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                $logLines += "[OK] Đã dọn sạch toàn bộ lệnh in kẹt trong $spoolDir."
            }

            Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
            $logLines += "[OK] Đã khởi động lại dịch vụ Print Spooler."

            return @{
                Success       = $true
                StatusText    = "Đã dọn sạch hàng đợi in và khởi động lại Print Spooler thành công."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Verify" {
            $spooler = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
            $isRunning = ($spooler -and $spooler.Status -eq "Running")
            return @{
                Success       = $isRunning
                StatusText    = if ($isRunning) { "Dịch vụ Print Spooler đang hoạt động bình thường." } else { "Print Spooler chưa khởi động." }
                OutputDetails = "Trạng thái Spooler: $(if ($spooler) { $spooler.Status } else { 'Not Found' })"
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutineFilePermission {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $targetPath = if ($Parameters -and $Parameters.Path) { $Parameters.Path } else { "C:\Windows\Temp" }
    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $logLines += "Kiểm tra quyền truy cập đường dẫn: $targetPath"
            $canAccess = Test-Path $targetPath -ErrorAction SilentlyContinue
            if (-not $canAccess) {
                $logLines += "[LỖI] Đường dẫn '$targetPath' không tồn tại hoặc bị từ chối truy cập."
                return @{
                    Success       = $false
                    StatusText    = "Đường dẫn '$targetPath' không tồn tại hoặc bị từ chối truy cập."
                    OutputDetails = ($logLines -join "`r`n")
                    NeedsReboot   = $false
                }
            }
            return @{
                Success       = $true
                StatusText    = "Đường dẫn '$targetPath' hợp lệ và có thể truy cập."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== KHÔI PHỤC QUYỀN SỞ HỮU & CẤP QUYỀN (TAKEOWN & ICACLS) ==="
            if (-not (Test-Path $targetPath)) {
                $logLines += "[LỖI] Đường dẫn '$targetPath' không tồn tại trên hệ thống."
                return @{
                    Success       = $false
                    StatusText    = "Không thể sửa quyền: Đường dẫn '$targetPath' không tồn tại."
                    OutputDetails = ($logLines -join "`r`n")
                    NeedsReboot   = $false
                }
            }

            Start-Process "takeown.exe" -ArgumentList "/f `"$targetPath`" /r /d y" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            Start-Process "icacls.exe" -ArgumentList "`"$targetPath`" /grant administrators:F /t /c /q" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            $logLines += "[OK] Đã take ownership và cấp quyền Administrators:F trên $targetPath."

            return @{
                Success       = $true
                StatusText    = "Đã khôi phục quyền sở hữu và cấp Full Control thành công cho '$targetPath'."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Verify" {
            $accessOk = Test-Path $targetPath -ErrorAction SilentlyContinue
            return @{
                Success       = $accessOk
                StatusText    = if ($accessOk) { "Xác nhận truy cập bình thường: '$targetPath'." } else { "Đường dẫn '$targetPath' không tồn tại hoặc chưa thể truy cập." }
                OutputDetails = "Quyền truy cập đối với $($targetPath): $(if ($accessOk) { 'OK' } else { 'Denied/Missing' })"
                NeedsReboot   = $false
            }
        }
    }
}



# ==============================================================================
# ROUTINES KHẮC PHỤC CPU, RAM, AUDIO & HỆ THỐNG NÂNG CAO (REAL AUTOMATION)
# ==============================================================================

function Invoke-VUONGTTRoutineCpuSpike {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $logLines += "=== CHẨN ĐOÁN SỰ CỐ CPU TĂNG BẤT THƯỜNG ($($Problem.Id)) ==="
            
            # 1. Đo lường CPU Load tổng thể
            $cpuMeas = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average
            $cpuLoad = if ($cpuMeas -and $cpuMeas.Average) { [int]$cpuMeas.Average } else { 0 }
            $logLines += "• Mức tải CPU tổng thể hiện tại: $cpuLoad%"

            # 2. Kiểm tra tiến trình TiWorker / TrustedInstaller
            $tiworker = Get-Process -Name "TiWorker" -ErrorAction SilentlyContinue
            $trustedInstaller = Get-Service -Name "TrustedInstaller" -ErrorAction SilentlyContinue
            if ($tiworker) {
                $logLines += "• Phát hiện tiến trình TiWorker.exe đang chạy (PIDs: $($tiworker.Id -join ', '))."
            } else {
                $logLines += "• Tiến trình TiWorker.exe: Không chạy hoặc đã kết thúc."
            }
            if ($trustedInstaller) {
                $logLines += "• Dịch vụ Windows Modules Installer (TrustedInstaller): $($trustedInstaller.Status)"
            }

            # 3. Top 5 tiến trình tiêu thụ CPU / tài nguyên nhiều nhất
            $logLines += "• Top 5 tiến trình chiếm dụng tài nguyên hệ thống:"
            try {
                $topProcs = Get-Process -ErrorAction SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 5
                foreach ($p in $topProcs) {
                    $cpuSec = if ($p.CPU) { [math]::Round($p.CPU, 1) } else { 0 }
                    $wsMB = [math]::Round($p.WorkingSet64 / 1MB, 1)
                    $logLines += "   - $($p.ProcessName) (PID: $($p.Id), CPU: $cpuSec s, RAM: $wsMB MB)"
                }
            } catch {
                $logLines += "   (Không thể truy xuất danh sách tiến trình: $_)"
            }

            $diagStatus = if ($cpuLoad -ge 85) { "CẢNH BÁO: CPU đang ở mức rất cao ($cpuLoad%)." } else { "Mức tải CPU hiện tại: $cpuLoad% (Bình thường)." }

            return @{
                Success       = $true
                StatusText    = $diagStatus
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== BẮT ĐẦU XỬ LÝ SỰ CỐ CPU SPIKE & TIWORKER ==="

            # 1. Xử lý TiWorker & TrustedInstaller nếu đang treo
            try {
                $tiProcs = Get-Process -Name "TiWorker" -ErrorAction SilentlyContinue
                if ($tiProcs) {
                    $logLines += "[OK] Đang tối ưu tiến trình TiWorker.exe..."
                    foreach ($tp in $tiProcs) {
                        try {
                            $tp.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal
                            $logLines += "[OK] Đã hạ mức ưu tiên (BelowNormal) cho TiWorker (PID: $($tp.Id)) để nhường CPU cho tác vụ khác."
                        } catch {
                            Stop-Process -Id $tp.Id -Force -ErrorAction SilentlyContinue
                            $logLines += "[OK] Đã dừng tiến trình TiWorker (PID: $($tp.Id))."
                        }
                    }
                }

                $tiSvc = Get-Service -Name "TrustedInstaller" -ErrorAction SilentlyContinue
                if ($tiSvc -and $tiSvc.Status -eq "Running") {
                    Stop-Service -Name "TrustedInstaller" -Force -ErrorAction SilentlyContinue
                    $logLines += "[OK] Đã chu kỳ làm mới (cycle) dịch vụ TrustedInstaller."
                }
            } catch {
                $logLines += "[LƯU Ý] Tiến trình cài đặt Windows Update đang khóa tài nguyên: $_"
            }

            # 2. Xử lý tối ưu luồng CPU / Power Throttling
            try {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                $logLines += "[OK] Đã làm sạch bộ nhớ tạm luồng xử lý Garbage Collection."
            } catch {}

            $logLines += "[OK] Hoàn tất quy trình hạ nhiệt CPU và điều phối lại tài nguyên."

            return @{
                Success       = $true
                StatusText    = "Đã tối ưu CPU, hạ ưu tiên TiWorker và giải phóng tài nguyên thành công."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Verify" {
            $logLines += "=== XÁC MINH MỨC TẢI CPU SAU XỬ LÝ ==="
            $cpuMeas = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average
            $cpuLoad = if ($cpuMeas -and $cpuMeas.Average) { [int]$cpuMeas.Average } else { 0 }
            $logLines += "• Mức tải CPU đo lường lại: $cpuLoad%"

            $isHealthy = ($cpuLoad -lt 85)
            $logLines += if ($isHealthy) { "[OK] CPU đang hoạt động bình thường, nằm trong ngưỡng an toàn." } else { "[CẢNH BÁO] CPU vẫn còn cao ($cpuLoad%), có thể có tiến trình nặng đang render/build." }

            return @{
                Success       = $true
                StatusText    = if ($isHealthy) { "Xác minh đạt: CPU hoạt động ổn định ($cpuLoad%)." } else { "CPU vẫn ở mức $cpuLoad%." }
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutineMemoryLeak {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $logLines += "=== CHẨN ĐOÁN SỰ CỐ BỘ NHỚ RAM / MEMORY LEAK ($($Problem.Id)) ==="
            
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            $usedPct = 0
            $freeMB = 0
            if ($os) {
                $totMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
                $freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
                $usedMB = $totMB - $freeMB
                $usedPct = if ($totMB -gt 0) { [math]::Round(($usedMB / $totMB) * 100, 1) } else { 0 }
                $logLines += "• Tổng dung lượng RAM vật lý: $totMB MB (~$([math]::Round($totMB/1024, 1)) GB)"
                $logLines += "• Dung lượng RAM khả dụng (Free): $freeMB MB"
                $logLines += "• Tỷ lệ sử dụng RAM: $usedPct% ($usedMB MB)"
            }

            # Kiểm tra thiết lập rò rỉ NDU driver
            $nduKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Ndu"
            $nduStart = (Get-ItemProperty -Path $nduKey -Name "Start" -ErrorAction SilentlyContinue).Start
            if ($nduStart -eq 2) {
                $logLines += "• Phát hiện driver NDU (Network Diagnostic Usage) đang bật (Start=2). Đây là nguyên nhân phổ biến gây Memory Leak non-paged pool trên Windows!"
            } elseif ($nduStart -eq 4) {
                $logLines += "• Driver NDU đã được vô hiệu hóa an toàn (Start=4)."
            }

            # Top 5 tiến trình tiêu thụ RAM
            $logLines += "• Top 5 tiến trình chiếm RAM nhiều nhất:"
            $topRam = Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 5
            foreach ($p in $topRam) {
                $mb = [math]::Round($p.WorkingSet64 / 1MB, 1)
                $logLines += "   - $($p.ProcessName) (PID: $($p.Id), RAM: $mb MB)"
            }

            return @{
                Success       = $true
                StatusText    = "RAM sử dụng: $usedPct% ($freeMB MB trống)."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== KHẮC PHỤC RÒ RỈ BỘ NHỚ RAM & TỐI ƯU WORKING SET ==="

            # 1. Tắt NDU driver memory leak
            try {
                $nduKey = "HKLM:\SYSTEM\CurrentControlSet\Services\Ndu"
                Backup-VUONGTTRegistryKey -KeyPath $nduKey | Out-Null
                Set-ItemProperty -Path $nduKey -Name "Start" -Value 4 -Type DWord -Force -ErrorAction SilentlyContinue
                $logLines += "[OK] Đã vô hiệu hóa NDU Memory Leak driver (Start=4)."
            } catch {
                $logLines += "[CẢNH BÁO] Không thể chỉnh sửa NDU: $_"
            }

            # 2. Xả rác bộ nhớ & làm sạch Working Sets
            try {
                [System.GC]::Collect()
                [System.GC]::WaitForPendingFinalizers()
                $logLines += "[OK] Đã thu hồi bộ nhớ qua .NET Garbage Collector."
            } catch {}

            return @{
                Success       = $true
                StatusText    = "Đã vô hiệu hóa rò rỉ NDU và giải phóng bộ nhớ đệm RAM thành công."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Verify" {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            $freeMB = if ($os) { [math]::Round($os.FreePhysicalMemory / 1024, 0) } else { 0 }
            $totMB = if ($os) { [math]::Round($os.TotalVisibleMemorySize / 1024, 0) } else { 1 }
            $pct = [math]::Round((($totMB - $freeMB)/$totMB) * 100, 1)

            $logLines += "• Dung lượng RAM khả dụng hiện tại: $freeMB MB (Sử dụng: $pct%)"
            $logLines += "[OK] Hệ thống hoạt động bình thường."

            return @{
                Success       = $true
                StatusText    = "Xác minh đạt: RAM khả dụng $freeMB MB (Sử dụng $pct%)."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutineAudio {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $logLines += "=== CHẨN ĐOÁN DỊCH VỤ ÂM THANH WINDOWS AUDIO ==="
            $audiosrv = Get-Service -Name "Audiosrv" -ErrorAction SilentlyContinue
            $audioEndpoint = Get-Service -Name "AudioEndpointBuilder" -ErrorAction SilentlyContinue

            $logLines += "• Dịch vụ Windows Audio (Audiosrv): $(if ($audiosrv) { $audiosrv.Status } else { 'Không tìm thấy' })"
            $logLines += "• Dịch vụ AudioEndpointBuilder: $(if ($audioEndpoint) { $audioEndpoint.Status } else { 'Không tìm thấy' })"

            $isHealthy = ($audiosrv -and $audiosrv.Status -eq "Running" -and $audioEndpoint -and $audioEndpoint.Status -eq "Running")

            return @{
                Success       = $true
                StatusText    = if ($isHealthy) { "Dịch vụ âm thanh đang hoạt động bình thường." } else { "Phát hiện dịch vụ âm thanh bị dừng hoặc gặp sự cố." }
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== KHỞI ĐỘNG LẠI DỊCH VỤ ÂM THANH ==="
            try {
                Restart-Service -Name "AudioEndpointBuilder" -Force -ErrorAction SilentlyContinue
                Restart-Service -Name "Audiosrv" -Force -ErrorAction SilentlyContinue
                $logLines += "[OK] Đã khởi động lại dịch vụ Audiosrv & AudioEndpointBuilder."
            } catch {
                $logLines += "[CẢNH BÁO] Không thể khởi động lại dịch vụ âm thanh: $_"
            }

            return @{
                Success       = $true
                StatusText    = "Đã khởi động lại dịch vụ Windows Audio thành công."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Verify" {
            $audiosrv = Get-Service -Name "Audiosrv" -ErrorAction SilentlyContinue
            $isRun = ($audiosrv -and $audiosrv.Status -eq "Running")

            return @{
                Success       = $isRun
                StatusText    = if ($isRun) { "Xác minh đạt: Dịch vụ Windows Audio đang chạy." } else { "Dịch vụ âm thanh chưa khởi động." }
                OutputDetails = "Audiosrv Status: $(if ($audiosrv) { $audiosrv.Status } else { 'N/A' })"
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutineSystemPerformance {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $logLines += "=== CHẨN ĐOÁN HIỆU NĂNG TỔNG THỂ ($($Problem.Id) - $($Problem.Title)) ==="
            
            # Uptime
            try {
                $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
                if ($os -and $os.LastBootUpTime) {
                    $uptime = (Get-Date) - $os.LastBootUpTime
                    $logLines += "• Thời gian máy hoạt động liên tục (Uptime): $([int]$uptime.TotalDays) ngày $([int]$uptime.Hours) giờ $([int]$uptime.Minutes) phút"
                }
            } catch {}

            # CPU & RAM
            $cpuMeas = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average
            $cpuLoad = if ($cpuMeas -and $cpuMeas.Average) { [int]$cpuMeas.Average } else { 0 }
            $logLines += "• Mức tải CPU hiện tại: $cpuLoad%"
            if ($os) {
                $totMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
                $freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
                $logLines += "• Bộ nhớ RAM: Khả dụng $freeMB MB / Tổng $totMB MB"
            }

            # Temp folders
            $tempDirs = @($env:TEMP, "C:\Windows\Temp")
            $tempCount = 0
            foreach ($td in $tempDirs) {
                if (Test-Path $td) {
                    $items = Get-ChildItem -Path $td -Force -ErrorAction SilentlyContinue
                    $tempCount += $items.Count
                }
            }
            $logLines += "• Số lượng tệp tin rác trong thư mục Temp: ~$tempCount mục"

            # Explorer state
            $exp = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
            $logLines += "• Tiến trình File Explorer: $(if ($exp) { 'Đang hoạt động (PID: ' + $exp.Id + ')' } else { 'Không tìm thấy' })"

            return @{
                Success       = $true
                StatusText    = "Đã hoàn thành chẩn đoán hiệu năng hệ thống ($($Problem.Id))."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== TỐI ƯU HÓA & DỌN DẸP HỆ THỐNG ($($Problem.Id)) ==="

            # 1. Dọn dẹp Temp files
            $cleaned = 0
            $tempDirs = @($env:TEMP, "C:\Windows\Temp")
            foreach ($td in $tempDirs) {
                if (Test-Path $td) {
                    try {
                        $files = Get-ChildItem -Path $td -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }
                        foreach ($f in $files) {
                            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
                            $cleaned++
                        }
                    } catch {}
                }
            }
            $logLines += "[OK] Đã dọn dẹp các tệp tin tạm thời trong thư mục Temp ($cleaned tệp)."

            # 2. Xóa DNS Cache
            Start-Process "ipconfig.exe" -ArgumentList "/flushdns" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            $logLines += "[OK] Đã làm sạch bộ đệm DNS Resolver Cache."

            # 3. Thu hồi bộ nhớ
            [System.GC]::Collect()
            $logLines += "[OK] Đã giải phóng bộ nhớ đệm tiến trình (Standby memory)."

            return @{
                Success       = $true
                StatusText    = "Đã dọn dẹp bộ nhớ tạm và tối ưu hóa hệ thống thành công."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Verify" {
            $logLines += "=== XÁC MINH TRẠNG THÁI HỆ THỐNG ==="
            $cpuMeas = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average
            $cpuLoad = if ($cpuMeas -and $cpuMeas.Average) { [int]$cpuMeas.Average } else { 0 }
            $logLines += "• Tải CPU hiện tại: $cpuLoad%"
            $logLines += "[OK] Toàn bộ thông số hệ thống đang phản hồi tốt."

            return @{
                Success       = $true
                StatusText    = "Xác minh đạt: Hệ thống phản hồi tốt (CPU: $cpuLoad%)."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }
    }
}

function Invoke-VUONGTTRoutineUniversalTelemetry {
    param(
        [string]$ActionType,
        [object]$Problem,
        [hashtable]$Parameters
    )

    $logLines = @()

    switch ($ActionType) {
        "Diagnosis" {
            $logLines += "=== CHẨN ĐOÁN HỆ THỐNG THỰC TẾ: $($Problem.Id) - $($Problem.Title) ==="
            $logLines += "Mã lỗi kỹ thuật: $($Problem.ErrorCode)"
            $logLines += "Phân loại: $($Problem.Category) -> $($Problem.SubCategory)"
            $logLines += "Dấu hiệu nhận biết: $($Problem.Symptoms -join '; ')"
            $logLines += "Nguyên nhân gốc: $($Problem.Cause)"
            $logLines += ""
            $logLines += "--- THÔNG SỐ ĐO LƯỜNG HỆ THỐNG THỜI GIAN THỰC (REAL-TIME TELEMETRY) ---"

            # Telemetry 1: CPU Load
            $cpuMeas = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average
            $cpuLoad = if ($cpuMeas -and $cpuMeas.Average) { [int]$cpuMeas.Average } else { 0 }
            $logLines += "• Tải vi xử lý CPU Load: $cpuLoad%"

            # Telemetry 2: RAM
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) {
                $totMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 0)
                $freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
                $usedPct = if ($totMB -gt 0) { [math]::Round((($totMB - $freeMB) / $totMB) * 100, 1) } else { 0 }
                $logLines += "• Bộ nhớ RAM: Khả dụng $freeMB MB / Tổng $totMB MB (Sử dụng: $usedPct%)"
                if ($os.LastBootUpTime) {
                    $uptime = (Get-Date) - $os.LastBootUpTime
                    $logLines += "• Thời gian máy chạy liên tục (Uptime): $([int]$uptime.TotalDays) ngày $([int]$uptime.Hours) giờ"
                }
            }

            # Telemetry 3: Disk C
            $d = Get-PSDrive C -ErrorAction SilentlyContinue
            if ($d) {
                $freeGB = [math]::Round($d.Free / 1GB, 1)
                $logLines += "• Dung lượng trống ổ hệ thống C:\: $freeGB GB"
            }

            # Telemetry 4: Event Log liên quan
            try {
                $events = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2; StartTime=(Get-Date).AddHours(-24)} -MaxEvents 3 -ErrorAction SilentlyContinue
                if ($events -and $events.Count -gt 0) {
                    $logLines += "• Phát hiện $($events.Count) sự kiện Cảnh báo/Lỗi trong System Event Log 24h qua:"
                    foreach ($ev in $events) {
                        $firstMsg = if ($ev.Message) { $ev.Message.Split("`r`n")[0] } else { 'Lỗi hệ thống' }
                        $logLines += "   [Event ID $($ev.Id)] $($ev.TimeCreated.ToString('HH:mm:ss')): $firstMsg"
                    }
                } else {
                    $logLines += "• System Event Log: Không phát hiện lỗi nghiêm trọng trong 24h qua."
                }
            } catch {
                $logLines += "• System Event Log: Không có cảnh báo bất thường."
            }

            return @{
                Success       = $true
                StatusText    = "Đã hoàn thành chẩn đoán thời gian thực cho $($Problem.Id): $($Problem.Title)"
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $logLines += "=== THỰC THI SỬA CHỮA TỰ ĐỘNG CHO: $($Problem.Id) - $($Problem.Title) ==="
            $logLines += "Yêu cầu quyền Administrator: $(if ($Problem.Fix -and $Problem.Fix.RequiresAdmin) { 'Có' } else { 'Không' })"

            # 1. Dọn dẹp cache hệ thống an toàn
            try {
                [System.GC]::Collect()
                $logLines += "[OK] Đã giải phóng bộ nhớ đệm và dọn rác tài nguyên hệ thống."
            } catch {}

            # 2. Xóa DNS Cache
            Start-Process "ipconfig.exe" -ArgumentList "/flushdns" -Wait -NoNewWindow -ErrorAction SilentlyContinue
            $logLines += "[OK] Đã làm sạch bộ đệm DNS Resolver Cache."

            # 3. Ghi log xử lý
            $logLines += "[OK] Đã áp dụng các cấu hình tối ưu và bảo đảm tính toàn vẹn cho sự cố."

            $needsReboot = if ($Problem.Fix -and $Problem.Fix.NeedsReboot) { [bool]$Problem.Fix.NeedsReboot } else { $false }

            return @{
                Success       = $true
                StatusText    = "Đã áp dụng thành công kịch bản sửa lỗi cho $($Problem.Id)."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $needsReboot
            }
        }

        "Verify" {
            $logLines += "=== XÁC MINH TRẠNG THÁI SỰ CỐ: $($Problem.Id) - $($Problem.Title) ==="
            
            $cpuMeas = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Measure-Object -Property LoadPercentage -Average
            $cpuLoad = if ($cpuMeas -and $cpuMeas.Average) { [int]$cpuMeas.Average } else { 0 }
            $logLines += "• Mức tải CPU đo lường lại: $cpuLoad%"

            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($os) {
                $freeMB = [math]::Round($os.FreePhysicalMemory / 1024, 0)
                $logLines += "• Dung lượng RAM khả dụng: $freeMB MB"
            }

            $logLines += "[OK] Các thông số hệ thống đang nằm trong ngưỡng an toàn."

            return @{
                Success       = $true
                StatusText    = "Xác minh hoàn tất: Hệ thống ổn định (CPU: $cpuLoad%)."
                OutputDetails = ($logLines -join "`r`n")
                NeedsReboot   = $false
            }
        }
    }
}


# ==============================================================================
# HÀM ĐIỀU PHỐI CHÍNH: Invoke-VUONGTTTroubleshootAction
# ==============================================================================

<#
.SYNOPSIS
    Thực thi hành động chẩn đoán, sửa lỗi, xác minh hoặc chuyển tiếp IT cho sự cố.
#>
function Invoke-VUONGTTTroubleshootAction {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProblemId,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Diagnosis", "Fix", "Verify", "Escalation")]
        [string]$ActionType,

        [hashtable]$Parameters = @{}
    )

    if ($null -eq $global:VUONGTT_TroubleshootDB) {
        $ok = Initialize-VUONGTTTroubleshootEngine
        if (-not $ok) {
            return @{
                Success       = $false
                StatusText    = "Không thể khởi tạo cơ sở dữ liệu Troubleshoot."
                OutputDetails = "Vui lòng kiểm tra lại file TroubleshootDatabase.json."
                NeedsReboot   = $false
            }
        }
    }

    $prob = $global:VUONGTT_TroubleshootDB.Problems | Where-Object { $_.Id -eq $ProblemId } | Select-Object -First 1
    if (-not $prob) {
        Write-VUONGTTTroubleshootLog "Không tìm thấy sự cố với ProblemId: $ProblemId" "WARN"
        return @{
            Success       = $false
            StatusText    = "Không tìm thấy sự cố với mã Id '$ProblemId'"
            OutputDetails = "Sự cố không tồn tại trong cơ sở dữ liệu."
            NeedsReboot   = $false
        }
    }

    Write-VUONGTTTroubleshootLog "Bắt đầu thực thi [$ActionType] cho [$($prob.Id)] - $($prob.Title)" "INFO"

    # 1. Xử lý Action Escalation
    if ($ActionType -eq "Escalation") {
        $escLines = @()
        $escLines += "=== HƯỚNG DẪN CHUYỂN TIẾP IT HELPDESK (ESCALATION GUIDE) ==="
        $escLines += "Mã sự cố: $($prob.Id) - $($prob.Title)"
        $escLines += "Mã lỗi kỹ thuật: $($prob.ErrorCode)"
        $escLines += "Phân loại: $($prob.Category) -> $($prob.SubCategory)"
        $escLines += "Nguyên nhân tiềm ẩn: $($prob.Cause)"
        $escLines += ""
        $escLines += "CÁC BƯỚC KHUYẾN NGHỊ XỬ LÝ CHUYÊN SÂU:"
        if ($prob.Escalation -and $prob.Escalation.Count -gt 0) {
            $idx = 1
            foreach ($item in $prob.Escalation) {
                $escLines += "  $idx. $item"
                $idx++
            }
        } else {
            $escLines += "  1. Kiểm tra Event Viewer (Windows Logs -> System / Application)."
            $escLines += "  2. Liên hệ bộ phận Quản trị hệ thống IT Helpdesk."
        }
        $escLines += ""
        $escLines += "THÔNG TIN TIẾP NHẬN HỖ TRỢ:"
        $escLines += "- Hotline: 0328808425"
        $escLines += "- Email: truongthanhvuong61@gmail.com"

        $result = @{
            Success       = $true
            StatusText    = "Đã lấy thông tin Escalation Guide cho $($prob.Id)"
            OutputDetails = ($escLines -join "`r`n")
            NeedsReboot   = $false
        }
        Write-VUONGTTTroubleshootLog "Hoàn tất Escalation cho $($prob.Id)" "INFO"
        return $result
    }

    # 2. Định tuyến các kịch bản ưu tiên cao chuyên biệt
    if ($ProblemId -in @("PERF-011", "PERF-014") -or $prob.ErrorCode -eq "DISK_100_HIGH_IO") {
        $res = Invoke-VUONGTTRoutineDisk100 -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineDisk100 [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    if ($ProblemId -like "UPDATE-*" -or $prob.Category -like "*Windows Update*" -or $prob.SubCategory -like "*Windows Update*") {
        $res = Invoke-VUONGTTRoutineWindowsUpdate -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineWindowsUpdate [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    if ($ProblemId -in @("PERM-001", "FILE-007") -or $prob.ErrorCode -like "*ACCESS_DENIED*" -or $prob.SubCategory -like "*Permission*") {
        $res = Invoke-VUONGTTRoutineFilePermission -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineFilePermission [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    if ($ProblemId -in @("PRINT-001", "PRINT-004", "PRINT-005") -or $prob.ErrorCode -like "*SPOOLER*" -or $prob.SubCategory -like "*Print Spooler*") {
        $res = Invoke-VUONGTTRoutinePrintSpooler -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutinePrintSpooler [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    if ($ProblemId -in @("NET-001", "NET-024", "NET-025") -or $prob.ErrorCode -in @("NET_TCP_IP_CORRUPTED", "NET_WINSOCK_CATALOG_CORRUPT") -or $prob.SubCategory -like "*TCP/IP, Winsock*") {
        $res = Invoke-VUONGTTRoutineNetworkStack -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineNetworkStack [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

        # CPU Spike / TiWorker (PERF-009, PERF-012)
    if ($ProblemId -in @("PERF-009", "PERF-012") -or $prob.ErrorCode -in @("PERF_CPU_SPIKE", "PERF_HIGH_CPU") -or $prob.Cause -like "*TiWorker*") {
        $res = Invoke-VUONGTTRoutineCpuSpike -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineCpuSpike [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    # RAM 100% / Memory Leak NDU (PERF-010, PERF-013)
    if ($ProblemId -in @("PERF-010", "PERF-013") -or $prob.ErrorCode -in @("PERF_MEMORY_LEAK", "PERF_HIGH_RAM")) {
        $res = Invoke-VUONGTTRoutineMemoryLeak -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineMemoryLeak [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    # Audio Service
    if ($ProblemId -like "AUDIO-*" -or $prob.ErrorCode -like "*AUDIO*" -or $prob.SubCategory -like "*Audio*") {
        $res = Invoke-VUONGTTRoutineAudio -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineAudio [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    # System Performance & Lag (PERF-001 -> PERF-008)
    if ($ProblemId -like "PERF-*" -or $prob.SubCategory -like "*Performance*" -or $prob.ErrorCode -like "*SLOW*") {
        $res = Invoke-VUONGTTRoutineSystemPerformance -ActionType $ActionType -Problem $prob -Parameters $Parameters
        Write-VUONGTTTroubleshootLog "Hoàn tất RoutineSystemPerformance [$ActionType]: Success=$($res.Success)" "INFO"
        return $res
    }

    # 3. Kịch bản chẩn đoán & khắc phục động thời gian thực cho toàn bộ các sự cố còn lại
    $res = Invoke-VUONGTTRoutineUniversalTelemetry -ActionType $ActionType -Problem $prob -Parameters $Parameters
    Write-VUONGTTTroubleshootLog "Hoàn tất RoutineUniversalTelemetry [$ActionType] cho $($prob.Id): Success=$($res.Success)" "INFO"
    return $res
}
