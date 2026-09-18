# VUONGTT Toolkit 2026 - CPU & Motherboard Lookup Database

$script:CPU_MAIN_DATA = @(
    # --- INTEL CORE ULTRA 200S (ARROW LAKE - LGA 1851) ---
    [PSCustomObject]@{
        Keywords    = @("285K", "285", "265K", "265", "245K", "245", "CORE ULTRA 9 285K", "CORE ULTRA 7 265K", "CORE ULTRA 5 245K", "LGA 1851", "ARROW LAKE", "Z890", "B860", "H810", "W880", "Q870")
        DisplayName = "Intel Core Ultra 9 285K"
        Socket      = "LGA 1851"
        Arch        = "Arrow Lake (Core Ultra 200S - LGA 1851)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="Z890"; IsPrimary=$true; Tag="High-end, OC, PCIe 5.0" },
            [PSCustomObject]@{ Name="W880"; IsPrimary=$false; Tag="Workstation" },
            [PSCustomObject]@{ Name="Q870"; IsPrimary=$false; Tag="Enterprise / vPro" },
            [PSCustomObject]@{ Name="B860"; IsPrimary=$false; Tag="Mainstream" },
            [PSCustomObject]@{ Name="H810"; IsPrimary=$false; Tag="Entry-level" }
        )
        Notes       = @(
            "- Socket 1851, DDR5 only (hoàn toàn không hỗ trợ DDR4).",
            "- Z890: Dòng cao cấp nhất, hỗ trợ ép xung (Overclocking), full băng thông PCIe 5.0 x16 và M.2 PCIe 5.0.",
            "- B860: Dòng phổ thông quốc dân, cân đối hiệu năng/giá thành tốt nhất, hỗ trợ ép xung RAM (XMP).",
            "- H810: Phân khúc giá rẻ văn phòng, không hỗ trợ ép xung, phù hợp cấu hình tiết kiệm ngân sách.",
            "- Q870/W880: Dành cho môi trường doanh nghiệp / workstation với bảo mật phần cứng vPro & ECC RAM."
        )
    },

    # --- AMD RYZEN 9000 & 7000 (ZEN 5 / ZEN 4 - AM5) ---
    [PSCustomObject]@{
        Keywords    = @("9800X3D", "9950X", "9900X", "9700X", "9600X", "7800X3D", "7950X", "7950X3D", "7900X", "7700X", "7600X", "7600", "7500F", "AM5", "ZEN 5", "ZEN 4", "X870E", "X870", "B650E", "B650", "A620", "X670E", "X670")
        DisplayName = "AMD Ryzen 7 9800X3D / 7800X3D"
        Socket      = "Socket AM5"
        Arch        = "Zen 5 / Zen 4 (Ryzen 9000 & 7000 Series - AM5)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="X870E"; IsPrimary=$true; Tag="Flagship, USB4, Dual PCIe 5.0" },
            [PSCustomObject]@{ Name="X870"; IsPrimary=$false; Tag="High-end, USB4 standard" },
            [PSCustomObject]@{ Name="B650E"; IsPrimary=$false; Tag="Enthusiast Mainstream PCIe 5.0" },
            [PSCustomObject]@{ Name="B650"; IsPrimary=$true; Tag="Best Value Mainstream" },
            [PSCustomObject]@{ Name="A620"; IsPrimary=$false; Tag="Entry-level budget" },
            [PSCustomObject]@{ Name="X670E"; IsPrimary=$false; Tag="Flagship Extreme" }
        )
        Notes       = @(
            "- Socket AM5 (LGA 1718), DDR5 only (yêu cầu bộ nhớ DDR5, tối ưu ở mức DDR5-6000 EXPO).",
            "- X870E / X870: Trang bị sẵn cổng USB4 40Gbps kép, hỗ trợ PCIe 5.0 cho cả GPU và NVMe SSD.",
            "- B650: Chipset ngon bổ rẻ nhất, VRM tốt có thể cân từ Ryzen 5 tới Ryzen 9 ngon lành, hỗ trợ PBO.",
            "- A620: Thích hợp cho Ryzen 5 7500F / 7600, không khuyến nghị dùng cho CPU TDP cao trên 105W.",
            "- Hỗ trợ nâng cấp lâu dài ít nhất đến năm 2027 theo cam kết của AMD."
        )
    },

    # --- INTEL CORE GEN 14, 13, 12 (RAPTOR LAKE / ALDER LAKE - LGA 1700) ---
    [PSCustomObject]@{
        Keywords    = @("14900K", "14700K", "14600K", "14400", "14400F", "13900K", "13700K", "13600K", "13400", "13400F", "12900K", "12700K", "12600K", "12400", "12400F", "12100", "12100F", "LGA 1700", "Z790", "B760", "Z690", "B660", "H610")
        DisplayName = "Intel Core i5-14400 / i7-14700K / i5-12400F"
        Socket      = "LGA 1700"
        Arch        = "Raptor Lake Refresh / Alder Lake (Core 12th-14th Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="Z790"; IsPrimary=$true; Tag="High-end OC, PCIe 5.0" },
            [PSCustomObject]@{ Name="B760"; IsPrimary=$true; Tag="Mainstream Best Choice" },
            [PSCustomObject]@{ Name="H610"; IsPrimary=$false; Tag="Entry-level Budget" },
            [PSCustomObject]@{ Name="Z690"; IsPrimary=$false; Tag="Previous Gen Flagship" },
            [PSCustomObject]@{ Name="B660"; IsPrimary=$false; Tag="Previous Gen Mainstream" }
        )
        Notes       = @(
            "- Socket LGA 1700, hỗ trợ song song 2 biến thể RAM: DDR4 hoặc DDR5 (tùy thuộc vào model bo mạch chủ).",
            "- B760: Lựa chọn quốc dân cho i5-12400F, 13400F, 13600K, 14400F.",
            "- Z790: Dành riêng cho các dòng K/KF (14900K, 14700K, 13600K) để mở khóa ép xung và tải điện cao.",
            "- H610: Phù hợp nhất với i3-12100F, i5-12400F cho cấu hình gaming phổ thông hoặc văn phòng.",
            "- Lưu ý: CPU Gen 13 và 14 cần cập nhật BIOS microcode mới nhất (0x129 / 0x12B) để đảm bảo độ bền điện áp."
        )
    },

    # --- AMD RYZEN 5000 & 3000 (ZEN 3 / ZEN 2 - AM4) ---
    [PSCustomObject]@{
        Keywords    = @("5800X3D", "5700X3D", "5950X", "5900X", "5800X", "5700X", "5600X", "5600", "5600G", "5500", "3600", "3700X", "3800X", "3900X", "AM4", "ZEN 3", "ZEN 2", "B550", "X570", "B450", "A520", "A320")
        DisplayName = "AMD Ryzen 5 5600X / 5700X3D / 3600"
        Socket      = "Socket AM4"
        Arch        = "Zen 3 / Zen 2 (Ryzen 5000 & 3000 Series - AM4)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B550"; IsPrimary=$true; Tag="Best Choice PCIe 4.0" },
            [PSCustomObject]@{ Name="X570"; IsPrimary=$false; Tag="High-end PCIe 4.0 Everywhere" },
            [PSCustomObject]@{ Name="B450"; IsPrimary=$false; Tag="Budget King PCIe 3.0" },
            [PSCustomObject]@{ Name="A520"; IsPrimary=$false; Tag="Entry-level Budget" },
            [PSCustomObject]@{ Name="A320"; IsPrimary=$false; Tag="Legacy Budget" }
        )
        Notes       = @(
            "- Socket AM4 (PGA 1331), chỉ sử dụng RAM DDR4 (tối ưu nhất ở mức DDR4-3200 / DDR4-3600 CL16).",
            "- B550: Hỗ trợ PCIe 4.0 cho khe VGA và khe M.2 đầu tiên, hỗ trợ ép xung RAM và PBO tuyệt vời.",
            "- B450: Bo mạch tiết kiệm chi phí nhất, chỉ cần update BIOS là chạy mượt mà Ryzen 5 5600 / 5700X.",
            "- X570: Toàn bộ các cổng mở rộng và PCIe đều đạt chuẩn 4.0, phù hợp cho người dùng nhiều ổ cứng NVMe.",
            "- Dòng X3D (5800X3D, 5700X3D) tối ưu chơi game vượt trội nhờ bộ nhớ đệm 3D V-Cache 96MB."
        )
    },

    # --- INTEL CORE GEN 11 & 10 (ROCKET LAKE / COMET LAKE - LGA 1200) ---
    [PSCustomObject]@{
        Keywords    = @("11900K", "11700K", "11400", "11400F", "10900K", "10700K", "10400", "10400F", "10100", "10100F", "LGA 1200", "Z590", "B560", "H510", "Z490", "B460", "H410")
        DisplayName = "Intel Core i5-10400 / i5-11400 / i7-10700"
        Socket      = "LGA 1200"
        Arch        = "Rocket Lake / Comet Lake (Core 10th & 11th Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B560"; IsPrimary=$true; Tag="Mainstream, RAM OC support" },
            [PSCustomObject]@{ Name="Z590"; IsPrimary=$false; Tag="High-end OC" },
            [PSCustomObject]@{ Name="H510"; IsPrimary=$false; Tag="Entry-level" },
            [PSCustomObject]@{ Name="B460"; IsPrimary=$false; Tag="10th Gen Mainstream" },
            [PSCustomObject]@{ Name="H410"; IsPrimary=$false; Tag="10th Gen Budget" }
        )
        Notes       = @(
            "- Socket LGA 1200, sử dụng RAM DDR4.",
            "- Gen 11 trên main B560/Z590 hỗ trợ chuẩn PCIe 4.0 cho VGA và khe M.2 đầu tiên.",
            "- B560 lần đầu tiên cho phép mở khóa ép xung RAM trên dòng B của Intel.",
            "- H510/H410 phù hợp nhất với i3-10100/10105 hoặc i5-10400F cho cấu hình văn phòng, đồ họa 2D."
        )
    },

    # --- INTEL CORE GEN 8 & 9 (COFFEE LAKE - LGA 1151v2) ---
    [PSCustomObject]@{
        Keywords    = @("9900K", "9700K", "9400", "9400F", "9100", "9100F", "8700K", "8400", "8100", "LGA 1151V2", "Z390", "B365", "B360", "H310", "Z370")
        DisplayName = "Intel Core i5-9400F / i7-8700 / i9-9900K"
        Socket      = "LGA 1151-v2"
        Arch        = "Coffee Lake & Coffee Lake Refresh (8th & 9th Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B365"; IsPrimary=$true; Tag="Best Compatibility (Win 7 & Win 10)" },
            [PSCustomObject]@{ Name="B360"; IsPrimary=$true; Tag="Standard Mainstream" },
            [PSCustomObject]@{ Name="Z390"; IsPrimary=$false; Tag="Flagship OC" },
            [PSCustomObject]@{ Name="H310"; IsPrimary=$false; Tag="Entry-level Budget" }
        )
        Notes       = @(
            "- Socket LGA 1151-v2, chỉ tương thích với mainboard Series 300 (Z390, B365, B360, H310, Z370).",
            "- Không lắp được trên mainboard Series 100/200 (H110, B250...) nếu không mod BIOS.",
            "- B365 hỗ trợ cài đặt Windows 7 dễ dàng do sử dụng node điều khiển 22nm có sẵn driver USB."
        )
    },

    # --- INTEL CORE GEN 6 & 7 (SKYLAKE / KABY LAKE - LGA 1151) ---
    [PSCustomObject]@{
        Keywords    = @("7700K", "7700", "7500", "7400", "7100", "6700K", "6700", "6500", "6400", "6100", "G4560", "G4400", "LGA 1151", "B250", "H110", "Z270", "B150", "Z170")
        DisplayName = "Intel Core i5-6500 / i7-7700 / G4560"
        Socket      = "LGA 1151"
        Arch        = "Skylake & Kaby Lake (6th & 7th Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B250"; IsPrimary=$true; Tag="Mainstream 7th Gen" },
            [PSCustomObject]@{ Name="H110"; IsPrimary=$true; Tag="Budget King 6th/7th Gen" },
            [PSCustomObject]@{ Name="Z270"; IsPrimary=$false; Tag="High-end OC" },
            [PSCustomObject]@{ Name="B150"; IsPrimary=$false; Tag="Mainstream 6th Gen" }
        )
        Notes       = @(
            "- Socket LGA 1151 (Series 100 và 200), hỗ trợ cả RAM DDR4 và DDR3L (tùy main).",
            "- H110 + Pentium G4560 hoặc i5-6500 là huyền thoại cấu hình net và văn phòng một thời.",
            "- Hỗ trợ chính thức Windows 7, Windows 10."
        )
    }
)

