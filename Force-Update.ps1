# VUONGTT Toolkit - Force Update Script
# Dùng để ép buộc cập nhật trên máy Client: irm https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/Force-Update.ps1 | iex

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13

Write-Host ""
Write-Host " ======================================================================" -ForegroundColor DarkYellow
Write-Host "     VUONGTT TOOLKIT - FORCE UPDATE (Cap Nhat Bat Buoc)              " -ForegroundColor Yellow
Write-Host " ======================================================================" -ForegroundColor DarkYellow
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host " [!] Can quyen Admin. Dang tu dong leo thang quyen..." -ForegroundColor Yellow
    $cmd = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; irm https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/Force-Update.ps1 | iex"
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($cmd)
    $encodedCmd = [System.Convert]::ToBase64String($bytes)
    $psExe = if (Test-Path "$PSHOME\powershell.exe") { "$PSHOME\powershell.exe" } else { "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" }
    $safeWorkingDir = if (Test-Path $env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
    try {
        Start-Process -FilePath $psExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCmd" -WorkingDirectory $safeWorkingDir -Verb RunAs
    } catch {
        Write-Host " [!] Khong the tu dong nang quyen: $($_.Exception.Message)" -ForegroundColor Red
    }
    Exit
}

$toolDir = "E:\toolwindows"
$exeUrl  = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe"
$verUrl  = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/version.json"
$exePath = Join-Path $toolDir "VUONGTT_Toolkit.exe"
$tmpPath = Join-Path $env:TEMP "VUONGTT_Toolkit_update.exe"

# Detect install dir
if (-not (Test-Path $toolDir)) {
    # Find exe in common locations
    $candidates = @(
        "$env:USERPROFILE\Desktop\VUONGTT_Toolkit.exe",
        "$env:PUBLIC\Desktop\VUONGTT_Toolkit.exe",
        "C:\VUONGTT\VUONGTT_Toolkit.exe",
        "C:\Tools\VUONGTT_Toolkit.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $exePath = $c; $toolDir = Split-Path $c; break }
    }
}

Write-Host " [1] Dang tai phien ban moi tu GitHub..." -ForegroundColor Cyan

# Get latest version info
try {
    $verJson = Invoke-RestMethod -Uri $verUrl -UseBasicParsing
    $newVer = $verJson.version
    Write-Host "     Phien ban moi nhat: v$newVer" -ForegroundColor Green
} catch {
    Write-Host "     Khong lay duoc thong tin phien ban, tiep tuc tai exe..." -ForegroundColor Yellow
}

# Download new exe
try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($exeUrl, $tmpPath)
    Write-Host " [2] Tai thanh cong: $tmpPath" -ForegroundColor Green
} catch {
    Write-Host " [!] Loi tai file: $_" -ForegroundColor Red
    Read-Host "Nhan Enter de thoat"
    Exit 1
}

# Kill running instances
Write-Host " [3] Dang tat chuong trinh cu..." -ForegroundColor Cyan
Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 1500

# Copy new exe
Write-Host " [4] Dang sao chep exe moi..." -ForegroundColor Cyan
$retries = 20
for ($i = 0; $i -lt $retries; $i++) {
    try {
        Copy-Item -Path $tmpPath -Destination $exePath -Force -ErrorAction Stop
        Write-Host "     Cap nhat thanh cong!" -ForegroundColor Green
        break
    } catch {
        if ($i -eq ($retries - 1)) {
            Write-Host "     [!] Khong the sao chep: $_" -ForegroundColor Red
        } else {
            Start-Sleep -Milliseconds 500
        }
    }
}

# Unblock
Unblock-File -Path $exePath -ErrorAction SilentlyContinue

# Copy version.json
try {
    $vj = Invoke-RestMethod -Uri $verUrl -UseBasicParsing | ConvertTo-Json -Compress
    $vj | Out-File -FilePath (Join-Path $toolDir "version.json") -Encoding utf8 -Force
} catch {}

Write-Host " [5] Dang khoi dong lai chuong trinh..." -ForegroundColor Cyan
Start-Sleep -Milliseconds 500
if (Test-Path $exePath) {
    Start-Process -FilePath $exePath
    Write-Host ""
    Write-Host " ✅ Cap nhat hoan tat! Chuong trinh da duoc khoi dong lai." -ForegroundColor Green
} else {
    Write-Host " [!] Khong tim thay file exe tai: $exePath" -ForegroundColor Red
}

Write-Host ""
Start-Sleep -Seconds 3
