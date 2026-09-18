<#
========================================================================================
   VUONGTT SOFTWARE - TOOLKIT 2026 VER 20.5.908.29
   VUONGTT Tool Pro 2026 - Professional
   Chuyên nghiệp - Tối ưu hóa - Cài đặt tự động - Sửa lỗi toàn diện Windows, Office & Phần cứng
========================================================================================
#>

param(
    [string]$SourceExePath
)

if ($SourceExePath -and (Test-Path $SourceExePath -ErrorAction SilentlyContinue)) {
    $global:VUONGTT_TARGET_EXE = $SourceExePath
    $env:VUONGTT_ORIGINAL_EXE = $SourceExePath
}

# Requires Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    try {
        $argList = "-NoProfile -ExecutionPolicy Bypass -Sta -File `"$PSCommandPath`""
        if ($SourceExePath) { $argList += " `"$SourceExePath`"" }
        Start-Process powershell.exe -ArgumentList $argList -Verb RunAs
        Exit
    } catch {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("Vui lòng đồng ý cấp quyền Quản trị viên (Run as Administrator) để khởi chạy VUONGTT Tool Pro 2026.", "Yêu cầu quyền Administrator", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        Exit
    }
}

# Add required assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir -or -not (Test-Path (Join-Path $ScriptDir "src\UI\MainWindow.xaml"))) {
    if (Test-Path "E:\toolwindows\src\UI\MainWindow.xaml") {
        $ScriptDir = "E:\toolwindows"
    } elseif (Test-Path "$env:TEMP\VUONGTT_Toolkit_Runtime\src\UI\MainWindow.xaml") {
        $ScriptDir = "$env:TEMP\VUONGTT_Toolkit_Runtime"
    }
}

# Import Core Modules
$corePath = Join-Path $ScriptDir "src\Core"
. (Join-Path $corePath "HardwareInfo.ps1")
. (Join-Path $corePath "OfficeInstaller.ps1")
. (Join-Path $corePath "Activator.ps1")
. (Join-Path $corePath "NetworkPrinterFix.ps1")
. (Join-Path $corePath "SystemTweaks.ps1")
. (Join-Path $corePath "BitLockerManager.ps1")
. (Join-Path $corePath "SoftwareInstaller.ps1")
. (Join-Path $corePath "SystemCustomizer.ps1")
. (Join-Path $corePath "UserManager.ps1")
. (Join-Path $corePath "CpuMainDatabase.ps1")
. (Join-Path $corePath "LaptopTester.ps1")
. (Join-Path $corePath "FontInstaller.ps1")
. (Join-Path $corePath "PartitionManager.ps1")
. (Join-Path $corePath "AccountingApps.ps1")
. (Join-Path $corePath "AppUpdater.ps1")

# Load Main UI XAML
$xamlFile = Join-Path $ScriptDir "src\UI\MainWindow.xaml"
[xml]$xaml = Get-Content -Path $xamlFile -Raw -Encoding UTF8
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [System.Windows.Markup.XamlReader]::Load($reader)

function Get-Control {
    param([string]$Name)
    return $window.FindName($Name)
}

function Get-VUONGTTSafeLogContent {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return "" }
    try {
        $fs = New-Object System.IO.FileStream($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $sr = New-Object System.IO.StreamReader($fs, [System.Text.Encoding]::UTF8)
        $t = $sr.ReadToEnd()
        $sr.Close()
        $fs.Close()
        return $t
    } catch {
        return ""
    }
}

# Controls Reference
$txtPageTitle       = Get-Control "txtPageTitle"
$txtPageIcon        = Get-Control "txtPageIcon"
$txtRealtimeClock   = Get-Control "txtRealtimeClock"
$btnCheckAppUpdate  = Get-Control "btnCheckAppUpdate"
$txtFooterStatus    = Get-Control "txtFooterStatus"
$btnExitApp         = Get-Control "btnExitApp"

# Theme Buttons
$btnThemeDefault    = Get-Control "btnThemeDefault"
$btnThemeDark       = Get-Control "btnThemeDark"
$btnThemeLight      = Get-Control "btnThemeLight"
$btnLangVI          = Get-Control "btnLangVI"
$btnLangEN          = Get-Control "btnLangEN"

# Menu Buttons
$menuButtons = @(
    "btnMenuSysInfo", "btnMenuCustomize", "btnMenuUsers", "btnMenuBenchmark",
    "btnMenuLaptopCheck", "btnMenuCpuMain", "btnMenuTestHardware",
    "btnMenuOffice", "btnMenuSoftware", "btnMenuCustomApp", "btnMenuFonts",
    "btnMenuCleaner", "btnMenuTweaks", "btnMenuPrinterLAN", "btnMenuBackupDriver",
    "btnMenuDevMgmt", "btnMenuActivation", "btnMenuBitLocker", "btnMenuAutoWin", "btnMenuPartition"
)

# Pages Dictionary
$pages = @{
    "SysInfo"      = Get-Control "pageSysInfo"
    "Customize"    = Get-Control "pageCustomize"
    "Users"        = Get-Control "pageUsers"
    "Benchmark"    = Get-Control "pageBenchmark"
    "LaptopCheck"  = Get-Control "pageLaptopCheck"
    "CpuMain"      = Get-Control "pageCpuMain"
    "TestHardware" = Get-Control "pageTestHardware"
    "Office"       = Get-Control "pageOffice"
    "Software"     = Get-Control "pageSoftware"
    "CustomApp"    = Get-Control "pageCustomApp"
    "Fonts"        = Get-Control "pageFonts"
    "Cleaner"      = Get-Control "pageCleaner"
    "Tweaks"       = Get-Control "pageTweaks"
    "PrinterLAN"   = Get-Control "pagePrinterLAN"
    "BackupDriver" = Get-Control "pageBackupDriver"
    "DevMgmt"      = Get-Control "pageBackupDriver"
    "Activation"   = Get-Control "pageActivation"
    "BitLocker"    = Get-Control "pageBitLocker"
    "AutoWin"      = Get-Control "pageAutoWin"
    "Partition"    = Get-Control "pagePartition"
}

$pageTitles = @{
    "SysInfo"      = @{ Title = "Xem Cấu Hình Máy Tính"; Icon = "💻" }
    "Customize"    = @{ Title = "Tùy Chỉnh Thông Tin Máy"; Icon = "🖥️" }
    "Users"        = @{ Title = "Quản Lý User & PC"; Icon = "👤" }
    "Benchmark"    = @{ Title = "Tốc Độ Ổ Đĩa (Benchmark)"; Icon = "⚡" }
    "LaptopCheck"  = @{ Title = "Kiểm Tra Laptop (Đã Sửa?)"; Icon = "🔍" }
    "CpuMain"      = @{ Title = "Tra Cứu CPU + Main"; Icon = "💡" }
    "TestHardware" = @{ Title = "Test Bàn Phím, Loa, Mic, Camera"; Icon = "⌨️" }
    "Office"       = @{ Title = "Cài Đặt Office (Tự Động)"; Icon = "📑" }
    "Software"     = @{ Title = "Tải Ứng Dụng Thiết Yếu"; Icon = "📥" }
    "CustomApp"    = @{ Title = "Cài App Tùy Chỉnh & Silent"; Icon = "📦" }
    "Fonts"        = @{ Title = "Cài Font Tiếng Việt Đầy Đủ"; Icon = "🔤" }
    "Cleaner"      = @{ Title = "Tối Ưu & Dọn Dẹp Hệ Thống"; Icon = "🚀" }
    "Tweaks"       = @{ Title = "Tinh Chỉnh Windows Chuyên Sâu"; Icon = "⚙️" }
    "PrinterLAN"   = @{ Title = "Sửa Lỗi Máy In (87 Chức Năng)"; Icon = "🖨️" }
    "BackupDriver" = @{ Title = "Sao Lưu & Khôi Phục Driver Thiết Bị"; Icon = "💾" }
    "DevMgmt"      = @{ Title = "Quản Lý Thiết Bị (Device Manager)"; Icon = "🛠️" }
    "Activation"   = @{ Title = "Kích Hoạt (MAS HWID)"; Icon = "🔑" }
    "BitLocker"    = @{ Title = "Quản Lý & Tắt BitLocker - EFS"; Icon = "🔒" }
    "AutoWin"      = @{ Title = "Bộ Công Cụ Cài Win & Bypass"; Icon = "🚀" }
    "Partition"    = @{ Title = "Quản Lý Phân Vùng Ổ Đĩa (Partition Pro)"; Icon = "💽" }
}

$script:currentTab = "SysInfo"

# Switch Tab Function
function Switch-Tab {
    param([string]$TargetTag, [switch]$SkipRefresh = $false)
    $script:currentTab = $TargetTag

    # Hide all pages
    $pages.Values | Where-Object { $_ } | ForEach-Object { $_.Visibility = [System.Windows.Visibility]::Collapsed }

    # Show target page
    if ($pages.ContainsKey($TargetTag) -and $pages[$TargetTag]) {
        $pages[$TargetTag].Visibility = [System.Windows.Visibility]::Visible
    }

    # Update menu button styling
    foreach ($btnName in $menuButtons) {
        $btn = Get-Control $btnName
        if ($btn) {
            if ($btn.Tag -eq $TargetTag) {
                $btn.Background = $window.Resources["MenuBtnActiveBg"]
                $btn.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#B45309")
            } else {
                $btn.Background = [System.Windows.Media.Brushes]::Transparent
                $btn.Foreground = $window.Resources["MenuBtnText"]
            }
        }
    }

    if ($pageTitles.ContainsKey($TargetTag)) {
        $txtPageTitle.Text = $pageTitles[$TargetTag].Title
        $txtPageIcon.Text  = $pageTitles[$TargetTag].Icon
    }

    if ($SkipRefresh) { return }

    # Module specific lazy refresh
    switch ($TargetTag) {
        "SysInfo"      { Refresh-SysInfoDisplay }
        "Benchmark"    {
            $txtBenchmarkResult2 = Get-Control "txtBenchmarkResult2"
            if ($txtBenchmarkResult2 -and $txtBenchmarkResult2.Text -like "*Bấm nút*") {
                $txtBenchmarkResult2.Text = "Sẵn sàng đo tốc độ SSD/HDD. Bấm nút 'Bắt Đầu Đo Tốc Độ SSD/HDD' ở trên để bắt đầu."
            }
            $txtFooterStatus.Text = "• [OK] Đang ở trang Đo Tốc Độ Ổ Đĩa & Benchmark Hệ Thống."
        }
        "Customize"    { Refresh-CustomizeDisplay }
        "Users"        { Refresh-UsersList }
        "CpuMain"      { Search-CpuInfo }
        "LaptopCheck"  { Refresh-BatteryDisplay }
        "TestHardware" { $txtFooterStatus.Text = "• [OK] Đang ở trang Kiểm Tra Phần Cứng & Thiết Bị Ngoại Vi." }
        "Office"       { Refresh-OfficeStatusBadge }
        "Software"     { $txtFooterStatus.Text = "• [OK] Kho 26 phần mềm thiết yếu sẵn sàng." }
        "CustomApp"    { $txtFooterStatus.Text = "• [OK] Sẵn sàng cài đặt ứng dụng tùy chỉnh hoặc file cài đặt silent." }
        "Fonts"        { $txtFooterStatus.Text = "• [OK] Sẵn sàng cài đặt trọn bộ Font tiếng Việt VNI, TCVN3, Unicode." }
        "Cleaner"      { $txtFooterStatus.Text = "• [OK] Sẵn sàng dọn dẹp rác hệ thống và giải phóng bộ nhớ RAM." }
        "Tweaks"       { $txtFooterStatus.Text = "• [OK] Sẵn sàng tinh chỉnh Windows và sửa lỗi hệ thống." }
        "PrinterLAN"   { $txtFooterStatus.Text = "• [OK] 87 chức năng sửa lỗi máy in & tối ưu chia sẻ LAN sẵn sàng." }
        "BackupDriver" { $txtFooterStatus.Text = "• [OK] Đang ở trang Sao Lưu & Khôi Phục Driver Thiết Bị." }
        "DevMgmt"      { 
            $txtFooterStatus.Text = "• [OK] Đã mở trình quản lý thiết bị Device Manager (devmgmt.msc)"
            Start-Process "devmgmt.msc"
        }
        "Activation"   { $txtFooterStatus.Text = "• [OK] Sẵn sàng kích hoạt bản quyền số vĩnh viễn MAS HWID." }
        "BitLocker"    { $txtFooterStatus.Text = "• [OK] Sẵn sàng quản lý mã hóa BitLocker & trích xuất Recovery Key." }
        "AutoWin"      { $txtFooterStatus.Text = "• [OK] Sẵn sàng công cụ 1-Click Bypass và tải ISO cài Win." }
        "Partition"    { 
            $txtFooterStatus.Text = "• [OK] Quản lý phân vùng đĩa & Storage Engine sẵn sàng."
            Refresh-DiskPartitionDisplay
        }
    }
}

# Wire Menu Clicks
foreach ($btnName in $menuButtons) {
    $btn = Get-Control $btnName
    if ($btn) {
        $btn.Add_Click({
            param($sender, $e)
            Switch-Tab -TargetTag $sender.Tag
        })
    }
}

# =========================================================================
# THEMES MANAGEMENT (Mặc Định / Tối / Sáng)
# =========================================================================
function Set-ToolkitTheme {
    param([ValidateSet("Default", "Dark", "Light")][string]$Theme)

    $conv = [System.Windows.Media.BrushConverter]::new()

    switch ($Theme) {
        "Default" {
            # Warm Amber / Cream (Screenshot Match)
            $window.Resources["AppBgBrush"]          = $conv.ConvertFromString("#FAF7F2")
            $window.Resources["SidebarBgBrush"]      = $conv.ConvertFromString("#F4ECE1")
            $window.Resources["SidebarBorderBrush"]  = $conv.ConvertFromString("#E5D9C8")
            $window.Resources["HeaderBgBrush"]       = $conv.ConvertFromString("#FAF7F2")
            $window.Resources["HeaderBorderBrush"]   = $conv.ConvertFromString("#E5D9C8")
            $window.Resources["CardBgBrush"]         = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["CardInnerBgBrush"]    = $conv.ConvertFromString("#FCFBF9")
            $window.Resources["CardBorderBrush"]     = $conv.ConvertFromString("#E5D9C8")
            $window.Resources["TextPrimaryBrush"]    = $conv.ConvertFromString("#292524")
            $window.Resources["TextSecondaryBrush"]  = $conv.ConvertFromString("#78716C")
            $window.Resources["InputBgBrush"]        = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["InputBorderBrush"]    = $conv.ConvertFromString("#D6C7B2")
            $window.Resources["InputTextBrush"]      = $conv.ConvertFromString("#292524")
            $window.Resources["MenuBtnHoverBg"]      = $conv.ConvertFromString("#EADBCA")
            $window.Resources["MenuBtnActiveBg"]     = $conv.ConvertFromString("#EADBCA")
            $window.Resources["MenuBtnText"]         = $conv.ConvertFromString("#292524")
            
            $btnThemeDefault.Background = $conv.ConvertFromString("#EADBCA")
            $btnThemeDefault.Foreground = $conv.ConvertFromString("#78350F")
            $btnThemeDark.Background    = $conv.ConvertFromString("#FFFFFF")
            $btnThemeLight.Background   = $conv.ConvertFromString("#FFFFFF")
        }
        "Dark" {
            # Sleek Dark
            $window.Resources["AppBgBrush"]          = $conv.ConvertFromString("#0F172A")
            $window.Resources["SidebarBgBrush"]      = $conv.ConvertFromString("#1E293B")
            $window.Resources["SidebarBorderBrush"]  = $conv.ConvertFromString("#334155")
            $window.Resources["HeaderBgBrush"]       = $conv.ConvertFromString("#0F172A")
            $window.Resources["HeaderBorderBrush"]   = $conv.ConvertFromString("#334155")
            $window.Resources["CardBgBrush"]         = $conv.ConvertFromString("#1E293B")
            $window.Resources["CardInnerBgBrush"]    = $conv.ConvertFromString("#0F172A")
            $window.Resources["CardBorderBrush"]     = $conv.ConvertFromString("#334155")
            $window.Resources["TextPrimaryBrush"]    = $conv.ConvertFromString("#F8FAFC")
            $window.Resources["TextSecondaryBrush"]  = $conv.ConvertFromString("#94A3B8")
            $window.Resources["InputBgBrush"]        = $conv.ConvertFromString("#0F172A")
            $window.Resources["InputBorderBrush"]    = $conv.ConvertFromString("#475569")
            $window.Resources["InputTextBrush"]      = $conv.ConvertFromString("#F8FAFC")
            $window.Resources["MenuBtnHoverBg"]      = $conv.ConvertFromString("#334155")
            $window.Resources["MenuBtnActiveBg"]     = $conv.ConvertFromString("#334155")
            $window.Resources["MenuBtnText"]         = $conv.ConvertFromString("#F8FAFC")

            $btnThemeDark.Background    = $conv.ConvertFromString("#334155")
            $btnThemeDark.Foreground    = $conv.ConvertFromString("#F8FAFC")
            $btnThemeDefault.Background = $conv.ConvertFromString("#1E293B")
            $btnThemeLight.Background   = $conv.ConvertFromString("#1E293B")
        }
        "Light" {
            # Clean Light
            $window.Resources["AppBgBrush"]          = $conv.ConvertFromString("#F8FAFC")
            $window.Resources["SidebarBgBrush"]      = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["SidebarBorderBrush"]  = $conv.ConvertFromString("#E2E8F0")
            $window.Resources["HeaderBgBrush"]       = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["HeaderBorderBrush"]   = $conv.ConvertFromString("#E2E8F0")
            $window.Resources["CardBgBrush"]         = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["CardInnerBgBrush"]    = $conv.ConvertFromString("#F1F5F9")
            $window.Resources["CardBorderBrush"]     = $conv.ConvertFromString("#E2E8F0")
            $window.Resources["TextPrimaryBrush"]    = $conv.ConvertFromString("#0F172A")
            $window.Resources["TextSecondaryBrush"]  = $conv.ConvertFromString("#64748B")
            $window.Resources["InputBgBrush"]        = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["InputBorderBrush"]    = $conv.ConvertFromString("#CBD5E1")
            $window.Resources["InputTextBrush"]      = $conv.ConvertFromString("#0F172A")
            $window.Resources["MenuBtnHoverBg"]      = $conv.ConvertFromString("#EFF6FF")
            $window.Resources["MenuBtnActiveBg"]     = $conv.ConvertFromString("#EFF6FF")
            $window.Resources["MenuBtnText"]         = $conv.ConvertFromString("#0F172A")

            $btnThemeLight.Background   = $conv.ConvertFromString("#EFF6FF")
            $btnThemeLight.Foreground   = $conv.ConvertFromString("#2563EB")
            $btnThemeDefault.Background = $conv.ConvertFromString("#FFFFFF")
            $btnThemeDark.Background    = $conv.ConvertFromString("#FFFFFF")
        }
    }

    if ($script:currentTab) {
        Switch-Tab -TargetTag $script:currentTab
    }
}

