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

function Start-VUONGTTOfficeInstall {
    param(
        [string]$ConfigFile,
        [bool]$DownloadOnly = $false,
        [scriptblock]$OnProgress = $null
    )

    $workDir = "$env:TEMP\VUONGTT_ODT"
    if (-not (Test-Path $workDir)) {
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }

    $setupExe = Join-Path $workDir "setup.exe"
    if (-not (Test-Path $setupExe)) {
        if ($OnProgress) { & $OnProgress "Đang tải công cụ Microsoft Office Deployment Tool (ODT)..." }
        $odtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17830.20162.exe"
        $installer = Join-Path $workDir "odt_installer.exe"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $odtUrl -OutFile $installer -UseBasicParsing
        Start-Process -FilePath $installer -ArgumentList "/quiet /extract:`"$workDir`"" -Wait -NoNewWindow
    }

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
    $setupExe = Join-Path $workDir "setup.exe"
    
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
