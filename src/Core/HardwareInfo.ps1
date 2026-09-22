# VUONGTT Toolkit 2026 - Enhanced Hardware Information & Real-time Metrics Module
# Encoding: UTF-8 with BOM

$script:cachedCpu     = $null
$script:cachedGpu     = $null
$script:cachedOs      = $null
$script:cachedCs      = $null
$script:cachedRam     = $null
$script:cachedBoard   = $null
$script:cachedPnpGpu  = $null
$script:cachedAllGpus = $null
$script:cachedDetailedHardwareInfo = $null

$global:VUONGTT_LiveMetricsShared = [hashtable]::Synchronized(@{
    SystemLoadPercent = 15
    CpuClockGHz       = 2.90
    CpuMaxClockGHz    = 4.10
    CpuTempC          = 36
    CpuName           = "Intel / AMD Processor"
    CpuLoadPercent    = 15
    RamUsedGB         = 8.0
    RamTotalGB        = 16.0
    RamPercent        = 50
    GpuName           = "Graphics Adapter"
    GpuVramGB         = 4.0
    GpuLoadPercent    = 2
    NetName           = "Ethernet"
    NetSpeed          = "12.5 KB/s"
    DiskSummary       = "C: Kháº£ dá»¥ng"
    DiskLoadPercent   = 0
    IsRunning         = $false
})

$script:metricsRunspace = $null
$script:metricsPowerShell = $null

function Get-VUONGTTSafeDesktopPath {
    $candidates = @(
        [Environment]::GetFolderPath([Environment+SpecialFolder]::Desktop),
        "$env:USERPROFILE\OneDrive\Desktop",
        "$env:USERPROFILE\Desktop",
        [Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments),
        "$env:USERPROFILE\Documents",
        $env:TEMP
    )

    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) {
            return $c
        }
    }

    # Neu chua ton tai, thu tao thu muc Desktop
    $defaultDesktop = "$env:USERPROFILE\Desktop"
    try {
        if (-not (Test-Path $defaultDesktop)) {
            New-Item -ItemType Directory -Path $defaultDesktop -Force | Out-Null
        }
        return $defaultDesktop
    } catch {
        return $env:TEMP
    }
}

function Get-VUONGTTHardwareSnapshot {
    if (-not $script:cachedCpu) {
        $script:cachedCpu   = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $script:cachedOs    = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $script:cachedCs    = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $script:cachedGpu   = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
        $script:cachedRam   = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
        $script:cachedBoard = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
        $script:cachedBios  = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
        $script:cachedCsp   = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
        
        # Quet PnP Entity de phat hien card do hoa chua co driver (Ma loi 28 / Display Class)
        $script:cachedPnpGpu = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object {
            $_.PNPClass -eq "Display" -or 
            $_.DeviceID -like "PCI\VEN_10DE*" -or 
            $_.DeviceID -like "PCI\VEN_1002*" -or 
            $_.DeviceID -like "PCI\VEN_8086&DEV_56*" -or
            $_.Name -like "*NVIDIA*" -or 
            $_.Name -like "*GeForce*" -or 
            $_.Name -like "*Radeon*"
        }
    }
}

function Clear-VUONGTTHardwareCache {
    $script:cachedCpu     = $null
    $script:cachedGpu     = $null
    $script:cachedOs      = $null
    $script:cachedCs      = $null
    $script:cachedRam     = $null
    $script:cachedBoard   = $null
    $script:cachedBios    = $null
    $script:cachedCsp     = $null
    $script:cachedPnpGpu  = $null
    $script:cachedAllGpus = $null
    $script:cachedDetailedHardwareInfo = $null
}

# Ham phan tich danh sach tat ca cac GPU tren may (Ho tro Multi-GPU: iGPU + dGPU)
function Get-VUONGTTAllGpus {
    [CmdletBinding()]
    param([switch]$ForceRefresh = $false)

    if ($script:cachedAllGpus -and -not $ForceRefresh) {
        return $script:cachedAllGpus
    }

    Get-VUONGTTHardwareSnapshot

    $allGpuList = @()
    $processedIds = [System.Collections.Generic.HashSet[string]]::new()

    # 1. Quet tu Win32_VideoController (Cac card da co Driver)
    if ($script:cachedGpu) {
        $gpuArr = @($script:cachedGpu)
        foreach ($vc in $gpuArr) {
            $pnpId = if ($vc.PNPDeviceID) { $vc.PNPDeviceID.Trim() } else { "" }
            if ($pnpId) { $null = $processedIds.Add($pnpId.ToUpper()) }

            # Trich xuat VEN va DEV
            $ven = ""
            $dev = ""
            if ($pnpId -match "VEN_([0-9A-Fa-f]{4})") { $ven = $matches[1].ToUpper() }
            if ($pnpId -match "DEV_([0-9A-Fa-f]{4})") { $dev = $matches[1].ToUpper() }
            $pciStr = if ($ven -and $dev) { "VEN_$ven DEV_$dev" } else { "PCI Standard" }

            $isDedicated = ($ven -eq "10DE" -or $ven -eq "1002" -or ($vc.Name -like "*NVIDIA*") -or ($vc.Name -like "*GeForce*") -or ($vc.Name -like "*Quadro*") -or ($vc.Name -like "*Radeon RX*") -or ($vc.Name -like "*Radeon Pro*") -or ($vc.Name -like "*Arc*"))
            $typeStr = if ($isDedicated) { "[dGPU (Rời)]" } else { "[iGPU (Tích hợp)]" }

            $vendor = if ($ven -eq "10DE" -or $vc.Name -like "*NVIDIA*") { "NVIDIA Corporation" }
                      elseif ($ven -eq "1002" -or $vc.Name -like "*AMD*" -or $vc.Name -like "*Radeon*") { "AMD / Radeon" }
                      elseif ($ven -eq "8086" -or $vc.Name -like "*Intel*") { "Intel Corporation" }
                      elseif ($vc.AdapterCompatibility) { $vc.AdapterCompatibility }
                      else { "Graphics Vendor" }

            $vramGB = if ($vc.AdapterRAM -and $vc.AdapterRAM -gt 0) { [math]::Round($vc.AdapterRAM / 1GB, 1) } else { 0 }
            # Neu VRAM bi bao 0 hoac am tren card roi thi uoc tinh theo dong card
            if ($vramGB -le 0 -and $isDedicated) { $vramGB = 4.0 }
            elseif ($vramGB -le 0) { $vramGB = 2.0 }

            $driverVer = if ($vc.DriverVersion) {
                if ($vc.DriverDate) { "$($vc.DriverVersion) ($($vc.DriverDate.ToString('dd/MM/yyyy')))" } else { $vc.DriverVersion }
            } else { "Standard Display Driver" }

            $resStr = if ($vc.CurrentHorizontalResolution -and $vc.CurrentVerticalResolution) {
                "$($vc.CurrentHorizontalResolution)x$($vc.CurrentVerticalResolution)"
            } else { "1920x1080 (Mặc định)" }

            $allGpuList += [PSCustomObject]@{
                Index        = $allGpuList.Count
                Name         = "$($vc.Name)"
                FullName     = "$($vc.Name) $typeStr"
                Vendor       = $vendor
                IsDedicated  = $isDedicated
                TypeTag      = $typeStr
                VramGB       = $vramGB
                VramStr      = "$vramGB GB VRAM"
                Driver       = $driverVer
                Resolution   = $resStr
                HardwareID   = $pciStr
                BusInterface = "PCIe 3.0/4.0 x16"
                Status       = "Hoạt động bình thường [OK]"
                HasError     = $false
            }
        }
    }

    # 2. Quet them tu Win32_PnPEntity (Tim card roi NVIDIA/AMD/Intel Arc CHUA CO DRIVER / Ma loi 28)
    if ($script:cachedPnpGpu) {
        foreach ($pnp in $script:cachedPnpGpu) {
            $devId = if ($pnp.DeviceID) { $pnp.DeviceID.Trim().ToUpper() } else { "" }
            if ($devId -and -not $processedIds.Contains($devId)) {
                # Kiem tra xem co phai card do hoa roi khong
                $ven = if ($devId -match "VEN_([0-9A-Fa-f]{4})") { $matches[1].ToUpper() } else { "" }
                $dev = if ($devId -match "DEV_([0-9A-Fa-f]{4})") { $matches[1].ToUpper() } else { "" }

                if ($ven -eq "10DE" -or $ven -eq "1002" -or $ven -eq "8086" -or $pnp.PNPClass -eq "Display") {
                    $venName = switch ($ven) {
                        "10DE" { "NVIDIA Corporation" }
                        "1002" { "AMD / Radeon" }
                        "8086" { "Intel Corporation" }
                        default { "Graphics Controller" }
                    }

                    $rawName = if ($pnp.Name) { $pnp.Name } elseif ($pnp.Description) { $pnp.Description } elseif ($pnp.Caption) { $pnp.Caption } else { "3D Video Controller" }
                    $gpuName = if ($ven -eq "10DE") { "NVIDIA Graphics Device ($rawName)" }
                               elseif ($ven -eq "1002") { "AMD Radeon Graphics ($rawName)" }
                               else { $rawName }

                    $errCode = $pnp.ConfigManagerErrorCode
                    $errStr = if ($errCode -eq 28) { "⚠️ Chưa cài Driver (Mã lỗi: 28)" }
                              elseif ($errCode) { "⚠️ Lỗi Driver (Mã lỗi: $errCode)" }
                              else { "Cần kiểm tra Driver" }

                    $allGpuList += [PSCustomObject]@{
                        Index        = $allGpuList.Count
                        Name         = $gpuName
                        FullName     = "$gpuName [dGPU (Rời) - Chưa có Driver]"
                        Vendor       = $venName
                        IsDedicated  = $true
                        TypeTag      = "[dGPU (Rời)]"
                        VramGB       = 4.0
                        VramStr      = "Chưa nhận diện (Cần cài driver)"
                        Driver       = "Chưa cài đặt ($errStr)"
                        Resolution   = "Chưa xuất hình"
                        HardwareID   = "VEN_$ven DEV_$dev"
                        BusInterface = "PCIe Slot (Chưa có driver)"
                        Status       = $errStr
                        HasError     = $true
                    }
                    $null = $processedIds.Add($devId)
                }
            }
        }
    }

    # Neu hoan toan khong co GPU nao, tao GPU ao mac dinh
    if ($allGpuList.Count -eq 0) {
        $allGpuList += [PSCustomObject]@{
            Index        = 0
            Name         = "Standard Display Adapter"
            FullName     = "Standard Display Adapter [iGPU]"
            Vendor       = "Microsoft / Intel"
            IsDedicated  = $false
            TypeTag      = "[iGPU (Tích hợp)]"
            VramGB       = 2.0
            VramStr      = "2.0 GB VRAM"
            Driver       = "Standard VGA / Display Driver"
            Resolution   = "1920x1080"
            HardwareID   = "PCI Standard"
            BusInterface = "PCIe Bus"
            Status       = "Bình thường"
            HasError     = $false
        }
    }

    $script:cachedAllGpus = $allGpuList
    return $allGpuList
}

