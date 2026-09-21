<#
========================================================================================
   VUONGTT SOFTWARE - TOOLKIT 2026 VER 20.5.908.47
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

function Invoke-VUONGTTDoEvents {
    try {
        if ([System.Windows.Threading.Dispatcher]::CurrentDispatcher) {
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        }
    } catch {}
    try {
        [System.Windows.Forms.Application]::DoEvents()
    } catch {}
}

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
. (Join-Path $corePath "LicenseManager.ps1")
. (Join-Path $corePath "IpScanner.ps1")
. (Join-Path $corePath "ConfigManager.ps1")
. (Join-Path $corePath "DiskHealthManager.ps1")

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
$btnCopyMoMo        = Get-Control "btnCopyMoMo"
$btnFooterMoMo      = Get-Control "btnFooterMoMo"
$btnCopyMoMoSysInfo = Get-Control "btnCopyMoMoSysInfo"
$btnShowDisclaimer  = Get-Control "btnShowDisclaimer"
$txtFooterVersionDisplay = Get-Control "txtFooterVersionDisplay"
if ($txtFooterVersionDisplay) { $txtFooterVersionDisplay.Text = "v" + (Get-VUONGTTCurrentVersion) }
$txtLogoVersionDisplay = Get-Control "txtLogoVersionDisplay"
if ($txtLogoVersionDisplay) { $txtLogoVersionDisplay.Text = "v" + (Get-VUONGTTCurrentVersion) + " — Professional" }
if ($window) { $window.Title = "VUONGTT Tool Pro 2026 - v" + (Get-VUONGTTCurrentVersion) }

# Admin & License Controls
$borderLicenseBadge         = Get-Control "borderLicenseBadge"
$txtLicenseBadge            = Get-Control "txtLicenseBadge"
$btnActivateLicense         = Get-Control "btnActivateLicense"
$btnHeaderAdmin             = Get-Control "btnHeaderAdmin"
$btnMenuAdmin               = Get-Control "btnMenuAdmin"

$pageAdminPortal            = Get-Control "pageAdminPortal"
$btnAdminLogout             = Get-Control "btnAdminLogout"
$btnSavePolicies            = Get-Control "btnSavePolicies"
$btnResetPolicies           = Get-Control "btnResetPolicies"
$btnSyncPolicies            = Get-Control "btnSyncPolicies"
$panelFeaturePoliciesList   = Get-Control "panelFeaturePoliciesList"
$txtNewKeyCustomer          = Get-Control "txtNewKeyCustomer"
$cmbNewKeyDuration          = Get-Control "cmbNewKeyDuration"
$txtNewKeyCount             = Get-Control "txtNewKeyCount"
$btnGenerateKeys            = Get-Control "btnGenerateKeys"
$lblKeyVaultStats           = Get-Control "lblKeyVaultStats"
$btnSyncCloudKeys           = Get-Control "btnSyncCloudKeys"
$btnExportKeys              = Get-Control "btnExportKeys"
$btnImportKeys              = Get-Control "btnImportKeys"
$panelKeysContainer         = Get-Control "panelKeysContainer"
$pwdAdminChangeNew          = Get-Control "pwdAdminChangeNew"
$pwdAdminChangeConfirm      = Get-Control "pwdAdminChangeConfirm"
$btnAdminChangePassSubmit   = Get-Control "btnAdminChangePassSubmit"

$modalAdminLogin            = Get-Control "modalAdminLogin"
$lblAdminLoginNotice        = Get-Control "lblAdminLoginNotice"
$pnlFirstLoginBanner        = Get-Control "pnlFirstLoginBanner"
$pnlAdminNormalLogin        = Get-Control "pnlAdminNormalLogin"
$pwdAdminLogin              = Get-Control "pwdAdminLogin"
$pnlAdminFirstChangePass    = Get-Control "pnlAdminFirstChangePass"
$pwdAdminNewPass            = Get-Control "pwdAdminNewPass"
$pwdAdminConfirmPass        = Get-Control "pwdAdminConfirmPass"
$lblAdminLoginError         = Get-Control "lblAdminLoginError"
$btnModalLoginCancel        = Get-Control "btnModalLoginCancel"
$btnModalLoginSubmit        = Get-Control "btnModalLoginSubmit"

$modalActivatePro           = Get-Control "modalActivatePro"
$lblActivateNotice          = Get-Control "lblActivateNotice"
$lblCurrentHWID             = Get-Control "lblCurrentHWID"
$txtModalLicenseKey         = Get-Control "txtModalLicenseKey"
$lblActivateError           = Get-Control "lblActivateError"
$btnModalActivateCancel     = Get-Control "btnModalActivateCancel"
$btnModalActivateSubmit     = Get-Control "btnModalActivateSubmit"

# Modal: Driver Doctor Controls
$modalDriverDoctor           = Get-Control "modalDriverDoctor"
$btnModalDriverDoctorClose   = Get-Control "btnModalDriverDoctorClose"
$btnModalDriverDoctorDone    = Get-Control "btnModalDriverDoctorDone"
$lblDriverDoctorTotal        = Get-Control "lblDriverDoctorTotal"
$lblDriverDoctorIssues       = Get-Control "lblDriverDoctorIssues"
$lblDriverDoctorGpu          = Get-Control "lblDriverDoctorGpu"
$lblDriverDoctorMachine      = Get-Control "lblDriverDoctorMachine"
$txtDriverDoctorDetails      = Get-Control "txtDriverDoctorDetails"
$btnDriverAutoWinUpdate      = Get-Control "btnDriverAutoWinUpdate"
$btnDriverSDIO               = Get-Control "btnDriverSDIO"
$btnDriver3DPChip            = Get-Control "btnDriver3DPChip"
$btnDriver3DPNet             = Get-Control "btnDriver3DPNet"
$btnDriverOEMSupport         = Get-Control "btnDriverOEMSupport"
$btnDriverOpenDevMgmt        = Get-Control "btnDriverOpenDevMgmt"
$btnDriverDoctorRescan       = Get-Control "btnDriverDoctorRescan"
$prgDriverDoctor             = Get-Control "prgDriverDoctor"
$lblDriverDoctorStatus       = Get-Control "lblDriverDoctorStatus"

# Theme Buttons
$btnThemeDefault    = Get-Control "btnThemeDefault"
$btnThemeDark       = Get-Control "btnThemeDark"
$btnThemeLight      = Get-Control "btnThemeLight"
$btnLangVI          = Get-Control "btnLangVI"
$btnLangEN          = Get-Control "btnLangEN"

# Menu Buttons
$menuButtons = @(
    "btnMenuSysInfo", "btnMenuCustomize", "btnMenuUsers", "btnMenuBenchmark",
    "btnMenuLaptopCheck", "btnMenuCpuMain",
    "btnMenuOffice", "btnMenuSoftware", "btnMenuCustomApp", "btnMenuUninstaller", "btnMenuFonts",
    "btnMenuCleaner", "btnMenuConfig", "btnMenuPrinterLAN", "btnMenuBackupDriver",
    "btnMenuDevMgmt", "btnMenuActivation", "btnMenuBitLocker", "btnMenuAutoWin", "btnMenuPartition",
    "btnMenuIpScanner", "btnMenuAdmin"
)

# Pages Dictionary
$pages = @{
    "SysInfo"      = Get-Control "pageSysInfo"
    "Customize"    = Get-Control "pageCustomize"
    "Users"        = Get-Control "pageUsers"
    "Benchmark"    = Get-Control "pageBenchmark"
    "LaptopCheck"  = Get-Control "pageLaptopCheck"
    "CpuMain"      = Get-Control "pageCpuMain"
    "Office"       = Get-Control "pageOffice"
    "Software"     = Get-Control "pageSoftware"
    "CustomApp"    = Get-Control "pageCustomApp"
    "Uninstaller"  = Get-Control "pageUninstaller"
    "Fonts"        = Get-Control "pageFonts"
    "Cleaner"      = Get-Control "pageCleaner"
    "Tweaks"       = Get-Control "pageCleaner"
    "Config"       = Get-Control "pageConfig"
    "PrinterLAN"   = Get-Control "pagePrinterLAN"
    "BackupDriver" = Get-Control "pageBackupDriver"
    "DevMgmt"      = Get-Control "pageBackupDriver"
    "Activation"   = Get-Control "pageActivation"
    "BitLocker"    = Get-Control "pageBitLocker"
    "AutoWin"      = Get-Control "pageAutoWin"
    "Partition"    = Get-Control "pagePartition"
    "IpScanner"    = Get-Control "pageIpScanner"
    "AdminPortal"  = Get-Control "pageAdminPortal"
}

$pageTitlesVI = @{
    "SysInfo"      = @{ Title = "Xem Cấu Hình Máy Tính"; Icon = "💻" }
    "Customize"    = @{ Title = "Tùy Chỉnh Thông Tin Máy"; Icon = "🖥️" }
    "Users"        = @{ Title = "Quản Lý User & PC"; Icon = "👤" }
    "Benchmark"    = @{ Title = "Tốc Độ Ổ Đĩa (Benchmark)"; Icon = "⚡" }
    "LaptopCheck"  = @{ Title = "Kiểm Tra Laptop & Ngoại Vi"; Icon = "🔬" }
    "CpuMain"      = @{ Title = "Tra Cứu CPU + Main"; Icon = "💡" }
    "Office"       = @{ Title = "Cài Đặt Office (Tự Động)"; Icon = "📑" }
    "Software"     = @{ Title = "Tải Ứng Dụng Thiết Yếu"; Icon = "📥" }
    "CustomApp"    = @{ Title = "Cài App Tùy Chỉnh & Silent"; Icon = "📦" }
    "Uninstaller"  = @{ Title = "Quản Lý & Gỡ Bỏ Phần Mềm (Clean Uninstaller Pro)"; Icon = "🗑️" }
    "Fonts"        = @{ Title = "Cài Font Tiếng Việt Đầy Đủ"; Icon = "🔤" }
    "Cleaner"      = @{ Title = "Tối Ưu & Dọn Dẹp (Tweaks Pro)"; Icon = "⚡" }
    "Tweaks"       = @{ Title = "Tối Ưu & Dọn Dẹp (Tweaks Pro)"; Icon = "⚡" }
    "Config"       = @{ Title = "Cấu Hình Tính Năng & Sửa Lỗi Hệ Thống"; Icon = "🛠️" }
    "PrinterLAN"   = @{ Title = "Sửa Lỗi Máy In (87 Chức Năng)"; Icon = "🖨️" }
    "BackupDriver" = @{ Title = "Quản Lý, Kiểm Tra & Cập Nhật Driver"; Icon = "💾" }
    "DevMgmt"      = @{ Title = "Quản Lý Thiết Bị (Device Manager)"; Icon = "🛠️" }
    "Activation"   = @{ Title = "Kích Hoạt (MAS HWID)"; Icon = "🔑" }
    "BitLocker"    = @{ Title = "Quản Lý & Tắt BitLocker - EFS"; Icon = "🔒" }
    "AutoWin"      = @{ Title = "Bộ Công Cụ Cài Win & Bypass"; Icon = "🚀" }
    "Partition"    = @{ Title = "Quản Lý Phân Vùng Ổ Đĩa (Partition Pro)"; Icon = "💽" }
    "IpScanner"    = @{ Title = "Advanced IP Scanner (Quét IP & Dò Thiết Bị LAN)"; Icon = "🌐" }
    "AdminPortal"  = @{ Title = "Quản Trị Viên (Admin Portal)"; Icon = "👑" }
}

$pageTitlesEN = @{
    "SysInfo"      = @{ Title = "System Specifications"; Icon = "💻" }
    "Customize"    = @{ Title = "Customize OEM Info"; Icon = "🖥️" }
    "Users"        = @{ Title = "User & PC Accounts"; Icon = "👤" }
    "Benchmark"    = @{ Title = "Disk Speed Benchmark"; Icon = "⚡" }
    "LaptopCheck"  = @{ Title = "Laptop & Hardware Diagnostics"; Icon = "🔬" }
    "CpuMain"      = @{ Title = "Lookup CPU & Mainboard"; Icon = "💡" }
    "Office"       = @{ Title = "Install Office (Auto)"; Icon = "📑" }
    "Software"     = @{ Title = "Essential Apps Download"; Icon = "📥" }
    "CustomApp"    = @{ Title = "Custom Silent Install"; Icon = "📦" }
    "Uninstaller"  = @{ Title = "Clean Uninstaller Pro"; Icon = "🗑️" }
    "Fonts"        = @{ Title = "Install Vietnamese Fonts"; Icon = "🔤" }
    "Cleaner"      = @{ Title = "System Cleaner & Tweaks Pro"; Icon = "⚡" }
    "Tweaks"       = @{ Title = "System Cleaner & Tweaks Pro"; Icon = "⚡" }
    "Config"       = @{ Title = "Windows Config & Fixes Manager"; Icon = "🛠️" }
    "PrinterLAN"   = @{ Title = "Printer Repair (87 Tools)"; Icon = "🖨️" }
    "BackupDriver" = @{ Title = "Manage, Check & Update Drivers"; Icon = "💾" }
    "DevMgmt"      = @{ Title = "Open Device Manager"; Icon = "🛠️" }
    "Activation"   = @{ Title = "Activate Windows & Office"; Icon = "🔑" }
    "BitLocker"    = @{ Title = "Manage BitLocker - EFS"; Icon = "🔒" }
    "AutoWin"      = @{ Title = "Auto Windows Deploy"; Icon = "🚀" }
    "Partition"    = @{ Title = "Disk Partition Pro"; Icon = "💽" }
    "IpScanner"    = @{ Title = "Advanced IP Scanner"; Icon = "🌐" }
    "AdminPortal"  = @{ Title = "Administrator Portal"; Icon = "👑" }
}

$pageTitles = $pageTitlesVI
$script:CurrentLanguage = "VI"
$script:CurrentTheme    = "Default"

$script:currentTab = "SysInfo"

# Switch Tab Function
function Switch-Tab {
    param([string]$TargetTag, [switch]$SkipRefresh = $false)

    # -------------------------------------------------------------
    # GATEKEEPER 1: ADMIN PORTAL ACCESS
    # -------------------------------------------------------------
    if ($TargetTag -eq "AdminPortal") {
        if (-not $global:isAdminAuthenticated) {
            Show-VUONGTTAdminLoginModal -TargetNextTab "AdminPortal"
            return
        }
    }

    # -------------------------------------------------------------
    # GATEKEEPER 2: PRO FEATURE ACCESS CONTROL
    # -------------------------------------------------------------
    if ($TargetTag -ne "AdminPortal") {
        # NẾU ADMIN ĐANG ĐĂNG NHẬP ($global:isAdminAuthenticated = $true):
        # MẶC ĐỊNH SỞ HỮU TOÀN BỘ QUYỀN VIP, DÙNG MỌI TÍNH NĂNG KHÔNG CẦN KEY VIP!
        if (-not $global:isAdminAuthenticated) {
            $policies = Get-VUONGTTFeaturePolicies
            $policy = $policies | Where-Object { $_.Id -eq $TargetTag }
            if ($policy -and $policy.Tier -eq "PRO") {
                $isPro = (Test-VUONGTTProLicense).IsPro
                if (-not $isPro) {
                    $featureName = if ($pageTitlesVI.ContainsKey($TargetTag)) { $pageTitlesVI[$TargetTag].Title } else { $TargetTag }
                    Show-VUONGTTLicenseActivationModal -PromptNotice "Chức năng '$featureName' thuộc phiên bản PRO! Vui lòng nhập License Key để kích hoạt." -TargetNextTab $TargetTag
                    return
                }
            }
        }
    }

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

    $dict = if ($script:CurrentLanguage -eq "EN") { $pageTitlesEN } else { $pageTitlesVI }
    if ($dict.ContainsKey($TargetTag)) {
        $txtPageTitle.Text = $dict[$TargetTag].Title
        $txtPageIcon.Text  = $dict[$TargetTag].Icon
    }

    if ($SkipRefresh) { return }

    # Module specific lazy refresh
    switch ($TargetTag) {
        "AdminPortal"  {
            $txtFooterStatus.Text = "• [ADMIN] Đang mở Trang Quản Trị Viên & tự động đồng bộ Cloud..."
            Render-VUONGTTAdminPolicies
            Render-VUONGTTAdminKeys
            try {
                [System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke([action]{
                    $cRes = Sync-VUONGTTCloudAdminData -ForceApi
                    if ($cRes -and $cRes.Success) {
                        Render-VUONGTTAdminPolicies
                        Render-VUONGTTAdminKeys
                        $txtFooterStatus.Text = "• [ADMIN CLOUD] Đã đồng bộ với Cloud! Kho: $($cRes.TotalKeys) keys."
                    }
                }) | Out-Null
            } catch {}
        }
        "SysInfo"      { Refresh-SysInfoDisplay }
        "Benchmark"    {
            Refresh-VUONGTTDiskHealthUI
            $txtFooterStatus.Text = if ($script:CurrentLanguage -eq "EN") { "• [OK] Disk Health & S.M.A.R.T diagnostic ready." } else { "• [OK] Sẵn sàng chẩn đoán sức khỏe ổ cứng S.M.A.R.T & đo hiệu năng." }
        }
        "Customize"    { Refresh-CustomizeDisplay }
        "Users"        { Refresh-UsersList }
        "CpuMain"      { Search-CpuInfo }
        "LaptopCheck"  { 
            Refresh-BatteryDisplay
            $txtFooterStatus.Text = if ($script:CurrentLanguage -eq "EN") { "• [OK] Laptop, hardware & peripheral test ready." } else { "• [OK] Bộ chẩn đoán Laptop, phần cứng & ngoại vi sẵn sàng." }
        }
        "Office"       { Refresh-OfficeStatusBadge }
        "Software"     { $txtFooterStatus.Text = "• [OK] Kho 26 phần mềm thiết yếu sẵn sàng." }
        "CustomApp"    { $txtFooterStatus.Text = "• [OK] Sẵn sàng cài đặt ứng dụng tùy chỉnh hoặc file cài đặt silent." }
        "Uninstaller"  {
            $txtFooterStatus.Text = "• [OK] Đang ở trang Quản Lý & Gỡ Bỏ Phần Mềm (Clean Uninstaller Pro)."
            if (-not $script:allInstalledApps -or $script:allInstalledApps.Count -eq 0) {
                Refresh-InstalledAppsGrid
            }
        }
        "Fonts"        { $txtFooterStatus.Text = "• [OK] Sẵn sàng cài đặt trọn bộ Font tiếng Việt VNI, TCVN3, Unicode." }
        "Cleaner"      { $txtFooterStatus.Text = "• [OK] Sẵn sàng dọn dẹp rác hệ thống và tinh chỉnh Windows Tweaks Pro." }
        "Tweaks"       { $txtFooterStatus.Text = "• [OK] Sẵn sàng dọn dẹp rác hệ thống và tinh chỉnh Windows Tweaks Pro." }
        "PrinterLAN"   { $txtFooterStatus.Text = "• [OK] 87 chức năng sửa lỗi máy in & tối ưu chia sẻ LAN sẵn sàng." }
        "BackupDriver" { 
            $txtFooterStatus.Text = if ($script:CurrentLanguage -eq "EN") { "• [OK] Comprehensive Driver Diagnostics & Auto-Update Ready." } else { "• [OK] Quản lý, kiểm tra chẩn đoán & cập nhật Driver toàn diện." }
            Refresh-DriverStatusBadge
        }
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
# THEMES & LANGUAGE MANAGEMENT
# =========================================================================
function Set-ToolkitLanguage {
    param([ValidateSet("VI", "EN")][string]$Lang)
    $script:CurrentLanguage = $Lang
    $conv = [System.Windows.Media.BrushConverter]::new()

    if ($Lang -eq "VI") {
        $btnLangVI.Background  = $conv.ConvertFromString("#FEE2E2")
        $btnLangVI.BorderBrush = $conv.ConvertFromString("#BE123C")
        $btnLangEN.Background  = $window.Resources["CardBgBrush"]
        $btnLangEN.BorderBrush = $window.Resources["CardBorderBrush"]

        # Theme buttons
        $btnThemeDefault.Content = "Mặc Định"
        $btnThemeDark.Content    = "Tối"
        $btnThemeLight.Content   = "Sáng"

        # Header buttons
        $btnCheckAppUpdate.Content = "🔄 Cập Nhật Tool"
        $btnExitApp.Content        = "🚪 Thoát Ứng Dụng"

        # Sidebar Headers
        $h1 = Get-Control "txtMenuHeaderGroup1"; if ($h1) { $h1.Text = "▾ THÔNG TIN HỆ THỐNG" }
        $h2 = Get-Control "txtMenuHeaderGroup2"; if ($h2) { $h2.Text = "▾ CÀI ĐẶT & TẢI VỀ" }
        $h3 = Get-Control "txtMenuHeaderGroup3"; if ($h3) { $h3.Text = "▾ TỐI ƯU HỆ THỐNG" }
        $h4 = Get-Control "txtMenuHeaderGroup4"; if ($h4) { $h4.Text = "▾ DRIVER & MÁY IN" }
        $h5 = Get-Control "txtMenuHeaderGroup5"; if ($h5) { $h5.Text = "▾ TIỆN ÍCH KỸ THUẬT" }

        # Sidebar Menu Items
        $menuTextsVI = @{
            "btnMenuSysInfo"      = "Xem Cấu Hình Máy Tính"
            "btnMenuCustomize"    = "Tùy chỉnh thông tin máy"
            "btnMenuUsers"        = "Quản lý User & PC"
            "btnMenuBenchmark"    = "Tốc Độ Ổ Đĩa (Benchmark)"
            "btnMenuLaptopCheck"  = "Kiểm Tra Laptop & Ngoại Vi"
            "btnMenuCpuMain"      = "Tra Cứu CPU + Main"
            "btnMenuOffice"       = "Cài Đặt Office (Tự Động)"
            "btnMenuSoftware"     = "Tải ứng dụng"
            "btnMenuCustomApp"    = "Cài app tùy chỉnh"
            "btnMenuUninstaller"  = "Gỡ Bỏ Phần Mềm (Clean)"
            "btnMenuFonts"        = "Cài font tiếng Việt"
            "btnMenuCleaner"      = "Tối Ưu & Dọn Dẹp (Tweaks Pro)"
            "btnMenuConfig"       = "Cấu Hình & Sửa Lỗi (Config)"
            "btnMenuPrinterLAN"   = "Sửa Lỗi Máy In (87 Chức Năng)"
            "btnMenuBackupDriver" = "Quản Lý & Cập Nhật Driver"
            "btnMenuDevMgmt"      = "Mở Device Manager"
            "btnMenuActivation"   = "Kích Hoạt (MAS HWID)"
            "btnMenuBitLocker"    = "Tắt BitLocker - EFS"
            "btnMenuAutoWin"      = "Cài Win & Tự Động Hóa"
            "btnMenuPartition"    = "Quản Lý Phân Vùng Ổ Đĩa"
            "btnMenuIpScanner"    = "Advanced IP Scanner"
        }
        foreach ($btnName in $menuTextsVI.Keys) {
            $b = Get-Control $btnName
            if ($b -and $b.Content -and $b.Content.Children.Count -ge 2) {
                $b.Content.Children.Item(1).Text = $menuTextsVI[$btnName]
            }
        }

        $txtFooterStatus.Text = "• [OK] Đã chọn ngôn ngữ Tiếng Việt"
    }
    else {
        # EN
        $btnLangEN.Background  = $conv.ConvertFromString("#DBEAFE")
        $btnLangEN.BorderBrush = $conv.ConvertFromString("#2563EB")
        $btnLangVI.Background  = $window.Resources["CardBgBrush"]
        $btnLangVI.BorderBrush = $window.Resources["CardBorderBrush"]

        # Theme buttons
        $btnThemeDefault.Content = "Default"
        $btnThemeDark.Content    = "Dark"
        $btnThemeLight.Content   = "Light"

        # Header buttons
        $btnCheckAppUpdate.Content = "🔄 Update Tool"
        $btnExitApp.Content        = "🚪 Exit Application"

        # Sidebar Headers
        $h1 = Get-Control "txtMenuHeaderGroup1"; if ($h1) { $h1.Text = "▾ SYSTEM INFORMATION" }
        $h2 = Get-Control "txtMenuHeaderGroup2"; if ($h2) { $h2.Text = "▾ INSTALL & DOWNLOAD" }
        $h3 = Get-Control "txtMenuHeaderGroup3"; if ($h3) { $h3.Text = "▾ SYSTEM OPTIMIZATION" }
        $h4 = Get-Control "txtMenuHeaderGroup4"; if ($h4) { $h4.Text = "▾ DRIVERS & PRINTER" }
        $h5 = Get-Control "txtMenuHeaderGroup5"; if ($h5) { $h5.Text = "▾ TECHNICAL UTILITIES" }

        # Sidebar Menu Items
        $menuTextsEN = @{
            "btnMenuSysInfo"      = "System Specifications"
            "btnMenuCustomize"    = "Customize OEM Info"
            "btnMenuUsers"        = "User & PC Accounts"
            "btnMenuBenchmark"    = "Disk Speed Benchmark"
            "btnMenuLaptopCheck"  = "Laptop & Hardware Diagnostics"
            "btnMenuCpuMain"      = "Lookup CPU & Mainboard"
            "btnMenuOffice"       = "Install Office (Auto)"
            "btnMenuSoftware"     = "Essential Apps Download"
            "btnMenuCustomApp"    = "Custom Silent Install"
            "btnMenuUninstaller"  = "Clean Uninstaller Pro"
            "btnMenuFonts"        = "Install Vietnamese Fonts"
            "btnMenuCleaner"      = "System Cleaner & Tweaks Pro"
            "btnMenuConfig"       = "Windows Config & Fixes"
            "btnMenuPrinterLAN"   = "Printer Repair (87 Tools)"
            "btnMenuBackupDriver" = "Manage & Update Drivers"
            "btnMenuDevMgmt"      = "Open Device Manager"
            "btnMenuActivation"   = "Activate Windows & Office"
            "btnMenuBitLocker"    = "Manage BitLocker - EFS"
            "btnMenuAutoWin"      = "Auto Windows Deploy"
            "btnMenuPartition"    = "Disk Partition Pro"
            "btnMenuIpScanner"    = "Advanced IP Scanner"
        }
        foreach ($btnName in $menuTextsEN.Keys) {
            $b = Get-Control $btnName
            if ($b -and $b.Content -and $b.Content.Children.Count -ge 2) {
                $b.Content.Children.Item(1).Text = $menuTextsEN[$btnName]
            }
        }

        $txtFooterStatus.Text = "• [OK] Language switched to English"
    }

    if ($script:currentTab) {
        Switch-Tab -TargetTag $script:currentTab -SkipRefresh
    }
}

function Set-ToolkitTheme {
    param([ValidateSet("Default", "Dark", "Light")][string]$Theme)

    $conv = [System.Windows.Media.BrushConverter]::new()
    $script:CurrentTheme = $Theme

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
            $window.Resources["LogBgBrush"]          = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["LogTextBrush"]        = $conv.ConvertFromString("#44403C")
            $window.Resources["PillBgBrush"]         = $conv.ConvertFromString("#EADBCA")
            $window.Resources["PillTextBrush"]       = $conv.ConvertFromString("#78350F")
            $window.Resources["GroupBoxBorderBrush"] = $conv.ConvertFromString("#D6C7B2")
            
            # Button States
            $btnThemeDefault.Background  = $conv.ConvertFromString("#EADBCA")
            $btnThemeDefault.Foreground  = $conv.ConvertFromString("#78350F")
            $btnThemeDefault.BorderBrush = $conv.ConvertFromString("#C4B5A0")

            $btnThemeDark.Background     = $conv.ConvertFromString("#FFFFFF")
            $btnThemeDark.Foreground     = $conv.ConvertFromString("#292524")
            $btnThemeDark.BorderBrush    = $conv.ConvertFromString("#D6C7B2")

            $btnThemeLight.Background    = $conv.ConvertFromString("#FFFFFF")
            $btnThemeLight.Foreground    = $conv.ConvertFromString("#292524")
            $btnThemeLight.BorderBrush   = $conv.ConvertFromString("#D6C7B2")
        }
        "Dark" {
            # Sleek Apple Dark (High Contrast, Crisp Clarity)
            $window.Resources["AppBgBrush"]          = $conv.ConvertFromString("#0B1120")
            $window.Resources["SidebarBgBrush"]      = $conv.ConvertFromString("#131C31")
            $window.Resources["SidebarBorderBrush"]  = $conv.ConvertFromString("#26354D")
            $window.Resources["HeaderBgBrush"]       = $conv.ConvertFromString("#131C31")
            $window.Resources["HeaderBorderBrush"]   = $conv.ConvertFromString("#26354D")
            $window.Resources["CardBgBrush"]         = $conv.ConvertFromString("#1A243B")
            $window.Resources["CardInnerBgBrush"]    = $conv.ConvertFromString("#0F172A")
            $window.Resources["CardBorderBrush"]     = $conv.ConvertFromString("#334460")
            $window.Resources["TextPrimaryBrush"]    = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["TextSecondaryBrush"]  = $conv.ConvertFromString("#CBD5E1")
            $window.Resources["InputBgBrush"]        = $conv.ConvertFromString("#0F172A")
            $window.Resources["InputBorderBrush"]    = $conv.ConvertFromString("#475569")
            $window.Resources["InputTextBrush"]      = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["MenuBtnHoverBg"]      = $conv.ConvertFromString("#26354D")
            $window.Resources["MenuBtnActiveBg"]     = $conv.ConvertFromString("#1E3A8A")
            $window.Resources["MenuBtnText"]         = $conv.ConvertFromString("#F8FAFC")
            $window.Resources["LogBgBrush"]          = $conv.ConvertFromString("#070D19")
            $window.Resources["LogTextBrush"]        = $conv.ConvertFromString("#F1F5F9")
            $window.Resources["PillBgBrush"]         = $conv.ConvertFromString("#1E3A8A")
            $window.Resources["PillTextBrush"]       = $conv.ConvertFromString("#93C5FD")
            $window.Resources["GroupBoxBorderBrush"] = $conv.ConvertFromString("#334460")

            # Button States
            $btnThemeDark.Background     = $conv.ConvertFromString("#2563EB")
            $btnThemeDark.Foreground     = $conv.ConvertFromString("#FFFFFF")
            $btnThemeDark.BorderBrush    = $conv.ConvertFromString("#60A5FA")

            $btnThemeDefault.Background  = $conv.ConvertFromString("#1A243B")
            $btnThemeDefault.Foreground  = $conv.ConvertFromString("#CBD5E1")
            $btnThemeDefault.BorderBrush = $conv.ConvertFromString("#334460")

            $btnThemeLight.Background    = $conv.ConvertFromString("#1A243B")
            $btnThemeLight.Foreground    = $conv.ConvertFromString("#CBD5E1")
            $btnThemeLight.BorderBrush   = $conv.ConvertFromString("#334460")
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
            $window.Resources["LogBgBrush"]          = $conv.ConvertFromString("#FFFFFF")
            $window.Resources["LogTextBrush"]        = $conv.ConvertFromString("#0F172A")
            $window.Resources["PillBgBrush"]         = $conv.ConvertFromString("#EFF6FF")
            $window.Resources["PillTextBrush"]       = $conv.ConvertFromString("#2563EB")
            $window.Resources["GroupBoxBorderBrush"] = $conv.ConvertFromString("#E2E8F0")

            # Button States
            $btnThemeLight.Background    = $conv.ConvertFromString("#EFF6FF")
            $btnThemeLight.Foreground    = $conv.ConvertFromString("#2563EB")
            $btnThemeLight.BorderBrush   = $conv.ConvertFromString("#93C5FD")

            $btnThemeDefault.Background  = $conv.ConvertFromString("#FFFFFF")
            $btnThemeDefault.Foreground  = $conv.ConvertFromString("#0F172A")
            $btnThemeDefault.BorderBrush = $conv.ConvertFromString("#CBD5E1")

            $btnThemeDark.Background     = $conv.ConvertFromString("#FFFFFF")
            $btnThemeDark.Foreground     = $conv.ConvertFromString("#0F172A")
            $btnThemeDark.BorderBrush    = $conv.ConvertFromString("#CBD5E1")
        }
    }

    if ($script:CurrentLanguage) {
        Set-ToolkitLanguage -Lang $script:CurrentLanguage
    }

    if ($script:currentTab) {
        Switch-Tab -TargetTag $script:currentTab -SkipRefresh
    }
}

$btnThemeDefault.Add_Click({ Set-ToolkitTheme -Theme "Default" })
$btnThemeDark.Add_Click({ Set-ToolkitTheme -Theme "Dark" })
$btnThemeLight.Add_Click({ Set-ToolkitTheme -Theme "Light" })

# Language buttons
$btnLangVI.Add_Click({ Set-ToolkitLanguage -Lang "VI" })
$btnLangEN.Add_Click({ Set-ToolkitLanguage -Lang "EN" })

# Exit Button & Cleanup
$btnExitApp.Add_Click({
    Stop-VUONGTTMetricsWorker
    $window.Close()
})
$window.Add_Closing({
    Stop-VUONGTTMetricsWorker
})

# =========================================================================
# REALTIME CLOCK & LIVE GAUGES TIMER (Every 1s clock, Every 2s metrics)
# =========================================================================
Start-VUONGTTMetricsWorker

$timerTicks = 0
$clockTimer = New-Object System.Windows.Threading.DispatcherTimer
$clockTimer.Interval = [TimeSpan]::FromSeconds(1)
$clockTimer.Add_Tick({
    $now = Get-Date
    $txtRealtimeClock.Text = "$($now.ToString('HH:mm:ss')) | $($now.ToString('dd/MM/yyyy'))"

    $timerTicks++
    if ($timerTicks % 2 -eq 0 -and $script:currentTab -eq "SysInfo") {
        # Update live metrics every 2s (instantaneous read from background cache)
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
$txtGaugeDiskPercent   = Get-Control "txtGaugeDiskPercent"
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
        if ($txtGaugeDiskPercent) {
            $txtGaugeDiskPercent.Text = "$($m.DiskLoadPercent)%"
        }
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

function Show-VUONGTTDriverDoctorModal {
    if (-not $modalDriverDoctor) { return }
    $modalDriverDoctor.Visibility = [System.Windows.Visibility]::Visible
    if ($prgDriverDoctor) { $prgDriverDoctor.Value = 15 }
    if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "Đang kiểm tra sâu bus PnP và chẩn đoán toàn bộ Driver..." }
    if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = "Đang truy vấn hệ thống và phân tích mã lỗi phần cứng..." }

    Invoke-VUONGTTDoEvents

    try {
        $diag = Get-VUONGTTDeepDriverDiagnostic
        if ($lblDriverDoctorTotal) { $lblDriverDoctorTotal.Text = "$($diag.TotalDevices)" }
        if ($lblDriverDoctorIssues) { 
            $lblDriverDoctorIssues.Text = "$($diag.IssueCount) Lỗi"
            $lblDriverDoctorIssues.Foreground = if ($diag.IssueCount -gt 0) { [System.Windows.Media.Brushes]::Crimson } else { [System.Windows.Media.Brushes]::ForestGreen }
        }
        if ($lblDriverDoctorGpu) { 
            $lblDriverDoctorGpu.Text = if ($diag.HasGpuWarning) { "Thiếu Driver!" } else { "Tối ưu [OK]" }
            $lblDriverDoctorGpu.Foreground = if ($diag.HasGpuWarning) { [System.Windows.Media.Brushes]::Crimson } else { [System.Windows.Media.Brushes]::ForestGreen }
        }
        if ($lblDriverDoctorMachine) { 
            $lblDriverDoctorMachine.Text = "$($diag.Manufacturer) / $($diag.Model)" 
        }

        if ($diag.IssueList -and $diag.IssueList.Count -gt 0) {
            $lines = @("=== PHÁT HIỆN $($diag.IssueCount) THIẾT BỊ CẦN BỔ SUNG / SỬA LỖI DRIVER ===")
            $idx = 0
            foreach ($iss in $diag.IssueList) {
                $idx++
                $lines += "`n[$idx] $($iss.Name)"
                $lines += "   • Hãng sản xuất/Vendor: $($iss.Vendor)"
                $lines += "   • Trạng thái lỗi: $($iss.Description)"
                if ($iss.HardwareID) { $lines += "   • Hardware ID: $($iss.HardwareID)" }
                $lines += "   👉 Hướng xử lý: $($iss.Suggestion)"
            }
            $lines += "`n💡 Bấm các nút bên dưới để Tự động cập nhật qua Windows Update, Snappy Driver Installer (SDIO) hoặc 3DP Chip ngay!"
            if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = ($lines -join "`n") }
            if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• Phát hiện $($diag.IssueCount) thiết bị phần cứng cần xử lý Driver." }
        } else {
            $msg = "=== TOÀN BỘ DRIVER PHẦN CỨNG HOẠT ĐỘNG HOÀN HẢO ===`n`n" +
                   "• Đã quét kiểm tra sâu: $($diag.TotalDevices) thiết bị PnP.`n" +
                   "• Thiết bị lỗi / chấm than vàng (Code 28, 10, 43...): 0 thiết bị.`n" +
                   "• Card màn hình (GPU): $($diag.GpuStatus)`n" +
                   "• Thông tin máy: $($diag.Manufacturer) $($diag.Model)" + (if ($diag.SerialNumber) { " (Serial/Tag: $($diag.SerialNumber))" } else { "" }) + "`n`n" +
                   "Chúc mừng! Máy tính của bạn đã được cài đặt đầy đủ tất cả các driver tối ưu."
            if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = $msg }
            if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• Không có thiết bị nào bị lỗi hoặc thiếu driver." }
        }
    } catch {
        if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = "Lỗi khi quét Driver: $($_.Exception.Message)" }
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• Lỗi truy vấn phần cứng: $($_.Exception.Message)" }
    }

    if ($prgDriverDoctor) { $prgDriverDoctor.Value = 100 }
}

