# VUONGTT Toolkit 2026 - Enhanced Office Deployment & Management Module

function Get-InstalledOfficeInfo {
    [CmdletBinding()]
    param()

    # Check ClickToRun configuration
    $c2r = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
    if (Test-Path $c2r) {
        $props = Get-ItemProperty -Path $c2r -ErrorAction SilentlyContinue
        if ($props -and $props.ProductReleaseIDs) {
            $ver = if ($props.VersionToReport) { $props.VersionToReport } else { "Click-to-Run" }
            $arch = if ($props.Platform) { $props.Platform } else { "x64" }
            return "Đã cài: Microsoft Office ($($props.ProductReleaseIDs) - $arch - v$ver)"
        }
    }

    # Check Registry Uninstall keys
    $uninstallPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($p in $uninstallPaths) {
        $items = Get-ItemProperty -Path $p -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*Microsoft Office*" -or $_.DisplayName -like "*Microsoft 365*" }
        if ($items) {
            $first = $items | Select-Object -First 1
            return "Đã cài: $($first.DisplayName)"
        }
    }

    return "Chưa phát hiện Microsoft Office trên máy tính"
}

function New-VUONGTTOfficeConfig {
    param(
        [string]$Version = "ProPlus2024Volume",
        [string]$Arch = "64",
        [string]$Channel = "PerpetualVL2024",
        [string]$PrimaryLang = "vi-vn",
        [string]$SecondaryLang = "",
        [string[]]$ExcludeApps = @(),
        [bool]$IncludeProject = $false,
        [bool]$IncludeVisio = $false,
        [string]$SourcePath = "",
        [string]$OutputPath = "$env:TEMP\VUONGTT_Office_Config.xml"
    )

    $excludeXml = ""
    foreach ($app in $ExcludeApps) {
        $excludeXml += "      <ExcludeApp ID=`"$app`" />`n"
    }

    $secLangXml = ""
    if (-not [string]::IsNullOrEmpty($SecondaryLang) -and $SecondaryLang -ne $PrimaryLang) {
        $secLangXml = "      <Language ID=`"$SecondaryLang`" />`n"
    }

    $projectXml = ""
    if ($IncludeProject) {
        $projId = if ($Version -like "*2024*") { "ProjectPro2024Volume" } elseif ($Version -like "*2021*") { "ProjectPro2021Volume" } elseif ($Version -like "*2019*") { "ProjectPro2019Volume" } else { "ProjectProRetail" }
        $projectXml = @"
    <Product ID="$projId">
      <Language ID="$PrimaryLang" />
$secLangXml    </Product>
"@
    }

    $visioXml = ""
    if ($IncludeVisio) {
        $visioId = if ($Version -like "*2024*") { "VisioPro2024Volume" } elseif ($Version -like "*2021*") { "VisioPro2021Volume" } elseif ($Version -like "*2019*") { "VisioPro2019Volume" } else { "VisioProRetail" }
        $visioXml = @"
    <Product ID="$visioId">
      <Language ID="$PrimaryLang" />
$secLangXml    </Product>
"@
    }

    $srcAttr = if (-not [string]::IsNullOrEmpty($SourcePath) -and (Test-Path $SourcePath)) { " SourcePath=`"$SourcePath`"" } else { "" }

    $xml = @"
<Configuration>
  <Add OfficeClientEdition="$Arch" Channel="$Channel"$srcAttr>
    <Product ID="$Version">
      <Language ID="$PrimaryLang" />
$secLangXml$excludeXml    </Product>
$projectXml
$visioXml
  </Add>
  <Property Name="SharedComputerLicensing" Value="0" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Property Name="DeviceBasedLicensing" Value="0" />
  <Property Name="SCLCacheOverride" Value="0" />
  <Updates Enabled="TRUE" />
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@

    $xml | Set-Content -Path $OutputPath -Encoding UTF8
    return $OutputPath
}

function Get-VUONGTTOfficeDeploymentTool {
    [CmdletBinding()]
    param(
        [string]$DestinationDir = "$env:TEMP\VUONGTT_ODT",
        [scriptblock]$OnProgress = $null
    )

    if (-not (Test-Path $DestinationDir)) {
        New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
    }

    $setupExe = Join-Path $DestinationDir "setup.exe"
    if (Test-Path $setupExe) {
        $size = (Get-Item $setupExe).Length
        if ($size -gt 500000) {
            return $setupExe
        }
    }

    # 1. Kiểm tra file setup.exe có sẵn trong thư mục Assets của Tool
    $assetSetupCandidates = @(
        "$PSScriptRoot\..\Assets\setup.exe",
        "src\Assets\setup.exe",
        "$env:TEMP\setup.exe"
    )
    foreach ($cand in $assetSetupCandidates) {
        if (Test-Path $cand) {
            Copy-Item -Path $cand -Destination $setupExe -Force -ErrorAction SilentlyContinue
            if ((Test-Path $setupExe) -and (Get-Item $setupExe).Length -gt 1000000) {
                return $setupExe
            }
        }
    }

    # Kích hoạt toàn diện các giao thức TLS hiện đại và tối ưu kết nối
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls,Tls11,Tls12' -bor 3072 -bor 12288
    [System.Net.ServicePointManager]::DefaultConnectionLimit = 64
    [System.Net.ServicePointManager]::Expect100Continue = $false

    if ($OnProgress) { & $OnProgress "Đang tìm kiếm phiên bản Microsoft Office Deployment Tool (ODT) mới nhất..." }

    # Danh sách URL tải ODT (ưu tiên cào link mới nhất từ Microsoft, fallback qua link direct)
    $candidateUrls = [System.Collections.Generic.List[string]]::new()

    # 1. Cố gắng lấy link direct mới nhất từ trang download chính thức của Microsoft
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36")
        $html = $wc.DownloadString("https://www.microsoft.com/en-us/download/details.aspx?id=49117")
        if ($html -match 'https://download\.microsoft\.com/download/[^"''\s\<\>]+\.exe') {
            $candidateUrls.Add($matches[0])
        }
    } catch {}

    # 2. Link direct Microsoft ODT chính thức cập nhật 2026
    $candidateUrls.Add("https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_20326-20112.exe")

    # 3. Link direct dự phòng của Microsoft
    $candidateUrls.Add("https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool.exe")

    $installer = Join-Path $DestinationDir "odt_installer.exe"
    $downloadSuccess = $false

    foreach ($url in $candidateUrls) {
        try {
            if ($OnProgress) { & $OnProgress "Đang tải công cụ ODT từ máy chủ Microsoft ($url)..." }
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36")
            $wc.DownloadFile($url, $installer)
            if ((Test-Path $installer) -and (Get-Item $installer).Length -gt 1000000) {
                $downloadSuccess = $true
                break
            }
        } catch {
            # Thử URL tiếp theo nếu URL hiện tại lỗi
        }
    }

    if (-not $downloadSuccess) {
        throw "Không thể kết nối đến máy chủ Microsoft để tải công cụ Office ODT! Vui lòng kiểm tra lại kết nối mạng Internet hoặc tường lửa."
    }

    # Trích xuất file setup.exe từ odt_installer.exe
    if ($OnProgress) { & $OnProgress "Đang giải nén bộ cài Microsoft ODT..." }

    # Kỹ thuật 1: Trích xuất trực tiếp khối CAB (MSCF signature) và dùng expand.exe (Không cần quyền Elevation!)
    try {
        $bytes = [System.IO.File]::ReadAllBytes($installer)
        $cabOffset = -1
        for ($i = 0; $i -lt ($bytes.Length - 4); $i++) {
            if ($bytes[$i] -eq 0x4D -and $bytes[$i+1] -eq 0x53 -and $bytes[$i+2] -eq 0x43 -and $bytes[$i+3] -eq 0x46) {
                $cabOffset = $i
                break
            }
        }
        if ($cabOffset -gt 0) {
            $cabFile = Join-Path $DestinationDir "odt_inner.cab"
            $cabBytes = New-Object byte[] ($bytes.Length - $cabOffset)
            [System.Array]::Copy($bytes, $cabOffset, $cabBytes, 0, $cabBytes.Length)
            [System.IO.File]::WriteAllBytes($cabFile, $cabBytes)
            & expand $cabFile -F:* $DestinationDir | Out-Null
            Remove-Item $cabFile -Force -ErrorAction SilentlyContinue
        }
    } catch {}

    # Kỹ thuật 2 (Fallback): Gọi trực tiếp tiến trình giải nén nếu Kỹ thuật 1 chưa tạo ra setup.exe
    if (-not (Test-Path $setupExe)) {
        try {
            if (Get-Command Start-VUONGTTProcessResponsive -ErrorAction SilentlyContinue) {
                Start-VUONGTTProcessResponsive -FilePath $installer -ArgumentList "/quiet /extract:`"$DestinationDir`"" -TimeoutSeconds 120 -NoNewWindow $true
            } else {
                Start-Process -FilePath $installer -ArgumentList "/quiet /extract:`"$DestinationDir`"" -Wait -NoNewWindow
            }
        } catch {}
    }

    # Kỹ thuật 3 (Fallback cuối cùng): Tải trực tiếp file setup.exe từ kho CDN GitHub
    if (-not (Test-Path $setupExe)) {
        try {
            if ($OnProgress) { & $OnProgress "Đang tải file setup.exe dự phòng từ CDN GitHub..." }
            $ghUrl = "https://raw.githubusercontent.com/truongthanhvuong/toolwindows/main/src/Assets/setup.exe"
            $wc = New-Object System.Net.WebClient
            $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
            $wc.DownloadFile($ghUrl, $setupExe)
        } catch {}
    }

    # Kiểm tra lại setup.exe
    if (Test-Path $setupExe) {
        return $setupExe
    } else {
        throw "Không tìm thấy file setup.exe sau khi giải nén Microsoft ODT."
    }
}

function Start-VUONGTTOfficeInstall {
    param(
        [string]$ConfigFile,
        [bool]$DownloadOnly = $false,
        [scriptblock]$OnProgress = $null
    )

    $workDir = "$env:TEMP\VUONGTT_ODT"
    $setupExe = Get-VUONGTTOfficeDeploymentTool -DestinationDir $workDir -OnProgress $OnProgress

    if (Test-Path $setupExe) {
        $modeArg = if ($DownloadOnly) { "/download `"$ConfigFile`"" } else { "/configure `"$ConfigFile`"" }
        if ($OnProgress) { 
            & $OnProgress $(if ($DownloadOnly) { "Đang tải dữ liệu bộ cài Office từ CDN Microsoft..." } else { "Bắt đầu tải và cài đặt Office từ máy chủ Microsoft..." })
        }
        $p = Start-Process -FilePath $setupExe -ArgumentList $modeArg -PassThru
        return $p
    } else {
        throw "Không tìm thấy ODT setup.exe sau khi giải nén."
    }
}

