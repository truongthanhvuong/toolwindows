# ==============================================================================
# BỘ TEST TDD: CHẨN ĐOÁN ĐA Ổ CỨNG (CRYSTALDISKINFO / HARD DISK SENTINEL)
# & CƠ CHẾ BẢO VỆ CHỐNG SẬP ỨNG DỤNG (GLOBAL EXCEPTION SHIELD)
# ==============================================================================

$passed = 0
$failed = 0

function Assert-Condition {
    param(
        [string]$TestName,
        [bool]$Condition,
        [string]$Message = ""
    )
    if ($Condition) {
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        $global:passed++
    } else {
        Write-Host "  [FAIL] $TestName - $Message" -ForegroundColor Red
        $global:failed++
    }
}

Write-Host ">>> BẮT ĐẦU CHẠY BỘ TEST MULTI-DISK HEALTH & STABILITY <<<" -ForegroundColor Cyan

$diskMgrPath = Join-Path $PSScriptRoot "..\src\Core\DiskHealthManager.ps1"
. $diskMgrPath

# ------------------------------------------------------------------------------
# CA 1: CHUẨN CRYSTALDISKINFO CHO Ổ NVME SSD (PercentageUsed = 0% -> SK 100%)
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 1: Chuẩn CrystalDiskInfo cho NVMe SSD ---" -ForegroundColor Yellow
$nvmeHealth = Get-VUONGTTRealisticHealthScore `
    -PowerOnHours 5000 `
    -PowerOnCount 1000 `
    -Wear 0 `
    -MediaType "SSD" `
    -IsNvme $true `
    -SizeGB 256 `
    -HealthStatus "Healthy"

Assert-Condition -TestName "1.1: Ổ NVMe SSD có PercentageUsed = 0% phải đạt sức khỏe 100% chuẩn CrystalDiskInfo (hiện tại: $($nvmeHealth.HealthPct)%)" `
    -Condition ($nvmeHealth.HealthPct -eq 100) `
    -Message "Ổ NVMe với Wear = 0% không được bị ép tụt sức khỏe"

Assert-Condition -TestName "1.2: Ổ NVMe SSD phải có HealthLevel là GOOD và nhãn TỐT (GOOD)" `
    -Condition ($nvmeHealth.HealthLevel -eq "GOOD" -and $nvmeHealth.HealthText -like "*GOOD*") `
    -Message "HealthLevel hoặc HealthText không đúng chuẩn CrystalDiskInfo"

# ------------------------------------------------------------------------------
# CA 2: CHUẨN HARD DISK SENTINEL CHO Ổ ĐĨA CƠ HDD (Không bad sector -> SK 100%)
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 2: Chuẩn Hard Disk Sentinel cho HDD ---" -ForegroundColor Yellow
$hddHealth = Get-VUONGTTRealisticHealthScore `
    -PowerOnHours 13532 `
    -PowerOnCount 5413 `
    -Wear -1 `
    -MediaType "HDD" `
    -Realloc 0 `
    -Pending 0 `
    -Uncorrectable 0 `
    -SizeGB 1000

Assert-Condition -TestName "2.1: Ổ HDD chạy 13,532 giờ nhưng 0 Bad Sector phải đạt sức khỏe 100% chuẩn Hard Disk Sentinel (hiện tại: $($hddHealth.HealthPct)%)" `
    -Condition ($hddHealth.HealthPct -eq 100) `
    -Message "HDD không có bad sector theo chuẩn Hard Disk Sentinel phải là 100% Perfect"

$hddBadHealth = Get-VUONGTTRealisticHealthScore `
    -PowerOnHours 13532 `
    -PowerOnCount 5413 `
    -Wear -1 `
    -MediaType "HDD" `
    -Realloc 5 `
    -Pending 2 `
    -Uncorrectable 0 `
    -SizeGB 1000

Assert-Condition -TestName "2.2: Ổ HDD có Reallocated/Pending Sector phải bị trừ điểm cảnh báo (hiện tại: $($hddBadHealth.HealthPct)%)" `
    -Condition ($hddBadHealth.HealthPct -lt 95 -and $hddBadHealth.HealthLevel -ne "GOOD") `
    -Message "HDD có sector lỗi không được phép đạt 100% hoặc GOOD"

# ------------------------------------------------------------------------------
# CA 3: ĐA Ổ ĐĨA ĐỘC LẬP & KHÔNG ĐÈ DỮ LIỆU SMART CỦA NHAU
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 3: Đa ổ đĩa độc lập dữ liệu ---" -ForegroundColor Yellow
# Giả lập 2 ổ đĩa: Disk 0 là HDD SATA (13532 giờ, 5413 chu kỳ, 29C), Disk 1 là NVMe SSD (200 giờ, 50 chu kỳ, 35C)
$mockSmartAttributes0 = Get-VUONGTTSmartAttributes `
    -Disk ([PSCustomObject]@{ BusType = "SATA"; Model = "TOSHIBA MQ04ABF100"; MediaType = "HDD" }) `
    -HealthLevel "GOOD" `
    -TempC 29 `
    -PowerHours 13532 `
    -PowerCount 5413 `
    -Wear -1

$mockSmartAttributes1 = Get-VUONGTTSmartAttributes `
    -Disk ([PSCustomObject]@{ BusType = "NVMe"; Model = "Kingmax PCIe SSD 256GB"; MediaType = "SSD" }) `
    -HealthLevel "GOOD" `
    -TempC 35 `
    -PowerHours 200 `
    -PowerCount 50 `
    -Wear 0

# Kiểm tra thuộc tính SMART ID 0C / 0B của từng ổ
$attr0_0C = $mockSmartAttributes0 | Where-Object { $_.Id -eq "0C" } | Select-Object -First 1
$attr1_0B = $mockSmartAttributes1 | Where-Object { $_.Id -eq "0B" } | Select-Object -First 1
$attr1_0C = $mockSmartAttributes1 | Where-Object { $_.Id -eq "0C" } | Select-Object -First 1

Assert-Condition -TestName "3.1: Disk 0 (HDD) có Power Cycle Count đúng 5,413 lần trong SMART" `
    -Condition ($attr0_0C -and $attr0_0C.RawValue -like "*5,413*") `
    -Message "Power Cycle Count của Disk 0 bị lệch, mong muốn 5,413 Lần, nhận được: $($attr0_0C.RawValue)"

Assert-Condition -TestName "3.2: Disk 1 (NVMe) có Power Cycles đúng 50 lần trong SMART (không bị lấy nhầm 5,413 lần của Disk 0)" `
    -Condition ($attr1_0B -and $attr1_0B.RawValue -like "*50*") `
    -Message "Power Cycles của Disk 1 bị đè dữ liệu của Disk 0! Nhận được: $($attr1_0B.RawValue)"

Assert-Condition -TestName "3.3: Disk 1 (NVMe) có Power On Hours đúng 200 giờ trong SMART (không bị lấy nhầm 13,532 giờ của Disk 0)" `
    -Condition ($attr1_0C -and $attr1_0C.RawValue -like "*200*") `
    -Message "Power On Hours của Disk 1 bị đè 13,532 giờ của Disk 0! Nhận được: $($attr1_0C.RawValue)"

# ------------------------------------------------------------------------------
# CA 4: KIỂM THỬ KHÔNG GỌI WMI ATA SMART CHO Ổ NVME (CHỐNG TRÙNG LẶP DỮ LIỆU)
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 4: Cách ly WMI ATA SMART cho ổ NVMe ---" -ForegroundColor Yellow
$scriptContent = Get-Content -Path $diskMgrPath -Raw -Encoding UTF8
$hasNvmeGuard = $scriptContent -match 'MSStorageDriver_ATAPISmartData' -and ($scriptContent -match 'NVMe' -or $scriptContent -match 'MediaType -eq "HDD"')

Assert-Condition -TestName "4.1: Tầng 1.5 WMI ATA SMART phải có bộ lọc cách ly không chạy cho ổ NVMe" `
    -Condition ($hasNvmeGuard) `
    -Message "Chưa có bộ lọc ngăn ổ NVMe lấy nhầm WMI ATA SMART của ổ khác"

# ------------------------------------------------------------------------------
# CA 5: KIỂM THỬ GLOBAL EXCEPTION SHIELD TRONG VUONGTT_TOOLKIT.PS1
# ------------------------------------------------------------------------------
Write-Host "`n--- Kiểm tra 5: Global Exception Shield & Tối ưu ổn định ---" -ForegroundColor Yellow
$toolkitPath = Join-Path $PSScriptRoot "..\VUONGTT_Toolkit.ps1"
$toolkitContent = Get-Content -Path $toolkitPath -Raw -Encoding UTF8