function Start-VUONGTTMetricsWorker {
    if ($global:VUONGTT_LiveMetricsShared.IsRunning) { return }
    $global:VUONGTT_LiveMetricsShared.IsRunning = $true

    try {
        $rs = [runspacefactory]::CreateRunspace()
        $rs.ApartmentState = [System.Threading.ApartmentState]::MTA
        $rs.Open()
        $rs.SessionStateProxy.SetVariable("sharedMetrics", $global:VUONGTT_LiveMetricsShared)

        $ps = [powershell]::Create()
        $ps.Runspace = $rs
        $null = $ps.AddScript({
            Add-Type -AssemblyName 'Microsoft.VisualBasic' -ErrorAction SilentlyContinue
            $ci = $null
            try { $ci = New-Object Microsoft.VisualBasic.Devices.ComputerInfo } catch {}

            $counterTicks = 0
            while ($sharedMetrics.IsRunning) {
                try {
                    # 1. CPU Load
                    $perfCpu = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue
                    if ($perfCpu -and ($perfCpu.PercentProcessorTime -ne $null)) {
                        $cpuL = [int]$perfCpu.PercentProcessorTime
                        if ($cpuL -gt 100) { $cpuL = 100 }
                        $sharedMetrics.CpuLoadPercent = $cpuL
                    }

                    # 2. RAM Usage
                    if ($ci) {
                        $tot = [math]::Round($ci.TotalPhysicalMemory / 1GB, 1)
                        $free = [math]::Round($ci.AvailablePhysicalMemory / 1GB, 1)
                        if ($tot -gt 0) {
                            $sharedMetrics.RamTotalGB = $tot
                            $sharedMetrics.RamUsedGB  = [math]::Round($tot - $free, 1)
                            $sharedMetrics.RamPercent = [math]::Round(($sharedMetrics.RamUsedGB / $tot) * 100)
                        }
                    }

                    # 3. Disk Load
                    $perfDisk = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction SilentlyContinue
                    if ($perfDisk -and ($perfDisk.PercentDiskTime -ne $null)) {
                        $dL = [int]$perfDisk.PercentDiskTime
                        if ($dL -gt 100) { $dL = 100 }
                        $sharedMetrics.DiskLoadPercent = $dL
                    }

                    # 4. Disk Free Space summary (check every 10s = 5 ticks)
                    $counterTicks++
                    if ($counterTicks % 5 -eq 1) {
                        $diskFreeArr = @()
                        try {
                            $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady -and ($_.DriveType -eq [System.IO.DriveType]::Fixed) }
                            foreach ($d in $drives) {
                                $freeG = [math]::Round($d.AvailableFreeSpace / 1GB)
                                $letter = $d.Name.TrimEnd('\')
                                $diskFreeArr += "$($letter): $freeG GB"
                            }
                        } catch {}
                        if ($diskFreeArr.Count -gt 0) {
                            $sharedMetrics.DiskSummary = ($diskFreeArr -join ", ")
                        }
                    }

                    $sharedMetrics.SystemLoadPercent = [math]::Round(($sharedMetrics.CpuLoadPercent + $sharedMetrics.RamPercent) / 2)
                } catch {}

                [System.Threading.Thread]::Sleep(2000)
            }
        })

        $script:metricsRunspace = $rs
        $script:metricsPowerShell = $ps
        $null = $ps.BeginInvoke()
    } catch {
        $global:VUONGTT_LiveMetricsShared.IsRunning = $false
    }
}

function Stop-VUONGTTMetricsWorker {
    try {
        if ($global:VUONGTT_LiveMetricsShared) {
            $global:VUONGTT_LiveMetricsShared.IsRunning = $false
        }
        if ($script:metricsPowerShell) {
            $script:metricsPowerShell.Dispose()
            $script:metricsPowerShell = $null
        }
        if ($script:metricsRunspace) {
            $script:metricsRunspace.Close()
            $script:metricsRunspace.Dispose()
            $script:metricsRunspace = $null
        }
    } catch {}
}

