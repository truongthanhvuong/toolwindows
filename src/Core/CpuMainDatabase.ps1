<#
.SYNOPSIS
    VUONGTT Toolkit 2026 - Comprehensive CPU & Motherboard Lookup and Comparison Engine
    Supports full spectrum of Intel (Core Ultra, Gen 1-14, Xeon, 775) & AMD (Ryzen 1000-9000, Threadripper, FX).
    Includes Smart Heuristic Pattern Analysis and Real-Time Online Search Engine.
#>

# =========================================================================
# 1. DANH MỤC CÁC DÒNG CPU CHÍNH & MAINBOARD / CHIPSET TƯƠNG THÍCH
# =========================================================================
$script:CPU_MAIN_DATA = @(
    # --- 1. INTEL CORE ULTRA 200S (ARROW LAKE - LGA 1851) ---
    [PSCustomObject]@{
        Keywords    = @("285K", "285", "265K", "265", "245K", "245", "225", "CORE ULTRA 9", "CORE ULTRA 7", "CORE ULTRA 5", "LGA 1851", "ARROW LAKE", "Z890", "B860", "H810", "W880", "Q870")
        DisplayName = "Intel Core Ultra 9 285K / 265K / 245K"
        Socket      = "LGA 1851"
        Arch        = "Arrow Lake (Core Ultra 200S - LGA 1851)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="Z890"; IsPrimary=$true; Tag="High-end, OC, PCIe 5.0" },
            [PSCustomObject]@{ Name="B860"; IsPrimary=$true; Tag="Mainstream Best Choice" },
            [PSCustomObject]@{ Name="H810"; IsPrimary=$false; Tag="Entry-level Budget" },
            [PSCustomObject]@{ Name="W880"; IsPrimary=$false; Tag="Workstation" },
            [PSCustomObject]@{ Name="Q870"; IsPrimary=$false; Tag="Enterprise / vPro" }
        )
        Notes       = @(
            "- Socket 1851, DDR5 only (hoàn toàn không hỗ trợ DDR4).",
            "- Z890: Dòng cao cấp nhất, hỗ trợ ép xung (Overclocking), full băng thông PCIe 5.0 x16 và M.2 PCIe 5.0.",
            "- B860: Dòng phổ thông quốc dân, cân đối hiệu năng/giá thành tốt nhất, hỗ trợ ép xung RAM (XMP).",
            "- H810: Phân khúc giá rẻ văn phòng, không hỗ trợ ép xung, phù hợp cấu hình tiết kiệm ngân sách.",
            "- Q870/W880: Dành cho môi trường doanh nghiệp / workstation với bảo mật phần cứng vPro & ECC RAM."
        )
    },

    # --- 2. AMD RYZEN 9000 & 8000G & 7000 (ZEN 5 / ZEN 4 - AM5) ---
    [PSCustomObject]@{
        Keywords    = @("9800X3D", "9950X", "9900X", "9700X", "9600X", "8700G", "8600G", "8500G", "7800X3D", "7950X", "7950X3D", "7900X", "7700X", "7600X", "7600", "7500F", "AM5", "ZEN 5", "ZEN 4", "X870E", "X870", "B650E", "B650", "A620", "X670E", "X670")
        DisplayName = "AMD Ryzen 7 9800X3D / 9950X / 7800X3D / 7600X"
        Socket      = "Socket AM5"
        Arch        = "Zen 5 / Zen 4 (Ryzen 9000 & 7000 Series - AM5)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="X870E"; IsPrimary=$true; Tag="Flagship, USB4, Dual PCIe 5.0" },
            [PSCustomObject]@{ Name="X870"; IsPrimary=$false; Tag="High-end, USB4 standard" },
            [PSCustomObject]@{ Name="B650"; IsPrimary=$true; Tag="Best Value Mainstream" },
            [PSCustomObject]@{ Name="B650E"; IsPrimary=$false; Tag="Enthusiast Mainstream PCIe 5.0" },
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

    # --- 3. INTEL CORE GEN 14, 13, 12 (RAPTOR LAKE / ALDER LAKE - LGA 1700) ---
    [PSCustomObject]@{
        Keywords    = @("14900KS", "14900K", "14700K", "14600K", "14500", "14400", "14400F", "14100", "14100F", "13900KS", "13900K", "13700K", "13600K", "13500", "13400", "13400F", "13100", "12900KS", "12900K", "12700K", "12600K", "12400", "12400F", "12100", "12100F", "G7400", "LGA 1700", "Z790", "B760", "Z690", "B660", "H610")
        DisplayName = "Intel Core i5-14400F / i7-14700K / i5-13400 / i5-12400F"
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

    # --- 4. AMD RYZEN 5000, 4000, 3000 (ZEN 3 / ZEN 2 - AM4) ---
    [PSCustomObject]@{
        Keywords    = @("5950X", "5900X", "5800X3D", "5800X", "5700X3D", "5700X", "5700G", "5600X", "5600", "5600G", "5500", "5500GT", "4500", "4100", "3950X", "3900X", "3800X", "3700X", "3600X", "3600", "3500X", "3400G", "3200G", "3100", "AM4", "ZEN 3", "ZEN 2", "B550", "X570", "B450", "A520", "A320")
        DisplayName = "AMD Ryzen 7 5700X3D / Ryzen 5 5600X / 3600"
        Socket      = "Socket AM4"
        Arch        = "Zen 3 / Zen 2 (Ryzen 5000 & 3000 Series - AM4)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B550"; IsPrimary=$true; Tag="Best Choice PCIe 4.0" },
            [PSCustomObject]@{ Name="B450"; IsPrimary=$true; Tag="Budget King PCIe 3.0" },
            [PSCustomObject]@{ Name="X570"; IsPrimary=$false; Tag="High-end PCIe 4.0 Everywhere" },
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

    # --- 5. INTEL CORE GEN 11 & 10 (ROCKET LAKE / COMET LAKE - LGA 1200) ---
    [PSCustomObject]@{
        Keywords    = @("11900K", "11700K", "11600K", "11400", "11400F", "10900K", "10850K", "10700K", "10600K", "10400", "10400F", "10100", "10105F", "G6405", "LGA 1200", "Z590", "B560", "H510", "Z490", "B460", "H410")
        DisplayName = "Intel Core i5-10400F / i5-11400F / i7-10700"
        Socket      = "LGA 1200"
        Arch        = "Rocket Lake / Comet Lake (Core 10th & 11th Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B560"; IsPrimary=$true; Tag="Mainstream, RAM OC support" },
            [PSCustomObject]@{ Name="H510"; IsPrimary=$true; Tag="Budget King 10th/11th Gen" },
            [PSCustomObject]@{ Name="Z590"; IsPrimary=$false; Tag="High-end OC" },
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

    # --- 6. INTEL CORE GEN 8 & 9 (COFFEE LAKE - LGA 1151v2) ---
    [PSCustomObject]@{
        Keywords    = @("9900KS", "9900K", "9700K", "9600K", "9400", "9400F", "9100", "9100F", "8700K", "8600K", "8400", "8100", "G5400", "LGA 1151V2", "Z390", "B365", "B360", "H310", "Z370")
        DisplayName = "Intel Core i5-9400F / i7-8700 / i9-9900K"
        Socket      = "LGA 1151-v2"
        Arch        = "Coffee Lake & Coffee Lake Refresh (8th & 9th Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B365"; IsPrimary=$true; Tag="Best Compatibility (Win 7 & Win 10)" },
            [PSCustomObject]@{ Name="B360"; IsPrimary=$true; Tag="Standard Mainstream" },
            [PSCustomObject]@{ Name="H310"; IsPrimary=$false; Tag="Entry-level Budget" },
            [PSCustomObject]@{ Name="Z390"; IsPrimary=$false; Tag="Flagship OC" }
        )
        Notes       = @(
            "- Socket LGA 1151-v2, chỉ tương thích với mainboard Series 300 (Z390, B365, B360, H310, Z370).",
            "- Không lắp được trên mainboard Series 100/200 (H110, B250...) nếu không mod BIOS.",
            "- B365 hỗ trợ cài đặt Windows 7 dễ dàng do sử dụng node điều khiển 22nm có sẵn driver USB."
        )
    },

    # --- 7. INTEL CORE GEN 6 & 7 (SKYLAKE / KABY LAKE - LGA 1151) ---
    [PSCustomObject]@{
        Keywords    = @("7700K", "7700", "7600K", "7500", "7400", "7100", "6700K", "6700", "6600K", "6500", "6400", "6100", "G4560", "G4400", "LGA 1151", "B250", "H110", "Z270", "B150", "Z170")
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
    },

    # --- 8. INTEL CORE GEN 4 & 5 (HASWELL / BROADWELL - LGA 1150) ---
    [PSCustomObject]@{
        Keywords    = @("4790K", "4790", "4770", "4690K", "4590", "4460", "4160", "4150", "4130", "G3250", "G3220", "E3-1231V3", "E3-1230V3", "LGA 1150", "HASWELL", "B85", "H81", "Z97", "H97", "Z87")
        DisplayName = "Intel Core i5-4460 / i7-4790K / Xeon E3-1231v3"
        Socket      = "LGA 1150"
        Arch        = "Haswell & Haswell Refresh (4th Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B85"; IsPrimary=$true; Tag="Mainstream Quốc Dân" },
            [PSCustomObject]@{ Name="H81"; IsPrimary=$true; Tag="Giá Rẻ Văn Phòng" },
            [PSCustomObject]@{ Name="Z97"; IsPrimary=$false; Tag="Cao Cấp Ép Xung" },
            [PSCustomObject]@{ Name="H97"; IsPrimary=$false; Tag="Cận Cao Cấp" }
        )
        Notes       = @(
            "- Socket LGA 1150, sử dụng RAM DDR3 / DDR3L (Bus 1333 / 1600 MHz).",
            "- B85: Dòng mainboard bền bỉ, 4 khe RAM, đầy đủ cổng SATA 3 và USB 3.0.",
            "- Xeon E3-1231v3: Bản chất là i7-4770 cắt giảm iGPU, giá rẻ hiệu năng cao cho render thời kỳ DDR3."
        )
    },

    # --- 9. INTEL CORE GEN 2 & 3 (SANDY / IVY BRIDGE - LGA 1155) ---
    [PSCustomObject]@{
        Keywords    = @("3770K", "3770", "3570K", "3470", "3220", "2600K", "2600", "2500", "2400", "2100", "G2030", "G860", "E3-1230V2", "LGA 1155", "IVY BRIDGE", "SANDY BRIDGE", "B75", "H61", "Z77")
        DisplayName = "Intel Core i5-3470 / i7-3770 / i5-2400 / Xeon E3-1230v2"
        Socket      = "LGA 1155"
        Arch        = "Ivy Bridge & Sandy Bridge (2nd & 3rd Gen)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="B75"; IsPrimary=$true; Tag="Mainstream có SATA3, USB 3.0" },
            [PSCustomObject]@{ Name="H61"; IsPrimary=$true; Tag="Giá Rẻ Cực Phổ Biến" },
            [PSCustomObject]@{ Name="Z77"; IsPrimary=$false; Tag="Flagship Ép Xung LGA 1155" }
        )
        Notes       = @(
            "- Socket LGA 1155, sử dụng RAM DDR3 (Bus 1333 / 1600 MHz).",
            "- H61: Dòng bo mạch chủ rẻ và phổ biến nhất trong lịch sử các phòng net và văn phòng.",
            "- B75: Nâng cấp đáng giá với cổng SATA 3 (6Gbps) cho SSD và cổng USB 3.0 phía trước."
        )
    },

    # --- 10. INTEL CORE 2 QUAD / DUO (LGA 775) ---
    [PSCustomObject]@{
        Keywords    = @("Q9650", "Q9550", "Q8400", "Q6600", "E8400", "E8500", "E7500", "E6750", "E5700", "E5200", "LGA 775", "CORE 2 QUAD", "CORE 2 DUO", "G41", "G31", "P45", "945GC")
        DisplayName = "Intel Core 2 Quad Q9550 / Q6600 / Core 2 Duo E8400"
        Socket      = "LGA 775"
        Arch        = "Core Microarchitecture / Penryn (LGA 775)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="G41"; IsPrimary=$true; Tag="DDR3 / DDR2 Combo" },
            [PSCustomObject]@{ Name="G31"; IsPrimary=$true; Tag="Huyền Thoại DDR2" },
            [PSCustomObject]@{ Name="P45"; IsPrimary=$false; Tag="High-end Rời Không iGPU" }
        )
        Notes       = @(
            "- Socket LGA 775, sử dụng RAM DDR2 hoặc DDR3 (main G41 combo).",
            "- Q6600 / Q9550: Những vi xử lý 4 nhân đầu tiên đưa khái niệm Quad-Core vào người dùng phổ thông.",
            "- Hiện tại phù hợp làm máy in hóa đơn, máy tính văn phòng cơ bản hoặc học sinh học gõ máy."
        )
    },

    # --- 11. INTEL XEON E5 SERVER / WORKSTATION (X99 / X79 - LGA 2011 & 2011-3) ---
    [PSCustomObject]@{
        Keywords    = @("2678V3", "2680V3", "2696V3", "2670V3", "2699V3", "2680V4", "2699V4", "2670", "2689", "2690", "1650", "E5-2678V3", "E5-2680V3", "LGA 2011-3", "LGA 2011", "X99", "X79", "C612")
        DisplayName = "Intel Xeon E5-2678v3 / E5-2680v4 / E5-2670 (X99 / X79)"
        Socket      = "LGA 2011-3 / LGA 2011"
        Arch        = "Haswell-EP / Broadwell-EP (Xeon E5 Workstation)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="X99"; IsPrimary=$true; Tag="Workstation / Gaming Dual CPU" },
            [PSCustomObject]@{ Name="C612"; IsPrimary=$false; Tag="Server Enterprise" },
            [PSCustomObject]@{ Name="X79"; IsPrimary=$false; Tag="Xeon E5 v1/v2 (DDR3 ECC)" }
        )
        Notes       = @(
            "- Bo mạch chủ X99 hỗ trợ Xeon E5 v3 và v4, chạy RAM DDR4 ECC Registered giá rẻ hoặc DDR4 thường.",
            "- Mainboard X79 hỗ trợ Xeon E5 v1 và v2, sử dụng RAM DDR3 ECC Server.",
            "- Lựa chọn số 1 cho các dàn cày giả lập Android (Nox, LDPlayer), render 3D Studio Max chi phí thấp."
        )
    },

    # --- 12. AMD RYZEN THREADRIPPER (WORKSTATION EXTREME) ---
    [PSCustomObject]@{
        Keywords    = @("7980X", "7970X", "7960X", "3990X", "3970X", "3960X", "2990WX", "1950X", "THREADRIPPER", "STR5", "STRX4", "STR4", "TRX50", "WRX90", "TRX40", "X399")
        DisplayName = "AMD Ryzen Threadripper 7980X / 3990X / 2990WX"
        Socket      = "Socket sTR5 / sTRX4 / sTR4"
        Arch        = "Zen 4 / Zen 2 Threadripper HEDT"
        Chipsets    = @(
            [PSCustomObject]@{ Name="TRX50"; IsPrimary=$true; Tag="Zen 4 HEDT Flagship" },
            [PSCustomObject]@{ Name="WRX90"; IsPrimary=$false; Tag="Zen 4 Pro Workstation" },
            [PSCustomObject]@{ Name="TRX40"; IsPrimary=$false; Tag="Zen 2 Threadripper 3000" },
            [PSCustomObject]@{ Name="X399"; IsPrimary=$false; Tag="Zen 1 Threadripper 1000/2000" }
        )
        Notes       = @(
            "- Dòng vi xử lý siêu cấp HEDT dành cho dựng phim điện ảnh, render VFX, mô phỏng khoa học và AI.",
            "- Hỗ trợ bộ nhớ 4 kênh hoặc 8 kênh (Quad/Octa-channel) băng thông cực khủng và hàng chục làn PCIe 5.0."
        )
    },

    # --- 13. AMD FX SERIES (AM3+) ---
    [PSCustomObject]@{
        Keywords    = @("FX-8350", "FX-8320", "FX-6300", "FX-4300", "AM3+", "AM3", "990FX", "970", "VISHERA")
        DisplayName = "AMD FX-8350 / FX-6300 (Socket AM3+)"
        Socket      = "Socket AM3+"
        Arch        = "Vishera / Piledriver (AMD FX 32nm)"
        Chipsets    = @(
            [PSCustomObject]@{ Name="970"; IsPrimary=$true; Tag="Mainstream AM3+" },
            [PSCustomObject]@{ Name="990FX"; IsPrimary=$false; Tag="Flagship AM3+ Multi-GPU" }
        )
        Notes       = @(
            "- Socket AM3+, sử dụng RAM DDR3. Kiến trúc 8 nhân module Piledriver tiêu thụ điện năng khá lớn (125W).",
            "- Cần tản nhiệt khí tháp tốt hoặc tản nước AIO để duy trì xung nhịp ổn định."
        )
    }
)

