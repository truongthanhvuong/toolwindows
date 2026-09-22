# =========================================================================
#   VUONGTT TOOLKIT 2026 - 1-CLICK RELEASE & AUTO-UPDATE PUBLISHER
#   Chuc nang: Tu dong dong goi EXE, cap nhat version va push len GitHub
#              de tat ca cac may khach hang bam 'Cap Nhat Tool' la nhan ngay ban moi.
# =========================================================================
param(
    [string]$Version = "",
    [string]$ChangelogMessage = ""
)

$rootDir = $PSScriptRoot
if (-not $rootDir) { $rootDir = (Get-Location).Path }

# Yeu cau dac quyen Administrator de build va chay smoke test
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ">>> Dang tu dong nang quyen Administrator cho Publish-Update.ps1..." -ForegroundColor Yellow
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Version) { $argList += " -Version `"$Version`"" }
    if ($ChangelogMessage) { $argList += " -ChangelogMessage `"$ChangelogMessage`"" }
    Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
    Exit
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   VUONGTT TOOLKIT 2026 - TIEN TRINH PHAT HANH BAN MOI   " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 0. Kiem tra va dong bo du lieu moi nhat tu GitHub truoc khi dong goi
Write-Host "`n>>> [0/5] Dang dong bo du lieu moi nhat tu GitHub (git pull --rebase)..." -ForegroundColor Cyan
git pull --rebase origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host " [!] Canh bao: Co the gap xung dot khi rebase, dang kiem tra lai..." -ForegroundColor Yellow
}

# 1. Xac dinh so hieu phien ban tiep theo
$verJsonPath = Join-Path $rootDir "version.json"
$currentVer = "20.5.908.55"
if (Test-Path $verJsonPath) {
    try {
        $vObj = Get-Content -Path $verJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($vObj -and $vObj.version) { $currentVer = $vObj.version.Trim() }
    } catch {}
}

if (-not $Version) {
    $parts = $currentVer.Split('.')
    if ($parts.Count -ge 4) {
        $lastNum = 0
        [int]::TryParse($parts[3], [ref]$lastNum) | Out-Null
        $newBuild = $lastNum + 1
        $targetVer = "$($parts[0]).$($parts[1]).$($parts[2]).$newBuild"
    } else {
        $targetVer = "$currentVer.1"
    }
} else {
    $targetVer = $Version.Trim()
}

Write-Host "`n>>> [1/5] Phien ban hien tai: v$currentVer --> Phien ban moi: v$targetVer" -ForegroundColor Green