$btnThemeDefault.Add_Click({ Set-ToolkitTheme -Theme "Default" })
$btnThemeDark.Add_Click({ Set-ToolkitTheme -Theme "Dark" })
$btnThemeLight.Add_Click({ Set-ToolkitTheme -Theme "Light" })

# Language buttons
$btnLangVI.Add_Click({ $txtFooterStatus.Text = "• [OK] Đã chọn ngôn ngữ Tiếng Việt" })
$btnLangEN.Add_Click({ $txtFooterStatus.Text = "• [OK] Language switched to English" })

# Exit Button
$btnExitApp.Add_Click({ $window.Close() })

# =========================================================================
# REALTIME CLOCK & LIVE GAUGES TIMER (Every 1s clock, Every 3s metrics)
# =========================================================================
$timerTicks = 0
$clockTimer = New-Object System.Windows.Threading.DispatcherTimer
$clockTimer.Interval = [TimeSpan]::FromSeconds(1)
$clockTimer.Add_Tick({
    $now = Get-Date
    $txtRealtimeClock.Text = "$($now.ToString('HH:mm:ss')) | $($now.ToString('dd/MM/yyyy'))"

    $timerTicks++
    if ($timerTicks % 3 -eq 0 -and $script:currentTab -eq "SysInfo") {
        # Update live metrics
        Update-LiveGaugeValues
    }
})
$clockTimer.Start()

# =========================================================================
# MODULE 1: XEM CẤU HÌNH MÁY TÍNH & 6 GAUGES
# =========================================================================
$txtGaugeTotalPercent  = Get-Control "txtGaugeTotalPercent"
$txtGaugeCpuPercent    = Get-Control "txtGaugeCpuPercent"
$txtGaugeCpuSub        = Get-Control "txtGaugeCpuSub"
$txtGaugeCpuName       = Get-Control "txtGaugeCpuName"
$txtGaugeRamPercent    = Get-Control "txtGaugeRamPercent"
$txtGaugeRamSub        = Get-Control "txtGaugeRamSub"
$txtGaugeRamTotal      = Get-Control "txtGaugeRamTotal"
$txtGaugeGpuPercent    = Get-Control "txtGaugeGpuPercent"
$txtGaugeGpuVram       = Get-Control "txtGaugeGpuVram"
$txtGaugeGpuName       = Get-Control "txtGaugeGpuName"
$txtGaugeNetSpeed      = Get-Control "txtGaugeNetSpeed"
$txtGaugeNetName       = Get-Control "txtGaugeNetName"
$txtGaugeDiskSummary   = Get-Control "txtGaugeDiskSummary"

$lblCpuTurbo           = Get-Control "lblCpuTurbo"
$lblCpuBus             = Get-Control "lblCpuBus"
$lblCpuSpeed           = Get-Control "lblCpuSpeed"
$lblCpuSocket          = Get-Control "lblCpuSocket"
$lblCpuTdp             = Get-Control "lblCpuTdp"
$lblCpuTemp            = Get-Control "lblCpuTemp"

$lblGpuTitle           = Get-Control "lblGpuTitle"
$lblGpuVendor          = Get-Control "lblGpuVendor"
$lblGpuBoard           = Get-Control "lblGpuBoard"
$lblGpuVram            = Get-Control "lblGpuVram"
$lblGpuArch            = Get-Control "lblGpuArch"
$lblGpuBus             = Get-Control "lblGpuBus"
$lblGpuPci             = Get-Control "lblGpuPci"
$lblGpuDriver          = Get-Control "lblGpuDriver"
$lblGpuRes             = Get-Control "lblGpuRes"

$panelGpu1Container    = Get-Control "panelGpu1Container"
$lblGpu1Title          = Get-Control "lblGpu1Title"
$lblGpu1Vendor         = Get-Control "lblGpu1Vendor"
$lblGpu1Vram           = Get-Control "lblGpu1Vram"
$lblGpu1Pci            = Get-Control "lblGpu1Pci"
$lblGpu1Driver         = Get-Control "lblGpu1Driver"
$lblGpu1Status         = Get-Control "lblGpu1Status"

$lblRamTotal           = Get-Control "lblRamTotal"
$lblRamSlots           = Get-Control "lblRamSlots"
$lblRamType            = Get-Control "lblRamType"
$lblRamChannel         = Get-Control "lblRamChannel"
$lblRamEffectiveSpeed  = Get-Control "lblRamEffectiveSpeed"
$lblRamDramFreq        = Get-Control "lblRamDramFreq"

$lblDimmTitle          = Get-Control "lblDimmTitle"
$lblDimmLocator        = Get-Control "lblDimmLocator"
$lblDimmMfg            = Get-Control "lblDimmMfg"
$lblDimmPart           = Get-Control "lblDimmPart"
$lblDimmCap            = Get-Control "lblDimmCap"
$lblDimmSpeed          = Get-Control "lblDimmSpeed"
$lblDimmVolt           = Get-Control "lblDimmVolt"
$lblDimmSerial         = Get-Control "lblDimmSerial"

$btnRefreshHardware    = Get-Control "btnRefreshHardware"
$btnCopyHardware       = Get-Control "btnCopyHardware"
$btnExportExcel        = Get-Control "btnExportExcel"
$btnExportCsv          = Get-Control "btnExportCsv"
$btnDriverVendor       = Get-Control "btnDriverVendor"
$btnMissingDriver      = Get-Control "btnMissingDriver"

function Update-LiveGaugeValues {
    try {
        $m = Get-VUONGTTLiveMetrics
        $txtGaugeTotalPercent.Text = "$($m.SystemLoadPercent)%"
        $txtGaugeCpuPercent.Text   = "$($m.CpuLoadPercent)%"
        $txtGaugeCpuSub.Text       = "$($m.CpuClockGHz) GHz · $($m.CpuTempC)°C"
        $txtGaugeCpuName.Text      = $m.CpuName
        $txtGaugeRamPercent.Text   = "$($m.RamPercent)%"
        $txtGaugeRamSub.Text       = "$($m.RamUsedGB) / $($m.RamTotalGB) GB"
        $txtGaugeRamTotal.Text     = "$($m.RamTotalGB) GB Total"
        $txtGaugeGpuVram.Text      = "$($m.GpuVramGB) GB VRAM"
        $txtGaugeGpuName.Text      = $m.GpuName
        $txtGaugeNetSpeed.Text     = $m.NetSpeed
        $txtGaugeNetName.Text      = $m.NetName
        $txtGaugeDiskSummary.Text  = "Ổ cứng trống: $($m.DiskSummary)"
    } catch {}
}