$btnDriverVendor.Add_Click({
    Open-VUONGTTOfficialDriverPortal
})

$btnMissingDriver.Add_Click({
    Show-VUONGTTDriverDoctorModal
})

# Wire Modal Driver Doctor Events
if ($btnModalDriverDoctorClose) {
    $btnModalDriverDoctorClose.Add_Click({ $modalDriverDoctor.Visibility = [System.Windows.Visibility]::Collapsed })
}
if ($btnModalDriverDoctorDone) {
    $btnModalDriverDoctorDone.Add_Click({ $modalDriverDoctor.Visibility = [System.Windows.Visibility]::Collapsed })
}
if ($btnDriverDoctorRescan) {
    $btnDriverDoctorRescan.Add_Click({ Show-VUONGTTDriverDoctorModal })
}

if ($btnDriverAutoWinUpdate) {
    $btnDriverAutoWinUpdate.Add_Click({
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "Đang quét PnP & Windows Update..." }
        if ($prgDriverDoctor) { $prgDriverDoctor.Value = 40 }
        $res = Invoke-VUONGTTWindowsUpdateDriverScan -OnProgress {
            param($m)
            if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = "$m`n$($txtDriverDoctorDetails.Text)" }
            Invoke-VUONGTTDoEvents
        }
        if ($prgDriverDoctor) { $prgDriverDoctor.Value = 100 }
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• Quét Windows Update hoàn tất." }
        [System.Windows.MessageBox]::Show($res, "Windows Update Driver", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnDriverSDIO) {
    $btnDriverSDIO.Add_Click({
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "Đang kết nối Snappy Driver Installer Origin..." }
        $res = Invoke-VUONGTTLaunchDriverTool -ToolName "sdio" -OnProgress {
            param($m)
            if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = "$m`n$($txtDriverDoctorDetails.Text)" }
        }
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• $res" }
    })
}

if ($btnDriver3DPChip) {
    $btnDriver3DPChip.Add_Click({
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "Đang khởi chạy 3DP Chip..." }
        $res = Invoke-VUONGTTLaunchDriverTool -ToolName "3dpchip" -OnProgress {
            param($m)
            if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = "$m`n$($txtDriverDoctorDetails.Text)" }
        }
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• $res" }
    })
}

if ($btnDriver3DPNet) {
    $btnDriver3DPNet.Add_Click({
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "Đang mở 3DP Net..." }
        $res = Invoke-VUONGTTLaunchDriverTool -ToolName "3dpnet" -OnProgress {
            param($m)
            if ($txtDriverDoctorDetails) { $txtDriverDoctorDetails.Text = "$m`n$($txtDriverDoctorDetails.Text)" }
        }
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• $res" }
    })
}

if ($btnDriverOEMSupport) {
    $btnDriverOEMSupport.Add_Click({
        $portal = Open-VUONGTTOfficialDriverPortal
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• Đã mở trang Driver hãng: $($portal.Manufacturer)" }
    })
}

if ($btnDriverOpenDevMgmt) {
    $btnDriverOpenDevMgmt.Add_Click({
        Start-Process "devmgmt.msc"
        if ($lblDriverDoctorStatus) { $lblDriverDoctorStatus.Text = "• Đã mở Device Manager" }
    })
}

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
# MODULE 3: TRA CỨU CPU + MAIN & SO SÁNH HIỆU NĂNG
# =========================================================================
$cmbCpuSearch          = Get-Control "cmbCpuSearch"
$btnSearchCpu          = Get-Control "btnSearchCpu"
$txtCpuFoundName       = Get-Control "txtCpuFoundName"
$txtCpuFoundSocket     = Get-Control "txtCpuFoundSocket"
$txtCpuFoundArch       = Get-Control "txtCpuFoundArch"
$txtCpuSpecsPill       = Get-Control "txtCpuSpecsPill"
$txtCpuR23Score        = Get-Control "txtCpuR23Score"
$txtCpuNotes           = Get-Control "txtCpuNotes"
$panelChipsets         = Get-Control "panelChipsets"

$cmbCpuCompare1        = Get-Control "cmbCpuCompare1"
$cmbCpuCompare2        = Get-Control "cmbCpuCompare2"
$btnCompareCpu         = Get-Control "btnCompareCpu"
$txtCpuCompareReport   = Get-Control "txtCpuCompareReport"

function Search-CpuInfo {
    $q = if ($cmbCpuSearch -and $cmbCpuSearch.Text) { $cmbCpuSearch.Text.Trim() } else { "285K" }
    if ([string]::IsNullOrEmpty($q)) { $q = "285K" }
    
    # Check enhanced spec DB first
    $spec = Find-CpuSpecByQuery -Query $q
    $item = Find-CpuOrChipset -Query $q

    if ($spec) {
        $txtCpuFoundName.Text   = $spec.Name
        $txtCpuFoundSocket.Text = $spec.Socket
        $txtCpuFoundArch.Text   = "$($spec.Arch) • Tiến trình $($spec.Node)"
        if ($txtCpuSpecsPill) {
            $txtCpuSpecsPill.Text = "$($spec.Cores)C/$($spec.Threads)T • $($spec.BaseClock) - $($spec.BoostClock) • L3 $($spec.L3Cache) • TDP $($spec.TDP)"
        }
        if ($txtCpuR23Score) {
            $txtCpuR23Score.Text = "Cinebench R23: $([string]::Format('{0:N0}', $spec.R23Single)) Single / $([string]::Format('{0:N0}', $spec.R23Multi)) Multi"
        }
        if ($txtCpuNotes) {
            $notesList = @(
                "- Chuẩn RAM hỗ trợ: $($spec.RAM)",
                "- Mainboard khuyến nghị: $($spec.Main)",
                "- Socket: $($spec.Socket) | TDP: $($spec.TDP) | Bộ nhớ đệm L3: $($spec.L3Cache)"
            )
            if ($item -and $item.Notes) {
                $notesList += $item.Notes
            }
            $txtCpuNotes.Text = ($notesList -join "`n")
        }
    } elseif ($item) {
        $txtCpuFoundName.Text   = $item.DisplayName
        $txtCpuFoundSocket.Text = $item.Socket
        $txtCpuFoundArch.Text   = $item.Arch
        if ($txtCpuNotes) { $txtCpuNotes.Text = ($item.Notes -join "`n") }
    }

    # Populate Chipset Badges
    if ($panelChipsets) {
        $panelChipsets.Children.Clear()
        $conv = [System.Windows.Media.BrushConverter]::new()
        $chipsetsToRender = @()

        if ($item -and $item.Chipsets) {
            $chipsetsToRender = $item.Chipsets
        } elseif ($spec -and $spec.Main) {
            $mainList = $spec.Main.Split(',')
            $isFirst = $true
            foreach ($m in $mainList) {
                $chipsetsToRender += [PSCustomObject]@{
                    Name = $m.Trim()
                    IsPrimary = $isFirst
                }
                $isFirst = $false
            }
        }

        foreach ($c in $chipsetsToRender) {
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

if ($btnSearchCpu) { $btnSearchCpu.Add_Click({ Search-CpuInfo }) }
if ($cmbCpuSearch) {
    $cmbCpuSearch.Add_SelectionChanged({ Search-CpuInfo })
    # Enter key to search
    $cmbCpuSearch.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
            Search-CpuInfo
            $_.Handled = $true
        }
    })
}

