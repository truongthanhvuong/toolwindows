# =========================================================================
#   KIEM THU TDD: CHE DO NGUON 24/7 (NEVER SLEEP - DISK & VIDEO ZERO TIMEOUT)
# =========================================================================
$ErrorActionPreference = "Stop"

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) {
        Write-Host "  [FAIL] $message" -ForegroundColor Red
        throw "Assertion Failed: $message"
    }
    Write-Host "  [PASS] $message" -ForegroundColor Green
}

Write-Host "`n>>> KIEM THU CHE DO NGUON DIEN 24/7 (NON-STOP NEVER SLEEP) <<<`n" -ForegroundColor Cyan

$opsPath = "E:\toolwindows\src-tauri\src\system_ops.rs"
$appJsPath = "E:\toolwindows\src-ui\app.js"
$opsContent = Get-Content -Path $opsPath -Raw -Encoding UTF8
$appJsContent = Get-Content -Path $appJsPath -Raw -Encoding UTF8

Write-Host "--- Nhom 1: Kiem Tra Logic Backend system_ops.rs ---" -ForegroundColor Yellow

# 1.1 system_ops.rs phai set DISKIDLE ve 0 (Turn off hard disk after = 0 / Never)
Assert-True ($opsContent -match 'SUB_DISK\s+DISKIDLE\s+0' -or $opsContent -match 'disk-timeout-ac\s+0') "system_ops.rs phai co lenh tat timeout o cung"
Assert-True ($opsContent -match 'SUB_DISK\s+DISKIDLE\s+0') "system_ops.rs phai ghi de SUB_DISK DISKIDLE 0 xuong Registry Power Subgroup"

# 1.2 system_ops.rs phai set VIDEOIDLE ve 0 (Turn off display after = 0 / Never)
Assert-True ($opsContent -match 'SUB_VIDEO\s+VIDEOIDLE\s+0') "system_ops.rs phai ghi de SUB_VIDEO VIDEOIDLE 0 tranh tat man hinh sau 15 phut"

# 1.3 system_ops.rs phai set STANDBYIDLE ve 0 (Sleep after = 0 / Never)
Assert-True ($opsContent -match 'SUB_SLEEP\s+STANDBYIDLE\s+0') "system_ops.rs phai ghi de SUB_SLEEP STANDBYIDLE 0"

# 1.4 system_ops.rs phai goi powercfg -setactive sau cung de commit settings xuong Kernel
Assert-True ($opsContent -match 'powercfg\s+-setactive\s+SCHEME_CURRENT' -or $opsContent -match 'powercfg\s+/setactive\s+SCHEME_CURRENT') "system_ops.rs phai commit setactive SCHEME_CURRENT"

Write-Host "`n--- Nhom 2: Kiem Tra Telemetry Readback Trong collect_win_optimize_state ---" -ForegroundColor Yellow

# 2.1 collect_win_optimize_state phai doc ca disk_seconds
Assert-True ($opsContent -match 'disk_seconds' -and $opsContent -match 'SUB_DISK DISKIDLE') "collect_win_optimize_state phai doc thuc te DISKIDLE de phan anh dung 20 phut"

Write-Host "`n--- Nhom 3: Kiem Tra Thuc Te He Dieu Hanh Windows ---" -ForegroundColor Yellow

# 3.1 Thuc thi truy van tren he thong va dam bao DISKIDLE hien tai la 0
$qDisk = (powercfg /q SCHEME_CURRENT SUB_DISK DISKIDLE 2>$null | Out-String)
$diskAc = -1
if ($qDisk -match 'Current AC Power Setting Index:\s+(0x[0-9a-fA-F]+)') {
    $diskAc = [convert]::ToInt32($matches[1], 16)
}
Assert-True ($diskAc -eq 0) "DISKIDLE hien tai tren may phai bang 0 (Never) chu khong phai 1200s (20 phut). Thuc te: $diskAc giay"

# 3.2 Thuc thi truy van tren he thong va dam bao VIDEOIDLE hien tai la 0
$qVideo = (powercfg /q SCHEME_CURRENT SUB_VIDEO VIDEOIDLE 2>$null | Out-String)
$videoAc = -1
if ($qVideo -match 'Current AC Power Setting Index:\s+(0x[0-9a-fA-F]+)') {
    $videoAc = [convert]::ToInt32($matches[1], 16)
}
Assert-True ($videoAc -eq 0) "VIDEOIDLE hien tai tren may phai bang 0 (Never) chu khong phai 900s (15 phut). Thuc te: $videoAc giay"

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "KET QUA: TAT CA TEST CHE DO 24/7 PASSED" -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green