$hasDispatcherException = $toolkitContent -match 'DispatcherUnhandledException'
$hasAppDomainException   = $toolkitContent -match 'CurrentDomain\.add_UnhandledException|UnhandledException'
$hasTaskException        = $toolkitContent -match 'UnobservedTaskException'
$hasHddLabelDistinction  = $toolkitContent -match 'Sức khỏe đĩa cơ' -or $toolkitContent -match 'đĩa cơ HDD'

Assert-Condition -TestName "5.1: Phải đăng ký DispatcherUnhandledException để chống tự động tắt ứng dụng khi phát sinh lỗi UI" `
    -Condition ($hasDispatcherException) `
    -Message "Chưa đăng ký DispatcherUnhandledException trong VUONGTT_Toolkit.ps1"

Assert-Condition -TestName "5.2: Phải đăng ký TaskScheduler.UnobservedTaskException để chống crash ngầm" `
    -Condition ($hasTaskException) `
    -Message "Chưa đăng ký UnobservedTaskException trong VUONGTT_Toolkit.ps1"

Assert-Condition -TestName "5.3: Nhãn tuổi thọ ổ cứng phải phân biệt giữa đĩa cơ HDD và chip Flash SSD" `
    -Condition ($hasHddLabelDistinction) `
    -Message "Chưa sửa nhãn tuổi thọ phân biệt HDD và SSD trong VUONGTT_Toolkit.ps1"

# ------------------------------------------------------------------------------
# TỔNG KẾT
# ------------------------------------------------------------------------------
Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "KẾT QUẢ TEST: $passed PASSED | $failed FAILED" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "========================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    Exit 1
} else {
    Exit 0
}
