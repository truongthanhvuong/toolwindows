$Host.UI.RawUI.WindowTitle = "VUONGTT Tool Pro 2026 - Cloud Bootstrapper"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13 -bor [System.Net.SecurityProtocolType]::Tls

Clear-Host
# Vo hieu hoa QuickEdit Mode tren Console de ngan chan freeze tien trinh khi click chuot
try {
    $consoleTypeDef = @"
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
"@
    if (-not ([System.Management.Automation.PSTypeName]'VUONGTT.Win32Console').Type) {
        Add-Type -MemberDefinition $consoleTypeDef -Name "Win32Console" -Namespace "VUONGTT" -ErrorAction SilentlyContinue
    }
    $hIn = [VUONGTT.Win32Console]::GetStdHandle(-10) # STD_INPUT_HANDLE
    $mode = 0
    if ([VUONGTT.Win32Console]::GetConsoleMode($hIn, [ref]$mode)) {
        # 0x0040 = ENABLE_QUICK_EDIT_MODE, 0x0080 = ENABLE_EXTENDED_FLAGS
        $newMode = ($mode -band (-bnot 0x0040)) -bor 0x0080
        [VUONGTT.Win32Console]::SetConsoleMode($hIn, $newMode) | Out-Null
    }
} catch {}

Write-Host ""
Write-Host " ====================================================================== " -ForegroundColor DarkYellow
Write-Host "       VUONGTT TOOL PRO 2026 - HE THONG KY THUAT VIEN DA NANG       " -ForegroundColor Yellow -BackgroundColor Black
Write-Host " ====================================================================== " -ForegroundColor DarkYellow
Write-Host "   Phat trien boi: Truong Thanh Vuong                                   " -ForegroundColor Gray
Write-Host "   Kho luu tru:    https://github.com/truongthanhvuong/toolwindows      " -ForegroundColor DarkCyan
Write-Host " ---------------------------------------------------------------------- " -ForegroundColor DarkGray

# 1. KIEM TRA VA YEU CAU QUYEN QUAN TRI VIEN (ADMINISTRATOR)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n [*] Dang yeu cau quyen quan tri vien (Run as Administrator)..." -ForegroundColor Yellow
    Write-Host " [*] Vui long bam 'YES' tren hop thoai UAC de cap phep hoat dong.`n" -ForegroundColor Cyan
    
    # Su dung -EncodedCommand (Base64 UTF-16LE) de tranh tuyet doi loi parse quote/ky tu dac biet
    $bootstrapRaw = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; irm https://tinyurl.com/vuongwin | iex"
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($bootstrapRaw)
    $encodedCmd = [Convert]::ToBase64String($bytes)

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCmd" -Verb RunAs
        # Khi da kich hoat tien trinh Administrator thanh cong, tu dong dong ngay cua so console cu
        Stop-Process -Id $PID -Force
        Exit
    } catch {
        $exMsg = $_.Exception.Message
        $isCancelled = ($_.Exception -is [System.ComponentModel.Win32Exception] -and $_.Exception.NativeErrorCode -eq 1223) -or ($exMsg -match "canceled by the user")
        if ($isCancelled) {
            Write-Host " [!] Ban da bam 'No' (Tu choi) tren hop thoai UAC. Bo cong cu yeu cau quyen Admin de can thiep he thong!" -ForegroundColor Red
        } else {
            Write-Host " [!] Khong the tu dong nang quyen: $exMsg" -ForegroundColor Red
            Write-Host " ðŸ‘‰ Giai phap: Hay mo PowerShell bang cach nhap chuot phai chon 'Run as Administrator', sau do dan lai lenh:`n    irm tinyurl.com/vuongwin | iex`n" -ForegroundColor Yellow
        }
        return
    }
}

# 2. THIET LAP VUNG CAI DAT AN TOAN & CAU HINH WINDOWS DEFENDER EXCLUSION
Write-Host "`n [1/3] Thiet lap vung luu tru an toan & Dang ky ngoai le Windows Defender..." -ForegroundColor Cyan
$installDir = Join-Path $env:ProgramData "VUONGTT_Toolkit"
$exePath    = Join-Path $installDir "VUONGTT_Toolkit.exe"

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

# Them Exclusion truc tiep vao Windows Defender de Defender KHONG BAO GIO scan hoac xoa file
try {
    Add-MpPreference -ExclusionPath $installDir -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "VUONGTT_Toolkit.exe" -ErrorAction SilentlyContinue
    Write-Host "  -> Da bao ve an toan thu muc va tien trinh khoi Windows Defender (Chong xoa nham)" -ForegroundColor Green
} catch {
    Write-Host "  -> Khong the goi Add-MpPreference (Co the Defender da bi tat hoac dung AV khac)" -ForegroundColor Gray
}

# 3. KIEM TRA VA TAI BAN MOI NHAT TU GITHUB / CDN (CHONG STALE CACHE & CHECK VERSION)
Write-Host "`n [2/3] Dang kiem tra va dong bo ban phat hanh moi nhat tu Cloud..." -ForegroundColor Cyan

# 3.1. Kiem tra phien ban hien co tren may (neu co)
$localVersion = $null
if (Test-Path $exePath) {
    try {
        $localInfo = (Get-Item $exePath).VersionInfo
        if ($localInfo -and $localInfo.ProductVersion) {
            $localVersion = $localInfo.ProductVersion.Trim()
            Write-Host "  -> Phien ban hien co tren may: v$localVersion" -ForegroundColor Gray
        }
    } catch {}
}

# 3.2. Truy van Commit SHA va version.json moi nhat tu Cloud de chong stale cache
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

