# =========================================================================
#   VUONGTT TOOLKIT 2026 - ADVANCED IP SCANNER MODULE
#   Quét dải IP mạng LAN đa luồng siêu tốc, nhận diện Hostname, MAC, Vendor, Cổng mở
# =========================================================================

function Get-VUONGTTLocalSubnetInfo {
    try {
        $adapter = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
            Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | 
            Select-Object -First 1

        if ($adapter) {
            $ipParts = $adapter.IPAddress.Split('.')
            $subnetPrefix = "$($ipParts[0]).$($ipParts[1]).$($ipParts[2])"
            return [PSCustomObject]@{
                LocalIP      = $adapter.IPAddress
                SubnetPrefix = $subnetPrefix
                StartIP      = "$subnetPrefix.1"
                EndIP        = "$subnetPrefix.254"
            }
        }
    } catch {}

    return [PSCustomObject]@{
        LocalIP      = "192.168.1.100"
        SubnetPrefix = "192.168.1"
        StartIP      = "192.168.1.1"
        EndIP        = "192.168.1.254"
    }
}

function Get-VUONGTTMacVendor {
    param([string]$MacAddress)
    if ([string]::IsNullOrWhiteSpace($MacAddress) -or $MacAddress -eq "-" -or $MacAddress.Length -lt 8) {
        return "Thiết bị mạng"
    }

    $cleanMac = $MacAddress.ToUpper().Replace("-", "").Replace(":", "").Substring(0, 6)

    # Common OUI Vendor prefixes
    $vendors = @{
        "001A11" = "Google";       "F4F5D8" = "Google";       "D83BD0" = "Apple";
        "F01898" = "Apple";        "ACDE48" = "Apple";        "BC9FE4" = "Apple";
        "00155D" = "Microsoft";    "0050F2" = "Microsoft";    "000C29" = "VMware";
        "005056" = "VMware";       "080027" = "VirtualBox";   "B827EB" = "Raspberry Pi";
        "DCA632" = "Raspberry Pi"; "00E04C" = "Realtek";      "525400" = "QEMU/KVM";
        "704D7B" = "TP-Link";      "50C7BF" = "TP-Link";      "E4F042" = "TP-Link";
        "001FC6" = "Asus";         "04D4C4" = "Asus";         "B06EBF" = "Samsung";
        "30074D" = "Samsung";      "000400" = "Lexmark";      "00215A" = "HP";
        "3C5282" = "HP";           "001E0B" = "HP Printer";   "000085" = "Canon";
        "701124" = "Canon Printer";"008077" = "Brother";      "30055C" = "Brother";
        "ECB5FA" = "Intel";        "001B21" = "Intel";        "F81A67" = "Dell";
        "B82A72" = "Dell";         "54EE75" = "Xiaomi";       "286C07" = "Xiaomi"
    }

    if ($vendors.ContainsKey($cleanMac)) {
        return $vendors[$cleanMac]
    }
    return "Card Mạng ($cleanMac)"
}

function Get-VUONGTTArpTable {
    $arpMap = @{}
    try {
        $neighbors = Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue
        if ($neighbors) {
            foreach ($n in $neighbors) {
                if ($n.LinkLayerAddress -and $n.LinkLayerAddress -ne "00-00-00-00-00-00" -and $n.LinkLayerAddress.Length -ge 12) {
                    $arpMap[$n.IPAddress] = $n.LinkLayerAddress.ToUpper()
                }
            }
        }
    } catch {}

    if ($arpMap.Count -eq 0) {
        try {
            $arpOut = arp -a
            foreach ($line in $arpOut) {
                if ($line -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+([0-9a-fA-F-]{17})") {
                    $arpMap[$matches[1]] = $matches[2].ToUpper()
                }
            }
        } catch {}
    }

    return $arpMap
}

