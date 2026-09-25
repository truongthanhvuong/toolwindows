# VUONGTT Toolkit 2026 - Enhanced Software Store & Custom App Module

function Invoke-VUONGTTDoEvents {
    try {
        if ([System.Windows.Threading.Dispatcher]::CurrentDispatcher) {
            [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
        }
    } catch {}
    try {
        if ([Type]::GetType("System.Windows.Forms.Application, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")) {
            [System.Windows.Forms.Application]::DoEvents()
        }
    } catch {}
}

$script:VUONGTT_APPS = @(
    # --- 1. VAN PHONG & TAI LIEU ---
    [PSCustomObject]@{ Id="office365";   Name="Microsoft 365 (Office 365 Mới Nhất)"; Category="Văn phòng"; WingetId="Microsoft.Office"; Url="https://go.microsoft.com/fwlink/p/?LinkID=2009112"; Silent="/configure"; IsOffice=$true },
    [PSCustomObject]@{ Id="foxitpdf";    Name="Foxit PDF Reader (Mới Nhất)";         Category="Văn phòng"; WingetId="Foxit.FoxitReader"; Url="https://cdn01.foxitsoftware.com/product/reader/desktop/win/12.1.3/FoxitPDFReader1213_enu_Setup_Prom.exe"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="acrobat";     Name="Adobe Acrobat Reader (Mới Nhất)";     Category="Văn phòng"; WingetId="Adobe.Acrobat.Reader.64-bit"; Url="https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2400120604/AcroRdrDC2400120604_en_US.exe"; Silent="/sAll /rs /msi EULA_ACCEPT=YES" },

    # --- 2. BO GO & FONT ---
    [PSCustomObject]@{ Id="unikey";      Name="UniKey (Gõ Tiếng Việt Chuẩn)";        Category="Bộ gõ";     WingetId="UniKey.UniKey"; Url="https://www.unikey.org/assets/release/unikey43RC5-200929-win64.zip"; Silent=""; IsZip=$true },
    [PSCustomObject]@{ Id="evkey";       Name="EVKey (Bộ gõ Chống kẹt phím)";        Category="Bộ gõ";     WingetId="lamquangminh.EVKey"; Url="https://github.com/lamquangminh/EVKey/releases/download/Release/EVKey.zip"; Silent=""; IsZip=$true },

    # --- 3. TRINH DUYET WEB ---
    [PSCustomObject]@{ Id="chrome";      Name="Google Chrome (Mới Nhất)";            Category="Trình duyệt"; WingetId="Google.Chrome"; Url="https://dl.google.com/chrome/install/standalonesetup64.exe"; Silent="/silent /install" },
    [PSCustomObject]@{ Id="coccoc";      Name="Trình duyệt Cốc Cốc (Mới Nhất)";      Category="Trình duyệt"; WingetId="CocCoc.CocCoc"; Url="https://files1.coccoc.com/browser/x64/120.0.6099.234/0A137B37-5CC3-881A-70E1-86CE2172C8D1/cmVmPXd3dy5nb29nbGUuY29t/coccoc_vi_machine.exe"; Silent="/silent" },
    [PSCustomObject]@{ Id="firefox";     Name="Mozilla Firefox (Mới Nhất)";          Category="Trình duyệt"; WingetId="Mozilla.Firefox"; Url="https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=vi"; Silent="-ms" },
    [PSCustomObject]@{ Id="brave";       Name="Brave Browser (Bảo Mật)";             Category="Trình duyệt"; WingetId="Brave.Brave"; Url="https://laptop-updates.brave.com/latest/winx64"; Silent="/silent" },

    # --- 4. NEN & GIAI NEN ---
    [PSCustomObject]@{ Id="7zip";        Name="7-Zip 64-bit (Mới Nhất)";             Category="Nén file";   WingetId="7zip.7zip"; Url="https://www.7-zip.org/a/7z2408-x64.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="winrar";      Name="WinRAR 64-bit (Mới Nhất)";            Category="Nén file";   WingetId="RARLab.WinRAR"; Url="https://www.rarlab.com/rar/winrar-x64-701.exe"; Silent="/s" },

    # --- 5. DIEU KHIEN TU XA ---
    [PSCustomObject]@{ Id="ultraviewer"; Name="UltraViewer (Điều Khiển Từ Xa)";      Category="Điều khiển"; WingetId="DucFabulous.UltraViewer"; Url="https://ultraviewer.net/vi/UltraViewer_setup_6.6_vi.exe"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="anydesk";     Name="AnyDesk Remote (Mới Nhất)";           Category="Điều khiển"; WingetId="AnyDeskSoftwareGmbH.AnyDesk"; Url="https://download.anydesk.com/AnyDesk.exe"; Silent="--install --start-with-win --silent" },
    [PSCustomObject]@{ Id="rustdesk";    Name="RustDesk Remote (Open Source)";       Category="Điều khiển"; WingetId="RustDesk.RustDesk"; Url="https://github.com/rustdesk/rustdesk/releases/download/1.3.1/rustdesk-1.3.1-x86_64.exe"; Silent="--silent-install" },
    [PSCustomObject]@{ Id="teamviewer";  Name="TeamViewer (Mới Nhất)";               Category="Điều khiển"; WingetId="TeamViewer.TeamViewer"; Url="https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe"; Silent="/S" },

    # --- 6. MANG XA HOI & LIEN LAC ---
    [PSCustomObject]@{ Id="zalo";        Name="Zalo PC (Bản Mới Nhất)";              Category="Liên lạc";   WingetId="VNGCorp.Zalo"; Url="https://res-zaloapp-aka-jpt.zdn.vn/win/ZaloSetup-26.8.20.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="telegram";    Name="Telegram Desktop (Mới Nhất)";         Category="Liên lạc";   WingetId="Telegram.TelegramDesktop"; Url="https://telegram.org/dl/desktop/win64"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="discord";     Name="Discord PC (Mới Nhất)";               Category="Liên lạc";   WingetId="Discord.Discord"; Url="https://discord.com/api/download?platform=win"; Silent="-s" },

    # --- 7. DA PHUONG TIEN & VIDEO / STREAM ---
    [PSCustomObject]@{ Id="capcut";      Name="CapCut PC (Biên tập Video)";          Category="Đa phương tiện"; WingetId="ByteDance.CapCut"; Url="https://sf16-web-tos-buz.capcutstatic.com/obj/capcut-web-buz-sg/packages/CapCut_9_4_0_4015_capcutpc_0_creatortool.exe"; Silent="/silent" },
    [PSCustomObject]@{ Id="obs";         Name="OBS Studio (Quay & Livestream)";      Category="Đa phương tiện"; WingetId="OBSProject.OBSStudio"; Url="https://github.com/obsproject/obs-studio/releases/download/32.2.2/OBS-Studio-32.2.2-Windows-x64-Installer.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="vlc";         Name="VLC Media Player (Mới Nhất)";         Category="Đa phương tiện"; WingetId="VideoLAN.VLC"; Url="https://get.videolan.org/vlc/3.0.21/win64/vlc-3.0.21-win64.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="klite";       Name="K-Lite Mega Codec Pack (Mới Nhất)";   Category="Đa phương tiện"; WingetId="CodecGuide.K-LiteCodecPackMega"; Url="https://files3.codecguide.com/K-Lite_Codec_Pack_1855_Mega.exe"; Silent="/verysilent" },
    [PSCustomObject]@{ Id="potplayer";   Name="Daum PotPlayer 64-bit (Mới Nhất)";     Category="Đa phương tiện"; WingetId="Daum.PotPlayer"; Url="https://t1.daumcdn.net/potplayer/PotPlayer/Version/Latest/PotPlayerSetup64.exe"; Silent="/S" },

    # --- 8. LAP TRINH & CONG CU HE THONG ---
    [PSCustomObject]@{ Id="everything";  Name="Everything Search (Tìm kiếm siêu tốc)"; Category="Kỹ thuật"; WingetId="voidtools.Everything"; Url="https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="fdm";         Name="Free Download Manager (FDM)";         Category="Kỹ thuật"; WingetId="SoftDeluxe.FreeDownloadManager"; Url="https://dn3.freedownloadmanager.org/6/latest/fdm_x64_setup.exe"; Silent="/VERYSILENT" },
    [PSCustomObject]@{ Id="crystaldiskmark"; Name="CrystalDiskMark (Đo tốc độ SSD)"; Category="Kỹ thuật"; WingetId="CrystalDewWorld.CrystalDiskMark"; Url="https://crystalmark.info/redirect.php?product=CrystalDiskMark"; Silent=""; IsZip=$true },
    [PSCustomObject]@{ Id="crystaldisk"; Name="CrystalDiskInfo (Sức khỏe ổ cứng)";  Category="Kỹ thuật"; WingetId="CrystalDewWorld.CrystalDiskInfo"; Url="https://crystalmark.info/redirect.php?product=CrystalDiskInfo"; Silent=""; IsZip=$true },
    [PSCustomObject]@{ Id="notepadplus"; Name="Notepad++ 64-bit (Mới Nhất)";         Category="Lập trình"; WingetId="Notepad++.Notepad++"; Url="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.9/npp.8.6.9.Installer.x64.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="vscode";      Name="Visual Studio Code (Mới Nhất)";       Category="Lập trình"; WingetId="Microsoft.VisualStudioCode"; Url="https://code.visualstudio.com/sha/download?build=stable&os=win32-x64-user"; Silent="/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders" },
    [PSCustomObject]@{ Id="git";         Name="Git for Windows (Mới Nhất)";          Category="Lập trình"; WingetId="Git.Git"; Url="https://github.com/git-for-windows/git/releases/download/v2.46.0.windows.1/Git-2.46.0-64-bit.exe"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="cpuz";        Name="CPU-Z (Thông tin vi xử lý)";         Category="Kỹ thuật"; WingetId="CPUID.CPU-Z"; Url="https://download.cpuid.com/cpu-z/cpu-z_3.01-en.exe"; Silent="/VERYSILENT" },
    [PSCustomObject]@{ Id="revo";        Name="Revo Uninstaller Free (Gỡ sạch app)"; Category="Kỹ thuật"; WingetId="RevoUninstaller.RevoUninstaller"; Url="https://download.revouninstaller.com/download/revosetup.exe"; Silent="/VERYSILENT /NORESTART" },

    # --- 9. KE TOAN, THUE & HOA DON DIEN TU ---
    [PSCustomObject]@{ Id="htkk";        Name="HTKK (Hỗ Trợ Kê Khai Thuế Mới Nhất)"; Category="Kế toán"; WingetId=""; Url="https://thuedientu.gdt.gov.vn/download/HTKK_Setup.zip"; IsZip=$true },
    [PSCustomObject]@{ Id="itaxviewer";  Name="iTaxViewer (Đọc Tờ Khai Thuế XML)";   Category="Kế toán"; WingetId=""; Url="https://thuedientu.gdt.gov.vn/download/iTaxViewer_Setup.exe"; Silent="/VERYSILENT /NORESTART /SP-" },
    [PSCustomObject]@{ Id="misasme";     Name="MISA SME (Kế Toán Doanh Nghiệp)";     Category="Kế toán"; WingetId=""; Url="https://sme.misa.vn/download/"; Silent="/silent" },
    [PSCustomObject]@{ Id="meinvoice";   Name="MISA meInvoice (Hóa Đơn Điện Tử)";    Category="Kế toán"; WingetId=""; Url="https://meinvoice.vn/tai-ve/"; Silent="/silent" },
    [PSCustomObject]@{ Id="kbhxh";       Name="KBHXH (Bảo Hiểm Xã Hội Điện Tử)";    Category="Kế toán"; WingetId=""; Url="https://gddt.baohiemxahoi.gov.vn/Download/KBHXH_Setup.exe"; Silent="/VERYSILENT /NORESTART" },
    [PSCustomObject]@{ Id="javatax";     Name="Java Token JRE (Ký Số Thuế Điện Tử)"; Category="Kế toán"; WingetId="Oracle.JavaRuntimeEnvironment"; Url="https://javadl.oracle.com/webapps/download/AutoDL?BundleId=249553_4d245f9418eb4ec4978736adb133d549"; Silent="/s" },
    [PSCustomObject]@{ Id="dvcplugin";   Name="Plugin Ký Số Cổng Dịch Vụ Công Quốc Gia"; Category="Kế toán"; WingetId=""; Url="https://dichvucong.gov.vn/pki/VNPT_Plugin.exe"; Silent="/VERYSILENT /NORESTART /SP-" },
    [PSCustomObject]@{ Id="vietteltoken";Name="Viettel-CA Token Manager v2 (Ký Số Nhà Nước & Thuế)"; Category="Kế toán"; WingetId=""; Url="https://viettel-ca.vn/download/Viettel-CA_v2_setup.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="vnpttoken";   Name="VNPT-CA Token Manager AN (Ký Số Thuế, BHXH, DVC)"; Category="Kế toán"; WingetId=""; Url="https://vnpt-ca.vn:443/documents/download?fileNameDownload=documents/15012026160533.exe"; Silent="/S" },
    [PSCustomObject]@{ Id="esigner";     Name="eSigner TCT (Ký Số Thuế Điện Tử Tổng Cục Thuế)"; Category="Kế toán"; WingetId=""; Url="https://thuedientu.gdt.gov.vn/download/eSigner_1.0.8_setup.exe"; Silent="/VERYSILENT /NORESTART /SP-" },
    [PSCustomObject]@{ Id="netfx35";     Name=".NET Framework 3.5 (.NET 2.0 & 3.0)"; Category="Kỹ thuật"; WingetId="Microsoft.DotNet.Framework.DeveloperPack_3"; Url="https://dotnet.microsoft.com"; IsFeature=$true }
)

# Load Complete 254+ Software Database from JSON with robust multi-directory probe and smart-merge
$dbCandidatePaths = @()
if ($ScriptDir) { $dbCandidatePaths += Join-Path $ScriptDir "src\Data\SoftwareDatabase.json" }
if ($PSScriptRoot) {
    $dbCandidatePaths += Join-Path $PSScriptRoot "..\Data\SoftwareDatabase.json"
    $dbCandidatePaths += Join-Path (Split-Path -Parent $PSScriptRoot) "Data\SoftwareDatabase.json"
}
$dbCandidatePaths += Join-Path $env:ProgramData "VUONGTT_Toolkit\runtime\src\Data\SoftwareDatabase.json"
$dbCandidatePaths += "E:\toolwindows\src\Data\SoftwareDatabase.json"
$dbCandidatePaths += "$env:TEMP\VUONGTT_Toolkit_Runtime\src\Data\SoftwareDatabase.json"
$dbCandidatePaths += Join-Path (Get-Location).Path "src\Data\SoftwareDatabase.json"

foreach ($dbp in $dbCandidatePaths) {
    if ($dbp -and (Test-Path $dbp)) {
        try {
            $jsonApps = Get-Content $dbp -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($jsonApps -and $jsonApps.Count -gt 0) {
                # SMART MERGE: Bao toan 100% Direct URLs, Silent switches va IsZip cua danh sach goc
                $appsMap = @{}
                foreach ($a in $script:VUONGTT_APPS) {
                    $appsMap[$a.Id.ToLower()] = $a
                }
                foreach ($j in $jsonApps) {
                    $jId = $j.Id.ToLower()
                    if ($appsMap.ContainsKey($jId)) {
                        $existing = $appsMap[$jId]
                        if (-not [string]::IsNullOrWhiteSpace($j.WingetId)) { $existing.WingetId = $j.WingetId }
                        if ([string]::IsNullOrWhiteSpace($existing.Url) -and -not [string]::IsNullOrWhiteSpace($j.Url)) { $existing.Url = $j.Url }
                        if ([string]::IsNullOrWhiteSpace($existing.Category) -and -not [string]::IsNullOrWhiteSpace($j.Category)) { $existing.Category = $j.Category }
                    } else {
                        $appsMap[$jId] = $j
                    }
                }
                $script:VUONGTT_APPS = @($appsMap.Values)
                break
            }
        } catch {}
    }
}

$script:APP_EXEC_MAP = @{
    "office365"       = @{ Exe = "WINWORD.EXE"; ProcessName = "WINWORD"; CommonPaths = @("$env:ProgramFiles\Microsoft Office\root\Office16\WINWORD.EXE", "${env:ProgramFiles(x86)}\Microsoft Office\root\Office16\WINWORD.EXE") }
    "foxitpdf"        = @{ Exe = "FoxitPDFReader.exe"; ProcessName = "FoxitPDFReader"; CommonPaths = @("$env:ProgramFiles\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe", "${env:ProgramFiles(x86)}\Foxit Software\Foxit PDF Reader\FoxitPDFReader.exe") }
    "acrobat"         = @{ Exe = "AcroRd32.exe"; ProcessName = "AcroRd32"; CommonPaths = @("$env:ProgramFiles\Adobe\Acrobat DC\Acrobat\Acrobat.exe", "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe", "$env:ProgramFiles\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe") }
    "unikey"          = @{ Exe = "UniKeyNT.exe"; ProcessName = "UniKeyNT"; CommonPaths = @("$env:SystemDrive\Tools\unikey\UniKeyNT.exe", "$env:ProgramFiles\UniKey\UniKeyNT.exe", "${env:ProgramFiles(x86)}\UniKey\UniKeyNT.exe") }
    "evkey"           = @{ Exe = "EVKey64.exe"; ProcessName = "EVKey64"; CommonPaths = @("$env:SystemDrive\Tools\evkey\EVKey64.exe", "$env:SystemDrive\Tools\evkey\EVKey32.exe") }
    "chrome"          = @{ Exe = "chrome.exe"; ProcessName = "chrome"; CommonPaths = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe") }
    "coccoc"          = @{ Exe = "browser.exe"; ProcessName = "browser"; CommonPaths = @("$env:LOCALAPPDATA\CocCoc\Browser\Application\browser.exe", "$env:ProgramFiles\CocCoc\Browser\Application\browser.exe") }
    "firefox"         = @{ Exe = "firefox.exe"; ProcessName = "firefox"; CommonPaths = @("$env:ProgramFiles\Mozilla Firefox\firefox.exe", "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe") }
    "brave"           = @{ Exe = "brave.exe"; ProcessName = "brave"; CommonPaths = @("$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe", "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe") }
    "7zip"            = @{ Exe = "7zFM.exe"; ProcessName = "7zFM"; CommonPaths = @("$env:ProgramFiles\7-Zip\7zFM.exe", "${env:ProgramFiles(x86)}\7-Zip\7zFM.exe") }
    "winrar"          = @{ Exe = "WinRAR.exe"; ProcessName = "WinRAR"; CommonPaths = @("$env:ProgramFiles\WinRAR\WinRAR.exe", "${env:ProgramFiles(x86)}\WinRAR\WinRAR.exe") }
    "ultraviewer"     = @{ Exe = "UltraViewer_Desktop.exe"; ProcessName = "UltraViewer_Desktop"; CommonPaths = @("$env:ProgramFiles\UltraViewer\UltraViewer_Desktop.exe", "${env:ProgramFiles(x86)}\UltraViewer\UltraViewer_Desktop.exe") }
    "anydesk"         = @{ Exe = "AnyDesk.exe"; ProcessName = "AnyDesk"; CommonPaths = @("$env:ProgramFiles\AnyDesk\AnyDesk.exe", "${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe") }
    "rustdesk"        = @{ Exe = "rustdesk.exe"; ProcessName = "rustdesk"; CommonPaths = @("$env:ProgramFiles\RustDesk\rustdesk.exe", "${env:ProgramFiles(x86)}\RustDesk\rustdesk.exe") }
    "teamviewer"      = @{ Exe = "TeamViewer.exe"; ProcessName = "TeamViewer"; CommonPaths = @("$env:ProgramFiles\TeamViewer\TeamViewer.exe", "${env:ProgramFiles(x86)}\TeamViewer\TeamViewer.exe") }
    "zalo"            = @{ Exe = "Zalo.exe"; ProcessName = "Zalo"; CommonPaths = @("$env:LOCALAPPDATA\Programs\Zalo\Zalo.exe", "$env:ProgramFiles\Zalo\Zalo.exe") }
    "telegram"        = @{ Exe = "Telegram.exe"; ProcessName = "Telegram"; CommonPaths = @("$env:APPDATA\Telegram Desktop\Telegram.exe", "$env:ProgramFiles\Telegram Desktop\Telegram.exe") }
    "discord"         = @{ Exe = "Discord.exe"; ProcessName = "Discord"; CommonPaths = @("$env:LOCALAPPDATA\Discord\Update.exe", "$env:LOCALAPPDATA\Discord\app-*\Discord.exe") }
    "capcut"          = @{ Exe = "CapCut.exe"; ProcessName = "CapCut"; CommonPaths = @("$env:LOCALAPPDATA\CapCut\Apps\CapCut.exe") }
    "obs"             = @{ Exe = "obs64.exe"; ProcessName = "obs64"; CommonPaths = @("$env:ProgramFiles\obs-studio\bin\64bit\obs64.exe") }
    "vlc"             = @{ Exe = "vlc.exe"; ProcessName = "vlc"; CommonPaths = @("$env:ProgramFiles\VideoLAN\VLC\vlc.exe", "${env:ProgramFiles(x86)}\VideoLAN\VLC\vlc.exe") }
    "klite"           = @{ Exe = "mpc-hc64.exe"; ProcessName = "mpc-hc64"; CommonPaths = @("$env:ProgramFiles\K-Lite Codec Pack\MPC-HC64\mpc-hc64.exe", "${env:ProgramFiles(x86)}\K-Lite Codec Pack\MPC-HC\mpc-hc.exe") }
    "potplayer"       = @{ Exe = "PotPlayer64.exe"; ProcessName = "PotPlayer64"; CommonPaths = @("$env:ProgramFiles\DAUM\PotPlayer\PotPlayer64.exe", "${env:ProgramFiles(x86)}\DAUM\PotPlayer\PotPlayer.exe") }
    "everything"      = @{ Exe = "Everything.exe"; ProcessName = "Everything"; CommonPaths = @("$env:ProgramFiles\Everything\Everything.exe", "${env:ProgramFiles(x86)}\Everything\Everything.exe") }
    "fdm"             = @{ Exe = "fdm.exe"; ProcessName = "fdm"; CommonPaths = @("$env:ProgramFiles\FreeDownloadManager.ORG\Free Download Manager\fdm.exe") }
    "crystaldiskmark" = @{ Exe = "DiskMark64.exe"; ProcessName = "DiskMark64"; CommonPaths = @("$env:SystemDrive\Tools\crystaldiskmark\DiskMark64.exe") }
    "notepadplus"     = @{ Exe = "notepad++.exe"; ProcessName = "notepad++"; CommonPaths = @("$env:ProgramFiles\Notepad++\notepad++.exe", "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe") }
    "vscode"          = @{ Exe = "Code.exe"; ProcessName = "Code"; CommonPaths = @("$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe", "$env:ProgramFiles\Microsoft VS Code\Code.exe") }
    "git"             = @{ Exe = "git-bash.exe"; ProcessName = "git-bash"; CommonPaths = @("$env:ProgramFiles\Git\git-bash.exe", "${env:ProgramFiles(x86)}\Git\git-bash.exe") }
    "crystaldisk"     = @{ Exe = "DiskInfo64.exe"; ProcessName = "DiskInfo64"; CommonPaths = @("$env:SystemDrive\Tools\crystaldisk\DiskInfo64.exe") }
    "cpuz"            = @{ Exe = "cpuz.exe"; ProcessName = "cpuz"; CommonPaths = @("$env:ProgramFiles\CPUID\CPU-Z\cpuz.exe", "${env:ProgramFiles(x86)}\CPUID\CPU-Z\cpuz.exe") }
    "revo"            = @{ Exe = "RevoUninPro.exe"; ProcessName = "RevoUninPro"; CommonPaths = @("$env:ProgramFiles\VS Revo Group\Revo Uninstaller Pro\RevoUninPro.exe", "${env:ProgramFiles(x86)}\VS Revo Group\Revo Uninstaller\Revouninstaller.exe") }
    "htkk"            = @{ Exe = "HTKK.exe"; ProcessName = "HTKK"; CommonPaths = @("$env:ProgramFiles\HTKK\HTKK.exe", "${env:ProgramFiles(x86)}\HTKK\HTKK.exe") }
    "itaxviewer"      = @{ Exe = "iTaxViewer.exe"; ProcessName = "iTaxViewer"; CommonPaths = @("$env:ProgramFiles\iTaxViewer\iTaxViewer.exe", "${env:ProgramFiles(x86)}\iTaxViewer\iTaxViewer.exe") }
    "misasme"         = @{ Exe = "MISA.SME.Client.exe"; ProcessName = "MISA.SME.Client"; CommonPaths = @("$env:ProgramFiles\MISA JSC\MISA SME\Bin\MISA.SME.Client.exe", "${env:ProgramFiles(x86)}\MISA JSC\MISA SME\Bin\MISA.SME.Client.exe") }
    "meinvoice"       = @{ Exe = "meInvoice.exe"; ProcessName = "meInvoice"; CommonPaths = @("$env:ProgramFiles\MISA JSC\meInvoice\meInvoice.exe", "${env:ProgramFiles(x86)}\MISA JSC\meInvoice\meInvoice.exe") }
    "kbhxh"           = @{ Exe = "KBHXH.exe"; ProcessName = "KBHXH"; CommonPaths = @("$env:ProgramFiles\KBHXH\KBHXH.exe", "${env:ProgramFiles(x86)}\KBHXH\KBHXH.exe") }
    "dvcplugin"       = @{ Exe = "VNPT_Plugin.exe"; ProcessName = "VNPT_Plugin"; CommonPaths = @("${env:ProgramFiles(x86)}\VNPT\VNPT Plugin\VNPT_Plugin.exe", "$env:ProgramFiles\VNPT\VNPT Plugin\VNPT_Plugin.exe") }
    "vietteltoken"    = @{ Exe = "Viettel-CA_v2.exe"; ProcessName = "Viettel-CA_v2"; CommonPaths = @("${env:ProgramFiles(x86)}\Viettel-CA\Viettel-CA Token Manager v2\Viettel-CA_v2.exe", "$env:ProgramFiles\Viettel-CA\Viettel-CA Token Manager v2\Viettel-CA_v2.exe") }
    "vnpttoken"       = @{ Exe = "vnpt-ca_cl.exe"; ProcessName = "vnpt-ca_cl"; CommonPaths = @("${env:ProgramFiles(x86)}\VNPT-CA\VNPT-CA Token Manager\vnpt-ca_cl.exe", "$env:ProgramFiles\VNPT-CA\VNPT-CA Token Manager\vnpt-ca_cl.exe") }
    "misakyso"        = @{ Exe = "MISA.KySo.exe"; ProcessName = "MISA.KySo"; CommonPaths = @("${env:ProgramFiles(x86)}\MISA JSC\MISA KySo\MISA.KySo.exe", "$env:ProgramFiles\MISA JSC\MISA KySo\MISA.KySo.exe") }
    "esigner"         = @{ Exe = "eSigner.exe"; ProcessName = "eSigner"; CommonPaths = @("${env:ProgramFiles(x86)}\eSigner\eSigner.exe", "$env:ProgramFiles\eSigner\eSigner.exe", "${env:ProgramFiles(x86)}\eSigner Java\eSigner.exe") }
    "netfx35"         = @{ Exe = ""; ProcessName = ""; CommonPaths = @("$env:SystemRoot\Microsoft.NET\Framework\v3.5", "$env:SystemRoot\Microsoft.NET\Framework64\v3.5") }
}

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

function Invoke-VUONGTTProcessWithLiveLog {
    param(
        [string]$FilePath,
        [string]$ArgumentList,
        [scriptblock]$OnOutputLine,
        [int]$TimeoutSeconds = 600
    )

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.Arguments = $ArgumentList
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo = $psi
        $proc.EnableRaisingEvents = $true

        # Hang doi dong bo an toan da luong tranh deadlock va nghe pipe
        $logQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

        $outHandler = [System.Diagnostics.DataReceivedEventHandler]{
            param($sender, $e)
            if ($e -and $e.Data) { $logQueue.Enqueue($e.Data) }
        }
        $errHandler = [System.Diagnostics.DataReceivedEventHandler]{
            param($sender, $e)
            if ($e -and $e.Data) { $logQueue.Enqueue($e.Data) }
        }

        $proc.add_OutputDataReceived($outHandler)
        $proc.add_ErrorDataReceived($errHandler)

        $started = $proc.Start()
        if (-not $started) {
            if ($OnOutputLine) { & $OnOutputLine "[LỖI] Không thể khởi chạy tiến trình: $FilePath" }
            return -1
        }

        $proc.BeginOutputReadLine()
        $proc.BeginErrorReadLine()

        $timeoutAt = (Get-Date).AddSeconds($TimeoutSeconds)

        while (-not $proc.HasExited) {
            $line = ""
            while ($logQueue.TryDequeue([ref]$line)) {
                if ($line -and $OnOutputLine) { & $OnOutputLine $line }
            }
            Start-Sleep -Milliseconds 60
            Invoke-VUONGTTDoEvents

            if ((Get-Date) -gt $timeoutAt) {
                if ($OnOutputLine) { & $OnOutputLine "[CẢNH BÁO] Quá thời gian chờ ($TimeoutSeconds giây), tự động đóng tiến trình..." }
                try { $proc.Kill() } catch {}
                break
            }
        }

        # Doc not cac dong log con sot lai sau khi tien trinh ket thuc
        Start-Sleep -Milliseconds 120
        $line = ""
        while ($logQueue.TryDequeue([ref]$line)) {
            if ($line -and $OnOutputLine) { & $OnOutputLine $line }
        }
        Invoke-VUONGTTDoEvents

        return $proc.ExitCode
    } catch {
        if ($OnOutputLine) { & $OnOutputLine "[LỖI TIẾN TRÌNH] $($_.Exception.Message)" }
        return -999
    }
}

function Start-VUONGTTInstalledApp {
    param(
        [string]$AppId,
        [string]$HintName = "",
        [scriptblock]$OnLog = $null
    )

    try {
        $cleanId = $AppId.Trim().ToLower()
        $map = $script:APP_EXEC_MAP[$cleanId]

        # 1. Thu tim theo danh sach duong dan chuan
        if ($map -and $map.CommonPaths) {
            foreach ($path in $map.CommonPaths) {
                if ($path -like "*\app-*\*") {
                    $expanded = Resolve-Path $path -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Path -First 1
                    if ($expanded -and (Test-Path $expanded)) {
                        if ($OnLog) { & $OnLog "  -> [TỰ ĐỘNG MỞ] Đang khởi chạy: $expanded" }
                        Start-Process -FilePath $expanded
                        return $true
                    }
                } elseif (Test-Path $path) {
                    if ($OnLog) { & $OnLog "  -> [TỰ ĐỘNG MỞ] Đang khởi chạy: $path" }
                    Start-Process -FilePath $path
                    return $true
                }
            }
        }

        # 2. Thu tra cuu Registry App Paths
        $targetExe = if ($map -and $map.Exe) { $map.Exe } else { "$cleanId.exe" }
        $regKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$targetExe",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$targetExe"
        )
        foreach ($rk in $regKeys) {
            if (Test-Path $rk) {
                $val = (Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue).'(default)'
                if ($val -and (Test-Path $val)) {
                    if ($OnLog) { & $OnLog "  -> [TỰ ĐỘNG MỞ] Khởi chạy từ App Paths: $val" }
                    Start-Process -FilePath $val
                    return $true
                }
            }
        }

        # 3. Thu tim qua System PATH
        $cmd = Get-Command $targetExe -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            if ($OnLog) { & $OnLog "  -> [TỰ ĐỘNG MỞ] Khởi chạy từ System PATH: $($cmd.Source)" }
            Start-Process -FilePath $cmd.Source
            return $true
        }

        # 4. Quet Shortcut (.lnk) trong Start Menu va Desktop
        $searchTerms = @($cleanId)
        if ($map -and $map.ProcessName) { $searchTerms += $map.ProcessName }
        if ($HintName) { $searchTerms += ($HintName -replace "[^\w\s]", "").Split(' ')[0] }

        $shortcutFolders = @(
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
            [Environment]::GetFolderPath("Desktop"),
            [Environment]::GetFolderPath("CommonDesktopDirectory")
        )

        foreach ($folder in $shortcutFolders) {
            if (Test-Path $folder) {
                foreach ($term in $searchTerms) {
                    if (-not $term -or $term.Length -lt 2) { continue }
                    $lnk = Get-ChildItem -Path $folder -Filter "*$term*.lnk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($lnk) {
                        if ($OnLog) { & $OnLog "  -> [TỰ ĐỘNG MỞ] Khởi chạy từ Shortcut: $($lnk.Name)" }
                        Start-Process -FilePath $lnk.FullName
                        return $true
                    }
                }
            }
        }

        if ($OnLog) { & $OnLog "  -> [THÔNG TIN] Đã cài xong, không tìm thấy file thực thi tự chạy cho '$cleanId'." }
        return $false
    } catch {
        if ($OnLog) { & $OnLog "  -> [CẢNH BÁO MỞ APP] $($_.Exception.Message)" }
        return $false
    }
}

function Install-VUONGTTCustomApp {
    param(
        [string]$TargetInput,
        [string]$SilentArgs = "",
        [scriptblock]$OnProgress = $null,
        [switch]$AutoLaunch = $true
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

        if ($OnProgress) { & $OnProgress "Đang thực thi tệp cài đặt $fileName (Real-time log)..." }
        try {
            $exitCode = Invoke-VUONGTTProcessWithLiveLog -FilePath $destFile -ArgumentList $SilentArgs -OnOutputLine $OnProgress
            if ($AutoLaunch) {
                $baseApp = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
                Start-VUONGTTInstalledApp -AppId $baseApp -HintName $baseApp -OnLog $OnProgress
            }
            return "[OK] Đã hoàn tất thực thi tệp cài đặt $fileName (Mã thoát: $exitCode)!"
        } catch {
            return "Lỗi khi khởi chạy: $($_.Exception.Message)"
        }
    } else {
        # Winget ID
        if ($OnProgress) { & $OnProgress "Đang cài đặt gói Winget '$inputClean' với luồng log chi tiết..." }
        try {
            $arg = "install --id `"$inputClean`" -e --silent --accept-package-agreements --accept-source-agreements --force"
            $exitCode = Invoke-VUONGTTProcessWithLiveLog -FilePath "winget.exe" -ArgumentList $arg -OnOutputLine $OnProgress
            $wingetOkCodes = @(0, -1978335189, -1978335215, -1978335188, 3010, 1641, 2316632065)
            if ($exitCode -in $wingetOkCodes) {
                if ($AutoLaunch) {
                    $pkgLeaf = $inputClean.Split('.')[-1]
                    Start-VUONGTTInstalledApp -AppId $pkgLeaf -HintName $pkgLeaf -OnLog $OnProgress
                }
                return "[OK] Đã cài đặt thành công ứng dụng '$inputClean' qua Winget (Mã: $exitCode)!"
            } else {
                return "Quá trình cài đặt Winget trả về mã: $exitCode"
            }
        } catch {
            return "Lỗi khi chạy Winget: $($_.Exception.Message)"
        }
    }
}

function Get-VUONGTTNetFx35Status {
    [CmdletBinding()]
    param()

    $isInstalled = $false
    $state = "Disabled"
    $details = ""

    try {
        # 1. Kiem tra nhanh qua Registry NDP v3.5
        $regKey = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5"
        if (Test-Path $regKey) {
            $inst = (Get-ItemProperty -Path $regKey -Name "Install" -ErrorAction SilentlyContinue).Install
            if ($inst -eq 1) {
                $isInstalled = $true
                $state = "Enabled"
                $details = "Đã cài đặt hoàn chỉnh (.NET Framework 2.0, 3.0, 3.5)"
            }
        }

        # 2. Kiem tra bo sung qua Windows Optional Feature
        if (-not $isInstalled) {
            $feat = Get-WindowsOptionalFeature -Online -FeatureName "NetFx3" -ErrorAction SilentlyContinue
            if ($feat -and $feat.State -eq "Enabled") {
                $isInstalled = $true
                $state = "Enabled"
                $details = "Tính năng Windows NetFx3 đang ở trạng thái Enabled"
            } elseif ($feat) {
                $state = $feat.State.ToString()
                $details = "Tính năng Windows NetFx3: $state"
            }
        }
    } catch {
        $details = $_.Exception.Message
    }

    return [PSCustomObject]@{
        IsInstalled = $isInstalled
        State       = $state
        Details     = $details
    }
}

function Install-VUONGTTNetFx35 {
    [CmdletBinding()]
    param(
        [scriptblock]$OnProgress = $null
    )

    $log = @()
    $msg = "Bắt đầu kiểm tra và cài đặt .NET Framework 3.5 (.NET 2.0 & 3.0)..."
    $log += $msg
    if ($OnProgress) { & $OnProgress $msg }

    # 1. Kiem tra xem may da co .NET 3.5 chua
    $status = Get-VUONGTTNetFx35Status
    if ($status.IsInstalled) {
        $msgOk = "[OK] .NET Framework 3.5 đã được cài đặt sẵn trên máy tính này!"
        $log += $msgOk
        if ($OnProgress) { & $OnProgress $msgOk }
        return $msgOk
    }

    # 2. Tu dong kiem tra va khoi dong Windows Update service (wuauserv) neu bi tat
    try {
        $wuSvc = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
        if ($wuSvc) {
            if ($wuSvc.StartType -eq "Disabled") {
                if ($OnProgress) { & $OnProgress "  -> Kích hoạt lại dịch vụ Windows Update (wuauserv)..." }
                Set-Service -Name "wuauserv" -StartupType Manual -ErrorAction SilentlyContinue
            }
            if ($wuSvc.Status -ne "Running") {
                Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    # 3. Kiem tra va bypass tam thoi WSUS (UseWUServer) neu co de tranh loi 0x800F0954
    $wsusKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    $origUseWUServer = $null
    $hasBypassedWsus = $false
    try {
        if (Test-Path $wsusKey) {
            $origUseWUServer = (Get-ItemProperty -Path $wsusKey -Name "UseWUServer" -ErrorAction SilentlyContinue).UseWUServer
            if ($origUseWUServer -eq 1) {
                if ($OnProgress) { & $OnProgress "  -> Phát hiện chính sách WSUS nội bộ. Đang tạm thời chuyển sang Microsoft Update..." }
                Set-ItemProperty -Path $wsusKey -Name "UseWUServer" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                Restart-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
                $hasBypassedWsus = $true
            }
        }
    } catch {}

    try {
        $msgDism = "Đang kích hoạt gói tính năng .NET Framework 3.5 từ máy chủ Microsoft (DISM)..."
        $log += $msgDism
        if ($OnProgress) { & $OnProgress $msgDism }

        # Chay DISM de Enable-Feature NetFx3
        $dismArgs = "/online /enable-feature /featurename:NetFx3 /all /norestart"
        $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
            Start-VUONGTTProcessResponsive -FilePath "dism.exe" -ArgumentList $dismArgs -TimeoutSeconds 900 -NoNewWindow $true
        } else {
            (Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -Wait -PassThru -NoNewWindow).ExitCode
        }

        # Kiem tra ket qua
        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            $msgSucc = "[OK] Đã kích hoạt và cài đặt thành công .NET Framework 3.5 (.NET 2.0 & 3.0)!"
            $log += $msgSucc
            if ($OnProgress) { & $OnProgress $msgSucc }
            return $msgSucc
        }

        # Fallback qua PowerShell Enable-WindowsOptionalFeature
        if ($OnProgress) { & $OnProgress "  -> DISM trả về mã $exitCode. Đang thử phương án dự phòng WindowsOptionalFeature..." }
        try {
            $featRes = Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart -ErrorAction Stop
            if ($featRes -and ($featRes.RestartNeeded -or $featRes.Online)) {
                $msgSucc2 = "[OK] Cài đặt thành công .NET Framework 3.5 qua WindowsOptionalFeature!"
                $log += $msgSucc2
                if ($OnProgress) { & $OnProgress $msgSucc2 }
                return $msgSucc2
            }
        } catch {
            $log += "[CẢNH BÁO] OptionalFeature error: $($_.Exception.Message)"
        }

        $msgFail = "[LỖI] Cài đặt .NET Framework 3.5 không thành công (DISM ExitCode: $exitCode). Vui lòng kiểm tra kết nối mạng Internet hoặc tường lửa."
        $log += $msgFail
        if ($OnProgress) { & $OnProgress $msgFail }
        return $msgFail

    } finally {
        # Khoi phuc lai gia tri WSUS goc neu da bypass
        if ($hasBypassedWsus -and $origUseWUServer -ne $null) {
            try {
                Set-ItemProperty -Path $wsusKey -Name "UseWUServer" -Value $origUseWUServer -Type DWord -Force -ErrorAction SilentlyContinue
                Restart-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

function Install-VUONGTTApp {
    param(
        [string]$AppId,
        [scriptblock]$OnProgress = $null,
        [switch]$AutoLaunch = $true
    )

    if ($AppId -in @("netfx35", "dotnet35")) {
        return Install-VUONGTTNetFx35 -OnProgress $OnProgress
    }

    if ($AppId -in @("htkk", "itaxviewer", "misasme", "meinvoice", "kbhxh", "javatax", "dvcplugin", "vietteltoken", "vnpttoken", "misakyso", "esigner")) {
        if ([bool](Get-Command "Install-VUONGTTAccountingApp" -ErrorAction SilentlyContinue)) {
            $res = Install-VUONGTTAccountingApp -AppId $AppId -OnProgress $OnProgress
            if ($AutoLaunch) {
                Start-VUONGTTInstalledApp -AppId $AppId -OnLog $OnProgress
            }
            return $res
        }
    }

    $app = $script:VUONGTT_APPS | Where-Object { $_.Id -eq $AppId }
    if (-not $app) { return "Không tìm thấy phần mềm: $AppId" }

    if ($app.IsOffice) {
        if ($OnProgress) { & $OnProgress "Đang chuẩn bị gói cài đặt Microsoft 365 mới nhất từ máy chủ Microsoft..." }
        $cfg = New-VUONGTTOfficeConfig -Version "O365ProPlusRetail" -Arch "64" -Channel "Current" -PrimaryLang "vi-vn"
        $p = Start-VUONGTTOfficeInstall -ConfigFile $cfg -OnProgress $OnProgress
        if ($AutoLaunch) {
            Start-VUONGTTInstalledApp -AppId "office365" -HintName "Word" -OnLog $OnProgress
        }
        return "Gói cài đặt Microsoft 365 đã được khởi động ngầm từ CDN Microsoft!"
    }

    $hasWinget = Test-VUONGTTWinget
    $wingetOkCodes = @(0, -1978335189, -1978335215, -1978335188, 3010, 1641, 2316632065)

    if ($hasWinget -and -not [string]::IsNullOrEmpty($app.WingetId)) {
        if ($OnProgress) { & $OnProgress "Đang cài đặt $($app.Name) qua Winget (Phiên bản mới nhất)..." }
        try {
            $arg = "install --id `"$($app.WingetId)`" -e --silent --accept-package-agreements --accept-source-agreements --force"
            $exitCode = Invoke-VUONGTTProcessWithLiveLog -FilePath "winget.exe" -ArgumentList $arg -OnOutputLine $OnProgress
            if ($exitCode -in $wingetOkCodes) {
                if ($AutoLaunch) {
                    Start-VUONGTTInstalledApp -AppId $app.Id -HintName $app.Name -OnLog $OnProgress
                }
                return "Đã cài đặt thành công $($app.Name) (phiên bản mới nhất qua Winget)!"
            } else {
                # Nếu đã có bản cũ, thử lệnh upgrade để cập nhật bản mới nhất
                if ($OnProgress) { & $OnProgress "  -> Thử cập nhật bản mới nhất qua Winget upgrade..." }
                $upgArg = "upgrade --id `"$($app.WingetId)`" -e --silent --accept-package-agreements --accept-source-agreements"
                $upgExitCode = Invoke-VUONGTTProcessWithLiveLog -FilePath "winget.exe" -ArgumentList $upgArg -OnOutputLine $OnProgress
                if ($upgExitCode -in $wingetOkCodes) {
                    if ($AutoLaunch) {
                        Start-VUONGTTInstalledApp -AppId $app.Id -HintName $app.Name -OnLog $OnProgress
                    }
                    return "Đã cập nhật $($app.Name) lên phiên bản mới nhất qua Winget!"
                }
            }
        } catch {
            if ($OnProgress) { & $OnProgress "  -> Winget gặp sự cố, chuyển sang tải trực tiếp từ máy chủ..." }
        }
    }

    # Fallback direct download
    if ([string]::IsNullOrWhiteSpace($app.Url)) {
        if (-not [string]::IsNullOrEmpty($app.WingetId)) {
            return "Phần mềm '$($app.Name)' yêu cầu tiện ích WinGet trên Windows để cài đặt tự động (Mã gói: $($app.WingetId)). Vui lòng kiểm tra dịch vụ WinGet trên máy."
        } else {
            return "Chưa cấu hình liên kết tải trực tiếp cho '$($app.Name)'."
        }
    }

    $destFolder = "$env:TEMP\VUONGTT_Apps"
    if (-not (Test-Path $destFolder)) { New-Item -ItemType Directory -Path $destFolder -Force | Out-Null }

    $isZip = ($app.IsZip -eq $true -or $app.Url -like "*.zip")
    $ext = if ($isZip) { ".zip" } else { ".exe" }
    $destFile = Join-Path $destFolder "$($app.Id)$ext"

    if ($OnProgress) { & $OnProgress "Đang tải $($app.Name) từ máy chủ chính thức: $($app.Url)..." }
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

    $dlSuccess = $false
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36")
        
        $script:dlIsDone = $false
        $script:dlLastReport = 0

        $wc.add_DownloadProgressChanged({
            param($s, $e)
            if ($e.ProgressPercentage -ge ($script:dlLastReport + 10) -or $e.ProgressPercentage -eq 100) {
                $script:dlLastReport = $e.ProgressPercentage
                $mbRec = [Math]::Round($e.BytesReceived / 1MB, 1)
                $mbTot = [Math]::Round($e.TotalBytesToReceive / 1MB, 1)
                if ($OnProgress) { & $OnProgress "  -> Đang tải: $($e.ProgressPercentage)% ($mbRec MB / $mbTot MB)..." }
            }
            Invoke-VUONGTTDoEvents
        })
        $wc.add_DownloadFileCompleted({
            param($s, $e)
            $script:dlIsDone = $true
        })

        $script:dlIsDone = $false
        $wc.DownloadFileAsync((New-Object System.Uri($app.Url)), $destFile)

        $dlTimeout = (Get-Date).AddMinutes(10)
        while (-not $script:dlIsDone -and (Get-Date) -lt $dlTimeout) {
            Start-Sleep -Milliseconds 60
            Invoke-VUONGTTDoEvents
        }

        if ((Test-Path $destFile) -and (Get-Item $destFile).Length -gt 1024) { $dlSuccess = $true }
    } catch {}

    if (-not $dlSuccess) {
        try {
            Invoke-WebRequest -Uri $app.Url -OutFile $destFile -UseBasicParsing -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" -TimeoutSec 60
            if ((Test-Path $destFile) -and (Get-Item $destFile).Length -gt 1024) { $dlSuccess = $true }
        } catch {
            return "Lỗi tải tệp: $($_.Exception.Message)"
        }
    }

    if (-not (Test-Path $destFile) -or (Get-Item $destFile).Length -le 1024) {
        return "Lỗi tải tệp: Tệp tải về không hợp lệ hoặc máy chủ từ chối kết nối!"
    }

    if ($isZip) {
        if ($OnProgress) { & $OnProgress "Đang giải nén $($app.Name)..." }
        $extractDir = "$env:SystemDrive\Tools\$($app.Id)"
        Expand-Archive -Path $destFile -DestinationPath $extractDir -Force
        if ($AutoLaunch) {
            Start-VUONGTTInstalledApp -AppId $app.Id -HintName $app.Name -OnLog $OnProgress
        }
        return "Đã tải và giải nén thành công vào: $extractDir"
    } else {
        if ($OnProgress) { & $OnProgress "Đang cài đặt tự động $($app.Name) (chạy ngầm silent)..." }
        $exitCode = Invoke-VUONGTTProcessWithLiveLog -FilePath $destFile -ArgumentList $app.Silent -OnOutputLine $OnProgress
        if ($AutoLaunch) {
            Start-VUONGTTInstalledApp -AppId $app.Id -HintName $app.Name -OnLog $OnProgress
        }
        return "Đã hoàn tất cài đặt $($app.Name) (Mã trả về: $exitCode)!"
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
        private string _displayIcon = "";

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

        public string DisplayIcon
        {
            get { return _displayIcon; }
            set { _displayIcon = value; OnPropertyChanged("DisplayIcon"); }
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
            $isTeamsApp = ($name -and ($name -like "*Teams*" -or $_.PSChildName -like "*Teams*"))
            $isAllowed = (-not $_.ParentKeyName) -and ((-not $_.SystemComponent) -or $isTeamsApp)
            if ($name -and ($name.Trim().Length -gt 0) -and $isAllowed) {
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
                    try {
                        $appItem.DisplayIcon      = if ($_.DisplayIcon) { $_.DisplayIcon.Trim() } else { "" }
                    } catch {}

                    $apps.Add($appItem)
                }
            }
        }
    }

    # Quét thêm Modern Store / AppX Packages (New Microsoft Teams, Skype, WhatsApp, ...)
    try {
        $appxList = Get-AppxPackage -ErrorAction SilentlyContinue | Where-Object {
            (-not $_.IsFramework) -and ($_.NonRemovable -ne $true)
        }

        $appxFriendlyNames = @{
            "MSTeams"                               = "Microsoft Teams (work or school)"
            "MicrosoftTeams"                        = "Microsoft Teams"
            "Microsoft.Teams"                       = "Microsoft Teams"
            "Microsoft.SkypeApp"                    = "Skype"
            "Microsoft.OneDriveSync"                = "Microsoft OneDrive"
            "Microsoft.Todos"                       = "Microsoft To Do"
            "Microsoft.Whiteboard"                  = "Microsoft Whiteboard"
            "Microsoft.Paint"                       = "Paint (Store)"
            "Microsoft.MSPaint"                     = "Paint 3D / Paint"
            "Microsoft.WindowsTerminal"             = "Windows Terminal"
            "Microsoft.PowerToys"                   = "Microsoft PowerToys"
            "SpotifyAB.SpotifyMusic"                = "Spotify"
            "5319275A.WhatsAppDesktop"              = "WhatsApp Desktop"
            "TelegramMessengerLLP.TelegramDesktop"  = "Telegram Desktop"
            "AgileBits.1Password"                   = "1Password"
            "Microsoft.BingNews"                    = "Bing News"
            "Microsoft.BingWeather"                 = "Bing Weather"
            "Microsoft.BingSearch"                  = "Bing Search"
            "Clipchamp.Clipchamp"                   = "Clipchamp Video Editor"
            "Microsoft.Clipchamp"                   = "Clipchamp Video Editor"
            "Microsoft.ClientWebExperience"         = "Windows Widgets (Web Experience)"
            "Microsoft.CrossDevice"                 = "Cross Device Experience Host"
            "Microsoft.ActionsServer"               = "Actions Server"
            "Microsoft.AV1VideoExtension"           = "AV1 Video Extension"
            "Microsoft.AVCEncoderVideoExtension"    = "AVC Encoder Video Extension"
            "Microsoft.VP9VideoExtensions"          = "VP9 Video Extensions"
            "Microsoft.HEIFImageExtension"          = "HEIF Image Extension"
            "Microsoft.RawImageExtension"           = "Raw Image Extension"
            "Microsoft.WebpImageExtension"          = "WebP Image Extension"
        }

        foreach ($pkg in $appxList) {
            $pName = $pkg.Name
            $fullName = $pkg.PackageFullName

            # Bỏ qua các runtime / framework ngầm của Windows
            if ($pName -like "Microsoft.VCLibs*" -or $pName -like "Microsoft.NET.Native*" -or
                $pName -like "Microsoft.UI.Xaml*" -or $pName -like "*LanguageExperiencePack*" -or
                $pName -like "*BrokerPlugin*" -or $pName -like "windows.*" -or
                $pName -like "Microsoft.Windows.ContentDeliveryManager*") {
                continue
            }

            $displayName = ""
            if ($appxFriendlyNames.ContainsKey($pName)) {
                $displayName = $appxFriendlyNames[$pName]
            } elseif ($pName -match 'Teams') {
                $displayName = "Microsoft Teams"
            } else {
                # Loại bỏ prefix namespace của Package (Microsoft., AgileBits., v.v.)
                $displayName = $pName -replace '^Microsoft\.', '' -replace '^[0-9A-Za-z]+\.', ''
                # TÁCH CAMELCASE BẮT BUỘC DÙNG -creplace (Case-Sensitive): Chữ thường đi liền chữ hoa (ví dụ: BingNews -> Bing News)
                $displayName = $displayName -creplace '([a-z])([A-Z])', '$1 $2'
                $displayName = $displayName.Trim()
            }

            if (-not $displayName) { $displayName = $pName }

            $keyUnique = "$displayName|$($pkg.Version)"
            if (-not $seen.Contains($keyUnique)) {
                $null = $seen.Add($keyUnique)

                $appItem = [VUONGTT.InstalledAppItem]::new()
                $appItem.IsChecked            = $false
                $appItem.DisplayName          = $displayName.Trim()
                $appItem.DisplayVersion       = if ($pkg.Version) { "$($pkg.Version)".Trim() } else { "--" }
                $appItem.Publisher            = if ($pkg.PublisherId -eq "8wekyb3d8bbwe") { "Microsoft Corporation" } else { "Microsoft Store / UWP" }
                $appItem.InstallDate          = "--"
                $appItem.SizeMb               = 120
                $appItem.SizeFormatted        = "120 MB"
                $appItem.InstallLocation      = if ($pkg.InstallLocation) { $pkg.InstallLocation } else { "" }
                $appItem.UninstallString      = "AppX:$fullName"
                $appItem.QuietUninstallString = "AppX:$fullName"
                $appItem.RegistryPath         = "AppX:\$fullName"
                $appItem.RegistryKeyName      = $fullName
                $appItem.DisplayIcon          = ""

                $apps.Add($appItem)
            }
        }
    } catch {}

    # Thăm dò dự phòng chuyên biệt cho Microsoft Teams (Disk Executables & Provisioned Packages)
    try {
        $hasTeamsInList = ($apps | Where-Object { $_.DisplayName -match 'Teams' -and $_.DisplayName -notmatch 'Add-in' }).Count -gt 0
        if (-not $hasTeamsInList) {
            # 1. Kiểm tra Teams Squirrel Classic trên đĩa
            $teamsExe = "$env:LOCALAPPDATA\Microsoft\Teams\current\Teams.exe"
            $teamsUpdateExe = "$env:LOCALAPPDATA\Microsoft\Teams\Update.exe"
            if (Test-Path $teamsExe -ErrorAction SilentlyContinue) {
                $ver = try { (Get-Item $teamsExe -ErrorAction SilentlyContinue).VersionInfo.ProductVersion } catch { "--" }
                $appItem = [VUONGTT.InstalledAppItem]::new()
                $appItem.IsChecked            = $false
                $appItem.DisplayName          = "Microsoft Teams (Classic)"
                $appItem.DisplayVersion       = if ($ver) { $ver } else { "--" }
                $appItem.Publisher            = "Microsoft Corporation"
                $appItem.InstallDate          = "--"
                $appItem.SizeMb               = 180
                $appItem.SizeFormatted        = "180 MB"
                $appItem.InstallLocation      = "$env:LOCALAPPDATA\Microsoft\Teams"
                $appItem.UninstallString      = if (Test-Path $teamsUpdateExe) { "`"$teamsUpdateExe`" --uninstall -s" } else { "cmd.exe /c rmdir /s /q `"$env:LOCALAPPDATA\Microsoft\Teams`"" }
                $appItem.QuietUninstallString = $appItem.UninstallString
                $appItem.RegistryPath         = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
                $appItem.RegistryKeyName      = "Teams"
                $apps.Add($appItem)
            }

            # 2. Kiểm tra New Teams MSIX trong WindowsApps
            $newTeamsExe = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Filter "ms-teams.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($newTeamsExe) {
                $appItem = [VUONGTT.InstalledAppItem]::new()
                $appItem.IsChecked            = $false
                $appItem.DisplayName          = "Microsoft Teams (work or school)"
                $appItem.DisplayVersion       = try { (Get-Item $newTeamsExe.FullName -ErrorAction SilentlyContinue).VersionInfo.ProductVersion } catch { "--" }
                $appItem.Publisher            = "Microsoft Corporation"
                $appItem.InstallDate          = "--"
                $appItem.SizeMb               = 150
                $appItem.SizeFormatted        = "150 MB"
                $appItem.InstallLocation      = Split-Path $newTeamsExe.FullName -Parent
                $appItem.UninstallString      = "AppX:MSTeams"
                $appItem.QuietUninstallString = "AppX:MSTeams"
                $appItem.RegistryPath         = "AppX:\MSTeams"
                $appItem.RegistryKeyName      = "MSTeams"
                $apps.Add($appItem)
            }
        }
    } catch {}

    $sorted = $apps | Sort-Object DisplayName

    if ($FilterText -and $FilterText.Trim().Length -gt 0) {
        $q = $FilterText.Trim()
        $sorted = $sorted | Where-Object {
            $_.DisplayName -like "*$q*" -or $_.Publisher -like "*$q*" -or $_.DisplayVersion -like "*$q*"
        }
    }

    return @($sorted)
}

# ==============================================================================
# BỘ HÀM PHỤ TRỢ CHO CLEAN UNINSTALLER ENGINE
# ==============================================================================

function Resolve-VUONGTTExecutableAndArgs {
    param([string]$CmdLine)

    if ([string]::IsNullOrWhiteSpace($CmdLine)) {
        return @{ Exe = ""; Args = "" }
    }

    $trimmed = $CmdLine.Trim()

    # Case 1: Có ngoặc kép bao quanh "C:\Path\To\file.exe" args...
    if ($trimmed -match '^"([^"]+)"\s*(.*)$') {
        return @{
            Exe  = $matches[1].Trim()
            Args = $matches[2].Trim()
        }
    }

    # Case 2: Không có ngoặc kép nhưng có chứa khoảng trắng.
    # Thử từng phân đoạn từ trái sang phải để tìm file thực tế trên đĩa
    $tokens = $trimmed -split '\s+'
    $candidate = ""
    $foundIndex = -1

    for ($i = 0; $i -lt $tokens.Count; $i++) {
        if ($i -eq 0) { $candidate = $tokens[0] }
        else { $candidate = "$candidate $($tokens[$i])" }

        # Kiểm tra nếu candidate là file .exe/.bat/.cmd/.vbs tồn tại
        if ($candidate -match '\.(exe|bat|cmd|vbs)$' -and (Test-Path $candidate -PathType Leaf -ErrorAction SilentlyContinue)) {
            $exe = $candidate
            $foundIndex = $i
            break
        }
    }

    if ($foundIndex -ge 0) {
        $remainingTokens = if ($foundIndex + 1 -lt $tokens.Count) {
            $tokens[($foundIndex + 1)..($tokens.Count - 1)] -join " "
        } else { "" }
        return @{
            Exe  = $exe
            Args = $remainingTokens.Trim()
        }
    }

    # Case 3: Phân đoạn tại khoảng trắng đầu tiên
    if ($trimmed -match '^([^\s]+)\s*(.*)$') {
        return @{
            Exe  = $matches[1].Trim()
            Args = $matches[2].Trim()
        }
    }

    return @{ Exe = $trimmed; Args = "" }
}

function Get-VUONGTTResolvedInstallLocations {
    param(
        [PSCustomObject]$AppItem,
        [string[]]$CleanTerms
    )

    $resolvedDirs = [System.Collections.Generic.List[string]]::new()

    # 1. Thư mục từ InstallLocation
    if ($AppItem.InstallLocation -and (Test-Path $AppItem.InstallLocation -ErrorAction SilentlyContinue)) {
        $resolvedDirs.Add($AppItem.InstallLocation.TrimEnd('\'))
    }

    # 2. Thư mục từ DisplayIcon
    $iconPath = ""
    try {
        if ($AppItem.DisplayIcon) { $iconPath = $AppItem.DisplayIcon }
    } catch {}

    if (-not $iconPath -and $AppItem.RegistryPath -and (Test-Path $AppItem.RegistryPath -ErrorAction SilentlyContinue)) {
        $regProps = Get-ItemProperty -Path $AppItem.RegistryPath -ErrorAction SilentlyContinue
        if ($regProps -and $regProps.DisplayIcon) {
            $iconPath = "$($regProps.DisplayIcon)"
        }
    }

    if ($iconPath) {
        $cleanIcon = ($iconPath -replace ',\s*-?[0-9]+$', '') -replace '^"|"$', ''
        if (Test-Path $cleanIcon -ErrorAction SilentlyContinue) {
            $parentDir = Split-Path -Path $cleanIcon -Parent
            if ($parentDir -and (Test-Path $parentDir -ErrorAction SilentlyContinue)) {
                $resolvedDirs.Add($parentDir.TrimEnd('\'))
            }
        }
    }

    # 3. Thư mục từ UninstallString
    $rawUninst = if ($AppItem.QuietUninstallString) { $AppItem.QuietUninstallString } else { $AppItem.UninstallString }
    if ($rawUninst -and $rawUninst -notmatch '\{[0-9A-Fa-f\-]{36}\}') {
        $parsed = Resolve-VUONGTTExecutableAndArgs -CmdLine $rawUninst
        if ($parsed.Exe -and (Test-Path $parsed.Exe -ErrorAction SilentlyContinue)) {
            $parentDir = Split-Path -Path $parsed.Exe -Parent
            if ($parentDir -and (Test-Path $parentDir -ErrorAction SilentlyContinue)) {
                $resolvedDirs.Add($parentDir.TrimEnd('\'))
            }
        }
    }

    # 4. Thăm dò trong các thư mục Program Files tiêu chuẩn theo CleanTerms
    $standardRoots = @(
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        "$env:LOCALAPPDATA\Programs"
    )

    foreach ($term in $CleanTerms) {
        if ($term.Length -ge 3) {
            foreach ($root in $standardRoots) {
                if ($root -and (Test-Path $root -ErrorAction SilentlyContinue)) {
                    $probe = Join-Path $root $term
                    if (Test-Path $probe -PathType Container -ErrorAction SilentlyContinue) {
                        $resolvedDirs.Add($probe.TrimEnd('\'))
                    }
                }
            }
        }
    }

    # Lọc an toàn tuyệt đối: Không bao giờ được phép xóa các thư mục gốc hoặc thư mục hệ thống
    $safeDirs = [System.Collections.Generic.List[string]]::new()
    $criticalRoots = @(
        "$env:SystemDrive\",
        "$env:SystemDrive",
        "$env:windir",
        "$env:windir\System32",
        "$env:ProgramFiles",
        "${env:ProgramFiles(x86)}",
        "$env:USERPROFILE",
        "$env:APPDATA",
        "$env:LOCALAPPDATA",
        "$env:ProgramData",
        "C:\Users",
        "C:\Users\Default"
    ) | ForEach-Object { $_.TrimEnd('\').ToLower() }

    foreach ($d in ($resolvedDirs | Select-Object -Unique)) {
        if (-not $d) { continue }
        $dNorm = $d.TrimEnd('\')
        $dLower = $dNorm.ToLower()

        if ($dNorm.Length -gt 10 -and $criticalRoots -notcontains $dLower) {
            $slashCount = ($dNorm.ToCharArray() | Where-Object { $_ -eq '\' }).Count
            if ($slashCount -ge 2) {
                $safeDirs.Add($dNorm)
            }
        }
    }

    return @($safeDirs | Select-Object -Unique)
}

function Stop-VUONGTTRelatedProcessesAndServices {
    param(
        [string[]]$TargetDirs,
        [string[]]$CleanTerms,
        [scriptblock]$OnLog
    )

    function Write-SubLog { param($m) if ($OnLog) { & $OnLog $m } }

    $whitelistProcesses = @("explorer", "taskmgr", "powershell", "pwsh", "cmd", "conhost", "svchost", "csrss", "lsass", "winlogon", "services", "dwm", "smss", "spoolsv", "vuongtt_toolkit", "devenv", "code")

    # 1. Quét và dừng Windows Services liên quan
    try {
        $services = Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue
        foreach ($svc in $services) {
            $pathName = $svc.PathName
            $svcName = $svc.Name
            $isRelated = $false

            if ($pathName) {
                foreach ($dir in $TargetDirs) {
                    if ($pathName -like "*$dir*") { $isRelated = $true; break }
                }
            }

            if (-not $isRelated) {
                foreach ($term in $CleanTerms) {
                    if ($term.Length -ge 4 -and ($svcName -like "*$term*" -or $svc.DisplayName -like "*$term*")) {
                        $isRelated = $true
                        break
                    }
                }
            }

            if ($isRelated -and $svcName -notlike "*Windows*" -and $svcName -notlike "*Microsoft*") {
                Write-SubLog "• Đang dừng dịch vụ nền liên quan: $svcName ($($svc.DisplayName))..."
                Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    # 2. Quét và dập tắt Processes liên quan khóa tệp
    try {
        $processes = Get-Process -ErrorAction SilentlyContinue
        foreach ($p in $processes) {
            $pName = $p.ProcessName.ToLower()
            if ($whitelistProcesses -contains $pName) { continue }

            $pPath = ""
            try { $pPath = $p.Path } catch {}
            if (-not $pPath) {
                try { $pPath = $p.MainModule.FileName } catch {}
            }

            $shouldKill = $false

            if ($pPath) {
                foreach ($dir in $TargetDirs) {
                    if ($pPath.StartsWith($dir, [System.StringComparison]::OrdinalIgnoreCase)) {
                        $shouldKill = $true
                        break
                    }
                }
            }

            if (-not $shouldKill) {
                foreach ($term in $CleanTerms) {
                    if ($term.Length -ge 3 -and $pName -eq $term.ToLower()) {
                        $shouldKill = $true
                        break
                    }
                }
            }

            if ($shouldKill) {
                Write-SubLog "• Đang dập tắt tiến trình khóa tệp: $($p.ProcessName) (PID: $($p.Id))..."
                try {
                    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
                    & taskkill.exe /F /PID $p.Id /T *>$null
                } catch {}
            }
        }
    } catch {}

    Start-Sleep -Milliseconds 250
}

function Remove-VUONGTTDirectoryThorough {
    param([string]$Path)

    if (-not (Test-Path $Path -ErrorAction SilentlyContinue)) { return $true }

    try {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
        return $true
    } catch {
        # Nếu bị lỗi lock, dọn dẹp từng file và áp dụng rename trick
        try {
            Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
                try {
                    $_.Attributes = 'Normal'
                    Remove-Item -Path $_.FullName -Force -ErrorAction Stop
                } catch {
                    $renamed = "$($_.FullName).del.$([Guid]::NewGuid().ToString('N').Substring(0,6))"
                    Rename-Item -Path $_.FullName -NewName $renamed -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path $renamed -Force -ErrorAction SilentlyContinue
                }
            }
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
            return (-not (Test-Path $Path -ErrorAction SilentlyContinue))
        } catch {
            return $false
        }
    }
}

# ==============================================================================
# HÀM CHÍNH: GỠ CÀI ĐẶT & GỠ SẠCH TRIỆT ĐỂ (TITANIUM CLEAN UNINSTALLER ENGINE)
# ==============================================================================

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

    # TẦNG 1: FINGERPRINT MATRIX (THU THẬP TỪ KHÓA & THƯ MỤC CÀI ĐẶT)
    $cleanTerms = [System.Collections.Generic.List[string]]::new()
    $baseName = $appName -replace '\s*(64-bit|32-bit|x64|x86|\(.*?\)|v?[0-9]+\.[0-9]+.*)$', ''
    $baseName = $baseName.Trim()

    if ($baseName.Length -ge 3) {
        $cleanTerms.Add($baseName)
    }

    # Thêm từ khóa tách biệt (ví dụ CPU-Z từ CPUID CPU-Z)
    $nameParts = $baseName -split '\s+'
    foreach ($part in $nameParts) {
        if ($part.Length -ge 4 -and $part -notmatch '^[0-9\.]+$') {
            $cleanTerms.Add($part)
        }
    }

    # Bổ sung Publisher nếu hợp lệ
    $publisher = if ($AppItem.Publisher) { $AppItem.Publisher.Trim() } else { "" }
    $forbiddenVendors = @("microsoft", "windows", "corporation", "chưa xác định", "unknown", "system", "intel", "amd", "realtek", "nvidia")
    if ($publisher.Length -ge 4 -and ($publisher.ToLower() -notin $forbiddenVendors)) {
        $cleanTerms.Add($publisher)
    }

    $forbiddenKeywords = @("windows", "microsoft", "system", "system32", "program files", "appdata", "users", "common files", "temp", "desktop", "intel", "amd", "realtek", "nvidia")
    $safeCleanTerms = @($cleanTerms | Select-Object -Unique | Where-Object { $_.ToLower() -notin $forbiddenKeywords -and $_.Length -ge 3 })

    # Nhận diện toàn bộ thư mục cài đặt gốc thực tế
    $targetInstallDirs = Get-VUONGTTResolvedInstallLocations -AppItem $AppItem -CleanTerms $safeCleanTerms

    # TẦNG 2: DẬP TẮT TIẾN TRÌNH & DỊCH VỤ ĐANG KHÓA TỆP TRƯỚC KHI GỠ
    if ($targetInstallDirs.Count -gt 0 -or $safeCleanTerms.Count -gt 0) {
        Stop-VUONGTTRelatedProcessesAndServices -TargetDirs $targetInstallDirs -CleanTerms $safeCleanTerms -OnLog $OnLog
    }

    # TẦNG 3: GIẢI MÃ CHUỖI LỆNH & GỌI UNINSTALLER GỐC
    $uninstCmd = if ($AppItem.QuietUninstallString) { $AppItem.QuietUninstallString } else { $AppItem.UninstallString }

    if (-not $uninstCmd) {
        Write-LogMsg "⚠️ [THÔNG BÁO] Ứng dụng không khai báo chuỗi UninstallString chính thống."
        if (-not $CleanDeepScan) {
            return "[THẤT BẠI] Ứng dụng không có chuỗi gỡ cài đặt trong Registry!"
        }
    } else {
        Write-LogMsg "• Lệnh gỡ bỏ phát hiện: $uninstCmd"
        try {
            # 3.0: Xử lý Modern Store / AppX / MSIX Package (New Microsoft Teams, Skype, ...)
            if ($uninstCmd -like "AppX:*") {
                $pkgFullName = $uninstCmd -replace '^AppX:', ''
                Write-LogMsg "• Phát hiện gói ứng dụng Modern Store/AppX: $pkgFullName"
                Write-LogMsg "• Đang thực hiện gỡ bỏ gói AppX qua PowerShell..."
                try {
                    Remove-AppxPackage -Package $pkgFullName -ErrorAction Stop
                    Write-LogMsg "✅ [THÀNH CÔNG] Đã gỡ bỏ AppX Package: $pkgFullName"
                } catch {
                    Write-LogMsg "⚠️ Gỡ AppX User: $($_.Exception.Message)"
                }

                # Nếu có quyền Administrator, gỡ cho AllUsers
                try {
                    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
                    if ($isAdmin) {
                        Remove-AppxPackage -Package $pkgFullName -AllUsers -ErrorAction SilentlyContinue
                        Write-LogMsg "✅ [ADMIN] Đã gỡ bỏ AppX Package trên phạm vi All Users."
                    }
                } catch {}

                # Nếu là Microsoft Teams, dọn dẹp thêm Provisioned Package
                if ($pkgFullName -like "*Teams*" -or $appName -like "*Teams*") {
                    try {
                        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object {
                            $_.DisplayName -match 'Teams' -or $_.PackageName -like "*Teams*"
                        } | ForEach-Object {
                            Write-LogMsg "• Đang gỡ bỏ AppX Provisioned Package: $($_.DisplayName)..."
                            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null
                            Write-LogMsg "✅ [ĐÃ XÓA PROVISIONED] $($_.DisplayName)"
                        }
                    } catch {}
                }
            } elseif ($uninstCmd -match '\{[0-9A-Fa-f\-]{36}\}') {
                # 3.1: Xử lý Windows Installer (MSI GUID)
                $guid = $matches[0]
                Write-LogMsg "• Phát hiện gói MSI Installer ($guid). Đang gọi MsiExec..."
                $msiArgs = if ($CleanDeepScan) { "/X$guid /qn /norestart" } else { "/X$guid /passive /norestart" }
                $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                    Start-VUONGTTProcessResponsive -FilePath "msiexec.exe" -ArgumentList $msiArgs -TimeoutSeconds 600 -NoNewWindow $false
                } else {
                    (Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru).ExitCode
                }
                Write-LogMsg "• MsiExec hoàn tất với mã thoát: $exitCode"
            } else {
                # 3.2: Xử lý tệp thực thi EXE thông minh (Smart Path Resolver)
                $resolved = Resolve-VUONGTTExecutableAndArgs -CmdLine $uninstCmd
                $exePath = $resolved.Exe
                $argList = $resolved.Args

                # Tự động tối ưu cờ Silent / Cưỡng chế khi người dùng chọn Gỡ Sạch Triệt Để
                if ($CleanDeepScan) {
                    $exeName = [System.IO.Path]::GetFileName($exePath).ToLower()
                    if ($exeName -like "*unins*.exe") {
                        # Inno Setup
                        if ($argList -notmatch '/(SILENT|VERYSILENT)') {
                            $argList = "$argList /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP-".Trim()
                        }
                    } elseif ($exeName -eq "uninstall.exe" -or $exeName -eq "uninst.exe") {
                        # NSIS
                        if ($argList -notmatch '/S') {
                            $argList = "$argList /S".Trim()
                        }
                    } elseif ($exeName -eq "setup.exe" -and $argList -like "*--uninstall*") {
                        # Chromium (Chrome, Brave, Edge)
                        if ($argList -notmatch '--force-uninstall') {
                            $argList = "$argList --force-uninstall --system-level".Trim()
                        }
                    }
                }

                if ($exePath -and (Test-Path $exePath -ErrorAction SilentlyContinue)) {
                    Write-LogMsg "• Đang khởi chạy uninstaller: `"$exePath`" $argList"
                    $workingDir = Split-Path -Path $exePath -Parent
                    $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                        Start-VUONGTTProcessResponsive -FilePath $exePath -ArgumentList $argList -WorkingDirectory $workingDir -TimeoutSeconds 600 -NoNewWindow $false
                    } else {
                        (Start-Process -FilePath $exePath -ArgumentList $argList -WorkingDirectory $workingDir -Wait -PassThru).ExitCode
                    }
                    Write-LogMsg "• Trình gỡ cài đặt kết thúc với mã thoát: $exitCode"
                } else {
                    Write-LogMsg "⚠️ Không thể tìm thấy file trực tiếp: $exePath. Thực thi qua cmd.exe..."
                    $exitCode = if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                        Start-VUONGTTProcessResponsive -FilePath "cmd.exe" -ArgumentList "/c `"$uninstCmd`"" -TimeoutSeconds 600 -NoNewWindow $true
                    } else {
                        (Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$uninstCmd`"" -Wait -PassThru).ExitCode
                    }
                    Write-LogMsg "• Lệnh kết thúc với mã thoát: $exitCode"
                }
            }
        } catch {
            Write-LogMsg "⚠️ Cảnh báo uninstaller: $($_.Exception.Message)"
        }
    }

    # BƯỚC 4, 5, 6, 7: CHẾ ĐỘ GỠ SẠCH TRIỆT ĐỂ (TITANIUM CLEAN DEEP SCAN)
    if ($CleanDeepScan) {
        Write-LogMsg "=========================================================="
        Write-LogMsg "🛡️ BẮT ĐẦU QUÉT & DỌN SẠCH TẬN GỐC (TITANIUM DEEP CLEAN)..."
        Write-LogMsg "=========================================================="

        # Dập tắt lại tiến trình lần 2 (nếu uninstaller vừa spawn thêm background process)
        Stop-VUONGTTRelatedProcessesAndServices -TargetDirs $targetInstallDirs -CleanTerms $safeCleanTerms -OnLog $null

        # TẦNG 4: CƯỠNG CHẾ XÓA THƯ MỤC CÀI ĐẶT GỐC
        if ($targetInstallDirs.Count -gt 0) {
            foreach ($dir in $targetInstallDirs) {
                if (Test-Path $dir -ErrorAction SilentlyContinue) {
                    $deleted = Remove-VUONGTTDirectoryThorough -Path $dir
                    if ($deleted) {
                        Write-LogMsg "✅ [ĐÃ XÓA SẠCH] Thư mục cài đặt gốc: $dir"
                    } else {
                        Write-LogMsg "⚠️ [ĐÃ ĐỔI TÊN/ĐÁNH DẤU XÓA] File bị khóa trong: $dir"
                    }
                }
            }
        }

        # TẦNG 4.1: XỬ LÝ DỌN DẸP TẬN GỐC CHUYÊN BIỆT CHO MICROSOFT TEAMS (WIN32 + APPX/MSIX)
        if ($appName -like "*Teams*" -or $uninstCmd -like "*Teams*") {
            Write-LogMsg "• Kích hoạt quy trình dọn dẹp chuyên sâu tận gốc Microsoft Teams..."
            
            # Dập tắt các tiến trình Teams còn sót
            Get-Process -Name "teams", "ms-teams", "msteams" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            
            # Gỡ bỏ toàn bộ gói AppX Teams còn lưu
            Get-AppxPackage -Name "*Teams*" -ErrorAction SilentlyContinue | ForEach-Object {
                Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue
                Write-LogMsg "✅ [ĐÃ XÓA GÓI APPX TEAMS] $($_.PackageFullName)"
            }

            # Xóa các thư mục rác chuyên biệt của Teams
            $teamsTrashDirs = @(
                "$env:LOCALAPPDATA\Microsoft\Teams",
                "$env:LOCALAPPDATA\Microsoft\TeamsMeetingAddin",
                "$env:LOCALAPPDATA\Microsoft\TeamsPresenceAddin",
                "$env:APPDATA\Microsoft\Teams",
                "$env:ProgramData\Microsoft\Teams",
                "C:\Program Files (x86)\Teams Installer"
            )
            Get-ChildItem -Path "$env:LOCALAPPDATA\Packages" -Directory -Filter "*Teams*" -ErrorAction SilentlyContinue | ForEach-Object {
                $teamsTrashDirs += $_.FullName
            }

            foreach ($td in $teamsTrashDirs) {
                if (Test-Path $td -ErrorAction SilentlyContinue) {
                    Remove-VUONGTTDirectoryThorough -Path $td | Out-Null
                    Write-LogMsg "✅ [ĐÃ XÓA THƯ MỤC TEAMS] $td"
                }
            }

            # Xóa autostart Run key của Teams
            $teamsRunKeys = @(
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
                "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
            )
            foreach ($rk in $teamsRunKeys) {
                if (Test-Path $rk -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty -Path $rk -Name "com.squirrel.Teams.Teams" -Force -ErrorAction SilentlyContinue
                    Remove-ItemProperty -Path $rk -Name "Teams" -Force -ErrorAction SilentlyContinue
                    Remove-ItemProperty -Path $rk -Name "MSTeams" -Force -ErrorAction SilentlyContinue
                }
            }
        }

        # TẦNG 5: QUÉT SÂU 2 CẤP APPDATA, LOCALAPPDATA, PROGRAMDATA (VENDOR + APP)
        $dataRoots = @(
            "$env:LOCALAPPDATA",
            "$env:APPDATA",
            "$env:ProgramData",
            "$env:ProgramFiles",
            "${env:ProgramFiles(x86)}",
            "$env:LOCALAPPDATA\Programs"
        )

        foreach ($dr in $dataRoots) {
            if (-not (Test-Path $dr -ErrorAction SilentlyContinue)) { continue }

            Get-ChildItem -Path $dr -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $dirName1 = $_.Name
                $dirPath1 = $_.FullName
                if ($dirName1.ToLower() -in $forbiddenKeywords) { return }

                # Kiểm tra khớp cấp 1
                $match1 = $false
                foreach ($term in $safeCleanTerms) {
                    if ($dirName1 -like "*$term*") { $match1 = $true; break }
                }

                if ($match1) {
                    Remove-VUONGTTDirectoryThorough -Path $dirPath1 | Out-Null
                    Write-LogMsg "✅ [ĐÃ DỌN RÁC APPDATA CẤP 1] $dirPath1"
                } else {
                    # Kiểm tra khớp cấp 2 (Thư mục Vendor chứa App)
                    Get-ChildItem -Path $dirPath1 -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                        $dirName2 = $_.Name
                        $dirPath2 = $_.FullName

                        $match2 = $false
                        foreach ($term in $safeCleanTerms) {
                            if ($dirName2 -like "*$term*") { $match2 = $true; break }
                        }

                        if ($match2) {
                            Remove-VUONGTTDirectoryThorough -Path $dirPath2 | Out-Null
                            Write-LogMsg "✅ [ĐÃ DỌN RÁC APPDATA CẤP 2] $dirPath2"

                            # Dọn dẹp thư mục Vendor nếu rỗng
                            $remaining = (Get-ChildItem -Path $dirPath1 -Force -ErrorAction SilentlyContinue).Count
                            if ($remaining -eq 0) {
                                Remove-Item -Path $dirPath1 -Force -ErrorAction SilentlyContinue
                                Write-LogMsg "✅ [ĐÃ DỌN THƯ MỤC VENDOR RỖNG] $dirPath1"
                            }
                        }
                    }
                }
            }
        }

        # TẦNG 6: DỌN DẸP REGISTRY CHUYÊN SÂU (UNINSTALL KEYS, SOFTWARE & STARTUP RUN)
        $uninstBranches = @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        )

        foreach ($ub in $uninstBranches) {
            if (-not (Test-Path $ub -ErrorAction SilentlyContinue)) { continue }
            Get-ChildItem -Path $ub -ErrorAction SilentlyContinue | ForEach-Object {
                $regKeyPath = $_.PSPath
                $regChild = $_.PSChildName
                $regProps = Get-ItemProperty -Path $regKeyPath -ErrorAction SilentlyContinue

                $shouldDelete = $false
                if ($AppItem.RegistryPath -and $regKeyPath -eq $AppItem.RegistryPath) {
                    $shouldDelete = $true
                } elseif ($AppItem.RegistryKeyName -and $regChild -eq $AppItem.RegistryKeyName) {
                    $shouldDelete = $true
                } elseif ($regProps -and $regProps.DisplayName -and $regProps.DisplayName.Trim() -eq $appName) {
                    $shouldDelete = $true
                }

                if ($shouldDelete) {
                    try {
                        Remove-Item -Path $regKeyPath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-LogMsg "✅ [ĐÃ XÓA MÃ GỠ BỎ REGISTRY] $regKeyPath"
                    } catch {}
                }
            }
        }

        # Quét Registry Software 2 cấp (HKCU & HKLM)
        $regRoots = @(
            "HKCU:\Software",
            "HKLM:\Software",
            "HKLM:\Software\Wow6432Node"
        )

        foreach ($rr in $regRoots) {
            if (-not (Test-Path $rr -ErrorAction SilentlyContinue)) { continue }
            Get-ChildItem -Path $rr -ErrorAction SilentlyContinue | ForEach-Object {
                $key1Name = $_.PSChildName
                $key1Path = $_.PSPath
                if ($key1Name.ToLower() -in $forbiddenKeywords) { return }

                $match1 = $false
                foreach ($term in $safeCleanTerms) {
                    if ($key1Name -like "*$term*") { $match1 = $true; break }
                }

                if ($match1) {
                    try {
                        Remove-Item -Path $key1Path -Recurse -Force -ErrorAction SilentlyContinue
                        Write-LogMsg "✅ [ĐÃ XÓA REGISTRY CẤP 1] $key1Path"
                    } catch {}
                } else {
                    Get-ChildItem -Path $key1Path -ErrorAction SilentlyContinue | ForEach-Object {
                        $key2Name = $_.PSChildName
                        $key2Path = $_.PSPath

                        $match2 = $false
                        foreach ($term in $safeCleanTerms) {
                            if ($key2Name -like "*$term*") { $match2 = $true; break }
                        }

                        if ($match2) {
                            try {
                                Remove-Item -Path $key2Path -Recurse -Force -ErrorAction SilentlyContinue
                                Write-LogMsg "✅ [ĐÃ XÓA REGISTRY CẤP 2] $key2Path"
                            } catch {}

                            $remSub = (Get-ChildItem -Path $key1Path -ErrorAction SilentlyContinue).Count
                            $remVal = ((Get-ItemProperty -Path $key1Path -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }).Count
                            if ($remSub -eq 0 -and $remVal -eq 0) {
                                Remove-Item -Path $key1Path -Recurse -Force -ErrorAction SilentlyContinue
                                Write-LogMsg "✅ [ĐÃ DỌN REGISTRY VENDOR RỖNG] $key1Path"
                            }
                        }
                    }
                }
            }
        }

        # Dọn dẹp Registry Startup Run
        $runKeys = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        )
        foreach ($rk in $runKeys) {
            if (Test-Path $rk -ErrorAction SilentlyContinue) {
                $props = Get-ItemProperty -Path $rk -ErrorAction SilentlyContinue
                if ($props) {
                    foreach ($prop in $props.PSObject.Properties) {
                        $propName = $prop.Name
                        $propVal = "$($prop.Value)"
                        if ($propName -match '^PS') { continue }

                        $isMatch = $false
                        foreach ($term in $safeCleanTerms) {
                            if ($propName -like "*$term*" -or $propVal -like "*$term*") {
                                $isMatch = $true; break
                            }
                        }
                        if ($isMatch) {
                            try {
                                Remove-ItemProperty -Path $rk -Name $propName -Force -ErrorAction SilentlyContinue
                                Write-LogMsg "✅ [ĐÃ XÓA KHỞI ĐỘNG CÙNG WINDOWS] $rk -> $propName"
                            } catch {}
                        }
                    }
                }
            }
        }

        # TẦNG 7: DỌN DẸP SCHEDULED TASKS & SHORTCUTS
        try {
            $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue
            foreach ($t in $tasks) {
                $tName = $t.TaskName
                $tPath = $t.TaskPath
                if ($tPath -like "\Microsoft\Windows\*" -or $tPath -like "\Microsoft\Office\*") { continue }

                $isMatch = $false
                foreach ($term in $safeCleanTerms) {
                    if ($term.Length -ge 4 -and ($tName -like "*$term*" -or $tPath -like "*$term*")) {
                        $isMatch = $true; break
                    }
                }
                if ($isMatch) {
                    try {
                        Unregister-ScheduledTask -TaskName $tName -TaskPath $tPath -Confirm:$false -ErrorAction SilentlyContinue
                        Write-LogMsg "✅ [ĐÃ XÓA TÁC VỤ ĐỊNH KỲ] $tPath$tName"
                    } catch {}
                }
            }
        } catch {}

        # Dọn Shortcuts trên Desktop & Start Menu
        $shortcutFolders = @(
            "$env:USERPROFILE\Desktop",
            "$env:PUBLIC\Desktop",
            "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
            "$env:ProgramData\Microsoft\Windows\Start Menu\Programs"
        )

        foreach ($sf in $shortcutFolders) {
            if (Test-Path $sf -ErrorAction SilentlyContinue) {
                foreach ($term in $safeCleanTerms) {
                    Get-ChildItem -Path $sf -Filter "*$term*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                        try {
                            Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                            Write-LogMsg "✅ [ĐÃ XÓA PHÍM TẮT] $($_.Name)"
                        } catch {}
                    }
                }
            }
        }

        Write-LogMsg "=========================================================="
        Write-LogMsg "🎉 [HOÀN TẤT] Đã gỡ bỏ và dọn dẹp sạch sẽ phần mềm $appName!"
    } else {
        Write-LogMsg "🎉 [HOÀN TẤT] Tiến trình gỡ cài đặt tiêu chuẩn đã kết thúc!"
    }

    return "Gỡ cài đặt hoàn tất!"
}

