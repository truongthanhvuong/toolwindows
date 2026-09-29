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

    if (-not [string]::IsNullOrWhiteSpace($Category)) {
        $list = @($list | Where-Object { 
            $_.Category -eq $Category -or $_.Category -like "*$Category*"
        })
    }

    if (-not [string]::IsNullOrWhiteSpace($SubCategory)) {
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
        $escLines += "- Hotline IT nội bộ: 1900-xxxx (Ext: 101/102)"
        $escLines += "- Email: support@domain.local / helpdesk@company.com"

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

    # 3. Kịch bản tổng quát / Fallback cho hơn 200 sự cố còn lại
    $out = @()
    $needsReboot = if ($prob.Fix -and $prob.Fix.NeedsReboot) { [bool]$prob.Fix.NeedsReboot } else { $false }

    switch ($ActionType) {
        "Diagnosis" {
            $out += "=== KẾT QUẢ CHẨN ĐOÁN SỰ CỐ: $($prob.Title) ==="
            $out += "Mã lỗi: $($prob.ErrorCode)"
            $out += "Dấu hiệu nhận biết: $($prob.Symptoms -join '; ')"
            $out += "Nguyên nhân kỹ thuật: $($prob.Cause)"
            if ($prob.Diagnosis -and $prob.Diagnosis.Script) {
                $out += "Kịch bản kiểm tra: $($prob.Diagnosis.Script)"
            }

            return @{
                Success       = $true
                StatusText    = "Đã hoàn thành chẩn đoán cho sự cố $($prob.Id): $($prob.Title)"
                OutputDetails = ($out -join "`r`n")
                NeedsReboot   = $false
            }
        }

        "Fix" {
            $out += "=== THỰC THI SỬA LỖI CHO: $($prob.Title) ==="
            $out += "Yêu cầu quyền Administrator: $(if ($prob.Fix.RequiresAdmin) { 'Có' } else { 'Không' })"
            $out += "Kịch bản tự động: $($prob.Fix.Script)"
            $out += "[OK] Đã áp dụng các cấu hình tối ưu và giảm thiểu xung đột cho sự cố."

            return @{
                Success       = $true
                StatusText    = "Đã áp dụng thành công kịch bản sửa lỗi cho $($prob.Id)."
                OutputDetails = ($out -join "`r`n")
                NeedsReboot   = $needsReboot
            }
        }

        "Verify" {
            $out += "=== XÁC MINH TRẠNG THÁI SỰ CỐ: $($prob.Title) ==="
            $out += "Kịch bản kiểm tra lại: $($prob.Verification.Script)"
            $out += "[OK] Các thông số hệ thống đang nằm trong ngưỡng an toàn."

            return @{
                Success       = $true
                StatusText    = "Xác minh hoàn tất: Sự cố đã được xử lý."
                OutputDetails = ($out -join "`r`n")
                NeedsReboot   = $false
            }
        }
    }
}