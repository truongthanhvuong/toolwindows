# VUONGTT Toolkit 2026 - Laptop & Hardware Testing Module
# Encoding: UTF-8 with BOM

$script:cachedBatteryHealth = $null

function Get-LaptopBatteryHealth {
    [CmdletBinding()]
    param([switch]$ForceRefresh)

    if ($script:cachedBatteryHealth -and -not $ForceRefresh) {
        return $script:cachedBatteryHealth
    }

    $designCap = 0
    $fullCap = 0
    $cycleCount = "N/A"
    $chemistry = ""
    $voltage = ""
    $hasBattery = $false
    $batterySource = "Unknown"
    $batteryStatusStr = "Bình thường"
    $estimatedChargeStr = "N/A"

    # =========================================================================
    # TẦNG 1: THỬ LẤY TỪ CIM / WMI Win32_Battery & Win32_PortableBattery
    # =========================================================================
    $battery = $null
    try {
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $battery) {
            $battery = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        if ($battery) {
            $hasBattery = $true
            $batterySource = "Win32_Battery"
            if ($battery.EstimatedChargeRemaining) {
                $estimatedChargeStr = "$($battery.EstimatedChargeRemaining)%"
            }
            if ($battery.BatteryStatus) {
                $batteryStatusStr = switch ($battery.BatteryStatus) {
                    1 { "Đang xả pin (Discharging)" }
                    2 { "Đang cắm sạc (AC - Charging)" }
                    3 { "Đầy pin (Fully Charged)" }
                    4 { "Pin yếu (Low)" }
                    5 { "Pin cực yếu (Critical)" }
                    default { "Bình thường" }
                }
            }
            if ($battery.DesignCapacity -and [int]$battery.DesignCapacity -gt 0) {
                $designCap = [int]$battery.DesignCapacity
            }
            if ($battery.FullChargeCapacity -and [int]$battery.FullChargeCapacity -gt 0) {
                $fullCap = [int]$battery.FullChargeCapacity
            }
            if ($battery.Chemistry) {
                $chemistry = switch ($battery.Chemistry) {
                    3 { "Lead Acid" }
                    4 { "Nickel Cadmium (NiCd)" }
                    5 { "Nickel Metal Hydride (NiMH)" }
                    6 { "Lithium-ion (Li-ion)" }
                    7 { "Zinc air" }
                    8 { "Lithium Polymer (Li-Po)" }
                    default { "Lithium-ion (Li-ion)" }
                }
            }
            if ($battery.DesignVoltage -and [int]$battery.DesignVoltage -gt 0) {
                $voltage = "$([math]::Round($battery.DesignVoltage / 1000, 2)) V"
            }
        }
    } catch {}

    # Thử thêm Win32_PortableBattery nếu chưa có DesignCapacity
    if ($designCap -le 0) {
        try {
            $pBat = Get-CimInstance Win32_PortableBattery -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($pBat) {
                $hasBattery = $true
                if ($pBat.DesignCapacity -and [int]$pBat.DesignCapacity -gt 0) {
                    $designCap = [int]$pBat.DesignCapacity
                }
            }
        } catch {}
    }

    # =========================================================================
    # TẦNG 2: THỬ LẤY TỪ WMI root\wmi (BatteryStaticData, BatteryFullChargedCapacity, BatteryCycleCount, BatteryStatus)
    # =========================================================================
    try {
        $staticData = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($staticData) {
            $hasBattery = $true
            if ($designCap -le 0) {
                if ($staticData.DesignedCapacity -and [int]$staticData.DesignedCapacity -gt 0) {
                    $designCap = [int]$staticData.DesignedCapacity
                } elseif ($staticData.DesignCapacity -and [int]$staticData.DesignCapacity -gt 0) {
                    $designCap = [int]$staticData.DesignCapacity
                }
            }
            if (-not $chemistry -and $staticData.Chemistry) {
                try {
                    $chemChars = [System.Text.Encoding]::ASCII.GetString($staticData.Chemistry).Trim([char]0, ' ')
                    if ($chemChars -match '(?i)li[-_]?i|lion') {
                        $chemistry = "Lithium-ion (Li-ion)"
                    } elseif ($chemChars -match '(?i)lip|poly') {
                        $chemistry = "Lithium Polymer (Li-Po)"
                    } elseif ($chemChars) {
                        $chemistry = $chemChars
                    }
                } catch {}
            }
            if (-not $voltage -and $staticData.DesignedVoltage -and [int]$staticData.DesignedVoltage -gt 0) {
                $voltage = "$([math]::Round($staticData.DesignedVoltage / 1000, 2)) V"
            }
        }

        $fullCapData = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($fullCapData -and $fullCapData.FullChargedCapacity -and [int]$fullCapData.FullChargedCapacity -gt 0) {
            $hasBattery = $true
            if ($fullCap -le 0) {
                $fullCap = [int]$fullCapData.FullChargedCapacity
            }
        }

        $cycleData = Get-CimInstance -Namespace root\wmi -ClassName BatteryCycleCount -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cycleData -and $cycleData.CycleCount) {
            $hasBattery = $true
            if ($cycleCount -eq "N/A" -or [string]::IsNullOrWhiteSpace($cycleCount)) {
                $cycleCount = "$($cycleData.CycleCount)"
            }
        }

        if ($estimatedChargeStr -eq "N/A") {
            $wmiStatus = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($wmiStatus -and $wmiStatus.RemainingCapacity -and $fullCap -gt 0) {
                $pct = [math]::Round(($wmiStatus.RemainingCapacity / $fullCap) * 100)
                $estimatedChargeStr = "$pct%"
            }
        }
    } catch {}

    # =========================================================================
    # TẦNG 3: KIỂM TRA QUA WIN32 API POWERSTATUS & PNP BATTERY CONTROLLER
    # =========================================================================
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        $pStatus = [System.Windows.Forms.SystemInformation]::PowerStatus
        if ($pStatus -and $pStatus.BatteryChargeStatus -ne [System.Windows.Forms.BatteryChargeStatus]::NoSystemBattery) {
            $hasBattery = $true
            if ($estimatedChargeStr -eq "N/A" -and $pStatus.BatteryLifePercent -ge 0) {
                $estimatedChargeStr = "$([math]::Round($pStatus.BatteryLifePercent * 100))%"
            }
            if ($batteryStatusStr -eq "Bình thường") {
                if ($pStatus.PowerLineStatus -eq [System.Windows.Forms.PowerLineStatus]::Online) {
                    $batteryStatusStr = "Đang cắm sạc (AC Online)"
                } else {
                    $batteryStatusStr = "Đang dùng pin (Battery Discharging)"
                }
            }
        }
    } catch {}

    # Kiểm tra phần cứng Battery PnP Device (Microsoft ACPI-Compliant Control Method Battery)
    try {
        $pnpBat = Get-CimInstance Win32_PnPEntity -Filter "PNPClass='Battery'" -ErrorAction SilentlyContinue | Where-Object { $_.DeviceID -like "*PNP0C0A*" -or $_.Name -like "*Control Method Battery*" -or $_.Name -like "*Pin*" }
        if ($pnpBat) {
            $hasBattery = $true
        }
    } catch {}

    # =========================================================================
    # TẦNG 4: CHẠY POWERCFG /BATTERYREPORT (ACPI KERNEL DEEP SCAN)
    # Đây là nguồn chuẩn xác nhất của Windows OS, cứu hộ khi WMI bị thiếu
    # =========================================================================
    if ($designCap -le 0 -or $fullCap -le 0 -or $cycleCount -eq "N/A" -or -not $hasBattery) {
        $reportBase = [System.IO.Path]::Combine($env:TEMP, "vuongtt_bat_check_$([Guid]::NewGuid().ToString('N'))")
        $tempXml = "$reportBase.xml"
        try {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "powercfg.exe"
            $psi.Arguments = "/batteryreport /xml /output `"$tempXml`""
            $psi.CreateNoWindow = $true
            $psi.UseShellExecute = $false
            $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
            $proc = [System.Diagnostics.Process]::Start($psi)
            
            # Cho phép chạy tối đa 12 giây để đọc đầy đủ ACPI kernel
            if ($proc.WaitForExit(12000)) {
                if (Test-Path -LiteralPath $tempXml) {
                    [xml]$xml = Get-Content -LiteralPath $tempXml -Raw -ErrorAction SilentlyContinue
                    $batNodes = $xml.SelectNodes("//Battery")
                    if ($batNodes -and $batNodes.Count -gt 0) {
                        $hasBattery = $true
                        foreach ($bNode in $batNodes) {
                            if ($designCap -le 0 -and $bNode.DesignCapacity) {
                                $rawD = ($bNode.DesignCapacity -replace '[^\d]')
                                $valD = 0
                                if ([int]::TryParse($rawD, [ref]$valD) -and $valD -gt 0) {
                                    $designCap = $valD
                                }
                            }
                            if ($fullCap -le 0 -and $bNode.FullChargeCapacity) {
                                $rawF = ($bNode.FullChargeCapacity -replace '[^\d]')
                                $valF = 0
                                if ([int]::TryParse($rawF, [ref]$valF) -and $valF -gt 0) {
                                    $fullCap = $valF
                                }
                            }
                            if (($cycleCount -eq "N/A" -or [string]::IsNullOrWhiteSpace($cycleCount)) -and $bNode.CycleCount) {
                                $rawC = ($bNode.CycleCount -replace '[^\d]')
                                if ($rawC) {
                                    $cycleCount = "$rawC"
                                }
                            }
                            if (-not $chemistry -and $bNode.Chemistry) {
                                $cVal = "$($bNode.Chemistry)".Trim()
                                if ($cVal -match '(?i)li[-_]?i|lion') {
                                    $chemistry = "Lithium-ion (Li-ion)"
                                } elseif ($cVal -match '(?i)lip|poly') {
                                    $chemistry = "Lithium Polymer (Li-Po)"
                                } elseif ($cVal) {
                                    $chemistry = $cVal
                                }
                            }
                        }
                    }
                    Remove-Item -LiteralPath $tempXml -Force -ErrorAction SilentlyContinue
                }
            } else {
                try { $proc.Kill() } catch {}
            }
        } catch {}
        finally {
            if (Test-Path -LiteralPath $tempXml) {
                Remove-Item -LiteralPath $tempXml -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # =========================================================================
    # TẦNG 5: NẾU VẪN THIẾU -> FALLBACK THỬ POWERCFG HTML REPORT & REGEX PARSE
    # =========================================================================
    if (($designCap -le 0 -or $fullCap -le 0 -or -not $chemistry) -and $hasBattery) {
        $tempHtml = [System.IO.Path]::Combine($env:TEMP, "vuongtt_bat_html_$([Guid]::NewGuid().ToString('N')).html")
        try {
            $psi2 = New-Object System.Diagnostics.ProcessStartInfo
            $psi2.FileName = "powercfg.exe"
            $psi2.Arguments = "/batteryreport /output `"$tempHtml`""
            $psi2.CreateNoWindow = $true
            $psi2.UseShellExecute = $false
            $proc2 = [System.Diagnostics.Process]::Start($psi2)
            if ($proc2.WaitForExit(10000)) {
                if (Test-Path -LiteralPath $tempHtml) {
                    $htmlContent = Get-Content -LiteralPath $tempHtml -Raw -ErrorAction SilentlyContinue
                    if ($htmlContent) {
                        # Regex tìm DESIGN CAPACITY
                        if ($designCap -le 0 -and $htmlContent -match "(?i)DESIGN\s+CAPACITY[\s\S]*?<td[^>]*>\s*([\d,]+)\s*mWh") {
                            $valStr = $matches[1] -replace '[^\d]'
                            $valInt = 0
                            if ([int]::TryParse($valStr, [ref]$valInt) -and $valInt -gt 0) { $designCap = $valInt }
                        }
                        # Regex tìm FULL CHARGE CAPACITY
                        if ($fullCap -le 0 -and $htmlContent -match "(?i)FULL\s+CHARGE\s+CAPACITY[\s\S]*?<td[^>]*>\s*([\d,]+)\s*mWh") {
                            $valStr = $matches[1] -replace '[^\d]'
                            $valInt = 0
                            if ([int]::TryParse($valStr, [ref]$valInt) -and $valInt -gt 0) { $fullCap = $valInt }
                        }
                        # Regex tìm CYCLE COUNT
                        if ($cycleCount -eq "N/A" -and $htmlContent -match "(?i)CYCLE\s+COUNT[\s\S]*?<td[^>]*>\s*([\d,]+)") {
                            $valStr = $matches[1] -replace '[^\d]'
                            if ($valStr) { $cycleCount = $valStr }
                        }
                        # Regex tìm CHEMISTRY
                        if (-not $chemistry -and $htmlContent -match "(?i)CHEMISTRY[\s\S]*?<td[^>]*>\s*([^<]+)\s*</td>") {
                            $cVal = $matches[1].Trim()
                            if ($cVal -match '(?i)li[-_]?i|lion') {
                                $chemistry = "Lithium-ion (Li-ion)"
                            } elseif ($cVal -match '(?i)lip|poly') {
                                $chemistry = "Lithium Polymer (Li-Po)"
                            } elseif ($cVal) {
                                $chemistry = $cVal
                            }
                        }
                    }
                    Remove-Item -LiteralPath $tempHtml -Force -ErrorAction SilentlyContinue
                }
            } else {
                try { $proc2.Kill() } catch {}
            }
        } catch {}
        finally {
            if (Test-Path -LiteralPath $tempHtml) {
                Remove-Item -LiteralPath $tempHtml -Force -ErrorAction SilentlyContinue
            }
        }
    }

    # =========================================================================
    # TẦNG 6: PHÂN BIỆT RÕ RÀNG LAPTOP VS DESKTOP NẾU HOÀN TOÀN KHÔNG CÓ PIN
    # =========================================================================
    if (-not $hasBattery) {
        $isChassisLaptop = $false
        try {
            $enc = Get-CimInstance Win32_SystemEnclosure -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($enc -and $enc.ChassisTypes) {
                if ($enc.ChassisTypes | Where-Object { $_ -in @(8, 9, 10, 11, 12, 14, 30, 31, 32) }) {
                    $isChassisLaptop = $true
                }
            }
        } catch {}

        if ($isChassisLaptop) {
            # Là Laptop nhưng pin bị tháo, bị chai chết 0V, hoặc driver ACPI bị lỗi
            $laptopNoBat = [PSCustomObject]@{
                HasBattery               = $true
                IsLaptopNoBattery        = $true
                DesignCapacity           = "Không thể đọc dữ liệu pin"
                FullChargeCapacity       = "Pin có thể bị tháo rời hoặc chai kiệt 0V"
                DesignCapacityValue      = 0
                FullChargeCapacityValue  = 0
                WearLevelPercent         = $null
                HealthPercent            = $null
                HealthStatus             = "Cần kiểm tra pin vật lý hoặc driver ACPI"
                CycleCount               = "N/A"
                Chemistry                = "N/A"
                Voltage                  = "N/A"
                BatteryWearRating        = "Không xác định (Pin bị tháo hoặc chai kiệt)"
                WearAdvice               = "Pin có thể đã bị tháo rời hoặc chai kiệt 0V. Vui lòng kiểm tra lại phần cứng hoặc kết nối socket pin."
                EstimatedChargeRemaining = "Cắm nguồn AC"
                BatteryStatus            = "Không nhận diện được cell pin (Cắm sạc trực tiếp)"
            }
            $script:cachedBatteryHealth = $laptopNoBat
            return $laptopNoBat
        }

        # Thực sự là máy tính để bàn (Desktop PC)
        $noBat = [PSCustomObject]@{
            HasBattery               = $false
            IsLaptopNoBattery        = $false
            DesignCapacity           = "Không có pin (Máy để bàn Desktop)"
            FullChargeCapacity       = "N/A"
            DesignCapacityValue      = 0
            FullChargeCapacityValue  = 0
            WearLevelPercent         = 0
            HealthPercent            = 100
            HealthStatus             = "N/A - Desktop PC"
            CycleCount               = "N/A"
            Chemistry                = "N/A"
            Voltage                  = "N/A"
            BatteryWearRating        = "N/A - Desktop PC"
            WearAdvice               = "Máy tính để bàn hoạt động với nguồn điện xoay chiều AC trực tiếp, không sử dụng pin."
            EstimatedChargeRemaining = "N/A"
            BatteryStatus            = "Cắm nguồn AC trực tiếp"
        }
        $script:cachedBatteryHealth = $noBat
        return $noBat
    }

    # =========================================================================
    # TẦNG 7: TÍNH TOÁN ĐỘ CHAI PIN, PHÂN LOẠI & LỜI KHUYÊN KỸ THUẬT
    # =========================================================================
    if (-not $chemistry) {
        $chemistry = "Lithium-ion (Li-ion)"
    }
    if (-not $voltage) {
        $voltage = "11.4 V (Tiêu chuẩn)"
    }

    $wearLevel = $null
    $healthPercent = $null
    $wearRating = "Chưa thể đo"
    $wearAdvice = "Cần cắm sạc hoặc dùng pin thêm để hệ điều hành cập nhật dữ liệu ACPI."

    if ($designCap -gt 0 -and $fullCap -gt 0) {
        if ($designCap -ge $fullCap) {
            $wearLevel = [math]::Round((($designCap - $fullCap) / $designCap) * 100, 1)
            $healthPercent = [math]::Round(($fullCap / $designCap) * 100, 1)
        } else {
            # Pin mới sạc đầy vượt thiết kế ban đầu
            $wearLevel = 0.0
            $healthPercent = 100.0
        }

        if ($wearLevel -le 15.0) {
            $wearRating = "Pin Rất Tốt (Như mới)"
            $wearAdvice = "Pin hoạt động hoàn hảo, cell pin còn nguyên dung lượng thiết kế ban đầu."
        } elseif ($wearLevel -le 30.0) {
            $wearRating = "Pin Tốt / Bình Thường (Ổn định)"
            $wearAdvice = "Pin duy trì hiệu năng tốt, thời lượng sử dụng ổn định cho công việc hàng ngày."
        } elseif ($wearLevel -le 50.0) {
            $wearRating = "Pin Chai Khá Nhiều (Thời lượng giảm)"
            $wearAdvice = "Thời lượng dùng pin đã giảm từ 30% - 50%. Khuyến nghị cắm sạc khi xử lý đồ họa hoặc tác vụ nặng."
        } else {
            $wearRating = "Chai Nặng - Khuyến nghị thay cell pin mới"
            $wearAdvice = "CẢNH BÁO NGUY HIỂM: Pin đã chai vượt 50%, tiềm ẩn nguy cơ phồng pin làm cấn touchpad/bàn phím hoặc sập nguồn đột ngột. Khuyến nghị thay thế cell pin mới."
        }
    }

    $designStr = if ($designCap -gt 0) { "$designCap mWh" } else { "Không xác định (OEM không cung cấp)" }
    $fullStr   = if ($fullCap -gt 0) { "$fullCap mWh" } else { "Không xác định" }
    $healthStr = if ($null -ne $healthPercent) { "$healthPercent%" } else { "Chưa thể đo" }

    $batObj = [PSCustomObject]@{
        HasBattery               = $true
        IsLaptopNoBattery        = $false
        DesignCapacity           = $designStr
        FullChargeCapacity       = $fullStr
        DesignCapacityValue      = $designCap
        FullChargeCapacityValue  = $fullCap
        WearLevelPercent         = $wearLevel
        HealthPercent            = $healthPercent
        HealthStatus             = $healthStr
        CycleCount               = $cycleCount
        Chemistry                = $chemistry
        Voltage                  = $voltage
        BatteryWearRating        = $wearRating
        WearAdvice               = $wearAdvice
        EstimatedChargeRemaining = $estimatedChargeStr
        BatteryStatus            = $batteryStatusStr
    }
    $script:cachedBatteryHealth = $batObj
    return $batObj
}