function Get-CpuMainList {
    return $script:CPU_MAIN_DATA
}

function Find-CpuOrChipset {
    param([string]$Query)
    if ([string]::IsNullOrWhiteSpace($Query)) {
        return $script:CPU_MAIN_DATA[0]
    }

    $q = $Query.Trim().ToUpper()
    foreach ($item in $script:CPU_MAIN_DATA) {
        foreach ($kw in $item.Keywords) {
            if ($kw.ToUpper() -eq $q -or $kw.ToUpper() -like "*$q*" -or $q -like "*$kw.ToUpper()*") {
                return $item
            }
        }
        if ($item.DisplayName.ToUpper() -like "*$q*" -or $item.Socket.ToUpper() -like "*$q*" -or $item.Arch.ToUpper() -like "*$q*") {
            return $item
        }
    }

    # Fallback to first item
    return $script:CPU_MAIN_DATA[0]
}

# =========================================================================
# GỢI Ý TÌM KIẾM CPU THÔNG MINH (AUTO-SUGGEST LIST)
# =========================================================================
function Get-VUONGTTCpuSuggestions {
    param([string]$Query)
    $suggestions = @()
    $q = if ($Query) { $Query.Trim().ToUpper() } else { "" }

    $allNames = @(
        "Intel Core Ultra 9 285K", "Intel Core Ultra 7 265K", "Intel Core Ultra 5 245K",
        "AMD Ryzen 7 9800X3D", "AMD Ryzen 9 9950X", "AMD Ryzen 9 9900X", "AMD Ryzen 7 9700X", "AMD Ryzen 5 9600X",
        "AMD Ryzen 7 7800X3D", "AMD Ryzen 9 7950X", "AMD Ryzen 9 7900X", "AMD Ryzen 7 7700X", "AMD Ryzen 5 7600X", "AMD Ryzen 5 7500F",
        "Intel Core i9-14900K", "Intel Core i7-14700K", "Intel Core i5-14600K", "Intel Core i5-14400F", "Intel Core i5-14400",
        "Intel Core i9-13900K", "Intel Core i7-13700K", "Intel Core i5-13600K", "Intel Core i5-13400F",
        "Intel Core i9-12900K", "Intel Core i7-12700K", "Intel Core i5-12600K", "Intel Core i5-12400F", "Intel Core i3-12100F",
        "AMD Ryzen 7 5700X3D", "AMD Ryzen 7 5800X3D", "AMD Ryzen 9 5950X", "AMD Ryzen 7 5700X", "AMD Ryzen 5 5600X", "AMD Ryzen 5 5600", "AMD Ryzen 5 3600",
        "Intel Core i5-10400F", "Intel Core i5-11400F", "Intel Core i7-10700K", "Intel Core i5-9400F", "Intel Core i5-8400", "Intel Core i5-6500"
    )

    if ([string]::IsNullOrWhiteSpace($q)) {
        return @("Intel Core Ultra 9 285K", "AMD Ryzen 7 9800X3D", "Intel Core i5-14400F", "AMD Ryzen 5 7600X", "Intel Core i5-12400F", "AMD Ryzen 5 5600X")
    }

    foreach ($name in $allNames) {
        if ($name.ToUpper().Contains($q) -or $q.Contains($name.ToUpper())) {
            $suggestions += $name
        }
    }

    # If few matches, scan database keywords
    if ($suggestions.Count -lt 3) {
        foreach ($item in $script:CPU_MAIN_DATA) {
            foreach ($kw in $item.Keywords) {
                if ($kw.ToUpper().Contains($q) -and ($suggestions -notcontains $item.DisplayName)) {
                    $suggestions += $item.DisplayName
                    break
                }
            }
        }
    }

    if ($suggestions.Count -eq 0) {
        $suggestions = @("Intel Core Ultra 9 285K", "AMD Ryzen 7 9800X3D", "Intel Core i5-14400F")
    }

    return ($suggestions | Select-Object -Unique -First 8)
}

