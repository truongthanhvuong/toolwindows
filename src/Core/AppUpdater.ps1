# VUONGTT Toolkit 2026 - Auto Update Engine Module
# Kiem tra, thong bao va tu dong cap nhat phien ban moi nhat (Hot-Swap Self-Update)

$script:APP_CURRENT_VERSION = "20.5.908.74"

# Tu dong dong bo phien ban tu version.json neu ton tai trong Runtime
try {
    $verJsonCandidates = @(
        "$env:TEMP\VUONGTT_Toolkit_Runtime\version.json"
    )
    if ($global:ScriptDir) {
        $verJsonCandidates += (Join-Path $global:ScriptDir "version.json")
    }
    foreach ($vf in $verJsonCandidates) {
        if ($vf -and (Test-Path $vf -ErrorAction SilentlyContinue)) {
            $parsedVer = Get-Content $vf -Raw -Encoding UTF8 -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($parsedVer -and $parsedVer.version) {
                $script:APP_CURRENT_VERSION = $parsedVer.version.Trim()
                break
            }
        }
    }
} catch {}

$script:UPDATE_CHECK_URL = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/version.json"

function Get-VUONGTTCurrentVersion {
    return $script:APP_CURRENT_VERSION
}

function Get-VUONGTTAppUpdateInfo {
    [CmdletBinding()]
    param(
        [string]$CheckUrl = $script:UPDATE_CHECK_URL,
        [int]$TimeoutSec = 5,
        [switch]$ForceApi
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
            # Kiến trúc phân tán cho 1000+ máy:
            # - Khi bấm kiểm tra thủ công (-ForceApi): Dùng REST API thời gian thực 0s.
            # - Khi máy khách chạy ngầm định kỳ: Dùng Fastly Raw CDN không giới hạn rate limit.
            if ($ForceApi) {
                try {
                    $apiUrl = "https://api.github.com/repos/truongthanhvuong/toolwindows/contents/version.json?ref=main"
                    $apiReq = [System.Net.HttpWebRequest]::Create($apiUrl)
                    $apiReq.Proxy = $null
                    $apiReq.Timeout = $TimeoutSec * 1000
                    $apiReq.UserAgent = "VUONGTT-Toolkit-Updater/2026"
                    $apiReq.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                    $apiReq.Headers.Add("Pragma", "no-cache")
                    $ghToken = if (Get-Command "Get-VUONGTTGitHubToken" -ErrorAction SilentlyContinue) { Get-VUONGTTGitHubToken } else { "" }
                    if ($ghToken) { $apiReq.Headers.Add("Authorization", "Bearer $ghToken") }
                    $apiResp = $apiReq.GetResponse()
                    $apiStream = $apiResp.GetResponseStream()
                    $apiReader = New-Object System.IO.StreamReader($apiStream, [System.Text.Encoding]::UTF8)
                    $apiRaw = $apiReader.ReadToEnd()
                    $apiReader.Close(); $apiStream.Close(); $apiResp.Close()

                    $apiObj = ConvertFrom-Json ($apiRaw.TrimStart([char]0xFEFF).Trim())
                    if ($apiObj -and $apiObj.content) {
                        $cleanBase64 = $apiObj.content -replace '\s+', ''
                        $bytes = [System.Convert]::FromBase64String($cleanBase64)
                        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                            $bytes = $bytes[3..($bytes.Length - 1)]
                        }
                        $jsonText = [System.Text.Encoding]::UTF8.GetString($bytes).Trim()
                    }
                } catch {}
            }

            # Fastly CDN Raw URL (Không giới hạn lượt gọi cho 1000+ máy)
            if (-not $jsonText) {
                $candidateUrls = @(
                    "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/version.json",
                    $CheckUrl
                )
                foreach ($targetUrl in $candidateUrls) {
                    try {
                        $sep = if ($targetUrl -like "*\?*") { "&" } else { "?" }
                        $urlWithBust = "$targetUrl$($sep)nocache=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

                        $wc = New-Object System.Net.WebClient
                        $wc.Proxy = $null
                        $wc.Encoding = [System.Text.Encoding]::UTF8
                        $wc.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")
                        $wc.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                        $wc.Headers.Add("Pragma", "no-cache")
                        $downloaded = $wc.DownloadString($urlWithBust)
                        if ($downloaded -and $downloaded.Length -gt 20) {
                            $jsonText = $downloaded
                            break
                        }
                    } catch {}
                }
            }

            # Fallback sang REST API nếu Raw CDN tạm thời chưa sẵn sàng
            if (-not $jsonText -and -not $ForceApi) {
                try {
                    $apiUrl = "https://api.github.com/repos/truongthanhvuong/toolwindows/contents/version.json?ref=main"
                    $apiReq = [System.Net.HttpWebRequest]::Create($apiUrl)
                    $apiReq.Proxy = $null
                    $apiReq.Timeout = $TimeoutSec * 1000
                    $apiReq.UserAgent = "VUONGTT-Toolkit-Updater/2026"
                    $ghToken = if (Get-Command "Get-VUONGTTGitHubToken" -ErrorAction SilentlyContinue) { Get-VUONGTTGitHubToken } else { "" }
                    if ($ghToken) { $apiReq.Headers.Add("Authorization", "Bearer $ghToken") }
                    $apiResp = $apiReq.GetResponse()
                    $apiStream = $apiResp.GetResponseStream()
                    $apiReader = New-Object System.IO.StreamReader($apiStream, [System.Text.Encoding]::UTF8)
                    $apiRaw = $apiReader.ReadToEnd()
                    $apiReader.Close(); $apiStream.Close(); $apiResp.Close()

                    $apiObj = ConvertFrom-Json ($apiRaw.TrimStart([char]0xFEFF).Trim())
                    if ($apiObj -and $apiObj.content) {
                        $cleanBase64 = $apiObj.content -replace '\s+', ''
                        $bytes = [System.Convert]::FromBase64String($cleanBase64)
                        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
                            $bytes = $bytes[3..($bytes.Length - 1)]
                        }
                        $jsonText = [System.Text.Encoding]::UTF8.GetString($bytes).Trim()
                    }
                } catch {}
            }
        }

        if ($jsonText) {
            $cleanJson = $jsonText.Trim().Trim([char]0xFEFF)
            $data = ConvertFrom-Json $cleanJson
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
        } else {
            $result.IsOnline = $false
            $result.Message = "Không thể kết nối đến máy chủ cập nhật GitHub. Vui lòng kiểm tra kết nối mạng!"
        }
    } catch {
        $result.IsOnline = $false
        $result.Message = "Lỗi kết nối máy chủ cập nhật: $($_.Exception.Message)"
    }

    return $result
}