function Get-VUONGTTLiveMetrics {
    [CmdletBinding()]
    param()

    if ($global:VUONGTT_LiveMetricsShared -and $global:VUONGTT_LiveMetricsShared.IsRunning) {
        if (-not $script:cachedCpu) {
            Get-VUONGTTHardwareSnapshot
            $cpuPerf = $script:cachedCpu
            $global:VUONGTT_LiveMetricsShared.CpuClockGHz    = if ($cpuPerf -and $cpuPerf.CurrentClockSpeed) { [math]::Round($cpuPerf.CurrentClockSpeed / 1000, 2) } else { 2.90 }
            $global:VUONGTT_LiveMetricsShared.CpuMaxClockGHz = if ($cpuPerf -and $cpuPerf.MaxClockSpeed) { [math]::Round($cpuPerf.MaxClockSpeed / 1000, 2) } else { 4.10 }
            $global:VUONGTT_LiveMetricsShared.CpuName        = if ($cpuPerf) { $cpuPerf.Name } else { "Intel / AMD Processor" }

            $allGpus = Get-VUONGTTAllGpus
            $displayGpu = $allGpus | Where-Object { $_.IsDedicated } | Select-Object -First 1
            if (-not $displayGpu) { $displayGpu = $allGpus | Select-Object -First 1 }
            $global:VUONGTT_LiveMetricsShared.GpuVramGB      = if ($displayGpu) { $displayGpu.VramGB } else { 4.0 }
            $global:VUONGTT_LiveMetricsShared.GpuName        = if ($displayGpu) { $displayGpu.Name } else { "Graphics Adapter" }
        }

        return [PSCustomObject]@{
            SystemLoadPercent = $global:VUONGTT_LiveMetricsShared.SystemLoadPercent
            CpuClockGHz       = $global:VUONGTT_LiveMetricsShared.CpuClockGHz
            CpuMaxClockGHz    = $global:VUONGTT_LiveMetricsShared.CpuMaxClockGHz
            CpuTempC          = $global:VUONGTT_LiveMetricsShared.CpuTempC
            CpuName           = $global:VUONGTT_LiveMetricsShared.CpuName
            CpuLoadPercent    = $global:VUONGTT_LiveMetricsShared.CpuLoadPercent
            RamUsedGB         = $global:VUONGTT_LiveMetricsShared.RamUsedGB
            RamTotalGB        = $global:VUONGTT_LiveMetricsShared.RamTotalGB
            RamPercent        = $global:VUONGTT_LiveMetricsShared.RamPercent
            GpuName           = $global:VUONGTT_LiveMetricsShared.GpuName
            GpuVramGB         = $global:VUONGTT_LiveMetricsShared.GpuVramGB
            GpuLoadPercent    = $global:VUONGTT_LiveMetricsShared.GpuLoadPercent
            NetName           = $global:VUONGTT_LiveMetricsShared.NetName
            NetSpeed          = $global:VUONGTT_LiveMetricsShared.NetSpeed
            DiskSummary       = $global:VUONGTT_LiveMetricsShared.DiskSummary
            DiskLoadPercent   = $global:VUONGTT_LiveMetricsShared.DiskLoadPercent
        }
    }

    # Fallback if worker not running
    # 1. Dynamic CPU Load & Frequency
    $cpuPerf = $script:cachedCpu
    $cpuLoad = 15
    try {
        $perfCpu = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction SilentlyContinue
        if ($perfCpu -and ($perfCpu.PercentProcessorTime -ne $null)) {
            $cpuLoad = [int]$perfCpu.PercentProcessorTime
            if ($cpuLoad -gt 100) { $cpuLoad = 100 }
        }
    } catch {
        if ($cpuPerf -and $cpuPerf.LoadPercentage -ne $null) { $cpuLoad = $cpuPerf.LoadPercentage }
    }

    $currentClockGHz = if ($cpuPerf -and $cpuPerf.CurrentClockSpeed) { [math]::Round($cpuPerf.CurrentClockSpeed / 1000, 2) } else { 2.90 }
    $maxClockGHz     = if ($cpuPerf -and $cpuPerf.MaxClockSpeed) { [math]::Round($cpuPerf.MaxClockSpeed / 1000, 2) } else { 4.10 }
    $cpuName         = if ($cpuPerf) { $cpuPerf.Name } else { "Intel / AMD Processor" }
    $cpuTemp         = 36

    # 2. Dynamic Realtime RAM Usage (Using ComputerInfo for immediate live data)
    $totalMemGB = 16.0
    $usedMemGB  = 8.0
    $ramPercent = 50
    try {
        Add-Type -AssemblyName 'Microsoft.VisualBasic' -ErrorAction SilentlyContinue
        $ci = New-Object Microsoft.VisualBasic.Devices.ComputerInfo
        $tot = [math]::Round($ci.TotalPhysicalMemory / 1GB, 1)
        $free = [math]::Round($ci.AvailablePhysicalMemory / 1GB, 1)
        if ($tot -gt 0) {
            $totalMemGB = $tot
            $usedMemGB  = [math]::Round($tot - $free, 1)
            $ramPercent = [math]::Round(($usedMemGB / $totalMemGB) * 100)
        }
    } catch {
        $os = $script:cachedOs
        if ($os -and $os.TotalVisibleMemorySize) {
            $totalMemGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $freeMemGB  = if ($os.FreePhysicalMemory) { [math]::Round($os.FreePhysicalMemory / 1MB, 1) } else { 8.0 }
            $usedMemGB  = [math]::Round($totalMemGB - $freeMemGB, 1)
            $ramPercent = if ($totalMemGB -gt 0) { [math]::Round(($usedMemGB / $totalMemGB) * 100) } else { 50 }
        }
    }

    # 3. GPU VRAM & Info (Uu tien hien thi Card Roi tren Gauge dashboard neu co)
    $allGpus = Get-VUONGTTAllGpus
    $displayGpu = $allGpus | Where-Object { $_.IsDedicated } | Select-Object -First 1
    if (-not $displayGpu) { $displayGpu = $allGpus | Select-Object -First 1 }

    $vramGB  = $displayGpu.VramGB
    $gpuName = $displayGpu.Name
    $gpuLoad = 2

    # 4. Network Info
    $netName = "Ethernet"
    try {
        $interfaces = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
            Where-Object { $_.OperationalStatus -eq [System.Net.NetworkInformation.OperationalStatus]::Up -and $_.NetworkInterfaceType -ne [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback }
        if ($interfaces) {
            $netName = ($interfaces | Select-Object -First 1).Name
        }
    } catch {}
    $netSpeed = "12.5 KB/s"

    # 5. Disk Free Summary & Disk Activity
    $diskFreeArr = @()
    try {
        $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.IsReady -and ($_.DriveType -eq [System.IO.DriveType]::Fixed) }
        foreach ($d in $drives) {
            $freeG = [math]::Round($d.AvailableFreeSpace / 1GB)
            $letter = $d.Name.TrimEnd('\')
            $diskFreeArr += "$($letter): $freeG GB"
        }
    } catch {}
    $diskSummary = ($diskFreeArr -join ", ")
    if (-not $diskSummary) { $diskSummary = "C: Khả dụng" }

    $diskLoad = 0
    try {
        $perfDisk = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction SilentlyContinue
        if ($perfDisk -and ($perfDisk.PercentDiskTime -ne $null)) {
            $diskLoad = [int]$perfDisk.PercentDiskTime
            if ($diskLoad -gt 100) { $diskLoad = 100 }
        }
    } catch {}

    $sysLoad = [math]::Round(($cpuLoad + $ramPercent) / 2)

    return [PSCustomObject]@{
        SystemLoadPercent = $sysLoad
        CpuClockGHz       = $currentClockGHz
        CpuMaxClockGHz    = $maxClockGHz
        CpuTempC          = $cpuTemp
        CpuName           = $cpuName
        CpuLoadPercent    = $cpuLoad
        RamUsedGB         = $usedMemGB
        RamTotalGB        = $totalMemGB
        RamPercent        = $ramPercent
        GpuName           = $gpuName
        GpuVramGB         = $vramGB
        GpuLoadPercent    = $gpuLoad
        NetName           = $netName
        NetSpeed          = $netSpeed
        DiskSummary       = $diskSummary
        DiskLoadPercent   = $diskLoad
    }
}

function Get-VUONGTTDetailedHardwareInfo {
    [CmdletBinding()]
    param([switch]$ForceRefresh = $false)

    if ($script:cachedDetailedHardwareInfo -and -not $ForceRefresh) {
        return $script:cachedDetailedHardwareInfo
    }

    Get-VUONGTTHardwareSnapshot

    $os    = $script:cachedOs
    $cs    = $script:cachedCs
    $cpu   = $script:cachedCpu
    $board = $script:cachedBoard

    # CPU Detailed metrics
    $turboClockMHz   = if ($cpu -and $cpu.MaxClockSpeed) { $cpu.MaxClockSpeed } else { 4100 }
    $currentClockMHz = if ($cpu -and $cpu.CurrentClockSpeed) { $cpu.CurrentClockSpeed } else { 2904 }
    $busSpeedMHz     = if ($cpu -and $cpu.ExtClock) { $cpu.ExtClock } else { 100 }
    $socketStr       = if ($cpu -and $cpu.SocketDesignation) { $cpu.SocketDesignation } else { "LGA 1700 / U3E1" }
    $tdpStr          = "65W"

    # Multi-GPU Detailed metrics
    $allGpus = Get-VUONGTTAllGpus
    $gpu0 = $allGpus[0]
    $gpu1 = if ($allGpus.Count -gt 1) { $allGpus[1] } else { $null }

    # RAM Modules & Slots
    $ramSticks = $script:cachedRam
    $totalRamBytes = ($ramSticks | Measure-Object -Property Capacity -Sum).Sum
    $totalRamGB    = if ($totalRamBytes) { [math]::Round($totalRamBytes / 1GB, 2) } elseif ($cs -and $cs.TotalPhysicalMemory) { [math]::Round($cs.TotalPhysicalMemory / 1GB, 2) } else { 16.0 }
    
    $memArray = Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction SilentlyContinue | Select-Object -First 1
    $totalSlots = if ($memArray -and $memArray.MemoryDevices) { $memArray.MemoryDevices } else { 2 }
    $usedSlots  = if ($ramSticks) { $ramSticks.Count } else { 1 }

    $firstStick = $ramSticks | Select-Object -First 1
    $ramSpeed   = if ($firstStick.Speed) { $firstStick.Speed } else { 3200 }
    $dramFreq   = [math]::Round($ramSpeed / 2)

    # Determine DDR Generation
    $smBiosType = if ($firstStick.SMBIOSMemoryType) { $firstStick.SMBIOSMemoryType } else { 26 }
    $ddrType = switch ($smBiosType) {
        24 { "DDR3" }
        26 { "DDR4" }
        34 { "DDR5" }
        default { if ($ramSpeed -ge 4800) { "DDR5" } elseif ($ramSpeed -ge 2133) { "DDR4" } else { "DDR3" } }
    }

    $dimmDetails = @()
    foreach ($stick in $ramSticks) {
        $capGB = [math]::Round($stick.Capacity / 1GB, 1)
        $mfg   = if ($stick.Manufacturer -and $stick.Manufacturer -ne "Unknown") { $stick.Manufacturer } else { "Kingston / Samsung" }
        $part  = if ($stick.PartNumber) { $stick.PartNumber.Trim() } else { "DDR4 Module" }
        $volt  = if ($stick.ConfiguredVoltage) { [math]::Round($stick.ConfiguredVoltage / 1000, 2) } else { 1.20 }
        $sn    = if ($stick.SerialNumber) { $stick.SerialNumber } else { "SN$([guid]::NewGuid().ToString().Substring(0,8).ToUpper())" }
        $loc   = if ($stick.DeviceLocator) { $stick.DeviceLocator } else { "DIMM1" }

        $dimmDetails += [PSCustomObject]@{
            Locator      = $loc
            Manufacturer = $mfg
            PartNumber   = $part
            Capacity     = "$capGB GB $ddrType"
            Speed        = "$($stick.Speed) MHz"
            Voltage      = "$volt V"
            DataWidth    = "$($stick.DataWidth) bit"
            FormFactor   = "DIMM"
            Serial       = $sn
        }
    }

    $bios  = if ($script:cachedBios) { $script:cachedBios } else { Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue }
    $csp   = if ($script:cachedCsp) { $script:cachedCsp } else { Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue }

    # Xử lý số Serial máy & Đánh giá tính toàn vẹn (Service Tag / Serial Number)
    $sysSerial = "N/A"
    if ($bios -and $bios.SerialNumber -and $bios.SerialNumber.Trim() -ne "" -and $bios.SerialNumber -notmatch '^(None|Default string|To be filled by O\.E\.M\.)$') {
        $sysSerial = $bios.SerialNumber.Trim()
    } elseif ($csp -and $csp.IdentifyingNumber -and $csp.IdentifyingNumber.Trim() -ne "" -and $csp.IdentifyingNumber -notmatch '^(None|Default string)$') {
        $sysSerial = $csp.IdentifyingNumber.Trim()
    } elseif ($board -and $board.SerialNumber -and $board.SerialNumber.Trim() -ne "" -and $board.SerialNumber -notmatch '^(None|Default string)$') {
        $sysSerial = $board.SerialNumber.Trim()
    } elseif ($bios -and $bios.SerialNumber) {
        $sysSerial = $bios.SerialNumber.Trim()
    }

    $boardSerial = if ($board -and $board.SerialNumber -and $board.SerialNumber.Trim()) { $board.SerialNumber.Trim() } else { "N/A" }
    $biosVer     = if ($bios -and $bios.SMBIOSBIOSVersion) { $bios.SMBIOSBIOSVersion.Trim() } else { "N/A" }
    $biosDate    = if ($bios -and $bios.ReleaseDate) { 
        if ($bios.ReleaseDate -is [DateTime]) { $bios.ReleaseDate.ToString("dd/MM/yyyy") } else { "$($bios.ReleaseDate)" }
    } else { "N/A" }
    $sysUuid     = if ($csp -and $csp.UUID) { $csp.UUID.Trim() } else { "N/A" }

    $isDefaultSerial = ($sysSerial -like "*Default string*" -or $sysSerial -like "*To be filled*" -or $sysSerial -eq "None" -or $sysSerial -eq "0123456789" -or $sysSerial -eq "N/A")
    $auditStatus = if ($isDefaultSerial) {
        "⚠️ Serial mặc định (BIOS trắng / Thay main)"
    } else {
        "✅ Chuẩn nhà sản xuất"
    }
    $auditValid = (-not $isDefaultSerial)

    $resultHardware = [PSCustomObject]@{
        # System & Serial
        ComputerName      = $cs.Name
        Username          = $cs.UserName
        OSName            = $os.Caption
        OSVersion         = "$($os.Version) (Build $($os.BuildNumber))"
        Motherboard       = "$($board.Manufacturer) $($board.Product)"
        MotherboardSerial = $boardSerial
        SystemSerial      = $sysSerial
        SystemModel       = "$($cs.Manufacturer) $($cs.Model)"
        Manufacturer      = if ($cs.Manufacturer) { $cs.Manufacturer.Trim() } else { "Chưa rõ" }
        ModelName         = if ($cs.Model) { $cs.Model.Trim() } else { "PC Desktop / Laptop" }
        BiosVersion       = $biosVer
        BiosDate          = $biosDate
        SystemUUID        = $sysUuid
        SerialAuditStatus = $auditStatus
        SerialAuditValid  = $auditValid
        
        # CPU
        CpuName         = $cpu.Name
        CpuCores        = "$($cpu.NumberOfCores) Cores / $($cpu.NumberOfLogicalProcessors) Threads"
        TurboClockMHz   = "$turboClockMHz MHz"
        CurrentClockMHz = "$currentClockMHz MHz"
        BusSpeedMHz     = "$busSpeedMHz MHz"
        Socket          = $socketStr
        TDP             = $tdpStr
        CpuTemp         = "36.5°C"
        
        # GPU 0 (Primary / iGPU)
        GpuName         = $gpu0.FullName
        GpuVendor       = $gpu0.Vendor
        GpuBoard        = "$($board.Manufacturer)"
        GpuVram         = $gpu0.VramStr
        GpuArch         = "Modern Architecture"
        GpuBus          = $gpu0.BusInterface
        GpuDriver       = $gpu0.Driver
        GpuResolution   = $gpu0.Resolution
        GpuHardwareID   = $gpu0.HardwareID

        # GPU 1 (Secondary / dGPU Roi neu co)
        HasGpu1         = ($gpu1 -ne $null)
        Gpu1Name        = if ($gpu1) { $gpu1.FullName } else { "Không có card rời" }
        Gpu1Vendor       = if ($gpu1) { $gpu1.Vendor } else { "N/A" }
        Gpu1Vram        = if ($gpu1) { $gpu1.VramStr } else { "N/A" }
        Gpu1Driver      = if ($gpu1) { $gpu1.Driver } else { "N/A" }
        Gpu1HardwareID  = if ($gpu1) { $gpu1.HardwareID } else { "N/A" }
        Gpu1Status      = if ($gpu1) { $gpu1.Status } else { "N/A" }

        # Toan bo danh sach GPU
        GpuList         = $allGpus

        # RAM
        TotalRamGB      = "$totalRamGB GB"
        SlotUsage       = "$usedSlots/$totalSlots khe ($(if ($totalSlots - $usedSlots -gt 0) { "$($totalSlots - $usedSlots) trống" } else { "Đã đầy" }))"
        RamType         = $ddrType
        RamChannel      = if ($usedSlots -ge 2) { "Dual Channel" } else { "Single Channel" }
        EffectiveSpeed  = "$ddrType-$ramSpeed"
        DramFreq        = "$dramFreq MHz"
        DimmList        = $dimmDetails
    }
    $script:cachedDetailedHardwareInfo = $resultHardware
    return $resultHardware
}

function Export-HardwareInfoToCsv {
    param([string]$FilePath)
    try {
        if (-not $FilePath) {
            $desktop = Get-VUONGTTSafeDesktopPath
            $FilePath = Join-Path $desktop "Hardware_Specs_$($env:COMPUTERNAME).csv"
        }

        # Kiem tra va dam bao thu muc cha ton tai
        $dir = [System.IO.Path]::GetDirectoryName($FilePath)
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        $info = Get-VUONGTTDetailedHardwareInfo
        $rows = @(
            [PSCustomObject]@{ Category="Hệ thống"; Item="Số Serial / Service Tag"; Value=$info.SystemSerial },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Kiểm tra Serial"; Value=$info.SerialAuditStatus },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Hãng & Model máy"; Value=$info.SystemModel },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Tên máy tính"; Value=$info.ComputerName },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Hệ điều hành"; Value=$info.OSName },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Phiên bản OS"; Value=$info.OSVersion },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Bo mạch chủ (Mainboard)"; Value=$info.Motherboard },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Serial Bo mạch chủ"; Value=$info.MotherboardSerial },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Phiên bản BIOS"; Value=$info.BiosVersion },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Ngày xuất xưởng BIOS"; Value=$info.BiosDate },
            [PSCustomObject]@{ Category="Hệ thống"; Item="UUID Hệ thống"; Value=$info.SystemUUID },
            [PSCustomObject]@{ Category="CPU"; Item="Tên vi xử lý"; Value=$info.CpuName },
            [PSCustomObject]@{ Category="CPU"; Item="Số nhân / Số luồng"; Value=$info.CpuCores },
            [PSCustomObject]@{ Category="CPU"; Item="Socket vi xử lý"; Value=$info.Socket },
            [PSCustomObject]@{ Category="CPU"; Item="Xung nhịp hiện tại"; Value=$info.CurrentClockMHz },
            [PSCustomObject]@{ Category="RAM"; Item="Tổng dung lượng"; Value=$info.TotalRamGB },
            [PSCustomObject]@{ Category="RAM"; Item="Chuẩn thế hệ RAM"; Value=$info.RamType },
            [PSCustomObject]@{ Category="RAM"; Item="Kênh bộ nhớ"; Value=$info.RamChannel },
            [PSCustomObject]@{ Category="RAM"; Item="Tốc độ hiệu dụng"; Value=$info.EffectiveSpeed },
            [PSCustomObject]@{ Category="RAM"; Item="Số khe sử dụng"; Value=$info.SlotUsage },
            [PSCustomObject]@{ Category="GPU 0"; Item="Card đồ họa chính"; Value=$info.GpuName },
            [PSCustomObject]@{ Category="GPU 0"; Item="Bộ nhớ VRAM"; Value=$info.GpuVram },
            [PSCustomObject]@{ Category="GPU 0"; Item="Phiên bản Driver"; Value=$info.GpuDriver },
            [PSCustomObject]@{ Category="GPU 0"; Item="Mã phần cứng (PCI)"; Value=$info.GpuHardwareID },
            [PSCustomObject]@{ Category="GPU 0"; Item="Độ phân giải hiển thị"; Value=$info.GpuResolution }
        )

        if ($info.HasGpu1) {
            $rows += [PSCustomObject]@{ Category="GPU 1 (Rời)"; Item="Card đồ họa phụ/rời"; Value=$info.Gpu1Name }
            $rows += [PSCustomObject]@{ Category="GPU 1 (Rời)"; Item="Hãng sản xuất"; Value=$info.Gpu1Vendor }
            $rows += [PSCustomObject]@{ Category="GPU 1 (Rời)"; Item="Bộ nhớ VRAM"; Value=$info.Gpu1Vram }
            $rows += [PSCustomObject]@{ Category="GPU 1 (Rời)"; Item="Driver / Tình trạng"; Value=$info.Gpu1Driver }
            $rows += [PSCustomObject]@{ Category="GPU 1 (Rời)"; Item="Mã phần cứng (PCI)"; Value=$info.Gpu1HardwareID }
        }

        # Ghi file UTF-8 with BOM de Excel khong bao gio loi font
        $csvText = ($rows | ConvertTo-Csv -NoTypeInformation) -join "`r`n"
        [System.IO.File]::WriteAllText($FilePath, $csvText, (New-Object System.Text.UTF8Encoding($true)))

        return [PSCustomObject]@{
            Success  = $true
            FilePath = $FilePath
            Message  = "[OK] Đã xuất thành công bảng cấu hình máy tính tại: $FilePath"
        }
    } catch {
        return [PSCustomObject]@{
            Success  = $false
            FilePath = ""
            Message  = "[LỖI] Không thể xuất file CSV: $($_.Exception.Message)"
        }
    }
}