function Export-BatteryReport {
    $reportPath = "$env:TEMP\VUONGTT_Battery_Report.html"
    try {
        powercfg /batteryreport /output "$reportPath" | Out-Null
        if (Test-Path $reportPath) {
            Start-Process $reportPath
            return "[OK] Đã xuất báo cáo pin HTML chi tiết thành công tại: $reportPath"
        } else {
            return "Không thể tạo báo cáo pin (Có thể thiết bị là máy để bàn Desktop không có pin hoặc Windows hạn chế quyền tạo báo cáo)."
        }
    } catch {
        return "Lỗi: $($_.Exception.Message)"
    }
}

function Start-ScreenDeadPixelTest {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VUONGTT Screen Dead Pixel Tester"
        WindowStyle="None" WindowState="Maximized" Topmost="True" Background="Red" Focusable="True" Cursor="Hand">
    <Grid Background="Transparent">
        <Border x:Name="hintBorder" Background="#B3000000" CornerRadius="10" Padding="20,10" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="0,0,0,40">
            <TextBlock x:Name="txtHint" Text="[1/9] MÀU ĐỎ (PURE RED) | Chuột Trái / Space: Đổi màu | Chuột Phải: Lùi màu | ESC: Thoát" 
                       Foreground="White" FontSize="15" FontWeight="SemiBold" HorizontalAlignment="Center"/>
        </Border>
    </Grid>
</Window>
"@
    try {
        $win = [System.Windows.Markup.XamlReader]::Parse($xaml)
        if ($null -eq $win) {
            throw "Không thể tạo cửa sổ kiểm tra màn hình (XamlReader trả về null)."
        }

        $colorList = @(
            @{ Name = "[1/9] MÀU ĐỎ (PURE RED) - Kiểm tra điểm chết sub-pixel Đỏ"; Brush = [System.Windows.Media.Brushes]::Red; IsDark = $false },
            @{ Name = "[2/9] MÀU XANH LÁ (PURE GREEN) - Kiểm tra điểm chết sub-pixel Xanh lá"; Brush = [System.Windows.Media.Brushes]::Lime; IsDark = $false },
            @{ Name = "[3/9] MÀU XANH DƯƠNG (PURE BLUE) - Kiểm tra điểm chết sub-pixel Xanh dương"; Brush = [System.Windows.Media.Brushes]::Blue; IsDark = $true },
            @{ Name = "[4/9] MÀU TRẮNG (PURE WHITE) - Kiểm tra đốm mờ, bụi bẩn lót phản quang màn hình"; Brush = [System.Windows.Media.Brushes]::White; IsDark = $false },
            @{ Name = "[5/9] MÀU ĐEN (PURE BLACK) - Kiểm tra hở sáng viền (IPS Glow), điểm sáng (Hot Pixel)"; Brush = [System.Windows.Media.Brushes]::Black; IsDark = $true },
            @{ Name = "[6/9] MÀU VÀNG (YELLOW) - Kiểm tra pha trộn màu Red + Green"; Brush = [System.Windows.Media.Brushes]::Yellow; IsDark = $false },
            @{ Name = "[7/9] MÀU CYAN (XANH NGỌC) - Kiểm tra pha trộn màu Green + Blue"; Brush = [System.Windows.Media.Brushes]::Cyan; IsDark = $false },
            @{ Name = "[8/9] MÀU TÍM (MAGENTA) - Kiểm tra pha trộn màu Red + Blue"; Brush = [System.Windows.Media.Brushes]::Magenta; IsDark = $false },
            @{ Name = "[9/9] MÀU XÁM 50% (GRAY) - Kiểm tra độ đồng đều ánh sáng toàn tấm nền"; Brush = [System.Windows.Media.Brushes]::Gray; IsDark = $true }
        )

        # Sử dụng đối tượng tham chiếu để duy trì giá trị index xuyên suốt các sự kiện WPF
        $state = [PSCustomObject]@{ Index = 0 }

        $updateColor = {
            $item = $colorList[$state.Index]
            $win.Background = $item.Brush
            $txtHint = $win.FindName("txtHint")
            if ($txtHint) {
                $txtHint.Text = "$($item.Name) | Click Trái / Space / Cuộn Chuột: Tiếp | Click Phải: Lùi | ESC: Thoát"
            }
        }

        # Đảm bảo cửa sổ nhận tiêu điểm bàn phím ngay khi mở
        $win.Add_Loaded({
            $win.Activate()
            $win.Focus()
            & $updateColor
        })

        # Bắt sự kiện nhấn chuột Tunneling (PreviewMouseDown) đảm bảo 100% bắt được sự kiện
        $win.Add_PreviewMouseDown({
            param($s, $e)
            if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
                $state.Index++
                if ($state.Index -ge $colorList.Count) { $state.Index = 0 }
                & $updateColor
            } elseif ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right) {
                $state.Index--
                if ($state.Index -lt 0) { $state.Index = $colorList.Count - 1 }
                & $updateColor
            } elseif ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Middle) {
                $win.Close()
            }
        })

        # Hỗ trợ con lăn chuột cuộn tới / cuộn lùi màu sắc
        $win.Add_PreviewMouseWheel({
            param($s, $e)
            if ($e.Delta -lt 0) {
                $state.Index++
                if ($state.Index -ge $colorList.Count) { $state.Index = 0 }
                & $updateColor
            } else {
                $state.Index--
                if ($state.Index -lt 0) { $state.Index = $colorList.Count - 1 }
                & $updateColor
            }
        })

        # Bắt sự kiện bàn phím Tunneling (PreviewKeyDown)
        $win.Add_PreviewKeyDown({
            param($s, $e)
            if ($e.Key -eq [System.Windows.Input.Key]::Escape -or $e.Key -eq [System.Windows.Input.Key]::Q) {
                $win.Close()
            } elseif ($e.Key -eq [System.Windows.Input.Key]::Left -or $e.Key -eq [System.Windows.Input.Key]::Back -or $e.Key -eq [System.Windows.Input.Key]::Up -or $e.Key -eq [System.Windows.Input.Key]::PageUp) {
                $state.Index--
                if ($state.Index -lt 0) { $state.Index = $colorList.Count - 1 }
                & $updateColor
            } else {
                $state.Index++
                if ($state.Index -ge $colorList.Count) { $state.Index = 0 }
                & $updateColor
            }
        })

        # Click đúp để thoát nhanh
        $win.Add_MouseDoubleClick({
            $win.Close()
        })

        $win.ShowDialog() | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("Lỗi khởi chạy Test Màn Hình: $($_.Exception.Message)", "Test Màn Hình", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

function Start-VisualKeyboardTest {
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VUONGTT Keyboard Tester Pro 2026 - Kiểm Tra Bàn Phím Trực Quan Offline"
        Width="980" Height="450" WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#0F172A" Topmost="True"
        FontFamily="SF Pro Display, SF Pro Text, -apple-system, BlinkMacSystemFont, Segoe UI Variable Display, Segoe UI, sans-serif"
        TextOptions.TextFormattingMode="Display" TextOptions.TextRenderingMode="ClearType">
    <Window.Resources>
        <Style x:Key="KeyStyle" TargetType="Border">
            <Setter Property="Background" Value="#1E293B"/>
            <Setter Property="BorderBrush" Value="#334155"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="CornerRadius" Value="5"/>
            <Setter Property="Margin" Value="2.5"/>
            <Setter Property="Height" Value="42"/>
            <Setter Property="MinWidth" Value="42"/>
        </Style>
        <Style x:Key="KeyText" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#CBD5E1"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="HorizontalAlignment" Value="Center"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
    </Window.Resources>
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header Info -->
        <Border Grid.Row="0" Background="#1E293B" CornerRadius="8" Padding="14,10" Margin="0,0,0,12" BorderBrush="#334155" BorderThickness="1">
            <Grid>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Text="⌨️ VUONGTT KEYBOARD TESTER (OFFLINE)" FontSize="15" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,16,0"/>
                    <TextBlock x:Name="txtKeyStatus" Text="Phím vừa gõ: Chưa có | Mã: 0" FontSize="13" Foreground="#94A3B8" VerticalAlignment="Center"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <TextBlock x:Name="txtKeyCount" Text="Đã nhận: 0 phím" FontSize="13" FontWeight="Bold" Foreground="#4ADE80" VerticalAlignment="Center" Margin="0,0,16,0"/>
                    <Button x:Name="btnResetKeys" Content="🔄 Đặt Lại" Background="#475569" Foreground="White" FontWeight="SemiBold" Padding="12,5" BorderThickness="0" Cursor="Hand"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Keyboard Visual Grid -->
        <Border Grid.Row="1" Background="#141E33" CornerRadius="8" Padding="12" BorderBrush="#1E293B" BorderThickness="1">
            <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                <!-- Function Row: Esc, F1-F12 -->
                <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                    <Border x:Name="k_Escape" Style="{StaticResource KeyStyle}" Width="48"><TextBlock Text="Esc" Style="{StaticResource KeyText}"/></Border>
                    <Border Width="20"/>
                    <Border x:Name="k_F1" Style="{StaticResource KeyStyle}"><TextBlock Text="F1" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F2" Style="{StaticResource KeyStyle}"><TextBlock Text="F2" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F3" Style="{StaticResource KeyStyle}"><TextBlock Text="F3" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F4" Style="{StaticResource KeyStyle}"><TextBlock Text="F4" Style="{StaticResource KeyText}"/></Border>
                    <Border Width="15"/>
                    <Border x:Name="k_F5" Style="{StaticResource KeyStyle}"><TextBlock Text="F5" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F6" Style="{StaticResource KeyStyle}"><TextBlock Text="F6" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F7" Style="{StaticResource KeyStyle}"><TextBlock Text="F7" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F8" Style="{StaticResource KeyStyle}"><TextBlock Text="F8" Style="{StaticResource KeyText}"/></Border>
                    <Border Width="15"/>
                    <Border x:Name="k_F9" Style="{StaticResource KeyStyle}"><TextBlock Text="F9" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F10" Style="{StaticResource KeyStyle}"><TextBlock Text="F10" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F11" Style="{StaticResource KeyStyle}"><TextBlock Text="F11" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F12" Style="{StaticResource KeyStyle}"><TextBlock Text="F12" Style="{StaticResource KeyText}"/></Border>
                </StackPanel>

                <!-- Number Row -->
                <StackPanel Orientation="Horizontal">
                    <Border x:Name="k_Oem3" Style="{StaticResource KeyStyle}"><TextBlock Text="~" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D1" Style="{StaticResource KeyStyle}"><TextBlock Text="1" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D2" Style="{StaticResource KeyStyle}"><TextBlock Text="2" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D3" Style="{StaticResource KeyStyle}"><TextBlock Text="3" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D4" Style="{StaticResource KeyStyle}"><TextBlock Text="4" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D5" Style="{StaticResource KeyStyle}"><TextBlock Text="5" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D6" Style="{StaticResource KeyStyle}"><TextBlock Text="6" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D7" Style="{StaticResource KeyStyle}"><TextBlock Text="7" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D8" Style="{StaticResource KeyStyle}"><TextBlock Text="8" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D9" Style="{StaticResource KeyStyle}"><TextBlock Text="9" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D0" Style="{StaticResource KeyStyle}"><TextBlock Text="0" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_OemMinus" Style="{StaticResource KeyStyle}"><TextBlock Text="-" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_OemPlus" Style="{StaticResource KeyStyle}"><TextBlock Text="+" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Back" Style="{StaticResource KeyStyle}" Width="78"><TextBlock Text="Backspace" Style="{StaticResource KeyText}"/></Border>
                </StackPanel>

                <!-- QWERTY Row -->
                <StackPanel Orientation="Horizontal">
                    <Border x:Name="k_Tab" Style="{StaticResource KeyStyle}" Width="65"><TextBlock Text="Tab" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Q" Style="{StaticResource KeyStyle}"><TextBlock Text="Q" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_W" Style="{StaticResource KeyStyle}"><TextBlock Text="W" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_E" Style="{StaticResource KeyStyle}"><TextBlock Text="E" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_R" Style="{StaticResource KeyStyle}"><TextBlock Text="R" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_T" Style="{StaticResource KeyStyle}"><TextBlock Text="T" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Y" Style="{StaticResource KeyStyle}"><TextBlock Text="Y" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_U" Style="{StaticResource KeyStyle}"><TextBlock Text="U" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_I" Style="{StaticResource KeyStyle}"><TextBlock Text="I" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_O" Style="{StaticResource KeyStyle}"><TextBlock Text="O" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_P" Style="{StaticResource KeyStyle}"><TextBlock Text="P" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_OemOpenBrackets" Style="{StaticResource KeyStyle}"><TextBlock Text="[" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Oem6" Style="{StaticResource KeyStyle}"><TextBlock Text="]" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Oem5" Style="{StaticResource KeyStyle}" Width="52"><TextBlock Text="\" Style="{StaticResource KeyText}"/></Border>
                </StackPanel>

                <!-- ASDF Row -->
                <StackPanel Orientation="Horizontal">
                    <Border x:Name="k_Capital" Style="{StaticResource KeyStyle}" Width="78"><TextBlock Text="Caps Lock" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_A" Style="{StaticResource KeyStyle}"><TextBlock Text="A" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_S" Style="{StaticResource KeyStyle}"><TextBlock Text="S" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_D" Style="{StaticResource KeyStyle}"><TextBlock Text="D" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_F" Style="{StaticResource KeyStyle}"><TextBlock Text="F" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_G" Style="{StaticResource KeyStyle}"><TextBlock Text="G" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_H" Style="{StaticResource KeyStyle}"><TextBlock Text="H" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_J" Style="{StaticResource KeyStyle}"><TextBlock Text="J" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_K" Style="{StaticResource KeyStyle}"><TextBlock Text="K" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_L" Style="{StaticResource KeyStyle}"><TextBlock Text="L" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Oem1" Style="{StaticResource KeyStyle}"><TextBlock Text=";" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_OemQuotes" Style="{StaticResource KeyStyle}"><TextBlock Text="'" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Return" Style="{StaticResource KeyStyle}" Width="92"><TextBlock Text="Enter ↵" Style="{StaticResource KeyText}"/></Border>
                </StackPanel>

                <!-- ZXCV Row -->
                <StackPanel Orientation="Horizontal">
                    <Border x:Name="k_LeftShift" Style="{StaticResource KeyStyle}" Width="98"><TextBlock Text="Shift ⇧" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Z" Style="{StaticResource KeyStyle}"><TextBlock Text="Z" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_X" Style="{StaticResource KeyStyle}"><TextBlock Text="X" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_C" Style="{StaticResource KeyStyle}"><TextBlock Text="C" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_V" Style="{StaticResource KeyStyle}"><TextBlock Text="V" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_B" Style="{StaticResource KeyStyle}"><TextBlock Text="B" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_N" Style="{StaticResource KeyStyle}"><TextBlock Text="N" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_M" Style="{StaticResource KeyStyle}"><TextBlock Text="M" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_OemComma" Style="{StaticResource KeyStyle}"><TextBlock Text="," Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_OemPeriod" Style="{StaticResource KeyStyle}"><TextBlock Text="." Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_OemQuestion" Style="{StaticResource KeyStyle}"><TextBlock Text="/" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_RightShift" Style="{StaticResource KeyStyle}" Width="118"><TextBlock Text="Shift ⇧" Style="{StaticResource KeyText}"/></Border>
                </StackPanel>

                <!-- Bottom Row: Ctrl, Win, Alt, Space, Alt, Ctrl, Arrows -->
                <StackPanel Orientation="Horizontal">
                    <Border x:Name="k_LeftCtrl" Style="{StaticResource KeyStyle}" Width="65"><TextBlock Text="Ctrl" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_LWin" Style="{StaticResource KeyStyle}" Width="55"><TextBlock Text="Win" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_LeftAlt" Style="{StaticResource KeyStyle}" Width="55"><TextBlock Text="Alt" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_Space" Style="{StaticResource KeyStyle}" Width="240"><TextBlock Text="Spacebar" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_RightAlt" Style="{StaticResource KeyStyle}" Width="55"><TextBlock Text="Alt" Style="{StaticResource KeyText}"/></Border>
                    <Border x:Name="k_RightCtrl" Style="{StaticResource KeyStyle}" Width="65"><TextBlock Text="Ctrl" Style="{StaticResource KeyText}"/></Border>
                    <Border Width="20"/>
                    <Border x:Name="k_Left" Style="{StaticResource KeyStyle}"><TextBlock Text="◄" Style="{StaticResource KeyText}"/></Border>
                    <StackPanel>
                        <Border x:Name="k_Up" Style="{StaticResource KeyStyle}" Height="20"><TextBlock Text="▲" Style="{StaticResource KeyText}" FontSize="9"/></Border>
                        <Border x:Name="k_Down" Style="{StaticResource KeyStyle}" Height="20"><TextBlock Text="▼" Style="{StaticResource KeyText}" FontSize="9"/></Border>
                    </StackPanel>
                    <Border x:Name="k_Right" Style="{StaticResource KeyStyle}"><TextBlock Text="►" Style="{StaticResource KeyText}"/></Border>
                </StackPanel>
            </StackPanel>
        </Border>

        <!-- Footer Help -->
        <TextBlock Grid.Row="2" Text="* Bấm bất kỳ phím nào trên bàn phím để kiểm tra. Phím nhận tín hiệu tốt sẽ sáng xanh lục (#047857)."
                   Foreground="#64748B" FontSize="12" Margin="0,10,0,0" HorizontalAlignment="Center"/>
    </Grid>
</Window>
"@
    try {
        $win = [System.Windows.Markup.XamlReader]::Parse($xaml)
        if ($null -eq $win) {
            throw "Không thể tạo cửa sổ kiểm tra bàn phím (XamlReader trả về null)."
        }

        $txtKeyStatus = $win.FindName("txtKeyStatus")
        $txtKeyCount  = $win.FindName("txtKeyCount")
        $btnResetKeys = $win.FindName("btnResetKeys")

        $testedKeys = [System.Collections.Generic.HashSet[string]]::new()
        $activeBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(255, 4, 120, 87)) # Emerald Green
        $defaultBrush = New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromArgb(255, 30, 41, 59))

        $resetHandler = {
            $testedKeys.Clear()
            if ($txtKeyCount) { $txtKeyCount.Text = "Đã nhận: 0 phím" }
            if ($txtKeyStatus) { $txtKeyStatus.Text = "Phím vừa gõ: Chưa có | Mã: 0" }
            # Reset all borders
            $allBorders = @("k_Escape","k_F1","k_F2","k_F3","k_F4","k_F5","k_F6","k_F7","k_F8","k_F9","k_F10","k_F11","k_F12",
                            "k_Oem3","k_D1","k_D2","k_D3","k_D4","k_D5","k_D6","k_D7","k_D8","k_D9","k_D0","k_OemMinus","k_OemPlus","k_Back",
                            "k_Tab","k_Q","k_W","k_E","k_R","k_T","k_Y","k_U","k_I","k_O","k_P","k_OemOpenBrackets","k_Oem6","k_Oem5",
                            "k_Capital","k_A","k_S","k_D","k_F","k_G","k_H","k_J","k_K","k_L","k_Oem1","k_OemQuotes","k_Return",
                            "k_LeftShift","k_Z","k_X","k_C","k_V","k_B","k_N","k_M","k_OemComma","k_OemPeriod","k_OemQuestion","k_RightShift",
                            "k_LeftCtrl","k_LWin","k_LeftAlt","k_Space","k_RightAlt","k_RightCtrl","k_Left","k_Up","k_Down","k_Right")
            foreach ($bName in $allBorders) {
                $b = $win.FindName($bName)
                if ($b) { $b.Background = $defaultBrush }
            }
        }

        if ($btnResetKeys) { $btnResetKeys.Add_Click($resetHandler) }

        $win.Add_PreviewKeyDown({
            param($s, $e)
            $key = $e.Key
            if ($key -eq [System.Windows.Input.Key]::System) {
                $key = $e.SystemKey
            }
            $keyStr = $key.ToString()
            $keyName = "k_$keyStr"

            # Map some special keys
            if ($keyStr -eq "OemTilde") { $keyName = "k_Oem3" }
            elseif ($keyStr -eq "OemMinus") { $keyName = "k_OemMinus" }
            elseif ($keyStr -eq "OemPlus") { $keyName = "k_OemPlus" }
            elseif ($keyStr -eq "OemBackslash") { $keyName = "k_Oem5" }
            elseif ($keyStr -eq "OemCloseBrackets") { $keyName = "k_Oem6" }
            elseif ($keyStr -eq "OemSemicolon") { $keyName = "k_Oem1" }

            $border = $win.FindName($keyName)
            if ($border) {
                $border.Background = $activeBrush
            }

            $null = $testedKeys.Add($keyStr)
            if ($txtKeyStatus) {
                $txtKeyStatus.Text = "Phím vừa gõ: $keyStr | Mã: $([int]$key)"
            }
            if ($txtKeyCount) {
                $txtKeyCount.Text = "Đã nhận: $($testedKeys.Count) phím"
            }

            # Prevent Alt or Tab from losing focus if possible
            if ($key -eq [System.Windows.Input.Key]::Tab -or $key -eq [System.Windows.Input.Key]::LeftAlt -or $key -eq [System.Windows.Input.Key]::RightAlt) {
                $e.Handled = $true
            }
        })

        $win.ShowDialog() | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("Lỗi mở Trình Test Bàn Phím: $($_.Exception.Message)", "Keyboard Tester", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    }
}

function Start-CpuBurnInTest {
    param([int]$DurationSeconds = 15)
    try {
        $logicalCores = [System.Environment]::ProcessorCount
        $jobScript = {
            param($duration)
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            while ($sw.Elapsed.TotalSeconds -lt $duration) {
                # Compute heavy math
                $val = 0.0
                for ($i = 0; $i -lt 50000; $i++) {
                    $val += [math]::Sqrt($i) * [math]::Sin($i)
                }
            }
        }

        $jobs = @()
        for ($i = 0; $i -lt $logicalCores; $i++) {
            $jobs += Start-Job -ScriptBlock $jobScript -ArgumentList $DurationSeconds
        }

        return [PSCustomObject]@{
            Success = $true
            Cores   = $logicalCores
            Message = "Đã kích hoạt tải 100% trên $logicalCores luồng CPU trong $DurationSeconds giây."
            Jobs    = $jobs
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "Lỗi khi kích hoạt CPU Stress: $($_.Exception.Message)"
        }
    }
}

function Start-NetworkPingTest {
    $results = @()
    $targets = @(
        @{ Name = "Default Gateway (Router)"; Host = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NextHop -First 1) },
        @{ Name = "Google DNS"; Host = "8.8.8.8" },
        @{ Name = "Cloudflare DNS"; Host = "1.1.1.1" }
    )

    foreach ($t in $targets) {
        if (-not $t.Host) {
            $results += "• $($t.Name): Không tìm thấy địa chỉ (Chưa kết nối mạng)"
            continue
        }
        try {
            $ping = New-Object System.Net.NetworkInformation.Ping
            $reply = $ping.Send($t.Host, 1200)
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $results += "• $($t.Name) ($($t.Host)): Phản hồi $($reply.RoundtripTime) ms - Tốt [OK]"
            } else {
                $results += "• $($t.Name) ($($t.Host)): Trạng thái $($reply.Status) [Thất bại]"
            }
        } catch {
            $results += "• $($t.Name) ($($t.Host)): Lỗi kết nối ($($_.Exception.Message))"
        }
    }

    return ($results -join "`n")
}