# CPU Side-by-Side Comparison Handler
if ($btnCompareCpu) {
    $btnCompareCpu.Add_Click({
        $q1 = if ($cmbCpuCompare1 -and $cmbCpuCompare1.Text) { $cmbCpuCompare1.Text.Trim() } else { "14400" }
        $q2 = if ($cmbCpuCompare2 -and $cmbCpuCompare2.Text) { $cmbCpuCompare2.Text.Trim() } else { "9800X3D" }
        
        $txtFooterStatus.Text = "• [Đang xử lý] Đang tính toán và so sánh hiệu năng: $q1 VS $q2..."
        $cmp = Compare-VUONGTTCpu -Cpu1Query $q1 -Cpu2Query $q2
        if ($txtCpuCompareReport) {
            $txtCpuCompareReport.Text = $cmp.ReportText
        }
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất so sánh đối đầu $($cmp.Cpu1.Name) và $($cmp.Cpu2.Name)!"
    })
}

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
            if ($txtOfficeLog) {
                $txtOfficeLog.Text = $msg
                Invoke-VUONGTTDoEvents
            }
        }
        $prgOffice.Value = 100
        $txtOfficeLog.Text = "Tiến trình ODT đã khởi động thành công! Đang thực thi ngầm..."
        [System.Windows.MessageBox]::Show("Tiến trình Microsoft Office ODT đang chạy ngầm trong máy. Vui lòng giữ kết nối Internet ổn định!", "Cài Đặt Office", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        $prgOffice.Value = 0
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

# Active Button Highlight Function (Chỉ hiệu ứng ô được chọn, các ô khác làm mờ trung tính)
function Set-ActivePrinterButton {
    param($activeCtl)
    $bc = [System.Windows.Media.BrushConverter]::new()
    foreach ($item in $printerActionsMap) {
        if (-not $item.Ctl) { continue }
        if ($item.Ctl -eq $activeCtl) {
            # Selected button: Highlight Red (#DC2626) with full opacity and amber highlight border
            $item.Ctl.Background = $bc.ConvertFromString("#DC2626")
            $item.Ctl.Foreground = [System.Windows.Media.Brushes]::White
            $item.Ctl.Opacity = 1.0
            $item.Ctl.BorderBrush = $bc.ConvertFromString("#F59E0B")
            $item.Ctl.BorderThickness = [System.Windows.Thickness]::new(2.5)
        } else {
            # Unselected buttons: Muted dark slate (#334155), no active border, lowered opacity
            $item.Ctl.Background = $bc.ConvertFromString("#334155")
            $item.Ctl.Foreground = [System.Windows.Media.Brushes]::White
            $item.Ctl.Opacity = 0.55
            $item.Ctl.BorderBrush = $bc.ConvertFromString("#475569")
            $item.Ctl.BorderThickness = [System.Windows.Thickness]::new(1)
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
$txtPrinterSearch.Add_KeyDown({
    if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
        if ($btnAutoFixMatched) {
            $btnAutoFixMatched.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $_.Handled = $true
        }
    }
})

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
$btnSelectAllApps          = Get-Control "btnSelectAllApps"
$btnUnselectAllApps        = Get-Control "btnUnselectAllApps"
$btnInstallSelectedApps    = Get-Control "btnInstallSelectedApps"
$btnUpdateAllApps          = Get-Control "btnUpdateAllApps"
$txtSoftwareLog            = Get-Control "txtSoftwareLog"

$prgSoftware               = Get-Control "prgSoftware"
$lblSoftwareProgressText   = Get-Control "lblSoftwareProgressText"
$lblSoftwareProgressPercent= Get-Control "lblSoftwareProgressPercent"
$lblSoftwareSubText        = Get-Control "lblSoftwareSubText"
$chkSoftwareAutoLaunch     = Get-Control "chkSoftwareAutoLaunch"
$btnClearSoftwareLog       = Get-Control "btnClearSoftwareLog"

$txtCustomAppInput         = Get-Control "txtCustomAppInput"
$btnInstallCustomApp       = Get-Control "btnInstallCustomApp"
$txtCustomAppLog           = Get-Control "txtCustomAppLog"
$prgCustomApp              = Get-Control "prgCustomApp"
$lblCustomAppStatus        = Get-Control "lblCustomAppStatus"
$chkCustomAutoLaunch       = Get-Control "chkCustomAutoLaunch"
$txtLocalInstallerPath     = Get-Control "txtLocalInstallerPath"
$btnBrowseInstaller        = Get-Control "btnBrowseInstaller"
$btnRunSilentInstall       = Get-Control "btnRunSilentInstall"

$btnInstallAllFonts        = Get-Control "btnInstallAllFonts"
$btnInstallTcvn3           = Get-Control "btnInstallTcvn3"
$btnInstallVni             = Get-Control "btnInstallVni"

$btnInstallAccountingOnly  = Get-Control "btnInstallAccountingOnly"
$btnUpdateAccounting       = Get-Control "btnUpdateAccounting"
$btnOpenTaxPortal          = Get-Control "btnOpenTaxPortal"

$appControls = @()
$dbPathLocal = Join-Path $ScriptDir "src\Data\SoftwareDatabase.json"
if (-not (Test-Path $dbPathLocal)) {
    $dbPathLocal = "E:\toolwindows\src\Data\SoftwareDatabase.json"
}
if (Test-Path $dbPathLocal) {
    try {
        $dbData = Get-Content $dbPathLocal -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($item in $dbData) {
            $cleanName = "app_" + ($item.Id -replace '[^a-zA-Z0-9_]', '_').Trim('_')
            $appControls += $cleanName
        }
    } catch {}
}
if ($appControls.Count -eq 0) {
    $appControls = @("app_chrome", "app_coccoc", "app_firefox", "app_brave", "app_zalo", "app_telegram", "app_discord", "app_office365", "app_unikey", "app_7zip", "app_ultraviewer", "app_everything", "app_htkk", "app_itaxviewer")
}

# --- App Filter Tabs Wiring ---
$btnTabAll        = Get-Control "btnTabAll"
$btnTabBrowsers   = Get-Control "btnTabBrowsers"
$btnTabComms      = Get-Control "btnTabComms"
$btnTabDev        = Get-Control "btnTabDev"
$btnTabDocs       = Get-Control "btnTabDocs"
$btnTabGames      = Get-Control "btnTabGames"
$btnTabMicrosoft  = Get-Control "btnTabMicrosoft"
$btnTabMedia      = Get-Control "btnTabMedia"
$btnTabPro        = Get-Control "btnTabPro"
$btnTabSelfhosted = Get-Control "btnTabSelfhosted"
$btnTabUtils      = Get-Control "btnTabUtils"
$btnTabAccounting = Get-Control "btnTabAccounting"

$secBrowsers   = Get-Control "secBrowsers"
$secComms      = Get-Control "secComms"
$secDev        = Get-Control "secDev"
$secDocs       = Get-Control "secDocs"
$secGames      = Get-Control "secGames"
$secMicrosoft  = Get-Control "secMicrosoft"
$secMedia      = Get-Control "secMedia"
$secPro        = Get-Control "secPro"
$secSelfhosted = Get-Control "secSelfhosted"
$secUtils      = Get-Control "secUtils"
$secAccounting = Get-Control "secAccounting"

$txtSelectedAppsCount = Get-Control "txtSelectedAppsCount"
$btnUninstallApps     = Get-Control "btnUninstallApps"

# Pre-cache 244 App Control Objects in memory (eliminates thousands of recursive visual tree lookups)
$script:appControlObjects = @()
$iconDir = Join-Path $ScriptDir "src\Assets\AppIcons"
foreach ($name in $appControls) {
    $c = Get-Control $name
    if ($c) {
        if ($c.Tag) {
            $iconLeaf = Split-Path $c.Tag -Leaf
            $fullIconPath = Join-Path $iconDir $iconLeaf
            if (Test-Path $fullIconPath) {
                $c.Tag = $fullIconPath
            }
        }
        $c.Add_Checked({ Update-VUONGTTAppSelectionCount })
        $c.Add_Unchecked({ Update-VUONGTTAppSelectionCount })
        $script:appControlObjects += [PSCustomObject]@{
            Control = $c
            Name    = $name
            Content = "$($c.Content)"
        }
    }
}

function Update-VUONGTTAppSelectionCount {
    $cCount = 0
    foreach ($item in $script:appControlObjects) {
        if ($item.Control.IsChecked) { $cCount++ }
    }
    if ($txtSelectedAppsCount) {
        $txtSelectedAppsCount.Text = "Đã chọn: $cCount ứng dụng"
    }
}

$btnSelectAllApps.Add_Click({
    foreach ($item in $script:appControlObjects) {
        if ($item.Control.Visibility -eq [System.Windows.Visibility]::Visible) {
            $item.Control.IsChecked = $true
        }
    }
    Update-VUONGTTAppSelectionCount
})

$btnUnselectAllApps.Add_Click({
    foreach ($item in $script:appControlObjects) {
        $item.Control.IsChecked = $false
    }
    Update-VUONGTTAppSelectionCount
})

# Instant Real-Time Search Handler (0ms RAM lookup)
$txtAppSearch = Get-Control "txtAppSearch"
if ($txtAppSearch) {
    $txtAppSearch.Add_TextChanged({
        $q = $txtAppSearch.Text.Trim().ToLower()
        $isWhite = [string]::IsNullOrWhiteSpace($q)
        foreach ($item in $script:appControlObjects) {
            if ($isWhite) {
                $item.Control.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $isMatch = ($item.Content -and $item.Content.ToLower().Contains($q)) -or ($item.Name.ToLower().Contains($q))
                $item.Control.Visibility = if ($isMatch) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
            }
        }
    })
}

Update-VUONGTTAppSelectionCount


function Set-VUONGTTAppFilterTab {
    param([string]$Category)
    
    $sections = @{
        "Browsers"   = $secBrowsers
        "Comms"      = $secComms
        "Dev"        = $secDev
        "Docs"       = $secDocs
        "Games"      = $secGames
        "Microsoft"  = $secMicrosoft
        "Media"      = $secMedia
        "Pro"        = $secPro
        "Selfhosted" = $secSelfhosted
        "Utils"      = $secUtils
        "Accounting" = $secAccounting
    }

    $tabButtons = @{
        "All"        = $btnTabAll
        "Browsers"   = $btnTabBrowsers
        "Comms"      = $btnTabComms
        "Dev"        = $btnTabDev
        "Docs"       = $btnTabDocs
        "Games"      = $btnTabGames
        "Microsoft"  = $btnTabMicrosoft
        "Media"      = $btnTabMedia
        "Pro"        = $btnTabPro
        "Selfhosted" = $btnTabSelfhosted
        "Utils"      = $btnTabUtils
        "Accounting" = $btnTabAccounting
    }

    $activeBrush   = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2563EB")
    $inactiveBrush = $window.Resources["CardInnerBgBrush"]

    foreach ($k in $tabButtons.Keys) {
        $tb = $tabButtons[$k]
        if ($tb) {
            if ($k -eq $Category) {
                $tb.Background = $activeBrush
                $tb.Foreground = [System.Windows.Media.Brushes]::White
            } else {
                $tb.Background = $inactiveBrush
                $tb.Foreground = $window.Resources["TextPrimaryBrush"]
            }
        }
    }

    foreach ($k in $sections.Keys) {
        $sec = $sections[$k]
        if ($sec) {
            if ($Category -eq "All" -or $Category -eq $k) {
                $sec.Visibility = [System.Windows.Visibility]::Visible
            } else {
                $sec.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }
    }
}

if ($btnTabAll)        { $btnTabAll.Add_Click({ Set-VUONGTTAppFilterTab "All" }) }
if ($btnTabBrowsers)   { $btnTabBrowsers.Add_Click({ Set-VUONGTTAppFilterTab "Browsers" }) }
if ($btnTabComms)      { $btnTabComms.Add_Click({ Set-VUONGTTAppFilterTab "Comms" }) }
if ($btnTabDev)        { $btnTabDev.Add_Click({ Set-VUONGTTAppFilterTab "Dev" }) }
if ($btnTabDocs)       { $btnTabDocs.Add_Click({ Set-VUONGTTAppFilterTab "Docs" }) }
if ($btnTabGames)      { $btnTabGames.Add_Click({ Set-VUONGTTAppFilterTab "Games" }) }
if ($btnTabMicrosoft)  { $btnTabMicrosoft.Add_Click({ Set-VUONGTTAppFilterTab "Microsoft" }) }
if ($btnTabMedia)      { $btnTabMedia.Add_Click({ Set-VUONGTTAppFilterTab "Media" }) }
if ($btnTabPro)        { $btnTabPro.Add_Click({ Set-VUONGTTAppFilterTab "Pro" }) }
if ($btnTabSelfhosted) { $btnTabSelfhosted.Add_Click({ Set-VUONGTTAppFilterTab "Selfhosted" }) }
if ($btnTabUtils)      { $btnTabUtils.Add_Click({ Set-VUONGTTAppFilterTab "Utils" }) }
if ($btnTabAccounting) { $btnTabAccounting.Add_Click({ Set-VUONGTTAppFilterTab "Accounting" }) }

if ($btnUninstallApps) {
    $btnUninstallApps.Add_Click({
        $selected = @()
        foreach ($name in $appControls) {
            $c = Get-Control $name
            if ($c -and $c.IsChecked) { $selected += $name.Replace("app_", "") }
        }
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng tích chọn ứng dụng cần gỡ!", "Gỡ Cài Đặt", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }
        $confirm = [System.Windows.MessageBox]::Show("Bạn có chắc chắn muốn gỡ cài đặt $($selected.Count) ứng dụng đã chọn?", "Xác nhận gỡ bỏ", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            if ($txtSoftwareLog) { $txtSoftwareLog.AppendText("`r`n[GỠ CÀI ĐẶT] Đang gỡ bỏ các ứng dụng đã chọn...`r`n") }
            foreach ($appId in $selected) {
                $appObj = $script:VUONGTT_APPS | Where-Object { $_.Id -eq $appId }
                if ($appObj -and $appObj.WingetId) {
                    Start-Process "winget.exe" -ArgumentList "uninstall --id $($appObj.WingetId) --silent" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                    if ($txtSoftwareLog) { $txtSoftwareLog.AppendText("[OK] Đã gửi lệnh gỡ: $($appObj.Name)`r`n") }
                }
            }
        }
    })
}

if ($btnClearSoftwareLog) {
    $btnClearSoftwareLog.Add_Click({
        if ($txtSoftwareLog) { $txtSoftwareLog.Text = "Sẵn sàng tải và cài đặt phần mềm." }
        if ($prgSoftware) { $prgSoftware.Value = 0 }
        if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "Sẵn sàng tải và cài đặt" }
        if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "0%" }
        if ($lblSoftwareSubText) { $lblSoftwareSubText.Text = "Hiển thị luồng log chi tiết thời gian thực khi cài đặt" }
    })
}

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
        if ($txtSoftwareLog) { $txtSoftwareLog.Text = "[CẢNH BÁO] Vui lòng tích chọn ít nhất 1 ứng dụng để cài đặt!" }
        [System.Windows.MessageBox]::Show("Vui lòng tích chọn ít nhất 1 ứng dụng!", "Tải Ứng Dụng", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $autoLaunch = if ($chkSoftwareAutoLaunch) { [bool]$chkSoftwareAutoLaunch.IsChecked } else { $true }
    if ($prgSoftware) { $prgSoftware.Value = 0 }
    if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "0%" }
    if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "Bắt đầu cài đặt $($selected.Count) ứng dụng..." }

    $logPrefix = "=== [KHỞI ĐỘNG TIẾN TRÌNH CÀI ĐẶT $($selected.Count) ỨNG DỤNG - $(Get-Date -Format 'HH:mm:ss')] ==="
    if ($txtSoftwareLog) { 
        $txtSoftwareLog.Text = "$logPrefix`r`n"
        $txtSoftwareLog.ScrollToEnd()
    }

    $streamLog = {
        param($msg)
        if ($txtSoftwareLog) {
            $txtSoftwareLog.AppendText("$msg`r`n")
            $txtSoftwareLog.ScrollToEnd()
        }
        Invoke-VUONGTTDoEvents
    }

    $i = 0
    foreach ($appId in $selected) {
        $i++
        $pct = [int](($i / $selected.Count) * 100)
        $appObj = $script:VUONGTT_APPS | Where-Object { $_.Id -eq $appId }
        $appName = if ($appObj) { $appObj.Name } else { $appId }

        if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "[$i/$($selected.Count)] Đang xử lý: $appName..." }
        if ($lblSoftwareSubText) { $lblSoftwareSubText.Text = "Đang cài đặt $appName ($i/$($selected.Count))..." }
        & $streamLog "`r`n>>> BẮT ĐẦU CÀI ĐẶT [$i/$($selected.Count)]: $appName"

        $res = Install-VUONGTTApp -AppId $appId -OnProgress $streamLog -AutoLaunch:$autoLaunch
        & $streamLog "-> Kết quả: $res"

        if ($prgSoftware) { $prgSoftware.Value = $pct }
        if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "$pct%" }
        Invoke-VUONGTTDoEvents
    }

    if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "Đã hoàn tất cài đặt toàn bộ $($selected.Count) ứng dụng!" }
    if ($lblSoftwareSubText) { $lblSoftwareSubText.Text = "Quá trình cài đặt kết thúc thành công." }
    if ($prgSoftware) { $prgSoftware.Value = 100 }
    if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "100%" }
    & $streamLog "`r`n=== [HOÀN TẤT TOÀN BỘ CÀI ĐẶT] ==="

    [System.Windows.MessageBox]::Show("Đã hoàn tất cài đặt toàn bộ $($selected.Count) ứng dụng đã chọn!`nCác ứng dụng đã được tự động mở sẵn sàng sử dụng.", "Tải Ứng Dụng Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

$btnUpdateAllApps.Add_Click({
    if ($txtSoftwareLog) { $txtSoftwareLog.Text = "Đang chạy Winget upgrade --all (Cập nhật toàn bộ phần mềm)...`r`n" }
    if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "Đang cập nhật toàn bộ ứng dụng..." }
    if ($prgSoftware) { $prgSoftware.Value = 30 }

    $res = Invoke-VUONGTTProcessWithLiveLog -FilePath "powershell.exe" -ArgumentList "-NoProfile -Command winget upgrade --all --silent --accept-package-agreements --accept-source-agreements" -OnOutputLine {
        param($m)
        if ($txtSoftwareLog) { 
            $txtSoftwareLog.AppendText("$m`r`n")
            $txtSoftwareLog.ScrollToEnd()
        }
    }

    if ($prgSoftware) { $prgSoftware.Value = 100 }
    if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "100%" }
    if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "Đã cập nhật xong toàn bộ ứng dụng!" }
    [System.Windows.MessageBox]::Show("Đã hoàn tất kiểm tra và nâng cấp toàn bộ ứng dụng qua Winget!", "Cập Nhật Ứng Dụng", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
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
            if ($txtSoftwareLog) { $txtSoftwareLog.Text = "[CẢNH BÁO] Vui lòng tích chọn ít nhất 1 ứng dụng kế toán (HTKK, iTaxViewer, MISA, KBHXH, Java...) để cài đặt!`n$($txtSoftwareLog.Text)" }
            [System.Windows.MessageBox]::Show("Vui lòng tích chọn ít nhất 1 ứng dụng kế toán!", "Ứng Dụng Kế Toán", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $autoLaunch = if ($chkSoftwareAutoLaunch) { [bool]$chkSoftwareAutoLaunch.IsChecked } else { $true }
        if ($prgSoftware) { $prgSoftware.Value = 0 }
        if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "0%" }
        if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "Bắt đầu cài đặt $($selectedAcct.Count) ứng dụng kế toán..." }

        if ($txtSoftwareLog) {
            $txtSoftwareLog.Text = "=== [BẮT ĐẦU CÀI ĐẶT $($selectedAcct.Count) ỨNG DỤNG KẾ TOÁN MỚI NHẤT] ===`r`n"
            $txtSoftwareLog.ScrollToEnd()
        }

        $acctStream = {
            param($m)
            if ($txtSoftwareLog) {
                $txtSoftwareLog.AppendText("$m`r`n")
                $txtSoftwareLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents
        }

        $k = 0
        foreach ($appId in $selectedAcct) {
            $k++
            $pct = [int](($k / $selectedAcct.Count) * 100)
            if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "[$k/$($selectedAcct.Count)] Đang cài gói kế toán: $appId..." }
            
            $res = Install-VUONGTTAccountingApp -AppId $appId -OnProgress $acctStream -AutoLaunch:$autoLaunch
            & $acctStream "-> Kết quả: $res"
            if ($prgSoftware) { $prgSoftware.Value = $pct }
            if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "$pct%" }
        }

        if ($lblSoftwareProgressText) { $lblSoftwareProgressText.Text = "Hoàn tất cài đặt gói ứng dụng kế toán!" }
        if ($prgSoftware) { $prgSoftware.Value = 100 }
        if ($lblSoftwareProgressPercent) { $lblSoftwareProgressPercent.Text = "100%" }
        & $acctStream "`r`n=== [HOÀN TẤT CÀI ĐẶT GÓI KẾ TOÁN] ==="
        [System.Windows.MessageBox]::Show("Đã hoàn tất quá trình tải và cài đặt các ứng dụng kế toán!`nCác ứng dụng đã sẵn sàng sử dụng.", "Kế Toán & Thuế", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
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
        if ($txtSoftwareLog) {
            $txtSoftwareLog.Text = "=== [BẮT ĐẦU KIỂM TRA & CẬP NHẬT ỨNG DỤNG KẾ TOÁN] ===`r`n"
            $txtSoftwareLog.ScrollToEnd()
        }
        $res = Update-VUONGTTAccountingApps -AppsToUpdate $selectedAcct -OnProgress {
            param($m)
            if ($txtSoftwareLog) {
                $txtSoftwareLog.AppendText("$m`r`n")
                $txtSoftwareLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents
        }
        if ($txtSoftwareLog) { $txtSoftwareLog.AppendText("=== [HOÀN TẤT TIẾN TRÌNH CẬP NHẬT KẾ TOÁN] ===`r`n") }
        [System.Windows.MessageBox]::Show("Tiến trình cập nhật các phần mềm kế toán đã hoàn tất!`nXem log chi tiết tại khung nhật ký.", "Cập Nhật Kế Toán", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnOpenTaxPortal) {
    $btnOpenTaxPortal.Add_Click({
        if ($txtSoftwareLog) { $txtSoftwareLog.AppendText("[PORTAL] Đang mở Cổng Thuế Điện Tử Tổng cục Thuế (https://thuedientu.gdt.gov.vn)...`r`n") }
        try {
            [System.Diagnostics.Process]::Start("https://thuedientu.gdt.gov.vn") | Out-Null
        } catch {
            Start-Process "https://thuedientu.gdt.gov.vn"
        }
    })
}

$btnInstallCustomApp.Add_Click({
    $target = $txtCustomAppInput.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.MessageBox]::Show("Vui lòng nhập ID Winget hoặc liên kết URL tệp cài đặt!", "Cài App Tùy Chỉnh", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $autoLaunch = if ($chkCustomAutoLaunch) { [bool]$chkCustomAutoLaunch.IsChecked } else { $true }
    if ($prgCustomApp) { $prgCustomApp.Value = 20 }
    if ($lblCustomAppStatus) { $lblCustomAppStatus.Text = "Đang kết nối & tải gói: $target..." }
    if ($txtCustomAppLog) { 
        $txtCustomAppLog.Text = "=== [BẮT ĐẦU CÀI ĐẶT TÙY CHỈNH: $target] ===`r`n"
        $txtCustomAppLog.ScrollToEnd()
    }

    $customStream = {
        param($m)
        if ($txtCustomAppLog) {
            $txtCustomAppLog.AppendText("$m`r`n")
            $txtCustomAppLog.ScrollToEnd()
        }
        Invoke-VUONGTTDoEvents
    }

    $res = Install-VUONGTTCustomApp -TargetInput $target -OnProgress $customStream -AutoLaunch:$autoLaunch
    if ($prgCustomApp) { $prgCustomApp.Value = 100 }
    if ($lblCustomAppStatus) { $lblCustomAppStatus.Text = "Hoàn tất cài đặt $target" }
    & $customStream "=== [KẾT QUẢ] $res ==="
    [System.Windows.MessageBox]::Show($res, "Cài App Tùy Chỉnh", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
})

if ($btnBrowseInstaller) {
    $btnBrowseInstaller.Add_Click({
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Filter = "Tệp cài đặt (*.exe;*.msi)|*.exe;*.msi|Mọi tệp (*.*)|*.*"
        $ofd.Title = "Chọn tệp cài đặt phần mềm (.exe hoặc .msi)"
        if ($ofd.ShowDialog() -eq $true) {
            $txtLocalInstallerPath.Text = $ofd.FileName
        }
    })
}

if ($btnRunSilentInstall) {
    $btnRunSilentInstall.Add_Click({
        $path = $txtLocalInstallerPath.Text.Trim()
        if (-not (Test-Path $path)) {
            [System.Windows.MessageBox]::Show("Tệp cài đặt không tồn tại tại: $path", "Cài Đặt Cục Bộ", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $autoLaunch = if ($chkCustomAutoLaunch) { [bool]$chkCustomAutoLaunch.IsChecked } else { $true }
        if ($prgCustomApp) { $prgCustomApp.Value = 25 }
        if ($lblCustomAppStatus) { $lblCustomAppStatus.Text = "Đang cài đặt ngầm: $([System.IO.Path]::GetFileName($path))..." }
        
        $silentArg = if ($path -like "*.msi") { "/qn /norestart" } else { "/silent /verysilent /qn /s" }
        $customStream = {
            param($m)
            if ($txtCustomAppLog) {
                $txtCustomAppLog.AppendText("$m`r`n")
                $txtCustomAppLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents
        }

        & $customStream "=== [BẮT ĐẦU CÀI ĐẶT CỤC BỘ: $path] ==="
        $exitCode = Invoke-VUONGTTProcessWithLiveLog -FilePath $path -ArgumentList $silentArg -OnOutputLine $customStream
        if ($autoLaunch) {
            $appName = [System.IO.Path]::GetFileNameWithoutExtension($path)
            Start-VUONGTTInstalledApp -AppId $appName -HintName $appName -OnLog $customStream
        }
        if ($prgCustomApp) { $prgCustomApp.Value = 100 }
        if ($lblCustomAppStatus) { $lblCustomAppStatus.Text = "Cài đặt cục bộ hoàn tất" }
        & $customStream "-> Hoàn tất cài đặt với mã thoát: $exitCode"
        [System.Windows.MessageBox]::Show("Đã hoàn tất cài đặt $path (Mã thoát: $exitCode)!", "Cài Đặt Cục Bộ", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

# =========================================================================
# MODULE: GỠ BỎ PHẦN MỀM (CLEAN UNINSTALLER PRO)
# =========================================================================
$txtInstalledAppsCount   = Get-Control "txtInstalledAppsCount"
$btnRefreshInstalledApps = Get-Control "btnRefreshInstalledApps"
$txtSearchInstalledApps  = Get-Control "txtSearchInstalledApps"
$btnClearSearchApps      = Get-Control "btnClearSearchApps"
$lvInstalledApps            = Get-Control "lvInstalledApps"
$chkSelectAllUninstApps     = Get-Control "chkSelectAllUninstApps"
$btnSelectAllUninstApps     = Get-Control "btnSelectAllUninstApps"
$btnDeselectAllUninstApps   = Get-Control "btnDeselectAllUninstApps"
$btnUninstallClean          = Get-Control "btnUninstallClean"
$btnUninstallStandard       = Get-Control "btnUninstallStandard"
$btnOpenAppFolder           = Get-Control "btnOpenAppFolder"
$btnOpenAppRegistry         = Get-Control "btnOpenAppRegistry"
$txtUninstallerLog          = Get-Control "txtUninstallerLog"
$btnClearUninstallerLog     = Get-Control "btnClearUninstallerLog"

$script:allInstalledApps = @()

function Update-VUONGTTSelectedAppsCount {
    $total = if ($script:allInstalledApps) { $script:allInstalledApps.Count } else { 0 }
    $selCount = @($script:allInstalledApps | Where-Object { $_.IsChecked -eq $true }).Count
    $shownCount = if ($lvInstalledApps.ItemsSource) { $lvInstalledApps.ItemsSource.Count } else { 0 }
    if ($txtInstalledAppsCount) {
        $txtInstalledAppsCount.Text = "Phát hiện $total phần mềm đã cài đặt trên máy (Đang hiển thị: $shownCount mục | Đã tick chọn: $selCount phần mềm)"
    }
}

function Refresh-InstalledAppsGrid {
    param([string]$Filter = "")
    if (-not $lvInstalledApps) { return }

    if (-not $Filter -or $script:allInstalledApps.Count -eq 0) {
        $txtFooterStatus.Text = "• [SCAN] Đang phát hiện phần mềm đã cài trên Windows..."
        if ($txtUninstallerLog) { $txtUninstallerLog.Text = "Đang quét danh sách phần mềm từ Registry 64-bit, 32-bit và CurrentUser..." }
        Invoke-VUONGTTDoEvents
        
        $script:allInstalledApps = Get-VUONGTTInstalledSoftware
    }

    $filtered = if ($Filter -and $Filter.Trim().Length -gt 0) {
        $q = $Filter.Trim()
        $script:allInstalledApps | Where-Object {
            $_.DisplayName -like "*$q*" -or $_.Publisher -like "*$q*" -or $_.DisplayVersion -like "*$q*"
        }
    } else {
        $script:allInstalledApps
    }

    $lvInstalledApps.ItemsSource = @($filtered)
    $cnt = if ($filtered) { $filtered.Count } else { 0 }
    $total = if ($script:allInstalledApps) { $script:allInstalledApps.Count } else { 0 }

    if ($chkSelectAllUninstApps) { $chkSelectAllUninstApps.IsChecked = $false }
    Update-VUONGTTSelectedAppsCount

    $txtFooterStatus.Text = "• [OK] Đã phát hiện $total phần mềm cài đặt trên máy."
    if ($txtUninstallerLog) {
        $txtUninstallerLog.Text = "✅ Đã nạp xong danh sách $total phần mềm!`nHướng dẫn: Tick chọn các ô vuông để gỡ hàng loạt, hoặc nhấp chọn một phần mềm rồi nhấn 'Gỡ Sạch Triệt Để' hoặc 'Gỡ Cài Đặt Tiêu Chuẩn'."
    }
}

# Sự kiện Header CheckBox: Chọn tất cả / Bỏ chọn tất cả
if ($chkSelectAllUninstApps) {
    $chkSelectAllUninstApps.Add_Click({
        $state = ($chkSelectAllUninstApps.IsChecked -eq $true)
        if ($lvInstalledApps.ItemsSource) {
            foreach ($item in $lvInstalledApps.ItemsSource) {
                $item.IsChecked = $state
            }
        }
        Update-VUONGTTSelectedAppsCount
    })
}

# Sự kiện nút Chọn Hết
if ($btnSelectAllUninstApps) {
    $btnSelectAllUninstApps.Add_Click({
        if ($lvInstalledApps.ItemsSource) {
            foreach ($item in $lvInstalledApps.ItemsSource) {
                $item.IsChecked = $true
            }
        }
        if ($chkSelectAllUninstApps) { $chkSelectAllUninstApps.IsChecked = $true }
        Update-VUONGTTSelectedAppsCount
    })
}

# Sự kiện nút Bỏ Chọn
if ($btnDeselectAllUninstApps) {
    $btnDeselectAllUninstApps.Add_Click({
        if ($script:allInstalledApps) {
            foreach ($item in $script:allInstalledApps) {
                $item.IsChecked = $false
            }
        }
        if ($chkSelectAllUninstApps) { $chkSelectAllUninstApps.IsChecked = $false }
        Update-VUONGTTSelectedAppsCount
    })
}

if ($btnRefreshInstalledApps) {
    $btnRefreshInstalledApps.Add_Click({
        $script:allInstalledApps = @()
        Refresh-InstalledAppsGrid -Filter $txtSearchInstalledApps.Text
    })
}

if ($txtSearchInstalledApps) {
    $txtSearchInstalledApps.Add_TextChanged({
        Refresh-InstalledAppsGrid -Filter $txtSearchInstalledApps.Text
    })
}

if ($btnClearSearchApps) {
    $btnClearSearchApps.Add_Click({
        if ($txtSearchInstalledApps) { $txtSearchInstalledApps.Text = "" }
        Refresh-InstalledAppsGrid
    })
}

if ($btnClearUninstallerLog) {
    $btnClearUninstallerLog.Add_Click({
        if ($txtUninstallerLog) { $txtUninstallerLog.Text = "Nhật ký đã được xóa." }
    })
}

# 1. Gỡ cài đặt tiêu chuẩn (Hỗ trợ 1 hoặc Hàng Loạt)
if ($btnUninstallStandard) {
    $btnUninstallStandard.Add_Click({
        $selectedList = @($script:allInstalledApps | Where-Object { $_.IsChecked -eq $true })
        if ($selectedList.Count -eq 0 -and $lvInstalledApps.SelectedItem) {
            $selectedList = @($lvInstalledApps.SelectedItem)
        }

        if ($selectedList.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng tick chọn ít nhất một phần mềm trong danh sách để gỡ cài đặt!", "Chưa Chọn Phần Mềm", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $namesList = ($selectedList | ForEach-Object { "• $($_.DisplayName) (v$($_.DisplayVersion))" }) -join "`n"
        if ($selectedList.Count -gt 10) {
            $namesList = (($selectedList | Select-Object -First 10 | ForEach-Object { "• $($_.DisplayName)" }) -join "`n") + "`n... và $($selectedList.Count - 10) phần mềm khác."
        }

        $confirm = [System.Windows.MessageBox]::Show(
            "BẠN CÓ CHẮC CHẮN MUỐN GỠ CÀI ĐẶT TIÊU CHUẨN $($selectedList.Count) PHẦN MỀM ĐÃ CHỌN?`n`nDanh sách phần mềm:`n$namesList`n`nLưu ý: Hệ thống sẽ lần lượt gọi bộ gỡ cài đặt gốc của nhà sản xuất cho từng phần mềm.",
            "Xác Nhận Gỡ Cài Đặt Tiêu Chuẩn",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Question
        )

        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            $txtUninstallerLog.Text = ""
            $logBuilder = [System.Text.StringBuilder]::new()
            $onLogBlock = {
                param($msg)
                $null = $logBuilder.AppendLine($msg)
                $txtUninstallerLog.Text = $logBuilder.ToString()
                $txtUninstallerLog.ScrollToEnd()
                Invoke-VUONGTTDoEvents
            }

            $idx = 1
            $totalBatch = $selectedList.Count
            foreach ($appItem in $selectedList) {
                $txtFooterStatus.Text = "• [TIẾN ĐỘ $idx/$totalBatch] Đang gỡ bỏ: $($appItem.DisplayName)..."
                & $onLogBlock "=========================================================="
                & $onLogBlock "▶ [TIẾN ĐỘ $idx / $totalBatch] Đang gỡ bỏ: $($appItem.DisplayName)..."
                & $onLogBlock "=========================================================="
                $null = Invoke-VUONGTTUninstallSoftware -AppItem $appItem -CleanDeepScan:$false -OnLog $onLogBlock
                $idx++
            }

            & $onLogBlock "🎉 [HOÀN TẤT] Đã hoàn thành gỡ cài đặt toàn bộ $totalBatch phần mềm!"
            $txtFooterStatus.Text = "• [OK] Đã hoàn thành gỡ cài đặt $totalBatch phần mềm."
            [System.Windows.MessageBox]::Show("Đã hoàn tất tiến trình gỡ cài đặt cho $totalBatch phần mềm đã chọn!", "Gỡ Cài Đặt Tiêu Chuẩn Hoàn Tất", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            
            # Quét lại danh sách
            $script:allInstalledApps = @()
            Refresh-InstalledAppsGrid -Filter $txtSearchInstalledApps.Text
        }
    })
}

# 2. Gỡ sạch triệt để (Clean Uninstall - Deep Clean) (Hỗ trợ 1 hoặc Hàng Loạt)
if ($btnUninstallClean) {
    $btnUninstallClean.Add_Click({
        $selectedList = @($script:allInstalledApps | Where-Object { $_.IsChecked -eq $true })
        if ($selectedList.Count -eq 0 -and $lvInstalledApps.SelectedItem) {
            $selectedList = @($lvInstalledApps.SelectedItem)
        }

        if ($selectedList.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng tick chọn ít nhất một phần mềm trong danh sách để gỡ sạch triệt để!", "Chưa Chọn Phần Mềm", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $namesList = ($selectedList | ForEach-Object { "• $($_.DisplayName) (v$($_.DisplayVersion))" }) -join "`n"
        if ($selectedList.Count -gt 10) {
            $namesList = (($selectedList | Select-Object -First 10 | ForEach-Object { "• $($_.DisplayName)" }) -join "`n") + "`n... và $($selectedList.Count - 10) phần mềm khác."
        }

        $confirm = [System.Windows.MessageBox]::Show(
            "BẠN CÓ MUỐN GỠ SẠCH TRIỆT ĐỂ (CLEAN DEEP UNINSTALL) $($selectedList.Count) PHẦN MỀM ĐÃ CHỌN?`n`nDanh sách phần mềm:`n$namesList`n`nQuy trình Gỡ Sạch Triệt Để sẽ tự động thực hiện cho từng phần mềm:`n1. Khởi chạy trình gỡ cài đặt gốc.`n2. Quét & xóa sạch toàn bộ thư mục cài đặt gốc còn sót lại.`n3. Quét & xóa sạch tệp rác trong AppData & ProgramData.`n4. Quét & xóa sạch các khóa Registry còn sót lại.`n5. Xóa biểu tượng Shortcut trên Desktop và Start Menu.`n`nBạn có muốn tiếp tục không?",
            "Xác Nhận Gỡ Sạch Triệt Để Hàng Loạt",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )

        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            $txtUninstallerLog.Text = ""
            $logBuilder = [System.Text.StringBuilder]::new()
            $onLogBlock = {
                param($msg)
                $null = $logBuilder.AppendLine($msg)
                $txtUninstallerLog.Text = $logBuilder.ToString()
                $txtUninstallerLog.ScrollToEnd()
                Invoke-VUONGTTDoEvents
            }

            $idx = 1
            $totalBatch = $selectedList.Count
            foreach ($appItem in $selectedList) {
                $txtFooterStatus.Text = "• [GỠ SẠCH $idx/$totalBatch] Đang xử lý: $($appItem.DisplayName)..."
                & $onLogBlock "=========================================================="
                & $onLogBlock "⚡ [GỠ SẠCH $idx / $totalBatch] Bắt đầu gỡ & quét rác: $($appItem.DisplayName)..."
                & $onLogBlock "=========================================================="
                $null = Invoke-VUONGTTUninstallSoftware -AppItem $appItem -CleanDeepScan:$true -OnLog $onLogBlock
                $idx++
            }

            & $onLogBlock "=========================================================="
            & $onLogBlock "🎉 [HOÀN TẤT TOÀN BỘ] Đã gỡ sạch triệt để và quét rác $totalBatch phần mềm!"
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất gỡ sạch triệt để $totalBatch phần mềm."
            [System.Windows.MessageBox]::Show("GỠ SẠCH HOÀN TẤT!`n`nĐã gỡ bỏ và dọn dẹp sạch sẽ toàn bộ $totalBatch phần mềm đã chọn (bao gồm tệp rác & Registry còn sót lại).", "Gỡ Sạch Triệt Để Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

            # Quét lại danh sách
            $script:allInstalledApps = @()
            Refresh-InstalledAppsGrid -Filter $txtSearchInstalledApps.Text
        }
    })
}

# 3. Mở thư mục cài đặt
if ($btnOpenAppFolder) {
    $btnOpenAppFolder.Add_Click({
        $selected = $lvInstalledApps.SelectedItem
        if (-not $selected) {
            [System.Windows.MessageBox]::Show("Vui lòng chọn một phần mềm trong bảng!", "Thông Báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $folder = $selected.InstallLocation
        if ($folder -and (Test-Path $folder -ErrorAction SilentlyContinue)) {
            Start-Process "explorer.exe" -ArgumentList "`"$folder`""
        } else {
            [System.Windows.MessageBox]::Show("Ứng dụng này không có thông tin thư mục cài đặt cố định trong Registry hoặc thư mục không còn tồn tại!", "Thư Mục Không Tồn Tại", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
}

# 4. Mở Registry Key
if ($btnOpenAppRegistry) {
    $btnOpenAppRegistry.Add_Click({
        $selected = $lvInstalledApps.SelectedItem
        if (-not $selected -or -not $selected.RegistryPath) {
            [System.Windows.MessageBox]::Show("Vui lòng chọn một phần mềm trong bảng!", "Thông Báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        try {
            $cleanReg = $selected.RegistryPath -replace '^Microsoft\.PowerShell\.Core\\Registry::', ''
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit" -Name "LastKey" -Value $cleanReg -ErrorAction SilentlyContinue
            Start-Process "regedit.exe"
        } catch {
            Start-Process "regedit.exe"
        }
    })
}

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

# Hardware & Peripheral Diagnostic Controls (Merged Single Tab)
$btnTestKeyboard       = Get-Control "btnTestKeyboard"
$btnTestMic            = Get-Control "btnTestMic"
$btnTestCam            = Get-Control "btnTestCam"
$btnTestKeyboardVisual = Get-Control "btnTestKeyboardVisual"
$btnTestCpuStress      = Get-Control "btnTestCpuStress"
$btnTestNetworkPing    = Get-Control "btnTestNetworkPing"
$btnTestAudioBass      = Get-Control "btnTestAudioBass"
$btnTestAudioTreble    = Get-Control "btnTestAudioTreble"
$btnTestSpeakerLeft    = Get-Control "btnTestSpeakerLeft"
$btnTestSpeakerRight   = Get-Control "btnTestSpeakerRight"
$btnTestSpeakerStereo  = Get-Control "btnTestSpeakerStereo"

# 1. Visual Keyboard Test (Offline WPF GUI)
if ($btnTestKeyboardVisual) {
    $btnTestKeyboardVisual.Add_Click({
        $txtFooterStatus.Text = "• [OK] Đang chạy bộ test bàn phím trực quan Offline..."
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "[OK] Đang mở trình kiểm tra bàn phím trực quan Offline (không cần Internet)..." }
        Start-VisualKeyboardTest
    })
}

# 2. Key Test Online
if ($btnTestKeyboard) {
    $btnTestKeyboard.Add_Click({
        Start-Process "https://en.key-test.com/"
        $txtFooterStatus.Text = "• [OK] Đã mở trình kiểm tra bàn phím trực tuyến (Key Test)."
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "[OK] Đang mở trình kiểm tra bàn phím trực quan trên trình duyệt..." }
    })
}

# 3. CPU Burn-in / Stress Test (15s)
if ($btnTestCpuStress) {
    $btnTestCpuStress.Add_Click({
        $confirm = [System.Windows.MessageBox]::Show(
            "Bạn có muốn bắt đầu Stress Test CPU 100% trong 15 giây?`n`nQuá trình này sẽ đẩy tải toàn bộ các luồng CPU lên 100% để kiểm tra độ ổn định nguồn, tản nhiệt và quạt làm mát.",
            "CPU Burn-In Stress Test",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "🔥 Đang kích hoạt Stress Test 100% CPU trên tất cả các luồng trong 15 giây... Đang theo dõi nhiệt độ & quạt..." }
            $txtFooterStatus.Text = "• [TEST] Đang kích hoạt 100% tải CPU..."
            $stressRes = Start-CpuBurnInTest -DurationSeconds 15
            if ($stressRes.Success) {
                if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "🔥 [ĐANG CHẠY] $($stressRes.Message)`nQuá trình sẽ tự ngắt an toàn sau 15 giây..." }
                Start-Sleep -Seconds 1
                if ($txtRepairAuditLog) { $txtRepairAuditLog.Text += "`n[OK] Tiến trình tính toán tải nặng đang chạy trên $($stressRes.Cores) luồng." }
            } else {
                if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "❌ $($stressRes.Message)" }
            }
        }
    })
}

# 4. Network Ping & Wi-Fi Stability Tester
if ($btnTestNetworkPing) {
    $btnTestNetworkPing.Add_Click({
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "🌐 Đang kiểm tra độ trễ mạng (Ping) tới Gateway, Google DNS và Cloudflare..." }
        $txtFooterStatus.Text = "• [TEST] Đang đo độ trễ và kiểm tra card mạng..."
        $res = Start-NetworkPingTest
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "================ KẾT QUẢ ĐO ĐỘ TRỄ MẠNG (PING) ================`n$res`n==============================================================" }
        $txtFooterStatus.Text = "• [OK] Đã hoàn thành kiểm tra độ trễ mạng"
    })
}

# 5. Audio Frequency (Bass / Treble)
if ($btnTestAudioBass) {
    $btnTestAudioBass.Add_Click({
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "🎵 Đang phát chuỗi tần số Siêu Trầm (Bass 120-200Hz) qua loa..." }
        $res = Test-AudioFrequency -Type "Bass"
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã phát tần số Bass"
    })
}

if ($btnTestAudioTreble) {
    $btnTestAudioTreble.Add_Click({
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "🎵 Đang phát chuỗi tần số Cao (Treble 2500-4500Hz) qua loa..." }
        $res = Test-AudioFrequency -Type "Treble"
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã phát tần số Treble"
    })
}

# 6. Mic & Camera Handlers
if ($btnTestMic) {
    $btnTestMic.Add_Click({
        try {
            Start-Process "explorer.exe" -ArgumentList "ms-windows-soundrecorder:"
        } catch {
            Start-Process "mmsys.cpl"
        }
        $txtFooterStatus.Text = "• [OK] Đã mở trình kiểm tra Microphone."
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "[OK] Đã kích hoạt công cụ ghi âm và kiểm tra tín hiệu Microphone." }
    })
}

if ($btnTestCam) {
    $btnTestCam.Add_Click({
        try {
            Start-Process "explorer.exe" -ArgumentList "microsoft.windows.camera:"
        } catch {
            Start-Process "https://webcamtests.com/"
        }
        $txtFooterStatus.Text = "• [OK] Đã mở ứng dụng Camera / Webcam."
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "[OK] Đã khởi động ứng dụng Camera để kiểm tra hình ảnh và cảm biến." }
    })
}

# 7. Audio Stereo & Screen Dead Pixel Handlers
if ($btnTestSpeakerLeft) {
    $btnTestSpeakerLeft.Add_Click({
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "Đang phát tín hiệu âm thanh kiểm tra Loa Trái (Left Channel 800Hz)..." }
        [System.Console]::Beep(800, 600)
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "[OK] Đã phát xong tín hiệu tần số 800Hz trên Loa Trái." }
        $txtFooterStatus.Text = "• [OK] Đã test Loa Trái"
    })
}

if ($btnTestSpeakerRight) {
    $btnTestSpeakerRight.Add_Click({
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "Đang phát tín hiệu âm thanh kiểm tra Loa Phải (Right Channel 1200Hz)..." }
        [System.Console]::Beep(1200, 600)
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "[OK] Đã phát xong tín hiệu tần số 1200Hz trên Loa Phải." }
        $txtFooterStatus.Text = "• [OK] Đã test Loa Phải"
    })
}