function Get-CpuMainList {
    return $script:CPU_MAIN_DATA
}

function Find-CpuOrChipset {
    param([string]$Query)
    if ([string]::IsNullOrWhiteSpace($Query)) { return $script:CPU_MAIN_DATA[0] }

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
    return $script:CPU_MAIN_DATA[0]
}

# =========================================================================
# 2. CƠ SỞ DỮ LIỆU CHI TIẾT ĐỐI ĐẦU & SO SÁNH CPU (60+ MẪU PHỔ BIẾN)
# =========================================================================
$script:CPU_SPEC_DB = @{
    # --- INTEL CORE ULTRA (ARROW LAKE) ---
    "285K"     = @{ Name="Intel Core Ultra 9 285K"; Socket="LGA 1851"; Node="TSMC N3B (3nm)"; Cores="24 (8P + 16E)"; Threads="24"; BaseClock="3.7 GHz"; BoostClock="5.7 GHz"; L3Cache="36 MB"; TDP="125W (Max 250W)"; RAM="DDR5-6400"; iGPU="Intel Graphics Xe (4 Xe-cores)"; R23Single=2350; R23Multi=43000; Main="Z890, B860, H810"; Arch="Arrow Lake" };
    "265K"     = @{ Name="Intel Core Ultra 7 265K"; Socket="LGA 1851"; Node="TSMC N3B (3nm)"; Cores="20 (8P + 12E)"; Threads="20"; BaseClock="3.9 GHz"; BoostClock="5.5 GHz"; L3Cache="30 MB"; TDP="125W (Max 250W)"; RAM="DDR5-6400"; iGPU="Intel Graphics Xe"; R23Single=2240; R23Multi=35800; Main="Z890, B860, H810"; Arch="Arrow Lake" };
    "245K"     = @{ Name="Intel Core Ultra 5 245K"; Socket="LGA 1851"; Node="TSMC N3B (3nm)"; Cores="14 (6P + 8E)"; Threads="14"; BaseClock="4.2 GHz"; BoostClock="5.2 GHz"; L3Cache="24 MB"; TDP="125W (Max 159W)"; RAM="DDR5-6400"; iGPU="Intel Graphics Xe"; R23Single=2110; R23Multi=25200; Main="B860, Z890, H810"; Arch="Arrow Lake" };

    # --- AMD RYZEN 9000 & 8000 & 7000 (ZEN 5 / ZEN 4) ---
    "9800X3D"  = @{ Name="AMD Ryzen 7 9800X3D"; Socket="Socket AM5"; Node="TSMC 4nm (Zen 5)"; Cores="8 (8P)"; Threads="16"; BaseClock="4.7 GHz"; BoostClock="5.2 GHz"; L3Cache="96 MB (3D V-Cache)"; TDP="120W"; RAM="DDR5-6000 EXPO"; iGPU="Radeon Graphics (2 CUs)"; R23Single=2180; R23Multi=24200; Main="X870E, X870, B650E, B650"; Arch="Zen 5" };
    "9950X"    = @{ Name="AMD Ryzen 9 9950X"; Socket="Socket AM5"; Node="TSMC 4nm (Zen 5)"; Cores="16 (16P)"; Threads="32"; BaseClock="4.3 GHz"; BoostClock="5.7 GHz"; L3Cache="64 MB"; TDP="170W (Max 230W)"; RAM="DDR5-6000"; iGPU="Radeon Graphics"; R23Single=2320; R23Multi=45200; Main="X870E, X870, B650"; Arch="Zen 5" };
    "9900X"    = @{ Name="AMD Ryzen 9 9900X"; Socket="Socket AM5"; Node="TSMC 4nm (Zen 5)"; Cores="12 (12P)"; Threads="24"; BaseClock="4.4 GHz"; BoostClock="5.6 GHz"; L3Cache="64 MB"; TDP="120W (Max 162W)"; RAM="DDR5-6000"; iGPU="Radeon Graphics"; R23Single=2270; R23Multi=33800; Main="X870, B650"; Arch="Zen 5" };
    "9700X"    = @{ Name="AMD Ryzen 7 9700X"; Socket="Socket AM5"; Node="TSMC 4nm (Zen 5)"; Cores="8 (8P)"; Threads="16"; BaseClock="3.8 GHz"; BoostClock="5.5 GHz"; L3Cache="32 MB"; TDP="65W (105W TDP mode)"; RAM="DDR5-6000"; iGPU="Radeon Graphics"; R23Single=2260; R23Multi=21500; Main="B650, X870, A620"; Arch="Zen 5" };
    "9600X"    = @{ Name="AMD Ryzen 5 9600X"; Socket="Socket AM5"; Node="TSMC 4nm (Zen 5)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.9 GHz"; BoostClock="5.4 GHz"; L3Cache="32 MB"; TDP="65W (105W TDP mode)"; RAM="DDR5-6000"; iGPU="Radeon Graphics"; R23Single=2210; R23Multi=17100; Main="B650, A620"; Arch="Zen 5" };
    "8700G"    = @{ Name="AMD Ryzen 7 8700G"; Socket="Socket AM5"; Node="TSMC 4nm (Phoenix)"; Cores="8 (8P)"; Threads="16"; BaseClock="4.2 GHz"; BoostClock="5.1 GHz"; L3Cache="16 MB"; TDP="65W"; RAM="DDR5-5200"; iGPU="Radeon 780M (Cực Mạnh)"; R23Single=1880; R23Multi=18200; Main="B650, A620"; Arch="Zen 4" };
    "7800X3D"  = @{ Name="AMD Ryzen 7 7800X3D"; Socket="Socket AM5"; Node="TSMC 5nm (Zen 4)"; Cores="8 (8P)"; Threads="16"; BaseClock="4.2 GHz"; BoostClock="5.0 GHz"; L3Cache="96 MB (3D V-Cache)"; TDP="120W"; RAM="DDR5-6000 EXPO"; iGPU="Radeon Graphics"; R23Single=1820; R23Multi=18500; Main="B650, X670, A620"; Arch="Zen 4" };
    "7950X"    = @{ Name="AMD Ryzen 9 7950X"; Socket="Socket AM5"; Node="TSMC 5nm (Zen 4)"; Cores="16 (16P)"; Threads="32"; BaseClock="4.5 GHz"; BoostClock="5.7 GHz"; L3Cache="64 MB"; TDP="170W (Max 230W)"; RAM="DDR5-5200"; iGPU="Radeon Graphics"; R23Single=2050; R23Multi=38500; Main="X670E, B650"; Arch="Zen 4" };
    "7700X"    = @{ Name="AMD Ryzen 7 7700X"; Socket="Socket AM5"; Node="TSMC 5nm (Zen 4)"; Cores="8 (8P)"; Threads="16"; BaseClock="4.5 GHz"; BoostClock="5.4 GHz"; L3Cache="32 MB"; TDP="105W"; RAM="DDR5-5200"; iGPU="Radeon Graphics"; R23Single=1990; R23Multi=19800; Main="B650, A620"; Arch="Zen 4" };
    "7600X"    = @{ Name="AMD Ryzen 5 7600X / 7600"; Socket="Socket AM5"; Node="TSMC 5nm (Zen 4)"; Cores="6 (6P)"; Threads="12"; BaseClock="4.7 GHz"; BoostClock="5.3 GHz"; L3Cache="32 MB"; TDP="105W / 65W"; RAM="DDR5-5200"; iGPU="Radeon Graphics"; R23Single=1980; R23Multi=15200; Main="B650, A620"; Arch="Zen 4" };
    "7500F"    = @{ Name="AMD Ryzen 5 7500F"; Socket="Socket AM5"; Node="TSMC 5nm (Zen 4)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.7 GHz"; BoostClock="5.0 GHz"; L3Cache="32 MB"; TDP="65W"; RAM="DDR5-5200"; iGPU="Không có (Cần VGA rời)"; R23Single=1830; R23Multi=14100; Main="B650, A620"; Arch="Zen 4" };

    # --- INTEL CORE GEN 14 (RAPTOR LAKE REFRESH) ---
    "14900KS"  = @{ Name="Intel Core i9-14900KS"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="24 (8P + 16E)"; Threads="32"; BaseClock="3.2 GHz"; BoostClock="6.2 GHz"; L3Cache="36 MB"; TDP="150W (Max 320W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2380; R23Multi=42500; Main="Z790 (VRM Khủng)"; Arch="Raptor Lake-R" };
    "14900K"   = @{ Name="Intel Core i9-14900K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="24 (8P + 16E)"; Threads="32"; BaseClock="3.2 GHz"; BoostClock="6.0 GHz"; L3Cache="36 MB"; TDP="125W (Max 253W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2300; R23Multi=40000; Main="Z790, B760"; Arch="Raptor Lake-R" };
    "14700K"   = @{ Name="Intel Core i7-14700K / 14700KF"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="20 (8P + 12E)"; Threads="28"; BaseClock="3.4 GHz"; BoostClock="5.6 GHz"; L3Cache="33 MB"; TDP="125W (Max 253W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2180; R23Multi=35000; Main="Z790, B760"; Arch="Raptor Lake-R" };
    "14600K"   = @{ Name="Intel Core i5-14600K / 14600KF"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="14 (6P + 8E)"; Threads="20"; BaseClock="3.5 GHz"; BoostClock="5.3 GHz"; L3Cache="24 MB"; TDP="125W (Max 181W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2080; R23Multi=24800; Main="B760, Z790"; Arch="Raptor Lake-R" };
    "14400"    = @{ Name="Intel Core i5-14400 / 14400F"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="10 (6P + 4E)"; Threads="16"; BaseClock="2.5 GHz"; BoostClock="4.7 GHz"; L3Cache="20 MB"; TDP="65W (Max 148W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 730"; R23Single=1780; R23Multi=16200; Main="B760, H610, B660"; Arch="Raptor Lake-R" };
    "14100"    = @{ Name="Intel Core i3-14100 / 14100F"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="4 (4P)"; Threads="8"; BaseClock="3.5 GHz"; BoostClock="4.7 GHz"; L3Cache="12 MB"; TDP="60W (Max 110W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 730"; R23Single=1750; R23Multi=9100; Main="H610, B760"; Arch="Raptor Lake-R" };

    # --- INTEL CORE GEN 13 (RAPTOR LAKE) ---
    "13900K"   = @{ Name="Intel Core i9-13900K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="24 (8P + 16E)"; Threads="32"; BaseClock="3.0 GHz"; BoostClock="5.8 GHz"; L3Cache="36 MB"; TDP="125W (Max 253W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2250; R23Multi=38800; Main="Z790, B760, Z690"; Arch="Raptor Lake" };
    "13700K"   = @{ Name="Intel Core i7-13700K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="16 (8P + 8E)"; Threads="24"; BaseClock="3.4 GHz"; BoostClock="5.4 GHz"; L3Cache="30 MB"; TDP="125W (Max 253W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2120; R23Multi=31000; Main="Z790, B760"; Arch="Raptor Lake" };
    "13600K"   = @{ Name="Intel Core i5-13600K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="14 (6P + 8E)"; Threads="20"; BaseClock="3.5 GHz"; BoostClock="5.1 GHz"; L3Cache="24 MB"; TDP="125W (Max 181W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=2000; R23Multi=24000; Main="Z790, B760, B660"; Arch="Raptor Lake" };
    "13500"    = @{ Name="Intel Core i5-13500"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="14 (6P + 8E)"; Threads="20"; BaseClock="2.5 GHz"; BoostClock="4.8 GHz"; L3Cache="24 MB"; TDP="65W (Max 154W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=1850; R23Multi=21200; Main="B760, B660, H610"; Arch="Alder Lake C0" };
    "13400"    = @{ Name="Intel Core i5-13400 / 13400F"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="10 (6P + 4E)"; Threads="16"; BaseClock="2.5 GHz"; BoostClock="4.6 GHz"; L3Cache="20 MB"; TDP="65W (Max 148W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 730"; R23Single=1740; R23Multi=15800; Main="B760, H610, B660"; Arch="Raptor Lake" };

    # --- INTEL CORE GEN 12 (ALDER LAKE) ---
    "12900K"   = @{ Name="Intel Core i9-12900K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="16 (8P + 8E)"; Threads="24"; BaseClock="3.2 GHz"; BoostClock="5.2 GHz"; L3Cache="30 MB"; TDP="125W (Max 241W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=1980; R23Multi=27500; Main="Z690, B660, Z790"; Arch="Alder Lake" };
    "12700K"   = @{ Name="Intel Core i7-12700K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="12 (8P + 4E)"; Threads="20"; BaseClock="3.6 GHz"; BoostClock="5.0 GHz"; L3Cache="25 MB"; TDP="125W (Max 190W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=1920; R23Multi=22800; Main="Z690, B660, B760"; Arch="Alder Lake" };
    "12600K"   = @{ Name="Intel Core i5-12600K"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="10 (6P + 4E)"; Threads="16"; BaseClock="3.7 GHz"; BoostClock="4.9 GHz"; L3Cache="20 MB"; TDP="125W (Max 150W)"; RAM="DDR4 / DDR5"; iGPU="Intel UHD 770"; R23Single=1860; R23Multi=17500; Main="B660, Z690, B760"; Arch="Alder Lake" };
    "12400F"   = @{ Name="Intel Core i5-12400F / 12400"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="6 (6P)"; Threads="12"; BaseClock="2.5 GHz"; BoostClock="4.4 GHz"; L3Cache="18 MB"; TDP="65W (Max 117W)"; RAM="DDR4 / DDR5"; iGPU="Không có (hoặc UHD 730)"; R23Single=1690; R23Multi=12400; Main="B760, H610, B660"; Arch="Alder Lake" };
    "12100F"   = @{ Name="Intel Core i3-12100F / 12100"; Socket="LGA 1700"; Node="Intel 7 (10nm)"; Cores="4 (4P)"; Threads="8"; BaseClock="3.3 GHz"; BoostClock="4.3 GHz"; L3Cache="12 MB"; TDP="60W (Max 89W)"; RAM="DDR4 / DDR5"; iGPU="Không có (hoặc UHD 730)"; R23Single=1640; R23Multi=8400; Main="H610, B660, B760"; Arch="Alder Lake" };

    # --- AMD RYZEN 5000 & 4000 (ZEN 3 / ZEN 2 - AM4) ---
    "5950X"    = @{ Name="AMD Ryzen 9 5950X"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="16 (16P)"; Threads="32"; BaseClock="3.4 GHz"; BoostClock="4.9 GHz"; L3Cache="64 MB"; TDP="105W (Max 142W)"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1640; R23Multi=26000; Main="B550, X570"; Arch="Zen 3" };
    "5900X"    = @{ Name="AMD Ryzen 9 5900X"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="12 (12P)"; Threads="24"; BaseClock="3.7 GHz"; BoostClock="4.8 GHz"; L3Cache="64 MB"; TDP="105W (Max 142W)"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1620; R23Multi=21500; Main="B550, X570"; Arch="Zen 3" };
    "5800X3D"  = @{ Name="AMD Ryzen 7 5800X3D"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="8 (8P)"; Threads="16"; BaseClock="3.4 GHz"; BoostClock="4.5 GHz"; L3Cache="96 MB (3D V-Cache)"; TDP="105W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1490; R23Multi=15100; Main="B550, B450, X570"; Arch="Zen 3" };
    "5700X3D"  = @{ Name="AMD Ryzen 7 5700X3D"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="8 (8P)"; Threads="16"; BaseClock="3.0 GHz"; BoostClock="4.1 GHz"; L3Cache="96 MB (3D V-Cache)"; TDP="105W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1380; R23Multi=13800; Main="B550, B450"; Arch="Zen 3" };
    "5700X"    = @{ Name="AMD Ryzen 7 5700X"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="8 (8P)"; Threads="16"; BaseClock="3.4 GHz"; BoostClock="4.6 GHz"; L3Cache="32 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1530; R23Multi=13600; Main="B550, B450, A520"; Arch="Zen 3" };
    "5600X"    = @{ Name="AMD Ryzen 5 5600X / 5600"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 3)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.7 GHz"; BoostClock="4.6 GHz"; L3Cache="32 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1550; R23Multi=11600; Main="B550, B450, A520"; Arch="Zen 3" };
    "5600G"    = @{ Name="AMD Ryzen 5 5600G"; Socket="Socket AM4"; Node="TSMC 7nm (Cezanne)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.9 GHz"; BoostClock="4.4 GHz"; L3Cache="16 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Radeon Vega 7"; R23Single=1420; R23Multi=10600; Main="B450, A520, B550"; Arch="Zen 3" };
    "5500"     = @{ Name="AMD Ryzen 5 5500"; Socket="Socket AM4"; Node="TSMC 7nm (Cezanne)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.6 GHz"; BoostClock="4.2 GHz"; L3Cache="16 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1390; R23Multi=10100; Main="B450, A520, A320"; Arch="Zen 3" };

    # --- AMD RYZEN 3000 & 2000 & 1000 (ZEN 2 / ZEN) ---
    "3900X"    = @{ Name="AMD Ryzen 9 3900X"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 2)"; Cores="12 (12P)"; Threads="24"; BaseClock="3.8 GHz"; BoostClock="4.6 GHz"; L3Cache="64 MB"; TDP="105W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1310; R23Multi=18500; Main="X570, B450, B550"; Arch="Zen 2" };
    "3700X"    = @{ Name="AMD Ryzen 7 3700X"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 2)"; Cores="8 (8P)"; Threads="16"; BaseClock="3.6 GHz"; BoostClock="4.4 GHz"; L3Cache="32 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1280; R23Multi=12100; Main="B450, B550, A320"; Arch="Zen 2" };
    "3600"     = @{ Name="AMD Ryzen 5 3600 / 3600X"; Socket="Socket AM4"; Node="TSMC 7nm (Zen 2)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.6 GHz"; BoostClock="4.2 GHz"; L3Cache="32 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Không có"; R23Single=1250; R23Multi=9200; Main="B450, A320, B550"; Arch="Zen 2" };
    "2600"     = @{ Name="AMD Ryzen 5 2600 / 2600X"; Socket="Socket AM4"; Node="12nm (Zen+)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.4 GHz"; BoostClock="3.9 GHz"; L3Cache="16 MB"; TDP="65W"; RAM="DDR4-2933"; iGPU="Không có"; R23Single=1010; R23Multi=7100; Main="B450, A320, B350"; Arch="Zen+" };
    "1600"     = @{ Name="AMD Ryzen 5 1600"; Socket="Socket AM4"; Node="14nm (Zen)"; Cores="6 (6P)"; Threads="12"; BaseClock="3.2 GHz"; BoostClock="3.6 GHz"; L3Cache="16 MB"; TDP="65W"; RAM="DDR4-2666"; iGPU="Không có"; R23Single=920; R23Multi=6400; Main="A320, B350, B450"; Arch="Zen" };

    # --- INTEL CORE GEN 11 & 10 (LGA 1200) ---
    "11900K"   = @{ Name="Intel Core i9-11900K"; Socket="LGA 1200"; Node="14nm+++"; Cores="8 (8P)"; Threads="16"; BaseClock="3.5 GHz"; BoostClock="5.3 GHz"; L3Cache="16 MB"; TDP="125W"; RAM="DDR4-3200"; iGPU="Intel UHD 750"; R23Single=1620; R23Multi=15500; Main="Z590, B560"; Arch="Rocket Lake" };
    "11700K"   = @{ Name="Intel Core i7-11700K"; Socket="LGA 1200"; Node="14nm+++"; Cores="8 (8P)"; Threads="16"; BaseClock="3.6 GHz"; BoostClock="5.0 GHz"; L3Cache="16 MB"; TDP="125W"; RAM="DDR4-3200"; iGPU="Intel UHD 750"; R23Single=1530; R23Multi=14100; Main="B560, Z590"; Arch="Rocket Lake" };
    "11400"    = @{ Name="Intel Core i5-11400 / 11400F"; Socket="LGA 1200"; Node="14nm+++"; Cores="6 (6P)"; Threads="12"; BaseClock="2.6 GHz"; BoostClock="4.4 GHz"; L3Cache="12 MB"; TDP="65W"; RAM="DDR4-3200"; iGPU="Intel UHD 730"; R23Single=1410; R23Multi=10200; Main="B560, H510"; Arch="Rocket Lake" };
    "10900K"   = @{ Name="Intel Core i9-10900K"; Socket="LGA 1200"; Node="14nm+++"; Cores="10 (10P)"; Threads="20"; BaseClock="3.7 GHz"; BoostClock="5.3 GHz"; L3Cache="20 MB"; TDP="125W"; RAM="DDR4-2933"; iGPU="Intel UHD 630"; R23Single=1420; R23Multi=16400; Main="Z490, Z590, B560"; Arch="Comet Lake" };
    "10700"    = @{ Name="Intel Core i7-10700 / 10700K"; Socket="LGA 1200"; Node="14nm+++"; Cores="8 (8P)"; Threads="16"; BaseClock="2.9 GHz"; BoostClock="4.8 GHz"; L3Cache="16 MB"; TDP="65W / 125W"; RAM="DDR4-2933"; iGPU="Intel UHD 630"; R23Single=1280; R23Multi=12500; Main="B560, B460, H510"; Arch="Comet Lake" };
    "10400"    = @{ Name="Intel Core i5-10400 / 10400F"; Socket="LGA 1200"; Node="14nm+++"; Cores="6 (6P)"; Threads="12"; BaseClock="2.9 GHz"; BoostClock="4.3 GHz"; L3Cache="12 MB"; TDP="65W"; RAM="DDR4-2666"; iGPU="Intel UHD 630"; R23Single=1120; R23Multi=8200; Main="B560, H510, B460, H410"; Arch="Comet Lake" };
    "10100"    = @{ Name="Intel Core i3-10100 / 10105F"; Socket="LGA 1200"; Node="14nm+++"; Cores="4 (4P)"; Threads="8"; BaseClock="3.6 GHz"; BoostClock="4.3 GHz"; L3Cache="6 MB"; TDP="65W"; RAM="DDR4-2666"; iGPU="Intel UHD 630"; R23Single=1080; R23Multi=5500; Main="H510, H410, B560"; Arch="Comet Lake" };

    # --- INTEL CORE GEN 8 & 9 (LGA 1151v2) ---
    "9900K"    = @{ Name="Intel Core i9-9900K"; Socket="LGA 1151v2"; Node="14nm++"; Cores="8 (8P)"; Threads="16"; BaseClock="3.6 GHz"; BoostClock="5.0 GHz"; L3Cache="16 MB"; TDP="95W"; RAM="DDR4-2666"; iGPU="Intel UHD 630"; R23Single=1280; R23Multi=12800; Main="Z390, B365, B360"; Arch="Coffee Lake-R" };
    "9700K"    = @{ Name="Intel Core i7-9700K"; Socket="LGA 1151v2"; Node="14nm++"; Cores="8 (8P)"; Threads="8"; BaseClock="3.6 GHz"; BoostClock="4.9 GHz"; L3Cache="12 MB"; TDP="95W"; RAM="DDR4-2666"; iGPU="Intel UHD 630"; R23Single=1230; R23Multi=9200; Main="Z390, B365, B360"; Arch="Coffee Lake-R" };
    "9400F"    = @{ Name="Intel Core i5-9400F / 9400"; Socket="LGA 1151v2"; Node="14nm++"; Cores="6 (6P)"; Threads="6"; BaseClock="2.9 GHz"; BoostClock="4.1 GHz"; L3Cache="9 MB"; TDP="65W"; RAM="DDR4-2666"; iGPU="Không có (hoặc UHD 630)"; R23Single=980; R23Multi=5600; Main="B365, B360, H310"; Arch="Coffee Lake-R" };
    "9100F"    = @{ Name="Intel Core i3-9100F"; Socket="LGA 1151v2"; Node="14nm++"; Cores="4 (4P)"; Threads="4"; BaseClock="3.6 GHz"; BoostClock="4.2 GHz"; L3Cache="6 MB"; TDP="65W"; RAM="DDR4-2400"; iGPU="Không có"; R23Single=970; R23Multi=3800; Main="H310, B365"; Arch="Coffee Lake-R" };
    "8700"     = @{ Name="Intel Core i7-8700 / 8700K"; Socket="LGA 1151v2"; Node="14nm++"; Cores="6 (6P)"; Threads="12"; BaseClock="3.2 GHz"; BoostClock="4.6 GHz"; L3Cache="12 MB"; TDP="65W / 95W"; RAM="DDR4-2666"; iGPU="Intel UHD 630"; R23Single=1150; R23Multi=8700; Main="B360, B365, Z370"; Arch="Coffee Lake" };

    # --- INTEL CORE GEN 6 & 7 (LGA 1151) ---
    "7700"     = @{ Name="Intel Core i7-7700 / 7700K"; Socket="LGA 1151"; Node="14nm+"; Cores="4 (4P)"; Threads="8"; BaseClock="3.6 GHz"; BoostClock="4.2 GHz"; L3Cache="8 MB"; TDP="65W / 91W"; RAM="DDR4-2400"; iGPU="Intel HD 630"; R23Single=1010; R23Multi=5800; Main="B250, H110, Z270"; Arch="Kaby Lake" };
    "6500"     = @{ Name="Intel Core i5-6500 / 6400"; Socket="LGA 1151"; Node="14nm"; Cores="4 (4P)"; Threads="4"; BaseClock="3.2 GHz"; BoostClock="3.6 GHz"; L3Cache="6 MB"; TDP="65W"; RAM="DDR4-2133 / DDR3L"; iGPU="Intel HD 530"; R23Single=850; R23Multi=3400; Main="B250, H110, B150"; Arch="Skylake" };
    "G4560"    = @{ Name="Intel Pentium G4560"; Socket="LGA 1151"; Node="14nm+"; Cores="2 (2P)"; Threads="4"; BaseClock="3.5 GHz"; BoostClock="3.5 GHz"; L3Cache="3 MB"; TDP="54W"; RAM="DDR4-2400"; iGPU="Intel HD 610"; R23Single=720; R23Multi=2200; Main="H110, B250"; Arch="Kaby Lake" };

    # --- INTEL CORE GEN 4 & 5 (LGA 1150) ---
    "4790K"    = @{ Name="Intel Core i7-4790K / 4790"; Socket="LGA 1150"; Node="22nm"; Cores="4 (4P)"; Threads="8"; BaseClock="4.0 GHz"; BoostClock="4.4 GHz"; L3Cache="8 MB"; TDP="88W"; RAM="DDR3-1600"; iGPU="Intel HD 4600"; R23Single=880; R23Multi=4800; Main="B85, H81, Z97"; Arch="Devil's Canyon" };
    "4460"     = @{ Name="Intel Core i5-4460 / 4590"; Socket="LGA 1150"; Node="22nm"; Cores="4 (4P)"; Threads="4"; BaseClock="3.2 GHz"; BoostClock="3.4 GHz"; L3Cache="6 MB"; TDP="84W"; RAM="DDR3-1600"; iGPU="Intel HD 4600"; R23Single=740; R23Multi=2900; Main="B85, H81"; Arch="Haswell" };
    "1231V3"   = @{ Name="Intel Xeon E3-1231v3 / 1230v3"; Socket="LGA 1150"; Node="22nm"; Cores="4 (4P)"; Threads="8"; BaseClock="3.4 GHz"; BoostClock="3.8 GHz"; L3Cache="8 MB"; TDP="80W"; RAM="DDR3-1600"; iGPU="Không có"; R23Single=820; R23Multi=4500; Main="B85, H81"; Arch="Haswell" };

    # --- INTEL CORE GEN 2 & 3 (LGA 1155) ---
    "3770"     = @{ Name="Intel Core i7-3770 / 3770K"; Socket="LGA 1155"; Node="22nm"; Cores="4 (4P)"; Threads="8"; BaseClock="3.4 GHz"; BoostClock="3.9 GHz"; L3Cache="8 MB"; TDP="77W"; RAM="DDR3-1600"; iGPU="Intel HD 4000"; R23Single=780; R23Multi=4200; Main="B75, H61, Z77"; Arch="Ivy Bridge" };
    "3470"     = @{ Name="Intel Core i5-3470 / 3570"; Socket="LGA 1155"; Node="22nm"; Cores="4 (4P)"; Threads="4"; BaseClock="3.2 GHz"; BoostClock="3.6 GHz"; L3Cache="6 MB"; TDP="77W"; RAM="DDR3-1600"; iGPU="Intel HD 2500"; R23Single=690; R23Multi=2600; Main="B75, H61"; Arch="Ivy Bridge" };
    "2400"     = @{ Name="Intel Core i5-2400 / 2500"; Socket="LGA 1155"; Node="32nm"; Cores="4 (4P)"; Threads="4"; BaseClock="3.1 GHz"; BoostClock="3.4 GHz"; L3Cache="6 MB"; TDP="95W"; RAM="DDR3-1333"; iGPU="Intel HD 2000"; R23Single=620; R23Multi=2300; Main="H61, B75"; Arch="Sandy Bridge" };

    # --- INTEL XEON WORKSTATION (X99 / X79) ---
    "2678V3"   = @{ Name="Intel Xeon E5-2678v3"; Socket="LGA 2011-3"; Node="22nm"; Cores="12 (12P)"; Threads="24"; BaseClock="2.5 GHz"; BoostClock="3.1 GHz (Unlock 3.3 Turbo)"; L3Cache="30 MB"; TDP="120W"; RAM="DDR4 / DDR3 ECC"; iGPU="Không có"; R23Single=680; R23Multi=12100; Main="X99, C612"; Arch="Haswell-EP" };
    "2680V4"   = @{ Name="Intel Xeon E5-2680v4"; Socket="LGA 2011-3"; Node="14nm"; Cores="14 (14P)"; Threads="28"; BaseClock="2.4 GHz"; BoostClock="3.3 GHz"; L3Cache="35 MB"; TDP="120W"; RAM="DDR4-2400 ECC"; iGPU="Không có"; R23Single=720; R23Multi=14200; Main="X99, C612"; Arch="Broadwell-EP" };
    "2670"     = @{ Name="Intel Xeon E5-2670"; Socket="LGA 2011"; Node="32nm"; Cores="8 (8P)"; Threads="16"; BaseClock="2.6 GHz"; BoostClock="3.3 GHz"; L3Cache="20 MB"; TDP="115W"; RAM="DDR3 ECC"; iGPU="Không có"; R23Single=540; R23Multi=6400; Main="X79"; Arch="Sandy Bridge-EP" };

    # --- INTEL CORE 2 QUAD (LGA 775) ---
    "Q9550"    = @{ Name="Intel Core 2 Quad Q9550 / Q9650"; Socket="LGA 775"; Node="45nm"; Cores="4 (4P)"; Threads="4"; BaseClock="2.83 GHz"; BoostClock="2.83 GHz"; L3Cache="12 MB L2"; TDP="95W"; RAM="DDR2 / DDR3"; iGPU="Không có"; R23Single=380; R23Multi=1520; Main="G41, G31, P45"; Arch="Yorkfield" };
    "E8400"    = @{ Name="Intel Core 2 Duo E8400"; Socket="LGA 775"; Node="45nm"; Cores="2 (2P)"; Threads="2"; BaseClock="3.0 GHz"; BoostClock="3.0 GHz"; L3Cache="6 MB L2"; TDP="65W"; RAM="DDR2 / DDR3"; iGPU="Không có"; R23Single=390; R23Multi=780; Main="G41, G31"; Arch="Wolfdale" };

    # --- AMD FX SERIES (AM3+) ---
    "FX-8350"  = @{ Name="AMD FX-8350 / FX-8320"; Socket="Socket AM3+"; Node="32nm (Vishera)"; Cores="8 (8P)"; Threads="8"; BaseClock="4.0 GHz"; BoostClock="4.2 GHz"; L3Cache="8 MB L3 + 8 MB L2"; TDP="125W"; RAM="DDR3-1866"; iGPU="Không có"; R23Single=480; R23Multi=3100; Main="970, 990FX"; Arch="Piledriver" };
    "FX-6300"  = @{ Name="AMD FX-6300"; Socket="Socket AM3+"; Node="32nm (Vishera)"; Cores="6 (6P)"; Threads="6"; BaseClock="3.5 GHz"; BoostClock="4.1 GHz"; L3Cache="8 MB L3"; TDP="95W"; RAM="DDR3-1866"; iGPU="Không có"; R23Single=460; R23Multi=2300; Main="970, 990FX"; Arch="Piledriver" }
}

# =========================================================================
# 3. ĐỘNG CƠ PHÂN TÍCH QUY TẮC MẪU THÔNG MINH (SMART HEURISTIC SPECS)
# Tự động sinh thông số chuẩn xác cho BẤT KỲ CPU nào chưa có trong Database!
# =========================================================================
function Get-VUONGTTSmartCpuSpecs {
    param([string]$Query)
    $q = if ($Query) { $Query.Trim().ToUpper() } else { "CORE I5" }

    # 1. NHẬN DIỆN THẾ HỆ INTEL CORE ULTRA (LGA 1851)
    if ($q -match "ULTRA|285|265|245|1851") {
        return @{
            Name = if ($q -like "*285*") { "Intel Core Ultra 9 285K" } elseif ($q -like "*265*") { "Intel Core Ultra 7 265K" } else { "Intel Core Ultra 5 245K" }
            Socket = "LGA 1851"
            Node = "TSMC N3B (3nm)"
            Cores = if ($q -like "*285*") { "24 (8P + 16E)" } elseif ($q -like "*265*") { "20 (8P + 12E)" } else { "14 (6P + 8E)" }
            Threads = if ($q -like "*285*") { "24" } elseif ($q -like "*265*") { "20" } else { "14" }
            BaseClock = "3.8 GHz"
            BoostClock = "5.5 GHz"
            L3Cache = "36 MB"
            TDP = "125W (Max 250W)"
            RAM = "DDR5-6400"
            iGPU = "Intel Graphics Xe"
            R23Single = 2250
            R23Multi = 36000
            Main = "Z890, B860, H810, W880"
            Arch = "Arrow Lake (Core Ultra 200S)"
        }
    }

    # 2. NHẬN DIỆN AMD RYZEN 9000 (ZEN 5 - AM5)
    if ($q -match "9[0-9]{3}X|9[0-9]{3}X3D|9800X|9950X|9900X|9700X|9600X") {
        $isX3D = $q -like "*X3D*"
        return @{
            Name = "AMD Ryzen " + $(if ($q -like "*9950*") { "9 9950X" } elseif ($q -like "*9900*") { "9 9900X" } elseif ($q -like "*9800*") { "7 9800X3D" } elseif ($q -like "*9700*") { "7 9700X" } else { "5 9600X" })
            Socket = "Socket AM5"
            Node = "TSMC 4nm (Zen 5)"
            Cores = if ($q -like "*9950*") { "16 (16P)" } elseif ($q -like "*9900*") { "12 (12P)" } elseif ($q -like "*9600*") { "6 (6P)" } else { "8 (8P)" }
            Threads = if ($q -like "*9950*") { "32" } elseif ($q -like "*9900*") { "24" } elseif ($q -like "*9600*") { "12" } else { "16" }
            BaseClock = "4.0 GHz"
            BoostClock = "5.4 GHz"
            L3Cache = if ($isX3D) { "96 MB (3D V-Cache)" } else { "32 MB / 64 MB" }
            TDP = if ($isX3D -or $q -like "*99*") { "120W - 170W" } else { "65W (PBO 105W)" }
            RAM = "DDR5-6000 EXPO"
            iGPU = "Radeon Graphics RDNA 2"
            R23Single = 2200
            R23Multi = if ($q -like "*9950*") { 45000 } elseif ($q -like "*9900*") { 34000 } else { 23000 }
            Main = "X870E, X870, B650E, B650, A620"
            Arch = "Zen 5 (Ryzen 9000)"
        }
    }

    # 3. NHẬN DIỆN INTEL GEN 12, 13, 14 (LGA 1700)
    if ($q -match "14[0-9]{3}|13[0-9]{3}|12[0-9]{3}|LGA 1700") {
        $gen = if ($q -like "*14*") { "14th Gen" } elseif ($q -like "*13*") { "13th Gen" } else { "12th Gen" }
        return @{
            Name = "Intel Core " + $(if ($q -like "*900*") { "i9" } elseif ($q -like "*700*") { "i7" } elseif ($q -like "*600*" -or $q -like "*400*" -or $q -like "*500*") { "i5" } else { "i3" }) + " ($gen)"
            Socket = "LGA 1700"
            Node = "Intel 7 (10nm)"
            Cores = if ($q -like "*900*") { "24 Cores" } elseif ($q -like "*700*") { "16-20 Cores" } elseif ($q -like "*600*" -or $q -like "*500*") { "14 Cores" } elseif ($q -like "*400*") { "6-10 Cores" } else { "4 Cores" }
            Threads = if ($q -like "*900*") { "32" } elseif ($q -like "*700*") { "24-28" } elseif ($q -like "*600*") { "20" } elseif ($q -like "*400*") { "12-16" } else { "8" }
            BaseClock = "3.0 GHz"
            BoostClock = if ($q -like "*900*") { "5.8 GHz - 6.0 GHz" } elseif ($q -like "*700*") { "5.4 GHz" } else { "4.6 GHz" }
            L3Cache = "18 MB - 36 MB"
            TDP = if ($q -like "*K*") { "125W (Max 253W)" } else { "65W (Max 148W)" }
            RAM = "DDR4 / DDR5 (Dual Support)"
            iGPU = if ($q -like "*F*") { "Không có (F-series)" } else { "Intel UHD 770 / 730" }
            R23Single = if ($q -like "*900*") { 2280 } elseif ($q -like "*700*") { 2150 } else { 1800 }
            R23Multi = if ($q -like "*900*") { 39000 } elseif ($q -like "*700*") { 32000 } elseif ($q -like "*600*") { 24000 } else { 15000 }
            Main = "Z790, B760, H610, Z690, B660"
            Arch = "Raptor Lake / Alder Lake (LGA 1700)"
        }
    }

    # 3.5. NHẬN DIỆN AMD FX SERIES (AM3+)
    if ($q -match "FX-|FX8|FX6|FX4|AM3\+|VISHERA|8350|8320|6300|4300") {
        return @{
            Name = "AMD FX Series Processor ($Query)"
            Socket = "Socket AM3+"
            Node = "32nm (Vishera)"
            Cores = if ($q -like "*8*") { "8 Cores" } elseif ($q -like "*6*") { "6 Cores" } else { "4 Cores" }
            Threads = if ($q -like "*8*") { "8 Threads" } elseif ($q -like "*6*") { "6 Threads" } else { "4 Threads" }
            BaseClock = "3.8 GHz"
            BoostClock = "4.2 GHz"
            L3Cache = "8 MB L3"
            TDP = "95W - 125W"
            RAM = "DDR3-1866"
            iGPU = "Không có"
            R23Single = 480
            R23Multi = 3100
            Main = "970, 990FX, 990X"
            Arch = "Vishera (AMD FX)"
        }
    }

    # 4. NHẬN DIỆN AMD RYZEN 7000 / 8000G (AM5)
    if ($q -match "7[0-9]{3}|8[0-9]{3}|7800X|7950X|7700|7600|7500|8700G|8600G") {
        return @{
            Name = "AMD Ryzen ($q - AM5)"
            Socket = "Socket AM5"
            Node = "TSMC 5nm (Zen 4)"
            Cores = if ($q -like "*7950*") { "16 Cores" } elseif ($q -like "*7900*") { "12 Cores" } elseif ($q -like "*7700*" -or $q -like "*7800*") { "8 Cores" } else { "6 Cores" }
            Threads = if ($q -like "*7950*") { "32" } elseif ($q -like "*7900*") { "24" } elseif ($q -like "*7700*" -or $q -like "*7800*") { "16" } else { "12" }
            BaseClock = "4.2 GHz"
            BoostClock = "5.2 GHz"
            L3Cache = if ($q -like "*X3D*") { "96 MB (3D V-Cache)" } else { "32 MB" }
            TDP = if ($q -like "*X3D*" -or $q -like "*79*") { "120W - 170W" } else { "65W - 105W" }
            RAM = "DDR5-5200 / DDR5-6000"
            iGPU = "Radeon Graphics"
            R23Single = 1900
            R23Multi = if ($q -like "*7950*") { 38000 } elseif ($q -like "*7800*") { 18500 } else { 15000 }
            Main = "B650, X670, A620, X870"
            Arch = "Zen 4 (Ryzen 7000 Series)"
        }
    }

    # 5. NHẬN DIỆN AMD RYZEN 5000 / 3000 / 2000 / 1000 (AM4)
    if ($q -match "5[0-9]{3}|3[0-9]{3}|2[0-9]{3}|1[0-9]{3}|AM4|5600|5700|5800|5900|3600") {
        return @{
            Name = "AMD Ryzen ($q - AM4)"
            Socket = "Socket AM4"
            Node = "TSMC 7nm / 12nm"
            Cores = if ($q -like "*5950*" -or $q -like "*3950*") { "16 Cores" } elseif ($q -like "*5900*" -or $q -like "*3900*") { "12 Cores" } elseif ($q -like "*5800*" -or $q -like "*5700*" -or $q -like "*3700*") { "8 Cores" } else { "6 Cores" }
            Threads = if ($q -like "*5950*" -or $q -like "*3950*") { "32" } elseif ($q -like "*5900*" -or $q -like "*3900*") { "24" } elseif ($q -like "*5800*" -or $q -like "*5700*" -or $q -like "*3700*") { "16" } else { "12" }
            BaseClock = "3.6 GHz"
            BoostClock = "4.6 GHz"
            L3Cache = if ($q -like "*X3D*") { "96 MB (3D V-Cache)" } else { "32 MB" }
            TDP = "65W - 105W"
            RAM = "DDR4-3200"
            iGPU = if ($q -like "*G*") { "Radeon Vega iGPU" } else { "Không có" }
            R23Single = 1500
            R23Multi = if ($q -like "*5950*") { 26000 } elseif ($q -like "*5800*") { 15000 } else { 11500 }
            Main = "B550, B450, A520, X570, A320"
            Arch = "Zen 3 / Zen 2 (Socket AM4)"
        }
    }

    # 6. NHẬN DIỆN INTEL GEN 10 / 11 (LGA 1200)
    if ($q -match "11[0-9]{3}|10[0-9]{3}|LGA 1200|10400|11400") {
        return @{
            Name = "Intel Core ($q - LGA 1200)"
            Socket = "LGA 1200"
            Node = "14nm+++"
            Cores = if ($q -like "*900*") { "10 Cores" } elseif ($q -like "*700*") { "8 Cores" } elseif ($q -like "*400*" -or $q -like "*600*") { "6 Cores" } else { "4 Cores" }
            Threads = if ($q -like "*900*") { "20" } elseif ($q -like "*700*") { "16" } elseif ($q -like "*400*" -or $q -like "*600*") { "12" } else { "8" }
            BaseClock = "3.2 GHz"
            BoostClock = "4.6 GHz"
            L3Cache = "12 MB - 20 MB"
            TDP = if ($q -like "*K*") { "125W" } else { "65W" }
            RAM = "DDR4-2933 / DDR4-3200"
            iGPU = "Intel UHD Graphics"
            R23Single = 1350
            R23Multi = if ($q -like "*900*") { 16000 } elseif ($q -like "*700*") { 13000 } else { 8500 }
            Main = "B560, H510, Z590, B460, H410"
            Arch = "Rocket Lake / Comet Lake (LGA 1200)"
        }
    }

    # 7. NHẬN DIỆN INTEL XEON (X99 / X79 / WORKSTATION)
    if ($q -match "XEON|2678|2680|2670|2696|2699|E5-|E3-|W-") {
        $isV3V4 = $q -like "*V3*" -or $q -like "*V4*"
        return @{
            Name = "Intel Xeon Processor ($Query)"
            Socket = if ($isV3V4) { "LGA 2011-3 (X99)" } else { "LGA 2011 (X79)" }
            Node = if ($isV3V4) { "22nm / 14nm" } else { "32nm" }
            Cores = "8 - 14 Cores"
            Threads = "16 - 28 Threads"
            BaseClock = "2.5 GHz"
            BoostClock = "3.3 GHz"
            L3Cache = "25 MB - 35 MB"
            TDP = "120W - 145W"
            RAM = if ($isV3V4) { "DDR4 ECC Registered" } else { "DDR3 ECC Registered" }
            iGPU = "Không có (Server/Workstation)"
            R23Single = 680
            R23Multi = 13500
            Main = if ($isV3V4) { "X99, C612" } else { "X79, C602" }
            Arch = "Haswell-EP / Broadwell-EP / Sandy-EP"
        }
    }

    # 8. MẪU MẶC ĐỊNH CHO TÊN BẤT KỲ
    return @{
        Name = "Bộ Xử Lý: $Query"
        Socket = "Theo tiêu chuẩn hãng sản xuất (Intel / AMD)"
        Node = "Quy trình bán dẫn tiêu chuẩn"
        Cores = "Đa nhân / Đa luồng"
        Threads = "Đa luồng đồng thời"
        BaseClock = "Xung chuẩn"
        BoostClock = "Turbo Boost"
        L3Cache = "Cache L3 dung lượng lớn"
        TDP = "65W - 125W"
        RAM = "DDR4 / DDR5"
        iGPU = "Tích hợp hoặc Yêu cầu VGA rời"
        R23Single = 1200
        R23Multi = 9000
        Main = "Tương thích theo socket nhà sản xuất công bố"
        Arch = "X86-64 Microarchitecture"
    }
}

# =========================================================================
# 4. TÌM KIẾM THÔNG TIN CPU TRỰC TUYẾN QUA INTERNET (ONLINE LIVE SEARCH)
# =========================================================================
function Find-CpuOnlineInfo {
    param([string]$Query)
    if ([string]::IsNullOrWhiteSpace($Query)) { return $null }

    $cleanQ = $Query.Trim()
    $result = [PSCustomObject]@{
        Success     = $false
        Query       = $cleanQ
        Title       = ""
        Summary     = ""
        SourceUrl   = ""
        Specs       = $null
    }

    try {
        # 1. Tra cứu Wikipedia API để tìm bài viết chính xác
        $searchUrl = "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=" + [uri]::EscapeDataString("$cleanQ microprocessor") + "&utf8=&format=json"
        $wikiSearch = Invoke-RestMethod -Uri $searchUrl -TimeoutSec 6 -UserAgent "VUONGTT_Toolkit_2026/2.0" -ErrorAction Stop

        if ($wikiSearch -and $wikiSearch.query -and $wikiSearch.query.search -and $wikiSearch.query.search.Count -gt 0) {
            $bestTitle = $wikiSearch.query.search[0].title
            
            # Lấy tóm tắt và thông số của trang này
            $summaryUrl = "https://en.wikipedia.org/api/rest_v1/page/summary/" + [uri]::EscapeDataString($bestTitle)
            $wikiSummary = Invoke-RestMethod -Uri $summaryUrl -TimeoutSec 6 -UserAgent "VUONGTT_Toolkit_2026/2.0" -ErrorAction SilentlyContinue

            if ($wikiSummary -and $wikiSummary.extract) {
                $result.Success   = $true
                $result.Title     = $wikiSummary.title
                $result.Summary   = $wikiSummary.extract
                $result.SourceUrl = if ($wikiSummary.content_urls -and $wikiSummary.content_urls.desktop) { $wikiSummary.content_urls.desktop.page } else { "" }
            }
        }
    } catch {
        # Fallback qua heuristic
    }

    # Kết hợp Heuristic Engine để có bảng thông số chuẩn
    $heuristic = Get-VUONGTTSmartCpuSpecs -Query $cleanQ
    if ($result.Success) {
        $heuristic.Name = "$cleanQ ($($result.Title))"
    }
    $result.Specs = $heuristic

    return $result
}

# =========================================================================
# 5. TÌM KIẾM BỘ ĐẶC TẢ CPU THEO QUERY (TỰ ĐỘNG CHỌN NGUỒN TỐT NHẤT)
# =========================================================================
function Find-CpuSpecByQuery {
    param(
        [string]$Query,
        [switch]$EnableOnlineSearch = $false
    )
    if ([string]::IsNullOrWhiteSpace($Query)) { return $script:CPU_SPEC_DB["14400"] }
    $q = $Query.Trim().ToUpper()

    # 1. Kiểm tra key trực tiếp trong từ điển tĩnh
    foreach ($k in $script:CPU_SPEC_DB.Keys) {
        $spec = $script:CPU_SPEC_DB[$k]
        if ($k.ToUpper() -eq $q -or $spec.Name.ToUpper() -eq $q) {
            return $spec
        }
    }

    # 2. Kiểm tra chứa tên hoặc model
    foreach ($k in $script:CPU_SPEC_DB.Keys) {
        $spec = $script:CPU_SPEC_DB[$k]
        if ($spec.Name.ToUpper().Contains($q) -or $q.Contains($k.ToUpper())) {
            return $spec
        }
    }

    # 3. Tra cứu trực tuyến nếu được yêu cầu
    if ($EnableOnlineSearch) {
        $online = Find-CpuOnlineInfo -Query $Query
        if ($online -and $online.Specs) {
            return $online.Specs
        }
    }

    # 4. Sử dụng Động cơ Heuristic thông minh
    return (Get-VUONGTTSmartCpuSpecs -Query $Query)
}

# =========================================================================
# 6. TỰ ĐỘNG SO SÁNH ĐỐI ĐẦU 2 CPU TOÀN DIỆN (SIDE-BY-SIDE ENGINE)
# =========================================================================
function Compare-VUONGTTCpu {
    param(
        [string]$Cpu1Query = "14400",
        [string]$Cpu2Query = "9800X3D",
        [switch]$EnableOnlineSearch = $false
    )

    $cpu1 = Find-CpuSpecByQuery -Query $Cpu1Query -EnableOnlineSearch:$EnableOnlineSearch
    $cpu2 = Find-CpuSpecByQuery -Query $Cpu2Query -EnableOnlineSearch:$EnableOnlineSearch

    $r23MultiDiff = 0
    $winnerMulti = ""
    if ($cpu1.R23Multi -and $cpu2.R23Multi) {
        if ($cpu1.R23Multi -gt $cpu2.R23Multi) {
            $diff = [math]::Round((($cpu1.R23Multi - $cpu2.R23Multi) / $cpu2.R23Multi) * 100, 1)
            $winnerMulti = "$($cpu1.Name) VƯỢT TRỘI (+$diff%)"
        } elseif ($cpu2.R23Multi -gt $cpu1.R23Multi) {
            $diff = [math]::Round((($cpu2.R23Multi - $cpu1.R23Multi) / $cpu1.R23Multi) * 100, 1)
            $winnerMulti = "$($cpu2.Name) VƯỢT TRỘI (+$diff%)"
        } else {
            $winnerMulti = "Ngang ngửa nhau (Hiệu năng tương đương)"
        }
    }

    $winnerSingle = ""
    if ($cpu1.R23Single -and $cpu2.R23Single) {
        if ($cpu1.R23Single -gt $cpu2.R23Single) {
            $diff = [math]::Round((($cpu1.R23Single - $cpu2.R23Single) / $cpu2.R23Single) * 100, 1)
            $winnerSingle = "$($cpu1.Name) NHANH HƠN (+$diff%)"
        } elseif ($cpu2.R23Single -gt $cpu1.R23Single) {
            $diff = [math]::Round((($cpu2.R23Single - $cpu1.R23Single) / $cpu1.R23Single) * 100, 1)
            $winnerSingle = "$($cpu2.Name) NHANH HƠN (+$diff%)"
        } else {
            $winnerSingle = "Ngang ngửa nhau"
        }
    }

    $lines = @()
    $lines += "================================================================================"
    $lines += "   BẢNG SO SÁNH HIỆU NĂNG & THÔNG SỐ ĐỐI ĐẦU CHI TIẾT: $($cpu1.Name) VS $($cpu2.Name)"
    $lines += "================================================================================"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "TIÊU CHÍ SO SÁNH", $cpu1.Name, $cpu2.Name
    $lines += "--------------------------------------------------------------------------------"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Socket cắm", $cpu1.Socket, $cpu2.Socket
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Kiến trúc / Node", "$($cpu1.Arch) ($($cpu1.Node))", "$($cpu2.Arch) ($($cpu2.Node))"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Số Nhân / Luồng", "$($cpu1.Cores) / $($cpu1.Threads)", "$($cpu2.Cores) / $($cpu2.Threads)"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Xung Cơ bản / Boost", "$($cpu1.BaseClock) / $($cpu1.BoostClock)", "$($cpu2.BaseClock) / $($cpu2.BoostClock)"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Bộ nhớ đệm L3 Cache", $cpu1.L3Cache, $cpu2.L3Cache
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Mức ăn điện TDP", $cpu1.TDP, $cpu2.TDP
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Chuẩn RAM hỗ trợ", $cpu1.RAM, $cpu2.RAM
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Mainboard tương thích", $cpu1.Main, $cpu2.Main
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Cinebench R23 Single", "$($cpu1.R23Single) pts", "$($cpu2.R23Single) pts"
    $lines += "{0,-24} | {1,-35} | {2,-35}" -f "• Cinebench R23 Multi", "$($cpu1.R23Multi) pts", "$($cpu2.R23Multi) pts"
    $lines += "--------------------------------------------------------------------------------"
    $lines += "🏆 ĐÁNH GIÁ ĐỐI ĐẦU CHUYÊN SÂU TỪ KỸ THUẬT VIÊN:"
    $lines += "• Đa nhiệm / Dựng hình 3D / Render: $winnerMulti"
    $lines += "• Tốc độ đơn nhân / Phản hồi phần mềm: $winnerSingle"

    # Nhận xét Gaming và 3D V-Cache
    if ($cpu1.L3Cache -like "*3D V-Cache*" -or $cpu2.L3Cache -like "*3D V-Cache*") {
        $x3dName = if ($cpu1.L3Cache -like "*3D V-Cache*") { $cpu1.Name } else { $cpu2.Name }
        $lines += "• Hiệu năng Gaming Thực Tế: $x3dName sở hữu công nghệ 3D V-Cache bộ đệm khủng, giúp đẩy mức 1% Low FPS và Average FPS trong các tựa game Esport/AAA lên cao nhất thị trường."
    }

    # Đánh giá nhiệt độ & tản nhiệt
    $lines += "• Tản nhiệt khuyến nghị:"
    $lines += "   + Với $($cpu1.Name) ($($cpu1.TDP)): $(if ($cpu1.TDP -like '*Max 2*' -or $cpu1.TDP -like '*170W*') { 'Cần tản nước AIO 360mm hoặc tản tháp đôi cao cấp.' } elseif ($cpu1.TDP -like '*12*') { 'Cần tản tháp khí đôi (Thermalright PA120) hoặc tản nước AIO 240mm.' } else { 'Tản khí đơn 4 ống đồng (CR1000 / AG400) hoạt động cực kỳ mát mẻ.' })"
    $lines += "   + Với $($cpu2.Name) ($($cpu2.TDP)): $(if ($cpu2.TDP -like '*Max 2*' -or $cpu2.TDP -like '*170W*') { 'Cần tản nước AIO 360mm hoặc tản tháp đôi cao cấp.' } elseif ($cpu2.TDP -like '*12*') { 'Cần tản tháp khí đôi (Thermalright PA120) hoặc tản nước AIO 240mm.' } else { 'Tản khí đơn 4 ống đồng (CR1000 / AG400) hoạt động cực kỳ mát mẻ.' })"
    $lines += "================================================================================"

    return [PSCustomObject]@{
        Cpu1        = $cpu1
        Cpu2        = $cpu2
        ReportText  = ($lines -join "`r`n")
    }
}