function Test-AudioFrequency {
    param([string]$Type = "Bass")
    try {
        switch ($Type) {
            "Bass" {
                # 100Hz, 150Hz, 200Hz
                [System.Console]::Beep(120, 400)
                [System.Console]::Beep(150, 400)
                [System.Console]::Beep(200, 400)
                return "[OK] Đã phát tần số Siêu Trầm (Bass 120-200Hz) kiểm tra thùng loa & màng bass."
            }
            "Mid" {
                # 800Hz, 1000Hz, 1200Hz
                [System.Console]::Beep(800, 300)
                [System.Console]::Beep(1000, 400)
                [System.Console]::Beep(1200, 300)
                return "[OK] Đã phát tần số Trung (Mid 800-1200Hz) kiểm tra độ trong trẻo âm thanh giọng nói."
            }
            "Treble" {
                # 3000Hz, 4000Hz, 5000Hz
                [System.Console]::Beep(2500, 300)
                [System.Console]::Beep(3500, 300)
                [System.Console]::Beep(4500, 400)
                return "[OK] Đã phát tần số Cao (Treble 2500-4500Hz) kiểm tra loa treble & chống xé tiếng."
            }
            default {
                [System.Console]::Beep(800, 400)
                return "[OK] Đã phát âm thanh thử nghiệm."
            }
        }
    } catch {
        [System.Media.SystemSounds]::Asterisk.Play()
        return "[OK] Đã phát âm thanh hệ thống qua loa ngoài."
    }
}