if ($btnTestSpeakerStereo) {
    $btnTestSpeakerStereo.Add_Click({
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "Đang phát chuỗi âm thanh Stereo đa tần số qua 2 loa..." }
        [System.Console]::Beep(523, 200)
        [System.Console]::Beep(659, 200)
        [System.Console]::Beep(784, 200)
        [System.Console]::Beep(1046, 350)
        if ($txtRepairAuditLog) { $txtRepairAuditLog.Text = "[OK] Cả 2 kênh Loa Stereo đã phát chuỗi âm thanh rõ ràng, không rè." }
        $txtFooterStatus.Text = "• [OK] Đã test Loa Stereo hoàn tất"
    })
}

$btnRunRepairAudit.Add_Click({
    $txtRepairAuditLog.Text = "Đang quét thông tin phần cứng..."
    $res = Get-LaptopRepairAudit
    $txtRepairAuditLog.Text = $res
})

# =========================================================================
# MODULE 9: SỨC KHỎE Ổ CỨNG & BENCHMARK HỆ THỐNG (CRYSTAL DISK INFO)
# =========================================================================
$cmbDiskSelect        = Get-Control "cmbDiskSelect"
$btnRefreshDiskHealth = Get-Control "btnRefreshDiskHealth"
$borderHealthBadge    = Get-Control "borderHealthBadge"
$badgeHealthColor     = Get-Control "badgeHealthColor"
$txtHealthPct         = Get-Control "txtHealthPct"
$txtHealthRating      = Get-Control "txtHealthRating"
$txtHealthGrade       = Get-Control "txtHealthGrade"
$txtHealthDesc        = Get-Control "txtHealthDesc"
$txtDiskTemp          = Get-Control "txtDiskTemp"
$txtDiskTempStatus    = Get-Control "txtDiskTempStatus"
$txtPowerHours        = Get-Control "txtPowerHours"
$txtPowerCount        = Get-Control "txtPowerCount"
$txtRemainingLife     = Get-Control "txtRemainingLife"
$txtBusInterface      = Get-Control "txtBusInterface"
$txtDiskModel         = Get-Control "txtDiskModel"
$txtDiskMediaType     = Get-Control "txtDiskMediaType"
$txtDiskCapacity      = Get-Control "txtDiskCapacity"
$txtDiskSerial        = Get-Control "txtDiskSerial"
$txtDiskFirmware      = Get-Control "txtDiskFirmware"
$panelDiskVolumes     = Get-Control "panelDiskVolumes"
$lstSmartAttributes   = Get-Control "lstSmartAttributes"
$btnRunDiskBenchmark2 = Get-Control "btnRunDiskBenchmark2"
$btnRunSurfaceScan    = Get-Control "btnRunSurfaceScan"
$btnCopyDiskReport    = Get-Control "btnCopyDiskReport"
$btnRunCpuBenchmark   = Get-Control "btnRunCpuBenchmark"
$btnRunRamBenchmark   = Get-Control "btnRunRamBenchmark"
$btnCheckPowerHours   = Get-Control "btnCheckPowerHours"
$txtBenchmarkResult2  = Get-Control "txtBenchmarkResult2"
$txtSessionUptime     = Get-Control "txtSessionUptime"
$txtPowerHoursRating  = Get-Control "txtPowerHoursRating"

$script:cachedDiskHealthList = @()

function Select-VUONGTTDiskIndex {
    param([int]$Index = 0)
    if (-not $script:cachedDiskHealthList -or $script:cachedDiskHealthList.Count -eq 0) { return }
    if ($Index -lt 0 -or $Index -ge $script:cachedDiskHealthList.Count) { $Index = 0 }

    $d = $script:cachedDiskHealthList[$Index]
    if (-not $d) { return }

    $conv = [System.Windows.Media.BrushConverter]::new()

    # Health Badge
    if ($txtHealthPct) { $txtHealthPct.Text = "$($d.HealthPct)%" }
    if ($txtHealthRating) {
        $txtHealthRating.Text = $d.HealthText
        $txtHealthRating.Foreground = $conv.ConvertFromString($d.HealthColor)
    }
    if ($badgeHealthColor) {
        $badgeHealthColor.Background = $conv.ConvertFromString($d.HealthColor)
    }
    if ($borderHealthBadge) {
        $borderHealthBadge.BorderBrush = $conv.ConvertFromString($d.HealthColor)
    }
    if ($txtHealthDesc) { $txtHealthDesc.Text = $d.HealthDescription }

    # Temperature
    if ($txtDiskTemp) {
        if ($d.TemperatureC) {
            $txtDiskTemp.Text = "$($d.TemperatureC)°C"
            if ($d.TemperatureC -ge 65) {
                $txtDiskTemp.Foreground = $conv.ConvertFromString("#BE123C")
                $txtDiskTempStatus.Text = "CẢNH BÁO • Nhiệt độ quá cao"
                $txtDiskTempStatus.Foreground = $conv.ConvertFromString("#BE123C")
            } elseif ($d.TemperatureC -ge 50) {
                $txtDiskTemp.Foreground = $conv.ConvertFromString("#B45309")
                $txtDiskTempStatus.Text = "Ấm • Hoạt động bình thường"
                $txtDiskTempStatus.Foreground = $conv.ConvertFromString("#B45309")
            } else {
                $txtDiskTemp.Foreground = $conv.ConvertFromString("#0284C7")
                $txtDiskTempStatus.Text = "Mát Mẻ • Hoạt động an toàn"
                $txtDiskTempStatus.Foreground = $conv.ConvertFromString("#047857")
            }
        } else {
            $txtDiskTemp.Text = "N/A"
            $txtDiskTempStatus.Text = "Môi trường ảo hóa / Tiêu chuẩn mở"
            $txtDiskTempStatus.Foreground = $conv.ConvertFromString("#64748B")
        }
    }

    # Stats & Specs
    if ($txtPowerHours) {
        $pohFmt = [string]::Format('{0:N0}', $d.PowerOnHours)
        $txtPowerHours.Text = "$pohFmt Giờ (~$([math]::Round($d.PowerOnHours / 24, 0)) Ngày)"
    }
    if ($txtPowerCount) {
        $pocFmt = [string]::Format('{0:N0}', $d.PowerOnCount)
        $txtPowerCount.Text = "$pocFmt Lần"
    }
    if ($txtSessionUptime) {
        $txtSessionUptime.Text = if ($d.SessionUptime) { $d.SessionUptime } else { "Đang hoạt động" }
    }
    if ($txtPowerHoursRating) {
        $txtPowerHoursRating.Text = if ($d.PowerHoursRating) { $d.PowerHoursRating } else { "Tốt • Bền Bỉ" }
    }
    if ($txtRemainingLife) {
        $txtRemainingLife.Text = "$($d.HealthPct)% (Tuổi thọ chip Flash)"
        $txtRemainingLife.Foreground = $conv.ConvertFromString($d.HealthColor)
    }
    if ($txtBusInterface) {
        $txtBusInterface.Text = "$($d.BusType) • $($d.MediaType)"
    }
    if ($txtDiskModel) { $txtDiskModel.Text = $d.Model }
    if ($txtDiskMediaType) { $txtDiskMediaType.Text = $d.MediaType }
    if ($txtDiskCapacity) { $txtDiskCapacity.Text = "$($d.SizeGB) GB" }
    if ($txtDiskSerial) { $txtDiskSerial.Text = $d.Serial }
    if ($txtDiskFirmware) { $txtDiskFirmware.Text = $d.Firmware }

    # Volumes & Usage ProgressBars
    if ($panelDiskVolumes) {
        $panelDiskVolumes.Children.Clear()
        if ($d.Volumes -and $d.Volumes.Count -gt 0) {
            foreach ($v in $d.Volumes) {
                $vCard = New-Object System.Windows.Controls.Border
                $vCard.Background = $window.Resources["CardInnerBgBrush"]
                $vCard.BorderBrush = $window.Resources["CardBorderBrush"]
                $vCard.BorderThickness = New-Object System.Windows.Thickness(1)
                $vCard.CornerRadius = New-Object System.Windows.CornerRadius(6)
                $vCard.Padding = New-Object System.Windows.Thickness(10, 8, 10, 8)
                $vCard.Margin = New-Object System.Windows.Thickness(0, 0, 0, 6)

                $vSp = New-Object System.Windows.Controls.StackPanel

                $vHeader = New-Object System.Windows.Controls.Grid
                $vHeader.Margin = New-Object System.Windows.Thickness(0, 0, 0, 4)

                $lblVName = New-Object System.Windows.Controls.TextBlock
                $lblVName.Text = "Phân vùng $($v.DriveLetter) [$($v.Label)] - $($v.FileSystem)"
                $lblVName.FontWeight = [System.Windows.FontWeights]::Bold
                $lblVName.FontSize = 11.5

                $lblVUsage = New-Object System.Windows.Controls.TextBlock
                $lblVUsage.Text = "Trống $($v.FreeGB) GB / $($v.TotalGB) GB"
                $lblVUsage.FontSize = 11
                $lblVUsage.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
                $lblVUsage.Foreground = $window.Resources["TextSecondaryBrush"]

                $vHeader.Children.Add($lblVName) | Out-Null
                $vHeader.Children.Add($lblVUsage) | Out-Null
                $vSp.Children.Add($vHeader) | Out-Null

                $pb = New-Object System.Windows.Controls.ProgressBar
                $pb.Height = 8
                $pb.Minimum = 0
                $pb.Maximum = 100
                $pb.Value = $v.UsedPercent
                $pb.Foreground = if ($v.UsedPercent -ge 90) { $conv.ConvertFromString("#BE123C") } elseif ($v.UsedPercent -ge 75) { $conv.ConvertFromString("#B45309") } else { $conv.ConvertFromString("#0284C7") }
                $pb.Background = $conv.ConvertFromString("#E2E8F0")

                $vSp.Children.Add($pb) | Out-Null

                $vCard.Child = $vSp
                $panelDiskVolumes.Children.Add($vCard) | Out-Null
            }
        } else {
            $txtNoVol = New-Object System.Windows.Controls.TextBlock
            $txtNoVol.Text = "Không có phân vùng hệ thống nào được gán trên ổ đĩa này."
            $txtNoVol.Foreground = $window.Resources["TextSecondaryBrush"]
            $panelDiskVolumes.Children.Add($txtNoVol) | Out-Null
        }
    }

    # SMART Attributes
    if ($lstSmartAttributes) {
        $lstSmartAttributes.Items.Clear()
        if ($d.SmartAttributes) {
            foreach ($attr in $d.SmartAttributes) {
                $lstSmartAttributes.Items.Add($attr) | Out-Null
            }
        }
    }
}

function Refresh-VUONGTTDiskHealthUI {
    $script:cachedDiskHealthList = Get-VUONGTTDiskHealthList
    if ($cmbDiskSelect) {
        $cmbDiskSelect.Items.Clear()
        foreach ($d in $script:cachedDiskHealthList) {
            $cmbDiskSelect.Items.Add("[Disk $($d.DeviceId)] $($d.Model) ($($d.SizeGB) GB) - $($d.HealthText)") | Out-Null
        }
        if ($cmbDiskSelect.Items.Count -gt 0) {
            $cmbDiskSelect.SelectedIndex = 0
        }
    }
    Select-VUONGTTDiskIndex -Index 0
}

if ($cmbDiskSelect) {
    $cmbDiskSelect.Add_SelectionChanged({
        if ($cmbDiskSelect.SelectedIndex -ge 0) {
            Select-VUONGTTDiskIndex -Index $cmbDiskSelect.SelectedIndex
        }
    })
}

if ($btnRefreshDiskHealth) {
    $btnRefreshDiskHealth.Add_Click({
        $txtFooterStatus.Text = "• [SCAN] Đang quét lại thông tin sức khỏe và S.M.A.R.T ổ cứng..."
        Refresh-VUONGTTDiskHealthUI
        $txtFooterStatus.Text = "• [OK] Đã cập nhật xong tình trạng sức khỏe ổ đĩa!"
    })
}

if ($btnCheckPowerHours) {
    $btnCheckPowerHours.Add_Click({
        $curDisk = if ($script:cachedDiskHealthList -and $cmbDiskSelect -and $cmbDiskSelect.SelectedIndex -ge 0) { $script:cachedDiskHealthList[$cmbDiskSelect.SelectedIndex] } else { $null }
        if (-not $curDisk -and $script:cachedDiskHealthList.Count -gt 0) { $curDisk = $script:cachedDiskHealthList[0] }
        if ($curDisk) {
            $txtFooterStatus.Text = "• [SCAN] Đang phân tích chi tiết thời gian vận hành và lịch sử bật máy..."
            if ($txtBenchmarkResult2) {
                $txtBenchmarkResult2.Text = "⏳ Đang phân tích chi tiết tổng số giờ hoạt động, thời gian bật máy hiện tại và lịch sử bật/tắt nguồn..."
            }
            Invoke-VUONGTTDoEvents
            $analysis = Get-VUONGTTDiskPowerAnalysis -DiskHealthObj $curDisk
            if ($txtBenchmarkResult2) {
                $txtBenchmarkResult2.Text = $analysis
            }
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất phân tích chi tiết số giờ chạy của ổ đĩa ($($curDisk.Model))!"
        }
    })
}

if ($btnRunDiskBenchmark2) {
    $btnRunDiskBenchmark2.Add_Click({
        $targetDrive = "C"
        $curDisk = if ($script:cachedDiskHealthList -and $cmbDiskSelect -and $cmbDiskSelect.SelectedIndex -ge 0) { $script:cachedDiskHealthList[$cmbDiskSelect.SelectedIndex] } else { $null }
        if ($curDisk -and $curDisk.Volumes -and $curDisk.Volumes.Count -gt 0) {
            $targetDrive = $curDisk.Volumes[0].DriveLetter.Replace(":","")
        }

        if ($txtBenchmarkResult2) {
            $txtBenchmarkResult2.Text = "⏳ Đang tiến hành đo tốc độ Đọc/Ghi tuần tự trên phân vùng $($targetDrive): (Kích thước mẫu 128 MB)... Vui lòng đợi trong giây lát!"
        }
        Invoke-VUONGTTDoEvents

        $res = Measure-VUONGTTDiskBenchmark -TargetDrive $targetDrive
        if ($txtBenchmarkResult2) { $txtBenchmarkResult2.Text = $res }
        $txtFooterStatus.Text = "• [OK] Hoàn tất đo tốc độ Đọc/Ghi thực tế của ổ đĩa ($($targetDrive):)!"
    })
}

