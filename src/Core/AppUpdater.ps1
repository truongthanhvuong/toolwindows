# VUONGTT Toolkit 2026 - Auto Update Engine Module
# Kiem tra, thong bao va tu dong cap nhat phien ban moi nhat (Hot-Swap Self-Update)

$script:APP_CURRENT_VERSION = "20.5.909.38"

# Tu dong dong bo phien ban tu version.json neu ton tai trong Runtime
try {
    $verJsonCandidates = @()
    if ($global:ScriptDir) {
        $verJsonCandidates += (Join-Path $global:ScriptDir "version.json")
    }
    $verJsonCandidates += (Join-Path $env:ProgramData "VUONGTT_Toolkit\runtime\version.json")
    $verJsonCandidates += "E:\toolwindows\version.json"
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
            # Kiến trúc đa tầng 0s-Latency chống CDN Fastly Edge Cache:
            $latestSha = ""

            # Ưu tiên Tầng 1: Nếu ForceApi (bấm nút Cập Nhật Tool) -> Truy vấn trực tiếp GitHub Commits API để lấy Commit SHA mới nhất (Bất biến 100%, 0s Cache)
            if ($ForceApi) {
                $commitUrls = @(
                    "https://api.github.com/repos/truongthanhvuong/toolwindows/commits?path=version.json&page=1&per_page=1",
                    "https://api.github.com/repos/truongthanhvuong/toolwindows/commits/main"
                )
                foreach ($cUrl in $commitUrls) {
                    try {
                        $cReq = [System.Net.HttpWebRequest]::Create($cUrl)
                        $cReq.Proxy = $null
                        $cReq.Timeout = $TimeoutSec * 1000
                        $cReq.UserAgent = "VUONGTT-Toolkit-Updater/2026"
                        $cReq.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                        $cReq.Headers.Add("Pragma", "no-cache")
                        $ghToken = if (Get-Command "Get-VUONGTTGitHubToken" -ErrorAction SilentlyContinue) { Get-VUONGTTGitHubToken } else { "" }
                        if ($ghToken) { $cReq.Headers.Add("Authorization", "Bearer $ghToken") }

                        $cResp = $cReq.GetResponse()
                        $cStream = $cResp.GetResponseStream()
                        $cReader = New-Object System.IO.StreamReader($cStream, [System.Text.Encoding]::UTF8)
                        $cRaw = $cReader.ReadToEnd()
                        $cReader.Close(); $cStream.Close(); $cResp.Close()

                        $cObj = ConvertFrom-Json ($cRaw.TrimStart([char]0xFEFF).Trim())
                        $shaCandidate = if ($cObj -is [Array] -and $cObj.Count -gt 0) { $cObj[0].sha } elseif ($cObj -and $cObj.sha) { $cObj.sha } else { "" }
                        if ($shaCandidate) {
                            $latestSha = $shaCandidate
                            $wcSha = New-Object System.Net.WebClient
                            $wcSha.Proxy = $null
                            $wcSha.Encoding = [System.Text.Encoding]::UTF8
                            $wcSha.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")
                            $shaRaw = $wcSha.DownloadString("https://raw.githubusercontent.com/truongthanhvuong/toolwindows/$latestSha/version.json")
                            if ($shaRaw -and $shaRaw.Length -gt 20) {
                                $jsonText = $shaRaw
                                break
                            }
                        }
                    } catch {}
                }
            }

            # Tầng 2: jsDelivr Open Source CDN (Toàn cầu, purge tức thì, không dính GitHub raw cache 15 phút, không rate limit)
            if (-not $jsonText) {
                try {
                    $jsBust = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                    $jsDelivrUrl = "https://cdn.jsdelivr.net/gh/truongthanhvuong/toolwindows@main/version.json?t=$jsBust"
                    $wc = New-Object System.Net.WebClient
                    $wc.Proxy = $null
                    $wc.Encoding = [System.Text.Encoding]::UTF8
                    $wc.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")
                    $wc.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                    $wc.Headers.Add("Pragma", "no-cache")
                    $jsDownloaded = $wc.DownloadString($jsDelivrUrl)
                    if ($jsDownloaded -and $jsDownloaded.Length -gt 20) {
                        $jsonText = $jsDownloaded
                    }
                } catch {}
            }

            # Tầng 2.5: GitHub Commits API Fallback nếu chưa chạy ở trên
            if (-not $jsonText) {
                try {
                    $commitApiUrl = "https://api.github.com/repos/truongthanhvuong/toolwindows/commits?path=version.json&page=1&per_page=1"
                    $cReq = [System.Net.HttpWebRequest]::Create($commitApiUrl)
                    $cReq.Proxy = $null
                    $cReq.Timeout = $TimeoutSec * 1000
                    $cReq.UserAgent = "VUONGTT-Toolkit-Updater/2026"
                    $cReq.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
                    $cReq.Headers.Add("Pragma", "no-cache")
                    $ghToken = if (Get-Command "Get-VUONGTTGitHubToken" -ErrorAction SilentlyContinue) { Get-VUONGTTGitHubToken } else { "" }
                    if ($ghToken) { $cReq.Headers.Add("Authorization", "Bearer $ghToken") }

                    $cResp = $cReq.GetResponse()
                    $cStream = $cResp.GetResponseStream()
                    $cReader = New-Object System.IO.StreamReader($cStream, [System.Text.Encoding]::UTF8)
                    $cRaw = $cReader.ReadToEnd()
                    $cReader.Close(); $cStream.Close(); $cResp.Close()

                    $cObj = ConvertFrom-Json ($cRaw.TrimStart([char]0xFEFF).Trim())
                    if ($cObj -and $cObj.Count -gt 0 -and $cObj[0].sha) {
                        $latestSha = $cObj[0].sha
                        $wcSha = New-Object System.Net.WebClient
                        $wcSha.Proxy = $null
                        $wcSha.Encoding = [System.Text.Encoding]::UTF8
                        $wcSha.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")
                        $shaRaw = $wcSha.DownloadString("https://raw.githubusercontent.com/truongthanhvuong/toolwindows/$latestSha/version.json")
                        if ($shaRaw -and $shaRaw.Length -gt 20) {
                            $jsonText = $shaRaw
                        }
                    }
                } catch {}
            }

            # Tầng 3: GitHub Contents REST API trực tiếp từ Git Tree (0s Latency)
            if (-not $jsonText) {
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

            # Tầng 4: GitHub Raw CDN Fallback
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

                # Nếu có Commit SHA mới nhất, tối ưu URL tải file EXE theo SHA để không bao giờ bị Fastly CDN trả về file EXE cũ
                if ($latestSha -and $result.DownloadUrl -like "*raw.githubusercontent.com*/main/*") {
                    $result.DownloadUrl = $result.DownloadUrl -replace "/main/", "/$latestSha/"
                }

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

    # 4. Quét tiến trình VUONGTT_Toolkit đang chạy
    try {
        $vProc = Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue | Where-Object { $_.Path -and (Test-Path $_.Path -ErrorAction SilentlyContinue) } | Select-Object -First 1
        if ($vProc -and $vProc.Path) {
            return $vProc.Path
        }
    } catch {}

    # 5. Dò tìm trong các thư mục thông dụng của người dùng hiện tại
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

    # 6. Fallback an toàn mặc định: Thư mục Downloads
    return (Join-Path $userProf "Downloads\VUONGTT_Toolkit.exe")
}

# Tự động dọn dẹp các tệp tin backup .old / .bak sau khi cập nhật thành công
try {
    $cleanupTarget = Get-VUONGTTTargetExePath
    if ($cleanupTarget -and (Test-Path "$cleanupTarget.old")) {
        Remove-Item "$cleanupTarget.old" -Force -ErrorAction SilentlyContinue
    }
} catch {}

function Start-VUONGTTBackgroundPreDownload {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl,
        [string]$NewVersion,
        [scriptblock]$OnProgress = $null
    )

    if (-not $DownloadUrl -or -not $NewVersion) { return $null }

    $stagedReadyExe = "$env:TEMP\VUONGTT_Toolkit_v$($NewVersion)_READY.exe"
    if (Test-Path $stagedReadyExe) {
        try {
            $fi = Get-Item $stagedReadyExe -ErrorAction SilentlyContinue
            if ($fi -and $fi.Length -gt 1000000) {
                $global:VUONGTT_UPDATE_READY = @{
                    Version = $NewVersion
                    ExePath = $stagedReadyExe
                }
                return $stagedReadyExe
            }
        } catch {}
    }

    $tempPart = "$env:TEMP\VUONGTT_Toolkit_v$($NewVersion)_stage.tmp"
    if (Test-Path $tempPart) { Remove-Item $tempPart -Force -ErrorAction SilentlyContinue }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $dlClient = New-Object System.Net.WebClient
        $dlClient.Headers.Add("User-Agent", "VUONGTT-Toolkit-PreDownloader/2026")

        # Tối ưu hóa Commit SHA
        if ($DownloadUrl -like "*raw.githubusercontent.com*/main/VUONGTT_Toolkit.exe*") {
            try {
                $cApiUrl = "https://api.github.com/repos/truongthanhvuong/toolwindows/commits?path=VUONGTT_Toolkit.exe&page=1&per_page=1"
                $wcSha = New-Object System.Net.WebClient
                $wcSha.Proxy = $null
                $wcSha.Headers.Add("User-Agent", "VUONGTT-Toolkit-PreDownloader/2026")
                $cRaw = $wcSha.DownloadString($cApiUrl)
                $cObj = ConvertFrom-Json $cRaw
                if ($cObj -and $cObj.Count -gt 0 -and $cObj[0].sha) {
                    $DownloadUrl = $DownloadUrl -replace "/main/VUONGTT_Toolkit.exe", "/$($cObj[0].sha)/VUONGTT_Toolkit.exe"
                }
            } catch {}
        }

        $dlUrlWithCacheBust = $DownloadUrl
        if ($dlUrlWithCacheBust -like "http*") {
            $sep = if ($dlUrlWithCacheBust -like "*\?*") { "&" } else { "?" }
            $dlUrlWithCacheBust = "$dlUrlWithCacheBust$($sep)nocache=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
        }

        if ($OnProgress) { & $OnProgress "Đang tự động tải ngầm bản cập nhật v$NewVersion..." }
        $dlClient.DownloadFile($dlUrlWithCacheBust, $tempPart)

        if ((Test-Path $tempPart) -and (Get-Item $tempPart).Length -gt 1000000) {
            Move-Item -Path $tempPart -Destination $stagedReadyExe -Force -ErrorAction SilentlyContinue
            $global:VUONGTT_UPDATE_READY = @{
                Version = $NewVersion
                ExePath = $stagedReadyExe
            }
            return $stagedReadyExe
        }
    } catch {
        if (Test-Path $tempPart) { Remove-Item $tempPart -Force -ErrorAction SilentlyContinue }
    }
    return $null
}

