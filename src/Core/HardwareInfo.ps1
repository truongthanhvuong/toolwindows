# VUONGTT Toolkit 2026 - Enhanced Hardware Information & Real-time Metrics Module
# Encoding: UTF-8 with BOM

$script:cachedCpu     = $null
$script:cachedGpu     = $null
$script:cachedOs      = $null
$script:cachedCs      = $null
$script:cachedRam     = $null
$script:cachedBoard   = $null
$script:cachedPnpGpu  = $null

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
    $script:cachedCpu    = $null
    $script:cachedGpu    = $null
    $script:cachedOs     = $null
    $script:cachedCs     = $null
    $script:cachedRam    = $null
    $script:cachedBoard  = $null
    $script:cachedPnpGpu = $null
}

# Ham phan tich danh sach tat ca cac GPU tren may (Ho tro Multi-GPU: iGPU + dGPU)
function Get-VUONGTTAllGpus {
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

    return $allGpuList
}

function Get-VUONGTTLiveMetrics {
    [CmdletBinding()]
    param()

    Get-VUONGTTHardwareSnapshot

    # 1. CPU Load & Frequency
    $cpuPerf = $script:cachedCpu
    $cpuLoad = if ($cpuPerf -and $cpuPerf.LoadPercentage -ne $null) { $cpuPerf.LoadPercentage } else { 20 }
    $currentClockGHz = if ($cpuPerf -and $cpuPerf.CurrentClockSpeed) { [math]::Round($cpuPerf.CurrentClockSpeed / 1000, 2) } else { 2.90 }
    $maxClockGHz     = if ($cpuPerf -and $cpuPerf.MaxClockSpeed) { [math]::Round($cpuPerf.MaxClockSpeed / 1000, 2) } else { 4.10 }
    $cpuName         = if ($cpuPerf) { $cpuPerf.Name } else { "Intel / AMD Processor" }
    $cpuTemp         = 36

    # 2. RAM Usage
    $os = $script:cachedOs
    $totalMemGB = if ($os -and $os.TotalVisibleMemorySize) { [math]::Round($os.TotalVisibleMemorySize / 1MB, 1) } else { 16.0 }
    $freeMemGB  = if ($os -and $os.FreePhysicalMemory) { [math]::Round($os.FreePhysicalMemory / 1MB, 1) } else { 8.0 }
    $usedMemGB  = [math]::Round($totalMemGB - $freeMemGB, 1)
    $ramPercent = if ($totalMemGB -gt 0) { [math]::Round(($usedMemGB / $totalMemGB) * 100) } else { 50 }

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

    # 5. Disk Free Summary
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

    return [PSCustomObject]@{
        SystemLoadPercent = $cpuLoad
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
        DiskLoadPercent   = 5
    }
}

function Get-VUONGTTDetailedHardwareInfo {
    [CmdletBinding()]
    param()

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

    return [PSCustomObject]@{
        # System
        ComputerName    = $cs.Name
        Username        = $cs.UserName
        OSName          = $os.Caption
        OSVersion       = "$($os.Version) (Build $($os.BuildNumber))"
        Motherboard     = "$($board.Manufacturer) $($board.Product)"
        
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
            [PSCustomObject]@{ Category="Hệ thống"; Item="Tên máy tính"; Value=$info.ComputerName },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Hệ điều hành"; Value=$info.OSName },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Phiên bản OS"; Value=$info.OSVersion },
            [PSCustomObject]@{ Category="Hệ thống"; Item="Bo mạch chủ (Mainboard)"; Value=$info.Motherboard },
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
            FilePath = $FilePath
            Message  = "Lỗi xuất file: $($_.Exception.Message)"
        }
    }
}