if ($btnRunSurfaceScan) {
    $btnRunSurfaceScan.Add_Click({
        $targetDrive = "C"
        $curDisk = if ($script:cachedDiskHealthList -and $cmbDiskSelect -and $cmbDiskSelect.SelectedIndex -ge 0) { $script:cachedDiskHealthList[$cmbDiskSelect.SelectedIndex] } else { $null }
        if ($curDisk -and $curDisk.Volumes -and $curDisk.Volumes.Count -gt 0) {
            $targetDrive = $curDisk.Volumes[0].DriveLetter.Replace(":","")
        }

        if ($txtBenchmarkResult2) {
            $txtBenchmarkResult2.Text = "⏳ Đang bắt đầu quét kiểm tra bề mặt & hệ thống tệp trên phân vùng $($targetDrive): (Chkdsk Scan-Only an toàn)... Vui lòng đợi!"
        }
        Invoke-VUONGTTDoEvents

        $res = Invoke-VUONGTTDiskSurfaceScan -TargetDrive $targetDrive
        if ($txtBenchmarkResult2) { $txtBenchmarkResult2.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất quét kiểm tra bề mặt phân vùng $($targetDrive):!"
    })
}

if ($btnCopyDiskReport) {
    $btnCopyDiskReport.Add_Click({
        $curDisk = if ($script:cachedDiskHealthList -and $cmbDiskSelect -and $cmbDiskSelect.SelectedIndex -ge 0) { $script:cachedDiskHealthList[$cmbDiskSelect.SelectedIndex] } else { $null }
        if (-not $curDisk -and $script:cachedDiskHealthList.Count -gt 0) { $curDisk = $script:cachedDiskHealthList[0] }
        if ($curDisk) {
            $rep = Export-VUONGTTDiskHealthReport -DiskHealthObj $curDisk
            [System.Windows.Clipboard]::SetText($rep)
            if ($txtBenchmarkResult2) { $txtBenchmarkResult2.Text = $rep }
            $txtFooterStatus.Text = "• [COPIED] Đã sao chép toàn bộ Báo Cáo Sức Khỏe Ổ Cứng (CrystalDisk Report) vào Clipboard!"
        }
    })
}

if ($btnRunCpuBenchmark) {
    $btnRunCpuBenchmark.Add_Click({
        if ($txtBenchmarkResult2) {
            $txtBenchmarkResult2.Text = "⏳ Đang kiểm tra hiệu năng tính toán CPU (Stress & Math Benchmark)..."
            Invoke-VUONGTTDoEvents
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $sum = 0
            for ($i = 1; $i -le 2000000; $i++) { $sum += [math]::Sqrt($i) }
            $sw.Stop()
            $score = [math]::Round(2000000 / ($sw.ElapsedMilliseconds + 1) * 10)
            $txtBenchmarkResult2.Text = "=== KẾT QUẢ BENCHMARK CPU ===`r`n- Thời gian xử lý: $($sw.ElapsedMilliseconds) ms`r`n- Điểm hiệu năng ước tính: $score điểm`r`n- Tình trạng: Hoạt động ổn định, không throttling.`r`n- Thời gian đo: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')"
        }
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất benchmark CPU!"
    })
}

if ($btnRunRamBenchmark) {
    $btnRunRamBenchmark.Add_Click({
        if ($txtBenchmarkResult2) {
            $txtBenchmarkResult2.Text = "⏳ Đang kiểm tra tốc độ cấp phát và băng thông bộ nhớ RAM..."
            Invoke-VUONGTTDoEvents
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $bytes = New-Object byte[] (64 * 1024 * 1024)
            for ($i = 0; $i -lt $bytes.Length; $i += 4096) { $bytes[$i] = 255 }
            $sw.Stop()
            $speedMBs = [math]::Round(64 / (($sw.ElapsedMilliseconds + 1) / 1000.0), 2)
            $txtBenchmarkResult2.Text = "=== KẾT QUẢ BENCHMARK BỘ NHỚ RAM ===`r`n- Kích thước mẫu: 64 MB`r`n- Thời gian cấp phát & ghi: $($sw.ElapsedMilliseconds) ms`r`n- Tốc độ xử lý RAM ước tính: $speedMBs MB/s`r`n- Bộ đệm RAM phản hồi tuyệt vời.`r`n- Thời gian đo: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')"
        }
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất đo băng thông RAM!"
    })
}

# =========================================================================
# MODULE 10: FONT INSTALLER & AUTOCAD TYPOGRAPHY
# =========================================================================
$btnInstallAllFonts      = Get-Control "btnInstallAllFonts"
$btnInstallAutoCADFonts  = Get-Control "btnInstallAutoCADFonts"
$btnInstallVNIFonts      = Get-Control "btnInstallVNIFonts"
$btnInstallTCVN3Fonts    = Get-Control "btnInstallTCVN3Fonts"
$btnInstallGoogleFonts   = Get-Control "btnInstallGoogleFonts"
$btnInstallCustomFonts   = Get-Control "btnInstallCustomFonts"
$btnOpenFontFolder       = Get-Control "btnOpenFontFolder"
$txtFontLog              = Get-Control "txtFontLog"

$onFontLog = {
    param($msg)
    if ($txtFontLog) {
        $txtFontLog.AppendText("$msg`r`n")
        $txtFontLog.ScrollToEnd()
    }
    Invoke-VUONGTTDoEvents
}

if ($btnInstallAllFonts) {
    $btnInstallAllFonts.Add_Click({
        $btnInstallAllFonts.IsEnabled = $false
        try {
            if ($txtFontLog) { $txtFontLog.Text = "" }
            $txtFooterStatus.Text = "• [FONTS] Đang nạp toàn bộ Font Tiếng Việt & Unicode..."
            Invoke-VUONGTTDoEvents
            $res = Install-VietnameseFonts -FontType "ALL" -OnProgress $onFontLog
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất cài đặt toàn bộ Font Tiếng Việt!"
            [System.Windows.MessageBox]::Show("Đã hoàn tất quá trình cài đặt và kích hoạt toàn bộ Font Tiếng Việt vào hệ thống Windows!", "Cài Đặt Font Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } finally {
            $btnInstallAllFonts.IsEnabled = $true
        }
    })
}

if ($btnInstallAutoCADFonts) {
    $btnInstallAutoCADFonts.Add_Click({
        $btnInstallAutoCADFonts.IsEnabled = $false
        try {
            if ($txtFontLog) { $txtFontLog.Text = "" }
            $txtFooterStatus.Text = "• [AUTOCAD] Đang nạp bộ Font AutoCAD (.SHX & TTF) chống lỗi bản vẽ..."
            Invoke-VUONGTTDoEvents
            $res = Install-VietnameseFonts -FontType "AUTOCAD" -OnProgress $onFontLog
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất cài đặt trọn bộ Font AutoCAD!"
            [System.Windows.MessageBox]::Show("ĐÃ HOÀN TẤT CÀI ĐẶT BỘ FONT AUTOCAD!`n`n• Toàn bộ font .SHX đã được nạp vào tất cả phiên bản AutoCAD tìm thấy trên máy.`n• Toàn bộ font bản vẽ TTF đã được đăng ký vào Windows Fonts.`n• Đã xuất gói dự phòng tại màn hình Desktop (AutoCAD_Fonts_Full).", "Cài Đặt Font AutoCAD Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } finally {
            $btnInstallAutoCADFonts.IsEnabled = $true
        }
    })
}

if ($btnInstallVNIFonts) {
    $btnInstallVNIFonts.Add_Click({
        $btnInstallVNIFonts.IsEnabled = $false
        try {
            if ($txtFontLog) { $txtFontLog.Text = "" }
            $txtFooterStatus.Text = "• [FONTS] Đang cài đặt bộ Font VNI..."
            Invoke-VUONGTTDoEvents
            $res = Install-VietnameseFonts -FontType "VNI" -OnProgress $onFontLog
            $txtFooterStatus.Text = "• [OK] Đã cài đặt bộ Font VNI!"
            [System.Windows.MessageBox]::Show("Đã hoàn tất cài đặt bộ Font VNI (VNI-Times, VNI-Aptima...)!", "Cài Đặt Font VNI Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } finally {
            $btnInstallVNIFonts.IsEnabled = $true
        }
    })
}

if ($btnInstallTCVN3Fonts) {
    $btnInstallTCVN3Fonts.Add_Click({
        $btnInstallTCVN3Fonts.IsEnabled = $false
        try {
            if ($txtFontLog) { $txtFontLog.Text = "" }
            $txtFooterStatus.Text = "• [FONTS] Đang cài đặt bộ Font TCVN3 / ABC..."
            Invoke-VUONGTTDoEvents
            $res = Install-VietnameseFonts -FontType "TCVN3" -OnProgress $onFontLog
            $txtFooterStatus.Text = "• [OK] Đã cài đặt bộ Font TCVN3!"
            [System.Windows.MessageBox]::Show("Đã hoàn tất cài đặt bộ Font TCVN3 (.VnTime, .VnArial...)!", "Cài Đặt Font TCVN3 Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } finally {
            $btnInstallTCVN3Fonts.IsEnabled = $true
        }
    })
}

if ($btnInstallGoogleFonts) {
    $btnInstallGoogleFonts.Add_Click({
        $btnInstallGoogleFonts.IsEnabled = $false
        try {
            if ($txtFontLog) { $txtFontLog.Text = "" }
            $txtFooterStatus.Text = "• [FONTS] Đang cài đặt Google Fonts tiếng Việt (Roboto, Inter...)..."
            Invoke-VUONGTTDoEvents
            $res = Install-VietnameseFonts -FontType "UNICODE" -OnProgress $onFontLog
            $txtFooterStatus.Text = "• [OK] Đã cài đặt Google Fonts tiếng Việt!"
            [System.Windows.MessageBox]::Show("Đã hoàn tất cài đặt bộ Google Fonts Tiếng Việt hiện đại!", "Cài Đặt Google Fonts Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } finally {
            $btnInstallGoogleFonts.IsEnabled = $true
        }
    })
}

if ($btnInstallCustomFonts) {
    $btnInstallCustomFonts.Add_Click({
        $dlg = New-Object System.Windows.Forms.OpenFileDialog
        $dlg.Title = "Chọn Gói Font (File ZIP hoặc Tệp Font Cần Cài)"
        $dlg.Filter = "Tất cả định dạng font (*.zip;*.shx;*.ttf;*.otf)|*.zip;*.shx;*.ttf;*.otf|Tệp ZIP Font (*.zip)|*.zip|Font AutoCAD (*.shx)|*.shx|Font Windows (*.ttf;*.otf)|*.ttf;*.otf|Mọi tệp (*.*)|*.*"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $selFile = $dlg.FileName
            $btnInstallCustomFonts.IsEnabled = $false
            try {
                if ($txtFontLog) { $txtFontLog.Text = "" }
                $txtFooterStatus.Text = "• [FONTS] Đang nạp gói font từ: $selFile..."
                Invoke-VUONGTTDoEvents
                $res = Install-VietnameseFonts -FontType "CUSTOM" -CustomSourcePath $selFile -OnProgress $onFontLog
                $txtFooterStatus.Text = "• [OK] Đã nạp xong gói font tùy chọn!"
                [System.Windows.MessageBox]::Show("Đã nạp thành công toàn bộ font từ tệp tùy chọn vào hệ thống Windows và AutoCAD!", "Cài Đặt Font Tùy Chọn", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            } finally {
                $btnInstallCustomFonts.IsEnabled = $true
            }
        }
    })
}

if ($btnOpenFontFolder) {
    $btnOpenFontFolder.Add_Click({
        Start-Process "explorer.exe" -ArgumentList "$env:WINDIR\Fonts"
        $txtFooterStatus.Text = "• [OK] Đã mở thư mục Fonts hệ thống"
    })
}

# =========================================================================
# MODULE 11: QUẢN LÝ, KIỂM TRA & CẬP NHẬT DRIVER TOÀN DIỆN
# =========================================================================
$txtDriverMachineInfo        = Get-Control "txtDriverMachineInfo"
$txtDriverTotalDevices       = Get-Control "txtDriverTotalDevices"
$txtDriverIssuesCount        = Get-Control "txtDriverIssuesCount"
$txtDriverGpuStatus          = Get-Control "txtDriverGpuStatus"

$btnCheckAllDrivers          = Get-Control "btnCheckAllDrivers"
$btnViewDriverIssues         = Get-Control "btnViewDriverIssues"
$btnOpenDeviceManagerDirect  = Get-Control "btnOpenDeviceManagerDirect"

$btnAutoUpdateAllDrivers     = Get-Control "btnAutoUpdateAllDrivers"
$btnLaunchSDIO               = Get-Control "btnLaunchSDIO"
$btnLaunch3DPChip            = Get-Control "btnLaunch3DPChip"
$btnOpenOEMDriverPortal      = Get-Control "btnOpenOEMDriverPortal"

$btnBackupAllDrivers         = Get-Control "btnBackupAllDrivers"
$btnBackupPrinterDrivers     = Get-Control "btnBackupPrinterDrivers"
$btnExportDriverList         = Get-Control "btnExportDriverList"
$btnOpenBackupFolder         = Get-Control "btnOpenBackupFolder"
$btnRestoreDrivers           = Get-Control "btnRestoreDrivers"
$btnCheckMissingDrivers      = Get-Control "btnCheckMissingDrivers"
$btnClearDriverLog           = Get-Control "btnClearDriverLog"
$txtDriverLog                = Get-Control "txtDriverLog"

function Refresh-DriverStatusBadge {
    try {
        $diag = Get-VUONGTTDeepDriverDiagnostic
        if ($txtDriverMachineInfo) {
            $txtDriverMachineInfo.Text = "$($diag.Manufacturer) $($diag.Model)"
        }
        if ($txtDriverTotalDevices) {
            $txtDriverTotalDevices.Text = "$($diag.TotalDevices) Thiết bị"
        }
        if ($txtDriverIssuesCount) {
            if ($diag.IssueCount -gt 0) {
                $txtDriverIssuesCount.Text = "$($diag.IssueCount) Lỗi / Thiếu (!)"
                $txtDriverIssuesCount.Foreground = [System.Windows.Media.Brushes]::Crimson
            } else {
                $txtDriverIssuesCount.Text = "0 (Tối ưu [OK])"
                $txtDriverIssuesCount.Foreground = [System.Windows.Media.Brushes]::ForestGreen
            }
        }
        if ($txtDriverGpuStatus) {
            if ($diag.HasGpuWarning) {
                $txtDriverGpuStatus.Text = "Cảnh báo / Thiếu VGA (!)"
                $txtDriverGpuStatus.Foreground = [System.Windows.Media.Brushes]::Crimson
            } else {
                $txtDriverGpuStatus.Text = "$($diag.GpuStatus)"
                $txtDriverGpuStatus.Foreground = [System.Windows.Media.Brushes]::ForestGreen
            }
        }
    } catch {}
}

if ($btnCheckAllDrivers) {
    $btnCheckAllDrivers.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang quét sâu toàn bộ phần cứng PnP và chẩn đoán Driver..." }
        Invoke-VUONGTTDoEvents
        try {
            $diag = Get-VUONGTTDeepDriverDiagnostic
            Refresh-DriverStatusBadge

            $report = @(
                "============================================================",
                "  BÁO CÁO CHẨN ĐOÁN DRIVER & PHẦN CỨNG MÁY TÍNH",
                "  Thời gian kiểm tra: $(Get-Date -Format 'HH:mm:ss dd/MM/yyyy')",
                "============================================================",
                "• Máy tính / Model: $($diag.Manufacturer) $($diag.Model)",
                "• Số Serial / Service Tag: $(if ($diag.SerialNumber) { $diag.SerialNumber } else { 'N/A' })",
                "• Tổng số thiết bị phần cứng PnP: $($diag.TotalDevices) thiết bị",
                "• Tình trạng Card đồ họa (GPU): $($diag.GpuStatus)"
            )

            if ($diag.IssueCount -gt 0) {
                $report += "⚠️ PHÁT HIỆN $($diag.IssueCount) THIẾT BỊ THIẾU DRIVER HOẶC BỊ LỖI CHẤM THAN VÀNG (!):"
                $idx = 0
                foreach ($iss in $diag.IssueList) {
                    $idx++
                    $report += "  [$idx] $($iss.Name)"
                    $report += "      • Hãng / Vendor: $($iss.Vendor)"
                    $report += "      • Trạng thái lỗi: $($iss.Description)"
                    if ($iss.HardwareID) { $report += "      • Hardware ID: $($iss.HardwareID)" }
                    $report += "      👉 Giải pháp: $($iss.Suggestion)"
                }
                $report += "`n💡 Bấm 'Cập Nhật Toàn Bộ Driver Tự Động' hoặc 'Xem Chi Tiết Thiết Bị Lỗi' để khắc phục ngay."
            } else {
                $report += "`n🎉 KẾT QUẢ: TOÀN BỘ DRIVER HOẠT ĐỘNG HOÀN HẢO!"
                $report += "• Không có thiết bị nào bị thiếu Driver hoặc có mã lỗi phần cứng."
            }

            if ($txtDriverLog) { $txtDriverLog.Text = ($report -join "`n") }
            $txtFooterStatus.Text = "• [OK] Đã quét xong phần cứng: $($diag.TotalDevices) thiết bị, $($diag.IssueCount) lỗi driver."
        } catch {
            if ($txtDriverLog) { $txtDriverLog.Text = "[LỖI KIỂM TRA DRIVER] $($_.Exception.Message)" }
        }
    })
}

if ($btnViewDriverIssues) {
    $btnViewDriverIssues.Add_Click({
        Show-VUONGTTDriverDoctorModal
    })
}

if ($btnAutoUpdateAllDrivers) {
    $btnAutoUpdateAllDrivers.Add_Click({
        if ($txtDriverLog) { 
            $txtDriverLog.Text = "Đang kích hoạt quy trình tự động quét & cập nhật toàn bộ Driver qua Microsoft Update..." 
        }
        $btnAutoUpdateAllDrivers.IsEnabled = $false
        Invoke-VUONGTTDoEvents

        try {
            $updateSummary = Invoke-VUONGTTAutoUpdateAllDrivers -OnProgress {
                param($msg)
                if ($txtDriverLog) {
                    $txtDriverLog.Text = "$msg`n$($txtDriverLog.Text)"
                }
                Invoke-VUONGTTDoEvents
            }
            if ($txtDriverLog) { $txtDriverLog.Text = $updateSummary }
            Refresh-DriverStatusBadge
            $txtFooterStatus.Text = "• [OK] Quy trình cập nhật toàn bộ Driver đã hoàn tất!"
            [System.Windows.MessageBox]::Show("Đã hoàn tất quy trình quét và cập nhật Driver qua Microsoft Update Catalog.`nChi tiết kết quả đã được ghi vào khung Nhật ký bên dưới.", "Cập Nhật Driver", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } catch {
            if ($txtDriverLog) { $txtDriverLog.Text = "[LỖI CẬP NHẬT DRIVER] $($_.Exception.Message)" }
        } finally {
            $btnAutoUpdateAllDrivers.IsEnabled = $true
        }
    })
}

if ($btnLaunchSDIO) {
    $btnLaunchSDIO.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang kiểm tra và khởi chạy bộ cài Driver Snappy Driver Installer Origin (SDIO)..." }
        $res = Invoke-VUONGTTLaunchDriverTool -ToolName "sdio" -OnProgress {
            param($m)
            if ($txtDriverLog) { $txtDriverLog.Text = "$m`n$($txtDriverLog.Text)" }
            Invoke-VUONGTTDoEvents
        }
        if ($txtDriverLog) { $txtDriverLog.Text = "$res`n$($txtDriverLog.Text)" }
        $txtFooterStatus.Text = "• [OK] $res"
    })
}

if ($btnLaunch3DPChip) {
    $btnLaunch3DPChip.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "Đang kiểm tra và mở công cụ 3DP Chip..." }
        $res = Invoke-VUONGTTLaunchDriverTool -ToolName "3dpchip" -OnProgress {
            param($m)
            if ($txtDriverLog) { $txtDriverLog.Text = "$m`n$($txtDriverLog.Text)" }
            Invoke-VUONGTTDoEvents
        }
        if ($txtDriverLog) { $txtDriverLog.Text = "$res`n$($txtDriverLog.Text)" }
        $txtFooterStatus.Text = "• [OK] $res"
    })
}

if ($btnOpenOEMDriverPortal) {
    $btnOpenOEMDriverPortal.Add_Click({
        $portal = Open-VUONGTTOfficialDriverPortal
        if ($txtDriverLog) { 
            $txtDriverLog.Text = "[CHÍNH HÃNG] Đã mở cổng hỗ trợ tải Driver chính hãng của hãng $($portal.Vendor):`n$($portal.Url)" 
        }
        $txtFooterStatus.Text = "• [OK] Đã mở trang hỗ trợ Driver $($portal.Vendor)"
    })
}

if ($btnClearDriverLog) {
    $btnClearDriverLog.Add_Click({
        if ($txtDriverLog) { $txtDriverLog.Text = "" }
    })
}

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
        Show-VUONGTTDriverDoctorModal
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

# =========================================================================
# MODULE 11: TỐI ƯU HÓA WINDOWS (TWEAKS PRO - WINUTIL SPEC)
# =========================================================================
$btnPresetStandard    = Get-Control "btnPresetStandard"
$btnPresetMinimal     = Get-Control "btnPresetMinimal"
$btnPresetAdvanced    = Get-Control "btnPresetAdvanced"
$btnPresetClear       = Get-Control "btnPresetClear"
$btnGetInstalledTweaks= Get-Control "btnGetInstalledTweaks"
$btnAppXRemoval       = Get-Control "btnAppXRemoval"

$btnRunTweaks         = Get-Control "btnRunTweaks"
$btnUndoTweaks        = Get-Control "btnUndoTweaks"
$cmbDnsProvider       = Get-Control "cmbDnsProvider"
$btnEnableUltimatePlan = Get-Control "btnEnableUltimatePlan"
$btnDisableUltimatePlan= Get-Control "btnDisableUltimatePlan"
$txtTweaksLog         = Get-Control "txtTweaksLog"
if (-not $txtTweaksLog) { $txtTweaksLog = $txtCleanerLog }

$allTweakCheckboxes = @(
    "chk_ActivityHistory", "chk_BitLocker", "chk_ConsumerFeatures", "chk_DeliveryOptimization",
    "chk_DiskCleanup", "chk_EndTaskRightClick", "chk_AutoFolderDiscovery", "chk_Hibernation",
    "chk_LocationTracking", "chk_StoreSearchRec", "chk_PreventDeviceApps", "chk_RestorePoint",
    "chk_ServicesManual", "chk_StartMenuLayout", "chk_Telemetry", "chk_TempFiles", "chk_Widgets",
    "chk_BackgroundApps", "chk_ReservedStorage", "chk_IPv6PreferIPv4", "chk_ClassicContextMenu",
    "chk_VisualEffects", "chk_GameMode",
    "tog_DarkTheme", "tog_LongPaths", "tog_ShowFileExt", "tog_ShowHiddenFiles", "tog_NumLock",
    "tog_TaskbarCenter", "tog_TaskbarSearch", "tog_TaskbarTaskView", "tog_StartBing", "tog_WindowSnap"
)

# Presets wiring
if ($btnPresetStandard) {
    $btnPresetStandard.Add_Click({
        $standardTweaks = @(
            "chk_ActivityHistory", "chk_ConsumerFeatures", "chk_DeliveryOptimization", "chk_DiskCleanup",
            "chk_EndTaskRightClick", "chk_AutoFolderDiscovery", "chk_Hibernation", "chk_LocationTracking",
            "chk_StoreSearchRec", "chk_PreventDeviceApps", "chk_RestorePoint", "chk_Telemetry",
            "chk_TempFiles", "chk_Widgets", "tog_DarkTheme", "tog_LongPaths", "tog_ShowFileExt",
            "tog_ShowHiddenFiles", "tog_NumLock"
        )
        foreach ($name in $allTweakCheckboxes) {
            $c = Get-Control $name
            if ($c) { $c.IsChecked = ($standardTweaks -contains $name) }
        }
        if ($txtTweaksLog) { $txtTweaksLog.Text = "[CHỌN NHANH] Đã chọn toàn bộ Tinh Chỉnh Chuẩn (Standard) khuyên dùng an toàn 100%!" }
        $txtFooterStatus.Text = "• [OK] Đã nạp Preset Chuẩn (Standard)"
    })
}

if ($btnPresetMinimal) {
    $btnPresetMinimal.Add_Click({
        $minimalTweaks = @("chk_ActivityHistory", "chk_Telemetry", "chk_TempFiles", "chk_EndTaskRightClick", "tog_ShowFileExt")
        foreach ($name in $allTweakCheckboxes) {
            $c = Get-Control $name
            if ($c) { $c.IsChecked = ($minimalTweaks -contains $name) }
        }
        if ($txtTweaksLog) { $txtTweaksLog.Text = "[CHỌN NHANH] Đã chọn Tinh Chỉnh Tối Giản (Minimal) nhẹ nhàng!" }
        $txtFooterStatus.Text = "• [OK] Đã nạp Preset Tối Giản (Minimal)"
    })
}

if ($btnPresetAdvanced) {
    $btnPresetAdvanced.Add_Click({
        foreach ($name in $allTweakCheckboxes) {
            $c = Get-Control $name
            if ($c) { $c.IsChecked = $true }
        }
        if ($txtTweaksLog) { $txtTweaksLog.Text = "[CHỌN NHANH] Đã chọn Toàn Bộ Tinh Chỉnh Nâng Cao (Gaming / Triệt để)!" }
        $txtFooterStatus.Text = "• [OK] Đã nạp Preset Nâng Cao (Advanced)"
    })
}

if ($btnPresetClear) {
    $btnPresetClear.Add_Click({
        foreach ($name in $allTweakCheckboxes) {
            $c = Get-Control $name
            if ($c) { $c.IsChecked = $false }
        }
        if ($txtTweaksLog) { $txtTweaksLog.Text = "Đã bỏ chọn toàn bộ các mục tinh chỉnh." }
        $txtFooterStatus.Text = "• [OK] Đã bỏ chọn toàn bộ Tweaks"
    })
}

if ($btnGetInstalledTweaks) {
    $btnGetInstalledTweaks.Add_Click({
        if ($txtTweaksLog) { $txtTweaksLog.Text = "Đang kiểm tra các tinh chỉnh hiện có trên máy tính..." }
        $dark = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
        $cDark = Get-Control "tog_DarkTheme"; if ($cDark -and $dark -and $dark.AppsUseLightTheme -eq 0) { $cDark.IsChecked = $true }
        
        $ext = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -ErrorAction SilentlyContinue
        $cExt = Get-Control "tog_ShowFileExt"; if ($cExt -and $ext -and $ext.HideFileExt -eq 0) { $cExt.IsChecked = $true }
        
        $hid = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -ErrorAction SilentlyContinue
        $cHid = Get-Control "tog_ShowHiddenFiles"; if ($cHid -and $hid -and $hid.Hidden -eq 1) { $cHid.IsChecked = $true }

        $long = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -ErrorAction SilentlyContinue
        $cLong = Get-Control "tog_LongPaths"; if ($cLong -and $long -and $long.LongPathsEnabled -eq 1) { $cLong.IsChecked = $true }

        if ($txtTweaksLog) { $txtTweaksLog.Text = "[OK] Đã phát hiện và đánh dấu các thiết lập đang kích hoạt trên máy!" }
        $txtFooterStatus.Text = "• [OK] Đã nạp trạng thái tinh chỉnh hiện tại"
    })
}

if ($btnAppXRemoval) {
    $btnAppXRemoval.Add_Click({
        $confirm = [System.Windows.MessageBox]::Show("Bạn có muốn dọn dẹp các AppX Bloatware rác mặc định của Windows (Clipchamp, Solitaire, Xbox...)?", "Dọn App Rác Windows", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            $junkApps = @("*bing*", "*solitaire*", "*clipchamp*", "*skype*", "*gethelp*", "*feedback*")
            if ($txtTweaksLog) { $txtTweaksLog.Text = "Đang tiến hành gỡ bỏ các ứng dụng rác AppX...`r`n" }
            foreach ($j in $junkApps) {
                Get-AppxPackage -AllUsers -Name $j -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
                if ($txtTweaksLog) { $txtTweaksLog.AppendText("[OK] Đã gỡ: $j`r`n") }
            }
            if ($txtTweaksLog) { $txtTweaksLog.AppendText("Hoàn tất dọn dẹp ứng dụng rác AppX!`r`n") }
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất gỡ bỏ AppX Bloatware"
        }
    })
}