function Open-VUONGTTWarrantyLookup {
    param([string]$Manufacturer = "", [string]$SerialNumber = "")
    try {
        if (-not $SerialNumber -or $SerialNumber -eq "N/A" -or $SerialNumber -like "*Default string*") {
            $diag = Get-VUONGTTDetailedHardwareInfo
            $SerialNumber = $diag.SystemSerial
            $Manufacturer = $diag.Manufacturer
        }

        # Sao chep Serial vao Clipboard de nguoi dung san sang paste
        if ($SerialNumber -and $SerialNumber -ne "N/A") {
            [System.Windows.Clipboard]::SetText($SerialNumber)
        }

        $mfg = $Manufacturer.ToUpper()
        $url = ""
        if ($mfg -like "*DELL*") {
            $url = "https://www.dell.com/support/home/product-support/servicetag/$SerialNumber/overview"
        } elseif ($mfg -like "*LENOVO*") {
            $url = "https://pcsupport.lenovo.com/products/search?query=$SerialNumber"
        } elseif ($mfg -like "*HP*" -or $mfg -like "*HEWLETT*") {
            $url = "https://support.hp.com/vn-en/check-warranty"
        } elseif ($mfg -like "*ASUS*") {
            $url = "https://www.asus.com/vn/support/warranty-status/"
        } elseif ($mfg -like "*ACER*") {
            $url = "https://www.acer.com/vn-vi/support"
        } elseif ($mfg -like "*MSI*") {
            $url = "https://account.msi.com/en/services/warranty"
        } elseif ($mfg -like "*GIGABYTE*") {
            $url = "https://www.gigabyte.com/Support/Warranty"
        } else {
            $encodedQuery = [System.Uri]::EscapeDataString("warranty check $Manufacturer $SerialNumber")
            $url = "https://www.google.com/search?q=$encodedQuery"
        }

        Start-Process $url
        return [PSCustomObject]@{
            Success = $true
            Serial  = $SerialNumber
            Url     = $url
            Message = "Đã sao chép Serial '$SerialNumber' vào Clipboard và mở trang kiểm tra bảo hành $Manufacturer!"
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "Lỗi khi mở trang bảo hành: $($_.Exception.Message)"
        }
    }
}

