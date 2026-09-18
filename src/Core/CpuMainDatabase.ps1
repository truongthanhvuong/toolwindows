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