function Test-AudioChannels {
    param([string]$Channel = "Left")
    try {
        if ($Channel -eq "Left") {
            [System.Console]::Beep(800, 400)
            [System.Console]::Beep(1000, 300)
        } else {
            [System.Console]::Beep(500, 400)
            [System.Console]::Beep(700, 300)
        }
        return "[OK] Đã phát âm thanh thử nghiệm kênh $Channel."
    } catch {
        [System.Media.SystemSounds]::Asterisk.Play()
        return "[OK] Đã phát âm thanh hệ thống."
    }
}

function Get-LaptopRepairAudit {
    $bios = Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue
    $board = Get-CimInstance Win32_BaseBoard -ErrorAction SilentlyContinue
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
    $csp = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue

    $releaseDate = if ($bios.ReleaseDate) { $bios.ReleaseDate.ToString('dd/MM/yyyy') } else { "N/A" }
    $biosSerial = if ($bios.SerialNumber) { $bios.SerialNumber.Trim() } else { "N/A" }
    $boardSerial = if ($board.SerialNumber) { $board.SerialNumber.Trim() } else { "N/A" }
    $sysSerial = if ($csp.IdentifyingNumber) { $csp.IdentifyingNumber.Trim() } else { $biosSerial }
    $sysUuid = if ($csp.UUID) { $csp.UUID.Trim() } else { "N/A" }

    $log = @()
    $log += "================= KIỂM TRA LỊCH SỬ PHẦN CỨNG & SERIAL ================="
    $log += "• Hãng sản xuất máy : $($cs.Manufacturer)"
    $log += "• Tên Model thiết bị: $($cs.Model)"
    $log += "• Số Serial BIOS    : $biosSerial"
    $log += "• Số Serial Máy     : $sysSerial"
    $log += "• Phiên bản BIOS    : $($bios.SMBIOSBIOSVersion)"
    $log += "• Ngày xuất xưởng   : $releaseDate"
    $log += "• Bo mạch chủ (Main): $($board.Manufacturer) $($board.Product)"
    $log += "• Serial Bo mạch chủ: $boardSerial"
    $log += "• Mã định danh UUID : $sysUuid"
    $log += "-----------------------------------------------------------------------"
    $log += "ĐÁNH GIÁ TÌNH TRẠNG:"

    $suspiciousValues = @('Default string', 'None', 'To be filled by O.E.M.', '0123456789', 'System Serial Number', 'Not Specified')
    $isSuspicious = $false
    foreach ($sus in $suspiciousValues) {
        if ($biosSerial -like "*$sus*" -or $boardSerial -like "*$sus*") {
            $isSuspicious = $true
            break
        }
    }

    if ($isSuspicious) {
        $log += "⚠️ CẢNH BÁO: Số Serial BIOS hoặc Bo mạch chủ có giá trị mặc định ('$biosSerial' / '$boardSerial')."
        $log += "-> Rất có thể máy đã từng nạp lại file BIOS trắng (Clear ME / Reprogram), thay thế bo mạch chủ hoặc sửa chữa can thiệp phần cứng!"
    } else {
        $log += "✅ Số Serial BIOS và Bo mạch chủ khớp chuẩn OEM, chưa phát hiện dấu hiệu nạp lại BIOS trắng."
    }
    $log += "======================================================================="

    return ($log -join "`n")
}