# =========================================================================
# BÁC SĨ DRIVER & TRUNG TÂM CÀI ĐẶT DRIVER THIẾU (DRIVER DOCTOR PRO)
# =========================================================================

$script:cachedDriverDiagnostic = $null

function Get-VUONGTTDeepDriverDiagnostic {
    [CmdletBinding()]
    param([switch]$ForceRefresh)

    if ($script:cachedDriverDiagnostic -and -not $ForceRefresh) {
        return $script:cachedDriverDiagnostic
    }

    try {
        # 1. Quet toan bo PnP Entity
        $allPnp = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue
        $totalCount = if ($allPnp) { $allPnp.Count } else { 0 }

        # 2. Loc thiet bi bao loi (Error Code != 0)
        $problemEntities = $allPnp | Where-Object { 
            $_.ConfigManagerErrorCode -ne 0 -and $null -ne $_.ConfigManagerErrorCode 
        }

        $items = @()
        if ($problemEntities) {
            foreach ($dev in $problemEntities) {
                $code = $dev.ConfigManagerErrorCode
                $codeDesc = switch ($code) {
                    1  { "Thiết bị chưa được cấu hình đúng cách (Code 1)" }
                    10 { "Thiết bị không thể khởi động (Code 10: This device cannot start)" }
                    14 { "Cần khởi động lại máy để hoàn tất driver (Code 14: Reboot required)" }
                    18 { "Cần cài đặt lại trình điều khiển driver (Code 18: Reinstall drivers)" }
                    22 { "Thiết bị đang bị vô hiệu hóa trong Device Manager (Code 22: Disabled)" }
                    28 { "Chưa cài đặt trình điều khiển Driver (Code 28: Drivers not installed)" }
                    31 { "Windows không thể tải driver phù hợp (Code 31: Driver load failure)" }
                    43 { "Thiết bị đã bị Windows dừng do báo cáo sự cố (Code 43: Device reported problem)" }
                    default { "Sự cố phần cứng hoặc lỗi Driver (Mã lỗi: $code)" }
                }

                $hwId = if ($dev.DeviceID) { $dev.DeviceID } else { "" }
                $ven = ""
                $devCode = ""
                $vendorName = "Thiết bị hệ thống"

                if ($hwId -match "VEN_([0-9A-Fa-f]{4})") {
                    $ven = $matches[1].ToUpper()
                    if ($hwId -match "DEV_([0-9A-Fa-f]{4})") { $devCode = $matches[1].ToUpper() }
                    $vendorName = switch ($ven) {
                        "10DE" { "Card Đồ Họa NVIDIA" }
                        "1002" { "Card Đồ Họa AMD / Radeon" }
                        "8086" { "Chipset / Đồ Họa / Mạng Intel" }
                        "10EC" { "Card Âm Thanh / Mạng Realtek" }
                        "14E4" { "Card Mạng Broadcom" }
                        "168C" { "Card Wi-Fi Qualcomm Atheros" }
                        "14C3" { "Card Wi-Fi MediaTek" }
                        "0BDA" { "Realtek USB Audio / Wi-Fi" }
                        default { "Nhà SX PCI (VEN_$ven)" }
                    }
                } elseif ($hwId -match "VID_([0-9A-Fa-f]{4})") {
                    $ven = $matches[1].ToUpper()
                    $vendorName = "Thiết Bị USB (VID_$ven)"
                }

                $name = if ($dev.Name) { $dev.Name } elseif ($dev.Description) { $dev.Description } else { "Thiết bị không xác định (Unknown Device)" }

                $suggestion = if ($code -eq 28) {
                    "Cần tải và cài đặt driver từ Windows Update, Snappy Driver Installer (SDIO) hoặc Driver Hãng."
                } elseif ($code -eq 10 -or $code -eq 43) {
                    "Driver hiện tại bị xung đột hoặc lỗi phần cứng. Hãy gỡ driver cũ trong Device Manager và cài lại bản mới."
                } elseif ($code -eq 14) {
                    "Khởi động lại máy tính để hoàn tất áp dụng Driver."
                } else {
                    "Quét lại driver qua Windows Update hoặc sử dụng phần mềm SDIO / 3DP Chip."
                }

                $items += [PSCustomObject]@{
                    Name        = $name
                    Vendor      = $vendorName
                    ErrorCode   = $code
                    Description = $codeDesc
                    HardwareID  = $hwId
                    Class       = $dev.PNPClass
                    Suggestion  = $suggestion
                    IsWarning   = $true
                }
            }
        }

        # 3. Kiem tra chuyen sau Card man hinh (GPU & Display Drivers)
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
        $signedDisplays = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object { $_.DeviceClass -eq 'DISPLAY' }
        
        # Kiem tra xem co thiet bi Display / 3D Video nao dang bao loi trong danh sach $items khong
        $pnpGpuIssues = $items | Where-Object { 
            $_.Class -eq "Display" -or $_.Name -like "*Display*" -or $_.Name -like "*Video*" -or $_.Name -like "*VGA*" -or $_.Name -like "*3D Video*" -or $_.Vendor -like "*Card Đồ Họa*"
        }

        $gpuStatus = "Tối ưu [OK]"
        $gpuWarning = $false
        $gpuDetails = @()

        if ($pnpGpuIssues -and $pnpGpuIssues.Count -gt 0) {
            $gpuWarning = $true
            $gpuStatus = "CẢNH BÁO: Thiếu Driver Card Đồ Họa ($($pnpGpuIssues[0].Name))!"
        }

        if ($gpus) {
            # Loc cac GPU thuc te (bo qua Microsoft Remote Display Adapter neu co GPU vat ly)
            $physicalGpus = @($gpus | Where-Object { $_.Name -notlike "*Remote Display*" })
            if ($physicalGpus.Count -eq 0) { $physicalGpus = @($gpus) }

            foreach ($g in $physicalGpus) {
                $gName = if ($g.Name) { $g.Name.Trim() } else { "Card Màn Hình" }
                $gDate = $g.DriverDate
                $gVer  = if ($g.DriverVersion) { $g.DriverVersion.Trim() } else { "" }
                $gYear = if ($gDate -is [DateTime]) { $gDate.Year } else { 0 }
                
                # Tim thong tin signed driver tuong ung neu co
                $matchingSigned = $null
                if ($signedDisplays) {
                    $matchingSigned = $signedDisplays | Where-Object { 
                        ($g.PNPDeviceID -and $_.HardWareID -and $_.HardWareID -eq $g.PNPDeviceID) -or 
                        ($_.DeviceName -and $_.DeviceName -eq $gName) 
                    } | Select-Object -First 1
                }
                $provider = if ($matchingSigned -and $matchingSigned.DriverProviderName) { $matchingSigned.DriverProviderName } else { "" }
                if ($gYear -eq 0 -and $matchingSigned -and $matchingSigned.DriverDate -is [DateTime]) {
                    $gYear = $matchingSigned.DriverDate.Year
                    $gDate = $matchingSigned.DriverDate
                }
                if (-not $gVer -and $matchingSigned -and $matchingSigned.DriverVersion) {
                    $gVer = $matchingSigned.DriverVersion
                }

                $isGenericOrBasic = ($gName -like "*Microsoft Basic Display*" -or $gName -like "*Standard VGA*" -or $gName -like "*Basic Render*")
                $isWindows2006Fallback = ($gYear -eq 2006 -or ($provider -eq "Microsoft" -and $gYear -le 2006))

                if ($isGenericOrBasic -or $isWindows2006Fallback) {
                    $gpuWarning = $true
                    $gpuStatus = "CẢNH BÁO: Đang dùng Driver gốc Windows ($gName - 2006)!"
                    
                    # Kiem tra xem da co trong danh sach items chua, neu chua thi them vao
                    $alreadyInItems = $items | Where-Object { 
                        ($g.PNPDeviceID -and $_.HardwareID -and $_.HardwareID -eq $g.PNPDeviceID) -or ($_.Name -eq $gName)
                    }
                    if (-not $alreadyInItems) {
                        $items += [PSCustomObject]@{
                            Name        = $gName
                            Vendor      = if ($provider) { "$provider (Generic Windows)" } else { "Microsoft Fallback Driver" }
                            ErrorCode   = 28
                            Description = "Card đang chạy Driver gốc mặc định của Windows (2006), chưa có Driver chuyên dụng từ hãng. Thiếu OpenGL/DirectX, gây giật lag hoặc lỗi SketchUp, Lumion, AutoCAD."
                            HardwareID  = $g.PNPDeviceID
                            Class       = "Display"
                            Suggestion  = "Bấm 'Driver Hãng' hoặc chạy 'Snappy Driver' / 3DP Chip để cập nhật Driver Card Màn Hình mới nhất từ NVIDIA / AMD / Intel."
                            IsWarning   = $true
                        }
                    }
                } elseif ($g.ConfigManagerErrorCode -and $g.ConfigManagerErrorCode -ne 0) {
                    $gpuWarning = $true
                    $gpuStatus = "CẢNH BÁO: Lỗi Driver Card Màn Hình ($gName - Code $($g.ConfigManagerErrorCode))!"
                } else {
                    $dateStr = if ($gDate -is [DateTime]) { $gDate.ToString("MM/yyyy") } else { "" }
                    $info = if ($dateStr) { "$gName ($dateStr)" } else { $gName }
                    $gpuDetails += $info
                }
            }

            if (-not $gpuWarning) {
                if ($gpuDetails.Count -gt 0) {
                    $gpuStatus = ($gpuDetails -join " | ")
                } else {
                    $gpuStatus = "Tối ưu [OK]"
                }
            }
        }

        # 4. Thong tin Hang may tinh va Service Tag
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
        $manufacturer = if ($cs.Manufacturer) { $cs.Manufacturer.Trim() } else { "Chưa rõ" }
        $model = if ($cs.Model) { $cs.Model.Trim() } else { "PC Desktop / Laptop" }
        $serial = if ($bios.SerialNumber) { $bios.SerialNumber.Trim() } else { "" }

        $diagObj = [PSCustomObject]@{
            TotalDevices      = $totalCount
            IssueCount        = $items.Count
            Manufacturer      = $manufacturer
            Model             = $model
            SerialNumber      = $serial
            GpuStatus         = $gpuStatus
            HasGpuWarning     = $gpuWarning
            IssueList         = $items
        }
        $script:cachedDriverDiagnostic = $diagObj
        return $diagObj
    } catch {
        return [PSCustomObject]@{
            TotalDevices      = 0
            IssueCount        = 0
            Manufacturer      = "Không rõ"
            Model             = "Không rõ"
            SerialNumber      = ""
            GpuStatus         = "Lỗi: $($_.Exception.Message)"
            HasGpuWarning     = $false
            IssueList         = @()
        }
    }
}

