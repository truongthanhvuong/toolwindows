# =========================================================================
#   VUONGTT TOOLKIT 2026 - ADVANCED IP SCANNER MODULE (ULTRA FAST ASYNC ENGINE)
#   Quét dải IP mạng LAN đa luồng siêu tốc, nhận diện Hostname, MAC, Vendor, Cổng mở
#   Không làm đơ giao diện (Zero UI Freezing) - Hỗ trợ dừng tức thì (Instant Cancel)
# =========================================================================

$csharpScannerCode = @"
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

namespace VUONGTT.Network
{
    public class DiscoveredDevice
    {
        public string Status { get; set; }
        public string IP { get; set; }
        public string Hostname { get; set; }
        public string MacAddress { get; set; }
        public string Vendor { get; set; }
        public string Ports { get; set; }
        public string PingTime { get; set; }
    }

    public class FastScanner
    {
        public static volatile bool IsCancelled = false;
        public static volatile bool IsRunning = false;
        public static int TotalCount = 0;
        public static int CompletedCount = 0;
        public static ConcurrentQueue<DiscoveredDevice> DiscoveredQueue = new ConcurrentQueue<DiscoveredDevice>();

        public static void Cancel()
        {
            IsCancelled = true;
        }

        public static void StartScan(string prefix, int from, int to, Dictionary<string, string> arpMap, Dictionary<string, string> vendorMap)
        {
            IsCancelled = false;
            IsRunning = true;
            TotalCount = (to - from + 1);
            CompletedCount = 0;

            DiscoveredDevice dummy;
            while (DiscoveredQueue.TryDequeue(out dummy)) { }

            Task.Run(async () =>
            {
                try
                {
                    var semaphore = new SemaphoreSlim(64);
                    var tasks = new List<Task>();

                    for (int i = from; i <= to; i++)
                    {
                        if (IsCancelled) break;
                        int currentIpNum = i;
                        string ip = string.Format("{0}.{1}", prefix, currentIpNum);

                        tasks.Add(Task.Run(async () =>
                        {
                            if (IsCancelled) return;
                            await semaphore.WaitAsync();
                            try
                            {
                                if (IsCancelled) return;
                                using (var ping = new Ping())
                                {
                                    var reply = await ping.SendPingAsync(ip, 250);
                                    if (reply.Status == IPStatus.Success)
                                    {
                                        long rtt = reply.RoundtripTime;
                                        string mac = "-";
                                        string vendor = "Thiết bị mạng";
                                        if (arpMap != null && arpMap.ContainsKey(ip))
                                        {
                                            mac = arpMap[ip];
                                            string cleanMac = mac.Replace("-", "").Replace(":", "").ToUpper();
                                            if (cleanMac.Length >= 6)
                                            {
                                                string prefixMac = cleanMac.Substring(0, 6);
                                                if (vendorMap != null && vendorMap.ContainsKey(prefixMac))
                                                {
                                                    vendor = vendorMap[prefixMac];
                                                }
                                                else
                                                {
                                                    vendor = string.Format("Card Mạng ({0})", prefixMac);
                                                }
                                            }
                                        }

                                        // Fast hostname lookup with 200ms timeout
                                        string host = ip;
                                        try
                                        {
                                            var dnsTask = Dns.GetHostEntryAsync(ip);
                                            if (await Task.WhenAny(dnsTask, Task.Delay(200)) == dnsTask)
                                            {
                                                var entry = await dnsTask;
                                                if (entry != null && !string.IsNullOrEmpty(entry.HostName))
                                                {
                                                    host = entry.HostName;
                                                }
                                            }
                                        }
                                        catch { }

                                        // Fast port probe for common LAN services
                                        var openPorts = new List<string>();
                                        int[] portsToCheck = new int[] { 445, 80, 9100, 3389 };
                                        foreach (int port in portsToCheck)
                                        {
                                            if (IsCancelled) break;
                                            try
                                            {
                                                using (var client = new TcpClient())
                                                {
                                                    var connectTask = client.ConnectAsync(ip, port);
                                                    if (await Task.WhenAny(connectTask, Task.Delay(75)) == connectTask)
                                                    {
                                                        if (client.Connected)
                                                        {
                                                            if (port == 445) openPorts.Add("SMB");
                                                            else if (port == 80) openPorts.Add("Web");
                                                            else if (port == 9100) openPorts.Add("In(9100)");
                                                            else if (port == 3389) openPorts.Add("RDP");
                                                        }
                                                    }
                                                }
                                            }
                                            catch { }
                                        }

                                        string portStr = openPorts.Count > 0 ? string.Join(", ", openPorts.ToArray()) : "ICMP";

                                        var dev = new DiscoveredDevice
                                        {
                                            Status = "🟢 Online",
                                            IP = ip,
                                            Hostname = host,
                                            MacAddress = mac,
                                            Vendor = vendor,
                                            Ports = portStr,
                                            PingTime = string.Format("{0} ms", rtt)
                                        };

                                        DiscoveredQueue.Enqueue(dev);
                                    }
                                }
                            }
                            catch { }
                            finally
                            {
                                semaphore.Release();
                                Interlocked.Increment(ref CompletedCount);
                            }
                        }));
                    }

                    await Task.WhenAll(tasks);
                }
                finally
                {
                    IsRunning = false;
                }
            });
        }
    }
}
"@

try {
    if (-not ([System.Management.Automation.PSTypeName]'VUONGTT.Network.FastScanner').Type) {
        Add-Type -TypeDefinition $csharpScannerCode -Language CSharp
    }
} catch {
    # Type may already be loaded
}

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

function Get-VUONGTTVendorDictionary {
    $dict = New-Object 'System.Collections.Generic.Dictionary[string, string]'
    $pairs = @{
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
        "B82A72" = "Dell";         "54EE75" = "Xiaomi";       "286C07" = "Xiaomi";
        "FC6947" = "Huawei";       "00180A" = "Cisco";        "CC4E24" = "Hikvision";
        "34BA9A" = "Dahua";        "001132" = "Synology"
    }
    foreach ($k in $pairs.Keys) {
        $dict[$k] = $pairs[$k]
    }
    return $dict
}

function Get-VUONGTTArpTableDict {
    $arpMap = New-Object 'System.Collections.Generic.Dictionary[string, string]'
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

function Get-VUONGTTMacVendor {
    param([string]$MacAddress)
    if ([string]::IsNullOrWhiteSpace($MacAddress) -or $MacAddress -eq "-" -or $MacAddress.Length -lt 8) {
        return "Thiết bị mạng"
    }

    $cleanMac = $MacAddress.ToUpper().Replace("-", "").Replace(":", "")
    if ($cleanMac.Length -ge 6) {
        $prefix = $cleanMac.Substring(0, 6)
        $dict = Get-VUONGTTVendorDictionary
        if ($dict.ContainsKey($prefix)) {
            return $dict[$prefix]
        }
        return "Card Mạng ($prefix)"
    }
    return "Thiết bị mạng"
}