# Lay thong tin version.json tu Cloud (Uu tien dung duong dan SHA de 0s cache)
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

# 3.3. Xac dinh co can tai ban moi khong
# Neu da co file va version khop voi ban moi nhat tren Cloud -> Bo qua buoc tai de tiet kiem thoi gian
$needDownload = $true
if ($localVersion -and $latestVer -and ($localVersion -eq $latestVer) -and ((Get-Item $exePath).Length -gt 1000000)) {
    Write-Host "  [OK] May tinh da co san phien ban moi nhat v$localVersion! San sang khoi chay." -ForegroundColor Green
    $needDownload = $false
} elseif ($localVersion -and $latestVer -and ($localVersion -ne $latestVer)) {
    Write-Host "  [*] Phat hien phien ban moi (v$localVersion -> v$latestVer), dang tien hanh cap nhat..." -ForegroundColor Yellow
}

if ($needDownload) {
    # 3.4. Xay dung danh sach URL tai (Uu tien duong dan Commit SHA de chong 100% cache cu cua Fastly)
    $urls = @()
    if ($latestSha) {
        $urls += "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/$latestSha/VUONGTT_Toolkit.exe"
    }
    $urls += "https://github.com/truongthanhvuong/toolwindows/raw/main/VUONGTT_Toolkit.exe?t=$tStamp"
    $urls += "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe"

    $downloadSuccess = $false
    $tempDownload = Join-Path $installDir "VUONGTT_Toolkit_dl.exe"
    if (Test-Path $tempDownload) { Remove-Item $tempDownload -Force -ErrorAction SilentlyContinue }

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
        try {
            Unblock-File -Path $tempDownload -ErrorAction SilentlyContinue

            # Neu tien trinh cu dang chay, dung lai va cho giai phong file lock triet de
            $stopAttempts = 10
            while ((Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue) -and ($stopAttempts -gt 0)) {
                Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 300
                $stopAttempts--
            }

            # Thu ghi de file voi vong lap thu lai neu con bi lock boi he thong
            $overwriteOk = $false
            for ($attempt = 1; $attempt -le 5; $attempt++) {
                try {
                    Move-Item -Path $tempDownload -Destination $exePath -Force
                    $overwriteOk = $true
                    break
                } catch {
                    Start-Sleep -Milliseconds 400
                }
            }

            if ($overwriteOk) {
                Unblock-File -Path $exePath -ErrorAction SilentlyContinue
                $sizeMb = [math]::Round(((Get-Item $exePath).Length / 1MB), 2)
                $finalVer = (Get-Item $exePath).VersionInfo.ProductVersion
                Write-Host "  -> Cap nhat thanh cong ban moi nhat v$finalVer ($sizeMb MB)!" -ForegroundColor Green
            } else {
                Write-Host "  [!] Khong the ghi de file do he thong dang khoa file, dang dung file hien co..." -ForegroundColor Red
            }
        } catch {
            Write-Host "  [!] Khong the ghi de file EXE: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        if (Test-Path $exePath) {
            Write-Host "  [!] Khong the tai ban moi tu Cloud do loi mang. May tinh se tam thoi su dung ban san co tren may." -ForegroundColor Yellow
        } else {
            Write-Host "  [LOI NGUY HIEM] Khong the tai duoc VUONGTT_Toolkit.exe tu may chu Cloud! Vui long kiem tra ket noi mang." -ForegroundColor Red
            return
        }
    }
}

# Don sach shortcut Desktop neu ton tai tu phien ban truoc (Theo yeu cau nguoi dung)
try {
    $desktops = @("$home\Desktop", "$env:PUBLIC\Desktop")
    foreach ($desk in $desktops) {
        if (Test-Path $desk) {
            $oldLnk = Join-Path $desk "VUONGTT Tool Pro 2026.lnk"
            if (Test-Path $oldLnk) { Remove-Item $oldLnk -Force -ErrorAction SilentlyContinue }
        }
    }
} catch {}

# 4. KHOI CHAY UNG DUNG (CHE DO LIVE - TU DONG XOA SACH KHI DONG)
Write-Host "`n [3/3] Khoi dong VUONGTT Tool Pro 2026 (Che do Live - Tu dong don sach khi dong)..." -ForegroundColor Cyan
try {
    $proc = Start-Process -FilePath $exePath -ArgumentList "--live" -WorkingDirectory $installDir -PassThru
    Write-Host "`n ====================================================================== " -ForegroundColor Green
    Write-Host "  [OK] TOOL DA DUOC KHOI CHAY THANH CONG TREN MAN HINH!" -ForegroundColor Green
    Write-Host "  [*] Cua so nay se tu dong dong ngay khi ban tat VUONGTT Tool Pro." -ForegroundColor Yellow
    Write-Host " ====================================================================== `n" -ForegroundColor Green

    # Theo doi tien trinh tool: khi nao tool dong thi tu dong don dep va dong cua so
    while ($true) {
        if ($proc -and $proc.HasExited) { break }
        $running = Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue
        if (-not $running) { break }
        Start-Sleep -Milliseconds 500
    }

    Start-Sleep -Milliseconds 600
    Remove-Item -Path $exePath -Force -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $installDir "runtime") -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "`n [OK] Da tu dong don dep sach se file khoi may tinh! Dang dong cua so..." -ForegroundColor Green
    Start-Sleep -Milliseconds 500

    # Tu dong tat/dong ngay lap tuc cua so PowerShell Console nay
    [System.Environment]::Exit(0)
    Stop-Process -Id $PID -Force
} catch {
    Write-Host "  [!] Khong the khoi chay file EXE: $($_.Exception.Message)" -ForegroundColor Red
}
