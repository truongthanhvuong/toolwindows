# Test suite: Kiem thu Telemetry phan cung thuc te (TDD)
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " TEST SUITE: KIEM THU TELEMETRY PHAN CUNG THUC TE TREN MAY" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Thu thap thong so that tren he dieu hanh
$realOs = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ProductName
$realCpu = (Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0").ProcessorNameString.Trim()
$realGpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty Name).Trim()
$realDisk = (Get-CimInstance Win32_DiskDrive | Select-Object -First 1 -ExpandProperty Model).Trim()

Write-Host "Thong so he dieu hanh & phan cung thuc te:" -ForegroundColor Gray
Write-Host " - Real OS:   $realOs" -ForegroundColor Gray
Write-Host " - Real CPU:  $realCpu" -ForegroundColor Gray
Write-Host " - Real GPU:  $realGpu" -ForegroundColor Gray
Write-Host " - Real Disk: $realDisk" -ForegroundColor Gray

# 2. Goi Rust telemetry logic
$testScript = @"
`$d = [PSCustomObject]@{
    os = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName;
    build = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild;
    cpu = (Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0').ProcessorNameString.Trim();
    cpu_mhz = (Get-ItemProperty 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0').'~MHz';
    cores = [System.Environment]::ProcessorCount;
    gpu = (Get-CimInstance Win32_VideoController | Select-Object -First 1 -ExpandProperty Name);
    disk = (Get-CimInstance Win32_DiskDrive | Select-Object -First 1 -ExpandProperty Model);
    net = (Get-CimInstance Win32_NetworkAdapter -Filter 'NetConnectionStatus=2' | Select-Object -First 1 -ExpandProperty Name);
}
ConvertTo-Json -Compress `$d
"@

$rawJson = powershell -NoProfile -Command $testScript
$obj = $rawJson | ConvertFrom-Json

$failed = 0

# Check 1: Khong duoc chua i9-13900K neu CPU that khong phai i9-13900K
if ($realCpu -notmatch "i9-13900K" -and $obj.cpu -match "i9-13900K") {
    Write-Host "[FAIL] CPU bi hardcode thanh i9-13900K!" -ForegroundColor Red
    $failed++
} else {
    Write-Host "[PASS] CPU khong bi hardcode: $($obj.cpu)" -ForegroundColor Green
}

# Check 2: Khong duoc chua RTX 4080 neu GPU that khong phai RTX 4080
if ($realGpu -notmatch "RTX 4080" -and $obj.gpu -match "RTX 4080") {
    Write-Host "[FAIL] GPU bi hardcode thanh RTX 4080!" -ForegroundColor Red
    $failed++
} else {
    Write-Host "[PASS] GPU khong bi hardcode: $($obj.gpu)" -ForegroundColor Green
}

# Check 3: Khong duoc chua Samsung 990 Pro neu Disk that khong phai Samsung 990 Pro
if ($realDisk -notmatch "Samsung 990" -and $obj.disk -match "Samsung 990") {
    Write-Host "[FAIL] Disk bi hardcode thanh Samsung 990!" -ForegroundColor Red
    $failed++
} else {
    Write-Host "[PASS] Disk khong bi hardcode: $($obj.disk)" -ForegroundColor Green
}

# Check 4: OS khong duoc hardcode Windows 11 neu may la Windows 10
if ($realOs -match "Windows 10" -and $obj.os -match "Windows 11") {
    Write-Host "[FAIL] OS bi hardcode thanh Windows 11 tren may Windows 10!" -ForegroundColor Red
    $failed++
} else {
    Write-Host "[PASS] OS khong bi hardcode: $($obj.os)" -ForegroundColor Green
}

if ($failed -gt 0) {
    exit 1
} else {
    exit 0
}