# =========================================================================
# THÔNG SỐ ĐỐI ĐẦU & SO SÁNH 2 CPU (SIDE-BY-SIDE CPU COMPARISON)
# =========================================================================
$script:CPU_SPEC_DB = @{
    "285K" = @{ Name="Intel Core Ultra 9 285K"; Socket="LGA 1851"; Node="TSMC N3B (3nm)"; Cores="24 (8P + 16E)"; Threads="24"; BaseClock="3.7 GHz"; BoostClock="5.7 GHz"; L3Cache="36 MB"; TDP="125W (Max 250W)"; RAM="DDR5-6400"; iGPU="Intel Graphics Xe (4 Xe-cores)"; R23Single=2350; R23Multi=43000; Main="Z890, B860, H810" };
    "9800X3D" = @{ Name="AMD Ryzen 7 9800X3D"; Socket="Socket AM5"; Node="TSMC 4nm (Zen 5)"; Cores="8 (8P)"; Threads="16"; BaseClock="4.7 GHz"; BoostClock="5.2 GHz"; L3Cache="96 MB (3D V-Cache)"; TDP="120W"; RAM="DDR5-6000 EXPO"; iGPU="Radeon Graphics (2 CUs)"; R23Single=2150; R23Multi=24000; Main="X870E, X870, B650E, B650" };
    "9950X" = @{ Name="AMD Ryzen 9 9950X"; Socket="Socket AM5"; Node="TSMC 4nm (Zen 5)"; Cores="16 (16P)"; Threads="32"; BaseClock="4.3 GHz"; BoostClock="5.7 GHz"; L3Cache="64 MB"; TDP="170W (Max 230W)"; RAM="DDR5-6000"; iGPU="Radeon Graphics"; R23Single=2300; R23Multi=44500; Main="X870E, X870, B650" };
    "14900K" = @{ Name="Intel Core i9-14900K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="24 (8P + 16E)"; Threads="32"; BaseClock="3.2 GHz"; BoostClock="6.0 GHz"; L3Cache="36 MB"; TDP="125W (Max 253W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2300; R23Multi=40000; Main="Z790, B760" };
    "14700K" = @{ Name="Intel Core i7-14700K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="20 (8P + 12E)"; Threads="28"; BaseClock="3.4 GHz"; BoostClock="5.6 GHz"; L3Cache="33 MB"; TDP="125W (Max 253W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2180; R23Multi=35000; Main="Z790, B760" };
    "14400" = @{ Name="Intel Core i5-14400 / 14400F"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="10 (6P + 4E)"; Threads="16"; BaseClock="2.5 GHz"; BoostClock="4.7 GHz"; L3Cache="20 MB"; TDP="65W (Max 148W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 730 (hoặc None với bản F)"; R23Single=1780; R23Multi=16200; Main="B760, H610, B660" };
    "7800X3D" = @{ Name="AMD Ryzen 7 7800X3D"; Socket="Socket AM5"; Node="TSMC 5nm (Zen 4)"; Cores="8 (8P)"; Threads="16"; BaseClock="4.2 GHz"; BoostClock="5.0 GHz"; L3Cache="96 MB (3D V-Cache)"; TDP="120W"; RAM="DDR5-6000 EXPO"; iGPU="Radeon Graphics"; R23Single=1820; R23Multi=18500; Main="B650, X670, A620" };
    "7600X" = @{ Name="AMD Ryzen 5 7600X / 7600"; Socket="Socket AM5"; Node="TSMC 5nm (Zen 4)"; Cores="6 (6P)"; Threads="12"; BaseClock="4.7 GHz"; BoostClock="5.3 GHz"; L3Cache="32 MB"; TDP="105W (hoặc 65W)"; RAM="DDR5-6000"; iGPU="Radeon Graphics"; R23Single=1980; R23Multi=15200; Main="B650, A620" };
    "13600K" = @{ Name="Intel Core i5-13600K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="14 (6P + 8E)"; Threads="20"; BaseClock="3.5 GHz"; BoostClock="5.1 GHz"; L3Cache="24 MB"; TDP="125W (Max 181W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2000; R23Multi=24000; Main="Z790, B760, B660" };
    "12400F" = @{ Name="Intel Core i5-12400F"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="6 (6P)"; Threads="12"; BaseClock="2.5 GHz"; BoostClock="4.4 GHz"; L3Cache="18 MB"; TDP="65W (Max 117W)"; RAM="DDR4 / DDR5"; iGPU="Không có (Cần card rời)"; R23Single=1690; R23Multi=12400; Main="B760, H610, B660" };
    "5600X" = @{ Name="AMD Ryzen 5 5600X / 5600"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.7 GHz"; BoostClock="4.6 GHz"; L3Cache="32 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Không có (Cần card rời)"; R23Single=1550; R23Multi=11600; Main="B550, B450, A520" };
    "5700X3D" = @{ Name="AMD Ryzen 7 5700X3D"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="8 (8P)"; Threads="16"; BaseClock="3.0 GHz"; BoostClock="4.1 GHz"; L3Cache="96 MB (3D V-Cache)"; TDP="105W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1380; R23Multi=13800; Main="B550, B450" };
    "10400" = @{ Name="Intel Core i5-10400 / 10400F"; Socket="LGA 1200"; Node="14nm+++"; Cores="6 (6P)"; Threads="12"; BaseClock="2.9 GHz"; BoostClock="4.3 GHz"; L3Cache="12 MB"; TDP="65W"; RAM="DDR4-2666"; iGPU="Intel UHD 630"; R23Single=1120; R23Multi=8200; Main="B560, H510, B460, H410" };
    "9400F" = @{ Name="Intel Core i5-9400F"; Socket="LGA 1151v2"; Node="14nm++"; Cores="6 (6P)"; Threads="6"; BaseClock="2.9 GHz"; BoostClock="4.1 GHz"; L3Cache="9 MB"; TDP="65W"; RAM="DDR4-2666"; iGPU="Không có"; R23Single=980; R23Multi=5600; Main="B365, B360, H310" };
    "6500" = @{ Name="Intel Core i5-6500"; Socket="LGA 1151"; Node="14nm"; Cores="4 (4P)"; Threads="4"; BaseClock="3.2 GHz"; BoostClock="3.6 GHz"; L3Cache="6 MB"; TDP="65W"; RAM="DDR4-2133 / DDR3L"; iGPU="Intel HD 530"; R23Single=850; R23Multi=3400; Main="B250, H110, B150" }
}

function Find-CpuSpecByQuery {
    param([string]$Query)
    if ([string]::IsNullOrWhiteSpace($Query)) { return $script:CPU_SPEC_DB["14400"] }
    $q = $Query.Trim().ToUpper()

    foreach ($k in $script:CPU_SPEC_DB.Keys) {
        $spec = $script:CPU_SPEC_DB[$k]
        if ($k.ToUpper() -eq $q -or $spec.Name.ToUpper().Contains($q) -or $q.Contains($k.ToUpper())) {
            return $spec
        }
    }

    # Partial keyword match
    if ($q -like "*285*" -or $q -like "*ARROW*") { return $script:CPU_SPEC_DB["285K"] }
    if ($q -like "*9800*" -or $q -like "*9800X3D*") { return $script:CPU_SPEC_DB["9800X3D"] }
    if ($q -like "*9950*") { return $script:CPU_SPEC_DB["9950X"] }
    if ($q -like "*14900*") { return $script:CPU_SPEC_DB["14900K"] }
    if ($q -like "*14700*") { return $script:CPU_SPEC_DB["14700K"] }
    if ($q -like "*14400*") { return $script:CPU_SPEC_DB["14400"] }
    if ($q -like "*7800*" -or $q -like "*7800X3D*") { return $script:CPU_SPEC_DB["7800X3D"] }
    if ($q -like "*7600*") { return $script:CPU_SPEC_DB["7600X"] }
    if ($q -like "*13600*") { return $script:CPU_SPEC_DB["13600K"] }
    if ($q -like "*12400*") { return $script:CPU_SPEC_DB["12400F"] }
    if ($q -like "*5600*") { return $script:CPU_SPEC_DB["5600X"] }
    if ($q -like "*5700X3D*") { return $script:CPU_SPEC_DB["5700X3D"] }
    if ($q -like "*10400*") { return $script:CPU_SPEC_DB["10400"] }

    return $script:CPU_SPEC_DB["14400"]
}

function Compare-VUONGTTCpu {
    param(
        [string]$Cpu1Query = "14400",
        [string]$Cpu2Query = "9800X3D"
    )

    $cpu1 = Find-CpuSpecByQuery -Query $Cpu1Query
    $cpu2 = Find-CpuSpecByQuery -Query $Cpu2Query

    $winnerMulti = if ($cpu1.R23Multi -gt $cpu2.R23Multi) { "$($cpu1.Name) (+$( [math]::Round((($cpu1.R23Multi - $cpu2.R23Multi)/$cpu2.R23Multi)*100, 1) )%)" } else { "$($cpu2.Name) (+$( [math]::Round((($cpu2.R23Multi - $cpu1.R23Multi)/$cpu1.R23Multi)*100, 1) )%)" }
    $winnerSingle = if ($cpu1.R23Single -gt $cpu2.R23Single) { "$($cpu1.Name) (+$( [math]::Round((($cpu1.R23Single - $cpu2.R23Single)/$cpu2.R23Single)*100, 1) )%)" } else { "$($cpu2.Name) (+$( [math]::Round((($cpu2.R23Single - $cpu1.R23Single)/$cpu1.R23Single)*100, 1) )%)" }

    $lines = @()
    $lines += "================================================================================"
    $lines += "        BẢNG SO SÁNH HIỆU NĂNG & THÔNG SỐ ĐỐI ĐẦU: $($cpu1.Name) VS $($cpu2.Name)"
    $lines += "================================================================================"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "TIÊU CHÍ SO SÁNH", $cpu1.Name, $cpu2.Name
    $lines += "--------------------------------------------------------------------------------"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Socket cắm", $cpu1.Socket, $cpu2.Socket
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Tiến trình công nghệ", $cpu1.Node, $cpu2.Node
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Số Nhân / Luồng", "$($cpu1.Cores) / $($cpu1.Threads)", "$($cpu2.Cores) / $($cpu2.Threads)"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Xung Cơ bản / Turbo", "$($cpu1.BaseClock) / $($cpu1.BoostClock)", "$($cpu2.BaseClock) / $($cpu2.BoostClock)"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Bộ nhớ đệm L3 Cache", $cpu1.L3Cache, $cpu2.L3Cache
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Mức ăn điện TDP", $cpu1.TDP, $cpu2.TDP
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Chuẩn RAM hỗ trợ", $cpu1.RAM, $cpu2.RAM
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Mainboard tương thích", $cpu1.Main, $cpu2.Main
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Cinebench R23 Đơn nhân", "$($cpu1.R23Single) pts", "$($cpu2.R23Single) pts"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Cinebench R23 Đa nhân", "$($cpu1.R23Multi) pts", "$($cpu2.R23Multi) pts"
    $lines += "--------------------------------------------------------------------------------"
    $lines += "🏆 ĐÁNH GIÁ TỔNG QUAN:"
    $lines += "• Thắng về Đa Nhiệm / Đa Nhân: $winnerMulti"
    $lines += "• Thắng về Đơn Nhân / Ứng Dụng Nhanh: $winnerSingle"
    if ($cpu1.L3Cache -like "*3D V-Cache*" -or $cpu2.L3Cache -like "*3D V-Cache*") {
        $lines += "• Nhận xét Gaming: Dòng trang bị 3D V-Cache có FPS trung bình và 1% Low FPS trong Game vượt trội hoàn toàn nhờ dung lượng cache khủng."
    }
    $lines += "================================================================================"

    return [PSCustomObject]@{
        Cpu1        = $cpu1
        Cpu2        = $cpu2
        ReportText  = ($lines -join "`n")
    }
}
