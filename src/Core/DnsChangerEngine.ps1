# DnsChangerEngine.ps1
# Engine Đổi DNS Nhanh & Đo Ping Tối Ưu Mạng (DNS Changer Pro)
# Hỗ trợ Google, Cloudflare, AdGuard, Quad9, OpenDNS, Nhà mạng VN (VNPT, Viettel, FPT) & DHCP

function Get-VUONGTTNetworkAdapters {
    [CmdletBinding()]
    param()

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    try {
        if (Get-Command "Get-NetAdapter" -ErrorAction SilentlyContinue) {
            $adapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" }
            foreach ($ad in $adapters) {
                $dnsInfo = Get-DnsClientServerAddress -InterfaceAlias $ad.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
                $currentDns = if ($dnsInfo -and $dnsInfo.ServerAddresses) { $dnsInfo.ServerAddresses -join ", " } else { "DHCP (Tự động)" }

                $ipInfo = Get-NetIPAddress -InterfaceAlias $ad.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -notlike "169.254*" } | Select-Object -First 1
                $ipAddr = if ($ipInfo) { $ipInfo.IPAddress } else { "N/A" }

                $results.Add([PSCustomObject]@{
                    InterfaceAlias = $ad.Name
                    Description    = $ad.InterfaceDescription
                    Status         = $ad.Status
                    MacAddress     = $ad.MacAddress
                    IPv4Address    = $ipAddr
                    CurrentDns     = $currentDns
                })
            }
        }
    } catch {}

    # Fallback to WMI nếu Get-NetAdapter không khả dụng
    if ($results.Count -eq 0) {
        try {
            $wmiConfigs = Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
            foreach ($cfg in $wmiConfigs) {
                $dnsStr = if ($cfg.DNSServerSearchOrder) { $cfg.DNSServerSearchOrder -join ", " } else { "DHCP (Tự động)" }
                $results.Add([PSCustomObject]@{
                    InterfaceAlias = $cfg.Description
                    Description    = $cfg.Description
                    Status         = "Up"
                    MacAddress     = $cfg.MACAddress
                    IPv4Address    = ($cfg.IPAddress | Select-Object -First 1)
                    CurrentDns     = $dnsStr
                })
            }
        } catch {}
    }

    return $results
}

function Get-VUONGTTDnsPresets {
    [CmdletBinding()]
    param()

    return @(
        [PSCustomObject]@{
            Name        = "Cloudflare DNS (1.1.1.1)"
            Primary     = "1.1.1.1"
            Secondary   = "1.0.0.1"
            Description = "Tốc độ nhanh nhất thế giới, tôn trọng quyền riêng tư, không lưu log"
        },
        [PSCustomObject]@{
            Name        = "Google Public DNS (8.8.8.8)"
            Primary     = "8.8.8.8"
            Secondary   = "8.8.4.4"
            Description = "Phổ biến, định tuyến toàn cầu ổn định và độ tin cậy tuyệt đối"
        },
        [PSCustomObject]@{
            Name        = "AdGuard DNS (Chặn Quảng Cáo)"
            Primary     = "94.140.14.14"
            Secondary   = "94.140.15.15"
            Description = "Chặn đứng quảng cáo, banner độc hại và theo dõi theo thời gian thực"
        },
        [PSCustomObject]@{
            Name        = "AdGuard Family (Bảo Vệ Gia Đình)"
            Primary     = "94.140.14.15"
            Secondary   = "94.140.15.16"
            Description = "Chặn web người lớn, nội dung độc hại và bật Tìm kiếm an toàn"
        },
        [PSCustomObject]@{
            Name        = "Quad9 DNS (Bảo Mật Cao)"
            Primary     = "9.9.9.9"
            Secondary   = "149.112.112.112"
            Description = "Chống phishing, botnet, mã độc tống tiền tệp lây nhiễm từ Thụy Sĩ"
        },
        [PSCustomObject]@{
            Name        = "OpenDNS (Cisco Umbrella)"
            Primary     = "208.67.222.222"
            Secondary   = "208.67.220.220"
            Description = "Hệ thống bảo vệ đám mây nổi tiếng của Cisco Systems"
        },
        [PSCustomObject]@{
            Name        = "VNPT Telecom (Việt Nam)"
            Primary     = "123.30.225.225"
            Secondary   = "203.162.4.190"
            Description = "Máy chủ nội địa tối ưu cho đường truyền cáp quang VNPT"
        },
        [PSCustomObject]@{
            Name        = "Viettel Telecom (Việt Nam)"
            Primary     = "203.113.131.1"
            Secondary   = "203.113.188.1"
            Description = "Máy chủ nội địa tối ưu cho đường truyền cáp quang Viettel"
        },
        [PSCustomObject]@{
            Name        = "FPT Telecom (Việt Nam)"
            Primary     = "210.245.24.20"
            Secondary   = "210.245.24.22"
            Description = "Máy chủ nội địa tối ưu cho mạng FPT Telecom"
        },
        [PSCustomObject]@{
            Name        = "DHCP (Nhận DNS Tự Động Từ Router)"
            Primary     = ""
            Secondary   = ""
            Description = "Khôi phục cài đặt mặc định, modem/router sẽ tự cấp phát DNS"
        }
    )
}

