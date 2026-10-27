function Compare-SemVer([string]$v1, [string]$v2) {
    if (-not $v1 -or -not $v2) { return 0 }
    $p1 = ($v1.Trim() -replace '^[vV]', '').Split('.')
    $p2 = ($v2.Trim() -replace '^[vV]', '').Split('.')
    $maxLen = [Math]::Max($p1.Length, $p2.Length)
    for ($i = 0; $i -lt $maxLen; $i++) {
        $n1 = 0; $n2 = 0
        if ($i -lt $p1.Length) { [int]::TryParse($p1[$i], [ref]$n1) | Out-Null }
        if ($i -lt $p2.Length) { [int]::TryParse($p2[$i], [ref]$n2) | Out-Null }
        if ($n1 -gt $n2) { return 1 }
        if ($n1 -lt $n2) { return -1 }
    }
    return 0
}

﻿$Host.UI.RawUI.WindowTitle = "VUONGTT Tool Pro 2026 - Cloud Bootstrapper"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13 -bor [System.Net.SecurityProtocolType]::Tls

Clear-Host

Write-Host ""
Write-Host " ====================================================================== " -ForegroundColor DarkYellow
Write-Host "       VUONGTT TOOL PRO 2026 - HE THONG KY THUAT VIEN DA NANG       " -ForegroundColor Yellow -BackgroundColor Black
Write-Host " ====================================================================== " -ForegroundColor DarkYellow
Write-Host "   Phat trien boi: Truong Thanh Vuong                                   " -ForegroundColor Gray
Write-Host "   Kho luu tru:    https://github.com/truongthanhvuong/toolwindows      " -ForegroundColor DarkCyan
Write-Host "   Nen tang:       Rust Tauri v2 - Fluent OS Utility (14 Man Hinh)      " -ForegroundColor Green
Write-Host " ---------------------------------------------------------------------- " -ForegroundColor DarkGray