function Invoke-VUONGTTAppSelfUpdate {
    [CmdletBinding()]
    param(
        [string]$DownloadUrl,
        [string]$NewVersion,
        [string]$PreDownloadedExePath = "",
        [scriptblock]$OnProgress = $null
    )

    if (-not $DownloadUrl -and -not $PreDownloadedExePath) {
        return "[LỖI] Đường dẫn tải phiên bản mới không hợp lệ!"
    }

    # Xác định đường dẫn file EXE đích thông minh đa tầng
    $targetExePath = Get-VUONGTTTargetExePath
    if (-not $targetExePath -or ($targetExePath -like "*powershell*") -or ($targetExePath -notlike "*.exe")) {
        $userProf = [System.Environment]::GetFolderPath("UserProfile")
        $targetExePath = Join-Path $userProf "Downloads\VUONGTT_Toolkit.exe"
    }

    try {
        $tempDownloadExe = "$env:TEMP\VUONGTT_Toolkit_v$($NewVersion)_update.exe"

        # Nếu đã có file tải trước (Pre-Downloaded Staging), sử dụng trực tiếp không cần tải lại mạng
        $usedStaged = $false
        if ($PreDownloadedExePath -and (Test-Path $PreDownloadedExePath -ErrorAction SilentlyContinue) -and ((Get-Item $PreDownloadedExePath).Length -gt 500000)) {
            Copy-Item -Path $PreDownloadedExePath -Destination $tempDownloadExe -Force -ErrorAction SilentlyContinue
            $usedStaged = $true
        } elseif (Test-Path "$env:TEMP\VUONGTT_Toolkit_v$($NewVersion)_READY.exe") {
            $readyPath = "$env:TEMP\VUONGTT_Toolkit_v$($NewVersion)_READY.exe"
            if ((Get-Item $readyPath).Length -gt 500000) {
                Copy-Item -Path $readyPath -Destination $tempDownloadExe -Force -ErrorAction SilentlyContinue
                $usedStaged = $true
            }
        }

        if (-not $usedStaged) {
            if ($OnProgress) { & $OnProgress "Đang chuẩn bị tải gói cập nhật phiên bản v$NewVersion..." }
            if (Test-Path $tempDownloadExe) { Remove-Item $tempDownloadExe -Force -ErrorAction SilentlyContinue }

            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

            $client = New-Object System.Net.WebClient
            $client.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")

            # Tối ưu hóa tải file EXE bằng Commit SHA bất biến chống Fastly CDN cache trả về binary cũ
            if ($DownloadUrl -like "*raw.githubusercontent.com*/main/VUONGTT_Toolkit.exe*") {
                try {
                    $cApiUrl = "https://api.github.com/repos/truongthanhvuong/toolwindows/commits?path=VUONGTT_Toolkit.exe&page=1&per_page=1"
                    $wcSha = New-Object System.Net.WebClient
                    $wcSha.Proxy = $null
                    $wcSha.Headers.Add("User-Agent", "VUONGTT-Toolkit-Updater/2026")
                    $cRaw = $wcSha.DownloadString($cApiUrl)
                    $cObj = ConvertFrom-Json $cRaw
                    if ($cObj -and $cObj.Count -gt 0 -and $cObj[0].sha) {
                        $DownloadUrl = $DownloadUrl -replace "/main/VUONGTT_Toolkit.exe", "/$($cObj[0].sha)/VUONGTT_Toolkit.exe"
                    }
                } catch {}
            }

            $dlUrlWithCacheBust = $DownloadUrl
            if ($dlUrlWithCacheBust -like "http*") {
                $sep = if ($dlUrlWithCacheBust -like "*\?*") { "&" } else { "?" }
                $dlUrlWithCacheBust = "$dlUrlWithCacheBust$($sep)nocache=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
            }

            if ($OnProgress) { & $OnProgress "Đang kết nối máy chủ và tải bản cập nhật mới nhất: $DownloadUrl..." }
            $client.DownloadFile($dlUrlWithCacheBust, $tempDownloadExe)
        }

    if (-not (Test-Path $tempDownloadExe) -or (Get-Item $tempDownloadExe).Length -lt 500000) {
        return "[LỖI] Tải bản cập nhật thất bại hoặc tệp tin bị lỗi dung lượng (< 500KB)! Vui lòng kiểm tra lại kết nối mạng."
    }

    $sizeKb = [math]::Round((Get-Item $tempDownloadExe).Length / 1KB, 1)
    if ($OnProgress) { & $OnProgress "Đã sẵn sàng gói cập nhật ($sizeKb KB). Đang tự động thay thế file trong 1 giây..." }

        # Tạo script cập nhật độc lập chuẩn xác từ các phiên bản hoạt động ổn định trước đó
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

        # Khởi chạy updater.cmd với cửa sổ ẩn như phiên bản cũ ổn định
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$updaterCmd`"" -WindowStyle Hidden

        # Đóng ứng dụng cũ ngay lập tức
        Start-Sleep -Milliseconds 800
        [System.Environment]::Exit(0)

        return "[OK] Đang khởi động lại ứng dụng mới!"
    } catch {
        return "[LỖI CẬP NHẬT] $($_.Exception.Message)"
    }
}
