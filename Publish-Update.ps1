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
Write-Host "`n>>> [2/5] Dang bien dich VUONGTT_Toolkit.exe..." -ForegroundColor Yellow
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

# 5. Git Commit va Push len GitHub voi co che tu dong Rebase & Retry
Write-Host "`n>>> [3/5] Dang day ban moi v$targetVer len GitHub..." -ForegroundColor Yellow
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
        Write-Host "`n>>> [4/5] Dang lam moi (Purge) cache CDN toan cau..." -ForegroundColor Yellow
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

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "CHÚC MỪNG! ĐÃ PHÁT HÀNH BẢN v$targetVer LÊN GITHUB THÀNH CÔNG!`n`n" +
            "• Phiên bản mới: v$targetVer`n" +
            "• Dung lượng EXE: $exeSize KB`n`n" +
            "Tất cả các máy Client chỉ cần bấm 'Cập Nhật Tool' hoặc mở Tool lên là sẽ tự động nâng cấp!",
            "Phát Hành Thành Công - VUONGTT Toolkit 2026",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } catch {}
} else {
    Write-Host "`n[CANH BAO] Push len GitHub chua hoan tat. Vui long kiem tra ket noi mang hoac tai khoan GitHub!" -ForegroundColor Red
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    try {
        [System.Windows.Forms.MessageBox]::Show(
            "CẢNH BÁO: Không thể đẩy bản cập nhật lên GitHub!`n`n" +
            "Vui lòng kiểm tra lại kết nối mạng Internet hoặc thông tin tài khoản Git.",
            "Lỗi Phát Hành GitHub",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    } catch {}
}

Write-Host "`n"
Read-Host "Bam Enter de dong cua so..."
