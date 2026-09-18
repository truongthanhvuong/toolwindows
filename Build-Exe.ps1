# =========================================================================
#   VUONGTT TOOLKIT 2026 - EXE COMPILER SCRIPT
#   Bien dich toan bo ma nguon thanh 1 file VUONGTT_Toolkit.exe duy nhat
# =========================================================================

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $RootDir) { $RootDir = "E:\toolwindows" }

$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $cscPath)) {
    $cscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (-not (Test-Path $cscPath)) {
    Write-Error "Khong tim thay trinh bien dich csc.exe trong he thong Windows!"
    Exit 1
}

Write-Host ">>> Trinh bien dich C#: $cscPath" -ForegroundColor Cyan

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
    "/resource:`"$RootDir\src\Core\LicenseManager.ps1`",VUONGTT.LicenseManager.ps1"
)

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