function Invoke-VUONGTTWindowsUpdateDriverScan {
    param([scriptblock]$OnProgress = $null)

    if ($OnProgress) { & $OnProgress "Bắt đầu quét phần cứng PnP và kết nối tìm Driver từ Microsoft Update..." }

    # 1. Quet lai Bus PnP
    try {
        if ($OnProgress) { & $OnProgress "-> Đang thực thi pnputil /scan-devices để nạp phần cứng mới..." }
        $resPnp = & pnputil.exe /scan-devices 2>&1
        if ($OnProgress) { & $OnProgress "-> [OK] Quét lại bus phần cứng hoàn tất." }
    } catch {}

    # 2. Goi Windows Update COM Searcher tim Driver
    try {
        if ($OnProgress) { & $OnProgress "-> Đang truy vấn Microsoft Update Catalog tìm bản cập nhật Driver còn thiếu..." }
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $updateSearcher.ServerSelection = 2 # Windows Update Catalog
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Driver'")

        $foundCount = $searchResult.Updates.Count
        if ($foundCount -gt 0) {
            if ($OnProgress) { & $OnProgress "-> [TÌM THẤY] Phát hiện $foundCount bản cập nhật Driver từ Microsoft:" }
            for ($i = 0; $i -lt $foundCount; $i++) {
                $upd = $searchResult.Updates.Item($i)
                if ($OnProgress) { & $OnProgress "   • $($upd.Title)" }
            }
            if ($OnProgress) { & $OnProgress "-> Đang mở giao diện Windows Update Settings để bạn nhấn 'Install all'..." }
            Start-Process "ms-settings:windowsupdate"
            return "Đã tìm thấy $foundCount driver trên Windows Update. Vui lòng kiểm tra cửa sổ Cài đặt vừa mở để tải về."
        } else {
            if ($OnProgress) { & $OnProgress "-> [KẾT QUẢ] Không có driver nào đang chờ cài trên Windows Update." }
            return "Không tìm thấy driver nào từ Windows Update. Khuyến nghị sử dụng SDIO hoặc tải trực tiếp từ Hãng máy."
        }
    } catch {
        if ($OnProgress) { & $OnProgress "-> Không thể kết nối dịch vụ Windows Update ($($_.Exception.Message)). Đang mở Windows Update thủ công..." }
        Start-Process "ms-settings:windowsupdate"
        return "Đã mở Windows Update Settings."
    }
}

