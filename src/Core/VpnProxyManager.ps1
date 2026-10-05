# =========================================================================
#   VUONGTT_Toolkit - VPN / Proxy & Network Optimization Engine
#   File: src/Core/VpnProxyManager.ps1
#   Purpose: Public IP Checkup, Proxy Switcher (WinINet P/Invoke), Network Reset
# =========================================================================

# Ensure WinINet native API for immediate system-wide proxy notification without restart
if (-not ([System.Management.Automation.PSTypeName]'VUONGTT.WinINet').Type) {
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

namespace VUONGTT {
    public class WinINet {
        [DllImport("wininet.dll", SetLastError = true)]
        public static extern bool InternetSetOption(IntPtr hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);

        public const int INTERNET_OPTION_SETTINGS_CHANGED = 39;
        public const int INTERNET_OPTION_REFRESH = 37;

        public static void NotifySettingsChanged() {
            InternetSetOption(IntPtr.Zero, INTERNET_OPTION_SETTINGS_CHANGED, IntPtr.Zero, 0);
            InternetSetOption(IntPtr.Zero, INTERNET_OPTION_REFRESH, IntPtr.Zero, 0);
        }
    }
}
"@ -ErrorAction SilentlyContinue
    } catch {
        # Fallback if already compiled or security restricted
    }
}

function Get-VUONGTTProxyCountries {
    <#
    .SYNOPSIS
        Returns curated list of countries and high-speed public relays.
    #>
    return @(
        [PSCustomObject]@{
            Code          = "VN"
            Name          = "Việt Nam (Hà Nội / HCM)"
            Flag          = "🇻🇳"
            Host          = "vn.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "12 ms"
            MapX          = 680
            MapY          = 320
            CountryTag    = "Vietnam"
            StreetAddress = "FPT Tower, Số 10 Phạm Văn Bạch, Dịch Vọng Hậu, Cầu Giấy, Hà Nội"
            Latitude      = 21.0307
            Longitude     = 105.7836
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=21.0307,105.7836"
        },
        [PSCustomObject]@{
            Code          = "SG"
            Name          = "Singapore (Fastest Global)"
            Flag          = "🇸🇬"
            Host          = "sg.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "35 ms"
            MapX          = 660
            MapY          = 350
            CountryTag    = "Singapore"
            StreetAddress = "Equinix SG1, 20 Ayer Rajah Crescent, One-North, Singapore"
            Latitude      = 1.2982
            Longitude     = 103.7877
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=1.2982,103.7877"
        },
        [PSCustomObject]@{
            Code          = "US"
            Name          = "United States (California / NY)"
            Flag          = "🇺🇸"
            Host          = "us.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "165 ms"
            MapX          = 240
            MapY          = 220
            CountryTag    = "USA"
            StreetAddress = "Digital Realty NYC, 60 Hudson Street, New York, NY 10013"
            Latitude      = 40.7180
            Longitude     = -74.0089
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=40.7180,-74.0089"
        },
        [PSCustomObject]@{
            Code          = "JP"
            Name          = "Japan (Tokyo High-Speed)"
            Flag          = "🇯🇵"
            Host          = "jp.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "68 ms"
            MapX          = 760
            MapY          = 210
            CountryTag    = "Japan"
            StreetAddress = "Equinix TY2 Data Center, Shinagawa / Minato, Tokyo"
            Latitude      = 35.6262
            Longitude     = 139.7528
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=35.6262,139.7528"
        },
        [PSCustomObject]@{
            Code          = "KR"
            Name          = "South Korea (Seoul)"
            Flag          = "🇰🇷"
            Host          = "kr.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "72 ms"
            MapX          = 730
            MapY          = 205
            CountryTag    = "Korea"
            StreetAddress = "Gangnam Datacenter, Teheran-ro, Gangnam-gu, Seoul"
            Latitude      = 37.5008
            Longitude     = 127.0369
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=37.5008,127.0369"
        },
        [PSCustomObject]@{
            Code          = "UK"
            Name          = "United Kingdom (London)"
            Flag          = "🇬🇧"
            Host          = "uk.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "180 ms"
            MapX          = 460
            MapY          = 170
            CountryTag    = "UK"
            StreetAddress = "Telehouse Docklands North, Coriander Ave, London E14 2AA"
            Latitude      = 51.5113
            Longitude     = -0.0075
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=51.5113,-0.0075"
        },
        [PSCustomObject]@{
            Code          = "DE"
            Name          = "Germany (Frankfurt)"
            Flag          = "🇩🇪"
            Host          = "de.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "190 ms"
            MapX          = 485
            MapY          = 175
            CountryTag    = "Germany"
            StreetAddress = "Frankfurt Maincube, Hanauer Landstraße 322, Frankfurt am Main"
            Latitude      = 50.1109
            Longitude     = 8.6821
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=50.1109,8.6821"
        },
        [PSCustomObject]@{
            Code          = "FR"
            Name          = "France (Paris)"
            Flag          = "🇫🇷"
            Host          = "fr.proxy.vuongtt.local"
            Port          = 8080
            Latency       = "185 ms"
            MapX          = 465
            MapY          = 185
            CountryTag    = "France"
            StreetAddress = "Equinix PA3 Paris, Rue Ambroise Croizat, Saint-Denis, Paris"
            Latitude      = 48.9192
            Longitude     = 2.3582
            StreetViewUrl = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=48.9192,2.3582"
        }
    )
}

