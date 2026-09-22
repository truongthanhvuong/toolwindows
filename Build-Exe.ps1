# =========================================================================
#   VUONGTT TOOLKIT 2026 - EXE COMPILER SCRIPT
#   Bien dich toan bo ma nguon thanh 1 file VUONGTT_Toolkit.exe duy nhat
# =========================================================================
param(
    [switch]$NoBump = $false,
    [string]$TargetVersion = ""
)

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $RootDir) { $RootDir = "E:\toolwindows" }

# =========================================================================
# TU DONG NANG PHIEN BAN (+1 BUILD) DONG BO KHI BUILD LOCAL
# =========================================================================
if (-not $NoBump) {
    $verJsonPath = Join-Path $RootDir "version.json"
    $curVer = "20.5.909.01"
    if (Test-Path $verJsonPath) {
        try {
            $vObj = Get-Content -Path $verJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($vObj -and $vObj.version) { $curVer = $vObj.version.Trim() }
        } catch {}
    }

    $newVer = ""
    if ($TargetVersion) {
        $newVer = $TargetVersion.Trim()
    } else {
        $parts = $curVer.Split('.')
        if ($parts.Count -ge 4) {
            $buildNum = 0
            [int]::TryParse($parts[3], [ref]$buildNum) | Out-Null
            $nextBuild = $buildNum + 1
            $nextBuildStr = if ($nextBuild -lt 10) { "0$nextBuild" } else { "$nextBuild" }
            $newVer = "$($parts[0]).$($parts[1]).$($parts[2]).$nextBuildStr"
        } else {
            $newVer = "$curVer.1"
        }
    }

    Write-Host ">>> [VERSION BUMP] Tu dong nang phien ban: v$curVer -> v$newVer" -ForegroundColor Green

    # 1. version.json
    try {
        $vObj = Get-Content -Path $verJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $vObj.version = $newVer
        $vObj.releaseDate = (Get-Date).ToString("dd/MM/yyyy")
        $vObj | ConvertTo-Json -Depth 5 | Set-Content -Path $verJsonPath -Encoding UTF8
    } catch {}

    # 2. AppUpdater.ps1
    $updFile = Join-Path $RootDir "src\Core\AppUpdater.ps1"
    if (Test-Path $updFile) {
        $txt = [System.IO.File]::ReadAllText($updFile, [System.Text.Encoding]::UTF8)
        $txt = $txt -replace '\$script:APP_CURRENT_VERSION\s*=\s*"[^"]+"', "`$script:APP_CURRENT_VERSION = `"$newVer`""
        [System.IO.File]::WriteAllText($updFile, $txt, (New-Object System.Text.UTF8Encoding($true)))
    }

    # 3. Program.cs
    $csFile = Join-Path $RootDir "src\Program.cs"
    if (Test-Path $csFile) {
        $txt = [System.IO.File]::ReadAllText($csFile, [System.Text.Encoding]::UTF8)
        $txt = $txt -replace 'v\d+\.\d+\.\d+\.\d+', "v$newVer"
        $txt = $txt -replace 'AssemblyVersion\("[^"]+"\)', "AssemblyVersion(`"$newVer`")"
        $txt = $txt -replace 'AssemblyFileVersion\("[^"]+"\)', "AssemblyFileVersion(`"$newVer`")"
        [System.IO.File]::WriteAllText($csFile, $txt, (New-Object System.Text.UTF8Encoding($true)))
    }

    # 4. MainWindow.xaml
    $xamlFile = Join-Path $RootDir "src\UI\MainWindow.xaml"
    if (Test-Path $xamlFile) {
        $txt = [System.IO.File]::ReadAllText($xamlFile, [System.Text.Encoding]::UTF8)
        $txt = $txt -replace 'v\d+\.\d+\.\d+\.\d+', "v$newVer"
        [System.IO.File]::WriteAllText($xamlFile, $txt, (New-Object System.Text.UTF8Encoding($true)))
    }

    # 5. VUONGTT_Toolkit.ps1
    $mainPs1 = Join-Path $RootDir "VUONGTT_Toolkit.ps1"
    if (Test-Path $mainPs1) {
        $txt = [System.IO.File]::ReadAllText($mainPs1, [System.Text.Encoding]::UTF8)
        $txt = $txt -replace 'VER\s+\d+\.\d+\.\d+\.\d+', "VER $newVer"
        [System.IO.File]::WriteAllText($mainPs1, $txt, (New-Object System.Text.UTF8Encoding($true)))
    }
}

$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $cscPath)) {
    $cscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (-not (Test-Path $cscPath)) {
    Write-Error "Khong tim thay trinh bien dich csc.exe trong he thong Windows!"
    Exit 1
}

Write-Host ">>> Trinh bien dich C#: $cscPath" -ForegroundColor Cyan

# Dam bao 100% cac file ma nguon ps1, xaml, json, cs deu co UTF-8 BOM tranh loi font/ky tu tieng Viet trong PowerShell va csc
$utf8Bom = New-Object System.Text.UTF8Encoding($true)
$textFilesToEnforce = Get-ChildItem -Path $RootDir -Recurse -Include "*.ps1", "*.xaml", "*.json", "*.cs" -File | Where-Object { $_.FullName -notmatch "\\\.git\\" }
foreach ($tf in $textFilesToEnforce) {
    try {
        $bytes = [System.IO.File]::ReadAllBytes($tf.FullName)
        if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
            $content = [System.IO.File]::ReadAllText($tf.FullName, [System.Text.Encoding]::UTF8)
            [System.IO.File]::WriteAllText($tf.FullName, $content, $utf8Bom)
        }
    } catch {}
}

$outputExe = Join-Path $RootDir "VUONGTT_Toolkit.exe"
$programCs = Join-Path $RootDir "src\Program.cs"
$iconPath  = Join-Path $RootDir "src\Assets\AppIcon.ico"

$resources = @(
    "/resource:`"$RootDir\VUONGTT_Toolkit.ps1`",VUONGTT.VUONGTT_Toolkit.ps1",
    "/resource:`"$RootDir\src\UI\MainWindow.xaml`",VUONGTT.MainWindow.xaml",
    "/resource:`"$RootDir\src\UI\OfficeAIOModal.xaml`",VUONGTT.OfficeAIOModal.xaml",
    "/resource:`"$RootDir\src\Core\HardwareInfo.ps1`",VUONGTT.HardwareInfo.ps1",
    "/resource:`"$RootDir\src\Core\OfficeInstaller.ps1`",VUONGTT.OfficeInstaller.ps1",
    "/resource:`"$RootDir\src\Core\Activator.ps1`",VUONGTT.Activator.ps1",
    "/resource:`"$RootDir\src\Core\NetworkPrinterFix.ps1`",VUONGTT.NetworkPrinterFix.ps1",
    "/resource:`"$RootDir\src\Core\SystemTweaks.ps1`",VUONGTT.SystemTweaks.ps1",
    "/resource:`"$RootDir\src\Core\BitLockerManager.ps1`",VUONGTT.BitLockerManager.ps1",
    "/resource:`"$RootDir\src\Core\SoftwareInstaller.ps1`",VUONGTT.SoftwareInstaller.ps1",
    "/resource:`"$RootDir\src\Core\SystemCustomizer.ps1`",VUONGTT.SystemCustomizer.ps1",
    "/resource:`"$RootDir\src\Core\UserManager.ps1`",VUONGTT.UserManager.ps1",
    "/resource:`"$RootDir\src\Core\CpuMainDatabase.ps1`",VUONGTT.CpuMainDatabase.ps1",
    "/resource:`"$RootDir\src\Core\LaptopTester.ps1`",VUONGTT.LaptopTester.ps1",
    "/resource:`"$RootDir\src\Core\FontInstaller.ps1`",VUONGTT.FontInstaller.ps1",
    "/resource:`"$RootDir\src\Core\PartitionManager.ps1`",VUONGTT.PartitionManager.ps1",
    "/resource:`"$RootDir\src\Core\AccountingApps.ps1`",VUONGTT.AccountingApps.ps1",
    "/resource:`"$RootDir\src\Core\AppUpdater.ps1`",VUONGTT.AppUpdater.ps1",
    "/resource:`"$RootDir\src\Core\LicenseManager.ps1`",VUONGTT.LicenseManager.ps1",
    "/resource:`"$RootDir\src\Core\IpScanner.ps1`",VUONGTT.IpScanner.ps1",
    "/resource:`"$RootDir\src\Core\ConfigManager.ps1`",VUONGTT.ConfigManager.ps1",
    "/resource:`"$RootDir\src\Core\DiskHealthManager.ps1`",VUONGTT.DiskHealthManager.ps1",
    "/resource:`"$RootDir\src\Core\AutoWinDeployer.ps1`",VUONGTT.AutoWinDeployer.ps1",
    "/resource:`"$RootDir\src\Config\licenses_vault.json`",VUONGTT.licenses_vault.json",
    "/resource:`"$RootDir\src\Config\feature_policy.json`",VUONGTT.feature_policy.json",
    "/resource:`"$RootDir\src\Data\SoftwareDatabase.json`",VUONGTT.SoftwareDatabase.json",
    "/resource:`"$RootDir\version.json`",VUONGTT.version.json"
)