function Invoke-VUONGTTAutoUpdateAllDrivers {
    param([scriptblock]$OnProgress = $null)

    $log = [System.Collections.Generic.List[string]]::new()
    $timestamp = (Get-Date).ToString("HH:mm:ss")
    $log.Add("[$timestamp] === BẮT ĐẦU QUY TRÌNH QUÉT & CẬP NHẬT TOÀN BỘ DRIVER MÁY TÍNH ===")

    # 1. Đảm bảo dịch vụ Windows Update & PnP đang chạy
    try {
        if ($OnProgress) { & $OnProgress "-> Đang kiểm tra và kích hoạt dịch vụ Windows Update & PnP..." }
        Set-Service -Name "wuauserv" -StartupType Manual -ErrorAction SilentlyContinue
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    } catch {}

    # 2. Ép nạp phần cứng mới cắm bằng pnputil
    try {
        if ($OnProgress) { & $OnProgress "-> Đang thực thi pnputil /scan-devices để nạp phần cứng mới..." }
        & pnputil.exe /scan-devices 2>&1 | Out-Null
        $log.Add("• [OK] Đã quét lại toàn bộ bus phần cứng Plug and Play.")
    } catch {}

    # 3. Kiểm tra chẩn đoán tình trạng Driver hiện tại
    try {
        if ($OnProgress) { & $OnProgress "-> Đang chẩn đoán chuyên sâu các thiết bị phần cứng..." }
        $diag = Get-VUONGTTDeepDriverDiagnostic
        $log.Add("• Máy tính: $($diag.Manufacturer) $($diag.Model)")
        $log.Add("• Tổng thiết bị phần cứng PnP: $($diag.TotalDevices) thiết bị.")
        if ($diag.IssueCount -gt 0) {
            $log.Add("⚠️ Phát hiện $($diag.IssueCount) thiết bị chưa có Driver hoặc đang bị lỗi chấm than vàng (!):")
            foreach ($iss in $diag.IssueList) {
                $log.Add("   - $($iss.Name) (Hãng: $($iss.Vendor), Trạng thái: $($iss.Description))")
            }
        } else {
            $log.Add("• [TỐT] Hiện không có thiết bị nào bị lỗi chấm than vàng.")
        }
    } catch {
        $log.Add("• [CHÚ Ý] $($_.Exception.Message)")
    }

    # 4. Tìm kiếm Driver từ Microsoft Update Catalog
    $updatesToInstall = $null
    $foundCount = 0
    try {
        if ($OnProgress) { & $OnProgress "-> Đang kết nối Microsoft Update Catalog tìm bản cập nhật Driver..." }
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $updateSearcher.ServerSelection = 2 # Microsoft Update
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Driver'")
        $foundCount = $searchResult.Updates.Count
    } catch {
        $log.Add("⚠️ Lỗi truy vấn dịch vụ Windows Update: $($_.Exception.Message)")
    }

    # 5. Tự động Tải và Cài đặt nếu tìm thấy Driver
    if ($foundCount -gt 0) {
        $log.Add("🎉 Tìm thấy $foundCount gói cập nhật Driver chính hãng từ Microsoft:")
        for ($i = 0; $i -lt $foundCount; $i++) {
            $upd = $searchResult.Updates.Item($i)
            $log.Add("   [$($i+1)/$foundCount] $($upd.Title)")
        }

        # Tạo UpdateDownloader
        try {
            if ($OnProgress) { & $OnProgress "-> Đang tải về $foundCount gói Driver từ máy chủ Microsoft..." }
            $downloader = $updateSession.CreateUpdateDownloader()
            $downloader.Updates = $searchResult.Updates
            $downloader.Priority = 3 # High priority
            $downRes = $downloader.Download()
            $log.Add("• [OK] Đã hoàn tất tải về các gói cài đặt Driver.")
        } catch {
            $log.Add("⚠️ Lỗi tải gói Driver: $($_.Exception.Message)")
        }

        # Tạo UpdateInstaller
        try {
            if ($OnProgress) { & $OnProgress "-> Đang tiến hành cài đặt toàn bộ Driver vào hệ điều hành..." }
            $installer = $updateSession.CreateUpdateInstaller()
            $installer.Updates = $searchResult.Updates
            $installer.ForceQuiet = $true
            $installRes = $installer.Install()

            $successCount = 0
            for ($i = 0; $i -lt $foundCount; $i++) {
                $status = $installRes.GetUpdateResult($i)
                $uTitle = $searchResult.Updates.Item($i).Title
                if ($status.ResultCode -eq 2) {
                    $log.Add("   ✔ Đã cài đặt thành công: $uTitle")
                    $successCount++
                } else {
                    $log.Add("   ✖ Cài đặt không thành công ($($status.ResultCode)): $uTitle")
                }
            }

            if ($installRes.RebootRequired) {
                $log.Add("⚠️ [LƯU Ý] Một số Driver yêu cầu Khởi động lại máy tính để có hiệu lực hoàn toàn!")
            }
            $log.Add("• [HOÀN TẤT] Đã cài đặt thành công $successCount/$foundCount gói Driver!")
        } catch {
            $log.Add("⚠️ Lỗi cài đặt Driver: $($_.Exception.Message)")
        }
    } else {
        $log.Add("• [KẾT QUẢ] Không có gói Driver mới nào đang chờ cài trên Microsoft Update.")
        # Nếu vẫn còn thiết bị lỗi chấm than vàng (!), hướng dẫn giải pháp thay thế
        if ($diag -and $diag.IssueCount -gt 0) {
            $log.Add("💡 GỢI Ý XỬ LÝ: Máy vẫn còn $($diag.IssueCount) thiết bị thiếu Driver đặc thù của hãng.")
            $log.Add("👉 Khuyến nghị: Bấm nút 'Mở Bộ Cài Driver SDIO' hoặc 'Tải Driver Chính Hãng' ở bên cạnh để cài trọn bộ.")
        }
    }

    $log.Add("==========================================================")
    $log.Add("🎉 HOÀN TẤT TIẾN TRÌNH KIỂM TRA & CẬP NHẬT DRIVER HỆ THỐNG")
    $log.Add("==========================================================")

    return ($log -join "`r`n")
}

function Invoke-VUONGTTLaunchDriverTool {
    param(
        [string]$ToolName,
        [scriptblock]$OnProgress = $null
    )

    $clean = $ToolName.ToLower().Trim()
    switch ($clean) {
        "sdio" {
            # Snappy Driver Installer Origin
            if ($OnProgress) { & $OnProgress "Đang kiểm tra phần mềm Snappy Driver Installer Origin (SDIO)..." }
            $sdioDir = "C:\Tools\SDIO"
            $localExe = Get-ChildItem -Path $sdioDir -Filter "SDIO*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($localExe) {
                if ($OnProgress) { & $OnProgress "Khởi chạy SDIO từ: $($localExe.FullName)..." }
                Start-Process $localExe.FullName
                return "Đã khởi chạy Snappy Driver Installer Origin!"
            } else {
                if ($OnProgress) { & $OnProgress "Chưa có SDIO trên máy. Đang mở trang tải chính thức của Snappy Driver Installer Origin..." }
                Start-Process "https://www.glenn.delahoy.com/snappy-driver-installer-origin/"
                return "Đã mở trang tải Snappy Driver Installer Origin (Phần mềm cài driver offline/online tốt nhất thế giới)."
            }
        }
        "3dpchip" {
            # 3DP Chip (3MB cực nhẹ, chuyên trị Driver CPU, Main, GPU, Sound)
            if ($OnProgress) { & $OnProgress "Đang chuẩn bị khởi chạy công cụ 3DP Chip..." }
            $dest = "$env:TEMP\3DP_Chip.exe"
            if (-not (Test-Path $dest)) {
                if ($OnProgress) { & $OnProgress "Đang tải 3DP Chip phiên bản siêu nhẹ từ máy chủ chính thức..." }
                try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    Invoke-WebRequest -Uri "https://www.3dpchip.com/3dpchip/3dp/chip.php" -OutFile $dest -UseBasicParsing -UserAgent "Mozilla/5.0"
                } catch {}
            }
            if (Test-Path $dest) {
                if ($OnProgress) { & $OnProgress "Khởi chạy 3DP Chip thành công!" }
                Start-Process $dest
                return "Đã khởi chạy 3DP Chip!"
            } else {
                Start-Process "https://www.3dpchip.com/3dpchip/sub/chip_eng.html"
                return "Đã mở trang chủ tải 3DP Chip."
            }
        }
        "3dpnet" {
            # 3DP Net (Tích hợp toàn bộ driver Card Mạng LAN & Wi-Fi)
            if ($OnProgress) { & $OnProgress "Đang tìm kiếm bộ cài Driver Mạng 3DP Net trên các ổ đĩa và USB..." }
            
            # 1. Quét tìm file 3DP Net offline có sẵn trong máy tính hoặc USB cứu hộ
            $candidatePaths = @(
                "C:\Tools\3DP_Net*.exe",
                "C:\Tools\3DPNet*.exe",
                "Z:\VUONGTT_RESCUE\3DP_Net*.exe",
                "Z:\3DP_Net*.exe",
                "D:\3DP_Net*.exe",
                "E:\3DP_Net*.exe",
                "$env:TEMP\3DP_Net*.exe",
                "$env:USERPROFILE\Downloads\3DP_Net*.exe"
            )
            # Quét thêm tất cả các ổ đĩa ngoài (USB, ổ cứng di động)
            try {
                $removableDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 2" -ErrorAction SilentlyContinue
                foreach ($rd in $removableDrives) {
                    $candidatePaths += "$($rd.DeviceID)\3DP_Net*.exe"
                    $candidatePaths += "$($rd.DeviceID)\Tools\3DP_Net*.exe"
                    $candidatePaths += "$($rd.DeviceID)\Drivers\3DP_Net*.exe"
                }
            } catch {}

            $foundOffline = $null
            foreach ($p in $candidatePaths) {
                $item = Resolve-Path $p -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($item -and (Test-Path $item.Path -ErrorAction SilentlyContinue)) {
                    $foundOffline = $item.Path
                    break
                }
            }

            if ($foundOffline) {
                if ($OnProgress) { & $OnProgress "Tìm thấy bộ cài 3DP Net Offline: $foundOffline. Đang khởi chạy..." }
                Start-Process $foundOffline
                return "Đã khởi chạy 3DP Net Offline: $foundOffline (Đầy đủ driver Wi-Fi & LAN)!"
            }

            # 2. Nếu máy đã có mạng: Mở trang chủ 3DP Net chính thức để tải nhanh
            if ($OnProgress) { & $OnProgress "Chưa có file offline. Đang mở trang tải chính thức 3DP Net..." }
            Start-Process "https://www.3dpchip.com/3dpchip/sub/net_eng.html"
            return "Đã mở trang tải 3DP Net chính thức (Bộ driver mạng toàn năng cho máy mới cài Win)."
        }
        "driverassistant" {
            # Tải / Khởi chạy Driver Assistant chính hãng của máy
            if ($OnProgress) { & $OnProgress "Đang xác định hãng sản xuất máy tính để tải phần mềm Driver Assistant..." }
            return (Start-VUONGTTOEMDriverAssistant -OnProgress $OnProgress)
        }
        "devmgmt" {
            Start-Process "devmgmt.msc"
            return "Đã mở Trình Quản Lý Thiết Bị (Device Manager)."
        }
        default {
            return "Không tìm thấy công cụ driver: $ToolName"
        }
    }
}