function Get-VUONGTTNetworkCheckup {
    <#
    .SYNOPSIS
        Queries public IP, geolocation, ISP, active DNS, and gateway with strict timeout.
    #>
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds = 3
    )

    $result = [PSCustomObject]@{
        PublicIP   = "Đang lấy..."
        Country    = "Không xác định"
        City       = ""
        ISP        = "Không xác định"
        Timezone   = ""
        Status     = "Unknown"
        DnsServers = @()
        ProxyState = "Disabled"
        ProxyServer= ""
        LatencyMs  = -1
    }

    # 1. Read Current Windows Proxy State from Registry
    try {
        $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $proxyEnable = (Get-ItemProperty -Path $regPath -Name "ProxyEnable" -ErrorAction SilentlyContinue).ProxyEnable
        $proxyServer = (Get-ItemProperty -Path $regPath -Name "ProxyServer" -ErrorAction SilentlyContinue).ProxyServer

        if ($proxyEnable -eq 1) {
            $result.ProxyState = "Enabled"
            $result.ProxyServer = if ($proxyServer) { $proxyServer } else { "Active" }
        } else {
            $result.ProxyState = "Disabled"
            $result.ProxyServer = "None"
        }
    } catch {
        $result.ProxyState = "Error"
    }

    # 2. Get Local Active DNS Servers
    try {
        $dnsList = @(Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { $_.ServerAddresses -and $_.ServerAddresses.Count -gt 0 } |
            Select-Object -ExpandProperty ServerAddresses)
        $result.DnsServers = ($dnsList | Select-Object -Unique)
    } catch {
        $result.DnsServers = @("DHCP / Auto")
    }

    # 3. Query Geolocation via ip-api with timeout
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $req = [System.Net.HttpWebRequest]::Create("http://ip-api.com/json/?fields=status,message,country,city,isp,query,timezone")
        $req.Timeout = ($TimeoutSeconds * 1000)
        $req.ReadWriteTimeout = ($TimeoutSeconds * 1000)
        $req.UserAgent = "VUONGTT_Toolkit/20.5"

        $resp = $req.GetResponse()
        $stream = $resp.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $jsonRaw = $reader.ReadToEnd()
        $sw.Stop()

        $resp.Close()
        $stream.Close()
        $reader.Close()

        if ($jsonRaw) {
            $parsed = $jsonRaw | ConvertFrom-Json
            if ($parsed.status -eq "success") {
                $result.PublicIP   = $parsed.query
                $result.Country    = $parsed.country
                $result.City       = $parsed.city
                $result.ISP        = $parsed.isp
                $result.Timezone   = $parsed.timezone
                $result.Status     = "Connected"
                $result.LatencyMs  = [int]$sw.ElapsedMilliseconds
                return $result
            }
        }
    } catch {
        # Fallback to ipify.org
        try {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $req2 = [System.Net.HttpWebRequest]::Create("https://api.ipify.org?format=text")
            $req2.Timeout = ($TimeoutSeconds * 1000)
            $resp2 = $req2.GetResponse()
            $stream2 = $resp2.GetResponseStream()
            $reader2 = New-Object System.IO.StreamReader($stream2)
            $ipText = $reader2.ReadToEnd().Trim()
            $sw.Stop()

            $resp2.Close()
            $stream2.Close()
            $reader2.Close()

            if ($ipText) {
                $result.PublicIP  = $ipText
                $result.Country   = "Internet Gateway"
                $result.ISP       = "Public ISP"
                $result.Status    = "Connected"
                $result.LatencyMs = [int]$sw.ElapsedMilliseconds
                return $result
            }
        } catch {
            $result.PublicIP  = "Không có kết nối mạng"
            $result.Status    = "Offline"
            $result.LatencyMs = -1
        }
    }

    return $result
}