function Get-VUONGTTTargetExePath {
    # 1. Global variable từ lệnh gọi khởi động
    if ($global:VUONGTT_TARGET_EXE -and (Test-Path $global:VUONGTT_TARGET_EXE -ErrorAction SilentlyContinue) -and ($global:VUONGTT_TARGET_EXE -like "*.exe")) {
        return $global:VUONGTT_TARGET_EXE
    }

    # 2. Biến môi trường từ C# wrapper
    if ($env:VUONGTT_ORIGINAL_EXE -and (Test-Path $env:VUONGTT_ORIGINAL_EXE -ErrorAction SilentlyContinue) -and ($env:VUONGTT_ORIGINAL_EXE -like "*.exe")) {
        return $env:VUONGTT_ORIGINAL_EXE
    }

    # 3. File launcher_info.txt trong Temp hoặc Runtime
    $infoFiles = @(
        "$env:TEMP\VUONGTT_Toolkit_Runtime\launcher_info.txt",
        "$env:TEMP\launcher_info.txt"
    )
    foreach ($inf in $infoFiles) {
        if (Test-Path $inf -ErrorAction SilentlyContinue) {
            try {
                $rawP = (Get-Content $inf -Raw -ErrorAction SilentlyContinue).Trim()
                if ($rawP -and (Test-Path $rawP -ErrorAction SilentlyContinue) -and ($rawP -like "*.exe") -and ($rawP -notlike "*powershell*")) {
                    return $rawP
                }
            } catch {}
        }
    }

    # 4. Truy vết tiến trình cha qua WMI/CIM
    try {
        $parentPid = (Get-CimInstance Win32_Process -Filter "ProcessId = $PID" -ErrorAction SilentlyContinue).ParentProcessId
        if ($parentPid) {
            $parentProc = Get-CimInstance Win32_Process -Filter "ProcessId = $parentPid" -ErrorAction SilentlyContinue
            if ($parentProc -and $parentProc.ExecutablePath -and ($parentProc.ExecutablePath -like "*.exe") -and ($parentProc.ExecutablePath -notlike "*powershell*")) {
                return $parentProc.ExecutablePath
            }
        }
    } catch {}

    # 5. Quét tiến trình VUONGTT_Toolkit đang chạy
    try {
        $vProc = Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($vProc -and $vProc.Path -and (Test-Path $vProc.Path -ErrorAction SilentlyContinue)) {
            return $vProc.Path
        }
    } catch {}

    # 6. Dò tìm trong các thư mục thông dụng của người dùng hiện tại
    $userProf = [System.Environment]::GetFolderPath("UserProfile")
    $candidates = @(
        (Join-Path $userProf "Downloads\VUONGTT_Toolkit.exe"),
        (Join-Path $userProf "Desktop\VUONGTT_Toolkit.exe"),
        "E:\toolwindows\VUONGTT_Toolkit.exe",
        "D:\VUONGTT_Toolkit.exe",
        "C:\VUONGTT_Toolkit.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand -ErrorAction SilentlyContinue) {
            return $cand
        }
    }

    # 7. Fallback an toàn mặc định: Thư mục Downloads
    return (Join-Path $userProf "Downloads\VUONGTT_Toolkit.exe")
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

    # Xác định đường dẫn file EXE đích thông minh đa tầng
    $targetExePath = Get-VUONGTTTargetExePath
    if (-not $targetExePath -or ($targetExePath -like "*powershell*") -or ($targetExePath -notlike "*.exe")) {
        $userProf = [System.Environment]::GetFolderPath("UserProfile")
        $targetExePath = Join-Path $userProf "Downloads\VUONGTT_Toolkit.exe"
    }

    if ($OnProgress) { & $OnProgress "Đang chuẩn bị tải gói cập nhật phiên bản v$NewVersion..." }

    $tempDownloadExe = "$env:TEMP\VUONGTT_Toolkit_v$($NewVersion)_update.exe"
    if (Test-Path $tempDownloadExe) { Remove-Item $tempDownloadExe -Force -ErrorAction SilentlyContinue }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $client = New-Object System.Net.WebClient
        $client.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")

        $dlUrlWithCacheBust = $DownloadUrl
        if ($dlUrlWithCacheBust -like "http*") {
            $sep = if ($dlUrlWithCacheBust -like "*\?*") { "&" } else { "?" }
            $dlUrlWithCacheBust = "$dlUrlWithCacheBust$($sep)nocache=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
        }

        if ($OnProgress) { & $OnProgress "Đang kết nối máy chủ và tải bản cập nhật mới nhất: $DownloadUrl..." }
        $client.DownloadFile($dlUrlWithCacheBust, $tempDownloadExe)

        if (-not (Test-Path $tempDownloadExe) -or (Get-Item $tempDownloadExe).Length -lt 50000) {
            return "[LỖI] Tải bản cập nhật thất bại hoặc tệp tin bị lỗi! Vui lòng thử lại sau."
        }

        $sizeKb = [math]::Round((Get-Item $tempDownloadExe).Length / 1KB, 1)
        if ($OnProgress) { & $OnProgress "Đã tải xong bản mới ($sizeKb KB). Đang khởi tạo tiến trình tự động thay thế file..." }

        # Tạo script chuyển giao độc lập không bao giờ mở shell PowerShell rỗng
        $updaterCmd = "$env:TEMP\VUONGTT_HotSwap_Updater.cmd"
        $cmdContent = @"
