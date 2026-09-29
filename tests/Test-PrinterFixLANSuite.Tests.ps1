# Test-PrinterFixLANSuite.Tests.ps1
# TDD Test Suite for Printer & LAN Share Suite (4 Sub-tabs & 0x7c Modal)

$ErrorActionPreference = "Stop"
$root = "e:\toolwindows"
$xamlPath = Join-Path $root "src\UI\MainWindow.xaml"
$backendPath = Join-Path $root "src\Core\NetworkPrinterFix.ps1"
$scriptPath = Join-Path $root "VUONGTT_Toolkit.ps1"

$testsPassed = 0
$testsFailed = 0

function Assert-Condition {
    param([string]$Name, [bool]$Condition, [string]$Details = "")
    if ($Condition) {
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testsPassed++
    } else {
        Write-Host "  [FAIL] $Name - $Details" -ForegroundColor Red
        $script:testsFailed++
    }
}

Write-Host "`n=== KIỂM THỬ TDD: BỘ CÔNG CỤ FIX MÁY IN - SHARE LAN (4 SUB-TABS & MODAL 0x7C) ===" -ForegroundColor Cyan

# 1. Kiểm tra cấu trúc XAML 4 Sub-tabs
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8
$hasSubtabs = ($xamlContent -match 'x:Name="tabPrinterLAN_Fix"') -and 
              ($xamlContent -match 'x:Name="tabPrinterLAN_Credentials"') -and 
              ($xamlContent -match 'x:Name="tabPrinterLAN_ShareUser"') -and 
              ($xamlContent -match 'x:Name="tabPrinterLAN_ShareData"')
Assert-Condition "XAML chứa đầy đủ 4 Sub-tabs (Fix Máy In, Credentials, Tạo User, Fix Chia Sẻ Dữ Liệu)" $hasSubtabs "Không tìm thấy đủ 4 x:Name của các subtabs"

# 2. Kiểm tra DataGrids trong XAML
$hasPrinterGrid = ($xamlContent -match 'x:Name="dgPrinterList"')
$hasUserGrid = ($xamlContent -match 'x:Name="dgUsersList"')
Assert-Condition "XAML chứa DataGrid danh sách máy in (dgPrinterList) và DataGrid User (dgUsersList)" ($hasPrinterGrid -and $hasUserGrid) "Thiếu dgPrinterList hoặc dgUsersList"

# 3. Kiểm tra Modal Overlay 0x0000007c
$hasModal0x7c = ($xamlContent -match 'x:Name="modal0x7c"') -and 
                ($xamlContent -match 'btnExecuteFix0x7c') -and 
                ($xamlContent -match 'rbWin10_2004_Plus')
Assert-Condition "XAML chứa Modal Overlay 0x0000007c với radio options và nút thực thi" $hasModal0x7c "Không tìm thấy modal0x7c hoặc các nút lựa chọn"

# 4. Kiểm tra Checkboxes của 9 Mã lỗi
$hasErrorChecks = ($xamlContent -match 'chkErr0x7c') -and 
                  ($xamlContent -match 'chkErr0xbc4') -and 
                  ($xamlContent -match 'chkErr0x4005') -and 
                  ($xamlContent -match 'chkErr0x11b') -and 
                  ($xamlContent -match 'chkErr0xbcb') -and 
                  ($xamlContent -match 'chkErr0x6d9') -and 
                  ($xamlContent -match 'chkErr0x709') -and 
                  ($xamlContent -match 'chkErr0x012') -and 
                  ($xamlContent -match 'chkErrPolicyInEffect')
Assert-Condition "XAML chứa đủ 9 Checkbox mã lỗi (Máy trạm, Máy chủ, Cả 2 máy)" $hasErrorChecks "Thiếu các checkbox mã lỗi tương ứng"

# 5. Kiểm tra Backend Functions trong NetworkPrinterFix.ps1
. $backendPath

$hasPrinterListFunc = (Get-Command "Get-VUONGTTPrinterList" -ErrorAction SilentlyContinue) -ne $null
$hasLocalUsersFunc  = (Get-Command "Get-VUONGTTLocalUsers" -ErrorAction SilentlyContinue) -ne $null
$hasBatchErrorFunc  = (Get-Command "Invoke-VUONGTTBatchErrorFix" -ErrorAction SilentlyContinue) -ne $null
$hasFix0x7cFunc     = (Get-Command "Invoke-VUONGTTFix0x7c" -ErrorAction SilentlyContinue) -ne $null
$hasCredsFunc       = (Get-Command "Get-VUONGTTCredentials" -ErrorAction SilentlyContinue) -ne $null

Assert-Condition "Backend chứa đầy đủ các hàm cốt lõi (Printer, User, Creds, Batch Error, 0x7c Hot-Swap)" ($hasPrinterListFunc -and $hasLocalUsersFunc -and $hasBatchErrorFunc -and $hasFix0x7cFunc -and $hasCredsFunc) "Các hàm backend mới chưa được định nghĩa trong NetworkPrinterFix.ps1"

# 6. Kiểm tra thực thi Get-VUONGTTPrinterList và Get-VUONGTTLocalUsers
if ($hasPrinterListFunc -and $hasLocalUsersFunc) {
    $printers = Get-VUONGTTPrinterList
    $users = Get-VUONGTTLocalUsers
    Assert-Condition "Backend Get-VUONGTTPrinterList và Get-VUONGTTLocalUsers chạy thành công và trả về dữ liệu" ($printers -ne $null -and $users -ne $null -and $users.Count -gt 0) "Dữ liệu trả về null hoặc không quét được user"
} else {
    Assert-Condition "Backend Get-VUONGTTPrinterList và Get-VUONGTTLocalUsers chạy thành công và trả về dữ liệu" $false "Hàm chưa tồn tại"
}

Write-Host "`nKẾT QUẢ KIỂM THỬ: $testsPassed PASS / $testsFailed FAIL" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -gt 0) {
    exit 1
} else {
    exit 0
}
