# VUONGTT Toolkit 2026 - Enhanced Software Store & Custom App Module

$script:VUONGTT_APPS = @(
    # --- 1. VAN PHONG & TAI LIEU ---
    [PSCustomObject]@{ Id="office365";   Name="Microsoft 365 (Office 365 Mới Nhất)"; Category="Văn phòng"; WingetId="Microsoft.Office"; Url="https://go.microsoft.com/fwlink/p/?LinkID=2009112"; Silent="/configure"; IsOffice=$true },
    [PSCustomObject]@{ Id="foxitpdf";    Name="Foxit PDF Reader";                 Category="Văn phòng"; WingetId="Foxit.FoxitReader"; Url="https://cdn01.foxitsoftware.com/product/reader/desktop/win/12.1.3/FoxitPDFReader1213_enu_Setup_Prom.exe"; Silent="/VERYSILENT" },
    [PSCustomObject]@{ Id="acrobat";     Name="Adobe Acrobat Reader";             Category="Văn phòng"; WingetId="Adobe.Acrobat.Reader.64-bit"; Url="https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2400120604/AcroRdrDC2400120604_en_US.exe"; Silent="/sAll /rs /msi EULA_ACCEPT=YES" },

    # --- 2. BO GO & FONT ---
    [PSCustomObject]@{ Id="unikey";      Name="UniKey 4.3 RC5 (Gõ Tiếng Việt)";   Category="Bộ gõ";     WingetId=""; Url="https://www.unikey.org/assets/release/unikey43RC5-200929-win64.zip"; Silent=""; IsZip=$true },
    [PSCustomObject]@{ Id="evkey";       Name="EVKey (Chống kẹt phím)";           Category="Bộ gõ";     WingetId=""; Url="https://github.com/lamquangminh/EVKey/releases/download/v5.0.0/EVKey.zip"; Silent=""; IsZip=$true },

    # --- 3. TRINH DUYET WEB ---
    [PSCustomObject]@{ Id="chrome";      Name="Google Chrome (Mới Nhất)";         Category="Trình duyệt"; WingetId="Google.Chrome"; Url="https://dl.google.com/chrome/install/standalonesetup64.exe"; Silent="/silent /install" },
    [PSCustomObject]@{ Id="coccoc";      Name="Trình duyệt Cốc Cốc";              Category="Trình duyệt"; WingetId="CocCoc.CocCoc"; Url="https://coccoc.com/download/coccoc_standalone.exe"; Silent="/silent" },
    [PSCustomObject]@{ Id="firefox";     Name="Mozilla Firefox";                  Category="Trình duyệt"; WingetId="Mozilla.Firefox"; Url="https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=vi"; Silent="-ms" },
    [PSCustomObject]@{ Id="brave";       Name="Brave Browser";                    Category="Trình duyệt"; WingetId="Brave.Brave"; Url="https://laptop-updates.brave.com/latest/winx64"; Silent="/silent" },

    # --- 4. NEN & GIAI NEN ---
    [PSCustomObject]@{ Id="7zip";        Name="7-Zip 64-bit";                     Category="Nén file";   WingetId="7zip.7zip"; Url="https://www.7-zip.org/a/7z2408-x64.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="winrar";      Name="WinRAR 64-bit (Mới Nhất)";         Category="Nén file";   WingetId="RARLab.WinRAR"; Url="https://www.rarlab.com/rar/winrar-x64-701.exe"; Silent="/s" },

    # --- 5. DIEU KHIEN TU XA ---
    [PSCustomObject]@{ Id="ultraviewer"; Name="UltraViewer 6.6";                  Category="Điều khiển"; WingetId=""; Url="https://ultraviewer.net/vi/UltraViewer_setup_6.6_vi.exe"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="anydesk";     Name="AnyDesk Remote";                   Category="Điều khiển"; WingetId="AnyDeskSoftwareGmbH.AnyDesk"; Url="https://download.anydesk.com/AnyDesk.exe"; Silent="--install `"$env:ProgramFiles(x86)\AnyDesk`" --start-with-win --silent" },
    [PSCustomObject]@{ Id="rustdesk";    Name="RustDesk Remote (Open Source)";    Category="Điều khiển"; WingetId="RustDesk.RustDesk"; Url="https://github.com/rustdesk/rustdesk/releases/download/1.3.1/rustdesk-1.3.1-x86_64.exe"; Silent="--silent-install" },
    [PSCustomObject]@{ Id="teamviewer";  Name="TeamViewer";                       Category="Điều khiển"; WingetId="TeamViewer.TeamViewer"; Url="https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"; Silent="/S" },

    # --- 6. MANG XA HOI & LIEN LAC ---
    [PSCustomObject]@{ Id="zalo";        Name="Zalo PC (Mới Nhất)";               Category="Liên lạc";   WingetId="VNG.Zalo"; Url="https://res-zalo.zadn.vn/download/ZaloSetup.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="telegram";    Name="Telegram Desktop";                 Category="Liên lạc";   WingetId="Telegram.TelegramDesktop"; Url="https://telegram.org/dl/desktop/win64"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="discord";     Name="Discord PC";                       Category="Liên lạc";   WingetId="Discord.Discord"; Url="https://discord.com/api/download?platform=win"; Silent="-s" },

    # --- 7. DA PHUONG TIEN & VIDEO / STREAM ---
    [PSCustomObject]@{ Id="capcut";      Name="CapCut PC (Biên tập Video)";       Category="Đa phương tiện"; WingetId="ByteDance.CapCut"; Url="https://lf16-capcut.faceuext.com/obj/capcut-router-us/publish/CapCut_Setup.exe"; Silent="/silent" },
    [PSCustomObject]@{ Id="obs";         Name="OBS Studio (Quay & Livestream)";   Category="Đa phương tiện"; WingetId="OBSProject.OBSStudio"; Url="https://cdn-fastly.obsproject.com/downloads/OBS-Studio-30.2.2-Windows-Installer.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="vlc";         Name="VLC Media Player";                 Category="Đa phương tiện"; WingetId="VideoLAN.VLC"; Url="https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="klite";       Name="K-Lite Mega Codec Pack";           Category="Đa phương tiện"; WingetId="CodecGuide.K-LiteCodecPackMega"; Url="https://files3.codecguide.com/K-Lite_Codec_Pack_1855_Mega.exe"; Silent="/verysilent" },
    [PSCustomObject]@{ Id="potplayer";   Name="Daum PotPlayer 64-bit";            Category="Đa phương tiện"; WingetId="Daum.PotPlayer"; Url="https://t1.daumcdn.net/potplayer/PotPlayer/Version/Latest/PotPlayerSetup64.exe"; Silent="/S" },

    # --- 8. LAP TRINH & CONG CU HE THONG ---
    [PSCustomObject]@{ Id="everything";  Name="Everything Search (Tìm file siêu tốc)"; Category="Kỹ thuật"; WingetId="voidtools.Everything"; Url="https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="fdm";         Name="Free Download Manager (Tải file nhanh)"; Category="Kỹ thuật"; WingetId="SoftDeluxe.FreeDownloadManager"; Url="https://dn3.freedownloadmanager.org/6/latest/fdm_x64_setup.exe"; Silent="/VERYSILENT" },
    [PSCustomObject]@{ Id="crystaldiskmark"; Name="CrystalDiskMark (Đo tốc độ SSD)"; Category="Kỹ thuật"; WingetId="CrystalDewWorld.CrystalDiskMark"; Url="https://osdn.net/frs/redir.php?m=rwthaachen&f=crystaldiskmark%2F79591%2FDiskMark8_0_5.zip"; Silent=""; IsZip=$true },
    [PSCustomObject]@{ Id="notepadplus"; Name="Notepad++ 64-bit";                 Category="Lập trình";  WingetId="Notepad++.Notepad++"; Url="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.x64.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="vscode";      Name="Visual Studio Code (Mới Nhất)";    Category="Lập trình";  WingetId="Microsoft.VisualStudioCode"; Url="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"; Silent="/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders" },
    [PSCustomObject]@{ Id="git";         Name="Git for Windows";                  Category="Lập trình";  WingetId="Git.Git"; Url="https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="crystaldisk"; Name="CrystalDiskInfo (Sức khỏe ổ cứng)"; Category="Kỹ thuật";  WingetId="CrystalDewWorld.CrystalDiskInfo"; Url="https://osdn.net/frs/redir.php?m=rwthaachen&f=crystaldiskinfo%2F79590%2FDiskInfo9_4_4.zip"; Silent=""; IsZip=$true },
    [PSCustomObject]@{ Id="cpuz";        Name="CPU-Z (Thông tin vi xử lý)";      Category="Kỹ thuật";  WingetId="CPUID.CPU-Z"; Url="https://download.cpuid.com/cpu-z/cpu-z_2.09-en.exe"; Silent="/VERYSILENT" },
    # --- 9. KE TOAN, THUE & HOA DON DIEN TU ---
    [PSCustomObject]@{ Id="htkk";        Name="HTKK (Hỗ Trợ Kê Khai Thuế Mới Nhất)"; Category="Kế toán"; WingetId=""; Url="https://thuedientu.gdt.gov.vn/download/HTKK_Setup.zip"; IsZip=$true },
    [PSCustomObject]@{ Id="itaxviewer";  Name="iTaxViewer (Đọc Tờ Khai Thuế XML)";  Category="Kế toán"; WingetId=""; Url="https://thuedientu.gdt.gov.vn/download/iTaxViewer_Setup.exe"; Silent="/VERYSILENT /NORESTART /SP-" },
    [PSCustomObject]@{ Id="misasme";     Name="MISA SME (Kế Toán Doanh Nghiệp)";    Category="Kế toán"; WingetId=""; Url="https://download.misa.vn/misasme/misasme.exe"; Silent="/silent" },
    [PSCustomObject]@{ Id="meinvoice";   Name="MISA meInvoice (Hóa Đơn Điện Tử)";   Category="Kế toán"; WingetId=""; Url="https://download.misa.vn/meinvoice/meInvoice.exe"; Silent="/silent" },
    [PSCustomObject]@{ Id="kbhxh";       Name="KBHXH (Bảo Hiểm Xã Hội Điện Tử)";   Category="Kế toán"; WingetId=""; Url="https://gddt.baohiemxahoi.gov.vn/Download/KBHXH_Setup.exe"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="javatax";     Name="Java Token JRE (Ký Số Thuế Điện Tử)"; Category="Kế toán"; WingetId="Oracle.JavaRuntimeEnvironment"; Url="https://javadl.oracle.com/webapps/download/AutoDL?BundleId=249553_4d245f9418eb4ec4978736adb133d549"; Silent="/s" }
)

function Get-VUONGTTAppList {
    return $script:VUONGTT_APPS
}

function Test-VUONGTTWinget {
    try {
        $w = Get-Command winget.exe -ErrorAction SilentlyContinue
        return ($null -ne $w)
    } catch {
        return $false
    }
}

function Install-VUONGTTCustomApp {
    param(
        [string]$TargetInput, # Can be a Winget ID (e.g. Git.Git) or a direct download URL (e.g. https://...)
        [string]$SilentArgs = "",
        [scriptblock]$OnProgress = $null
    )

    if ([string]::IsNullOrWhiteSpace($TargetInput)) {
        return "Lỗi: Vui lòng nhập ID Winget hoặc đường link URL tải phần mềm!"
    }

    $inputClean = $TargetInput.Trim()

    if ($inputClean -like "http*://*") {
        # Direct URL Download & Install
        if ($OnProgress) { & $OnProgress "Đang tải gói cài đặt từ: $inputClean..." }
        $tempDir = "$env:TEMP\VUONGTT_CustomApp"
        if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
        
        $fileName = [System.IO.Path]::GetFileName($inputClean.Split('?')[0])
        if (-not $fileName) { $fileName = "custom_setup.exe" }
        $destFile = Join-Path $tempDir $fileName

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try {
            Invoke-WebRequest -Uri $inputClean -OutFile $destFile -UseBasicParsing
        } catch {
            return "Lỗi khi tải file: $($_.Exception.Message)"
        }

        if ($OnProgress) { & $OnProgress "Đang thực thi tệp cài đặt $fileName..." }
        try {
            $p = Start-Process -FilePath $destFile -ArgumentList $SilentArgs -PassThru -Wait
            return "[OK] Đã hoàn tất thực thi tệp cài đặt $fileName!"
        } catch {
            return "Lỗi khi khởi chạy: $($_.Exception.Message)"
        }
    } else {
        # Winget ID
        if ($OnProgress) { & $OnProgress "Đang tìm và cài đặt gói Winget '$inputClean'..." }
        try {
            $arg = "install --id `"$inputClean`" -e --silent --accept-package-agreements --accept-source-agreements --force"
            $p = Start-Process -FilePath "winget.exe" -ArgumentList $arg -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0 -or $p.ExitCode -eq -1978335189) {
                return "[OK] Đã cài đặt thành công ứng dụng '$inputClean' qua Winget!"
            } else {
                return "Quá trình cài đặt Winget trả về mã: $($p.ExitCode)"
            }
        } catch {
            return "Lỗi khi chạy Winget: $($_.Exception.Message)"
        }
    }
}