function Start-VUONGTTFastIpScan {
    param(
        [string]$StartIP = "192.168.1.1",
        [string]$EndIP   = "192.168.1.254",
        [scriptblock]$ProgressCallback = $null
    )

    $results = @()
    try {
        $p1 = $StartIP.Split('.')
        $p2 = $EndIP.Split('.')
        $prefix = "$($p1[0]).$($p1[1]).$($p1[2])"
        $startNum = [int]$p1[3]
        $endNum   = [int]$p2[3]
        if ($startNum -gt $endNum) { $startNum, $endNum = $endNum, $startNum }
        if ($startNum -lt 1) { $startNum = 1 }
        if ($endNum -gt 254) { $endNum = 254 }

        $total = ($endNum - $startNum) + 1
        $arpMap = Get-VUONGTTArpTable

        # Multi-thread Ping via Async System.Net.NetworkInformation.Ping
        $pingTasks = @()
        $pinger = New-Object System.Net.NetworkInformation.Ping

        for ($i = $startNum; $i -le $endNum; $i++) {
            $ip = "$prefix.$i"
            $pingTasks += [PSCustomObject]@{
                IP     = $ip
                Task   = (New-Object System.Net.NetworkInformation.Ping).SendPingAsync($ip, 350)
            }
        }

        # Wait and collect
        $doneCount = 0
        foreach ($item in $pingTasks) {
            $ip = $item.IP
            $reply = $null
            try {
                $reply = $item.Task.Result
            } catch {}

            $isOnline = ($reply -and $reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
            $roundtrip = if ($isOnline) { "$($reply.RoundtripTime) ms" } else { "-" }

            $mac = "-"
            $vendor = "-"
            $hostname = "-"
            $deviceType = "Không rõ"
            $openPorts = "-"

            if ($isOnline) {
                # Look up ARP
                if ($arpMap.ContainsKey($ip)) {
                    $mac = $arpMap[$ip]
                    $vendor = Get-VUONGTTMacVendor -MacAddress $mac
                }

                # Hostname reverse DNS
                try {
                    $hostEntry = [System.Net.Dns]::GetHostEntry($ip)
                    if ($hostEntry -and $hostEntry.HostName) {
                        $hostname = $hostEntry.HostName
                    }
                } catch {
                    $hostname = "PC-Host-$ip"
                }

                # Detect device type / ports quick probe
                $ports = @()
                $portsToProbe = @(
                    @{ Port = 80;   Name = "HTTP (Web)" },
                    @{ Port = 445;  Name = "SMB (Share File)" },
                    @{ Port = 9100; Name = "RAW (Máy In)" },
                    @{ Port = 3389; Name = "RDP (Remote Desktop)" }
                )
                foreach ($pt in $portsToProbe) {
                    try {
                        $client = New-Object System.Net.Sockets.TcpClient
                        $asyncWait = $client.BeginConnect($ip, $pt.Port, $null, $null)
                        $success = $asyncWait.AsyncWaitHandle.WaitOne(80, $false)
                        if ($success -and $client.Connected) {
                            $ports += $pt.Name
                            $client.EndConnect($asyncWait)
                        }
                        $client.Close()
                    } catch {}
                }

                if ($ports.Count -gt 0) {
                    $openPorts = $ports -join ", "
                    if ($openPorts -like "*Máy In*") { $deviceType = "🖨️ Máy In Mạng" }
                    elseif ($openPorts -like "*SMB*") { $deviceType = "💻 Máy Tính (PC/Server)" }
                    elseif ($openPorts -like "*HTTP*") { $deviceType = "🌐 Thiết Bị Mạng/Router" }
                    else { $deviceType = "📡 Thiết Bị Mạng" }
                } else {
                    $deviceType = "💻 Thiết Bị Mạng"
                }

                $results += [PSCustomObject]@{
                    Status     = "🟢 Online"
                    IP         = $ip
                    Hostname   = $hostname
                    MAC        = $mac
                    Vendor     = $vendor
                    DeviceType = $deviceType
                    Ports      = $openPorts
                    PingTime   = $roundtrip
                }
            }

            $doneCount++
            if ($ProgressCallback) {
                & $ProgressCallback $doneCount $total $ip
            }
        }
    } catch {
        Write-Warning "Lỗi quét IP: $($_.Exception.Message)"
    }

    return $results
}