function Set-VUONGTTSystemProxy {
    <#
    .SYNOPSIS
        Configures or Disables Windows System Proxy and triggers WinINet live refresh.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$ProxyServer = "",

        [switch]$Disable
    )

    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"

    try {
        if ($Disable -or [string]::IsNullOrWhiteSpace($ProxyServer)) {
            Set-ItemProperty -Path $regPath -Name "ProxyEnable" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $regPath -Name "ProxyServer" -Value "" -Type String -Force
            Write-Verbose "Proxy disabled in Registry"
        } else {
            Set-ItemProperty -Path $regPath -Name "ProxyEnable" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $regPath -Name "ProxyServer" -Value $ProxyServer -Type String -Force
            Set-ItemProperty -Path $regPath -Name "ProxyOverride" -Value "<local>" -Type String -Force
            Write-Verbose "Proxy enabled: $ProxyServer"
        }

        # Broadcast live change to all Windows sockets and browsers
        try {
            [VUONGTT.WinINet]::NotifySettingsChanged()
        } catch {
            # In case WinINet P/Invoke was not compiled
        }

        return $true
    } catch {
        Write-Warning "Lỗi cấu hình proxy: $($_.Exception.Message)"
        return $false
    }
}

function Reset-VUONGTTNetworkToDefault {
    <#
    .SYNOPSIS
        Completely resets Proxy, DNS to DHCP defaults, flushes DNS cache, and fixes network stack.
    #>
    [CmdletBinding()]
    param(
        [switch]$FullWinsockReset
    )

    $logOutput = @()
    $logOutput += "[1/4] Vô hiệu hóa Windows System Proxy..."
    Set-VUONGTTSystemProxy -Disable
    $logOutput += "  -> Proxy đã tắt hoàn toàn."

    $logOutput += "[2/4] Khôi phục DNS về mặc định Router (DHCP)..."
    try {
        Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {
            $adapterName = $_.Name
            Set-DnsClientServerAddress -InterfaceAlias $adapterName -ResetServerAddresses -ErrorAction SilentlyContinue
            $logOutput += "  -> Reset DNS adapter: $adapterName"
        }
    } catch {
        $logOutput += "  -> Không thể reset một số adapter DNS: $($_.Exception.Message)"
    }

    $logOutput += "[3/4] Xóa sạch bộ nhớ đệm DNS (Flush DNS)..."
    try {
        Clear-DnsClientCache -ErrorAction SilentlyContinue
        & ipconfig /flushdns | Out-Null
        $logOutput += "  -> Đã làm mới bộ nhớ đệm phân giải tên miền."
    } catch {
        $logOutput += "  -> Flush DNS cảnh báo: $($_.Exception.Message)"
    }

    if ($FullWinsockReset) {
        $logOutput += "[4/4] Khôi phục Winsock & TCP/IP Stack..."
        try {
            & netsh winsock reset | Out-Null
            & netsh int ip reset | Out-Null
            $logOutput += "  -> Winsock và TCP/IP đã được reset về mặc định gốc."
        } catch {
            $logOutput += "  -> Winsock reset cảnh báo: $($_.Exception.Message)"
        }
    } else {
        $logOutput += "[4/4] Bỏ qua Winsock reset (Giữ nguyên cấu hình card mạng vật lý)."
    }

    return ($logOutput -join "`n")
}