# Auto embed all colorful brand icons from src\Assets\AppIcons
$appIconFiles = Get-ChildItem -Path (Join-Path $RootDir "src\Assets\AppIcons") -Filter "*.png"
foreach ($icon in $appIconFiles) {
    $resources += "/resource:`"$($icon.FullName)`",VUONGTT.AppIcons.$($icon.Name)"
}

$references = @(
    "/r:System.dll",
    "/r:System.Core.dll",
    "/r:System.Windows.Forms.dll",
    "/r:System.Drawing.dll"
)

$argsList = @(
    "/target:winexe",
    "/platform:anycpu",
    "/optimize+",
    "/out:`"$outputExe`"",
    "/win32icon:`"$iconPath`""
) + $references + $resources + @("`"$programCs`"")

# Handle locked file if application is currently open
if (Test-Path $outputExe) {
    try {
        [System.IO.File]::OpenWrite($outputExe).Close()
    } catch {
        $backup = "$RootDir\VUONGTT_Toolkit.old_$([guid]::NewGuid().ToString().Substring(0,8)).exe"
        Move-Item $outputExe $backup -Force
    }
}

Write-Host ">>> Bat dau dong goi VUONGTT_Toolkit.exe..." -ForegroundColor Yellow

$proc = Start-Process -FilePath $cscPath -ArgumentList $argsList -NoNewWindow -Wait -PassThru

if ($proc.ExitCode -eq 0 -and (Test-Path $outputExe)) {
    $size = (Get-Item $outputExe).Length / 1KB
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host "[THANH CONG] Da tao thanh cong file: VUONGTT_Toolkit.exe" -ForegroundColor Green
    Write-Host "Dung luong: $([math]::Round($size, 2)) KB" -ForegroundColor Green
    Write-Host "Duong dan: $outputExe" -ForegroundColor Green
    Write-Host "Dac quyen: Administrator Tu dong tu nang quyen qua UAC (runas)" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
} else {
    Write-Error "Qua trinh bien dich that bai voi ma loi: $($proc.ExitCode)"
    Exit 1
}