function Uninstall-VUONGTTOffice {
    param([scriptblock]$OnProgress = $null)

    $workDir = "$env:TEMP\VUONGTT_ODT"
    $setupExe = Get-VUONGTTOfficeDeploymentTool -DestinationDir $workDir -OnProgress $OnProgress
    
    $removeXml = "$env:TEMP\VUONGTT_Office_Remove.xml"
    @"
<Configuration>
  <Remove All="TRUE" />
  <Display Level="Full" AcceptEULA="TRUE" />
</Configuration>
"@ | Set-Content -Path $removeXml -Encoding UTF8

    if (Test-Path $setupExe) {
        if ($OnProgress) { & $OnProgress "Đang thực thi gỡ bỏ toàn bộ các phiên bản Microsoft Office..." }
        $p = Start-Process -FilePath $setupExe -ArgumentList "/configure `"$removeXml`"" -PassThru
        return $p
    } else {
        # Fallback to C2R Client if exists
        $c2rClient = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe"
        if (Test-Path $c2rClient) {
            $p = Start-Process -FilePath $c2rClient -ArgumentList "scenario=install scenariosubtype=uninstall baseurl=`"`" platform=x64 culture=en-us version=16.0.0.0" -PassThru
            return $p
        }
        throw "Không tìm thấy công cụ gỡ cài đặt Office ODT."
    }
}