function Install-VUONGTTApp {
    param(
        [string]$AppId,
        [scriptblock]$OnProgress = $null
    )

    if ($AppId -in @("htkk", "itaxviewer", "misasme", "meinvoice", "kbhxh", "javatax")) {
        if ([bool](Get-Command "Install-VUONGTTAccountingApp" -ErrorAction SilentlyContinue)) {
            return Install-VUONGTTAccountingApp -AppId $AppId -OnProgress $OnProgress
        }
    }

    $app = $script:VUONGTT_APPS | Where-Object { $_.Id -eq $AppId }
    if (-not $app) { return "Không tìm thấy phần mềm: $AppId" }

    if ($app.IsOffice) {
        if ($OnProgress) { & $OnProgress "Đang chuẩn bị gói cài đặt Microsoft 365 mới nhất từ máy chủ Microsoft..." }
        $cfg = New-VUONGTTOfficeConfig -Version "O365ProPlusRetail" -Arch "64" -Channel "Current" -PrimaryLang "vi-vn"
        $p = Start-VUONGTTOfficeInstall -ConfigFile $cfg -OnProgress $OnProgress
        return "Gói cài đặt Microsoft 365 đã được khởi động ngầm từ CDN Microsoft!"
    }

    $hasWinget = Test-VUONGTTWinget

    if ($hasWinget -and -not [string]::IsNullOrEmpty($app.WingetId)) {
        if ($OnProgress) { & $OnProgress "Đang cài đặt $($app.Name) qua Winget (Phiên bản mới nhất)..." }
        try {
            $arg = "install --id `"$($app.WingetId)`" -e --silent --accept-package-agreements --accept-source-agreements --force"
            $p = Start-Process -FilePath "winget.exe" -ArgumentList $arg -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0 -or $p.ExitCode -eq -1978335189) {
                return "Đã cài đặt thành công $($app.Name) (phiên bản mới nhất qua Winget)!"
            }
        } catch {}
    }

    # Fallback direct download
    $destFolder = "$env:TEMP\VUONGTT_Apps"
    if (-not (Test-Path $destFolder)) { New-Item -ItemType Directory -Path $destFolder -Force | Out-Null }

    $isZip = ($app.IsZip -eq $true -or $app.Url -like "*.zip")
    $ext = if ($isZip) { ".zip" } else { ".exe" }
    $destFile = Join-Path $destFolder "$($app.Id)$ext"

    if ($OnProgress) { & $OnProgress "Đang tải $($app.Name) từ máy chủ chính thức..." }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    try {
        Invoke-WebRequest -Uri $app.Url -OutFile $destFile -UseBasicParsing
    } catch {
        return "Lỗi tải tệp: $($_.Exception.Message)"
    }

    if ($isZip) {
        if ($OnProgress) { & $OnProgress "Đang giải nén $($app.Name)..." }
        $extractDir = "$env:SystemDrive\Tools\$($app.Id)"
        Expand-Archive -Path $destFile -DestinationPath $extractDir -Force
        return "Đã tải và giải nén thành công vào: $extractDir"
    } else {
        if ($OnProgress) { & $OnProgress "Đang cài đặt tự động $($app.Name)..." }
        $proc = Start-Process -FilePath $destFile -ArgumentList $app.Silent -PassThru -Wait
        return "Đã hoàn tất cài đặt $($app.Name)!"
    }
}

# =========================================================================
#   VUONGTT SOFTWARE UNINSTALLER PRO (CLEAN UNINSTALL & DEEP CLEAN)
# =========================================================================

function Get-VUONGTTInstalledSoftware {
    [CmdletBinding()]
    param([string]$FilterText = "")

    if (-not ([System.Management.Automation.PSTypeName]'VUONGTT.InstalledAppItem').Type) {
        Add-Type -TypeDefinition @"
namespace VUONGTT
{
    using System;
    using System.ComponentModel;

    public class InstalledAppItem : INotifyPropertyChanged
    {
        private bool _isChecked = false;
        private string _displayName = "";
        private string _displayVersion = "";
        private string _publisher = "";
        private string _installDate = "";
        private double _sizeMb = 0;
        private string _sizeFormatted = "";
        private string _installLocation = "";
        private string _uninstallString = "";
        private string _quietUninstallString = "";
        private string _registryPath = "";
        private string _registryKeyName = "";

        public bool IsChecked
        {
            get { return _isChecked; }
            set { if (_isChecked != value) { _isChecked = value; OnPropertyChanged("IsChecked"); } }
        }

        public string DisplayName
        {
            get { return _displayName; }
            set { _displayName = value; OnPropertyChanged("DisplayName"); }
        }

        public string DisplayVersion
        {
            get { return _displayVersion; }
            set { _displayVersion = value; OnPropertyChanged("DisplayVersion"); }
        }

        public string Publisher
        {
            get { return _publisher; }
            set { _publisher = value; OnPropertyChanged("Publisher"); }
        }

        public string InstallDate
        {
            get { return _installDate; }
            set { _installDate = value; OnPropertyChanged("InstallDate"); }
        }

        public double SizeMb
        {
            get { return _sizeMb; }
            set { _sizeMb = value; OnPropertyChanged("SizeMb"); }
        }

        public string SizeFormatted
        {
            get { return _sizeFormatted; }
            set { _sizeFormatted = value; OnPropertyChanged("SizeFormatted"); }
        }

        public string InstallLocation
        {
            get { return _installLocation; }
            set { _installLocation = value; OnPropertyChanged("InstallLocation"); }
        }

        public string UninstallString
        {
            get { return _uninstallString; }
            set { _uninstallString = value; OnPropertyChanged("UninstallString"); }
        }

        public string QuietUninstallString
        {
            get { return _quietUninstallString; }
            set { _quietUninstallString = value; OnPropertyChanged("QuietUninstallString"); }
        }

        public string RegistryPath
        {
            get { return _registryPath; }
            set { _registryPath = value; OnPropertyChanged("RegistryPath"); }
        }

        public string RegistryKeyName
        {
            get { return _registryKeyName; }
            set { _registryKeyName = value; OnPropertyChanged("RegistryKeyName"); }
        }

        public event PropertyChangedEventHandler PropertyChanged;
        protected void OnPropertyChanged(string name)
        {
            if (PropertyChanged != null) PropertyChanged(this, new PropertyChangedEventArgs(name));
        }
    }
}
"@
    }

    $regPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $apps = [System.Collections.Generic.List[VUONGTT.InstalledAppItem]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($p in $regPaths) {
        Get-ItemProperty $p -ErrorAction SilentlyContinue | ForEach-Object {
            $name = $_.DisplayName
            $uninst = $_.UninstallString
            if ($name -and ($name.Trim().Length -gt 0) -and (-not $_.SystemComponent) -and (-not $_.ParentKeyName)) {
                # Loại trừ các bản vá Windows Hotfix / Security Update nhỏ
                if ($name -like "KB[0-9]*" -or $name -like "Security Update for *" -or $name -like "Update for Windows *") {
                    return
                }

                $keyUnique = "$($name.Trim())|$($_.DisplayVersion)"
                if (-not $seen.Contains($keyUnique)) {
                    $null = $seen.Add($keyUnique)

                    $sizeMb = if ($_.EstimatedSize) { [math]::Round([double]$_.EstimatedSize / 1024, 1) } else { 0 }
                    $sizeFormatted = if ($sizeMb -gt 1024) { "$([math]::Round($sizeMb / 1024, 2)) GB" } elseif ($sizeMb -gt 0) { "$sizeMb MB" } else { "--" }

                    $instDate = if ($_.InstallDate -and $_.InstallDate.Length -eq 8) {
                        "$($_.InstallDate.Substring(6,2))/$($_.InstallDate.Substring(4,2))/$($_.InstallDate.Substring(0,4))"
                    } else { "--" }

                    $appItem = [VUONGTT.InstalledAppItem]::new()
                    $appItem.IsChecked            = $false
                    $appItem.DisplayName          = $name.Trim()
                    $appItem.DisplayVersion       = if ($_.DisplayVersion) { $_.DisplayVersion.Trim() } else { "--" }
                    $appItem.Publisher            = if ($_.Publisher) { $_.Publisher.Trim() } else { "Chưa xác định" }
                    $appItem.InstallDate          = $instDate
                    $appItem.SizeMb               = $sizeMb
                    $appItem.SizeFormatted        = $sizeFormatted
                    $appItem.InstallLocation      = if ($_.InstallLocation) { $_.InstallLocation.Trim() } else { "" }
                    $appItem.UninstallString      = if ($_.UninstallString) { $_.UninstallString.Trim() } else { "" }
                    $appItem.QuietUninstallString = if ($_.QuietUninstallString) { $_.QuietUninstallString.Trim() } else { "" }
                    $appItem.RegistryPath         = if ($_.PSPath) { $_.PSPath } else { "" }
                    $appItem.RegistryKeyName      = if ($_.PSChildName) { $_.PSChildName } else { "" }

                    $apps.Add($appItem)
                }
            }
        }
    }

    $sorted = $apps | Sort-Object DisplayName

    if ($FilterText -and $FilterText.Trim().Length -gt 0) {
        $q = $FilterText.Trim()
        $sorted = $sorted | Where-Object {
            $_.DisplayName -like "*$q*" -or $_.Publisher -like "*$q*" -or $_.DisplayVersion -like "*$q*"
        }
    }

    return @($sorted)
}

function Invoke-VUONGTTUninstallSoftware {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$AppItem,
        [switch]$CleanDeepScan = $false,
        [scriptblock]$OnLog = $null
    )

    function Write-LogMsg {
        param([string]$Msg)
        if ($OnLog) { & $OnLog $Msg }
    }

    $appName = $AppItem.DisplayName
    Write-LogMsg ">>> Bắt đầu tiến trình gỡ cài đặt: $appName (v$($AppItem.DisplayVersion))..."

    $uninstCmd = if ($AppItem.QuietUninstallString) { $AppItem.QuietUninstallString } else { $AppItem.UninstallString }

    if (-not $uninstCmd) {
        Write-LogMsg "⚠️ [CẢNH BÁO] Không tìm thấy chuỗi lệnh gỡ cài đặt chính thống trong Registry!"
        if (-not $CleanDeepScan) {
            return "[THẤT BẠI] Ứng dụng không có UninstallString hợp lệ!"
        }
    } else {
        Write-LogMsg "• Lệnh gỡ bỏ phát hiện: $uninstCmd"
        try {
            # Xử lý lệnh MsiExec (GUID)
            if ($uninstCmd -match '\{[0-9A-Fa-f\-]{36}\}') {
                $guid = $matches[0]
                Write-LogMsg "• Phát hiện gói Windows Installer (MSI): $guid. Đang gọi MsiExec..."
                $msiArgs = "/X$guid /passive /norestart"
                $proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
                Write-LogMsg "• MsiExec hoàn tất với mã thoát: $($proc.ExitCode)"
            } else {
                # Xử lý lệnh tệp thực thi EXE thông thường
                $exePath = ""
                $argList = ""
                if ($uninstCmd -match '^"([^"]+)"\s*(.*)$') {
                    $exePath = $matches[1]
                    $argList = $matches[2]
                } elseif ($uninstCmd -match '^([^\s]+)\s*(.*)$') {
                    $exePath = $matches[1]
                    $argList = $matches[2]
                } else {
                    $exePath = $uninstCmd
                }

                if (Test-Path $exePath -ErrorAction SilentlyContinue) {
                    Write-LogMsg "• Đang khởi chạy uninstaller gốc: $exePath $argList"
                    $proc = Start-Process -FilePath $exePath -ArgumentList $argList -Wait -PassThru
                    Write-LogMsg "• Trình gỡ cài đặt kết thúc với mã thoát: $($proc.ExitCode)"
                } else {
                    Write-LogMsg "⚠️ Không thể chạy trực tiếp: $exePath. Thực thi qua cmd.exe..."
                    $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninstCmd`"" -Wait -PassThru
                    Write-LogMsg "• Lệnh kết thúc với mã thoát: $($proc.ExitCode)"
                }
            }
        } catch {
            Write-LogMsg "⚠️ Lỗi khi khởi chạy uninstaller gốc: $($_.Exception.Message)"
        }
    }

    # BƯỚC 2: NẾU BẬT GỠ SẠCH TRIỆT ĐỂ (CLEAN DEEP SCAN)
    if ($CleanDeepScan) {
        Write-LogMsg "=========================================================="
        Write-LogMsg "🔍 BẮT ĐẦU QUÉT & DỌN RÁC CHUYÊN SÂU (DEEP CLEAN REMNANTS)..."
        Write-LogMsg "=========================================================="
        
        # Tạo từ khóa lọc an toàn
        $cleanTerm = $appName -replace '\s*(64-bit|32-bit|x64|x86|\(.*?\)|v?[0-9]+\.[0-9]+.*)$', ''
        $cleanTerm = $cleanTerm.Trim()

        # Bảo vệ tuyệt đối hệ thống - Không bao giờ quét hoặc xóa từ khóa nguy hiểm
        $forbiddenKeywords = @("windows", "microsoft", "system", "system32", "program files", "appdata", "users", "common files", "temp", "desktop", "intel", "amd", "realtek", "nvidia")
        $isForbidden = $false
        foreach ($fk in $forbiddenKeywords) {
            if ($cleanTerm.ToLower() -eq $fk) {
                $isForbidden = $true
                break
            }
        }

        if ($cleanTerm.Length -ge 3 -and -not $isForbidden) {
            Write-LogMsg "• Từ khóa nhận diện tệp/khóa rác: '$cleanTerm'"

            # 1. Dọn dẹp thư mục cài đặt gốc (InstallLocation)
            if ($AppItem.InstallLocation -and (Test-Path $AppItem.InstallLocation -ErrorAction SilentlyContinue)) {
                $loc = $AppItem.InstallLocation
                if ($loc.Length -gt 10 -and $loc -notlike "C:\Windows*" -and $loc -notlike "C:\Program Files" -and $loc -notlike "C:\Program Files (x86)") {
                    try {
                        Remove-Item -Path $loc -Recurse -Force -ErrorAction SilentlyContinue
                        Write-LogMsg "✅ [ĐÃ XÓA SẠCH] Thư mục cài đặt gốc: $loc"
                    } catch {}
                }
            }

            # 2. Dọn dẹp các thư mục rác trong AppData & ProgramData
            $dataRoots = @(
                "$env:LOCALAPPDATA",
                "$env:APPDATA",
                "$env:ProgramData",
                "$env:ProgramFiles",
                "${env:ProgramFiles(x86)}"
            )

            foreach ($dr in $dataRoots) {
                if (Test-Path $dr -ErrorAction SilentlyContinue) {
                    Get-ChildItem -Path $dr -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                        if ($_.Name -like "*$cleanTerm*" -and ($_.Name.ToLower() -notin $forbiddenKeywords)) {
                            $targetTrash = $_.FullName
                            try {
                                Remove-Item -Path $targetTrash -Recurse -Force -ErrorAction SilentlyContinue
                                Write-LogMsg "✅ [ĐÃ DỌN RÁC] Thư mục dư thừa: $targetTrash"
                            } catch {}
                        }
                    }
                }
            }

            # 3. Dọn dẹp khóa Registry còn sót lại
            $regRoots = @(
                "HKCU:\Software",
                "HKLM:\Software",
                "HKLM:\Software\Wow6432Node"
            )

            foreach ($rr in $regRoots) {
                if (Test-Path $rr -ErrorAction SilentlyContinue) {
                    Get-ChildItem -Path $rr -ErrorAction SilentlyContinue | ForEach-Object {
                        $keyNameOnly = $_.PSChildName
                        if ($keyNameOnly -like "*$cleanTerm*" -and ($keyNameOnly.ToLower() -notin $forbiddenKeywords)) {
                            $trashRegKey = $_.PSPath
                            try {
                                Remove-Item -Path $trashRegKey -Recurse -Force -ErrorAction SilentlyContinue
                                Write-LogMsg "✅ [ĐÃ XÓA REGISTRY] $trashRegKey"
                            } catch {}
                        }
                    }
                }
            }

            # 4. Xóa Registry Uninstall Key của chính ứng dụng nếu uninstaller bỏ sót
            if ($AppItem.RegistryPath -and (Test-Path $AppItem.RegistryPath -ErrorAction SilentlyContinue)) {
                try {
                    Remove-Item -Path $AppItem.RegistryPath -Recurse -Force -ErrorAction SilentlyContinue
                    Write-LogMsg "✅ [ĐÃ XÓA MÃ GỠ BỎ REGISTRY] $($AppItem.RegistryPath)"
                } catch {}
            }

            # 5. Dọn dẹp Shortcut (.lnk) trên Desktop & Start Menu
            $shortcutFolders = @(
                "$env:USERPROFILE\Desktop",
                "$env:PUBLIC\Desktop",
                "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
                "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
            )

            foreach ($sf in $shortcutFolders) {
                if (Test-Path $sf -ErrorAction SilentlyContinue) {
                    Get-ChildItem -Path $sf -Filter "*$cleanTerm*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                            Write-LogMsg "✅ [ĐÃ XÓA SHORTCUT] $($_.Name)"
                        } catch {}
                    }
                }
            }
        } else {
            Write-LogMsg "• Bỏ qua quét theo tên vì từ khóa quá ngắn hoặc thuộc hệ thống bảo vệ."
        }
        Write-LogMsg "=========================================================="
        Write-LogMsg "🎉 [HOÀN TẤT] Đã gỡ bỏ và dọn dẹp sạch sẽ phần mềm $appName!"
    } else {
        Write-LogMsg "🎉 [HOÀN TẤT] Tiến trình gỡ cài đặt tiêu chuẩn đã kết thúc!"
    }

    return "Gỡ cài đặt hoàn tất!"
}