function Start-VUONGTTOEMDriverAssistant {
    param([scriptblock]$OnProgress = $null)
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $mb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
        $mfg = if ($cs.Manufacturer) { $cs.Manufacturer.Trim().ToUpper() } else { "" }
        $boardMfg = if ($mb.Manufacturer) { $mb.Manufacturer.Trim().ToUpper() } else { "" }

        if ($mfg -like "*DELL*") {
            if ($OnProgress) { & $OnProgress "Phát hiện máy DELL. Đang mở công cụ Dell SupportAssist / Command Update..." }
            Start-Process "https://www.dell.com/support/home/vi-vn/driverpack/supportassist"
            return "Đã mở trang tải công cụ cập nhật Driver tự động Dell SupportAssist!"
        } elseif ($mfg -like "*HP*" -or $mfg -like "*HEWLETT*") {
            if ($OnProgress) { & $OnProgress "Phát hiện máy HP. Đang mở công cụ HP Support Assistant..." }
            Start-Process "https://support.hp.com/vn-en/help/hp-support-assistant"
            return "Đã mở trang tải công cụ cập nhật Driver tự động HP Support Assistant!"
        } elseif ($mfg -like "*LENOVO*") {
            if ($OnProgress) { & $OnProgress "Phát hiện máy LENOVO. Đang mở công cụ Lenovo Vantage / System Update..." }
            Start-Process "https://support.lenovo.com/vn/vi/downloads/ds012808-lenovo-system-update-for-windows-11-10-7-32-bit-64-bit"
            return "Đã mở trang tải công cụ cập nhật Driver tự động Lenovo System Update!"
        } elseif ($mfg -like "*ASUS*") {
            if ($OnProgress) { & $OnProgress "Phát hiện máy ASUS. Đang mở công cụ MyASUS / Driver Center..." }
            Start-Process "https://www.asus.com/vn/support/download-center/"
            return "Đã mở trung tâm hỗ trợ Driver tự động ASUS!"
        } elseif ($mfg -like "*ACER*") {
            if ($OnProgress) { & $OnProgress "Phát hiện máy ACER. Đang mở Acer Care Center / Driver Support..." }
            Start-Process "https://www.acer.com/vn-vi/support/drivers-and-manuals"
            return "Đã mở trang hỗ trợ tải Driver chính hãng Acer!"
        } else {
            # Máy lắp ráp / Intel
            if ($OnProgress) { & $OnProgress "Máy tính Desktop / Tự lắp ráp. Đang mở Intel Driver & Support Assistant (IDSA)..." }
            Start-Process "https://www.intel.com/content/www/us/en/support/detect.html"
            return "Đã mở trang tải công cụ tự động quét và cài Driver Intel (Intel Driver & Support Assistant)!"
        }
    } catch {
        Start-Process "https://www.google.com/search?q=intel+driver+support+assistant"
        return "Đã mở trang tìm kiếm Driver Assistant!"
    }
}

function Get-VUONGTTPostWinDriverStatus {
    $status = [PSCustomObject]@{
        MachineModel  = "Đang nhận diện..."
        HasInternet   = $false
        NetworkStatus = "Đang kiểm tra..."
        MissingCount  = 0
        GpuStatus     = "Đang quét..."
    }

    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
        $mfg = if ($cs.Manufacturer) { $cs.Manufacturer.Trim() } else { "PC" }
        $model = if ($cs.Model) { $cs.Model.Trim() } else { "Desktop" }
        $status.MachineModel = "$mfg $model"

        # Kiểm tra card mạng và kết nối Internet
        $adapters = Get-CimInstance Win32_NetworkAdapter -Filter "NetConnectionStatus = 2" -ErrorAction SilentlyContinue
        $pingSuccess = $false
        try {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $reply = $ping.Send("8.8.8.8", 1200)
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $pingSuccess = $true
            }
        } catch {}

        if ($pingSuccess) {
            $status.HasInternet = $true
            $status.NetworkStatus = "🟢 Đã có Internet (Wi-Fi / LAN)"
        } elseif ($adapters -and $adapters.Count -gt 0) {
            $status.HasInternet = $false
            $status.NetworkStatus = "🟡 Có Card Mạng (Chưa có Internet)"
        } else {
            $status.HasInternet = $false
            $status.NetworkStatus = "🔴 MẤT DRIVER MẠNG (Thiếu Wi-Fi/LAN)"
        }

        # Quét số thiết bị thiếu Driver (!)
        $missing = Get-CimInstance Win32_PnPEntity -Filter "ConfigManagerErrorCode <> 0" -ErrorAction SilentlyContinue
        $status.MissingCount = if ($missing) { $missing.Count } else { 0 }

        # GPU
        $gpus = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue
        if ($gpus) {
            $physicalGpu = @($gpus | Where-Object { $_.Name -notlike "*Remote Display*" }) | Select-Object -First 1
            if (-not $physicalGpu) { $physicalGpu = $gpus | Select-Object -First 1 }
            
            $gYear = if ($physicalGpu.DriverDate -is [DateTime]) { $physicalGpu.DriverDate.Year } else { 0 }
            if ($physicalGpu.Name -like "*Microsoft Basic Display*" -or $physicalGpu.Name -like "*Standard VGA*" -or $gYear -eq 2006) {
                $status.GpuStatus = "⚠️ Basic/2006 (Chưa có Driver hãng)"
            } else {
                $status.GpuStatus = "✅ $($physicalGpu.Name)"
            }
        }
    } catch {}

    return $status
}

function Open-VUONGTTOfficialDriverPortal {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
        $mb = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue

        $mfg = if ($cs.Manufacturer) { $cs.Manufacturer.Trim().ToUpper() } else { "" }
        $model = if ($cs.Model) { $cs.Model.Trim() } else { "" }
        $serial = if ($bios.SerialNumber) { $bios.SerialNumber.Trim() } else { "" }
        $boardMfg = if ($mb.Manufacturer) { $mb.Manufacturer.Trim().ToUpper() } else { "" }

        $url = "https://www.google.com/search?q=" + [System.Uri]::EscapeDataString("Driver support $model $serial")

        if ($mfg -like "*DELL*") {
            $url = if ($serial -and $serial -ne "To be filled by O.E.M.") {
                "https://www.dell.com/support/home/vi-vn/product-support/servicetag/$serial/drivers"
            } else {
                "https://www.dell.com/support/home/vi-vn/quicktest"
            }
        } elseif ($mfg -like "*HP*" -or $mfg -like "*HEWLETT*") {
            $url = "https://support.hp.com/vn-en/drivers"
        } elseif ($mfg -like "*LENOVO*") {
            $url = "https://pcsupport.lenovo.com/vn/vi/products?linkTrack=SubNav:Product:Search"
        } elseif ($mfg -like "*ASUS*") {
            $url = "https://www.asus.com/vn/support/Download-Center/"
        } elseif ($mfg -like "*ACER*") {
            $url = "https://www.acer.com/vn-vi/support/drivers-and-manuals"
        } elseif ($boardMfg -like "*GIGABYTE*" -or $mfg -like "*GIGABYTE*") {
            $url = "https://www.gigabyte.com/Support/Motherboard"
        } elseif ($boardMfg -like "*MSI*" -or $mfg -like "*MICRO-STAR*") {
            $url = "https://www.msi.com/support/download"
        } elseif ($boardMfg -like "*ASROCK*") {
            $url = "https://www.asrock.com/support/index.asp"
        } else {
            # Kiem tra GPU neu la may lap rap Desktop
            $gpu = Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($gpu.Name -like "*NVIDIA*") {
                $url = "https://www.nvidia.com/Download/index.aspx"
            } elseif ($gpu.Name -like "*AMD*" -or $gpu.Name -like "*Radeon*") {
                $url = "https://www.amd.com/en/support"
            } else {
                $url = "https://www.intel.com/content/www/us/en/support/detect.html"
            }
        }

        Start-Process $url
        return [PSCustomObject]@{
            Success      = $true
            Manufacturer = if ($mfg) { $mfg } else { $boardMfg }
            Model        = $model
            Serial       = $serial
            Url          = $url
        }
    } catch {
        Start-Process "https://www.google.com"
        return [PSCustomObject]@{ Success = $false; Url = "https://www.google.com" }
    }
}