@echo off
title VUONGTT Toolkit Auto Updater
echo ========================================================
echo   VUONGTT TOOLKIT AUTO UPDATER - DANG CAP NHAT...
echo ========================================================
echo 1. Dang dong cac tien trinh cu de giai phong file lock...
taskkill /f /im "VUONGTT_Toolkit.exe" >nul 2>&1
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
    echo [CANH BAO] Khong the ghi de file goc, dang luu ban moi tai Downloads...
    set "FALLBACK_EXE=%USERPROFILE%\Downloads\VUONGTT_Toolkit_v$($NewVersion).exe"
    copy /y "$tempDownloadExe" "%FALLBACK_EXE%" >nul
    del /f /q "$tempDownloadExe" 2>nul
    echo 3. Khoi dong lai VUONGTT Tool Pro 2026 moi nhat...
    start "" "%FALLBACK_EXE%"
    timeout /t 1 /nobreak >nul
    del /f /q "%~f0" 2>nul
    exit
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

        # Khởi chạy updater.cmd ngầm
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$updaterCmd`"" -WindowStyle Hidden

        # Đóng ứng dụng cũ ngay lập tức
        Start-Sleep -Milliseconds 800
        [System.Environment]::Exit(0)

        return "[OK] Đang khởi động lại ứng dụng mới!"
    } catch {
        return "[LỖI CẬP NHẬT] $($_.Exception.Message)"
    }
}