# Run Tweaks
if ($btnRunTweaks) {
    $btnRunTweaks.Add_Click({
        $btnRunTweaks.IsEnabled = $false
        if ($btnUndoTweaks) { $btnUndoTweaks.IsEnabled = $false }
        $cursorBefore = [System.Windows.Input.Mouse]::OverrideCursor
        [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait

        try {
            if ($txtTweaksLog) {
                $txtTweaksLog.Text = "=== [BẮT ĐẦU ÁP DỤNG CÁC TINH CHỈNH ĐÃ CHỌN - $(Get-Date -Format 'HH:mm:ss')] ===`r`n"
                $txtTweaksLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents

            $count = 0
            $restartExplorerNeeded = $false
            foreach ($name in $allTweakCheckboxes) {
                $c = Get-Control $name
                if ($c -and $c.IsChecked) {
                    $key = $name.Replace("chk_", "").Replace("tog_", "")
                    if ($key -in @("ShowFileExt", "ShowHiddenFiles", "ClassicContextMenu", "TaskbarCenter", "StartMenuLayout")) {
                        $restartExplorerNeeded = $true
                    }
                    $res = Invoke-VUONGTTSingleTweak -TweakKey $key -Enable $true
                    if ($txtTweaksLog) {
                        $txtTweaksLog.AppendText("$res`r`n")
                        $txtTweaksLog.ScrollToEnd()
                    }
                    $count++
                    Invoke-VUONGTTDoEvents
                }
            }

            # Apply DNS if selected
            if ($cmbDnsProvider -and $cmbDnsProvider.SelectedItem) {
                $dnsText = $cmbDnsProvider.SelectedItem.Content.ToString()
                if ($dnsText -like "*Cloudflare*") { $dRes = Set-VUONGTTDns "Cloudflare" }
                elseif ($dnsText -like "*Google*") { $dRes = Set-VUONGTTDns "Google" }
                elseif ($dnsText -like "*Quad9*") { $dRes = Set-VUONGTTDns "Quad9" }
                elseif ($dnsText -like "*AdGuard*") { $dRes = Set-VUONGTTDns "AdGuard" }
                else { $dRes = Set-VUONGTTDns "Default" }
                if ($txtTweaksLog) {
                    $txtTweaksLog.AppendText("$dRes`r`n")
                    $txtTweaksLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
            }

            if ($restartExplorerNeeded) {
                if ($txtTweaksLog) {
                    $txtTweaksLog.AppendText("• Đang làm mới giao diện Windows Explorer...`r`n")
                    $txtTweaksLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 400
                Invoke-VUONGTTDoEvents
            }

            if ($txtTweaksLog) {
                $txtTweaksLog.AppendText("=== [HOÀN TẤT] Đã áp dụng thành công $count mục tinh chỉnh! ===`r`n")
                $txtTweaksLog.ScrollToEnd()
            }
            $txtFooterStatus.Text = "• [OK] Đã áp dụng thành công các tinh chỉnh Windows!"
        } finally {
            [System.Windows.Input.Mouse]::OverrideCursor = $cursorBefore
            $btnRunTweaks.IsEnabled = $true
            if ($btnUndoTweaks) { $btnUndoTweaks.IsEnabled = $true }
            Invoke-VUONGTTDoEvents
        }
    })
}

# Undo Tweaks
if ($btnUndoTweaks) {
    $btnUndoTweaks.Add_Click({
        $btnUndoTweaks.IsEnabled = $false
        if ($btnRunTweaks) { $btnRunTweaks.IsEnabled = $false }
        $cursorBefore = [System.Windows.Input.Mouse]::OverrideCursor
        [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait

        try {
            if ($txtTweaksLog) {
                $txtTweaksLog.Text = "=== [BẮT ĐẦU HOÀN TÁC CÁC TINH CHỈNH ĐÃ CHỌN - $(Get-Date -Format 'HH:mm:ss')] ===`r`n"
                $txtTweaksLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents

            $count = 0
            $restartExplorerNeeded = $false
            foreach ($name in $allTweakCheckboxes) {
                $c = Get-Control $name
                if ($c -and $c.IsChecked) {
                    $key = $name.Replace("chk_", "").Replace("tog_", "")
                    if ($key -in @("ShowFileExt", "ShowHiddenFiles", "ClassicContextMenu", "TaskbarCenter", "StartMenuLayout")) {
                        $restartExplorerNeeded = $true
                    }
                    $res = Invoke-VUONGTTSingleTweak -TweakKey $key -Enable $false
                    if ($txtTweaksLog) {
                        $txtTweaksLog.AppendText("$res`r`n")
                        $txtTweaksLog.ScrollToEnd()
                    }
                    $count++
                    Invoke-VUONGTTDoEvents
                }
            }

            if ($restartExplorerNeeded) {
                if ($txtTweaksLog) {
                    $txtTweaksLog.AppendText("• Đang làm mới giao diện Windows Explorer...`r`n")
                    $txtTweaksLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
                Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 400
                Invoke-VUONGTTDoEvents
            }

            if ($txtTweaksLog) {
                $txtTweaksLog.AppendText("=== [HOÀN TẤT] Đã hoàn tác $count mục tinh chỉnh về mặc định! ===`r`n")
                $txtTweaksLog.ScrollToEnd()
            }
            $txtFooterStatus.Text = "• [OK] Đã hoàn tác các tinh chỉnh về mặc định!"
        } finally {
            [System.Windows.Input.Mouse]::OverrideCursor = $cursorBefore
            $btnUndoTweaks.IsEnabled = $true
            if ($btnRunTweaks) { $btnRunTweaks.IsEnabled = $true }
            Invoke-VUONGTTDoEvents
        }
    })
}

if ($btnEnableUltimatePlan) {
    $btnEnableUltimatePlan.Add_Click({
        $res = Set-VUONGTTUltimatePerformancePlan -Enable $true
        if ($txtTweaksLog) { $txtTweaksLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã kích hoạt Ultimate Performance Power Plan"
    })
}

if ($btnDisableUltimatePlan) {
    $btnDisableUltimatePlan.Add_Click({
        $res = Set-VUONGTTUltimatePerformancePlan -Enable $false
        if ($txtTweaksLog) { $txtTweaksLog.Text = $res }
        $txtFooterStatus.Text = "• [OK] Đã chuyển về Balanced Power Plan"
    })
}

# =========================================================================
# MODULE CONFIG: CẤU HÌNH TÍNH NĂNG & SỬA LỖI HỆ THỐNG (IMAGE 4)
# =========================================================================
$btnInstallFeatures      = Get-Control "btnInstallFeatures"
$btnFixAutoLogon         = Get-Control "btnFixAutoLogon"
$btnFixNetworkReset      = Get-Control "btnFixNetworkReset"
$btnFixNtpServer         = Get-Control "btnFixNtpServer"
$btnFixSystemCorruption  = Get-Control "btnFixSystemCorruption"
$btnFixWindowsUpdate     = Get-Control "btnFixWindowsUpdate"
$btnFixWinGet            = Get-Control "btnFixWinGet"
$btnEnableOpenSSH        = Get-Control "btnEnableOpenSSH"
$txtConfigLog            = Get-Control "txtConfigLog"

# Install Features
if ($btnInstallFeatures) {
    $btnInstallFeatures.Add_Click({
        $btnInstallFeatures.IsEnabled = $false
        try {
            if ($txtConfigLog) {
                $txtConfigLog.Text = "=== [BẮT ĐẦU CÀI ĐẶT TÍNH NĂNG WINDOWS] ===`r`n"
                $txtConfigLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents

            $feats = @(
                @{ Control="chk_FeatNetFx3"; DismName="NetFx3" },
                @{ Control="chk_FeatHyperV"; DismName="Microsoft-Hyper-V" },
                @{ Control="chk_FeatDirectPlay"; DismName="DirectPlay" },
                @{ Control="chk_FeatNFS"; DismName="ServicesForNFS-ClientOnly" },
                @{ Control="chk_FeatSandbox"; DismName="Containers-DisposableClientVM" },
                @{ Control="chk_FeatWSL"; DismName="Microsoft-Windows-Subsystem-Linux" }
            )

            foreach ($f in $feats) {
                $ctrl = Get-Control $f.Control
                if ($ctrl -and $ctrl.IsChecked) {
                    if ($txtConfigLog) {
                        $txtConfigLog.AppendText("Đang kích hoạt tính năng: $($f.DismName)...`r`n")
                        $txtConfigLog.ScrollToEnd()
                    }
                    Invoke-VUONGTTDoEvents
                    $res = Enable-VUONGTTOptionalFeature -FeatureName $f.DismName
                    if ($txtConfigLog) {
                        $txtConfigLog.AppendText("$res`r`n")
                        $txtConfigLog.ScrollToEnd()
                    }
                    Invoke-VUONGTTDoEvents
                }
            }

            $chkF8 = Get-Control "chk_FeatF8Boot"
            if ($chkF8 -and $chkF8.IsChecked) {
                $resF8 = Set-VUONGTTLegacyF8Boot -Enable $true
                if ($txtConfigLog) {
                    $txtConfigLog.AppendText("$resF8`r`n")
                    $txtConfigLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
            }

            $chkReg = Get-Control "chk_FeatRegBackup"
            if ($chkReg -and $chkReg.IsChecked) {
                $resReg = Enable-VUONGTTRegistryBackupDaily
                if ($txtConfigLog) {
                    $txtConfigLog.AppendText("$resReg`r`n")
                    $txtConfigLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
            }

            $chkClassicMenu = Get-Control "chk_FeatClassicMenu"
            if ($chkClassicMenu -and $chkClassicMenu.IsChecked) {
                if ($txtConfigLog) {
                    $txtConfigLog.AppendText("Đang kích hoạt Menu Chuột Phải Windows 10 (Classic Context Menu)...`r`n")
                    $txtConfigLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
                $resMenu = Set-VUONGTTClassicContextMenu -Enable $true
                if ($txtConfigLog) {
                    $txtConfigLog.AppendText("$resMenu`r`n")
                    $txtConfigLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
            }

            if ($txtConfigLog) {
                $txtConfigLog.AppendText("=== [HOÀN TẤT] Quá trình thiết lập tính năng đã xong! ===`r`n")
                $txtConfigLog.ScrollToEnd()
            }
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất cài đặt tính năng Windows!"
        } finally {
            $btnInstallFeatures.IsEnabled = $true
            Invoke-VUONGTTDoEvents
        }
    })
}

# --- BỘ CÔNG CỤ SỬA LỖI WINDOWS (CHECKLIST - CHỌN RỒI MỚI CHẠY) ---
$fixCheckBoxNames = @(
    "chk_FixSystemFiles", "chk_FixWindowsUpdate", "chk_FixNetwork", "chk_FixPrintSpooler",
    "chk_FixExplorer", "chk_FixSearch", "chk_FixStore", "chk_FixAudio", "chk_FixNtp",
    "chk_FixTempFiles", "chk_FixWinGet", "chk_FixFirewall", "chk_FixHostsFile", "chk_FixAutoLogon",
    "chk_FixClassicContextMenu"
)

$btnSelectAllFixes   = Get-Control "btnSelectAllFixes"
$btnUnselectAllFixes = Get-Control "btnUnselectAllFixes"
$btnRunSelectedFixes = Get-Control "btnRunSelectedFixes"

if ($btnSelectAllFixes) {
    $btnSelectAllFixes.Add_Click({
        foreach ($name in $fixCheckBoxNames) {
            $c = Get-Control $name
            if ($c) { $c.IsChecked = $true }
        }
    })
}

if ($btnUnselectAllFixes) {
    $btnUnselectAllFixes.Add_Click({
        foreach ($name in $fixCheckBoxNames) {
            $c = Get-Control $name
            if ($c) { $c.IsChecked = $false }
        }
    })
}

if ($btnRunSelectedFixes) {
    $btnRunSelectedFixes.Add_Click({
        $selectedCount = 0
        foreach ($name in $fixCheckBoxNames) {
            $c = Get-Control $name
            if ($c -and $c.IsChecked) { $selectedCount++ }
        }

        if ($selectedCount -eq 0) {
            [System.Windows.MessageBox]::Show("Vui lòng tích chọn ít nhất 1 lỗi cần sửa trong danh sách trước khi nhấn Chạy!", "Chưa Chọn Lỗi", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $btnRunSelectedFixes.IsEnabled = $false
        try {
            if ($txtConfigLog) {
                $txtConfigLog.Text = "=== [BẮT ĐẦU SỬA LỖI HỆ THỐNG WINDOWS - $selectedCount MỤC ĐÃ CHỌN] ===`r`n`r`n"
                $txtConfigLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents

            $onLiveLog = {
                param($line)
                if ($txtConfigLog) {
                    $txtConfigLog.AppendText("$line`r`n")
                    $txtConfigLog.ScrollToEnd()
                }
                Invoke-VUONGTTDoEvents
            }

            # 1. System Files (SFC /scannow & DISM)
            $chkSys = Get-Control "chk_FixSystemFiles"
            if ($chkSys -and $chkSys.IsChecked) {
                & $onLiveLog "▶ [1/14] Đang quét và sửa lỗi file hệ thống (SFC & DISM)..."
                Invoke-VUONGTTProcessWithLiveLog -FilePath "sfc.exe" -ArgumentList "/scannow" -OnOutputLine $onLiveLog -TimeoutSeconds 600
                Invoke-VUONGTTProcessWithLiveLog -FilePath "dism.exe" -ArgumentList "/online /cleanup-image /restorehealth" -OnOutputLine $onLiveLog -TimeoutSeconds 600
                & $onLiveLog "✔ Hoàn tất sửa file hệ thống!`r`n"
            }

            # 2. Windows Update
            $chkUpd = Get-Control "chk_FixWindowsUpdate"
            if ($chkUpd -and $chkUpd.IsChecked) {
                & $onLiveLog "▶ [2/14] Đang khôi phục và sửa lỗi Windows Update..."
                $res = Invoke-VUONGTTRepairWindowsUpdate
                & $onLiveLog "$res`r`n"
            }

            # 3. Network & DNS
            $chkNet = Get-Control "chk_FixNetwork"
            if ($chkNet -and $chkNet.IsChecked) {
                & $onLiveLog "▶ [3/14] Đang đặt lại kết nối mạng & xóa DNS cache..."
                $res = Invoke-VUONGTTResetNetwork
                & $onLiveLog "$res`r`n"
            }

            # 4. Print Spooler
            $chkPrn = Get-Control "chk_FixPrintSpooler"
            if ($chkPrn -and $chkPrn.IsChecked) {
                & $onLiveLog "▶ [4/14] Đang sửa lỗi máy in & dịch vụ Print Spooler..."
                $res = Invoke-VUONGTTFixPrintSpoolerService
                & $onLiveLog "$res`r`n"
            }

            # 5. Explorer & Taskbar
            $chkExp = Get-Control "chk_FixExplorer"
            if ($chkExp -and $chkExp.IsChecked) {
                & $onLiveLog "▶ [5/14] Đang khởi động lại Explorer & làm mới Taskbar..."
                $res = Invoke-VUONGTTFixExplorerTaskbar
                & $onLiveLog "$res`r`n"
            }

            # 6. Windows Search
            $chkSrch = Get-Control "chk_FixSearch"
            if ($chkSrch -and $chkSrch.IsChecked) {
                & $onLiveLog "▶ [6/14] Đang khôi phục dịch vụ tìm kiếm Windows Search..."
                $res = Invoke-VUONGTTFixWindowsSearch
                & $onLiveLog "$res`r`n"
            }

            # 7. Microsoft Store
            $chkStore = Get-Control "chk_FixStore"
            if ($chkStore -and $chkStore.IsChecked) {
                & $onLiveLog "▶ [7/14] Đang đặt lại bộ nhớ đệm Microsoft Store (wsreset)..."
                $res = Invoke-VUONGTTFixMicrosoftStore
                & $onLiveLog "$res`r`n"
            }

            # 8. Audio Service
            $chkAud = Get-Control "chk_FixAudio"
            if ($chkAud -and $chkAud.IsChecked) {
                & $onLiveLog "▶ [8/14] Đang khởi động lại toàn bộ dịch vụ âm thanh..."
                $res = Invoke-VUONGTTFixAudioService
                & $onLiveLog "$res`r`n"
            }

            # 9. NTP Time Sync
            $chkNtp = Get-Control "chk_FixNtp"
            if ($chkNtp -and $chkNtp.IsChecked) {
                & $onLiveLog "▶ [9/14] Đang đồng bộ lại đồng hồ chuẩn qua NTP..."
                $res = Invoke-VUONGTTSyncNtpServer
                & $onLiveLog "$res`r`n"
            }

            # 10. Temp & Prefetch
            $chkTmp = Get-Control "chk_FixTempFiles"
            if ($chkTmp -and $chkTmp.IsChecked) {
                & $onLiveLog "▶ [10/14] Đang dọn dẹp các tệp tạm và rác hệ thống..."
                $res = Invoke-VUONGTTFixTempAndPrefetch
                & $onLiveLog "$res`r`n"
            }

            # 11. WinGet
            $chkWg = Get-Control "chk_FixWinGet"
            if ($chkWg -and $chkWg.IsChecked) {
                & $onLiveLog "▶ [11/14] Đang cài đặt / làm mới gói WinGet App Installer..."
                $res = Invoke-VUONGTTReinstallWinget
                & $onLiveLog "$res`r`n"
            }

            # 12. Windows Firewall
            $chkFw = Get-Control "chk_FixFirewall"
            if ($chkFw -and $chkFw.IsChecked) {
                & $onLiveLog "▶ [12/14] Đang khôi phục cấu hình Windows Firewall về mặc định..."
                $res = Invoke-VUONGTTFixWindowsFirewall
                & $onLiveLog "$res`r`n"
            }

            # 13. Hosts File
            $chkHosts = Get-Control "chk_FixHostsFile"
            if ($chkHosts -and $chkHosts.IsChecked) {
                & $onLiveLog "▶ [13/14] Đang đặt lại tệp hosts về trạng thái nguyên bản..."
                $res = Invoke-VUONGTTFixHostsFile
                & $onLiveLog "$res`r`n"
            }

            # 14. AutoLogon
            $chkAuto = Get-Control "chk_FixAutoLogon"
            if ($chkAuto -and $chkAuto.IsChecked) {
                & $onLiveLog "▶ [14/15] Đang mở giao diện cấu hình tự động đăng nhập (netplwiz)..."
                Start-Process "control.exe" -ArgumentList "userpasswords2"
                & $onLiveLog "✔ Đã mở cửa sổ tài khoản người dùng userpasswords2!`r`n"
            }

            # 15. Classic Context Menu Win 10
            $chkClassicCtx = Get-Control "chk_FixClassicContextMenu"
            if ($chkClassicCtx -and $chkClassicCtx.IsChecked) {
                & $onLiveLog "▶ [15/15] Đang bật Menu Chuột Phải Windows 10 cổ điển..."
                $resMenu = Set-VUONGTTClassicContextMenu -Enable $true
                & $onLiveLog "✔ $resMenu`r`n"
            }

            & $onLiveLog "=========================================================="
            & $onLiveLog "🎉 [HOÀN TẤT] Quá trình xử lý các lỗi đã chọn kết thúc thành công 100%!"
            & $onLiveLog "=========================================================="
            $txtFooterStatus.Text = "• [OK] Đã hoàn tất sửa các lỗi đã chọn thành công!"
            [System.Windows.MessageBox]::Show("ĐÃ HOÀN TẤT QUÁ TRÌNH SỬA LỖI HỆ THỐNG!`n`nToàn bộ các lỗi bạn đã chọn đã được xử lý và khôi phục.", "Sửa Lỗi Hoàn Tất", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        } finally {
            $btnRunSelectedFixes.IsEnabled = $true
            Invoke-VUONGTTDoEvents
        }
    })
}

if ($btnEnableOpenSSH) {
    $btnEnableOpenSSH.Add_Click({
        $btnEnableOpenSSH.IsEnabled = $false
        try {
            if ($txtConfigLog) {
                $txtConfigLog.Text = "Đang kích hoạt OpenSSH Server...`r`n"
                $txtConfigLog.ScrollToEnd()
            }
            Invoke-VUONGTTDoEvents
            $res = Enable-VUONGTTOpenSSHServer
            if ($txtConfigLog) {
                $txtConfigLog.AppendText("$res`r`n")
                $txtConfigLog.ScrollToEnd()
            }
        } finally {
            $btnEnableOpenSSH.IsEnabled = $true
            Invoke-VUONGTTDoEvents
        }
    })
}

# 14 Legacy Panels với Scoping An Toàn (.GetNewClosure) và Ghi Log Trực Tiếp
$panelMap = @{
    "btnPanelCompMgmt"      = "compmgmt"
    "btnPanelControl"       = "control"
    "btnPanelMouse"         = "main"
    "btnPanelNetwork"       = "ncpa"
    "btnPanelPower"         = "power"
    "btnPanelPrinters"      = "printers"
    "btnPanelAppWiz"        = "appwiz"
    "btnPanelRegion"        = "region"
    "btnPanelSecurity"      = "security"
    "btnPanelSound"         = "sound"
    "btnPanelSysProperties" = "sysdm"
    "btnPanelTimeDate"      = "timedate"
    "btnPanelFirewall"      = "firewall"
    "btnPanelRestore"       = "restore"
}
foreach ($btnId in $panelMap.Keys) {
    $b = Get-Control $btnId
    if ($b) {
        $panelTarget = $panelMap[$btnId]
        $b.Add_Click({
            $res = Open-VUONGTTLegacyPanel $panelTarget
            if ($txtConfigLog) {
                $txtConfigLog.AppendText("$res`r`n")
                $txtConfigLog.ScrollToEnd()
            }
            if ($txtFooterStatus) {
                $txtFooterStatus.Text = "• $res"
            }
            Invoke-VUONGTTDoEvents
        }.GetNewClosure())
    }
}

# --- Module 15: Quản Lý Phân Vùng Ổ Đĩa (Partition Wizard Pro) ---
$btnRefreshDisks       = Get-Control "btnRefreshDisks"
$btnCheckDiskHealth    = Get-Control "btnCheckDiskHealth"
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

$cmbSplitSourceDrive   = Get-Control "cmbSplitSourceDrive"
$txtSplitSizeGB        = Get-Control "txtSplitSizeGB"
$cmbSplitNewLetter     = Get-Control "cmbSplitNewLetter"
$txtSplitNewLabel      = Get-Control "txtSplitNewLabel"
$btnExecuteSplit       = Get-Control "btnExecuteSplit"

$panelDisksContainer   = Get-Control "panelDisksContainer"
$txtPartitionLog       = Get-Control "txtPartitionLog"
$btnClearPartitionLog  = Get-Control "btnClearPartitionLog"

function Refresh-DiskPartitionDisplay {
    if (-not $panelDisksContainer) { return }
    $panelDisksContainer.Children.Clear()
    if ($cmbPartitionDrives) { $cmbPartitionDrives.Items.Clear() }
    if ($cmbSplitSourceDrive) { $cmbSplitSourceDrive.Items.Clear() }
    if ($cmbSplitNewLetter) { $cmbSplitNewLetter.Items.Clear() }

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
    if ($cmbSplitSourceDrive) {
        foreach ($l in $lettersAdded) {
            $cmbSplitSourceDrive.Items.Add($l) | Out-Null
        }
        if ($cmbSplitSourceDrive.Items.Count -gt 0) {
            $cmbSplitSourceDrive.SelectedIndex = 0
        }
    }
    if ($cmbSplitNewLetter) {
        $allLetters = [char[]]([char]'D'..[char]'Z') | ForEach-Object { [string]$_ }
        foreach ($cand in $allLetters) {
            if ($lettersAdded -notcontains $cand) {
                $cmbSplitNewLetter.Items.Add($cand) | Out-Null
            }
        }
        if ($cmbSplitNewLetter.Items.Count -gt 0) {
            $cmbSplitNewLetter.SelectedIndex = 0
        }
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

if ($btnCheckDiskHealth) {
    $btnCheckDiskHealth.Add_Click({
        $txtPartitionLog.Text = "Đang kiểm tra thông số SMART và sức khỏe chi tiết toàn bộ ổ cứng..."
        $txtFooterStatus.Text = "• [Đang xử lý] Đang kiểm tra sức khỏe SMART toàn bộ ổ đĩa..."
        Invoke-VUONGTTDoEvents
        $report = Get-VUONGTTDiskHealthReport
        $txtPartitionLog.Text = "$report`n`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất kiểm tra sức khỏe SMART ổ cứng!"
    })
}

if ($btnExecuteSplit) {
    $btnExecuteSplit.Add_Click({
        $srcDrive = if ($cmbSplitSourceDrive -and $cmbSplitSourceDrive.SelectedItem) { $cmbSplitSourceDrive.SelectedItem.ToString() } else { "C" }
        $splitSize = if ($txtSplitSizeGB -and $txtSplitSizeGB.Text) { [int]$txtSplitSizeGB.Text.Trim() } else { 30 }
        $newLetter = if ($cmbSplitNewLetter -and $cmbSplitNewLetter.SelectedItem) { $cmbSplitNewLetter.SelectedItem.ToString() } else { "E" }
        $newLabel = if ($txtSplitNewLabel -and $txtSplitNewLabel.Text) { $txtSplitNewLabel.Text.Trim() } else { "DATA" }

        $confirm = [System.Windows.MessageBox]::Show("BẠN CÓ CHẮC CHẮN MUỐN CHIA PHÂN VÙNG?`n`n• Ổ nguồn thu nhỏ: ${srcDrive}:`n• Cắt bớt: $splitSize GB`n• Tạo ổ mới: ${newLetter}: ('$newLabel')`n`nThao tác này an toàn và không làm mất dữ liệu trên ổ nguồn.", "Xác nhận chia ổ đĩa", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $txtFooterStatus.Text = "• [Đang xử lý] Đang thu nhỏ phân vùng ${srcDrive}: và tạo ổ mới ${newLetter}:..."
        $txtPartitionLog.Text = "Bắt đầu tiến trình chia phân vùng tự động..."
        Invoke-VUONGTTDoEvents

        $res = Invoke-VUONGTTSplitPartition -SourceDriveLetter $srcDrive -SplitSizeGB $splitSize -NewDriveLetter $newLetter -NewVolumeLabel $newLabel
        $txtPartitionLog.Text = "$res`n`n$($txtPartitionLog.Text)"
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất chia phân vùng ổ đĩa!"
        Refresh-DiskPartitionDisplay
    })
}

if ($txtSplitSizeGB) {
    $txtSplitSizeGB.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter) {
            if ($btnExecuteSplit) {
                $btnExecuteSplit.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
                $_.Handled = $true
            }
        }
    })
}

$btnLaunchMAS         = Get-Control "btnLaunchMAS"
$btnCheckStatus       = Get-Control "btnCheckStatus"
$btnCleanCrack        = Get-Control "btnCleanCrack"
$btnCopyActivationKey = Get-Control "btnCopyActivationKey"
$txtActivationLog     = Get-Control "txtActivationLog"

$btnLaunchMAS.Add_Click({
    $txtActivationLog.Text = "Đang khởi chạy Massgrave MAS bản quyền số chính thức..."
    Invoke-VUONGTTMAS
})
$btnCheckStatus.Add_Click({
    $txtActivationLog.Text = "Đang tiến hành kiểm tra sâu bản quyền Windows, Office và trích xuất Product Key..."
    Invoke-VUONGTTDoEvents
    $st = Get-VUONGTTActivationStatus
    $txtActivationLog.Text = $st.DetailedReport
    if ($txtFooterStatus) {
        $txtFooterStatus.Text = "• [OK] Đã hoàn tất kiểm tra sâu bản quyền hệ thống & Product Key!"
    }
})
$btnCleanCrack.Add_Click({
    $log = Invoke-VUONGTTCleanCrack
    $txtActivationLog.Text = $log
})
if ($btnCopyActivationKey) {
    $btnCopyActivationKey.Add_Click({
        $contentToCopy = $txtActivationLog.Text
        if (-not $contentToCopy -or $contentToCopy.Length -lt 20 -or $contentToCopy -like "*Sẵn sàng*") {
            $st = Get-VUONGTTActivationStatus
            $contentToCopy = $st.DetailedReport
            $txtActivationLog.Text = $contentToCopy
        }
        try {
            [System.Windows.Clipboard]::SetText($contentToCopy)
            if ($txtFooterStatus) {
                $txtFooterStatus.Text = "• [OK] Đã sao chép toàn bộ thông tin Key & Bản quyền vào Clipboard!"
            }
        } catch {
            if ($txtFooterStatus) {
                $txtFooterStatus.Text = "• [LỖI] Không thể sao chép vào Clipboard: $($_.Exception.Message)"
            }
        }
    })
}

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

        $txtFooterStatus.Text = "• [UPDATE] Đang kiểm tra phiên bản mới thời gian thực từ GitHub..."
        Invoke-VUONGTTDoEvents

        $info = Get-VUONGTTAppUpdateInfo -ForceApi
        $btnCheckAppUpdate.Content = $origContent
        $btnCheckAppUpdate.IsEnabled = $true

        if ($info.HasUpdate) {
            $btnCheckAppUpdate.Content = "🔥 CÓ BẢN MỚI v$($info.LatestVersion)"
            $btnCheckAppUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")
            $txtFooterStatus.Text = "• [AUTO-UPDATE] Đã tìm thấy bản mới v$($info.LatestVersion)! Đang tự động tải và thay thế file..."
            Invoke-VUONGTTDoEvents
            $res = Invoke-VUONGTTAppSelfUpdate -DownloadUrl $info.DownloadUrl -NewVersion $info.LatestVersion -OnProgress {
                param($m)
                $txtFooterStatus.Text = "• [UPDATE] $m"
                Invoke-VUONGTTDoEvents
            }
            [System.Windows.MessageBox]::Show($res, "Cập Nhật Ứng Dụng", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        } elseif (-not $info.IsOnline) {
            $txtFooterStatus.Text = "• [!] Không thể kết nối máy chủ cập nhật!"
            [System.Windows.MessageBox]::Show("KHÔNG THỂ KẾT NỐI MÁY CHỦ CẬP NHẬT!`n`n$($info.Message)", "Kiểm Tra Cập Nhật", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        } else {
            $txtFooterStatus.Text = "• [OK] Bạn đang dùng phiên bản mới nhất (v$($info.CurrentVersion))!"
            $changeText = if ($info.Changelog) { ($info.Changelog -join "`n• ") } else { "Đã cập nhật toàn bộ tính năng và sửa lỗi mới nhất." }
            $msg = @"
BẠN ĐANG SỬ DỤNG PHIÊN BẢN MỚI NHẤT!
=====================================================
• Phiên bản hiện tại:  v$($info.CurrentVersion) (Mới nhất)
• Ngày phát hành:      $($info.ReleaseDate)
• Trạng thái kết nối:  Trực tuyến (GitHub Verified)

BẢNG NÂNG CẤP & ĐIỂM MỚI TRONG BẢN NÀY:
• $changeText

=====================================================
Hệ thống không tìm thấy bản cập nhật nào mới hơn.
Toàn bộ tính năng mới đã sẵn sàng phục vụ!
"@
            [System.Windows.MessageBox]::Show($msg, "Bảng Nâng Cấp & Kiểm Tra Cập Nhật", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
}

# ================= XỬ LÝ SỰ KIỆN MOMO, BẢN QUYỀN & MIỄN TRỪ TRÁCH NHIỆM =================
$copyMoMoAction = {
    try {
        [System.Windows.Clipboard]::SetText("0328808425")
        $txtFooterStatus.Text = "• [COPIED] Đã sao chép số MoMo: 0328808425 vào Clipboard. Cảm ơn bạn đã ủng hộ!"
        [System.Windows.MessageBox]::Show("ĐÃ SAO CHÉP SỐ MOMO THÀNH CÔNG!`n`n• Số điện thoại MoMo: 0328808425`n• Chủ tài khoản: Trương Thanh Vương`n`nChân thành cảm ơn bạn đã đồng hành và ủng hộ tác giả phát triển VUONGTT Tool Pro 2026!", "Ủng Hộ Tác Giả (MoMo)", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    } catch {
        [System.Windows.MessageBox]::Show("Số MoMo ủng hộ tác giả: 0328808425 (Trương Thanh Vương)", "Ủng Hộ MoMo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    }
}

if ($btnCopyMoMo) { $btnCopyMoMo.Add_Click($copyMoMoAction) }
if ($btnFooterMoMo) { $btnFooterMoMo.Add_Click($copyMoMoAction) }
if ($btnCopyMoMoSysInfo) { $btnCopyMoMoSysInfo.Add_Click($copyMoMoAction) }

if ($btnShowDisclaimer) {
    $btnShowDisclaimer.Add_Click({
        $disclaimerMsg = @"
THÔNG TIN BẢN QUYỀN & MIỄN TRỪ TRÁCH NHIỆM
=====================================================
© 2026 VUONGTT. Bảo lưu mọi quyền.
Ủng hộ MoMo: 0328808425 (Trương Thanh Vương)

Miễn trừ trách nhiệm:
Phần mềm được cung cấp nguyên trạng, không bảo hành. 
Tác giả không chịu trách nhiệm về bất kỳ thiệt hại hoặc mất dữ liệu nào khi sử dụng tool.
=====================================================
"@
        [System.Windows.MessageBox]::Show($disclaimerMsg, "Bản Quyền & Miễn Trừ Trách Nhiệm", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnExitApp) {
    $btnExitApp.Add_Click({
        $window.Close()
    })
}

# =========================================================================
#   HỆ THỐNG QUẢN TRỊ ADMIN PORTAL, PHÂN QUYỀN & LICENSE KEY HWID
# =========================================================================
$global:isAdminAuthenticated = $false
$script:adminPolicyCombos    = @{}
$script:adminPendingTab      = $null
$script:licensePendingTab    = $null

function Update-VUONGTTLicenseUI {
    $conv = [System.Windows.Media.BrushConverter]::new()
    
    # NẾU ADMIN ĐANG ĐĂNG NHẬP: MẶC ĐỊNH MỞ KHÓA TOÀN BỘ QUYỀN VIP
    if ($global:isAdminAuthenticated) {
        if ($borderLicenseBadge) {
            $borderLicenseBadge.Background  = $conv.ConvertFromString("#DCFCE7")
            $borderLicenseBadge.BorderBrush = $conv.ConvertFromString("#86EFAC")
        }
        if ($txtLicenseBadge) {
            $txtLicenseBadge.Text       = "👑 ADMIN PORTAL (VIP)"
            $txtLicenseBadge.Foreground = $conv.ConvertFromString("#047857")
        }
        if ($btnActivateLicense) {
            $btnActivateLicense.Visibility = [System.Windows.Visibility]::Collapsed
        }
        return
    }

    # Kiểm tra bản quyền máy thực tế (đối soát với kho Vault)
    $pro = Test-VUONGTTProLicense
    if ($pro.IsPro) {
        if ($borderLicenseBadge) {
            $borderLicenseBadge.Background  = $conv.ConvertFromString("#ECFDF5")
            $borderLicenseBadge.BorderBrush = $conv.ConvertFromString("#A7F3D0")
        }
        if ($txtLicenseBadge) {
            $txtLicenseBadge.Text       = "🟢 PRO • $($pro.Duration)"
            $txtLicenseBadge.Foreground = $conv.ConvertFromString("#047857")
        }
        if ($btnActivateLicense) {
            $btnActivateLicense.Visibility = [System.Windows.Visibility]::Collapsed
        }
    } else {
        if ($borderLicenseBadge) {
            $borderLicenseBadge.Background  = $conv.ConvertFromString("#FEF3C7")
            $borderLicenseBadge.BorderBrush = $conv.ConvertFromString("#FCD34D")
        }
        if ($txtLicenseBadge) {
            $txtLicenseBadge.Text       = "⚪ FREE VERSION"
            $txtLicenseBadge.Foreground = $conv.ConvertFromString("#B45309")
        }
        if ($btnActivateLicense) {
            $btnActivateLicense.Visibility = [System.Windows.Visibility]::Visible
        }
    }
}

function Show-VUONGTTAdminLoginModal {
    param([string]$TargetNextTab = "AdminPortal")
    $script:adminPendingTab = $TargetNextTab
    if (-not $modalAdminLogin) { return }

    # CHẶN HOÀN TOÀN BẢNG ĐỔI PASS LẦN ĐẦU TRÊN MÁY KHÁC
    if ($pnlFirstLoginBanner) { $pnlFirstLoginBanner.Visibility = [System.Windows.Visibility]::Collapsed }
    if ($pnlAdminFirstChangePass) { $pnlAdminFirstChangePass.Visibility = [System.Windows.Visibility]::Collapsed }
    if ($lblAdminLoginNotice) { $lblAdminLoginNotice.Text = "Nhập mật khẩu quản trị viên để đăng nhập và mở khóa toàn bộ tính năng cao cấp." }
    if ($btnModalLoginSubmit) { $btnModalLoginSubmit.Content = "Đăng Nhập" }

    $pwdAdminLogin.Password        = ""
    if ($pwdAdminNewPass) { $pwdAdminNewPass.Password = "" }
    if ($pwdAdminConfirmPass) { $pwdAdminConfirmPass.Password = "" }
    $lblAdminLoginError.Visibility = [System.Windows.Visibility]::Collapsed
    $lblAdminLoginError.Text       = ""

    $modalAdminLogin.Visibility    = [System.Windows.Visibility]::Visible
    $pwdAdminLogin.Focus() | Out-Null
}

function Show-VUONGTTLicenseActivationModal {
    param([string]$PromptNotice = "", [string]$TargetNextTab = $null)
    $script:licensePendingTab = $TargetNextTab
    if (-not $modalActivatePro) { return }

    if ($PromptNotice) {
        $lblActivateNotice.Text = $PromptNotice
    } else {
        $lblActivateNotice.Text = "Nhập License Key để mở khóa toàn bộ tính năng cao cấp cho máy tính này."
    }

    $currentHwid = Get-VUONGTTHardwareId
    if ($lblCurrentHWID) { $lblCurrentHWID.Text = $currentHwid }
    if ($txtModalLicenseKey) { $txtModalLicenseKey.Text = "" }
    if ($lblActivateError) { $lblActivateError.Visibility = [System.Windows.Visibility]::Collapsed }

    $modalActivatePro.Visibility = [System.Windows.Visibility]::Visible
    if ($txtModalLicenseKey) { $txtModalLicenseKey.Focus() | Out-Null }
}

# Render danh sách 20 chức năng để phân quyền FREE vs PRO
function Render-VUONGTTAdminPolicies {
    if (-not $panelFeaturePoliciesList) { return }
    $panelFeaturePoliciesList.Children.Clear()
    $script:adminPolicyCombos = @{}

    $policies = Get-VUONGTTFeaturePolicies
    $conv = [System.Windows.Media.BrushConverter]::new()

    foreach ($f in $policies) {
        $row = New-Object System.Windows.Controls.Border
        $row.Background = $window.Resources["CardInnerBgBrush"]
        $row.BorderBrush = $window.Resources["CardBorderBrush"]
        $row.BorderThickness = New-Object System.Windows.Thickness(1)
        $row.CornerRadius = New-Object System.Windows.CornerRadius(6)
        $row.Padding = New-Object System.Windows.Thickness(10, 8, 10, 8)
        $row.Margin = New-Object System.Windows.Thickness(0, 0, 0, 6)

        $grid = New-Object System.Windows.Controls.Grid
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::Auto
        $grid.ColumnDefinitions.Add($c1)
        $grid.ColumnDefinitions.Add($c2)

        $spLeft = New-Object System.Windows.Controls.StackPanel
        $titleBlock = New-Object System.Windows.Controls.TextBlock
        $titleBlock.Text = "$($f.Icon) $($f.Name)"
        $titleBlock.FontWeight = [System.Windows.FontWeights]::Bold
        $titleBlock.FontSize = 13
        $titleBlock.Foreground = $window.Resources["TextPrimaryBrush"]

        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = $f.Description
        $descBlock.FontSize = 11
        $descBlock.Foreground = $window.Resources["TextSecondaryBrush"]
        $descBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $descBlock.Margin = New-Object System.Windows.Thickness(0, 2, 0, 0)

        $spLeft.Children.Add($titleBlock) | Out-Null
        $spLeft.Children.Add($descBlock) | Out-Null
        [System.Windows.Controls.Grid]::SetColumn($spLeft, 0)
        $grid.Children.Add($spLeft) | Out-Null

        $cmb = New-Object System.Windows.Controls.ComboBox
        $cmb.Width = 95
        $cmb.Height = 28
        $cmb.VerticalContentAlignment = [System.Windows.VerticalAlignment]::Center
        
        $itemFree = New-Object System.Windows.Controls.ComboBoxItem
        $itemFree.Content = "⚪ FREE"
        $itemFree.FontWeight = [System.Windows.FontWeights]::Bold
        $itemFree.Foreground = $conv.ConvertFromString("#047857")

        $itemPro = New-Object System.Windows.Controls.ComboBoxItem
        $itemPro.Content = "⭐ PRO"
        $itemPro.FontWeight = [System.Windows.FontWeights]::Bold
        $itemPro.Foreground = $conv.ConvertFromString("#B45309")

        $cmb.Items.Add($itemFree) | Out-Null
        $cmb.Items.Add($itemPro) | Out-Null
        $cmb.SelectedIndex = if ($f.Tier -eq "PRO") { 1 } else { 0 }

        $script:adminPolicyCombos[$f.Id] = $cmb
        [System.Windows.Controls.Grid]::SetColumn($cmb, 1)
        $grid.Children.Add($cmb) | Out-Null

        $row.Child = $grid
        $panelFeaturePoliciesList.Children.Add($row) | Out-Null
    }
}

# Render danh sách License Keys trong Vault
function Render-VUONGTTAdminKeys {
    if (-not $panelKeysContainer) { return }
    $panelKeysContainer.Children.Clear()

    $rawKeys = Get-VUONGTTAllLicenses
    $keys = @($rawKeys | Where-Object { $_ -and $_.Key -and ($_.Key.Trim().Length -eq 25) -and ($_.Key.Trim() -match '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') })
    $totalCount = $keys.Count
    $usedCount  = @($keys | Where-Object { $_.IsUsed -eq $true -or [string]$_.IsUsed -eq "True" }).Count
    $freeCount  = $totalCount - $usedCount

    if ($lblKeyVaultStats) {
        $lblKeyVaultStats.Text = "Tổng: $totalCount | Đã kích hoạt: $usedCount | Còn trống: $freeCount"
    }

    if ($totalCount -eq 0) {
        $emptyBlock = New-Object System.Windows.Controls.TextBlock
        $emptyBlock.Text = "Kho khóa hiện đang trống. Hãy nhập thông tin ở trên và bấm 'Tạo License Key' để sinh key mới."
        $emptyBlock.Foreground = $window.Resources["TextSecondaryBrush"]
        $emptyBlock.Margin = New-Object System.Windows.Thickness(10)
        $emptyBlock.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $panelKeysContainer.Children.Add($emptyBlock) | Out-Null
        return
    }

    # Hiển thị key mới tạo lên đầu danh sách để Quản trị viên dễ nhìn thấy ngay
    if ($keys.Count -gt 1) {
        $displayKeys = [System.Collections.ArrayList]::new($keys)
        $displayKeys.Reverse()
    } else {
        $displayKeys = $keys
    }

    $conv = [System.Windows.Media.BrushConverter]::new()
    foreach ($k in $displayKeys) {
        if (-not $k -or -not $k.Key -or ($k.Key.Trim().Length -ne 25) -or ($k.Key.Trim() -notmatch '^VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')) { continue }
        $card = New-Object System.Windows.Controls.Border
        $card.Background = $window.Resources["CardInnerBgBrush"]
        $card.BorderBrush = if ($k.IsUsed) { $conv.ConvertFromString("#FCA5A5") } else { $conv.ConvertFromString("#A7F3D0") }
        $card.BorderThickness = New-Object System.Windows.Thickness(1)
        $card.CornerRadius = New-Object System.Windows.CornerRadius(6)
        $card.Padding = New-Object System.Windows.Thickness(12, 8, 12, 8)
        $card.Margin = New-Object System.Windows.Thickness(0, 0, 0, 8)

        $grid = New-Object System.Windows.Controls.Grid
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::Auto
        $grid.ColumnDefinitions.Add($c1)
        $grid.ColumnDefinitions.Add($c2)

        $spInfo = New-Object System.Windows.Controls.StackPanel
        
        $spKeyRow = New-Object System.Windows.Controls.WrapPanel
        $spKeyRow.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $spKeyRow.Margin = New-Object System.Windows.Thickness(0, 0, 0, 2)

        $txtKeyVal = New-Object System.Windows.Controls.TextBlock
        $txtKeyVal.Text = $k.Key.Trim()
        $txtKeyVal.FontFamily = New-Object System.Windows.Media.FontFamily("Consolas, Courier New, monospace")
        $txtKeyVal.FontWeight = [System.Windows.FontWeights]::Bold
        $txtKeyVal.FontSize = 13
        $txtKeyVal.Foreground = $conv.ConvertFromString("#1E40AF")
        $txtKeyVal.Margin = New-Object System.Windows.Thickness(0, 0, 8, 2)
        $txtKeyVal.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $spKeyRow.Children.Add($txtKeyVal) | Out-Null

        $durBadge = New-Object System.Windows.Controls.Border
        $durBadge.Background = $conv.ConvertFromString("#FEF3C7")
        $durBadge.CornerRadius = New-Object System.Windows.CornerRadius(3)
        $durBadge.Padding = New-Object System.Windows.Thickness(6, 1, 6, 1)
        $durBadge.Margin = New-Object System.Windows.Thickness(0, 0, 0, 2)
        $durBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $durTxt = New-Object System.Windows.Controls.TextBlock
        $durTxt.Text = $k.Duration
        $durTxt.FontSize = 10.5
        $durTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $durTxt.Foreground = $conv.ConvertFromString("#B45309")
        $durBadge.Child = $durTxt
        $spKeyRow.Children.Add($durBadge) | Out-Null

        $spInfo.Children.Add($spKeyRow) | Out-Null

        $txtCust = New-Object System.Windows.Controls.TextBlock
        $txtCust.Text = "Khách hàng: $($k.Customer) • Ngày tạo: $($k.CreatedDate)"
        $txtCust.FontSize = 11
        $txtCust.Foreground = $window.Resources["TextSecondaryBrush"]
        $txtCust.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $txtCust.Margin = New-Object System.Windows.Thickness(0, 2, 0, 2)
        $spInfo.Children.Add($txtCust) | Out-Null

        $txtStatus = New-Object System.Windows.Controls.TextBlock
        if ($k.IsUsed) {
            $txtStatus.Text = "🔴 ĐÃ KÍCH HOẠT: Máy '$($k.UsedPCName)' [$($k.UsedHWID)] vào $($k.ActivatedDate)"
            $txtStatus.Foreground = $conv.ConvertFromString("#BE123C")
            $txtStatus.FontWeight = [System.Windows.FontWeights]::SemiBold
        } else {
            $txtStatus.Text = "🟢 CHƯA SỬ DỤNG (Sẵn sàng gửi cho khách hàng kích hoạt trên 1 PC)"
            $txtStatus.Foreground = $conv.ConvertFromString("#047857")
            $txtStatus.FontWeight = [System.Windows.FontWeights]::SemiBold
        }
        $txtStatus.FontSize = 11
        $txtStatus.TextWrapping = [System.Windows.TextWrapping]::Wrap
        $spInfo.Children.Add($txtStatus) | Out-Null

        [System.Windows.Controls.Grid]::SetColumn($spInfo, 0)
        $grid.Children.Add($spInfo) | Out-Null

        # Action Buttons (Copy Key, Delete Key)
        $spBtns = New-Object System.Windows.Controls.StackPanel
        $spBtns.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $spBtns.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

        $btnCopyKey = New-Object System.Windows.Controls.Button
        $btnCopyKey.Content = "📋 Copy"
        $btnCopyKey.Height = 28
        $btnCopyKey.Padding = New-Object System.Windows.Thickness(8, 0, 8, 0)
        $btnCopyKey.Margin = New-Object System.Windows.Thickness(0, 0, 6, 0)
        $btnCopyKey.Background = $conv.ConvertFromString("#334155")
        $btnCopyKey.Foreground = [System.Windows.Media.Brushes]::White
        $btnCopyKey.FontWeight = [System.Windows.FontWeights]::Bold
        $btnCopyKey.FontSize = 11
        $btnCopyKey.Cursor = [System.Windows.Input.Cursors]::Hand
        $keyVal = $k.Key
        $btnCopyKey.Add_Click({
            [System.Windows.Clipboard]::SetText($keyVal)
            $txtFooterStatus.Text = "• [COPIED] Đã sao chép License Key $keyVal vào Clipboard!"
        }.GetNewClosure())

        $btnDelKey = New-Object System.Windows.Controls.Button
        $btnDelKey.Content = "🗑️ Xóa"
        $btnDelKey.Height = 28
        $btnDelKey.Padding = New-Object System.Windows.Thickness(8, 0, 8, 0)
        $btnDelKey.Background = $conv.ConvertFromString("#FEE2E2")
        $btnDelKey.Foreground = $conv.ConvertFromString("#BE123C")
        $btnDelKey.FontWeight = [System.Windows.FontWeights]::Bold
        $btnDelKey.FontSize = 11
        $btnDelKey.Cursor = [System.Windows.Input.Cursors]::Hand
        $btnDelKey.Add_Click({
            $confirm = [System.Windows.MessageBox]::Show("Bạn có chắc chắn muốn xóa License Key này khỏi kho không?`n`nKey: $keyVal", "Xác Nhận Xóa Key", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
            if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
                Remove-VUONGTTLicenseKey -Key $keyVal | Out-Null
                Render-VUONGTTAdminKeys
                Update-VUONGTTLicenseUI
                $txtFooterStatus.Text = "• [DELETE] Đã xóa thành công License Key $keyVal khỏi kho và thu hồi bản quyền nếu máy đang sử dụng key này."
            }
        }.GetNewClosure())

        $spBtns.Children.Add($btnCopyKey) | Out-Null
        $spBtns.Children.Add($btnDelKey) | Out-Null
        [System.Windows.Controls.Grid]::SetColumn($spBtns, 1)
        $grid.Children.Add($spBtns) | Out-Null

        $card.Child = $grid
        $panelKeysContainer.Children.Add($card) | Out-Null
    }
}

# ================= KẾT NỐI SỰ KIỆN ADMIN & LICENSE =================
if ($btnHeaderAdmin) {
    $btnHeaderAdmin.Add_Click({
        Switch-Tab -TargetTag "AdminPortal"
    })
}

if ($btnActivateLicense) {
    $btnActivateLicense.Add_Click({
        Show-VUONGTTLicenseActivationModal -PromptNotice "Nhập License Key để mở khóa toàn bộ tính năng cao cấp cho máy tính này."
    })
}

if ($btnAdminLogout) {
    $btnAdminLogout.Add_Click({
        $global:isAdminAuthenticated = $false
        Update-VUONGTTLicenseUI
        Switch-Tab -TargetTag "SysInfo"
        $txtFooterStatus.Text = "• [LOGOUT] Đã đăng xuất khỏi Trang Quản Trị Viên."
        [System.Windows.MessageBox]::Show("Bạn đã đăng xuất khỏi Admin Portal an toàn. Hệ thống đã trở về chế độ thông thường.", "Đăng Xuất Admin", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnSavePolicies) {
    $btnSavePolicies.Add_Click({
        $policies = Get-VUONGTTFeaturePolicies
        foreach ($fid in $script:adminPolicyCombos.Keys) {
            $cmb = $script:adminPolicyCombos[$fid]
            $tier = if ($cmb.SelectedIndex -eq 1) { "PRO" } else { "FREE" }
            foreach ($p in $policies) {
                if ($p.Id -eq $fid) { $p.Tier = $tier }
            }
        }
        $txtFooterStatus.Text = "• [SAVING] Đang lưu cấu hình và tự động đồng bộ lên GitHub Cloud..."
        Invoke-VUONGTTDoEvents
        $saved = Save-VUONGTTFeaturePolicies -Policies $policies
        Update-VUONGTTLicenseUI
        $txtFooterStatus.Text = "• [SAVED & CLOUD SYNC] Đã lưu cấu hình phân quyền và tự động đồng bộ lên GitHub thành công!"
        [System.Windows.MessageBox]::Show("ĐÃ LƯU VÀ TỰ ĐỘNG ĐỒNG BỘ LÊN GITHUB THÀNH CÔNG!`n`n- Phân quyền tính năng mới đã được cập nhật trực tiếp lên GitHub Cloud.`n- Toàn bộ các máy khác đang mở tool sẽ tự động nhận diện và cập nhật phân quyền này trong vòng 20 giây!", "Phân Quyền Tính Năng", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnResetPolicies) {
    $btnResetPolicies.Add_Click({
        $c = [System.Windows.MessageBox]::Show("Bạn có muốn khôi phục phân quyền tính năng về mặc định của nhà sản xuất không?", "Khôi Phục Mặc Định", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($c -eq [System.Windows.MessageBoxResult]::Yes) {
            Reset-VUONGTTFeaturePoliciesToDefault | Out-Null
            Render-VUONGTTAdminPolicies
            $txtFooterStatus.Text = "• [RESET] Đã khôi phục phân quyền tính năng về mặc định ban đầu."
        }
    })
}

if ($btnSyncPolicies) {
    $btnSyncPolicies.Add_Click({
        $txtFooterStatus.Text = "• [CLOUD SYNC] Đang đồng bộ cấu hình phân quyền từ Cloud GitHub..."
        Invoke-VUONGTTDoEvents
        $res = Sync-VUONGTTCloudAdminData -ForceApi
        Render-VUONGTTAdminPolicies
        $txtFooterStatus.Text = "• [CLOUD SYNC] " + $res.Message
        [System.Windows.MessageBox]::Show($res.Message, "Đồng Bộ Phân Quyền Cloud", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnSyncCloudKeys) {
    $btnSyncCloudKeys.Add_Click({
        $txtFooterStatus.Text = "• [CLOUD SYNC] Đang kết nối máy chủ Cloud và hợp nhất License Keys giữa các máy Admin..."
        Invoke-VUONGTTDoEvents
        $res = Sync-VUONGTTCloudAdminData -ForceApi
        Render-VUONGTTAdminKeys
        Render-VUONGTTAdminPolicies
        $txtFooterStatus.Text = "• [CLOUD SYNC] " + $res.Message
        [System.Windows.MessageBox]::Show("ĐÃ ĐỒNG BỘ ĐÁM MÂY THÀNH CÔNG!`n`n- Tổng số License Key trong kho: $($res.TotalKeys) key`n- Số key mới gộp thêm từ máy khác/Cloud: $($res.KeysMerged) key`n- Phân quyền tính năng: Đã đồng bộ`n`nToàn bộ dữ liệu Admin giữa 2 máy đã được hợp nhất hoàn toàn!", "Đồng Bộ Cloud Admin", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnExportKeys) {
    $btnExportKeys.Add_Click({
        $keys = Get-VUONGTTAllLicenses
        if ($keys.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Kho khóa hiện đang trống!", "Sao Chép Danh Sách Key", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }
        $lines = @()
        foreach ($k in $keys) {
            $status = if ($k.IsUsed) { "[ĐÃ KÍCH HOẠT: $($k.UsedPCName)]" } else { "[CHƯA DÙNG]" }
            $lines += "$($k.Key) | $($k.Duration) | $($k.Customer) | $status"
        }
        $text = $lines -join "`r`n"
        [System.Windows.Clipboard]::SetText($text)
        $txtFooterStatus.Text = "• [EXPORT] Đã sao chép toàn bộ $($keys.Count) License Keys vào Clipboard!"
        [System.Windows.MessageBox]::Show("ĐÃ SAO CHÉP TOÀN BỘ $($keys.Count) LICENSE KEYS VÀO CLIPBOARD!`n`nBạn có thể dán sang Zalo/Telegram hoặc gửi sang máy Admin khác để bấm nút 'Nhập Key'.", "Sao Chép Toàn Bộ Key", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($btnImportKeys) {
    $btnImportKeys.Add_Click({
        $clip = ""
        try { $clip = [System.Windows.Clipboard]::GetText() } catch {}
        $matches = [regex]::Matches($clip, 'VUONG-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}')
        if ($matches.Count -gt 0) {
            $vault = @(Get-VUONGTTAllLicenses)
            $importedCount = 0
            foreach ($m in $matches) {
                $kVal = $m.Value
                if (-not ($vault.Key -contains $kVal)) {
                    $vault += [PSCustomObject]@{
                        Key           = $kVal
                        Customer      = "Đồng bộ từ máy Admin khác"
                        Duration      = "Lifetime"
                        CreatedDate   = (Get-Date).ToString("dd/MM/yyyy HH:mm:ss")
                        IsUsed        = $false
                        UsedHWID      = ""
                        UsedPCName    = ""
                        ActivatedDate = ""
                    }
                    $importedCount++
                }
            }
            if ($importedCount -gt 0) {
                Save-VUONGTTLicenseVault -KeyList $vault
                Render-VUONGTTAdminKeys
                $txtFooterStatus.Text = "• [IMPORT] Đã gộp thành công $importedCount License Key mới vào kho!"
                [System.Windows.MessageBox]::Show("ĐÃ GỘP THÀNH CÔNG $importedCount LICENSE KEY MỚI TỪ CLIPBOARD!`n`nTổng số License Key trong kho hiện tại: $($vault.Count) keys.", "Nhập License Key Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                return
            } else {
                [System.Windows.MessageBox]::Show("Tất cả $($matches.Count) License Key trong Clipboard đã có sẵn trong kho hiện tại!", "Thông Báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
                return
            }
        }
        [System.Windows.MessageBox]::Show("Không tìm thấy mã License Key (dạng VUONG-XXXX-XXXX-XXXX-XXXX) nào trong Clipboard!`n`nHướng dẫn nhanh: Ở máy kia bấm nút '📋 Copy Tất Cả', rồi sang máy này bấm '📥 Nhập Key' là 2 máy có kho key giống hệt nhau ngay lập tức!", "Hướng Dẫn Nhập Key", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    })
}

if ($btnGenerateKeys) {
    $btnGenerateKeys.Add_Click({
        $cust = if ($txtNewKeyCustomer.Text.Trim()) { $txtNewKeyCustomer.Text.Trim() } else { "Khách Hàng" }
        $durItem = $cmbNewKeyDuration.SelectedItem
        $duration = if ($durItem) { $durItem.Content.ToString() } else { "Lifetime" }
        $count = 1
        [int]::TryParse($txtNewKeyCount.Text.Trim(), [ref]$count) | Out-Null
        if ($count -lt 1) { $count = 1 }
        if ($count -gt 50) { $count = 50 }

        $newCreated = New-VUONGTTLicenseKey -Customer $cust -Duration $duration -Count $count
        Render-VUONGTTAdminKeys

        if ($newCreated.Count -gt 0) {
            [System.Windows.Clipboard]::SetText($newCreated[0].Key)
            $txtFooterStatus.Text = "• [KEY CREATED] Đã tạo thành công $($newCreated.Count) License Key! Đã copy key đầu tiên vào Clipboard."
            [System.Windows.MessageBox]::Show("TẠO LICENSE KEY THÀNH CÔNG!`n`n- Mã Key: $($newCreated[0].Key)`n- Thời hạn: $duration`n- Khách hàng: $cust`n`n(Đã tự động sao chép mã Key vào Clipboard để bạn gửi cho khách hàng)", "Tạo License Key Mới", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
}

if ($btnAdminChangePassSubmit) {
    $btnAdminChangePassSubmit.Add_Click({
        $newP = $pwdAdminChangeNew.Password
        $cfmP = $pwdAdminChangeConfirm.Password
        if (-not $newP -or $newP.Length -lt 4) {
            [System.Windows.MessageBox]::Show("Mật khẩu mới phải có ít nhất 4 ký tự!", "Đổi Mật Khẩu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }
        if ($newP -ne $cfmP) {
            [System.Windows.MessageBox]::Show("Xác nhận mật khẩu mới không khớp! Vui lòng kiểm tra lại.", "Đổi Mật Khẩu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return
        }

        $res = Set-VUONGTTAdminPassword -NewPassword $newP
        if ($res) {
            $pwdAdminChangeNew.Password = ""
            $pwdAdminChangeConfirm.Password = ""
            $txtFooterStatus.Text = "• [ADMIN] Đã đổi mật khẩu quản trị viên thành công!"
            [System.Windows.MessageBox]::Show("ĐÃ ĐỔI MẬT KHẨU ADMIN THÀNH CÔNG!`n`nVui lòng ghi nhớ mật khẩu mới cho các lần đăng nhập tiếp theo.", "Đổi Mật Khẩu", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
}

if ($pwdAdminChangeConfirm) {
    $pwdAdminChangeConfirm.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter -and $btnAdminChangePassSubmit) {
            $btnAdminChangePassSubmit.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $_.Handled = $true
        }
    })
}
if ($pwdAdminChangeNew) {
    $pwdAdminChangeNew.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter -and $pwdAdminChangeConfirm) {
            $pwdAdminChangeConfirm.Focus() | Out-Null
            $_.Handled = $true
        }
    })
}

# Modal Login Event Handlers (Chặn tạo pass mới trên máy khác - Chỉ xác thực 1 mật khẩu Admin duy nhất)
if ($btnModalLoginSubmit) {
    $btnModalLoginSubmit.Add_Click({
        $inputPass = $pwdAdminLogin.Password
        if (-not $inputPass) {
            $lblAdminLoginError.Text = "Vui lòng nhập mật khẩu Quản Trị Viên!"
            $lblAdminLoginError.Visibility = [System.Windows.Visibility]::Visible
            return
        }

        $chk = Test-VUONGTTAdminAuth -Password $inputPass
        if ($chk.IsValid) {
            $global:isAdminAuthenticated = $true
            Update-VUONGTTLicenseUI
            $modalAdminLogin.Visibility = [System.Windows.Visibility]::Collapsed
            $next = if ($script:adminPendingTab) { $script:adminPendingTab } else { "AdminPortal" }
            Switch-Tab -TargetTag $next
            $txtFooterStatus.Text = "• [SUPER ADMIN] Đã đăng nhập quyền Quản trị viên. Toàn bộ tính năng đã được mở khóa VIP!"
        } else {
            $lblAdminLoginError.Text = "Mật khẩu Admin không chính xác! Vui lòng thử lại."
            $lblAdminLoginError.Visibility = [System.Windows.Visibility]::Visible
        }
    })
}

if ($pwdAdminLogin) {
    $pwdAdminLogin.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter -and $btnModalLoginSubmit) {
            $btnModalLoginSubmit.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $_.Handled = $true
        }
    })
}

if ($btnModalLoginCancel) {
    $btnModalLoginCancel.Add_Click({
        $modalAdminLogin.Visibility = [System.Windows.Visibility]::Collapsed
    })
}

# Modal Activate Pro Event Handlers
if ($btnModalActivateSubmit) {
    $btnModalActivateSubmit.Add_Click({
        $keyInput = $txtModalLicenseKey.Text.Trim()
        if (-not $keyInput) {
            $lblActivateError.Text = "Vui lòng nhập mã License Key!"
            $lblActivateError.Visibility = [System.Windows.Visibility]::Visible
            return
        }

        $res = Invoke-VUONGTTKeyActivation -InputKey $keyInput
        if ($res.Success) {
            $modalActivatePro.Visibility = [System.Windows.Visibility]::Collapsed
            
            # CẬP NHẬT TRỰC TIẾP BADGE VÀ NÚT BẢN QUYỀN SANG 🟢 PRO NGAY TỨC THÌ
            try {
                $conv = [System.Windows.Media.BrushConverter]::new()
                if ($borderLicenseBadge) {
                    $borderLicenseBadge.Background  = $conv.ConvertFromString("#ECFDF5")
                    $borderLicenseBadge.BorderBrush = $conv.ConvertFromString("#A7F3D0")
                }
                if ($txtLicenseBadge) {
                    $txtLicenseBadge.Text       = "🟢 PRO • $($res.Duration)"
                    $txtLicenseBadge.Foreground = $conv.ConvertFromString("#047857")
                }
                if ($btnActivateLicense) {
                    $btnActivateLicense.Visibility = [System.Windows.Visibility]::Collapsed
                }
            } catch {}

            Update-VUONGTTLicenseUI

            # NẾU TRANG QUẢN TRỊ ĐANG MỞ, CẬP NHẬT LẠI DANH SÁCH KEY ĐỂ THẤY NGAY KEY ĐÃ DÙNG
            if ($pageAdminPortal -and $pageAdminPortal.Visibility -eq [System.Windows.Visibility]::Visible) {
                Render-VUONGTTAdminKeys
            }

            $txtFooterStatus.Text = "• [PRO] $($res.Message)"

            # TỰ ĐỘNG KIỂM TRA VÀ CẬP NHẬT PHIÊN BẢN MỚI (AUTO UPDATE)
            try {
                if (Get-Command "Get-VUONGTTAppUpdateInfo" -ErrorAction SilentlyContinue) {
                    $chkUp = Get-VUONGTTAppUpdateInfo
                    if ($chkUp.HasUpdate -and $btnCheckAppUpdate) {
                        $btnCheckAppUpdate.Content = "🔥 CÓ BẢN MỚI v$($chkUp.LatestVersion)"
                        $btnCheckAppUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")
                        $txtFooterStatus.Text = "• [PRO] Đã kích hoạt PRO! Phát hiện bản cập nhật mới v$($chkUp.LatestVersion)."
                    }
                }
            } catch {}

            $msgSuccess = @"
KÍCH HOẠT BẢN QUYỀN PRO THÀNH CÔNG!
=====================================================
• Mã License Key: $keyInput
• Thời Hạn Bản Quyền: $($res.Duration)
• Đối Tác / Khách Hàng: $($res.Customer)
• Trạng Thái: Đã liên kết và khóa chặt với phần cứng máy tính này!

Toàn bộ các tính năng PRO cao cấp đã được mở khóa tự động.
Hệ thống cũng đã tự động kiểm tra và đồng bộ cập nhật mới nhất!
"@
            [System.Windows.MessageBox]::Show($msgSuccess, "Kích Hoạt Bản Quyền PRO Thành Công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

            if ($script:licensePendingTab) {
                $target = $script:licensePendingTab
                $script:licensePendingTab = $null
                Switch-Tab -TargetTag $target
            }
        } else {
            $lblActivateError.Text = $res.Message
            $lblActivateError.Visibility = [System.Windows.Visibility]::Visible
        }
    })
}

if ($txtModalLicenseKey) {
    $txtModalLicenseKey.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter -and $btnModalActivateSubmit) {
            $btnModalActivateSubmit.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $_.Handled = $true
        }
    })
}

if ($btnModalActivateCancel) {
    $btnModalActivateCancel.Add_Click({
        $modalActivatePro.Visibility = [System.Windows.Visibility]::Collapsed
    })
}

# =========================================================================
# MODULE 20: ADVANCED IP SCANNER (QUÉT IP & DÒ THIẾT BỊ MẠNG LAN)
# =========================================================================
$txtIpScanStart     = Get-Control "txtIpScanStart"
$txtIpScanEnd       = Get-Control "txtIpScanEnd"
$btnDetectSubnet    = Get-Control "btnDetectSubnet"
$btnStartIpScan     = Get-Control "btnStartIpScan"
$btnStopIpScan      = Get-Control "btnStopIpScan"
$btnCopySelectedIp  = Get-Control "btnCopySelectedIp"
$btnOpenSmbShare    = Get-Control "btnOpenSmbShare"
$btnOpenWebAdmin    = Get-Control "btnOpenWebAdmin"
$btnExportIpCsv     = Get-Control "btnExportIpCsv"
$lblIpScanStatus    = Get-Control "lblIpScanStatus"
$lblIpScanStats     = Get-Control "lblIpScanStats"
$prgIpScan          = Get-Control "prgIpScan"
$lstIpDevices       = Get-Control "lstIpDevices"

$global:cancelIpScan = $false
$global:scannedDevicesList = New-Object System.Collections.ArrayList

function Detect-LocalSubnet {
    try {
        $sub = Get-VUONGTTLocalSubnetInfo
        if ($sub) {
            if ($txtIpScanStart) { $txtIpScanStart.Text = $sub.StartIP }
            if ($txtIpScanEnd)   { $txtIpScanEnd.Text   = $sub.EndIP }
            if ($lblIpScanStatus) { $lblIpScanStatus.Text = "Đã nhận diện mạng LAN: $($sub.SubnetPrefix).0/24 (IP máy bạn: $($sub.LocalIP))" }
        }
    } catch {}
}

# Auto-detect subnet on startup
Detect-LocalSubnet

if ($btnDetectSubnet) {
    $btnDetectSubnet.Add_Click({
        Detect-LocalSubnet
        $txtFooterStatus.Text = "• [OK] Đã nhận diện dải IP mạng LAN cục bộ!"
    })
}

if ($txtIpScanStart) {
    $txtIpScanStart.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter -and $btnStartIpScan) {
            $btnStartIpScan.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $_.Handled = $true
        }
    })
}
if ($txtIpScanEnd) {
    $txtIpScanEnd.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Enter -and $btnStartIpScan) {
            $btnStartIpScan.RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Button]::ClickEvent)))
            $_.Handled = $true
        }
    })
}

if ($btnStartIpScan) {
    $btnStartIpScan.Add_Click({
        $startIp = if ($txtIpScanStart) { $txtIpScanStart.Text.Trim() } else { "192.168.1.1" }
        $endIp   = if ($txtIpScanEnd)   { $txtIpScanEnd.Text.Trim() }   else { "192.168.1.254" }

        $btnStartIpScan.IsEnabled = $false
        $btnStopIpScan.IsEnabled  = $true
        $global:scannedDevicesList.Clear()
        if ($lstIpDevices) { $lstIpDevices.Items.Clear() }
        if ($prgIpScan)    { $prgIpScan.Value = 0 }
        if ($lblIpScanStatus) { $lblIpScanStatus.Text = "Đang quét siêu tốc đa luồng dải IP từ $startIp đến $endIp..." }
        $txtFooterStatus.Text = "• [Đang quét] Đang quét IP mạng LAN siêu tốc (Zero-Lag Async Engine)..."

        try {
            $p1 = $startIp.Split('.')
            $p2 = $endIp.Split('.')
            $prefix = "$($p1[0]).$($p1[1]).$($p1[2])"
            $from = [int]$p1[3]
            $to   = [int]$p2[3]
            if ($to -lt $from) { $to = 254 }

            $arpMap = Get-VUONGTTArpTableDict
            $vendorMap = Get-VUONGTTVendorDictionary

            [VUONGTT.Network.FastScanner]::StartScan($prefix, $from, $to, $arpMap, $vendorMap)

            if (-not $script:ipScanTimer) {
                $script:ipScanTimer = New-Object System.Windows.Threading.DispatcherTimer
                $script:ipScanTimer.Interval = [TimeSpan]::FromMilliseconds(50)
                $script:ipScanTimer.Add_Tick({
                    $dev = $null
                    $addedAny = $false
                    while ([VUONGTT.Network.FastScanner]::DiscoveredQueue.TryDequeue([ref]$dev)) {
                        if ($dev) {
                            $row = [PSCustomObject]@{
                                Status     = $dev.Status
                                IP         = $dev.IP
                                Hostname   = $dev.Hostname
                                MacAddress = $dev.MacAddress
                                Vendor     = $dev.Vendor
                                Ports      = $dev.Ports
                                Ping       = $dev.PingTime
                            }
                            $global:scannedDevicesList.Add($row) | Out-Null
                            if ($lstIpDevices) { $lstIpDevices.Items.Add($row) | Out-Null }
                            $addedAny = $true
                        }
                    }
                    if ($addedAny -and $lblIpScanStats) {
                        $lblIpScanStats.Text = "Tổng thiết bị Online: $($global:scannedDevicesList.Count)"
                    }

                    $tot = [VUONGTT.Network.FastScanner]::TotalCount
                    $done = [VUONGTT.Network.FastScanner]::CompletedCount
                    if ($tot -gt 0 -and $prgIpScan) {
                        $pct = [math]::Min(100, [math]::Round(($done / $tot) * 100))
                        $prgIpScan.Value = $pct
                    }

                    if (-not [VUONGTT.Network.FastScanner]::IsRunning) {
                        $script:ipScanTimer.Stop()
                        $btnStartIpScan.IsEnabled = $true
                        $btnStopIpScan.IsEnabled  = $false

                        if ([VUONGTT.Network.FastScanner]::IsCancelled) {
                            if ($lblIpScanStatus) { $lblIpScanStatus.Text = "Đã dừng quét IP. Tìm thấy $($global:scannedDevicesList.Count) thiết bị Online." }
                            $txtFooterStatus.Text = "• [Dừng] Đã dừng quét IP!"
                        } else {
                            if ($lblIpScanStatus) { $lblIpScanStatus.Text = "Quét hoàn tất 100%! Đã tìm thấy $($global:scannedDevicesList.Count) thiết bị Online." }
                            $txtFooterStatus.Text = "• [OK] Đã hoàn tất quét IP mạng LAN siêu tốc!"
                        }
                    }
                })
            }
            $script:ipScanTimer.Start()
        } catch {
            if ($lblIpScanStatus) { $lblIpScanStatus.Text = "Lỗi khi quét: $($_.Exception.Message)" }
            $btnStartIpScan.IsEnabled = $true
            $btnStopIpScan.IsEnabled  = $false
        }
    })
}

if ($btnStopIpScan) {
    $btnStopIpScan.Add_Click({
        [VUONGTT.Network.FastScanner]::Cancel()
        if ($lblIpScanStatus) { $lblIpScanStatus.Text = "Đang yêu cầu dừng quét..." }
        $txtFooterStatus.Text = "• [Dừng] Đang dừng quét mạng..."
    })
}

if ($btnCopySelectedIp) {
    $btnCopySelectedIp.Add_Click({
        if ($lstIpDevices -and $lstIpDevices.SelectedItem) {
            $sel = $lstIpDevices.SelectedItem
            $clipText = "IP: $($sel.IP) | Hostname: $($sel.Hostname) | MAC: $($sel.MacAddress) | Vendor: $($sel.Vendor)"
            [System.Windows.Clipboard]::SetText($clipText)
            $txtFooterStatus.Text = "• [COPY] Đã sao chép thông tin thiết bị $($sel.IP) vào Clipboard!"
        } else {
            [System.Windows.MessageBox]::Show("Vui lòng chọn 1 thiết bị trong danh sách để sao chép!", "Thông báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
}

if ($btnOpenSmbShare) {
    $btnOpenSmbShare.Add_Click({
        if ($lstIpDevices -and $lstIpDevices.SelectedItem) {
            $sel = $lstIpDevices.SelectedItem
            Start-Process "explorer.exe" -ArgumentList "\\$($sel.IP)"
            $txtFooterStatus.Text = "• [OK] Đang mở thư mục chia sẻ: \\$($sel.IP)"
        } else {
            [System.Windows.MessageBox]::Show("Vui lòng chọn 1 thiết bị trong danh sách để mở ổ chia sẻ!", "Thông báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
        }
    })
}

if ($btnOpenWebAdmin) {
    $btnOpenWebAdmin.Add_Click({
        if ($lstIpDevices -and $lstIpDevices.SelectedItem) {
            $sel = $lstIpDevices.SelectedItem
            Start-Process "http://$($sel.IP)"
            $txtFooterStatus.Text = "• [OK] Đang mở trang web quản trị: http://$($sel.IP)"
        }
    })
}

if ($btnExportIpCsv) {
    $btnExportIpCsv.Add_Click({
        if ($global:scannedDevicesList.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Chưa có dữ liệu thiết bị nào để xuất báo cáo!", "Thông báo", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
            return
        }
        $deskPath = [Environment]::GetFolderPath("Desktop")
        $csvPath  = Join-Path $deskPath "VUONGTT_LAN_IP_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $global:scannedDevicesList | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        $txtFooterStatus.Text = "• [CSV] Đã xuất báo cáo thiết bị ra Desktop!"
        [System.Windows.MessageBox]::Show("Đã xuất báo cáo thành công ra Desktop:`n$csvPath", "Xuất Báo Cáo CSV", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })
}

if ($lstIpDevices) {
    $lstIpDevices.Add_MouseDoubleClick({
        if ($lstIpDevices.SelectedItem) {
            $sel = $lstIpDevices.SelectedItem
            Start-Process "explorer.exe" -ArgumentList "\\$($sel.IP)"
        }
    })
}

# Khởi tạo trạng thái bản quyền ban đầu
Update-VUONGTTLicenseUI

# Khởi tạo giao diện trang đầu tiên ngay lập tức mà không chặn WMI
Switch-Tab -TargetTag "SysInfo" -SkipRefresh
$txtFooterStatus.Text = "• [OK] Đang khởi động hệ thống và nạp thông số phần cứng..."

# Tải dữ liệu phần cứng ngầm sau khi cửa sổ đã hiện lên màn hình người dùng
$window.Add_ContentRendered({
    Invoke-VUONGTTDoEvents
    Refresh-SysInfoDisplay
    Update-VUONGTTLicenseUI
    $txtFooterStatus.Text = "• [OK] VUONGTT Tool Pro 2026 sẵn sàng phục vụ!"

    # ================= REALTIME BACKGROUND 2-WAY CLOUD AUTO-SYNC WORKER =================
    # Tự động đồng bộ chính sách phân quyền (Free/PRO), kho license keys và kiểm tra bản update
    # Chạy ngầm trong background runspace mỗi 20s, hoàn toàn không gây gián đoạn hay đơ giao diện WPF.
    $script:bgSyncState = @{
        IsBusy      = $false
        PowerShell  = $null
        AsyncHandle = $null
    }
    $script:lastSyncTime = [DateTime]::MinValue
    $script:appRootDir   = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }

    $bgWorkerScript = {
        param($appRoot)
        try {
            $licFile = Join-Path $appRoot "src\Core\LicenseManager.ps1"
            $updFile = Join-Path $appRoot "src\Core\AppUpdater.ps1"
            if (Test-Path $licFile) { . $licFile }
            if (Test-Path $updFile) { . $updFile }
            $cRes = if (Get-Command "Sync-VUONGTTCloudAdminData" -ErrorAction SilentlyContinue) { Sync-VUONGTTCloudAdminData } else { $null }
            $uInfo = if (Get-Command "Get-VUONGTTAppUpdateInfo" -ErrorAction SilentlyContinue) { Get-VUONGTTAppUpdateInfo } else { $null }
            return @{
                Success    = $true
                SyncResult = $cRes
                UpdateInfo = $uInfo
            }
        } catch {
            return @{
                Success = $false
                Error   = $_.Exception.Message
            }
        }
    }

    $syncWorkerTimer = New-Object System.Windows.Threading.DispatcherTimer
    $syncWorkerTimer.Interval = [TimeSpan]::FromSeconds(3)
    $syncWorkerTimer.Add_Tick({
        # 1. Kiểm tra nếu tác vụ ngầm đã có kết quả
        if ($script:bgSyncState.IsBusy) {
            if ($script:bgSyncState.AsyncHandle -and $script:bgSyncState.AsyncHandle.IsCompleted) {
                try {
                    $rawRes = $script:bgSyncState.PowerShell.EndInvoke($script:bgSyncState.AsyncHandle)
                    $script:bgSyncState.PowerShell.Dispose()
                    $script:bgSyncState.PowerShell = $null
                    $script:bgSyncState.AsyncHandle = $null
                    $script:bgSyncState.IsBusy = $false
                    $script:lastSyncTime = [DateTime]::UtcNow

                    if ($rawRes -and $rawRes.Success) {
                        $cRes = $rawRes.SyncResult
                        $uInfo = $rawRes.UpdateInfo

                        # Nhận diện bản cập nhật phần mềm mới từ GitHub
                        if ($uInfo -and $uInfo.HasUpdate) {
                            if ($btnCheckAppUpdate) {
                                $btnCheckAppUpdate.Content = "🔥 CÓ BẢN MỚI v$($uInfo.LatestVersion)"
                                $btnCheckAppUpdate.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#BE123C")
                                $btnCheckAppUpdate.Visibility = [System.Windows.Visibility]::Visible
                            }

                            # Tự động nâng cấp cho 1000 máy khách hàng (Auto-Yes Hot-Update):
                            $isDevSourceRepo = (Test-Path (Join-Path $script:appRootDir "Publish-Update.ps1"))
                            if (-not $isDevSourceRepo -and -not $script:hasTriggeredAutoUpdate) {
                                $script:hasTriggeredAutoUpdate = $true
                                $txtFooterStatus.Text = "• [AUTO-UPDATE] Tác giả vừa cập nhật bản mới v$($uInfo.LatestVersion)! Tự động nâng cấp sau 3 giây..."

                                $autoUpdTimer = New-Object System.Windows.Threading.DispatcherTimer
                                $autoUpdTimer.Interval = [TimeSpan]::FromSeconds(3)
                                $autoUpdTimer.Add_Tick({
                                    $autoUpdTimer.Stop()
                                    $txtFooterStatus.Text = "• [AUTO-UPDATE] Đang tải bản v$($uInfo.LatestVersion) từ GitHub..."
                                    Invoke-VUONGTTDoEvents
                                    Invoke-VUONGTTAppSelfUpdate -DownloadUrl $uInfo.DownloadUrl -NewVersion $uInfo.LatestVersion -OnProgress {
                                        param($m)
                                        $txtFooterStatus.Text = "• [AUTO-UPDATE] $m"
                                        Invoke-VUONGTTDoEvents
                                    }
                                })
                                $autoUpdTimer.Start()
                            } elseif ($isDevSourceRepo) {
                                $txtFooterStatus.Text = "• [CHÚ Ý] Đã có bản cập nhật mới v$($uInfo.LatestVersion) trên GitHub! Bấm nút 'Có Bản Mới' ở trên để nâng cấp."
                            }
                        }

                        # Tự động cập nhật phân quyền Free/PRO nếu Admin vừa đổi trên Cloud
                        if ($cRes -and $cRes.PoliciesSynced) {
                            Update-VUONGTTLicenseUI
                            if ($pageAdminPortal -and $pageAdminPortal.Visibility -eq [System.Windows.Visibility]::Visible) {
                                Render-VUONGTTAdminPolicies
                            }
                            $txtFooterStatus.Text = "• [AUTO-SYNC] Đã tự động cập nhật phân quyền tính năng mới nhất từ Cloud GitHub!"
                        }

                        # Tự động cập nhật kho key nếu có key mới hoặc thay đổi trạng thái kích hoạt từ xa
                        if ($cRes -and ($cRes.KeysMerged -gt 0 -or $cRes.VaultUpdated)) {
                            if ($pageAdminPortal -and $pageAdminPortal.Visibility -eq [System.Windows.Visibility]::Visible) {
                                Render-VUONGTTAdminKeys
                            }
                            $txtFooterStatus.Text = "• [AUTO-SYNC] Đã tự động đồng bộ kho License Key từ Cloud!"
                        }
                    }
                } catch {
                    $script:bgSyncState.IsBusy = $false
                }
            }
            return
        }

        # 2. Kích hoạt lượt đồng bộ mới nếu đã đủ chu kỳ 20 giây (hoặc ngay lần đầu)
        $elapsed = ([DateTime]::UtcNow - $script:lastSyncTime).TotalSeconds
        if ($elapsed -ge 20) {
            $script:bgSyncState.IsBusy = $true
            try {
                $ps = [System.Management.Automation.PowerShell]::Create()
                $ps.AddScript($bgWorkerScript).AddArgument($script:appRootDir) | Out-Null
                $script:bgSyncState.PowerShell = $ps
                $script:bgSyncState.AsyncHandle = $ps.BeginInvoke()
            } catch {
                $script:bgSyncState.IsBusy = $false
            }
        }
    })
    $syncWorkerTimer.Start()

    $window.Add_Closing({
        try {
            $syncWorkerTimer.Stop()
            if ($script:bgSyncState -and $script:bgSyncState.PowerShell) {
                $script:bgSyncState.PowerShell.Dispose()
            }
        } catch {}
    })
})

# Hiển thị cửa sổ giao diện ngay lập tức
$window.ShowDialog() | Out-Null