function Test-VUONGTTDnsBenchmark {
    [CmdletBinding()]
    param()

    $presets = Get-VUONGTTDnsPresets | Where-Object { $_.Primary -ne "" }
    $pinger = [System.Net.NetworkInformation.Ping]::new()
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($p in $presets) {
        $lat = 9999
        $statusStr = "Timeout"
        try {
            # Ping 2 lần lấy trung bình
            $reply1 = $pinger.Send($p.Primary, 600)
            if ($reply1.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $lat = $reply1.RoundtripTime
                $statusStr = "$lat ms"
            }
        } catch {
            $statusStr = "Lỗi"
        }

        $results.Add([PSCustomObject]@{
            Name       = $p.Name
            Primary    = $p.Primary
            Secondary  = $p.Secondary
            LatencyMs  = $lat
            StatusText = $statusStr
        })
    }

    # Sắp xếp theo ping nhanh nhất
    return ($results | Sort-Object LatencyMs)
}

function Set-VUONGTTDns {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InterfaceAlias,
        [Parameter(Mandatory = $false)]
        [string]$PrimaryDns = "",
        [Parameter(Mandatory = $false)]
        [string]$SecondaryDns = "",
        [switch]$ResetDhcp
    )

    try {
        if ($ResetDhcp -or (-not $PrimaryDns)) {
            # Khôi phục DHCP
            if (Get-Command "Set-DnsClientServerAddress" -ErrorAction SilentlyContinue) {
                Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses -ErrorAction SilentlyContinue
            } else {
                & netsh interface ip set dns name="$InterfaceAlias" source=dhcp | Out-Null
            }
            $msg = "Đã khôi phục cài đặt DNS về DHCP (Tự động) cho card mạng [$InterfaceAlias]."
        } else {
            # Gán DNS tĩnh
            $servers = @($PrimaryDns)
            if ($SecondaryDns) { $servers += $SecondaryDns }

            if (Get-Command "Set-DnsClientServerAddress" -ErrorAction SilentlyContinue) {
                Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $servers -ErrorAction Stop
            } else {
                & netsh interface ip set dns name="$InterfaceAlias" static $PrimaryDns | Out-Null
                if ($SecondaryDns) {
                    & netsh interface ip add dns name="$InterfaceAlias" $SecondaryDns index=2 | Out-Null
                }
            }
            $msg = "Đã áp dụng DNS thành công cho [$InterfaceAlias]: $PrimaryDns, $SecondaryDns."
        }

        # Xóa sạch DNS cache hệ thống
        if (Get-Command "Clear-DnsClientCache" -ErrorAction SilentlyContinue) {
            Clear-DnsClientCache -ErrorAction SilentlyContinue
        } else {
            & ipconfig /flushdns | Out-Null
        }

        return [PSCustomObject]@{
            Success        = $true
            Message        = $msg
            InterfaceAlias = $InterfaceAlias
            PrimaryDns     = $PrimaryDns
            SecondaryDns   = $SecondaryDns
        }
    } catch {
        return [PSCustomObject]@{
            Success        = $false
            Message        = "Lỗi khi đổi DNS: $($_.Exception.Message)"
            InterfaceAlias = $InterfaceAlias
            PrimaryDns     = $PrimaryDns
            SecondaryDns   = $SecondaryDns
        }
    }
}