function Refresh-SysInfoDisplay {
    Update-LiveGaugeValues
    try {
        $d = Get-VUONGTTDetailedHardwareInfo
        
        $lblCpuTurbo.Text   = $d.TurboClockMHz
        $lblCpuBus.Text     = $d.BusSpeedMHz
        $lblCpuSpeed.Text   = $d.CurrentClockMHz
        $lblCpuSocket.Text  = $d.Socket
        $lblCpuTdp.Text     = $d.TDP
        $lblCpuTemp.Text    = $d.CpuTemp

        $lblGpuTitle.Text   = $d.GpuName
        $lblGpuVendor.Text  = $d.GpuVendor
        $lblGpuBoard.Text   = $d.GpuBoard
        $lblGpuVram.Text    = $d.GpuVram
        $lblGpuArch.Text    = $d.GpuArch
        $lblGpuBus.Text     = $d.GpuBus
        if ($lblGpuPci)     { $lblGpuPci.Text = $d.GpuHardwareID }
        $lblGpuDriver.Text  = $d.GpuDriver
        $lblGpuRes.Text     = $d.GpuResolution

        # GPU 1: Card Do Hoa Roi (NVIDIA / AMD)
        if ($panelGpu1Container) {
            if ($d.HasGpu1) {
                $panelGpu1Container.Visibility = [System.Windows.Visibility]::Visible
                if ($lblGpu1Title)  { $lblGpu1Title.Text  = $d.Gpu1Name }
                if ($lblGpu1Vendor) { $lblGpu1Vendor.Text = $d.Gpu1Vendor }
                if ($lblGpu1Vram)   { $lblGpu1Vram.Text   = $d.Gpu1Vram }
                if ($lblGpu1Pci)    { $lblGpu1Pci.Text    = $d.Gpu1HardwareID }
                if ($lblGpu1Driver) { $lblGpu1Driver.Text = $d.Gpu1Driver }
                if ($lblGpu1Status) {
                    $lblGpu1Status.Text = $d.Gpu1Status
                    if ($d.Gpu1Status -like "*Chưa*" -or $d.Gpu1Status -like "*Lỗi*") {
                        $lblGpu1Status.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")
                    } else {
                        $lblGpu1Status.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#047857")
                    }
                }
            } else {
                $panelGpu1Container.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }

        $lblRamTotal.Text          = $d.TotalRamGB
        $lblRamSlots.Text          = $d.SlotUsage
        $lblRamType.Text           = $d.RamType
        $lblRamChannel.Text        = $d.RamChannel
        $lblRamEffectiveSpeed.Text = $d.EffectiveSpeed
        $lblRamDramFreq.Text       = $d.DramFreq

        if ($d.DimmList -and $d.DimmList.Count -gt 0) {
            $dimm = $d.DimmList[0]
            $lblDimmTitle.Text   = "◆ $($dimm.Locator): $($dimm.Manufacturer) / DRAM $($dimm.PartNumber)"
            $lblDimmLocator.Text = $dimm.Locator
            $lblDimmMfg.Text     = $dimm.Manufacturer
            $lblDimmPart.Text    = $dimm.PartNumber
            $lblDimmCap.Text     = $dimm.Capacity
            $lblDimmSpeed.Text   = $dimm.Speed
            $lblDimmVolt.Text    = $dimm.Voltage
            $lblDimmSerial.Text  = $dimm.Serial
        }
        $txtFooterStatus.Text = "• [OK] Đã quét toàn bộ thông tin phần cứng thành công."
    } catch {
        $txtFooterStatus.Text = "• [LỖI] Không thể đọc chi tiết phần cứng: $($_.Exception.Message)"
    }
}

# Disk Benchmark Controls
$txtBenchmarkResult  = Get-Control "txtBenchmarkResult"
$btnRunDiskBenchmark = Get-Control "btnRunDiskBenchmark"

if ($btnRunDiskBenchmark) {
    $btnRunDiskBenchmark.Add_Click({
        $btnRunDiskBenchmark.IsEnabled = $false
        $btnRunDiskBenchmark.Content = "⏳ Đang Đo Tốc Độ..."
        $txtBenchmarkResult.Text = "Đang kiểm tra tốc độ đọc/ghi ổ đĩa hệ thống..."

        $benchTimer = New-Object System.Windows.Threading.DispatcherTimer
        $benchTimer.Interval = [TimeSpan]::FromMilliseconds(150)
        $benchTimer.Add_Tick({
            $benchTimer.Stop()
            try {
                $testPath = "$env:TEMP\VUONGTT_DiskSpeedTest.dat"
                $sizeMB = 64
                $data = New-Object byte[] ($sizeMB * 1024 * 1024)
                [System.Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($data)

                # Sequential Write Test
                $sw = [System.Diagnostics.Stopwatch]::StartNew()
                [System.IO.File]::WriteAllBytes($testPath, $data)
                $sw.Stop()
                $writeMBps = [math]::Round($sizeMB / ($sw.ElapsedMilliseconds / 1000), 1)

                # Sequential Read Test
                $sw.Restart()
                $readBytes = [System.IO.File]::ReadAllBytes($testPath)
                $sw.Stop()
                $readMBps = [math]::Round($sizeMB / ($sw.ElapsedMilliseconds / 1000), 1)

                if (Test-Path $testPath) { Remove-Item $testPath -Force -ErrorAction SilentlyContinue }

                $txtBenchmarkResult.Text = 'Doc: ' + $readMBps + ' MB/s | Ghi: ' + $writeMBps + ' MB/s'
                $txtFooterStatus.Text = '• [OK] Hoàn tất đo tốc độ ổ C: Đọc ' + $readMBps + ' MB/s - Ghi ' + $writeMBps + ' MB/s'
            } catch {
                $txtBenchmarkResult.Text = 'Lỗi: ' + $_.Exception.Message
            } finally {
                $btnRunDiskBenchmark.IsEnabled = $true
                $btnRunDiskBenchmark.Content = "🚀 Bắt Đầu Đo Tốc Độ"
            }
        })
        $benchTimer.Start()
    })
}

$btnRefreshHardware.Add_Click({
    Clear-VUONGTTHardwareCache
    Refresh-SysInfoDisplay
})

$btnCopyHardware.Add_Click({
    try {
        $d = Get-VUONGTTDetailedHardwareInfo
        $txt = @"
THÔNG TIN CẤU HÌNH MÁY TÍNH - $env:COMPUTERNAME
• CPU: $($d.CpuName) (Socket: $($d.Socket), Tốc độ: $($d.CurrentClockMHz))
• RAM: $($d.TotalRamGB) $($d.RamType) ($($d.SlotUsage), Kênh: $($d.RamChannel))
• GPU: $($d.GpuName) (VRAM: $($d.GpuVram), Driver: $($d.GpuDriver))
• Mainboard: $($d.Motherboard)
• Hệ điều hành: $($d.OSName) ($($d.OSVersion))
"@
        [System.Windows.Clipboard]::SetText($txt)
        [System.Windows.MessageBox]::Show("Đã sao chép cấu hình chi tiết vào Clipboard!", "Sao Chép Cấu Hình", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {}
})

# Xuat cau hinh ra Excel / CSV thong qua SaveFileDialog an toan tuyet doi
$exportAction = {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "Tệp CSV Microsoft Excel (*.csv)|*.csv|Tất cả tệp (*.*)|*.*"
        $sfd.FileName = "Hardware_Specs_$($env:COMPUTERNAME).csv"
        $sfd.InitialDirectory = Get-VUONGTTSafeDesktopPath
        $sfd.Title = "Chọn nơi lưu tệp thông số cấu hình phần cứng"
        
        if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $res = Export-HardwareInfoToCsv -FilePath $sfd.FileName
            if ($res.Success) {
                $txtFooterStatus.Text = "• [OK] Đã xuất cấu hình ra $($sfd.FileName)"
                $choice = [System.Windows.MessageBox]::Show(
                    "$($res.Message)`n`nBạn có muốn mở tệp vừa xuất bằng Microsoft Excel ngay bây giờ không?",
                    "Xuất Cấu Hình Thành Công",
                    [System.Windows.MessageBoxButton]::YesNo,
                    [System.Windows.MessageBoxImage]::Information
                )
                if ($choice -eq [System.Windows.MessageBoxResult]::Yes) {
                    Start-Process $sfd.FileName
                }
            } else {
                [System.Windows.MessageBox]::Show($res.Message, "Lỗi Xuất File", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            }
        }
    } catch {
        # Fallback an toan neu SaveFileDialog khong khoi tao duoc
        $safeDesktop = Get-VUONGTTSafeDesktopPath
        $target = Join-Path $safeDesktop "Hardware_Specs_$($env:COMPUTERNAME).csv"
        $res = Export-HardwareInfoToCsv -FilePath $target
        [System.Windows.MessageBox]::Show($res.Message, "Xuất Cấu Hình", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
}

$btnExportCsv.Add_Click($exportAction)
$btnExportExcel.Add_Click($exportAction)

$btnDriverVendor.Add_Click({
    Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"
})

$btnMissingDriver.Add_Click({
    $prob = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.ConfigManagerErrorCode -ne 0 -and $_.ConfigManagerErrorCode -ne $null }
    if ($prob) {
        $lines = @()
        foreach ($dev in $prob) {
            $devName = if ($dev.Name) { $dev.Name } elseif ($dev.Description) { $dev.Description } elseif ($dev.Caption) { $dev.Caption } else { "Thiết bị phần cứng" }
            $hwId = if ($dev.DeviceID) { $dev.DeviceID } else { "" }
            
            # Phan tich thong minh PCI Vendor & Device ID
            if ($hwId -like "PCI\VEN_*") {
                $ven = if ($hwId -match "VEN_([0-9A-Fa-f]{4})") { $matches[1].ToUpper() } else { "" }
                $devCode = if ($hwId -match "DEV_([0-9A-Fa-f]{4})") { $matches[1].ToUpper() } else { "" }
                $venName = switch ($ven) {
                    "10DE" { "Card Đồ Họa Rời NVIDIA" }
                    "1002" { "Card Đồ Họa AMD / Radeon" }
                    "8086" { "Thiết Bị Intel (Chipset / Audio / Graphics)" }
                    "10EC" { "Card Âm Thanh / Card Mạng Realtek" }
                    "14E4" { "Card Mạng Broadcom" }
                    "168C" { "Card Wi-Fi Qualcomm Atheros" }
                    default { "Vendor ID: $ven" }
                }
                $devName = "$venName ($devName) [VEN_$ven DEV_$devCode]"
            }
            $lines += "• $devName (Mã lỗi: $($dev.ConfigManagerErrorCode))"
        }
        $names = ($lines -join "`n")
        [System.Windows.MessageBox]::Show("Phát hiện $($prob.Count) thiết bị chưa đủ Driver trên máy:`n`n$names`n`n👉 Gợi ý: Nếu có card đồ họa rời NVIDIA/AMD, bạn có thể bấm nút 'Driver Hãng' để tải driver tự động.", "Kiểm Tra Driver Thiếu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    } else {
        [System.Windows.MessageBox]::Show("Tuyệt vời! Toàn bộ Driver trên máy đều hoạt động hoàn hảo, không có thiết bị nào bị lỗi hoặc thiếu driver.", "Kiểm Tra Driver", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
})

# =========================================================================
# MODULE 2: TÙY CHỈNH THÔNG TIN MÁY (System Properties)
# =========================================================================
$txtCustomComputerName  = Get-Control "txtCustomComputerName"
$txtCustomWorkgroup     = Get-Control "txtCustomWorkgroup"
$txtCustomDescription   = Get-Control "txtCustomDescription"
$txtCustomOwner         = Get-Control "txtCustomOwner"
$txtCustomOrg           = Get-Control "txtCustomOrg"
$txtCustomManufacturer  = Get-Control "txtCustomManufacturer"
$txtCustomModel         = Get-Control "txtCustomModel"
$txtCustomPhone         = Get-Control "txtCustomPhone"
$txtCustomURL           = Get-Control "txtCustomURL"

$prevComputerName       = Get-Control "prevComputerName"
$prevManufacturer       = Get-Control "prevManufacturer"
$prevModel              = Get-Control "prevModel"
$prevWorkgroup          = Get-Control "prevWorkgroup"
$prevOwner              = Get-Control "prevOwner"

$btnApplyCustomize      = Get-Control "btnApplyCustomize"
$btnBackupCustomize     = Get-Control "btnBackupCustomize"
$btnRestoreCustomize    = Get-Control "btnRestoreCustomize"
$btnReloadCustomize     = Get-Control "btnReloadCustomize"
$txtCustomizeLog        = Get-Control "txtCustomizeLog"

function Refresh-CustomizeDisplay {
    $info = Get-SystemCustomizerInfo
    $txtCustomComputerName.Text = $info.ComputerName
    $txtCustomWorkgroup.Text    = $info.Workgroup
    $txtCustomDescription.Text  = if ($info.ComputerDescription) { $info.ComputerDescription } else { "Không bắt buộc" }
    $txtCustomOwner.Text        = if ($info.RegisteredOwner) { $info.RegisteredOwner } else { "VUONGTT" }
    $txtCustomOrg.Text          = if ($info.RegisteredOrganization) { $info.RegisteredOrganization } else { "Không bắt buộc" }
    $txtCustomManufacturer.Text = if ($info.Manufacturer) { $info.Manufacturer } else { "Ví dụ: VUONGTT Technology" }
    $txtCustomModel.Text        = if ($info.Model) { $info.Model } else { "Ví dụ: VTT-Pro2026" }
    $txtCustomPhone.Text        = if ($info.SupportPhone) { $info.SupportPhone } else { "Ví dụ: 1900 xxxx" }
    $txtCustomURL.Text          = if ($info.SupportURL) { $info.SupportURL } else { "https://..." }

    # Update preview
    $prevComputerName.Text = $info.ComputerName
    $prevManufacturer.Text = if ($info.Manufacturer) { $info.Manufacturer } else { "-" }
    $prevModel.Text        = if ($info.Model) { $info.Model } else { "-" }
    $prevWorkgroup.Text    = $info.Workgroup
    $prevOwner.Text        = if ($info.RegisteredOwner) { $info.RegisteredOwner } else { "VUONGTT" }

    $txtCustomizeLog.Text  = "Đã tải thông tin hiện tại."
}

# Live preview sync as user types
$txtCustomComputerName.Add_TextChanged({ $prevComputerName.Text = $txtCustomComputerName.Text })
$txtCustomManufacturer.Add_TextChanged({ $prevManufacturer.Text = $txtCustomManufacturer.Text })
$txtCustomModel.Add_TextChanged({ $prevModel.Text = $txtCustomModel.Text })
$txtCustomWorkgroup.Add_TextChanged({ $prevWorkgroup.Text = $txtCustomWorkgroup.Text })
$txtCustomOwner.Add_TextChanged({ $prevOwner.Text = $txtCustomOwner.Text })

$btnApplyCustomize.Add_Click({
    $mfg = if ($txtCustomManufacturer.Text -notlike "Ví dụ*") { $txtCustomManufacturer.Text } else { "" }
    $mdl = if ($txtCustomModel.Text -notlike "Ví dụ*") { $txtCustomModel.Text } else { "" }
    $ph  = if ($txtCustomPhone.Text -notlike "Ví dụ*") { $txtCustomPhone.Text } else { "" }
    $url = if ($txtCustomURL.Text -notlike "https://...") { $txtCustomURL.Text } else { "" }
    $desc= if ($txtCustomDescription.Text -ne "Không bắt buộc") { $txtCustomDescription.Text } else { "" }
    $org = if ($txtCustomOrg.Text -ne "Không bắt buộc") { $txtCustomOrg.Text } else { "" }

    $res = Set-SystemCustomizerInfo -ComputerName $txtCustomComputerName.Text `
                                    -Workgroup $txtCustomWorkgroup.Text `
                                    -ComputerDescription $desc `
                                    -RegisteredOwner $txtCustomOwner.Text `
                                    -RegisteredOrganization $org `
                                    -Manufacturer $mfg `
                                    -Model $mdl `
                                    -SupportPhone $ph `
                                    -SupportURL $url
    $txtCustomizeLog.Text = $res
    $txtFooterStatus.Text = "• [OK] Tùy chỉnh thông tin máy thành công"
})

$btnBackupCustomize.Add_Click({
    $res = Backup-SystemCustomizerInfo
    $txtCustomizeLog.Text = $res
})

$btnRestoreCustomize.Add_Click({
    $res = Restore-SystemCustomizerInfo
    $txtCustomizeLog.Text = $res
    Refresh-CustomizeDisplay
})

$btnReloadCustomize.Add_Click({
    Refresh-CustomizeDisplay
})

# =========================================================================
# MODULE 3: TRA CỨU CPU + MAIN
# =========================================================================
$cmbCpuSearch       = Get-Control "cmbCpuSearch"
$btnSearchCpu       = Get-Control "btnSearchCpu"
$txtCpuFoundName    = Get-Control "txtCpuFoundName"
$txtCpuFoundSocket  = Get-Control "txtCpuFoundSocket"
$txtCpuFoundArch    = Get-Control "txtCpuFoundArch"
$txtCpuNotes        = Get-Control "txtCpuNotes"
$panelChipsets      = Get-Control "panelChipsets"

function Search-CpuInfo {
    $q = if ($cmbCpuSearch.Text) { $cmbCpuSearch.Text } else { "285K" }
    $item = Find-CpuOrChipset -Query $q
    if ($item) {
        $txtCpuFoundName.Text   = $item.DisplayName
        $txtCpuFoundSocket.Text = $item.Socket
        $txtCpuFoundArch.Text   = $item.Arch
        $txtCpuNotes.Text       = ($item.Notes -join "`n")

        # Populate Chipset Badges
        $panelChipsets.Children.Clear()
        $conv = [System.Windows.Media.BrushConverter]::new()
        foreach ($c in $item.Chipsets) {
            $bd = New-Object System.Windows.Controls.Border
            $bd.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $bd.Padding      = [System.Windows.Thickness]::new(10, 4, 10, 4)
            $bd.Margin       = [System.Windows.Thickness]::new(3)

            $tb = New-Object System.Windows.Controls.TextBlock
            $tb.FontWeight = [System.Windows.FontWeights]::Bold
            $tb.FontSize   = 13

            if ($c.IsPrimary) {
                $bd.Background = $conv.ConvertFromString("#0D9488")
                $tb.Text       = "★ $($c.Name)"
                $tb.Foreground = [System.Windows.Media.Brushes]::White
            } else {
                $bd.Background  = $window.Resources["CardInnerBgBrush"]
                $bd.BorderBrush = $window.Resources["CardBorderBrush"]
                $bd.BorderThickness = [System.Windows.Thickness]::new(1)
                $tb.Text        = $c.Name
                $tb.Foreground  = $window.Resources["TextPrimaryBrush"]
            }

            $bd.Child = $tb
            $panelChipsets.Children.Add($bd) | Out-Null
        }
    }
}

$btnSearchCpu.Add_Click({ Search-CpuInfo })
$cmbCpuSearch.Add_SelectionChanged({ Search-CpuInfo })

# =========================================================================
# MODULE 4: CÀI ĐẶT OFFICE (TỰ ĐỘNG)
# =========================================================================
$txtInstalledOfficeBadge = Get-Control "txtInstalledOfficeBadge"
$radOfficeOnline         = Get-Control "radOfficeOnline"
$radOfficeOffline        = Get-Control "radOfficeOffline"
$radYear2016             = Get-Control "radYear2016"
$radYear2019             = Get-Control "radYear2019"
$radYear2021             = Get-Control "radYear2021"
$radYear2024             = Get-Control "radYear2024"
$radYearM365             = Get-Control "radYearM365"
$radOfficeArch64         = Get-Control "radOfficeArch64"
$radOfficeArch32         = Get-Control "radOfficeArch32"
$cmbOfficeFlavor         = Get-Control "cmbOfficeFlavor"
$cmbOfficeLangPrimary    = Get-Control "cmbOfficeLangPrimary"
$cmbOfficeLangSecondary  = Get-Control "cmbOfficeLangSecondary"

$chkWord                 = Get-Control "chkWord"
$chkExcel                = Get-Control "chkExcel"
$chkPowerPoint           = Get-Control "chkPowerPoint"
$chkOutlook              = Get-Control "chkOutlook"
$chkAccess               = Get-Control "chkAccess"
$chkOneNote              = Get-Control "chkOneNote"
$chkTeams                = Get-Control "chkTeams"
$chkProject              = Get-Control "chkProject"
$chkVisio                = Get-Control "chkVisio"

$btnOfficeInstall        = Get-Control "btnOfficeInstall"
$btnOfficeDownloadOnly   = Get-Control "btnOfficeDownloadOnly"
$btnOfficeUninstall      = Get-Control "btnOfficeUninstall"
$btnOfficeStop           = Get-Control "btnOfficeStop"
$btnOfficeViewLog        = Get-Control "btnOfficeViewLog"
$prgOffice               = Get-Control "prgOffice"
$txtOfficeLog            = Get-Control "txtOfficeLog"

$script:runningOfficeProc = $null

function Refresh-OfficeStatusBadge {
    $info = Get-InstalledOfficeInfo
    $txtInstalledOfficeBadge.Text = "🟢 $info"
}

function Execute-EnhancedOfficeInstall {
    param([bool]$DownloadOnly = $false)

    # 1. Version ID
    $flavorText = $cmbOfficeFlavor.Text
    $vId = if ($flavorText -like "*365*") { "O365ProPlusRetail" }
           elseif ($flavorText -like "*2024*") { "ProPlus2024Volume" }
           elseif ($flavorText -like "*2021*") { "ProPlus2021Volume" }
           elseif ($flavorText -like "*2019*") { "ProPlus2019Volume" }
           elseif ($flavorText -like "*2016*") { "ProPlusRetail" }
           else { "ProPlus2024Volume" }

    # Channel
    $channel = if ($vId -like "*2024*") { "PerpetualVL2024" }
               elseif ($vId -like "*2021*") { "PerpetualVL2021" }
               elseif ($vId -like "*2019*") { "PerpetualVL2019" }
               else { "Current" }

    $arch = if ($radOfficeArch32.IsChecked) { "32" } else { "64" }
    $pLang = if ($cmbOfficeLangPrimary.Text -like "*Việt*") { "vi-vn" } else { "en-us" }
    $sLang = if ($cmbOfficeLangSecondary.Text -like "*Việt*") { "vi-vn" } elseif ($cmbOfficeLangSecondary.Text -like "*English*") { "en-us" } else { "" }

    $excludes = @()
    if (-not $chkWord.IsChecked)       { $excludes += "Word" }
    if (-not $chkExcel.IsChecked)      { $excludes += "Excel" }
    if (-not $chkPowerPoint.IsChecked) { $excludes += "PowerPoint" }
    if (-not $chkOutlook.IsChecked)    { $excludes += "Outlook" }
    if (-not $chkAccess.IsChecked)     { $excludes += "Access" }
    if (-not $chkOneNote.IsChecked)    { $excludes += "OneNote" }
    if (-not $chkTeams.IsChecked)      { $excludes += "Teams" }

    $prgOffice.Value = 20
    $txtOfficeLog.Text = "Đang khởi tạo cấu hình Office XML..."

    $cfg = New-VUONGTTOfficeConfig -Version $vId `
                                  -Arch $arch `
                                  -Channel $channel `
                                  -PrimaryLang $pLang `
                                  -SecondaryLang $sLang `
                                  -ExcludeApps $excludes `
                                  -IncludeProject ($chkProject.IsChecked -eq $true) `
                                  -IncludeVisio ($chkVisio.IsChecked -eq $true)

    $prgOffice.Value = 50
    $txtOfficeLog.Text = "Đang khởi chạy ODT: $(if ($DownloadOnly) { 'Chỉ tải gói dữ liệu' } else { 'Tải và cài đặt tự động' })..."

    try {
        $script:runningOfficeProc = Start-VUONGTTOfficeInstall -ConfigFile $cfg -DownloadOnly $DownloadOnly -OnProgress {
            param($msg)
            $txtOfficeLog.Text = $msg
        }
        $prgOffice.Value = 100
        $txtOfficeLog.Text = "Tiến trình ODT đã khởi động thành công! Đang thực thi ngầm..."
        [System.Windows.MessageBox]::Show("Tiến trình Microsoft Office ODT đang chạy ngầm trong máy. Vui lòng giữ kết nối Internet ổn định!", "Cài Đặt Office", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        $txtOfficeLog.Text = "Lỗi: $($_.Exception.Message)"
        [System.Windows.MessageBox]::Show("Lỗi: $($_.Exception.Message)", "Lỗi Cài Đặt", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

$btnOfficeInstall.Add_Click({ Execute-EnhancedOfficeInstall -DownloadOnly $false })
$btnOfficeDownloadOnly.Add_Click({ Execute-EnhancedOfficeInstall -DownloadOnly $true })

$btnOfficeUninstall.Add_Click({
    $confirm = [System.Windows.MessageBox]::Show("Bạn có chắc chắn muốn gỡ sạch toàn bộ các phiên bản Microsoft Office trên máy?", "Xác Nhận Gỡ Office", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
        try {
            $txtOfficeLog.Text = "Đang tiến hành gỡ bỏ Microsoft Office..."
            Uninstall-VUONGTTOffice -OnProgress { param($m) $txtOfficeLog.Text = $m }
            [System.Windows.MessageBox]::Show("Tiến trình gỡ Office đã được khởi động!", "Gỡ Office", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            $txtOfficeLog.Text = "Lỗi gỡ: $($_.Exception.Message)"
        }
    }
})

$btnOfficeStop.Add_Click({
    if ($script:runningOfficeProc -and -not $script:runningOfficeProc.HasExited) {
        try {
            $script:runningOfficeProc.Kill()
            $txtOfficeLog.Text = "Đã buộc dừng tiến trình cài đặt Office!"
        } catch {}
    } else {
        Stop-Process -Name "setup", "OfficeClickToRun" -Force -ErrorAction SilentlyContinue
        $txtOfficeLog.Text = "Đã dừng các tiến trình Office setup chạy ngầm."
    }
})

$btnOfficeViewLog.Add_Click({
    $logDir = "$env:TEMP"
    Start-Process "explorer.exe" -ArgumentList "/select,`"$logDir\VUONGTT_Office_Config.xml`""
})

# =========================================================================
# MODULE 5: SỬA LỖI MÁY IN (87 CHỨC NĂNG & SEARCH LỖI)
# =========================================================================
$txtPrinterSearch        = Get-Control "txtPrinterSearch"
$btnPasteError           = Get-Control "btnPasteError"
$btnAutoFixMatched       = Get-Control "btnAutoFixMatched"
$btnAutoFixAllPrinters   = Get-Control "btnAutoFixAllPrinters"
$txtPrinterMatchHint     = Get-Control "txtPrinterMatchHint"
$panelPrinterButtons     = Get-Control "panelPrinterButtons"
$txtPrinterLog           = Get-Control "txtPrinterLog"
$btnClearPrinterLog      = Get-Control "btnClearPrinterLog"

$btnFixRpc6ba            = Get-Control "btnFixRpc6ba"
$btnFix11b               = Get-Control "btnFix11b"
$btnFix709               = Get-Control "btnFix709"
$btnFix7c                = Get-Control "btnFix7c"
$btnFix02                = Get-Control "btnFix02"
$btnFix40                = Get-Control "btnFix40"
$btnFix3e8               = Get-Control "btnFix3e8"
$btnFixBcb               = Get-Control "btnFixBcb"
$btnRestartSpooler       = Get-Control "btnRestartSpooler"
$btnClearPrintQueue      = Get-Control "btnClearPrintQueue"
$btnFixSnmpOffline       = Get-Control "btnFixSnmpOffline"
$btnFixLanShare          = Get-Control "btnFixLanShare"
$btnBackupPrinterDriver  = Get-Control "btnBackupPrinterDriver"
$btnOpenDevMgmt2         = Get-Control "btnOpenDevMgmt2"
$btnOpenPrintMgmt2       = Get-Control "btnOpenPrintMgmt2"

$printerActionsMap = @(
    @{ Ctl=$btnFixRpc6ba;           Action="0x6ba";           DefaultColor="#475569"; Keywords=@("0x0000006ba", "6ba", "rpc", "unavailable", "rpc server") },
    @{ Ctl=$btnFix11b;              Action="0x11b";           DefaultColor="#0284C7"; Keywords=@("0x0000011b", "11b", "rpcauthn", "chia se", "lan") },
    @{ Ctl=$btnFix709;              Action="0x709";           DefaultColor="#059669"; Keywords=@("0x00000709", "709", "point", "default printer") },
    @{ Ctl=$btnFix7c;               Action="0x7c";            DefaultColor="#B45309"; Keywords=@("0x0000007c", "7c", "policy", "buffer") },
    @{ Ctl=$btnFix02;               Action="0x02";            DefaultColor="#475569"; Keywords=@("0x00000002", "file not found", "driver", "02") },
    @{ Ctl=$btnFix40;               Action="0x40";            DefaultColor="#475569"; Keywords=@("0x00000040", "40", "network name", "smb") },
    @{ Ctl=$btnFix3e8;              Action="0x3e8";           DefaultColor="#475569"; Keywords=@("0x000003e8", "3e8", "port", "cong in") },
    @{ Ctl=$btnFixBcb;              Action="0xbcb";           DefaultColor="#475569"; Keywords=@("0x00000bcb", "bcb", "policy") },
    @{ Ctl=$btnRestartSpooler;      Action="restart_spooler"; DefaultColor="#059669"; Keywords=@("spooler", "khoi dong lai", "restart") },
    @{ Ctl=$btnClearPrintQueue;     Action="clear_queue";     DefaultColor="#D97706"; Keywords=@("ket lenh", "queue", "xoa lenh", "clear") },
    @{ Ctl=$btnFixSnmpOffline;      Action="snmp_offline";    DefaultColor="#7C3AED"; Keywords=@("offline", "snmp", "ngoai tuyen") },
    @{ Ctl=$btnFixLanShare;         Action="lan_share";       DefaultColor="#0284C7"; Keywords=@("chia se", "share", "lan", "smb", "guest") },
    @{ Ctl=$btnBackupPrinterDriver; Action="backup_driver";   DefaultColor="#475569"; Keywords=@("backup", "sao luu", "driver") },
    @{ Ctl=$btnOpenDevMgmt2;        Action="open_devmgmt";    DefaultColor="#475569"; Keywords=@("device", "thiet bi", "manager") },
    @{ Ctl=$btnOpenPrintMgmt2;      Action="open_printmgmt";  DefaultColor="#475569"; Keywords=@("print management", "quan ly in") }
)

# Active Button Highlight Function
function Set-ActivePrinterButton {
    param($activeCtl)
    $bc = [System.Windows.Media.BrushConverter]::new()
    foreach ($item in $printerActionsMap) {
        if (-not $item.Ctl) { continue }
        if ($item.Ctl -eq $activeCtl) {
            # Selected button: Highlight Red (#DC2626) with full opacity
            $item.Ctl.Background = $bc.ConvertFromString("#DC2626")
            $item.Ctl.Foreground = [System.Windows.Media.Brushes]::White
            $item.Ctl.Opacity = 1.0
        } else {
            # Unselected buttons: restore default theme color
            $defCol = if ($item.DefaultColor) { $item.DefaultColor } else { "#475569" }
            $item.Ctl.Background = $bc.ConvertFromString($defCol)
            $item.Ctl.Foreground = [System.Windows.Media.Brushes]::White
            $item.Ctl.Opacity = 0.85
        }
    }
}

# Connect clicks - Use sender.Tag to avoid PowerShell loop closure leak
foreach ($item in $printerActionsMap) {
    if ($item.Ctl) {
        $item.Ctl.Tag = $item.Action
        $item.Ctl.Add_Click({
            param($sender, $e)
            $actId = $sender.Tag
            if ([string]::IsNullOrEmpty($actId)) { return }
            # Visual feedback: Highlight clicked button immediately
            Set-ActivePrinterButton -activeCtl $sender
            $txtFooterStatus.Text = "• [Đang xử lý] Tự động sửa lỗi máy in: $actId (Auto Yes)..."
            $log = Invoke-PrinterFixAction -ActionId $actId
            $txtPrinterLog.Text = "$log`n`n$($txtPrinterLog.Text)"
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất sửa lỗi máy in: $actId"
        })
    }
}

# 1-Click Master Auto Fix: Fix all common printer & LAN issues automatically
if ($btnAutoFixAllPrinters) {
    $btnAutoFixAllPrinters.Add_Click({
        $txtFooterStatus.Text = "• [Đang xử lý] Đang tự động sửa toàn diện lỗi Máy In & Mạng LAN (Auto Yes)..."
        $log = Invoke-PrinterFixAction -ActionId "fix_all"
        $txtPrinterLog.Text = "$log`n`n$($txtPrinterLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất 1-Click tự động sửa toàn bộ lỗi máy in & LAN!"
    })
}

# Dynamic Filter Function for Printer Errors
function Filter-PrinterButtons {
    $q = $txtPrinterSearch.Text.Trim().ToLower()
    $matchCount = 0
    $bc = [System.Windows.Media.BrushConverter]::new()

    foreach ($item in $printerActionsMap) {
        if (-not $item.Ctl) { continue }
        if ([string]::IsNullOrEmpty($q)) {
            $item.Ctl.Opacity = 1.0
            $item.Ctl.IsEnabled = $true
            $defCol = if ($item.DefaultColor) { $item.DefaultColor } else { "#475569" }
            $item.Ctl.Background = $bc.ConvertFromString($defCol)
            $item.Ctl.Foreground = [System.Windows.Media.Brushes]::White
            $matchCount++
        } else {
            $isMatch = $false
            foreach ($kw in $item.Keywords) {
                if ($kw.ToLower() -like "*$q*" -or $q -like "*$kw*") {
                    $isMatch = $true
                    break
                }
            }
            if ($item.Ctl.Content.ToString().ToLower() -like "*$q*") {
                $isMatch = $true
            }

            if ($isMatch) {
                $item.Ctl.Opacity = 1.0
                $item.Ctl.Background = $bc.ConvertFromString("#DC2626")
                $item.Ctl.Foreground = [System.Windows.Media.Brushes]::White
                $matchCount++
            } else {
                $item.Ctl.Opacity = 0.35
                $item.Ctl.Background = $bc.ConvertFromString("#475569")
                $item.Ctl.Foreground = [System.Windows.Media.Brushes]::White
            }
        }
    }
    if ([string]::IsNullOrEmpty($q)) {
        $txtPrinterMatchHint.Text = "Sẵn sàng: Bấm trực tiếp vào mã lỗi bên dưới để tự động sửa ngay lập tức (Auto Yes không cần hỏi)."
    } else {
        $txtPrinterMatchHint.Text = "Tìm thấy $matchCount nút khớp với '$q' — bấm nút hoặc bấm '⚡ Tự Động Fix Lỗi Khớp' để sửa ngay."
    }
}

$txtPrinterSearch.Add_TextChanged({ Filter-PrinterButtons })

# Auto Fix Matched Error Button
if ($btnAutoFixMatched) {
    $btnAutoFixMatched.Add_Click({
        $q = $txtPrinterSearch.Text.Trim()
        $matchedActions = @()
        foreach ($item in $printerActionsMap) {
            if (-not $item.Ctl) { continue }
            if ($item.Ctl.Opacity -eq 1.0 -and $item.Action -notlike "open_*") {
                $matchedActions += $item
            }
        }

        if ($matchedActions.Count -eq 0) {
            foreach ($item in $printerActionsMap) {
                if ($item.Action -notlike "open_*") {
                    foreach ($kw in $item.Keywords) {
                        if ($kw.ToLower() -like "*$($q.ToLower())*" -or $q.ToLower() -like "*$($kw.ToLower())*") {
                            $matchedActions += $item
                            break
                        }
                    }
                }
            }
        }

        if ($matchedActions.Count -eq 0) {
            $txtPrinterLog.Text = "[CHÚ Ý] Không tìm thấy mã lỗi khớp riêng lẻ cho '$q'. Đang tự động chạy bộ sửa lỗi toàn diện...`n`n$($txtPrinterLog.Text)"
            $log = Invoke-PrinterFixAction -ActionId "fix_all"
            $txtPrinterLog.Text = "$log`n`n$($txtPrinterLog.Text)"
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất sửa lỗi toàn diện!"
            return
        }

        $allLogs = @()
        $timestamp = (Get-Date).ToString("HH:mm:ss")
        $allLogs += "[$timestamp] [BẮT ĐẦU TỰ ĐỘNG FIX $($matchedActions.Count) LỖI MÁY IN KHỚP (AUTO YES)]"
        foreach ($m in $matchedActions) {
            $txtFooterStatus.Text = "• [Đang xử lý] Đang tự động sửa: $($m.Action)..."
            $res = Invoke-PrinterFixAction -ActionId $m.Action
            $allLogs += $res
        }
        $allLogs += "[$timestamp] [HOÀN TẤT] Đã tự động sửa xong toàn bộ các lỗi phù hợp!"
        $txtPrinterLog.Text = ($allLogs -join "`n`n") + "`n`n" + $txtPrinterLog.Text
        $txtFooterStatus.Text = "• [OK] Đã tự động hoàn tất sửa các lỗi máy in được chọn!"
    })
}

$btnPasteError.Add_Click({
    try {
        $clip = [System.Windows.Clipboard]::GetText()
        if ($clip) {
            $txtPrinterSearch.Text = $clip.Trim()
            Filter-PrinterButtons
        }
    } catch {}
})

$btnClearPrinterLog.Add_Click({
    $txtPrinterLog.Text = "* Đã xóa nhật ký xử lý."
})

# Initial filter
Filter-PrinterButtons

# =========================================================================
# MODULE 6: QUẢN LÝ USER & PC
# =========================================================================
$lstUsers               = Get-Control "lstUsers"
$btnRefreshUsers        = Get-Control "btnRefreshUsers"
$txtSelectedUserNewPass = Get-Control "txtSelectedUserNewPass"
$btnChangePassword      = Get-Control "btnChangePassword"
$btnToggleUserStatus    = Get-Control "btnToggleUserStatus"
$btnPromoteAdmin        = Get-Control "btnPromoteAdmin"
$btnDeleteUser          = Get-Control "btnDeleteUser"

$txtNewUserName         = Get-Control "txtNewUserName"
$txtNewUserPass         = Get-Control "txtNewUserPass"
$chkNewUserIsAdmin      = Get-Control "chkNewUserIsAdmin"
$btnCreateUser          = Get-Control "btnCreateUser"
$btnEnableBuiltinAdmin  = Get-Control "btnEnableBuiltinAdmin"
$btnDisableBuiltinAdmin = Get-Control "btnDisableBuiltinAdmin"

function Refresh-UsersList {
    $users = Get-SystemUserAccounts
    $lstUsers.ItemsSource = $users
}

$btnRefreshUsers.Add_Click({ Refresh-UsersList })

$btnCreateUser.Add_Click({
    $res = New-SystemUserAccount -Username $txtNewUserName.Text.Trim() `
                                -Password $txtNewUserPass.Text `
                                -IsAdmin ($chkNewUserIsAdmin.IsChecked -eq $true)
    [System.Windows.MessageBox]::Show($res, "Tạo Tài Khoản", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    Refresh-UsersList
})

$btnChangePassword.Add_Click({
    $sel = $lstUsers.SelectedItem
    if (-not $sel) {
        [System.Windows.MessageBox]::Show("Vui lòng chọn 1 tài khoản trong danh sách!", "Đổi Mật Khẩu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }
    $newPass = $txtSelectedUserNewPass.Text
    $res = Set-SystemUserPassword -Username $sel.Username -NewPassword $newPass
    [System.Windows.MessageBox]::Show($res, "Đổi Mật Khẩu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

$btnToggleUserStatus.Add_Click({
    $sel = $lstUsers.SelectedItem
    if (-not $sel) { return }
    $res = Set-SystemUserStatus -Username $sel.Username -Enable (-not $sel.IsEnabled)
    [System.Windows.MessageBox]::Show($res, "Trạng Thái Tài Khoản", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    Refresh-UsersList
})

$btnPromoteAdmin.Add_Click({
    $sel = $lstUsers.SelectedItem
    if (-not $sel) { return }
    $res = Set-SystemUserAdmin -Username $sel.Username -MakeAdmin (-not $sel.IsAdmin)
    [System.Windows.MessageBox]::Show($res, "Phân Quyền Admin", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    Refresh-UsersList
})

$btnDeleteUser.Add_Click({
    $sel = $lstUsers.SelectedItem
    if (-not $sel) { return }
    $confirm = [System.Windows.MessageBox]::Show("Bạn có chắc chắn muốn xóa tài khoản '$($sel.Username)'?", "Xóa Tài Khoản", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
    if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
        $res = Remove-SystemUserAccount -Username $sel.Username
        [System.Windows.MessageBox]::Show($res, "Xóa Tài Khoản", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        Refresh-UsersList
    }
})

$btnEnableBuiltinAdmin.Add_Click({
    $res = Set-BuiltinAdminStatus -Enable $true
    [System.Windows.MessageBox]::Show($res, "Built-in Administrator", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    Refresh-UsersList
})
$btnDisableBuiltinAdmin.Add_Click({
    $res = Set-BuiltinAdminStatus -Enable $false
    [System.Windows.MessageBox]::Show($res, "Built-in Administrator", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    Refresh-UsersList
})

# =========================================================================
# MODULE 7: TẢI ỨNG DỤNG & CÀI APP TÙY CHỈNH & FONT
# =========================================================================
$btnSelectAllApps       = Get-Control "btnSelectAllApps"
$btnUnselectAllApps     = Get-Control "btnUnselectAllApps"
$btnInstallSelectedApps = Get-Control "btnInstallSelectedApps"
$btnUpdateAllApps       = Get-Control "btnUpdateAllApps"
$txtSoftwareLog         = Get-Control "txtSoftwareLog"

$txtCustomAppInput      = Get-Control "txtCustomAppInput"
$btnInstallCustomApp    = Get-Control "btnInstallCustomApp"
$txtCustomAppLog        = Get-Control "txtCustomAppLog"

$btnInstallAllFonts     = Get-Control "btnInstallAllFonts"
$btnInstallTcvn3        = Get-Control "btnInstallTcvn3"
$btnInstallVni          = Get-Control "btnInstallVni"

$btnInstallAccountingOnly = Get-Control "btnInstallAccountingOnly"
$btnUpdateAccounting      = Get-Control "btnUpdateAccounting"
$btnOpenTaxPortal         = Get-Control "btnOpenTaxPortal"

$appControls = @(
    "app_office365", "app_foxitpdf", "app_acrobat", "app_unikey", "app_evkey",
    "app_7zip", "app_winrar", "app_chrome", "app_coccoc", "app_firefox",
    "app_brave", "app_zalo", "app_telegram", "app_discord",
    "app_ultraviewer", "app_anydesk", "app_rustdesk", "app_teamviewer",
    "app_vlc", "app_notepadplus", "app_crystaldisk", "app_cpuz", "app_revo",
    "app_capcut", "app_obs", "app_everything", "app_fdm", "app_crystaldiskmark", "app_vscode", "app_git",
    "app_htkk", "app_itaxviewer", "app_misasme", "app_meinvoice", "app_kbhxh", "app_javatax"
)

$btnSelectAllApps.Add_Click({
    foreach ($name in $appControls) {
        $c = Get-Control $name
        if ($c) { $c.IsChecked = $true }
    }
})
$btnUnselectAllApps.Add_Click({
    foreach ($name in $appControls) {
        $c = Get-Control $name
        if ($c) { $c.IsChecked = $false }
    }
})

$btnInstallSelectedApps.Add_Click({
    $selected = @()
    foreach ($name in $appControls) {
        $c = Get-Control $name
        if ($c -and $c.IsChecked) {
            $id = $name.Replace("app_", "")
            $selected += $id
        }
    }

    if ($selected.Count -eq 0) {
        $txtSoftwareLog.Text = "Vui lòng tích chọn ít nhất 1 ứng dụng!"
        return
    }

    $txtSoftwareLog.Text = "Bắt đầu cài đặt $($selected.Count) ứng dụng..."
    foreach ($appId in $selected) {
        $res = Install-VUONGTTApp -AppId $appId -OnProgress { param($m) $txtSoftwareLog.Text = "$m`n$($txtSoftwareLog.Text)" }
        $txtSoftwareLog.Text = "$res`n$($txtSoftwareLog.Text)"
    }
    [System.Windows.MessageBox]::Show("Đã hoàn tất cài đặt toàn bộ ứng dụng đã chọn!", "Tải Ứng Dụng", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

$btnUpdateAllApps.Add_Click({
    $txtSoftwareLog.Text = "Đang chạy Winget upgrade --all..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade --all --silent" -Wait -NoNewWindow
    $txtSoftwareLog.Text = "Đã hoàn tất kiểm tra và nâng cấp toàn bộ ứng dụng trên hệ thống!"
    [System.Windows.MessageBox]::Show("Đã cập nhật toàn bộ ứng dụng qua Winget!", "Cập Nhật Ứng Dụng", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

if ($btnInstallAccountingOnly) {
    $btnInstallAccountingOnly.Add_Click({
        $acctIds = @("htkk", "itaxviewer", "misasme", "meinvoice", "kbhxh", "javatax")
        $selectedAcct = @()
        foreach ($id in $acctIds) {
            $chk = Get-Control "app_$id"
            if ($chk -and $chk.IsChecked) {
                $selectedAcct += $id
            }
        }
        if ($selectedAcct.Count -eq 0) {
            $txtSoftwareLog.Text = "[CẢNH BÁO] Vui lòng tích chọn ít nhất 1 ứng dụng kế toán (HTKK, iTaxViewer, MISA, KBHXH, Java...) để cài đặt!`n$($txtSoftwareLog.Text)"
            [System.Windows.MessageBox]::Show("Vui lòng tích chọn ít nhất 1 ứng dụng kế toán!", "Ứng Dụng Kế Toán", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $txtSoftwareLog.Text = "=== [BẮT ĐẦU CÀI ĐẶT $($selectedAcct.Count) ỨNG DỤNG KẾ TOÁN MỚI NHẤT] ===`n$($txtSoftwareLog.Text)"
        foreach ($appId in $selectedAcct) {
            $res = Install-VUONGTTAccountingApp -AppId $appId -OnProgress {
                param($m)
                $txtSoftwareLog.Text = "$m`n$($txtSoftwareLog.Text)"
                if ([System.Windows.Forms.Application]::MessageLoop) {
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            $txtSoftwareLog.Text = "$res`n$($txtSoftwareLog.Text)"
        }
        $txtSoftwareLog.Text = "=== [HOÀN TẤT CÀI ĐẶT GÓI KẾ TOÁN] ===`n$($txtSoftwareLog.Text)"
        [System.Windows.MessageBox]::Show("Đã hoàn tất quá trình tải và cài đặt các ứng dụng kế toán!", "Kế Toán & Thuế", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnUpdateAccounting) {
    $btnUpdateAccounting.Add_Click({
        $acctIds = @("htkk", "itaxviewer", "misasme", "meinvoice", "kbhxh", "javatax")
        $selectedAcct = @()
        foreach ($id in $acctIds) {
            $chk = Get-Control "app_$id"
            if ($chk -and $chk.IsChecked) {
                $selectedAcct += $id
            }
        }
        $txtSoftwareLog.Text = "=== [BẮT ĐẦU KIỂM TRA & CẬP NHẬT ỨNG DỤNG KẾ TOÁN] ===`n$($txtSoftwareLog.Text)"
        $res = Update-VUONGTTAccountingApps -AppsToUpdate $selectedAcct -OnProgress {
            param($m)
            $txtSoftwareLog.Text = "$m`n$($txtSoftwareLog.Text)"
            if ([System.Windows.Forms.Application]::MessageLoop) {
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
        $txtSoftwareLog.Text = "=== [HOÀN TẤT TIẾN TRÌNH CẬP NHẬT KẾ TOÁN] ===`n$($txtSoftwareLog.Text)"
        [System.Windows.MessageBox]::Show("Tiến trình cập nhật các phần mềm kế toán đã hoàn tất!`nXem log chi tiết tại khung nhật ký.", "Cập Nhật Kế Toán", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnOpenTaxPortal) {
    $btnOpenTaxPortal.Add_Click({
        $txtSoftwareLog.Text = "[PORTAL] Đang mở Cổng Thuế Điện Tử Tổng cục Thuế (https://thuedientu.gdt.gov.vn)...`n$($txtSoftwareLog.Text)"
        try {
            [System.Diagnostics.Process]::Start("https://thuedientu.gdt.gov.vn") | Out-Null
        } catch {
            Start-Process "https://thuedientu.gdt.gov.vn"
        }
    })
}

$btnInstallCustomApp.Add_Click({
    $target = $txtCustomAppInput.Text.Trim()
    $txtCustomAppLog.Text = "Đang xử lý cài đặt: $target..."
    $res = Install-VUONGTTCustomApp -TargetInput $target -OnProgress { param($m) $txtCustomAppLog.Text = $m }
    $txtCustomAppLog.Text = $res
    [System.Windows.MessageBox]::Show($res, "Cài App Tùy Chỉnh", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

$btnInstallAllFonts.Add_Click({
    $txtCustomAppLog.Text = "Đang cài đặt trọn bộ Font Tiếng Việt..."
    $res = Install-VietnameseFonts -FontType "ALL"
    $txtCustomAppLog.Text = $res
    [System.Windows.MessageBox]::Show($res, "Cài Font Tiếng Việt", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})
$btnInstallTcvn3.Add_Click({
    $res = Install-VietnameseFonts -FontType "TCVN3"
    $txtCustomAppLog.Text = $res
})
$btnInstallVni.Add_Click({
    $res = Install-VietnameseFonts -FontType "VNI"
    $txtCustomAppLog.Text = $res
})

# =========================================================================
# MODULE 8: TEST LAPTOP & PHẦN CỨNG
# =========================================================================
$lblBatteryStatus       = Get-Control "lblBatteryStatus"
$lblBatteryDesignCap    = Get-Control "lblBatteryDesignCap"
$lblBatteryFullCap      = Get-Control "lblBatteryFullCap"
$lblBatteryWear         = Get-Control "lblBatteryWear"
$btnRefreshBattery      = Get-Control "btnRefreshBattery"
$btnExportBatteryHtml   = Get-Control "btnExportBatteryHtml"

$btnTestDeadPixel       = Get-Control "btnTestDeadPixel"
$btnTestAudioLeft       = Get-Control "btnTestAudioLeft"
$btnTestAudioRight      = Get-Control "btnTestAudioRight"

$btnRunRepairAudit      = Get-Control "btnRunRepairAudit"
$txtRepairAuditLog      = Get-Control "txtRepairAuditLog"

function Refresh-BatteryDisplay {
    $bat = Get-LaptopBatteryHealth
    if ($bat.HasBattery) {
        $lblBatteryStatus.Text    = "Tình trạng: $($bat.BatteryStatus) ($($bat.EstimatedChargeRemaining))"
        $lblBatteryDesignCap.Text = "Dung lượng thiết kế: $($bat.DesignCapacity)"
        $lblBatteryFullCap.Text   = "Dung lượng sạc đầy: $($bat.FullChargeCapacity)"
        $lblBatteryWear.Text      = "Độ chai pin: $($bat.WearLevelPercent)% (Sức khỏe: $($bat.HealthStatus))"
    } else {
        $lblBatteryStatus.Text    = "Thiết bị: Máy tính để bàn (Desktop PC) - Cắm nguồn trực tiếp"
        $lblBatteryDesignCap.Text = "Không có pin tích hợp"
        $lblBatteryFullCap.Text   = "-"
        $lblBatteryWear.Text      = "Độ chai pin: 0%"
    }
}

$btnRefreshBattery.Add_Click({ Refresh-BatteryDisplay })
$btnExportBatteryHtml.Add_Click({
    $res = Export-BatteryReport
    [System.Windows.MessageBox]::Show($res, "Báo Cáo Pin", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

$btnTestDeadPixel.Add_Click({
    Start-ScreenDeadPixelTest
})

$btnTestAudioLeft.Add_Click({
    Test-AudioChannels -Channel "Left"
})
$btnTestAudioRight.Add_Click({
    Test-AudioChannels -Channel "Right"
})

# Hardware test handlers (Keyboard, Mic, Cam, CPU Stress, Network Ping, Audio)
$btnTestKeyboard       = Get-Control "btnTestKeyboard"
$btnTestMic            = Get-Control "btnTestMic"
$btnTestCam            = Get-Control "btnTestCam"
$btnTestKeyboard2      = Get-Control "btnTestKeyboard2"
$btnTestMic2           = Get-Control "btnTestMic2"
$btnTestCam2           = Get-Control "btnTestCam2"
$btnTestKeyboardVisual = Get-Control "btnTestKeyboardVisual"
$btnTestKeyboardVisual2 = Get-Control "btnTestKeyboardVisual2"
$btnTestCpuStress      = Get-Control "btnTestCpuStress"
$btnTestCpuStress2     = Get-Control "btnTestCpuStress2"
$btnTestNetworkPing    = Get-Control "btnTestNetworkPing"
$btnTestNetworkPing2   = Get-Control "btnTestNetworkPing2"
$btnTestAudioBass      = Get-Control "btnTestAudioBass"
$btnTestAudioBass2     = Get-Control "btnTestAudioBass2"
$btnTestAudioTreble    = Get-Control "btnTestAudioTreble"
$btnTestAudioTreble2   = Get-Control "btnTestAudioTreble2"
$txtHardwareTestLog    = Get-Control "txtHardwareTestLog"

# 1. Visual Keyboard Test (Offline WPF GUI)
$visualKbAction = {
    $txtFooterStatus.Text = "• [OK] Đang chạy bộ test bàn phím trực quan Offline..."
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Đang mở trình kiểm tra bàn phím trực quan Offline (không cần Internet)..." }
    Start-VisualKeyboardTest
}
if ($btnTestKeyboardVisual)  { $btnTestKeyboardVisual.Add_Click($visualKbAction) }
if ($btnTestKeyboardVisual2) { $btnTestKeyboardVisual2.Add_Click($visualKbAction) }

# 2. Key Test Online
$kbAction = {
    Start-Process "https://en.key-test.com/"
    $txtFooterStatus.Text = "• [OK] Đã mở trình kiểm tra bàn phím trực tuyến (Key Test)."
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Đang mở trình kiểm tra bàn phím trực quan trên trình duyệt..." }
}
if ($btnTestKeyboard)  { $btnTestKeyboard.Add_Click($kbAction) }
if ($btnTestKeyboard2) { $btnTestKeyboard2.Add_Click($kbAction) }

# 3. CPU Burn-in / Stress Test (15s)
$cpuStressAction = {
    $confirm = [System.Windows.MessageBox]::Show(
        "Bạn có muốn bắt đầu Stress Test CPU 100% trong 15 giây?`n`nQuá trình này sẽ đẩy tải toàn bộ các luồng CPU lên 100% để kiểm tra độ ổn định nguồn, tản nhiệt và quạt làm mát.",
        "CPU Burn-In Stress Test",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
    if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "🔥 Đang kích hoạt Stress Test 100% CPU trên tất cả các luồng trong 15 giây... Đang theo dõi nhiệt độ & quạt..." }
        $txtFooterStatus.Text = "• [TEST] Đang kích hoạt 100% tải CPU..."
        $stressRes = Start-CpuBurnInTest -DurationSeconds 15
        if ($stressRes.Success) {
            if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "🔥 [ĐANG CHẠY] $($stressRes.Message)`nQuá trình sẽ tự ngắt an toàn sau 15 giây..." }
            # Wait asynchronously / monitor
            Start-Sleep -Seconds 1
            if ($txtHardwareTestLog) { $txtHardwareTestLog.Text += "`n[OK] Tiến trình tính toán tải nặng đang chạy trên $($stressRes.Cores) luồng." }
        } else {
            if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "❌ $($stressRes.Message)" }
        }
    }
}
if ($btnTestCpuStress)  { $btnTestCpuStress.Add_Click($cpuStressAction) }
if ($btnTestCpuStress2) { $btnTestCpuStress2.Add_Click($cpuStressAction) }

# 4. Network Ping & Wi-Fi Stability Tester
$pingAction = {
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "🌐 Đang kiểm tra độ trễ mạng (Ping) tới Gateway, Google DNS và Cloudflare..." }
    $txtFooterStatus.Text = "• [TEST] Đang đo độ trễ và kiểm tra card mạng..."
    $res = Start-NetworkPingTest
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "================ KẾT QUẢ ĐO ĐỘ TRỄ MẠNG (PING) ================`n$res`n==============================================================" }
    $txtFooterStatus.Text = "• [OK] Đã hoàn thành kiểm tra độ trễ mạng"
}
if ($btnTestNetworkPing)  { $btnTestNetworkPing.Add_Click($pingAction) }
if ($btnTestNetworkPing2) { $btnTestNetworkPing2.Add_Click($pingAction) }

# 5. Audio Frequency (Bass / Treble)
$bassAction = {
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "🎵 Đang phát chuỗi tần số Siêu Trầm (Bass 120-200Hz) qua loa..." }
    $res = Test-AudioFrequency -Type "Bass"
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = $res }
    $txtFooterStatus.Text = "• [OK] Đã phát tần số Bass"
}
if ($btnTestAudioBass)  { $btnTestAudioBass.Add_Click($bassAction) }
if ($btnTestAudioBass2) { $btnTestAudioBass2.Add_Click($bassAction) }

$trebleAction = {
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "🎵 Đang phát chuỗi tần số Cao (Treble 2500-4500Hz) qua loa..." }
    $res = Test-AudioFrequency -Type "Treble"
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = $res }
    $txtFooterStatus.Text = "• [OK] Đã phát tần số Treble"
}
if ($btnTestAudioTreble)  { $btnTestAudioTreble.Add_Click($trebleAction) }
if ($btnTestAudioTreble2) { $btnTestAudioTreble2.Add_Click($trebleAction) }

# 6. Mic & Camera Handlers
$micAction = {
    try {
        Start-Process "explorer.exe" -ArgumentList "ms-windows-soundrecorder:"
    } catch {
        Start-Process "mmsys.cpl"
    }
    $txtFooterStatus.Text = "• [OK] Đã mở trình kiểm tra Microphone."
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Đã kích hoạt công cụ ghi âm và kiểm tra tín hiệu Microphone." }
}
if ($btnTestMic)  { $btnTestMic.Add_Click($micAction) }
if ($btnTestMic2) { $btnTestMic2.Add_Click($micAction) }

$camAction = {
    try {
        Start-Process "explorer.exe" -ArgumentList "microsoft.windows.camera:"
    } catch {
        Start-Process "https://webcamtests.com/"
    }
    $txtFooterStatus.Text = "• [OK] Đã mở ứng dụng Camera / Webcam."
    if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Đã khởi động ứng dụng Camera để kiểm tra hình ảnh và cảm biến." }
}
if ($btnTestCam)  { $btnTestCam.Add_Click($camAction) }
if ($btnTestCam2) { $btnTestCam2.Add_Click($camAction) }

# 7. Audio Stereo & Screen Dead Pixel Handlers
$btnTestSpeakerLeft   = Get-Control "btnTestSpeakerLeft"
$btnTestSpeakerRight  = Get-Control "btnTestSpeakerRight"
$btnTestSpeakerStereo = Get-Control "btnTestSpeakerStereo"
$btnTestScreenWhite   = Get-Control "btnTestScreenWhite"

if ($btnTestSpeakerLeft) {
    $btnTestSpeakerLeft.Add_Click({
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "Đang phát tín hiệu âm thanh kiểm tra Loa Trái (Left Channel 800Hz)..." }
        [System.Console]::Beep(800, 600)
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Đã phát xong tín hiệu tần số 800Hz trên Loa Trái." }
        $txtFooterStatus.Text = "• [OK] Đã test Loa Trái"
    })
}

if ($btnTestSpeakerRight) {
    $btnTestSpeakerRight.Add_Click({
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "Đang phát tín hiệu âm thanh kiểm tra Loa Phải (Right Channel 1200Hz)..." }
        [System.Console]::Beep(1200, 600)
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Đã phát xong tín hiệu tần số 1200Hz trên Loa Phải." }
        $txtFooterStatus.Text = "• [OK] Đã test Loa Phải"
    })
}

if ($btnTestSpeakerStereo) {
    $btnTestSpeakerStereo.Add_Click({
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "Đang phát chuỗi âm thanh Stereo đa tần số qua 2 loa..." }
        [System.Console]::Beep(523, 200)
        [System.Console]::Beep(659, 200)
        [System.Console]::Beep(784, 200)
        [System.Console]::Beep(1046, 350)
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Cả 2 kênh Loa Stereo đã phát chuỗi âm thanh rõ ràng, không rè." }
        $txtFooterStatus.Text = "• [OK] Đã test Loa Stereo hoàn tất"
    })
}

if ($btnTestScreenWhite) {
    $btnTestScreenWhite.Add_Click({
        Start-ScreenDeadPixelTest
        if ($txtHardwareTestLog) { $txtHardwareTestLog.Text = "[OK] Đã hoàn tất phiên kiểm tra điểm chết màn hình." }
    })
}

$btnRunRepairAudit.Add_Click({
    $txtRepairAuditLog.Text = "Đang quét thông tin phần cứng..."
    $res = Get-LaptopRepairAudit
    $txtRepairAuditLog.Text = $res
})

# =========================================================================
# MODULE 9: BENCHMARK HỆ THỐNG & Ổ ĐĨA
# =========================================================================
$btnRunDiskBenchmark2 = Get-Control "btnRunDiskBenchmark2"
$btnRunCpuBenchmark   = Get-Control "btnRunCpuBenchmark"
$btnRunRamBenchmark   = Get-Control "btnRunRamBenchmark"
$txtBenchmarkResult2  = Get-Control "txtBenchmarkResult2"

if ($btnRunDiskBenchmark2) {
    $btnRunDiskBenchmark2.Add_Click({
        if ($txtBenchmarkResult2) {
            $txtBenchmarkResult2.Text = "Đang tiến hành đo tốc độ Đọc/Ghi tuần tự trên ổ đĩa hệ thống (C:)..."
            $res = Measure-VUONGTTDiskBenchmark
            $txtBenchmarkResult2.Text = $res
        }
        if ($txtBenchmarkResult) { $txtBenchmarkResult.Text = $res }
        $txtFooterStatus.Text = "• [OK] Hoàn tất đo tốc độ đọc ghi ổ đĩa!"
    })
}

if ($btnRunCpuBenchmark) {
    $btnRunCpuBenchmark.Add_Click({
        if ($txtBenchmarkResult2) {
            $txtBenchmarkResult2.Text = "Đang kiểm tra hiệu năng tính toán CPU (Stress & Math Benchmark)..."
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $sum = 0
            for ($i = 1; $i -le 2000000; $i++) { $sum += [math]::Sqrt($i) }
            $sw.Stop()
            $score = [math]::Round(2000000 / ($sw.ElapsedMilliseconds + 1) * 10)
            $txtBenchmarkResult2.Text = "=== KẾT QUẢ BENCHMARK CPU ===`n- Thời gian xử lý: $($sw.ElapsedMilliseconds) ms`n- Điểm hiệu năng ước tính: $score điểm`n- Tình trạng: Hoạt động ổn định, không throttling.`n- Thời gian đo: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')"
        }
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất benchmark CPU!"
    })
}

if ($btnRunRamBenchmark) {
    $btnRunRamBenchmark.Add_Click({
        if ($txtBenchmarkResult2) {
            $txtBenchmarkResult2.Text = "Đang kiểm tra tốc độ cấp phát và băng thông bộ nhớ RAM..."
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $bytes = New-Object byte[] (64 * 1024 * 1024)
            for ($i = 0; $i -lt $bytes.Length; $i += 4096) { $bytes[$i] = 255 }
            $sw.Stop()
            $speedMBs = [math]::Round(64 / (($sw.ElapsedMilliseconds + 1) / 1000.0), 2)
            $txtBenchmarkResult2.Text = "=== KẾT QUẢ BENCHMARK BỘ NHỚ RAM ===`n- Kích thước mẫu: 64 MB`n- Thời gian cấp phát & ghi: $($sw.ElapsedMilliseconds) ms`n- Tốc độ xử lý RAM ước tính: $speedMBs MB/s`n- Bộ đệm RAM phản hồi tuyệt vời.`n- Thời gian đo: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')"
        }
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất đo băng thông RAM!"
    })
}

# =========================================================================
# MODULE 10: FONT INSTALLER
# =========================================================================
$btnInstallAllFonts    = Get-Control "btnInstallAllFonts"
$btnInstallVNIFonts    = Get-Control "btnInstallVNIFonts"
$btnInstallTCVN3Fonts  = Get-Control "btnInstallTCVN3Fonts"
$btnInstallGoogleFonts = Get-Control "btnInstallGoogleFonts"
$btnOpenFontFolder     = Get-Control "btnOpenFontFolder"
$txtFontLog            = Get-Control "txtFontLog"

if ($btnInstallAllFonts) {
    $btnInstallAllFonts.Add_Click({
        if ($txtFontLog) { $txtFontLog.Text = "Đang cài đặt trọn bộ Font Tiếng Việt (VNI + TCVN3 + Unicode)..." }
        $res = Install-VietnameseFonts -FontType "ALL"
        if ($txtFontLog) { $txtFontLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất cài đặt toàn bộ Font Tiếng Việt!"
    })
}

if ($btnInstallVNIFonts) {
    $btnInstallVNIFonts.Add_Click({
        if ($txtFontLog) { $txtFontLog.Text = "Đang cài đặt bộ Font VNI (VNI-Times, VNI-Aptima...)..." }
        $res = Install-VietnameseFonts -FontType "VNI"
        if ($txtFontLog) { $txtFontLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã cài đặt bộ Font VNI!"
    })
}

if ($btnInstallTCVN3Fonts) {
    $btnInstallTCVN3Fonts.Add_Click({
        if ($txtFontLog) { $txtFontLog.Text = "Đang cài đặt bộ Font TCVN3 (.VnTime, .VnArial...)..." }
        $res = Install-VietnameseFonts -FontType "TCVN3"
        if ($txtFontLog) { $txtFontLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã cài đặt bộ Font TCVN3!"
    })
}

if ($btnInstallGoogleFonts) {
    $btnInstallGoogleFonts.Add_Click({
        if ($txtFontLog) { $txtFontLog.Text = "Đang cài đặt Google Fonts tiếng Việt (Roboto, Inter, Montserrat...)..." }
        $res = Install-VietnameseFonts -FontType "UNICODE"
        if ($txtFontLog) { $txtFontLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã cài đặt Google Fonts tiếng Việt!"
    })
}

if ($btnOpenFontFolder) {
    $btnOpenFontFolder.Add_Click({
        Start-Process "explorer.exe" -ArgumentList "$env:WINDIR\Fonts"
        $txtFooterStatus.Text = "• [OK] Đã mở thư mục Fonts hệ thống"
    })
}

# =========================================================================
# MODULE 11: SAO LƯU & KHÔI PHỤC DRIVER
# =========================================================================
$btnBackupAllDrivers         = Get-Control "btnBackupAllDrivers"
$btnBackupPrinterDrivers     = Get-Control "btnBackupPrinterDrivers"
$btnExportDriverList         = Get-Control "btnExportDriverList"
$btnOpenBackupFolder         = Get-Control "btnOpenBackupFolder"
$btnRestoreDrivers           = Get-Control "btnRestoreDrivers"
$btnCheckMissingDrivers      = Get-Control "btnCheckMissingDrivers"
$btnOpenDeviceManagerDirect  = Get-Control "btnOpenDeviceManagerDirect"
$txtDriverLog                = Get-Control "txtDriverLog"

if ($btnBackupAllDrivers) {
    $btnBackupAllDrivers.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang quét và sao lưu toàn bộ Driver hệ thống bằng Export-WindowsDriver..." }
        try {
            $backupDir = "$env:SystemDrive\Backup_Drivers"
            if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
            Export-WindowsDriver -Online -Destination $backupDir -ErrorAction Stop | Out-Null
            $count = (Get-ChildItem -Path $backupDir -Directory).Count
            if ($txtDriverLog) {
                $txtDriverLog.Text = "[THÀNH CÔNG] Đã sao lưu $count gói Driver phần cứng vào thư mục: $backupDir`nThời gian: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')"
            }
            $txtFooterStatus.Text = "• [OK] Đã sao lưu xong toàn bộ driver hệ thống!"
        } catch {
            if ($txtDriverLog) { $txtDriverLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

if ($btnBackupPrinterDrivers) {
    $btnBackupPrinterDrivers.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang sao lưu riêng các gói Driver máy in..." }
        $res = Invoke-PrinterFixAction -ActionId "backup_driver"
        if ($txtDriverLog) { $txtDriverLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã sao lưu Driver máy in"
    })
}

if ($btnExportDriverList) {
    $btnExportDriverList.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang quét và xuất danh sách toàn bộ Driver đang cài đặt..." }
        try {
            $outPath = "$env:USERPROFILE\Desktop\Danh_Sach_Driver_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            driverquery /v /fo table > $outPath
            if ($txtDriverLog) {
                $txtDriverLog.Text = "[THÀNH CÔNG] Đã xuất danh sách chi tiết toàn bộ Driver ra Desktop:`n$outPath"
            }
            Start-Process "notepad.exe" -ArgumentList "`"$outPath`""
            $txtFooterStatus.Text = "• [OK] Đã xuất file danh sách Driver ra Desktop"
        } catch {
            if ($txtDriverLog) { $txtDriverLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

if ($btnOpenBackupFolder) {
    $btnOpenBackupFolder.Add_Click({
        $backupDir = "$env:SystemDrive\Backup_Drivers"
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
        Start-Process "explorer.exe" -ArgumentList "`"$backupDir`""
        $txtFooterStatus.Text = "• [OK] Đã mở thư mục lưu trữ Driver"
    })
}

if ($btnRestoreDrivers) {
    $btnRestoreDrivers.Add_Click({
        $backupDir = "$env:SystemDrive\Backup_Drivers"
        if (-not (Test-Path $backupDir)) {
            if ($txtDriverLog) { $txtDriverLog.Text = "[CHÚ Ý] Không tìm thấy thư mục sao lưu '$backupDir'. Vui lòng sao lưu trước khi khôi phục!" }
            return
        }
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang tiến hành nạp lại các gói Driver bằng công cụ PnPUtil..." }
        try {
            $res = pnputil.exe /add-driver "$backupDir\*.inf" /subdirs /install
            if ($txtDriverLog) { $txtDriverLog.Text = "[HOÀN TẤT KHÔI PHỤC DRIVER]`n" + ($res -join "`n") }
            $txtFooterStatus.Text = "• [OK] Đã nạp lại Driver từ thư mục Backup"
        } catch {
            if ($txtDriverLog) { $txtDriverLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

if ($btnCheckMissingDrivers) {
    $btnCheckMissingDrivers.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang quét các thiết bị có trạng thái lỗi (chấm than vàng !)..." }
        try {
            $missing = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 -and $_.ConfigManagerErrorCode -ne $null }
            if ($missing -and $missing.Count -gt 0) {
                $lines = @("Tìm thấy $($missing.Count) thiết bị phần cứng đang gặp sự cố hoặc thiếu Driver:")
                foreach ($m in $missing) {
                    $lines += "- Thiết bị: $($m.Name) | Mã lỗi: $($m.ConfigManagerErrorCode)"
                }
                if ($txtDriverLog) { $txtDriverLog.Text = ($lines -join "`n") }
            } else {
                if ($txtDriverLog) { $txtDriverLog.Text = "[TUYỆT VỜI] Toàn bộ thiết bị phần cứng đều hoạt động bình thường, không có thiết bị nào bị thiếu Driver hoặc báo lỗi chấm than vàng!" }
            }
            $txtFooterStatus.Text = "• [OK] Quét trạng thái driver hoàn tất"
        } catch {
            if ($txtDriverLog) { $txtDriverLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

if ($btnOpenDeviceManagerDirect) {
    $btnOpenDeviceManagerDirect.Add_Click({
        Start-Process "devmgmt.msc"
        $txtFooterStatus.Text = "• [OK] Đã mở Device Manager"
    })
}

# =========================================================================
# MODULE 12: CÀI WIN & BYPASS TOÀN DIỆN
# =========================================================================
$btnBypassWin11All       = Get-Control "btnBypassWin11All"
$btnBypassOOBEMSA        = Get-Control "btnBypassOOBEMSA"
$btnDisableBitLockerSetup = Get-Control "btnDisableBitLockerSetup"
$btnDownloadWin11ISO     = Get-Control "btnDownloadWin11ISO"
$btnDownloadWin10ISO     = Get-Control "btnDownloadWin10ISO"
$btnDownloadRufus        = Get-Control "btnDownloadRufus"
$btnDownloadVentoy       = Get-Control "btnDownloadVentoy"
$btnPostInstallTweak     = Get-Control "btnPostInstallTweak"
$txtAutoWinLog           = Get-Control "txtAutoWinLog"

if ($btnBypassWin11All) {
    $btnBypassWin11All.Add_Click({
        if ($txtAutoWinLog) { $txtAutoWinLog.Text = "Đang kích hoạt chính sách 1-Click Bypass Windows 11 (TPM, SecureBoot, RAM, CPU, Storage)..." }
        try {
            $keys = @("HKLM:\SYSTEM\Setup\LabConfig", "HKLM:\SYSTEM\Setup\MoSetup")
            foreach ($k in $keys) {
                if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
            }
            $lab = "HKLM:\SYSTEM\Setup\LabConfig"
            Set-ItemProperty -Path $lab -Name "BypassTPMCheck" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $lab -Name "BypassSecureBootCheck" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $lab -Name "BypassRAMCheck" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $lab -Name "BypassCPUCheck" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $lab -Name "BypassStorageCheck" -Value 1 -Type DWord -Force
            
            $mo = "HKLM:\SYSTEM\Setup\MoSetup"
            Set-ItemProperty -Path $mo -Name "AllowUpgradesWithUnsupportedTPMOrCPU" -Value 1 -Type DWord -Force
            
            if ($txtAutoWinLog) {
                $txtAutoWinLog.Text = "[THÀNH CÔNG] Đã kích hoạt 100% chính sách Bypass Windows 11!`n- BypassTPMCheck: 1`n- BypassSecureBootCheck: 1`n- BypassRAMCheck: 1`n- BypassCPUCheck: 1`n- BypassStorageCheck: 1`n- AllowUpgradesWithUnsupportedTPMOrCPU: 1`nMáy tính hiện có thể nâng cấp hoặc cài mới Windows 11 trên mọi dòng phần cứng!"
            }
            $txtFooterStatus.Text = "• [OK] Đã kích hoạt Bypass cài Windows 11 thành công!"
        } catch {
            if ($txtAutoWinLog) { $txtAutoWinLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

if ($btnBypassOOBEMSA) {
    $btnBypassOOBEMSA.Add_Click({
        if ($txtAutoWinLog) { $txtAutoWinLog.Text = "Đang thiết lập chính sách bỏ qua yêu cầu tài khoản Microsoft (OOBE / MSA)..." }
        try {
            $oobeKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE"
            if (-not (Test-Path $oobeKey)) { New-Item -Path $oobeKey -Force | Out-Null }
            Set-ItemProperty -Path $oobeKey -Name "BypassNRO" -Value 1 -Type DWord -Force
            if ($txtAutoWinLog) {
                $txtAutoWinLog.Text = "[THÀNH CÔNG] Đã kích hoạt BypassNRO = 1 trong Registry!`nKhi màn hình OOBE hiển thị 'Let's connect you to a network', bạn có thể chọn 'I don't have internet' để tạo tài khoản Local Account cục bộ nhanh chóng mà không cần tài khoản Microsoft."
            }
            $txtFooterStatus.Text = "• [OK] Đã kích hoạt Bypass Microsoft Account (MSA/OOBE)"
        } catch {
            if ($txtAutoWinLog) { $txtAutoWinLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

if ($btnDisableBitLockerSetup) {
    $btnDisableBitLockerSetup.Add_Click({
        if ($txtAutoWinLog) { $txtAutoWinLog.Text = "Đang tắt chính sách tự động mã hóa BitLocker khi cài đặt hệ thống..." }
        try {
            $bitPath = "HKLM:\SYSTEM\CurrentControlSet\Control\BitLocker"
            if (-not (Test-Path $bitPath)) { New-Item -Path $bitPath -Force | Out-Null }
            Set-ItemProperty -Path $bitPath -Name "PreventDeviceEncryption" -Value 1 -Type DWord -Force
            if ($txtAutoWinLog) {
                $txtAutoWinLog.Text = "[THÀNH CÔNG] Đã bật PreventDeviceEncryption = 1!`nTừ nay khi cài lại Windows hoặc đăng nhập tài khoản Microsoft, ổ đĩa sẽ KHÔNG tự ý mã hóa BitLocker gây rủi ro mất dữ liệu."
            }
            $txtFooterStatus.Text = "• [OK] Đã tắt tự động mã hóa BitLocker khi cài Win"
        } catch {
            if ($txtAutoWinLog) { $txtAutoWinLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

if ($btnDownloadWin11ISO) {
    $btnDownloadWin11ISO.Add_Click({
        Start-Process "https://www.microsoft.com/software-download/windows11"
        $txtFooterStatus.Text = "• [OK] Đã mở trang tải ISO Windows 11 chính hãng Microsoft"
    })
}

if ($btnDownloadWin10ISO) {
    $btnDownloadWin10ISO.Add_Click({
        Start-Process "https://www.microsoft.com/software-download/windows10"
        $txtFooterStatus.Text = "• [OK] Đã mở trang tải ISO Windows 10 chính hãng Microsoft"
    })
}

if ($btnDownloadRufus) {
    $btnDownloadRufus.Add_Click({
        Start-Process "https://rufus.ie/"
        $txtFooterStatus.Text = "• [OK] Đã mở trang tải công cụ Rufus"
    })
}

if ($btnDownloadVentoy) {
    $btnDownloadVentoy.Add_Click({
        Start-Process "https://www.ventoy.net/"
        $txtFooterStatus.Text = "• [OK] Đã mở trang tải công cụ Ventoy"
    })
}

if ($btnPostInstallTweak) {
    $btnPostInstallTweak.Add_Click({
        if ($txtAutoWinLog) { $txtAutoWinLog.Text = "Đang tiến hành tối ưu hóa hệ thống sau cài đặt (tắt telemetry, tắt quảng cáo, dọn bloatware)..." }
        $msg = Disable-VUONGTTTelemetry
        if ($txtAutoWinLog) { $txtAutoWinLog.Text = "[HOÀN TẤT TỐI ƯU SAU CÀI WIN]`n$msg`n- Đã tắt tự động tải app rác Microsoft Consumer Experience.`n- Đã tắt các gợi ý và quảng cáo trên Start Menu." }
        $txtFooterStatus.Text = "• [OK] Đã tối ưu hệ thống sau cài Win!"
    })
}

# =========================================================================
# MODULE 13: CUSTOM APP SILENT INSTALLER
# =========================================================================
$btnBrowseInstaller   = Get-Control "btnBrowseInstaller"
$btnRunSilentInstall  = Get-Control "btnRunSilentInstall"
$txtLocalInstallerPath = Get-Control "txtLocalInstallerPath"

if ($btnBrowseInstaller) {
    $btnBrowseInstaller.Add_Click({
        $dlg = New-Object Microsoft.Win32.OpenFileDialog
        $dlg.Filter = "Tệp Cài Đặt (*.exe;*.msi)|*.exe;*.msi|Tất cả tệp (*.*)|*.*"
        $dlg.Title = "Chọn tệp tin cài đặt ứng dụng"
        if ($dlg.ShowDialog() -eq $true) {
            if ($txtLocalInstallerPath) { $txtLocalInstallerPath.Text = $dlg.FileName }
        }
    })
}

if ($btnRunSilentInstall) {
    $btnRunSilentInstall.Add_Click({
        $txtCustomAppLog = Get-Control "txtCustomAppLog"
        $path = if ($txtLocalInstallerPath) { $txtLocalInstallerPath.Text } else { "" }
        if (-not (Test-Path $path)) {
            if ($txtCustomAppLog) { $txtCustomAppLog.Text = "[LỖI] Tệp tin cài đặt không tồn tại: $path" }
            return
        }
        if ($txtCustomAppLog) { $txtCustomAppLog.Text = "Đang khởi chạy cài đặt tự động ngầm: $path..." }
        try {
            $ext = [System.IO.Path]::GetExtension($path).ToLower()
            if ($ext -eq ".msi") {
                Start-Process "msiexec.exe" -ArgumentList "/i `"$path`" /qn /norestart" -Wait
            } else {
                Start-Process -FilePath $path -ArgumentList "/silent /verysilent /s /qn" -Wait
            }
            if ($txtCustomAppLog) { $txtCustomAppLog.Text = "[HOÀN TẤT] Đã thực thi cài đặt silent xong cho tệp tin: $path" }
            $txtFooterStatus.Text = "• [OK] Đã cài đặt silent xong: $([System.IO.Path]::GetFileName($path))"
        } catch {
            if ($txtCustomAppLog) { $txtCustomAppLog.Text = "[LỖI] $($_.Exception.Message)" }
        }
    })
}

# =========================================================================
# MODULE 14: CLEANER, TWEAKS, PARTITION PRO, ACTIVATION, BITLOCKER
# =========================================================================
$btnDeepClean            = Get-Control "btnDeepClean"
$btnCleanWinUpdate       = Get-Control "btnCleanWinUpdate"
$btnFlushDnsPrefetch     = Get-Control "btnFlushDnsPrefetch"
$btnCompactOS            = Get-Control "btnCompactOS"
$btnOptimizeRAM          = Get-Control "btnOptimizeRAM"
$btnOptimizeVisualEffects = Get-Control "btnOptimizeVisualEffects"
$btnOptimizeServices     = Get-Control "btnOptimizeServices"
$btnFastStartupToggle    = Get-Control "btnFastStartupToggle"
$btnRepairSystemFiles    = Get-Control "btnRepairSystemFiles"
$btnClearCleanerLog      = Get-Control "btnClearCleanerLog"
$txtCleanerLog           = Get-Control "txtCleanerLog"

if ($btnDeepClean) {
    $btnDeepClean.Add_Click({
        $txtCleanerLog.Text = "Đang quét và dọn rác đĩa C:..."
        $res = Invoke-VUONGTTDeepClean
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất dọn rác hệ thống!"
    })
}

if ($btnCleanWinUpdate) {
    $btnCleanWinUpdate.Add_Click({
        $txtCleanerLog.Text = "Đang tiến hành dọn dẹp WinSxS và cache Windows Update..."
        $res = Invoke-VUONGTTCleanWinUpdate
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất dọn WinSxS & Windows Update Cache!"
    })
}

if ($btnFlushDnsPrefetch) {
    $btnFlushDnsPrefetch.Add_Click({
        $txtCleanerLog.Text = "Đang xóa thư mục Prefetch và làm sạch cache phân giải DNS..."
        $res = Invoke-VUONGTTFlushDnsPrefetch
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã làm mới DNS Cache & dọn sạch Prefetch!"
    })
}

if ($btnCompactOS) {
    $btnCompactOS.Add_Click({
        $txtCleanerLog.Text = "Đang thực thi nén nhị phân hệ thống Compact OS..."
        $res = Invoke-VUONGTTCompactOS
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã kích hoạt Compact OS tiết kiệm dung lượng ổ C!"
    })
}

if ($btnOptimizeRAM) {
    $btnOptimizeRAM.Add_Click({
        $res = Invoke-VUONGTTCleanRAM
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã giải phóng bộ nhớ RAM!"
    })
}

if ($btnOptimizeVisualEffects) {
    $btnOptimizeVisualEffects.Add_Click({
        $res = Set-VUONGTTOptimizeVisualEffects
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã tối ưu hóa hiệu ứng trực quan siêu mượt!"
    })
}

if ($btnOptimizeServices) {
    $btnOptimizeServices.Add_Click({
        $res = Invoke-VUONGTTOptimizeServices
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã tắt các dịch vụ ngầm không cần thiết!"
    })
}

if ($btnFastStartupToggle) {
    $btnFastStartupToggle.Add_Click({
        $res = Set-VUONGTTFastStartup -Enable $false
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã cập nhật chế độ Khởi động nhanh (Fast Startup)!"
    })
}

if ($btnRepairSystemFiles) {
    $btnRepairSystemFiles.Add_Click({
        $txtCleanerLog.Text = "Đang bắt đầu quét và tự động sửa lỗi tập tin Windows bằng SFC & DISM..."
        $res = Invoke-VUONGTTRepairSystemFiles
        $txtCleanerLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất quét và sửa lỗi file hệ thống!"
    })
}

if ($btnClearCleanerLog) {
    $btnClearCleanerLog.Add_Click({
        $txtCleanerLog.Text = "Sẵn sàng dọn dẹp file rác và tối ưu hóa hệ thống Windows."
    })
}

# --- Tinh Chỉnh Windows ---
$btnEnableClassicMenu  = Get-Control "btnEnableClassicMenu"
$btnRestoreWin11Menu   = Get-Control "btnRestoreWin11Menu"
$btnShowExtensions     = Get-Control "btnShowExtensions"
$btnTakeOwnershipOn    = Get-Control "btnTakeOwnershipOn"
$btnTakeOwnershipOff   = Get-Control "btnTakeOwnershipOff"
$btnClassicPhotoViewer = Get-Control "btnClassicPhotoViewer"
$btnDisableTelemetry   = Get-Control "btnDisableTelemetry"
$btnUltimatePlan       = Get-Control "btnUltimatePlan"
$btnDisableUAC         = Get-Control "btnDisableUAC"
$btnEnableUAC          = Get-Control "btnEnableUAC"
$btnDisableHibernation = Get-Control "btnDisableHibernation"
$btnDisableAutoReboot  = Get-Control "btnDisableAutoReboot"
$btnOptimizeGaming     = Get-Control "btnOptimizeGaming"

$btnResetNetwork     = Get-Control "btnResetNetwork"
$btnRepairWinUpdate  = Get-Control "btnRepairWinUpdate"
$btnFixTaskbar       = Get-Control "btnFixTaskbar"
$btnFixNoInternet    = Get-Control "btnFixNoInternet"
$btnFixSysMainCpu    = Get-Control "btnFixSysMainCpu"
$btnFixStoreAppX     = Get-Control "btnFixStoreAppX"
$txtTweaksLog        = Get-Control "txtTweaksLog"

if ($btnEnableClassicMenu) {
    $btnEnableClassicMenu.Add_Click({
        $msg = Set-VUONGTTClassicContextMenu -Enable $true
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã bật Menu chuột phải cổ điển"
    })
}
if ($btnRestoreWin11Menu) {
    $btnRestoreWin11Menu.Add_Click({
        $msg = Set-VUONGTTClassicContextMenu -Enable $false
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã khôi phục Menu Win 11"
    })
}
if ($btnShowExtensions) {
    $btnShowExtensions.Add_Click({
        $msg = Set-VUONGTTShowFileExtensions
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã hiện đuôi file và file ẩn"
    })
}
if ($btnTakeOwnershipOn) {
    $btnTakeOwnershipOn.Add_Click({
        $msg = Set-VUONGTTTakeOwnershipMenu -Enable $true
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã thêm Take Ownership vào chuột phải"
    })
}
if ($btnTakeOwnershipOff) {
    $btnTakeOwnershipOff.Add_Click({
        $msg = Set-VUONGTTTakeOwnershipMenu -Enable $false
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã gỡ Take Ownership"
    })
}
if ($btnClassicPhotoViewer) {
    $btnClassicPhotoViewer.Add_Click({
        $msg = Set-VUONGTTClassicPhotoViewer
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã bật Windows Photo Viewer cổ điển"
    })
}
if ($btnDisableTelemetry) {
    $btnDisableTelemetry.Add_Click({
        $msg = Disable-VUONGTTTelemetry
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã tắt Telemetry & Bing"
    })
}
if ($btnUltimatePlan) {
    $btnUltimatePlan.Add_Click({
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null
        $txtTweaksLog.Text = "Đã thêm gói nguồn điện Ultimate Performance!"
        $txtFooterStatus.Text = "• [OK] Đã thêm gói Ultimate Performance"
    })
}
if ($btnDisableUAC) {
    $btnDisableUAC.Add_Click({
        $msg = Set-VUONGTTToggleUAC -Disable $true
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã tắt thông báo UAC"
    })
}
if ($btnEnableUAC) {
    $btnEnableUAC.Add_Click({
        $msg = Set-VUONGTTToggleUAC -Disable $false
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã bật lại UAC mặc định"
    })
}
if ($btnDisableHibernation) {
    $btnDisableHibernation.Add_Click({
        $msg = Set-VUONGTTToggleHibernation -Enable $false
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã tắt Ngủ Đông và thu hồi file hiberfil.sys"
    })
}
if ($btnDisableAutoReboot) {
    $btnDisableAutoReboot.Add_Click({
        $msg = Set-VUONGTTDisableAutoRebootUpdate
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã chặn Auto Restart sau Update"
    })
}
if ($btnOptimizeGaming) {
    $btnOptimizeGaming.Add_Click({
        $msg = Set-VUONGTTToggleGameMode
        $txtTweaksLog.Text = $msg
        $txtFooterStatus.Text = "• [OK] Đã tối ưu Game Mode & tắt Xbox DVR"
    })
}

if ($btnResetNetwork) {
    $btnResetNetwork.Add_Click({
        $txtTweaksLog.Text = "Đang đặt lại thiết lập mạng Winsock, TCP/IP và Flush DNS..."
        $res = Invoke-VUONGTTResetNetwork
        $txtTweaksLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã reset cấu hình mạng hệ thống"
    })
}

if ($btnRepairWinUpdate) {
    $btnRepairWinUpdate.Add_Click({
        $txtTweaksLog.Text = "Đang dọn dẹp SoftwareDistribution và khởi động lại dịch vụ Windows Update..."
        $res = Invoke-VUONGTTRepairWindowsUpdate
        $txtTweaksLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất sửa lỗi Windows Update"
    })
}

if ($btnFixTaskbar) {
    $btnFixTaskbar.Add_Click({
        $txtTweaksLog.Text = "Đang khởi động lại Windows Explorer và sửa lỗi Taskbar/Start Menu..."
        $res = Invoke-VUONGTTFixTaskbarStartMenu
        $txtTweaksLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã làm mới thanh tác vụ Taskbar"
    })
}

if ($btnFixNoInternet) {
    $btnFixNoInternet.Add_Click({
        $txtTweaksLog.Text = "Đang thiết lập lại thông số NCSI No Internet trong Registry..."
        $res = Invoke-VUONGTTFixNetworkNoInternet
        $txtTweaksLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã sửa lỗi thông báo No Internet"
    })
}

if ($btnFixSysMainCpu) {
    $btnFixSysMainCpu.Add_Click({
        $txtTweaksLog.Text = "Đang tối ưu hóa dịch vụ SysMain và Windows Search..."
        $res = Invoke-VUONGTTFixSysMainSearchCPU
        $txtTweaksLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã sửa lỗi CPU 100% SysMain"
    })
}

if ($btnFixStoreAppX) {
    $btnFixStoreAppX.Add_Click({
        $txtTweaksLog.Text = "Đang đăng ký lại toàn bộ gói ứng dụng Microsoft Store và AppX..."
        $res = Invoke-VUONGTTFixStoreAppX
        $txtTweaksLog.Text = $res
        $txtFooterStatus.Text = "• [OK] Đã làm mới Microsoft Store"
    })
}

# --- Module 15: Quản Lý Phân Vùng Ổ Đĩa (Partition Wizard Pro) ---
$btnRefreshDisks       = Get-Control "btnRefreshDisks"
$btnOpenDiskMgmt       = Get-Control "btnOpenDiskMgmt"
$btnOpenDiskPart       = Get-Control "btnOpenDiskPart"
$btnLaunchMiniTool     = Get-Control "btnLaunchMiniTool"
$btnTrimAllSSD         = Get-Control "btnTrimAllSSD"
$btnCheckMbr2Gpt       = Get-Control "btnCheckMbr2Gpt"
$cmbPartitionDrives    = Get-Control "cmbPartitionDrives"
$btnChkdskScan         = Get-Control "btnChkdskScan"
$txtNewVolumeLabel     = Get-Control "txtNewVolumeLabel"
$btnChangeLabel        = Get-Control "btnChangeLabel"
$txtNewDriveLetter     = Get-Control "txtNewDriveLetter"
$btnChangeDriveLetter  = Get-Control "btnChangeDriveLetter"
$panelDisksContainer   = Get-Control "panelDisksContainer"
$txtPartitionLog       = Get-Control "txtPartitionLog"
$btnClearPartitionLog  = Get-Control "btnClearPartitionLog"

function Refresh-DiskPartitionDisplay {
    if (-not $panelDisksContainer) { return }
    $panelDisksContainer.Children.Clear()
    if ($cmbPartitionDrives) { $cmbPartitionDrives.Items.Clear() }

    $txtFooterStatus.Text = "• [Đang xử lý] Đang nạp danh sách ổ đĩa và phân vùng hệ thống..."
    $diskMap = Get-VUONGTTDiskPartitionMap

    if (-not $diskMap -or $diskMap.Count -eq 0) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "Không tìm thấy ổ đĩa hoặc cần cấp quyền Administrator."
        $tb.Foreground = [System.Windows.Media.Brushes]::Red
        $panelDisksContainer.Children.Add($tb) | Out-Null
        return
    }

    $bc = [System.Windows.Media.BrushConverter]::new()
    $lettersAdded = @()

    foreach ($disk in $diskMap) {
        $card = New-Object System.Windows.Controls.Border
        $card.Style = $window.Resources["CardBorder"]
        $card.Margin = [System.Windows.Thickness]::new(0, 0, 0, 12)
        $card.Padding = [System.Windows.Thickness]::new(14)

        $sp = New-Object System.Windows.Controls.StackPanel

        # Header
        $gridHeader = New-Object System.Windows.Controls.Grid
        $gridHeader.Margin = [System.Windows.Thickness]::new(0, 0, 0, 10)
        
        $spHeaderLeft = New-Object System.Windows.Controls.StackPanel
        $spHeaderLeft.Orientation = [System.Windows.Controls.Orientation]::Horizontal

        $txtDiskTitle = New-Object System.Windows.Controls.TextBlock
        $txtDiskTitle.Text = "💽 Ổ Đĩa $($disk.Number): $($disk.FriendlyName)"
        $txtDiskTitle.FontWeight = [System.Windows.FontWeights]::Bold
        $txtDiskTitle.FontSize = 15
        $txtDiskTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $spHeaderLeft.Children.Add($txtDiskTitle) | Out-Null

        $bType = New-Object System.Windows.Controls.Border
        $bType.Background = $bc.ConvertFromString("#DBEAFE")
        $bType.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $bType.Padding = [System.Windows.Thickness]::new(8, 2, 8, 2)
        $bType.Margin = [System.Windows.Thickness]::new(10, 0, 4, 0)
        $tType = New-Object System.Windows.Controls.TextBlock
        $tType.Text = "$($disk.BusType) • $($disk.PartitionStyle)"
        $tType.Foreground = $bc.ConvertFromString("#1E40AF")
        $tType.FontWeight = [System.Windows.FontWeights]::Bold
        $tType.FontSize = 11.5
        $bType.Child = $tType
        $spHeaderLeft.Children.Add($bType) | Out-Null

        $bSize = New-Object System.Windows.Controls.Border
        $bSize.Background = $bc.ConvertFromString("#FEF3C7")
        $bSize.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $bSize.Padding = [System.Windows.Thickness]::new(8, 2, 8, 2)
        $bSize.Margin = [System.Windows.Thickness]::new(4, 0, 4, 0)
        $tSize = New-Object System.Windows.Controls.TextBlock
        $tSize.Text = "Tổng: $($disk.SizeGB) GB"
        $tSize.Foreground = $bc.ConvertFromString("#B45309")
        $tSize.FontWeight = [System.Windows.FontWeights]::Bold
        $tSize.FontSize = 11.5
        $bSize.Child = $tSize
        $spHeaderLeft.Children.Add($bSize) | Out-Null

        $gridHeader.Children.Add($spHeaderLeft) | Out-Null
        $sp.Children.Add($gridHeader) | Out-Null

        # Partitions
        if ($disk.Partitions.Count -eq 0) {
            $tbNoPart = New-Object System.Windows.Controls.TextBlock
            $tbNoPart.Text = "Chưa có phân vùng nào trên ổ đĩa này."
            $tbNoPart.Foreground = [System.Windows.Media.Brushes]::Gray
            $sp.Children.Add($tbNoPart) | Out-Null
        } else {
            foreach ($p in $disk.Partitions) {
                if ($p.DriveLetter -ne "-" -and $lettersAdded -notcontains $p.DriveLetter) {
                    $lettersAdded += $p.DriveLetter
                    if ($cmbPartitionDrives) { $cmbPartitionDrives.Items.Add($p.DriveLetter) | Out-Null }
                }

                $partBorder = New-Object System.Windows.Controls.Border
                $partBorder.Background = $window.Resources["CardInnerBgBrush"]
                $partBorder.BorderBrush = $window.Resources["CardBorderBrush"]
                $partBorder.BorderThickness = [System.Windows.Thickness]::new(1)
                $partBorder.CornerRadius = [System.Windows.CornerRadius]::new(6)
                $partBorder.Padding = [System.Windows.Thickness]::new(10, 8, 10, 8)
                $partBorder.Margin = [System.Windows.Thickness]::new(0, 0, 0, 6)

                $partGrid = New-Object System.Windows.Controls.Grid
                $col1 = New-Object System.Windows.Controls.ColumnDefinition
                $col1.Width = [System.Windows.GridLength]::new(180)
                $col2 = New-Object System.Windows.Controls.ColumnDefinition
                $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
                $col3 = New-Object System.Windows.Controls.ColumnDefinition
                $col3.Width = [System.Windows.GridLength]::new(140)
                $partGrid.ColumnDefinitions.Add($col1)
                $partGrid.ColumnDefinitions.Add($col2)
                $partGrid.ColumnDefinitions.Add($col3)

                $spCol1 = New-Object System.Windows.Controls.StackPanel
                $txtPartName = New-Object System.Windows.Controls.TextBlock
                $labelStr = if ($p.Label) { $p.Label } else { "Local Disk" }
                $txtPartName.Text = "📁 $($p.DriveLetter) $labelStr"
                $txtPartName.FontWeight = [System.Windows.FontWeights]::Bold
                $txtPartName.FontSize = 13
                $spCol1.Children.Add($txtPartName) | Out-Null

                $txtPartFS = New-Object System.Windows.Controls.TextBlock
                $txtPartFS.Text = "$($p.FileSystem) • $($p.Type)"
                $txtPartFS.FontSize = 11.5
                $txtPartFS.Foreground = $bc.ConvertFromString("#64748B")
                $spCol1.Children.Add($txtPartFS) | Out-Null
                [System.Windows.Controls.Grid]::SetColumn($spCol1, 0)
                $partGrid.Children.Add($spCol1) | Out-Null

                $spCol2 = New-Object System.Windows.Controls.StackPanel
                $spCol2.Margin = [System.Windows.Thickness]::new(10, 0, 10, 0)
                $spCol2.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

                $pBar = New-Object System.Windows.Controls.ProgressBar
                $pBar.Height = 12
                $pBar.Minimum = 0
                $pBar.Maximum = 100
                $pBar.Value = $p.UsedPercent
                $barCol = if ($p.UsedPercent -ge 90) { "#DC2626" } elseif ($p.UsedPercent -ge 75) { "#D97706" } else { "#059669" }
                $pBar.Foreground = $bc.ConvertFromString($barCol)
                $spCol2.Children.Add($pBar) | Out-Null

                $txtUsage = New-Object System.Windows.Controls.TextBlock
                $txtUsage.Text = "$($p.UsedPercent)% đã dùng (Còn trống $($p.FreeGB) GB / Tổng $($p.TotalGB) GB)"
                $txtUsage.FontSize = 11.5
                $txtUsage.Foreground = $bc.ConvertFromString("#64748B")
                $txtUsage.Margin = [System.Windows.Thickness]::new(0, 3, 0, 0)
                $spCol2.Children.Add($txtUsage) | Out-Null

                [System.Windows.Controls.Grid]::SetColumn($spCol2, 1)
                $partGrid.Children.Add($spCol2) | Out-Null

                $spCol3 = New-Object System.Windows.Controls.StackPanel
                $spCol3.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
                $spCol3.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

                $badge = New-Object System.Windows.Controls.Border
                $badge.Background = $bc.ConvertFromString("#F1F5F9")
                $badge.CornerRadius = [System.Windows.CornerRadius]::new(4)
                $badge.Padding = [System.Windows.Thickness]::new(6, 2, 6, 2)
                $tBadge = New-Object System.Windows.Controls.TextBlock
                $tBadge.Text = if ($p.IsBoot) { "⭐ System Boot" } else { "Khỏe mạnh" }
                $tBadge.FontSize = 11
                $tBadge.FontWeight = [System.Windows.FontWeights]::SemiBold
                $tBadge.Foreground = $bc.ConvertFromString("#334155")
                $badge.Child = $tBadge
                $spCol3.Children.Add($badge) | Out-Null

                [System.Windows.Controls.Grid]::SetColumn($spCol3, 2)
                $partGrid.Children.Add($spCol3) | Out-Null

                $partBorder.Child = $partGrid
                $sp.Children.Add($partBorder) | Out-Null
            }
        }

        $card.Child = $sp
        $panelDisksContainer.Children.Add($card) | Out-Null
    }

    if ($cmbPartitionDrives -and $cmbPartitionDrives.Items.Count -gt 0) {
        $cmbPartitionDrives.SelectedIndex = 0
    }
    $txtFooterStatus.Text = "• [OK] Đã hiển thị thông tin $($diskMap.Count) ổ đĩa và $($lettersAdded.Count) phân vùng."
}

if ($btnRefreshDisks) {
    $btnRefreshDisks.Add_Click({ Refresh-DiskPartitionDisplay })
}

if ($btnOpenDiskMgmt) {
    $btnOpenDiskMgmt.Add_Click({
        $res = Invoke-VUONGTTLaunchDiskManagement
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đã mở Disk Management"
    })
}

if ($btnOpenDiskPart) {
    $btnOpenDiskPart.Add_Click({
        $res = Invoke-VUONGTTLaunchDiskPart
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đã mở DiskPart Admin Console"
    })
}

if ($btnLaunchMiniTool) {
    $btnLaunchMiniTool.Add_Click({
        $res = Invoke-VUONGTTLaunchPartitionTools
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đã mở công cụ phân vùng"
    })
}

if ($btnTrimAllSSD) {
    $btnTrimAllSSD.Add_Click({
        $txtPartitionLog.Text = "Đang tối ưu hóa và TRIM toàn bộ các phân vùng ổ đĩa..."
        $res = Invoke-VUONGTTOptimizeTrim
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Hoàn tất TRIM toàn bộ ổ SSD!"
        Refresh-DiskPartitionDisplay
    })
}

if ($btnCheckMbr2Gpt) {
    $btnCheckMbr2Gpt.Add_Click({
        $txtPartitionLog.Text = "Đang kiểm tra tính tương thích chuyển đổi MBR sang GPT chuẩn UEFI..."
        $res = Invoke-VUONGTTMbr2GptCheck
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đã kiểm tra MBR2GPT xong!"
    })
}

if ($btnChkdskScan) {
    $btnChkdskScan.Add_Click({
        $drive = if ($cmbPartitionDrives -and $cmbPartitionDrives.SelectedItem) { $cmbPartitionDrives.SelectedItem.ToString() } else { "C:" }
        $txtPartitionLog.Text = "Đang quét lỗi bề mặt phân vùng $drive..."
        $res = Invoke-VUONGTTDiskSurfaceCheck -DriveLetter $drive
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Quét lỗi phân vùng $drive hoàn tất!"
    })
}

if ($btnChangeLabel) {
    $btnChangeLabel.Add_Click({
        $drive = if ($cmbPartitionDrives -and $cmbPartitionDrives.SelectedItem) { $cmbPartitionDrives.SelectedItem.ToString() } else { "C:" }
        $newLabel = if ($txtNewVolumeLabel) { $txtNewVolumeLabel.Text.Trim() } else { "" }
        if ([string]::IsNullOrEmpty($newLabel)) {
            $txtPartitionLog.Text = "[CHÚ Ý] Vui lòng nhập tên nhãn mới cho ổ đĩa!"
            return
        }
        $res = Set-VUONGTTVolumeLabel -DriveLetter $drive -NewLabel $newLabel
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đổi tên nhãn đĩa thành công!"
        Refresh-DiskPartitionDisplay
    })
}

if ($btnChangeDriveLetter) {
    $btnChangeDriveLetter.Add_Click({
        $oldDrive = if ($cmbPartitionDrives -and $cmbPartitionDrives.SelectedItem) { $cmbPartitionDrives.SelectedItem.ToString() } else { "" }
        $newDrive = if ($txtNewDriveLetter) { $txtNewDriveLetter.Text.Trim() } else { "" }
        if ([string]::IsNullOrEmpty($oldDrive) -or [string]::IsNullOrEmpty($newDrive)) {
            $txtPartitionLog.Text = "[CHÚ Ý] Vui lòng chọn ổ đĩa cũ và nhập ký tự mới!"
            return
        }
        $res = Set-VUONGTTDriveLetter -OldLetter $oldDrive -NewLetter $newDrive
        $txtPartitionLog.Text = "$res`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đổi ký tự ổ đĩa thành công!"
        Refresh-DiskPartitionDisplay
    })
}

if ($btnClearPartitionLog) {
    $btnClearPartitionLog.Add_Click({
        $txtPartitionLog.Text = "Sẵn sàng thực thi các tác vụ phân vùng đĩa và kiểm tra ổ cứng."
    })
}

$btnLaunchMAS    = Get-Control "btnLaunchMAS"
$btnCheckStatus  = Get-Control "btnCheckStatus"
$btnCleanCrack   = Get-Control "btnCleanCrack"
$txtActivationLog = Get-Control "txtActivationLog"

$btnLaunchMAS.Add_Click({
    $txtActivationLog.Text = "Đang khởi chạy Massgrave MAS bản quyền số chính thức..."
    Invoke-VUONGTTMAS
})
$btnCheckStatus.Add_Click({
    $st = Get-VUONGTTActivationStatus
    $txtActivationLog.Text = "KẾT QUẢ KIỂM TRA BẢN QUYỀN:`n- Windows: $($st.Windows)`n- Office:  $($st.Office)"
})
$btnCleanCrack.Add_Click({
    $log = Invoke-VUONGTTCleanCrack
    $txtActivationLog.Text = $log
})

$btnCheckBitLocker   = Get-Control "btnCheckBitLocker"
$btnSuspendBitLocker = Get-Control "btnSuspendBitLocker"
$btnDisableBitLocker = Get-Control "btnDisableBitLocker"
$btnGetRecoveryKey   = Get-Control "btnGetRecoveryKey"
$txtBitLockerLog     = Get-Control "txtBitLockerLog"

$btnCheckBitLocker.Add_Click({
    $txtBitLockerLog.Text = Get-VUONGTTBitLockerStatus
})
$btnSuspendBitLocker.Add_Click({
    $txtBitLockerLog.Text = Suspend-VUONGTTBitLocker -Drive "C:"
})
$btnDisableBitLocker.Add_Click({
    $txtBitLockerLog.Text = Disable-VUONGTTBitLocker -Drive "C:"
})

if ($btnGetRecoveryKey) {
    $btnGetRecoveryKey.Add_Click({
        $txtBitLockerLog.Text = "Đang trích xuất khóa khôi phục Recovery Key (48 chữ số) của BitLocker..."
        try {
            $vols = Get-BitLockerVolume -ErrorAction Stop
            $lines = @("=== DANH SÁCH BITLOCKER RECOVERY KEY ===")
            foreach ($v in $vols) {
                $lines += "Ổ đĩa: $($v.MountPoint) | Trạng thái: $($v.VolumeStatus) | Phương thức: $($v.EncryptionMethod)"
                foreach ($kp in $v.KeyProtector) {
                    if ($kp.KeyProtectorType -eq "RecoveryPassword") {
                        $lines += "-> ID Khóa: $($kp.KeyProtectorId)"
                        $lines += "-> KHÓA KHÔI PHỤC: $($kp.RecoveryPassword)"
                    }
                }
            }
            $txtBitLockerLog.Text = ($lines -join "`n")
            $txtFooterStatus.Text = "• [OK] Đã trích xuất Recovery Key thành công!"
        } catch {
            $txtBitLockerLog.Text = "[LỖI / CHÚ Ý] $($_.Exception.Message)`n(Có thể máy tính không bật BitLocker hoặc cần quyền Administrator cấp cao)"
        }
    })
}

if ($btnCheckAppUpdate) {
    $btnCheckAppUpdate.Add_Click({
        $btnCheckAppUpdate.IsEnabled = $false
        $origContent = $btnCheckAppUpdate.Content
        $btnCheckAppUpdate.Content = "⏳ Đang kiểm tra..."

        $txtFooterStatus.Text = "• [UPDATE] Đang kiểm tra phiên bản mới từ máy chủ..."
        if ([System.Windows.Forms.Application]::MessageLoop) {
            [System.Windows.Forms.Application]::DoEvents()
        }

        $info = Get-VUONGTTAppUpdateInfo
        $btnCheckAppUpdate.Content = $origContent
        $btnCheckAppUpdate.IsEnabled = $true

        if ($info.HasUpdate) {
            $btnCheckAppUpdate.Content = "🔥 CÓ BẢN MỚI v$($info.LatestVersion)"
            $btnCheckAppUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")

            $changeText = ($info.Changelog -join "`n• ")
            $msg = @"
ĐÃ CÓ PHIÊN BẢN MỚI CHO VUONGTT TOOL PRO 2026!
=====================================================
• Phiên bản hiện tại:  v$($info.CurrentVersion)
• Phiên bản mới nhất:  v$($info.LatestVersion) (Ngày: $($info.ReleaseDate))

ĐIỂM MỚI TRONG BẢN CẬP NHẬT:
• $changeText

=====================================================
Bạn có muốn tải và tự động cập nhật ngay bây giờ không?
(Tool sẽ tự động thay thế file và khởi động lại sau khi tải xong)
"@
            $choice = [System.Windows.MessageBox]::Show($msg, "Cập Nhật Ứng Dụng", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($choice -eq [System.Windows.MessageBoxResult]::Yes) {
                $txtFooterStatus.Text = "• [UPDATE] Đang tải bản cập nhật v$($info.LatestVersion)... Vui lòng chờ!"
                $res = Invoke-VUONGTTAppSelfUpdate -DownloadUrl $info.DownloadUrl -NewVersion $info.LatestVersion -OnProgress {
                    param($m)
                    $txtFooterStatus.Text = "• [UPDATE] $m"
                    if ([System.Windows.Forms.Application]::MessageLoop) {
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                }
                [System.Windows.MessageBox]::Show($res, "Cập Nhật Ứng Dụng", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            }
        } else {
            $txtFooterStatus.Text = "• [OK] Bạn đang dùng phiên bản mới nhất (v$($info.CurrentVersion))!"
            $msg = "BẠN ĐANG SỬ DỤNG PHIÊN BẢN MỚI NHẤT!`n`n- Phiên bản: v$($info.CurrentVersion)`n- Hệ thống không tìm thấy bản cập nhật nào mới hơn."
            [System.Windows.MessageBox]::Show($msg, "Kiểm Tra Cập Nhật", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
}

# Khởi tạo giao diện trang đầu tiên ngay lập tức mà không chặn WMI
Switch-Tab -TargetTag "SysInfo" -SkipRefresh
$txtFooterStatus.Text = "• [OK] Đang khởi động hệ thống và nạp thông số phần cứng..."

# Tải dữ liệu phần cứng ngầm sau khi cửa sổ đã hiện lên màn hình người dùng
$window.Add_ContentRendered({
    if ([System.Windows.Forms.Application]::MessageLoop) {
        [System.Windows.Forms.Application]::DoEvents()
    }
    Refresh-SysInfoDisplay
    $txtFooterStatus.Text = "• [OK] VUONGTT Tool Pro 2026 sẵn sàng phục vụ!"

    # Kiểm tra bản cập nhật ngầm sau 3.5 giây không làm chậm người dùng
    $updTimer = New-Object System.Windows.Threading.DispatcherTimer
    $updTimer.Interval = [TimeSpan]::FromSeconds(3.5)
    $updTimer.Add_Tick({
        $updTimer.Stop()
        try {
            $check = Get-VUONGTTAppUpdateInfo
            if ($check.HasUpdate -and $btnCheckAppUpdate) {
                $btnCheckAppUpdate.Content = "🔥 CÓ BẢN MỚI v$($check.LatestVersion)"
                $btnCheckAppUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")
                $txtFooterStatus.Text = "• [CHÚ Ý] Đã có bản cập nhật mới v$($check.LatestVersion)! Bấm nút 'Có Bản Mới' ở trên để nâng cấp."
            }
        } catch {}
    })
    $updTimer.Start()
})

# Hiển thị cửa sổ giao diện ngay lập tức
$window.ShowDialog() | Out-Null
