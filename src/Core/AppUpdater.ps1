# VUONGTT Toolkit 2026 - Auto Update Engine Module
# Kiem tra, thong bao va tu dong cap nhat phien ban moi nhat (Hot-Swap Self-Update)

$script:APP_CURRENT_VERSION = "20.5.908.27"
$script:UPDATE_CHECK_URL    = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/version.json"

function Get-VUONGTTCurrentVersion {
    return $script:APP_CURRENT_VERSION
}

function Get-VUONGTTAppUpdateInfo {
    [CmdletBinding()]
    param(
        [string]$CheckUrl = $script:UPDATE_CHECK_URL,
        [int]$TimeoutSec = 4
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    $result = [PSCustomObject]@{
        HasUpdate      = $false
        CurrentVersion = $script:APP_CURRENT_VERSION
        LatestVersion  = $script:APP_CURRENT_VERSION
        ReleaseDate    = (Get-Date).ToString("dd/MM/yyyy")
        DownloadUrl    = ""
        Changelog      = @("Phiên bản bạn đang sử dụng hiện tại là bản mới nhất.")
        IsOnline       = $false
        Message        = "Đang sử dụng phiên bản mới nhất ($($script:APP_CURRENT_VERSION))"
    }

    try {
        $jsonText = ""
        if ($CheckUrl -like "file://*" -or (Test-Path $CheckUrl -ErrorAction SilentlyContinue)) {
            $localPath = if ($CheckUrl -like "file://*") { [System.Uri]::new($CheckUrl).LocalPath } else { $CheckUrl }
            $jsonText = [System.IO.File]::ReadAllText($localPath, [System.Text.Encoding]::UTF8)
        } else {
            $req = [System.Net.HttpWebRequest]::Create($CheckUrl)
            $req.Timeout = $TimeoutSec * 1000
            $req.UserAgent = "VUONGTT-Toolkit-Updater/2026 ($($script:APP_CURRENT_VERSION))"
            $resp = $req.GetResponse()
            
            $stream = $resp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
            $jsonText = $reader.ReadToEnd()
            $reader.Close()
            $stream.Close()
            $resp.Close()
        }

        if ($jsonText) {
            $data = ConvertFrom-Json $jsonText
            $result.IsOnline = $true
            if ($data.version) {
                $result.LatestVersion = $data.version
                $result.ReleaseDate   = if ($data.releaseDate) { $data.releaseDate } else { (Get-Date).ToString("dd/MM/yyyy") }
                $result.DownloadUrl   = if ($data.downloadUrl) { $data.downloadUrl } else { "" }
                $result.Changelog     = if ($data.changelog) { $data.changelog } else { @("Cải tiến hiệu năng và sửa lỗi.") }

                # So sanh phien ban bang chuoi va version
                $curClean = ($script:APP_CURRENT_VERSION -replace '[^\d\.]', '')
                $newClean = ($data.version -replace '[^\d\.]', '')
                try {
                    $vCur = [System.Version]$curClean
                    $vNew = [System.Version]$newClean
                    if ($vNew -gt $vCur) {
                        $result.HasUpdate = $true
                        $result.Message = "Phát hiện phiên bản mới: v$($data.version) (Ngày: $($result.ReleaseDate))"
                    }
                } catch {
                    if ($newClean -ne $curClean) {
                        $result.HasUpdate = $true
                        $result.Message = "Có phiên bản mới: v$($data.version)"
                    }
                }
            }
        }
    } catch {
        # Fallback offline an toan - khong bao gio crash
        $result.IsOnline = $false
        $result.Message = "Đang chạy ngoại tuyến (Offline) - Phiên bản v$($script:APP_CURRENT_VERSION)"
    }

    return $result
}

function Invoke-VUONGTTAppSelfUpdate {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl,
        [string]$NewVersion,
        [scriptblock]$OnProgress = $null
    )

    if (-not $DownloadUrl) {
        return "[LỖI] Đường dẫn tải phiên bản mới không hợp lệ!"
    }

    # Xac dinh vi tri file EXE dang chay
    $currentProc = [System.Diagnostics.Process]::GetCurrentProcess()
    $targetExePath = $currentProc.MainModule.FileName

    # Neu dang chay tu powershell.exe hoac moi truong runtime temp, tim file goc VUONGTT_Toolkit.exe
    if ($targetExePath -like "*powershell*" -or $targetExePath -like "*Temp*") {
        if (Test-Path "E:\toolwindows\VUONGTT_Toolkit.exe") {
            $targetExePath = "E:\toolwindows\VUONGTT_Toolkit.exe"
        } elseif (Test-Path "$env:USERPROFILE\Desktop\VUONGTT_Toolkit.exe") {
            $targetExePath = "$env:USERPROFILE\Desktop\VUONGTT_Toolkit.exe"
        }
    }

    if ($OnProgress) { & $OnProgress "Đang chuẩn bị tải gói cập nhật phiên bản v$NewVersion..." }

    $tempDownloadExe = "$env:TEMP\VUONGTT_Toolkit_v$($NewVersion)_update.exe"
    if (Test-Path $tempDownloadExe) { Remove-Item $tempDownloadExe -Force -ErrorAction SilentlyContinue }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $client = New-Object System.Net.WebClient
        $client.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")

        if ($OnProgress) { & $OnProgress "Đang kết nối máy chủ và tải bản cập nhật mới nhất: $DownloadUrl..." }
        $client.DownloadFile($DownloadUrl, $tempDownloadExe)

        if (-not (Test-Path $tempDownloadExe) -or (Get-Item $tempDownloadExe).Length -lt 50000) {
            return "[LỖI] Tải bản cập nhật thất bại hoặc tệp tin bị lỗi! Vui lòng thử lại sau."
        }

        $sizeKb = [math]::Round((Get-Item $tempDownloadExe).Length / 1KB, 1)
        if ($OnProgress) { & $OnProgress "Đã tải xong bản mới ($sizeKb KB). Đang khởi tạo tiến trình tự động thay thế file..." }

        # Tao script chuyen giao doc lap (Hot-Swap Process Transfer)
        $updaterCmd = "$env:TEMP\VUONGTT_HotSwap_Updater.cmd"
        $cmdContent = @"
@echo off
title VUONGTT Toolkit Auto Updater
echo ========================================================
echo   VUONGTT TOOLKIT AUTO UPDATER - DANG CAP NHAT...
echo ========================================================
echo 1. Dang cho tien trinh cu dong lai hoan toan...
timeout /t 2 /nobreak >nul

:wait_loop
tasklist /fi "imagename eq VUONGTT_Toolkit.exe" 2>nul | find /i "VUONGTT_Toolkit.exe" >nul
if not errorlevel 1 (
    timeout /t 1 /nobreak >nul
    goto wait_loop
)

echo 2. Dang ghi de phien ban moi v$NewVersion...
copy /y "$tempDownloadExe" "$targetExePath" >nul
if errorlevel 1 (
    echo [LOI] Khong the ghi de file. Thu lai voi quyen Admin...
    timeout /t 1 /nobreak >nul
    copy /y "$tempDownloadExe" "$targetExePath" >nul
)

del /f /q "$tempDownloadExe" 2>nul

echo 3. Khoi dong lai VUONGTT Tool Pro 2026 moi nhat...
start "" "$targetExePath"

echo 4. Hoan tat cap nhat!
timeout /t 1 /nobreak >nul
del /f /q "%~f0" 2>nul
exit
"@
        [System.IO.File]::WriteAllText($updaterCmd, $cmdContent, [System.Text.Encoding]::Default)

        if ($OnProgress) { & $OnProgress "Đang khởi động lại ứng dụng với phiên bản v$NewVersion..." }

        # Khoi chay updater.cmd ngam
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$updaterCmd`"" -WindowStyle Hidden

        # Dong ung dung cu ngay lap tuc de giai phong file lock
        Start-Sleep -Milliseconds 800
        [System.Environment]::Exit(0)

        return "[OK] Đang khởi động lại ứng dụng mới!"
    } catch {
        return "[LỖI CẬP NHẬT] $($_.Exception.Message)"
    }
}