# 1. KIEM TRA VA YEU CAU QUYEN QUAN TRI VIEN (ADMINISTRATOR)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n [*] Dang yeu cau quyen quan tri vien (Run as Administrator)..." -ForegroundColor Yellow
    Write-Host " [*] Vui long bam 'YES' tren hop thoai UAC de cap phep hoat dong.`n" -ForegroundColor Cyan
    
    $cleanCmd = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; irm https://tinyurl.com/vuongwin | iex"
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cleanCmd`"" -Verb RunAs
        Stop-Process -Id $PID -Force
        Exit
    } catch {
        $exMsg = $_.Exception.Message
        $isCancelled = ($_.Exception -is [System.ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223) -or ($exMsg -match "canceled by the user")
        if ($isCancelled) {
            Write-Host " [!] Ban da bam 'No' tren hop thoai UAC. Bo cong cu yeu cau quyen Admin de can thiep he thong!" -ForegroundColor Red
        } else {
            Write-Host " [!] Khong the tu dong nang quyen: $exMsg" -ForegroundColor Red
            Write-Host " -> Hay mo PowerShell bang cach nhap chuot phai chon 'Run as Administrator', sau do dan lai lenh:`n    irm tinyurl.com/vuongwin | iex`n" -ForegroundColor Yellow
        }
        return
    }
}

# 2. THIET LAP VUNG CAI DAT AN TOAN
Write-Host "`n [1/4] Thiet lap vung luu tru bo cong cu..." -ForegroundColor Cyan
$installDir   = Join-Path $env:ProgramData "VUONGTT_Toolkit"
$exePath      = Join-Path $installDir "VUONGTT_Toolkit.exe"
$verFilePath  = Join-Path $installDir "installed_version.txt"

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Don dep cache rac tu cac phien ban cu trong TEMP va ProgramData de chong xung dot phien ban
try {
    $staleTempRuntime = Join-Path $env:TEMP "VUONGTT_Toolkit_Runtime"
    if (Test-Path $staleTempRuntime) {
        Remove-Item -Path $staleTempRuntime -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-ChildItem -Path $env:TEMP -Filter "VUONGTT_Toolkit_v*_READY.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $env:TEMP -Filter "VUONGTT_HotSwap_*.cmd" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    $staleRootScript = Join-Path $installDir "VUONGTT_Toolkit.ps1"
    if (Test-Path $staleRootScript) {
        Remove-Item -Path $staleRootScript -Force -ErrorAction SilentlyContinue
    }
} catch {}

# 3. KIEM TRA VA CAI DAT MICROSOFT EDGE WEBVIEW2 (NEU THIEU)
Write-Host "`n [2/4] Kiem tra thanh phan Microsoft Edge WebView2 Runtime..." -ForegroundColor Cyan
$hasWebView2 = $false
try {
    $wvRegKey1 = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
    $wvRegKey2 = Get-ItemProperty -Path "HKCU:\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
    $wvRegKey3 = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -ErrorAction SilentlyContinue
    if ($wvRegKey1.pv -or $wvRegKey2.pv -or $wvRegKey3.pv) {
        $hasWebView2 = $true
    }
} catch {}

if (-not $hasWebView2) {
    $wvPaths = @(
        "$env:ProgramFiles (x86)\Microsoft\EdgeWebView\Application",
        "$env:ProgramFiles\Microsoft\EdgeWebView\Application",
        "$env:LOCALAPPDATA\Microsoft\EdgeWebView\Application"
    )
    foreach ($p in $wvPaths) {
        if (Test-Path $p) {
            $hasWebView2 = $true
            break
        }
    }
}

if ($hasWebView2) {
    Write-Host "  [OK] Microsoft Edge WebView2 Runtime da san sang tren he thong." -ForegroundColor Green
} else {
    Write-Host "  [*] May tinh chua co WebView2 Runtime, dang tu dong tai va cai dat..." -ForegroundColor Yellow
    try {
        $wvInstaller = Join-Path $env:TEMP "MicrosoftEdgeWebview2Setup.exe"
        $wcWv = New-Object System.Net.WebClient
        $wcWv.DownloadFile("https://go.microsoft.com/fwlink/p/?LinkId=2124703", $wvInstaller)
        if (Test-Path $wvInstaller) {
            Start-Process -FilePath $wvInstaller -ArgumentList "/silent /install" -Wait -WindowStyle Hidden
            Remove-Item $wvInstaller -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Cai dat Microsoft Edge WebView2 hoan tat!" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [!] Khong the tu dong cai WebView2: $($_.Exception.Message)" -ForegroundColor DarkYellow
    }
}

# 4. KIEM TRA VA DONG BO BAN MOI NHAT TU GITHUB
Write-Host "`n [3/4] Dang kiem tra va dong bo ban phat hanh moi nhat tu Cloud..." -ForegroundColor Cyan

$localVersion = $null
if (Test-Path $exePath) {
    try {
        $localInfo = (Get-Item $exePath).VersionInfo
        if ($localInfo -and $localInfo.ProductVersion) {
            $localVersion = $localInfo.ProductVersion.Trim()
        }
    } catch {}
}
if (-not $localVersion -and (Test-Path $verFilePath)) {
    try {
        $localVersion = (Get-Content $verFilePath -Raw -ErrorAction SilentlyContinue).Trim()
    } catch {}
}

$latestSha = ""
$latestVer = ""

try {
    $wcApi = New-Object System.Net.WebClient
    $wcApi.Headers.Add("User-Agent", "VUONGTT-Cloud-Bootstrapper/2026")
    $jsonCommits = $wcApi.DownloadString("https://api.github.com/repos/truongthanhvuong/toolwindows/commits/main")
    $objCommits = ConvertFrom-Json $jsonCommits
    if ($objCommits -and $objCommits.sha) {
        $latestSha = $objCommits.sha
    }
} catch {}

$tStamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$verUrls = @()
if ($latestSha) {
    $verUrls += "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/$latestSha/version.json"
}
$verUrls += "https://cdn.jsdelivr.net/gh/truongthanhvuong/toolwindows@main/version.json?t=$tStamp"
$verUrls += "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/version.json?t=$tStamp"

foreach ($vUrl in $verUrls) {
    try {
        $wcVer = New-Object System.Net.WebClient
        $wcVer.Encoding = [System.Text.Encoding]::UTF8
        $wcVer.Headers.Add("User-Agent", "VUONGTT-Cloud-Bootstrapper/2026")
        $vContent = $wcVer.DownloadString($vUrl)
        $vObj = ConvertFrom-Json $vContent
        if ($vObj -and $vObj.version) {
            $latestVer = $vObj.version.Trim()
            Write-Host "  -> Phien ban moi nhat tren Cloud: v$latestVer" -ForegroundColor Green
            break
        }
    } catch {}
}

$needDownload = $true
$fileSize = 0
if (Test-Path $exePath) {
    $fileSize = (Get-Item $exePath).Length
}

if ($localVersion -and $latestVer -and ($fileSize -gt 1000000)) {
    $cmp = Compare-SemVer $latestVer $localVersion
    if ($cmp -le 0) {
        Write-Host "  [OK] May tinh da co san phien ban moi nhat v$localVersion! San sang khoi chay." -ForegroundColor Green
        $needDownload = $false
    } else {
        Write-Host "  [*] Phat hien phien ban moi tren Cloud (v$localVersion -> v$latestVer), dang cap nhat..." -ForegroundColor Yellow
        $needDownload = $true
    }
} elseif (Test-Path $exePath -and ($fileSize -gt 1000000)) {
    Write-Host "  [OK] May tinh da co san ban cai dat v$localVersion. San sang khoi chay." -ForegroundColor Green
    $needDownload = $false
} else {
    Write-Host "  [*] Dang tai ban phat hanh VUONGTT Tool Pro..." -ForegroundColor Yellow
    $needDownload = $true
}

if ($needDownload) {
    $urls = @()
    if ($latestSha) {
        $urls += "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/$latestSha/VUONGTT_Toolkit.exe"
    }
    $urls += "https://github.com/truongthanhvuong/toolwindows/raw/main/VUONGTT_Toolkit.exe?t=$tStamp"
    $urls += "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe"

    $downloadSuccess = $false
    $tempDownload = Join-Path $installDir "VUONGTT_Toolkit_dl.exe"
    if (Test-Path $tempDownload) { Remove-Item $tempDownload -Force -ErrorAction SilentlyContinue }

    # Dung tien trinh cu neu dang chay
    taskkill /F /IM "VUONGTT_Toolkit.exe" /T 2>&1 | Out-Null
    taskkill /F /IM "VUONGTT_Toolkit_Rust.exe" /T 2>&1 | Out-Null
    $stopAttempts = 5
    while ((Get-Process -Name "VUONGTT_Toolkit*" -ErrorAction SilentlyContinue) -and ($stopAttempts -gt 0)) {
        Get-Process -Name "VUONGTT_Toolkit*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 300
        $stopAttempts--
    }

    foreach ($url in $urls) {
        try {
            Write-Host "  -> Dang ket noi may chu: $url" -ForegroundColor Gray
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "VUONGTT-Cloud-Bootstrapper/2026")
            $wc.DownloadFile($url, $tempDownload)

            if ((Test-Path $tempDownload) -and ((Get-Item $tempDownload).Length -gt 1000000)) {
                $downloadSuccess = $true
                break
            }
        } catch {
            Write-Host "  [!] Ket noi link nay khong thanh cong, dang thu nguon du phong..." -ForegroundColor DarkYellow
        }
    }

    if ($downloadSuccess) {
        $replaced = $false
        for ($attempt = 1; $attempt -le 10; $attempt++) {
            taskkill /F /IM "VUONGTT_Toolkit.exe" /T 2>&1 | Out-Null
            taskkill /F /IM "VUONGTT_Toolkit_Rust.exe" /T 2>&1 | Out-Null
            Start-Sleep -Milliseconds 400
            try {
                Unblock-File -Path $tempDownload -ErrorAction SilentlyContinue
                Move-Item -Path $tempDownload -Destination $exePath -Force -ErrorAction Stop
                Unblock-File -Path $exePath -ErrorAction SilentlyContinue
                $replaced = $true
                break
            } catch {
                Start-Sleep -Milliseconds 600
            }
        }
        if ($replaced) {
            $sizeMb = [math]::Round(((Get-Item $exePath).Length / 1MB), 2)
            if ($latestVer) {
                Set-Content -Path $verFilePath -Value $latestVer -Force -Encoding UTF8
            }
            # Dong bo sang ca E:\toolwindows\VUONGTT_Toolkit.exe neu ton tai thu muc repo
            $repoExe = "E:\toolwindows\VUONGTT_Toolkit.exe"
            if ((Test-Path "E:\toolwindows") -and ($exePath -ne $repoExe)) {
                try { Copy-Item -Path $exePath -Destination $repoExe -Force -ErrorAction SilentlyContinue } catch {}
            }
            Write-Host "  -> Tai thanh cong VUONGTT Tool Pro ($sizeMb MB)!" -ForegroundColor Green
        } else {
            Write-Host "  [!] Khong the ghi de file EXE: File dang bi khoa boi tien trinh khac." -ForegroundColor Red
        }
    } else {
        if (Test-Path $exePath -and ((Get-Item $exePath).Length -gt 1000000)) {
            Write-Host "  [!] Khong the tai ban moi tu Cloud do loi mang. Su dung ban san co tren may." -ForegroundColor Yellow
        } else {
            Write-Host "  [LOI] Khong the tai VUONGTT_Toolkit.exe tu Cloud! Vui long kiem tra ket noi mang." -ForegroundColor Red
            return
        }
    }
}

# 5. TAO LOI TAT DESKTOP CONVENIENT SHORTCUT (TU DONG CHAY CLOUD BOOTSTRAPPER)
try {
    $desktopDirs = @(
        [System.Environment]::GetFolderPath('Desktop'),
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\OneDrive\Desktop",
        [System.Environment]::GetFolderPath('CommonDesktopDirectory')
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

    $psPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $bootstrapCmd = '-WindowStyle Hidden -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; try { irm https://tinyurl.com/vuongwin | iex } catch { if (Test-Path \`"' + $exePath + '\`") { Start-Process \`"' + $exePath + '\`" } }"'
    $wshShell = New-Object -ComObject WScript.Shell
    foreach ($d in $desktopDirs) {
        foreach ($scName in @("VUONGTT Toolkit.lnk", "VUONGTT Tool Pro 2026.lnk")) {
            try {
                $shortcut = $wshShell.CreateShortcut((Join-Path $d $scName))
                $shortcut.TargetPath = $psPath
                $shortcut.Arguments = $bootstrapCmd
                $shortcut.WorkingDirectory = $installDir
                $shortcut.Description = "VUONGTT Toolkit 2026 - Tu Dong Cap Nhat & Khoi Chay Ban Moi Nhat"
                $shortcut.IconLocation = "$exePath,0"
                $shortcut.Save()
            } catch {}
        }
    }
} catch {}

# 6. KHOI CHAY UNG DUNG
Write-Host "`n [4/4] Dang khoi chay VUONGTT Tool Pro 2026..." -ForegroundColor Cyan

# Kiem tra neu VUONGTT_Toolkit da dang chay va khong can cap nhat thi khong mo them cua so moi
$existingProc = Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue
if ($existingProc -and (-not $needDownload)) {
    Write-Host "  [OK] Ung dung VUONGTT Toolkit da dang chay tren he thong (PID: $($existingProc[0].Id))." -ForegroundColor Green
    Write-Host "  -> Dang tap trung cua so ung dung..." -ForegroundColor Cyan
    try {
        $wsh = New-Object -ComObject WScript.Shell
        $wsh.AppActivate("VUONGTT Toolkit") | Out-Null
    } catch {}
    Start-Sleep -Seconds 1
    Exit
}

$env:VUONGTT_LIVE_MODE = "1"

$proc = $null
try {
    $proc = Start-Process -FilePath $exePath -WorkingDirectory $installDir -PassThru -ErrorAction Stop
} catch {
    Write-Host "  [!] Khoi chay that bai: $($_.Exception.Message)" -ForegroundColor Red
}

if ($proc) {
    $displayVer = if ($latestVer) { "v$latestVer" } elseif ($localVersion) { "v$localVersion" } else { "2026" }
    Write-Host ""
    Write-Host " ====================================================================== " -ForegroundColor Green
    Write-Host "  [OK] VUONGTT TOOL PRO 2026 DA DUOC KHOI CHAY THANH CONG!              " -ForegroundColor Green
    Write-Host "  [+] Phien ban: $displayVer (Rust Tauri v2 - Fluent OS Utility)       " -ForegroundColor Yellow
    Write-Host "  [+] Da tao loi tat 'VUONGTT Tool Pro 2026' tren man hinh Desktop      " -ForegroundColor Cyan
    Write-Host "  [+] Cua so console nay se tu dong dong sau 2 giay...                  " -ForegroundColor Gray
    Write-Host " ====================================================================== " -ForegroundColor Green
    
    Start-Sleep -Seconds 2
    [System.Environment]::Exit(0)
    Stop-Process -Id $PID -Force
}
