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
