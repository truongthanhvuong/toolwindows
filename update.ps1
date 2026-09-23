<#
========================================================================================
   VUONGTT TOOLKIT 2026 - EMERGENCY 1-LINE AUTO-UPDATER
   Cập nhật tự động 1-click tức thì cho tất cả các máy Client
   Sử dụng: irm https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/update.ps1 | iex
========================================================================================
#>

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   VUONGTT TOOL PRO 2026 - TIẾN TRÌNH CẬP NHẬT TỨC THÌ    " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Yêu cầu quyền Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ">>> Yêu cầu cấp quyền Administrator để hoàn tất cập nhật..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { irm https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/update.ps1 | iex }`"" -Verb RunAs
    Exit
}

# 2. Định vị file VUONGTT_Toolkit.exe trên máy tính
$userProf = [System.Environment]::GetFolderPath("UserProfile")
$targetExe = $null

# Ưu tiên kiểm tra tiến trình đang chạy
try {
    $proc = Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue | Where-Object { $_.Path -and (Test-Path $_.Path) } | Select-Object -First 1
    if ($proc -and $proc.Path) { $targetExe = $proc.Path }
} catch {}

# Nếu chưa tìm thấy, quét các vị trí thông dụng
if (-not $targetExe) {
    $candidates = @(
        (Join-Path $userProf "Downloads\VUONGTT_Toolkit.exe"),
        (Join-Path $userProf "Desktop\VUONGTT_Toolkit.exe"),
        "E:\toolwindows\VUONGTT_Toolkit.exe",
        "D:\VUONGTT_Toolkit.exe",
        "C:\VUONGTT_Toolkit.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $targetExe = $cand
            break
        }
    }
}

if (-not $targetExe) {
    $targetExe = Join-Path $userProf "Downloads\VUONGTT_Toolkit.exe"
}

Write-Host ">>> [1/3] Vị trí file công cụ đích: $targetExe" -ForegroundColor Gray

# 3. Đóng tiến trình cũ để giải phóng file lock
Write-Host ">>> [2/3] Đóng tiến trình cũ và kết nối máy chủ GitHub..." -ForegroundColor Yellow
try {
    Stop-Process -Name "VUONGTT_Toolkit" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
} catch {}

# 4. Tải bản mới nhất từ GitHub
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$dlUrl = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe"
$tempFile = "$env:TEMP\VUONGTT_Toolkit_EmergencyUpdate_$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()).exe"

try {
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "VUONGTT-EmergencyUpdater/2026")
    $wc.DownloadFile($dlUrl, $tempFile)

    if ((Test-Path $tempFile) -and (Get-Item $tempFile).Length -gt 1000000) {
        $destDir = Split-Path $targetExe -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

        Copy-Item -Path $tempFile -Destination $targetExe -Force
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

        $ver = (Get-Item $targetExe).VersionInfo.FileVersion
        Write-Host "`n==========================================================" -ForegroundColor Green
        Write-Host " [THÀNH CÔNG] ĐÃ CẬP NHẬT LÊN PHIÊN BẢN MỚI NHẤT: v$ver!" -ForegroundColor Green
        Write-Host " Đang khởi động lại ứng dụng VUONGTT Tool Pro 2026..." -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Green

        Start-Process -FilePath $targetExe
        Start-Sleep -Seconds 2
    } else {
        Write-Host "[THẤT BẠI] File tải về không hợp lệ hoặc bị lỗi mạng!" -ForegroundColor Red
    }
} catch {
    Write-Host "[LỖI] $($_.Exception.Message)" -ForegroundColor Red
}