# 2. Dong bo so phien ban vao version.json
try {
    $verData = Get-Content -Path $verJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $verData.version = $targetVer
    $verData.releaseDate = (Get-Date).ToString("dd/MM/yyyy")
    if ($ChangelogMessage) {
        $verData.changelog = @($ChangelogMessage) + @($verData.changelog)
    }
    $verData | ConvertTo-Json -Depth 5 | Set-Content -Path $verJsonPath -Encoding UTF8
    Write-Host " -> Da cap nhat version.json" -ForegroundColor Gray
} catch {
    Write-Host " [!] Khong the cap nhat version.json: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Dong bo so phien ban vao cac tep ma nguon
$appUpdaterFile = Join-Path $rootDir "src\Core\AppUpdater.ps1"
if (Test-Path $appUpdaterFile) {
    $c = [System.IO.File]::ReadAllText($appUpdaterFile, [System.Text.Encoding]::UTF8)
    $c = $c -replace '\$script:APP_CURRENT_VERSION\s*=\s*"[^"]+"', "`$script:APP_CURRENT_VERSION = `"$targetVer`""
    [System.IO.File]::WriteAllText($appUpdaterFile, $c, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host " -> Da cap nhat src\Core\AppUpdater.ps1" -ForegroundColor Gray
}

$programCsFile = Join-Path $rootDir "src\Program.cs"
if (Test-Path $programCsFile) {
    $c = [System.IO.File]::ReadAllText($programCsFile, [System.Text.Encoding]::UTF8)
    $c = $c -replace 'v20\.5\.908\.\d+', "v$targetVer"
    [System.IO.File]::WriteAllText($programCsFile, $c, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host " -> Da cap nhat src\Program.cs" -ForegroundColor Gray
}

$xamlFile = Join-Path $rootDir "src\UI\MainWindow.xaml"
if (Test-Path $xamlFile) {
    $c = [System.IO.File]::ReadAllText($xamlFile, [System.Text.Encoding]::UTF8)
    $c = $c -replace 'v20\.5\.908\.\d+', "v$targetVer"
    [System.IO.File]::WriteAllText($xamlFile, $c, (New-Object System.Text.UTF8Encoding($true)))
    Write-Host " -> Da cap nhat src\UI\MainWindow.xaml" -ForegroundColor Gray
}

# 4. Bien dich lai file EXE
Write-Host "`n>>> [2/6] Dang bien dich VUONGTT_Toolkit.exe..." -ForegroundColor Yellow
$buildScript = Join-Path $rootDir "Build-Exe.ps1"
& powershell -ExecutionPolicy Bypass -File $buildScript
$exePath = Join-Path $rootDir "VUONGTT_Toolkit.exe"
if (-not (Test-Path $exePath)) {
    Write-Host "[THAT BAI] Khong tao duoc file EXE!" -ForegroundColor Red
    [void][System.Windows.Forms.MessageBox]::Show("Khong the bien dich VUONGTT_Toolkit.exe! Vui long kiem tra loi code.", "Loi Bien Dich", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}
$exeSize = [math]::Round((Get-Item $exePath).Length / 1KB, 1)
Write-Host " -> Bien dich thanh cong! File EXE: $exeSize KB" -ForegroundColor Green

# 4.5 Pre-flight Smoke Test: Kiem thu tu dong khoi chay EXE trong 6 giay de ngan ngua 100% rui ro crash tren 1.000 may Client
Write-Host "`n>>> [3/6] Dang thuc hien Pre-flight Smoke Test tren file EXE vua bien dich..." -ForegroundColor Yellow
Write-Host " -> Khoi chay tien trinh thu nghiem (che do --smoke-test): $exePath" -ForegroundColor Gray

$smokeErrFile = Join-Path $env:TEMP "VUONGTT_Toolkit_Runtime\error.log"
if (Test-Path $smokeErrFile) { Remove-Item $smokeErrFile -Force -ErrorAction SilentlyContinue }

$smokeProc = Start-Process -FilePath $exePath -ArgumentList "--smoke-test" -PassThru -ErrorAction Stop
$testDurationSec = 6
$hasCrashed = $false

for ($s = 1; $s -le $testDurationSec; $s++) {
    Start-Sleep -Seconds 1
    Write-Host " -> Theo doi do on dinh he thong... ($s/$testDurationSec s)" -ForegroundColor Gray
    
    # 1. Neu tien trinh chinh bi thoat voi ma loi != 0 -> Crash chac chan
    if ($smokeProc.HasExited -and $smokeProc.ExitCode -ne 0) {
        $hasCrashed = $true
        break
    }
    
    # 2. Neu tien trinh chinh thoat voi ExitCode == 0, kiem tra tien trinh PowerShell con
    if ($smokeProc.HasExited -and $smokeProc.ExitCode -eq 0) {
        $childPs = Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
            try {
                $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
                $cmd -like "*VUONGTT_Toolkit*"
            } catch { $false }
        }
        if (-not $childPs) {
            $hasCrashed = $true
            break
        }
    }
}

if ($hasCrashed) {
    $exitCode = $smokeProc.ExitCode
    Write-Host "`n==========================================================" -ForegroundColor Red
    Write-Host " [NGUY HIEM] PRE-FLIGHT SMOKE TEST THAT BAI!" -ForegroundColor Red
    Write-Host " File EXE bi vang/crash trong $testDurationSec giay dau (ExitCode: $exitCode)!" -ForegroundColor Red
    Write-Host " TIEN TRINH PHAT HANH BI HUY BO DE BAO VE 1.000 MAY CLIENT!" -ForegroundColor Red
    Write-Host " TUYET DOI KHONG THUC HIEN COMMIT HOAC PUSH GITHUB!" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Red

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show(
            "PRE-FLIGHT SMOKE TEST THAT BAI!`n`nFile VUONGTT_Toolkit.exe vua bien dich bi vang/crash trong $testDurationSec giay dau (ExitCode: $exitCode).`n`nHe thong da tu dong CHAN phat hanh de tranh lam hong 1.000 may Client!`nVui long kiem tra va sua loi truoc khi phat hanh lai.",
            "Phat Hanh Bi Huy Bo - Smoke Test Failed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } catch {}
    exit 1
}

Write-Host " -> [XAC NHAN] Pre-flight Smoke Test PASS! File EXE chay on dinh tren $testDurationSec giay khong loi!" -ForegroundColor Green
try {
    Stop-Process -Id $smokeProc.Id -Force -ErrorAction SilentlyContinue
    Get-Process -Name "powershell" -ErrorAction SilentlyContinue | Where-Object {
        try {
            $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            $cmd -like "*VUONGTT_Toolkit*"
        } catch { $false }
    } | Stop-Process -Force -ErrorAction SilentlyContinue
} catch {}

# 5. Git Commit va Push len GitHub voi co che tu dong Rebase & Retry
Write-Host "`n>>> [4/6] Dang day ban moi v$targetVer len GitHub..." -ForegroundColor Yellow

git add -A
$commitMsg = "release: v$targetVer - $(if ($ChangelogMessage) { $ChangelogMessage } else { 'Auto-update release for client machines' })"
git commit -m $commitMsg

$pushSuccess = $false
for ($attempt = 1; $attempt -le 3; $attempt++) {
    Write-Host " -> Dang thuc hien git push origin main (Lan thu $attempt)..." -ForegroundColor Gray
    git push origin main
    if ($LASTEXITCODE -eq 0) {
        $pushSuccess = $true
        break
    } else {
        Write-Host " [!] Push bi tu choi do GitHub co commit moi. Dang tu dong pull --rebase..." -ForegroundColor Yellow
        git pull --rebase origin main
        Start-Sleep -Seconds 1
    }
}

if ($pushSuccess) {
    # 6. Purge cache CDN toan cau de tat ca may khach nhan dien tuc thi trong 1s
    try {
        Write-Host "`n>>> [5/5] Dang lam moi (Purge) cache CDN toan cau..." -ForegroundColor Yellow
        $purgeUrl = "https://purge.jsdelivr.net/gh/truongthanhvuong/toolwindows@main/version.json"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "VUONGTT-Release-Publisher/2026")
        $pRes = $wc.DownloadString($purgeUrl)
        Write-Host " -> Da lam moi cache CDN toan cau thanh cong (0s Latency)!" -ForegroundColor Green
    } catch {
        Write-Host " [!] Bo qua lam moi CDN: $($_.Exception.Message)" -ForegroundColor Gray
    }

    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host " [THANH CONG RUC RO] DA PHAT HANH BAN v$targetVer LEN GITHUB!" -ForegroundColor Green
    Write-Host " Tat ca cac may khach hang chi can bam 'Cap Nhat Tool'" -ForegroundColor Yellow
    Write-Host " la se tu dong tai va cap nhat len phien ban v$targetVer!" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Green

    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $successMsg = "CHUC MUNG! DA PHAT HANH BAN v$targetVer LEN GITHUB THANH CONG!`n`n" +
                      "- Phien ban moi: v$targetVer`n" +
                      "- Dung luong EXE: $exeSize KB`n`n" +
                      "Tat ca cac may Client chi can bam 'Cap Nhat Tool' la se tu dong nhan ban moi!"
        [System.Windows.Forms.MessageBox]::Show($successMsg, "Phat Hanh Thanh Cong - VUONGTT Toolkit 2026", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {}
} else {
    Write-Host "`n[CANH BAO] Push len GitHub chua hoan tat. Vui long kiem tra ket noi mang hoac tai khoan GitHub!" -ForegroundColor Red
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $failMsg = "CANH BAO: Khong the day ban cap nhat len GitHub!`n`nVui long kiem tra lai ket noi mang Internet hoac thong tin tai khoan Git."
        [System.Windows.Forms.MessageBox]::Show($failMsg, "Loi Phat Hanh GitHub", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    } catch {}
}

Write-Host "`n"
Read-Host "Bam phim Enter de dong cua so..."
